// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/file_system/overlay_file_system.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'file_system_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FileTest);
    defineReflectiveTests(FolderTest);
    defineReflectiveTests(OverlayResourceProviderTest);
  });
}

final _isFile = TypeMatcher<File>();
final _isFileSystemException = TypeMatcher<FileSystemException>();
final _isFolder = TypeMatcher<Folder>();

@reflectiveTest
class FileTest extends OverlayTestSupport {
  @failingTest
  test_changes() {
    // TODO(brianwilkerson) Implement this.
    fail('Not tested');
  }

  test_copyTo_noOverlay() {
    File file = _file(exists: true);
    File targetFile =
        provider.getFile(baseProvider.convertPath('/foo/test.dart'));
    expect(targetFile.exists, isFalse);
    file.copyTo(file.parent.parent);
    expect(targetFile.exists, isTrue);
  }

  test_copyTo_onlyOverlay() {
    File file = _file(exists: false);
    provider.setOverlay(file.path, content: 'overlay', modificationStamp: 3);
    File targetFile =
        provider.getFile(baseProvider.convertPath('/foo/test.dart'));
    expect(targetFile.exists, isFalse);
    file.copyTo(file.parent.parent);
    expect(targetFile.exists, isTrue);
    expect(targetFile.readAsStringSync(), 'overlay');
    provider.removeOverlay(targetFile.path);
    expect(targetFile.exists, isFalse);
  }

  test_copyTo_withOverlay() {
    File file = _file(exists: true, content: 'base');
    provider.setOverlay(file.path, content: 'overlay', modificationStamp: 3);
    File targetFile =
        provider.getFile(baseProvider.convertPath('/foo/test.dart'));
    expect(targetFile.exists, isFalse);
    file.copyTo(file.parent.parent);
    expect(targetFile.exists, isTrue);
    expect(targetFile.readAsStringSync(), 'overlay');
    provider.removeOverlay(targetFile.path);
    expect(targetFile.exists, isTrue);
    expect(targetFile.readAsStringSync(), 'base');
  }

  test_createSource() {
    File file = _file(exists: true);
    Source source = file.createSource();
    expect(source, isNotNull);
    expect(source.fullName, defaultFilePath);
    expect(source.uri, Uri.file(defaultFilePath));
  }

  test_delete_existing_withoutOverlay() {
    File file = _file(exists: true);
    expect(file.exists, isTrue);
    file.delete();
    expect(file.exists, isFalse);
  }

  test_delete_existing_withOverlay() {
    File file = _file(exists: true, withOverlay: true);
    expect(file.exists, isTrue);
    file.delete();
    expect(file.exists, isFalse);
  }

  test_delete_notExisting_withoutOverlay() {
    File file = _file(exists: false);
    expect(file.exists, isFalse);
    expect(() => file.delete(), throwsA(_isFileSystemException));
  }

  test_delete_notExisting_withOverlay() {
    File file = _file(exists: false, withOverlay: true);
    expect(file.exists, isTrue);
    file.delete();
    expect(file.exists, isFalse);
  }

  test_exists_existing_withoutOverlay() {
    File file = _file(exists: true);
    expect(file.exists, isTrue);
  }

  test_exists_existing_withOverlay() {
    File file = _file(exists: true, withOverlay: true);
    expect(file.exists, isTrue);
  }

  test_exists_notExisting_withoutOverlay() {
    File file = _file(exists: false);
    expect(file.exists, isFalse);
  }

  test_exists_notExisting_withOverlay() {
    File file = _file(exists: false, withOverlay: true);
    expect(file.exists, isTrue);
  }

  test_isOrContains_false() {
    File file = _file(exists: true);
    expect(file.isOrContains(baseProvider.convertPath('/foo/bar/a.dart')),
        isFalse);
  }

  test_isOrContains_true() {
    File file = _file(exists: true);
    expect(file.isOrContains(file.path), isTrue);
  }

  test_lengthSync_withoutOverlay() {
    File file = _file(exists: true);
    expect(file.lengthSync, 1);
  }

