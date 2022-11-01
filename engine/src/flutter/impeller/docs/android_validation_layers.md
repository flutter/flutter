# Android Vulkan Validation Layers

This is a quick guide to get Vulkan validation layers support for a Flutter application. This guide assumes that you've created the application with `flutter create`, otherwise the locations might vary.

1. Download the validation layers from this [GitHub](https://github.com/KhronosGroup/Vulkan-ValidationLayers/releases) releases. Typically named `android-binaries-1.3.231.1.zip`.
2. When you unzip the file, you will see: `arm64-v8a  armeabi-v7a  x86  x86_64`
3. Copy these directories to `${FLUTTER_APP}/android/app/src/main/vklibs`. The layout should look similar to:

```
src/main/vklibs/
  arm64-v8a/
    libVkLayer_khronos_validation.so
  armeabi-v7a/
    libVkLayer_khronos_validation.so
  x86/
    libVkLayer_khronos_validation.so
  x86-64/
    libVkLayer_khronos_validation.so
```

4. Add the following line to `${FLUTTER_APP}/android/app/build.gradle`, `android > sourceSets` section: `main.jniLibs.srcDirs += 'src/main/vklibs'`.

5. This should enable Vulkan validation layers on your Android application.
