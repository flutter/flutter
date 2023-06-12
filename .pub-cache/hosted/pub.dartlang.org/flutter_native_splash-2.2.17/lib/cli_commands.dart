/// ## Flutter Native Splash
///
/// This is the main entry point for the Flutter Native Splash package.
library flutter_native_splash_cli;

import 'package:html/parser.dart' as html_parser;
import 'package:image/image.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:universal_io/io.dart';
import 'package:xml/xml.dart';
import 'package:yaml/yaml.dart';

part 'android.dart';
part 'constants.dart';
part 'flavor_helper.dart';
part 'ios.dart';
part 'templates.dart';
part 'web.dart';

late _FlavorHelper _flavorHelper;

/// Create splash screens for Android and iOS
void createSplash({
  required String? path,
  required String? flavor,
}) {
  if (flavor != null) {
    print(
      '''
╔════════════════════════════════════════════════════════════════════════════╗
║                              Flavor detected!                              ║
╠════════════════════════════════════════════════════════════════════════════╣
║ Setting up the $flavor flavor.                                             ║
╚════════════════════════════════════════════════════════════════════════════╝
''',
    );
  }

  final config = getConfig(configFile: path, flavor: flavor);
  createSplashByConfig(config);
}

/// Create splash screens for Android and iOS based on a config argument
void createSplashByConfig(Map<String, dynamic> config) {
  // Preparing all the data for later usage
  final String? image =
      _checkImageExists(config: config, parameter: _Parameter.image);
  final String? imageAndroid =
      _checkImageExists(config: config, parameter: _Parameter.imageAndroid);
  final String? imageIos =
      _checkImageExists(config: config, parameter: _Parameter.imageIos);
  final String? imageWeb =
      _checkImageExists(config: config, parameter: _Parameter.imageWeb);
  final String? darkImage =
      _checkImageExists(config: config, parameter: _Parameter.darkImage);
  final String? darkImageAndroid =
      _checkImageExists(config: config, parameter: _Parameter.darkImageAndroid);
  final String? darkImageIos =
      _checkImageExists(config: config, parameter: _Parameter.darkImageIos);
  final String? darkImageWeb =
      _checkImageExists(config: config, parameter: _Parameter.darkImageWeb);
  final String? brandingImage =
      _checkImageExists(config: config, parameter: _Parameter.brandingImage);
  final String? brandingImageAndroid = _checkImageExists(
      config: config, parameter: _Parameter.brandingImageAndroid);
  final String? brandingImageIos =
      _checkImageExists(config: config, parameter: _Parameter.brandingImageIos);
  final String? brandingImageWeb =
      _checkImageExists(config: config, parameter: _Parameter.brandingImageWeb);
  final String? brandingDarkImage = _checkImageExists(
      config: config, parameter: _Parameter.brandingDarkImage);
  final String? brandingDarkImageAndroid = _checkImageExists(
      config: config, parameter: _Parameter.brandingDarkImageAndroid);
  final String? brandingDarkImageIos = _checkImageExists(
      config: config, parameter: _Parameter.brandingDarkImageIos);
  final String? brandingDarkImageWeb = _checkImageExists(
      config: config, parameter: _Parameter.brandingDarkImageWeb);
  final String? color = parseColor(config[_Parameter.color]);
  final String? colorAndroid = parseColor(config[_Parameter.colorAndroid]);
  final String? colorIos = parseColor(config[_Parameter.colorIos]);
  final String? colorWeb = parseColor(config[_Parameter.colorWeb]);
  final String? darkColor = parseColor(config[_Parameter.darkColor]);
  final String? darkColorAndroid =
      parseColor(config[_Parameter.darkColorAndroid]);
  final String? darkColorIos = parseColor(config[_Parameter.darkColorIos]);
  final String? darkColorWeb = parseColor(config[_Parameter.darkColorWeb]);
  final String? backgroundImage =
      _checkImageExists(config: config, parameter: _Parameter.backgroundImage);
  final String? backgroundImageAndroid = _checkImageExists(
      config: config, parameter: _Parameter.backgroundImageAndroid);
  final String? backgroundImageIos = _checkImageExists(
      config: config, parameter: _Parameter.backgroundImageIos);
  final String? backgroundImageWeb = _checkImageExists(
      config: config, parameter: _Parameter.backgroundImageWeb);
  final String? darkBackgroundImage = _checkImageExists(
      config: config, parameter: _Parameter.darkBackgroundImage);
  final String? darkBackgroundImageAndroid = _checkImageExists(
    config: config,
    parameter: _Parameter.darkBackgroundImageAndroid,
  );
  final String? darkBackgroundImageIos = _checkImageExists(
      config: config, parameter: _Parameter.darkBackgroundImageIos);
  final String? darkBackgroundImageWeb = _checkImageExists(
      config: config, parameter: _Parameter.darkBackgroundImageWeb);

  final plistFiles = config[_Parameter.plistFiles] as List<String>?;
  String gravity = (config['fill'] as bool? ?? false) ? 'fill' : 'center';
  if (config[_Parameter.gravity] != null) {
    gravity = config[_Parameter.gravity] as String;
  }
  final String? androidScreenOrientation =
      config[_Parameter.androidScreenOrientation] as String?;
  final brandingGravity =
      config[_Parameter.brandingGravity] as String? ?? 'bottom';
  final bool fullscreen = config[_Parameter.fullscreen] as bool? ?? false;
  final String iosContentMode =
      config[_Parameter.iosContentMode] as String? ?? 'center';
  final webImageMode = config[_Parameter.webImageMode] as String? ?? 'center';
  String? android12Image;
  String? android12DarkImage;
  String? android12IconBackgroundColor;
  String? darkAndroid12IconBackgroundColor;
  String? android12Color;
  String? android12DarkColor;
  String? android12BrandingImage;
  String? android12DarkBrandingImage;

  if (config[_Parameter.android12Section] != null) {
    final android12Config =
        config[_Parameter.android12Section] as Map<String, dynamic>;
    android12Image =
        _checkImageExists(config: android12Config, parameter: _Parameter.image);
    android12DarkImage = _checkImageExists(
        config: android12Config, parameter: _Parameter.darkImage);
    android12IconBackgroundColor =
        parseColor(android12Config[_Parameter.iconBackgroundColor]);
    darkAndroid12IconBackgroundColor =
        parseColor(android12Config[_Parameter.iconBackgroundColorDark]);
    android12Color = parseColor(android12Config[_Parameter.color]) ?? color;
    android12DarkColor =
        parseColor(android12Config[_Parameter.darkColor]) ?? darkColor;
    android12BrandingImage = _checkImageExists(
        config: android12Config, parameter: _Parameter.brandingImage);
    android12DarkBrandingImage = _checkImageExists(
        config: android12Config, parameter: _Parameter.brandingDarkImage);
  }

  if (!config.containsKey(_Parameter.android) ||
      config[_Parameter.android] as bool) {
    if (Directory('android').existsSync()) {
      _createAndroidSplash(
        imagePath: imageAndroid ?? image,
        darkImagePath: darkImageAndroid ?? darkImage,
        brandingImagePath: brandingImageAndroid ?? brandingImage,
        brandingDarkImagePath: brandingDarkImageAndroid ?? brandingDarkImage,
        backgroundImage: backgroundImageAndroid ?? backgroundImage,
        darkBackgroundImage: darkBackgroundImageAndroid ?? darkBackgroundImage,
        color: colorAndroid ?? color,
        darkColor: darkColorAndroid ?? darkColor,
        gravity: gravity,
        brandingGravity: brandingGravity,
        fullscreen: fullscreen,
        screenOrientation: androidScreenOrientation,
        android12ImagePath: android12Image,
        android12DarkImagePath: android12DarkImage ?? android12Image,
        android12BackgroundColor: android12Color,
        android12DarkBackgroundColor: android12DarkColor ?? android12Color,
        android12IconBackgroundColor: android12IconBackgroundColor,
        darkAndroid12IconBackgroundColor:
            darkAndroid12IconBackgroundColor ?? android12IconBackgroundColor,
        android12BrandingImagePath: android12BrandingImage,
        android12DarkBrandingImagePath:
            android12DarkBrandingImage ?? android12BrandingImage,
      );
    } else {
      print('Android folder not found, skipping Android splash update...');
    }
  }

  if (!config.containsKey(_Parameter.ios) || config[_Parameter.ios] as bool) {
    if (Directory('ios').existsSync()) {
      _createiOSSplash(
        imagePath: imageIos ?? image,
        darkImagePath: darkImageIos ?? darkImage,
        backgroundImage: backgroundImageIos ?? backgroundImage,
        darkBackgroundImage: darkBackgroundImageIos ?? darkBackgroundImage,
        brandingImagePath: brandingImageIos ?? brandingImage,
        brandingDarkImagePath: brandingDarkImageIos ?? brandingDarkImage,
        color: colorIos ?? color,
        darkColor: darkColorIos ?? darkColor,
        plistFiles: plistFiles,
        iosContentMode: iosContentMode,
        iosBrandingContentMode: brandingGravity,
        fullscreen: fullscreen,
      );
    } else {
      print('iOS folder not found, skipping iOS splash update...');
    }
  }

  if (!config.containsKey(_Parameter.web) || config[_Parameter.web] as bool) {
    if (Directory('web').existsSync()) {
      _createWebSplash(
        imagePath: imageWeb ?? image,
        darkImagePath: darkImageWeb ?? darkImage,
        backgroundImage: backgroundImageWeb ?? backgroundImage,
        darkBackgroundImage: darkBackgroundImageWeb ?? darkBackgroundImage,
        brandingImagePath: brandingImageWeb ?? brandingImage,
        brandingDarkImagePath: brandingDarkImageWeb ?? brandingDarkImage,
        color: colorWeb ?? color,
        darkColor: darkColorWeb ?? darkColor,
        imageMode: webImageMode,
        brandingMode: brandingGravity,
      );
    } else {
      print('Web folder not found, skipping web splash update...');
    }
  }

  const String greet = '''

✅ Native splash complete.
Now go finish building something awesome! 💪 You rock! 🤘🤩
Like the package? Please give it a 👍 here: https://pub.dev/packages/flutter_native_splash
''';

  const String whatsNew = '''
╔════════════════════════════════════════════════════════════════════════════╗
║                                 WHAT IS NEW:                               ║
╠════════════════════════════════════════════════════════════════════════════╣
║ You can now keep the splash screen up while your app initializes!          ║
║ No need for a secondary splash screen anymore. Just use the remove()       ║
║ method to remove the splash screen after your initialization is complete.  ║
║ Check the docs for more info.                                              ║
╚════════════════════════════════════════════════════════════════════════════╝
''';
  print(whatsNew + greet);
}

