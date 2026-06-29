param(
    [string]$TutorialsRoot = "tutorials",
    [string]$ApplicationConfig = "spring-security/src/main/resources/application-local.yml",
    [string]$OutputSql = "spring-security/src/main/resources/db/migration/V13__replace_library_seed_from_cloudinary.sql",
    [string]$CloudinaryFolder = "",
    [switch]$DeleteExistingCloudinaryAssets,
    [switch]$ReplaceDatabaseSeed
)

$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Net.Http

function Get-ConfigDefault {
    param(
        [string]$Content,
        [string]$Key
    )

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
    param(
        [string]$EnvName,
        [string]$YamlKey,
        [string]$ConfigContent
    )

    $value = [Environment]::GetEnvironmentVariable($EnvName)
    if (-not [string]::IsNullOrWhiteSpace($value)) {
        return $value.Trim()
    }

    return (Get-ConfigDefault -Content $ConfigContent -Key $YamlKey)
}

function Get-Sha1Hex {
    param([string]$Value)

    $sha1 = [System.Security.Cryptography.SHA1]::Create()
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($Value)
        $hash = $sha1.ComputeHash($bytes)
        return -join ($hash | ForEach-Object { $_.ToString("x2") })
    }
    finally {
        $sha1.Dispose()
    }
}

function Upload-CloudinaryImage {
    param(
        [string]$CloudName,
        [string]$ApiKey,
        [string]$ApiSecret,
        [string]$Folder,
        [string]$AssetFolder,
        [System.IO.FileInfo]$File,
        [string]$PublicId
    )

    $timestamp = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds().ToString()
    $signaturePayload = "asset_folder=$AssetFolder&folder=$Folder&overwrite=true&public_id=$PublicId&timestamp=$timestamp$ApiSecret"
    $signature = Get-Sha1Hex $signaturePayload
    $uri = "https://api.cloudinary.com/v1_1/$CloudName/image/upload"

    $responseFile = [System.IO.Path]::GetTempFileName()
    $curlArgs = @(
        "--silent",
        "--show-error",
        "--fail-with-body",
        "--output", $responseFile,
        "-X", "POST",
        $uri,
        "-F", "file=@$($File.FullName)",
        "-F", "api_key=$ApiKey",
        "-F", "timestamp=$timestamp",
        "-F", "asset_folder=$AssetFolder",
        "-F", "folder=$Folder",
        "-F", "public_id=$PublicId",
        "-F", "overwrite=true",
        "-F", "signature=$signature"
    )

    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $stderr = & curl.exe @curlArgs 2>&1
    $exitCode = $LASTEXITCODE
    $ErrorActionPreference = $previousErrorActionPreference
    $body = if ([System.IO.File]::Exists($responseFile)) {
        [System.IO.File]::ReadAllText($responseFile)
    } else {
        ""
    }
    [System.IO.File]::Delete($responseFile)

    if ($exitCode -ne 0) {
        throw "Cloudinary upload failed for $($File.FullName): curlExit=$exitCode stderr=$stderr body=$body"
    }

    return ($body | ConvertFrom-Json)
}

function Remove-CloudinaryAssetsByPrefix {
    param(
        [string]$CloudName,
        [string]$ApiKey,
        [string]$ApiSecret,
        [string]$Prefix
    )

    $encodedPrefix = [System.Uri]::EscapeDataString($Prefix)
    $authBytes = [System.Text.Encoding]::ASCII.GetBytes("${ApiKey}:${ApiSecret}")
    $auth = [Convert]::ToBase64String($authBytes)
    $uri = "https://api.cloudinary.com/v1_1/$CloudName/resources/image/upload?prefix=$encodedPrefix&invalidate=true"
    $responseFile = [System.IO.Path]::GetTempFileName()
    $headers = @("Authorization: Basic $auth")
    $curlArgs = @(
        "--silent",
        "--show-error",
        "--fail-with-body",
        "--output", $responseFile,
        "-X", "DELETE",
        "-H", $headers[0],
        $uri
    )

    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $stderr = & curl.exe @curlArgs 2>&1
    $exitCode = $LASTEXITCODE
    $ErrorActionPreference = $previousErrorActionPreference
    $body = if ([System.IO.File]::Exists($responseFile)) {
        [System.IO.File]::ReadAllText($responseFile)
    } else {
        ""
    }
    [System.IO.File]::Delete($responseFile)

    if ($exitCode -ne 0) {
        throw "Cloudinary delete failed for prefix '$Prefix': curlExit=$exitCode stderr=$stderr body=$body"
    }

    return ($body | ConvertFrom-Json)
}

