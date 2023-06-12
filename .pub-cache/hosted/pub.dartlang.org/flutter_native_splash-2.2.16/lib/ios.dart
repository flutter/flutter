part of flutter_native_splash_cli;

// Image template
class _IosLaunchImageTemplate {
  final String fileName;
  final double pixelDensity;

  _IosLaunchImageTemplate({required this.fileName, required this.pixelDensity});
}

final List<_IosLaunchImageTemplate> _iOSSplashImages =
    <_IosLaunchImageTemplate>[
  _IosLaunchImageTemplate(fileName: 'LaunchImage.png', pixelDensity: 1),
  _IosLaunchImageTemplate(fileName: 'LaunchImage@2x.png', pixelDensity: 2),
  _IosLaunchImageTemplate(
    fileName: 'LaunchImage@3x.png',
    pixelDensity: 3,
  ), // original image must be @4x
];

final List<_IosLaunchImageTemplate> _iOSSplashImagesDark =
    <_IosLaunchImageTemplate>[
  _IosLaunchImageTemplate(fileName: 'LaunchImageDark.png', pixelDensity: 1),
  _IosLaunchImageTemplate(fileName: 'LaunchImageDark@2x.png', pixelDensity: 2),
  _IosLaunchImageTemplate(fileName: 'LaunchImageDark@3x.png', pixelDensity: 3),
  // original image must be @3x
];

//Resource files for branding assets
final List<_IosLaunchImageTemplate> _iOSBrandingImages =
    <_IosLaunchImageTemplate>[
  _IosLaunchImageTemplate(fileName: 'BrandingImage.png', pixelDensity: 1),
  _IosLaunchImageTemplate(fileName: 'BrandingImage@2x.png', pixelDensity: 2),
  _IosLaunchImageTemplate(
    fileName: 'BrandingImage@3x.png',
    pixelDensity: 3,
  ), // original image must be @4x
];
final List<_IosLaunchImageTemplate> _iOSBrandingImagesDark =
    <_IosLaunchImageTemplate>[
  _IosLaunchImageTemplate(fileName: 'BrandingImageDark.png', pixelDensity: 1),
  _IosLaunchImageTemplate(
    fileName: 'BrandingImageDark@2x.png',
    pixelDensity: 2,
  ),
  _IosLaunchImageTemplate(
    fileName: 'BrandingImageDark@3x.png',
    pixelDensity: 3,
  ),
  // original image must be @3x
];

