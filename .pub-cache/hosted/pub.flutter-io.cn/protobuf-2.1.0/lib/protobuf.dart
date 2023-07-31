// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library protobuf;

import 'dart:collection' show ListBase, MapBase;
import 'dart:convert'
    show base64Decode, base64Encode, jsonEncode, jsonDecode, Utf8Codec;
import 'dart:math' as math;
import 'dart:typed_data' show TypedData, Uint8List, ByteData, Endian;

import 'package:fixnum/fixnum.dart' show Int64;
import 'package:meta/meta.dart' show UseResult;

import 'src/protobuf/json_parsing_context.dart';
import 'src/protobuf/permissive_compare.dart';
import 'src/protobuf/type_registry.dart';
export 'src/protobuf/type_registry.dart' show TypeRegistry;

part 'src/protobuf/coded_buffer.dart';
part 'src/protobuf/coded_buffer_reader.dart';
part 'src/protobuf/coded_buffer_writer.dart';
part 'src/protobuf/consts.dart';
part 'src/protobuf/builder_info.dart';
part 'src/protobuf/event_plugin.dart';
part 'src/protobuf/exceptions.dart';
part 'src/protobuf/extension.dart';
part 'src/protobuf/extension_field_set.dart';
part 'src/protobuf/extension_registry.dart';
part 'src/protobuf/field_error.dart';
part 'src/protobuf/field_info.dart';
part 'src/protobuf/field_set.dart';
part 'src/protobuf/field_type.dart';
part 'src/protobuf/generated_message.dart';
part 'src/protobuf/generated_service.dart';
part 'src/protobuf/json.dart';
part 'src/protobuf/pb_list.dart';
part 'src/protobuf/pb_map.dart';
part 'src/protobuf/protobuf_enum.dart';
part 'src/protobuf/proto3_json.dart';
part 'src/protobuf/readonly_message.dart';
part 'src/protobuf/rpc_client.dart';
part 'src/protobuf/unknown_field_set.dart';
part 'src/protobuf/utils.dart';
part 'src/protobuf/unpack.dart';
part 'src/protobuf/wire_format.dart';

// TODO(sra): Use Int64.parse() when available - see http://dartbug.com/21915.
Int64 parseLongInt(String text) {
  if (text.startsWith('0x')) return Int64.parseHex(text.substring(2));
  if (text.startsWith('+0x')) return Int64.parseHex(text.substring(3));
  if (text.startsWith('-0x')) return -Int64.parseHex(text.substring(3));
  return Int64.parseInt(text);
}

const _utf8 = Utf8Codec(allowMalformed: true);
