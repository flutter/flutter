// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of protobuf;

/// Modifies a GeneratedMessage so that it's read-only.
abstract class ReadonlyMessageMixin {
  BuilderInfo get info_;

  void addExtension(Extension extension, var value) =>
      _readonly('addExtension');

  void clear() => _readonly('clear');

  void clearExtension(Extension extension) => _readonly('clearExtension');

  void clearField(int tagNumber) => _readonly('clearField');

  List<T>? createRepeatedField<T>(int tagNumber, FieldInfo<T> fi) {
    _readonly('createRepeatedField');
    return null; // not reached
  }

  void mergeFromBuffer(List<int> input,
          [ExtensionRegistry extensionRegistry = ExtensionRegistry.EMPTY]) =>
      _readonly('mergeFromBuffer');

  void mergeFromCodedBufferReader(CodedBufferReader input,
          [ExtensionRegistry extensionRegistry = ExtensionRegistry.EMPTY]) =>
      _readonly('mergeFromCodedBufferReader');

  void mergeFromJson(String data,
          [ExtensionRegistry extensionRegistry = ExtensionRegistry.EMPTY]) =>
      _readonly('mergeFromJson');

  void mergeFromJsonMap(Map<String, dynamic> json,
          [ExtensionRegistry extensionRegistry = ExtensionRegistry.EMPTY]) =>
      _readonly('mergeFromJsonMap');

  void mergeFromMessage(GeneratedMessage other) =>
      _readonly('mergeFromMessage');

  void mergeUnknownFields(UnknownFieldSet unknownFieldSet) =>
      _readonly('mergeUnknownFields');

  void setExtension(Extension extension, var value) =>
      _readonly('setExtension');

  void setField(int tagNumber, var value, [int? fieldType]) =>
      _readonly('setField');

  void _readonly(String methodName) {
    var messageType = info_.qualifiedMessageName;
    frozenMessageModificationHandler(messageType, methodName);
  }
}
