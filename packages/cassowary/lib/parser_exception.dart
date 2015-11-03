// Copyright (c) 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of cassowary;

class ParserException implements Exception {
  final String message;
  List<_EquationMember> members;
  ParserException(this.message, this.members);

  String toString() {
    if (message == null) return "Error while parsing constraint or expression";
    return "Error: '$message' while trying to parse constraint or expression";
  }
}
