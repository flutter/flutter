// igeopointfactory.dart

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
import 'enums.g.dart';
import 'geopoint.dart';
import 'structs.g.dart';

/// @nodoc
const IID_IGeopointFactory = '{db6b8d33-76bd-4e30-8af7-a844dc37b7a0}';

/// {@category Interface}
/// {@category winrt}
class IGeopointFactory extends IInspectable {
  // vtable begins at 6, is 3 entries long.
  IGeopointFactory.fromRawPointer(super.ptr);

  factory IGeopointFactory.from(IInspectable interface) =>
      IGeopointFactory.fromRawPointer(
          interface.toInterface(IID_IGeopointFactory));

  Geopoint create(BasicGeoposition position) {
    final retValuePtr = calloc<COMObject>();

    final hr = ptr.ref.vtable
        .elementAt(6)
        .cast<
            Pointer<
                NativeFunction<
                    HRESULT Function(Pointer, BasicGeoposition position,
                        Pointer<COMObject>)>>>()
        .value
        .asFunction<
            int Function(Pointer, BasicGeoposition position,
                Pointer<COMObject>)>()(ptr.ref.lpVtbl, position, retValuePtr);

    if (FAILED(hr)) {
      free(retValuePtr);
      throw WindowsException(hr);
    }

    return Geopoint.fromRawPointer(retValuePtr);
  }

  Geopoint createWithAltitudeReferenceSystem(BasicGeoposition position,
      AltitudeReferenceSystem altitudeReferenceSystem) {
    final retValuePtr = calloc<COMObject>();

    final hr =
        ptr.ref.vtable
                .elementAt(7)
                .cast<
                    Pointer<
                        NativeFunction<
                            HRESULT Function(
                                Pointer,
                                BasicGeoposition position,
                                Int32 altitudeReferenceSystem,
                                Pointer<COMObject>)>>>()
                .value
                .asFunction<
                    int Function(Pointer, BasicGeoposition position,
                        int altitudeReferenceSystem, Pointer<COMObject>)>()(
            ptr.ref.lpVtbl,
            position,
            altitudeReferenceSystem.value,
            retValuePtr);

    if (FAILED(hr)) {
      free(retValuePtr);
      throw WindowsException(hr);
    }

    return Geopoint.fromRawPointer(retValuePtr);
  }

  Geopoint createWithAltitudeReferenceSystemAndSpatialReferenceId(
      BasicGeoposition position,
      AltitudeReferenceSystem altitudeReferenceSystem,
      int spatialReferenceId) {
    final retValuePtr = calloc<COMObject>();

    final hr = ptr.ref.vtable
            .elementAt(8)
            .cast<
                Pointer<
                    NativeFunction<
                        HRESULT Function(
                            Pointer,
                            BasicGeoposition position,
                            Int32 altitudeReferenceSystem,
                            Uint32 spatialReferenceId,
                            Pointer<COMObject>)>>>()
            .value
            .asFunction<
                int Function(
                    Pointer,
                    BasicGeoposition position,
                    int altitudeReferenceSystem,
                    int spatialReferenceId,
                    Pointer<COMObject>)>()(ptr.ref.lpVtbl, position,
        altitudeReferenceSystem.value, spatialReferenceId, retValuePtr);

    if (FAILED(hr)) {
      free(retValuePtr);
      throw WindowsException(hr);
    }

    return Geopoint.fromRawPointer(retValuePtr);
  }
}
