// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/command_line.h"

#include <windows.h>

#include <Shellapi.h>
#include <memory>

namespace fml {

CommandLine CommandLineFromWideArgv(int argc, const wchar_t* const* argv) {
  std::vector<std::string> utf8_argv;
  for (int i = 0; i < argc; ++i) {
    const wchar_t* arg = argv[i];
    int arg_len = WideCharToMultiByte(CP_UTF8, 0, arg, wcslen(arg), nullptr, 0,
                                      nullptr, nullptr);
    std::string utf8_arg(arg_len, 0);
    WideCharToMultiByte(CP_UTF8, 0, arg, wcslen(arg), utf8_arg.data(),
                        utf8_arg.size(), nullptr, nullptr);
    utf8_argv.push_back(std::move(utf8_arg));
  }
  return CommandLineFromIterators(utf8_argv.begin(), utf8_argv.end());
}

std::optional<CommandLine> CommandLineFromPlatform() {
  wchar_t* command_line = GetCommandLineW();
  int unicode_argc;
  std::unique_ptr<wchar_t*[], decltype(::LocalFree)*> unicode_argv(
      CommandLineToArgvW(command_line, &unicode_argc), ::LocalFree);
  if (!unicode_argv) {
    return std::nullopt;
  }
  return CommandLineFromWideArgv(unicode_argc, unicode_argv.get());
}

}  // namespace fml
