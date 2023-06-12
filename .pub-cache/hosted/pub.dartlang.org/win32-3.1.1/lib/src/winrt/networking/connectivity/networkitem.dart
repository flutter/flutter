// networkitem.dart

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

import 'inetworkitem.dart';
import '../../../guid.dart';
import 'enums.g.dart';
import '../../../com/iinspectable.dart';

/// {@category Class}
/// {@category winrt}
class NetworkItem extends IInspectable implements INetworkItem {
  NetworkItem.fromRawPointer(super.ptr);

  // INetworkItem methods
  late final _iNetworkItem = INetworkItem.from(this);

  @override
  GUID get networkId => _iNetworkItem.networkId;

  @override
  NetworkTypes getNetworkTypes() => _iNetworkItem.getNetworkTypes();
}
