[![pub package](https://img.shields.io/pub/v/frontend_server_client.svg)](https://pub.dev/packages/frontend_server_client)
[![package publisher](https://img.shields.io/pub/publisher/frontend_server_client.svg)](https://pub.dev/packages/frontend_server_client/publisher)

This package provides a client interface around the frontend_server compiler
which ships with the Dart SDK.

## SDK Versioning Policy

This package keeps a relatively tight version constraint on the SDK to allow
for breaking changes in the frontend_server binary itself.

Specifically, releases of this package will have an upper bound of less than
the next _minor_ (middle) version number of the latest stable SDK. There are no
requirements for the lower bound (other than the package must pass tests on
that SDK).

The effect of this policy is that breaking changes will be allowed to the
frontend_server binary, but only in _minor_ SDK version releases.

**Note**: This also means that when a new stable SDK is released, this package
will also need a new version published on pub before users can get a valid
version solve.

### Working with dev SDK releases

By default when you do a pub get/upgrade, a constraint like `<2.9.0` will
actually allow dev releases of `2.9.0` if the current SDK is a dev release. It
emits a warning when it does this, but will happily alow it.

* This means that we don't have to publish versions that explicitly allow dev
  releases. We will be notified of breakages by our bots if a dev release does
  break us, and can release a patch.

If we need to depend on some new feature from a dev release, the min sdk
constraint should be bumped to that version but the max sdk constraint should
_not_ be changed. So for example we will have constraints like
`>=2.9.0-dev.1 <2.9.0`.
