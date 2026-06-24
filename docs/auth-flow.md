# JWT authentication flow

## API contract

### Email registration with OTP

Request a code with `POST /api/auth/register/request-otp`:

```json
{"email": "paper@example.com"}
```

The code contains six digits, expires after five minutes, can be resent after
60 seconds and is locked after five incorrect attempts. The database stores an
HMAC-SHA256 digest, never the raw OTP.

Verify the code and create the account with `POST /api/auth/register/verify`:

```json
{
  "email": "paper@example.com",
  "otp": "123456",
  "displayName": "Paper Artist",
  "handle": "paperartist",
  "password": "password123"
}
```

The Flutter app logs the new account in immediately after successful
verification.

### Login

`POST /api/auth/login`

```json
{
  "username": "paper@example.com",
  "password": "password123"
}
```

The successful `ApiResponse.data` value is:

```json
{
  "accessToken": "eyJ...",
  "refreshToken": "4fe1...",
  "tokenType": "Bearer",
  "expiresIn": 900
}
```

The backend also sets the refresh token as an HttpOnly cookie for browser
clients. Flutter mobile stores both tokens with `flutter_secure_storage`; the
password is never persisted.

### Refresh

`POST /api/auth/refresh-token` accepts either the HttpOnly cookie or:

```json
{"refreshToken": "4fe1..."}
```

The refresh token is rotated on every successful refresh. Reusing the previous
value returns `401`. The response has the same token shape as login.

### Protected requests

```http
Authorization: Bearer <accessToken>
```

`ApiClient` adds this header automatically. On the first `401`, it performs one
refresh, persists the rotated tokens and retries the original request once. If
refresh fails, the local session is cleared.

### Logout

`POST /api/auth/logout` accepts the refresh token body shown above. Server-side
state is revoked and the browser cookie is cleared. Flutter clears local tokens
even when the API is temporarily unavailable.

## Running locally

Flutter selects the local API address by platform: `http://10.0.2.2:8080` for
the Android emulator and `http://localhost:8080` for web/desktop. Debug Android
builds allow cleartext HTTP only for this local workflow.

For a physical device, replace `192.168.1.10` with the computer's LAN address:

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8080
```

For Flutter web, run on an origin listed by backend `CORS_ALLOWED_ORIGIN` and
provide the browser-reachable API URL:

```powershell
flutter run -d chrome --web-port 3000 `
  --dart-define=API_BASE_URL=http://localhost:8080
```

Production must use HTTPS and set `app.cookie.secure=true`.

## SMTP configuration

Registration email is disabled until SMTP credentials are supplied. For Gmail,
enable two-step verification and use an App Password rather than the normal
account password:

```powershell
$env:MAIL_HOST="smtp.gmail.com"
$env:MAIL_PORT="587"
$env:MAIL_USERNAME="your-account@gmail.com"
$env:MAIL_PASSWORD="your-16-character-app-password"
$env:MAIL_FROM="your-account@gmail.com"
$env:OTP_PEPPER="a-long-random-secret-used-only-by-the-server"

cd spring-security
.\mvnw.cmd spring-boot:run
```

SMTP connection, read and write timeouts are limited to five seconds. Never
commit real mail credentials or the production OTP pepper to Git.