/// Create iOS splash screen
void _createiOSSplash({
  required String? imagePath,
  required String? darkImagePath,
  String? brandingImagePath,
  String? brandingDarkImagePath,
  required String? color,
  required String? darkColor,
  List<String>? plistFiles,
  required String iosContentMode,
  String? iosBrandingContentMode,
  required bool fullscreen,
  required String? backgroundImage,
  required String? darkBackgroundImage,
}) {
  if (imagePath != null) {
    _applyImageiOS(imagePath: imagePath, list: _iOSSplashImages);
  } else {
    final splashImage = Image(1, 1);
    for (final template in _iOSSplashImages) {
      final file =
          File(_flavorHelper.iOSAssetsLaunchImageFolder + template.fileName);
      file.createSync(recursive: true);
      file.writeAsBytesSync(encodePng(splashImage));
    }
  }

  if (darkImagePath != null) {
    _applyImageiOS(
      imagePath: darkImagePath,
      dark: true,
      list: _iOSSplashImagesDark,
    );
  } else {
    for (final template in _iOSSplashImagesDark) {
      final file =
          File(_flavorHelper.iOSAssetsLaunchImageFolder + template.fileName);
      if (file.existsSync()) file.deleteSync();
    }
  }

  if (brandingImagePath != null) {
    _applyImageiOS(
      imagePath: brandingImagePath,
      list: _iOSBrandingImages,
      targetPath: _flavorHelper.iOSAssetsBrandingImageFolder,
    );
  } else {
    if (Directory(_flavorHelper.iOSAssetsBrandingImageFolder).existsSync()) {
      Directory(_flavorHelper.iOSAssetsBrandingImageFolder)
          .delete(recursive: true);
    }
  }
  if (brandingDarkImagePath != null) {
    _applyImageiOS(
      imagePath: brandingDarkImagePath,
      dark: true,
      list: _iOSBrandingImagesDark,
      targetPath: _flavorHelper.iOSAssetsBrandingImageFolder,
    );
  } else {
    for (final template in _iOSBrandingImagesDark) {
      final file =
          File(_flavorHelper.iOSAssetsBrandingImageFolder + template.fileName);
      if (file.existsSync()) file.deleteSync();
    }
  }

  final launchImageFile =
      File('${_flavorHelper.iOSAssetsLaunchImageFolder}Contents.json');
  launchImageFile.createSync(recursive: true);
  launchImageFile.writeAsStringSync(
    darkImagePath != null ? _iOSContentsJsonDark : _iOSContentsJson,
  );

  if (brandingImagePath != null) {
    final brandingImageFile =
        File('${_flavorHelper.iOSAssetsBrandingImageFolder}Contents.json');
    brandingImageFile.createSync(recursive: true);
    brandingImageFile.writeAsStringSync(
      brandingDarkImagePath != null
          ? _iOSBrandingContentsJsonDark
          : _iOSBrandingContentsJson,
    );
  }

  _createLaunchScreenStoryboard(
    imagePath: imagePath,
    brandingImagePath: brandingImagePath,
    iosContentMode: iosContentMode,
    iosBrandingContentMode: iosBrandingContentMode,
  );
  _createBackground(
    colorString: color,
    darkColorString: darkColor,
    darkBackgroundImageSource: darkBackgroundImage,
    backgroundImageSource: backgroundImage,
    darkBackgroundImageDestination:
        '${_flavorHelper.iOSAssetsLaunchImageBackgroundFolder}darkbackground.png',
    backgroundImageDestination:
        '${_flavorHelper.iOSAssetsLaunchImageBackgroundFolder}background.png',
  );

  final backgroundImageFile = File(
    '${_flavorHelper.iOSAssetsLaunchImageBackgroundFolder}Contents.json',
  );
  backgroundImageFile.createSync(recursive: true);

  backgroundImageFile.writeAsStringSync(
    (darkColor != null || darkBackgroundImage != null)
        ? _iOSLaunchBackgroundDarkJson
        : _iOSLaunchBackgroundJson,
  );

  _applyInfoPList(plistFiles: plistFiles, fullscreen: fullscreen);
}

/// Create splash screen images for original size, @2x and @3x
void _applyImageiOS({
  required String imagePath,
  bool dark = false,
  required List<_IosLaunchImageTemplate> list,
  String? targetPath,
}) {
  // Because the path is no longer static, targetPath can't have a default value.
  // That's why this was added, as a setup for a default value.
  targetPath ??= _flavorHelper.iOSAssetsLaunchImageFolder;

  print('[iOS] Creating ${dark ? 'dark mode ' : ''} images');

  final image = decodeImage(File(imagePath).readAsBytesSync());
  if (image == null) {
    print('$imagePath could not be loaded.');
    exit(1);
  }
  for (final template in list) {
    _saveImageiOS(template: template, image: image, targetPath: targetPath);
  }
}

/// Saves splash screen image to the project
void _saveImageiOS({
  required _IosLaunchImageTemplate template,
  required Image image,
  required String targetPath,
}) {
  final newFile = copyResize(
    image,
    width: image.width * template.pixelDensity ~/ 4,
    height: image.height * template.pixelDensity ~/ 4,
    interpolation: Interpolation.linear,
  );

  final file = File(targetPath + template.fileName);
  file.createSync(recursive: true);
  file.writeAsBytesSync(encodePng(newFile));
}

