// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef TOOLS_ANDROID_FORWARDER2_COMMAND_H_
#define TOOLS_ANDROID_FORWARDER2_COMMAND_H_

#include "base/basictypes.h"

namespace forwarder2 {

class Socket;

namespace command {

enum Type {
  ACCEPT_ERROR = 0,
  ACCEPT_SUCCESS,
  ACK,
  ADB_DATA_SOCKET_ERROR,
  ADB_DATA_SOCKET_SUCCESS,
  BIND_ERROR,
  BIND_SUCCESS,
  DATA_CONNECTION,
  HOST_SERVER_ERROR,
  HOST_SERVER_SUCCESS,
  KILL_ALL_LISTENERS,
  LISTEN,
  UNLISTEN,
  UNLISTEN_ERROR,
  UNLISTEN_SUCCESS,
};

}  // namespace command

bool ReadCommand(Socket* socket,
                 int* port_out,
                 command::Type* command_type_out);

// Helper function to read the command from the |socket| and return true if the
// |command| is equal to the given command parameter.
bool ReceivedCommand(command::Type command, Socket* socket);

bool SendCommand(command::Type command, int port, Socket* socket);

}  // namespace forwarder

#endif  // TOOLS_ANDROID_FORWARDER2_COMMAND_H_
