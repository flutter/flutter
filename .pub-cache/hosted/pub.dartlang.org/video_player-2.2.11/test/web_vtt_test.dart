// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/src/closed_caption_file.dart';
import 'package:video_player/video_player.dart';

void main() {
  group('Parse VTT file', () {
    WebVTTCaptionFile parsedFile;

    test('with Metadata', () {
      parsedFile = WebVTTCaptionFile(_valid_vtt_with_metadata);
      expect(parsedFile.captions.length, 1);

      expect(parsedFile.captions[0].start, Duration(seconds: 1));
      expect(
          parsedFile.captions[0].end, Duration(seconds: 2, milliseconds: 500));
      expect(parsedFile.captions[0].text, 'We are in New York City');
    });

    test('with Multiline', () {
      parsedFile = WebVTTCaptionFile(_valid_vtt_with_multiline);
      expect(parsedFile.captions.length, 1);

      expect(parsedFile.captions[0].start,
          Duration(seconds: 2, milliseconds: 800));
      expect(
          parsedFile.captions[0].end, Duration(seconds: 3, milliseconds: 283));
      expect(parsedFile.captions[0].text,
          "— It will perforate your stomach.\n— You could die.");
    });

    test('with styles tags', () {
      parsedFile = WebVTTCaptionFile(_valid_vtt_with_styles);
      expect(parsedFile.captions.length, 3);

      expect(parsedFile.captions[0].start,
          Duration(seconds: 5, milliseconds: 200));
      expect(
          parsedFile.captions[0].end, Duration(seconds: 6, milliseconds: 000));
      expect(parsedFile.captions[0].text,
          "You know I'm so excited my glasses are falling off here.");
    });

    test('with subtitling features', () {
      parsedFile = WebVTTCaptionFile(_valid_vtt_with_subtitling_features);
      expect(parsedFile.captions.length, 3);

      expect(parsedFile.captions[0].number, 1);
      expect(parsedFile.captions.last.start, Duration(seconds: 4));
      expect(parsedFile.captions.last.end, Duration(seconds: 5));
      expect(parsedFile.captions.last.text, "Transcrit par Célestes™");
    });

    test('with [hours]:[minutes]:[seconds].[milliseconds].', () {
      parsedFile = WebVTTCaptionFile(_valid_vtt_with_hours);
      expect(parsedFile.captions.length, 1);

      expect(parsedFile.captions[0].number, 1);
      expect(parsedFile.captions.last.start, Duration(seconds: 1));
      expect(parsedFile.captions.last.end, Duration(seconds: 2));
      expect(parsedFile.captions.last.text, "This is a test.");
    });

    test('with [minutes]:[seconds].[milliseconds].', () {
      parsedFile = WebVTTCaptionFile(_valid_vtt_without_hours);
      expect(parsedFile.captions.length, 1);

      expect(parsedFile.captions[0].number, 1);
      expect(parsedFile.captions.last.start, Duration(seconds: 3));
      expect(parsedFile.captions.last.end, Duration(seconds: 4));
      expect(parsedFile.captions.last.text, "This is a test.");
    });

    test('with invalid seconds format returns empty captions.', () {
      parsedFile = WebVTTCaptionFile(_invalid_seconds);
      expect(parsedFile.captions, isEmpty);
    });

    test('with invalid minutes format returns empty captions.', () {
      parsedFile = WebVTTCaptionFile(_invalid_minutes);
      expect(parsedFile.captions, isEmpty);
    });

    test('with invalid hours format returns empty captions.', () {
      parsedFile = WebVTTCaptionFile(_invalid_hours);
      expect(parsedFile.captions, isEmpty);
    });

    test('with invalid component length returns empty captions.', () {
      parsedFile = WebVTTCaptionFile(_time_component_too_long);
      expect(parsedFile.captions, isEmpty);

      parsedFile = WebVTTCaptionFile(_time_component_too_short);
      expect(parsedFile.captions, isEmpty);
    });
  });

  test('Parses VTT file with malformed input.', () {
    final ClosedCaptionFile parsedFile = WebVTTCaptionFile(_malformedVTT);

    expect(parsedFile.captions.length, 1);

    final Caption firstCaption = parsedFile.captions.single;
    expect(firstCaption.number, 1);
    expect(firstCaption.start, Duration(seconds: 13));
    expect(firstCaption.end, Duration(seconds: 16, milliseconds: 0));
    expect(firstCaption.text, 'Valid');
  });
}

/// See https://www.w3.org/TR/webvtt1/#introduction-comments
const String _valid_vtt_with_metadata = '''
WEBVTT Kind: captions; Language: en

REGION
id:bill
width:40%
lines:3
regionanchor:100%,100%
viewportanchor:90%,90%
scroll:up

NOTE
This file was written by Jill. I hope
you enjoy reading it. Some things to
bear in mind:
- I was lip-reading, so the cues may
not be 100% accurate
- I didn’t pay too close attention to
when the cues should start or end.

1
00:01.000 --> 00:02.500
<v Roger Bingham>We are in New York City
''';

/// See https://www.w3.org/TR/webvtt1/#introduction-multiple-lines
const String _valid_vtt_with_multiline = '''
WEBVTT

2
00:02.800 --> 00:03.283
— It will perforate your stomach.
— You could die.

''';

/// See https://www.w3.org/TR/webvtt1/#styling
const String _valid_vtt_with_styles = '''
WEBVTT

00:05.200 --> 00:06.000 align:start size:50%
<v Roger Bingham><i>You know I'm so excited my glasses are falling off here.</i>

00:00:06.050 --> 00:00:06.150 
<v Roger Bingham><i>I have a different time!</i>

00:06.200 --> 00:06.900
<c.yellow.bg_blue>This is yellow text on a blue background</c>

''';

//See https://www.w3.org/TR/webvtt1/#introduction-other-features
const String _valid_vtt_with_subtitling_features = '''
WEBVTT

test
00:00.000 --> 00:02.000
This is a test.

Slide 1
00:00:00.000 --> 00:00:10.700
Title Slide

crédit de transcription
00:04.000 --> 00:05.000
Transcrit par Célestes™

''';

/// With format [hours]:[minutes]:[seconds].[milliseconds]
const String _valid_vtt_with_hours = '''
WEBVTT

test
00:00:01.000 --> 00:00:02.000
This is a test.

''';

/// Invalid seconds format.
const String _invalid_seconds = '''
WEBVTT

60:00:000.000 --> 60:02:000.000
This is a test.

''';

/// Invalid minutes format.
const String _invalid_minutes = '''
WEBVTT

60:60:00.000 --> 60:70:00.000
This is a test.

''';

/// Invalid hours format.
const String _invalid_hours = '''
WEBVTT

5:00:00.000 --> 5:02:00.000
This is a test.

''';

/// Invalid seconds format.
const String _time_component_too_long = '''
WEBVTT

60:00:00:00.000 --> 60:02:00:00.000
This is a test.

''';

/// Invalid seconds format.
const String _time_component_too_short = '''
WEBVTT

60:00.000 --> 60:02.000
This is a test.

''';

/// With format [minutes]:[seconds].[milliseconds]
const String _valid_vtt_without_hours = '''
WEBVTT

00:03.000 --> 00:04.000
This is a test.

''';

const String _malformedVTT = '''

WEBVTT Kind: captions; Language: en

00:09.000--> 00:11.430
<Test>This one should be ignored because the arrow needs a space.

00:13.000 --> 00:16.000
<Test>Valid

00:16.000 --> 00:8.000
<Test>This one should be ignored because the time is missing a digit.

''';
