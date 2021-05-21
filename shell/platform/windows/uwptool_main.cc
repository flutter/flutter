// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <Windows.h>
#include <winrt/base.h>

#include <iomanip>
#include <iostream>
#include <map>
#include <memory>
#include <string>
#include <vector>

#include "flutter/fml/command_line.h"
#include "flutter/shell/platform/windows/uwptool_commands.h"

namespace {

using CommandMap = std::map<std::string, std::unique_ptr<flutter::Command>>;

// Prints the command usage to stderr.
void PrintUsage(const CommandMap& commands) {
  std::cerr << "usage: uwptool COMMAND [ARGUMENTS]" << std::endl;
  std::cerr << std::endl;
  std::cerr << "Available commands:" << std::endl;
  for (const auto& [command_name, command] : commands) {
    std::cerr << "  " << std::left << std::setw(15) << command_name
              << command->GetDescription() << std::endl;
  }
}

void PrintCommandUsage(const flutter::Command& command) {
  std::cerr << "usage: uwptool " << command.GetUsage() << std::endl;
}

}  // namespace

int main(int argc, char** argv) {
  winrt::init_apartment();

  // Register commands alphabetically, to make usage string clearer.
  CommandMap commands;
  commands.emplace("install", std::make_unique<flutter::InstallCommand>());
  commands.emplace("launch", std::make_unique<flutter::LaunchCommand>());
  commands.emplace("listapps", std::make_unique<flutter::ListAppsCommand>());
  commands.emplace("uninstall", std::make_unique<flutter::UninstallCommand>());

  // Parse command line arguments.
  auto command_line = fml::CommandLineFromArgcArgv(argc, argv);
  if (command_line.positional_args().size() < 1) {
    PrintUsage(commands);
    return 1;
  }
  std::vector<std::string> command_args(
      command_line.positional_args().begin() + 1,
      command_line.positional_args().end());

  // Determine the command.
  const std::string& command_name = command_line.positional_args()[0];
  const auto& it = commands.find(command_name);
  if (it == commands.end()) {
    std::cerr << "Unknown command: " << command_name << std::endl;
    PrintUsage(commands);
    return 1;
  }

  // Run the command.
  auto& command = it->second;
  if (!command->ValidateArgs(command_args)) {
    PrintCommandUsage(*command);
    return 1;
  }
  return command->Run(command_args);
}
