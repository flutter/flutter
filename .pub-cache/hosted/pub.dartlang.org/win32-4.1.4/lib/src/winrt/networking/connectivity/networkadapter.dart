// networkadapter.dart

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// ignore_for_file: unused_import
// ignore_for_file: constant_identifier_names, non_constant_identifier_names
// ignore_for_file: no_leading_underscores_for_local_identifiers

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
import '../../../winrt_callbacks.dart';
import '../../../winrt_helpers.dart';
import '../../foundation/iasyncoperation.dart';
import '../../internal/hstring_array.dart';
import 'connectionprofile.dart';
import 'inetworkadapter.dart';
import 'networkitem.dart';

/// Represents a network adapter.
///
/// {@category Class}
/// {@category winrt}
class NetworkAdapter extends IInspectable implements INetworkAdapter {
  NetworkAdapter.fromRawPointer(super.ptr);

  // INetworkAdapter methods
  late final _iNetworkAdapter = INetworkAdapter.from(this);

  @override
  int get outboundMaxBitsPerSecond => _iNetworkAdapter.outboundMaxBitsPerSecond;

  @override
  int get inboundMaxBitsPerSecond => _iNetworkAdapter.inboundMaxBitsPerSecond;

  @override
  int get ianaInterfaceType => _iNetworkAdapter.ianaInterfaceType;

  @override
  NetworkItem? get networkItem => _iNetworkAdapter.networkItem;

  @override
  Guid get networkAdapterId => _iNetworkAdapter.networkAdapterId;

  @override
  Future<ConnectionProfile?> getConnectedProfileAsync() =>
      _iNetworkAdapter.getConnectedProfileAsync();
}
