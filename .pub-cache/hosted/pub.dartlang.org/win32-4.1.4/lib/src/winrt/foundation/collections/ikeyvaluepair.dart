// ikeyvaluepair.dart

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

/// Represents a key-value pair.
///
/// This is typically used as a constraint type when you need to encapsulate
/// two type parameters into one to satisfy the constraints of another generic
/// interface.
///
/// {@category Interface}
/// {@category winrt}
class IKeyValuePair<K, V> extends IInspectable {
  // vtable begins at 6, is 2 entries long.
  final V Function(Pointer<COMObject>)? _creator;
  final K Function(int)? _enumKeyCreator;
  final V Function(int)? _enumCreator;

  /// Creates an instance of [IKeyValuePair] using the given [ptr].
  ///
  /// [K] must be of type `Guid`, `int`, `Object`, `String`, or `WinRTEnum`
  /// (e.g. `PedometerStepKind`).
  ///
  /// [V] must be of type `Object`, `String`, or `WinRT` (e.g. `IJsonValue`,
  /// `ProductLicense`).
  ///
  /// [creator] must be specified if [V] is a `WinRT` type.
  /// ```dart
  /// final keyValuePair =
  ///     IKeyValuePair<String, IJsonValue?>.fromRawPointer(ptr,
  ///         creator: IJsonValue.fromRawPointer);
  /// ```
  ///
  /// [enumCreator] must be specified if [V] is a `WinRTEnum` type.
  /// ```dart
  /// final keyValuePair =
  ///     IKeyValuePair<String, ChatMessageStatus>.fromRawPointer(ptr,
  ///         enumCreator: ChatMessageStatus.from);
  /// ```
  IKeyValuePair.fromRawPointer(
    super.ptr, {
    V Function(Pointer<COMObject>)? creator,
    K Function(int)? enumKeyCreator,
    V Function(int)? enumCreator,
  })  : _creator = creator,
        _enumKeyCreator = enumKeyCreator,
        _enumCreator = enumCreator {
    if (!isSupportedKeyValuePair<K, V>()) {
      throw ArgumentError('Unsupported key-value pair: IKeyValuePair<$K, $V>');
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
  }

  /// Gets the key of the key-value pair.
  K get key {
    if (isSameType<K, Guid>()) return _key_Guid as K;
    if (isSameType<K, int>()) return _key_Uint32 as K;
    if (isSameType<K, String>()) return _key_String as K;
    if (isSubtypeOfWinRTEnum<K>()) return _enumKeyCreator!(_key_enum);

    return _key_Object;
  }

  Guid get _key_Guid {
    final retValuePtr = calloc<GUID>();

    try {
      final hr = ptr.ref.lpVtbl.value
          .elementAt(6)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<GUID>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<GUID>)>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return retValuePtr.toDartGuid();
    } finally {
      free(retValuePtr);
    }
  }

  int get _key_enum {
    final retValuePtr = calloc<Int32>();

    try {
      final hr = ptr.ref.lpVtbl.value
          .elementAt(6)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Int32>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Int32>)>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return retValuePtr.value;
    } finally {
      free(retValuePtr);
    }
  }

  int get _key_Uint32 {
    final retValuePtr = calloc<Uint32>();

    try {
      final hr = ptr.ref.lpVtbl.value
          .elementAt(6)
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

  String get _key_String {
    final retValuePtr = calloc<HSTRING>();

    try {
      final hr = ptr.ref.lpVtbl.value
              .elementAt(6)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(Pointer, Pointer<HSTRING>)>>>()
              .value
              .asFunction<int Function(Pointer, Pointer<HSTRING>)>()(
          ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.toDartString();
      return retValue;
    } finally {
      WindowsDeleteString(retValuePtr.value);
      free(retValuePtr);
    }
  }

  K get _key_Object {
    final retValuePtr = calloc<COMObject>();

    final hr = ptr.ref.lpVtbl.value
            .elementAt(6)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(Pointer, Pointer<COMObject>)>>>()
            .value
            .asFunction<int Function(Pointer, Pointer<COMObject>)>()(
        ptr.ref.lpVtbl, retValuePtr);

    if (FAILED(hr)) {
      free(retValuePtr);
      throw WindowsException(hr);
    }

    return IPropertyValue.fromRawPointer(retValuePtr).value as K;
  }

  /// Gets the value of the key-value pair.
  V get value {
    if (isSameType<V, String>()) return _value_String as V;
    if (isSubtypeOfInspectable<V>()) return _value_COMObject;
    if (isSubtypeOfWinRTEnum<V>()) return _value_enum;

    return _value_Object as V;
  }

  V get _value_COMObject {
    final retValuePtr = calloc<COMObject>();

    final hr = ptr.ref.lpVtbl.value
            .elementAt(7)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(Pointer, Pointer<COMObject>)>>>()
            .value
            .asFunction<int Function(Pointer, Pointer<COMObject>)>()(
        ptr.ref.lpVtbl, retValuePtr);

    if (FAILED(hr)) {
      free(retValuePtr);
      throw WindowsException(hr);
    }

    return _creator!(retValuePtr);
  }

  V get _value_enum {
    final retValuePtr = calloc<Int32>();

    try {
      final hr = ptr.ref.lpVtbl.value
          .elementAt(7)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Int32>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Int32>)>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return _enumCreator!(retValuePtr.value);
    } finally {
      free(retValuePtr);
    }
  }

  Object? get _value_Object {
    final retValuePtr = calloc<COMObject>();

    final hr = ptr.ref.lpVtbl.value
            .elementAt(7)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(Pointer, Pointer<COMObject>)>>>()
            .value
            .asFunction<int Function(Pointer, Pointer<COMObject>)>()(
        ptr.ref.lpVtbl, retValuePtr);

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

  String get _value_String {
    final retValuePtr = calloc<HSTRING>();

    try {
      final hr = ptr.ref.lpVtbl.value
              .elementAt(7)
              .cast<
                  Pointer<
                      NativeFunction<
                          HRESULT Function(Pointer, Pointer<HSTRING>)>>>()
              .value
              .asFunction<int Function(Pointer, Pointer<HSTRING>)>()(
          ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.toDartString();
      return retValue;
    } finally {
      WindowsDeleteString(retValuePtr.value);
      free(retValuePtr);
    }
  }
}
