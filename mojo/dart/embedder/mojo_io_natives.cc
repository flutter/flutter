// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <stdio.h>
#include <string.h>

#include "base/logging.h"
#include "base/macros.h"
#include "dart/runtime/include/dart_api.h"
#include "mojo/dart/embedder/builtin.h"
#include "mojo/dart/embedder/common.h"
#include "mojo/dart/embedder/io/internet_address.h"
#include "mojo/dart/embedder/isolate_data.h"

namespace mojo {
namespace dart {

#define MOJO_IO_NATIVE_LIST(V)                                                 \
  V(InternetAddress_Parse, 1)                                                  \
  V(InternetAddress_Reverse, 1)                                                \
  V(Platform_NumberOfProcessors, 0)                                            \
  V(Platform_OperatingSystem, 0)                                               \
  V(Platform_PathSeparator, 0)                                                 \
  V(Platform_LocalHostname, 0)                                                 \
  V(Platform_ExecutableName, 0)                                                \
  V(Platform_Environment, 0)                                                   \
  V(Platform_ExecutableArguments, 0)                                           \
  V(Platform_PackageRoot, 0)                                                   \
  V(Platform_GetVersion, 0)                                                    \

MOJO_IO_NATIVE_LIST(DECLARE_FUNCTION);

static struct NativeEntries {
  const char* name;
  Dart_NativeFunction function;
  int argument_count;
} MojoEntries[] = {MOJO_IO_NATIVE_LIST(REGISTER_FUNCTION)};

Dart_NativeFunction MojoIoNativeLookup(Dart_Handle name,
                                       int argument_count,
                                       bool* auto_setup_scope) {
  const char* function_name = nullptr;
  Dart_Handle result = Dart_StringToCString(name, &function_name);
  DART_CHECK_VALID(result);
  DCHECK(function_name != nullptr);
  DCHECK(auto_setup_scope != nullptr);
  *auto_setup_scope = true;
  size_t num_entries = arraysize(MojoEntries);
  for (size_t i = 0; i < num_entries; ++i) {
    const struct NativeEntries& entry = MojoEntries[i];
    if (!strcmp(function_name, entry.name) &&
        (entry.argument_count == argument_count)) {
      return entry.function;
    }
  }
  return nullptr;
}

const uint8_t* MojoIoNativeSymbol(Dart_NativeFunction nf) {
  size_t num_entries = arraysize(MojoEntries);
  for (size_t i = 0; i < num_entries; ++i) {
    const struct NativeEntries& entry = MojoEntries[i];
    if (entry.function == nf) {
      return reinterpret_cast<const uint8_t*>(entry.name);
    }
  }
  return nullptr;
}

void InternetAddress_Parse(Dart_NativeArguments arguments) {
  const char* address = DartEmbedder::GetStringArgument(arguments, 0);
  CHECK(address != NULL);
  RawAddr raw;
  int type = strchr(address, ':') == NULL ? InternetAddress::TYPE_IPV4
                                          : InternetAddress::TYPE_IPV6;
  intptr_t length = (type == InternetAddress::TYPE_IPV4) ?
      IPV4_RAW_ADDR_LENGTH : IPV6_RAW_ADDR_LENGTH;
  if (InternetAddress::Parse(type, address, &raw)) {
    Dart_SetReturnValue(arguments,
                        DartEmbedder::MakeUint8TypedData(&raw.bytes[0],
                                                         length));
  } else {
    DartEmbedder::SetNullReturn(arguments);
  }
}

void InternetAddress_Reverse(Dart_NativeArguments arguments) {
  uint8_t* addr = NULL;
  intptr_t addr_len = 0;
  DartEmbedder::GetTypedDataListArgument(arguments, 0, &addr, &addr_len);
  if (addr_len == 0) {
    DartEmbedder::SetNullReturn(arguments);
    return;
  }
  // IPv4 or IPv6 address length.
  CHECK((addr_len == 4) || (addr_len == 16));
  RawAddr raw_addr;
  for (intptr_t i = 0; i < addr_len; i++) {
    raw_addr.bytes[i] = addr[i];
  }
  free(addr);

  const intptr_t kMaxHostLength = 1025;
  char host[kMaxHostLength];
  intptr_t error_code = 0;
  const char* error_description = NULL;
  bool success = InternetAddress::Reverse(raw_addr, addr_len,
                                          &host[0], kMaxHostLength,
                                          &error_code, &error_description);
  // List of length 2.
  // [0] -> code (0 indicates success).
  // [1] -> error or host.
  Dart_Handle result_list = Dart_NewList(2);
  Dart_ListSetAt(result_list, 0, Dart_NewInteger(error_code));
  if (success) {
    Dart_ListSetAt(result_list, 1, DartEmbedder::NewCString(host));
  } else {
    Dart_ListSetAt(result_list, 1, DartEmbedder::NewCString(error_description));
  }
  Dart_SetReturnValue(arguments, result_list);
}

void Platform_NumberOfProcessors(Dart_NativeArguments arguments) {
  // TODO(johnmccutchan): Is an implementation needed?
  DartEmbedder::SetNullReturn(arguments);
}

void Platform_OperatingSystem(Dart_NativeArguments arguments) {
  // TODO(johnmccutchan): Is an implementation needed?
  DartEmbedder::SetNullReturn(arguments);
}

void Platform_PathSeparator(Dart_NativeArguments arguments) {
  // TODO(johnmccutchan): Is an implementation needed?
  DartEmbedder::SetNullReturn(arguments);
}

void Platform_LocalHostname(Dart_NativeArguments arguments) {
  // TODO(johnmccutchan): Is an implementation needed?
  DartEmbedder::SetNullReturn(arguments);
}

void Platform_ExecutableName(Dart_NativeArguments arguments) {
  // TODO(johnmccutchan): Is an implementation needed?
  DartEmbedder::SetNullReturn(arguments);
}

void Platform_Environment(Dart_NativeArguments arguments) {
  // TODO(johnmccutchan): Is an implementation needed?
  Dart_SetReturnValue(arguments, Dart_NewList(0));
}

void Platform_ExecutableArguments(Dart_NativeArguments arguments) {
  // TODO(johnmccutchan): Is an implementation needed?
  DartEmbedder::SetNullReturn(arguments);
}

void Platform_PackageRoot(Dart_NativeArguments arguments) {
  const char* package_root = "";
  Dart_Isolate isolate = Dart_CurrentIsolate();
  DCHECK(isolate != nullptr);
  void* data = Dart_IsolateData(isolate);
  IsolateData* isolate_data = reinterpret_cast<IsolateData*>(data);
  if (isolate_data != nullptr) {
    package_root = isolate_data->package_root.c_str();
  }
  Dart_SetReturnValue(arguments, Dart_NewStringFromCString(package_root));
}

void Platform_GetVersion(Dart_NativeArguments arguments) {
  // TODO(johnmccutchan): Consider incorporating Mojo version.
  Dart_SetReturnValue(arguments,
                      Dart_NewStringFromCString(Dart_VersionString()));
}

}  // namespace dart
}  // namespace mojo
