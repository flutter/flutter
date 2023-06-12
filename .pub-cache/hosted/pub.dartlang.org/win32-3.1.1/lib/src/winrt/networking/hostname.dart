// hostname.dart

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// ignore_for_file: unused_import, directives_ordering
// ignore_for_file: constant_identifier_names, non_constant_identifier_names
// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../../combase.dart';
import '../../exceptions.dart';
import '../../macros.dart';
import '../../utils.dart';
import '../../types.dart';
import '../../win32/api_ms_win_core_winrt_string_l1_1_0.g.dart';
import '../../winrt_callbacks.dart';
import '../../winrt_helpers.dart';

import '../internal/hstring_array.dart';

import 'ihostname.dart';
import '../foundation/istringable.dart';
import 'ihostnamefactory.dart';
import 'ihostnamestatics.dart';
import 'connectivity/ipinformation.dart';
import 'enums.g.dart';
import '../../com/iinspectable.dart';

/// {@category Class}
/// {@category winrt}
class HostName extends IInspectable implements IHostName, IStringable {
  HostName.fromRawPointer(super.ptr);

  static const _className = 'Windows.Networking.HostName';

  // IHostNameFactory methods
  static HostName createHostName(String hostName) {
    final activationFactory =
        CreateActivationFactory(_className, IID_IHostNameFactory);

    try {
      return IHostNameFactory.fromRawPointer(activationFactory)
          .createHostName(hostName);
    } finally {
      free(activationFactory);
    }
  }

  // IHostNameStatics methods
  static int compare(String value1, String value2) {
    final activationFactory =
        CreateActivationFactory(_className, IID_IHostNameStatics);

    try {
      return IHostNameStatics.fromRawPointer(activationFactory)
          .compare(value1, value2);
    } finally {
      free(activationFactory);
    }
  }

  // IHostName methods
  late final _iHostName = IHostName.from(this);

  @override
  IPInformation get iPInformation => _iHostName.iPInformation;

  @override
  String get rawName => _iHostName.rawName;

  @override
  String get displayName => _iHostName.displayName;

  @override
  String get canonicalName => _iHostName.canonicalName;

  @override
  HostNameType get type => _iHostName.type;

  @override
  bool isEqual(HostName hostName) => _iHostName.isEqual(hostName);
  // IStringable methods
  late final _iStringable = IStringable.from(this);

  @override
  String toString() => _iStringable.toString();
}
