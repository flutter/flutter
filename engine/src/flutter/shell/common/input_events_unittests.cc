// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/common/shell_test.h"
#include "flutter/testing/testing.h"

// CREATE_FFI_LAMBDA is leaky by design
// NOLINTBEGIN(clang-analyzer-core.StackAddressEscape)

namespace flutter {
namespace testing {

// Throughout these tests, the choice of time unit is irrelevant as long as all
// times have the same units.
using UnitlessTime = int;

// Signature of a generator function that takes the frame index as input and
// returns the time of that frame.
using Generator = std::function<UnitlessTime(int)>;

namespace {

constexpr int64_t kImplicitViewId = 0;

}

void CreateSimulatedPointerData(PointerData& data,
                                PointerData::Change change,
                                double dx,
                                double dy) {
  data.time_stamp = 0;
  data.change = change;
  data.kind = PointerData::DeviceKind::kTouch;
  data.signal_kind = PointerData::SignalKind::kNone;
  data.device = 0;
  data.pointer_identifier = 0;
  data.physical_x = dx;
  data.physical_y = dy;
  data.physical_delta_x = 0.0;
  data.physical_delta_y = 0.0;
  data.buttons = 0;
  data.obscured = 0;
  data.synthesized = 0;
  data.pressure = 0.0;
  data.pressure_min = 0.0;
  data.pressure_max = 0.0;
  data.distance = 0.0;
  data.distance_max = 0.0;
  data.size = 0.0;
  data.radius_major = 0.0;
  data.radius_minor = 0.0;
  data.radius_min = 0.0;
  data.radius_max = 0.0;
  data.orientation = 0.0;
  data.tilt = 0.0;
  data.platformData = 0;
  data.scroll_delta_x = 0.0;
  data.scroll_delta_y = 0.0;
  data.view_id = kImplicitViewId;
}

TEST_F(ShellTest, CanCorrectlyPipePointerPacket) {
  // Sets up shell with test fixture.
  auto settings = CreateSettingsForFixture();
  std::unique_ptr<Shell> shell = CreateShell({
      .settings = settings,
      .platform_view_create_callback = ShellTestPlatformViewBuilder({
          .simulate_vsync = true,
      }),
  });

  auto configuration = RunConfiguration::InferFromSettings(settings);
  configuration.SetEntrypoint("onPointerDataPacketMain");
  // Sets up native handler.
  fml::AutoResetWaitableEvent reportLatch;
  std::vector<int64_t> result_sequence;
  auto nativeOnPointerDataPacket = [&reportLatch,
                                    &result_sequence](Dart_Handle sequences) {
    result_sequence =
        tonic::DartConverter<std::vector<int64_t>>::FromDart(sequences);
    reportLatch.Signal();
  };
  // Starts engine.
  AddFfiNativeCallback("NativeOnPointerDataPacket",
                       CREATE_FFI_LAMBDA(nativeOnPointerDataPacket));
  ASSERT_TRUE(configuration.IsValid());
  RunEngine(shell.get(), std::move(configuration));
  // Starts test.
  auto packet = std::make_unique<PointerDataPacket>(6);
  PointerData data;
  CreateSimulatedPointerData(data, PointerData::Change::kAdd, 0.0, 0.0);
  packet->SetPointerData(0, data);
  CreateSimulatedPointerData(data, PointerData::Change::kHover, 3.0, 0.0);
  packet->SetPointerData(1, data);
  CreateSimulatedPointerData(data, PointerData::Change::kDown, 3.0, 0.0);
  packet->SetPointerData(2, data);
  CreateSimulatedPointerData(data, PointerData::Change::kMove, 3.0, 4.0);
  packet->SetPointerData(3, data);
  CreateSimulatedPointerData(data, PointerData::Change::kUp, 3.0, 4.0);
  packet->SetPointerData(4, data);
  CreateSimulatedPointerData(data, PointerData::Change::kRemove, 3.0, 4.0);
  packet->SetPointerData(5, data);
  ShellTest::DispatchPointerData(shell.get(), std::move(packet));
  ShellTest::VSyncFlush(shell.get());

  reportLatch.Wait();
  size_t expect_length = 6;
  ASSERT_EQ(result_sequence.size(), expect_length);
  ASSERT_EQ(PointerData::Change(result_sequence[0]), PointerData::Change::kAdd);
  ASSERT_EQ(PointerData::Change(result_sequence[1]),
            PointerData::Change::kHover);
  ASSERT_EQ(PointerData::Change(result_sequence[2]),
            PointerData::Change::kDown);
  ASSERT_EQ(PointerData::Change(result_sequence[3]),
            PointerData::Change::kMove);
  ASSERT_EQ(PointerData::Change(result_sequence[4]), PointerData::Change::kUp);
  ASSERT_EQ(PointerData::Change(result_sequence[5]),
            PointerData::Change::kRemove);

  // Cleans up shell.
  ASSERT_TRUE(DartVMRef::IsInstanceRunning());
  DestroyShell(std::move(shell));
  ASSERT_FALSE(DartVMRef::IsInstanceRunning());
}

TEST_F(ShellTest, CanCorrectlySynthesizePointerPacket) {
  // Sets up shell with test fixture.
  auto settings = CreateSettingsForFixture();
  std::unique_ptr<Shell> shell = CreateShell({
      .settings = settings,
      .platform_view_create_callback = ShellTestPlatformViewBuilder({
          .simulate_vsync = true,
      }),
  });

  auto configuration = RunConfiguration::InferFromSettings(settings);
  configuration.SetEntrypoint("onPointerDataPacketMain");
  // Sets up native handler.
  fml::AutoResetWaitableEvent reportLatch;
  std::vector<int64_t> result_sequence;
  auto nativeOnPointerDataPacket = [&reportLatch,
                                    &result_sequence](Dart_Handle sequences) {
    result_sequence =
        tonic::DartConverter<std::vector<int64_t>>::FromDart(sequences);
    reportLatch.Signal();
  };
  // Starts engine.
  AddFfiNativeCallback("NativeOnPointerDataPacket",
                       CREATE_FFI_LAMBDA(nativeOnPointerDataPacket));
  ASSERT_TRUE(configuration.IsValid());
  RunEngine(shell.get(), std::move(configuration));
  // Starts test.
  auto packet = std::make_unique<PointerDataPacket>(4);
  PointerData data;
  CreateSimulatedPointerData(data, PointerData::Change::kAdd, 0.0, 0.0);
  packet->SetPointerData(0, data);
  CreateSimulatedPointerData(data, PointerData::Change::kDown, 3.0, 0.0);
  packet->SetPointerData(1, data);
  CreateSimulatedPointerData(data, PointerData::Change::kUp, 3.0, 4.0);
  packet->SetPointerData(2, data);
  CreateSimulatedPointerData(data, PointerData::Change::kRemove, 3.0, 4.0);
  packet->SetPointerData(3, data);
  ShellTest::DispatchPointerData(shell.get(), std::move(packet));
  ShellTest::VSyncFlush(shell.get());

  reportLatch.Wait();
  size_t expect_length = 6;
  ASSERT_EQ(result_sequence.size(), expect_length);
  ASSERT_EQ(PointerData::Change(result_sequence[0]), PointerData::Change::kAdd);
  // The pointer data packet converter should synthesize a hover event.
  ASSERT_EQ(PointerData::Change(result_sequence[1]),
            PointerData::Change::kHover);
  ASSERT_EQ(PointerData::Change(result_sequence[2]),
            PointerData::Change::kDown);
  // The pointer data packet converter should synthesize a move event.
  ASSERT_EQ(PointerData::Change(result_sequence[3]),
            PointerData::Change::kMove);
  ASSERT_EQ(PointerData::Change(result_sequence[4]), PointerData::Change::kUp);
  ASSERT_EQ(PointerData::Change(result_sequence[5]),
            PointerData::Change::kRemove);

  // Cleans up shell.
  ASSERT_TRUE(DartVMRef::IsInstanceRunning());
  DestroyShell(std::move(shell));
  ASSERT_FALSE(DartVMRef::IsInstanceRunning());
}

}  // namespace testing
}  // namespace flutter

// NOLINTEND(clang-analyzer-core.StackAddressEscape)
