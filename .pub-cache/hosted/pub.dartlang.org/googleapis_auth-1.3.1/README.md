Provides support for obtaining OAuth2 credentials to access Google APIs.

This package also provides convenience functionality for:

- obtaining authenticated HTTP clients
- automatically refreshing OAuth2 credentials

### Using this package

Using this package requires creating a Google Cloud Project and obtaining
application credentials for the specific application type. The steps required
are:

- Create a new Google Cloud Project on the
  [Google Developers Console](https://console.developers.google.com)
- Enable all APIs that the application will use on the
  [Google Developers Console](https://console.developers.google.com) (under
  DevConsole -> Project -> APIs & auth -> APIs)
- Obtain application credentials for a specific application type on the
  [Google Developers Console](https://console.developers.google.com) (under
  DevConsole -> Project -> APIs & auth -> Credentials)
- Use the `googleapis_auth` package to obtain access credentials / obtain an
  authenticated HTTP client.

Depending on the application type, there are different ways to achieve the third
and fourth step. The following is a list of supported OAuth2 flows with a
description of these two steps.

#### Client-side Web Application

For client-side only web applications a "Client ID" needs to be created (under
DevConsole -> Project -> APIs & auth -> Credentials). When creating a new client
ID, select the "Web application" type. For client-side only applications, no
`Redirect URIs` are necessary. The `Javascript Origins` setting must be set to
all URLs on which your application will be served (e.g. http://localhost:8080
for local testing).

After the Client ID has been created, you can obtain access credentials via

```dart
import 'package:googleapis_auth/auth_browser.dart';

// Initialize the browser oauth2 flow functionality then use it to obtain credentials.
Future<AccessCredentials> obtainCredentials() async {
  final flow = await createImplicitBrowserFlow(
    ClientId('....apps.googleusercontent.com'),
    ['scope1', 'scope2'],
  );

  try {
    return await flow.obtainAccessCredentialsViaUserConsent();
  } finally {
    flow.close();
  }
}
```

or obtain an authenticated HTTP client via

```dart
import 'package:googleapis_auth/auth_browser.dart';

// Initialize the browser oauth2 flow functionality then use it to
// get an authenticated and auto refreshing client.
Future<AuthClient> obtainAuthenticatedClient() async {
  final flow = await createImplicitBrowserFlow(
    ClientId('....apps.googleusercontent.com'),
    ['scope1', 'scope2'],
  );

  try {
    return await flow.clientViaUserConsent();
  } finally {
    flow.close();
  }
}
```

To prevent popup blockers from blocking the user authorization dialog, the
methods `obtainAccessCredentialsViaUserConsent` and `clientViaUserConsent`
should preferably only be called inside an event handler, since most browsers do
not block popup windows created in response to a user interaction.

The authenticated HTTP client can now access data on behalf a user for the
requested oauth2 scopes.

#### Installed/Console Application

For installed/console applications a "Client ID" needs to be created (under
DevConsole -> Project -> APIs & auth -> Credentials). When creating a new client
ID, select the "Installed application -> Other" type.

The redirect URIs for the automatic and manual flow will be configured
automatically.

After the Client ID has been created, you can obtain access credentials via

```dart
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

// Use the oauth2 authentication code flow functionality to obtain
// credentials. [prompt] is used for directing the user to a URI.
Future<AccessCredentials> obtainCredentials() async {
  final client = http.Client();

  try {
    return await obtainAccessCredentialsViaUserConsent(
      ClientId('....apps.googleusercontent.com', '...'),
      ['scope1', 'scope2'],
      client,
      _prompt,
    );
  } finally {
    client.close();
  }
}

void _prompt(String url) {
  print('Please go to the following URL and grant access:');
  print('  => $url');
  print('');
}
```

or obtain an authenticated HTTP client via

```dart
import 'package:googleapis_auth/auth_io.dart';

// Use the oauth2 code grant server flow functionality to
// get an authenticated and auto refreshing client.
Future<AuthClient> obtainCredentials() async => await clientViaUserConsent(
  ClientId('....apps.googleusercontent.com', '...'),
  ['scope1', 'scope2'],
  _prompt,
);

void _prompt(String url) {
  print('Please go to the following URL and grant access:');
  print('  => $url');
  print('');
}
```

The Client ID must be created with a `client_secret` here, however there is no
way to properly secure a `client_secret` for installed/console applications.
Fortunately the OAuth2 flow used in this case
[assumes that the app cannot keep secrets](https://developers.google.com/identity/protocols/oauth2/native-app)
so this particular `client_secret` does not need to be kept secret. You should
however make sure not to re-use the same `client_secret` anywhere secrecy is
required.

In case of misconfigured browsers/proxies or other issues, it is also possible
to use a manual flow via `obtainAccessCredentialsViaUserConsentManual` and
`clientViaUserConsentManual`. But in this case the `prompt` function needs to
complete with a `Future<String>` which contains the "authorization code". The
user obtains the "authorization code" (which is a string of characters) in a
browser and needs to copy & paste it to the application. (The prompt function
should block until it has gotten the "authorization code" from the user.)

The authenticated HTTP client can now access data on behalf a user for the
requested oauth2 scopes.

#### Autonomous Application / Service Account

If an application wants to act autonomously and access e.g. data from a Google
Cloud Project, then a Service Account can be created. In this case no user
authorization is involved.

A service account can be created via the "Service account" application type when
creating a Client ID (under DevConsole -> Project -> APIs & auth ->
Credentials). It will download a JSON document which contains a private RSA key.
That private key is used for obtaining access credentials.

After the service account was created, you can obtain access credentials via

```dart
import "package:googleapis_auth/auth_io.dart";
import "package:http/http.dart" as http;

...

// Use service account credentials to obtain oauth credentials.
Future<AccessCredentials> obtainCredentials() async {
  var accountCredentials = ServiceAccountCredentials.fromJson({
    "private_key_id": "<please fill in>",
    "private_key": "<please fill in>",
    "client_email": "<please fill in>@developer.gserviceaccount.com",
    "client_id": "<please fill in>.apps.googleusercontent.com",
    "type": "service_account"
  });
  var scopes = [...];

  var client = http.Client();
  AccessCredentials credentials =
    await obtainAccessCredentialsViaServiceAccount(accountCredentials, scopes, client);

  client.close();
  return credentials;
}
```

or an authenticated HTTP client via

```dart
import "package:googleapis_auth/auth_io.dart";

...

// Use service account credentials to get an authenticated and auto refreshing client.
Future<AuthClient> obtainAuthenticatedClient() async {
  final accountCredentials = ServiceAccountCredentials.fromJson({
    "private_key_id": "<please fill in>",
    "private_key": "<please fill in>",
    "client_email": "<please fill in>@developer.gserviceaccount.com",
    "client_id": "<please fill in>.apps.googleusercontent.com",
    "type": "service_account"
  });
  var scopes = [...];

  AuthClient client = await clientViaServiceAccount(accountCredentials, scopes);

  return client; // Remember to close the client when you are finished with it.
}
```

The authenticated HTTP client can now access APIs.

##### Impersonation

For some APIs the use of a service account also requires to impersonate a user.
To support that the `ServiceAccountCredentials` constructors have an optional
argument `impersonatedUser` to specify the user to impersonate.

One example of this are the Google Apps APIs. See
[Perform Google Apps Domain-Wide Delegation of Authority](https://developers.google.com/admin-sdk/directory/v1/guides/delegation)
for information on the additional security configuration required to enable this
for a service account.

#### Autonomous Application / Compute Engine using metadata service

If an application wants to act autonomously and access e.g. data from a Google
Cloud Project, then a Service Account can be used. In case the application is
running on a ComputeEngine VM it is possible to start a VM with a set of scopes
the VM is allowed to use. See the
[documentation](https://cloud.google.com/compute/docs/access/create-enable-service-accounts-for-instances#using)
for further information.

Here is an example of using the metadata service for obtaining access
credentials on a ComputeEngine VM.

```dart
import "package:googleapis_auth/auth_io.dart";
import "package:http/http.dart" as http;

...

// Use the metadata service to obtain oauth credentials.
Future<AccessCredentials> obtainCredentials() async {
  var client = http.Client();

  AccessCredentials credentials =
      await obtainAccessCredentialsViaMetadataServer(client);

  client.close();
  return credentials;
}
```

or an authenticated HTTP client via

```dart
import "package:googleapis_auth/auth_io.dart";

...

// Use the metadata service to get an authenticated and auto refreshing client.
Future<AuthClient> obtainAuthenticatedClient() async {

  AuthClient client = await clientViaMetadataServer();

  return client; // Remember to close the client when you are finished with it.
}
```

The authenticated HTTP client can now access APIs.

#### Accessing Public Data with API Key

It is possible to access some APIs by just using an API key without OAuth2.

An API key can be obtained on the Google Developers Console by creating a Key at
the "Public API access" section (under DevConsole -> Project -> APIs & auth ->
Credentials).

A key can be created for different application types: For browser applications
it is necessary to specify a set of referer URls from which the application
would like to access APIs. For server applications it is possible to specify a
list of IP ranges from which the client application would like to access APIs.

Note that the ApiKey is used for quota and billing purposes and should not be
disclosed to third parties.

Here is an example of getting an HTTP client which uses an API key for making
HTTP requests.

```dart
import "package:googleapis_auth/auth_io.dart";

var client = clientViaApiKey('<api-key-from-devconsole>');
// [client] can now be used to make REST calls to Google APIs.

...

client.close();
```

### More information

More information can be obtained from official Google Developers documentation:

- [OAuth2 to Access Google APIs](https://developers.google.com/identity/protocols/oauth2)
- [OAuth2 Playground](https://developers.google.com/oauthplayground/)
