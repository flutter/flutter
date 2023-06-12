// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/src/lint/project.dart';
import 'package:test/test.dart';

main() {
//  defineTests();
}

defineTests() {
  group('project', () {
    group('basic', () {
      // TODO(brianwilkerson) These tests fail on the bots because the cwd is
      // not the same there as when we run tests locally.
      group('cwd', () async {
        var project = await DartProject.create(_AnalysisSessionMock(), []);
        test('name', () {
          expect(project.name, 'analyzer');
        });
        test('spec', () {
          expect(project.pubspec, isNotNull);
        });
        test('root', () {
          expect(project.root.path, Directory.current.path);
        });
      });
      // TODO(brianwilkerson) Rewrite these to use a memory resource provider.
//      group('p1', () {
//        var project =
//            new DartProject(null, null, dir: new Directory('test/_data/p1'));
//        test('name', () {
//          expect(project.name, 'p1');
//        });
//        test('spec', () {
//          expect(project.pubspec, isNotNull);
//          expect(project.pubspec.name.value.text, 'p1');
//        });
//        test('root', () {
//          expect(project.root.path, 'test/_data/p1');
//        });
//      });
//      group('no pubspec', () {
//        var project = new DartProject(null, null,
//            dir: new Directory('test/_data/p1/src'));
//        test('name', () {
//          expect(project.name, 'src');
//        });
//        test('spec', () {
//          expect(project.pubspec, isNull);
//        });
//        test('root', () {
//          expect(project.root.path, 'test/_data/p1/src');
//        });
//      });
    });
  });
}

class _AnalysisSessionMock implements AnalysisSession {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