/// Remove any splash screen by setting the default white splash
void removeSplash({
  required String? path,
  required String? flavor,
}) {
  print("Restoring Flutter's default native splash screen...");
  final config = getConfig(configFile: path, flavor: flavor);

  final removeConfig = <String, dynamic>{
    _Parameter.color: '#ffffff',
    _Parameter.darkColor: '#000000'
  };

  if (config.containsKey(_Parameter.android)) {
    removeConfig[_Parameter.android] = config[_Parameter.android];
  }

  if (config.containsKey(_Parameter.ios)) {
    removeConfig[_Parameter.ios] = config[_Parameter.ios];
  }

  if (config.containsKey(_Parameter.web)) {
    removeConfig[_Parameter.web] = config[_Parameter.web];
  }

  /// Checks if the image that was specified in the config file does exist.
  /// If not the developer will receive an error message and the process will exit.
  if (config.containsKey(_Parameter.plistFiles)) {
    removeConfig[_Parameter.plistFiles] = config[_Parameter.plistFiles];
  }
  createSplashByConfig(removeConfig);
}

String? _checkImageExists({
  required Map<String, dynamic> config,
  required String parameter,
}) {
  final String? image = config[parameter]?.toString();
  if (image != null) {
    if (image.isNotEmpty && !File(image).existsSync()) {
      print(
        'The file "$image" set as the parameter "$parameter" was not found.',
      );
      exit(1);
    }

    // https://github.com/brendan-duncan/image#supported-image-formats
    final List<String> supportedFormats = [
      "png", "apng", // PNG
      "jpg", "jpeg", "jpe", "jfif", // JPEG
      "tga", "tpic", // TGA
      "gif", // GIF
      "ico", // ICO
      "bmp", "dib", // BMP
    ];

    if (!supportedFormats
        .any((format) => p.extension(image).toLowerCase() == ".$format")) {
      print(
        'Unsupported file format: $image  Your image must be in one of the following formats: $supportedFormats',
      );
      exit(1);
    }
  }

  return image == '' ? null : image;
}

