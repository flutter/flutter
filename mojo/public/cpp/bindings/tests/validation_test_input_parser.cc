// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/public/cpp/bindings/tests/validation_test_input_parser.h"

#include <assert.h>
#include <stdio.h>
#include <string.h>

#include <limits>
#include <map>
#include <set>
#include <utility>

#include "mojo/public/c/system/macros.h"

namespace mojo {
namespace test {
namespace {

class ValidationTestInputParser {
 public:
  ValidationTestInputParser(const std::string& input,
                            std::vector<uint8_t>* data,
                            size_t* num_handles,
                            std::string* error_message);
  ~ValidationTestInputParser();

  bool Run();

 private:
  struct DataType;

  typedef std::pair<const char*, const char*> Range;

  typedef bool (ValidationTestInputParser::*ParseDataFunc)(
      const DataType& type,
      const std::string& value_string);

  struct DataType {
    const char* name;
    size_t name_size;
    size_t data_size;
    ParseDataFunc parse_data_func;
  };

  // A dist4/8 item that hasn't been matched with an anchr item.
  struct PendingDistanceItem {
    // Where this data item is located in |data_|.
    size_t pos;
    // Either 4 or 8 (bytes).
    size_t data_size;
  };

  bool GetNextItem(Range* range);

  bool ParseItem(const Range& range);

  bool ParseUnsignedInteger(const DataType& type,
                            const std::string& value_string);
  bool ParseSignedInteger(const DataType& type,
                          const std::string& value_string);
  bool ParseFloat(const DataType& type, const std::string& value_string);
  bool ParseDouble(const DataType& type, const std::string& value_string);
  bool ParseBinarySequence(const DataType& type,
                           const std::string& value_string);
  bool ParseDistance(const DataType& type, const std::string& value_string);
  bool ParseAnchor(const DataType& type, const std::string& value_string);
  bool ParseHandles(const DataType& type, const std::string& value_string);

  bool StartsWith(const Range& range, const char* prefix, size_t prefix_length);

  bool ConvertToUnsignedInteger(const std::string& value_string,
                                unsigned long long int* value);

  template <typename T>
  void AppendData(T data) {
    size_t pos = data_->size();
    data_->resize(pos + sizeof(T));
    memcpy(&(*data_)[pos], &data, sizeof(T));
  }

  template <typename TargetType, typename InputType>
  bool ConvertAndAppendData(InputType value) {
    if (value > std::numeric_limits<TargetType>::max() ||
        value < std::numeric_limits<TargetType>::min()) {
      return false;
    }
    AppendData(static_cast<TargetType>(value));
    return true;
  }

  template <typename TargetType, typename InputType>
  bool ConvertAndFillData(size_t pos, InputType value) {
    if (value > std::numeric_limits<TargetType>::max() ||
        value < std::numeric_limits<TargetType>::min()) {
      return false;
    }
    TargetType target_value = static_cast<TargetType>(value);
    assert(pos + sizeof(TargetType) <= data_->size());
    memcpy(&(*data_)[pos], &target_value, sizeof(TargetType));
    return true;
  }

  static const DataType kDataTypes[];
  static const size_t kDataTypeCount;

  const std::string& input_;
  size_t input_cursor_;

  std::vector<uint8_t>* data_;
  size_t* num_handles_;
  std::string* error_message_;

