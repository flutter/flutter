

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/add_to_path.dart';
import 'package:mockito/mockito.dart';
import 'package:platform/platform.dart';

import '../../src/common.dart';
import '../../src/context.dart';

final Platform platform = FakePlatform(operatingSystem: 'linux', environment: <String, String>{
  'HOME': 'HOME/'
});

void main() {
  setUpAll(() {
    Cache.disableLocking();
  });

  testUsingContext('Adds flutter to .bashrc on linux if it exists', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final BufferLogger logger = BufferLogger.test();
    final AddToPathCommand command = AddToPathCommand(
      platform: platform,
      logger: logger,
      fileSystem: fileSystem,
    );

    final File bashRc = fileSystem.file('HOME/.bashrc')
      ..createSync(recursive: true);

    await createTestCommandRunner(command).run(<String>[
      'add-to-path',
    ]);

    expect(bashRc.readAsStringSync(), contains(kExportHeader));
  });

  testUsingContext('Exits on an unsupported platform', () async {
    final FileSystem fileSystem = MemoryFileSystem.test();
    final BufferLogger logger = BufferLogger.test();
    final AddToPathCommand command = AddToPathCommand(
      platform: FakePlatform(operatingSystem: 'fuchsia'),
      logger: logger,
      fileSystem: fileSystem,
    );

    expect(createTestCommandRunner(command).run(<String>[
      'add-to-path',
    ]), throwsToolExit());
  });
}

class MockLogger extends Mock implements Logger {}
