// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <windows.h>

#include <memory>
#include <optional>
#include <sstream>
#include <string>

#include "messages.g.h"
#include "system_apis.h"

namespace url_launcher_windows {

class UrlLauncherPlugin : public flutter::Plugin, public UrlLauncherApi {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrar* registrar);

  UrlLauncherPlugin();

  // Creates a plugin instance with the given SystemApi instance.
  //
  // Exists for unit testing with mock implementations.
  UrlLauncherPlugin(std::unique_ptr<SystemApis> system_apis);

  virtual ~UrlLauncherPlugin();

  // Disallow copy and move.
  UrlLauncherPlugin(const UrlLauncherPlugin&) = delete;
  UrlLauncherPlugin& operator=(const UrlLauncherPlugin&) = delete;

  // UrlLauncherApi:
  ErrorOr<bool> CanLaunchUrl(const std::string& url) override;
  std::optional<FlutterError> LaunchUrl(const std::string& url) override;

 private:
  std::unique_ptr<SystemApis> system_apis_;
};

}  // namespace url_launcher_windows