void createBackgroundImage({
  required String imageDestination,
  required String imageSource,
}) {
  // Copy will not work if the directory does not exist, so createSync
  // will ensure that the directory exists.
  File(imageDestination).createSync(recursive: true);

  // If source image is not already png, convert it, otherwise just copy it.
  if (p.extension(imageSource).toLowerCase() != '.png') {
    final image = decodeImage(File(imageSource).readAsBytesSync());
    if (image == null) {
      print('$imageSource could not be read');
      exit(1);
    }
    File(imageDestination)
      ..createSync(recursive: true)
      ..writeAsBytesSync(encodePng(image));
  } else {
    File(imageSource).copySync(imageDestination);
  }
}

/// Get config from `pubspec.yaml` or `flutter_native_splash.yaml`
Map<String, dynamic> getConfig({
  required String? configFile,
  required String? flavor,
}) {
  // It is important that the flavor setup occurs as soon as possible.
  // So before we generate anything, we need to setup the flavor (even if it's the default one).
  _flavorHelper = _FlavorHelper(flavor);
  // if `flutter_native_splash.yaml` exists use it as config file, otherwise use `pubspec.yaml`
  String filePath;
  if (configFile != null) {
    if (File(configFile).existsSync()) {
      filePath = configFile;
    } else {
      print('The config file `$configFile` was not found.');
      exit(1);
    }
  } else if (_flavorHelper.flavor != null) {
    filePath = 'flutter_native_splash-${_flavorHelper.flavor}.yaml';
  } else if (File('flutter_native_splash.yaml').existsSync()) {
    filePath = 'flutter_native_splash.yaml';
  } else {
    filePath = 'pubspec.yaml';
  }

  final Map yamlMap = loadYaml(File(filePath).readAsStringSync()) as Map;

  if (yamlMap['flutter_native_splash'] is! Map) {
    throw Exception(
      'Your `$filePath` file does not contain a '
      '`flutter_native_splash` section.',
    );
  }

  // yamlMap has the type YamlMap, which has several unwanted side effects
  return _yamlToMap(yamlMap['flutter_native_splash'] as YamlMap);
}

