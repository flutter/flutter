// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_CLIENT_WRAPPER_INCLUDE_FLUTTER_DART_PROJECT_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_CLIENT_WRAPPER_INCLUDE_FLUTTER_DART_PROJECT_H_

#include <string>
#include <vector>

namespace flutter {

// A set of Flutter and Dart assets used to initialize a Flutter engine.
class DartProject {
 public:
  // Creates a DartProject from a directory path. The directory should contain
  // the following top-level items:
  // - icudtl.dat (provided as a resource by the Flutter tool)
  // - flutter_assets (as built by the Flutter tool)
  //
  // The path can either be absolute, or relative to the directory containing
  // the running executable.
  explicit DartProject(const std::wstring& path) {
    assets_path_ = path + L"\\flutter_assets";
    icu_data_path_ = path + L"\\icudtl.dat";
  }

  ~DartProject() = default;

  // Switches to pass to the Flutter engine. See
  // https://github.com/flutter/engine/blob/master/shell/common/switches.h
  // for details. Not all switches will apply to embedding mode. Switches have
  // not stability guarantee, and are subject to change without notice.
  //
  // Note: This WILL BE REMOVED in the future. If you call this, please see
  // https://github.com/flutter/flutter/issues/38569.
  void SetEngineSwitches(const std::vector<std::string>& switches) {
    engine_switches_ = switches;
  }

 private:
  // Accessors for internals are private, so that they can be changed if more
  // flexible options for project structures are needed later without it
  // being a breaking change. Provide access to internal classes that need
  // them.
  friend class FlutterViewController;
  friend class DartProjectTest;

  const std::wstring& assets_path() const { return assets_path_; }
  const std::wstring& icu_data_path() const { return icu_data_path_; }
  const std::vector<std::string>& engine_switches() const {
    return engine_switches_;
  }

  // The path to the assets directory.
  std::wstring assets_path_;
  // The path to the ICU data.
  std::wstring icu_data_path_;
  // Switches to pass to the engine.
  std::vector<std::string> engine_switches_;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_CLIENT_WRAPPER_INCLUDE_FLUTTER_DART_PROJECT_H_
