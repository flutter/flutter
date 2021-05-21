#include "flutter/shell/platform/windows/uwptool_commands.h"

#include <iostream>
#include <sstream>

#include "flutter/shell/platform/windows/string_conversion.h"
#include "flutter/shell/platform/windows/uwptool_utils.h"

namespace flutter {

bool ListAppsCommand::ValidateArgs(const std::vector<std::string>& args) const {
  return true;
}

int ListAppsCommand::Run(const std::vector<std::string>& args) const {
  flutter::ApplicationStore app_store;
  for (const flutter::Application& app : app_store.GetApps()) {
    std::wcout << app.GetPackageFamily() << std::endl;
  }
  return 0;
}

bool InstallCommand::ValidateArgs(const std::vector<std::string>& args) const {
  return args.size() >= 1;
}

int InstallCommand::Run(const std::vector<std::string>& args) const {
  std::wstring package_uri = flutter::Utf16FromUtf8(args[0]);
  std::vector<std::wstring> dependency_uris;
  for (int i = 1; i < args.size(); ++i) {
    dependency_uris.push_back(flutter::Utf16FromUtf8(args[i]));
  }
  flutter::ApplicationStore app_store;
  if (app_store.Install(package_uri, dependency_uris)) {
    std::wcerr << L"Installed application " << package_uri << std::endl;
    return 0;
  }
  return 1;
}

bool UninstallCommand::ValidateArgs(
    const std::vector<std::string>& args) const {
  return args.size() >= 1;
}

int UninstallCommand::Run(const std::vector<std::string>& args) const {
  flutter::ApplicationStore app_store;
  std::wstring package_family = flutter::Utf16FromUtf8(args[0]);
  return app_store.Uninstall(package_family) ? 0 : 1;
}

bool LaunchCommand::ValidateArgs(const std::vector<std::string>& args) const {
  return args.size() >= 1;
}

int LaunchCommand::Run(const std::vector<std::string>& args) const {
  // Get the package family name.
  std::string package_family = args[0];

  // Concatenate the remaining args, comma-separated.
  std::ostringstream app_args;
  for (int i = 1; i < args.size(); ++i) {
    app_args << args[i];
    if (i < args.size() - 1) {
      app_args << ",";
    }
  }
  flutter::ApplicationStore app_store;
  int process_id = app_store.Launch(flutter::Utf16FromUtf8(package_family),
                                    flutter::Utf16FromUtf8(app_args.str()));
  if (process_id == -1) {
    std::cerr << "error: Failed to launch app with package family "
              << package_family << " arguments [" << app_args.str() << "]"
              << std::endl;
    return 1;
  }

  // Write an informative message for the user to stderr.
  std::cerr << "Launched app with package family " << package_family
            << ". PID: " << std::endl;
  // Write the PID to stdout. The flutter tool reads this value in.
  std::cout << process_id << std::endl;
  return 0;
}

}  // namespace flutter