  test_lengthSync_withOverlay() {
    File file = _file(exists: true, withOverlay: true);
    expect(file.lengthSync, 3);
  }

  test_modificationStamp_existing_withoutOverlay() {
    File file = _file(exists: true);
    expect(file.modificationStamp, isNotNull);
  }

  test_modificationStamp_existing_withOverlay() {
    File file = _file(exists: true, withOverlay: true);
    expect(file.modificationStamp, 42);
  }

  test_modificationStamp_notExisting_withoutOverlay() {
    File file = _file(exists: false);
    expect(() => file.modificationStamp, throwsA(_isFileSystemException));
  }

  test_modificationStamp_notExisting_withOverlay() {
    File file = _file(exists: false, withOverlay: true);
    expect(file.modificationStamp, 42);
  }

  test_parent() {
    var parent = _file(exists: true).parent;
    expect(parent.exists, isTrue);
    expect(parent.path, defaultFolderPath);
  }

  test_readAsBytesSync_existing_withoutOverlay() {
    File file = _file(exists: true);
    expect(file.readAsBytesSync(), <int>[97]);
  }

  test_readAsBytesSync_existing_withOverlay() {
    File file = _file(exists: true, withOverlay: true);
    expect(file.readAsBytesSync(), <int>[98, 98, 98]);
  }

  test_readAsBytesSync_existing_withOverlay_utf8() {
    // Strings should be encoded as UTF8 when they're written, so when we read
    // them back as bytes we should see the UTF8-encoded version of the string.
    String overlayContent = '\u00e5'; // latin small letter a with ring above
    File file =
        _file(exists: true, withOverlay: true, overlayContent: overlayContent);
    expect(file.readAsBytesSync(), <int>[0xc3, 0xa5]);
  }

  test_readAsBytesSync_notExisting_withoutOverlay() {
    File file = _file(exists: false);
    expect(() => file.readAsBytesSync(), throwsA(_isFileSystemException));
  }

  test_readAsBytesSync_notExisting_withOverlay() {
    File file = _file(exists: false, withOverlay: true);
    expect(file.readAsBytesSync(), <int>[98, 98, 98]);
  }

  test_readAsStringSync_existing_withoutOverlay() {
    File file = _file(exists: true);
    expect(file.readAsStringSync(), 'a');
  }

  test_readAsStringSync_existing_withOverlay() {
    File file = _file(exists: true, withOverlay: true);
    expect(file.readAsStringSync(), 'bbb');
  }

  test_readAsStringSync_notExisting_withoutOverlay() {
    File file = _file(exists: false);
    expect(() {
      file.readAsStringSync();
    }, throwsA(_isFileSystemException));
  }

  test_readAsStringSync_notExisting_withOverlay() {
    File file = _file(exists: false, withOverlay: true);
    expect(file.readAsStringSync(), 'bbb');
  }

  test_renameSync_existingFile_conflictsWithFile() {
    String oldPath = '/foo/bar/file.txt';
    String newPath = baseProvider.convertPath('/foo/bar/new-file.txt');
    File oldFile = _file(content: 'old', exists: true, path: oldPath);
    File newFile = _file(content: 'new', exists: true, path: newPath);
    oldFile.renameSync(newPath);
    expect(oldFile.path, baseProvider.convertPath(oldPath));
    expect(oldFile.exists, isFalse);
    expect(newFile.path, newPath);
    expect(newFile.exists, isTrue);
    expect(newFile.readAsStringSync(), 'old');
  }

  test_renameSync_existingFile_conflictsWithFolder() {
    String oldPath = '/foo/bar/file.txt';
    String newPath = baseProvider.convertPath('/foo/bar/new-baz');
    File oldFile = _file(exists: true, path: oldPath);
    Folder newFolder = _folder(exists: true, path: newPath);
    expect(() => oldFile.renameSync(newPath), throwsA(_isFileSystemException));
    expect(oldFile.path, baseProvider.convertPath(oldPath));
    expect(oldFile.exists, isTrue);
    expect(newFolder.path, newPath);
    expect(newFolder.exists, isTrue);
  }

