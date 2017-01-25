import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:test/test.dart';

void main() {
  group('file_system', () {
    /// Test file_systems.copyDirectorySync() using MemoryFileSystem.
    test('test directory copy', () async {
      MemoryFileSystem memoryFs = new MemoryFileSystem();
      String sourcePath = '/some/origin';
      Directory sourceDirectory = await memoryFs.directory(sourcePath).create(recursive: true);
      memoryFs.currentDirectory = sourcePath;
      (await memoryFs.file('some_file.txt').create()).writeAsStringSync('bleh');
      memoryFs.file('sub_dir/another_file.txt').createSync(recursive: true);
      memoryFs.directory('empty_directory').createSync();

      String targetPath = '/some/non-existent/target';
      Directory targetDirectory = memoryFs.directory(targetPath);
      copyDirectorySync(sourceDirectory, targetDirectory);
      expect(targetDirectory.existsSync(), true);
      memoryFs.currentDirectory = targetPath;
      expect(memoryFs.directory('empty_directory').existsSync(), true);
      expect(memoryFs.file('sub_dir/another_file.txt').existsSync(), true);
      expect(memoryFs.file('some_file.txt').readAsStringSync(), 'bleh');
    });
  });
}
