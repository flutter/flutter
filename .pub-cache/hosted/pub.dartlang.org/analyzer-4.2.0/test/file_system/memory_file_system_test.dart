// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/generated/engine.dart' show TimestampedData;
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:watcher/watcher.dart';

import 'file_system_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FileSystemExceptionTest);
    defineReflectiveTests(MemoryFileSourceExistingTest);
    defineReflectiveTests(MemoryFileSourceNotExistingTest);
    defineReflectiveTests(MemoryFileTest);
    defineReflectiveTests(MemoryFolderTest);
    defineReflectiveTests(MemoryResourceProviderTest);
  });
}

abstract class BaseTest extends FileSystemTestSupport {
  /// The resource provider to be used by the tests. Tests should use [provider]
  /// to access the resource provider.
  MemoryResourceProvider? _provider;

  /// The absolute path to the temporary directory in which all of the tests are
  /// to work.
  @override
  late final String tempPath;

  /// A path to a folder within the [tempPath] that can be used by tests.
  @override
  late final String defaultFolderPath;

  /// A path to a file within the [defaultFolderPath] that can be used by tests.
  @override
  late final String defaultFilePath;

  /// The content used for the file at the [defaultFilePath] if it is created
  /// and no other content is provided.
  @override
  String get defaultFileContent => 'a';

  @override
  bool get hasSymbolicLinkSupport => true;

  /// Return the resource provider to be used by the tests.
  @override
  MemoryResourceProvider get provider => _provider ??= createProvider();

  @override
  void createLink({required String path, required String target}) {
    provider.newLink(path, target);
  }

  /// Create the resource provider to be used by the tests. Subclasses can
  /// override this method to change the class of resource provider that is
  /// used.
  MemoryResourceProvider createProvider() => MemoryResourceProvider();

  @override
  File getFile({required bool exists, String? content, String? filePath}) {
    if (filePath == null) {
      filePath = defaultFilePath;
    } else {
      filePath = provider.convertPath(filePath);
    }
    if (exists) {
      provider.newFile(filePath, content ?? defaultFileContent);
    }
    return provider.getFile(filePath);
  }

  @override
  Folder getFolder({required bool exists, String? folderPath}) {
    if (folderPath == null) {
      folderPath = defaultFolderPath;
    } else {
      folderPath = provider.convertPath(folderPath);
    }
    if (exists) {
      provider.newFolder(folderPath);
    }
    return provider.getFolder(folderPath);
  }

  setUp() {
    tempPath = provider.convertPath('/temp');
    defaultFolderPath = join(tempPath, 'bar');
    defaultFilePath = join(tempPath, 'bar', 'test.dart');
  }
}

@reflectiveTest
class FileSystemExceptionTest {
  test_constructor() {
    var exception = FileSystemException('/my/path', 'my message');
    expect(exception.path, '/my/path');
    expect(exception.message, 'my message');
    expect(exception.toString(),
        'FileSystemException(path=/my/path; message=my message)');
  }
}

@reflectiveTest
class MemoryFileSourceExistingTest extends BaseTest {
  late final String sourcePath;
  late final Source source;

  @override
  setUp() {
    super.setUp();
    File file = getFile(exists: true);
    sourcePath = file.path;
    source = file.createSource();
  }

  test_contents() {
    TimestampedData<String> contents = source.contents;
    expect(contents.data, defaultFileContent);
  }

  test_equals_false_differentFile() {
    File fileA = getFile(exists: false, filePath: join(tempPath, 'a.dart'));
    File fileB = getFile(exists: false, filePath: join(tempPath, 'b.dart'));
    Source sourceA = fileA.createSource();
    Source sourceB = fileB.createSource();

    expect(sourceA == sourceB, isFalse);
  }

  test_equals_false_notMemorySource() {
    expect(source == Object(), isFalse);
  }

  test_equals_true_sameFile() {
    Source sourceA = getFile(exists: false).createSource();
    Source sourceB = getFile(exists: false).createSource();

    expect(sourceA == sourceB, isTrue);
  }

  test_equals_true_self() {
    expect(source == source, isTrue);
  }

  test_exists() {
    expect(source.exists(), isTrue);
  }

  test_fullName() {
    expect(source.fullName, sourcePath);
  }

  test_hashCode() {
    expect(source.hashCode, isNotNull);
  }

  test_resolveRelative() {
    Uri relative = resolveRelativeUri(
        source.uri,
        provider.pathContext
            .toUri(provider.pathContext.join('bar', 'baz.dart')));
    expect(
        relative,
        provider.pathContext
            .toUri(provider.convertPath('/temp/bar/bar/baz.dart')));
  }

