// Copyright 2013 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

library quiver.patttern.glob_test;

import 'package:quiver/pattern.dart';
import 'package:test/test.dart';

void main() {
  group('Glob', () {
    test('should match "*" against sequences of word chars', () {
      expectGlob('*.html', matches: [
        'a.html',
        '_-\a.html',
        r'^$*?.html',
        '()[]{}.html',
        '↭.html',
        '\u21ad.html',
        '♥.html',
        '\u2665.html'
      ], nonMatches: [
        'a.htm',
        'a.htmlx',
        '/a.html'
      ]);
      expectGlob('foo.*',
          matches: ['foo.html'],
          nonMatches: ['afoo.html', 'foo/a.html', 'foo.html/a']);
    });

    test('should match "**" against paths', () {
      expectGlob('**/*.html',
          matches: ['/a.html', 'a/b.html', 'a/b/c.html', 'a/b/c.html/d.html'],
          nonMatches: ['a.html', 'a/b.html/c']);
    });

    test('should match "?" a single word char', () {
      expectGlob('a?',
          matches: ['ab', 'a?', 'a↭', 'a\u21ad', 'a\\'],
          nonMatches: ['a', 'abc']);
    });
  });
}

void expectGlob(String pattern,
    {List<String> matches = const [], List<String> nonMatches = const []}) {
  var glob = Glob(pattern);
  for (final str in matches) {
    expect(glob.hasMatch(str), true);
    expect(glob.allMatches(str).map((m) => m.input), [str]);
    Match match = glob.matchAsPrefix(str)!;
    expect(match.start, 0);
    expect(match.end, str.length);
  }
  for (final str in nonMatches) {
    expect(glob.hasMatch(str), false);
    var m = List.from(glob.allMatches(str));
    expect(m.length, 0);
    expect(glob.matchAsPrefix(str), null);
  }
}
