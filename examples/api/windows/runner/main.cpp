// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <flutter/generated_plugin_registrant.h>
#include <flutter/dart_project.h>
#include <flutter/flutter_engine.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

#include <algorithm>
#include <cstdlib>
#include <sstream>

std::vector<std::string> GetEngineSwitches() {
  std::vector<std::string> switches;
  // Read engine switches from the environment in debug/profile. If release mode
  // support is needed in the future, it should likely use a whitelist.
  constexpr int BUF_LEN = 512;
  char buffer[BUF_LEN];

  const char* switch_count_key = "FLUTTER_ENGINE_SWITCHES";
  const int kMaxSwitchCount = 50;
  size_t retval;
  getenv_s(&retval, buffer, BUF_LEN, switch_count_key);
  if (retval == 0) {
    return switches;
  }
  
  int switch_count = std::min(kMaxSwitchCount, atoi(buffer));
  for (int i = 1; i <= switch_count; ++i) {
    std::ostringstream switch_key;
    switch_key << "FLUTTER_ENGINE_SWITCH_" << i;
    getenv_s(&retval, buffer, BUF_LEN, switch_key.str().c_str());
    if (retval == 0) {
      continue;
    }

    switches.push_back(buffer);
  }

  return switches;
}

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  auto const engine{std::make_shared<flutter::FlutterEngine>(project)};
  RegisterPlugins(engine.get());
  engine->Run();

  std::vector<std::string> engine_switches = GetEngineSwitches();
  bool const enable_multi_window = std::any_of(
      engine_switches.begin(), engine_switches.end(),
      [](std::string const& arg) { return arg == "enable-multi-window=true"; });
  if (!enable_multi_window) {
    FlutterWindow window(project);
    Win32Window::Point origin(10, 10);
    Win32Window::Size size(1280, 720);
    if (!window.CreateAndShow(L"flutter_api_samples", origin, size)) {
      return EXIT_FAILURE;
    }
    window.SetQuitOnClose(true);
  }

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
