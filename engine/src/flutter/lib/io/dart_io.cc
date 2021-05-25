// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/io/dart_io.h"

#include "flutter/fml/logging.h"
#include "third_party/dart/runtime/include/bin/dart_io_api.h"
#include "third_party/dart/runtime/include/dart_api.h"
#include "third_party/tonic/converter/dart_converter.h"
#include "third_party/tonic/logging/dart_error.h"

using tonic::LogIfError;
using tonic::ToDart;

namespace flutter {

void DartIO::InitForIsolate(bool may_insecurely_connect_to_all_domains,
                            std::string domain_network_policy) {
  Dart_Handle io_lib = Dart_LookupLibrary(ToDart("dart:io"));
  Dart_Handle result = Dart_SetNativeResolver(io_lib, dart::bin::LookupIONative,
                                              dart::bin::LookupIONativeSymbol);
  FML_CHECK(!LogIfError(result));

  Dart_Handle embedder_config_type =
      Dart_GetNonNullableType(io_lib, ToDart("_EmbedderConfig"), 0, nullptr);
  FML_CHECK(!LogIfError(embedder_config_type));

  Dart_Handle allow_insecure_connections_result = Dart_SetField(
      embedder_config_type, ToDart("_mayInsecurelyConnectToAllDomains"),
      ToDart(may_insecurely_connect_to_all_domains));
  FML_CHECK(!LogIfError(allow_insecure_connections_result));

  Dart_Handle dart_args[1];
  dart_args[0] = ToDart(domain_network_policy);
  Dart_Handle set_domain_network_policy_result = Dart_Invoke(
      embedder_config_type, ToDart("_setDomainPolicies"), 1, dart_args);
  FML_CHECK(!LogIfError(set_domain_network_policy_result));

  Dart_Handle ui_lib = Dart_LookupLibrary(ToDart("dart:ui"));
  Dart_Handle dart_validate_args[1];
  dart_validate_args[0] = ToDart(may_insecurely_connect_to_all_domains);
  Dart_Handle http_connection_hook_closure =
      Dart_Invoke(ui_lib, ToDart("_getHttpConnectionHookClosure"),
                  /*number_of_arguments=*/1, dart_validate_args);
  FML_CHECK(!LogIfError(http_connection_hook_closure));
  Dart_Handle http_lib = Dart_LookupLibrary(ToDart("dart:_http"));
  FML_CHECK(!LogIfError(http_lib));
  Dart_Handle set_http_connection_hook_result = Dart_SetField(
      http_lib, ToDart("_httpConnectionHook"), http_connection_hook_closure);
  FML_CHECK(!LogIfError(set_http_connection_hook_result));
}

}  // namespace flutter
