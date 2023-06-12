// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:html/dom.dart';

import 'closed_caption_file.dart';
import 'package:html/parser.dart' as html_parser;

/// Represents a [ClosedCaptionFile], parsed from the WebVTT file format.
/// See: https://en.wikipedia.org/wiki/WebVTT
class WebVTTCaptionFile extends ClosedCaptionFile {
  /// Parses a string into a [ClosedCaptionFile], assuming [fileContents] is in
  /// the WebVTT file format.
  /// * See: https://en.wikipedia.org/wiki/WebVTT
  WebVTTCaptionFile(String fileContents)
      : _captions = _parseCaptionsFromWebVTTString(fileContents);

  @override
  List<Caption> get captions => _captions;

  final List<Caption> _captions;
}

List<Caption> _parseCaptionsFromWebVTTString(String file) {
  final List<Caption> captions = <Caption>[];

  // Ignore metadata
  Set<String> metadata = {'HEADER', 'NOTE', 'REGION', 'WEBVTT'};

  int captionNumber = 1;
  for (List<String> captionLines in _readWebVTTFile(file)) {
    // CaptionLines represent a complete caption.
    // E.g
    // [
    //  [00:00.000 --> 01:24.000 align:center]
    //  ['Introduction']
    // ]
    // If caption has just header or time, but no text, `captionLines.length` will be 1.
    if (captionLines.length < 2) continue;

    // If caption has header equal metadata, ignore.
    String metadaType = captionLines[0].split(' ')[0];
    if (metadata.contains(metadaType)) continue;

    // Caption has header
    bool hasHeader = captionLines.length > 2;
    if (hasHeader) {
      final int? tryParseCaptionNumber = int.tryParse(captionLines[0]);
      if (tryParseCaptionNumber != null) {
        captionNumber = tryParseCaptionNumber;
      }
    }

    final _CaptionRange? captionRange = _CaptionRange.fromWebVTTString(
      hasHeader ? captionLines[1] : captionLines[0],
    );

    if (captionRange == null) {
      continue;
    }

    final String text = captionLines.sublist(hasHeader ? 2 : 1).join('\n');

    // TODO(cyanglaz): Handle special syntax in VTT captions.
    // https://github.com/flutter/flutter/issues/90007.
    final String textWithoutFormat = _extractTextFromHtml(text);

    final Caption newCaption = Caption(
      number: captionNumber,
      start: captionRange.start,
      end: captionRange.end,
      text: textWithoutFormat,
    );
    captions.add(newCaption);
    captionNumber++;
  }

  return captions;
}

class _CaptionRange {
  final Duration start;
  final Duration end;

  _CaptionRange(this.start, this.end);

  // Assumes format from an VTT file.
  // For example:
  // 00:09.000 --> 00:11.000
  static _CaptionRange? fromWebVTTString(String line) {
    final RegExp format =
        RegExp(_webVTTTimeStamp + _webVTTArrow + _webVTTTimeStamp);

    if (!format.hasMatch(line)) {
      return null;
    }

    final List<String> times = line.split(_webVTTArrow);

    final Duration? start = _parseWebVTTTimestamp(times[0]);
    final Duration? end = _parseWebVTTTimestamp(times[1]);

    if (start == null || end == null) {
      return null;
    }

    return _CaptionRange(start, end);
  }
}

String _extractTextFromHtml(String htmlString) {
  final Document document = html_parser.parse(htmlString);
  final Element? body = document.body;
  if (body == null) {
    return '';
  }
  final Element? bodyElement = html_parser.parse(body.text).documentElement;
  return bodyElement?.text ?? '';
}

// Parses a time stamp in an VTT file into a Duration.
//
// Returns `null` if `timestampString` is in an invalid format.
//
// For example:
//
// _parseWebVTTTimestamp('00:01:08.430')
// returns
// Duration(hours: 0, minutes: 1, seconds: 8, milliseconds: 430)
Duration? _parseWebVTTTimestamp(String timestampString) {
  if (!RegExp(_webVTTTimeStamp).hasMatch(timestampString)) {
    return null;
  }

  final List<String> dotSections = timestampString.split('.');
  final List<String> timeComponents = dotSections[0].split(':');

  // Validating and parsing the `timestampString`, invalid format will result this method
  // to return `null`. See https://www.w3.org/TR/webvtt1/#webvtt-timestamp for valid
  // WebVTT timestamp format.
  if (timeComponents.length > 3 || timeComponents.length < 2) {
    return null;
  }
  int hours = 0;
  if (timeComponents.length == 3) {
    final String hourString = timeComponents.removeAt(0);
    if (hourString.length < 2) {
      return null;
    }
    hours = int.parse(hourString);
  }
  final int minutes = int.parse(timeComponents.removeAt(0));
  if (minutes < 0 || minutes > 59) {
    return null;
  }
  final int seconds = int.parse(timeComponents.removeAt(0));
  if (seconds < 0 || seconds > 59) {
    return null;
  }

  List<String> milisecondsStyles = dotSections[1].split(" ");

  // TODO(cyanglaz): Handle caption styles.
  // https://github.com/flutter/flutter/issues/90009.
  // ```dart
  // if (milisecondsStyles.length > 1) {
  //  List<String> styles = milisecondsStyles.sublist(1);
  // }
  // ```
  // For a better readable code style, style parsing should happen before
  // calling this method. See: https://github.com/flutter/plugins/pull/2878/files#r713381134.
  int milliseconds = int.parse(milisecondsStyles[0]);

  return Duration(
    hours: hours,
    minutes: minutes,
    seconds: seconds,
    milliseconds: milliseconds,
  );
}

// Reads on VTT file and splits it into Lists of strings where each list is one
// caption.
List<List<String>> _readWebVTTFile(String file) {
  final List<String> lines = LineSplitter.split(file).toList();

  final List<List<String>> captionStrings = <List<String>>[];
  List<String> currentCaption = <String>[];
  int lineIndex = 0;
  for (final String line in lines) {
    final bool isLineBlank = line.trim().isEmpty;
    if (!isLineBlank) {
      currentCaption.add(line);
    }

    if (isLineBlank || lineIndex == lines.length - 1) {
      captionStrings.add(currentCaption);
      currentCaption = <String>[];
    }

    lineIndex += 1;
  }

  return captionStrings;
}

const String _webVTTTimeStamp = r'(\d+):(\d{2})(:\d{2})?\.(\d{3})';
const String _webVTTArrow = r' --> ';
