// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of protobuf;

/// An object representing an extension field.
class Extension<T> extends FieldInfo<T> {
  final String extendee;

  Extension(this.extendee, String name, int tagNumber, int fieldType,
      {dynamic defaultOrMaker,
      CreateBuilderFunc? subBuilder,
      ValueOfFunc? valueOf,
      List<ProtobufEnum>? enumValues,
      String? protoName})
      : super(name, tagNumber, null, fieldType,
            defaultOrMaker: defaultOrMaker,
            subBuilder: subBuilder,
            valueOf: valueOf,
            enumValues: enumValues,
            protoName: protoName);

  Extension.repeated(this.extendee, String name, int tagNumber, int fieldType,
      {CheckFunc<T>? check,
      CreateBuilderFunc? subBuilder,
      ValueOfFunc? valueOf,
      List<ProtobufEnum>? enumValues,
      String? protoName})
      : super.repeated(name, tagNumber, null, fieldType, check, subBuilder,
            valueOf: valueOf, enumValues: enumValues, protoName: protoName);

  @override
  int get hashCode => extendee.hashCode * 31 + tagNumber;

  @override
  bool operator ==(other) {
    if (other is! Extension) return false;

    var o = other;
    return extendee == o.extendee && tagNumber == o.tagNumber;
  }
}
