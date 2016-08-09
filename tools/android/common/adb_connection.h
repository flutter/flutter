// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef TOOLS_ANDROID_COMMON_ADB_CONNECTION_H_
#define TOOLS_ANDROID_COMMON_ADB_CONNECTION_H_

namespace tools {

// Creates a socket that can forward to a host socket through ADB.
// The format of forward_to is <port>:<ip_address>.
// Returns the socket handle, or -1 on any error.
int ConnectAdbHostSocket(const char* forward_to);

}  // namespace tools

#endif  // TOOLS_ANDROID_COMMON_ADB_CONNECTION_H_

