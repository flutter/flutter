// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library sync.http;

import 'dart:convert';
import 'dart:io'
    show
        BytesBuilder,
        ContentType,
        HttpException,
        HttpHeaders,
        RawSynchronousSocket;

part 'src/sync_http.dart';
part 'src/line_decoder.dart';
