// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/json/json_file_value_serializer.h"

#include "base/files/file_util.h"
#include "base/json/json_string_value_serializer.h"
#include "base/logging.h"

using base::FilePath;

const char JSONFileValueDeserializer::kAccessDenied[] = "Access denied.";
const char JSONFileValueDeserializer::kCannotReadFile[] = "Can't read file.";
const char JSONFileValueDeserializer::kFileLocked[] = "File locked.";
const char JSONFileValueDeserializer::kNoSuchFile[] = "File doesn't exist.";

JSONFileValueSerializer::JSONFileValueSerializer(
    const base::FilePath& json_file_path)
    : json_file_path_(json_file_path) {
}

JSONFileValueSerializer::~JSONFileValueSerializer() {
}

bool JSONFileValueSerializer::Serialize(const base::Value& root) {
  return SerializeInternal(root, false);
}

bool JSONFileValueSerializer::SerializeAndOmitBinaryValues(
    const base::Value& root) {
  return SerializeInternal(root, true);
}

bool JSONFileValueSerializer::SerializeInternal(const base::Value& root,
                                                bool omit_binary_values) {
  std::string json_string;
  JSONStringValueSerializer serializer(&json_string);
  serializer.set_pretty_print(true);
  bool result = omit_binary_values ?
      serializer.SerializeAndOmitBinaryValues(root) :
      serializer.Serialize(root);
  if (!result)
    return false;

  int data_size = static_cast<int>(json_string.size());
  if (base::WriteFile(json_file_path_, json_string.data(), data_size) !=
      data_size)
    return false;

  return true;
}

JSONFileValueDeserializer::JSONFileValueDeserializer(
    const base::FilePath& json_file_path)
    : json_file_path_(json_file_path),
      allow_trailing_comma_(false),
      last_read_size_(0U) {
}

JSONFileValueDeserializer::~JSONFileValueDeserializer() {
}

int JSONFileValueDeserializer::ReadFileToString(std::string* json_string) {
  DCHECK(json_string);
  if (!base::ReadFileToString(json_file_path_, json_string)) {
#if defined(OS_WIN)
    int error = ::GetLastError();
    if (error == ERROR_SHARING_VIOLATION || error == ERROR_LOCK_VIOLATION) {
      return JSON_FILE_LOCKED;
    } else if (error == ERROR_ACCESS_DENIED) {
      return JSON_ACCESS_DENIED;
    }
#endif
    if (!base::PathExists(json_file_path_))
      return JSON_NO_SUCH_FILE;
    else
      return JSON_CANNOT_READ_FILE;
  }

  last_read_size_ = json_string->size();
  return JSON_NO_ERROR;
}

const char* JSONFileValueDeserializer::GetErrorMessageForCode(int error_code) {
  switch (error_code) {
    case JSON_NO_ERROR:
      return "";
    case JSON_ACCESS_DENIED:
      return kAccessDenied;
    case JSON_CANNOT_READ_FILE:
      return kCannotReadFile;
    case JSON_FILE_LOCKED:
      return kFileLocked;
    case JSON_NO_SUCH_FILE:
      return kNoSuchFile;
    default:
      NOTREACHED();
      return "";
  }
}

base::Value* JSONFileValueDeserializer::Deserialize(int* error_code,
                                                    std::string* error_str) {
  std::string json_string;
  int error = ReadFileToString(&json_string);
  if (error != JSON_NO_ERROR) {
    if (error_code)
      *error_code = error;
    if (error_str)
      *error_str = GetErrorMessageForCode(error);
    return NULL;
  }

  JSONStringValueDeserializer deserializer(json_string);
  deserializer.set_allow_trailing_comma(allow_trailing_comma_);
  return deserializer.Deserialize(error_code, error_str);
}
