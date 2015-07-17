// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/debug/crash_logging.h"

#include <cmath>
#include <map>

#include "base/debug/stack_trace.h"
#include "base/format_macros.h"
#include "base/logging.h"
#include "base/strings/string_util.h"
#include "base/strings/stringprintf.h"

namespace base {
namespace debug {

namespace {

// Global map of crash key names to registration entries.
typedef std::map<base::StringPiece, CrashKey> CrashKeyMap;
CrashKeyMap* g_crash_keys_ = NULL;

// The maximum length of a single chunk.
size_t g_chunk_max_length_ = 0;

// String used to format chunked key names.
const char kChunkFormatString[] = "%s-%" PRIuS;

// The functions that are called to actually set the key-value pairs in the
// crash reportng system.
SetCrashKeyValueFuncT g_set_key_func_ = NULL;
ClearCrashKeyValueFuncT g_clear_key_func_ = NULL;

// For a given |length|, computes the number of chunks a value of that size
// will occupy.
size_t NumChunksForLength(size_t length) {
  // Compute (length / g_chunk_max_length_), rounded up.
  return (length + g_chunk_max_length_ - 1) / g_chunk_max_length_;
}

// The longest max_length allowed by the system.
const size_t kLargestValueAllowed = 1024;

}  // namespace

void SetCrashKeyValue(const base::StringPiece& key,
                      const base::StringPiece& value) {
  if (!g_set_key_func_ || !g_crash_keys_)
    return;

  const CrashKey* crash_key = LookupCrashKey(key);

  DCHECK(crash_key) << "All crash keys must be registered before use "
                    << "(key = " << key << ")";

  // Handle the un-chunked case.
  if (!crash_key || crash_key->max_length <= g_chunk_max_length_) {
    g_set_key_func_(key, value);
    return;
  }

  // Unset the unused chunks.
  std::vector<std::string> chunks =
      ChunkCrashKeyValue(*crash_key, value, g_chunk_max_length_);
  for (size_t i = chunks.size();
       i < NumChunksForLength(crash_key->max_length);
       ++i) {
    g_clear_key_func_(base::StringPrintf(kChunkFormatString, key.data(), i+1));
  }

  // Set the chunked keys.
  for (size_t i = 0; i < chunks.size(); ++i) {
    g_set_key_func_(base::StringPrintf(kChunkFormatString, key.data(), i+1),
                    chunks[i]);
  }
}

void ClearCrashKey(const base::StringPiece& key) {
  if (!g_clear_key_func_ || !g_crash_keys_)
    return;

  const CrashKey* crash_key = LookupCrashKey(key);

  // Handle the un-chunked case.
  if (!crash_key || crash_key->max_length <= g_chunk_max_length_) {
    g_clear_key_func_(key);
    return;
  }

  for (size_t i = 0; i < NumChunksForLength(crash_key->max_length); ++i) {
    g_clear_key_func_(base::StringPrintf(kChunkFormatString, key.data(), i+1));
  }
}

void SetCrashKeyToStackTrace(const base::StringPiece& key,
                             const StackTrace& trace) {
  size_t count = 0;
  const void* const* addresses = trace.Addresses(&count);
  SetCrashKeyFromAddresses(key, addresses, count);
}

void SetCrashKeyFromAddresses(const base::StringPiece& key,
                              const void* const* addresses,
                              size_t count) {
  std::string value = "<null>";
  if (addresses && count) {
    const size_t kBreakpadValueMax = 255;

    std::vector<std::string> hex_backtrace;
    size_t length = 0;

    for (size_t i = 0; i < count; ++i) {
      std::string s = base::StringPrintf("%p", addresses[i]);
      length += s.length() + 1;
      if (length > kBreakpadValueMax)
        break;
      hex_backtrace.push_back(s);
    }

    value = base::JoinString(hex_backtrace, " ");

    // Warn if this exceeds the breakpad limits.
    DCHECK_LE(value.length(), kBreakpadValueMax);
  }

  SetCrashKeyValue(key, value);
}

ScopedCrashKey::ScopedCrashKey(const base::StringPiece& key,
                               const base::StringPiece& value)
    : key_(key.as_string()) {
  SetCrashKeyValue(key, value);
}

ScopedCrashKey::~ScopedCrashKey() {
  ClearCrashKey(key_);
}

size_t InitCrashKeys(const CrashKey* const keys, size_t count,
                     size_t chunk_max_length) {
  DCHECK(!g_crash_keys_) << "Crash logging may only be initialized once";
  if (!keys) {
    delete g_crash_keys_;
    g_crash_keys_ = NULL;
    return 0;
  }

  g_crash_keys_ = new CrashKeyMap;
  g_chunk_max_length_ = chunk_max_length;

  size_t total_keys = 0;
  for (size_t i = 0; i < count; ++i) {
    g_crash_keys_->insert(std::make_pair(keys[i].key_name, keys[i]));
    total_keys += NumChunksForLength(keys[i].max_length);
    DCHECK_LT(keys[i].max_length, kLargestValueAllowed);
  }
  DCHECK_EQ(count, g_crash_keys_->size())
      << "Duplicate crash keys were registered";

  return total_keys;
}

const CrashKey* LookupCrashKey(const base::StringPiece& key) {
  if (!g_crash_keys_)
    return NULL;
  CrashKeyMap::const_iterator it = g_crash_keys_->find(key.as_string());
  if (it == g_crash_keys_->end())
    return NULL;
  return &(it->second);
}

void SetCrashKeyReportingFunctions(
    SetCrashKeyValueFuncT set_key_func,
    ClearCrashKeyValueFuncT clear_key_func) {
  g_set_key_func_ = set_key_func;
  g_clear_key_func_ = clear_key_func;
}

std::vector<std::string> ChunkCrashKeyValue(const CrashKey& crash_key,
                                            const base::StringPiece& value,
                                            size_t chunk_max_length) {
  std::string value_string = value.substr(0, crash_key.max_length).as_string();
  std::vector<std::string> chunks;
  for (size_t offset = 0; offset < value_string.length(); ) {
    std::string chunk = value_string.substr(offset, chunk_max_length);
    chunks.push_back(chunk);
    offset += chunk.length();
  }
  return chunks;
}

void ResetCrashLoggingForTesting() {
  delete g_crash_keys_;
  g_crash_keys_ = NULL;
  g_chunk_max_length_ = 0;
  g_set_key_func_ = NULL;
  g_clear_key_func_ = NULL;
}

}  // namespace debug
}  // namespace base
