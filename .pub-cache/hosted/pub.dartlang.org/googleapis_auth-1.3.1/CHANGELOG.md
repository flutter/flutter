## 1.3.1

- Include `plugin_name` during browser authorization.

## 1.3.0

- The `secret` param in `ClientId` constructor is now optional.
- Use the latest supported Google OAuth 2.0 URL
- `auth_browser` library:
  - Migrated to newer `auth2` Javascript API.
  - Added support for `hostedDomain` to all applicable functions.
  - `createImplicitBrowserFlow`: added (unsupported) `enableDebugLogs` param.
    (Maybe helpful for debugging, but should not be used in production.)
- `auth_io` library:
  - Generate a longer, secure random state token.
  - Implement code verifier logic for the desktop auth flows. See
    https://developers.google.com/identity/protocols/oauth2/native-app#create-code-challenge
  - `obtainAccessCredentialsViaCodeExchange`
    - `scopes` are now acquired from the initial API call and not via a separate
      API call to the `tokeninfo` endpoint.
    - Added optional `codeVerifier` parameter.

## 1.2.0

- Added an optional `hostedDomain` parameter to many functions in
  `auth_io.dart`. If provided, restricts sign-in to Google Apps hosted accounts
  at that domain.
- Fix an error when doing OAUTH code exchanged with an undefined secret.
- `clientViaApiKey` is now exported from `googleapis_auth.dart`.
- Added `String? details` to `UserConsentException`.
- Update the host used to access metadata on Google Cloud. From
  `http://metadata/` to `http://metadata.google.internal`.
- Require Dart 2.13
- Deprecated `RefreshFailedException` - `ServerRequestFailedException` is used
  instead.

## 1.1.0

- Added the `googleapis_auth.dart` library. It is convention to have the default
  library within a package align with the package name. `auth.dart` is now
  deprecated and will be removed in v2.
- Added `fromJson` factory and `toJson` method to `AccessToken`,
  `AccessCredentials`, and `ClientId`.
- Remove dynamic function invocations.

## 1.0.0

- Add support for null-safety.
- Require Dart 2.12 or later.

## 0.2.12+1

- Removed a `dart:async` import that isn't required for \>=Dart 2.1.
- Require \>=Dart 2.1.

## 0.2.12

- Add `clientViaApplicationDefaultCredentials` for obtaining credentials using
  [ADC](https://cloud.google.com/docs/authentication/production).

## 0.2.11+1

- Fix 'multiple completer completion' bug in `ImplicitFlow`.

## 0.2.11

- Add the `force` parameter to the `obtainAccessCredentialsViaUserConsent` API.

## 0.2.10

- Look for GCE metadata host in environment under `$GCE_METADATA_HOST`.

## 0.2.9

- Prepare for [Uint8List SDK breaking change](Prepare for Uint8List SDK breaking
  change).

## 0.2.8

- Initialize implicit browser flows statically, allowing multiple ImplicitFlow
  objects to initialize without trying to load the gapi JavaScript library
  multiple times.

## 0.2.7

- Support for specifying desired `ResponseType`, allowing applications to obtain
  an `id_token` using `ImplicitBrowserFlow`.

## 0.2.6

- Ignore script loading error after timeout for in-browser implicit login-flow.

## 0.2.5+3

- Support `package:http` `>=0.11.3+17 <0.13.0`.

## 0.2.5+2

- Support Dart 2.

## 0.2.5+1

- Switch all uppercase constants from `dart:convert` to lowercase.

## 0.2.5

- Add an optional `loginHint` parameter to browser oauth2 flow APIs which can be
  used to specify a hint as to which user is being logged in.

## 0.2.4

- Added `id_token` to `AccessCredentials`

- Migrated to Dart 2 `BigInt`.

## 0.2.3+6

- Fix async issue in oauth2 flow implementation

## 0.2.3+5

- Support the latest version of `crypto` package.

## 0.2.3+4

- Make package strong-mode compliant.

## 0.2.3+3

- Support package:crypto >= 0.9.2

## 0.2.3+2

- Use preferred "Metadata-Flavor" HTTP header in
  `MetadataServerAuthorizationFlow` instead of the deprecated
  "X-Google-Metadata-Request" header.

## 0.2.3

- Allow `ServiceAccountCredentials` constructors to take an optional `user`
  argument to specify a user to impersonate.

## 0.2.2

- Allow `ServiceAccountCredentials.fromJson` to accept a `Map`.
- Cleaned up `README.md`

## 0.2.1

- Added optional `force` and `immediate` arguments to `runHybridFlow`.

## 0.2.0

- Renamed `forceUserConsent` parameter to `immediate`.
- Added `runHybridFlow` function to `auth_browser`, with corresponding
  `HybridFlowResult` class.

## 0.1.1

- Add `clientViaApiKey` functions to `auth_io` ad `auth_browser`.

## 0.1.0

- First release.