  test_renameSync_existingFile_withoutOverlay() {
    String oldPath = '/foo/bar/file.txt';
    String newPath = baseProvider.convertPath('/foo/bar/new-file.txt');
    File oldFile = _file(exists: true, path: oldPath);
    File newFile = oldFile.renameSync(newPath);
    expect(oldFile.path, baseProvider.convertPath(oldPath));
    expect(oldFile.exists, isFalse);
    expect(newFile.path, newPath);
    expect(newFile.exists, isTrue);
    expect(newFile.readAsStringSync(), 'a');
  }

  test_renameSync_existingFile_withOverlay() {
    String oldPath = '/foo/bar/file.txt';
    String newPath = baseProvider.convertPath('/foo/bar/new-file.txt');
    File oldFile = _file(exists: true, path: oldPath, withOverlay: true);
    File newFile = oldFile.renameSync(newPath);
    expect(oldFile.path, baseProvider.convertPath(oldPath));
    expect(oldFile.exists, isFalse);
    expect(newFile.path, newPath);
    expect(newFile.exists, isTrue);
    expect(newFile.readAsStringSync(), 'bbb');
  }

  test_renameSync_notExisting_withoutOverlay() {
    String oldPath = '/foo/bar/file.txt';
    String newPath = baseProvider.convertPath('/foo/bar/new-file.txt');
    File oldFile = _file(exists: false, path: oldPath);
    expect(
      () => oldFile.renameSync(newPath),
      throwsFileSystemException,
    );
  }

  test_renameSync_notExisting_withOverlay() {
    String oldPath = '/foo/bar/file.txt';
    String newPath = baseProvider.convertPath('/foo/bar/new-file.txt');
    File oldFile = _file(exists: false, path: oldPath, withOverlay: true);
    expect(
      () => oldFile.renameSync(newPath),
      throwsFileSystemException,
    );
  }

  @failingTest
  void test_resolveSymbolicLinksSync_links_existingFile_withoutOverlay() {
    fail('Not tested');
    // TODO(brianwilkerson) Decide how to test this given that we cannot
    // create a link in a MemoryResourceProvider.
//    // Create a file at '/temp/a/b/test.txt'.
//    String pathA = baseProvider.convertPath('/temp/a');
//    String pathB = baseProvider.convertPath('/temp/a/b');
//    baseProvider.newFolder(pathB);
//    String filePath = baseProvider.convertPath('/temp/a/b/test.txt');
//    File testFile = baseProvider.newFile(filePath, 'test');
//
//    // Create a symbolic link from '/temp/c/d' to '/temp/a'.
//    String pathC = baseProvider.convertPath('/temp/c');
//    String pathD = baseProvider.convertPath('/temp/c/d');
//    new io.Link(pathD).createSync(pathA, recursive: true);
//
//    // Create a symbolic link from '/temp/e/f' to '/temp/c'.
//    String pathE = baseProvider.convertPath('/temp/e');
//    String pathF = baseProvider.convertPath('/temp/e/f');
//    new io.Link(pathF).createSync(pathC, recursive: true);
//
//    // Resolve the path '/temp/e/f/d/b/test.txt' to '/temp/a/b/test.txt'.
//    String linkPath = baseProvider.convertPath('/temp/e/f/d/b/test.txt');
//    File file = baseProvider.getFile(linkPath);
//    expect(file.resolveSymbolicLinksSync().path,
//        testFile.resolveSymbolicLinksSync());
  }

  void test_resolveSymbolicLinksSync_noLinks_existingFile_withoutOverlay() {
    _resolveSymbolicLinksSync_noLinks(
        _file(exists: true, path: '/temp/a/b/test.txt'));
  }

  void test_resolveSymbolicLinksSync_noLinks_existingFile_withOverlay() {
    _resolveSymbolicLinksSync_noLinks(
        _file(exists: true, path: '/temp/a/b/test.txt', withOverlay: true));
  }

