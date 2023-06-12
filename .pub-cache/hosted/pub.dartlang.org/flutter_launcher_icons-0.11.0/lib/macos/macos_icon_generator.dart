import 'dart:convert';
import 'dart:io';

import 'package:flutter_launcher_icons/abs/icon_generator.dart';
import 'package:flutter_launcher_icons/constants.dart' as constants;
import 'package:flutter_launcher_icons/custom_exceptions.dart';
import 'package:flutter_launcher_icons/macos/macos_icon_template.dart';
import 'package:flutter_launcher_icons/utils.dart' as utils;
import 'package:image/image.dart';
import 'package:path/path.dart' as path;

/// A [IconGenerator] implementation for macos
class MacOSIconGenerator extends IconGenerator {
  static const _iconSizeTemplates = <MacOSIconTemplate>[
    MacOSIconTemplate(16, 1),
    MacOSIconTemplate(16, 2),
    MacOSIconTemplate(32, 1),
    MacOSIconTemplate(32, 2),
    MacOSIconTemplate(128, 1),
    MacOSIconTemplate(128, 2),
    MacOSIconTemplate(256, 1),
    MacOSIconTemplate(256, 2),
    MacOSIconTemplate(512, 1),
    MacOSIconTemplate(512, 2),
  ];

  /// Creates a instance of [MacOSIconGenerator]
  MacOSIconGenerator(IconGeneratorContext context) : super(context, 'MacOS');

  @override
  void createIcons() {
    final imgFilePath = path.join(
      context.prefixPath,
      context.config.macOSConfig!.imagePath ?? context.config.imagePath,
    );

    context.logger
        .verbose('Decoding and loading image file at $imgFilePath...');
    final imgFile = utils.decodeImageFile(imgFilePath);
    if (imgFile == null) {
      context.logger.error('Image File not found at give path $imgFilePath...');
      throw FileNotFoundException(imgFilePath);
    }

    context.logger.verbose('Generating icons $imgFilePath...');
    _generateIcons(imgFile);
    context.logger.verbose('Updating contents.json');
    _updateContentsFile();
  }

  @override
  bool validateRequirements() {
    context.logger.verbose('Checking $platformName config...');
    final macOSConfig = context.macOSConfig;

    if (macOSConfig == null || !macOSConfig.generate) {
      context.logger
        ..verbose(
          '$platformName config is missing or "flutter_icons.macos.generate" is false. Skipped...',
        )
        ..verbose(macOSConfig);
      return false;
    }

    if (macOSConfig.imagePath == null && context.config.imagePath == null) {
      context.logger
        ..verbose({
          'flutter_icons.macos.image_path': macOSConfig.imagePath,
          'flutter_icons.image_path': context.config.imagePath,
        })
        ..error(
          'Missing image_path. Either provide "flutter_icons.macos.image_path" or "flutter_icons.image_path"',
        );

      return false;
    }

    // this files and folders should exist to create macos icons
    final enitiesToCheck = [
      path.join(context.prefixPath, constants.macOSDirPath),
      path.join(context.prefixPath, constants.macOSIconsDirPath),
      path.join(context.prefixPath, constants.macOSContentsFilePath),
    ];

    final failedEntityPath = utils.areFSEntiesExist(enitiesToCheck);
    if (failedEntityPath != null) {
      context.logger.error(
        '$failedEntityPath this file or folder is required to generate $platformName icons',
      );
      return false;
    }

    return true;
  }

  void _generateIcons(Image image) {
    final iconsDir = utils.createDirIfNotExist(
      path.join(context.prefixPath, constants.macOSIconsDirPath),
    );

    for (final template in _iconSizeTemplates) {
      final resizedImg = utils.createResizedImage(template.scaledSize, image);
      final iconFile = utils.createFileIfNotExist(
        path.join(context.prefixPath, iconsDir.path, template.iconFile),
      );
      iconFile.writeAsBytesSync(encodePng(resizedImg));
    }
  }

  void _updateContentsFile() {
    final contentsFilePath =
        File(path.join(context.prefixPath, constants.macOSContentsFilePath));
    final contentsConfig =
        jsonDecode(contentsFilePath.readAsStringSync()) as Map<String, dynamic>;
    contentsConfig
      ..remove('images')
      ..['images'] = _iconSizeTemplates
          .map<Map<String, dynamic>>((e) => e.iconContent)
          .toList();

    contentsFilePath
        .writeAsStringSync(utils.prettifyJsonEncode(contentsConfig));
  }
}
