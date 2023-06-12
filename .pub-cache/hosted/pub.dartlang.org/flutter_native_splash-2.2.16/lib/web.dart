part of flutter_native_splash_cli;

// Image template
class _WebLaunchImageTemplate {
  final String fileName;
  final double pixelDensity;

  _WebLaunchImageTemplate({required this.fileName, required this.pixelDensity});
}

/// Create Web splash screen
void _createWebSplash({
  required String? imagePath,
  required String? darkImagePath,
  required String? color,
  required String? darkColor,
  required String? brandingImagePath,
  required String? brandingDarkImagePath,
  required String imageMode,
  required String brandingMode,
  required String? backgroundImage,
  required String? darkBackgroundImage,
}) {
  if (!File(_webIndex).existsSync()) {
    print('[Web] $_webIndex not found.  Skipping Web.');
    return;
  }

  darkImagePath ??= imagePath;
  _createWebImages(
    imagePath: imagePath,
    webSplashImages: [
      _WebLaunchImageTemplate(fileName: 'light-1x.png', pixelDensity: 1),
      _WebLaunchImageTemplate(fileName: 'light-2x.png', pixelDensity: 2),
      _WebLaunchImageTemplate(fileName: 'light-3x.png', pixelDensity: 3),
      _WebLaunchImageTemplate(fileName: 'light-4x.png', pixelDensity: 4),
    ],
  );
  _createWebImages(
    imagePath: darkImagePath,
    webSplashImages: [
      _WebLaunchImageTemplate(fileName: 'dark-1x.png', pixelDensity: 1),
      _WebLaunchImageTemplate(fileName: 'dark-2x.png', pixelDensity: 2),
      _WebLaunchImageTemplate(fileName: 'dark-3x.png', pixelDensity: 3),
      _WebLaunchImageTemplate(fileName: 'dark-4x.png', pixelDensity: 4),
    ],
  );

  brandingDarkImagePath ??= brandingImagePath;
  _createWebImages(
    imagePath: brandingImagePath,
    webSplashImages: [
      _WebLaunchImageTemplate(fileName: 'branding-1x.png', pixelDensity: 1),
      _WebLaunchImageTemplate(fileName: 'branding-2x.png', pixelDensity: 2),
      _WebLaunchImageTemplate(fileName: 'branding-3x.png', pixelDensity: 3),
      _WebLaunchImageTemplate(fileName: 'branding-4x.png', pixelDensity: 4),
    ],
  );
  _createWebImages(
    imagePath: brandingDarkImagePath,
    webSplashImages: [
      _WebLaunchImageTemplate(
        fileName: 'branding-dark-1x.png',
        pixelDensity: 1,
      ),
      _WebLaunchImageTemplate(
        fileName: 'branding-dark-2x.png',
        pixelDensity: 2,
      ),
      _WebLaunchImageTemplate(
        fileName: 'branding-dark-3x.png',
        pixelDensity: 3,
      ),
      _WebLaunchImageTemplate(
        fileName: 'branding-dark-4x.png',
        pixelDensity: 4,
      ),
    ],
  );

  createBackgroundImages(
    backgroundImage: backgroundImage,
    darkBackgroundImage: darkBackgroundImage,
  );
  _createSplashCss(
    color: color,
    darkColor: darkColor,
    darkBackgroundImage: darkBackgroundImage,
    backgroundImage: backgroundImage,
    hasDarkImage: darkBackgroundImage != null,
  );
  _createSplashJs();
  _updateHtml(
    imageMode: imageMode,
    imagePath: imagePath,
    brandingMode: brandingMode,
    brandingImagePath: brandingImagePath,
  );
}

void createBackgroundImages({
  required String? backgroundImage,
  required String? darkBackgroundImage,
}) {
  print('[Web] Creating background images');
  _createBackgroundImage(
    backgroundImage: backgroundImage,
    fileName: "light-background.png",
  );
  _createBackgroundImage(
    backgroundImage: darkBackgroundImage,
    fileName: "dark-background.png",
  );
}

void _createBackgroundImage({
  required String? backgroundImage,
  required String fileName,
}) {
  final backgroundDestination = '$_webSplashImagesFolder$fileName';
  if (backgroundImage == null) {
    final file = File(backgroundDestination);
    if (file.existsSync()) file.deleteSync();
  } else {
    createBackgroundImage(
      imageDestination: backgroundDestination,
      imageSource: backgroundImage,
    );
  }
}