Map<String, dynamic> _yamlToMap(YamlMap yamlMap) {
  final Map<String, dynamic> map = <String, dynamic>{};
  for (final MapEntry<dynamic, dynamic> entry in yamlMap.entries) {
    if (entry.value is YamlList) {
      final list = <String>[];
      for (final value in entry.value as YamlList) {
        if (value is String) {
          list.add(value);
        }
      }
      map[entry.key as String] = list;
    } else if (entry.value is YamlMap) {
      map[entry.key as String] = _yamlToMap(entry.value as YamlMap);
    } else {
      map[entry.key as String] = entry.value;
    }
  }
  return map;
}

@visibleForTesting
String? parseColor(dynamic color) {
  dynamic colorValue = color;
  if (colorValue is int) colorValue = colorValue.toString().padLeft(6, '0');

  if (colorValue is String) {
    colorValue = colorValue.replaceAll('#', '').replaceAll(' ', '');
    if (colorValue.length == 6) return colorValue;
  }
  if (colorValue == null) return null;

  throw Exception('Invalid color value');
}

class _Parameter {
  static const android = 'android';
  static const android12Section = 'android_12';
  static const androidScreenOrientation = 'android_screen_orientation';
  static const backgroundImage = 'background_image';
  static const backgroundImageAndroid = 'background_android';
  static const backgroundImageIos = 'background_ios';
  static const backgroundImageWeb = 'background_web';
  static const brandingDarkImage = 'branding_dark';
  static const brandingDarkImageAndroid = 'branding_dark_android';
  static const brandingDarkImageIos = 'branding_dark_ios';
  static const brandingDarkImageWeb = 'branding_dark_web';
  static const brandingGravity = 'branding_mode';
  static const brandingImage = 'branding';
  static const brandingImageAndroid = 'branding_android';
  static const brandingImageIos = 'branding_ios';
  static const brandingImageWeb = 'branding_web';
  static const color = 'color';
  static const colorAndroid = "color_android";
  static const colorIos = "color_ios";
  static const colorWeb = "color_web";
  static const darkBackgroundImage = 'background_image_dark';
  static const darkBackgroundImageAndroid = 'background_image_dark_android';
  static const darkBackgroundImageIos = 'background_image_dark_ios';
  static const darkBackgroundImageWeb = 'background_image_dark_web';
  static const darkColor = 'color_dark';
  static const darkColorAndroid = "color_dark_android";
  static const darkColorIos = "color_dark_ios";
  static const darkColorWeb = "color_dark_web";
  static const darkImage = 'image_dark';
  static const darkImageAndroid = 'image_dark_android';
  static const darkImageIos = 'image_dark_ios';
  static const darkImageWeb = 'image_dark_web';
  static const fullscreen = 'fullscreen';
  static const gravity = 'android_gravity';
  static const iconBackgroundColor = 'icon_background_color';
  static const iconBackgroundColorDark = 'icon_background_color_dark';
  static const image = 'image';
  static const imageAndroid = 'image_android';
  static const imageIos = 'image_ios';
  static const imageWeb = 'image_web';
  static const ios = 'ios';
  static const iosContentMode = 'ios_content_mode';
  static const plistFiles = 'info_plist_files';
  static const web = 'web';
  static const webImageMode = 'web_image_mode';
}
