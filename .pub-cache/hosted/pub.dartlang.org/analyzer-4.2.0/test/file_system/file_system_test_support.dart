// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

final isFile = TypeMatcher<File>();
final isFileSystemException = TypeMatcher<FileSystemException>();
final isFolder = TypeMatcher<Folder>();

final throwsFileSystemException = throwsA(isFileSystemException);

abstract class FileSystemTestSupport {
  /// The content used for the file at the [defaultFilePath] if it is created
  /// and no other content is provided.
  String get defaultFileContent;

  /// A path to a file within the [defaultFolderPath] that can be used by tests.
  String get defaultFilePath;

  /// A path to a folder within the [tempPath] that can be used by tests.
  String get defaultFolderPath;

  /// Return `true` if the file system has support for symbolic links.
  /// Windows until recently (Windows 10, 2016) did not have it.
  bool get hasSymbolicLinkSupport;

  /// Return the resource provider to be used by the tests.
  ResourceProvider get provider;

  /// The absolute path to the temporary directory in which all of the tests are
  /// to work.
  String get tempPath;

  /// Create a link from [path] to [target].
  /// The [target] does not have to exist, can be create later, or not at all.
  void createLink({required String path, required String target});

  /// Return a file accessed through the resource provider. If [exists] is
  /// `true` then the returned file will exist, otherwise it won't. If [content]
  /// is provided then the file will have the given content, otherwise it will
  /// have the [defaultFileContent]. If the file does not exist then the content
  /// is ignored. If a [filePath] is provided, then the file will be located at
  /// that path; otherwise the file will have the [defaultFilePath].
  File getFile({required bool exists, String? content, String? filePath});

  /// Return a folder accessed through the resource provider. If [exists] is
  /// `true` then the returned folder will exist, otherwise it won't. If a
  /// [folderPath] is provided, then the folder will be located at that path;
  /// otherwise the folder will have the [defaultFolderPath].
  Folder getFolder({required bool exists, String? folderPath});

  /// Return a file path composed of the provided parts as defined by the
  /// current path context.
  String join(String part1,
          [String? part2,
          String? part3,
          String? part4,
          String? part5,
          String? part6]) =>
      provider.pathContext.join(part1, part2, part3, part4, part5, part6);
}

