// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

/// The IPv4 mDNS Address.
final InternetAddress mDnsAddressIPv4 = InternetAddress('224.0.0.251');

/// The IPv6 mDNS Address.
final InternetAddress mDnsAddressIPv6 = InternetAddress('FF02::FB');

/// The mDNS port.
const int mDnsPort = 5353;

/// Enumeration of supported resource record class types.
abstract class ResourceRecordClass {
  // This class is intended to be used as a namespace, and should not be
  // extended directly.
  ResourceRecordClass._();

  /// Internet address class ("IN").
  static const int internet = 1;
}

/// Enumeration of DNS question types.
abstract class QuestionType {
  // This class is intended to be used as a namespace, and should not be
  // extended directly.
  QuestionType._();

  /// "QU" Question.
  static const int unicast = 0x8000;

  /// "QM" Question.
  static const int multicast = 0x0000;
}
