// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <string>

#include "flutter/lib/ui/isolate_name_server/isolate_name_server.h"
#include "flutter/lib/ui/isolate_name_server/isolate_name_server_natives.h"
#include "flutter/lib/ui/ui_dart_state.h"
#include "third_party/tonic/dart_binding_macros.h"
#include "third_party/tonic/dart_library_natives.h"

namespace blink {

Dart_Handle IsolateNameServerNatives::LookupPortByName(
    const std::string& name) {
  IsolateNameServer* name_server =
      UIDartState::Current()->GetIsolateNameServer();
  Dart_Port port = name_server->LookupIsolatePortByName(name);
  if (port == ILLEGAL_PORT) {
    return Dart_Null();
  }
  return Dart_NewSendPort(port);
}

Dart_Handle IsolateNameServerNatives::RegisterPortWithName(
    Dart_Handle port_handle,
    const std::string& name) {
  IsolateNameServer* name_server =
      UIDartState::Current()->GetIsolateNameServer();
  Dart_Port port = ILLEGAL_PORT;
  Dart_SendPortGetId(port_handle, &port);
  if (!name_server->RegisterIsolatePortWithName(port, name)) {
    return Dart_False();
  }
  return Dart_True();
}

Dart_Handle IsolateNameServerNatives::RemovePortNameMapping(
    const std::string& name) {
  IsolateNameServer* name_server =
      UIDartState::Current()->GetIsolateNameServer();
  if (!name_server->RemoveIsolateNameMapping(name)) {
    return Dart_False();
  }
  return Dart_True();
}

#define FOR_EACH_BINDING(V)                         \
  V(IsolateNameServerNatives, LookupPortByName)     \
  V(IsolateNameServerNatives, RegisterPortWithName) \
  V(IsolateNameServerNatives, RemovePortNameMapping)

FOR_EACH_BINDING(DART_NATIVE_CALLBACK_STATIC)

#define DART_REGISTER_NATIVE_STATIC_(CLASS, METHOD) \
  DART_REGISTER_NATIVE_STATIC(CLASS, METHOD),

void IsolateNameServerNatives::RegisterNatives(
    tonic::DartLibraryNatives* natives) {
  natives->Register({FOR_EACH_BINDING(DART_REGISTER_NATIVE_STATIC_)});
}

}  // namespace blink
