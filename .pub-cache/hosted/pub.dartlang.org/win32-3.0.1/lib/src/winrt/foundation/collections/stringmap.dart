// stringmap.dart

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
const IID_StringMap = '{CD1492C1-0CB1-4612-A886-3794553FD14A}';

/// An associative collection, also known as a map or a dictionary.
///
/// {@category Class}
/// {@category winrt}
class StringMap extends IInspectable implements IMap<String, String?> {
  StringMap({Allocator allocator = calloc})
      : super(ActivateClass(_className, allocator: allocator));
  StringMap.fromRawPointer(super.ptr);

  static const _className = 'Windows.Foundation.Collections.StringMap';

  late final _iMap =
      IMap<String, String?>.fromRawPointer(toInterface(IID_IMap_String_String));

  @override
  void clear() => _iMap.clear();

  @override
  IIterator<IKeyValuePair<String, String?>> first() => _iMap.first();

  @override
  Map<String, String?> getView() => _iMap.getView();

  @override
  bool hasKey(String value) => _iMap.hasKey(value);

  @override
  bool insert(String key, String? value) => _iMap.insert(key, value);

  @override
  String? lookup(String key) => _iMap.lookup(key);

  @override
  void remove(String key) => _iMap.remove(key);

  @override
  int get size => _iMap.size;

  @override
  Map<String, String?> toMap() => _iMap.toMap();
}
