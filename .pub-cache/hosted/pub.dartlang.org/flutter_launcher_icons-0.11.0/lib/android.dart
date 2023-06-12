import 'dart:io';

import 'package:flutter_launcher_icons/constants.dart';
import 'package:flutter_launcher_icons/constants.dart' as constants;
import 'package:flutter_launcher_icons/custom_exceptions.dart';
import 'package:flutter_launcher_icons/flutter_launcher_icons_config.dart';
import 'package:flutter_launcher_icons/utils.dart';
import 'package:flutter_launcher_icons/xml_templates.dart' as xml_template;
import 'package:image/image.dart';
import 'package:path/path.dart' as path;

class AndroidIconTemplate {
  AndroidIconTemplate({required this.size, required this.directoryName});

  final String directoryName;
  final int size;
}

final List<AndroidIconTemplate> adaptiveForegroundIcons = <AndroidIconTemplate>[
  AndroidIconTemplate(directoryName: 'drawable-mdpi', size: 108),
  AndroidIconTemplate(directoryName: 'drawable-hdpi', size: 162),
  AndroidIconTemplate(directoryName: 'drawable-xhdpi', size: 216),
  AndroidIconTemplate(directoryName: 'drawable-xxhdpi', size: 324),
  AndroidIconTemplate(directoryName: 'drawable-xxxhdpi', size: 432),
];

List<AndroidIconTemplate> androidIcons = <AndroidIconTemplate>[
  AndroidIconTemplate(directoryName: 'mipmap-mdpi', size: 48),
  AndroidIconTemplate(directoryName: 'mipmap-hdpi', size: 72),
  AndroidIconTemplate(directoryName: 'mipmap-xhdpi', size: 96),
  AndroidIconTemplate(directoryName: 'mipmap-xxhdpi', size: 144),
  AndroidIconTemplate(directoryName: 'mipmap-xxxhdpi', size: 192),
];

void createDefaultIcons(
  FlutterLauncherIconsConfig flutterLauncherIconsConfig,
  String? flavor,
) {
  printStatus('Creating default icons Android');
  // todo: support prefixPath
  final String? filePath = flutterLauncherIconsConfig.getImagePathAndroid();
  if (filePath == null) {
    throw const InvalidConfigException(errorMissingImagePath);
  }
  final Image? image = decodeImageFile(filePath);
  if (image == null) {
    return;
  }
  final File androidManifestFile = File(constants.androidManifestFile);
  if (flutterLauncherIconsConfig.isCustomAndroidFile) {
    printStatus('Adding a new Android launcher icon');
    final String iconName = flutterLauncherIconsConfig.android;
    isAndroidIconNameCorrectFormat(iconName);
    final String iconPath = '$iconName.png';
    for (AndroidIconTemplate template in androidIcons) {
      _saveNewImages(template, image, iconPath, flavor);
    }
    overwriteAndroidManifestWithNewLauncherIcon(iconName, androidManifestFile);
  } else {
    printStatus(
      'Overwriting the default Android launcher icon with a new icon',
    );
    for (AndroidIconTemplate template in androidIcons) {
      overwriteExistingIcons(
        template,
        image,
        constants.androidFileName,
        flavor,
      );
    }
    overwriteAndroidManifestWithNewLauncherIcon(
      constants.androidDefaultIconName,
      androidManifestFile,
    );
  }
}

/// Ensures that the Android icon name is in the correct format
bool isAndroidIconNameCorrectFormat(String iconName) {
  // assure the icon only consists of lowercase letters, numbers and underscore
  if (!RegExp(r'^[a-z0-9_]+$').hasMatch(iconName)) {
    throw const InvalidAndroidIconNameException(
      constants.errorIncorrectIconName,
    );
  }
  return true;
}

