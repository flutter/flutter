#!/usr/bin/env dart
// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:protoc_plugin/indenting_writer.dart';
import 'package:protoc_plugin/protoc.dart';
import 'package:protoc_plugin/src/linker.dart';
import 'package:protoc_plugin/src/options.dart';
import 'package:test/test.dart';

import 'golden_file.dart';
import 'service_util.dart';

void main() {
  test('testServiceGenerator', () {
    var options = GenerationOptions();
    var fd = buildFileDescriptor(
        'testpkg', 'testpkg.proto', ['SomeRequest', 'SomeReply']);
    fd.service.add(buildServiceDescriptor());
    var fg = FileGenerator(fd, options);

    var fd2 = buildFileDescriptor(
        'foo.bar', 'foobar.proto', ['EmptyMessage', 'AnotherReply']);
    var fg2 = FileGenerator(fd2, options);

    link(GenerationOptions(), [fg, fg2]);

    var serviceWriter = IndentingWriter();
    fg.serviceGenerators[0].generate(serviceWriter);
    expectMatchesGoldenFile(
        serviceWriter.toString(), 'test/goldens/serviceGenerator');
    expectMatchesGoldenFile(
        fg.generateJsonFile(), 'test/goldens/serviceGenerator.pb.json');
  });
}