  void test_resolveSymbolicLinksSync_noLinks_notExisting_withoutOverlay() {
    var file = _file(
      exists: false,
      path: '/temp/a/b/test.txt',
    );

    expect(() {
      file.resolveSymbolicLinksSync();
    }, throwsA(isFileSystemException));
  }

  void test_resolveSymbolicLinksSync_noLinks_notExisting_withOverlay() {
    var file = _file(
      exists: false,
      path: '/temp/a/b/test.txt',
      withOverlay: true,
    );

    expect(file.resolveSymbolicLinksSync(), file);
  }

  test_shortName() {
    expect(_file(exists: true).shortName, 'test.dart');
  }

  test_toUri() {
    File file = _file(exists: true);
    expect(file.toUri(), Uri.file(file.path));
  }

  test_writeAsBytesSync_withoutOverlay() {
    File file = _file(exists: true);
    var bytes = Uint8List.fromList([99, 99]);
    file.writeAsBytesSync(bytes);
    expect(file.readAsBytesSync(), bytes);
  }

  test_writeAsBytesSync_withOverlay() {
    File file = _file(exists: true, withOverlay: true);
    var bytes = Uint8List.fromList([99, 99]);
    expect(
      () => file.writeAsBytesSync(bytes),
      throwsA(_isFileSystemException),
    );
  }

  test_writeAsStringSync_withoutOverlay() {
    File file = _file(exists: true);
    file.writeAsStringSync('cc');
    expect(file.readAsStringSync(), 'cc');
  }

  test_writeAsStringSync_withOverlay() {
    File file = _file(exists: true, withOverlay: true);
    expect(() => file.writeAsStringSync('cc'), throwsA(_isFileSystemException));
  }

  void _resolveSymbolicLinksSync_noLinks(File file) {
    //
    // On some platforms the path to the temp directory includes a symbolic
    // link. We remove that from the equation before creating the File in order
    // to show that the operation works as expected without symbolic links.
    //
    file = baseProvider.getFile(file.resolveSymbolicLinksSync().path);
    expect(file.resolveSymbolicLinksSync(), file);
  }
}

@reflectiveTest
class FolderTest extends OverlayTestSupport {
  test_canonicalizePath_dot_absolute() {
    Folder folder = _folder(exists: true, path: '/foo/bar');
    expect(folder.canonicalizePath(baseProvider.convertPath('/a/b/./c')),
        equals(baseProvider.convertPath('/a/b/c')));
  }

  test_canonicalizePath_dot_relative() {
    Folder folder = _folder(exists: true, path: '/foo/bar');
    expect(folder.canonicalizePath(baseProvider.convertPath('./baz')),
        equals(baseProvider.convertPath('/foo/bar/baz')));
  }

  test_canonicalizePath_dotDot_absolute() {
    Folder folder = _folder(exists: true, path: '/foo/bar');
    expect(folder.canonicalizePath(baseProvider.convertPath('/a/b/../c')),
        equals(baseProvider.convertPath('/a/c')));
  }

  test_canonicalizePath_dotDot_relative() {
    Folder folder = _folder(exists: true, path: '/foo/bar');
    expect(folder.canonicalizePath(baseProvider.convertPath('../baz')),
        equals(baseProvider.convertPath('/foo/baz')));
  }

  test_canonicalizePath_simple_absolute() {
    Folder folder = _folder(exists: true, path: '/foo/bar');
    expect(folder.canonicalizePath(baseProvider.convertPath('/baz')),
        equals(baseProvider.convertPath('/baz')));
  }

  test_canonicalizePath_simple_relative() {
    Folder folder = _folder(exists: true, path: '/foo/bar');
    expect(folder.canonicalizePath(baseProvider.convertPath('baz')),
        equals(baseProvider.convertPath('/foo/bar/baz')));
  }

  @failingTest
  test_changes() {
    // TODO(brianwilkerson) Implement this.
    fail('Not tested');
  }

