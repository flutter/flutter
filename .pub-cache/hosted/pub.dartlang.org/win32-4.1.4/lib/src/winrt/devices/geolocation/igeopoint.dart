// igeopoint.dart

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
import 'igeoshape.dart';
import 'structs.g.dart';

/// @nodoc
const IID_IGeopoint = '{6bfa00eb-e56e-49bb-9caf-cbaa78a8bcef}';

/// {@category Interface}
/// {@category winrt}
class IGeopoint extends IInspectable implements IGeoshape {
  // vtable begins at 6, is 1 entries long.
  IGeopoint.fromRawPointer(super.ptr);

  factory IGeopoint.from(IInspectable interface) =>
      IGeopoint.fromRawPointer(interface.toInterface(IID_IGeopoint));

  BasicGeoposition get position {
    final retValuePtr = calloc<BasicGeoposition>();

    try {
      final hr = ptr.ref.vtable
          .elementAt(6)
          .cast<
              Pointer<
                  NativeFunction<
                      HRESULT Function(Pointer, Pointer<BasicGeoposition>)>>>()
          .value
          .asFunction<
              int Function(Pointer,
                  Pointer<BasicGeoposition>)>()(ptr.ref.lpVtbl, retValuePtr);

      if (FAILED(hr)) throw WindowsException(hr);

      final retValue = retValuePtr.ref;
      return retValue;
    } finally {}
  }

  // IGeoshape methods
  late final _iGeoshape = IGeoshape.from(this);

  @override
  GeoshapeType get geoshapeType => _iGeoshape.geoshapeType;

  @override
  int get spatialReferenceId => _iGeoshape.spatialReferenceId;

  @override
  AltitudeReferenceSystem get altitudeReferenceSystem =>
      _iGeoshape.altitudeReferenceSystem;
}
