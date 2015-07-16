// Protocol Buffers - Google's data interchange format
// Copyright 2008 Google Inc.  All rights reserved.
// http://code.google.com/p/protobuf/
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//     * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//     * Neither the name of Google Inc. nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

// Author: kenton@google.com (Kenton Varda)

#include <vector>
#include <google/protobuf/stubs/common.h>
#include <google/protobuf/stubs/strutil.h>
#include <google/protobuf/stubs/substitute.h>

#include <google/protobuf/testing/googletest.h>
#include <gtest/gtest.h>

#include "config.h"

namespace google {
namespace protobuf {
namespace {

// TODO(kenton):  More tests.

#ifdef PACKAGE_VERSION  // only defined when using automake, not MSVC

TEST(VersionTest, VersionMatchesConfig) {
  // Verify that the version string specified in config.h matches the one
  // in common.h.  The config.h version is a string which may have a suffix
  // like "beta" or "rc1", so we remove that.
  string version = PACKAGE_VERSION;
  int pos = 0;
  while (pos < version.size() &&
         (ascii_isdigit(version[pos]) || version[pos] == '.')) {
    ++pos;
  }
  version.erase(pos);

  EXPECT_EQ(version, internal::VersionString(GOOGLE_PROTOBUF_VERSION));
}

#endif  // PACKAGE_VERSION

TEST(CommonTest, IntMinMaxConstants) {
  // kint32min was declared incorrectly in the first release of protobufs.
  // Ugh.
  EXPECT_LT(kint32min, kint32max);
  EXPECT_EQ(static_cast<uint32>(kint32min), static_cast<uint32>(kint32max) + 1);
  EXPECT_LT(kint64min, kint64max);
  EXPECT_EQ(static_cast<uint64>(kint64min), static_cast<uint64>(kint64max) + 1);
  EXPECT_EQ(0, kuint32max + 1);
  EXPECT_EQ(0, kuint64max + 1);
}

vector<string> captured_messages_;

void CaptureLog(LogLevel level, const char* filename, int line,
                const string& message) {
  captured_messages_.push_back(
    strings::Substitute("$0 $1:$2: $3",
      implicit_cast<int>(level), filename, line, message));
}

TEST(LoggingTest, DefaultLogging) {
  CaptureTestStderr();
  int line = __LINE__;
  GOOGLE_LOG(INFO   ) << "A message.";
  GOOGLE_LOG(WARNING) << "A warning.";
  GOOGLE_LOG(ERROR  ) << "An error.";

  string text = GetCapturedTestStderr();
  EXPECT_EQ(
    "[libprotobuf INFO "__FILE__":" + SimpleItoa(line + 1) + "] A message.\n"
    "[libprotobuf WARNING "__FILE__":" + SimpleItoa(line + 2) + "] A warning.\n"
    "[libprotobuf ERROR "__FILE__":" + SimpleItoa(line + 3) + "] An error.\n",
    text);
}

TEST(LoggingTest, NullLogging) {
  LogHandler* old_handler = SetLogHandler(NULL);

  CaptureTestStderr();
  GOOGLE_LOG(INFO   ) << "A message.";
  GOOGLE_LOG(WARNING) << "A warning.";
  GOOGLE_LOG(ERROR  ) << "An error.";

  EXPECT_TRUE(SetLogHandler(old_handler) == NULL);

  string text = GetCapturedTestStderr();
  EXPECT_EQ("", text);
}

TEST(LoggingTest, CaptureLogging) {
  captured_messages_.clear();

  LogHandler* old_handler = SetLogHandler(&CaptureLog);

  int start_line = __LINE__;
  GOOGLE_LOG(ERROR) << "An error.";
  GOOGLE_LOG(WARNING) << "A warning.";

  EXPECT_TRUE(SetLogHandler(old_handler) == &CaptureLog);

  ASSERT_EQ(2, captured_messages_.size());
  EXPECT_EQ(
    "2 "__FILE__":" + SimpleItoa(start_line + 1) + ": An error.",
    captured_messages_[0]);
  EXPECT_EQ(
    "1 "__FILE__":" + SimpleItoa(start_line + 2) + ": A warning.",
    captured_messages_[1]);
}

TEST(LoggingTest, SilenceLogging) {
  captured_messages_.clear();

  LogHandler* old_handler = SetLogHandler(&CaptureLog);

  int line1 = __LINE__; GOOGLE_LOG(INFO) << "Visible1";
  LogSilencer* silencer1 = new LogSilencer;
  GOOGLE_LOG(INFO) << "Not visible.";
  LogSilencer* silencer2 = new LogSilencer;
  GOOGLE_LOG(INFO) << "Not visible.";
  delete silencer1;
  GOOGLE_LOG(INFO) << "Not visible.";
  delete silencer2;
  int line2 = __LINE__; GOOGLE_LOG(INFO) << "Visible2";

  EXPECT_TRUE(SetLogHandler(old_handler) == &CaptureLog);

  ASSERT_EQ(2, captured_messages_.size());
  EXPECT_EQ(
    "0 "__FILE__":" + SimpleItoa(line1) + ": Visible1",
    captured_messages_[0]);
  EXPECT_EQ(
    "0 "__FILE__":" + SimpleItoa(line2) + ": Visible2",
    captured_messages_[1]);
}

class ClosureTest : public testing::Test {
 public:
  void SetA123Method()   { a_ = 123; }
  static void SetA123Function() { current_instance_->a_ = 123; }