  test_contains() {
    Folder folder = _folder(exists: true);
    expect(folder.contains(defaultFilePath), isTrue);
  }

  test_copyTo() {
    String sourcePath = baseProvider.convertPath('/source');
    String subdirPath = baseProvider.convertPath('/source/subdir');
    baseProvider.newFolder(sourcePath);
    baseProvider.newFolder(subdirPath);
    baseProvider.newFile(
        baseProvider.convertPath('/source/file1.txt'), 'file1');
    baseProvider.newFile(
        baseProvider.convertPath('/source/subdir/file2.txt'), 'file2');
    Folder source = provider.getFolder(sourcePath);
    Folder destination =
        provider.getFolder(baseProvider.convertPath('/destination'));

    Folder copy = source.copyTo(destination);
    expect(copy.parent, destination);
    _verifyStructure(copy, source);
  }

  test_create() {
    Folder folder = _folder(exists: false);
    expect(folder.exists, isFalse);
    folder.create();
    expect(folder.exists, isTrue);
  }

  test_delete_existing() {
    Folder folder = _folder(exists: true);
    expect(folder.exists, isTrue);
    folder.delete();
    expect(folder.exists, isFalse);
  }

  test_delete_notExisting() {
    Folder folder = _folder(exists: false);
    expect(folder.exists, isFalse);
    expect(() => folder.delete(), throwsFileSystemException);
  }

  void test_exists_links_existing() {
    var foo_path = baseProvider.convertPath('/foo');
    var bar_path = baseProvider.convertPath('/bar');

    baseProvider.newFolder(foo_path);
    baseProvider.newLink(bar_path, foo_path);

    var bar = provider.getFolder(bar_path);
    expect(bar.exists, isTrue);
  }

  void test_exists_links_notExisting() {
    var foo_path = baseProvider.convertPath('/foo');
    var bar_path = baseProvider.convertPath('/bar');

    baseProvider.newLink(bar_path, foo_path);

    var bar = provider.getFolder(bar_path);
    expect(bar.exists, isFalse);
  }

  void test_exists_links_notExisting_withOverlay() {
    var foo_path = baseProvider.convertPath('/foo');
    var bar_path = baseProvider.convertPath('/bar');

    _file(exists: false, path: '/foo/aaa/a.dart', withOverlay: true);
    baseProvider.newLink(bar_path, foo_path);

    // We cannot resolve `/bar` to `/foo` using the base provider.
    // So, we don't know that we should check that `/foo/aaa/a.dart` exists.
    var bar = provider.getFolder(bar_path);
    expect(bar.exists, isFalse);
  }

  test_exists_noLinks_false() {
    Folder folder = _folder(exists: false);
    expect(folder.exists, isFalse);
  }

  test_exists_noLinks_true() {
    Folder folder = _folder(exists: true);
    expect(folder.exists, isTrue);
  }

  test_getChild_file_existing() {
    Folder folder = _folder(exists: true);
    _file(exists: true);
    Resource child = folder.getChild(defaultFilePath);
    expect(child, _isFile);
  }

  test_getChild_file_notExisting() {
    Folder folder = _folder(exists: true);
    Resource child = folder.getChild(defaultFilePath);
    expect(child, _isFile);
  }

  test_getChild_folder() {
    Folder folder = _folder(exists: true);
    String childPath = provider.pathContext.join(folder.path, 'lib');
    _folder(exists: true, path: childPath);
    Resource child = folder.getChild(childPath);
    expect(child, _isFolder);
  }

  test_getChildAssumingFile() {
    Folder folder = _folder(exists: true);
    File child = folder.getChildAssumingFile('README.md');
    expect(child, isNotNull);
  }

  test_getChildAssumingFolder() {
    Folder folder = _folder(exists: true);
    Folder child = folder.getChildAssumingFolder('lib');
    expect(child, isNotNull);
  }

