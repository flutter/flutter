// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@TestOn('vm')
import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:build/src/builder/build_step.dart';
import 'package:build/src/builder/build_step_impl.dart';
import 'package:build_resolvers/build_resolvers.dart';
import 'package:build_test/build_test.dart';
import 'package:pedantic/pedantic.dart';
import 'package:test/test.dart';

void main() {
  late ResourceManager resourceManager;

  setUp(() {
    resourceManager = ResourceManager();
  });

  tearDown(() async {
    await resourceManager.disposeAll();
  });

  group('with reader/writer stub', () {
    late AssetId primary;
    late BuildStepImpl buildStep;

    setUp(() {
      var reader = StubAssetReader();
      var writer = StubAssetWriter();
      primary = makeAssetId();
      buildStep = BuildStepImpl(
          primary, [], reader, writer, AnalyzerResolvers(), resourceManager);
    });

    test('doesnt allow non-expected outputs', () {
      var id = makeAssetId();
      expect(() => buildStep.writeAsString(id, '$id'),
          throwsA(TypeMatcher<UnexpectedOutputException>()));
      expect(() => buildStep.writeAsBytes(id, [0]),
          throwsA(TypeMatcher<UnexpectedOutputException>()));
    });

    test('fetchResource can fetch resources', () async {
      var expected = 1;
      var intResource = Resource(() => expected);
      var actual = await buildStep.fetchResource(intResource);
      expect(actual, expected);
    });
  });

  group('with in memory file system', () {
    late InMemoryAssetWriter writer;
    late InMemoryAssetReader reader;

    setUp(() {
      writer = InMemoryAssetWriter();
      reader = InMemoryAssetReader.shareAssetCache(writer.assets);
    });

    test('tracks outputs created by a builder', () async {
      var builder = TestBuilder();
      var primary = makeAssetId('a|web/primary.txt');
      var inputs = {
        primary: 'foo',
      };
      addAssets(inputs, writer);
      var outputId = AssetId.parse('$primary.copy');
      var buildStep = BuildStepImpl(primary, [outputId], reader, writer,
          AnalyzerResolvers(), resourceManager);

      await builder.build(buildStep);
      await buildStep.complete();

      // One output.
      expect(writer.assets[outputId], decodedMatches('foo'));
    });

    group('resolve', () {
      test('can resolve assets', () async {
        var inputs = {
          makeAssetId('a|web/a.dart'): '''
              library a;

              import 'b.dart';
            ''',
          makeAssetId('a|web/b.dart'): '''
              library b;
            ''',
        };
        addAssets(inputs, writer);

        var primary = makeAssetId('a|web/a.dart');
        var buildStep = BuildStepImpl(
            primary, [], reader, writer, AnalyzerResolvers(), resourceManager);
        var resolver = buildStep.resolver;

        var aLib = await resolver.libraryFor(primary);
        expect(aLib.name, 'a');
        expect(aLib.importedLibraries.length, 2);
        expect(aLib.importedLibraries.any((library) => library.name == 'b'),
            isTrue);

        var bLib = await resolver.findLibraryByName('b');
        expect(bLib!.name, 'b');
        expect(bLib.importedLibraries.length, 1);

        await buildStep.complete();
      });
    });
  });

  group('With slow writes', () {
    late BuildStepImpl buildStep;
    late SlowAssetWriter assetWriter;
    late AssetId outputId;
    late String outputContent;

    setUp(() async {
      var primary = makeAssetId();
      assetWriter = SlowAssetWriter();
      outputId = makeAssetId('a|test.txt');
      outputContent = '$outputId';
      buildStep = BuildStepImpl(primary, [outputId], StubAssetReader(),
          assetWriter, AnalyzerResolvers(), resourceManager);
    });

    test('Completes only after writes finish', () async {
      unawaited(buildStep.writeAsString(outputId, outputContent));
      var isComplete = false;
      unawaited(buildStep.complete().then((_) {
        isComplete = true;
      }));
      await Future(() {});
      expect(isComplete, false,
          reason: 'File has not written, should not be complete');
      assetWriter.finishWrite();
      await Future(() {});
      expect(isComplete, true, reason: 'File is written, should be complete');
    });

    test('Completes only after async writes finish', () async {
      var outputCompleter = Completer<String>();
      unawaited(buildStep.writeAsString(outputId, outputCompleter.future));
      var isComplete = false;
      unawaited(buildStep.complete().then((_) {
        isComplete = true;
      }));
      await Future(() {});
      expect(isComplete, false,
          reason: 'File has not resolved, should not be complete');
      outputCompleter.complete(outputContent);
      await Future(() {});
      expect(isComplete, false,
          reason: 'File has not written, should not be complete');
      assetWriter.finishWrite();
      await Future(() {});
      expect(isComplete, true, reason: 'File is written, should be complete');
    });
  });

  group('With erroring writes', () {
    late AssetId primary;
    late BuildStepImpl buildStep;
    late AssetId output;

    setUp(() {
      var reader = StubAssetReader();
      var writer = StubAssetWriter();
      primary = makeAssetId();
      output = makeAssetId();
      buildStep = BuildStepImpl(primary, [output], reader, writer,
          AnalyzerResolvers(), resourceManager,
          stageTracker: NoOpStageTracker.instance);
    });

    test('Captures failed asynchronous writes', () {
      buildStep.writeAsString(output, Future.error('error'));
      expect(buildStep.complete(), throwsA('error'));
    });
  });

  test('reportUnusedAssets forwards calls if provided', () {
    var reader = StubAssetReader();
    var writer = StubAssetWriter();
    var unused = <AssetId>{};
    var buildStep = BuildStepImpl(
        makeAssetId(), [], reader, writer, AnalyzerResolvers(), resourceManager,
        reportUnusedAssets: unused.addAll);
    var reported = [
      makeAssetId(),
      makeAssetId(),
      makeAssetId(),
    ];
    buildStep.reportUnusedAssets(reported);
    expect(unused, equals(reported));
  });
}

class SlowAssetWriter implements AssetWriter {
  final _writeCompleter = Completer<Null>();

  void finishWrite() {
    _writeCompleter.complete(null);
  }

  @override
  Future<void> writeAsBytes(AssetId id, FutureOr<List<int>> bytes) =>
      _writeCompleter.future;

  @override
  Future<void> writeAsString(AssetId id, FutureOr<String> contents,
          {Encoding encoding = utf8}) =>
      _writeCompleter.future;
}
