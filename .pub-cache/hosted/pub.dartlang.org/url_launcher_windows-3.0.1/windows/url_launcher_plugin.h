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

#include "system_apis.h"

namespace url_launcher_plugin {

class UrlLauncherPlugin : public flutter::Plugin {
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

  // Called when a method is called on the plugin channel.
  void HandleMethodCall(const flutter::MethodCall<>& method_call,
                        std::unique_ptr<flutter::MethodResult<>> result);

 private:
  // Returns whether or not the given URL has a registered handler.
  bool CanLaunchUrl(const std::string& url);

  // Attempts to launch the given URL. On failure, returns an error string.
  std::optional<std::string> LaunchUrl(const std::string& url);

  std::unique_ptr<SystemApis> system_apis_;
};

}  // namespace url_launcher_plugin
