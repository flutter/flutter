part of flutter_native_splash_cli;

/// Image template
class _AndroidDrawableTemplate {
  final String directoryName;
  final double pixelDensity;

  _AndroidDrawableTemplate({
    required this.directoryName,
    required this.pixelDensity,
  });
}

final _imagesTemplates = _generateImageTemplates();
final _imageDarkTemplates = _generateImageTemplates(dark: true);
final _imagesAndroid12Templates = _generateImageTemplates(android12: true);
final _imagesAndroid12DarkTemplates =
    _generateImageTemplates(android12: true, dark: true);

List<_AndroidDrawableTemplate> _generateImageTemplates({
  bool dark = false,
  bool android12 = false,
}) {
  final prefix = "drawable${dark ? '-night' : ''}";
  final suffix = android12 ? '-v31' : '';
  return <_AndroidDrawableTemplate>[
    _AndroidDrawableTemplate(
      directoryName: '$prefix-mdpi$suffix',
      pixelDensity: 1,
    ),
    _AndroidDrawableTemplate(
      directoryName: '$prefix-hdpi$suffix',
      pixelDensity: 1.5,
    ),
    _AndroidDrawableTemplate(
      directoryName: '$prefix-xhdpi$suffix',
      pixelDensity: 2,
    ),
    _AndroidDrawableTemplate(
      directoryName: '$prefix-xxhdpi$suffix',
      pixelDensity: 3,
    ),
    _AndroidDrawableTemplate(
      directoryName: '$prefix-xxxhdpi$suffix',
      pixelDensity: 4,
    ),
  ];
}

/// Create Android splash screen
void _createAndroidSplash({
  required String? imagePath,
  required String? darkImagePath,
  required String? android12ImagePath,
  required String? android12DarkImagePath,
  required String? android12BackgroundColor,
  required String? android12DarkBackgroundColor,
  required String? brandingImagePath,
  required String? brandingDarkImagePath,
  required String? color,
  required String? darkColor,
  required String gravity,
  required String brandingGravity,
  required bool fullscreen,
  required String? backgroundImage,
  required String? darkBackgroundImage,
  required String? android12IconBackgroundColor,
  required String? darkAndroid12IconBackgroundColor,
  required String? screenOrientation,
  String? android12BrandingImagePath,
  String? android12DarkBrandingImagePath,
}) {
  _applyImageAndroid(imagePath: imagePath);

  _applyImageAndroid(imagePath: darkImagePath, dark: true);

  //create resources for branding image if provided
  _applyImageAndroid(imagePath: brandingImagePath, fileName: 'branding.png');

  _applyImageAndroid(
    imagePath: brandingDarkImagePath,
    dark: true,
    fileName: 'branding.png',
  );

  //create android 12 image if provided.  (otherwise uses launch icon)
  _applyImageAndroid(
    imagePath: android12ImagePath,
    fileName: 'android12splash.png',
  );

  _applyImageAndroid(
    imagePath: android12DarkImagePath,
    dark: true,
    fileName: 'android12splash.png',
  );

  _applyImageAndroid(
    imagePath: android12BrandingImagePath,
    android12: true,
    fileName: 'android12branding.png',
  );

  _applyImageAndroid(
    imagePath: android12DarkBrandingImagePath,
    dark: true,
    android12: true,
    fileName: 'android12branding.png',
  );

  _createBackground(
    colorString: color,
    darkColorString: darkColor,
    darkBackgroundImageSource: darkBackgroundImage,
    backgroundImageSource: backgroundImage,
    darkBackgroundImageDestination:
        '${_flavorHelper.androidNightDrawableFolder}background.png',
    backgroundImageDestination:
        '${_flavorHelper.androidDrawableFolder}background.png',
  );

  _createBackground(
    colorString: color,
    darkColorString: darkColor,
    darkBackgroundImageSource: darkBackgroundImage,
    backgroundImageSource: backgroundImage,
    darkBackgroundImageDestination:
        '${_flavorHelper.androidNightV21DrawableFolder}background.png',
    backgroundImageDestination:
        '${_flavorHelper.androidV21DrawableFolder}background.png',
  );

  print('[Android] Updating launch background(s) with splash image path...');

  _applyLaunchBackgroundXml(
    gravity: gravity,
    launchBackgroundFilePath: _flavorHelper.androidLaunchBackgroundFile,
    showImage: imagePath != null,
    showBranding: brandingImagePath != null,
    brandingGravity: brandingGravity,
  );

  if (darkColor != null || darkBackgroundImage != null) {
    _applyLaunchBackgroundXml(
      gravity: gravity,
      launchBackgroundFilePath: _flavorHelper.androidLaunchDarkBackgroundFile,
      showImage: imagePath != null,
      showBranding: brandingImagePath != null,
      brandingGravity: brandingGravity,
    );
  }

  if (Directory(_flavorHelper.androidV21DrawableFolder).existsSync()) {
    _applyLaunchBackgroundXml(
      gravity: gravity,
      launchBackgroundFilePath: _flavorHelper.androidV21LaunchBackgroundFile,
      showImage: imagePath != null,
      showBranding: brandingImagePath != null,
      brandingGravity: brandingGravity,
    );
    if (darkColor != null || darkBackgroundImage != null) {
      _applyLaunchBackgroundXml(
        gravity: gravity,
        launchBackgroundFilePath:
            _flavorHelper.androidV21LaunchDarkBackgroundFile,
        showImage: imagePath != null,
        showBranding: brandingImagePath != null,
        brandingGravity: brandingGravity,
      );
    }
  }

  print('[Android] Updating styles...');
  if (android12BackgroundColor != null ||
      android12ImagePath != null ||
      android12IconBackgroundColor != null ||
      android12BrandingImagePath != null) {
    _applyStylesXml(
      fullScreen: fullscreen,
      file: _flavorHelper.androidV31StylesFile,
      template: _androidV31StylesXml,
      android12BackgroundColor: android12BackgroundColor,
      android12ImagePath: android12ImagePath,
      android12IconBackgroundColor: android12IconBackgroundColor,
      android12BrandingImagePath: android12BrandingImagePath,
    );
  }

  if (android12DarkBackgroundColor != null ||
      android12DarkImagePath != null ||
      darkAndroid12IconBackgroundColor != null ||
      brandingDarkImagePath != null) {
    _applyStylesXml(
      fullScreen: fullscreen,
      file: _flavorHelper.androidV31StylesNightFile,
      template: _androidV31StylesNightXml,
      android12BackgroundColor: android12DarkBackgroundColor,
      android12ImagePath: android12DarkImagePath,
      android12IconBackgroundColor: darkAndroid12IconBackgroundColor,
      android12BrandingImagePath: android12DarkBrandingImagePath,
    );
  }

  _applyStylesXml(
    fullScreen: fullscreen,
    file: _flavorHelper.androidStylesFile,
    template: _androidStylesXml,
  );

  if (darkColor != null || darkBackgroundImage != null) {
    _applyStylesXml(
      fullScreen: fullscreen,
      file: _flavorHelper.androidNightStylesFile,
      template: _androidStylesNightXml,
    );
  }

  _applyOrientation(orientation: screenOrientation);
}

