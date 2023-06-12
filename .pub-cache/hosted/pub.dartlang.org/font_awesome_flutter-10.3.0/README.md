# font_awesome_flutter 

[![Flutter Community: font_awesome_flutter](https://fluttercommunity.dev/_github/header/font_awesome_flutter)](https://github.com/fluttercommunity/community)

[![Pub](https://img.shields.io/pub/v/font_awesome_flutter.svg)](https://pub.dartlang.org/packages/font_awesome_flutter)

The *free* [Font Awesome](https://fontawesome.com/icons) Icon pack available 
as set of Flutter Icons - based on font awesome version 6.2.1.

This icon pack includes only the *free* icons offered by Font Awesome out-of-the-box.
If you have purchased the pro icons and want to enable support for them, please see the instructions below.

## Installation

In the `dependencies:` section of your `pubspec.yaml`, add the following line:

```yaml
dependencies:
  font_awesome_flutter: <latest_version>
```

## Usage

```dart
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class MyWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    return IconButton(
      // Use the FaIcon Widget + FontAwesomeIcons class for the IconData
      icon: FaIcon(FontAwesomeIcons.gamepad), 
      onPressed: () { print("Pressed"); }
     );
  }
}
```

### Icon names

Icon names equal those on the [official website](https://fontawesome.com/icons), but are written in lower camel case. If more than one icon style is available for an icon, the style name is used as prefix, except for "regular".
Due to restrictions in dart, icons starting with numbers have those numbers written out.

#### Examples:
| Icon name                                                                             | Code | Style|
|---------------------------------------------------------------------------------------| --- | ---|
| [angle-double-up](https://fontawesome.com/icons/angle-double-up?style=solid)          | `FontAwesomeIcons.angleDoubleUp` | solid _(this icon does not have other free styles)_ |
| [arrow-alt-circle-up](https://fontawesome.com/icons/arrow-alt-circle-up?style=regular) | `FontAwesomeIcons.arrowAltCircleUp` | regular |
| [arrow-alt-circle-up](https://fontawesome.com/icons/arrow-alt-circle-up?style=solid)  |  `FontAwesomeIcons.solidArrowAltCircleUp` | solid |
| [1](https://fontawesome.com/icons/1?style=solid)                                      | `FontAwesomeIcons.solidOne` | solid |

## Example App

View the Flutter app in the `example` directory to see all the available `FontAwesomeIcons`.

## Customizing font awesome flutter

We supply a configurator tool to assist you with common customizations to this package.
All options are interoperable.
By default, if run without arguments and no `icons.json` in `lib/fonts` exists, it updates all icons to the
newest free version of font awesome.

### Setup
To use your custom version, you must first clone [this repository](https://github.com/fluttercommunity/font_awesome_flutter.git)
to a location of your choice and run `flutter pub get` inside. This installs all dependencies.

The configurator is located in the `util` folder and can be started by running `configurator.bat` on Windows, or 
`./configurator.sh` on linux and mac. All following examples use the `.sh` version, but work same for `.bat`.
(If on windows, omit the `./` or replace it with `.\`.)
An overview of available options can be viewed with `./configurator.sh --help`.

To use your customized version in an app, go to the app's `pubspec.yaml` and add a dependency for
`font_awesome_flutter: '>= 4.7.0'`. Then override the dependency's location:
```yaml
dependencies:
  font_awesome_flutter: '>= 4.7.0'
  ...
  
dependency_overrides:
  font_awesome_flutter:
    path: path/to/your/font_awesome_flutter
  ...
```

### Enable pro icons
:exclamation: By importing pro icons you acknowledge that it is your obligation
to keep these files private. This includes **not** uploading your package to
a public github repository or other public file sharing services.

* Go to the location of your custom font_awesome_flutter version (see [setup](#setup))
* Download the web version of font awesome pro and open it
* Move **all** `.ttf` files from the `webfonts` directory and `icons.json` from `metadata` to
  `path/to/your/font_awesome_flutter/lib/fonts`. Replace existing files.
* Run the configurator. It should say "Custom icons.json found"

It may be required to run `flutter clean` in apps who use this version for changes to appear.

### Excluding styles
One or more styles can be excluded from all generation processes by passing them with the `--exclude` option:
```
$ ./configurator.sh --exclude solid
$ ./configurator.sh --exclude solid,brands
```

See the [optimizations](#what-about-file-size-and-ram-usage) and [dynamic icon retrieval by name](#retrieve-icons-dynamically-by-their-name-or-css-class)
sections for more information as to why it makes sense for your app.

### Retrieve icons dynamically by their name or css class
Probably the most requested feature after support for pro icons is the ability to retrieve an icon by their name.
This was previously not possible, because a mapping from name to icon would break all
[discussed optimizations](#what-about-file-size-and-ram-usage). Please bear in mind that this is still the case.
As all icons could theoretically be requested, none can be removed by flutter. It is strongly advised to only use this
option in conjunction with [a limited set of styles](#excluding-styles) and with as few of them as possible. You may
need to build your app with the `--no-tree-shake-icons` flag for it to succeed.

Using the new configurator tool, this is now an optional feature. Run the tool with the `--dynamic` flag to generate...
```
$ ./configurator.sh --dynamic
```
...and the following import to use the map. For normal icons, use `faIconMapping` with a key of this format:
'style icon-name'.
```dart
import 'package:font_awesome_flutter/name_icon_mapping.dart';

...
    FaIcon(
      icon: faIconMapping['solid abacus'],
    );
...
```

To exclude unused styles combine the configurator options:
```
$ ./configurator.sh --dynamic --exclude solid
```


A common use case also includes fetching css classes from a server. The utility function `getIconFromCss()` takes a
string of classes and returns the icon which would be shown by a browser:
```dart
getIconFromCss('far custom-class fa-abacus'); // returns the abacus icon in regular style. custom-class is ignored
```

## Duotone icons

Duotone support has been discontinued after font awesome changed the way they lay out the icon glyphs inside the font's
file. The new way using ligatures is not supported by flutter at the moment.

For more information on why duotone icon support was discontinued, see
[this comment](https://github.com/fluttercommunity/font_awesome_flutter/issues/192#issuecomment-1073003668).

## FAQ

<details>
  <summary><h3>Why aren't the icons aligned properly or why are the icons being cut off?</h3></summary>
  Please use the `FaIcon` widget provided by the library instead of the `Icon`
  widget provided by Flutter. The `Icon` widget assumes all icons are square, but
  many Font Awesome Icons are not.
</details>

<details>
  <summary><h3>What about file size and ram usage</h3></summary>
  This package has been written in a way so that it only uses the minimum amount of resources required.

  All links (eg. `FontAwesomeIcons.abacus`) to unused icons will be removed automatically, which means only required icon
  definitions are loaded into ram.

  Flutter 1.22 added icon tree shaking. This means unused icon "images" will be removed as well. However, this only
  applies to styles of which at least one icon has been used. Assuming only icons of style "regular" are being used,
  "regular" will be minified to only include the used icons and "solid" and "brands" will stay in their raw, complete
  form. This issue is being [tracked over in the flutter repository](https://github.com/flutter/flutter/issues/64106).

  However, using the configurator, you can easily exclude styles from the package. For more information, see
  [customizing font awesome flutter](#customizing-font-awesome-flutter)
</details>

<details>
  <summary><h3>Why aren't the icons showing up on Mobile devices?</h3></summary>
  If you're not seeing any icons at all, sometimes it means that Flutter has a cached version of the app on device and
  hasn't pushed the new fonts. I've run into that as well a few times...

  Please try:

  1. Stopping the app
  2. Running `flutter clean` in your app directory
  3. Deleting the app from your simulator / emulator / device
  4. Rebuild & Deploy the app.
</details>

<details>
  <summary><h3>Why aren't the icons showing up on Web?</h3></summary>
  Most likely, the fonts were not correctly added to the `FontManifest.json`.
  Note: older versions of Flutter did not properly package non-Material fonts
  in the `FontManifest.json` during the build step, but that issue has been
  resolved and this shouldn't be much of a problem these days.

  Please ensure you are using `Flutter 1.14.6 beta` or newer! 
</details>

<details>
  <summary><h3>Why does mac/linux not run the configurator?</h3></summary>
  This is most probably due to missing file permissions. Downloaded scripts cannot be executed by default.
  
  Either give the execute permission to `util/configurator.sh` with `$ chmod +x configurator.sh` or run the commands by prepending an `sh`:
  
  `$ sh ./configurator.sh`
</details>
