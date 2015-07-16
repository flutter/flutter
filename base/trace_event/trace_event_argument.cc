// Copyright (c) 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/trace_event/trace_event_argument.h"

#include "base/json/json_writer.h"
#include "base/values.h"

namespace base {
namespace trace_event {

TracedValue::TracedValue() : root_(new DictionaryValue()) {
  stack_.push_back(root_.get());
}

TracedValue::~TracedValue() {
  DCHECK_EQ(1u, stack_.size());
}

void TracedValue::SetInteger(const char* name, int value) {
  GetCurrentDictionary()->SetInteger(name, value);
}

void TracedValue::SetDouble(const char* name, double value) {
  GetCurrentDictionary()->SetDouble(name, value);
}

void TracedValue::SetBoolean(const char* name, bool value) {
  GetCurrentDictionary()->SetBoolean(name, value);
}

void TracedValue::SetString(const char* name, const std::string& value) {
  GetCurrentDictionary()->SetString(name, value);
}

void TracedValue::SetValue(const char* name, scoped_ptr<Value> value) {
  GetCurrentDictionary()->Set(name, value.Pass());
}

void TracedValue::BeginDictionary(const char* name) {
  DictionaryValue* dictionary = new DictionaryValue();
  GetCurrentDictionary()->Set(name, make_scoped_ptr(dictionary));
  stack_.push_back(dictionary);
}

void TracedValue::BeginArray(const char* name) {
  ListValue* array = new ListValue();
  GetCurrentDictionary()->Set(name, make_scoped_ptr(array));
  stack_.push_back(array);
}

void TracedValue::EndDictionary() {
  DCHECK_GT(stack_.size(), 1u);
  DCHECK(GetCurrentDictionary());
  stack_.pop_back();
}

void TracedValue::AppendInteger(int value) {
  GetCurrentArray()->AppendInteger(value);
}

void TracedValue::AppendDouble(double value) {
  GetCurrentArray()->AppendDouble(value);
}

void TracedValue::AppendBoolean(bool value) {
  GetCurrentArray()->AppendBoolean(value);
}

void TracedValue::AppendString(const std::string& value) {
  GetCurrentArray()->AppendString(value);
}

void TracedValue::BeginArray() {
  ListValue* array = new ListValue();
  GetCurrentArray()->Append(array);
  stack_.push_back(array);
}

void TracedValue::BeginDictionary() {
  DictionaryValue* dictionary = new DictionaryValue();
  GetCurrentArray()->Append(dictionary);
  stack_.push_back(dictionary);
}

void TracedValue::EndArray() {
  DCHECK_GT(stack_.size(), 1u);
  DCHECK(GetCurrentArray());
  stack_.pop_back();
}

DictionaryValue* TracedValue::GetCurrentDictionary() {
  DCHECK(!stack_.empty());
  DictionaryValue* dictionary = NULL;
  stack_.back()->GetAsDictionary(&dictionary);
  DCHECK(dictionary);
  return dictionary;
}

ListValue* TracedValue::GetCurrentArray() {
  DCHECK(!stack_.empty());
  ListValue* list = NULL;
  stack_.back()->GetAsList(&list);
  DCHECK(list);
  return list;
}

void TracedValue::AppendAsTraceFormat(std::string* out) const {
  std::string tmp;
  JSONWriter::Write(*stack_.front(), &tmp);
  *out += tmp;
  DCHECK_EQ(1u, stack_.size()) << tmp;
}

}  // namespace trace_event
}  // namespace base
