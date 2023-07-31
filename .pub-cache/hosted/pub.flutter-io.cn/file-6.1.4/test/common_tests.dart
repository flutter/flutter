// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:file/file.dart';
import 'package:file_testing/file_testing.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:test/test.dart' as testpkg show group, setUp, tearDown, test;

import 'utils.dart';

/// Callback used in [runCommonTests] to produce the root folder in which all
/// file system entities will be created.
typedef RootPathGenerator = String Function();

/// Callback used in [runCommonTests] to create the file system under test.
/// It must return either a [FileSystem] or a [Future] that completes with a
/// [FileSystem].
typedef FileSystemGenerator = dynamic Function();

/// A function to run before tests (passed to [setUp]) or after tests
/// (passed to [tearDown]).
typedef SetUpTearDown = dynamic Function();

/// Runs a suite of tests common to all file system implementations. All file
/// system implementations should run *at least* these tests to ensure
/// compliance with file system API.
///
/// If [root] is specified, its return value will be used as the root folder
/// in which all file system entities will be created. If not specified, the
/// tests will attempt to create entities in the file system root.
///
/// [skip] may be used to skip certain tests (or entire groups of tests) in
/// this suite (to be used, for instance, if a file system implementation is
/// not yet fully complete). The format of each entry in the list is:
/// `$group1Description > $group2Description > ... > $testDescription`.
/// Entries may use regular expression syntax.
///
/// If [replay] is specified, each test (and its setup callbacks) will run
/// twice - once as a "setup" pass with the file system returned by
/// [createFileSystem], and again as the "test" pass with the file system
/// returned by [replay]. This is intended for use with `ReplayFileSystem`,
/// where in order for the file system to behave as expected, a recording of
/// the invocation(s) must first be made.
void runCommonTests(
  FileSystemGenerator createFileSystem, {
  RootPathGenerator? root,
  List<String> skip = const <String>[],
  FileSystemGenerator? replay,
}) {
  RootPathGenerator? rootfn = root;

  group('common', () {
    late FileSystemGenerator createFs;
    late List<SetUpTearDown> setUps;
    late List<SetUpTearDown> tearDowns;
    late FileSystem fs;
    late String root;
    List<String> stack = <String>[];

    void skipIfNecessary(String description, void Function() callback) {
      stack.add(description);
      bool matchesCurrentFrame(String input) =>
          RegExp('^$input\$').hasMatch(stack.join(' > '));
      if (skip.where(matchesCurrentFrame).isEmpty) {
        callback();
      }
      stack.removeLast();
    }

    testpkg.setUp(() async {
      createFs = createFileSystem;
      setUps = <SetUpTearDown>[];
      tearDowns = <SetUpTearDown>[];
    });

    void setUp(FutureOr<void> Function() callback) {
      testpkg.setUp(replay == null ? callback : () => setUps.add(callback));
    }

    void tearDown(FutureOr<void> Function() callback) {
      if (replay == null) {
        testpkg.tearDown(callback);
      } else {
        testpkg.setUp(() => tearDowns.insert(0, callback));
      }
    }

    void group(String description, void Function() body) =>
        skipIfNecessary(description, () => testpkg.group(description, body));

    void test(String description, FutureOr<void> Function() body,
            {dynamic skip}) =>
        skipIfNecessary(description, () {
          if (replay == null) {
            testpkg.test(description, body, skip: skip);
          } else {
            group('rerun', () {
              testpkg.setUp(() async {
                await Future.forEach(setUps, (SetUpTearDown setUp) => setUp());
                await body();
                for (SetUpTearDown tearDown in tearDowns) {
                  await tearDown();
                }
                createFs = replay;
                await Future.forEach(setUps, (SetUpTearDown setUp) => setUp());
              });

              testpkg.test(description, body, skip: skip);

              testpkg.tearDown(() async {
                for (SetUpTearDown tearDown in tearDowns) {
                  await tearDown();
                }
              });
            });
          }
        });

    /// Returns [path] prefixed by the [root] namespace.
    /// This is only intended for absolute paths.
    String ns(String path) {
      p.Context posix = p.Context(style: p.Style.posix);
      List<String> parts = posix.split(path);
      parts[0] = root;
      path = fs.path.joinAll(parts);
      String rootPrefix = fs.path.rootPrefix(path);
      assert(rootPrefix.isNotEmpty);
      String result = root == rootPrefix
          ? path
          : (path == rootPrefix
              ? root
              : fs.path.join(root, fs.path.joinAll(parts.sublist(1))));
      return result;
    }

    setUp(() async {
      root = rootfn != null ? rootfn() : '/';
      fs = await createFs() as FileSystem;
      assert(fs.path.isAbsolute(root));
      assert(!root.endsWith(fs.path.separator) ||
          fs.path.rootPrefix(root) == root);
    });

    group('FileSystem', () {
      group('directory', () {
        test('allowsStringArgument', () {
          expect(fs.directory(ns('/foo')), isDirectory);
        });

        test('allowsUriArgument', () {
          expect(fs.directory(Uri.parse('file:///')), isDirectory);
        });

        test('succeedsWithUriArgument', () {
          fs.directory(ns('/foo')).createSync();
          Uri uri = fs.path.toUri(ns('/foo'));
          expect(fs.directory(uri), exists);
        });

        test('allowsDirectoryArgument', () {
          expect(fs.directory(io.Directory(ns('/foo'))), isDirectory);
        });

        test('disallowsOtherArgumentType', () {
          expect(() => fs.directory(123), throwsArgumentError);
        });

        // Fails due to
        // https://github.com/google/file.dart/issues/112
        test('considersBothSlashesEquivalent', () {
          fs.directory(r'foo\bar_dir').createSync(recursive: true);
          expect(fs.directory(r'foo/bar_dir'), exists);
        }, skip: 'Fails due to https://github.com/google/file.dart/issues/112');
      });

      group('file', () {
        test('allowsStringArgument', () {
          expect(fs.file(ns('/foo')), isFile);
        });

        test('allowsUriArgument', () {
          expect(fs.file(Uri.parse('file:///')), isFile);
        });

        test('succeedsWithUriArgument', () {
          fs.file(ns('/foo')).createSync();
          Uri uri = fs.path.toUri(ns('/foo'));
          expect(fs.file(uri), exists);
        });

        test('allowsDirectoryArgument', () {
          expect(fs.file(io.File(ns('/foo'))), isFile);
        });

        test('disallowsOtherArgumentType', () {
          expect(() => fs.file(123), throwsArgumentError);
        });

        // Fails due to
        // https://github.com/google/file.dart/issues/112
        test('considersBothSlashesEquivalent', () {
          fs.file(r'foo\bar_file').createSync(recursive: true);
          expect(fs.file(r'foo/bar_file'), exists);
        }, skip: 'Fails due to https://github.com/google/file.dart/issues/112');
      });

      group('link', () {
        test('allowsStringArgument', () {
          expect(fs.link(ns('/foo')), isLink);
        });

        test('allowsUriArgument', () {
          expect(fs.link(Uri.parse('file:///')), isLink);
        });

        test('succeedsWithUriArgument', () {
          fs.file(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          Uri uri = fs.path.toUri(ns('/bar'));
          expect(fs.link(uri), exists);
        });

        test('allowsDirectoryArgument', () {
          expect(fs.link(io.File(ns('/foo'))), isLink);
        });

        test('disallowsOtherArgumentType', () {
          expect(() => fs.link(123), throwsArgumentError);
        });
      });

      group('path', () {
        test('hasCorrectCurrentWorkingDirectory', () {
          expect(fs.path.current, fs.currentDirectory.path);
        });

        test('separatorIsAmongExpectedValues', () {
          expect(fs.path.separator, anyOf('/', r'\'));
        });
      });

      group('systemTempDirectory', () {
        test('existsAsDirectory', () {
          Directory tmp = fs.systemTempDirectory;
          expect(tmp, isDirectory);
          expect(tmp, exists);
        });
      });

      group('currentDirectory', () {
        test('defaultsToRoot', () {
          expect(fs.currentDirectory.path, root);
        });

        test('throwsIfSetToNonExistentPath', () {
          expectFileSystemException(ErrorCodes.ENOENT, () {
            fs.currentDirectory = ns('/foo');
          });
        });

        test('throwsIfHasNonExistentPathInComplexChain', () {
          fs.directory(ns('/foo')).createSync();
          expectFileSystemException(ErrorCodes.ENOENT, () {
            fs.currentDirectory = ns('/bar/../foo');
          });
        });

        test('succeedsIfSetToValidStringPath', () {
          fs.directory(ns('/foo')).createSync();
          fs.currentDirectory = ns('/foo');
          expect(fs.currentDirectory.path, ns('/foo'));
        });

        test('succeedsIfSetToValidDirectory', () {
          fs.directory(ns('/foo')).createSync();
          fs.currentDirectory = io.Directory(ns('/foo'));
          expect(fs.currentDirectory.path, ns('/foo'));
        });

        test('throwsIfArgumentIsNotStringOrDirectory', () {
          expect(() {
            fs.currentDirectory = 123;
          }, throwsArgumentError);
        });

        test('succeedsIfSetToRelativePath', () {
          fs.directory(ns('/foo/bar')).createSync(recursive: true);
          fs.currentDirectory = 'foo';
          expect(fs.currentDirectory.path, ns('/foo'));
          fs.currentDirectory = 'bar';
          expect(fs.currentDirectory.path, ns('/foo/bar'));
        });

        test('succeedsIfSetToAbsolutePathWhenCwdIsNotRoot', () {
          fs.directory(ns('/foo/bar')).createSync(recursive: true);
          fs.directory(ns('/baz/qux')).createSync(recursive: true);
          fs.currentDirectory = ns('/foo/bar');
          expect(fs.currentDirectory.path, ns('/foo/bar'));
          fs.currentDirectory = fs.directory(ns('/baz/qux'));
          expect(fs.currentDirectory.path, ns('/baz/qux'));
        });

        test('succeedsIfSetToParentDirectory', () {
          fs.directory(ns('/foo')).createSync();
          fs.currentDirectory = 'foo';
          expect(fs.currentDirectory.path, ns('/foo'));
          fs.currentDirectory = '..';
          expect(fs.currentDirectory.path, ns('/'));
        });

        test('staysAtRootIfSetToParentOfRoot', () {
          fs.currentDirectory =
              List<String>.filled(20, '..').join(fs.path.separator);
          String cwd = fs.currentDirectory.path;
          expect(cwd, fs.path.rootPrefix(cwd));
        });

        test('removesTrailingSlashIfSet', () {
          fs.directory(ns('/foo')).createSync();
          fs.currentDirectory = ns('/foo/');
          expect(fs.currentDirectory.path, ns('/foo'));
        });

        test('throwsIfSetToFilePathSegmentAtTail', () {
          fs.file(ns('/foo')).createSync();
          expectFileSystemException(ErrorCodes.ENOTDIR, () {
            fs.currentDirectory = ns('/foo');
          });
        });

        test('throwsIfSetToFilePathSegmentViaTraversal', () {
          fs.file(ns('/foo')).createSync();
          expectFileSystemException(ErrorCodes.ENOTDIR, () {
            fs.currentDirectory = ns('/foo/bar/baz');
          });
        });

        test('resolvesLinksIfEncountered', () {
          fs.link(ns('/foo/bar/baz')).createSync(ns('/qux'), recursive: true);
          fs.directory(ns('/qux')).createSync();
          fs.directory(ns('/quux')).createSync();
          fs.currentDirectory = ns('/foo/bar/baz/../quux/');
          expect(fs.currentDirectory.path, ns('/quux'));
        });

        test('succeedsIfSetToDirectoryLinkAtTail', () {
          fs.directory(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          fs.currentDirectory = ns('/bar');
          expect(fs.currentDirectory.path, ns('/foo'));
        });

        test('throwsIfSetToLinkLoop', () {
          fs.link(ns('/foo')).createSync(ns('/bar'));
          fs.link(ns('/bar')).createSync(ns('/foo'));
          expectFileSystemException(
            anyOf(ErrorCodes.EMLINK, ErrorCodes.ELOOP),
            () {
              fs.currentDirectory = ns('/foo');
            },
          );
        });
      });

      group('stat', () {
        test('isNotFoundForPathToNonExistentEntityAtTail', () {
          FileStat stat = fs.statSync(ns('/foo'));
          expect(stat.type, FileSystemEntityType.notFound);
        });

        test('isNotFoundForPathToNonExistentEntityInTraversal', () {
          FileStat stat = fs.statSync(ns('/foo/bar'));
          expect(stat.type, FileSystemEntityType.notFound);
        });

        test('isDirectoryForDirectory', () {
          fs.directory(ns('/foo')).createSync();
          FileStat stat = fs.statSync(ns('/foo'));
          expect(stat.type, FileSystemEntityType.directory);
        });

        test('isFileForFile', () {
          fs.file(ns('/foo')).createSync();
          FileStat stat = fs.statSync(ns('/foo'));
          expect(stat.type, FileSystemEntityType.file);
        });

        test('isFileForLinkToFile', () {
          fs.file(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          FileStat stat = fs.statSync(ns('/bar'));
          expect(stat.type, FileSystemEntityType.file);
        });

        test('isNotFoundForLinkWithCircularReference', () {
          fs.link(ns('/foo')).createSync(ns('/bar'));
          fs.link(ns('/bar')).createSync(ns('/baz'));
          fs.link(ns('/baz')).createSync(ns('/foo'));
          FileStat stat = fs.statSync(ns('/foo'));
          expect(stat.type, FileSystemEntityType.notFound);
        });
      });

      group('identical', () {
        test('isTrueForIdenticalPathsToExistentFile', () {
          fs.file(ns('/foo')).createSync();
          expect(fs.identicalSync(ns('/foo'), ns('/foo')), true);
        });

        test('isFalseForDifferentPathsToDifferentFiles', () {
          fs.file(ns('/foo')).createSync();
          fs.file(ns('/bar')).createSync();
          expect(fs.identicalSync(ns('/foo'), ns('/bar')), false);
        });

        test('isTrueForDifferentPathsToSameFileViaLinkInTraversal', () {
          fs.file(ns('/foo/file')).createSync(recursive: true);
          fs.link(ns('/bar')).createSync(ns('/foo'));
          expect(fs.identicalSync(ns('/foo/file'), ns('/bar/file')), true);
        });

        test('isFalseForDifferentPathsToSameFileViaLinkAtTail', () {
          fs.file(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          expect(fs.identicalSync(ns('/foo'), ns('/bar')), false);
        });

        test('throwsForDifferentPathsToNonExistentEntities', () {
          expectFileSystemException(ErrorCodes.ENOENT, () {
            fs.identicalSync(ns('/foo'), ns('/bar'));
          });
        });

        test('throwsForDifferentPathsToOneFileOneNonExistentEntity', () {
          fs.file(ns('/foo')).createSync();
          expectFileSystemException(ErrorCodes.ENOENT, () {
            fs.identicalSync(ns('/foo'), ns('/bar'));
          });
        });
      });

      group('type', () {
        test('isFileForFile', () {
          fs.file(ns('/foo')).createSync();
          FileSystemEntityType type = fs.typeSync(ns('/foo'));
          expect(type, FileSystemEntityType.file);
        });

        test('isDirectoryForDirectory', () {
          fs.directory(ns('/foo')).createSync();
          FileSystemEntityType type = fs.typeSync(ns('/foo'));
          expect(type, FileSystemEntityType.directory);
        });

        test('isDirectoryForAncestorOfRoot', () {
          FileSystemEntityType type = fs
              .typeSync(List<String>.filled(20, '..').join(fs.path.separator));
          expect(type, FileSystemEntityType.directory);
        });

        test('isFileForLinkToFileAndFollowLinksTrue', () {
          fs.file(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          FileSystemEntityType type = fs.typeSync(ns('/bar'));
          expect(type, FileSystemEntityType.file);
        });

        test('isLinkForLinkToFileAndFollowLinksFalse', () {
          fs.file(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          FileSystemEntityType type =
              fs.typeSync(ns('/bar'), followLinks: false);
          expect(type, FileSystemEntityType.link);
        });

        test('isNotFoundForLinkWithCircularReferenceAndFollowLinksTrue', () {
          fs.link(ns('/foo')).createSync(ns('/bar'));
          fs.link(ns('/bar')).createSync(ns('/baz'));
          fs.link(ns('/baz')).createSync(ns('/foo'));
          FileSystemEntityType type = fs.typeSync(ns('/foo'));
          expect(type, FileSystemEntityType.notFound);
        });

        test('isNotFoundForNoEntityAtTail', () {
          FileSystemEntityType type = fs.typeSync(ns('/foo'));
          expect(type, FileSystemEntityType.notFound);
        });

        test('isNotFoundForNoDirectoryInTraversal', () {
          FileSystemEntityType type = fs.typeSync(ns('/foo/bar/baz'));
          expect(type, FileSystemEntityType.notFound);
        });
      });
    });

    group('Directory', () {
      test('uri', () {
        expect(fs.directory(ns('/foo')).uri, fs.path.toUri(ns('/foo') + '/'));
        expect(fs.directory('foo').uri.toString(), 'foo/');
      });

      group('exists', () {
        test('falseIfNotExists', () {
          expect(fs.directory(ns('/foo')), isNot(exists));
          expect(fs.directory('foo'), isNot(exists));
          expect(fs.directory(ns('/foo/bar')), isNot(exists));
        });

        test('trueIfExistsAsDirectory', () {
          fs.directory(ns('/foo')).createSync();
          expect(fs.directory(ns('/foo')), exists);
          expect(fs.directory('foo'), exists);
        });

        test('falseIfExistsAsFile', () {
          fs.file(ns('/foo')).createSync();
          expect(fs.directory(ns('/foo')), isNot(exists));
          expect(fs.directory('foo'), isNot(exists));
        });

        test('trueIfExistsAsLinkToDirectory', () {
          fs.directory(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          expect(fs.directory(ns('/bar')), exists);
          expect(fs.directory('bar'), exists);
        });

        test('falseIfExistsAsLinkToFile', () {
          fs.file(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          expect(fs.directory(ns('/bar')), isNot(exists));
          expect(fs.directory('bar'), isNot(exists));
        });

        test('falseIfNotFoundSegmentExistsThenIsBackedOut', () {
          fs.directory(ns('/foo')).createSync();
          expect(fs.directory(ns('/bar/../foo')), isNot(exists));
        });
      });

      group('create', () {
        test('returnsCovariantType', () async {
          expect(await fs.directory(ns('/foo')).create(), isDirectory);
        });

        test('succeedsIfAlreadyExistsAsDirectory', () {
          fs.directory(ns('/foo')).createSync();
          fs.directory(ns('/foo')).createSync();
        });

        test('throwsIfAlreadyExistsAsFile', () {
          fs.file(ns('/foo')).createSync();
          expectFileSystemException(ErrorCodes.ENOTDIR, () {
            fs.directory(ns('/foo')).createSync();
          });
        });

        test('succeedsIfAlreadyExistsAsLinkToDirectory', () {
          fs.directory(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          fs.directory(ns('/bar')).createSync();
        });

        test('throwsIfAlreadyExistsAsLinkToFile', () {
          fs.file(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          // TODO(tvolkert): Change this to just be 'Not a directory'
          // once Dart 1.22 is stable.
          expectFileSystemException(
            anyOf(ErrorCodes.EEXIST, ErrorCodes.ENOTDIR),
            () {
              fs.directory(ns('/bar')).createSync();
            },
          );
        });

        test('throwsIfAlreadyExistsAsLinkToNotFoundAtTail', () {
          fs.link(ns('/foo')).createSync(ns('/bar'));
          expectFileSystemException(ErrorCodes.ENOENT, () {
            fs.directory(ns('/foo')).createSync();
          });
        });

        test('throwsIfAlreadyExistsAsLinkToNotFoundViaTraversal', () {
          fs.link(ns('/foo')).createSync(ns('/bar/baz'));
          expectFileSystemException(ErrorCodes.ENOENT, () {
            fs.directory(ns('/foo')).createSync();
          });
        });

        test('throwsIfAlreadyExistsAsLinkToNotFoundInDifferentDirectory', () {
          fs.directory(ns('/foo')).createSync();
          fs.directory(ns('/bar')).createSync();
          fs.link(ns('/bar/baz')).createSync(ns('/foo/qux'));
          expectFileSystemException(ErrorCodes.ENOENT, () {
            fs.directory(ns('/bar/baz')).createSync();
          });
        });

        test('succeedsIfTailDoesntExist', () {
          expect(fs.directory(ns('/')), exists);
          fs.directory(ns('/foo')).createSync();
          expect(fs.directory(ns('/foo')), exists);
        });

        test('throwsIfAncestorDoesntExistRecursiveFalse', () {
          expectFileSystemException(ErrorCodes.ENOENT, () {
            fs.directory(ns('/foo/bar')).createSync();
          });
        });

        test('succeedsIfAncestorDoesntExistRecursiveTrue', () {
          fs.directory(ns('/foo/bar')).createSync(recursive: true);
          expect(fs.directory(ns('/foo')), exists);
          expect(fs.directory(ns('/foo/bar')), exists);
        });
      });

      group('rename', () {
        test('returnsCovariantType', () async {
          Directory src() => fs.directory(ns('/foo'))..createSync();
          expect(src().renameSync(ns('/bar')), isDirectory);
          expect(await src().rename(ns('/baz')), isDirectory);
        });

        test('succeedsIfDestinationDoesntExist', () {
          Directory src = fs.directory(ns('/foo'))..createSync();
          Directory dest = src.renameSync(ns('/bar'));
          expect(dest.path, ns('/bar'));
          expect(dest, exists);
        });

        test(
          'succeedsIfDestinationIsEmptyDirectory',
          () {
            fs.directory(ns('/bar')).createSync();
            Directory src = fs.directory(ns('/foo'))..createSync();
            Directory dest = src.renameSync(ns('/bar'));
            expect(src, isNot(exists));
            expect(dest, exists);
          },
          // See https://github.com/google/file.dart/issues/197.
          skip: io.Platform.isWindows,
        );

        test('throwsIfDestinationIsFile', () {
          fs.file(ns('/bar')).createSync();
          Directory src = fs.directory(ns('/foo'))..createSync();
          expectFileSystemException(ErrorCodes.ENOTDIR, () {
            src.renameSync(ns('/bar'));
          });
        });

        test('throwsIfDestinationParentFolderDoesntExist', () {
          Directory src = fs.directory(ns('/foo'))..createSync();
          expectFileSystemException(ErrorCodes.ENOENT, () {
            src.renameSync(ns('/bar/baz'));
          });
        });

        test('throwsIfDestinationIsNonEmptyDirectory', () {
          fs.file(ns('/bar/baz')).createSync(recursive: true);
          Directory src = fs.directory(ns('/foo'))..createSync();
          // The error will be 'Directory not empty' on OS X, but it will be
          // 'File exists' on Linux.
          expectFileSystemException(
            anyOf(ErrorCodes.ENOTEMPTY, ErrorCodes.EEXIST),
            () {
              src.renameSync(ns('/bar'));
            },
          );
        });

        test('throwsIfSourceDoesntExist', () {
          expectFileSystemException(ErrorCodes.ENOENT, () {
            fs.directory(ns('/foo')).renameSync(ns('/bar'));
          });
        });

        test('throwsIfSourceIsFile', () {
          fs.file(ns('/foo')).createSync();
          expectFileSystemException(ErrorCodes.ENOTDIR, () {
            fs.directory(ns('/foo')).renameSync(ns('/bar'));
          });
        });

        test('succeedsIfSourceIsLinkToDirectory', () {
          fs.directory(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          fs.directory(ns('/bar')).renameSync(ns('/baz'));
          expect(fs.typeSync(ns('/foo'), followLinks: false),
              FileSystemEntityType.directory);
          expect(fs.typeSync(ns('/bar')), FileSystemEntityType.notFound);
          expect(fs.typeSync(ns('/baz'), followLinks: false),
              FileSystemEntityType.link);
          expect(fs.link(ns('/baz')).targetSync(), ns('/foo'));
        });

        test('throwsIfDestinationIsLinkToNotFound', () {
          Directory src = fs.directory(ns('/foo'))..createSync();
          fs.link(ns('/bar')).createSync(ns('/baz'));
          expectFileSystemException(ErrorCodes.ENOTDIR, () {
            src.renameSync(ns('/bar'));
          });
        });

        test('throwsIfDestinationIsLinkToEmptyDirectory', () {
          Directory src = fs.directory(ns('/foo'))..createSync();
          fs.directory(ns('/bar')).createSync();
          fs.link(ns('/baz')).createSync(ns('/bar'));
          expectFileSystemException(ErrorCodes.ENOTDIR, () {
            src.renameSync(ns('/baz'));
          });
        });

        test('succeedsIfDestinationIsInDifferentDirectory', () {
          Directory src = fs.directory(ns('/foo'))..createSync();
          fs.directory(ns('/bar')).createSync();
          src.renameSync(ns('/bar/baz'));
          expect(fs.typeSync(ns('/foo')), FileSystemEntityType.notFound);
          expect(fs.typeSync(ns('/bar/baz')), FileSystemEntityType.directory);
        });

        test('succeedsIfSourceIsLinkToDifferentDirectory', () {
          fs.directory(ns('/foo/subfoo')).createSync(recursive: true);
          fs.directory(ns('/bar/subbar')).createSync(recursive: true);
          fs.directory(ns('/baz/subbaz')).createSync(recursive: true);
          fs.link(ns('/foo/subfoo/lnk')).createSync(ns('/bar/subbar'));
          fs.directory(ns('/foo/subfoo/lnk')).renameSync(ns('/baz/subbaz/dst'));
          expect(fs.typeSync(ns('/foo/subfoo/lnk')),
              FileSystemEntityType.notFound);
          expect(fs.typeSync(ns('/baz/subbaz/dst'), followLinks: false),
              FileSystemEntityType.link);
          expect(fs.typeSync(ns('/baz/subbaz/dst'), followLinks: true),
              FileSystemEntityType.directory);
        });
      });

      group('delete', () {
        test('returnsCovariantType', () async {
          Directory dir = fs.directory(ns('/foo'))..createSync();
          expect(await dir.delete(), isDirectory);
        });

        test('succeedsIfEmptyDirectoryExistsAndRecursiveFalse', () {
          Directory dir = fs.directory(ns('/foo'))..createSync();
          dir.deleteSync();
          expect(dir, isNot(exists));
        });

        test('succeedsIfEmptyDirectoryExistsAndRecursiveTrue', () {
          Directory dir = fs.directory(ns('/foo'))..createSync();
          dir.deleteSync(recursive: true);
          expect(dir, isNot(exists));
        });

        test('throwsIfNonEmptyDirectoryExistsAndRecursiveFalse', () {
          Directory dir = fs.directory(ns('/foo'))..createSync();
          fs.file(ns('/foo/bar')).createSync();
          expectFileSystemException(ErrorCodes.ENOTEMPTY, () {
            dir.deleteSync();
          });
        });

        test('succeedsIfNonEmptyDirectoryExistsAndRecursiveTrue', () {
          Directory dir = fs.directory(ns('/foo'))..createSync();
          fs.file(ns('/foo/bar')).createSync();
          dir.deleteSync(recursive: true);
          expect(fs.directory(ns('/foo')), isNot(exists));
          expect(fs.file(ns('/foo/bar')), isNot(exists));
        });

        test('throwsIfDirectoryDoesntExistAndRecursiveFalse', () {
          expectFileSystemException(ErrorCodes.ENOENT, () {
            fs.directory(ns('/foo')).deleteSync();
          });
        });

        test('throwsIfDirectoryDoesntExistAndRecursiveTrue', () {
          expectFileSystemException(ErrorCodes.ENOENT, () {
            fs.directory(ns('/foo')).deleteSync(recursive: true);
          });
        });

        test('succeedsIfPathReferencesFileAndRecursiveTrue', () {
          fs.file(ns('/foo')).createSync();
          fs.directory(ns('/foo')).deleteSync(recursive: true);
          expect(fs.typeSync(ns('/foo')), FileSystemEntityType.notFound);
        });

        test('throwsIfPathReferencesFileAndRecursiveFalse', () {
          fs.file(ns('/foo')).createSync();
          expectFileSystemException(ErrorCodes.ENOTDIR, () {
            fs.directory(ns('/foo')).deleteSync();
          });
        });

        test('succeedsIfPathReferencesLinkToDirectoryAndRecursiveTrue', () {
          fs.directory(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          fs.directory(ns('/bar')).deleteSync(recursive: true);
          expect(fs.typeSync(ns('/foo'), followLinks: false),
              FileSystemEntityType.directory);
          expect(fs.typeSync(ns('/bar'), followLinks: false),
              FileSystemEntityType.notFound);
        });

        test('succeedsIfPathReferencesLinkToDirectoryAndRecursiveFalse', () {
          fs.directory(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          fs.directory(ns('/bar')).deleteSync();
          expect(fs.typeSync(ns('/foo'), followLinks: false),
              FileSystemEntityType.directory);
          expect(fs.typeSync(ns('/bar'), followLinks: false),
              FileSystemEntityType.notFound);
        });

        test('succeedsIfExistsAsLinkToDirectoryInDifferentDirectory', () {
          fs.directory(ns('/foo/bar')).createSync(recursive: true);
          fs.link(ns('/baz/qux')).createSync(ns('/foo/bar'), recursive: true);
          fs.directory(ns('/baz/qux')).deleteSync();
          expect(fs.typeSync(ns('/foo/bar'), followLinks: false),
              FileSystemEntityType.directory);
          expect(fs.typeSync(ns('/baz/qux'), followLinks: false),
              FileSystemEntityType.notFound);
        });

        test('succeedsIfPathReferencesLinkToFileAndRecursiveTrue', () {
          fs.file(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          fs.directory(ns('/bar')).deleteSync(recursive: true);
          expect(fs.typeSync(ns('/foo'), followLinks: false),
              FileSystemEntityType.file);
          expect(fs.typeSync(ns('/bar'), followLinks: false),
              FileSystemEntityType.notFound);
        });

        test('throwsIfPathReferencesLinkToFileAndRecursiveFalse', () {
          fs.file(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          expectFileSystemException(ErrorCodes.ENOTDIR, () {
            fs.directory(ns('/bar')).deleteSync();
          });
        });

        test('throwsIfPathReferencesLinkToNotFoundAndRecursiveFalse', () {
          fs.link(ns('/foo')).createSync(ns('/bar'));
          expectFileSystemException(ErrorCodes.ENOTDIR, () {
            fs.directory(ns('/foo')).deleteSync();
          });
        });
      });

      group('resolveSymbolicLinks', () {
        test('succeedsForRootDirectory', () {
          expect(fs.directory(ns('/')).resolveSymbolicLinksSync(), ns('/'));
        });

        test('throwsIfPathIsEmpty', () {
          expectFileSystemException(ErrorCodes.ENOENT, () {
            fs.directory('').resolveSymbolicLinksSync();
          });
        });

        test('throwsIfLoopInLinkChain', () {
          fs.link(ns('/foo')).createSync(ns('/bar'));
          fs.link(ns('/bar')).createSync(ns('/baz'));
          fs.link(ns('/baz')).createSync(ns('/foo'));
          expectFileSystemException(
            anyOf(ErrorCodes.EMLINK, ErrorCodes.ELOOP),
            () {
              fs.directory(ns('/foo')).resolveSymbolicLinksSync();
            },
          );
        });

        test('throwsIfPathNotFoundInTraversal', () {
          expectFileSystemException(ErrorCodes.ENOENT, () {
            fs.directory(ns('/foo/bar')).resolveSymbolicLinksSync();
          });
        });

        test('throwsIfPathNotFoundAtTail', () {
          expectFileSystemException(ErrorCodes.ENOENT, () {
            fs.directory(ns('/foo')).resolveSymbolicLinksSync();
          });
        });

        test('throwsIfPathNotFoundInMiddleThenBackedOut', () {
          fs.directory(ns('/foo/bar')).createSync(recursive: true);
          expectFileSystemException(ErrorCodes.ENOENT, () {
            fs.directory(ns('/foo/baz/../bar')).resolveSymbolicLinksSync();
          });
        });

        test('resolvesRelativePathToCurrentDirectory', () {
          fs.directory(ns('/foo/bar')).createSync(recursive: true);
          fs.link(ns('/foo/baz')).createSync(ns('/foo/bar'));
          fs.currentDirectory = ns('/foo');
          expect(
              fs.directory('baz').resolveSymbolicLinksSync(), ns('/foo/bar'));
        });

        test('resolvesAbsolutePathsAbsolutely', () {
          fs.directory(ns('/foo/bar')).createSync(recursive: true);
          fs.currentDirectory = ns('/foo');
          expect(fs.directory(ns('/foo/bar')).resolveSymbolicLinksSync(),
              ns('/foo/bar'));
        });

        test('handlesRelativeLinks', () {
          fs.directory(ns('/foo/bar/baz')).createSync(recursive: true);
          fs.link(ns('/foo/qux')).createSync(fs.path.join('bar', 'baz'));
          expect(
            fs.directory(ns('/foo/qux')).resolveSymbolicLinksSync(),
            ns('/foo/bar/baz'),
          );
          expect(
            fs.directory(fs.path.join('foo', 'qux')).resolveSymbolicLinksSync(),
            ns('/foo/bar/baz'),
          );
        });

        test('handlesAbsoluteLinks', () {
          fs.directory(ns('/foo')).createSync();
          fs.directory(ns('/bar/baz/qux')).createSync(recursive: true);
          fs.link(ns('/foo/quux')).createSync(ns('/bar/baz/qux'));
          expect(fs.directory(ns('/foo/quux')).resolveSymbolicLinksSync(),
              ns('/bar/baz/qux'));
        });

        test('handlesLinksWhoseTargetsHaveNestedLinks', () {
          fs.directory(ns('/foo')).createSync();
          fs.link(ns('/foo/quuz')).createSync(ns('/bar'));
          fs.link(ns('/foo/grault')).createSync(ns('/baz/quux'));
          fs.directory(ns('/bar')).createSync();
          fs.link(ns('/bar/qux')).createSync(ns('/baz'));
          fs.link(ns('/bar/garply')).createSync(ns('/foo'));
          fs.directory(ns('/baz')).createSync();
          fs.link(ns('/baz/quux')).createSync(ns('/bar/garply/quuz'));
          expect(fs.directory(ns('/foo/grault/qux')).resolveSymbolicLinksSync(),
              ns('/baz'));
        });

        test('handlesParentAndThisFolderReferences', () {
          fs.directory(ns('/foo/bar/baz')).createSync(recursive: true);
          fs.link(ns('/foo/bar/baz/qux')).createSync(fs.path.join('..', '..'));
          String resolved = fs
              .directory(ns('/foo/./bar/baz/../baz/qux/bar'))
              .resolveSymbolicLinksSync();
          expect(resolved, ns('/foo/bar'));
        });

        test('handlesBackToBackSlashesInPath', () {
          fs.directory(ns('/foo/bar/baz')).createSync(recursive: true);
          expect(fs.directory(ns('//foo/bar///baz')).resolveSymbolicLinksSync(),
              ns('/foo/bar/baz'));
        });

        test('handlesComplexPathWithMultipleLinks', () {
          fs
              .link(ns('/foo/bar/baz'))
              .createSync(fs.path.join('..', '..', 'qux'), recursive: true);
          fs.link(ns('/qux')).createSync('quux');
          fs.link(ns('/quux/quuz')).createSync(ns('/foo'), recursive: true);
          String resolved = fs
              .directory(ns('/foo//bar/./baz/quuz/bar/..///bar/baz/'))
              .resolveSymbolicLinksSync();
          expect(resolved, ns('/quux'));
        });
      });

      group('absolute', () {
        test('returnsCovariantType', () {
          expect(fs.directory('foo').absolute, isDirectory);
        });

        test('returnsSamePathIfAlreadyAbsolute', () {
          expect(fs.directory(ns('/foo')).absolute.path, ns('/foo'));
        });

        test('succeedsForRelativePaths', () {
          expect(fs.directory('foo').absolute.path, ns('/foo'));
        });
      });

      group('parent', () {
        late String root;

        setUp(() {
          root = fs.path.style.name == 'windows' ? r'C:\' : '/';
        });

        test('returnsCovariantType', () {
          expect(fs.directory(root).parent, isDirectory);
        });

        test('returnsRootForRoot', () {
          expect(fs.directory(root).parent.path, root);
        });

        test('succeedsForNonRoot', () {
          expect(fs.directory(ns('/foo/bar')).parent.path, ns('/foo'));
        });
      });

      group('createTemp', () {
        test('returnsCovariantType', () {
          expect(fs.directory(ns('/')).createTempSync(), isDirectory);
        });

        test('throwsIfDirectoryDoesntExist', () {
          expectFileSystemException(ErrorCodes.ENOENT, () {
            fs.directory(ns('/foo')).createTempSync();
          });
        });

        test('resolvesNameCollisions', () {
          fs.directory(ns('/foo/bar')).createSync(recursive: true);
          Directory tmp = fs.directory(ns('/foo')).createTempSync('bar');
          expect(tmp.path,
              allOf(isNot(ns('/foo/bar')), startsWith(ns('/foo/bar'))));
        });

        test('succeedsWithoutPrefix', () {
          Directory dir = fs.directory(ns('/foo'))..createSync();
          expect(dir.createTempSync().path, startsWith(ns('/foo/')));
        });

        test('succeedsWithPrefix', () {
          Directory dir = fs.directory(ns('/foo'))..createSync();
          expect(dir.createTempSync('bar').path, startsWith(ns('/foo/bar')));
        });

        test('succeedsWithNestedPathPrefixThatExists', () {
          fs.directory(ns('/foo/bar')).createSync(recursive: true);
          Directory tmp = fs.directory(ns('/foo')).createTempSync('bar/baz');
          expect(tmp.path, startsWith(ns('/foo/bar/baz')));
        });

        test('throwsWithNestedPathPrefixThatDoesntExist', () {
          Directory dir = fs.directory(ns('/foo'))..createSync();
          expectFileSystemException(ErrorCodes.ENOENT, () {
            dir.createTempSync('bar/baz');
          });
        });
      });

      group('list', () {
        late Directory dir;

        setUp(() {
          dir = fs.currentDirectory = fs.directory(ns('/foo'))..createSync();
          fs.file('bar').createSync();
          fs.file(fs.path.join('baz', 'qux')).createSync(recursive: true);
          fs.link('quux').createSync(fs.path.join('baz', 'qux'));
          fs
              .link(fs.path.join('baz', 'quuz'))
              .createSync(fs.path.join('..', 'quux'));
          fs.link(fs.path.join('baz', 'grault')).createSync('.');
          fs.currentDirectory = ns('/');
        });

        test('returnsCovariantType', () async {
          void expectIsFileSystemEntity(dynamic entity) {
            expect(entity, isFileSystemEntity);
          }

          dir.listSync().forEach(expectIsFileSystemEntity);
          (await dir.list().toList()).forEach(expectIsFileSystemEntity);
        });

        test('returnsEmptyListForEmptyDirectory', () {
          Directory empty = fs.directory(ns('/bar'))..createSync();
          expect(empty.listSync(), isEmpty);
        });

        test('throwsIfDirectoryDoesntExist', () {
          expectFileSystemException(ErrorCodes.ENOENT, () {
            fs.directory(ns('/bar')).listSync();
          });
        });

        test('returnsLinkObjectsIfFollowLinksFalse', () {
          List<FileSystemEntity> list = dir.listSync(followLinks: false);
          expect(list, hasLength(3));
          expect(list, contains(allOf(isFile, hasPath(ns('/foo/bar')))));
          expect(list, contains(allOf(isDirectory, hasPath(ns('/foo/baz')))));
          expect(list, contains(allOf(isLink, hasPath(ns('/foo/quux')))));
        });

        test('followsLinksIfFollowLinksTrue', () {
          List<FileSystemEntity> list = dir.listSync();
          expect(list, hasLength(3));
          expect(list, contains(allOf(isFile, hasPath(ns('/foo/bar')))));
          expect(list, contains(allOf(isDirectory, hasPath(ns('/foo/baz')))));
          expect(list, contains(allOf(isFile, hasPath(ns('/foo/quux')))));
        });

        test('returnsLinkObjectsForRecursiveLinkIfFollowLinksTrue', () {
          expect(
            dir.listSync(recursive: true),
            allOf(
              hasLength(9),
              allOf(
                contains(allOf(isFile, hasPath(ns('/foo/bar')))),
                contains(allOf(isFile, hasPath(ns('/foo/quux')))),
                contains(allOf(isFile, hasPath(ns('/foo/baz/qux')))),
                contains(allOf(isFile, hasPath(ns('/foo/baz/quuz')))),
                contains(allOf(isFile, hasPath(ns('/foo/baz/grault/qux')))),
                contains(allOf(isFile, hasPath(ns('/foo/baz/grault/quuz')))),
              ),
              allOf(
                contains(allOf(isDirectory, hasPath(ns('/foo/baz')))),
                contains(allOf(isDirectory, hasPath(ns('/foo/baz/grault')))),
              ),
              contains(allOf(isLink, hasPath(ns('/foo/baz/grault/grault')))),
            ),
          );
        });

        test('recurseIntoDirectoriesIfRecursiveTrueFollowLinksFalse', () {
          expect(
            dir.listSync(recursive: true, followLinks: false),
            allOf(
              hasLength(6),
              contains(allOf(isFile, hasPath(ns('/foo/bar')))),
              contains(allOf(isFile, hasPath(ns('/foo/baz/qux')))),
              contains(allOf(isLink, hasPath(ns('/foo/quux')))),
              contains(allOf(isLink, hasPath(ns('/foo/baz/quuz')))),
              contains(allOf(isLink, hasPath(ns('/foo/baz/grault')))),
              contains(allOf(isDirectory, hasPath(ns('/foo/baz')))),
            ),
          );
        });

        test('childEntriesNotNormalized', () {
          dir = fs.directory(ns('/bar/baz'))..createSync(recursive: true);
          fs.file(ns('/bar/baz/qux')).createSync();
          List<FileSystemEntity> list =
              fs.directory(ns('/bar//../bar/./baz')).listSync();
          expect(list, hasLength(1));
          expect(list[0], allOf(isFile, hasPath(ns('/bar//../bar/./baz/qux'))));
        });

        test('symlinksToNotFoundAlwaysReturnedAsLinks', () {
          dir = fs.directory(ns('/bar'))..createSync();
          fs.link(ns('/bar/baz')).createSync('qux');
          for (bool followLinks in const <bool>[true, false]) {
            List<FileSystemEntity> list =
                dir.listSync(followLinks: followLinks);
            expect(list, hasLength(1));
            expect(list[0], allOf(isLink, hasPath(ns('/bar/baz'))));
          }
        });
      });

      test('childEntities', () {
        Directory dir = fs.directory(ns('/foo'))..createSync();
        dir.childDirectory('bar').createSync();
        dir.childFile('baz').createSync();
        dir.childLink('qux').createSync('bar');
        expect(fs.directory(ns('/foo/bar')), exists);
        expect(fs.file(ns('/foo/baz')), exists);
        expect(fs.link(ns('/foo/qux')), exists);
      });
    });

    group('File', () {
      test('uri', () {
        expect(fs.file(ns('/foo')).uri, fs.path.toUri(ns('/foo')));
        expect(fs.file('foo').uri.toString(), 'foo');
      });

      group('create', () {
        test('returnsCovariantType', () async {
          expect(await fs.file(ns('/foo')).create(), isFile);
        });

        test('succeedsIfTailDoesntAlreadyExist', () {
          fs.file(ns('/foo')).createSync();
          expect(fs.file(ns('/foo')), exists);
        });

        test('succeedsIfAlreadyExistsAsFile', () {
          fs.file(ns('/foo')).createSync();
          fs.file(ns('/foo')).createSync();
          expect(fs.file(ns('/foo')), exists);
        });

        test('throwsIfAncestorDoesntExistRecursiveFalse', () {
          expectFileSystemException(ErrorCodes.ENOENT, () {
            fs.file(ns('/foo/bar')).createSync();
          });
        });

        test('succeedsIfAncestorDoesntExistRecursiveTrue', () {
          fs.file(ns('/foo/bar')).createSync(recursive: true);
          expect(fs.file(ns('/foo/bar')), exists);
        });

        test('throwsIfAlreadyExistsAsDirectory', () {
          fs.directory(ns('/foo')).createSync();
          expectFileSystemException(ErrorCodes.EISDIR, () {
            fs.file(ns('/foo')).createSync();
          });
        });

        test('throwsIfAlreadyExistsAsLinkToDirectory', () {
          fs.directory(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          expectFileSystemException(ErrorCodes.EISDIR, () {
            fs.file(ns('/bar')).createSync();
          });
        });

        test('succeedsIfAlreadyExistsAsLinkToFile', () {
          fs.file(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          fs.file(ns('/bar')).createSync();
          expect(fs.file(ns('/bar')), exists);
        });

        test('succeedsIfAlreadyExistsAsLinkToNotFoundAtTail', () {
          fs.link(ns('/foo')).createSync(ns('/bar'));
          fs.file(ns('/foo')).createSync();
          expect(fs.typeSync(ns('/foo'), followLinks: false),
              FileSystemEntityType.link);
          expect(fs.typeSync(ns('/bar'), followLinks: false),
              FileSystemEntityType.file);
        });

        test('throwsIfAlreadyExistsAsLinkToNotFoundViaTraversal', () {
          fs.link(ns('/foo')).createSync(ns('/bar/baz'));
          expectFileSystemException(ErrorCodes.ENOENT, () {
            fs.file(ns('/foo')).createSync();
          });
          expectFileSystemException(ErrorCodes.ENOENT, () {
            fs.file(ns('/foo')).createSync(recursive: true);
          });
        });

        /*
        test('throwsIfPathSegmentIsLinkToNotFoundAndRecursiveTrue', () {
          fs.link(ns('/foo')).createSync(ns('/bar'));
          expectFileSystemException(ErrorCodes.ENOENT, () {
            fs.file(ns('/foo/baz')).createSync(recursive: true);
          });
        });
        */

        test('succeedsIfAlreadyExistsAsLinkToNotFoundInDifferentDirectory', () {
          fs.directory(ns('/foo')).createSync();
          fs.directory(ns('/bar')).createSync();
          fs.link(ns('/bar/baz')).createSync(ns('/foo/qux'));
          fs.file(ns('/bar/baz')).createSync();
          expect(fs.typeSync(ns('/bar/baz'), followLinks: false),
              FileSystemEntityType.link);
          expect(fs.typeSync(ns('/foo/qux'), followLinks: false),
              FileSystemEntityType.file);
        });
      });

      group('rename', () {
        test('returnsCovariantType', () async {
          File f() => fs.file(ns('/foo'))..createSync();
          expect(await f().rename(ns('/bar')), isFile);
          expect(f().renameSync(ns('/baz')), isFile);
        });

        test('succeedsIfDestinationDoesntExistAtTail', () {
          File src = fs.file(ns('/foo'))..createSync();
          File dest = src.renameSync(ns('/bar'));
          expect(fs.file(ns('/foo')), isNot(exists));
          expect(fs.file(ns('/bar')), exists);
          expect(dest.path, ns('/bar'));
        });

        test('throwsIfDestinationDoesntExistViaTraversal', () {
          File f = fs.file(ns('/foo'))..createSync();
          expectFileSystemException(ErrorCodes.ENOENT, () {
            f.renameSync(ns('/bar/baz'));
          });
        });

        test('succeedsIfDestinationExistsAsFile', () {
          File f = fs.file(ns('/foo'))..createSync();
          fs.file(ns('/bar')).createSync();
          f.renameSync(ns('/bar'));
          expect(fs.file(ns('/foo')), isNot(exists));
          expect(fs.file(ns('/bar')), exists);
        });

        test('throwsIfDestinationExistsAsDirectory', () {
          File f = fs.file(ns('/foo'))..createSync();
          fs.directory(ns('/bar')).createSync();
          expectFileSystemException(ErrorCodes.EISDIR, () {
            f.renameSync(ns('/bar'));
          });
        });

        test('succeedsIfDestinationExistsAsLinkToFile', () {
          File f = fs.file(ns('/foo'))..createSync();
          fs.file(ns('/bar')).createSync();
          fs.link(ns('/baz')).createSync(ns('/bar'));
          f.renameSync(ns('/baz'));
          expect(fs.typeSync(ns('/foo')), FileSystemEntityType.notFound);
          expect(fs.typeSync(ns('/bar'), followLinks: false),
              FileSystemEntityType.file);
          expect(fs.typeSync(ns('/baz'), followLinks: false),
              FileSystemEntityType.file);
        });

        test('throwsIfDestinationExistsAsLinkToDirectory', () {
          File f = fs.file(ns('/foo'))..createSync();
          fs.directory(ns('/bar')).createSync();
          fs.link(ns('/baz')).createSync(ns('/bar'));
          expectFileSystemException(ErrorCodes.EISDIR, () {
            f.renameSync(ns('/baz'));
          });
        });

        test('succeedsIfDestinationExistsAsLinkToNotFound', () {
          File f = fs.file(ns('/foo'))..createSync();
          fs.link(ns('/bar')).createSync(ns('/baz'));
          f.renameSync(ns('/bar'));
          expect(fs.typeSync(ns('/foo')), FileSystemEntityType.notFound);
          expect(fs.typeSync(ns('/bar'), followLinks: false),
              FileSystemEntityType.file);
        });

        test('throwsIfSourceDoesntExist', () {
          expectFileSystemException(ErrorCodes.ENOENT, () {
            fs.file(ns('/foo')).renameSync(ns('/bar'));
          });
        });

        test('throwsIfSourceExistsAsDirectory', () {
          fs.directory(ns('/foo')).createSync();
          expectFileSystemException(ErrorCodes.EISDIR, () {
            fs.file(ns('/foo')).renameSync(ns('/bar'));
          });
        });

        test('succeedsIfSourceExistsAsLinkToFile', () {
          fs.file(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          fs.file(ns('/bar')).renameSync(ns('/baz'));
          expect(fs.typeSync(ns('/bar')), FileSystemEntityType.notFound);
          expect(fs.typeSync(ns('/baz'), followLinks: false),
              FileSystemEntityType.link);
          expect(fs.typeSync(ns('/baz'), followLinks: true),
              FileSystemEntityType.file);
        });

        test('throwsIfSourceExistsAsLinkToDirectory', () {
          fs.directory(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          expectFileSystemException(ErrorCodes.EISDIR, () {
            fs.file(ns('/bar')).renameSync(ns('/baz'));
          });
        });

        test('throwsIfSourceExistsAsLinkToNotFound', () {
          fs.link(ns('/foo')).createSync(ns('/bar'));
          expectFileSystemException(ErrorCodes.ENOENT, () {
            fs.file(ns('/foo')).renameSync(ns('/baz'));
          });
        });
      });

      group('copy', () {
        test('returnsCovariantType', () async {
          File f() => fs.file(ns('/foo'))..createSync();
          expect(await f().copy(ns('/bar')), isFile);
          expect(f().copySync(ns('/baz')), isFile);
        });

        test('succeedsIfDestinationDoesntExistAtTail', () {
          File f = fs.file(ns('/foo'))
            ..createSync()
            ..writeAsStringSync('foo');
          f.copySync(ns('/bar'));
          expect(fs.file(ns('/foo')), exists);
          expect(fs.file(ns('/bar')), exists);
          expect(fs.file(ns('/foo')).readAsStringSync(), 'foo');
        });

        test('throwsIfDestinationDoesntExistViaTraversal', () {
          File f = fs.file(ns('/foo'))..createSync();
          expectFileSystemException(ErrorCodes.ENOENT, () {
            f.copySync(ns('/bar/baz'));
          });
        });

        test('succeedsIfDestinationExistsAsFile', () {
          File f = fs.file(ns('/foo'))
            ..createSync()
            ..writeAsStringSync('foo');
          fs.file(ns('/bar'))
            ..createSync()
            ..writeAsStringSync('bar');
          f.copySync(ns('/bar'));
          expect(fs.file(ns('/foo')), exists);
          expect(fs.file(ns('/bar')), exists);
          expect(fs.file(ns('/foo')).readAsStringSync(), 'foo');
          expect(fs.file(ns('/bar')).readAsStringSync(), 'foo');
        });

        test('throwsIfDestinationExistsAsDirectory', () {
          File f = fs.file(ns('/foo'))..createSync();
          fs.directory(ns('/bar')).createSync();
          expectFileSystemException(ErrorCodes.EISDIR, () {
            f.copySync(ns('/bar'));
          });
        });

        test('succeedsIfDestinationExistsAsLinkToFile', () {
          File f = fs.file(ns('/foo'))
            ..createSync()
            ..writeAsStringSync('foo');
          fs.file(ns('/bar'))
            ..createSync()
            ..writeAsStringSync('bar');
          fs.link(ns('/baz')).createSync(ns('/bar'));
          f.copySync(ns('/baz'));
          expect(fs.typeSync(ns('/foo'), followLinks: false),
              FileSystemEntityType.file);
          expect(fs.typeSync(ns('/bar'), followLinks: false),
              FileSystemEntityType.file);
          expect(fs.typeSync(ns('/baz'), followLinks: false),
              FileSystemEntityType.link);
          expect(fs.file(ns('/foo')).readAsStringSync(), 'foo');
          expect(fs.file(ns('/bar')).readAsStringSync(), 'foo');
        }, skip: io.Platform.isWindows /* No links on Windows */);

        test('throwsIfDestinationExistsAsLinkToDirectory', () {
          File f = fs.file(ns('/foo'))..createSync();
          fs.directory(ns('/bar')).createSync();
          fs.link(ns('/baz')).createSync(ns('/bar'));
          expectFileSystemException(ErrorCodes.EISDIR, () {
            f.copySync(ns('/baz'));
          });
        });

        test('throwsIfSourceDoesntExist', () {
          expectFileSystemException(ErrorCodes.ENOENT, () {
            fs.file(ns('/foo')).copySync(ns('/bar'));
          });
        });

        test('throwsIfSourceExistsAsDirectory', () {
          fs.directory(ns('/foo')).createSync();
          expectFileSystemException(ErrorCodes.EISDIR, () {
            fs.file(ns('/foo')).copySync(ns('/bar'));
          });
        });

        test('succeedsIfSourceExistsAsLinkToFile', () {
          fs.file(ns('/foo'))
            ..createSync()
            ..writeAsStringSync('foo');
          fs.link(ns('/bar')).createSync(ns('/foo'));
          fs.file(ns('/bar')).copySync(ns('/baz'));
          expect(fs.typeSync(ns('/foo'), followLinks: false),
              FileSystemEntityType.file);
          expect(fs.typeSync(ns('/bar'), followLinks: false),
              FileSystemEntityType.link);
          expect(fs.typeSync(ns('/baz'), followLinks: false),
              FileSystemEntityType.file);
          expect(fs.file(ns('/foo')).readAsStringSync(), 'foo');
          expect(fs.file(ns('/baz')).readAsStringSync(), 'foo');
        });

        test('succeedsIfDestinationIsInDifferentDirectoryThanSource', () {
          File f = fs.file(ns('/foo/bar'))
            ..createSync(recursive: true)
            ..writeAsStringSync('foo');
          fs.directory(ns('/baz')).createSync();
          f.copySync(ns('/baz/qux'));
          expect(fs.file(ns('/foo/bar')), exists);
          expect(fs.file(ns('/baz/qux')), exists);
          expect(fs.file(ns('/foo/bar')).readAsStringSync(), 'foo');
          expect(fs.file(ns('/baz/qux')).readAsStringSync(), 'foo');
        });

        test('succeedsIfSourceIsLinkToFileInDifferentDirectory', () {
          fs.file(ns('/foo/bar'))
            ..createSync(recursive: true)
            ..writeAsStringSync('foo');
          fs.link(ns('/baz/qux')).createSync(ns('/foo/bar'), recursive: true);
          fs.file(ns('/baz/qux')).copySync(ns('/baz/quux'));
          expect(fs.typeSync(ns('/foo/bar'), followLinks: false),
              FileSystemEntityType.file);
          expect(fs.typeSync(ns('/baz/qux'), followLinks: false),
              FileSystemEntityType.link);
          expect(fs.typeSync(ns('/baz/quux'), followLinks: false),
              FileSystemEntityType.file);
          expect(fs.file(ns('/foo/bar')).readAsStringSync(), 'foo');
          expect(fs.file(ns('/baz/quux')).readAsStringSync(), 'foo');
        });

        test('succeedsIfDestinationIsLinkToFileInDifferentDirectory', () {
          fs.file(ns('/foo/bar'))
            ..createSync(recursive: true)
            ..writeAsStringSync('bar');
          fs.file(ns('/baz/qux'))
            ..createSync(recursive: true)
            ..writeAsStringSync('qux');
          fs.link(ns('/baz/quux')).createSync(ns('/foo/bar'));
          fs.file(ns('/baz/qux')).copySync(ns('/baz/quux'));
          expect(fs.typeSync(ns('/foo/bar'), followLinks: false),
              FileSystemEntityType.file);
          expect(fs.typeSync(ns('/baz/qux'), followLinks: false),
              FileSystemEntityType.file);
          expect(fs.typeSync(ns('/baz/quux'), followLinks: false),
              FileSystemEntityType.link);
          expect(fs.file(ns('/foo/bar')).readAsStringSync(), 'qux');
          expect(fs.file(ns('/baz/qux')).readAsStringSync(), 'qux');
        }, skip: io.Platform.isWindows /* No links on Windows */);
      });

      group('length', () {
        test('throwsIfDoesntExist', () {
          expectFileSystemException(ErrorCodes.ENOENT, () {
            fs.file(ns('/foo')).lengthSync();
          });
        });

        test('throwsIfExistsAsDirectory', () {
          fs.directory(ns('/foo')).createSync();
          expectFileSystemException(ErrorCodes.EISDIR, () {
            fs.file(ns('/foo')).lengthSync();
          });
        });

        test('returnsZeroForNewlyCreatedFile', () {
          File f = fs.file(ns('/foo'))..createSync();
          expect(f.lengthSync(), 0);
        });

        test('writeNBytesReturnsLengthN', () {
          File f = fs.file(ns('/foo'))..createSync();
          f.writeAsBytesSync(<int>[1, 2, 3, 4], flush: true);
          expect(f.lengthSync(), 4);
        });

        test('succeedsIfExistsAsLinkToFile', () {
          fs.file(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          expect(fs.file(ns('/bar')).lengthSync(), 0);
        });
      });

      group('absolute', () {
        test('returnsSamePathIfAlreadyAbsolute', () {
          expect(fs.file(ns('/foo')).absolute.path, ns('/foo'));
        });

        test('succeedsForRelativePaths', () {
          expect(fs.file('foo').absolute.path, ns('/foo'));
        });
      });

      group('lastAccessed', () {
        test('isNowForNewlyCreatedFile', () {
          DateTime before = downstairs();
          File f = fs.file(ns('/foo'))..createSync();
          DateTime after = ceil();
          DateTime accessed = f.lastAccessedSync();
          expect(accessed, isSameOrAfter(before));
          expect(accessed, isSameOrBefore(after));
        });

        test('throwsIfDoesntExist', () {
          expectFileSystemException(ErrorCodes.ENOENT, () {
            fs.file(ns('/foo')).lastAccessedSync();
          });
        });

        test('throwsIfExistsAsDirectory', () {
          fs.directory(ns('/foo')).createSync();
          expectFileSystemException(ErrorCodes.EISDIR, () {
            fs.file(ns('/foo')).lastAccessedSync();
          });
        });

        test('succeedsIfExistsAsLinkToFile', () {
          DateTime before = downstairs();
          fs.file(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          DateTime after = ceil();
          DateTime accessed = fs.file(ns('/bar')).lastAccessedSync();
          expect(accessed, isSameOrAfter(before));
          expect(accessed, isSameOrBefore(after));
        });
      });

      group('setLastAccessed', () {
        final DateTime time = DateTime(1999);

        test('throwsIfDoesntExist', () {
          expectFileSystemException(ErrorCodes.ENOENT, () {
            fs.file(ns('/foo')).setLastAccessedSync(time);
          });
        });

        test('throwsIfExistsAsDirectory', () {
          fs.directory(ns('/foo')).createSync();
          expectFileSystemException(ErrorCodes.EISDIR, () {
            fs.file(ns('/foo')).setLastAccessedSync(time);
          });
        });

        test('succeedsIfExistsAsFile', () {
          File f = fs.file(ns('/foo'))..createSync();
          f.setLastAccessedSync(time);
          expect(fs.file(ns('/foo')).lastAccessedSync(), time);
        });

        test('succeedsIfExistsAsLinkToFile', () {
          File f = fs.file(ns('/foo'))..createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          f.setLastAccessedSync(time);
          expect(fs.file(ns('/bar')).lastAccessedSync(), time);
        });
      });

      group('lastModified', () {
        test('isNowForNewlyCreatedFile', () {
          DateTime before = downstairs();
          File f = fs.file(ns('/foo'))..createSync();
          DateTime after = ceil();
          DateTime modified = f.lastModifiedSync();
          expect(modified, isSameOrAfter(before));
          expect(modified, isSameOrBefore(after));
        });

        test('throwsIfDoesntExist', () {
          expectFileSystemException(ErrorCodes.ENOENT, () {
            fs.file(ns('/foo')).lastModifiedSync();
          });
        });

        test('throwsIfExistsAsDirectory', () {
          fs.directory(ns('/foo')).createSync();
          expectFileSystemException(ErrorCodes.EISDIR, () {
            fs.file(ns('/foo')).lastModifiedSync();
          });
        });

        test('succeedsIfExistsAsLinkToFile', () {
          DateTime before = downstairs();
          fs.file(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          DateTime after = ceil();
          DateTime modified = fs.file(ns('/bar')).lastModifiedSync();
          expect(modified, isSameOrAfter(before));
          expect(modified, isSameOrBefore(after));
        });
      });

      group('setLastModified', () {
        final DateTime time = DateTime(1999);

        test('throwsIfDoesntExist', () {
          expectFileSystemException(ErrorCodes.ENOENT, () {
            fs.file(ns('/foo')).setLastModifiedSync(time);
          });
        });

        test('throwsIfExistsAsDirectory', () {
          fs.directory(ns('/foo')).createSync();
          expectFileSystemException(ErrorCodes.EISDIR, () {
            fs.file(ns('/foo')).setLastModifiedSync(time);
          });
        });

        test('succeedsIfExistsAsFile', () {
          File f = fs.file(ns('/foo'))..createSync();
          f.setLastModifiedSync(time);
          expect(fs.file(ns('/foo')).lastModifiedSync(), time);
        });

        test('succeedsIfExistsAsLinkToFile', () {
          File f = fs.file(ns('/foo'))..createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          f.setLastModifiedSync(time);
          expect(fs.file(ns('/bar')).lastModifiedSync(), time);
        });
      });

      group('open', () {
        void testIfDoesntExistAtTail(FileMode mode) {
          if (mode == FileMode.read) {
            test('throwsIfDoesntExistAtTail', () {
              expectFileSystemException(ErrorCodes.ENOENT, () {
                fs.file(ns('/bar')).openSync(mode: mode);
              });
            });
          } else {
            test('createsFileIfDoesntExistAtTail', () {
              RandomAccessFile raf = fs.file(ns('/bar')).openSync(mode: mode);
              raf.closeSync();
              expect(fs.file(ns('/bar')), exists);
            });
          }
        }

        void testThrowsIfDoesntExistViaTraversal(FileMode mode) {
          test('throwsIfDoesntExistViaTraversal', () {
            expectFileSystemException(ErrorCodes.ENOENT, () {
              fs.file(ns('/bar/baz')).openSync(mode: mode);
            });
          });
        }

        void testRandomAccessFileOperations(FileMode mode) {
          group('RandomAccessFile', () {
            late File f;
            late RandomAccessFile raf;

            setUp(() {
              f = fs.file(ns('/foo'))..createSync();
              f.writeAsStringSync('pre-existing content\n', flush: true);
              raf = f.openSync(mode: mode);
            });

            tearDown(() {
              try {
                raf.closeSync();
              } on FileSystemException {
                // Ignore; a test may have already closed it.
              }
            });

            test('succeedsIfClosedAfterClosed', () {
              raf.closeSync();
              expectFileSystemException(null, () {
                raf.closeSync();
              });
            });

            test('throwsIfReadAfterClose', () {
              raf.closeSync();
              expectFileSystemException(null, () {
                raf.readByteSync();
              });
            });

            test('throwsIfWriteAfterClose', () {
              raf.closeSync();
              expectFileSystemException(null, () {
                raf.writeByteSync(0xBAD);
              });
            });

            test('throwsIfTruncateAfterClose', () {
              raf.closeSync();
              expectFileSystemException(null, () {
                raf.truncateSync(0);
              });
            });

            if (mode == FileMode.write || mode == FileMode.writeOnly) {
              test('lengthIsResetToZeroIfOpened', () {
                expect(raf.lengthSync(), equals(0));
              });

              test('throwsIfAsyncUnawaited', () async {
                try {
                  final Future<void> future = raf.flush();
                  expectFileSystemException(null, () => raf.flush());
                  expectFileSystemException(null, () => raf.flushSync());
                  await expectLater(future, completes);
                  raf.flushSync();
                } finally {
                  raf.closeSync();
                }
              });
            } else {
              test('lengthIsNotModifiedIfOpened', () {
                expect(raf.lengthSync(), isNot(equals(0)));
              });
            }

            if (mode == FileMode.writeOnly ||
                mode == FileMode.writeOnlyAppend) {
              test('throwsIfReadByte', () {
                expectFileSystemException(ErrorCodes.EBADF, () {
                  raf.readByteSync();
                });
              });

              test('throwsIfRead', () {
                expectFileSystemException(ErrorCodes.EBADF, () {
                  raf.readSync(2);
                });
              });

              test('throwsIfReadInto', () {
                expectFileSystemException(ErrorCodes.EBADF, () {
                  raf.readIntoSync(List<int>.filled(5, 0));
                });
              });
            } else {
              group('read', () {
                setUp(() {
                  if (mode == FileMode.write) {
                    // Write data back that we truncated when opening the file.
                    raf.writeStringSync('pre-existing content\n');
                  }
                  // Reset the position to zero so we can read the content.
                  raf.setPositionSync(0);
                });

                test('readByte', () {
                  expect(utf8.decode(<int>[raf.readByteSync()]), 'p');
                });

                test('read', () {
                  List<int> bytes = raf.readSync(1024);
                  expect(bytes.length, 21);
                  expect(utf8.decode(bytes), 'pre-existing content\n');
                });

                test('readIntoWithBufferLargerThanContent', () {
                  List<int> buffer = List<int>.filled(1024, 0);
                  int numRead = raf.readIntoSync(buffer);
                  expect(numRead, 21);
                  expect(utf8.decode(buffer.sublist(0, 21)),
                      'pre-existing content\n');
                });

                test('readIntoWithBufferSmallerThanContent', () {
                  List<int> buffer = List<int>.filled(10, 0);
                  int numRead = raf.readIntoSync(buffer);
                  expect(numRead, 10);
                  expect(utf8.decode(buffer), 'pre-existi');
                });

                test('readIntoWithStart', () {
                  List<int> buffer = List<int>.filled(10, 0);
                  int numRead = raf.readIntoSync(buffer, 2);
                  expect(numRead, 8);
                  expect(utf8.decode(buffer.sublist(2)), 'pre-exis');
                });

                test('readIntoWithStartAndEnd', () {
                  List<int> buffer = List<int>.filled(10, 0);
                  int numRead = raf.readIntoSync(buffer, 2, 5);
                  expect(numRead, 3);
                  expect(utf8.decode(buffer.sublist(2, 5)), 'pre');
                });

                test('openReadHandleDoesNotChange', () {
                  final String initial = utf8.decode(raf.readSync(4));
                  expect(initial, 'pre-');
                  final File newFile = f.renameSync(ns('/bar'));
                  String rest = utf8.decode(raf.readSync(1024));
                  expect(rest, 'existing content\n');

                  assert(newFile.path != f.path);
                  expect(f, isNot(exists));
                  expect(newFile, exists);

                  // [RandomAccessFile.path] always returns the original path.
                  expect(raf.path, f.path);
                });
              });
            }

            if (mode == FileMode.read) {
              test('throwsIfWriteByte', () {
                expectFileSystemException(ErrorCodes.EBADF, () {
                  raf.writeByteSync(0xBAD);
                });
              });

              test('throwsIfWriteFrom', () {
                expectFileSystemException(ErrorCodes.EBADF, () {
                  raf.writeFromSync(<int>[1, 2, 3, 4]);
                });
              });

              test('throwsIfWriteString', () {
                expectFileSystemException(ErrorCodes.EBADF, () {
                  raf.writeStringSync('This should throw.');
                });
              });
            } else {
              test('lengthGrowsAsDataIsWritten', () {
                int lengthBefore = f.lengthSync();
                raf.writeByteSync(0xFACE);
                expect(raf.lengthSync(), lengthBefore + 1);
              });

              test('flush', () {
                int lengthBefore = f.lengthSync();
                raf.writeByteSync(0xFACE);
                raf.flushSync();
                expect(f.lengthSync(), lengthBefore + 1);
              });

              test('writeByte', () {
                raf.writeByteSync(utf8.encode('A').first);
                raf.flushSync();
                if (mode == FileMode.write || mode == FileMode.writeOnly) {
                  expect(f.readAsStringSync(), 'A');
                } else {
                  expect(f.readAsStringSync(), 'pre-existing content\nA');
                }
              });

              test('writeFrom', () {
                raf.writeFromSync(utf8.encode('Hello world'));
                raf.flushSync();
                if (mode == FileMode.write || mode == FileMode.writeOnly) {
                  expect(f.readAsStringSync(), 'Hello world');
                } else {
                  expect(f.readAsStringSync(),
                      'pre-existing content\nHello world');
                }
              });

              test('writeFromWithStart', () {
                raf.writeFromSync(utf8.encode('Hello world'), 2);
                raf.flushSync();
                if (mode == FileMode.write || mode == FileMode.writeOnly) {
                  expect(f.readAsStringSync(), 'llo world');
                } else {
                  expect(
                      f.readAsStringSync(), 'pre-existing content\nllo world');
                }
              });

              test('writeFromWithStartAndEnd', () {
                raf.writeFromSync(utf8.encode('Hello world'), 2, 5);
                raf.flushSync();
                if (mode == FileMode.write || mode == FileMode.writeOnly) {
                  expect(f.readAsStringSync(), 'llo');
                } else {
                  expect(f.readAsStringSync(), 'pre-existing content\nllo');
                }
              });

              test('writeString', () {
                raf.writeStringSync('Hello world');
                raf.flushSync();
                if (mode == FileMode.write || mode == FileMode.writeOnly) {
                  expect(f.readAsStringSync(), 'Hello world');
                } else {
                  expect(f.readAsStringSync(),
                      'pre-existing content\nHello world');
                }
              });

              test('openWriteHandleDoesNotChange', () {
                raf.writeStringSync('Hello ');
                final File newFile = f.renameSync(ns('/bar'));
                raf.writeStringSync('world');

                final String contents = newFile.readAsStringSync();
                if (mode == FileMode.write || mode == FileMode.writeOnly) {
                  expect(contents, 'Hello world');
                } else {
                  expect(contents, 'pre-existing content\nHello world');
                }

                assert(newFile.path != f.path);
                expect(f, isNot(exists));
                expect(newFile, exists);

                // [RandomAccessFile.path] always returns the original path.
                expect(raf.path, f.path);
              });
            }

            if (mode == FileMode.append || mode == FileMode.writeOnlyAppend) {
              test('positionInitializedToEndOfFile', () {
                expect(raf.positionSync(), 21);
              });
            } else {
              test('positionInitializedToZero', () {
                expect(raf.positionSync(), 0);
              });
            }

            group('position', () {
              setUp(() {
                if (mode == FileMode.write || mode == FileMode.writeOnly) {
                  // Write data back that we truncated when opening the file.
                  raf.writeStringSync('pre-existing content\n');
                }
              });

              if (mode != FileMode.writeOnly &&
                  mode != FileMode.writeOnlyAppend) {
                test('growsAfterRead', () {
                  raf.setPositionSync(0);
                  raf.readSync(10);
                  expect(raf.positionSync(), 10);
                });

                test('affectsRead', () {
                  raf.setPositionSync(5);
                  expect(utf8.decode(raf.readSync(5)), 'xisti');
                });
              }

              if (mode == FileMode.read) {
                test('succeedsIfSetPastEndOfFile', () {
                  raf.setPositionSync(32);
                  expect(raf.positionSync(), 32);
                });
              } else {
                test('growsAfterWrite', () {
                  int positionBefore = raf.positionSync();
                  raf.writeStringSync('Hello world');
                  expect(raf.positionSync(), positionBefore + 11);
                });

                test('affectsWrite', () {
                  raf.setPositionSync(5);
                  raf.writeStringSync('-yo-');
                  raf.flushSync();
                  expect(f.readAsStringSync(), 'pre-e-yo-ing content\n');
                });

                test('succeedsIfSetAndWrittenPastEndOfFile', () {
                  raf.setPositionSync(32);
                  expect(raf.positionSync(), 32);
                  raf.writeStringSync('here');
                  raf.flushSync();
                  List<int> bytes = f.readAsBytesSync();
                  expect(bytes.length, 36);
                  expect(utf8.decode(bytes.sublist(0, 21)),
                      'pre-existing content\n');
                  expect(utf8.decode(bytes.sublist(32, 36)), 'here');
                  expect(bytes.sublist(21, 32), everyElement(0));
                });
              }

              test('throwsIfSetToNegativeNumber', () {
                expectFileSystemException(ErrorCodes.EINVAL, () {
                  raf.setPositionSync(-12);
                });
              });
            });

            if (mode == FileMode.read) {
              test('throwsIfTruncate', () {
                expectFileSystemException(ErrorCodes.EINVAL, () {
                  raf.truncateSync(5);
                });
              });
            } else {
              group('truncate', () {
                setUp(() {
                  if (mode == FileMode.write || mode == FileMode.writeOnly) {
                    // Write data back that we truncated when opening the file.
                    raf.writeStringSync('pre-existing content\n');
                  }
                });

                test('succeedsIfSetWithinRangeOfContent', () {
                  raf.truncateSync(5);
                  raf.flushSync();
                  expect(f.lengthSync(), 5);
                  expect(f.readAsStringSync(), 'pre-e');
                });

                test('succeedsIfSetToZero', () {
                  raf.truncateSync(0);
                  raf.flushSync();
                  expect(f.lengthSync(), 0);
                  expect(f.readAsStringSync(), isEmpty);
                });

                test('throwsIfSetToNegativeNumber', () {
                  expectFileSystemException(ErrorCodes.EINVAL, () {
                    raf.truncateSync(-2);
                  });
                });

                test('extendsFileIfSetPastEndOfFile', () {
                  raf.truncateSync(32);
                  raf.flushSync();
                  List<int> bytes = f.readAsBytesSync();
                  expect(bytes.length, 32);
                  expect(utf8.decode(bytes.sublist(0, 21)),
                      'pre-existing content\n');
                  expect(bytes.sublist(21, 32), everyElement(0));
                });
              });
            }
          });
        }

        void testOpenWithMode(FileMode mode) {
          testIfDoesntExistAtTail(mode);
          testThrowsIfDoesntExistViaTraversal(mode);
          testRandomAccessFileOperations(mode);
        }

        group('READ', () => testOpenWithMode(FileMode.read));
        group('WRITE', () => testOpenWithMode(FileMode.write));
        group('APPEND', () => testOpenWithMode(FileMode.append));
        group('WRITE_ONLY', () => testOpenWithMode(FileMode.writeOnly));
        group('WRITE_ONLY_APPEND',
            () => testOpenWithMode(FileMode.writeOnlyAppend));
      });

      group('openRead', () {
        test('throwsIfDoesntExist', () {
          Stream<List<int>> stream = fs.file(ns('/foo')).openRead();
          expect(stream.drain<void>(),
              throwsFileSystemException(ErrorCodes.ENOENT));
        });

        test('succeedsIfExistsAsFile', () async {
          File f = fs.file(ns('/foo'))..createSync();
          f.writeAsStringSync('Hello world', flush: true);
          Stream<List<int>> stream = f.openRead();
          List<List<int>> data = await stream.toList();
          expect(data, hasLength(1));
          expect(utf8.decode(data[0]), 'Hello world');
        });

        test('throwsIfExistsAsDirectory', () {
          fs.directory(ns('/foo')).createSync();
          Stream<List<int>> stream = fs.file(ns('/foo')).openRead();
          expect(stream.drain<void>(),
              throwsFileSystemException(ErrorCodes.EISDIR));
        });

        test('succeedsIfExistsAsLinkToFile', () async {
          File f = fs.file(ns('/foo'))..createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          f.writeAsStringSync('Hello world', flush: true);
          Stream<List<int>> stream = fs.file(ns('/bar')).openRead();
          List<List<int>> data = await stream.toList();
          expect(data, hasLength(1));
          expect(utf8.decode(data[0]), 'Hello world');
        });

        test('respectsStartAndEndParameters', () async {
          File f = fs.file(ns('/foo'))..createSync();
          f.writeAsStringSync('Hello world', flush: true);
          Stream<List<int>> stream = f.openRead(2);
          List<List<int>> data = await stream.toList();
          expect(data, hasLength(1));
          expect(utf8.decode(data[0]), 'llo world');
          stream = f.openRead(2, 5);
          data = await stream.toList();
          expect(data, hasLength(1));
          expect(utf8.decode(data[0]), 'llo');
        });

        test('throwsIfStartParameterIsNegative', () async {
          File f = fs.file(ns('/foo'))..createSync();
          Stream<List<int>> stream = f.openRead(-2);
          expect(stream.drain<void>(), throwsRangeError);
        });

        test('stopsAtEndOfFileIfEndParameterIsPastEndOfFile', () async {
          File f = fs.file(ns('/foo'))..createSync();
          f.writeAsStringSync('Hello world', flush: true);
          Stream<List<int>> stream = f.openRead(2, 1024);
          List<List<int>> data = await stream.toList();
          expect(data, hasLength(1));
          expect(utf8.decode(data[0]), 'llo world');
        });

        test('providesSingleSubscriptionStream', () async {
          File f = fs.file(ns('/foo'))..createSync();
          f.writeAsStringSync('Hello world', flush: true);
          Stream<List<int>> stream = f.openRead();
          expect(stream.isBroadcast, isFalse);
          await stream.drain<void>();
        });

        test('openReadHandleDoesNotChange', () async {
          // Ideally, `data` should be large enough so that its contents are
          // split across multiple chunks in the [Stream].  However, there
          // doesn't seem to be a good way to determine the chunk size used by
          // [io.File].
          final List<int> data = List<int>.generate(
            1024 * 256,
            (int index) => index & 0xFF,
            growable: false,
          );

          final File f = fs.file(ns('/foo'))..createSync();

          f.writeAsBytesSync(data, flush: true);
          final Stream<List<int>> stream = f.openRead();

          File? newFile;
          List<int>? initialChunk;
          final List<int> remainingChunks = <int>[];

          await for (List<int> chunk in stream) {
            if (initialChunk == null) {
              initialChunk = chunk;
              assert(initialChunk.isNotEmpty);
              expect(initialChunk, data.getRange(0, initialChunk.length));

              newFile = f.renameSync(ns('/bar'));
            } else {
              remainingChunks.addAll(chunk);
            }
          }

          expect(
            remainingChunks,
            data.getRange(initialChunk!.length, data.length),
          );

          assert(newFile?.path != f.path);
          expect(f, isNot(exists));
          expect(newFile, exists);
        });
      });

      group('openWrite', () {
        test('createsFileIfDoesntExist', () async {
          await fs.file(ns('/foo')).openWrite().close();
          expect(fs.file(ns('/foo')), exists);
        });

        test('throwsIfExistsAsDirectory', () {
          fs.directory(ns('/foo')).createSync();
          expect(fs.file(ns('/foo')).openWrite().close(),
              throwsFileSystemException(ErrorCodes.EISDIR));
        });

        test('throwsIfExistsAsLinkToDirectory', () {
          fs.directory(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          expect(fs.file(ns('/bar')).openWrite().close(),
              throwsFileSystemException(ErrorCodes.EISDIR));
        });

        test('throwsIfModeIsRead', () {
          expect(() => fs.file(ns('/foo')).openWrite(mode: FileMode.read),
              throwsArgumentError);
        });

        test('succeedsIfExistsAsEmptyFile', () async {
          File f = fs.file(ns('/foo'))..createSync();
          IOSink sink = f.openWrite();
          sink.write('Hello world');
          await sink.flush();
          await sink.close();
          expect(f.readAsStringSync(), 'Hello world');
        });

        test('succeedsIfExistsAsLinkToFile', () async {
          fs.file(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          IOSink sink = fs.file(ns('/bar')).openWrite();
          sink.write('Hello world');
          await sink.flush();
          await sink.close();
          expect(fs.file(ns('/foo')).readAsStringSync(), 'Hello world');
        });

        test('overwritesContentInWriteMode', () async {
          File f = fs.file(ns('/foo'))..createSync();
          f.writeAsStringSync('Hello');
          IOSink sink = f.openWrite();
          sink.write('Goodbye');
          await sink.flush();
          await sink.close();
          expect(fs.file(ns('/foo')).readAsStringSync(), 'Goodbye');
        });

        test('appendsContentInAppendMode', () async {
          File f = fs.file(ns('/foo'))..createSync();
          f.writeAsStringSync('Hello');
          IOSink sink = f.openWrite(mode: FileMode.append);
          sink.write('Goodbye');
          await sink.flush();
          await sink.close();
          expect(fs.file(ns('/foo')).readAsStringSync(), 'HelloGoodbye');
        });

        test('openWriteHandleDoesNotChange', () async {
          File f = fs.file(ns('/foo'))..createSync();
          IOSink sink = f.openWrite();
          sink.write('Hello');
          await sink.flush();

          final File newFile = f.renameSync(ns('/bar'));
          sink.write('Goodbye');
          await sink.flush();
          await sink.close();

          expect(newFile.readAsStringSync(), 'HelloGoodbye');

          assert(newFile.path != f.path);
          expect(f, isNot(exists));
          expect(newFile, exists);
        });

        group('ioSink', () {
          late File f;
          late IOSink sink;
          late bool isSinkClosed;

          Future<dynamic> closeSink() {
            Future<dynamic> future = sink.close();
            isSinkClosed = true;
            return future;
          }

          setUp(() {
            f = fs.file(ns('/foo'));
            sink = f.openWrite();
            isSinkClosed = false;
          });

          tearDown(() async {
            if (!isSinkClosed) {
              await closeSink();
            }
          });

          test('throwsIfAddError', () async {
            sink.addError(ArgumentError());
            expect(sink.done, throwsArgumentError);
            isSinkClosed = true;
          });

          test('allowsChangingEncoding', () async {
            sink.encoding = latin1;
            sink.write('ÿ');
            sink.encoding = utf8;
            sink.write('ÿ');
            await sink.flush();
            expect(await f.readAsBytes(), <int>[255, 195, 191]);
          });

          test('succeedsIfAddRawData', () async {
            sink.add(<int>[1, 2, 3, 4]);
            await sink.flush();
            expect(await f.readAsBytes(), <int>[1, 2, 3, 4]);
          });

          test('succeedsIfWrite', () async {
            sink.write('Hello world');
            await sink.flush();
            expect(await f.readAsString(), 'Hello world');
          });

          test('succeedsIfWriteAll', () async {
            sink.writeAll(<String>['foo', 'bar', 'baz'], ' ');
            await sink.flush();
            expect(await f.readAsString(), 'foo bar baz');
          });

          test('succeedsIfWriteCharCode', () async {
            sink.writeCharCode(35);
            await sink.flush();
            expect(await f.readAsString(), '#');
          });

          test('succeedsIfWriteln', () async {
            sink.writeln('Hello world');
            await sink.flush();
            expect(await f.readAsString(), 'Hello world\n');
          });

          test('ignoresDataWrittenAfterClose', () async {
            sink.write('Before close');
            await closeSink();
            expect(() => sink.write('After close'), throwsStateError);
            expect(await f.readAsString(), 'Before close');
          });

          test('ignoresCloseAfterAlreadyClosed', () async {
            sink.write('Hello world');
            Future<dynamic> f1 = closeSink();
            Future<dynamic> f2 = closeSink();
            await Future.wait<dynamic>(<Future<dynamic>>[f1, f2]);
          });

          test('returnsAccurateDoneFuture', () async {
            bool done = false;
            // ignore: unawaited_futures
            sink.done.then((dynamic _) => done = true);
            expect(done, isFalse);
            sink.write('foo');
            expect(done, isFalse);
            await sink.close();
            expect(done, isTrue);
          });

          group('addStream', () {
            late StreamController<List<int>> controller;
            late bool isControllerClosed;

            Future<dynamic> closeController() {
              Future<dynamic> future = controller.close();
              isControllerClosed = true;
              return future;
            }

            setUp(() {
              controller = StreamController<List<int>>();
              isControllerClosed = false;
              sink.addStream(controller.stream);
            });

            tearDown(() async {
              if (!isControllerClosed) {
                await closeController();
              }
            });

            test('succeedsIfStreamProducesData', () async {
              controller.add(<int>[1, 2, 3, 4, 5]);
              await closeController();
              await sink.flush();
              expect(await f.readAsBytes(), <int>[1, 2, 3, 4, 5]);
            });

            test('blocksCallToAddWhileStreamIsActive', () {
              expect(() => sink.add(<int>[1, 2, 3]), throwsStateError);
            });

            test('blocksCallToWriteWhileStreamIsActive', () {
              expect(() => sink.write('foo'), throwsStateError);
            });

            test('blocksCallToWriteAllWhileStreamIsActive', () {
              expect(() => sink.writeAll(<String>['a', 'b']), throwsStateError);
            });

            test('blocksCallToWriteCharCodeWhileStreamIsActive', () {
              expect(() => sink.writeCharCode(35), throwsStateError);
            });

            test('blocksCallToWritelnWhileStreamIsActive', () {
              expect(() => sink.writeln('foo'), throwsStateError);
            });

            test('blocksCallToFlushWhileStreamIsActive', () {
              expect(() => sink.flush(), throwsStateError);
            });
          });
        });
      });

      group('readAsBytes', () {
        test('throwsIfDoesntExist', () {
          expectFileSystemException(ErrorCodes.ENOENT, () {
            fs.file(ns('/foo')).readAsBytesSync();
          });
        });

        test('throwsIfExistsAsDirectory', () {
          fs.directory(ns('/foo')).createSync();
          expectFileSystemException(ErrorCodes.EISDIR, () {
            fs.file(ns('/foo')).readAsBytesSync();
          });
        });

        test('throwsIfExistsAsLinkToDirectory', () {
          fs.directory(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          expectFileSystemException(ErrorCodes.EISDIR, () {
            fs.file(ns('/bar')).readAsBytesSync();
          });
        });

        test('succeedsIfExistsAsFile', () {
          File f = fs.file(ns('/foo'))..createSync();
          f.writeAsBytesSync(<int>[1, 2, 3, 4]);
          expect(f.readAsBytesSync(), <int>[1, 2, 3, 4]);
        });

        test('succeedsIfExistsAsLinkToFile', () {
          fs.file(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          fs.file(ns('/foo')).writeAsBytesSync(<int>[1, 2, 3, 4]);
          expect(fs.file(ns('/bar')).readAsBytesSync(), <int>[1, 2, 3, 4]);
        });

        test('returnsEmptyListForZeroByteFile', () {
          File f = fs.file(ns('/foo'))..createSync();
          expect(f.readAsBytesSync(), isEmpty);
        });

        test('returns a copy, not a view, of the file content', () {
          File f = fs.file(ns('/foo'))..createSync();
          f.writeAsBytesSync(<int>[1, 2, 3, 4]);
          List<int> result = f.readAsBytesSync();
          expect(result, <int>[1, 2, 3, 4]);
          result[0] = 10;
          expect(f.readAsBytesSync(), <int>[1, 2, 3, 4]);
        });
      });

      group('readAsString', () {
        test('throwsIfDoesntExist', () {
          expectFileSystemException(ErrorCodes.ENOENT, () {
            fs.file(ns('/foo')).readAsStringSync();
          });
        });

        test('throwsIfExistsAsDirectory', () {
          fs.directory(ns('/foo')).createSync();
          expectFileSystemException(ErrorCodes.EISDIR, () {
            fs.file(ns('/foo')).readAsStringSync();
          });
        });

        test('throwsIfExistsAsLinkToDirectory', () {
          fs.directory(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          expectFileSystemException(ErrorCodes.EISDIR, () {
            fs.file(ns('/bar')).readAsStringSync();
          });
        });

        test('succeedsIfExistsAsFile', () {
          File f = fs.file(ns('/foo'))..createSync();
          f.writeAsStringSync('Hello world');
          expect(f.readAsStringSync(), 'Hello world');
        });

        test('succeedsIfExistsAsLinkToFile', () {
          fs.file(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          fs.file(ns('/foo')).writeAsStringSync('Hello world');
          expect(fs.file(ns('/bar')).readAsStringSync(), 'Hello world');
        });

        test('returnsEmptyStringForZeroByteFile', () {
          File f = fs.file(ns('/foo'))..createSync();
          expect(f.readAsStringSync(), isEmpty);
        });
      });

      group('readAsLines', () {
        const String testString = 'Hello world\nHow are you?\nI am fine';
        final List<String> expectedLines = <String>[
          'Hello world',
          'How are you?',
          'I am fine',
        ];

        test('throwsIfDoesntExist', () {
          expectFileSystemException(ErrorCodes.ENOENT, () {
            fs.file(ns('/foo')).readAsLinesSync();
          });
        });

        test('throwsIfExistsAsDirectory', () {
          fs.directory(ns('/foo')).createSync();
          expectFileSystemException(ErrorCodes.EISDIR, () {
            fs.file(ns('/foo')).readAsLinesSync();
          });
        });

        test('throwsIfExistsAsLinkToDirectory', () {
          fs.directory(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          expectFileSystemException(ErrorCodes.EISDIR, () {
            fs.file(ns('/bar')).readAsLinesSync();
          });
        });

        test('succeedsIfExistsAsFile', () {
          File f = fs.file(ns('/foo'))..createSync();
          f.writeAsStringSync(testString);
          expect(f.readAsLinesSync(), expectedLines);
        });

        test('succeedsIfExistsAsLinkToFile', () {
          File f = fs.file(ns('/foo'))..createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          f.writeAsStringSync(testString);
          expect(f.readAsLinesSync(), expectedLines);
        });

        test('returnsEmptyListForZeroByteFile', () {
          File f = fs.file(ns('/foo'))..createSync();
          expect(f.readAsLinesSync(), isEmpty);
        });

        test('isTrailingNewlineAgnostic', () {
          File f = fs.file(ns('/foo'))..createSync();
          f.writeAsStringSync(testString + '\n');
          expect(f.readAsLinesSync(), expectedLines);

          f.writeAsStringSync('\n');
          expect(f.readAsLinesSync(), <String>['']);

          f.writeAsStringSync('\n\n');
          expect(f.readAsLinesSync(), <String>['', '']);
        });
      });

      group('writeAsBytes', () {
        test('returnsCovariantType', () async {
          expect(await fs.file(ns('/foo')).writeAsBytes(<int>[]), isFile);
        });

        test('createsFileIfDoesntExist', () {
          File f = fs.file(ns('/foo'));
          expect(f, isNot(exists));
          f.writeAsBytesSync(<int>[1, 2, 3, 4]);
          expect(f, exists);
        });

        test('throwsIfExistsAsDirectory', () {
          fs.directory(ns('/foo')).createSync();
          expectFileSystemException(ErrorCodes.EISDIR, () {
            fs.file(ns('/foo')).writeAsBytesSync(<int>[1, 2, 3, 4]);
          });
        });

        test('throwsIfExistsAsLinkToDirectory', () {
          fs.directory(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          expectFileSystemException(ErrorCodes.EISDIR, () {
            fs.file(ns('/foo')).writeAsBytesSync(<int>[1, 2, 3, 4]);
          });
        });

        test('succeedsIfExistsAsLinkToFile', () {
          File f = fs.file(ns('/foo'))..createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          fs.file(ns('/bar')).writeAsBytesSync(<int>[1, 2, 3, 4]);
          expect(f.readAsBytesSync(), <int>[1, 2, 3, 4]);
        });

        test('throwsIfFileModeRead', () {
          File f = fs.file(ns('/foo'))..createSync();
          expectFileSystemException(ErrorCodes.EBADF, () {
            f.writeAsBytesSync(<int>[1], mode: FileMode.read);
          });
        });

        test('overwritesContentIfFileModeWrite', () {
          File f = fs.file(ns('/foo'))..createSync();
          f.writeAsBytesSync(<int>[1, 2]);
          expect(f.readAsBytesSync(), <int>[1, 2]);
          f.writeAsBytesSync(<int>[3, 4]);
          expect(f.readAsBytesSync(), <int>[3, 4]);
        });

        test('appendsContentIfFileModeAppend', () {
          File f = fs.file(ns('/foo'))..createSync();
          f.writeAsBytesSync(<int>[1, 2], mode: FileMode.append);
          expect(f.readAsBytesSync(), <int>[1, 2]);
          f.writeAsBytesSync(<int>[3, 4], mode: FileMode.append);
          expect(f.readAsBytesSync(), <int>[1, 2, 3, 4]);
        });

        test('acceptsEmptyBytesList', () {
          File f = fs.file(ns('/foo'))..createSync();
          f.writeAsBytesSync(<int>[]);
          expect(f.readAsBytesSync(), <int>[]);
        });

        test('updatesLastModifiedTime', () async {
          File f = fs.file(ns('/foo'))..createSync();
          DateTime before = f.statSync().modified;
          await Future<void>.delayed(const Duration(seconds: 2));
          f.writeAsBytesSync(<int>[1, 2, 3]);
          DateTime after = f.statSync().modified;
          expect(after, isAfter(before));
        });
      });

      group('writeAsString', () {
        test('returnsCovariantType', () async {
          expect(await fs.file(ns('/foo')).writeAsString('foo'), isFile);
        });

        test('createsFileIfDoesntExist', () {
          File f = fs.file(ns('/foo'));
          expect(f, isNot(exists));
          f.writeAsStringSync('Hello world');
          expect(f, exists);
        });

        test('throwsIfExistsAsDirectory', () {
          fs.directory(ns('/foo')).createSync();
          expectFileSystemException(ErrorCodes.EISDIR, () {
            fs.file(ns('/foo')).writeAsStringSync('Hello world');
          });
        });

        test('throwsIfExistsAsLinkToDirectory', () {
          fs.directory(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          expectFileSystemException(ErrorCodes.EISDIR, () {
            fs.file(ns('/foo')).writeAsStringSync('Hello world');
          });
        });

        test('succeedsIfExistsAsLinkToFile', () {
          File f = fs.file(ns('/foo'))..createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          fs.file(ns('/bar')).writeAsStringSync('Hello world');
          expect(f.readAsStringSync(), 'Hello world');
        });

        test('throwsIfFileModeRead', () {
          File f = fs.file(ns('/foo'))..createSync();
          expectFileSystemException(ErrorCodes.EBADF, () {
            f.writeAsStringSync('Hello world', mode: FileMode.read);
          });
        });

        test('overwritesContentIfFileModeWrite', () {
          File f = fs.file(ns('/foo'))..createSync();
          f.writeAsStringSync('Hello world');
          expect(f.readAsStringSync(), 'Hello world');
          f.writeAsStringSync('Goodbye cruel world');
          expect(f.readAsStringSync(), 'Goodbye cruel world');
        });

        test('appendsContentIfFileModeAppend', () {
          File f = fs.file(ns('/foo'))..createSync();
          f.writeAsStringSync('Hello', mode: FileMode.append);
          expect(f.readAsStringSync(), 'Hello');
          f.writeAsStringSync('Goodbye', mode: FileMode.append);
          expect(f.readAsStringSync(), 'HelloGoodbye');
        });

        test('acceptsEmptyString', () {
          File f = fs.file(ns('/foo'))..createSync();
          f.writeAsStringSync('');
          expect(f.readAsStringSync(), isEmpty);
        });
      });

      group('exists', () {
        test('trueIfExists', () {
          fs.file(ns('/foo')).createSync();
          expect(fs.file(ns('/foo')), exists);
        });

        test('falseIfDoesntExistAtTail', () {
          expect(fs.file(ns('/foo')), isNot(exists));
        });

        test('falseIfDoesntExistViaTraversal', () {
          expect(fs.file(ns('/foo/bar')), isNot(exists));
        });

        test('falseIfExistsAsDirectory', () {
          fs.directory(ns('/foo')).createSync();
          expect(fs.file(ns('/foo')), isNot(exists));
        });

        test('falseIfExistsAsLinkToDirectory', () {
          fs.directory(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          expect(fs.file(ns('/bar')), isNot(exists));
        });

        test('trueIfExistsAsLinkToFile', () {
          fs.file(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          expect(fs.file(ns('/bar')), exists);
        });

        test('falseIfNotFoundSegmentExistsThenIsBackedOut', () {
          fs.file(ns('/foo/bar')).createSync(recursive: true);
          expect(fs.directory(ns('/baz/../foo/bar')), isNot(exists));
        });
      });

      group('stat', () {
        test('isNotFoundIfDoesntExistAtTail', () {
          FileStat stat = fs.file(ns('/foo')).statSync();
          expect(stat.type, FileSystemEntityType.notFound);
        });

        test('isNotFoundIfDoesntExistViaTraversal', () {
          FileStat stat = fs.file(ns('/foo/bar')).statSync();
          expect(stat.type, FileSystemEntityType.notFound);
        });

        test('isDirectoryIfExistsAsDirectory', () {
          fs.directory(ns('/foo')).createSync();
          FileStat stat = fs.file(ns('/foo')).statSync();
          expect(stat.type, FileSystemEntityType.directory);
        });

        test('isFileIfExistsAsFile', () {
          fs.file(ns('/foo')).createSync();
          FileStat stat = fs.file(ns('/foo')).statSync();
          expect(stat.type, FileSystemEntityType.file);
        });

        test('isFileIfExistsAsLinkToFile', () {
          fs.file(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          FileStat stat = fs.file(ns('/bar')).statSync();
          expect(stat.type, FileSystemEntityType.file);
        });
      });

      group('delete', () {
        test('returnsCovariantType', () async {
          File f = fs.file(ns('/foo'))..createSync();
          expect(await f.delete(), isFile);
        });

        test('succeedsIfExistsAsFile', () {
          fs.file(ns('/foo')).createSync();
          expect(fs.file(ns('/foo')), exists);
          fs.file(ns('/foo')).deleteSync();
          expect(fs.file(ns('/foo')), isNot(exists));
        });

        test('throwsIfDoesntExistAndRecursiveFalse', () {
          expectFileSystemException(ErrorCodes.ENOENT, () {
            fs.file(ns('/foo')).deleteSync();
          });
        });

        test('throwsIfDoesntExistAndRecursiveTrue', () {
          expectFileSystemException(ErrorCodes.ENOENT, () {
            fs.file(ns('/foo')).deleteSync(recursive: true);
          });
        });

        test('succeedsIfExistsAsDirectoryAndRecursiveTrue', () {
          fs.directory(ns('/foo')).createSync();
          fs.file(ns('/foo')).deleteSync(recursive: true);
          expect(fs.typeSync(ns('/foo')), FileSystemEntityType.notFound);
        });

        test('throwsIfExistsAsDirectoryAndRecursiveFalse', () {
          fs.directory(ns('/foo')).createSync();
          expectFileSystemException(ErrorCodes.EISDIR, () {
            fs.file(ns('/foo')).deleteSync();
          });
        });

        test('succeedsIfExistsAsLinkToFileAndRecursiveTrue', () {
          fs.file(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          expect(fs.file(ns('/bar')), exists);
          fs.file(ns('/bar')).deleteSync(recursive: true);
          expect(fs.file(ns('/bar')), isNot(exists));
        });

        test('succeedsIfExistsAsLinkToFileAndRecursiveFalse', () {
          fs.file(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          expect(fs.file(ns('/bar')), exists);
          fs.file(ns('/bar')).deleteSync();
          expect(fs.file(ns('/bar')), isNot(exists));
        });

        test('succeedsIfExistsAsLinkToDirectoryAndRecursiveTrue', () {
          fs.directory(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          expect(fs.typeSync(ns('/bar')), FileSystemEntityType.directory);
          fs.file(ns('/bar')).deleteSync(recursive: true);
          expect(fs.typeSync(ns('/foo')), FileSystemEntityType.directory);
          expect(fs.typeSync(ns('/bar')), FileSystemEntityType.notFound);
        });

        test('throwsIfExistsAsLinkToDirectoryAndRecursiveFalse', () {
          fs.directory(ns('/foo')).createSync();
          fs.link(ns('/bar')).createSync(ns('/foo'));
          expectFileSystemException(ErrorCodes.EISDIR, () {
            fs.file(ns('/bar')).deleteSync();
          });
        });
      });
    });

    group('Link', () {
      group('uri', () {
        test('whenTargetIsDirectory', () {
          fs.directory(ns('/foo')).createSync();
          Link l = fs.link(ns('/bar'))..createSync(ns('/foo'));
          expect(l.uri, fs.path.toUri(ns('/bar')));
          expect(fs.link('bar').uri.toString(), 'bar');
        });

        test('whenTargetIsFile', () {
          fs.file(ns('/foo')).createSync();
          Link l = fs.link(ns('/bar'))..createSync(ns('/foo'));
          expect(l.uri, fs.path.toUri(ns('/bar')));
          expect(fs.link('bar').uri.toString(), 'bar');
        });

        test('whenLinkDoesntExist', () {
          expect(fs.link(ns('/foo')).uri, fs.path.toUri(ns('/foo')));
          expect(fs.link('foo').uri.toString(), 'foo');
        });
      });

      group('exists', () {
        test('isFalseIfLinkDoesntExistAtTail', () {
          expect(fs.link(ns('/foo')), isNot(exists));
        });

        test('isFalseIfLinkDoesntExistViaTraversal', () {
          expect(fs.link(ns('/foo/bar')), isNot(exists));
        });

        test('isFalseIfPathReferencesFile', () {
          fs.file(ns('/foo')).createSync();
          expect(fs.link(ns('/foo')), isNot(exists));
        });

        test('isFalseIfPathReferencesDirectory', () {
          fs.directory(ns('/foo')).createSync();
          expect(fs.link(ns('/foo')), isNot(exists));
        });

        test('isTrueIfTargetIsNotFound', () {
          Link l = fs.link(ns('/foo'))..createSync(ns('/bar'));
          expect(l, exists);
        });

        test('isTrueIfTargetIsFile', () {
          Link l = fs.link(ns('/foo'))..createSync(ns('/bar'));
          fs.file(ns('/bar')).createSync();
          expect(l, exists);
        });

        test('isTrueIfTargetIsDirectory', () {
          Link l = fs.link(ns('/foo'))..createSync(ns('/bar'));
          fs.directory(ns('/bar')).createSync();
          expect(l, exists);
        });

        test('isTrueIfTargetIsLinkLoop', () {
          Link l = fs.link(ns('/foo'))..createSync(ns('/bar'));
          fs.link(ns('/bar')).createSync(ns('/foo'));
          expect(l, exists);
        });
      });

      group('stat', () {
        test('isNotFoundIfLinkDoesntExistAtTail', () {
          expect(fs.link(ns('/foo')).statSync().type,
              FileSystemEntityType.notFound);
        });

        test('isNotFoundIfLinkDoesntExistViaTraversal', () {
          expect(fs.link(ns('/foo/bar')).statSync().type,
              FileSystemEntityType.notFound);
        });

        test('isFileIfPathReferencesFile', () {
          fs.file(ns('/foo')).createSync();
          expect(
              fs.link(ns('/foo')).statSync().type, FileSystemEntityType.file);
        });

        test('isDirectoryIfPathReferencesDirectory', () {
          fs.directory(ns('/foo')).createSync();
          expect(fs.link(ns('/foo')).statSync().type,
              FileSystemEntityType.directory);
        });

        test('isNotFoundIfTargetNotFoundAtTail', () {
          Link l = fs.link(ns('/foo'))..createSync(ns('/bar'));
          expect(l.statSync().type, FileSystemEntityType.notFound);
        });

        test('isNotFoundIfTargetNotFoundViaTraversal', () {
          Link l = fs.link(ns('/foo'))..createSync(ns('/bar/baz'));
          expect(l.statSync().type, FileSystemEntityType.notFound);
        });

        test('isNotFoundIfTargetIsLinkLoop', () {
          Link l = fs.link(ns('/foo'))..createSync(ns('/bar'));
          fs.link(ns('/bar')).createSync(ns('/foo'));
          expect(l.statSync().type, FileSystemEntityType.notFound);
        });

        test('isFileIfTargetIsFile', () {
          Link l = fs.link(ns('/foo'))..createSync(ns('/bar'));
          fs.file(ns('/bar')).createSync();
          expect(l.statSync().type, FileSystemEntityType.file);
        });

        test('isDirectoryIfTargetIsDirectory', () {
          Link l = fs.link(ns('/foo'))..createSync(ns('/bar'));
          fs.directory(ns('/bar')).createSync();
          expect(l.statSync().type, FileSystemEntityType.directory);
        });
      });

      group('delete', () {
        test('returnsCovariantType', () async {
          Link link = fs.link(ns('/foo'))..createSync(ns('/bar'));
          expect(await link.delete(), isLink);
        });

        test('throwsIfLinkDoesntExistAtTail', () {
          expectFileSystemException(ErrorCodes.ENOENT, () {
            fs.link(ns('/foo')).deleteSync();
          });
        });

        test('throwsIfLinkDoesntExistViaTraversal', () {
          expectFileSystemException(ErrorCodes.ENOENT, () {
            fs.link(ns('/foo/bar')).deleteSync();
          });
        });

        test('throwsIfPathReferencesFileAndRecursiveFalse', () {
          fs.file(ns('/foo')).createSync();
          expectFileSystemException(ErrorCodes.EINVAL, () {
            fs.link(ns('/foo')).deleteSync();
          });
        });

        test('succeedsIfPathReferencesFileAndRecursiveTrue', () {
          fs.file(ns('/foo')).createSync();
          fs.link(ns('/foo')).deleteSync(recursive: true);
          expect(fs.typeSync(ns('/foo'), followLinks: false),
              FileSystemEntityType.notFound);
        });

        test('throwsIfPathReferencesDirectoryAndRecursiveFalse', () {
          fs.directory(ns('/foo')).createSync();
          // TODO(tvolkert): Change this to just be 'Is a directory'
          // once Dart 1.22 is stable.
          expectFileSystemException(
            anyOf(ErrorCodes.EINVAL, ErrorCodes.EISDIR),
            () {
              fs.link(ns('/foo')).deleteSync();
            },
          );
        });

        test('succeedsIfPathReferencesDirectoryAndRecursiveTrue', () {
          fs.directory(ns('/foo')).createSync();
          fs.link(ns('/foo')).deleteSync(recursive: true);
          expect(fs.typeSync(ns('/foo'), followLinks: false),
              FileSystemEntityType.notFound);
        });

        test('unlinksIfTargetIsFileAndRecursiveFalse', () {
          Link l = fs.link(ns('/foo'))..createSync(ns('/bar'));
          fs.file(ns('/bar')).createSync();
          l.deleteSync();
          expect(fs.typeSync(ns('/foo'), followLinks: false),
              FileSystemEntityType.notFound);
          expect(fs.typeSync(ns('/bar'), followLinks: false),
              FileSystemEntityType.file);
        });

        test('unlinksIfTargetIsFileAndRecursiveTrue', () {
          Link l = fs.link(ns('/foo'))..createSync(ns('/bar'));
          fs.file(ns('/bar')).createSync();
          l.deleteSync(recursive: true);
          expect(fs.typeSync(ns('/foo'), followLinks: false),
              FileSystemEntityType.notFound);
          expect(fs.typeSync(ns('/bar'), followLinks: false),
              FileSystemEntityType.file);
        });

        test('unlinksIfTargetIsDirectoryAndRecursiveFalse', () {
          Link l = fs.link(ns('/foo'))..createSync(ns('/bar'));
          fs.directory(ns('/bar')).createSync();
          l.deleteSync();
          expect(fs.typeSync(ns('/foo'), followLinks: false),
              FileSystemEntityType.notFound);
          expect(fs.typeSync(ns('/bar'), followLinks: false),
              FileSystemEntityType.directory);
        });

        test('unlinksIfTargetIsDirectoryAndRecursiveTrue', () {
          Link l = fs.link(ns('/foo'))..createSync(ns('/bar'));
          fs.directory(ns('/bar')).createSync();
          l.deleteSync(recursive: true);
          expect(fs.typeSync(ns('/foo'), followLinks: false),
              FileSystemEntityType.notFound);
          expect(fs.typeSync(ns('/bar'), followLinks: false),
              FileSystemEntityType.directory);
        });

        test('unlinksIfTargetIsLinkLoop', () {
          Link l = fs.link(ns('/foo'))..createSync(ns('/bar'));
          fs.link(ns('/bar')).createSync(ns('/foo'));
          l.deleteSync();
          expect(fs.typeSync(ns('/foo'), followLinks: false),
              FileSystemEntityType.notFound);
          expect(fs.typeSync(ns('/bar'), followLinks: false),
              FileSystemEntityType.link);
        });
      });

      group('parent', () {
        test('returnsCovariantType', () {
          expect(fs.link(ns('/foo')).parent, isDirectory);
        });

        test('succeedsIfLinkDoesntExist', () {
          expect(fs.link(ns('/foo')).parent.path, ns('/'));
        });

        test('ignoresLinkTarget', () {
          Link l = fs.link(ns('/foo/bar'))
            ..createSync(ns('/baz/qux'), recursive: true);
          expect(l.parent.path, ns('/foo'));
        });
      });

      group('create', () {
        test('returnsCovariantType', () async {
          expect(await fs.link(ns('/foo')).create(ns('/bar')), isLink);
        });

        test('succeedsIfLinkDoesntExistAtTail', () {
          Link l = fs.link(ns('/foo'))..createSync(ns('/bar'));
          expect(fs.typeSync(ns('/foo'), followLinks: false),
              FileSystemEntityType.link);
          expect(l.targetSync(), ns('/bar'));
        });

        test('throwsIfLinkDoesntExistViaTraversalAndRecursiveFalse', () {
          expectFileSystemException(ErrorCodes.ENOENT, () {
            fs.link(ns('/foo/bar')).createSync('baz');
          });
        });

        test('succeedsIfLinkDoesntExistViaTraversalAndRecursiveTrue', () {
          Link l = fs.link(ns('/foo/bar'))..createSync('baz', recursive: true);
          expect(fs.typeSync(ns('/foo'), followLinks: false),
              FileSystemEntityType.directory);
          expect(fs.typeSync(ns('/foo/bar'), followLinks: false),
              FileSystemEntityType.link);
          expect(l.targetSync(), 'baz');
        });

        test('throwsIfAlreadyExistsAsFile', () {
          fs.file(ns('/foo')).createSync();
          expectFileSystemException(ErrorCodes.EEXIST, () {
            fs.link(ns('/foo')).createSync(ns('/bar'));
          });
        });

        test('throwsIfAlreadyExistsAsDirectory', () {
          fs.directory(ns('/foo')).createSync();
          expectFileSystemException(ErrorCodes.EEXIST, () {
            fs.link(ns('/foo')).createSync(ns('/bar'));
          });
        });

        test('throwsIfAlreadyExistsWithSameTarget', () {
          fs.link(ns('/foo')).createSync(ns('/bar'));
          expectFileSystemException(ErrorCodes.EEXIST, () {
            fs.link(ns('/foo')).createSync(ns('/bar'));
          });
        });

        test('throwsIfAlreadyExistsWithDifferentTarget', () {
          fs.link(ns('/foo')).createSync(ns('/bar'));
          expectFileSystemException(ErrorCodes.EEXIST, () {
            fs.link(ns('/foo')).createSync(ns('/baz'));
          });
        });
      });

      group('update', () {
        test('returnsCovariantType', () async {
          Link l = fs.link(ns('/foo'))..createSync(ns('/bar'));
          expect(await l.update(ns('/baz')), isLink);
        });

        test('throwsIfLinkDoesntExistAtTail', () {
          expectFileSystemException(ErrorCodes.ENOENT, () {
            fs.link(ns('/foo')).updateSync(ns('/bar'));
          });
        });

        test('throwsIfLinkDoesntExistViaTraversal', () {
          expectFileSystemException(ErrorCodes.ENOENT, () {
            fs.link(ns('/foo/bar')).updateSync(ns('/baz'));
          });
        });

        test('throwsIfPathReferencesFile', () {
          fs.file(ns('/foo')).createSync();
          expectFileSystemException(ErrorCodes.EINVAL, () {
            fs.link(ns('/foo')).updateSync(ns('/bar'));
          });
        });

        test('throwsIfPathReferencesDirectory', () {
          fs.directory(ns('/foo')).createSync();
          // TODO(tvolkert): Change this to just be 'Is a directory'
          // once Dart 1.22 is stable.
          expectFileSystemException(
            anyOf(ErrorCodes.EINVAL, ErrorCodes.EISDIR),
            () {
              fs.link(ns('/foo')).updateSync(ns('/bar'));
            },
          );
        });

        test('succeedsIfNewTargetSameAsOldTarget', () {
          fs.link(ns('/foo')).createSync(ns('/bar'));
          fs.link(ns('/foo')).updateSync(ns('/bar'));
          expect(fs.typeSync(ns('/foo'), followLinks: false),
              FileSystemEntityType.link);
          expect(fs.link(ns('/foo')).targetSync(), ns('/bar'));
        });

        test('succeedsIfNewTargetDifferentFromOldTarget', () {
          fs.link(ns('/foo')).createSync(ns('/bar'));
          fs.link(ns('/foo')).updateSync(ns('/baz'));
          expect(fs.typeSync(ns('/foo'), followLinks: false),
              FileSystemEntityType.link);
          expect(fs.link(ns('/foo')).targetSync(), ns('/baz'));
        });
      });

      group('absolute', () {
        test('returnsCovariantType', () {
          expect(fs.link('foo').absolute, isLink);
        });

        test('returnsSamePathIfAlreadyAbsolute', () {
          expect(fs.link(ns('/foo')).absolute.path, ns('/foo'));
        });

        test('succeedsForRelativePaths', () {
          expect(fs.link('foo').absolute.path, ns('/foo'));
        });
      });

      group('target', () {
        test('throwsIfLinkDoesntExistAtTail', () {
          expectFileSystemException(ErrorCodes.ENOENT, () {
            fs.link(ns('/foo')).targetSync();
          });
        });

        test('throwsIfLinkDoesntExistViaTraversal', () {
          expectFileSystemException(ErrorCodes.ENOENT, () {
            fs.link(ns('/foo/bar')).targetSync();
          });
        });

        test('throwsIfPathReferencesFile', () {
          fs.file(ns('/foo')).createSync();
          expectFileSystemException(ErrorCodes.ENOENT, () {
            fs.link(ns('/foo')).targetSync();
          });
        });

        test('throwsIfPathReferencesDirectory', () {
          fs.directory(ns('/foo')).createSync();
          expectFileSystemException(ErrorCodes.ENOENT, () {
            fs.link(ns('/foo')).targetSync();
          });
        });

        test('succeedsIfTargetIsNotFound', () {
          Link l = fs.link(ns('/foo'))..createSync(ns('/bar'));
          expect(l.targetSync(), ns('/bar'));
        });

        test('succeedsIfTargetIsFile', () {
          Link l = fs.link(ns('/foo'))..createSync(ns('/bar'));
          fs.file(ns('/bar')).createSync();
          expect(l.targetSync(), ns('/bar'));
        });

        test('succeedsIfTargetIsDirectory', () {
          Link l = fs.link(ns('/foo'))..createSync(ns('/bar'));
          fs.directory(ns('/bar')).createSync();
          expect(l.targetSync(), ns('/bar'));
        });

        test('succeedsIfTargetIsLinkLoop', () {
          Link l = fs.link(ns('/foo'))..createSync(ns('/bar'));
          fs.link(ns('/bar')).createSync(ns('/foo'));
          expect(l.targetSync(), ns('/bar'));
        });
      });

      group('rename', () {
        test('returnsCovariantType', () async {
          Link l() => fs.link(ns('/foo'))..createSync(ns('/bar'));
          expect(l().renameSync(ns('/bar')), isLink);
          expect(await l().rename(ns('/bar')), isLink);
        });

        test('throwsIfSourceDoesntExistAtTail', () {
          expectFileSystemException(ErrorCodes.ENOENT, () {
            fs.link(ns('/foo')).renameSync(ns('/bar'));
          });
        });

        test('throwsIfSourceDoesntExistViaTraversal', () {
          expectFileSystemException(ErrorCodes.ENOENT, () {
            fs.link(ns('/foo/bar')).renameSync(ns('/bar'));
          });
        });

        test('throwsIfSourceIsFile', () {
          fs.file(ns('/foo')).createSync();
          expectFileSystemException(ErrorCodes.EINVAL, () {
            fs.link(ns('/foo')).renameSync(ns('/bar'));
          });
        });

        test('throwsIfSourceIsDirectory', () {
          fs.directory(ns('/foo')).createSync();
          expectFileSystemException(ErrorCodes.EISDIR, () {
            fs.link(ns('/foo')).renameSync(ns('/bar'));
          });
        });

        test('succeedsIfSourceIsLinkToFile', () {
          Link l = fs.link(ns('/foo'))..createSync(ns('/bar'));
          fs.file(ns('/bar')).createSync();
          Link renamed = l.renameSync(ns('/baz'));
          expect(renamed.path, ns('/baz'));
          expect(fs.typeSync(ns('/foo'), followLinks: false),
              FileSystemEntityType.notFound);
          expect(fs.typeSync(ns('/bar'), followLinks: false),
              FileSystemEntityType.file);
          expect(fs.typeSync(ns('/baz'), followLinks: false),
              FileSystemEntityType.link);
          expect(fs.link(ns('/baz')).targetSync(), ns('/bar'));
        });

        test('succeedsIfSourceIsLinkToNotFound', () {
          Link l = fs.link(ns('/foo'))..createSync(ns('/bar'));
          Link renamed = l.renameSync(ns('/baz'));
          expect(renamed.path, ns('/baz'));
          expect(fs.typeSync(ns('/foo'), followLinks: false),
              FileSystemEntityType.notFound);
          expect(fs.typeSync(ns('/baz'), followLinks: false),
              FileSystemEntityType.link);
          expect(fs.link(ns('/baz')).targetSync(), ns('/bar'));
        });

        test('succeedsIfSourceIsLinkToDirectory', () {
          Link l = fs.link(ns('/foo'))..createSync(ns('/bar'));
          fs.directory(ns('/bar')).createSync();
          Link renamed = l.renameSync(ns('/baz'));
          expect(renamed.path, ns('/baz'));
          expect(fs.typeSync(ns('/foo'), followLinks: false),
              FileSystemEntityType.notFound);
          expect(fs.typeSync(ns('/bar'), followLinks: false),
              FileSystemEntityType.directory);
          expect(fs.typeSync(ns('/baz'), followLinks: false),
              FileSystemEntityType.link);
          expect(fs.link(ns('/baz')).targetSync(), ns('/bar'));
        });

        test('succeedsIfSourceIsLinkLoop', () {
          Link l = fs.link(ns('/foo'))..createSync(ns('/bar'));
          fs.link(ns('/bar')).createSync(ns('/foo'));
          Link renamed = l.renameSync(ns('/baz'));
          expect(renamed.path, ns('/baz'));
          expect(fs.typeSync(ns('/foo'), followLinks: false),
              FileSystemEntityType.notFound);
          expect(fs.typeSync(ns('/bar'), followLinks: false),
              FileSystemEntityType.link);
          expect(fs.typeSync(ns('/baz'), followLinks: false),
              FileSystemEntityType.link);
          expect(fs.link(ns('/baz')).targetSync(), ns('/bar'));
        });

        test('succeedsIfDestinationDoesntExistAtTail', () {
          Link l = fs.link(ns('/foo'))..createSync(ns('/bar'));
          Link renamed = l.renameSync(ns('/baz'));
          expect(renamed.path, ns('/baz'));
          expect(fs.link(ns('/foo')), isNot(exists));
          expect(fs.link(ns('/baz')), exists);
        });

        test('throwsIfDestinationDoesntExistViaTraversal', () {
          Link l = fs.link(ns('/foo'))..createSync(ns('/bar'));
          expectFileSystemException(ErrorCodes.ENOENT, () {
            l.renameSync(ns('/baz/qux'));
          });
        });

        test('throwsIfDestinationExistsAsFile', () {
          Link l = fs.link(ns('/foo'))..createSync(ns('/bar'));
          fs.file(ns('/baz')).createSync();
          expectFileSystemException(ErrorCodes.EINVAL, () {
            l.renameSync(ns('/baz'));
          });
        });

        test('throwsIfDestinationExistsAsDirectory', () {
          Link l = fs.link(ns('/foo'))..createSync(ns('/bar'));
          fs.directory(ns('/baz')).createSync();
          expectFileSystemException(ErrorCodes.EINVAL, () {
            l.renameSync(ns('/baz'));
          });
        });

        test('succeedsIfDestinationExistsAsLinkToFile', () {
          Link l = fs.link(ns('/foo'))..createSync(ns('/bar'));
          fs.file(ns('/baz')).createSync();
          fs.link(ns('/qux')).createSync(ns('/baz'));
          l.renameSync(ns('/qux'));
          expect(fs.typeSync(ns('/foo')), FileSystemEntityType.notFound);
          expect(fs.typeSync(ns('/baz'), followLinks: false),
              FileSystemEntityType.file);
          expect(fs.typeSync(ns('/qux'), followLinks: false),
              FileSystemEntityType.link);
          expect(fs.link(ns('/qux')).targetSync(), ns('/bar'));
        });

        test('throwsIfDestinationExistsAsLinkToDirectory', () {
          Link l = fs.link(ns('/foo'))..createSync(ns('/bar'));
          fs.directory(ns('/baz')).createSync();
          fs.link(ns('/qux')).createSync(ns('/baz'));
          l.renameSync(ns('/qux'));
          expect(fs.typeSync(ns('/foo')), FileSystemEntityType.notFound);
          expect(fs.typeSync(ns('/baz'), followLinks: false),
              FileSystemEntityType.directory);
          expect(fs.typeSync(ns('/qux'), followLinks: false),
              FileSystemEntityType.link);
          expect(fs.link(ns('/qux')).targetSync(), ns('/bar'));
        });

        test('succeedsIfDestinationExistsAsLinkToNotFound', () {
          Link l = fs.link(ns('/foo'))..createSync(ns('/bar'));
          fs.link(ns('/baz')).createSync(ns('/qux'));
          l.renameSync(ns('/baz'));
          expect(fs.typeSync(ns('/foo')), FileSystemEntityType.notFound);
          expect(fs.typeSync(ns('/baz'), followLinks: false),
              FileSystemEntityType.link);
          expect(fs.link(ns('/baz')).targetSync(), ns('/bar'));
        });
      });
    });
  });
}