  std::map<std::string, PendingDistanceItem> pending_distance_items_;
  std::set<std::string> anchors_;
};

#define DATA_TYPE(name, data_size, parse_data_func) \
  { name, sizeof(name) - 1, data_size, parse_data_func }

const ValidationTestInputParser::DataType
    ValidationTestInputParser::kDataTypes[] = {
        DATA_TYPE("[u1]", 1, &ValidationTestInputParser::ParseUnsignedInteger),
        DATA_TYPE("[u2]", 2, &ValidationTestInputParser::ParseUnsignedInteger),
        DATA_TYPE("[u4]", 4, &ValidationTestInputParser::ParseUnsignedInteger),
        DATA_TYPE("[u8]", 8, &ValidationTestInputParser::ParseUnsignedInteger),
        DATA_TYPE("[s1]", 1, &ValidationTestInputParser::ParseSignedInteger),
        DATA_TYPE("[s2]", 2, &ValidationTestInputParser::ParseSignedInteger),
        DATA_TYPE("[s4]", 4, &ValidationTestInputParser::ParseSignedInteger),
        DATA_TYPE("[s8]", 8, &ValidationTestInputParser::ParseSignedInteger),
        DATA_TYPE("[b]", 1, &ValidationTestInputParser::ParseBinarySequence),
        DATA_TYPE("[f]", 4, &ValidationTestInputParser::ParseFloat),
        DATA_TYPE("[d]", 8, &ValidationTestInputParser::ParseDouble),
        DATA_TYPE("[dist4]", 4, &ValidationTestInputParser::ParseDistance),
        DATA_TYPE("[dist8]", 8, &ValidationTestInputParser::ParseDistance),
        DATA_TYPE("[anchr]", 0, &ValidationTestInputParser::ParseAnchor),
        DATA_TYPE("[handles]", 0, &ValidationTestInputParser::ParseHandles)};

const size_t ValidationTestInputParser::kDataTypeCount =
    sizeof(ValidationTestInputParser::kDataTypes) /
    sizeof(ValidationTestInputParser::kDataTypes[0]);

ValidationTestInputParser::ValidationTestInputParser(const std::string& input,
                                                     std::vector<uint8_t>* data,
                                                     size_t* num_handles,
                                                     std::string* error_message)
    : input_(input),
      input_cursor_(0),
      data_(data),
      num_handles_(num_handles),
      error_message_(error_message) {
  assert(data_);
  assert(num_handles_);
  assert(error_message_);
  data_->clear();
  *num_handles_ = 0;
  error_message_->clear();
}

ValidationTestInputParser::~ValidationTestInputParser() {
}

bool ValidationTestInputParser::Run() {
  Range range;
  bool result = true;
  while (result && GetNextItem(&range))
    result = ParseItem(range);

  if (!result) {
    *error_message_ =
        "Error occurred when parsing " + std::string(range.first, range.second);
  } else if (!pending_distance_items_.empty()) {
    // We have parsed all the contents in |input_| successfully, but there are
    // unmatched dist4/8 items.
    *error_message_ = "Error occurred when matching [dist4/8] and [anchr].";
    result = false;
  }
  if (!result) {
    data_->clear();
    *num_handles_ = 0;
  } else {
    assert(error_message_->empty());
  }

  return result;
}

bool ValidationTestInputParser::GetNextItem(Range* range) {
  const char kWhitespaceChars[] = " \t\n\r";
  const char kItemDelimiters[] = " \t\n\r/";
  const char kEndOfLineChars[] = "\n\r";
  while (true) {
    // Skip leading whitespaces.
    // If there are no non-whitespace characters left, |input_cursor_| will be
    // set to std::npos.
    input_cursor_ = input_.find_first_not_of(kWhitespaceChars, input_cursor_);

    if (input_cursor_ >= input_.size())
      return false;

    if (StartsWith(
            Range(&input_[0] + input_cursor_, &input_[0] + input_.size()),
            "//",
            2)) {
      // Skip contents until the end of the line.
      input_cursor_ = input_.find_first_of(kEndOfLineChars, input_cursor_);
    } else {
      range->first = &input_[0] + input_cursor_;
      input_cursor_ = input_.find_first_of(kItemDelimiters, input_cursor_);
      range->second = input_cursor_ >= input_.size()
                          ? &input_[0] + input_.size()
                          : &input_[0] + input_cursor_;
      return true;
    }
  }
  return false;
}

bool ValidationTestInputParser::ParseItem(const Range& range) {
  for (size_t i = 0; i < kDataTypeCount; ++i) {
    if (StartsWith(range, kDataTypes[i].name, kDataTypes[i].name_size)) {
      return (this->*kDataTypes[i].parse_data_func)(
          kDataTypes[i],
          std::string(range.first + kDataTypes[i].name_size, range.second));
    }
  }

  // "[u1]" is optional.
  return ParseUnsignedInteger(kDataTypes[0],
                              std::string(range.first, range.second));
}

bool ValidationTestInputParser::ParseUnsignedInteger(
    const DataType& type,
    const std::string& value_string) {
  unsigned long long int value;
  if (!ConvertToUnsignedInteger(value_string, &value))
    return false;

  switch (type.data_size) {
    case 1:
      return ConvertAndAppendData<uint8_t>(value);
    case 2:
      return ConvertAndAppendData<uint16_t>(value);
    case 4:
      return ConvertAndAppendData<uint32_t>(value);
    case 8:
      return ConvertAndAppendData<uint64_t>(value);
    default:
      assert(false);
      return false;
  }
}

bool ValidationTestInputParser::ParseSignedInteger(
    const DataType& type,
    const std::string& value_string) {
  long long int value;
  if (sscanf(value_string.c_str(), "%lli", &value) != 1)
    return false;

  switch (type.data_size) {
    case 1:
      return ConvertAndAppendData<int8_t>(value);
    case 2:
      return ConvertAndAppendData<int16_t>(value);
    case 4:
      return ConvertAndAppendData<int32_t>(value);
    case 8:
      return ConvertAndAppendData<int64_t>(value);
    default:
      assert(false);
      return false;
  }
}

bool ValidationTestInputParser::ParseFloat(const DataType& type,
                                           const std::string& value_string) {
  static_assert(sizeof(float) == 4, "sizeof(float) is not 4");

  float value;
  if (sscanf(value_string.c_str(), "%f", &value) != 1)
    return false;

  AppendData(value);
  return true;
}

bool ValidationTestInputParser::ParseDouble(const DataType& type,
                                            const std::string& value_string) {
  static_assert(sizeof(double) == 8, "sizeof(double) is not 8");

  double value;
  if (sscanf(value_string.c_str(), "%lf", &value) != 1)
    return false;

  AppendData(value);
  return true;
}

bool ValidationTestInputParser::ParseBinarySequence(
    const DataType& type,
    const std::string& value_string) {
  if (value_string.size() != 8)
    return false;

  uint8_t value = 0;
  for (std::string::const_iterator iter = value_string.begin();
       iter != value_string.end();
       ++iter) {
    value <<= 1;
    if (*iter == '1')
      value++;
    else if (*iter != '0')
      return false;
  }
  AppendData(value);
  return true;
}

bool ValidationTestInputParser::ParseDistance(const DataType& type,
                                              const std::string& value_string) {
  if (pending_distance_items_.find(value_string) !=
      pending_distance_items_.end())
    return false;

  PendingDistanceItem item = {data_->size(), type.data_size};
  data_->resize(data_->size() + type.data_size);
  pending_distance_items_[value_string] = item;

  return true;
}

bool ValidationTestInputParser::ParseAnchor(const DataType& type,
                                            const std::string& value_string) {
  if (anchors_.find(value_string) != anchors_.end())
    return false;
  anchors_.insert(value_string);

  std::map<std::string, PendingDistanceItem>::iterator iter =
      pending_distance_items_.find(value_string);
  if (iter == pending_distance_items_.end())
    return false;

  PendingDistanceItem dist_item = iter->second;
  pending_distance_items_.erase(iter);

  size_t distance = data_->size() - dist_item.pos;
  switch (dist_item.data_size) {
    case 4:
      return ConvertAndFillData<uint32_t>(dist_item.pos, distance);
    case 8:
      return ConvertAndFillData<uint64_t>(dist_item.pos, distance);
    default:
      assert(false);
      return false;
  }
}

bool ValidationTestInputParser::ParseHandles(const DataType& type,
                                             const std::string& value_string) {
  // It should be the first item.
  if (!data_->empty())
    return false;

  unsigned long long int value;
  if (!ConvertToUnsignedInteger(value_string, &value))
    return false;

  if (value > std::numeric_limits<size_t>::max())
    return false;

  *num_handles_ = static_cast<size_t>(value);
  return true;
}

bool ValidationTestInputParser::StartsWith(const Range& range,
                                           const char* prefix,
                                           size_t prefix_length) {
  if (static_cast<size_t>(range.second - range.first) < prefix_length)
    return false;

  return memcmp(range.first, prefix, prefix_length) == 0;
}

bool ValidationTestInputParser::ConvertToUnsignedInteger(
    const std::string& value_string,
    unsigned long long int* value) {
  const char* format = nullptr;
  if (value_string.find_first_of("xX") != std::string::npos)
    format = "%llx";
  else
    format = "%llu";
  return sscanf(value_string.c_str(), format, value) == 1;
}

}  // namespace

bool ParseValidationTestInput(const std::string& input,
                              std::vector<uint8_t>* data,
                              size_t* num_handles,
                              std::string* error_message) {
  ValidationTestInputParser parser(input, data, num_handles, error_message);
  return parser.Run();
}

}  // namespace test
}  // namespace mojo