  void SetAMethod(int a)         { a_ = a; }
  void SetCMethod(string c)      { c_ = c; }

  static void SetAFunction(int a)         { current_instance_->a_ = a; }
  static void SetCFunction(string c)      { current_instance_->c_ = c; }

  void SetABMethod(int a, const char* b)  { a_ = a; b_ = b; }
  static void SetABFunction(int a, const char* b) {
    current_instance_->a_ = a;
    current_instance_->b_ = b;
  }

  virtual void SetUp() {
    current_instance_ = this;
    a_ = 0;
    b_ = NULL;
    c_.clear();
    permanent_closure_ = NULL;
  }

  void DeleteClosureInCallback() {
    delete permanent_closure_;
  }

  int a_;
  const char* b_;
  string c_;
  Closure* permanent_closure_;

  static ClosureTest* current_instance_;
};

ClosureTest* ClosureTest::current_instance_ = NULL;

TEST_F(ClosureTest, TestClosureFunction0) {
  Closure* closure = NewCallback(&SetA123Function);
  EXPECT_NE(123, a_);
  closure->Run();
  EXPECT_EQ(123, a_);
}

TEST_F(ClosureTest, TestClosureMethod0) {
  Closure* closure = NewCallback(current_instance_,
                                 &ClosureTest::SetA123Method);
  EXPECT_NE(123, a_);
  closure->Run();
  EXPECT_EQ(123, a_);
}

TEST_F(ClosureTest, TestClosureFunction1) {
  Closure* closure = NewCallback(&SetAFunction, 456);
  EXPECT_NE(456, a_);
  closure->Run();
  EXPECT_EQ(456, a_);
}

TEST_F(ClosureTest, TestClosureMethod1) {
  Closure* closure = NewCallback(current_instance_,
                                 &ClosureTest::SetAMethod, 456);
  EXPECT_NE(456, a_);
  closure->Run();
  EXPECT_EQ(456, a_);
}

TEST_F(ClosureTest, TestClosureFunction1String) {
  Closure* closure = NewCallback(&SetCFunction, string("test"));
  EXPECT_NE("test", c_);
  closure->Run();
  EXPECT_EQ("test", c_);
}

TEST_F(ClosureTest, TestClosureMethod1String) {
  Closure* closure = NewCallback(current_instance_,
                                 &ClosureTest::SetCMethod, string("test"));
  EXPECT_NE("test", c_);
  closure->Run();
  EXPECT_EQ("test", c_);
}

TEST_F(ClosureTest, TestClosureFunction2) {
  const char* cstr = "hello";
  Closure* closure = NewCallback(&SetABFunction, 789, cstr);
  EXPECT_NE(789, a_);
  EXPECT_NE(cstr, b_);
  closure->Run();
  EXPECT_EQ(789, a_);
  EXPECT_EQ(cstr, b_);
}

TEST_F(ClosureTest, TestClosureMethod2) {
  const char* cstr = "hello";
  Closure* closure = NewCallback(current_instance_,
                                 &ClosureTest::SetABMethod, 789, cstr);
  EXPECT_NE(789, a_);
  EXPECT_NE(cstr, b_);
  closure->Run();
  EXPECT_EQ(789, a_);
  EXPECT_EQ(cstr, b_);
}

// Repeat all of the above with NewPermanentCallback()

TEST_F(ClosureTest, TestPermanentClosureFunction0) {
  Closure* closure = NewPermanentCallback(&SetA123Function);
  EXPECT_NE(123, a_);
  closure->Run();
  EXPECT_EQ(123, a_);
  a_ = 0;
  closure->Run();
  EXPECT_EQ(123, a_);
  delete closure;
}

TEST_F(ClosureTest, TestPermanentClosureMethod0) {
  Closure* closure = NewPermanentCallback(current_instance_,
                                          &ClosureTest::SetA123Method);
  EXPECT_NE(123, a_);
  closure->Run();
  EXPECT_EQ(123, a_);
  a_ = 0;
  closure->Run();
  EXPECT_EQ(123, a_);
  delete closure;
}

TEST_F(ClosureTest, TestPermanentClosureFunction1) {
  Closure* closure = NewPermanentCallback(&SetAFunction, 456);
  EXPECT_NE(456, a_);
  closure->Run();
  EXPECT_EQ(456, a_);
  a_ = 0;
  closure->Run();
  EXPECT_EQ(456, a_);
  delete closure;
}

TEST_F(ClosureTest, TestPermanentClosureMethod1) {
  Closure* closure = NewPermanentCallback(current_instance_,
                                          &ClosureTest::SetAMethod, 456);
  EXPECT_NE(456, a_);
  closure->Run();
  EXPECT_EQ(456, a_);
  a_ = 0;
  closure->Run();
  EXPECT_EQ(456, a_);
  delete closure;
}

TEST_F(ClosureTest, TestPermanentClosureFunction2) {
  const char* cstr = "hello";
  Closure* closure = NewPermanentCallback(&SetABFunction, 789, cstr);
  EXPECT_NE(789, a_);
  EXPECT_NE(cstr, b_);
  closure->Run();
  EXPECT_EQ(789, a_);
  EXPECT_EQ(cstr, b_);
  a_ = 0;
  b_ = NULL;
  closure->Run();
  EXPECT_EQ(789, a_);
  EXPECT_EQ(cstr, b_);
  delete closure;
}

TEST_F(ClosureTest, TestPermanentClosureMethod2) {
  const char* cstr = "hello";
  Closure* closure = NewPermanentCallback(current_instance_,
                                          &ClosureTest::SetABMethod, 789, cstr);
  EXPECT_NE(789, a_);
  EXPECT_NE(cstr, b_);
  closure->Run();
  EXPECT_EQ(789, a_);
  EXPECT_EQ(cstr, b_);
  a_ = 0;
  b_ = NULL;
  closure->Run();
  EXPECT_EQ(789, a_);
  EXPECT_EQ(cstr, b_);
  delete closure;
}

TEST_F(ClosureTest, TestPermanentClosureDeleteInCallback) {
  permanent_closure_ = NewPermanentCallback((ClosureTest*) this,
      &ClosureTest::DeleteClosureInCallback);
  permanent_closure_->Run();
}

}  // anonymous namespace
}  // namespace protobuf
}  // namespace google