  test_getChildren_existing() {
    Folder folder = _folder(exists: true);
    Folder child1 = _folder(
        exists: true, path: provider.pathContext.join(folder.path, 'lib'));
    _file(exists: true, path: provider.pathContext.join(child1.path, 'a.dart'));
    File child2 = _file(
        exists: true, path: provider.pathContext.join(folder.path, 'b.dart'));
    File child3 = _file(
        exists: false,
        path: provider.pathContext.join(folder.path, 'c.dart'),
        withOverlay: true);
    List<Resource> children = folder.getChildren();
    expect(children, hasLength(3));
    expect(children.map((resource) => resource.path),
        unorderedEquals([child1.path, child2.path, child3.path]));
  }

  test_getChildren_existing_withOverlay() {
    Folder folder = _folder(exists: true);
    Folder child1 = _folder(
        exists: true, path: provider.pathContext.join(folder.path, 'lib'));
    _file(
        exists: true,
        path: provider.pathContext.join(child1.path, 'a.dart'),
        withOverlay: true);
    List<String> childPaths =
        folder.getChildren().map((resource) => resource.path).toList();
    expect(childPaths, equals([child1.path]));
  }

  test_getChildren_multipleDescendantOverlays() {
    Folder folder = _folder(exists: true);
    Folder child1 = _folder(
        exists: false, path: provider.pathContext.join(folder.path, 'lib'));
    _file(
        exists: false,
        withOverlay: true,
        path: provider.pathContext.join(child1.path, 'a.dart'));
    _file(
        exists: false,
        withOverlay: true,
        path: provider.pathContext.join(child1.path, 'b.dart'));
    List<String> childPaths =
        folder.getChildren().map((resource) => resource.path).toList();
    expect(childPaths, equals([child1.path]));
  }

  test_getChildren_nonExisting_withOverlay() {
    File file = _file(exists: false, withOverlay: true);
    List<Resource> children = file.parent.parent.getChildren();
    expect(children, hasLength(1));
    expect(children[0], _isFolder);
  }

  test_isOrContains_false() {
    Folder folder = _folder(exists: true);
    expect(folder.isOrContains(baseProvider.convertPath('/foo/baz')), isFalse);
  }

  test_isOrContains_true_child() {
    Folder folder = _folder(exists: true);
    expect(folder.isOrContains(defaultFilePath), isTrue);
  }

  test_isOrContains_true_same() {
    Folder folder = _folder(exists: true);
    expect(folder.isOrContains(folder.path), isTrue);
  }

  test_parent_ofNonRoot() {
    Folder parent = _folder(exists: true).parent;
    expect(parent.exists, isTrue);
    expect(parent.path, baseProvider.convertPath('/foo'));
  }

  test_parent_ofRoot() {
    var parent = _folder(exists: true, path: '/').parent;
    expect(parent.exists, isTrue);
    expect(parent.path, baseProvider.convertPath('/'));
  }

  @failingTest
  test_resolveSymbolicLinksSync_links() {
    // TODO(brianwilkerson) Implement this.
    fail('Not tested');
  }

  void test_resolveSymbolicLinksSync_links_existing() {
    var foo_path = baseProvider.convertPath('/foo');
    var bar_path = baseProvider.convertPath('/bar');

    baseProvider.newFolder(foo_path);
    baseProvider.newLink(bar_path, foo_path);

    var foo = provider.getFolder(foo_path);
    var bar = provider.getFolder(bar_path);
    expect(bar.resolveSymbolicLinksSync(), foo);
  }

  void test_resolveSymbolicLinksSync_links_notExisting() {
    var foo_path = baseProvider.convertPath('/foo');
    var bar_path = baseProvider.convertPath('/bar');

    baseProvider.newLink(bar_path, foo_path);

    expect(() {
      var bar = provider.getFolder(bar_path);
      bar.resolveSymbolicLinksSync();
    }, throwsA(isFileSystemException));
  }

