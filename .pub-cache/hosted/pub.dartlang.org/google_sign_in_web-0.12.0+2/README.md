# google\_sign\_in\_web

The web implementation of [google_sign_in](https://pub.dev/packages/google_sign_in)

## Migrating to v0.11 and v0.12 (Google Identity Services)

The `google_sign_in_web` plugin is backed by the new Google Identity Services
(GIS) JS SDK since version 0.11.0.

The GIS SDK is used both for [Authentication](https://developers.google.com/identity/gsi/web/guides/overview)
and [Authorization](https://developers.google.com/identity/oauth2/web/guides/overview) flows.

The GIS SDK, however, doesn't behave exactly like the one being deprecated.
Some concepts have experienced pretty drastic changes, and that's why this
plugin required a major version update.

### Differences between Google Identity Services SDK and Google Sign-In for Web SDK.

The **Google Sign-In JavaScript for Web JS SDK** is set to be deprecated after
March 31, 2023. **Google Identity Services (GIS) SDK** is the new solution to
quickly and easily sign users into your app suing their Google accounts.

* In the GIS SDK, Authentication and Authorization are now two separate concerns.
  * Authentication (information about the current user) flows will not
    authorize `scopes` anymore.
  * Authorization (permissions for the app to access certain user information)
    flows will not return authentication information.
* The GIS SDK no longer has direct access to previously-seen users upon initialization.
  * `signInSilently` now displays the One Tap UX for web.
* **Since 0.12** The plugin provides an `idToken` (JWT-encoded info) when the
  user successfully completes an authentication flow:
  * In the plugin: `signInSilently` and through the web-only `renderButton` widget.
* The plugin `signIn` method uses the OAuth "Implicit Flow" to Authorize the requested `scopes`.
  * This method only provides an `accessToken`, and not an `idToken`, so if your
    app needs an `idToken`, this method **should be avoided on the web**.
* The GIS SDK no longer handles sign-in state and user sessions, it only provides
  Authentication credentials for the moment the user did authenticate.
* The GIS SDK no longer is able to renew Authorization sessions on the web.
  Once the token expires, API requests will begin to fail with unauthorized,
  and user Authorization is required again.

See more differences in the following migration guides:

* Authentication > [Migrating from Google Sign-In](https://developers.google.com/identity/gsi/web/guides/migration)
* Authorization > [Migrate to Google Identity Services](https://developers.google.com/identity/oauth2/web/guides/migration-to-gis)

### New use cases to take into account in your app

#### Authentication != Authorization

In the GIS SDK, the concepts of Authentication and Authorization have been separated.

It is possible now to have an Authenticated user that hasn't Authorized any `scopes`.

Flutter apps that need to run in the web must now handle the fact that an Authenticated
user may not have permissions to access the `scopes` it requires to function.

The Google Sign In plugin has a new `canAccessScopes` method that can be used to
check if a user is Authorized or not.

It is also possible that Authorizations expire while users are using an app
(after 3600 seconds), so apps should monitor response failures from the APIs, and
prompt users (interactively) to grant permissions again.

Check the "Integration considerations > [UX separation for authentication and authorization](https://developers.google.com/identity/gsi/web/guides/integrate#ux_separation_for_authentication_and_authorization)
guide" in the official GIS SDK documentation for more information about this.

_(See also the [package:google_sign_in example app](https://pub.dev/packages/google_sign_in/example)
for a simple implementation of this (look at the `isAuthorized` variable).)_

#### Is this separation *always required*?

Only if the scopes required by an app are different from the
[OpenID Connect scopes](https://developers.google.com/identity/protocols/oauth2/scopes#openid-connect).

If an app only needs an `idToken`, or the OpenID Connect scopes, the Authentication
bits of the plugin should be enough for your app (`signInSilently` and `renderButton`).

### What happened to the `signIn` method on the web?

Because the GIS SDK for web no longer provides users with the ability to create
their own Sign-In buttons, or an API to start the sign in flow, the current
implementation of `signIn` (that does authorization and authentication) is no
longer feasible on the web.

The web plugin attempts to simulate the old `signIn` behavior by using the 
[OAuth Implicit pop-up flow](https://developers.google.com/identity/oauth2/web/guides/use-token-model),
which authenticates and authorizes users.

The drawback of this approach is that the OAuth flow **only returns an `accessToken`**,
and a synthetic version of the User Data, that does **not include an `idToken`**.

The solution to this is to **migrate your custom "Sign In" buttons in the web to
the Button Widget provided by this package: `Widget renderButton()`.**

_(Check the [package:google_sign_in example app](https://pub.dev/packages/google_sign_in/example)
for an example on how to mix the `renderButton` widget on the web, with a custom
button for the mobile.)_

#### Enable access to the People API for your GCP project

If you want to use the `signIn` method on the web, the plugin will do an additional
request to the PeopleAPI to retrieve the logged-in user information (minus the `idToken`).

For this to work, you must enable access to the People API on your Client ID in
the GCP console.

This is **not recommended**. Ideally, your web application should use a mix of
`signInSilently` and the Google Sign In web `renderButton` to authenticate your
users, and then `canAccessScopes` and `requestScopes` to authorize the `scopes`
that are needed.

#### Why is the `idToken` missing after `signIn`?

The `idToken` is cryptographically signed by Google Identity Services, and
this plugin can't spoof that signature.

#### User Sessions

Since the GIS SDK does _not_ manage user sessions anymore, apps that relied on
this feature might break.

If long-lived sessions are required, consider using some user authentication
system that supports Google Sign In as a federated Authentication provider,
like [Firebase Auth](https://firebase.google.com/docs/auth/flutter/federated-auth#google),
or similar.

#### Expired / Invalid Authorization Tokens

Since the GIS SDK does _not_ auto-renew authorization tokens anymore, it's now
the responsibility of your app to do so.

Apps now need to monitor the status code of their REST API requests for response
codes different to `200`. For example:

* `401`: Missing or invalid access token.
* `403`: Expired access token.

In either case, your app needs to prompt the end user to `requestScopes`, to
**interactively** renew the token.

The GIS SDK limits authorization token duration to one hour (3600 seconds).

## Usage

### Import the package

This package is [endorsed](https://flutter.dev/docs/development/packages-and-plugins/developing-packages#endorsed-federated-plugin),
which means you can simply use `google_sign_in`
normally. This package will be automatically included in your app when you do,
so you do not need to add it to your `pubspec.yaml`.

However, if you `import` this package to use any of its APIs directly, you
should add it to your `pubspec.yaml` as usual.

For example, you need to import this package directly if you plan to use the
web-only `Widget renderButton()` method.

### Web integration

First, go through the instructions [here](https://developers.google.com/identity/gsi/web/guides/get-google-api-clientid) to create your Google Sign-In OAuth client ID.

On your `web/index.html` file, add the following `meta` tag, somewhere in the
`head` of the document:

```html
<meta name="google-signin-client_id" content="YOUR_GOOGLE_SIGN_IN_OAUTH_CLIENT_ID.apps.googleusercontent.com">
```

For this client to work correctly, the last step is to configure the **Authorized JavaScript origins**, which _identify the domains from which your application can send API requests._ When in local development, this is normally `localhost` and some port.

You can do this by:

1. Going to the [Credentials page](https://console.developers.google.com/apis/credentials).
2. Clicking "Edit" in the OAuth 2.0 Web application client that you created above.
3. Adding the URIs you want to the **Authorized JavaScript origins**.

For local development, you must add two `localhost` entries:

* `http://localhost` and
* `http://localhost:7357` (or any port that is free in your machine)

#### Starting flutter in http://localhost:7357

Normally `flutter run` starts in a random port. In the case where you need to deal with authentication like the above, that's not the most appropriate behavior.

You can tell `flutter run` to listen for requests in a specific host and port with the following:

```sh
flutter run -d chrome --web-hostname localhost --web-port 7357
```

### Other APIs

Read the rest of the instructions if you need to add extra APIs (like Google People API).

### Using the plugin

See the [**Usage** instructions of `package:google_sign_in`](https://pub.dev/packages/google_sign_in#usage)

Note that the **`serverClientId` parameter of the `GoogleSignIn` constructor is not supported on Web.**

## Example

Find the example wiring in the [Google sign-in example application](https://github.com/flutter/packages/blob/main/packages/google_sign_in/google_sign_in/example/lib/main.dart).

## API details

See [google_sign_in.dart](https://github.com/flutter/packages/blob/main/packages/google_sign_in/google_sign_in/lib/google_sign_in.dart) for more API details.

## Contributions and Testing

Tests are crucial for contributions to this package. All new contributions should be reasonably tested.

**Check the [`test/README.md` file](https://github.com/flutter/packages/blob/main/packages/google_sign_in/google_sign_in_web/test/README.md)** for more information on how to run tests on this package.

Contributions to this package are welcome. Read the [Contributing to Flutter Plugins](https://github.com/flutter/packages/blob/main/CONTRIBUTING.md) guide to get started.

## Issues and feedback

Please file [issues](https://github.com/flutter/flutter/issues/new)
to send feedback or report a bug.

**Thank you!**
