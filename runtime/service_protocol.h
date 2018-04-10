// Copyright 2017 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_RUNTIME_SERVICE_PROTOCOL_H_
#define FLUTTER_RUNTIME_SERVICE_PROTOCOL_H_

#include <map>
#include <mutex>
#include <set>
#include <string>

#include "flutter/fml/task_runner.h"
#include "lib/fxl/macros.h"
#include "lib/fxl/strings/string_view.h"
#include "lib/fxl/synchronization/thread_annotations.h"
#include "third_party/rapidjson/rapidjson/document.h"

namespace blink {

class ServiceProtocol {
 public:
  static const fxl::StringView kScreenshotExtensionName;
  static const fxl::StringView kScreenshotSkpExtensionName;
  static const fxl::StringView kRunInViewExtensionName;
  static const fxl::StringView kFlushUIThreadTasksExtensionName;
  static const fxl::StringView kSetAssetBundlePathExtensionName;

  class Handler {
   public:
    struct Description {
      int64_t isolate_port = 0 /* illegal port by default. */;
      std::string isolate_name;

      Description() {}

      Description(int64_t p_isolate_port, std::string p_isolate_name)
          : isolate_port(p_isolate_port),
            isolate_name(std::move(p_isolate_name)) {}

      void Write(Handler* handler,
                 rapidjson::Value& value,
                 rapidjson::MemoryPoolAllocator<>& allocator) const;
    };

    using ServiceProtocolMap = std::map<fxl::StringView, fxl::StringView>;

    virtual fxl::RefPtr<fxl::TaskRunner> GetServiceProtocolHandlerTaskRunner(
        fxl::StringView method) const = 0;

    virtual Description GetServiceProtocolDescription() const = 0;

    virtual bool HandleServiceProtocolMessage(
        fxl::StringView method,  // one if the extension names specified above.
        const ServiceProtocolMap& params,
        rapidjson::Document& response) = 0;
  };

  ServiceProtocol();

  ~ServiceProtocol();

  void ToggleHooks(bool set);

  void AddHandler(Handler* handler);

  void RemoveHandler(Handler* handler);

 private:
  const std::set<fxl::StringView> endpoints_;
  mutable std::mutex handlers_mutex_;
  std::set<Handler*> handlers_;

  FXL_WARN_UNUSED_RESULT
  static bool HandleMessage(const char* method,
                            const char** param_keys,
                            const char** param_values,
                            intptr_t num_params,
                            void* user_data,
                            const char** json_object);
  FXL_WARN_UNUSED_RESULT
  static bool HandleMessage(fxl::StringView method,
                            const Handler::ServiceProtocolMap& params,
                            ServiceProtocol* service_protocol,
                            rapidjson::Document& response);
  FXL_WARN_UNUSED_RESULT
  bool HandleMessage(fxl::StringView method,
                     const Handler::ServiceProtocolMap& params,
                     rapidjson::Document& response) const;

  FXL_WARN_UNUSED_RESULT
  bool HandleListViewsMethod(rapidjson::Document& response) const;

  FXL_DISALLOW_COPY_AND_ASSIGN(ServiceProtocol);
};

}  // namespace blink

#endif  // FLUTTER_RUNTIME_SERVICE_PROTOCOL_H_
