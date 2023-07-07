## Local Development

### With Flutter tools (recommended)

1. Fork and download the [Flutter repo](https://github.com/flutter/flutter). Detailed instructions can be found [here](https://github.com/flutter/flutter/wiki/Setting-up-the-Framework-development-environment).
2. Add an alias to your `.bashrc`/`.zshrc` for Flutter Tools:
```
alias flutter_tools='/YOUR_PATH/flutter/bin/dart --observe /YOUR_PATH/flutter/packages/flutter_tools/bin/flutter_tools.dart'
```

> **Explanation:**
> * `/PATH_TO_YOUR_FLUTTER_REPO/bin/dart`: This is the path to the Dart SDK that Flutter Tools uses
> * `--observe`: This flag specifies we want a Dart DevTools URL for debugging
> * `/PATH_TO_YOUR_FLUTTER_REPO/packages/flutter_tools/bin/flutter_tools.dart`: This is the path to Flutter Tools itself
>
> *More details can be found at the Flutter Tools [README](https://github.com/flutter/flutter/blob/master/packages/flutter_tools/README.md).*
3. In your Flutter Tools [`pubspec.yaml`](https://github.com/flutter/flutter/blob/master/packages/flutter_tools/pubspec.yaml), change the DWDS dependency to point to your local DWDS: 
```
  dwds:
    path: /YOUR_PATH/dwds
```
4. Choose a Flutter app to run (eg, the [old](https://github.com/flutter/flutter/tree/master/dev/integration_tests/flutter_gallery) or [new](https://github.com/flutter/gallery) Flutter Gallery apps).
5. From the Flutter app repo, run your local Flutter Tools with alias you defined in step #2:
```
flutter_tools run -d chrome
```
6. Open up the **first** Dart DevTools URL you see printed:
```
...
The Dart VM service is listening on http://127.0.0.1:8181/ajXIPMLq6iI=/
The Dart DevTools debugger and profiler is available at: http://127.0.0.1:8181/ajXIPMLq6iI=/devtools/#/?uri=ws%3A%2F%2F127.0.0.1%3A8181%2FajXIPMLq6iI%3D%2Fws   <== THIS ONE!
Launching lib/main.dart on Chrome in debug mode...
...
```
7. The Dart DevTools you open is connected to your Flutter Tools, but because of the path dependency added in step #3, you can debug your local DWDS as well.

### With WebDev

1. In the `/webdev` directory, run `pub global activate --source path webdev` (this only needs to be run once)
2. Uncomment the dwds dependency override in `/webdev/webdev/pubspec.yaml`, then run `dart run build_runner build` from `/webdev/webdev` directory
    * *Note: You will have to comment and build, and then uncomment and build, each time you need to pick up new changes*
2. From `/webdev/example`, run `webdev serve --debug --verbose` (Note: all options can be found by running `webdev help serve`)
3. Type opt/alt-d in the browser. This is required to start the VM.
4. [OPTIONAL] If you need to connect a locally running DevTools (instructions for running [here](https://github.com/flutter/devtools/blob/master/CONTRIBUTING.md )), then close the DevTools that automatically opened in the previous step. Copy and paste the debug URI (should be logged in your terminal) into the DevTools connection box.

### Note:
If you get this error:

`The /webdev/webdev/pubspec.yaml file has changed since the /webdev/webdev/pubspec.lock file was generated, please run "dart pub get" again.` 

You need to do the following:

* `rm webdev/webdev/pubspec.lock`
* Then, from `/webdev/webdev` run `dart pub get`

## Changes required when submitting a PR
* Make sure you update the `CHANGELOG.md` with a description of the change
* If DWDS / Webdev was just released, then you will need to update the version in the `CHANGELOG`, and the `pubspec.yaml` file as well (eg, https://github.com/dart-lang/webdev/pull/1462)
* For any directories you’ve touched, `run dart run build_runner` build to check in the any file that should be built. This will make sure the integration tests are run against the built files. 

## Release steps 

### Step 1: Roll DWDS into g3 
> *NOTE: You must be a Googler to do this step. If you are not, please ask someone for help.*
* See directions at: go/roll-dwds
* Wait a few days after rolling into g3 before continuing to step 2. We do so to have time to catch new bugs internally before publishing externally. Look for any new exceptions at go/ddt-web-dashboard

## Step 2: Publish DWDS to pub
* Make sure you are on the Dart stable SDK version (check with `dart --version`)
* From each of the subdirectories (`/dwds`, `/frontend_server_client`, `/frontend_server_common`, and `/webdev`) update dependencies with `dart pub upgrade`
* Update the version number in `dwds/pubspec.yaml` and `dwds/CHANGELOG.md`
* From `/dwds` run `dart run build_runner build`, this will build and update the version in `/dwds/lib/src/version.dart`
* Submit a PR with those changes (example PR: https://github.com/dart-lang/webdev/pull/1456). *Note: Ensure your PR doesn’t have any dependency overrides.*
* Once the PR is submitted, pull from master and `run dart pub publish`
* Finally, go to https://github.com/dart-lang/webdev/releases and create a new release, eg https://github.com/dart-lang/webdev/releases/tag/dwds-v12.0.0. You might need to delete some of the content of the autogenerated notes. 
> *Note: To have the right permissions for publishing, you need to be invited to the tools.dart.dev. A member of the Dart team should be able to add you at https://pub.dev/publishers/tools.dart.dev/admin.* 

## Step 3: Publish Webdev to pub 
> *Note: DWDS is a dependency of Webdev, which is why DWDS must be published before Webdev can be published.* 
* Make sure you are on the Dart stable SDK version (check with `dart --version`)
* Update the DWDS version in `/webdev/pubspec.yaml` to match the newly released DWDS version, and update the Webdev version to the new version number. Also, comment out the dependency_override  so that Webdev is now depending on the version of DWDS on pub (which should have just been published) instead of the local version. 
* Update `/webdev/CHANGELOG.md` to match the new webdev version
* From `/webdev`, run `dart pub upgrade`
* From `/webdev` run `dart run build_runner build`, this will build and update the version in `webdev/lib/src/version.dart`
* Submit a PR with those changes (example PR: https://github.com/dart-lang/webdev/pull/1498)
* Once the PR is submitted, pull from master and run `dart pub publish` 
* Finally, go to https://github.com/dart-lang/webdev/releases and create a new release, eg https://github.com/dart-lang/webdev/releases/tag/webdev-v2.7.8. You might need to delete some of the content of the autogenerated notes. 

## Whenever the Dart SDK is updated 
Whenever Dart SDK is updated to a new major or minor version (~every 2 weeks), any PR submissions to Webdev are blocked by the min_sdk_test until the Dart min SDK constraint is updated. Therefore, whenever your PR gets blocked by the test, you need to:
1. Create a new PR that updates all the min SDK constraints to the new version, eg: https://github.com/dart-lang/webdev/pull/1463.
2. From each of the subdirectories (`/dwds`, `/frontend_server_client`, `/frontend_server_common`, and `/webdev`) update dependencies with `dart pub upgrade`
3. Make sure to update the `CHANGELOG` to include the new version number 
4. Submit your PR. At this point, you technically will be able to submit the PR that was blocked, but the point of the test is to make sure that DWDS and Webdev get released after a Dart stable release. Therefore, follow the steps above to publish DWDS and Webdev. 
> ### Why is this necessary?
> This is so that we don’t need to support older versions of the SDK and test against them, therefore every time the Dart SDK is bumped to a new major or minor version, DWDS and Webdev’s min Dart SDK constraint needs to to be changed and DWDS and Webdev have to be released. 
> Since DWDS is dependent on DDC and the runtime API, if we had a looser min constraint we would need to run tests for all earlier stable releases of the SDK that match the constraint, which would have differences in functionality and therefore need different tests.
