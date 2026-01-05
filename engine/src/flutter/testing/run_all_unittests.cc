// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <fstream>
#include <iostream>
#include <optional>
#include <string>

#include "flutter/fml/backtrace.h"
#include "flutter/fml/build_config.h"
#include "flutter/fml/command_line.h"
#include "flutter/testing/debugger_detection.h"
#include "flutter/testing/test_args.h"
#include "flutter/testing/test_timeout_listener.h"
#include "gtest/gtest.h"

#ifdef FML_OS_IOS
#include <asl.h>
#endif  // FML_OS_IOS

namespace {

std::optional<fml::TimeDelta> GetTestTimeout() {
  const auto& command_line = flutter::testing::GetArgsForProcess();

  std::string timeout_seconds;
  if (!command_line.GetOptionValue("timeout", &timeout_seconds)) {
    // No timeout specified. Default to 300s.
    return fml::TimeDelta::FromSeconds(300u);
  }

  const auto seconds = std::stoi(timeout_seconds);

  if (seconds < 1) {
    return std::nullopt;
  }

  return fml::TimeDelta::FromSeconds(seconds);
}

/// Simple glob matcher for filtering tests in the list command.
/// Supports * and ? wildcards.
/// @param  name    The string to test against the filter.
/// @param  filter  The glob filter pattern.
/// @return true    If the name matches the filter.
/// @return false   Otherwise.
bool SimpleMatchesFilter(const std::string& name, const std::string& filter) {
  const char* p_name = name.c_str();
  const char* p_filter = filter.c_str();

  while (*p_filter) {
    if (*p_filter == '*') {
      while (*p_filter == '*') {
        p_filter++;
      }
      if (!*p_filter) {
        return true;
      }
      while (*p_name) {
        if (SimpleMatchesFilter(p_name, p_filter)) {
          return true;
        }
        p_name++;
      }
      return false;
    } else if (*p_filter == '?' || *p_filter == *p_name) {
      if (!*p_name) {
        return false;
      }
      p_filter++;
      p_name++;
    } else {
      return false;
    }
  }
  return !*p_name;
}

std::pair<std::string, std::string> ParseCommand(const std::string& input) {
  size_t space_pos = input.find(' ');
  if (space_pos != std::string::npos) {
    return {input.substr(0, space_pos), input.substr(space_pos + 1)};
  }
  return {input, ""};
}

std::vector<std::string> FindMatchingTests(const std::string& pattern) {
  std::vector<std::string> matches;
  const auto* unit_test = ::testing::UnitTest::GetInstance();
  for (int i = 0; i < unit_test->total_test_suite_count(); ++i) {
    const auto* test_suite = unit_test->GetTestSuite(i);
    for (int j = 0; j < test_suite->total_test_count(); ++j) {
      const auto* test_info = test_suite->GetTestInfo(j);
      std::string full_name =
          std::string(test_suite->name()) + "." + test_info->name();

      bool matched = false;
      if (pattern.empty()) {
        matched = true;
      } else {
        if (full_name.find(pattern) != std::string::npos) {
          matched = true;
        } else if (SimpleMatchesFilter(full_name, pattern)) {
          matched = true;
        }
      }

      if (matched) {
        matches.push_back(full_name);
      }
    }
  }
  return matches;
}

// RunInteractive function implementation
void RunInteractive() {
  std::string input;
  std::string last_filter;
  const std::string kHistoryFile = "flutter_unittests_last_cmd.txt";

  // Load last filter
  std::ifstream history_in(kHistoryFile);
  if (history_in) {
    std::getline(history_in, last_filter);
  }

  while (true) {
    std::cout << "\nInteractive Test Runner\n";
    std::cout << "-----------------------\n";
    std::cout << "Commands:\n";
    std::cout << "  list [filter]  : List tests (optional substring/glob)\n";
    std::cout << "  run [filter]   : Run tests (optional substring/glob)\n";
    std::cout << "  [enter]        : Run with last used filter ("
              << (last_filter.empty() ? "none" : last_filter) << ")\n";
    std::cout << "  q, quit, exit  : Exit\n";
    std::cout << "\n> ";

    if (!std::getline(std::cin, input)) {
      break;
    }

    if (input == "q" || input == "quit" || input == "exit") {
      break;
    }

    std::string command;
    std::string argument;

    if (input.empty()) {
      if (!last_filter.empty()) {
        command = "run";
        argument = last_filter;
      } else {
        continue;
      }
    } else {
      auto [cmd, arg] = ParseCommand(input);
      command = cmd;
      argument = arg;
    }

    if (command == "list" || command == "run") {
      std::vector<std::string> matches = FindMatchingTests(argument);
      size_t match_count = matches.size();

      if (command == "list") {
        std::cout << "\nMatching Tests (" << match_count << "):\n";
        for (const auto& name : matches) {
          std::cout << "  " << name << "\n";
        }
      } else if (command == "run") {
        if (match_count == 0) {
          std::cout << "No tests matched '" << argument << "'.\n";
          continue;
        }

        std::string filter = argument.empty() ? "*" : argument;
        // Auto-wrap substring in * if it doesn't look like a glob, to easier
        // invoke gtest filter
        bool looks_like_glob = argument.find('*') != std::string::npos ||
                               argument.find('?') != std::string::npos;
        if (!argument.empty() && !looks_like_glob) {
          filter = "*" + argument + "*";
        }

        GTEST_FLAG_SET(filter, filter);
        last_filter = filter;

        // Save filter to history
        std::ofstream history_out(kHistoryFile);
        if (history_out) {
          history_out << last_filter;
        }

        std::cout << "\nRunning " << match_count
                  << " tests with filter: " << filter << "\n";
        // Ignore result invocation in interactive mode
        (void)RUN_ALL_TESTS();

        // Reset filter
        GTEST_FLAG_SET(filter, "*");
      }
    } else {
      std::cout << "Unknown command.\n";
    }
  }
}

}  // namespace

