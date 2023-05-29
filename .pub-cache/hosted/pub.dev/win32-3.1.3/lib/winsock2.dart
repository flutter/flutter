// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: directives_ordering

/// Support for programming against the Win32 Windows Socket 2 library on
/// Windows operating systems.
///
/// This library extends the core `win32` library with Windows Socket functions.
/// Since this library is somewhat specialist and many of its function names
/// (e.g. `send`, `connect`) are likely to conflict with other libraries or
/// programs, it is separately exported.
///
/// To add Winsock2 support to your app, use the additional line below:
///
/// ```dart
/// import 'package:win32/win32.dart';
/// import 'package:win32/winsock2.dart' as winsock2;
/// ```
///
/// Now you can call, for instance, `winsock2.connect()` or `winsock2.send()`.
///
/// The `winsock2` library will normally be used in conjunction with the main
/// `win32` library, and the latter will be required for constants and structs
/// used here.
library winsock2;

// Core Win32 APIs, constants and macros
export 'src/structs.g.dart'
    show
        ADDRINFO,
        FD_SET,
        IN_ADDR,
        SOCKADDR,
        TIMEVAL,
        HOSTENT,
        PROTOENT,
        SERVENT;
export 'src/constants_winsock.dart';

// Traditional C-style Windows APIs
export 'src/win32/ws2_32.g.dart';
