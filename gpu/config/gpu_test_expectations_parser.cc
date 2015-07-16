// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/config/gpu_test_expectations_parser.h"

#include "base/files/file_util.h"
#include "base/logging.h"
#include "base/strings/string_number_conversions.h"
#include "base/strings/string_split.h"
#include "base/strings/string_util.h"
#include "base/strings/stringprintf.h"

namespace gpu {

namespace {

enum LineParserStage {
  kLineParserBegin = 0,
  kLineParserBugID,
  kLineParserConfigs,
  kLineParserColon,
  kLineParserTestName,
  kLineParserEqual,
  kLineParserExpectations,
};

enum Token {
  // os
  kConfigWinXP = 0,
  kConfigWinVista,
  kConfigWin7,
  kConfigWin8,
  kConfigWin,
  kConfigMacLeopard,
  kConfigMacSnowLeopard,
  kConfigMacLion,
  kConfigMacMountainLion,
  kConfigMacMavericks,
  kConfigMac,
  kConfigLinux,
  kConfigChromeOS,
  kConfigAndroid,
  // gpu vendor
  kConfigNVidia,
  kConfigAMD,
  kConfigIntel,
  kConfigVMWare,
  // build type
  kConfigRelease,
  kConfigDebug,
  // expectation
  kExpectationPass,
  kExpectationFail,
  kExpectationFlaky,
  kExpectationTimeout,
  kExpectationSkip,
  // separator
  kSeparatorColon,
  kSeparatorEqual,

  kNumberOfExactMatchTokens,

  // others
  kConfigGPUDeviceID,
  kTokenComment,
  kTokenWord,
};

struct TokenInfo {
  const char* name;
  int32 flag;
};

const TokenInfo kTokenData[] = {
  { "xp", GPUTestConfig::kOsWinXP },
  { "vista", GPUTestConfig::kOsWinVista },
  { "win7", GPUTestConfig::kOsWin7 },
  { "win8", GPUTestConfig::kOsWin8 },
  { "win", GPUTestConfig::kOsWin },
  { "leopard", GPUTestConfig::kOsMacLeopard },
  { "snowleopard", GPUTestConfig::kOsMacSnowLeopard },
  { "lion", GPUTestConfig::kOsMacLion },
  { "mountainlion", GPUTestConfig::kOsMacMountainLion },
  { "mavericks", GPUTestConfig::kOsMacMavericks },
  { "mac", GPUTestConfig::kOsMac },
  { "linux", GPUTestConfig::kOsLinux },
  { "chromeos", GPUTestConfig::kOsChromeOS },
  { "android", GPUTestConfig::kOsAndroid },
  { "nvidia", 0x10DE },
  { "amd", 0x1002 },
  { "intel", 0x8086 },
  { "vmware", 0x15ad },
  { "release", GPUTestConfig::kBuildTypeRelease },
  { "debug", GPUTestConfig::kBuildTypeDebug },
  { "pass", GPUTestExpectationsParser::kGpuTestPass },
  { "fail", GPUTestExpectationsParser::kGpuTestFail },
  { "flaky", GPUTestExpectationsParser::kGpuTestFlaky },
  { "timeout", GPUTestExpectationsParser::kGpuTestTimeout },
  { "skip", GPUTestExpectationsParser::kGpuTestSkip },
  { ":", 0 },
  { "=", 0 },
};

enum ErrorType {
  kErrorFileIO = 0,
  kErrorIllegalEntry,
  kErrorInvalidEntry,
  kErrorEntryWithOsConflicts,
  kErrorEntryWithGpuVendorConflicts,
  kErrorEntryWithBuildTypeConflicts,
  kErrorEntryWithGpuDeviceIdConflicts,
  kErrorEntryWithExpectationConflicts,
  kErrorEntriesOverlap,