void createAdaptiveIcons(
  FlutterLauncherIconsConfig flutterLauncherIconsConfig,
  String? flavor,
) {
  printStatus('Creating adaptive icons Android');

  // Retrieve the necessary Flutter Launcher Icons configuration from the pubspec.yaml file
  final String? backgroundConfig =
      flutterLauncherIconsConfig.adaptiveIconBackground;
  final String? foregroundImagePath =
      flutterLauncherIconsConfig.adaptiveIconForeground;
  if (backgroundConfig == null || foregroundImagePath == null) {
    throw const InvalidConfigException(errorMissingImagePath);
  }
  final Image? foregroundImage = decodeImageFile(foregroundImagePath);
  if (foregroundImage == null) {
    return;
  }

  // Create adaptive icon foreground images
  for (AndroidIconTemplate androidIcon in adaptiveForegroundIcons) {
    overwriteExistingIcons(
      androidIcon,
      foregroundImage,
      constants.androidAdaptiveForegroundFileName,
      flavor,
    );
  }

  // Create adaptive icon background
  if (isAdaptiveIconConfigPngFile(backgroundConfig)) {
    _createAdaptiveBackgrounds(
      flutterLauncherIconsConfig,
      backgroundConfig,
      flavor,
    );
  } else {
    createAdaptiveIconMipmapXmlFile(flutterLauncherIconsConfig, flavor);
    updateColorsXmlFile(backgroundConfig, flavor);
  }
}

/// Retrieves the colors.xml file for the project.
///
/// If the colors.xml file is found, it is updated with a new color item for the
/// adaptive icon background.
///
/// If not, the colors.xml file is created and a color item for the adaptive icon
/// background is included in the new colors.xml file.
void updateColorsXmlFile(String backgroundConfig, String? flavor) {
  final File colorsXml = File(constants.androidColorsFile(flavor));
  if (colorsXml.existsSync()) {
    printStatus('Updating colors.xml with color for adaptive icon background');
    updateColorsFile(colorsXml, backgroundConfig);
  } else {
    printStatus('No colors.xml file found in your Android project');
    printStatus(
      'Creating colors.xml file and adding it to your Android project',
    );
    createNewColorsFile(backgroundConfig, flavor);
  }
}

/// Creates the xml file required for the adaptive launcher icon
/// FILE LOCATED HERE: res/mipmap-anydpi/{icon-name-from-yaml-config}.xml
void createAdaptiveIconMipmapXmlFile(
  FlutterLauncherIconsConfig flutterLauncherIconsConfig,
  String? flavor,
) {
  if (flutterLauncherIconsConfig.isCustomAndroidFile) {
    File(
      constants.androidAdaptiveXmlFolder(flavor) +
          flutterLauncherIconsConfig.android +
          '.xml',
    ).create(recursive: true).then((File adaptiveIcon) {
      adaptiveIcon.writeAsString(xml_template.icLauncherXml);
    });
  } else {
    File(
      constants.androidAdaptiveXmlFolder(flavor) +
          constants.androidDefaultIconName +
          '.xml',
    ).create(recursive: true).then((File adaptiveIcon) {
      adaptiveIcon.writeAsString(xml_template.icLauncherXml);
    });
  }
}

/// creates adaptive background using png image
void _createAdaptiveBackgrounds(
  FlutterLauncherIconsConfig flutterLauncherIconsConfig,
  String adaptiveIconBackgroundImagePath,
  String? flavor,
) {
  final String filePath = adaptiveIconBackgroundImagePath;
  final Image? image = decodeImageFile(filePath);
  if (image == null) {
    return;
  }

  // creates a png image (ic_adaptive_background.png) for the adaptive icon background in each of the locations
  // it is required
  for (AndroidIconTemplate androidIcon in adaptiveForegroundIcons) {
    _saveNewImages(
      androidIcon,
      image,
      constants.androidAdaptiveBackgroundFileName,
      flavor,
    );
  }

  // Creates the xml file required for the adaptive launcher icon
  // FILE LOCATED HERE:  res/mipmap-anydpi/{icon-name-from-yaml-config}.xml
  if (flutterLauncherIconsConfig.isCustomAndroidFile) {
    File(
      constants.androidAdaptiveXmlFolder(flavor) +
          flutterLauncherIconsConfig.android +
          '.xml',
    ).create(recursive: true).then((File adaptiveIcon) {
      adaptiveIcon.writeAsString(xml_template.icLauncherDrawableBackgroundXml);
    });
  } else {
    File(
      constants.androidAdaptiveXmlFolder(flavor) +
          constants.androidDefaultIconName +
          '.xml',
    ).create(recursive: true).then((File adaptiveIcon) {
      adaptiveIcon.writeAsString(xml_template.icLauncherDrawableBackgroundXml);
    });
  }
}

