// ireference.dart

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../com/iinspectable.dart';
import '../../exceptions.dart';
import '../../guid.dart';
import '../../macros.dart';
import '../../types.dart';
import '../../utils.dart';
import '../../win32/api_ms_win_core_winrt_string_l1_1_0.g.dart';
import '../../winrt_constants.dart';
import '../../winrt_helpers.dart';
import 'structs.g.dart';

/// Enables arbitrary enumerations, structures, and delegate types to be used
/// as property values.
///
/// {@category Interface}
/// {@category winrt}
class IReference<T> extends IInspectable {
  // vtable begins at 6, is 1 entries long.
  final T Function(int)? _enumCreator;

  /// Creates an instance of [IReference] using the given [ptr].
  ///
  /// [T] must be of type `DateTime`, `double`, `Duration`, `int`, `String`,
  /// `Struct` (e.g. `GUID`,`Point`, `Rect`, `Size`), or `WinRTEnum` (e.g.
  /// `WebErrorStatus`).
  ///
  /// [enumCreator] must be specified if [T] is a `WinRTEnum` type.
  /// ```dart
  /// final reference = IReference<WebErrorStatus>.fromRawPointer(ptr,
  ///     enumCreator: WebErrorStatus.from);
  /// ```
  IReference.fromRawPointer(super.ptr, {T Function(int)? enumCreator})
      : _enumCreator = enumCreator {
    if (isSubtypeOfWinRTEnum<T>() && enumCreator == null) {
      throw ArgumentError.notNull('enumCreator');
    }
  }

  /// Gets the type that is represented as an `IPropertyValue``.
  T? get value {
    if (ptr.ref.lpVtbl == nullptr) return null;

    final iid = referenceIidFromIids(iids);
    switch (iid) {
      // Handle Int32 types and Int32 enumerations
      case IID_IReference_AdaptiveMediaSourceResourceType:
      case IID_IReference_CaptureSceneMode:
      case IID_IReference_EmailMailboxSmimeEncryptionAlgorithm:
      case IID_IReference_EmailMailboxSmimeSigningAlgorithm:
      case IID_IReference_HdcpProtection:
      case IID_IReference_ManualFocusDistance:
      case IID_IReference_MediaCaptureFocusState:
      case IID_IReference_MediaPlaybackAutoRepeatMode:
      case IID_IReference_MediaPlaybackType:
      case IID_IReference_UserDataTaskWeekOfMonth:
      case IID_IReference_WebErrorStatus:
      case IID_IReference_Int32:
        if (isSubtypeOfWinRTEnum<T>()) return _enumCreator!(getInt32());
        return getInt32() as T;
      // Handle Uint32 types and Uint32 enumerations
      case IID_IReference_BluetoothLEAdvertisementFlags:
      case IID_IReference_UserDataTaskDaysOfWeek:
      case IID_IReference_Uint32:
        if (isSubtypeOfWinRTEnum<T>()) return _enumCreator!(getUInt32());
        return getUInt32() as T;
      case IID_IReference_Boolean:
        return getBoolean() as T;
      case IID_IReference_DateTime:
        return getDateTime() as T;
      case IID_IReference_Double:
        return getDouble() as T;
      case IID_IReference_Float:
        return getSingle() as T;
      case IID_IReference_GUID:
        return getGuid() as T;
      case IID_IReference_Int16:
        return getInt16() as T;
      case IID_IReference_Int64:
        return getInt64() as T;
      case IID_IReference_Point:
        return getPoint() as T;
      case IID_IReference_Rect:
        return getRect() as T;
      case IID_IReference_Size:
        return getSize() as T;
      case IID_IReference_TimeSpan:
        return getTimeSpan() as T;
      case IID_IReference_Uint8:
        return getUInt8() as T;
      case IID_IReference_Uint64:
        return getUInt64() as T;
      // TODO: These structs are not yet supported. Since the PropertyValue does
      // not support them, we need to create our own IReference<T> (and possibly
      // IPropertyValue) implementations for them.
      case IID_IReference_BasicGeoposition:
      case IID_IReference_BitmapBounds:
      case IID_IReference_DisplayPresentationRate:
      case IID_IReference_HolographicStereoTransform:
      case IID_IReference_Matrix4x4:
      case IID_IReference_MseTimeRange:
      case IID_IReference_Quaternion:
      case IID_IReference_SizeInt32:
      case IID_IReference_SpatialBoundingBox:
      case IID_IReference_SpatialBoundingFrustum:
      case IID_IReference_SpatialBoundingOrientedBox:
      case IID_IReference_SpatialRay:
      case IID_IReference_Vector2:
      case IID_IReference_Vector3:
      case IID_IReference_WhiteBalanceGain:
      default:
        throw UnsupportedError('Unsupported IID: $iid');
    }
  }

