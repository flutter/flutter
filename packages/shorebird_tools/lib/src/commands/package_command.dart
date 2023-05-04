import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;

/// {@template package_command}
///
/// `shorebird_tools package`
/// A [Command] that packages a generated patch into an archive
/// {@endtemplate}
class PackageCommand extends Command<int> {
  /// {@macro package_command}
  PackageCommand({
    required Logger logger,
  }) : _logger = logger {
    argParser
      ..addOption(
        'patch',
        abbr: 'p',
        mandatory: true,
        help: 'The path to the patch artifact which will be packaged',
      )
      ..addOption(
        'output',
        abbr: 'o',
        mandatory: true,
        help: 'Where to write the packaged patch archive',
      );
  }

  @override
  String get description => 'Packages a patch artifact into an archive';

  @override
  String get name => 'package';

  final Logger _logger;

  @override
  Future<int> run() async {
    final patchFilePath = argResults!['patch'] as String;
    final outFilePath = argResults!['output'] as String;

    final patchFile = File(patchFilePath);
    if (!patchFile.existsSync()) {
      _logger.err('Patch file not found at $patchFilePath');
      return ExitCode.software.code;
    }

    final outFile = File(outFilePath);

    final bytes = patchFile.readAsBytesSync();
    final archiveFile = ArchiveFile(
      p.basename(patchFilePath),
      bytes.length,
      bytes,
    );

    ZipEncoder()
      ..startEncode(OutputFileStream(outFile.absolute.path))
      ..addFile(archiveFile)
      ..endEncode();

    _logger.info('Packaged patch at $patchFilePath to $outFilePath');

    return ExitCode.success.code;
  }
}