function Sql-Escape {
    param([string]$Value)
    if ($null -eq $Value) {
        return ""
    }
    return $Value.Replace("'", "''")
}

function To-Title {
    param([string]$Name)
    $words = $Name -replace "_steps$", "" -split "[_-]+"
    return (($words | ForEach-Object {
        if ($_.Length -eq 0) { "" } else { $_.Substring(0, 1).ToUpperInvariant() + $_.Substring(1).ToLowerInvariant() }
    }) -join " ")
}

$workspace = (Resolve-Path ".").Path
$tutorialRootPath = [System.IO.Path]::GetFullPath((Join-Path $workspace $TutorialsRoot))
$configPath = [System.IO.Path]::GetFullPath((Join-Path $workspace $ApplicationConfig))
$outputPath = [System.IO.Path]::GetFullPath((Join-Path $workspace $OutputSql))

if (-not $tutorialRootPath.StartsWith($workspace, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "TutorialsRoot must stay inside workspace: $tutorialRootPath"
}
if (-not $outputPath.StartsWith($workspace, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "OutputSql must stay inside workspace: $outputPath"
}
if (-not [System.IO.Directory]::Exists($tutorialRootPath)) {
    throw "Tutorial folder not found: $tutorialRootPath"
}
if (-not [System.IO.File]::Exists($configPath)) {
    throw "Config file not found: $configPath"
}

$config = [System.IO.File]::ReadAllText($configPath)
$cloudName = Get-CloudinarySetting "CLOUDINARY_CLOUD_NAME" "cloud-name" $config
$apiKey = Get-CloudinarySetting "CLOUDINARY_API_KEY" "api-key" $config
$apiSecret = Get-CloudinarySetting "CLOUDINARY_API_SECRET" "api-secret" $config
if ([string]::IsNullOrWhiteSpace($CloudinaryFolder)) {
    $CloudinaryFolder = Get-CloudinarySetting "CLOUDINARY_FOLDER" "folder" $config
}

if ([string]::IsNullOrWhiteSpace($cloudName) -or
    [string]::IsNullOrWhiteSpace($apiKey) -or
    [string]::IsNullOrWhiteSpace($apiSecret) -or
    [string]::IsNullOrWhiteSpace($CloudinaryFolder)) {
    throw "Missing Cloudinary config. Set CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY, CLOUDINARY_API_SECRET, and CLOUDINARY_FOLDER or application-local.yml defaults."
}

$metadata = @{
    "boat" = @{
        Title = "Origami Boat"
        Category = "geometric"
        Difficulty = "EASY"
        Minutes = 15
        Description = "Fold a classic paper boat from a rectangular sequence of clean creases."
        Materials = @("1 sheet of origami paper", "Flat working surface")
    }
    "cube" = @{
        Title = "Origami Cube"
        Category = "modular"
        Difficulty = "HARD"
        Minutes = 45
        Description = "Build a geometric cube with crisp modular folds."
        Materials = @("6 square sheets", "Patience for repeated modules")
    }
    "gold_flower" = @{
        Title = "Gold Paper Flower"
        Category = "flowers"
        Difficulty = "MEDIUM"
        Minutes = 30
        Description = "Create a decorative flower with layered golden petals."
        Materials = @("1 square sheet", "Bone folder optional")
    }
    "origami_chick_in_egg_steps" = @{
        Title = "Origami Chick In Egg"
        Category = "animals"
        Difficulty = "MEDIUM"
        Minutes = 25
        Description = "Make a cute chick emerging from a cracked paper egg."
        Materials = @("1 yellow square sheet", "1 white square sheet", "Marker optional")
    }
    "pink_bird" = @{
        Title = "Pink Paper Bird"
        Category = "birds"
        Difficulty = "MEDIUM"
        Minutes = 25
        Description = "Fold a soft pink bird model with a neat body and wings."
        Materials = @("1 square sheet", "Flat working surface")
    }
    "plane" = @{
        Title = "Origami Plane"
        Category = "geometric"
        Difficulty = "EASY"
        Minutes = 20
        Description = "A paper plane tutorial with detailed folds from nose to wings."
        Materials = @("1 rectangular sheet", "Ruler optional")
    }
    "sword" = @{
        Title = "Origami Sword"
        Category = "geometric"
        Difficulty = "MEDIUM"
        Minutes = 20
        Description = "Fold a simple paper sword with a blade and handle."
        Materials = @("1 square sheet", "Bone folder optional")
    }
}

$imageExtensions = @(".jpg", ".jpeg", ".png", ".webp")
$tutorialDirs = Get-ChildItem $tutorialRootPath -Directory | Sort-Object Name
$uploaded = [ordered]@{}

if ($DeleteExistingCloudinaryAssets) {
    Write-Host "Deleting old Cloudinary assets with prefix: $CloudinaryFolder"
    $deleteResult = Remove-CloudinaryAssetsByPrefix `
        -CloudName $cloudName `
        -ApiKey $apiKey `
        -ApiSecret $apiSecret `
        -Prefix $CloudinaryFolder
    $deletedCount = if ($deleteResult.deleted) {
        ($deleteResult.deleted.PSObject.Properties | Measure-Object).Count
    } elseif ($deleteResult.deleted_counts) {
        ($deleteResult.deleted_counts.PSObject.Properties | Measure-Object).Count
    } else {
        0
    }
    Write-Host "Deleted Cloudinary assets: $deletedCount"
}

foreach ($dir in $tutorialDirs) {
    $files = Get-ChildItem $dir.FullName -File |
        Where-Object { $imageExtensions -contains $_.Extension.ToLowerInvariant() } |
        Sort-Object Name

    if ($files.Count -eq 0) {
        Write-Host "Skip $($dir.Name): no image files"
        continue
    }

    Write-Host "Uploading $($dir.Name): $($files.Count) image(s)"
    $rows = New-Object System.Collections.Generic.List[object]
    $index = 1
    foreach ($file in $files) {
        $stepNumber = "{0:D2}" -f $index
        $publicId = "$($dir.Name)/step_$stepNumber"
        $assetFolder = "$CloudinaryFolder/$($dir.Name)"
        $result = Upload-CloudinaryImage `
            -CloudName $cloudName `
            -ApiKey $apiKey `
            -ApiSecret $apiSecret `
            -Folder $CloudinaryFolder `
            -AssetFolder $assetFolder `
            -File $file `
            -PublicId $publicId

        $rows.Add([pscustomobject]@{
            StepNumber = $index
            FileName = $file.Name
            SecureUrl = [string]$result.secure_url
        })
        $index++
    }
    $uploaded[$dir.Name] = $rows
}

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("-- Replace Library tutorials from local tutorials/ folder after uploading images to Cloudinary.")
$lines.Add("-- Generated by scripts/seed_library_from_tutorials.ps1.")
$lines.Add("")
$lines.Add("INSERT INTO users (")
$lines.Add("    username, password, display_name, handle, bio, avatar_url,")
$lines.Add("    enabled, account_locked, account_expired")
$lines.Add(")")
$lines.Add("SELECT")
$lines.Add("    'tutorial-seeder@origami.local',")
$lines.Add("    '`$2a`$10`$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy',")
$lines.Add("    'Tutorial Seeder',")
$lines.Add("    'tutorial_seeder',")
$lines.Add("    'Seed creator generated from local tutorial images.',")
$firstTutorialImages = $uploaded.Values | Select-Object -First 1
$avatarUrl = if ($null -ne $firstTutorialImages -and $firstTutorialImages.Count -gt 0) {
    $firstTutorialImages[0].SecureUrl
} else {
    ""
}
$lines.Add("    '$(Sql-Escape $avatarUrl)',")
$lines.Add("    TRUE, FALSE, FALSE")
$lines.Add("WHERE NOT EXISTS (")
$lines.Add("    SELECT 1 FROM users WHERE username = 'tutorial-seeder@origami.local'")
$lines.Add(");")
$lines.Add("")
$lines.Add("SET @folder_seed_creator_id = (")
$lines.Add("    SELECT id FROM users WHERE username = 'tutorial-seeder@origami.local' LIMIT 1")
$lines.Add(");")
$lines.Add("SET @folder_seed_user_role_id = (SELECT id FROM roles WHERE name = 'USER' LIMIT 1);")
$lines.Add("")
$lines.Add("INSERT INTO user_roles (user_id, role_id)")
$lines.Add("SELECT @folder_seed_creator_id, @folder_seed_user_role_id")
$lines.Add("WHERE @folder_seed_creator_id IS NOT NULL")
$lines.Add("  AND @folder_seed_user_role_id IS NOT NULL")
$lines.Add("  AND NOT EXISTS (")
$lines.Add("      SELECT 1 FROM user_roles")
$lines.Add("      WHERE user_id = @folder_seed_creator_id")
$lines.Add("        AND role_id = @folder_seed_user_role_id")
$lines.Add("  );")
$lines.Add("")

if ($ReplaceDatabaseSeed) {
    $seedSlugs = @()
    foreach ($name in $uploaded.Keys) {
        $seedSlugs += "folder-$($name -replace '_steps$', '' -replace '_', '-')"
    }
    $slugList = ($seedSlugs | ForEach-Object { "    '$(Sql-Escape $_)'" }) -join ",`r`n"
    $lines.Add("-- Remove previous generated seed tutorials before inserting the refreshed set.")
    $lines.Add("-- Child rows are removed by ON DELETE CASCADE constraints.")
    $lines.Add("DELETE FROM tutorials")
    $lines.Add("WHERE slug LIKE 'folder-%'")
    if ($seedSlugs.Count -gt 0) {
        $lines.Add("   OR slug IN (")
        $lines.Add($slugList)
        $lines.Add("   )")
    }
    $lines.Add(";")
    $lines.Add("")
}

foreach ($name in $uploaded.Keys) {
    $rows = $uploaded[$name]
    if ($rows.Count -eq 0) {
        continue
    }

    $meta = $metadata[$name]
    if ($null -eq $meta) {
        $meta = @{
            Title = To-Title $name
            Category = "geometric"
            Difficulty = "MEDIUM"
            Minutes = [Math]::Max(10, $rows.Count * 2)
            Description = "Origami tutorial generated from local step images."
            Materials = @("Origami paper", "Flat working surface")
        }
    }

    $slug = "folder-$($name -replace '_steps$', '' -replace '_', '-')"
    $varName = "@tutorial_$($name -replace '[^A-Za-z0-9]', '_')"
    $thumb = $rows[$rows.Count - 1].SecureUrl
    $title = [string]$meta.Title
    $category = [string]$meta.Category
    $difficulty = [string]$meta.Difficulty
    $minutes = [int]$meta.Minutes
    $description = [string]$meta.Description
    $materials = $meta.Materials

    $lines.Add("-- ---------------------------------------------------------------------------")
    $lines.Add("-- $title")
    $lines.Add("-- ---------------------------------------------------------------------------")
    $lines.Add("SET @category_id = (SELECT id FROM categories WHERE slug = '$(Sql-Escape $category)' LIMIT 1);")
    $lines.Add("")
    $lines.Add("INSERT INTO tutorials (")
    $lines.Add("    creator_id, category_id, slug, title, description, thumbnail_url,")
    $lines.Add("    difficulty, estimated_minutes, status, submitted_at, published_at, deleted")
    $lines.Add(")")
    $lines.Add("SELECT")
    $lines.Add("    @folder_seed_creator_id,")
    $lines.Add("    @category_id,")
    $lines.Add("    '$(Sql-Escape $slug)',")
    $lines.Add("    '$(Sql-Escape $title)',")
    $lines.Add("    '$(Sql-Escape $description)',")
    $lines.Add("    '$(Sql-Escape $thumb)',")
    $lines.Add("    '$(Sql-Escape $difficulty)',")
    $lines.Add("    $minutes,")
    $lines.Add("    'APPROVED',")
    $lines.Add("    CURRENT_TIMESTAMP(6),")
    $lines.Add("    CURRENT_TIMESTAMP(6),")
    $lines.Add("    FALSE")
    $lines.Add("WHERE @folder_seed_creator_id IS NOT NULL")
    $lines.Add("  AND NOT EXISTS (SELECT 1 FROM tutorials WHERE slug = '$(Sql-Escape $slug)');")
    $lines.Add("")
    $lines.Add("SET $varName = (SELECT id FROM tutorials WHERE slug = '$(Sql-Escape $slug)' LIMIT 1);")
    $lines.Add("")

    $materialOrder = 1
    foreach ($material in $materials) {
        $lines.Add("INSERT INTO tutorial_materials (tutorial_id, name, quantity, notes, display_order)")
        $lines.Add("SELECT $varName, '$(Sql-Escape $material)', NULL, NULL, $materialOrder")
        $lines.Add("WHERE $varName IS NOT NULL")
        $lines.Add("  AND NOT EXISTS (")
        $lines.Add("      SELECT 1 FROM tutorial_materials")
        $lines.Add("      WHERE tutorial_id = $varName AND display_order = $materialOrder")
        $lines.Add("  );")
        $lines.Add("")
        $materialOrder++
    }

    foreach ($row in $rows) {
        $stepNumber = [int]$row.StepNumber
        $stepTitle = "Step $stepNumber"
        $stepDescription = "Follow the fold shown in step $stepNumber for $title."
        $lines.Add("INSERT INTO tutorial_steps (tutorial_id, step_number, title, description, media_url)")
        $lines.Add("SELECT $varName, $stepNumber, '$(Sql-Escape $stepTitle)', '$(Sql-Escape $stepDescription)', '$(Sql-Escape $row.SecureUrl)'")
        $lines.Add("WHERE $varName IS NOT NULL")
        $lines.Add("  AND NOT EXISTS (")
        $lines.Add("      SELECT 1 FROM tutorial_steps")
        $lines.Add("      WHERE tutorial_id = $varName AND step_number = $stepNumber")
        $lines.Add("  );")
        $lines.Add("")
    }

    $lines.Add("INSERT INTO tutorial_status_history (tutorial_id, moderator_id, from_status, to_status, note)")
    $lines.Add("SELECT $varName, NULL, NULL, 'APPROVED', 'Seeded from local tutorial images uploaded to Cloudinary.'")
    $lines.Add("WHERE $varName IS NOT NULL")
    $lines.Add("  AND NOT EXISTS (")
    $lines.Add("      SELECT 1 FROM tutorial_status_history")
    $lines.Add("      WHERE tutorial_id = $varName AND to_status = 'APPROVED'")
    $lines.Add("  );")
    $lines.Add("")
}

[System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($outputPath)) | Out-Null
[System.IO.File]::WriteAllLines($outputPath, $lines, [System.Text.UTF8Encoding]::new($false))

Write-Host "Generated SQL migration: $outputPath"
Write-Host "Uploaded tutorials: $($uploaded.Keys.Count)"
