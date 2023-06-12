// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
#include "url_launcher_plugin.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <windows.h>

#include <memory>
#include <optional>
#include <sstream>
#include <string>

namespace url_launcher_plugin {

namespace {

using flutter::EncodableMap;
using flutter::EncodableValue;

// Converts the given UTF-8 string to UTF-16.
std::wstring Utf16FromUtf8(const std::string& utf8_string) {
  if (utf8_string.empty()) {
    return std::wstring();
  }
  int target_length =
      ::MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, utf8_string.data(),
                            static_cast<int>(utf8_string.length()), nullptr, 0);
  if (target_length == 0) {
    return std::wstring();
  }
  std::wstring utf16_string;
  utf16_string.resize(target_length);
  int converted_length =
      ::MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, utf8_string.data(),
                            static_cast<int>(utf8_string.length()),
                            utf16_string.data(), target_length);
  if (converted_length == 0) {
    return std::wstring();
  }
  return utf16_string;
}

// Returns the URL argument from |method_call| if it is present, otherwise
// returns an empty string.
std::string GetUrlArgument(const flutter::MethodCall<>& method_call) {
  std::string url;
  const auto* arguments = std::get_if<EncodableMap>(method_call.arguments());
  if (arguments) {
    auto url_it = arguments->find(EncodableValue("url"));
    if (url_it != arguments->end()) {
      url = std::get<std::string>(url_it->second);
    }
  }
  return url;
}

}  // namespace

// static
void UrlLauncherPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrar* registrar) {
  auto channel = std::make_unique<flutter::MethodChannel<>>(
      registrar->messenger(), "plugins.flutter.io/url_launcher_windows",
      &flutter::StandardMethodCodec::GetInstance());

  std::unique_ptr<UrlLauncherPlugin> plugin =
      std::make_unique<UrlLauncherPlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto& call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

UrlLauncherPlugin::UrlLauncherPlugin()
    : system_apis_(std::make_unique<SystemApisImpl>()) {}

UrlLauncherPlugin::UrlLauncherPlugin(std::unique_ptr<SystemApis> system_apis)
    : system_apis_(std::move(system_apis)) {}

UrlLauncherPlugin::~UrlLauncherPlugin() = default;

void UrlLauncherPlugin::HandleMethodCall(
    const flutter::MethodCall<>& method_call,
    std::unique_ptr<flutter::MethodResult<>> result) {
  if (method_call.method_name().compare("launch") == 0) {
    std::string url = GetUrlArgument(method_call);
    if (url.empty()) {
      result->Error("argument_error", "No URL provided");
      return;
    }

    std::optional<std::string> error = LaunchUrl(url);
    if (error) {
      result->Error("open_error", error.value());
      return;
    }
    result->Success(EncodableValue(true));
  } else if (method_call.method_name().compare("canLaunch") == 0) {
    std::string url = GetUrlArgument(method_call);
    if (url.empty()) {
      result->Error("argument_error", "No URL provided");
      return;
    }

    bool can_launch = CanLaunchUrl(url);
    result->Success(EncodableValue(can_launch));
  } else {
    result->NotImplemented();
  }
}

bool UrlLauncherPlugin::CanLaunchUrl(const std::string& url) {
  size_t separator_location = url.find(":");
  if (separator_location == std::string::npos) {
    return false;
  }
  std::wstring scheme = Utf16FromUtf8(url.substr(0, separator_location));

  HKEY key = nullptr;
  if (system_apis_->RegOpenKeyExW(HKEY_CLASSES_ROOT, scheme.c_str(), 0,
                                  KEY_QUERY_VALUE, &key) != ERROR_SUCCESS) {
    return false;
  }
  bool has_handler =
      system_apis_->RegQueryValueExW(key, L"URL Protocol", nullptr, nullptr,
                                     nullptr) == ERROR_SUCCESS;
  system_apis_->RegCloseKey(key);
  return has_handler;
}

std::optional<std::string> UrlLauncherPlugin::LaunchUrl(
    const std::string& url) {
  std::wstring url_wide = Utf16FromUtf8(url);

  int status = static_cast<int>(reinterpret_cast<INT_PTR>(
      system_apis_->ShellExecuteW(nullptr, TEXT("open"), url_wide.c_str(),
                                  nullptr, nullptr, SW_SHOWNORMAL)));

  // Per ::ShellExecuteW documentation, anything >32 indicates success.
  if (status <= 32) {
    std::ostringstream error_message;
    error_message << "Failed to open " << url << ": ShellExecute error code "
                  << status;
    return std::optional<std::string>(error_message.str());
  }
  return std::nullopt;
}

}  // namespace url_launcher_plugin
