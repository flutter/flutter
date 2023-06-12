// printing3dmultiplepropertymaterial.dart

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// ignore_for_file: unused_import, directives_ordering
// ignore_for_file: constant_identifier_names, non_constant_identifier_names
// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../../combase.dart';
import '../../../exceptions.dart';
import '../../../macros.dart';
import '../../../utils.dart';
import '../../../types.dart';
import '../../../win32/api_ms_win_core_winrt_string_l1_1_0.g.dart';
import '../../../winrt_callbacks.dart';
import '../../../winrt_helpers.dart';

import '../../internal/hstring_array.dart';

import 'iprinting3dmultiplepropertymaterial.dart';
import '../../foundation/collections/ivector.dart';
import '../../../com/iinspectable.dart';

/// {@category Class}
/// {@category winrt}
class Printing3DMultiplePropertyMaterial extends IInspectable
    implements IPrinting3DMultiplePropertyMaterial {
  Printing3DMultiplePropertyMaterial({Allocator allocator = calloc})
      : super(ActivateClass(_className, allocator: allocator));
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
