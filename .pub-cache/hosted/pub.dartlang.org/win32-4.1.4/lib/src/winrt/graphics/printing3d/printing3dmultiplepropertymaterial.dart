// printing3dmultiplepropertymaterial.dart

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
import '../../foundation/collections/ivector.dart';
import '../../internal/hstring_array.dart';
import 'iprinting3dmultiplepropertymaterial.dart';

/// Represents a combination of properties and/or materials from the
/// material groups specified in `MaterialGroupIndices`.
///
/// {@category Class}
/// {@category winrt}
class Printing3DMultiplePropertyMaterial extends IInspectable
    implements IPrinting3DMultiplePropertyMaterial {
  Printing3DMultiplePropertyMaterial() : super(ActivateClass(_className));
  Printing3DMultiplePropertyMaterial.fromRawPointer(super.ptr);

  static const _className =
      'Windows.Graphics.Printing3D.Printing3DMultiplePropertyMaterial';

  // IPrinting3DMultiplePropertyMaterial methods
  late final _iPrinting3DMultiplePropertyMaterial =
      IPrinting3DMultiplePropertyMaterial.from(this);

  @override
  IVector<int> get materialIndices =>
      _iPrinting3DMultiplePropertyMaterial.materialIndices;
}
