// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <string>
#include <vector>

#include "flutter/testing/testing.h"
#include "impeller/toolkit/interop/tracing.h"

namespace impeller::interop::testing {

namespace {

class FakeSystemTracer final : public SystemTracer {
 public:
  bool enabled = true;
  int is_enabled_calls = 0;
  std::vector<std::string> calls;

  // |SystemTracer|
  bool IsEnabled() override {
    is_enabled_calls++;
    return enabled;
  }

  // |SystemTracer|
  void BeginSection(const char* name) override {
    calls.push_back(std::string("B:") + name);
  }

  // |SystemTracer|
  void EndSection() override { calls.push_back("E"); }

  // |SystemTracer|
  void BeginAsyncSection(const char* name, int32_t cookie) override {
    calls.push_back(std::string("S:") + name + ":" + std::to_string(cookie));
  }

  // |SystemTracer|
  void EndAsyncSection(const char* name, int32_t cookie) override {
    calls.push_back(std::string("F:") + name + ":" + std::to_string(cookie));
  }

  // |SystemTracer|
  void SetCounter(const char* name, int64_t value) override {
    calls.push_back(std::string("C:") + name + ":" + std::to_string(value));
  }
};

void Forward(SystemTracer& tracer,
             const char* label,
             Dart_Timeline_Event_Type type,
             int64_t id = 0,
             std::vector<const char*> names = {},
             std::vector<const char*> values = {}) {
  ForwardTimelineEventToSystemTracer(tracer, label, id, type,
                                     static_cast<intptr_t>(names.size()),
                                     names.data(), values.data());
}

std::string Format(char phase, const char* name, int64_t value = 0) {
  char buffer[1024];
  const size_t length =
      FormatTraceMarkerRecord(buffer, sizeof(buffer), phase, 42, name, value);
  EXPECT_EQ(length, std::string(buffer).size());
  return buffer;
}

}  // namespace

TEST(TracingTest, DoesNothingWhenNotEnabled) {
  FakeSystemTracer tracer;
  tracer.enabled = false;
  Forward(tracer, "A", Dart_Timeline_Event_Begin);
  Forward(tracer, "A", Dart_Timeline_Event_End);
  Forward(tracer, "A", Dart_Timeline_Event_Instant);
  Forward(tracer, "A", Dart_Timeline_Event_Async_Begin, 1);
  Forward(tracer, "A", Dart_Timeline_Event_Async_End, 1);
  Forward(tracer, "A", Dart_Timeline_Event_Counter, 0, {"v"}, {"1"});
  // Ends are forwarded based on whether their begin was forwarded.
  EXPECT_EQ(tracer.is_enabled_calls, 5);
  EXPECT_TRUE(tracer.calls.empty());
}

TEST(TracingTest, DoesNotEndEnclosingSectionsWhenTracingStarts) {
  FakeSystemTracer tracer;
  tracer.enabled = false;
  Forward(tracer, "Outer", Dart_Timeline_Event_Begin);
  tracer.enabled = true;
  Forward(tracer, "Inner", Dart_Timeline_Event_Begin);
  Forward(tracer, "Inner", Dart_Timeline_Event_End);
  Forward(tracer, "Outer", Dart_Timeline_Event_End);
  EXPECT_EQ(tracer.calls, (std::vector<std::string>{"B:Inner", "E"}));
}

TEST(TracingTest, EndsOpenSectionsWhenTracingStops) {
  FakeSystemTracer tracer;
  Forward(tracer, "Outer", Dart_Timeline_Event_Begin);
  tracer.enabled = false;
  Forward(tracer, "Inner", Dart_Timeline_Event_Begin);
  Forward(tracer, "Inner", Dart_Timeline_Event_End);
  Forward(tracer, "Outer", Dart_Timeline_Event_End);
  EXPECT_EQ(tracer.calls, (std::vector<std::string>{"B:Outer", "E"}));
}

TEST(TracingTest, IgnoresEndsOfSectionsThatBeganBeforeForwarding) {
  FakeSystemTracer tracer;
  Forward(tracer, "Unknown", Dart_Timeline_Event_End);
  Forward(tracer, "A", Dart_Timeline_Event_Begin);
  Forward(tracer, "A", Dart_Timeline_Event_End);
  EXPECT_EQ(tracer.calls, (std::vector<std::string>{"B:A", "E"}));
}

TEST(TracingTest, KeepsDeeplyNestedSectionsBalanced) {
  FakeSystemTracer tracer;
  constexpr int kDepth = 100;
  for (int i = 0; i < kDepth; i++) {
    Forward(tracer, "Section", Dart_Timeline_Event_Begin);
  }
  for (int i = 0; i < kDepth; i++) {
    Forward(tracer, "Section", Dart_Timeline_Event_End);
  }
  int begins = 0;
  int ends = 0;
  for (const auto& call : tracer.calls) {
    begins += call == "B:Section";
    ends += call == "E";
  }
  EXPECT_EQ(begins, 64);
  EXPECT_EQ(ends, 64);
  // And the sections after are unaffected.
  tracer.calls.clear();
  Forward(tracer, "After", Dart_Timeline_Event_Begin);
  Forward(tracer, "After", Dart_Timeline_Event_End);
  EXPECT_EQ(tracer.calls, (std::vector<std::string>{"B:After", "E"}));
}

TEST(TracingTest, ForwardsSections) {
  FakeSystemTracer tracer;
  Forward(tracer, "Outer", Dart_Timeline_Event_Begin);
  Forward(tracer, "Inner", Dart_Timeline_Event_Begin, 0, {"Bytes", "Mode"},
          {"1024", "fast"});
  Forward(tracer, "Inner", Dart_Timeline_Event_End);
  Forward(tracer, "Outer", Dart_Timeline_Event_End);
  EXPECT_EQ(tracer.calls,
            (std::vector<std::string>{
                "B:Outer", "B:Inner(Bytes=1024, Mode=fast)", "E", "E"}));
}

TEST(TracingTest, ForwardsInstantsAsZeroLengthSections) {
  FakeSystemTracer tracer;
  Forward(tracer, "Instant", Dart_Timeline_Event_Instant);
  EXPECT_EQ(tracer.calls, (std::vector<std::string>{"B:Instant", "E"}));
}

TEST(TracingTest, ForwardsAsyncSections) {
  FakeSystemTracer tracer;
  Forward(tracer, "Async", Dart_Timeline_Event_Async_Begin, 7);
  Forward(tracer, "Async", Dart_Timeline_Event_Async_End, 7);
  EXPECT_EQ(tracer.calls, (std::vector<std::string>{"S:Async:7", "F:Async:7"}));
}

TEST(TracingTest, ForwardsCounters) {
  FakeSystemTracer tracer;
  Forward(tracer, "Single", Dart_Timeline_Event_Counter, 0, {"value"}, {"12"});
  Forward(tracer, "Multi", Dart_Timeline_Event_Counter, 0, {"a", "b"},
          {"-3", "4"});
  EXPECT_EQ(tracer.calls, (std::vector<std::string>{
                              "C:Single:12", "C:Multi a:-3", "C:Multi b:4"}));
}

TEST(TracingTest, IgnoresEventsWithoutATraceEquivalent) {
  FakeSystemTracer tracer;
  Forward(tracer, "Flow", Dart_Timeline_Event_Flow_Begin, 1);
  Forward(tracer, "Flow", Dart_Timeline_Event_Flow_Step, 1);
  Forward(tracer, "Flow", Dart_Timeline_Event_Flow_End, 1);
  Forward(tracer, "Async", Dart_Timeline_Event_Async_Instant, 1);
  EXPECT_TRUE(tracer.calls.empty());
}

TEST(TracingTest, FormatsTraceMarkerRecords) {
  EXPECT_EQ(Format('B', "Section"), "B|42|Section");
  EXPECT_EQ(Format('E', nullptr), "E|42");
  EXPECT_EQ(Format('S', "Async", 7), "S|42|Async|7");
  EXPECT_EQ(Format('F', "Async", 7), "F|42|Async|7");
  EXPECT_EQ(Format('C', "Counter", -5), "C|42|Counter|-5");
}

TEST(TracingTest, SanitizesTraceMarkerRecordNames) {
  EXPECT_EQ(Format('B', "a|b\nc\rd"), "B|42|a b c d");
  EXPECT_EQ(Format('C', "x|y", 1), "C|42|x y|1");
}

TEST(TracingTest, TruncatesLongTraceMarkerRecordNames) {
  const std::string name(64, 'x');
  char buffer[16];
  EXPECT_EQ(
      FormatTraceMarkerRecord(buffer, sizeof(buffer), 'B', 42, name.c_str(), 0),
      15u);
  EXPECT_EQ(std::string(buffer), "B|42|xxxxxxxxxx");
  // The value is never truncated.
  EXPECT_EQ(FormatTraceMarkerRecord(buffer, sizeof(buffer), 'C', 42,
                                    name.c_str(), 1234),
            15u);
  EXPECT_EQ(std::string(buffer), "C|42|xxxxx|1234");
  // Not even the fixed parts fit.
  EXPECT_EQ(FormatTraceMarkerRecord(buffer, 4, 'B', 42, "x", 0), 0u);
  EXPECT_EQ(FormatTraceMarkerRecord(buffer, 8, 'C', 42, "x", 123456789), 0u);
}

TEST(TracingTest, TracesProcessWhenGraphicsTagIsEnabled) {
  EXPECT_TRUE(ShouldTraceProcess("0x2", {}, "/bin/foo"));
  EXPECT_TRUE(ShouldTraceProcess("2", {}, "/bin/foo"));
  EXPECT_TRUE(ShouldTraceProcess("0x1e", {}, "/bin/foo"));
  EXPECT_FALSE(ShouldTraceProcess("0x1000", {}, "/bin/foo"));
  EXPECT_FALSE(ShouldTraceProcess("0", {}, "/bin/foo"));
  EXPECT_FALSE(ShouldTraceProcess("", {}, "/bin/foo"));
  EXPECT_FALSE(ShouldTraceProcess("0x2junk", {}, "/bin/foo"));
}

TEST(TracingTest, TracesProcessWhenAppTracingIsEnabledForIt) {
  EXPECT_TRUE(ShouldTraceProcess("0", {"*"}, "/bin/foo"));
  EXPECT_TRUE(ShouldTraceProcess("0", {"bar", "/bin/foo"}, "/bin/foo"));
  EXPECT_TRUE(ShouldTraceProcess("0", {"/bin/*"}, "/bin/foo"));
  EXPECT_TRUE(ShouldTraceProcess("0", {"*foo"}, "/bin/foo"));
  EXPECT_TRUE(ShouldTraceProcess("0", {"/bin/f?o"}, "/bin/foo"));
  EXPECT_TRUE(ShouldTraceProcess("0", {"/*/*o*"}, "/bin/foo"));
  EXPECT_TRUE(ShouldTraceProcess("0", {"*"}, ""));
  EXPECT_FALSE(ShouldTraceProcess("0", {"bar"}, "/bin/foo"));
  EXPECT_FALSE(ShouldTraceProcess("0", {"/bin/fo"}, "/bin/foo"));
  EXPECT_FALSE(ShouldTraceProcess("0", {"/bin/foo?"}, "/bin/foo"));
  EXPECT_FALSE(ShouldTraceProcess("0", {"*bar*"}, "/bin/foo"));
  EXPECT_FALSE(ShouldTraceProcess("0", {""}, "/bin/foo"));
  EXPECT_FALSE(ShouldTraceProcess("0", {}, "/bin/foo"));
}

}  // namespace impeller::interop::testing
