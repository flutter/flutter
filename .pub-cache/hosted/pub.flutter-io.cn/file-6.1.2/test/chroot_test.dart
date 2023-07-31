// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
import 'dart:io' as io;

import 'package:file/chroot.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:test/test.dart';

import 'common_tests.dart';

void main() {
  group('ChrootFileSystem', () {
    ChrootFileSystem createMemoryBackedChrootFileSystem() {
      MemoryFileSystem fs = MemoryFileSystem();
      fs.directory('/tmp').createSync();
      return ChrootFileSystem(fs, '/tmp');
    }

    // TODO(jamesderlin): Make ChrootFile.openSync return a delegating
    // RandomAccessFile that uses the chroot'd path.
    List<String> skipCommon = <String>[
      'File > open > .* > RandomAccessFile > read > openReadHandleDoesNotChange',
      'File > open > .* > RandomAccessFile > openWriteHandleDoesNotChange',
    ];

    group('memoryBacked', () {
      runCommonTests(createMemoryBackedChrootFileSystem, skip: skipCommon);
    });

    group('localBacked', () {
      late ChrootFileSystem fs;
      late io.Directory tmp;

      setUp(() {
        tmp = io.Directory.systemTemp.createTempSync('file_test_');
        tmp = io.Directory(tmp.resolveSymbolicLinksSync());
        fs = ChrootFileSystem(const LocalFileSystem(), tmp.path);
      });

      tearDown(() {
        tmp.deleteSync(recursive: true);
      });

      runCommonTests(
        () => fs,
        skip: <String>[
          // https://github.com/dart-lang/sdk/issues/28275
          'Link > rename > throwsIfDestinationExistsAsDirectory',

          // https://github.com/dart-lang/sdk/issues/28277
          'Link > rename > throwsIfDestinationExistsAsFile',

          ...skipCommon,
        ],
      );
    }, skip: io.Platform.isWindows);

    group('chrootSpecific', () {
      late ChrootFileSystem fs;
      late MemoryFileSystem mem;

      setUp(() {
        fs = createMemoryBackedChrootFileSystem();
        mem = fs.delegate as MemoryFileSystem;
      });

      group('FileSystem', () {
        group('currentDirectory', () {
          test('staysInJailIfSetToParentOfRoot', () {
            fs.currentDirectory = '../../../..';
            fs.file('foo').createSync();
            expect(mem.file('/tmp/foo'), exists);
          });

          test('throwsIfSetToSymlinkToDirectoryOutsideJail', () {
            mem.directory('/bar').createSync();
            mem.link('/tmp/foo').createSync('/bar');
            expectFileSystemException(ErrorCodes.ENOENT, () {
              fs.currentDirectory = '/foo';
            });
          });
        });

        group('stat', () {
          test('isNotFoundForJailbreakPath', () {
            mem.file('/foo').createSync();
            expect(fs.statSync('../foo').type, FileSystemEntityType.notFound);
          });

          test('isNotFoundForSymlinkWithJailbreakTarget', () {
            mem.file('/foo').createSync();
            mem.link('/tmp/bar').createSync('/foo');
            expect(mem.statSync('/tmp/bar').type, FileSystemEntityType.file);
            expect(fs.statSync('/bar').type, FileSystemEntityType.notFound);
          });

          test('isNotFoundForSymlinkToOutsideAndBackInsideJail', () {
            mem.file('/tmp/bar').createSync();
            mem.link('/foo').createSync('/tmp/bar');
            mem.link('/tmp/baz').createSync('/foo');
            expect(mem.statSync('/tmp/baz').type, FileSystemEntityType.file);
            expect(fs.statSync('/baz').type, FileSystemEntityType.notFound);
          });
        });

        group('type', () {
          test('isNotFoundForJailbreakPath', () {
            mem.file('/foo').createSync();
            expect(fs.typeSync('../foo'), FileSystemEntityType.notFound);
          });

          test('isNotFoundForSymlinkWithJailbreakTarget', () {
            mem.file('/foo').createSync();
            mem.link('/tmp/bar').createSync('/foo');
            expect(mem.typeSync('/tmp/bar'), FileSystemEntityType.file);
            expect(fs.typeSync('/bar'), FileSystemEntityType.notFound);
          });

          test('isNotFoundForSymlinkToOutsideAndBackInsideJail', () {
            mem.file('/tmp/bar').createSync();
            mem.link('/foo').createSync('/tmp/bar');
            mem.link('/tmp/baz').createSync('/foo');
            expect(mem.typeSync('/tmp/baz'), FileSystemEntityType.file);
            expect(fs.typeSync('/baz'), FileSystemEntityType.notFound);
          });
        });
      });

      group('File', () {
        group('delegate', () {
          test('referencesRootEntityForJailbreakPath', () {
            mem.file('/foo').createSync();
            dynamic f = fs.file('../foo');
            expect(f.delegate.path, '/tmp/foo');
          });
        });

        group('create', () {
          test('createsAtRootIfPathReferencesJailbreakFile', () {
            fs.file('../foo').createSync();
            expect(mem.file('/foo'), isNot(exists));
            expect(mem.file('/tmp/foo'), exists);
          });
        });

        group('copy', () {
          test('copiesToRootDirectoryIfDestinationIsJailbreakPath', () {
            File f = fs.file('/foo')..createSync();
            f.copySync('../bar');
            expect(mem.file('/bar'), isNot(exists));
            expect(mem.file('/tmp/bar'), exists);
          });
        });
      });

      group('Link', () {
        group('target', () {
          test('chrootAndDelegateFileSystemsReturnSameValue', () {
            mem.file('/foo').createSync();
            mem.link('/tmp/bar').createSync('/foo');
            mem.link('/tmp/baz').createSync('../foo');
            expect(mem.link('/tmp/bar').targetSync(), '/foo');
            expect(fs.link('/bar').targetSync(), '/foo');
            expect(mem.link('/tmp/baz').targetSync(), '../foo');
            expect(fs.link('/baz').targetSync(), '../foo');
          });
        });
      });
    });
  });
}
