# Android Api and Related versions

Picking the full suite of android versions can be difficult if you are not a full time android developer. 
This document is for contributors to understand what versions of common android tooling should be used in the flutter/flutter codebase. 

## Overview

**The most important thing is for any test, project, or app to have compatible versions. **

If versions need to be different then a comment explaining why and what is being evaluated should be included. 
All chosen versions should pass the minimum versions checks defined in [DependencyVersionChecker](https://github.com/flutter/flutter/blob/master/packages/flutter_tools/gradle/src/main/kotlin/DependencyVersionChecker.kt) 

If the versions chosen are not known by [gradle_utils.dart](https://github.com/flutter/flutter/blob/a16c447abcb695b4ca907d59e66dc87f4f7178d3/packages/flutter_tools/lib/src/android/gradle_utils.dart#L63) then update gradle_utils.dart. 

## Specifics

- "compileSdk" version should be `flutter.compileSdkVersion` or if a pure android project the highest number that has proven stable and is available in CIPD. 
- "targetSdk" takes human level effort to update. This is by design of the AGP team. The version should be `flutter.targetSdkVersion` or the highest number that has proven stable and is available in cipd. This number may lag behind compile sdk because of the effort to update.
- "AGP" version should be the version set in flutter templates or newer. If the version is intentionally different there should be a comment explaining why.
- "gradle" version should be the version set in flutter templates or newere. If the version is intentionally different there should be a comment explaining why.
- "kotlin" version should be the version set in flutter templates or newere. If the version is intentionally different there should be a comment explaining why.

### compileSdk 

Must be higher then or equal to `targetSdk`. 
Should be `compileSdk` instead of `compileSdkVersion`. 
Should be the max value available in CIPD if not `flutter.compileSdkVersion`

```
// OK
android {
  compileSdk flutter.compileSdkVersion
}
```

```
// OK if flutter.compileSdkVersion is not available like in an add to app example. 
android {
  compileSdk 35 
}
```

```
// NOT OK 
android {
  compileSdk 28
}
```

### targetSdk 

Must be higher then or equal to `minSdk`. 
Should be `targetSdk` instead of `targetSdkVersion`.

```
// OK
defaultConfig {
  targetSdk flutter.targetSdkVersion
}
```

```
// OK if flutter.compileSdkVersion is not available like in an add to app example. 
defaultConfig {
  targetSdk 35 
}
```

```
// NOT OK 
defaultConfig {
  targetSdk 28
}
```

### AGP

AKA `com.android.application`, `com.android.tools.build:gradle` `com.android.library`


```
// OK 
dependencies {
    classpath "com.android.tools.build:gradle:8.8.1"
}
```

```
// OK 
dependencies {
    // Testing backwards compatability of feature XYZ
    classpath "com.android.tools.build:gradle:7.5.2"
}
```

### gradle 

Gradle versions are the least likley to break across minor version updates. 

```
// OK 
distributionUrl=https\://services.gradle.org/distributions/gradle-8.12.1-bin.zip
```

### kotlin 

Changing kotlin versions is most likley to have an issue with another dependency. 

```
// Ok
ext.kotlin_version = "1.7.10"
...
classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
```

