// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html' as html show NetworkInformation;
import 'package:connectivity_platform_interface/connectivity_platform_interface.dart';

/// Converts an incoming NetworkInformation object into the correct ConnectivityResult.
ConnectivityResult networkInformationToConnectivityResult(
  html.NetworkInformation? info,
) {
  if (info == null) {
    return ConnectivityResult.none;
  }
  if (info.downlink == 0 && info.rtt == 0) {
    return ConnectivityResult.none;
  }
  if (info.effectiveType != null) {
    return _effectiveTypeToConnectivityResult(info.effectiveType!);
  }
  if (info.type != null) {
    return _typeToConnectivityResult(info.type!);
  }
  return ConnectivityResult.none;
}

ConnectivityResult _effectiveTypeToConnectivityResult(String effectiveType) {
  // Possible values:
  /*'2g'|'3g'|'4g'|'slow-2g'*/
  switch (effectiveType) {
    case 'slow-2g':
    case '2g':
    case '3g':
      return ConnectivityResult.mobile;
    default:
      return ConnectivityResult.wifi;
  }
}

ConnectivityResult _typeToConnectivityResult(String type) {
  // Possible values:
  /*'bluetooth'|'cellular'|'ethernet'|'mixed'|'none'|'other'|'unknown'|'wifi'|'wimax'*/
  switch (type) {
    case 'none':
      return ConnectivityResult.none;
    case 'bluetooth':
    case 'cellular':
    case 'mixed':
    case 'other':
    case 'unknown':
      return ConnectivityResult.mobile;
    default:
      return ConnectivityResult.wifi;
  }
}