/// Creates a colors.xml file if it was missing from android/app/src/main/res/values/colors.xml
void createNewColorsFile(String backgroundColor, String? flavor) {
  File(constants.androidColorsFile(flavor))
      .create(recursive: true)
      .then((File colorsFile) {
    colorsFile.writeAsString(xml_template.colorsXml).then((File file) {
      updateColorsFile(colorsFile, backgroundColor);
    });
  });
}

/// Updates the colors.xml with the new adaptive launcher icon color
void updateColorsFile(File colorsFile, String backgroundColor) {
  // Write foreground color
  final List<String> lines = colorsFile.readAsLinesSync();
  bool foundExisting = false;
  for (int x = 0; x < lines.length; x++) {
    String line = lines[x];
    if (line.contains('name="ic_launcher_background"')) {
      foundExisting = true;
      // replace anything between tags which does not contain another tag
      line = line.replaceAll(RegExp(r'>([^><]*)<'), '>$backgroundColor<');
      lines[x] = line;
      break;
    }
  }

  // Add new line if we didn't find an existing value
  if (!foundExisting) {
    lines.insert(
      lines.length - 1,
      '\t<color name="ic_launcher_background">$backgroundColor</color>',
    );
  }

  colorsFile.writeAsStringSync(lines.join('\n'));
}

/// Overrides the existing launcher icons in the project
/// Note: Do not change interpolation unless you end up with better results (see issue for result when using cubic
/// interpolation)
/// https://github.com/fluttercommunity/flutter_launcher_icons/issues/101#issuecomment-495528733
void overwriteExistingIcons(
  AndroidIconTemplate template,
  Image image,
  String filename,
  String? flavor,
) {
  final Image newFile = createResizedImage(template.size, image);
  File(
    constants.androidResFolder(flavor) +
        template.directoryName +
        '/' +
        filename,
  ).create(recursive: true).then((File file) {
    file.writeAsBytesSync(encodePng(newFile));
  });
}

/// Saves new launcher icons to the project, keeping the old launcher icons.
/// Note: Do not change interpolation unless you end up with better results
/// https://github.com/fluttercommunity/flutter_launcher_icons/issues/101#issuecomment-495528733
void _saveNewImages(
  AndroidIconTemplate template,
  Image image,
  String iconFilePath,
  String? flavor,
) {
  final Image newFile = createResizedImage(template.size, image);
  File(
    constants.androidResFolder(flavor) +
        template.directoryName +
        '/' +
        iconFilePath,
  ).create(recursive: true).then((File file) {
    file.writeAsBytesSync(encodePng(newFile));
  });
}

/// Updates the line which specifies the launcher icon within the AndroidManifest.xml
/// with the new icon name (only if it has changed)
///
/// Note: default iconName = "ic_launcher"
Future<void> overwriteAndroidManifestWithNewLauncherIcon(
  String iconName,
  File androidManifestFile,
) async {
  // we do not use `file.readAsLinesSync()` here because that always gets rid of the last empty newline
  final List<String> oldManifestLines =
      (await androidManifestFile.readAsString()).split('\n');
  final List<String> transformedLines =
      _transformAndroidManifestWithNewLauncherIcon(oldManifestLines, iconName);
  await androidManifestFile.writeAsString(transformedLines.join('\n'));
}

/// Updates only the line containing android:icon with the specified iconName
List<String> _transformAndroidManifestWithNewLauncherIcon(
  List<String> oldManifestLines,
  String iconName,
) {
  return oldManifestLines.map((String line) {
    if (line.contains('android:icon')) {
      // Using RegExp replace the value of android:icon to point to the new icon
      // anything but a quote of any length: [^"]*
      // an escaped quote: \\" (escape slash, because it exists regex)
      // quote, no quote / quote with things behind : \"[^"]*
      // repeat as often as wanted with no quote at start: [^"]*(\"[^"]*)*
      // escaping the slash to place in string: [^"]*(\\"[^"]*)*"
      // result: any string which does only include escaped quotes
      return line.replaceAll(
        RegExp(r'android:icon="[^"]*(\\"[^"]*)*"'),
        'android:icon="@mipmap/$iconName"',
      );
    } else {
      return line;
    }
  }).toList();
}

