// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:protobuf/protobuf.dart';
import 'package:protoc_plugin/src/generated/descriptor.pb.dart';
import 'package:test/test.dart';

import '../out/protos/custom_option.pb.dart';
import '../out/protos/custom_option.pbjson.dart';
import '../out/protos/google/protobuf/unittest.pbjson.dart';

void main() {
  test('Can decode message descriptor', () {
    final descriptor = DescriptorProto.fromBuffer(testAllTypesDescriptor);
    expect(descriptor.name, 'TestAllTypes');
    final nestedEnumDescriptor = descriptor.enumType.first;
    expect(nestedEnumDescriptor.name, 'NestedEnum');
  });
  test('Can decode enum descriptor', () {
    final descriptor = EnumDescriptorProto.fromBuffer(foreignEnumDescriptor);
    expect(descriptor.name, 'ForeignEnum');
    expect(descriptor.value.map((v) => v.name),
        ['FOREIGN_FOO', 'FOREIGN_BAR', 'FOREIGN_BAZ']);
  });
  test('Can decode service descriptor', () {
    final descriptor = ServiceDescriptorProto.fromBuffer(testServiceDescriptor);
    expect(descriptor.name, 'TestService');
    expect(descriptor.method.map((m) => m.name), ['Foo', 'Bar']);
  });
  test('Can read custom options', () {
    final registry = ExtensionRegistry()..add(Custom_option.myOption);
    final descriptor =
        DescriptorProto.fromBuffer(myMessageDescriptor, registry);
    final option = descriptor.options.getExtension(Custom_option.myOption);
    expect(option, 'Hello world!');
  });
}
