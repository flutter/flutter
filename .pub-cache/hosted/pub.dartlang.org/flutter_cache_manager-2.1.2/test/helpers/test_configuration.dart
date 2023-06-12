import 'package:file/file.dart' show File;
import 'package:file/memory.dart';
import 'package:flutter_cache_manager/src/config/config.dart';
import 'package:flutter_cache_manager/src/storage/file_system/file_system.dart';

import 'mock_cache_info_repository.dart';
import 'mock_file_service.dart';

Config createTestConfig() {
  return Config(
    'test',
    fileSystem: TestFileSystem(),
    repo: MockCacheInfoRepository(),
    fileService: MockFileService(),
  );
}

class TestFileSystem extends FileSystem {
  final directoryFuture =
      MemoryFileSystem().systemTempDirectory.createTemp('test');
  @override
  Future<File> createFile(String name) async {
    var dir = await directoryFuture;
    await dir.create(recursive: true);
    return dir.childFile(name);
  }
}