  void test_resolveSymbolicLinksSync_links_notExisting_withOverlay() {
    var foo_path = baseProvider.convertPath('/foo');
    var bar_path = baseProvider.convertPath('/bar');

    _file(exists: false, path: '/foo/aaa/a.dart', withOverlay: true);
    baseProvider.newLink(bar_path, foo_path);

    // We cannot resolve `/bar` to `/foo` using the base provider.
    // So, we don't know that we should check that `/foo/aaa/a.dart` exists.
    expect(() {
      var bar = provider.getFolder(bar_path);
      bar.resolveSymbolicLinksSync();
    }, throwsA(isFileSystemException));
  }

  void test_resolveSymbolicLinksSync_noLinks_existing() {
    var folder = _folder(exists: true, path: '/test');
    expect(folder.resolveSymbolicLinksSync(), folder);
  }

  void test_resolveSymbolicLinksSync_noLinks_notExisting() {
    var folder = _folder(exists: false, path: '/test');
    expect(() {
      folder.resolveSymbolicLinksSync();
    }, throwsA(isFileSystemException));
  }

  void test_resolveSymbolicLinksSync_noLinks_notExisting_withOverlay() {
    _file(exists: false, path: '/test/aaa/a.dart', withOverlay: true);
    var folder = _folder(exists: false, path: '/test');
    expect(folder.resolveSymbolicLinksSync(), folder);
  }

  test_shortName() {
    expect(_folder(exists: true).shortName, 'bar');
  }

  test_toUri() {
    Folder folder = _folder(exists: true);
    expect(folder.toUri(), Uri.directory(folder.path));
  }

  /// Verify that the [copy] has the same name and content as the [source].
  void _verifyStructure(Folder copy, Folder source) {
    expect(copy.shortName, source.shortName);
    Map<String, File> sourceFiles = <String, File>{};
    Map<String, Folder> sourceFolders = <String, Folder>{};
    for (Resource child in source.getChildren()) {
      if (child is File) {
        sourceFiles[child.shortName] = child;
      } else if (child is Folder) {
        sourceFolders[child.shortName] = child;
      } else {
        fail('Unknown class of resource: ${child.runtimeType}');
      }
    }
    Map<String, File> copyFiles = <String, File>{};
    Map<String, Folder> copyFolders = <String, Folder>{};
    for (Resource child in source.getChildren()) {
      if (child is File) {
        copyFiles[child.shortName] = child;
      } else if (child is Folder) {
        copyFolders[child.shortName] = child;
      } else {
        fail('Unknown class of resource: ${child.runtimeType}');
      }
    }
    for (String fileName in sourceFiles.keys) {
      var sourceChild = sourceFiles[fileName]!;
      var copiedChild = copyFiles[fileName];
      if (copiedChild == null) {
        fail('Failed to copy file ${sourceChild.path}');
      }
      expect(copiedChild.readAsStringSync(), sourceChild.readAsStringSync(),
          reason: 'Incorrectly copied file ${sourceChild.path}');
    }
    for (String fileName in sourceFolders.keys) {
      var sourceChild = sourceFolders[fileName]!;
      var copiedChild = copyFolders[fileName];
      if (copiedChild == null) {
        fail('Failed to copy folder ${sourceChild.path}');
      }
      _verifyStructure(copiedChild, sourceChild);
    }
  }
}

@reflectiveTest
class OverlayResourceProviderTest extends OverlayTestSupport {
  test_getFile_existing_withoutOverlay() {
    File file = _file(exists: true);
    expect(file, isNotNull);
    expect(file.path, defaultFilePath);
    expect(file.exists, isTrue);
  }

  test_getFile_existing_withOverlay() {
    File file = _file(exists: true, withOverlay: true);
    expect(file, isNotNull);
    expect(file.path, defaultFilePath);
    expect(file.exists, isTrue);
  }

  test_getFile_notExisting_withoutOverlay() {
    File file = _file(exists: false);
    expect(file, isNotNull);
    expect(file.path, defaultFilePath);
    expect(file.exists, isFalse);
  }

  test_getFile_notExisting_withOverlay() {
    File file = _file(exists: false, withOverlay: true);
    expect(file, isNotNull);
    expect(file.path, defaultFilePath);
    expect(file.exists, isTrue);
  }

