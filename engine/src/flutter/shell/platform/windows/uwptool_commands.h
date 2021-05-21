// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_UWPTOOL_COMMANDS_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_UWPTOOL_COMMANDS_H_

#include <string>
#include <vector>

namespace flutter {

// A uwptool command that can be invoked as the first argument of the uwptool
// arguments list.
class Command {
 public:
  Command(const std::string_view name,
          const std::string_view usage,
          const std::string_view description)
      : name_(name), usage_(usage), description_(description) {}
  virtual ~Command() {}

  std::string GetCommandName() const { return name_; }
  std::string GetUsage() const { return usage_; }
  std::string GetDescription() const { return description_; }

  // Returns true if the arguments list constitute valid arguments for this
  // command.
  virtual bool ValidateArgs(const std::vector<std::string>& args) const = 0;

  // Invokes the command with the specified arguments list.
  virtual int Run(const std::vector<std::string>& args) const = 0;

 private:
  std::string name_;
  std::string usage_;
  std::string description_;
};

// Command that prints a list of all installed applications on the system.
class ListAppsCommand : public Command {
 public:
  ListAppsCommand()
      : Command("listapps",
                "listapps",
                "List installed apps by package family name") {}

  bool ValidateArgs(const std::vector<std::string>& args) const override;
  int Run(const std::vector<std::string>& args) const override;
};

// Command that installs the specified package and dependencies.
class InstallCommand : public Command {
 public:
  InstallCommand()
      : Command("install",
                "install PACKAGE_URI DEPENDENCY_URI...",
                "Install the specified package with all listed dependencies") {}

  bool ValidateArgs(const std::vector<std::string>& args) const override;
  int Run(const std::vector<std::string>& args) const override;
};

// Command that uninstalls the specified package.
class UninstallCommand : public Command {
 public:
  UninstallCommand()
      : Command("uninstall",
                "uninstall PACKAGE_FAMILY_NAME",
                "Uninstall the specified package") {}

  bool ValidateArgs(const std::vector<std::string>& args) const override;
  int Run(const std::vector<std::string>& args) const override;
};

// Launches the app installed on the system with the specified package.
//
// Returns -1 if no matching app, or multiple matching apps are found, or if
// the app fails to launch. Otherwise, the process ID of the launched app is
// returned.
class LaunchCommand : public Command {
 public:
  LaunchCommand()
      : Command("launch",
                "launch PACKAGE_FAMILY_NAME",
                "Launch the specified package") {}

  bool ValidateArgs(const std::vector<std::string>& args) const override;
  int Run(const std::vector<std::string>& args) const override;

 private:
  int LaunchApp(const std::wstring_view package_family,
                const std::wstring_view args) const;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_UWPTOOL_COMMANDS_H_
