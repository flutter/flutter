import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:platform/platform.dart' show LocalPlatform, Platform;

import './prepare_package.dart';

void main() {
  const Platform platform = LocalPlatform();
  const FileSystem fs = LocalFileSystem();
  final Directory dir = fs.systemTempDirectory.createTempSync();
  const String revision = 'abc123';
  const String version = 'x.y.z';
  final File outputFile = dir.childFile('yolo.dawg')..createSync();
  final ArchivePublisher publisher = ArchivePublisher(
    dir,
    revision,
    Branch.dev,
    version,
    outputFile,
    false, // dryRun
    subprocessOutput: true,
  );
  publisher.updateMetadata(
    '$newGsReleaseFolder/${ArchivePublisher.getMetadataFilename(platform)}',
    baseUrl: 'blah',
  );
}