  test_getFolder_existing_withoutOverlay() {
    Folder folder = _folder(exists: true);
    expect(folder, isNotNull);
    expect(folder.path, defaultFolderPath);
    expect(folder.exists, isTrue);
  }

  test_getFolder_notExisting_withoutOverlay() {
    Folder folder = _folder(exists: false);
    expect(folder, isNotNull);
    expect(folder.path, defaultFolderPath);
    expect(folder.exists, isFalse);
  }

  test_getFolder_notExisting_withOverlay() {
    File file = _file(exists: false, withOverlay: true);
    Folder folder = file.parent;
    expect(folder, isNotNull);
    expect(folder.path, defaultFolderPath);
    expect(folder.exists, isTrue);
  }

  test_getResource_file_existing_withoutOverlay() {
    String path = _file(exists: true).path;
    Resource resource = provider.getResource(path);
    expect(resource, _isFile);
  }

  test_getResource_file_existing_withOverlay() {
    String path = _file(exists: true, withOverlay: true).path;
    Resource resource = provider.getResource(path);
    expect(resource, _isFile);
  }

  test_getResource_file_notExisting_withoutOverlay() {
    String path = _file(exists: false).path;
    Resource resource = provider.getResource(path);
    expect(resource, _isFile);
  }

  test_getResource_file_notExisting_withOverlay() {
    String path = _file(exists: false, withOverlay: true).path;
    Resource resource = provider.getResource(path);
    expect(resource, _isFile);
  }

  test_getResource_folder_existing() {
    String path = _folder(exists: true).path;
    Resource resource = provider.getResource(path);
    expect(resource, _isFolder);
  }

  test_getResource_folder_nonExisting_withOverlay() {
    String filePath = _file(exists: false, withOverlay: true).path;
    String folderPath = provider.pathContext.dirname(filePath);
    Resource resource = provider.getResource(folderPath);
    expect(resource, _isFolder);
  }

  test_getStateLocation_uniqueness() {
    String idOne = 'one';
    Folder folderOne = provider.getStateLocation(idOne)!;

    String idTwo = 'two';
    Folder folderTwo = provider.getStateLocation(idTwo)!;

    expect(folderTwo, isNot(equals(folderOne)));
    expect(provider.getStateLocation(idOne), equals(folderOne));
  }

  test_hasOverlay() {
    expect(provider.hasOverlay(defaultFilePath), isFalse);

    provider.setOverlay(defaultFilePath, content: 'x', modificationStamp: 0);
    expect(provider.hasOverlay(defaultFilePath), isTrue);

    provider.removeOverlay(defaultFilePath);
    expect(provider.hasOverlay(defaultFilePath), isFalse);
  }

  test_pathContext() {
    expect(provider.pathContext, baseProvider.pathContext);
  }
}

class OverlayTestSupport {
  late final MemoryResourceProvider baseProvider;
  late final OverlayResourceProvider provider;

  late final String defaultFolderPath;
  late final String defaultFilePath;

  void setUp() {
    baseProvider = MemoryResourceProvider();
    provider = OverlayResourceProvider(baseProvider);

    defaultFolderPath = baseProvider.convertPath('/foo/bar');
    defaultFilePath = baseProvider.convertPath('/foo/bar/test.dart');
  }

  File _file(
      {required bool exists,
      String? content,
      String? path,
      bool withOverlay = false,
      String overlayContent = 'bbb'}) {
    if (path == null) {
      path = defaultFilePath;
    } else {
      path = baseProvider.convertPath(path);
    }
    if (exists) {
      baseProvider.newFile(path, content ?? 'a');
    }
    if (withOverlay) {
      provider.setOverlay(path, content: overlayContent, modificationStamp: 42);
    }
    return provider.getFile(path);
  }

  Folder _folder({required bool exists, String? path}) {
    if (path == null) {
      path = defaultFolderPath;
    } else {
      path = baseProvider.convertPath(path);
    }
    if (exists) {
      baseProvider.newFolder(path);
    }
    return provider.getFolder(path);
  }
}
