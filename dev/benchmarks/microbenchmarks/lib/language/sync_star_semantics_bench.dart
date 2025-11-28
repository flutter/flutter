// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import '../common.dart';

const int _kNumIterations = 1000;
const int _kNumWarmUp = 100;

Future<void> execute() async {
  final List<String> words =
      'Lorem Ipsum is simply dummy text of the printing and'
              " typesetting industry. Lorem Ipsum has been the industry's"
              ' standard dummy text ever since the 1500s, when an unknown'
              ' printer took a galley of type and scrambled it to make a'
              ' type specimen book'
          .split(' ');
  final data = <InlineSpanSemanticsInformation>[];
  for (var i = 0; i < words.length; i++) {
    if (i.isEven) {
      data.add(InlineSpanSemanticsInformation(words[i]));
    } else if (i.isEven) {
      data.add(InlineSpanSemanticsInformation(words[i], isPlaceholder: true));
    }
  }
  print(words);

  // Warm up lap
  for (var i = 0; i < _kNumWarmUp; i += 1) {
    combineSemanticsInfoSyncStar(data);
    combineSemanticsInfoList(data);
  }

  final watch = Stopwatch();
  watch.start();
  for (var i = 0; i < _kNumIterations; i += 1) {
    consumeSpan(combineSemanticsInfoSyncStar(data));
  }
  final int combineSemanticsInfoSyncStarTime = watch.elapsedMicroseconds;
  watch
    ..reset()
    ..start();
  for (var i = 0; i < _kNumIterations; i += 1) {
    consumeSpan(combineSemanticsInfoList(data));
  }
  final int combineSemanticsInfoListTime = watch.elapsedMicroseconds;
  watch
    ..reset()
    ..start();

  final printer = BenchmarkResultPrinter();
  const double scale = 1000.0 / _kNumIterations;
  printer.addResult(
    description: 'combineSemanticsInfoSyncStar',
    value: combineSemanticsInfoSyncStarTime * scale,
    unit: 'ns per iteration',
    name: 'combineSemanticsInfoSyncStar_iteration',
  );
  printer.addResult(
    description: 'combineSemanticsInfoList',
    value: combineSemanticsInfoListTime * scale,
    unit: 'ns per iteration',
    name: 'combineSemanticsInfoList_iteration',
  );
  printer.printToStdout();
}

String consumeSpan(Iterable<InlineSpanSemanticsInformation> items) {
  var result = '';
  for (final span in items) {
    result += span.text;
  }
  return result;
}

Iterable<InlineSpanSemanticsInformation> combineSemanticsInfoSyncStar(
  List<InlineSpanSemanticsInformation> inputs,
) sync* {
  var workingText = '';
  String? workingLabel;
  for (final info in inputs) {
    if (info.requiresOwnNode) {
      yield InlineSpanSemanticsInformation(
        workingText,
        semanticsLabel: workingLabel ?? workingText,
      );
      workingText = '';
      workingLabel = null;
      yield info;
    } else {
      workingText += info.text;
      workingLabel ??= '';
      final String? infoSemanticsLabel = info.semanticsLabel;
      workingLabel += infoSemanticsLabel ?? info.text;
    }
  }
  assert(workingLabel != null);
}

Iterable<InlineSpanSemanticsInformation> combineSemanticsInfoList(
  List<InlineSpanSemanticsInformation> inputs,
) {
  var workingText = '';
  String? workingLabel;
  final result = <InlineSpanSemanticsInformation>[];
  for (final info in inputs) {
    if (info.requiresOwnNode) {
      result.add(
        InlineSpanSemanticsInformation(workingText, semanticsLabel: workingLabel ?? workingText),
      );
      workingText = '';
      workingLabel = null;
      result.add(info);
    } else {
      workingText += info.text;
      workingLabel ??= '';
      final String? infoSemanticsLabel = info.semanticsLabel;
      workingLabel += infoSemanticsLabel ?? info.text;
    }
  }
  assert(workingLabel != null);
  return result;
}

//
//  Note that the benchmark is normally run by benchmark_collection.dart.
//
Future<void> main() async {
  return execute();
}