/// Create splash screen as drawables for multiple screens (dpi)
void _applyImageAndroid({
  String? imagePath,
  bool dark = false,
  bool android12 = false,
  String fileName = 'splash.png',
}) {
  final templates = _getAssociatedTemplates(android12: android12, dark: dark);
  if (imagePath == null) {
    for (final template in templates) {
      _deleteImageAndroid(template: template, fileName: fileName);
    }
  } else {
    print(
      '[Android] Creating ${dark ? 'dark mode ' : 'default '}'
      '${fileName.split('.')[0]} images',
    );

    final image = decodeImage(File(imagePath).readAsBytesSync());
    if (image == null) {
      print('The file $imagePath could not be read.');
      exit(1);
    }

    for (final template in templates) {
      _saveImageAndroid(template: template, image: image, fileName: fileName);
    }
  }
}

List<_AndroidDrawableTemplate> _getAssociatedTemplates({
  required bool android12,
  required bool dark,
}) {
  if (android12) {
    return dark ? _imagesAndroid12DarkTemplates : _imagesAndroid12Templates;
  } else {
    return dark ? _imageDarkTemplates : _imagesTemplates;
  }
}

/// Saves splash screen image to the project
/// Note: Do not change interpolation unless you end up with better results
/// https://github.com/fluttercommunity/flutter_launcher_icons/issues/101#issuecomment-495528733
void _saveImageAndroid({
  required _AndroidDrawableTemplate template,
  required Image image,
  required fileName,
}) {
  //added file name attribute to make this method generic for splash image and branding image.
  final newFile = copyResize(
    image,
    width: image.width * template.pixelDensity ~/ 4,
    height: image.height * template.pixelDensity ~/ 4,
    interpolation: Interpolation.cubic,
  );

  // Whne the flavor value is not specified we will place all the data inside the main directory.
  // However if the flavor value is specified, we need to place the data in the correct directory.
  // Default: android/app/src/main/res/
  // With a flavor: android/app/src/[flavor name]/res/
  final file = File(
    '${_flavorHelper.androidResFolder}${template.directoryName}/$fileName',
  );
  // File(_androidResFolder + template.directoryName + '/' + 'splash.png');
  file.createSync(recursive: true);
  file.writeAsBytesSync(encodePng(newFile));
}

