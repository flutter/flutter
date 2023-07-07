// ipropertyset.dart

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
import 'iobservablemap.dart';

/// @nodoc
const IID_IPropertySet = '{8a43ed9f-f4e6-4421-acf9-1dab2986820c}';

/// Represents a collection of key-value pairs, correlating several other
/// collection interfaces.
///
/// {@category Interface}
/// {@category winrt}
class IPropertySet extends IInspectable
    implements
        IObservableMap<String, Object?>,
        IMap<String, Object?>,
        IIterable<IKeyValuePair<String, Object?>> {
  // vtable begins at 6, is 0 entries long.
  IPropertySet.fromRawPointer(super.ptr);

  factory IPropertySet.from(IInspectable interface) =>
      IPropertySet.fromRawPointer(interface.toInterface(IID_IPropertySet));

  // IObservableMap<String, Object?> methods
  late final _iObservableMap = IObservableMap<String, Object?>.fromRawPointer(
      toInterface('{236aac9d-fb12-5c4d-a41c-9e445fb4d7ec}'));

  @override
  int add_MapChanged(Pointer<NativeFunction<MapChangedEventHandler>> vhnd) =>
      _iObservableMap.add_MapChanged(vhnd);

  @override
  void remove_MapChanged(int token) => _iObservableMap.remove_MapChanged(token);

  // IMap<String, Object?> methods
  late final _iMap = IMap<String, Object?>.fromRawPointer(
      toInterface('{1b0d3570-0877-5ec2-8a2c-3b9539506aca}'),
      iterableIid: '{fe2f3d47-5d47-5499-8374-430c7cda0204}');

  @override
  Object? lookup(String key) => _iMap.lookup(key);

  @override
  int get size => _iMap.size;

  @override
  bool hasKey(String key) => _iMap.hasKey(key);

  @override
  Map<String, Object?> getView() => _iMap.getView();

  @override
  bool insert(String key, Object? value) => _iMap.insert(key, value);

  @override
  void remove(String key) => _iMap.remove(key);

  @override
  void clear() => _iMap.clear();

  @override
  IIterator<IKeyValuePair<String, Object?>> first() => _iMap.first();

  @override
  Map<String, Object?> toMap() => _iMap.toMap();
}
