// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_RUNTIME_SERVICE_PROTOCOL_H_
#define FLUTTER_RUNTIME_SERVICE_PROTOCOL_H_

#include <map>
#include <set>
#include <shared_mutex>
#include <string>

#include "flutter/fml/compiler_specific.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/string_view.h"
#include "flutter/fml/synchronization/atomic_object.h"
#include "flutter/fml/synchronization/thread_annotations.h"
#include "flutter/fml/task_runner.h"
#include "rapidjson/document.h"

namespace blink {

class ServiceProtocol {
 public:
  static const fml::StringView kScreenshotExtensionName;
  static const fml::StringView kScreenshotSkpExtensionName;
  static const fml::StringView kRunInViewExtensionName;
  static const fml::StringView kFlushUIThreadTasksExtensionName;
  static const fml::StringView kSetAssetBundlePathExtensionName;

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

    using ServiceProtocolMap = std::map<fml::StringView, fml::StringView>;

    virtual fml::RefPtr<fml::TaskRunner> GetServiceProtocolHandlerTaskRunner(
        fml::StringView method) const = 0;

    virtual Description GetServiceProtocolDescription() const = 0;

    virtual bool HandleServiceProtocolMessage(
        fml::StringView method,  // one if the extension names specified above.
        const ServiceProtocolMap& params,
        rapidjson::Document& response) = 0;
  };

  ServiceProtocol();

  ~ServiceProtocol();

  void ToggleHooks(bool set);

  void AddHandler(Handler* handler, Handler::Description description);

  void RemoveHandler(Handler* handler);

  void SetHandlerDescription(Handler* handler,
                             Handler::Description description);

 private:
  const std::set<fml::StringView> endpoints_;
  mutable std::shared_timed_mutex handlers_mutex_;
  std::map<Handler*, fml::AtomicObject<Handler::Description>> handlers_;

  FML_WARN_UNUSED_RESULT
  static bool HandleMessage(const char* method,
                            const char** param_keys,
                            const char** param_values,
                            intptr_t num_params,
                            void* user_data,
                            const char** json_object);
  FML_WARN_UNUSED_RESULT
  static bool HandleMessage(fml::StringView method,
                            const Handler::ServiceProtocolMap& params,
                            ServiceProtocol* service_protocol,
                            rapidjson::Document& response);
  FML_WARN_UNUSED_RESULT
  bool HandleMessage(fml::StringView method,
                     const Handler::ServiceProtocolMap& params,
                     rapidjson::Document& response) const;

  FML_WARN_UNUSED_RESULT
  bool HandleListViewsMethod(rapidjson::Document& response) const;

  FML_DISALLOW_COPY_AND_ASSIGN(ServiceProtocol);
};

}  // namespace blink

#endif  // FLUTTER_RUNTIME_SERVICE_PROTOCOL_H_
