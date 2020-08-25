// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// A fuchsia-specific shell test.
//
// This test is only supposed to be ran on Fuchsia OS, as it exercises
// Fuchsia-specific functionality for which no equivalent exists elsewhere.

#define FML_USED_ON_EMBEDDER

#include <time.h>
#include <unistd.h>

#include <memory>

#include <fuchsia/intl/cpp/fidl.h>
#include <fuchsia/settings/cpp/fidl.h>
#include <lib/sys/cpp/component_context.h>

#include "flutter/fml/synchronization/count_down_latch.h"
#include "flutter/runtime/dart_vm.h"
#include "flutter/shell/common/shell_test.h"

namespace flutter {
namespace testing {

using fuchsia::intl::TimeZoneId;
using fuchsia::settings::Intl_Set_Result;
using fuchsia::settings::IntlSettings;

class FuchsiaShellTest : public ShellTest {
 protected:
  FuchsiaShellTest()
      : ctx_(sys::ComponentContext::CreateAndServeOutgoingDirectory()),
        intl_() {
    ctx_->svc()->Connect(intl_.NewRequest());
  }

  ~FuchsiaShellTest() {
    // Restore the time zoe that matche that of the test harness.  This is
    // the default.
    const std::string local_timezone = GetLocalTimezone();
    SetTimezone(local_timezone);
    AssertTimezone(local_timezone, GetSettings());
  }

  // Gets the international settings from this Fuchsia realm.
  IntlSettings GetSettings() {
    IntlSettings settings;
    zx_status_t status = intl_->Watch2(&settings);
    EXPECT_EQ(status, ZX_OK);
    return settings;
  }

  // Sets the timezone of this Fuchsia realm to `timezone_name`.
  void SetTimezone(const std::string& timezone_name) {
    fuchsia::settings::IntlSettings settings;
    settings.set_time_zone_id(TimeZoneId{.id = timezone_name});
    Intl_Set_Result result;
    zx_status_t status = intl_->Set(std::move(settings), &result);
    ASSERT_EQ(status, ZX_OK);
  }

  std::string GetLocalTimezone() {
    const time_t timestamp = time(nullptr);
    const struct tm* local_time = localtime(&timestamp);
    EXPECT_NE(local_time, nullptr)
        << "Could not get local time: errno=" << errno << ": "
        << strerror(errno);
    return std::string(local_time->tm_zone);
  }

  // Checks that the timezone name in the `settings` matches what is `expected`.
  void AssertTimezone(const std::string& expected,
                      const IntlSettings& settings) {
    ASSERT_EQ(expected, settings.time_zone_id().id);
  }

  std::unique_ptr<sys::ComponentContext> ctx_;
  fuchsia::settings::IntlSyncPtr intl_;

  fuchsia::settings::IntlSettings save_settings_;
};

static bool ValidateShell(Shell* shell) {
  if (!shell) {
    return false;
  }

  if (!shell->IsSetup()) {
    return false;
  }

  ShellTest::PlatformViewNotifyCreated(shell);

  {
    fml::AutoResetWaitableEvent latch;
    fml::TaskRunner::RunNowOrPostTask(
        shell->GetTaskRunners().GetPlatformTaskRunner(), [shell, &latch]() {
          shell->GetPlatformView()->NotifyDestroyed();
          latch.Signal();
        });
    latch.Wait();
  }

  return true;
}

// Verifies that changing the Fuchsia settings timezone through the FIDL
// settings interface results in a change of the reported local time in the
// isolate.
//
// The test is as follows:
//
// - Set an initial timezone, then get a timestamp from the isolate rounded down
//   to the nearest hour.  The assumption is as long as this test doesn't run
//   very near the whole hour, which should be very unlikely, the nearest hour
//   will vary depending on the time zone.
// - Set a different timezone.  Get a timestamp from the isolate again and
//   confirm that this time around the timestamps are different.
// - Set the initial timezone again, and get the timestamp.  This time, the
//   timestamp rounded down to whole hour should match the timestamp we got
//   in the initial step.
TEST_F(FuchsiaShellTest, LocaltimesVaryOnTimezoneChanges) {
  // Start with a set timezone.   System timezone will be restored at test
  // teardown.
  SetTimezone("Europe/Amsterdam");
  AssertTimezone("Europe/Amsterdam", GetSettings());

  // See fixtures/shell_test.dart, the callback NotifyLocalTime is declared
  // there.
  fml::AutoResetWaitableEvent latch;
  std::string dart_isolate_time_str;
  AddNativeCallback("NotifyLocalTime", CREATE_NATIVE_ENTRY([&](auto args) {
                      dart_isolate_time_str =
                          tonic::DartConverter<std::string>::FromDart(
                              Dart_GetNativeArgument(args, 0));
                      latch.Signal();
                    }));

  fml::AutoResetWaitableEvent fixture_latch;
  AddNativeCallback("WaitFixture", CREATE_NATIVE_ENTRY([&](auto args) {
                      // Wait for the test fixture to advance.
                      fixture_latch.Wait();
                    }));

  auto settings = CreateSettingsForFixture();
  auto configuration = RunConfiguration::InferFromSettings(settings);
  configuration.SetEntrypoint("timezonesChange");

  std::unique_ptr<Shell> shell = CreateShell(settings);
  ASSERT_NE(shell.get(), nullptr);
  ASSERT_TRUE(ValidateShell(shell.get()));
  RunEngine(shell.get(), std::move(configuration));
  latch.Wait();

  // Save the first reported local time.
  const std::string initial_dart_isolate_time_str = dart_isolate_time_str;

  SetTimezone("America/New_York");
  AssertTimezone("America/New_York", GetSettings());

  // Allow the dart program to advance.
  fixture_latch.Signal();
  // Wait until the isolate processes the timezone update.
  latch.Wait();

  const std::string modified_dart_isolate_time_str = dart_isolate_time_str;

  ASSERT_NE(initial_dart_isolate_time_str, modified_dart_isolate_time_str)
      << "Local time clocks in Europe/Amsterdam and America/New_York "
      << "should never be the same but this test says they are; time zone "
      << "handling in the dart VM is likely broken.";

  // Set the timezone back to the original one we started from, and verify
  // that the timestamp (to the resolution of 1 hour) match.
  SetTimezone("Europe/Amsterdam");
  AssertTimezone("Europe/Amsterdam", GetSettings());

  // Allow the dart program to advance.
  fixture_latch.Signal();
  // Wait until the isolate processes the timezone update.
  latch.Wait();

  const std::string final_dart_isolate_time_str = dart_isolate_time_str;

  ASSERT_EQ(initial_dart_isolate_time_str, final_dart_isolate_time_str)
      << "Local time in Europe/Amsterdam rounded down to nearest hour read "
         "twice"
      << "should be the same but this test says they are not; time zone "
      << "handling in the dart VM is likely broken.";

  DestroyShell(std::move(shell));
}

}  // namespace testing
}  // namespace flutter
