// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_TRACE_EVENT_TRACE_EVENT_ARGUMENT_H_
#define BASE_TRACE_EVENT_TRACE_EVENT_ARGUMENT_H_

#include <string>
#include <vector>

#include "base/memory/scoped_ptr.h"
#include "base/trace_event/trace_event.h"

namespace base {
class DictionaryValue;
class ListValue;
class Value;

namespace trace_event {

class BASE_EXPORT TracedValue : public ConvertableToTraceFormat {
 public:
  TracedValue();

  void EndDictionary();
  void EndArray();

  void SetInteger(const char* name, int value);
  void SetDouble(const char* name, double value);
  void SetBoolean(const char* name, bool value);
  void SetString(const char* name, const std::string& value);
  void SetValue(const char* name, scoped_ptr<Value> value);
  void BeginDictionary(const char* name);
  void BeginArray(const char* name);

  void AppendInteger(int);
  void AppendDouble(double);
  void AppendBoolean(bool);
  void AppendString(const std::string&);
  void BeginArray();
  void BeginDictionary();

  void AppendAsTraceFormat(std::string* out) const override;

 private:
  ~TracedValue() override;

  DictionaryValue* GetCurrentDictionary();
  ListValue* GetCurrentArray();

  scoped_ptr<base::Value> root_;
  std::vector<Value*> stack_;  // Weak references.
  DISALLOW_COPY_AND_ASSIGN(TracedValue);
};

}  // namespace trace_event
}  // namespace base

#endif  // BASE_TRACE_EVENT_TRACE_EVENT_ARGUMENT_H_
