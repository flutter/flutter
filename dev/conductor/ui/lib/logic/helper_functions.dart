// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Function that converts the cherrypick captured by input forms from string to
// a string array
List<String> cherrypickStringtoArray(String? cherrypickString) {
  return cherrypickString == '' || cherrypickString == null ? <String>[] : cherrypickString.split(',');
}
