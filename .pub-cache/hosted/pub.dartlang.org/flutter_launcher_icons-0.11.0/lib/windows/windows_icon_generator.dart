import 'package:flutter_launcher_icons/abs/icon_generator.dart';
import 'package:flutter_launcher_icons/constants.dart' as constants;
import 'package:flutter_launcher_icons/custom_exceptions.dart';
import 'package:flutter_launcher_icons/utils.dart' as utils;
import 'package:image/image.dart';
import 'package:path/path.dart' as path;

/// A Implementation of [IconGenerator] for Windows
class WindowsIconGenerator extends IconGenerator {
  /// Creates a instance of [WindowsIconGenerator]
  WindowsIconGenerator(IconGeneratorContext context)
      : super(context, 'Windows');

  @override
  void createIcons() {
    final imgFilePath = path.join(
      context.prefixPath,
      context.windowsConfig!.imagePath ?? context.config.imagePath,
    );

    context.logger
        .verbose('Decoding and loading image file from $imgFilePath...');
    final imgFile = utils.decodeImageFile(imgFilePath);
    // TODO(RatakondalaArun): remove null check
    // #utils.decodeImageFile never returns null instead it throws Exception
    if (imgFile == null) {
      context.logger
          .error('Image File not found at given path $imgFilePath...');
      throw FileNotFoundException(imgFilePath);
    }

    context.logger.verbose('Generating icon from $imgFilePath...');
    _generateIcon(imgFile);
  }

  @override
  bool validateRequirements() {
    context.logger.verbose('Validating windows config...');
    final windowsConfig = context.windowsConfig;
    if (windowsConfig == null || !windowsConfig.generate) {
      context.logger.error(
        'Windows config is not provided or windows.generate is false. Skipped...',
      );
      return false;
    }

    if (windowsConfig.imagePath == null && context.config.imagePath == null) {
      context.logger.error(
        'Invalid config. Either provide windows.image_path or image_path',
      );
      return false;
    }

    // if icon_size is given it should be between 48<=icon_size<=256
    // because .ico only supports this size
    if (windowsConfig.iconSize != null &&
        (windowsConfig.iconSize! < 48 || windowsConfig.iconSize! > 256)) {
      context.logger.error(
        'Invalid windows.icon_size=${windowsConfig.iconSize}. Icon size should be between 48<=icon_size<=256',
      );
      return false;
    }
    final entitesToCheck = [
      path.join(context.prefixPath, constants.windowsDirPath),
      path.join(
        context.prefixPath,
        windowsConfig.imagePath ?? context.config.imagePath,
      ),
    ];

    final failedEntityPath = utils.areFSEntiesExist(entitesToCheck);
    if (failedEntityPath != null) {
      context.logger.error(
        '$failedEntityPath this file or folder is required to generate web icons',
      );
      return false;
    }

    return true;
  }

  void _generateIcon(Image image) {
    final favIcon = utils.createResizedImage(
      context.windowsConfig!.iconSize ?? constants.windowsDefaultIconSize,
      image,
    );
    final favIconFile = utils.createFileIfNotExist(
      path.join(context.prefixPath, constants.windowsIconFilePath),
    );
    favIconFile.writeAsBytesSync(encodeIco(favIcon));
  }
}
