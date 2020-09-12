// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

/// Determines whether `address` is a valid IPv6 or IPv4 address.
///
/// Throws an [ArgumentError] if the address is neither.
void validateAddress(String address) {
  if (!(isIpV4Address(address) || isIpV6Address(address))) {
    throw ArgumentError(
        '"$address" is neither a valid IPv4 nor IPv6 address');
  }
}

/// Returns true if `address` is a valid IPv6 address.
bool isIpV6Address(String address) {
  try {
    InternetAddress(address, type:InternetAddressType.IPv6);
    return true;
  } on FormatException {
    return false;
  }
}

/// Returns true if `address` is a valid IPv4 address.
bool isIpV4Address(String address) {
  try {
    InternetAddress(address, type:InternetAddressType.IPv4);
    return true;
  } on FormatException {
    return false;
  }
}
