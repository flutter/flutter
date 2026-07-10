# Release Environment Checklist

Use this checklist before any public deployment.

## 1) Build-time Defines (Required)

### Production
- APP_ENV must be `production` (or `prod`).
- RECAPTCHA_SITE_KEY must be a real production key for web builds.
- FCM_SERVER_KEY must NOT be shipped to clients.

Example web release build:

```bash
flutter build web --release --dart-define=APP_ENV=production --dart-define=RECAPTCHA_SITE_KEY=YOUR_REAL_RECAPTCHA_KEY
```

Example Android release build:

```bash
flutter build appbundle --release --dart-define=APP_ENV=production
```

## 2) Firebase Rules
- Publish `FIREBASE_SECURITY_RULES_PRODUCTION.json` to production.
- Use `FIREBASE_SECURITY_RULES_STAGING.json` only in staging projects.
- Never reuse staging rules in production.

## 3) App Check
- Web: verify RECAPTCHA_SITE_KEY is configured for the production origin.
- Android: Play Integrity must be enabled in Firebase App Check.
- iOS: DeviceCheck/App Attest configured as needed.

## 4) Secrets and Signing
- `android/key.properties` must contain local real secrets only on the release machine.
- Do not commit keystore files or secret passwords.
- Rotate any leaked signing values before production rollout.

## 5) Authentication Sanity
- Client login succeeds with valid credentials.
- Instructor login succeeds with valid credentials.
- Invalid credentials fail cleanly.
- Unprovisioned client accounts are rejected.

## 6) Smoke Tests
- Client can load profile and workouts after login.
- Instructor can load clients and assign workouts.
- Rest day and notifications features do not throw permission errors.

## 7) Go/No-Go
Go only if all checks above pass in staging and production rules are published.
