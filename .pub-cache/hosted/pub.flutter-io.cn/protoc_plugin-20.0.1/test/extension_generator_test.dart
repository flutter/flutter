#!/usr/bin/env dart
// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:protoc_plugin/indenting_writer.dart';
import 'package:protoc_plugin/protoc.dart';
import 'package:protoc_plugin/src/generated/descriptor.pb.dart' as pb;
import 'package:protoc_plugin/src/generated/plugin.pb.dart' as pb;
import 'package:protoc_plugin/src/linker.dart';
import 'package:protoc_plugin/src/options.dart';
import 'package:test/test.dart';

import 'golden_file.dart';

void main() {
  test('testExtensionGenerator', () {
    final extensionFieldDescriptor = pb.FieldDescriptorProto()
      ..name = 'client_info'
      ..jsonName = 'clientInfo'
      ..number = 261486461
      ..label = pb.FieldDescriptorProto_Label.LABEL_OPTIONAL
      ..type = pb.FieldDescriptorProto_Type.TYPE_STRING
      ..extendee = '.Card';
    final messageDescriptor = pb.DescriptorProto()
      ..name = 'Card'
      ..extension.add(extensionFieldDescriptor);
    final fileDescriptor = pb.FileDescriptorProto()
      ..messageType.add(messageDescriptor)
      ..extension.add(extensionFieldDescriptor);

    final fileGenerator = FileGenerator(fileDescriptor, GenerationOptions());
    final options = parseGenerationOptions(
        pb.CodeGeneratorRequest(), pb.CodeGeneratorResponse());
    link(options, [fileGenerator]);
    final writer = IndentingWriter(filename: 'sample.proto');
    fileGenerator.extensionGenerators.single.generate(writer);

    expectMatchesGoldenFile(writer.toString(), 'test/goldens/extension');
    expectMatchesGoldenFile(
        writer.sourceLocationInfo.toString(), 'test/goldens/extension.meta');
  });
}