/// Retrieves the minSdk value from the
/// - flutter.gradle: `'$FLUTTER_ROOT/packages/flutter_tools/gradle/flutter.gradle'`
/// - build.gradle: `'android/app/build.gradle'`
/// - local.properties: `'android/local.properties'`
///
/// If found none returns [constants.androidDefaultAndroidMinSDK]
int minSdk() {
  final androidGradleFile = File(constants.androidGradleFile);
  final androidLocalPropertiesFile = File(constants.androidLocalPropertiesFile);

  // looks for minSdk value in build.gradle, flutter.gradle & local.properties.
  // this should always be order
  // first check build.gradle, then local.properties, then flutter.gradle
  return _getMinSdkFromFile(androidGradleFile) ??
      _getMinSdkFromFile(androidLocalPropertiesFile) ??
      _getMinSdkFlutterGradle(androidLocalPropertiesFile) ??
      constants.androidDefaultAndroidMinSDK;
}

/// Retrieves the minSdk value from [File]
int? _getMinSdkFromFile(File file) {
  final List<String> lines = file.readAsLinesSync();
  for (String line in lines) {
    if (line.contains('minSdkVersion')) {
      if (line.contains('//') &&
          line.indexOf('//') < line.indexOf('minSdkVersion')) {
        // This line is commented
        continue;
      }
      // remove anything from the line that is not a digit
      final String minSdk = line.replaceAll(RegExp(r'[^\d]'), '');
      // when minSdkVersion value not found
      return int.tryParse(minSdk);
    }
  }
  return null; // Didn't find minSdk, assume the worst
}

/// A helper function to [_getMinSdkFlutterGradle]
/// which retrives value of `flutter.sdk` from `local.properties` file
String? _getFlutterSdkPathFromLocalProperties(File file) {
  final List<String> lines = file.readAsLinesSync();
  for (String line in lines) {
    if (!line.contains('flutter.sdk=')) {
      continue;
    }
    if (line.contains('#') &&
        line.indexOf('#') < line.indexOf('flutter.sdk=')) {
      continue;
    }
    final flutterSdkPath = line.split('=').last.trim();
    if (flutterSdkPath.isEmpty) {
      return null;
    }
    return flutterSdkPath;
  }
  return null;
}

/// Retrives value of `minSdkVersion` from `flutter.gradle`
int? _getMinSdkFlutterGradle(File localPropertiesFile) {
  final flutterRoot =
      _getFlutterSdkPathFromLocalProperties(localPropertiesFile);
  if (flutterRoot == null) {
    return null;
  }

  final flutterGradleFile =
      File(path.join(flutterRoot, constants.androidFlutterGardlePath));

  final List<String> lines = flutterGradleFile.readAsLinesSync();
  for (String line in lines) {
    if (!line.contains('static int minSdkVersion =')) {
      continue;
    }
    if (line.contains('//') &&
        line.indexOf('//') < line.indexOf('static int minSdkVersion =')) {
      continue;
    }
    final minSdk = line.split('=').last.trim();
    return int.tryParse(minSdk);
  }
  return null;
}

/// Returns true if the adaptive icon configuration is a PNG image
bool isAdaptiveIconConfigPngFile(String backgroundFile) {
  return backgroundFile.endsWith('.png');
}

/// (NOTE THIS IS JUST USED FOR UNIT TEST)
/// Ensures the correct path is used for generating adaptive icons
/// "Next you must create alternative drawable resources in your app for use with
/// Android 8.0 (API level 26) in res/mipmap-anydpi/ic_launcher.xml"
/// Source: https://developer.android.com/guide/practices/ui_guidelines/icon_design_adaptive
bool isCorrectMipmapDirectoryForAdaptiveIcon(String path) {
  return path == 'android/app/src/main/res/mipmap-anydpi-v26/';
}