/// Updates LaunchScreen.storyboard adding splash image path
void _updateLaunchScreenStoryboard({
  required String? imagePath,
  required String iosContentMode,
  String? brandingImagePath,
  String? iosBrandingContentMode,
}) {
  String? iosBrandingContentModeValue = iosBrandingContentMode;
  // Load the data
  final file = File(_flavorHelper.iOSLaunchScreenStoryboardFile);
  final xmlDocument = XmlDocument.parse(file.readAsStringSync());
  final documentData = xmlDocument.getElement('document');

  // Find the view that contains the splash image
  final view =
      documentData?.descendants.whereType<XmlElement>().firstWhere((element) {
    return element.name.qualified == 'view' &&
        element.getAttribute('id') == 'Ze5-6b-2t3';
  });
  if (view == null) {
    print(
      'Default Flutter view Ze5-6b-2t3 not found. '
      'Did you modify your default ${_flavorHelper.iOSLaunchScreenStoryboardName}.storyboard file?',
    );
    exit(1);
  }

  // Find the splash imageView
  final subViews = view.getElement('subviews');
  if (subViews == null) {
    print(
      'Not able to find "subviews" in ${_flavorHelper.iOSLaunchScreenStoryboardName}.storyboard. Image for '
      'splash screen not updated. Did you modify your default '
      '${_flavorHelper.iOSLaunchScreenStoryboardName}.storyboard file?',
    );
    exit(1);
  }
  final imageView = subViews.children.whereType<XmlElement>().firstWhere(
    (element) =>
        element.name.qualified == 'imageView' &&
        element.getAttribute('image') == _flavorHelper.iOSLaunchImageName,
    orElse: () {
      print(
        'Not able to find "${_flavorHelper.iOSLaunchImageName}" in ${_flavorHelper.iOSLaunchScreenStoryboardName}.storyboard. Image '
        'for splash screen not updated. Did you modify your default '
        '${_flavorHelper.iOSLaunchScreenStoryboardName}.storyboard file? [1]',
      );
      exit(1);
    },
  );
  subViews.children.whereType<XmlElement>().firstWhere(
    (element) =>
        element.name.qualified == 'imageView' &&
        element.getAttribute('image') == _flavorHelper.iOSLaunchBackgroundName,
    orElse: () {
      subViews.children.insert(
        0,
        XmlDocument.parse(_flavorHelper.iOSLaunchBackgroundSubView)
            .rootElement
            .copy(),
      );
      return XmlElement(XmlName(''));
    },
  );
  // Update the fill property
  imageView.setAttribute('contentMode', iosContentMode);

  if (!['bottom', 'bottomRight', 'bottomLeft']
      .contains(iosBrandingContentModeValue)) {
    iosBrandingContentModeValue = 'bottom';
  }
  if (brandingImagePath != null &&
      iosBrandingContentModeValue != iosContentMode) {
    final brandingImageView =
        subViews.children.whereType<XmlElement>().firstWhere(
      (element) {
        return element.name.qualified == 'imageView' &&
            element.getAttribute('image') == _flavorHelper.iOSBrandingImageName;
      },
      orElse: () {
        subViews.children.insert(
          subViews.children.length - 1,
          XmlDocument.parse(_flavorHelper.iOSBrandingSubView)
              .rootElement
              .copy(),
        );
        return XmlElement(XmlName(''));
      },
    );

    brandingImageView.setAttribute('contentMode', iosBrandingContentMode);
  }
  // Find the resources
  final resources = documentData?.getElement('resources');
  final launchImageResource =
      resources?.children.whereType<XmlElement>().firstWhere(
    (element) =>
        element.name.qualified == 'image' &&
        element.getAttribute('name') == _flavorHelper.iOSLaunchImageName,
    orElse: () {
      print(
        'Not able to find "${_flavorHelper.iOSLaunchImageName}" in ${_flavorHelper.iOSLaunchScreenStoryboardName}.storyboard. Image '
        'for splash screen not updated. Did you modify your default '
        '${_flavorHelper.iOSLaunchScreenStoryboardName}.storyboard file? [2]',
      );
      exit(1);
    },
  );

  resources?.children.whereType<XmlElement>().firstWhere(
    (element) =>
        element.name.qualified == 'image' &&
        element.getAttribute('name') == _flavorHelper.iOSLaunchBackgroundName,
    orElse: () {
      // If the color has not been set via background image, set it here:

      resources.children.add(
        XmlDocument.parse(
          '<image name="${_flavorHelper.iOSLaunchBackgroundName}" width="1" height="1"/>',
        ).rootElement.copy(),
      );
      return XmlElement(XmlName(''));
    },
  );

  view.children.remove(view.getElement('constraints'));
  view.children.add(
    XmlDocument.parse(_iOSLaunchBackgroundConstraints).rootElement.copy(),
  );

  if (imagePath != null) {
    final image = decodeImage(File(imagePath).readAsBytesSync());
    if (image == null) {
      print('$imagePath could not be loaded.');
      exit(1);
    }
    launchImageResource?.setAttribute('width', image.width.toString());
    launchImageResource?.setAttribute('height', image.height.toString());
  }

  if (brandingImagePath != null) {
    final brandingImageResource =
        resources?.children.whereType<XmlElement>().firstWhere(
      (element) =>
          element.name.qualified == 'image' &&
          element.getAttribute('name') == _flavorHelper.iOSBrandingImageName,
      orElse: () {
        resources.children.add(
          XmlDocument.parse(
            '<image name="${_flavorHelper.iOSBrandingImageName}" width="1" height="1"/>',
          ).rootElement.copy(),
        );
        return XmlElement(XmlName(''));
      },
    );

    final branding = decodeImage(File(brandingImagePath).readAsBytesSync());
    if (branding == null) {
      print('$brandingImagePath could not be loaded.');
      exit(1);
    }
    brandingImageResource?.setAttribute('width', branding.width.toString());
    brandingImageResource?.setAttribute('height', branding.height.toString());

    var toParse = _iOSBrandingCenterBottomConstraints;
    if (iosBrandingContentModeValue == 'bottomLeft') {
      toParse = _iOSBrandingLeftBottomConstraints;
    } else if (iosBrandingContentModeValue == 'bottomRight') {
      toParse = _iOSBrandingRightBottomConstraints;
    }
    final element = view.getElement('constraints');

    final doc = XmlDocument.parse(toParse).rootElement.copy();
    if (doc.firstChild != null) {
      print('[iOS] updating constraints with splash branding');
      for (final v in doc.children) {
        element?.children.insert(0, v.copy());
      }
    }
  }

  file.writeAsStringSync(
    '${xmlDocument.toXmlString(pretty: true, indent: '    ')}\n',
  );
}

