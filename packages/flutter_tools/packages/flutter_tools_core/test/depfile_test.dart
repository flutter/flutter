// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:test/test.dart';

void main() {
  group('ExtensionDepfile', () {
    test('parses single and multiple inputs and outputs', () {
      final single = ExtensionDepfile.parse('a.txt: b.txt\n');
      expect(single.outputs, equals(<String>['a.txt']));
      expect(single.inputs, equals(<String>['b.txt']));

      final multiple = ExtensionDepfile.parse('out1.txt out2.txt: in1.txt in2.txt in3.txt\n');
      expect(multiple.outputs, equals(<String>['out1.txt', 'out2.txt']));
      expect(multiple.inputs, equals(<String>['in1.txt', 'in2.txt', 'in3.txt']));
    });

    test('unescapes spaces and deduplicates entries when parsing', () {
      final parsed = ExtensionDepfile.parse(
        r'/path/with\ spaces/out.txt: /path/with\ spaces/in.txt /path/with\ spaces/in.txt',
      );
      expect(parsed.outputs, equals(<String>['/path/with spaces/out.txt']));
      expect(parsed.inputs, equals(<String>['/path/with spaces/in.txt']));
    });

    test('parses Windows escaped paths and whitespace variations', () {
      final windowsParsed = ExtensionDepfile.parse(
        r'C:\\out\ dir\\a.txt: C:\\in\ dir\\b.txt C:\\in\ dir\\c.txt',
      );
      expect(windowsParsed.outputs, equals(<String>[r'C:\out dir\a.txt']));
      expect(windowsParsed.inputs, equals(<String>[r'C:\in dir\b.txt', r'C:\in dir\c.txt']));

      final whitespaceParsed = ExtensionDepfile.parse('a.txt\n  : b.txt    c.txt\n\n');
      expect(whitespaceParsed.outputs, equals(<String>['a.txt']));
      expect(whitespaceParsed.inputs, equals(<String>['b.txt', 'c.txt']));
    });

    test('parse throws FormatException on malformed depfile contents', () {
      expect(() => ExtensionDepfile.parse('missing_colon.txt b.txt'), throwsFormatException);
      expect(() => ExtensionDepfile.parse('a.txt: b.txt: c.txt'), throwsFormatException);
    });

    test('formats POSIX and Windows depfiles and round-trips through parse', () {
      const depfile = ExtensionDepfile(
        inputs: <String>['/project/Hello Flutter/in.txt', '/project/other.txt'],
        outputs: <String>['/project/Hello Flutter/out.txt'],
      );

      final String posixFormatted = depfile.format();
      expect(
        posixFormatted,
        equals(
          r' /project/Hello\ Flutter/out.txt:  /project/Hello\ Flutter/in.txt /project/other.txt',
        ),
      );
      expect(ExtensionDepfile.parse(posixFormatted), equals(depfile));

      const windowsDepfile = ExtensionDepfile(
        inputs: <String>[r'C:\Hello Flutter\in.txt'],
        outputs: <String>[r'C:\Hello Flutter\out.txt'],
      );
      final String windowsFormatted = windowsDepfile.format(windows: true);
      expect(
        windowsFormatted,
        equals(r' C:\\Hello\ Flutter\\out.txt:  C:\\Hello\ Flutter\\in.txt'),
      );
      expect(ExtensionDepfile.parse(windowsFormatted), equals(windowsDepfile));
    });

    test('equality, hashCode, and toString work as expected', () {
      const depfile1 = ExtensionDepfile(inputs: <String>['in.txt'], outputs: <String>['out.txt']);
      const depfile2 = ExtensionDepfile(inputs: <String>['in.txt'], outputs: <String>['out.txt']);
      const depfile3 = ExtensionDepfile(
        inputs: <String>['other.txt'],
        outputs: <String>['out.txt'],
      );

      expect(depfile1, equals(depfile2));
      expect(depfile1.hashCode, equals(depfile2.hashCode));
      expect(depfile1, isNot(equals(depfile3)));
      expect(depfile1.hashCode, isNot(equals(depfile3.hashCode)));
      expect(depfile1.toString(), contains('inputs: [in.txt]'));
      expect(depfile1.toString(), contains('outputs: [out.txt]'));
    });
  });
}
