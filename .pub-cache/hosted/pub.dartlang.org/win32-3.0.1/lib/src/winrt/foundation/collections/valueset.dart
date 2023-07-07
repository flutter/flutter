// valueset.dart

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
const IID_ValueSet = '{DC7B347D-F2AB-42F7-A191-ECA055FD02AC}';

/// Implements a map with keys of type `String` and values of type `Object`.
///
/// `Object` must be a WinRT `PropertyValue` or `ValueSet`.
///
/// As a `PropertyValue`, it can be any type except
/// `PropertyType.InspectableArray`. This limitation exists to ensure that the
/// value can be serialized; passed by value accoss a process boundary.
///
/// {@category Class}
/// {@category winrt}
class ValueSet extends IInspectable implements IMap<String, Object?> {
  ValueSet({Allocator allocator = calloc})
      : super(ActivateClass(_className, allocator: allocator));
  ValueSet.fromRawPointer(super.ptr);

  static const _className = 'Windows.Foundation.Collections.ValueSet';

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