/// Creates LaunchScreen.storyboard with splash image path
void _createLaunchScreenStoryboard({
  required String? imagePath,
  required String iosContentMode,
  required String? iosBrandingContentMode,
  required String? brandingImagePath,
}) {
  final file = File(_flavorHelper.iOSLaunchScreenStoryboardFile);
  file.createSync(recursive: true);
  file.writeAsStringSync(_flavorHelper.iOSLaunchScreenStoryBoardContent);

  return _updateLaunchScreenStoryboard(
    imagePath: imagePath,
    brandingImagePath: brandingImagePath,
    iosContentMode: iosContentMode,
    iosBrandingContentMode: iosBrandingContentMode,
  );
}

void _createBackground({
  required String? colorString,
  required String? darkColorString,
  required String? backgroundImageSource,
  required String? darkBackgroundImageSource,
  required String backgroundImageDestination,
  required String darkBackgroundImageDestination,
}) {
  if (colorString != null) {
    final background = Image(1, 1);
    final redChannel = int.parse(colorString.substring(0, 2), radix: 16);
    final greenChannel = int.parse(colorString.substring(2, 4), radix: 16);
    final blueChannel = int.parse(colorString.substring(4, 6), radix: 16);
    background.fill(
      0xFF000000 + (blueChannel << 16) + (greenChannel << 8) + redChannel,
    );
    final file = File(backgroundImageDestination);
    file.createSync(recursive: true);
    file.writeAsBytesSync(encodePng(background));
  } else if (backgroundImageSource != null) {
    createBackgroundImage(
      imageDestination: backgroundImageDestination,
      imageSource: backgroundImageSource,
    );
  } else {
    throw Exception('No color string or background image!');
  }

  if (darkColorString != null) {
    final background = Image(1, 1);
    final redChannel = int.parse(darkColorString.substring(0, 2), radix: 16);
    final greenChannel = int.parse(darkColorString.substring(2, 4), radix: 16);
    final blueChannel = int.parse(darkColorString.substring(4, 6), radix: 16);
    background.fill(
      0xFF000000 + (blueChannel << 16) + (greenChannel << 8) + redChannel,
    );
    final file = File(darkBackgroundImageDestination);
    file.createSync(recursive: true);
    file.writeAsBytesSync(encodePng(background));
  } else if (darkBackgroundImageSource != null) {
    createBackgroundImage(
      imageDestination: darkBackgroundImageDestination,
      imageSource: darkBackgroundImageSource,
    );
  } else {
    final file = File(darkBackgroundImageDestination);
    if (file.existsSync()) file.deleteSync();
  }
}

