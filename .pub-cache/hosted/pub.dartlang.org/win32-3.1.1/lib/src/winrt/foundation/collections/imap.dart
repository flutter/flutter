// imap.dart

// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../../com/iinspectable.dart';
import '../../../combase.dart';
import '../../../exceptions.dart';
import '../../../guid.dart';
import '../../../macros.dart';
import '../../../types.dart';
import '../../../utils.dart';
import '../../../win32/api_ms_win_core_winrt_string_l1_1_0.g.dart';
import '../../../winrt_helpers.dart';
import '../../devices/sensors/enums.g.dart';
import '../../devices/sensors/pedometerstepkind_helpers.dart';
import '../../internal/ipropertyvalue_helpers.dart';
import '../../internal/map_helpers.dart';
import '../../media/mediaproperties/mediapropertyset.dart';
import '../ipropertyvalue.dart';
import '../winrt_enum.dart';
import 'iiterable.dart';
import 'iiterator.dart';
import 'ikeyvaluepair.dart';
import 'imapview.dart';
import 'propertyset.dart';
import 'stringmap.dart';

/// Represents an associative collection, also known as a map or a dictionary.
///
/// {@category Interface}
/// {@category winrt}
class IMap<K, V> extends IInspectable
    implements IIterable<IKeyValuePair<K, V>> {
  // vtable begins at 6, is 7 entries long.
  late final IKeyValuePair<K, V> Function(Pointer<COMObject>) _iterableCreator;
  final V Function(Pointer<COMObject>)? _creator;
  final V Function(int)? _enumCreator;

  /// Creates an empty [IMap].
  ///
  /// [K] must be of type `GUID` or `String` and [V] must be of type
  /// `Object?` or `String?`.
  factory IMap() {
    if (isSameType<K, GUID>() && isSimilarType<V, Object>()) {
      return IMap.fromRawPointer(MediaPropertySet().ptr);
    }

    if (isSameType<K, String>()) {
      if (isSimilarType<V, String>()) {
        return IMap.fromRawPointer(StringMap().ptr);
      }

      if (isSimilarType<V, Object>()) {
        return IMap.fromRawPointer(PropertySet().ptr);
      }
    }

    throw ArgumentError('Unsupported key-value pair: IMap<$K, $V>');
  }

  /// Creates an instance of [IMap] using the given [ptr].
  ///
  /// [K] must be of type `GUID`, `int`, `Object`, `String`, or `WinRTEnum`
  /// (e.g. `PedometerStepKind`).
  ///
  /// [V] must be of type `Object`, `String`, or `WinRT` (e.g. `IJsonValue`,
  /// `ProductLicense`).
  ///
  /// [creator] must be specified if [V] is a `WinRT` type.
  /// ```dart
  /// final map = IMap<String, IJsonValue?>.fromRawPointer(ptr,
  ///     creator: IJsonValue.fromRawPointer);
  /// ```
  ///
  /// [enumCreator] must be specified if [V] is a `WinRTEnum` type.
  /// ```dart
  /// final map = IMap<String, ChatMessageStatus?>.fromRawPointer(ptr,
  ///     enumCreator: ChatMessageStatus.from);
  /// ```
  IMap.fromRawPointer(
    super.ptr, {
    V Function(Pointer<COMObject>)? creator,
    V Function(int)? enumCreator,
  })  : _creator = creator,
        _enumCreator = enumCreator {
    if (!isSupportedKeyValuePair<K, V>()) {
      throw ArgumentError('Unsupported key-value pair: IMap<$K, $V>');
    }

    if (isSubtypeOfInspectable<V>() && creator == null) {
      throw ArgumentError.notNull('creator');
    }

    if (isSubtypeOfWinRTEnum<V>() && enumCreator == null) {
      throw ArgumentError.notNull('enumCreator');
    }

    _iterableCreator = (Pointer<COMObject> ptr) => IKeyValuePair.fromRawPointer(
        ptr,
        creator: _creator,
        enumCreator: _enumCreator);
  }

  /// Creates an [IMap] with the same keys and values as [other].
  ///
  /// [other] must be of type `Map<GUID, Object?>`, `Map<String, Object?>`,
  /// or `Map<String, String?>`.
  factory IMap.fromMap(Map<K, V> other) {
    if (isSameType<K, GUID>() && isSimilarType<V, Object>()) {
      final iMap = MediaPropertySet();
      other.cast<GUID, Object?>().forEach(iMap.insert);
      return IMap.fromRawPointer(iMap.ptr);
    }

    if (isSameType<K, String>()) {
      if (isSimilarType<V, String>()) {
        final iMap = StringMap();
        other.cast<String, String?>().forEach(iMap.insert);
        return IMap.fromRawPointer(iMap.ptr);
      }

      if (isSimilarType<V, Object>()) {
        final iMap = PropertySet();
        other.cast<String, Object?>().forEach(iMap.insert);
        return IMap.fromRawPointer(iMap.ptr);
      }
    }

    throw ArgumentError.value(other, 'other', 'Unsupported map');
  }

  /// Returns the item at the specified key in the map.
  V lookup(K key) {
    if (isSameType<K, GUID>()) {
      if (isSubtypeOfInspectable<V>()) {
        return _lookup_GUID_COMObject(key as GUID);
      }

      return _lookup_GUID_Object(key as GUID) as V;
    }

    if (isSameType<K, int>()) {
      return _lookup_Uint32_COMObject(key as int);
    }

    if (isSameType<K, PedometerStepKind>()) {
      return lookupByPedometerStepKind(key as PedometerStepKind) as V;
    }

    if (isSameType<K, String>()) {
      if (isSimilarType<V, String>()) {
        return _lookup_String_String(key as String) as V;
      }

      if (isSubtypeOfInspectable<V>()) {
        return _lookup_String_COMObject(key as String);
      }

      if (isSubtypeOfWinRTEnum<V>()) {
        return _lookup_String_enum(key as String);
      }

      return _lookup_String_Object(key as String) as V;
    }

    return _lookup_Object_Object(key as IInspectable) as V;
  }

  V _lookup_GUID_COMObject(GUID key) {
    final retValuePtr = calloc<COMObject>();

    final hr = ptr.ref.lpVtbl.value
            .elementAt(6)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(Pointer, GUID, Pointer<COMObject>)>>>()
            .value
            .asFunction<int Function(Pointer, GUID, Pointer<COMObject>)>()(
        ptr.ref.lpVtbl, key, retValuePtr);

    if (FAILED(hr)) {
      free(retValuePtr);
      throw WindowsException(hr);
    }

    return _creator!(retValuePtr);
  }

  Object? _lookup_GUID_Object(GUID key) {
    final retValuePtr = calloc<COMObject>();

    final hr = ptr.ref.lpVtbl.value
            .elementAt(6)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(Pointer, GUID, Pointer<COMObject>)>>>()
            .value
            .asFunction<int Function(Pointer, GUID, Pointer<COMObject>)>()(
        ptr.ref.lpVtbl, key, retValuePtr);

    if (FAILED(hr)) {
      free(retValuePtr);
      throw WindowsException(hr);
    }

    return IPropertyValue.fromRawPointer(retValuePtr).value;
  }

  V _lookup_Uint32_COMObject(int key) {
    final retValuePtr = calloc<COMObject>();

    final hr =
        ptr.ref.lpVtbl.value
                .elementAt(6)
                .cast<
                    Pointer<
                        NativeFunction<
                            HRESULT Function(
                                Pointer, Uint32, Pointer<COMObject>)>>>()
                .value
                .asFunction<int Function(Pointer, int, Pointer<COMObject>)>()(
            ptr.ref.lpVtbl, key, retValuePtr);

    if (FAILED(hr)) {
      free(retValuePtr);
      throw WindowsException(hr);
    }

    return _creator!(retValuePtr);
  }

  Object? _lookup_Object_Object(IInspectable key) {
    final retValuePtr = calloc<COMObject>();

    final hr = ptr.ref.lpVtbl.value
            .elementAt(6)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(
                            Pointer, COMObject, Pointer<COMObject>)>>>()
            .value
            .asFunction<int Function(Pointer, COMObject, Pointer<COMObject>)>()(
        ptr.ref.lpVtbl, key.ptr.ref, retValuePtr);

    if (FAILED(hr)) {
      free(retValuePtr);
      throw WindowsException(hr);
    }

    return IPropertyValue.fromRawPointer(retValuePtr).value;
  }

  V _lookup_String_COMObject(String key) {
    final retValuePtr = calloc<COMObject>();
    final hKey = convertToHString(key);

    try {
      final hr = ptr.ref.lpVtbl.value
              .elementAt(6)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(
                              Pointer, HSTRING, Pointer<COMObject>)>>>()
              .value
              .asFunction<int Function(Pointer, int, Pointer<COMObject>)>()(
          ptr.ref.lpVtbl, hKey, retValuePtr);

      if (FAILED(hr)) {
        free(retValuePtr);
        throw WindowsException(hr);
      }

      return _creator!(retValuePtr);
    } finally {
      WindowsDeleteString(hKey);
    }
  }

  V _lookup_String_enum(String key) {
    final retValuePtr = calloc<Int32>();
    final hKey = convertToHString(key);

    try {
      final hr =
          ptr.ref.lpVtbl.value
                  .elementAt(6)
                  .cast<
                      Pointer<
                          NativeFunction<
                              HRESULT Function(
                                  Pointer, HSTRING, Pointer<Int32>)>>>()
                  .value
                  .asFunction<int Function(Pointer, int, Pointer<Int32>)>()(
              ptr.ref.lpVtbl, hKey, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return _enumCreator!(retValuePtr.value);
    } finally {
      WindowsDeleteString(hKey);
      free(retValuePtr);
    }
  }

  Object? _lookup_String_Object(String key) {
    final retValuePtr = calloc<COMObject>();
    final hKey = convertToHString(key);

    try {
      final hr = ptr.ref.lpVtbl.value
              .elementAt(6)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(
                              Pointer, HSTRING, Pointer<COMObject>)>>>()
              .value
              .asFunction<int Function(Pointer, int, Pointer<COMObject>)>()(
          ptr.ref.lpVtbl, hKey, retValuePtr);

      if (FAILED(hr)) {
        free(retValuePtr);
        throw WindowsException(hr);
      }

      return IPropertyValue.fromRawPointer(retValuePtr).value;
    } finally {
      WindowsDeleteString(hKey);
    }
  }

  String? _lookup_String_String(String key) {
    final retValuePtr = calloc<HSTRING>();
    final hKey = convertToHString(key);

    try {
      final hr =
          ptr.ref.lpVtbl.value
                  .elementAt(6)
                  .cast<
                      Pointer<
                          NativeFunction<
                              HRESULT Function(
                                  Pointer, HSTRING, Pointer<HSTRING>)>>>()
                  .value
                  .asFunction<int Function(Pointer, int, Pointer<HSTRING>)>()(
              ptr.ref.lpVtbl, hKey, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      if (retValuePtr.value == 0) return null;

      final retValue = retValuePtr.toDartString();
      return retValue;
    } finally {
      WindowsDeleteString(hKey);
      WindowsDeleteString(retValuePtr.value);
      free(retValuePtr);
    }
  }

  /// Gets the number of items in the map.
  int get size {
    final retValuePtr = calloc<Uint32>();

    try {
      final hr = ptr.ref.lpVtbl.value
          .elementAt(7)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Uint32>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Uint32>)>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return retValuePtr.value;
    } finally {
      free(retValuePtr);
    }
  }

  /// Determines whether the map contains the specified key.
  bool hasKey(K value) {
    if (isSameType<K, GUID>()) return _hasKey_GUID(value as GUID);
    if (isSameType<K, int>()) return _hasKey_Uint32(value as int);
    if (isSameType<K, PedometerStepKind>()) {
      return hasKeyByPedometerStepKind(value as PedometerStepKind);
    }
    if (isSameType<K, String>()) return _hasKey_String(value as String);

    return _hasKey_Object(value as IInspectable);
  }

  bool _hasKey_GUID(GUID value) {
    final retValuePtr = calloc<Bool>();

    try {
      final hr = ptr.ref.lpVtbl.value
              .elementAt(8)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(Pointer, GUID, Pointer<Bool>)>>>()
              .value
              .asFunction<int Function(Pointer, GUID, Pointer<Bool>)>()(
          ptr.ref.lpVtbl, value, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return retValuePtr.value;
    } finally {
      free(retValuePtr);
    }
  }

  bool _hasKey_Uint32(int value) {
    final retValuePtr = calloc<Bool>();

    try {
      final hr = ptr.ref.lpVtbl.value
              .elementAt(8)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(Pointer, Uint32, Pointer<Bool>)>>>()
              .value
              .asFunction<int Function(Pointer, int, Pointer<Bool>)>()(
          ptr.ref.lpVtbl, value, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return retValuePtr.value;
    } finally {
      free(retValuePtr);
    }
  }

  bool _hasKey_Object(IInspectable value) {
    final retValuePtr = calloc<Bool>();

    try {
      final hr = ptr.ref.lpVtbl.value
          .elementAt(8)
          .cast<
              Pointer<
                  NativeFunction<
                      HRESULT Function(Pointer, COMObject, Pointer<Bool>)>>>()
          .value
          .asFunction<
              int Function(Pointer, COMObject,
                  Pointer<Bool>)>()(ptr.ref.lpVtbl, value.ptr.ref, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return retValuePtr.value;
    } finally {
      free(retValuePtr);
    }
  }

  bool _hasKey_String(String value) {
    final retValuePtr = calloc<Bool>();
    final hValue = convertToHString(value);

    try {
      final hr = ptr.ref.lpVtbl.value
              .elementAt(8)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(Pointer, HSTRING, Pointer<Bool>)>>>()
              .value
              .asFunction<int Function(Pointer, int, Pointer<Bool>)>()(
          ptr.ref.lpVtbl, hValue, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return retValuePtr.value;
    } finally {
      free(retValuePtr);
      WindowsDeleteString(hValue);
    }
  }

  /// Returns an immutable view of the map.
  Map<K, V> getView() {
    final retValuePtr = calloc<COMObject>();

    try {
      final hr = ptr.ref.lpVtbl.value
              .elementAt(9)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(Pointer, Pointer<COMObject>)>>>()
              .value
              .asFunction<int Function(Pointer, Pointer<COMObject>)>()(
          ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return IMapView<K, V>.fromRawPointer(retValuePtr,
              creator: _creator, enumCreator: _enumCreator)
          .toMap();
    } finally {
      free(retValuePtr);
    }
  }

  /// Inserts or replaces an item in the map.
  bool insert(K key, V value) {
    if (isSameType<K, GUID>()) {
      if (isSubtypeOfInspectable<V>()) {
        return _insert_GUID_Object(key as GUID, (value as IInspectable).ptr);
      }

      return _insert_GUID_Object(key as GUID, boxValue(value));
    }

    if (isSameType<K, int>()) {
      return _insert_Uint32_COMObject(key as int, (value as IInspectable).ptr);
    }

    if (isSameType<K, PedometerStepKind>()) {
      return insertByPedometerStepKind(
          key as PedometerStepKind, (value as IInspectable).ptr);
    }

    if (isSameType<K, String>()) {
      if (isSimilarType<V, String>()) {
        return _insert_String_String(key as String, value as String?);
      }

      if (isSubtypeOfInspectable<V>()) {
        return _insert_String_Object(
            key as String, (value as IInspectable).ptr);
      }

      if (isSubtypeOfWinRTEnum<V>()) {
        return _insert_String_enum(key as String, value as WinRTEnum?);
      }

      return _insert_String_Object(key as String, boxValue(value));
    }

    return _insert_Object_Object(key as IInspectable, boxValue(value));
  }

  bool _insert_GUID_Object(GUID key, Pointer<COMObject> value) {
    final retValuePtr = calloc<Bool>();

    try {
      final hr = ptr.ref.lpVtbl.value
              .elementAt(10)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(
                              Pointer, GUID, COMObject, Pointer<Bool>)>>>()
              .value
              .asFunction<
                  int Function(Pointer, GUID, COMObject, Pointer<Bool>)>()(
          ptr.ref.lpVtbl, key, value.ref, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return retValuePtr.value;
    } finally {
      free(retValuePtr);
    }
  }

  bool _insert_Uint32_COMObject(int key, Pointer<COMObject> value) {
    final retValuePtr = calloc<Bool>();

    try {
      final hr = ptr.ref.lpVtbl.value
              .elementAt(10)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(
                              Pointer, Uint32, COMObject, Pointer<Bool>)>>>()
              .value
              .asFunction<
                  int Function(Pointer, int, COMObject, Pointer<Bool>)>()(
          ptr.ref.lpVtbl, key, value.ref, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return retValuePtr.value;
    } finally {
      free(retValuePtr);
    }
  }

  bool _insert_Object_Object(IInspectable key, Pointer<COMObject> value) {
    final retValuePtr = calloc<Bool>();

    try {
      final hr = ptr.ref.lpVtbl.value
              .elementAt(10)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(
                              Pointer, COMObject, COMObject, Pointer<Bool>)>>>()
              .value
              .asFunction<
                  int Function(Pointer, COMObject, COMObject, Pointer<Bool>)>()(
          ptr.ref.lpVtbl, key.ptr.ref, value.ref, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return retValuePtr.value;
    } finally {
      free(retValuePtr);
    }
  }

  bool _insert_String_enum(String key, WinRTEnum? value) {
    final retValuePtr = calloc<Bool>();
    final hKey = convertToHString(key);

    try {
      final hr = ptr.ref.lpVtbl.value
              .elementAt(10)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(
                              Pointer, HSTRING, Int32, Pointer<Bool>)>>>()
              .value
              .asFunction<int Function(Pointer, int, int, Pointer<Bool>)>()(
          ptr.ref.lpVtbl, hKey, value?.value ?? 0, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return retValuePtr.value;
    } finally {
      WindowsDeleteString(hKey);
      free(retValuePtr);
    }
  }

  bool _insert_String_Object(String key, Pointer<COMObject> value) {
    final retValuePtr = calloc<Bool>();
    final hKey = convertToHString(key);

    try {
      final hr = ptr.ref.lpVtbl.value
              .elementAt(10)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(
                              Pointer, HSTRING, COMObject, Pointer<Bool>)>>>()
              .value
              .asFunction<
                  int Function(Pointer, int, COMObject, Pointer<Bool>)>()(
          ptr.ref.lpVtbl, hKey, value.ref, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return retValuePtr.value;
    } finally {
      WindowsDeleteString(hKey);
      free(retValuePtr);
    }
  }

  bool _insert_String_String(String key, String? value) {
    final retValuePtr = calloc<Bool>();
    final hKey = convertToHString(key);
    final hValue = value != null ? convertToHString(value) : 0;

    try {
      final hr = ptr.ref.lpVtbl.value
              .elementAt(10)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(
                              Pointer, HSTRING, HSTRING, Pointer<Bool>)>>>()
              .value
              .asFunction<int Function(Pointer, int, int, Pointer<Bool>)>()(
          ptr.ref.lpVtbl, hKey, hValue, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return retValuePtr.value;
    } finally {
      WindowsDeleteString(hKey);
      WindowsDeleteString(hValue);
      free(retValuePtr);
    }
  }

  /// Removes an item from the map.
  void remove(K key) {
    if (isSameType<K, GUID>()) return _remove_GUID(key as GUID);
    if (isSameType<K, int>()) return _remove_Uint32(key as int);
    if (isSameType<K, PedometerStepKind>()) {
      return removeByPedometerStepKind(key as PedometerStepKind);
    }
    if (isSameType<K, String>()) return _remove_String(key as String);

    return _remove_Object(key as IInspectable);
  }

  void _remove_GUID(GUID key) {
    final hr = ptr.ref.lpVtbl.value
        .elementAt(11)
        .cast<Pointer<NativeFunction<HRESULT Function(Pointer, GUID)>>>()
        .value
        .asFunction<int Function(Pointer, GUID)>()(ptr.ref.lpVtbl, key);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  void _remove_Uint32(int key) {
    final hr = ptr.ref.lpVtbl.value
        .elementAt(11)
        .cast<Pointer<NativeFunction<HRESULT Function(Pointer, Uint32)>>>()
        .value
        .asFunction<int Function(Pointer, int)>()(ptr.ref.lpVtbl, key);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  void _remove_Object(IInspectable key) {
    final hr = ptr.ref.lpVtbl.value
        .elementAt(11)
        .cast<Pointer<NativeFunction<HRESULT Function(Pointer, COMObject)>>>()
        .value
        .asFunction<
            int Function(Pointer, COMObject)>()(ptr.ref.lpVtbl, key.ptr.ref);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  void _remove_String(String key) {
    final hKey = convertToHString(key);

    try {
      final hr = ptr.ref.lpVtbl.value
          .elementAt(11)
          .cast<Pointer<NativeFunction<HRESULT Function(Pointer, HSTRING)>>>()
          .value
          .asFunction<int Function(Pointer, int)>()(ptr.ref.lpVtbl, hKey);

      if (FAILED(hr)) throw WindowsException(hr);
    } finally {
      WindowsDeleteString(hKey);
    }
  }

  /// Removes all items from the map.
  void clear() {
    final hr = ptr.ref.lpVtbl.value
        .elementAt(12)
        .cast<Pointer<NativeFunction<HRESULT Function(Pointer)>>>()
        .value
        .asFunction<int Function(Pointer)>()(ptr.ref.lpVtbl);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  /// Creates an unmodifiable [Map] from the current [IMap] instance.
  Map<K, V> toMap() => size == 0
      ? Map.unmodifiable(<K, V>{})
      : MapHelper.toMap<K, V>(first(), length: size, creator: _iterableCreator);

  late final _iIterable = IIterable<IKeyValuePair<K, V>>.fromRawPointer(
      toInterface(iterableIidFromIids(iids)),
      creator: _iterableCreator);

  @override
  IIterator<IKeyValuePair<K, V>> first() => _iIterable.first();
}
