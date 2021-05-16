// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <Windows.h>
#include <winrt/base.h>

#include <algorithm>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>

#include "flutter/fml/command_line.h"
#include "flutter/shell/platform/windows/string_conversion.h"
#include "flutter/shell/platform/windows/uwptool_utils.h"

namespace {

// Prints a list of installed UWP apps to stdout.
void PrintInstalledApps() {
  flutter::ApplicationStore app_store;
  for (const flutter::Application& app : app_store.GetApps()) {
    std::wcout << app.GetPackageFamily() << std::endl;
  }
}

// Launches the app installed on the system with the specified package.
//
// Returns -1 if no matching app, or multiple matching apps are found, or if
// the app fails to launch. Otherwise, the process ID of the launched app is
// returned.
int LaunchApp(const std::wstring_view package_family,
              const std::wstring_view args) {
  flutter::ApplicationStore app_store;
  for (flutter::Application& app : app_store.GetApps(package_family)) {
    int process_id = app.Launch(args);
    if (process_id != -1) {
      return process_id;
    }
  }
  return -1;
}

// Installs the app in the specified build output directory.
//
// Returns true on success.
bool InstallApp(const std::wstring_view package_uri,
                const std::vector<std::wstring>& dependency_uris) {
  flutter::ApplicationStore app_store;
  if (app_store.InstallApp(package_uri, dependency_uris)) {
    std::wcerr << L"Installed application " << package_uri << std::endl;
    return true;
  }
  return false;
}

// Uninstalls the app with the specified package.
//
// Returns true on success.
bool UninstallApp(const std::wstring_view package_family) {
  bool success = true;
  flutter::ApplicationStore app_store;
  for (flutter::Application& app : app_store.GetApps(package_family)) {
    if (app.Uninstall()) {
      std::wcerr << L"Uninstalled application " << app.GetPackageFullName()
                 << std::endl;
    } else {
      std::wcerr << L"error: Failed to uninstall application "
                 << app.GetPackageFullName() << std::endl;
      success = false;
    }
  }
  return success;
}

// Prints the command usage to stderr.
void PrintUsage() {
  std::cerr << "usage: uwptool COMMAND [ARGUMENTS]" << std::endl
            << "commands:" << std::endl
            << "  listapps                       list all apps" << std::endl
            << "  launch PACKAGE_FAMILY          launch an app" << std::endl
            << "  install PACKAGE_URI DEP_URI... install an app" << std::endl
            << "  uninstall PACKAGE_FAMILY       uninstall an app" << std::endl;
}

}  // namespace

int main(int argc, char** argv) {
  winrt::init_apartment();

  auto command_line = fml::CommandLineFromArgcArgv(argc, argv);
  if (command_line.positional_args().size() < 1) {
    PrintUsage();
    return 1;
  }

  const std::vector<std::string>& args = command_line.positional_args();
  std::string command = args[0];
  if (command == "listapps") {
    PrintInstalledApps();
    return 0;
  } else if (command == "launch") {
    if (args.size() < 2) {
      PrintUsage();
      return 1;
    }

    // Get the package family name.
    std::string package_family = args[1];

    // Concatenate the remaining args, comma-separated.
    std::ostringstream app_args;
    for (int i = 2; i < args.size(); ++i) {
      app_args << args[i];
      if (i < args.size() - 1) {
        app_args << ",";
      }
    }
    int process_id = LaunchApp(flutter::Utf16FromUtf8(package_family),
                               flutter::Utf16FromUtf8(app_args.str()));
    if (process_id == -1) {
      std::cerr << "error: Failed to launch app with package family "
                << package_family << std::endl;
      return 1;
    }

    // Write an informative message for the user to stderr.
    std::cerr << "Launched app with package family " << package_family
              << ". PID: " << std::endl;
    // Write the PID to stdout. The flutter tool reads this value in.
    std::cout << process_id << std::endl;
    return 0;
  } else if (command == "install") {
    if (args.size() < 2) {
      PrintUsage();
      return 1;
    }
    std::wstring package_uri = flutter::Utf16FromUtf8(args[1]);
    std::vector<std::wstring> dependency_uris;
    for (int i = 2; i < args.size(); ++i) {
      dependency_uris.push_back(flutter::Utf16FromUtf8(args[i]));
    }
    return InstallApp(package_uri, dependency_uris) ? 0 : 1;
  } else if (command == "uninstall") {
    if (args.size() < 2) {
      PrintUsage();
      return 1;
    }
    std::string package_family = args[1];
    return UninstallApp(flutter::Utf16FromUtf8(package_family)) ? 0 : 1;
  }

  std::cerr << "Unknown command: " << command << std::endl;
  PrintUsage();
  return 1;
}
