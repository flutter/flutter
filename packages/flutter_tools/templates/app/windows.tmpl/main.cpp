#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include <chrono>
#include <codecvt>
#include <iostream>
#include <string>
#include <vector>

#include "flutter/generated_plugin_registrant.h"
#include "win32_window.h"
#include "window_configuration.h"

namespace {

// Returns the path of the directory containing this executable, or an empty
// string if the directory cannot be found.
std::string GetExecutableDirectory() {
  wchar_t buffer[MAX_PATH];
  if (GetModuleFileName(nullptr, buffer, MAX_PATH) == 0) {
    std::cerr << "Couldn't locate executable" << std::endl;
    return "";
  }
  std::wstring_convert<std::codecvt_utf8_utf16<wchar_t>> wide_to_utf8;
  std::string executable_path = wide_to_utf8.to_bytes(buffer);
  size_t last_separator_position = executable_path.find_last_of('\\');
  if (last_separator_position == std::string::npos) {
    std::cerr << "Unabled to find parent directory of " << executable_path
              << std::endl;
    return "";
  }
  return executable_path.substr(0, last_separator_position);
}

}  // namespace

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    ::AllocConsole();
  }

  // Resources are located relative to the executable.
  std::string base_directory = GetExecutableDirectory();
  if (base_directory.empty()) {
    base_directory = ".";
  }
  std::string data_directory = base_directory + "\\data";
  std::string assets_path = data_directory + "\\flutter_assets";
  std::string icu_data_path = data_directory + "\\icudtl.dat";

  // Arguments for the Flutter Engine.
  std::vector<std::string> arguments;

  // Top-level window frame.
  Win32Window::Point origin(kFlutterWindowOriginX, kFlutterWindowOriginY);
  Win32Window::Size size(kFlutterWindowWidth, kFlutterWindowHeight);

  flutter::FlutterViewController flutter_controller(
      icu_data_path, size.width, size.height, assets_path, arguments);
  RegisterPlugins(&flutter_controller);

  // Create a top-level win32 window to host the Flutter view.
  Win32Window window;
  if (!window.CreateAndShow(kFlutterWindowTitle, origin, size)) {
    return EXIT_FAILURE;
  }

  // Parent and resize Flutter view into top-level window.
  window.SetChildContent(flutter_controller.view()->GetNativeWindow());

  // Run messageloop with a hook for flutter_controller to do work until
  // the window is closed.
  std::chrono::nanoseconds wait_duration(0);
  // Run until the window is closed.
  while (window.GetHandle() != nullptr) {
    MsgWaitForMultipleObjects(0, nullptr, FALSE,
                              static_cast<DWORD>(wait_duration.count() / 1000),
                              QS_ALLINPUT);
    MSG message;
    // All pending Windows messages must be processed; MsgWaitForMultipleObjects
    // won't return again for items left in the queue after PeekMessage.
    while (PeekMessage(&message, nullptr, 0, 0, PM_REMOVE)) {
      if (message.message == WM_QUIT) {
        window.Destroy();
        break;
      }
      TranslateMessage(&message);
      DispatchMessage(&message);
    }
    // Allow Flutter to process its messages.
    // TODO: Consider interleaving processing on a per-message basis to avoid
    // the possibility of one queue starving the other.
    wait_duration = flutter_controller.ProcessMessages();
  }

  return EXIT_SUCCESS;
}
