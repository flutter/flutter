// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Exit code constants.
///
/// From [the BSD sysexits manpage][manpage]. Not every constant here is used.
///
/// [manpage]: http://www.freebsd.org/cgi/man.cgi?query=sysexits
/// The command completely successfully.
const success = 0;

/// The command was used incorrectly.
const usage = 64;

/// The input data was incorrect.
const data = 65;

/// An input file did not exist or was unreadable.
const noInput = 66;

/// The user specified did not exist.
const noUser = 67;

/// The host specified did not exist.
const noHost = 68;

/// A service is unavailable.
const unavailable = 69;

/// An internal software error has been detected.
const software = 70;

/// An operating system error has been detected.
const os = 71;

/// Some system file did not exist or was unreadable.
const osFile = 72;

/// A user-specified output file cannot be created.
const cantCreate = 73;

/// An error occurred while doing I/O on some file.
const io = 74;

/// Temporary failure, indicating something that is not really an error.
const tempFail = 75;

/// The remote system returned something invalid during a protocol exchange.
const protocol = 76;

/// The user did not have sufficient permissions.
const noPerm = 77;

/// Something was unconfigured or mis-configured.
const config = 78;

/// No tests were ran.
const noTestsRan = 79;
