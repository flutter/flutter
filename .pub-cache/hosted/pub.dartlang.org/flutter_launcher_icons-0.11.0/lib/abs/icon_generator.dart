import 'dart:io';

import 'package:flutter_launcher_icons/flutter_launcher_icons_config.dart';
import 'package:flutter_launcher_icons/logger.dart';

/// A base class to generate icons
abstract class IconGenerator {
  /// Contains config
  final IconGeneratorContext context;

  /// Name of the platform this [IconGenerator] is created for.
  final String platformName;

  /// Creates a instance of [IconGenerator].
  ///
  /// A [context] is created and provided by [generateIconsFor],
  /// [platformName] takes the name of the platform that this [IconGenerator]
  /// is implemented for
  ///
  /// Also Refer
  /// - [WebIconGenerator] generate icons for web
  /// - [generateIconFor] generates icons for given platform
  IconGenerator(this.context, this.platformName);

  /// Creates icons for this platform.
  void createIcons();

  /// Should return `true` if this platform
  /// has all the requirements to create icons.
  /// This runs before to [createIcons]
  bool validateRequirements();
}

/// Provides easy access to user arguments and configuration
class IconGeneratorContext {
  /// Contains configuration from configuration file
  final FlutterLauncherIconsConfig config;

  /// A logger
  final FLILogger logger;

  /// Value of `--prefix` flag
  final String prefixPath;

  /// Value of `--flavor` flag
  final String? flavor;

  /// Creates an instance of [IconGeneratorContext]
  IconGeneratorContext({
    required this.config,
    required this.logger,
    required this.prefixPath,
    this.flavor,
  });

  /// Shortcut for `config.webConfig`
  WebConfig? get webConfig => config.webConfig;

  /// Shortcut for `config.windowsConfig`
  WindowsConfig? get windowsConfig => config.windowsConfig;

  /// Shortcut for `config.macOSConfig`
  MacOSConfig? get macOSConfig => config.macOSConfig;
}

/// Generates Icon for given platforms
void generateIconsFor({
  required FlutterLauncherIconsConfig config,
  required String? flavor,
  required String prefixPath,
  required FLILogger logger,
  required List<IconGenerator> Function(IconGeneratorContext context) platforms,
}) {
  try {
    final platformList = platforms(
      IconGeneratorContext(
        config: config,
        logger: logger,
        prefixPath: prefixPath,
        flavor: flavor,
      ),
    );
    if (platformList.isEmpty) {
      // ? maybe we can print help
      logger.info('No platform provided');
    }

    for (final platform in platformList) {
      final progress =
          logger.progress('Creating Icons for ${platform.platformName}');
      logger.verbose(
        'Validating platform requirements for ${platform.platformName}',
      );
      // in case a platform throws an exception it should not effect other platforms
      try {
        if (!platform.validateRequirements()) {
          logger.error(
            'Requirements failed for platform ${platform.platformName}. Skipped',
          );
          progress.cancel();
          continue;
        }
        platform.createIcons();
        progress.finish(message: 'done', showTiming: true);
      } catch (e, st) {
        progress.cancel();
        logger
          ..error(e.toString())
          ..verbose(st);
        continue;
      }
    }
  } catch (e, st) {
    // todo: better error handling
    // stacktrace should only print when verbose is turned on
    // else a normal help line
    logger
      ..error(e.toString())
      ..verbose(st);
    exit(1);
  }
}
