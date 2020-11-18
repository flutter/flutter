// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include "flutter/shell/common/rasterizer.h"

#include "flutter/shell/common/thread_host.h"
#include "flutter/testing/testing.h"
#include "gmock/gmock.h"

using testing::_;
using testing::ByMove;
using testing::Return;
using testing::ReturnRef;

namespace flutter {
namespace {
class MockDelegate : public Rasterizer::Delegate {
 public:
  MOCK_METHOD1(OnFrameRasterized, void(const FrameTiming& frame_timing));
  MOCK_METHOD0(GetFrameBudget, fml::Milliseconds());
  MOCK_CONST_METHOD0(GetLatestFrameTargetTime, fml::TimePoint());
  MOCK_CONST_METHOD0(GetTaskRunners, const TaskRunners&());
  MOCK_CONST_METHOD0(GetIsGpuDisabledSyncSwitch,
                     std::shared_ptr<fml::SyncSwitch>());
};

class MockSurface : public Surface {
 public:
  MOCK_METHOD0(IsValid, bool());
  MOCK_METHOD1(AcquireFrame,
               std::unique_ptr<SurfaceFrame>(const SkISize& size));
  MOCK_CONST_METHOD0(GetRootTransformation, SkMatrix());
  MOCK_METHOD0(GetContext, GrDirectContext*());
  MOCK_METHOD0(GetExternalViewEmbedder, ExternalViewEmbedder*());
  MOCK_METHOD0(MakeRenderContextCurrent, std::unique_ptr<GLContextResult>());
  MOCK_METHOD0(ClearRenderContext, bool());
};

class MockExternalViewEmbedder : public ExternalViewEmbedder {
 public:
  MOCK_METHOD0(GetRootCanvas, SkCanvas*());
  MOCK_METHOD0(CancelFrame, void());
  MOCK_METHOD4(BeginFrame,
               void(SkISize frame_size,
                    GrDirectContext* context,
                    double device_pixel_ratio,
                    fml::RefPtr<fml::RasterThreadMerger> raster_thread_merger));
  MOCK_METHOD2(PrerollCompositeEmbeddedView,
               void(int view_id, std::unique_ptr<EmbeddedViewParams> params));
  MOCK_METHOD1(PostPrerollAction,
               PostPrerollResult(
                   fml::RefPtr<fml::RasterThreadMerger> raster_thread_merger));
  MOCK_METHOD0(GetCurrentCanvases, std::vector<SkCanvas*>());
  MOCK_METHOD1(CompositeEmbeddedView, SkCanvas*(int view_id));
  MOCK_METHOD3(
      SubmitFrame,
      void(GrDirectContext* context,
           std::unique_ptr<SurfaceFrame> frame,
           const std::shared_ptr<fml::SyncSwitch>& gpu_disable_sync_switch));
  MOCK_METHOD2(EndFrame,
               void(bool should_resubmit_frame,
                    fml::RefPtr<fml::RasterThreadMerger> raster_thread_merger));
  MOCK_METHOD0(SupportsDynamicThreadMerging, bool());
};
}  // namespace

TEST(RasterizerTest, create) {
  MockDelegate delegate;
  auto rasterizer = std::make_unique<Rasterizer>(delegate);
  EXPECT_TRUE(rasterizer != nullptr);
}

TEST(RasterizerTest, drawEmptyPipeline) {
  std::string test_name =
      ::testing::UnitTest::GetInstance()->current_test_info()->name();
  ThreadHost thread_host("io.flutter.test." + test_name + ".",
                         ThreadHost::Type::Platform | ThreadHost::Type::GPU |
                             ThreadHost::Type::IO | ThreadHost::Type::UI);
  TaskRunners task_runners("test", thread_host.platform_thread->GetTaskRunner(),
                           thread_host.raster_thread->GetTaskRunner(),
                           thread_host.ui_thread->GetTaskRunner(),
                           thread_host.io_thread->GetTaskRunner());
  MockDelegate delegate;
  ON_CALL(delegate, GetTaskRunners()).WillByDefault(ReturnRef(task_runners));
  auto rasterizer = std::make_unique<Rasterizer>(delegate);
  auto surface = std::make_unique<MockSurface>();
  rasterizer->Setup(std::move(surface));
  fml::AutoResetWaitableEvent latch;
  thread_host.raster_thread->GetTaskRunner()->PostTask([&] {
    auto pipeline = fml::AdoptRef(new Pipeline<LayerTree>(/*depth=*/10));
    rasterizer->Draw(pipeline, nullptr);
    latch.Signal();
  });
  latch.Wait();
}

TEST(RasterizerTest,
     drawWithExternalViewEmbedderExternalViewEmbedderSubmitFrameCalled) {
  std::string test_name =
      ::testing::UnitTest::GetInstance()->current_test_info()->name();
  ThreadHost thread_host("io.flutter.test." + test_name + ".",
                         ThreadHost::Type::Platform | ThreadHost::Type::GPU |
                             ThreadHost::Type::IO | ThreadHost::Type::UI);
  TaskRunners task_runners("test", thread_host.platform_thread->GetTaskRunner(),
                           thread_host.raster_thread->GetTaskRunner(),
                           thread_host.ui_thread->GetTaskRunner(),
                           thread_host.io_thread->GetTaskRunner());
  MockDelegate delegate;
  EXPECT_CALL(delegate, GetTaskRunners())
      .WillRepeatedly(ReturnRef(task_runners));
  EXPECT_CALL(delegate, OnFrameRasterized(_));
  auto rasterizer = std::make_unique<Rasterizer>(delegate);
  auto surface = std::make_unique<MockSurface>();

  std::shared_ptr<MockExternalViewEmbedder> external_view_embedder =
      std::make_shared<MockExternalViewEmbedder>();
  rasterizer->SetExternalViewEmbedder(external_view_embedder);

  auto surface_frame = std::make_unique<SurfaceFrame>(
      /*surface=*/nullptr, /*supports_readback=*/true,
      /*submit_callback=*/[](const SurfaceFrame&, SkCanvas*) { return true; });
  EXPECT_CALL(*surface, AcquireFrame(SkISize()))
      .WillOnce(Return(ByMove(std::move(surface_frame))));

  EXPECT_CALL(*external_view_embedder,
              BeginFrame(/*frame_size=*/SkISize(), /*context=*/nullptr,
                         /*device_pixel_ratio=*/2.0,
                         /*raster_thread_merger=*/
                         fml::RefPtr<fml::RasterThreadMerger>(nullptr)))
      .Times(1);
  EXPECT_CALL(*external_view_embedder, SubmitFrame).Times(1);
  EXPECT_CALL(
      *external_view_embedder,
      EndFrame(/*should_resubmit_frame=*/false,
               /*raster_thread_merger=*/fml::RefPtr<fml::RasterThreadMerger>(
                   nullptr)))
      .Times(1);

  rasterizer->Setup(std::move(surface));
  fml::AutoResetWaitableEvent latch;
  thread_host.raster_thread->GetTaskRunner()->PostTask([&] {
    auto pipeline = fml::AdoptRef(new Pipeline<LayerTree>(/*depth=*/10));
    auto layer_tree = std::make_unique<LayerTree>(/*frame_size=*/SkISize(),
                                                  /*device_pixel_ratio=*/2.0f);
    bool result = pipeline->Produce().Complete(std::move(layer_tree));
    EXPECT_TRUE(result);
    auto no_discard = [](LayerTree&) { return false; };
    rasterizer->Draw(pipeline, no_discard);
    latch.Signal();
  });
  latch.Wait();
}

TEST(
    RasterizerTest,
    drawWithExternalViewEmbedderAndThreadMergerNotMergedExternalViewEmbedderSubmitFrameNotCalled) {
  std::string test_name =
      ::testing::UnitTest::GetInstance()->current_test_info()->name();
  ThreadHost thread_host("io.flutter.test." + test_name + ".",
                         ThreadHost::Type::Platform | ThreadHost::Type::GPU |
                             ThreadHost::Type::IO | ThreadHost::Type::UI);
  TaskRunners task_runners("test", thread_host.platform_thread->GetTaskRunner(),
                           thread_host.raster_thread->GetTaskRunner(),
                           thread_host.ui_thread->GetTaskRunner(),
                           thread_host.io_thread->GetTaskRunner());
  MockDelegate delegate;
  EXPECT_CALL(delegate, GetTaskRunners())
      .WillRepeatedly(ReturnRef(task_runners));
  EXPECT_CALL(delegate, OnFrameRasterized(_));
  auto rasterizer = std::make_unique<Rasterizer>(delegate);
  auto surface = std::make_unique<MockSurface>();
  std::shared_ptr<MockExternalViewEmbedder> external_view_embedder =
      std::make_shared<MockExternalViewEmbedder>();
  rasterizer->SetExternalViewEmbedder(external_view_embedder);
  EXPECT_CALL(*external_view_embedder, SupportsDynamicThreadMerging)
      .WillRepeatedly(Return(true));
  auto surface_frame = std::make_unique<SurfaceFrame>(
      /*surface=*/nullptr, /*supports_readback=*/true,
      /*submit_callback=*/[](const SurfaceFrame&, SkCanvas*) { return true; });
  EXPECT_CALL(*surface, AcquireFrame(SkISize()))
      .WillOnce(Return(ByMove(std::move(surface_frame))));

  EXPECT_CALL(*external_view_embedder,
              BeginFrame(/*frame_size=*/SkISize(), /*context=*/nullptr,
                         /*device_pixel_ratio=*/2.0,
                         /*raster_thread_merger=*/_))
      .Times(1);
  EXPECT_CALL(*external_view_embedder, SubmitFrame).Times(0);
  EXPECT_CALL(*external_view_embedder, EndFrame(/*should_resubmit_frame=*/false,
                                                /*raster_thread_merger=*/_))
      .Times(1);

  rasterizer->Setup(std::move(surface));
  fml::AutoResetWaitableEvent latch;
  thread_host.raster_thread->GetTaskRunner()->PostTask([&] {
    auto pipeline = fml::AdoptRef(new Pipeline<LayerTree>(/*depth=*/10));
    auto layer_tree = std::make_unique<LayerTree>(/*frame_size=*/SkISize(),
                                                  /*device_pixel_ratio=*/2.0f);
    bool result = pipeline->Produce().Complete(std::move(layer_tree));
    EXPECT_TRUE(result);
    auto no_discard = [](LayerTree&) { return false; };
    rasterizer->Draw(pipeline, no_discard);
    latch.Signal();
  });
  latch.Wait();
}

TEST(
    RasterizerTest,
    drawWithExternalViewEmbedderAndThreadsMergedExternalViewEmbedderSubmitFrameCalled) {
  std::string test_name =
      ::testing::UnitTest::GetInstance()->current_test_info()->name();
  ThreadHost thread_host("io.flutter.test." + test_name + ".",
                         ThreadHost::Type::Platform | ThreadHost::Type::GPU |
                             ThreadHost::Type::IO | ThreadHost::Type::UI);
  fml::MessageLoop::EnsureInitializedForCurrentThread();
  TaskRunners task_runners("test",
                           fml::MessageLoop::GetCurrent().GetTaskRunner(),
                           fml::MessageLoop::GetCurrent().GetTaskRunner(),
                           thread_host.ui_thread->GetTaskRunner(),
                           thread_host.io_thread->GetTaskRunner());

  MockDelegate delegate;
  EXPECT_CALL(delegate, GetTaskRunners())
      .WillRepeatedly(ReturnRef(task_runners));
  EXPECT_CALL(delegate, OnFrameRasterized(_));

  auto rasterizer = std::make_unique<Rasterizer>(delegate);
  auto surface = std::make_unique<MockSurface>();

  std::shared_ptr<MockExternalViewEmbedder> external_view_embedder =
      std::make_shared<MockExternalViewEmbedder>();
  rasterizer->SetExternalViewEmbedder(external_view_embedder);

  auto surface_frame = std::make_unique<SurfaceFrame>(
      /*surface=*/nullptr, /*supports_readback=*/true,
      /*submit_callback=*/[](const SurfaceFrame&, SkCanvas*) { return true; });
  EXPECT_CALL(*surface, AcquireFrame(SkISize()))
      .WillOnce(Return(ByMove(std::move(surface_frame))));
  EXPECT_CALL(*external_view_embedder, SupportsDynamicThreadMerging)
      .WillRepeatedly(Return(true));

  EXPECT_CALL(*external_view_embedder,
              BeginFrame(/*frame_size=*/SkISize(), /*context=*/nullptr,
                         /*device_pixel_ratio=*/2.0,
                         /*raster_thread_merger=*/_))
      .Times(1);
  EXPECT_CALL(*external_view_embedder, SubmitFrame).Times(1);
  EXPECT_CALL(*external_view_embedder, EndFrame(/*should_resubmit_frame=*/false,
                                                /*raster_thread_merger=*/_))
      .Times(1);

  rasterizer->Setup(std::move(surface));

  auto pipeline = fml::AdoptRef(new Pipeline<LayerTree>(/*depth=*/10));
  auto layer_tree = std::make_unique<LayerTree>(/*frame_size=*/SkISize(),
                                                /*device_pixel_ratio=*/2.0f);
  bool result = pipeline->Produce().Complete(std::move(layer_tree));
  EXPECT_TRUE(result);
  auto no_discard = [](LayerTree&) { return false; };
  rasterizer->Draw(pipeline, no_discard);
}

TEST(RasterizerTest, externalViewEmbedderDoesntEndFrameWhenNoSurfaceIsSet) {
  std::string test_name =
      ::testing::UnitTest::GetInstance()->current_test_info()->name();
  ThreadHost thread_host("io.flutter.test." + test_name + ".",
                         ThreadHost::Type::Platform | ThreadHost::Type::GPU |
                             ThreadHost::Type::IO | ThreadHost::Type::UI);
  TaskRunners task_runners("test", thread_host.platform_thread->GetTaskRunner(),
                           thread_host.raster_thread->GetTaskRunner(),
                           thread_host.ui_thread->GetTaskRunner(),
                           thread_host.io_thread->GetTaskRunner());
  MockDelegate delegate;
  EXPECT_CALL(delegate, GetTaskRunners())
      .WillRepeatedly(ReturnRef(task_runners));
  auto rasterizer = std::make_unique<Rasterizer>(delegate);

  std::shared_ptr<MockExternalViewEmbedder> external_view_embedder =
      std::make_shared<MockExternalViewEmbedder>();
  rasterizer->SetExternalViewEmbedder(external_view_embedder);

  EXPECT_CALL(
      *external_view_embedder,
      EndFrame(/*should_resubmit_frame=*/false,
               /*raster_thread_merger=*/fml::RefPtr<fml::RasterThreadMerger>(
                   nullptr)))
      .Times(0);

  fml::AutoResetWaitableEvent latch;
  thread_host.raster_thread->GetTaskRunner()->PostTask([&] {
    auto pipeline = fml::AdoptRef(new Pipeline<LayerTree>(/*depth=*/10));
    auto no_discard = [](LayerTree&) { return false; };
    rasterizer->Draw(pipeline, no_discard);
    latch.Signal();
  });
  latch.Wait();
}
}  // namespace flutter
