# Flutter Launcher Icons

[![Flutter Community: flutter_launcher_icons](https://fluttercommunity.dev/_github/header/flutter_launcher_icons)](https://github.com/fluttercommunity/community)

[![Build Status](https://travis-ci.org/fluttercommunity/flutter_launcher_icons.svg?branch=master)](https://travis-ci.org/MarkOSullivan94/flutter_launcher_icons) [![pub package](https://img.shields.io/pub/v/flutter_launcher_icons.svg)](https://pub.dartlang.org/packages/flutter_launcher_icons)

A command-line tool which simplifies the task of updating your Flutter app's launcher icon. Fully flexible, allowing you to choose what platform you wish to update the launcher icon for and if you want, the option to keep your old launcher icon in case you want to revert back sometime in the future.

## :book: Guide

### 1. Setup the config file

Add your Flutter Launcher Icons configuration to your `pubspec.yaml` or create a new config file called `flutter_launcher_icons.yaml`.
An example is shown below. More complex examples [can be found in the example projects](https://github.com/fluttercommunity/flutter_launcher_icons/tree/master/example).

```yaml
dev_dependencies:
  flutter_launcher_icons: "^0.11.0"

flutter_icons:
  android: "launcher_icon"
  ios: true
  image_path: "assets/icon/icon.png"
  min_sdk_android: 21 # android min sdk min:16, default 21
  web:
    generate: true
    image_path: "path/to/image.png"
    background_color: "#hexcode"
    theme_color: "#hexcode"
  windows:
    generate: true
    image_path: "path/to/image.png"
    icon_size: 48 # min:48, max:256, default: 48
  macos:
    generate: true
    image_path: "path/to/image.png"
```

If you name your configuration file something other than `flutter_launcher_icons.yaml` or `pubspec.yaml` you will need to specify
the name of the file when running the package.

```shell
flutter pub get
flutter pub run flutter_launcher_icons -f <your config file name here>
```

Note: If you are not using the existing `pubspec.yaml` ensure that your config file is located in the same directory as it.

### 2. Run the package

After setting up the configuration, all that is left to do is run the package.

```shell
flutter pub get
flutter pub run flutter_launcher_icons
```

If you encounter any issues [please report them here](https://github.com/fluttercommunity/flutter_launcher_icons/issues).

In the above configuration, the package is setup to replace the existing launcher icons in both the Android and iOS project
with the icon located in the image path specified above and given the name "launcher_icon" in the Android project and "Example-Icon" in the iOS project.

## :mag: Attributes

Shown below is the full list of attributes which you can specify within your Flutter Launcher Icons configuration.

### Global

- `image_path`: The location of the icon image file which you want to use as the app launcher icon.

### Android

- `android`
  - `true`: Override the default existing Flutter launcher icon for the platform specified
  - `false`: Ignore making launcher icons for this platform
  - `icon/path/here.png`: This will generate a new launcher icons for the platform with the name you specify, without removing the old default existing Flutter launcher icon.
- `image_path`: The location of the icon image file which you want to use as the app launcher icon
- `image_path_android`: The location of the icon image file specific for Android platform (optional - if not defined then the image_path is used)
- `min_sdk_android`: Specify android min sdk value
**The next two attributes are only used when generating Android launcher icon**

- `adaptive_icon_background`: The color (E.g. `"#ffffff"`) or image asset (E.g. `"assets/images/christmas-background.png"`) which will
be used to fill out the background of the adaptive icon.
- `adaptive_icon_foreground`: The image asset which will be used for the icon foreground of the adaptive icon
*Note: Adaptive Icons will only be generated when both adaptive_icon_background and adaptive_icon_foreground are specified. (the image_path is not automatically taken as foreground)*

### IOS

- `ios`
  - `true`: Override the default existing Flutter launcher icon for the platform specified
  - `false`: Ignore making launcher icons for this platform
  - `icon/path/here.png`: This will generate a new launcher icons for the platform with the name you specify, without removing the old default existing Flutter launcher icon.
- `image_path_ios`: The location of the icon image file specific for iOS platform (optional - if not defined then the image_path is used)
- `remove_alpha_ios`: Removes alpha channel for IOS icons

### Web

- `web`: Add web related configs
  - `generate`: Specifies weather to generate icons for this platform or not
  - `image_path`: Path to web icon.png
  - `background_color`: Updates *background_color* in `web/manifest.json`
  - `theme_color`: Updates *theme_color* in `web/manifest.json`

### Windows

- `windows`: Add Windows related configs
  - `generate`: Specifies weather to generate icons for Windows platform or not
  - `image_path`: Path to web icon.png
  - `icon_size`: Windows app icon size. Icon size should be within this constrains *48<=icon_size<=256, defaults to 48*
  
### MacOS

- `macos`: Add MacOS related configs
  - `generate`: Specifies weather to generate icons for MacOS platform or not
  - `image_path`: Path to macos icon.png file

*Note: iOS icons should [fill the entire image](https://stackoverflow.com/questions/26014461/black-border-on-my-ios-icon) and not contain transparent borders.*

## Flavor support

Create a Flutter Launcher Icons configuration file for your flavor. The config file is called `flutter_launcher_icons-<flavor>.yaml` by replacing `<flavor>` by the name of your desired flavor.

The configuration file format is the same.

An example project with flavor support enabled [has been added to the examples](https://github.com/fluttercommunity/flutter_launcher_icons/tree/master/example/flavors).

## :question: Troubleshooting

Listed a couple common issues with solutions for them

### Generated icon color is different from the original icon

Caused by an update to the image dependency which is used by Flutter Launcher Icons.

```txt
Use #AARRGGBB for colors instead of ##AABBGGRR, to be compatible with Flutter image class.
```

[Related issue](https://github.com/fluttercommunity/flutter_launcher_icons/issues/98)

### Image foreground is too big / too small

For best results try and use a foreground image which has padding much like [the one in the example](https://github.com/fluttercommunity/flutter_launcher_icons/blob/master/example/default_example/assets/images/icon-foreground-432x432.png).

[Related issue](https://github.com/fluttercommunity/flutter_launcher_icons/issues/96)

### Dependency incompatible

You may receive a message similar to the following

```log
Because flutter_launcher_icons >=0.9.0 depends on args 2.0.0 and flutter_native_splash 1.2.0 depends on args ^2.1.1, flutter_launcher_icons >=0.9.0 is incompatible with flutter_native_splash 1.2.0.
And because no versions of flutter_native_splash match >1.2.0 <2.0.0, flutter_launcher_icons >=0.9.0 is incompatible with flutter_native_splash ^1.2.0.
So, because enstack depends on both flutter_native_splash ^1.2.0 and flutter_launcher_icons ^0.9.0, version solving failed.
pub get failed (1; So, because enstack depends on both flutter_native_splash ^1.2.0 and flutter_launcher_icons ^0.9.0, version solving failed.)
```

For a quick fix, you can temporarily override all references to a dependency: [See here for an example](https://github.com/fluttercommunity/flutter_launcher_icons/issues/262#issuecomment-879872076).

## :eyes: Example

[![Video Example](https://i.imgur.com/R28hqdz.png)](https://www.youtube.com/watch?v=RjNAxwcP3Tc)

Note: This is showing a very old version (v0.0.5)

### Special thanks

- Thanks to Brendan Duncan for the underlying [image package](https://pub.dev/packages/image) to transform the icons.
- Big thank you to all the contributors to the project. Every PR / reported issue is greatly appreciated!