  test_resolveRelative_dart() {
    File file = getFile(
        exists: false,
        filePath: provider.convertPath('/sdk/lib/core/core.dart'));
    Source source = file.createSource(Uri.parse('dart:core'));

    Uri resolved = resolveRelativeUri(source.uri, Uri.parse('int.dart'));
    expect(resolved.toString(), 'dart:core/int.dart');
  }

  test_shortName() {
    expect(source.shortName, 'test.dart');
  }
}

@reflectiveTest
class MemoryFileSourceNotExistingTest extends BaseTest {
  late final String sourcePath;
  late final Source source;

  @override
  setUp() {
    super.setUp();
    File file = getFile(exists: false);
    sourcePath = file.path;
    source = file.createSource();
  }

  test_contents() {
    expect(() => source.contents, throwsA(isFileSystemException));
  }

  test_exists() {
    expect(source.exists(), isFalse);
  }

  test_fullName() {
    expect(source.fullName, sourcePath);
  }

  test_resolveRelative() {
    Uri relative = resolveRelativeUri(
        source.uri,
        provider.pathContext
            .toUri(provider.pathContext.join('bar', 'baz.dart')));
    expect(
        relative,
        provider.pathContext
            .toUri(provider.convertPath('/temp/bar/bar/baz.dart')));
  }

  test_shortName() {
    expect(source.shortName, 'test.dart');
  }
}

@reflectiveTest
class MemoryFileTest extends BaseTest with FileTestMixin {
  @override
  test_delete_notExisting() {
    File file = getFile(exists: false);
    expect(file.exists, isFalse);

    expect(
      () => file.delete(),
      throwsFileSystemException,
    );
  }

  @override
  test_renameSync_notExisting() {
    String oldPath = join(tempPath, 'file.txt');
    String newPath = join(tempPath, 'new-file.txt');
    File oldFile = getFile(exists: true, filePath: oldPath);

    File newFile = oldFile.renameSync(newPath);
    expect(oldFile.path, oldPath);
    expect(oldFile.exists, isFalse);
    expect(newFile.path, newPath);
    expect(newFile.exists, isTrue);
    expect(newFile.readAsStringSync(), defaultFileContent);
  }

  @override
  test_writeAsBytesSync_notExisting() {
    File file = getFile(exists: false);

    var bytes = Uint8List.fromList([99, 99]);
    file.writeAsBytesSync(bytes);
    expect(file.exists, true);
    expect(file.readAsBytesSync(), bytes);
  }

  @override
  test_writeAsStringSync_notExisting() {
    File file = getFile(exists: false);

    file.writeAsStringSync('cc');
    expect(file.exists, true);
    expect(file.readAsStringSync(), 'cc');
  }
}

@reflectiveTest
class MemoryFolderTest extends BaseTest with FolderTestMixin {
  test_isRoot_false() {
    var path = provider.convertPath('/foo');
    expect(provider.getFolder(path).isRoot, isFalse);
  }

  test_isRoot_true() {
    var path = provider.convertPath('/');
    expect(provider.getFolder(path).isRoot, isTrue);
  }
}

