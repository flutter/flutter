// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/dl_op_flags.h"
#include "flutter/lib/ui/painting/paint.h"
#include "flutter/shell/common/shell_test.h"
#include "flutter/shell/common/thread_host.h"

#include "flutter/testing/testing.h"

namespace flutter {
namespace testing {

TEST_F(ShellTest, ConvertPaintToDlPaint) {
  auto message_latch = std::make_shared<fml::AutoResetWaitableEvent>();
  DlPaint dl_paint;

  auto nativeToDlPaint = [message_latch, &dl_paint](Dart_NativeArguments args) {
    Dart_Handle dart_paint = Dart_GetNativeArgument(args, 0);
    Dart_Handle paint_objects =
        Dart_GetField(dart_paint, tonic::ToDart("_objects"));
    Dart_Handle paint_data = Dart_GetField(dart_paint, tonic::ToDart("_data"));
    Paint ui_paint(paint_objects, paint_data);

    ui_paint.paint(dl_paint, DisplayListOpFlags::kDrawRectFlags,
                   DlTileMode::kClamp);
    message_latch->Signal();
  };

  Settings settings = CreateSettingsForFixture();
  TaskRunners task_runners("test",                  // label
                           GetCurrentTaskRunner(),  // platform
                           CreateNewThread(),       // raster
                           CreateNewThread(),       // ui
                           CreateNewThread()        // io
  );

  AddNativeCallback("ConvertPaintToDlPaint",
                    CREATE_NATIVE_ENTRY(nativeToDlPaint));

  std::unique_ptr<Shell> shell = CreateShell(settings, task_runners);

  ASSERT_TRUE(shell->IsSetup());
  auto configuration = RunConfiguration::InferFromSettings(settings);
  configuration.SetEntrypoint("convertPaintToDlPaint");

  shell->RunEngine(std::move(configuration), [](auto result) {
    ASSERT_EQ(result, Engine::RunStatus::Success);
  });

  message_latch->Wait();
  DestroyShell(std::move(shell), task_runners);

  EXPECT_EQ(dl_paint.getBlendMode(), DlBlendMode::kModulate);
  EXPECT_EQ(static_cast<uint32_t>(dl_paint.getColor().argb()), 0x11223344u);
  if (dl_paint.getColorFilter()) {
    std::shared_ptr<const DlColorFilter> expected_filter =
        DlColorFilter::MakeBlend(DlColor(0x55667788), DlBlendMode::kXor);
    EXPECT_EQ(*dl_paint.getColorFilter(), *expected_filter);
  } else {
    FAIL() << "color filter was nullptr";
  }
  if (dl_paint.getMaskFilter()) {
    EXPECT_EQ(*dl_paint.getMaskFilter(),
              DlBlurMaskFilter(DlBlurStyle::kInner, 0.75));
  } else {
    FAIL() << "mask filter was nullptr";
  }
  EXPECT_EQ(dl_paint.getDrawStyle(), DlDrawStyle::kStroke);
}

}  // namespace testing
}  // namespace flutter
