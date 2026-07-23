# Go-Live Security Checklist

Use this checklist before putting the app online.

## 1) Firebase Authentication
- Enable Firebase Authentication in Firebase Console.
- Ensure every app user signs in through Firebase Auth before database access.
- Use uid-based ownership for user records.

## 2) Realtime Database Rules
- Publish rules from FIREBASE_SECURITY_RULES.json.
- Confirm rules are deny-by-default at root.
- Current phase: enforce auth plus owner/instructor checks with uid/username compatibility.
- Final phase: complete uid ownership migration for all records and remove legacy username-path compatibility.
- Do not use test-mode rules in production.

## 3) Password Handling
- Do not store plaintext passwords in local storage or Realtime Database.
- Keep password verification server/auth provider based where possible.
- Remove any debug logs that include passwords or tokens.

## 4) App Check
- Enable Firebase App Check for Realtime Database.
- Enforce App Check in production after validating clients.

## 5) Environments
- Use separate Firebase projects for dev and production.
- Keep production credentials and keys out of source control.

## 6) Monitoring
- Enable Firebase alerts and usage monitoring.
- Watch for unusual reads/writes and auth failures.

## 7) Release Hygiene
- Build release mode only for production deployment.
- Keep dependencies updated and remove dead debug code.
