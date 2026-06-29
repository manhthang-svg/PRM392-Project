param(
    [string]$Prefix = "origami/tutorials",
    [string]$ApplicationConfig = "spring-security/src/main/resources/application-local.yml"
)

$ErrorActionPreference = "Stop"

function Get-ConfigDefault {
    param([string]$Content, [string]$Key)

    $match = [regex]::Match($Content, "(?m)^\s*$([regex]::Escape($Key)):\s*\$\{[^:}]+:([^}]*)\}\s*$")
    if ($match.Success) {
        return $match.Groups[1].Value.Trim()
    }

    $plain = [regex]::Match($Content, "(?m)^\s*$([regex]::Escape($Key)):\s*(.+?)\s*$")
    if ($plain.Success) {
        return $plain.Groups[1].Value.Trim()
    }

    return ""
}

function Get-CloudinarySetting {
    param([string]$EnvName, [string]$YamlKey, [string]$ConfigContent)

    $value = [Environment]::GetEnvironmentVariable($EnvName)
    if (-not [string]::IsNullOrWhiteSpace($value)) {
        return $value.Trim()
    }

    return (Get-ConfigDefault -Content $ConfigContent -Key $YamlKey)
}

$workspace = (Resolve-Path ".").Path
$configPath = [System.IO.Path]::GetFullPath((Join-Path $workspace $ApplicationConfig))
$config = [System.IO.File]::ReadAllText($configPath)
$cloudName = Get-CloudinarySetting "CLOUDINARY_CLOUD_NAME" "cloud-name" $config
$apiKey = Get-CloudinarySetting "CLOUDINARY_API_KEY" "api-key" $config
$apiSecret = Get-CloudinarySetting "CLOUDINARY_API_SECRET" "api-secret" $config

if ([string]::IsNullOrWhiteSpace($cloudName) -or
    [string]::IsNullOrWhiteSpace($apiKey) -or
    [string]::IsNullOrWhiteSpace($apiSecret)) {
    throw "Missing Cloudinary config."
}

$authBytes = [System.Text.Encoding]::ASCII.GetBytes("${apiKey}:${apiSecret}")
$auth = [Convert]::ToBase64String($authBytes)
$deletedTotal = 0
$nextCursor = ""

do {
    $encodedPrefix = [System.Uri]::EscapeDataString($Prefix)
    $uri = "https://api.cloudinary.com/v1_1/$cloudName/resources/image/upload?prefix=$encodedPrefix&max_results=500"
    if (-not [string]::IsNullOrWhiteSpace($nextCursor)) {
        $uri += "&next_cursor=$([System.Uri]::EscapeDataString($nextCursor))"
    }

    $listBody = & curl.exe --silent --show-error --fail-with-body -H "Authorization: Basic $auth" $uri
    if ($LASTEXITCODE -ne 0) {
        throw "Cloudinary list failed for prefix '$Prefix': $listBody"
    }

    $list = $listBody | ConvertFrom-Json
    $publicIds = @($list.resources | ForEach-Object { $_.public_id })
    if ($publicIds.Count -eq 0) {
        break
    }

    $deleteUri = "https://api.cloudinary.com/v1_1/$cloudName/resources/image/upload"
    $args = @(
        "--silent",
        "--show-error",
        "--fail-with-body",
        "-X", "DELETE",
        "-H", "Authorization: Basic $auth"
    )
    foreach ($publicId in $publicIds) {
        $args += @("-d", "public_ids[]=$publicId")
    }
    $args += @("-d", "invalidate=true", $deleteUri)

    $deleteBody = & curl.exe @args
    if ($LASTEXITCODE -ne 0) {
        throw "Cloudinary delete failed for prefix '$Prefix': $deleteBody"
    }

    $deletedTotal += $publicIds.Count
    Write-Host "Deleted batch: $($publicIds.Count)"
    $nextCursor = [string]$list.next_cursor
} while (-not [string]::IsNullOrWhiteSpace($nextCursor))

Write-Host "Deleted total: $deletedTotal"
