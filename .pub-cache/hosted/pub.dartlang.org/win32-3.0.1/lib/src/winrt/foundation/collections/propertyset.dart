// propertyset.dart

// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../../com/iinspectable.dart';
import '../../../winrt_constants.dart';
import '../../../winrt_helpers.dart';
import 'iiterator.dart';
import 'ikeyvaluepair.dart';
import 'imap.dart';

/// @nodoc
const IID_PropertySet = '{D0204E8D-5F1D-4F95-A6E2-BE7B29830342}';

/// Represents a property set, which is a set of `PropertyValue` objects with
/// string keys.
///
/// {@category Class}
/// {@category winrt}
class PropertySet extends IInspectable implements IMap<String, Object?> {
  PropertySet({Allocator allocator = calloc})
      : super(ActivateClass(_className, allocator: allocator));
  PropertySet.fromRawPointer(super.ptr);

  static const _className = 'Windows.Foundation.Collections.PropertySet';

  late final _iMap =
      IMap<String, Object?>.fromRawPointer(toInterface(IID_IMap_String_Object));

  @override
  void clear() => _iMap.clear();

  @override
  IIterator<IKeyValuePair<String, Object?>> first() => _iMap.first();

  @override
  Map<String, Object?> getView() => _iMap.getView();

  @override
  bool hasKey(String value) => _iMap.hasKey(value);

  @override
  bool insert(String key, Object? value) => _iMap.insert(key, value);

  @override
  Object? lookup(String key) => _iMap.lookup(key);

  @override
  void remove(String key) => _iMap.remove(key);

  @override
  int get size => _iMap.size;

  @override
  Map<String, Object?> toMap() => _iMap.toMap();
}