void _deleteImageAndroid({
  required _AndroidDrawableTemplate template,
  required fileName,
}) {
  final file = File(
    '${_flavorHelper.androidResFolder}${template.directoryName}/$fileName',
  );
  if (file.existsSync()) {
    print('[Android] Deleting $fileName');
    file.deleteSync(recursive: true);
  }
}

/// Updates launch_background.xml adding splash image path
void _applyLaunchBackgroundXml({
  required String launchBackgroundFilePath,
  required String gravity,
  required bool showImage,
  bool showBranding = false,
  String brandingGravity = 'bottom',
}) {
  String brandingGravityValue = brandingGravity;
  print('[Android]  - $launchBackgroundFilePath');
  final launchBackgroundFile = File(launchBackgroundFilePath);
  launchBackgroundFile.createSync(recursive: true);
  final launchBackgroundDocument =
      XmlDocument.parse(_androidLaunchBackgroundXml);

  final layerList = launchBackgroundDocument.getElement('layer-list');
  final List<XmlNode> items = layerList!.children;

  if (showImage) {
    final splashItem =
        XmlDocument.parse(_androidLaunchItemXml).rootElement.copy();
    splashItem.getElement('bitmap')?.setAttribute('android:gravity', gravity);
    items.add(splashItem);
  }

  if (showBranding && gravity != brandingGravityValue) {
    //add branding when splash image and branding image are not at the same position
    final brandingItem =
        XmlDocument.parse(_androidBrandingItemXml).rootElement.copy();
    if (brandingGravityValue == 'bottomRight') {
      brandingGravityValue = 'bottom|right';
    } else if (brandingGravityValue == 'bottomLeft') {
      brandingGravityValue = 'bottom|left';
    } else if (brandingGravityValue != 'bottom') {
      print(
        '$brandingGravityValue illegal property defined for the branding mode. Setting back to default.',
      );
      brandingGravityValue = 'bottom';
    }
    brandingItem
        .getElement('bitmap')
        ?.setAttribute('android:gravity', brandingGravityValue);
    items.add(brandingItem);
  }

  launchBackgroundFile.writeAsStringSync(
    '${launchBackgroundDocument.toXmlString(pretty: true, indent: '    ')}\n',
  );
}

/// Create or update styles.xml full screen mode setting
void _applyStylesXml({
  required bool fullScreen,
  required String file,
  required String template,
  String? android12BackgroundColor,
  String? android12ImagePath,
  String? android12IconBackgroundColor,
  String? android12BrandingImagePath,
}) {
  final stylesFile = File(file);
  print('[Android]  - $file');
  if (!stylesFile.existsSync()) {
    print('[Android] No $file found in your Android project');
    print('[Android] Creating $file and adding it to your Android project');
    stylesFile.createSync(recursive: true);
    stylesFile.writeAsStringSync(template);
  }

  _updateStylesFile(
    fullScreen: fullScreen,
    stylesFile: stylesFile,
    android12BackgroundColor: android12BackgroundColor,
    android12ImagePath: android12ImagePath,
    android12IconBackgroundColor: android12IconBackgroundColor,
    android12BrandingImagePath: android12BrandingImagePath,
  );
}

