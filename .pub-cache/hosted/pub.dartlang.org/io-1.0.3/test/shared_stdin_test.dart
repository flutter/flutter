// Copyright 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:io/io.dart' hide sharedStdIn;
import 'package:test/test.dart';

void main() {
  // ignore: close_sinks
  late StreamController<String> fakeStdIn;
  late SharedStdIn sharedStdIn;

  setUp(() {
    fakeStdIn = StreamController<String>(sync: true);
    sharedStdIn = SharedStdIn(fakeStdIn.stream.map((s) => s.codeUnits));
  });

  test('should allow a single subscriber', () async {
    final logs = <String>[];
    final sub = sharedStdIn.transform(utf8.decoder).listen(logs.add);
    fakeStdIn.add('Hello World');
    await sub.cancel();
    expect(logs, ['Hello World']);
  });

  test('should allow multiple subscribers', () async {
    final logs = <String>[];
    final asUtf8 = sharedStdIn.transform(utf8.decoder);
    var sub = asUtf8.listen(logs.add);
    fakeStdIn.add('Hello World');
    await sub.cancel();
    sub = asUtf8.listen(logs.add);
    fakeStdIn.add('Goodbye World');
    await sub.cancel();
    expect(logs, ['Hello World', 'Goodbye World']);
  });

  test('should throw if a subscriber is still active', () async {
    final active = sharedStdIn.listen((_) {});
    expect(() => sharedStdIn.listen((_) {}), throwsStateError);
    await active.cancel();
    expect(() => sharedStdIn.listen((_) {}), returnsNormally);
  });

  test('should return a stream of lines', () async {
    expect(
      sharedStdIn.lines(),
      emitsInOrder(<dynamic>[
        'I',
        'Think',
        'Therefore',
        'I',
        'Am',
      ]),
    );
    [
      'I\nThink\n',
      'Therefore\n',
      'I\n',
      'Am\n',
    ].forEach(fakeStdIn.add);
  });

  test('should return the next line', () {
    expect(sharedStdIn.nextLine(), completion('Hello World'));
    fakeStdIn.add('Hello World\n');
  });

  test('should allow listening for new lines multiple times', () async {
    expect(sharedStdIn.nextLine(), completion('Hello World'));
    fakeStdIn.add('Hello World\n');
    await Future<void>.value();

    expect(sharedStdIn.nextLine(), completion('Hello World'));
    fakeStdIn.add('Hello World\n');
  });
}
