// imapview.dart

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
import '../../internal/ipropertyvalue_helpers.dart';
import '../../internal/map_helpers.dart';
import '../ipropertyvalue.dart';
import '../winrt_enum.dart';
import 'iiterable.dart';
import 'iiterator.dart';
import 'ikeyvaluepair.dart';

/// Represents an immutable view into a map.
///
/// {@category Interface}
/// {@category winrt}
class IMapView<K, V> extends IInspectable
    implements IIterable<IKeyValuePair<K, V>> {
  // vtable begins at 6, is 4 entries long.
  final String _iterableIid;
  late final IKeyValuePair<K, V> Function(Pointer<COMObject>) _iterableCreator;
  final V Function(Pointer<COMObject>)? _creator;
  final K Function(int)? _enumKeyCreator;
  final V Function(int)? _enumCreator;

  /// Creates an instance of [IMapView] using the given [ptr] and [iterableIid].
  ///
  /// [iterableIid] must be the IID of the `IIterable<IKeyValuePair<K, V>>`
  /// interface (e.g. [IID_IIterable_IKeyValuePair_String_Object]).
  ///
  /// [K] must be of type `Guid`, `int`, `Object`, `String`, or `WinRTEnum`
  /// (e.g. `PedometerStepKind`).
  ///
  /// [V] must be of type `Object`, `String`, or `WinRT` (e.g. `IJsonValue`,
  /// `ProductLicense`).
  ///
  /// [creator] must be specified if [V] is a `WinRT` type.
  /// ```dart
  /// final mapView = IMapView<String, IJsonValue?>.fromRawPointer(ptr,
  ///     creator: IJsonValue.fromRawPointer);
  /// ```
  ///
  /// [enumCreator] must be specified if [V] is a `WinRTEnum` type.
  /// ```dart
  /// final mapView = IMapView<String, ChatMessageStatus>.fromRawPointer(ptr,
  ///     enumCreator: ChatMessageStatus.from);
  /// ```
  IMapView.fromRawPointer(
    super.ptr, {
    required String iterableIid,
    V Function(Pointer<COMObject>)? creator,
    K Function(int)? enumKeyCreator,
    V Function(int)? enumCreator,
  })  : _iterableIid = iterableIid,
        _creator = creator,
        _enumKeyCreator = enumKeyCreator,
        _enumCreator = enumCreator {
    if (!isSupportedKeyValuePair<K, V>()) {
      throw ArgumentError('Unsupported key-value pair: IMapView<$K, $V>');
    }

    if (isSubtypeOfInspectable<V>() && creator == null) {
      throw ArgumentError.notNull('creator');
    }

    if (isSubtypeOfWinRTEnum<K>() && enumKeyCreator == null) {
      throw ArgumentError.notNull('enumKeyCreator');
    }

    if (isSubtypeOfWinRTEnum<V>() && enumCreator == null) {
      throw ArgumentError.notNull('enumCreator');
    }

    _iterableCreator = (Pointer<COMObject> ptr) => IKeyValuePair.fromRawPointer(
        ptr,
        creator: _creator,
        enumKeyCreator: _enumKeyCreator,
        enumCreator: _enumCreator);
  }

  /// Returns the item at the specified key in the map.
  V lookup(K key) {
    if (isSameType<K, Guid>()) {
      if (isSubtypeOfInspectable<V>()) {
        return _lookup_Guid_COMObject(key as Guid);
      }

      return _lookup_Guid_Object(key as Guid) as V;
    }

    if (isSameType<K, int>()) {
      return _lookup_Uint32_COMObject(key as int);
    }

    if (isSameType<K, String>()) {
      if (isSameType<V, String>()) {
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

    if (isSubtypeOfWinRTEnum<K>()) {
      return _lookup_enum_COMObject(key as WinRTEnum);
    }

    return _lookup_Object_Object(key as IInspectable) as V;
  }

  V _lookup_Guid_COMObject(Guid key) {
    final retValuePtr = calloc<COMObject>();
    final nativeGuidPtr = key.toNativeGUID();

    final hr = ptr.ref.lpVtbl.value
            .elementAt(6)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(Pointer, GUID, Pointer<COMObject>)>>>()
            .value
            .asFunction<int Function(Pointer, GUID, Pointer<COMObject>)>()(
        ptr.ref.lpVtbl, nativeGuidPtr.ref, retValuePtr);

    if (FAILED(hr)) {
      free(nativeGuidPtr);
      free(retValuePtr);
      throw WindowsException(hr);
    }

    free(nativeGuidPtr);

    return _creator!(retValuePtr);
  }

  Object? _lookup_Guid_Object(Guid key) {
    final retValuePtr = calloc<COMObject>();
    final nativeGuidPtr = key.toNativeGUID();

    final hr = ptr.ref.lpVtbl.value
            .elementAt(6)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(Pointer, GUID, Pointer<COMObject>)>>>()
            .value
            .asFunction<int Function(Pointer, GUID, Pointer<COMObject>)>()(
        ptr.ref.lpVtbl, nativeGuidPtr.ref, retValuePtr);

    if (FAILED(hr)) {
      free(nativeGuidPtr);
      free(retValuePtr);
      throw WindowsException(hr);
    }

    free(nativeGuidPtr);

    if (retValuePtr.ref.lpVtbl == nullptr) {
      free(retValuePtr);
      return null;
    }

    return IPropertyValue.fromRawPointer(retValuePtr).value;
  }

  V _lookup_enum_COMObject(WinRTEnum key) {
    final retValuePtr = calloc<COMObject>();

    final hr =
        ptr.ref.lpVtbl.value
                .elementAt(6)
                .cast<
                    Pointer<
                        NativeFunction<
                            HRESULT Function(
                                Pointer, Int32, Pointer<COMObject>)>>>()
                .value
                .asFunction<int Function(Pointer, int, Pointer<COMObject>)>()(
            ptr.ref.lpVtbl, key.value, retValuePtr);

    if (FAILED(hr)) {
      free(retValuePtr);
      throw WindowsException(hr);
    }

    return _creator!(retValuePtr);
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

    if (retValuePtr.ref.lpVtbl == nullptr) {
      free(retValuePtr);
      return null;
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

      if (retValuePtr.ref.lpVtbl == nullptr) {
        free(retValuePtr);
        return null;
      }

      return IPropertyValue.fromRawPointer(retValuePtr).value;
    } finally {
      WindowsDeleteString(hKey);
    }
  }

  String _lookup_String_String(String key) {
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
    if (isSameType<K, Guid>()) return _hasKey_Guid(value as Guid);
    if (isSameType<K, int>()) return _hasKey_Uint32(value as int);
    if (isSameType<K, String>()) return _hasKey_String(value as String);
    if (isSubtypeOfWinRTEnum<K>()) return _hasKey_enum(value as WinRTEnum);

    return _hasKey_Object(value as IInspectable);
  }

  bool _hasKey_Guid(Guid value) {
    final retValuePtr = calloc<Bool>();
    final nativeGuidPtr = value.toNativeGUID();

    try {
      final hr = ptr.ref.lpVtbl.value
              .elementAt(8)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(Pointer, GUID, Pointer<Bool>)>>>()
              .value
              .asFunction<int Function(Pointer, GUID, Pointer<Bool>)>()(
          ptr.ref.lpVtbl, nativeGuidPtr.ref, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return retValuePtr.value;
    } finally {
      free(nativeGuidPtr);
      free(retValuePtr);
    }
  }

  bool _hasKey_enum(WinRTEnum value) {
    final retValuePtr = calloc<Bool>();

    try {
      final hr = ptr.ref.lpVtbl.value
              .elementAt(8)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(Pointer, Int32, Pointer<Bool>)>>>()
              .value
              .asFunction<int Function(Pointer, int, Pointer<Bool>)>()(
          ptr.ref.lpVtbl, value.value, retValuePtr);

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

  /// Splits the map view into two views.
  void split(IMapView<K, V> first, IMapView<K, V> second) {
    final hr = ptr.ref.lpVtbl.value
        .elementAt(9)
        .cast<
            Pointer<
                NativeFunction<
                    HRESULT Function(
                        Pointer, Pointer<COMObject>, Pointer<COMObject>)>>>()
        .value
        .asFunction<
            int Function(Pointer, Pointer<COMObject>,
                Pointer<COMObject>)>()(ptr.ref.lpVtbl, first.ptr, second.ptr);

    if (FAILED(hr)) throw WindowsException(hr);
  }

  /// Creates an unmodifiable [Map] from the current [IMapView] instance.
  Map<K, V> toMap() => size == 0
      ? Map.unmodifiable(<K, V>{})
      : MapHelper.toMap<K, V>(first(), length: size, creator: _iterableCreator);

  late final _iIterable = IIterable<IKeyValuePair<K, V>>.fromRawPointer(
      toInterface(_iterableIid),
      creator: _iterableCreator);

  @override
  IIterator<IKeyValuePair<K, V>> first() => _iIterable.first();
}
