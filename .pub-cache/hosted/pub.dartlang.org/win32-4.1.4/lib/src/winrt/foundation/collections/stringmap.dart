// stringmap.dart

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
import '../../internal/hstring_array.dart';
import 'iiterable.dart';
import 'iiterator.dart';
import 'ikeyvaluepair.dart';
import 'imap.dart';
import 'imapview.dart';
import 'iobservablemap.dart';

/// An associative collection, also known as a map or a dictionary.
///
/// {@category Class}
/// {@category winrt}
class StringMap extends IInspectable
    implements
        IMap<String, String>,
        IIterable<IKeyValuePair<String, String>>,
        IObservableMap<String, String> {
  StringMap() : super(ActivateClass(_className));
  StringMap.fromRawPointer(super.ptr);

  static const _className = 'Windows.Foundation.Collections.StringMap';

  // IMap<String, String> methods
  late final _iMap = IMap<String, String>.fromRawPointer(
      toInterface('{f6d1f700-49c2-52ae-8154-826f9908773c}'),
      iterableIid: '{e9bdaaf0-cbf6-5c72-be90-29cbf3a1319b}');

  @override
  String lookup(String key) => _iMap.lookup(key);

  @override
  int get size => _iMap.size;

  @override
  bool hasKey(String key) => _iMap.hasKey(key);

  @override
  Map<String, String> getView() => _iMap.getView();

  @override
  bool insert(String key, String value) => _iMap.insert(key, value);

  @override
  void remove(String key) => _iMap.remove(key);

  @override
  void clear() => _iMap.clear();

  @override
  IIterator<IKeyValuePair<String, String>> first() => _iMap.first();

  @override
  Map<String, String> toMap() => _iMap.toMap();

  // IObservableMap<String, String> methods
  late final _iObservableMap = IObservableMap<String, String>.fromRawPointer(
      toInterface('{1e036276-2f60-55f6-b7f3-f86079e6900b}'));

  @override
  int add_MapChanged(Pointer<NativeFunction<MapChangedEventHandler>> vhnd) =>
      _iObservableMap.add_MapChanged(vhnd);

  @override
  void remove_MapChanged(int token) => _iObservableMap.remove_MapChanged(token);
}
