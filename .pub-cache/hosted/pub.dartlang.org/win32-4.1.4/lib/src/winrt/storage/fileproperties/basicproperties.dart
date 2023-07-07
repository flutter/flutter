// basicproperties.dart

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// ignore_for_file: unused_import
// ignore_for_file: constant_identifier_names, non_constant_identifier_names
// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../../com/iinspectable.dart';
import '../../../combase.dart';
import '../../../exceptions.dart';
import '../../../macros.dart';
import '../../../types.dart';
import '../../../utils.dart';
import '../../../win32/api_ms_win_core_winrt_string_l1_1_0.g.dart';
import '../../../winrt_callbacks.dart';
import '../../../winrt_helpers.dart';
import '../../foundation/collections/iiterable.dart';
import '../../foundation/collections/ikeyvaluepair.dart';
import '../../foundation/collections/imap.dart';
import '../../foundation/iasyncaction.dart';
import '../../foundation/iasyncoperation.dart';
import '../../internal/hstring_array.dart';
import 'ibasicproperties.dart';
import 'istorageitemextraproperties.dart';

/// Provides access to the basic properties, like the size of the item or
/// the date the item was last modified, of the item (like a file or
/// folder).
///
/// {@category Class}
/// {@category winrt}
class BasicProperties extends IInspectable
    implements IBasicProperties, IStorageItemExtraProperties {
  BasicProperties.fromRawPointer(super.ptr);

  // IBasicProperties methods
  late final _iBasicProperties = IBasicProperties.from(this);

  @override
  int get size => _iBasicProperties.size;

  @override
  DateTime get dateModified => _iBasicProperties.dateModified;

  @override
  DateTime get itemDate => _iBasicProperties.itemDate;

  // IStorageItemExtraProperties methods
  late final _iStorageItemExtraProperties =
      IStorageItemExtraProperties.from(this);

  @override
  Future<IMap<String, Object?>> retrievePropertiesAsync(
          IIterable<String>? propertiesToRetrieve) =>
      _iStorageItemExtraProperties
          .retrievePropertiesAsync(propertiesToRetrieve);

  @override
  Future<void> savePropertiesAsync(
          IIterable<IKeyValuePair<String, Object?>>? propertiesToSave) =>
      _iStorageItemExtraProperties.savePropertiesAsync(propertiesToSave);

  @override
  Future<void> savePropertiesAsyncOverloadDefault() =>
      _iStorageItemExtraProperties.savePropertiesAsyncOverloadDefault();
}
