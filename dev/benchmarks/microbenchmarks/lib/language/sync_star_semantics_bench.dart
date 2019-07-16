// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';

import '../common.dart';

const int _kNumIterations = 1000;
const int _kNumWarmUp = 100;

void main() {
  final List<String> words = 'Lorem Ipsum is simply dummy text of the printing and'
    'typesetting industry. Lorem Ipsum has been the industry\'s'
    ' standard dummy text ever since the 1500s, when an unknown'
    ' printer took a galley of type and scrambled it to make a'
    ' type specimen book'.split(' ');
  final List<InlineSpanSemanticsInformation> data = <InlineSpanSemanticsInformation>[];
  for (int i = 0; i < words.length; i++) {
    if (i.isEven) {
      data.add(
        InlineSpanSemanticsInformation(words[i], isPlaceholder: false),
      );
    } else if (i % 2 == 0) {
      data.add(
        InlineSpanSemanticsInformation(words[i], isPlaceholder: true),
      );
    }
  }
  print(words);

  // Warm up lap
  for (int i = 0; i < _kNumWarmUp; i += 1) {
    combineSemanticsInfoSyncStar(data);
    combineSemanticsInfoList(data);
  }

  final Stopwatch watch = Stopwatch();
  watch.start();
  for (int i = 0; i < _kNumIterations; i += 1) {
    consumeSpan(combineSemanticsInfoSyncStar(data));
  }
  final int combineSemanticsInfoSyncStarTime = watch.elapsedMicroseconds;
  watch
    ..reset()
    ..start();
  for (int i = 0; i < _kNumIterations; i += 1) {
    consumeSpan(combineSemanticsInfoList(data));
  }
  final int combineSemanticsInfoListTime = watch.elapsedMicroseconds;
  watch
    ..reset()
    ..start();

  final BenchmarkResultPrinter printer = BenchmarkResultPrinter();
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
  String result = '';
  for (InlineSpanSemanticsInformation span in items) {
    result += span.text;
  }
  return result;
}


Iterable<InlineSpanSemanticsInformation> combineSemanticsInfoSyncStar(List<InlineSpanSemanticsInformation> inputs) sync* {
  String workingText = '';
  String workingLabel;
  for (InlineSpanSemanticsInformation info in inputs) {
    if (info.requiresOwnNode) {
      if (workingText != null) {
        yield InlineSpanSemanticsInformation(workingText, semanticsLabel: workingLabel ?? workingText);
        workingText = '';
        workingLabel = null;
      }
      yield info;
    } else {
      workingText += info.text;
      workingLabel ??= '';
      if (info.semanticsLabel != null) {
        workingLabel += info.semanticsLabel;
      } else {
        workingLabel += info.text;
      }
    }
  }
  if (workingText != null) {
    yield InlineSpanSemanticsInformation(workingText, semanticsLabel: workingLabel);
  } else {
    assert(workingLabel != null);
  }
}

Iterable<InlineSpanSemanticsInformation> combineSemanticsInfoList(List<InlineSpanSemanticsInformation> inputs) {
  String workingText = '';
  String workingLabel;
  final List<InlineSpanSemanticsInformation> result = <InlineSpanSemanticsInformation>[];
  for (InlineSpanSemanticsInformation info in inputs) {
    if (info.requiresOwnNode) {
      if (workingText != null) {
        result.add(InlineSpanSemanticsInformation(workingText, semanticsLabel: workingLabel ?? workingText));
        workingText = '';
        workingLabel = null;
      }
      result.add(info);
    } else {
      workingText += info.text;
      workingLabel ??= '';
      if (info.semanticsLabel != null) {
        workingLabel += info.semanticsLabel;
      } else {
        workingLabel += info.text;
      }
    }
  }
  if (workingText != null) {
    result.add(InlineSpanSemanticsInformation(workingText, semanticsLabel: workingLabel));
  } else {
    assert(workingLabel != null);
  }
  return result;
}

// TODO(jonahwilliams): use class from framework when landed.
class InlineSpanSemanticsInformation {
  const InlineSpanSemanticsInformation(
    this.text, {
    this.isPlaceholder = false,
    this.semanticsLabel,
    this.recognizer
  }) : assert(text != null),
       assert(isPlaceholder != null),
       assert(isPlaceholder == false || (text == '\uFFFC' && semanticsLabel == null && recognizer == null)),
       requiresOwnNode = isPlaceholder || recognizer != null;

   /// The text info for a [PlaceholderSpan].
  static const InlineSpanSemanticsInformation placeholder = InlineSpanSemanticsInformation('\uFFFC', isPlaceholder: true);

   /// The text value, if any.  For [PlaceholderSpan]s, this will be the unicode
  /// placeholder value.
  final String text;

   /// The semanticsLabel, if any.
  final String semanticsLabel;

   /// The gesture recognizer, if any, for this span.
  final GestureRecognizer recognizer;

   /// Whether this is for a placeholder span.
  final bool isPlaceholder;

   /// True if this configuration should get its own semantics node.
  ///
  /// This will be the case of the [recognizer] is not null, of if
  /// [isPlaceholder] is true.
  final bool requiresOwnNode;

   @override
  bool operator ==(dynamic other) {
    if (other is! InlineSpanSemanticsInformation) {
      return false;
    }
    return other.text == text &&
           other.semanticsLabel == semanticsLabel &&
           other.recognizer == recognizer &&
           other.isPlaceholder == isPlaceholder;
  }

  @override
  int get hashCode => ui.hashValues(text, semanticsLabel, recognizer, isPlaceholder);
}