  int getUInt8() {
    final retValuePtr = calloc<Uint8>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(6)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Uint8>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Uint8>)>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  int getInt16() {
    final retValuePtr = calloc<Int16>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(6)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Int16>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Int16>)>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  int getUInt16() {
    final retValuePtr = calloc<Uint16>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(6)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Uint16>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Uint16>)>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  int getInt32() {
    final retValuePtr = calloc<Int32>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(6)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Int32>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Int32>)>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  int getUInt32() {
    final retValuePtr = calloc<Uint32>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(6)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Uint32>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Uint32>)>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  int getInt64() {
    final retValuePtr = calloc<Int64>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(6)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Int64>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Int64>)>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  int getUInt64() {
    final retValuePtr = calloc<Uint64>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(6)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Uint64>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Uint64>)>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  double getSingle() {
    final retValuePtr = calloc<Float>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(6)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Float>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Float>)>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  double getDouble() {
    final retValuePtr = calloc<Double>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(6)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Double>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Double>)>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  int getChar16() {
    final retValuePtr = calloc<Uint16>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(6)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Uint16>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Uint16>)>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  bool getBoolean() {
    final retValuePtr = calloc<Bool>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(6)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Bool>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Bool>)>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.value;
      return retValue;
    } finally {
      free(retValuePtr);
    }
  }

  String getString() {
    final retValuePtr = calloc<HSTRING>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(6)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<IntPtr>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<IntPtr>)>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.toDartString();
      return retValue;
    } finally {
      WindowsDeleteString(retValuePtr.value);
      free(retValuePtr);
    }
  }

  GUID getGuid() {
    final retValuePtr = calloc<GUID>();

    final hr = ptr.ref.vtable
        .elementAt(6)
        .cast<
            Pointer<NativeFunction<HRESULT Function(Pointer, Pointer<GUID>)>>>()
        .value
        .asFunction<
            int Function(
                Pointer, Pointer<GUID>)>()(ptr.ref.lpVtbl, retValuePtr);

    if (FAILED(hr)) throw WindowsException(hr);

    return retValuePtr.ref;
  }

  DateTime getDateTime() {
    final retValuePtr = calloc<Uint64>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(6)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Uint64>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Uint64>)>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return DateTime.utc(1601, 01, 01)
          .add(Duration(microseconds: retValuePtr.value ~/ 10));
    } finally {
      free(retValuePtr);
    }
  }

  Duration getTimeSpan() {
    final retValuePtr = calloc<Uint64>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(6)
          .cast<
              Pointer<
                  NativeFunction<HRESULT Function(Pointer, Pointer<Uint64>)>>>()
          .value
          .asFunction<
              int Function(
                  Pointer, Pointer<Uint64>)>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      return Duration(microseconds: retValuePtr.value ~/ 10);
    } finally {
      free(retValuePtr);
    }
  }

  Point getPoint() {
    final retValuePtr = calloc<Point>();

    final hr = ptr.ref.vtable
        .elementAt(6)
        .cast<
            Pointer<
                NativeFunction<HRESULT Function(Pointer, Pointer<Point>)>>>()
        .value
        .asFunction<
            int Function(
                Pointer, Pointer<Point>)>()(ptr.ref.lpVtbl, retValuePtr);

    if (FAILED(hr)) throw WindowsException(hr);

    return retValuePtr.ref;
  }

  Size getSize() {
    final retValuePtr = calloc<Size>();

    final hr = ptr.ref.vtable
        .elementAt(6)
        .cast<
            Pointer<NativeFunction<HRESULT Function(Pointer, Pointer<Size>)>>>()
        .value
        .asFunction<
            int Function(
                Pointer, Pointer<Size>)>()(ptr.ref.lpVtbl, retValuePtr);

    if (FAILED(hr)) throw WindowsException(hr);

    return retValuePtr.ref;
  }

  Rect getRect() {
    final retValuePtr = calloc<Rect>();

    final hr = ptr.ref.vtable
        .elementAt(6)
        .cast<
            Pointer<NativeFunction<HRESULT Function(Pointer, Pointer<Rect>)>>>()
        .value
        .asFunction<
            int Function(
                Pointer, Pointer<Rect>)>()(ptr.ref.lpVtbl, retValuePtr);

    if (FAILED(hr)) throw WindowsException(hr);

    return retValuePtr.ref;
  }
}