/// Unlike most test mixins, this mixin defines some abstract test methods.
/// These are tests whose behavior differs between the two implementations of
/// the file system and therefore need to be implemented differently. (They
/// probably shouldn't differ, but they do.) The abstract methods exist so that
/// we cannot forget to implement the tests for each implementation.
mixin FileTestMixin implements FileSystemTestSupport {
  @failingTest
  test_changes() {
    // TODO(brianwilkerson) Implement this.
    fail('Not tested');
  }

  test_copyTo_existing() {
    File file = getFile(exists: true, content: 'contents');
    Folder destination = provider.getFolder(join(tempPath, 'destination'));

    File copy = file.copyTo(destination);
    expect(copy.parent, destination);
    expect(copy.shortName, file.shortName);
    expect(copy.exists, isTrue);
    expect(copy.readAsStringSync(), 'contents');
  }

  test_copyTo_notExisting() {
    File file = getFile(exists: false);
    Folder destination = provider.getFolder(join(tempPath, 'destination'));

    expect(() => file.copyTo(destination), throwsA(isFileSystemException));
  }

  test_createSource() {
    File file = getFile(exists: true);

    Source source = file.createSource();
    expect(source, isNotNull);
    expect(source.fullName, defaultFilePath);
    expect(source.uri, Uri.file(defaultFilePath));
    expect(source.exists(), isTrue);
    expect(source.contents.data, defaultFileContent);
  }

  test_delete_existing() {
    File file = getFile(exists: true);
    expect(file.exists, isTrue);
    expect(file.parent.getChildren(), contains(file));

    file.delete();
    expect(file.exists, isFalse);
    expect(file.parent.getChildren(), isNot(contains(file)));
  }

  test_delete_notExisting();

  test_equals_beforeAndAfterCreate() {
    File file1 = getFile(exists: false);
    File file2 = getFile(exists: true);

    expect(file1 == file2, isTrue);
  }

  test_equals_differentPaths() {
    File file1 = getFile(exists: true);
    File file2 = getFile(exists: true, filePath: join(tempPath, 'file2.txt'));

    expect(file1 == file2, isFalse);
  }

  test_equals_samePath() {
    File file1 = getFile(exists: true);
    var file2 = provider.getResource(file1.path) as File;

    expect(file1 == file2, isTrue);
  }

  test_exists_existing() {
    File file = getFile(exists: true);

    expect(file.exists, isTrue);
  }

  test_exists_links_existing() {
    if (!hasSymbolicLinkSupport) return;

    var a_path = join(tempPath, 'a.dart');
    var b_path = join(tempPath, 'b.dart');

    createLink(path: b_path, target: a_path);
    getFile(exists: true, filePath: a_path);

    var a = provider.getFile(a_path);
    var b = provider.getFile(b_path);

    expect(a.exists, isTrue);
    expect(b.exists, isTrue);
  }

  test_exists_links_notExisting() {
    if (!hasSymbolicLinkSupport) return;

    var a_path = join(tempPath, 'a.dart');
    var b_path = join(tempPath, 'b.dart');

    createLink(path: b_path, target: a_path);

    var a = provider.getFile(a_path);
    var b = provider.getFile(b_path);

    expect(a.exists, isFalse);
    expect(b.exists, isFalse);
  }

  test_exists_notExisting() {
    File file = getFile(exists: false);

    expect(file.exists, isFalse);
  }

  test_hashCode_samePath() {
    File file1 = getFile(exists: true);
    var file2 = provider.getResource(file1.path) as File;

    expect(file1.hashCode, equals(file2.hashCode));
  }

  test_isOrContains_false() {
    File file = getFile(exists: false);

    expect(file.isOrContains(join(tempPath, 'foo', 'a.dart')), isFalse);
  }

  test_isOrContains_true() {
    File file = getFile(exists: false);

    expect(file.isOrContains(file.path), isTrue);
  }

  test_lengthSync_existing() {
    var file = getFile(exists: true);
    var bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
    file.writeAsBytesSync(bytes);

    expect(file.lengthSync, bytes.length);
  }

  test_lengthSync_notExisting() {
    File file = getFile(exists: false);

    expect(() => file.lengthSync, throwsA(isFileSystemException));
  }

  test_modificationStamp_existing() {
    File file = getFile(exists: true);

    expect(file.modificationStamp, isNonNegative);
  }

  test_modificationStamp_notExisting() {
    File file = getFile(exists: false);

    expect(() => file.modificationStamp, throwsA(isFileSystemException));
  }

  test_parent2() {
    File file = getFile(exists: true);

    var parent = file.parent;
    expect(parent.exists, isTrue);
    expect(parent.path, defaultFolderPath);
  }

  test_path() {
    File file = getFile(exists: false);

    expect(file.path, defaultFilePath);
  }

  test_readAsBytesSync_existing() {
    File file = getFile(exists: true);

    expect(file.readAsBytesSync(), <int>[97]);
  }

  test_readAsBytesSync_notExisting() {
    File file = getFile(exists: false);

    expect(() => file.readAsBytesSync(), throwsA(isFileSystemException));
  }

  test_readAsStringSync_existing() {
    File file = getFile(exists: true);

    expect(file.readAsStringSync(), defaultFileContent);
  }

  test_readAsStringSync_notExisting() {
    File file = getFile(exists: false);

    expect(() => file.readAsStringSync(), throwsA(isFileSystemException));
  }

  test_renameSync_existing() {
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

  test_renameSync_existing_conflictsWithFile() {
    String oldPath = join(tempPath, 'file.txt');
    String newPath = join(tempPath, 'new-file.txt');
    File oldFile = getFile(content: 'old', exists: true, filePath: oldPath);
    File newFile = getFile(content: 'new', exists: true, filePath: newPath);

    oldFile.renameSync(newPath);
    expect(oldFile.path, oldPath);
    expect(oldFile.exists, isFalse);
    expect(newFile.path, newPath);
    expect(newFile.exists, isTrue);
    expect(newFile.readAsStringSync(), 'old');
  }

  test_renameSync_existing_conflictsWithFolder() {
    String oldPath = join(tempPath, 'file.txt');
    String newPath = join(tempPath, 'new-baz');
    File oldFile = getFile(exists: true, filePath: oldPath);
    Folder newFolder = getFolder(exists: true, folderPath: newPath);

    expect(() => oldFile.renameSync(newPath), throwsA(isFileSystemException));
    expect(oldFile.path, oldPath);
    expect(oldFile.exists, isTrue);
    expect(newFolder.path, newPath);
    expect(newFolder.exists, isTrue);
  }

  test_renameSync_notExisting();

  test_resolveSymbolicLinksSync_links_existing() {
    if (!hasSymbolicLinkSupport) return;

    var a_path = join(tempPath, 'aaa', 'a.dart');
    var b_path = join(tempPath, 'bbb', 'b.dart');

    getFile(exists: true, filePath: a_path);
    createLink(path: b_path, target: a_path);

    var resolved = provider.getFile(b_path).resolveSymbolicLinksSync();
    expect(resolved.path, a_path);
  }

  test_resolveSymbolicLinksSync_links_existing2() {
    if (!hasSymbolicLinkSupport) return;

    var a = join(tempPath, 'aaa', 'a.dart');
    var b = join(tempPath, 'bbb', 'b.dart');
    var c = join(tempPath, 'ccc', 'c.dart');

    getFile(exists: true, filePath: a);
    createLink(path: b, target: a);
    createLink(path: c, target: b);

    var resolved = provider.getFile(c).resolveSymbolicLinksSync();
    expect(resolved.path, a);
  }

  test_resolveSymbolicLinksSync_links_notExisting() {
    if (!hasSymbolicLinkSupport) return;

    var a = join(tempPath, 'a.dart');
    var b = join(tempPath, 'b.dart');

    createLink(path: b, target: a);

    expect(() {
      provider.getFile(b).resolveSymbolicLinksSync();
    }, throwsA(isFileSystemException));
  }

  test_resolveSymbolicLinksSync_noLinks_existing() {
    File file = getFile(exists: true);

    expect(file.resolveSymbolicLinksSync(), file);
  }

  test_resolveSymbolicLinksSync_noLinks_notExisting() {
    var path = join(tempPath, 'a.dart');

    expect(() {
      provider.getFile(path).resolveSymbolicLinksSync();
    }, throwsA(isFileSystemException));
  }

  test_shortName() {
    File file = getFile(exists: false);

    expect(file.shortName, 'test.dart');
  }

  test_toString() {
    File file = getFile(exists: false);

    expect(file.toString(), defaultFilePath);
  }

  test_toUri() {
    File file = getFile(exists: true);

    expect(file.toUri(), Uri.file(file.path));
  }

  test_writeAsBytesSync_existing() {
    File file = getFile(exists: true);

    var bytes = Uint8List.fromList([99, 99]);
    file.writeAsBytesSync(bytes);
    expect(file.readAsBytesSync(), bytes);
  }

  test_writeAsBytesSync_notExisting();

  test_writeAsStringSync_existing() {
    File file = getFile(exists: true);

    file.writeAsStringSync('cc');
    expect(file.readAsStringSync(), 'cc');
  }

  test_writeAsStringSync_notExisting();
}

mixin FolderTestMixin implements FileSystemTestSupport {
  test_canonicalizePath_absolute() {
    Folder folder = getFolder(exists: false);
    String path2 = join(tempPath, 'folder2');

    expect(folder.canonicalizePath(path2), equals(path2));
  }

  test_canonicalizePath_absolute_dot() {
    Folder folder = getFolder(exists: false);
    String path2 = join(tempPath, 'folder2');

    expect(folder.canonicalizePath(join(path2, '.', 'baz')),
        equals(join(path2, 'baz')));
  }

  test_canonicalizePath_absolute_dotDot() {
    Folder folder = getFolder(exists: false);
    String path2 = join(tempPath, 'folder2');
    String path3 = join(tempPath, 'folder3');

    expect(
        folder.canonicalizePath(join(path2, '..', 'folder3')), equals(path3));
  }

  test_canonicalizePath_relative() {
    Folder folder = getFolder(exists: false);

    expect(
        folder.canonicalizePath('baz'), equals(join(defaultFolderPath, 'baz')));
  }

  test_canonicalizePath_relative_dot() {
    Folder folder = getFolder(exists: false);

    expect(folder.canonicalizePath(join('.', 'baz')),
        equals(join(defaultFolderPath, 'baz')));
  }

  test_canonicalizePath_relative_dotDot() {
    Folder folder = getFolder(exists: false);
    String path2 = join(tempPath, 'folder2');

    expect(folder.canonicalizePath(join('..', 'folder2')), equals(path2));
  }

  @failingTest
  test_changes() {
    // TODO(brianwilkerson) Implement this.
    fail('Not tested');
  }

  test_contains_immediateChild() {
    Folder folder = getFolder(exists: false);

    expect(folder.contains(join(defaultFolderPath, 'aaa.txt')), isTrue);
  }

  test_contains_nestedChild() {
    Folder folder = getFolder(exists: false);

    expect(folder.contains(join(defaultFolderPath, 'aaa', 'bbb.txt')), isTrue);
  }

  test_contains_self() {
    Folder folder = getFolder(exists: false);

    expect(folder.contains(defaultFolderPath), isFalse);
  }

  test_contains_unrelated() {
    Folder folder = getFolder(exists: false);

    expect(folder.contains(join(tempPath, 'baz.txt')), isFalse);
  }

  test_copyTo() {
    Folder source =
        getFolder(exists: true, folderPath: join(tempPath, 'source'));
    String sourcePath = source.path;
    Folder subdirectory =
        getFolder(exists: true, folderPath: join(sourcePath, 'subdir'));
    String subdirectoryPath = subdirectory.path;
    getFile(
        exists: true,
        content: 'file1',
        filePath: join(sourcePath, 'file1.txt'));
    getFile(
        exists: true,
        content: 'file2',
        filePath: join(subdirectoryPath, 'file2.txt'));
    Folder destination =
        getFolder(exists: true, folderPath: join(tempPath, 'destination'));

    Folder copy = source.copyTo(destination);
    expect(copy.parent, destination);
    _verifyStructure(copy, source);
  }

  test_create() {
    Folder folder = getFolder(exists: false);
    expect(folder.exists, isFalse);

    folder.create();
    expect(folder.exists, isTrue);
  }

  test_delete() {
    File file =
        getFile(exists: true, filePath: join(defaultFolderPath, 'myFile'));
    var folder = file.parent;
    expect(folder.exists, isTrue);
    expect(file.exists, isTrue);

    folder.delete();
    expect(folder.exists, isFalse);
    expect(file.exists, isFalse);
  }

  test_equals_differentPaths() {
    Folder folder1 =
        getFolder(exists: true, folderPath: join(tempPath, 'folder1'));
    Folder folder2 =
        getFolder(exists: true, folderPath: join(tempPath, 'folder2'));

    expect(folder1 == folder2, isFalse);
  }

  test_equals_samePath() {
    Folder folder1 = getFolder(exists: false);
    Folder folder2 = getFolder(exists: false);

    expect(folder1 == folder2, isTrue);
  }

  test_exists_links_existing() {
    if (!hasSymbolicLinkSupport) return;

    var foo_path = join(tempPath, 'foo');
    var bar_path = join(tempPath, 'bar');

    createLink(path: bar_path, target: foo_path);
    getFolder(exists: true, folderPath: foo_path);

    var foo = provider.getFolder(foo_path);
    var bar = provider.getFolder(bar_path);

    expect(foo.exists, isTrue);
    expect(bar.exists, isTrue);
  }

  test_exists_links_notExisting() {
    if (!hasSymbolicLinkSupport) return;

    var foo_path = join(tempPath, 'foo');
    var bar_path = join(tempPath, 'bar');

    createLink(path: bar_path, target: foo_path);

    var foo = provider.getFolder(foo_path);
    var bar = provider.getFolder(bar_path);

    expect(foo.exists, isFalse);
    expect(bar.exists, isFalse);
  }

  test_getChild_doesNotExist() {
    Folder folder = getFolder(exists: true);

    var child = folder.getChild('no-such-resource');
    expect(child, isNotNull);
    expect(child.exists, isFalse);
  }

  test_getChild_file() {
    Folder folder = getFolder(exists: true);
    getFile(exists: true, filePath: join(defaultFolderPath, 'myFile'));

    var child = folder.getChild('myFile');
    expect(child, isFile);
    expect(child.exists, isTrue);
  }

  test_getChild_folder() {
    Folder folder = getFolder(exists: true);
    getFolder(exists: true, folderPath: join(folder.path, 'myFolder'));

    var child = folder.getChild('myFolder');
    expect(child, isFolder);
    expect(child.exists, isTrue);
  }

  test_getChildAssumingFile_doesNotExist() {
    Folder folder = getFolder(exists: true);

    File child = folder.getChildAssumingFile('myFile');
    expect(child, isNotNull);
    expect(child.exists, isFalse);
  }

  test_getChildAssumingFile_file() {
    Folder folder = getFolder(exists: true);
    getFile(exists: true, filePath: join(defaultFolderPath, 'myFile'));

    File child = folder.getChildAssumingFile('myFile');
    expect(child, isNotNull);
    expect(child.exists, isTrue);
  }

  test_getChildAssumingFile_folder() {
    Folder folder = getFolder(exists: true);
    getFolder(exists: true, folderPath: join(defaultFolderPath, 'myFolder'));

    File child = folder.getChildAssumingFile('myFolder');
    expect(child, isNotNull);
    expect(child.exists, isFalse);
  }

  test_getChildAssumingFolder_doesNotExist() {
    Folder folder = getFolder(exists: true);

    Folder child = folder.getChildAssumingFolder('myFile');
    expect(child, isNotNull);
    expect(child.exists, isFalse);
  }

  test_getChildAssumingFolder_file() {
    Folder folder = getFolder(exists: true);
    getFile(exists: true, filePath: join(defaultFolderPath, 'myFile'));

    Folder child = folder.getChildAssumingFolder('myFile');
    expect(child, isNotNull);
    expect(child.exists, isFalse);
  }

  test_getChildAssumingFolder_folder() {
    Folder folder = getFolder(exists: true);
    getFolder(exists: true, folderPath: join(defaultFolderPath, 'myFolder'));

    Folder child = folder.getChildAssumingFolder('myFolder');
    expect(child, isNotNull);
    expect(child.exists, isTrue);
  }

  test_getChildren_doesNotExist() {
    Folder folder = getFolder(exists: true);

    folder = folder.getChildAssumingFolder('no-such-folder');
    expect(() => folder.getChildren(), throwsA(isFileSystemException));
  }

  test_getChildren_exists() {
    Folder folder = getFolder(exists: true);
    // create 2 files and 1 folder
    getFile(exists: true, filePath: join(defaultFolderPath, 'a.txt'));
    getFolder(exists: true, folderPath: join(defaultFolderPath, 'bFolder'));
    getFile(exists: true, filePath: join(defaultFolderPath, 'c.txt'));

    // prepare 3 children
    List<Resource> children = folder.getChildren();
    expect(children, hasLength(3));
    children.sort((a, b) => a.shortName.compareTo(b.shortName));
    // check that each child exists
    for (var child in children) {
      expect(child.exists, true);
    }
    // check names
    expect(children[0].shortName, 'a.txt');
    expect(children[1].shortName, 'bFolder');
    expect(children[2].shortName, 'c.txt');
    // check types
    expect(children[0], isFile);
    expect(children[1], isFolder);
    expect(children[2], isFile);
  }

  test_getChildren_hasLink_file() {
    if (!hasSymbolicLinkSupport) return;

    var a_path = join(tempPath, 'a.dart');
    var b_path = join(tempPath, 'b.dart');

    createLink(path: b_path, target: a_path);
    var a = getFile(exists: true, filePath: a_path);

    var children = provider.getFolder(tempPath).getChildren();
    expect(children, hasLength(2));
    expect(
      children.map((e) => e.path),
      unorderedEquals([a_path, b_path]),
    );

    var b = children.singleWhere((e) => e.path == b_path) as File;
    expect(b.resolveSymbolicLinksSync(), a);
  }

  test_getChildren_hasLink_folder() {
    if (!hasSymbolicLinkSupport) return;

    var foo_path = join(tempPath, 'foo');
    var bar_path = join(tempPath, 'bar');

    var foo = getFolder(exists: true, folderPath: foo_path);
    createLink(path: bar_path, target: foo_path);

    var children = provider.getFolder(tempPath).getChildren();
    expect(children, hasLength(2));
    expect(
      children.map((e) => e.path),
      unorderedEquals([foo_path, bar_path]),
    );

    var b = children.singleWhere((e) => e.path == bar_path) as Folder;
    expect(b.resolveSymbolicLinksSync(), foo);
  }

  test_getChildren_isLink() {
    if (!hasSymbolicLinkSupport) return;

    var foo_path = join(tempPath, 'foo');
    var bar_path = join(tempPath, 'bar');
    var foo_a_path = join(foo_path, 'a.dart');
    var bar_a_path = join(bar_path, 'a.dart');
    var foo_b_path = join(foo_path, 'b');
    var bar_b_path = join(bar_path, 'b');

    var foo_a = getFile(exists: true, filePath: foo_a_path);
    var foo_b = getFolder(exists: true, folderPath: foo_b_path);
    createLink(path: bar_path, target: foo_path);

    var children = provider.getFolder(bar_path).getChildren();
    expect(children, hasLength(2));
    expect(
      children.map((e) => e.path),
      unorderedEquals([bar_a_path, bar_b_path]),
    );

    var bar_a = children.singleWhere((e) => e.path == bar_a_path) as File;
    expect(bar_a.resolveSymbolicLinksSync(), foo_a);

    var bar_b = children.singleWhere((e) => e.path == bar_b_path) as Folder;
    expect(bar_b.resolveSymbolicLinksSync(), foo_b);
  }

  test_hashCode() {
    Folder folder1 = getFolder(exists: false);
    Folder folder2 = getFolder(exists: false);

    expect(folder1.hashCode, folder2.hashCode);
  }

  test_isOrContains_containedFile() {
    Folder folder = getFolder(exists: true);

    expect(folder.isOrContains(join(defaultFolderPath, 'aaa.txt')), isTrue);
  }

  test_isOrContains_deeplyContained() {
    Folder folder = getFolder(exists: true);

    expect(
        folder.isOrContains(join(defaultFolderPath, 'aaa', 'bbb.txt')), isTrue);
  }

  test_isOrContains_notContained() {
    Folder folder = getFolder(exists: true);

    expect(folder.isOrContains(join(tempPath, 'baz.txt')), isFalse);
  }

  test_isOrContains_same() {
    Folder folder = getFolder(exists: true);

    expect(folder.isOrContains(defaultFolderPath), isTrue);
  }

  test_parent() {
    Folder folder = getFolder(exists: true);

    var parent = folder.parent;
    expect(parent.path, equals(tempPath));
    //
    // Since the OS is in control of where tempPath is, we don't know how far it
    // should be from the root. So just verify that each call to parent results
    // in a folder with a shorter path, and that we reach the root eventually.
    //
    while (true) {
      var grandParent = parent.parent;
      if (grandParent.isRoot) {
        break;
      }
      expect(grandParent.path.length, lessThan(parent.path.length));
      parent = grandParent;
    }
  }

  test_resolveSymbolicLinksSync_links_existing() {
    if (!hasSymbolicLinkSupport) return;

    var foo = join(tempPath, 'foo');
    var bar = join(tempPath, 'bar');

    getFolder(exists: true, folderPath: foo);
    createLink(path: bar, target: foo);

    var resolved = provider.getFolder(bar).resolveSymbolicLinksSync();
    expect(resolved.path, foo);
  }

  test_resolveSymbolicLinksSync_links_notExisting() {
    if (!hasSymbolicLinkSupport) return;

    var foo = join(tempPath, 'foo');
    var bar = join(tempPath, 'bar');

    createLink(path: bar, target: foo);

    expect(() {
      provider.getFolder(bar).resolveSymbolicLinksSync();
    }, throwsA(isFileSystemException));
  }

  test_resolveSymbolicLinksSync_noLinks_notExisting() {
    var path = join(tempPath, 'foo');

    expect(() {
      provider.getFolder(path).resolveSymbolicLinksSync();
    }, throwsA(isFileSystemException));
  }

  test_toUri() {
    Folder folder = getFolder(exists: true);

    expect(folder.toUri(), Uri.directory(defaultFolderPath));
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

mixin ResourceProviderTestMixin implements FileSystemTestSupport {
  test_getFile_existing() {
    getFile(exists: true);

    File file = provider.getFile(defaultFilePath);
    expect(file, isNotNull);
    expect(file.path, defaultFilePath);
    expect(file.exists, isTrue);
  }

  test_getFile_notExisting() {
    File file = provider.getFile(defaultFilePath);
    expect(file, isNotNull);
    expect(file.path, defaultFilePath);
    expect(file.exists, isFalse);
  }

  test_getFolder_existing() {
    getFolder(exists: true);

    Folder folder = provider.getFolder(defaultFolderPath);
    expect(folder, isNotNull);
    expect(folder.path, defaultFolderPath);
    expect(folder.exists, isTrue);
  }

  test_getFolder_notExisting() {
    Folder folder = provider.getFolder(defaultFolderPath);
    expect(folder, isNotNull);
    expect(folder.path, defaultFolderPath);
    expect(folder.exists, isFalse);
  }

  test_getResource_file_existing() {
    String filePath = getFile(exists: true).path;

    Resource resource = provider.getResource(filePath);
    expect(resource, isFile);
  }

  test_getResource_folder_existing() {
    String filePath = getFolder(exists: true).path;

    Resource resource = provider.getResource(filePath);
    expect(resource, isFolder);
  }

  test_getResource_notExisting() {
    String resourcePath = getFile(exists: false).path;

    Resource resource = provider.getResource(resourcePath);
    expect(resource, isFile);
  }

  test_getStateLocation_uniqueness() {
    var folderOne = provider.getStateLocation('one')!;
    expect(folderOne, isNotNull);

    var folderTwo = provider.getStateLocation('two')!;
    expect(folderTwo, isNotNull);
    expect(folderTwo, isNot(equals(folderOne)));

    expect(provider.getStateLocation('one'), equals(folderOne));
  }

  test_pathContext() {
    expect(provider.pathContext, path.context);
  }
}
