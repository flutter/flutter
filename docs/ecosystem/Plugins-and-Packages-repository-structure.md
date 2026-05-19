This provides an overview of the structure of the flutter/packages repository.

# Packages

Most packages are located in `packages`. A few which are derived heavily from third-party code are instead in `third_party/packages/`.

## Plugins

Plugins in flutter/packages uses the federated plugin model. If you are not familiar with federated plugins, start with reading [the federated plugin overview](https://docs.flutter.dev/development/packages-and-plugins/developing-packages#federated-plugins) to understand the terms below.

All plugins are located in the `packages/` directory. Almost all plugins have the following layout:
- `some_plugin/` - A directory containing the individual packages of the federated plugin:
  - `some_plugin/` - The app-facing package
  - `some_plugin_platform_interface/` - The platform interface
  - `some_plugin_android/`, `some_plugin_ios/`, `some_plugin_web/`, `some_plugin_windows/`, `some_plugin_macos/`, and/or `some_plugin_linux/` - The individual platform implementations, as applicable
    - In some special cases, implementation packages have different names; examples include `webview_flutter_wkwebview` and `in_app_purchase_storekit`. These would normally be named `_ios`, but have more generic names because they include (or expected to include in the future) macOS implementations. Sharing a package allows sharing the code, as the OS APIs are largely the same across the two platforms.

This layout reflects the goal of having all multi-platform plugins in flutter/packages being fully federated. (While this is not strictly necessary, as all packages are being maintained by the Flutter team, using a fully federated structure ensures that we are testing the federated model and finding issues and areas for improvement specific to federation.)

### Android Specifics

#### Gradle structure

`package/example/android/settings.gradle` imports the flutter tooling, includes the app directory (same as `flutter create` projects) additionally it configures GoogleCloudPlatform/artifact-registry-maven-tools for use in CI.

This repo has a GCP instance that mirrors dependencies available from `google()` and `mavenCentral()` used by CI (or Googlers). This gives us redundant uptime for dependency availability.

Using the specific google hosted cache is not intended for contributors outside of CI. We protect that execution with an environment variable `ARTIFACT_HUB_REPOSITORY` to ensure that by default users do not see rejected cloud credentials or errors in builds. Contributors could setup an artifact repository and set the environment variable to point to a hosted repository but that is practically not worth it for almost all contributors.

Googlers can debug locally by setting `ARTIFACT_HUB_REPOSITORY` to the valid artifact hub value and authenticating with GCP. To authenticate run `gcloud auth application-default login`. To find artifact hub url use `<url>` section of go/artifact-hub#maven or inspect the value on CI servers. CI uses a service account for billing. That is defined in go/artifact-hub-service-account (Googler access only).

## Useful links for debugging

- https://github.com/GoogleCloudPlatform/artifact-registry-maven-tools/blob/master/README.md
- https://docs.gradle.org/current/userguide/declaring_repositories.html
- https://docs.gradle.org/current/userguide/viewing_debugging_dependencies.html

Command to force refresh of dependencies `./gradlew app:dependencies --configuration <SOME_TASK> --refresh-dependencies`

### Unfederated plugins

A few plugins are inherently single-platform (for example, `flutter_plugin_android_lifecycle`), and so are not federated. For those plugins the structure is:

- `some_plugin/` - A plugin containing the app-facing API and its implementation

# Tools

`script/tool/` contains the tooling used to manage tasks across all packages in the repository. See [its README](https://github.com/flutter/packages/blob/main/script/tool/README.md) for more information.