int main(int argc, char** argv) {
  fml::InstallCrashHandler();

  flutter::testing::SetArgsForProcess(argc, argv);

  const auto& command_line = flutter::testing::GetArgsForProcess();
  if (command_line.HasOption("interactive")) {
    ::testing::InitGoogleTest(&argc, argv);
    RunInteractive();
    return 0;
  }

#ifdef FML_OS_IOS
  asl_log_descriptor(NULL, NULL, ASL_LEVEL_NOTICE, STDOUT_FILENO,
                     ASL_LOG_DESCRIPTOR_WRITE);
  asl_log_descriptor(NULL, NULL, ASL_LEVEL_ERR, STDERR_FILENO,
                     ASL_LOG_DESCRIPTOR_WRITE);
#endif  // FML_OS_IOS

  ::testing::InitGoogleTest(&argc, argv);
  GTEST_FLAG_SET(death_test_style, "threadsafe");

  // Check if the user has specified a timeout.
  const auto timeout = GetTestTimeout();
  if (!timeout.has_value()) {
    FML_LOG(INFO) << "Timeouts disabled via a command line flag.";
    return RUN_ALL_TESTS();
  }

  // Check if the user is debugging the process.
  if (flutter::testing::GetDebuggerStatus() ==
      flutter::testing::DebuggerStatus::kAttached) {
    FML_LOG(INFO) << "Debugger is attached. Suspending test timeouts.";
    return RUN_ALL_TESTS();
  }

  auto timeout_listener =
      new flutter::testing::TestTimeoutListener(timeout.value());
  auto& listeners = ::testing::UnitTest::GetInstance()->listeners();
  listeners.Append(timeout_listener);
  auto result = RUN_ALL_TESTS();
  delete listeners.Release(timeout_listener);
  return result;
}