/// Update Info.plist for status bar behaviour (hidden/visible)
void _applyInfoPList({List<String>? plistFiles, required bool fullscreen}) {
  List<String>? plistFilesValue = plistFiles;
  if (plistFilesValue == null) {
    plistFilesValue = [];
    plistFilesValue.add(_flavorHelper.iOSInfoPlistFile);
  }

  for (final plistFile in plistFilesValue) {
    if (!File(plistFile).existsSync()) {
      print(
        'File $plistFile not found.  If you renamed the file, make sure to'
        ' specify it in the info_plist_files section of your '
        'flutter_native_splash configuration.',
      );
      exit(1);
    }

    print('[iOS] Updating $plistFile for status bar hidden/visible');
    _updateInfoPlistFile(plistFile: plistFile, fullscreen: fullscreen);
  }
}

/// Update Infop.list with status bar hidden directive
void _updateInfoPlistFile({
  required String plistFile,
  required bool fullscreen,
}) {
  // Load the data
  final file = File(plistFile);
  final xmlDocument = XmlDocument.parse(file.readAsStringSync());
  final dict = xmlDocument.getElement('plist')?.getElement('dict');
  if (dict == null) {
    throw Exception('$plistFile plist dict element not found');
  }

  var elementFound = true;
  final uIStatusBarHidden = dict.children.whereType<XmlElement>().firstWhere(
    (element) {
      return element.text == 'UIStatusBarHidden';
    },
    orElse: () {
      final builder = XmlBuilder();
      builder.element(
        'key',
        nest: () {
          builder.text('UIStatusBarHidden');
        },
      );
      dict.children.add(builder.buildFragment());
      dict.children.add(XmlElement(XmlName(fullscreen.toString())));
      elementFound = false;
      return XmlElement(XmlName(''));
    },
  );

  if (elementFound) {
    final index = dict.children.indexOf(uIStatusBarHidden);
    final uIStatusBarHiddenValue = dict.children[index + 1].following
        .firstWhere((element) => element.nodeType == XmlNodeType.ELEMENT);
    uIStatusBarHiddenValue.replace(XmlElement(XmlName(fullscreen.toString())));
  }

  elementFound = true;
  if (fullscreen) {
    final uIViewControllerBasedStatusBarAppearance =
        dict.children.whereType<XmlElement>().firstWhere(
      (element) {
        return element.text == 'UIViewControllerBasedStatusBarAppearance';
      },
      orElse: () {
        final builder = XmlBuilder();
        builder.element(
          'key',
          nest: () {
            builder.text('UIViewControllerBasedStatusBarAppearance');
          },
        );
        dict.children.add(builder.buildFragment());
        dict.children.add(XmlElement(XmlName((!fullscreen).toString())));
        elementFound = false;
        return XmlElement(XmlName(''));
      },
    );

    if (elementFound) {
      final index =
          dict.children.indexOf(uIViewControllerBasedStatusBarAppearance);

      final uIViewControllerBasedStatusBarAppearanceValue = dict
          .children[index + 1].following
          .firstWhere((element) => element.nodeType == XmlNodeType.ELEMENT);
      uIViewControllerBasedStatusBarAppearanceValue
          .replace(XmlElement(XmlName('false')));
    }
  }

  file.writeAsStringSync(
    '${xmlDocument.toXmlString(pretty: true, indent: '	')}\n',
  );
}