/// Updates styles.xml adding full screen property
Future<void> _updateStylesFile({
  required bool fullScreen,
  required File stylesFile,
  required String? android12BackgroundColor,
  required String? android12ImagePath,
  required String? android12IconBackgroundColor,
  required String? android12BrandingImagePath,
}) async {
  final stylesDocument = XmlDocument.parse(stylesFile.readAsStringSync());
  final resources = stylesDocument.getElement('resources');
  final styles = resources?.findElements('style');
  if (styles?.length == 1) {
    print(
      '[Android] Only 1 style in styles.xml. Flutter V2 embedding has 2 '
      'styles by default.  Full screen mode not supported in Flutter V1 '
      'embedding.  Skipping update of styles.xml with fullscreen mode',
    );
    return;
  }

  XmlElement launchTheme;
  try {
    launchTheme = styles!.singleWhere(
      (element) => element.attributes.any(
        (attribute) =>
            attribute.name.toString() == 'name' &&
            attribute.value == 'LaunchTheme',
      ),
    );
  } on StateError {
    print(
      'LaunchTheme was not found in styles.xml. Skipping fullscreen '
      'mode',
    );
    return;
  }

  replaceElement(
    launchTheme: launchTheme,
    name: 'android:forceDarkAllowed',
    value: "false",
  );

  replaceElement(
    launchTheme: launchTheme,
    name: 'android:windowFullscreen',
    value: fullScreen.toString(),
  );

  replaceElement(
    launchTheme: launchTheme,
    name: 'android:windowLayoutInDisplayCutoutMode',
    value: 'shortEdges',
  );

  // In Android 12, the color must be set directly in the styles.xml
  if (android12BackgroundColor == null) {
    removeElement(
      launchTheme: launchTheme,
      name: 'android:windowSplashScreenBackground',
    );
  } else {
    replaceElement(
      launchTheme: launchTheme,
      name: 'android:windowSplashScreenBackground',
      value: '#$android12BackgroundColor',
    );
  }

  if (android12BrandingImagePath == null) {
    removeElement(
      launchTheme: launchTheme,
      name: 'android:windowSplashScreenBrandingImage',
    );
  } else {
    replaceElement(
      launchTheme: launchTheme,
      name: 'android:windowSplashScreenBrandingImage',
      value: '@drawable/android12branding',
    );
  }

  if (android12ImagePath == null) {
    removeElement(
      launchTheme: launchTheme,
      name: 'android:windowSplashScreenAnimatedIcon',
    );
  } else {
    replaceElement(
      launchTheme: launchTheme,
      name: 'android:windowSplashScreenAnimatedIcon',
      value: '@drawable/android12splash',
    );
  }

  if (android12IconBackgroundColor == null) {
    removeElement(
      launchTheme: launchTheme,
      name: 'android:windowSplashScreenIconBackgroundColor',
    );
  } else {
    replaceElement(
      launchTheme: launchTheme,
      name: 'android:windowSplashScreenIconBackgroundColor',
      value: '#$android12IconBackgroundColor',
    );
  }

  stylesFile.writeAsStringSync(
    '${stylesDocument.toXmlString(pretty: true, indent: '    ')}\n',
  );
}

void replaceElement({
  required XmlElement launchTheme,
  required String name,
  required String value,
}) {
  launchTheme.children.removeWhere(
    (element) => element.attributes.any(
      (attribute) =>
          attribute.name.toString() == 'name' && attribute.value == name,
    ),
  );

  launchTheme.children.add(
    XmlElement(
      XmlName('item'),
      [XmlAttribute(XmlName('name'), name)],
      [XmlText(value)],
    ),
  );
}

void removeElement({required XmlElement launchTheme, required String name}) {
  launchTheme.children.removeWhere(
    (element) => element.attributes.any(
      (attribute) =>
          attribute.name.toString() == 'name' && attribute.value == name,
    ),
  );
}

void _applyOrientation({required String? orientation}) {
  final manifestFile = File(_flavorHelper.androidManifestFile);
  final manifestDocument = XmlDocument.parse(manifestFile.readAsStringSync());

  final manifestRoot = manifestDocument.getElement('manifest');
  final application = manifestRoot?.getElement('application');
  final activity = application?.getElement('activity');
  const String attribute = 'android:screenOrientation';
  if (orientation == null) {
    if (activity?.attributes.any((p0) => p0.name.toString() == attribute) ??
        false) {
      activity?.removeAttribute(attribute);
    } else {
      return;
    }
  } else {
    activity?.setAttribute(attribute, orientation);
  }
  manifestFile.writeAsStringSync(
    manifestDocument.toXmlString(
      pretty: true,
      indent: '    ',
      indentAttribute: (XmlAttribute xmlAttribute) {
        // Try to preserve AndroidManifest.XML formatting:
        if (xmlAttribute.name.toString() == "xmlns:android") return false;
        if (xmlAttribute.value == "android.intent.action.MAIN") return false;
        if (xmlAttribute.value == "android.intent.category.LAUNCHER") {
          return false;
        }
        return true;
      },
    ),
  );
}
