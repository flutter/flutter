// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:licenses/licenses.dart';
import 'package:test/test.dart';

class _MockLicenseSource implements LicenseSource {
  _MockLicenseSource(this.name, this.libraryName, this.officialSourceLocation);
  @override
  String name;
  @override
  String libraryName;
  @override
  String officialSourceLocation;
  @override
  List<License>? nearestLicensesFor(String name) => null;
  @override
  License? nearestLicenseOfType(LicenseType type) => null;
  @override
  License? nearestLicenseWithName(String name, {String? authors}) => null;
}

void main() {
  test('Block comments', () {
    final _MockLicenseSource licenseSource = _MockLicenseSource('foo', 'bar', 'baz');
    final List<License> licenses = determineLicensesFor(
      '''
/*
 * The authors of this software are Rob Pike and Ken Thompson.
 *              Copyright (c) 2002 by Lucent Technologies.
 * Permission to use, copy, modify, and distribute this software for any
 * purpose without fee is hereby granted, provided that this entire notice
 * is included in all copies of any software which is or includes a copy
 * or modification of this software and in all copies of the supporting
 * documentation for such software.
 * THIS SOFTWARE IS BEING PROVIDED "AS IS", WITHOUT ANY EXPRESS OR IMPLIED
 * WARRANTY.  IN PARTICULAR, NEITHER THE AUTHORS NOR LUCENT TECHNOLOGIES MAKE ANY
 * REPRESENTATION OR WARRANTY OF ANY KIND CONCERNING THE MERCHANTABILITY
 * OF THIS SOFTWARE OR ITS FITNESS FOR ANY PARTICULAR PURPOSE.
 */

#include <stdarg.h>
#include <string.h>

#include "util/utf.h"
''',
      'foo.h',
      licenseSource,
      origin: 'origin',
    );
    expect(licenses, isNotEmpty);
  });
}
