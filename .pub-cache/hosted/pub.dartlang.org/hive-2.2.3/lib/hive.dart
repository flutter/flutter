/// Hive is a lightweight and blazing fast key-value store written in pure Dart.
/// It is strongly encrypted using AES-256.
library hive;

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:hive/src/box/default_compaction_strategy.dart';
import 'package:hive/src/box/default_key_comparator.dart';
import 'package:hive/src/crypto/aes_cbc_pkcs7.dart';
import 'package:hive/src/crypto/crc32.dart';
import 'package:hive/src/hive_impl.dart';
import 'package:hive/src/object/hive_list_impl.dart';
import 'package:hive/src/object/hive_object.dart';
import 'package:hive/src/util/extensions.dart';
import 'package:meta/meta.dart';

export 'src/box_collection/box_collection_stub.dart'
    if (dart.library.html) 'package:hive/src/box_collection/box_collection_indexed_db.dart'
    if (dart.library.io) 'package:hive/src/box_collection/box_collection.dart';
export 'src/object/hive_object.dart' show HiveObject, HiveObjectMixin;

part 'src/annotations/hive_field.dart';
part 'src/annotations/hive_type.dart';
part 'src/binary/binary_reader.dart';
part 'src/binary/binary_writer.dart';
part 'src/box/box.dart';
part 'src/box/box_base.dart';
part 'src/box/lazy_box.dart';
part 'src/crypto/hive_aes_cipher.dart';
part 'src/crypto/hive_cipher.dart';
part 'src/hive.dart';
part 'src/hive_error.dart';
part 'src/object/hive_collection.dart';
part 'src/object/hive_list.dart';
part 'src/object/hive_storage_backend_preference.dart';
part 'src/registry/type_adapter.dart';
part 'src/registry/type_registry.dart';

/// Global constant to access Hive.
// ignore: non_constant_identifier_names
final HiveInterface Hive = HiveImpl();
