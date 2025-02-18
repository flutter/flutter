# Android Api and Related versions

## Overview

The most important thing is for any test, project, or app to have compatible versions. 
If versions need to be different then a comment explaining why and what is being evaluated should be included. 
All chosen versions should pass the minimum versions checks defined in [gradle_utils.dart](https://github.com/flutter/flutter/blob/a16c447abcb695b4ca907d59e66dc87f4f7178d3/packages/flutter_tools/lib/src/android/gradle_utils.dart#L63)

## Specifics

- "compileSdk" version should be `flutter.compileSdkVersion` or if a pure android project the highest number that has proven stable and is available in CIPD. 
- "targetSdk" takes human level effort to update. This is by design of the AGP team. The version should be `flutter.targetSdkVersion` or the highest number that has proven stable and is available in cipd. This number may lag behind compile sdk because of the effort to update.
- "AGP" version should be the version set in flutter templates or newer. If the version is intentionally different there should be a comment explaining why.
- "gradle" version should be the version set in flutter templates or newere. If the version is intentionally different there should be a comment explaining why.
- "kotlin" version should be the version set in flutter templates or newere. If the version is intentionally different there should be a comment explaining why.