void _createWebImages({
  required String? imagePath,
  required List<_WebLaunchImageTemplate> webSplashImages,
}) {
  if (imagePath == null) {
    for (final template in webSplashImages) {
      final file = File(_webSplashImagesFolder + template.fileName);
      if (file.existsSync()) file.deleteSync();
    }
  } else {
    final image = decodeImage(File(imagePath).readAsBytesSync());
    if (image == null) {
      print('$imagePath could not be read');
      exit(1);
    }
    print('[Web] Creating images');
    for (final template in webSplashImages) {
      _saveImageWeb(template: template, image: image);
    }
  }
}

void _saveImageWeb({
  required _WebLaunchImageTemplate template,
  required Image image,
}) {
  final newFile = copyResize(
    image,
    width: image.width * template.pixelDensity ~/ 4,
    height: image.height * template.pixelDensity ~/ 4,
    interpolation: Interpolation.linear,
  );

  final file = File(_webSplashImagesFolder + template.fileName);
  file.createSync(recursive: true);
  file.writeAsBytesSync(encodePng(newFile));
}

void _createSplashCss({
  required String? color,
  required String? darkColor,
  required String? backgroundImage,
  required String? darkBackgroundImage,
  required bool hasDarkImage,
}) {
  print('[Web] Creating CSS');
  color ??= 'ffffff';
  var cssContent = _webCss.replaceFirst('[LIGHTBACKGROUNDCOLOR]', '#$color');
  if (darkColor != null || darkBackgroundImage != null || hasDarkImage) {
    darkColor ??= '000000';
    cssContent +=
        _webCssDark.replaceFirst('[DARKBACKGROUNDCOLOR]', '#$darkColor');
  }

  if (backgroundImage == null) {
    cssContent = cssContent.replaceFirst('  [LIGHTBACKGROUNDIMAGE]\n', '');
  } else {
    cssContent = cssContent.replaceFirst(
      '[LIGHTBACKGROUNDIMAGE]',
      'background-image: url("img/light-background.png");',
    );
  }

  if (backgroundImage == null) {
    cssContent = cssContent.replaceFirst('    [DARKBACKGROUNDIMAGE]\n', '');
  } else {
    cssContent = cssContent.replaceFirst(
      '[DARKBACKGROUNDIMAGE]',
      'background-image: url("img/dark-background.png");',
    );
  }

  final file = File(_webFolder + _webRelativeStyleFile);
  file.createSync(recursive: true);
  file.writeAsStringSync(cssContent);
}

void _createSplashJs() {
  final file = File(_webFolder + _webRelativeJSFile);
  file.createSync(recursive: true);
  file.writeAsStringSync(_webJS);
}

void _updateHtml({
  required String imageMode,
  required String? imagePath,
  required String brandingMode,
  required String? brandingImagePath,
}) {
  print('[Web] Updating index.html');
  final webIndex = File(_webIndex);
  final document = html_parser.parse(webIndex.readAsStringSync());

  // Add style sheet if it doesn't exist
  document.querySelector(
        'link[rel="stylesheet"][type="text/css"][href="splash/style.css"]',
      ) ??
      document.head?.append(
        html_parser.parseFragment(
          '  <link rel="stylesheet" type="text/css" href="splash/style.css">\n',
          container: '',
        ),
      );

  // Add meta viewport if it doesn't exist
  document.querySelector(
        'meta[content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no"][name="viewport"]',
      ) ??
      document.head?.append(
        html_parser.parseFragment(
          '  <meta content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" name="viewport">\n',
          container: '',
        ),
      );

  // Add javascript if it doesn't exist
  document.querySelector(
        'script[src="splash/splash.js"]',
      ) ??
      document.head?.append(
        html_parser.parseFragment(
          '  <script src="splash/splash.js"></script>\n',
          container: '',
        ),
      );

  // Update splash image
  document.querySelector('picture#splash')?.remove();
  if (imagePath != null) {
    document.body?.insertBefore(
      html_parser.parseFragment(
        _indexHtmlPicture.replaceAll('[IMAGEMODE]', imageMode),
        container: '',
      ),
      document.body?.firstChild,
    );
  }

  // Update branding image
  document.querySelector('picture#splash-branding')?.remove();
  if (brandingImagePath != null) {
    document.body?.insertBefore(
      html_parser.parseFragment(
        _indexHtmlBrandingPicture.replaceAll('[BRANDINGMODE]', brandingMode),
        container: '',
      ),
      document.body?.firstChild,
    );
  }

  // Write the updated index.html
  webIndex.writeAsStringSync(document.outerHtml);
}
