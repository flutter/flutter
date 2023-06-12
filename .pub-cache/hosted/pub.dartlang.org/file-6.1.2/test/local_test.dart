// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
import 'dart:io' as io;

import 'package:file/local.dart';
import 'package:file_testing/src/testing/internal.dart';
import 'package:test/test.dart';

import 'common_tests.dart';

void main() {
  group('LocalFileSystem', () {
    late LocalFileSystem fs;
    late io.Directory tmp;
    late String cwd;

    setUp(() {
      fs = const LocalFileSystem();
      tmp = io.Directory.systemTemp.createTempSync('file_test_');
      tmp = io.Directory(tmp.resolveSymbolicLinksSync());
      cwd = io.Directory.current.path;
      io.Directory.current = tmp;
    });

    tearDown(() {
      io.Directory.current = cwd;
      tmp.deleteSync(recursive: true);
    });

    setUpAll(() {
      if (io.Platform.isWindows) {
        // TODO(tvolkert): Remove once all more serious test failures are fixed
        // https://github.com/google/file.dart/issues/56
        ignoreOsErrorCodes = true;
      }
    });

    tearDownAll(() {
      ignoreOsErrorCodes = false;
    });

    Map<String, List<String>> skipOnPlatform = <String, List<String>>{
      'windows': <String>[
        'FileSystem > currentDirectory > throwsIfHasNonExistentPathInComplexChain',
        'FileSystem > currentDirectory > resolvesLinksIfEncountered',
        'FileSystem > currentDirectory > succeedsIfSetToDirectoryLinkAtTail',
        'FileSystem > stat > isFileForLinkToFile',
        'FileSystem > type > isFileForLinkToFileAndFollowLinksTrue',
        'FileSystem > type > isNotFoundForLinkWithCircularReferenceAndFollowLinksTrue',
        'Directory > exists > falseIfNotFoundSegmentExistsThenIsBackedOut',
        'Directory > rename > throwsIfDestinationIsNonEmptyDirectory',
        'Directory > rename > throwsIfDestinationIsLinkToEmptyDirectory',
        'Directory > resolveSymbolicLinks > throwsIfPathNotFoundInMiddleThenBackedOut',
        'Directory > resolveSymbolicLinks > handlesRelativeLinks',
        'Directory > resolveSymbolicLinks > handlesLinksWhoseTargetsHaveNestedLinks',
        'Directory > resolveSymbolicLinks > handlesComplexPathWithMultipleLinks',
        'Directory > createTemp > succeedsWithNestedPathPrefixThatExists',
        'Directory > list > followsLinksIfFollowLinksTrue',
        'Directory > list > returnsCovariantType',
        'Directory > list > returnsLinkObjectsForRecursiveLinkIfFollowLinksTrue',
        'Directory > delete > succeedsIfPathReferencesLinkToFileAndRecursiveTrue',
        'File > rename > succeedsIfSourceExistsAsLinkToFile',
        'File > copy > succeedsIfSourceExistsAsLinkToFile',
        'File > copy > succeedsIfSourceIsLinkToFileInDifferentDirectory',
        'File > delete > succeedsIfExistsAsLinkToFileAndRecursiveTrue',
        'File > openWrite > ioSink > throwsIfEncodingIsNullAndWriteObject',
        'File > openWrite > ioSink > allowsChangingEncoding',
        'File > openWrite > ioSink > succeedsIfAddRawData',
        'File > openWrite > ioSink > succeedsIfWrite',
        'File > openWrite > ioSink > succeedsIfWriteAll',
        'File > openWrite > ioSink > succeedsIfWriteCharCode',
        'File > openWrite > ioSink > succeedsIfWriteln',
        'File > openWrite > ioSink > addStream > succeedsIfStreamProducesData',
        'File > openWrite > ioSink > addStream > blocksCallToAddWhileStreamIsActive',
        'File > openWrite > ioSink > addStream > blocksCallToWriteWhileStreamIsActive',
        'File > openWrite > ioSink > addStream > blocksCallToWriteAllWhileStreamIsActive',
        'File > openWrite > ioSink > addStream > blocksCallToWriteCharCodeWhileStreamIsActive',
        'File > openWrite > ioSink > addStream > blocksCallToWritelnWhileStreamIsActive',
        'File > openWrite > ioSink > addStream > blocksCallToFlushWhileStreamIsActive',
        'File > stat > isFileIfExistsAsLinkToFile',
        'Link > stat > isFileIfTargetIsFile',
        'Link > stat > isDirectoryIfTargetIsDirectory',
        'Link > delete > unlinksIfTargetIsDirectoryAndRecursiveTrue',
        'Link > delete > unlinksIfTargetIsFileAndRecursiveTrue',

        // Fixed in SDK 1.23 (https://github.com/dart-lang/sdk/issues/28852)
        'File > open > WRITE > RandomAccessFile > truncate > throwsIfSetToNegativeNumber',
        'File > open > APPEND > RandomAccessFile > truncate > throwsIfSetToNegativeNumber',
        'File > open > WRITE_ONLY > RandomAccessFile > truncate > throwsIfSetToNegativeNumber',
        'File > open > WRITE_ONLY_APPEND > RandomAccessFile > truncate > throwsIfSetToNegativeNumber',

        // Windows does not allow removing or renaming open files.
        '.* > openReadHandleDoesNotChange',
        '.* > openWriteHandleDoesNotChange',
      ],
    };

    runCommonTests(
      () => fs,
      root: () => tmp.path,
      skip: <String>[
        // https://github.com/dart-lang/sdk/issues/28171
        'File > rename > throwsIfDestinationExistsAsLinkToDirectory',

        // https://github.com/dart-lang/sdk/issues/28275
        'Link > rename > throwsIfDestinationExistsAsDirectory',

        // https://github.com/dart-lang/sdk/issues/28277
        'Link > rename > throwsIfDestinationExistsAsFile',

        ...skipOnPlatform[io.Platform.operatingSystem] ?? <String>[],
      ],
    );

    group('toString', () {
      test('File', () {
        expect(fs.file('/foo').toString(), "LocalFile: '/foo'");
      });

      test('Directory', () {
        expect(fs.directory('/foo').toString(), "LocalDirectory: '/foo'");
      });

      test('Link', () {
        expect(fs.link('/foo').toString(), "LocalLink: '/foo'");
      });
    });
  });
}
