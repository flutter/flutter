// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Checks whether [thisVersion] and [thatVersion] have the same semver
/// identifier without extra platform specific information.
bool isSameSdkVersion(String thisVersion, String thatVersion) =>
    thisVersion?.split(' ')?.first == thatVersion?.split(' ')?.first;
