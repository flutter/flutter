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
import '../../devices/sensors/enums.g.dart';
import '../../devices/sensors/pedometerstepkind_helpers.dart';
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
  final V Function(int)? _enumCreator;

  /// Creates an instance of [IKeyValuePair] using the given [ptr].
  ///
  /// [K] must be of type `GUID`, `int`, `Object`, `String`, or `WinRTEnum`
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
  ///     IKeyValuePair<String, ChatMessageStatus?>.fromRawPointer(ptr,
  ///         enumCreator: ChatMessageStatus.from);
  /// ```
  IKeyValuePair.fromRawPointer(
    super.ptr, {
    V Function(Pointer<COMObject>)? creator,
    V Function(int)? enumCreator,
  })  : _creator = creator,
        _enumCreator = enumCreator {
    if (!isSupportedKeyValuePair<K, V>()) {
      throw ArgumentError('Unsupported key-value pair: IKeyValuePair<$K, $V>');
    }

    if (isSubtypeOfInspectable<V>() && creator == null) {
      throw ArgumentError.notNull('creator');
    }

    if (isSubtypeOfWinRTEnum<V>() && enumCreator == null) {
      throw ArgumentError.notNull('enumCreator');
    }
  }

  /// Gets the key of the key-value pair.
  K get key {
    if (isSameType<K, GUID>()) return _key_GUID as K;
    if (isSameType<K, int>()) return _key_Uint32 as K;
    if (isSameType<K, PedometerStepKind>()) return keyAsPedometerStepKind as K;
    if (isSameType<K, String>()) return _key_String as K;

    return _key_Object;
  }

  GUID get _key_GUID {
    final retValuePtr = calloc<GUID>();

    final hr = ptr.ref.lpVtbl.value
        .elementAt(6)
        .cast<
            Pointer<NativeFunction<HRESULT Function(Pointer, Pointer<GUID>)>>>()
        .value
        .asFunction<
            int Function(
                Pointer, Pointer<GUID>)>()(ptr.ref.lpVtbl, retValuePtr);

    if (FAILED(hr)) {
      free(retValuePtr);
      throw WindowsException(hr);
    }

    return retValuePtr.ref;
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
    if (isSimilarType<V, String>()) return _value_String as V;
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

    return IPropertyValue.fromRawPointer(retValuePtr).value;
  }

  String? get _value_String {
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

      if (retValuePtr.value == 0) return null;

      final retValue = retValuePtr.toDartString();
      return retValue;
    } finally {
      WindowsDeleteString(retValuePtr.value);
      free(retValuePtr);
    }
  }
}
