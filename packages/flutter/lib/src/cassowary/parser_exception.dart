// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'equation_member.dart';

class ParserException implements Exception {
  ParserException(this.message, this.members);

  final String message;

  List<EquationMember> members;

  @override
  String toString() {
    if (message == null)
      return 'Error while parsing constraint or expression';
    return 'Error: "$message" while trying to parse constraint or expression';
  }
}
