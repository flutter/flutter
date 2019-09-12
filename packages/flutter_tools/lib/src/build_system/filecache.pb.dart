// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

///
//  Generated code. Do not modify.
//  source: lib/src/build_system/filecache.proto
///
// ignore_for_file: camel_case_types,non_constant_identifier_names,library_prefixes,unused_import,unused_shown_name, sort_constructors_first

import 'dart:core' as $core show bool, Deprecated, double, int, List, Map, override, pragma, String, dynamic;

import 'package:protobuf/protobuf.dart' as $pb;

class FileHash extends $pb.GeneratedMessage {
  factory FileHash() => create();

  static final $pb.BuilderInfo _i = $pb.BuilderInfo('FileHash', package: const $pb.PackageName('flutter_tools'))
    ..aOS(1, 'path')
    ..aOS(2, 'hash')
    ..hasRequiredFields = false;

  FileHash._() : super();

  factory FileHash.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);

  factory FileHash.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  @$core.override
  FileHash clone() => FileHash()..mergeFromMessage(this);

  @$core.override
  FileHash copyWith(void Function(FileHash) updates) => super.copyWith(($core.dynamic message) => updates(message as FileHash));

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FileHash create() => FileHash._();

  // @$core.override
  FileHash createEmptyInstance() => create(); // ignore: annotate_overrides
  static $pb.PbList<FileHash> createRepeated() => $pb.PbList<FileHash>();
  static FileHash getDefault() => _defaultInstance ??= create()..freeze();
  static FileHash _defaultInstance;

  $core.String get path => $_getS(0, '');
  set path($core.String v) { $_setString(0, v); }
  $core.bool hasPath() => $_has(0);
  void clearPath() => clearField(1);

  $core.String get hash => $_getS(1, '');
  set hash($core.String v) { $_setString(1, v); }
  $core.bool hasHash() => $_has(1);
  void clearHash() => clearField(2);
}

class FileStorage extends $pb.GeneratedMessage {
  factory FileStorage() => create();
  static final $pb.BuilderInfo _i = $pb.BuilderInfo('FileHashStore', package: const $pb.PackageName('flutter_tools'))
    ..a<$core.int>(1, 'version', $pb.PbFieldType.O3)
    ..pc<FileHash>(2, 'files', $pb.PbFieldType.PM,FileHash.create)
    ..hasRequiredFields = false;

  FileStorage._() : super();
  factory FileStorage.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory FileStorage.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  @$core.override
  FileStorage clone() => FileStorage()..mergeFromMessage(this);

  @$core.override
  FileStorage copyWith(void Function(FileStorage) updates) => super.copyWith(($core.dynamic message) => updates(message as FileStorage));

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FileStorage create() => FileStorage._();

  // @$core.override
  FileStorage createEmptyInstance() => create(); // ignore: annotate_overrides

  static $pb.PbList<FileStorage> createRepeated() => $pb.PbList<FileStorage>();

  static FileStorage getDefault() => _defaultInstance ??= create()..freeze();

  static FileStorage _defaultInstance;

  $core.int get version => $_get(0, 0);
  set version($core.int v) { $_setSignedInt32(0, v); }
  $core.bool hasVersion() => $_has(0);
  void clearVersion() => clearField(1);

  $core.List<FileHash> get files => $_getList(1);
}
