// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../protoc.dart';

PbMixin? wellKnownMixinForFullName(String qualifiedName) =>
    _wellKnownMixins[qualifiedName];

const _wellKnownImportPath =
    'package:protobuf/src/protobuf/mixins/well_known.dart';

const _wellKnownMixins = {
  'google.protobuf.Any': PbMixin('AnyMixin',
      importFrom: _wellKnownImportPath,
      injectedHelpers: [
        '''
/// Creates a new [Any] encoding [message].
///
/// The [typeUrl] will be [typeUrlPrefix]/`fullName` where `fullName` is
/// the fully qualified name of the type of [message].
static Any pack($protobufImportPrefix.GeneratedMessage message,
{$coreImportPrefix.String typeUrlPrefix = 'type.googleapis.com'}) {
  final result = create();
  $mixinImportPrefix.AnyMixin.packIntoAny(result, message,
      typeUrlPrefix: typeUrlPrefix);
  return result;
}'''
      ],
      hasProto3JsonHelpers: true),
  'google.protobuf.Timestamp': PbMixin('TimestampMixin',
      importFrom: _wellKnownImportPath,
      injectedHelpers: [
        '''
/// Creates a new instance from [dateTime].
///
/// Time zone information will not be preserved.
static Timestamp fromDateTime($coreImportPrefix.DateTime dateTime) {
  final result = create();
  $mixinImportPrefix.TimestampMixin.setFromDateTime(result, dateTime);
  return result;
}'''
      ],
      hasProto3JsonHelpers: true),
  'google.protobuf.Duration': PbMixin(
    'DurationMixin',
    importFrom: _wellKnownImportPath,
    hasProto3JsonHelpers: true,
  ),
  'google.protobuf.Struct': PbMixin(
    'StructMixin',
    importFrom: _wellKnownImportPath,
    hasProto3JsonHelpers: true,
  ),
  'google.protobuf.Value': PbMixin(
    'ValueMixin',
    importFrom: _wellKnownImportPath,
    hasProto3JsonHelpers: true,
  ),
  'google.protobuf.ListValue': PbMixin(
    'ListValueMixin',
    importFrom: _wellKnownImportPath,
    hasProto3JsonHelpers: true,
  ),
  'google.protobuf.DoubleValue': PbMixin(
    'DoubleValueMixin',
    importFrom: _wellKnownImportPath,
    hasProto3JsonHelpers: true,
  ),
  'google.protobuf.FloatValue': PbMixin(
    'FloatValueMixin',
    importFrom: _wellKnownImportPath,
    hasProto3JsonHelpers: true,
  ),
  'google.protobuf.Int64Value': PbMixin(
    'Int64ValueMixin',
    importFrom: _wellKnownImportPath,
    hasProto3JsonHelpers: true,
  ),
  'google.protobuf.UInt64Value': PbMixin(
    'UInt64ValueMixin',
    importFrom: _wellKnownImportPath,
    hasProto3JsonHelpers: true,
  ),
  'google.protobuf.Int32Value': PbMixin(
    'Int32ValueMixin',
    importFrom: _wellKnownImportPath,
    hasProto3JsonHelpers: true,
  ),
  'google.protobuf.UInt32Value': PbMixin(
    'UInt32ValueMixin',
    importFrom: _wellKnownImportPath,
    hasProto3JsonHelpers: true,
  ),
  'google.protobuf.BoolValue': PbMixin(
    'BoolValueMixin',
    importFrom: _wellKnownImportPath,
    hasProto3JsonHelpers: true,
  ),
  'google.protobuf.StringValue': PbMixin(
    'StringValueMixin',
    importFrom: _wellKnownImportPath,
    hasProto3JsonHelpers: true,
  ),
  'google.protobuf.BytesValue': PbMixin(
    'BytesValueMixin',
    importFrom: _wellKnownImportPath,
    hasProto3JsonHelpers: true,
  ),
  'google.protobuf.FieldMask': PbMixin(
    'FieldMaskMixin',
    importFrom: _wellKnownImportPath,
    hasProto3JsonHelpers: true,
  )
};