@reflectiveTest
class MemoryResourceProviderTest extends BaseTest
    with ResourceProviderTestMixin {
  test_deleteFile_existing() {
    File file = getFile(exists: true);
    expect(file.exists, isTrue);

    provider.deleteFile(defaultFilePath);
    expect(file.exists, isFalse);
  }

  test_deleteFile_folder() {
    Folder folder = getFolder(exists: true);

    expect(
      () => provider.deleteFile(defaultFolderPath),
      throwsFileSystemException,
    );
    expect(folder.exists, isTrue);
  }

  test_deleteFile_notExisting() {
    File file = getFile(exists: false);

    expect(
      () => provider.deleteFile(defaultFilePath),
      throwsFileSystemException,
    );
    expect(file.exists, isFalse);
  }

  test_modifyFile_existing_file() {
    File file = getFile(exists: true);

    provider.modifyFile(file.path, 'contents 2');
    expect(file.readAsStringSync(), 'contents 2');
  }

  test_modifyFile_existing_folder() {
    getFolder(exists: true);

    expect(
      () => provider.modifyFile(defaultFolderPath, 'contents'),
      throwsFileSystemException,
    );
    expect(provider.getResource(defaultFolderPath), isFolder);
  }

  test_modifyFile_notExisting() {
    getFile(exists: false);

    expect(
      () => provider.modifyFile(defaultFilePath, 'contents'),
      throwsFileSystemException,
    );
    Resource file = provider.getResource(defaultFilePath);
    expect(file, isFile);
    expect(file.exists, isFalse);
  }

  test_newFileWithBytes() {
    var bytes = Uint8List.fromList([1, 2, 3, 4, 5]);

    provider.newFileWithBytes(defaultFilePath, bytes);
    Resource file = provider.getResource(defaultFilePath);
    expect(file, isFile);
    expect(file.exists, isTrue);
    expect((file as File).readAsBytesSync(), bytes);
  }

  test_newFolder_emptyPath() {
    expect(() => provider.newFolder(''), throwsArgumentError);
  }

  test_newFolder_existing_file() {
    getFile(exists: true);

    expect(
      () => provider.newFolder(defaultFilePath),
      throwsFileSystemException,
    );
  }

  test_newFolder_existing_folder() {
    Folder folder = getFolder(exists: true);

    Folder newFolder = provider.newFolder(folder.path);
    expect(newFolder, folder);
  }

  test_newFolder_notAbsolute() {
    expect(() => provider.newFolder('not/absolute'), throwsArgumentError);
  }

  test_newLink_folder() {
    provider.newLink(
      provider.convertPath('/test/lib/foo'),
      provider.convertPath('/test/lib'),
    );

    provider.newFile(
      provider.convertPath('/test/lib/a.dart'),
      'aaa',
    );

    {
      var path = '/test/lib/foo/a.dart';
      var convertedPath = provider.convertPath(path);
      var file = provider.getFile(convertedPath);
      expect(file.exists, true);
      expect(file.modificationStamp, isNonNegative);
      expect(file.readAsStringSync(), 'aaa');
    }

    {
      var path = '/test/lib/foo/foo/a.dart';
      var convertedPath = provider.convertPath(path);
      var file = provider.getFile(convertedPath);
      expect(file.exists, true);
      expect(file.modificationStamp, isNonNegative);
      expect(file.readAsStringSync(), 'aaa');
    }
  }

  @override
  test_pathContext() {
    if (path.style == path.Style.windows) {
      // On Windows the path context is replaced by one whose current directory
      // is the root of the 'C' drive.
      path.Context context = provider.pathContext;
      expect(context.style, path.Style.windows);
      expect(context.current, 'C:\\');
    } else {
      super.test_pathContext();
    }
  }

  test_watch_createFile() {
    String rootPath = provider.convertPath('/my/path');
    provider.newFolder(rootPath);
    return _watchingFolder(rootPath, (changesReceived) {
      expect(changesReceived, hasLength(0));
      String path = provider.pathContext.join(rootPath, 'foo');

      provider.newFile(path, 'contents');
      return _delayed(() {
        expect(changesReceived, hasLength(1));
        expect(changesReceived[0].type, equals(ChangeType.ADD));
        expect(changesReceived[0].path, equals(path));
      });
    });
  }

  test_watch_deleteFile() {
    String rootPath = provider.convertPath('/my/path');
    provider.newFolder(rootPath);
    String path = provider.pathContext.join(rootPath, 'foo');
    provider.newFile(path, 'contents 1');
    return _watchingFolder(rootPath, (changesReceived) {
      expect(changesReceived, hasLength(0));

      provider.deleteFile(path);
      return _delayed(() {
        expect(changesReceived, hasLength(1));
        expect(changesReceived[0].type, equals(ChangeType.REMOVE));
        expect(changesReceived[0].path, equals(path));
      });
    });
  }

  test_watch_modifyFile() {
    String rootPath = provider.convertPath('/my/path');
    provider.newFolder(rootPath);
    String path = provider.pathContext.join(rootPath, 'foo');
    provider.newFile(path, 'contents 1');
    return _watchingFolder(rootPath, (changesReceived) {
      expect(changesReceived, hasLength(0));

      provider.modifyFile(path, 'contents 2');
      return _delayed(() {
        expect(changesReceived, hasLength(1));
        expect(changesReceived[0].type, equals(ChangeType.MODIFY));
        expect(changesReceived[0].path, equals(path));
      });
    });
  }

  test_watch_modifyFile_inSubDir() {
    String rootPath = provider.convertPath('/my/path');
    provider.newFolder(rootPath);
    String subdirPath = provider.pathContext.join(rootPath, 'foo');
    provider.newFolder(subdirPath);
    String path = provider.pathContext.join(rootPath, 'bar');
    provider.newFile(path, 'contents 1');
    return _watchingFolder(rootPath, (changesReceived) {
      expect(changesReceived, hasLength(0));

      provider.modifyFile(path, 'contents 2');
      return _delayed(() {
        expect(changesReceived, hasLength(1));
        expect(changesReceived[0].type, equals(ChangeType.MODIFY));
        expect(changesReceived[0].path, equals(path));
      });
    });
  }

  Future _delayed(Function() computation) {
    return Future.delayed(Duration.zero, computation);
  }

  _watchingFolder(
      String path, Function(List<WatchEvent> changesReceived) test) {
    var folder = provider.getResource(path) as Folder;
    var changesReceived = <WatchEvent>[];
    folder.watch().changes.listen(changesReceived.add);
    return test(changesReceived);
  }
}
