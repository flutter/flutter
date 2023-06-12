// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/src/closed_caption_file.dart';
import 'package:video_player/video_player.dart';

void main() {
  test('Parses SubRip file', () {
    final SubRipCaptionFile parsedFile = SubRipCaptionFile(_validSubRip);

    expect(parsedFile.captions.length, 4);

    final Caption firstCaption = parsedFile.captions.first;
    expect(firstCaption.number, 1);
    expect(firstCaption.start, Duration(seconds: 6));
    expect(firstCaption.end, Duration(seconds: 12, milliseconds: 74));
    expect(firstCaption.text, 'This is a test file');

    final Caption secondCaption = parsedFile.captions[1];
    expect(secondCaption.number, 2);
    expect(
      secondCaption.start,
      Duration(minutes: 1, seconds: 54, milliseconds: 724),
    );
    expect(
      secondCaption.end,
      Duration(minutes: 1, seconds: 56, milliseconds: 760),
    );
    expect(secondCaption.text, '- Hello.\n- Yes?');

    final Caption thirdCaption = parsedFile.captions[2];
    expect(thirdCaption.number, 3);
    expect(
      thirdCaption.start,
      Duration(minutes: 1, seconds: 56, milliseconds: 884),
    );
    expect(
      thirdCaption.end,
      Duration(minutes: 1, seconds: 58, milliseconds: 954),
    );
    expect(
      thirdCaption.text,
      'These are more test lines\nYes, these are more test lines.',
    );

    final Caption fourthCaption = parsedFile.captions[3];
    expect(fourthCaption.number, 4);
    expect(
      fourthCaption.start,
      Duration(hours: 1, minutes: 1, seconds: 59, milliseconds: 84),
    );
    expect(
      fourthCaption.end,
      Duration(hours: 1, minutes: 2, seconds: 1, milliseconds: 552),
    );
    expect(
      fourthCaption.text,
      '- [ Machinery Beeping ]\n- I\'m not sure what that was,',
    );
  });

  test('Parses SubRip file with malformed input', () {
    final ClosedCaptionFile parsedFile = SubRipCaptionFile(_malformedSubRip);

    expect(parsedFile.captions.length, 1);

    final Caption firstCaption = parsedFile.captions.single;
    expect(firstCaption.number, 2);
    expect(firstCaption.start, Duration(seconds: 15));
    expect(firstCaption.end, Duration(seconds: 17, milliseconds: 74));
    expect(firstCaption.text, 'This one is valid');
  });
}

const String _validSubRip = '''
1
00:00:06,000 --> 00:00:12,074
This is a test file

2
00:01:54,724 --> 00:01:56,760
- Hello.
- Yes?

3
00:01:56,884 --> 00:01:58,954
These are more test lines
Yes, these are more test lines.

4
01:01:59,084 --> 01:02:01,552
- [ Machinery Beeping ]
- I'm not sure what that was,

''';

const String _malformedSubRip = '''
1
00:00:06,000--> 00:00:12,074
This one should be ignored because the
arrow needs a space.

2
00:00:15,000 --> 00:00:17,074
This one is valid

3
00:01:54,724 --> 00:01:6,760
This one should be ignored because the
ned time is missing a digit.
''';
