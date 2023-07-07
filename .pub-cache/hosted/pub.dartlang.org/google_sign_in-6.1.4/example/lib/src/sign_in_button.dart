// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

export 'sign_in_button/stub.dart'
    if (dart.library.js_util) 'sign_in_button/web.dart'
    if (dart.library.io) 'sign_in_button/mobile.dart';