  kNumberOfErrors,
};

const char* kErrorMessage[] = {
  "file IO failed",
  "entry with wrong format",
  "entry invalid, likely wrong modifiers combination",
  "entry with OS modifier conflicts",
  "entry with GPU vendor modifier conflicts",
  "entry with GPU build type conflicts",
  "entry with GPU device id conflicts or malformat",
  "entry with expectation modifier conflicts",
  "two entries's configs overlap",
};

Token ParseToken(const std::string& word) {
  if (StartsWithASCII(word, "//", false))
    return kTokenComment;
  if (StartsWithASCII(word, "0x", false))
    return kConfigGPUDeviceID;

  for (int32 i = 0; i < kNumberOfExactMatchTokens; ++i) {
    if (base::LowerCaseEqualsASCII(word, kTokenData[i].name))
      return static_cast<Token>(i);
  }
  return kTokenWord;
}

// reference name can have the last character as *.
bool NamesMatching(const std::string& ref, const std::string& test_name) {
  size_t len = ref.length();
  if (len == 0)
    return false;
  if (ref[len - 1] == '*') {
    if (test_name.length() > len -1 &&
        ref.compare(0, len - 1, test_name, 0, len - 1) == 0)
      return true;
    return false;
  }
  return (ref == test_name);
}

}  // namespace anonymous

GPUTestExpectationsParser::GPUTestExpectationsParser() {
  // Some sanity check.
  DCHECK_EQ(static_cast<unsigned int>(kNumberOfExactMatchTokens),
            sizeof(kTokenData) / sizeof(kTokenData[0]));
  DCHECK_EQ(static_cast<unsigned int>(kNumberOfErrors),
            sizeof(kErrorMessage) / sizeof(kErrorMessage[0]));
}

GPUTestExpectationsParser::~GPUTestExpectationsParser() {
}

bool GPUTestExpectationsParser::LoadTestExpectations(const std::string& data) {
  entries_.clear();
  error_messages_.clear();

  std::vector<std::string> lines;
  base::SplitString(data, '\n', &lines);
  bool rt = true;
  for (size_t i = 0; i < lines.size(); ++i) {
    if (!ParseLine(lines[i], i + 1))
      rt = false;
  }
  if (DetectConflictsBetweenEntries()) {
    entries_.clear();
    rt = false;
  }

  return rt;
}

bool GPUTestExpectationsParser::LoadTestExpectations(
    const base::FilePath& path) {
  entries_.clear();
  error_messages_.clear();

  std::string data;
  if (!base::ReadFileToString(path, &data)) {
    error_messages_.push_back(kErrorMessage[kErrorFileIO]);
    return false;
  }
  return LoadTestExpectations(data);
}

int32 GPUTestExpectationsParser::GetTestExpectation(
    const std::string& test_name,
    const GPUTestBotConfig& bot_config) const {
  for (size_t i = 0; i < entries_.size(); ++i) {
    if (NamesMatching(entries_[i].test_name, test_name) &&
        bot_config.Matches(entries_[i].test_config))
      return entries_[i].test_expectation;
  }
  return kGpuTestPass;
}

const std::vector<std::string>&
GPUTestExpectationsParser::GetErrorMessages() const {
  return error_messages_;
}

bool GPUTestExpectationsParser::ParseConfig(
    const std::string& config_data, GPUTestConfig* config) {
  DCHECK(config);
  std::vector<std::string> tokens;
  base::SplitStringAlongWhitespace(config_data, &tokens);

  for (size_t i = 0; i < tokens.size(); ++i) {
    Token token = ParseToken(tokens[i]);
    switch (token) {
      case kConfigWinXP:
      case kConfigWinVista:
      case kConfigWin7:
      case kConfigWin8:
      case kConfigWin:
      case kConfigMacLeopard:
      case kConfigMacSnowLeopard:
      case kConfigMacLion:
      case kConfigMacMountainLion:
      case kConfigMacMavericks:
      case kConfigMac:
      case kConfigLinux:
      case kConfigChromeOS:
      case kConfigAndroid:
      case kConfigNVidia:
      case kConfigAMD:
      case kConfigIntel:
      case kConfigVMWare:
      case kConfigRelease:
      case kConfigDebug:
      case kConfigGPUDeviceID:
        if (token == kConfigGPUDeviceID) {
          if (!UpdateTestConfig(config, tokens[i], 0))
            return false;
        } else {
          if (!UpdateTestConfig(config, token, 0))
            return false;
        }
        break;
      default:
        return false;
    }
  }
  return true;
}

bool GPUTestExpectationsParser::ParseLine(
    const std::string& line_data, size_t line_number) {
  std::vector<std::string> tokens;
  base::SplitStringAlongWhitespace(line_data, &tokens);
  int32 stage = kLineParserBegin;
  GPUTestExpectationEntry entry;
  entry.line_number = line_number;
  GPUTestConfig& config = entry.test_config;
  bool comments_encountered = false;
  for (size_t i = 0; i < tokens.size() && !comments_encountered; ++i) {
    Token token = ParseToken(tokens[i]);
    switch (token) {
      case kTokenComment:
        comments_encountered = true;
        break;
      case kConfigWinXP:
      case kConfigWinVista:
      case kConfigWin7:
      case kConfigWin8:
      case kConfigWin:
      case kConfigMacLeopard:
      case kConfigMacSnowLeopard:
      case kConfigMacLion:
      case kConfigMacMountainLion:
      case kConfigMacMavericks:
      case kConfigMac:
      case kConfigLinux:
      case kConfigChromeOS:
      case kConfigAndroid:
      case kConfigNVidia:
      case kConfigAMD:
      case kConfigIntel:
      case kConfigVMWare:
      case kConfigRelease:
      case kConfigDebug:
      case kConfigGPUDeviceID:
        // MODIFIERS, could be in any order, need at least one.
        if (stage != kLineParserConfigs && stage != kLineParserBugID) {
          PushErrorMessage(kErrorMessage[kErrorIllegalEntry],
                           line_number);
          return false;
        }
        if (token == kConfigGPUDeviceID) {
          if (!UpdateTestConfig(&config, tokens[i], line_number))
            return false;
        } else {
          if (!UpdateTestConfig(&config, token, line_number))
            return false;
        }
        if (stage == kLineParserBugID)
          stage++;
        break;
      case kSeparatorColon:
        // :
        if (stage != kLineParserConfigs) {
          PushErrorMessage(kErrorMessage[kErrorIllegalEntry],
                           line_number);
          return false;
        }
        stage++;
        break;
      case kSeparatorEqual:
        // =
        if (stage != kLineParserTestName) {
          PushErrorMessage(kErrorMessage[kErrorIllegalEntry],
                           line_number);
          return false;
        }
        stage++;
        break;
      case kTokenWord:
        // BUG_ID or TEST_NAME
        if (stage == kLineParserBegin) {
          // Bug ID is not used for anything; ignore it.
        } else if (stage == kLineParserColon) {
          entry.test_name = tokens[i];
        } else {
          PushErrorMessage(kErrorMessage[kErrorIllegalEntry],
                           line_number);
          return false;
        }
        stage++;
        break;
      case kExpectationPass:
      case kExpectationFail:
      case kExpectationFlaky:
      case kExpectationTimeout:
      case kExpectationSkip:
        // TEST_EXPECTATIONS
        if (stage != kLineParserEqual && stage != kLineParserExpectations) {
          PushErrorMessage(kErrorMessage[kErrorIllegalEntry],
                           line_number);
          return false;
        }
        if ((kTokenData[token].flag & entry.test_expectation) != 0) {
          PushErrorMessage(kErrorMessage[kErrorEntryWithExpectationConflicts],
                           line_number);
          return false;
        }
        entry.test_expectation =
            (kTokenData[token].flag | entry.test_expectation);
        if (stage == kLineParserEqual)
          stage++;
        break;
      default:
        DCHECK(false);
        break;
    }
  }
  if (stage == kLineParserBegin) {
    // The whole line is empty or all comments
    return true;
  }
  if (stage == kLineParserExpectations) {
    if (!config.IsValid()) {
        PushErrorMessage(kErrorMessage[kErrorInvalidEntry], line_number);
        return false;
    }
    entries_.push_back(entry);
    return true;
  }
  PushErrorMessage(kErrorMessage[kErrorIllegalEntry], line_number);
  return false;
}

bool GPUTestExpectationsParser::UpdateTestConfig(
    GPUTestConfig* config, int32 token, size_t line_number) {
  DCHECK(config);
  switch (token) {
    case kConfigWinXP:
    case kConfigWinVista:
    case kConfigWin7:
    case kConfigWin8:
    case kConfigWin:
    case kConfigMacLeopard:
    case kConfigMacSnowLeopard:
    case kConfigMacLion:
    case kConfigMacMountainLion:
    case kConfigMacMavericks:
    case kConfigMac:
    case kConfigLinux:
    case kConfigChromeOS:
    case kConfigAndroid:
      if ((config->os() & kTokenData[token].flag) != 0) {
        PushErrorMessage(kErrorMessage[kErrorEntryWithOsConflicts],
                         line_number);
        return false;
      }
      config->set_os(config->os() | kTokenData[token].flag);
      break;
    case kConfigNVidia:
    case kConfigAMD:
    case kConfigIntel:
    case kConfigVMWare:
      {
        uint32 gpu_vendor =
            static_cast<uint32>(kTokenData[token].flag);
        for (size_t i = 0; i < config->gpu_vendor().size(); ++i) {
          if (config->gpu_vendor()[i] == gpu_vendor) {
            PushErrorMessage(
                kErrorMessage[kErrorEntryWithGpuVendorConflicts],
                line_number);
            return false;
          }
        }
        config->AddGPUVendor(gpu_vendor);
      }
      break;
    case kConfigRelease:
    case kConfigDebug:
      if ((config->build_type() & kTokenData[token].flag) != 0) {
        PushErrorMessage(
            kErrorMessage[kErrorEntryWithBuildTypeConflicts],
            line_number);
        return false;
      }
      config->set_build_type(
          config->build_type() | kTokenData[token].flag);
      break;
    default:
      DCHECK(false);
      break;
  }
  return true;
}

bool GPUTestExpectationsParser::UpdateTestConfig(
    GPUTestConfig* config,
    const std::string& gpu_device_id,
    size_t line_number) {
  DCHECK(config);
  uint32 device_id = 0;
  if (config->gpu_device_id() != 0 ||
      !base::HexStringToUInt(gpu_device_id, &device_id) ||
      device_id == 0) {
    PushErrorMessage(kErrorMessage[kErrorEntryWithGpuDeviceIdConflicts],
                     line_number);
    return false;
  }
  config->set_gpu_device_id(device_id);
  return true;
}

bool GPUTestExpectationsParser::DetectConflictsBetweenEntries() {
  bool rt = false;
  for (size_t i = 0; i < entries_.size(); ++i) {
    for (size_t j = i + 1; j < entries_.size(); ++j) {
      if (entries_[i].test_name == entries_[j].test_name &&
          entries_[i].test_config.OverlapsWith(entries_[j].test_config)) {
        PushErrorMessage(kErrorMessage[kErrorEntriesOverlap],
                         entries_[i].line_number,
                         entries_[j].line_number);
        rt = true;
      }
    }
  }
  return rt;
}

void GPUTestExpectationsParser::PushErrorMessage(
    const std::string& message, size_t line_number) {
  error_messages_.push_back(
      base::StringPrintf("Line %d : %s",
                         static_cast<int>(line_number), message.c_str()));
}

void GPUTestExpectationsParser::PushErrorMessage(
    const std::string& message,
    size_t entry1_line_number,
    size_t entry2_line_number) {
  error_messages_.push_back(
      base::StringPrintf("Line %d and %d : %s",
                         static_cast<int>(entry1_line_number),
                         static_cast<int>(entry2_line_number),
                         message.c_str()));
}

GPUTestExpectationsParser:: GPUTestExpectationEntry::GPUTestExpectationEntry()
    : test_expectation(0),
      line_number(0) {
}

}  // namespace gpu

