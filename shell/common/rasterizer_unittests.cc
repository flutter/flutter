// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include "flutter/shell/common/rasterizer.h"

#include <memory>
#include <optional>

#include "flutter/flow/frame_timings.h"
#include "flutter/fml/synchronization/count_down_latch.h"
#include "flutter/fml/time/time_point.h"
#include "flutter/shell/common/thread_host.h"
#include "flutter/testing/testing.h"

#include "third_party/skia/include/core/SkSurface.h"

#include "gmock/gmock.h"

using testing::_;
using testing::ByMove;
using testing::NiceMock;
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
  MOCK_CONST_METHOD0(GetParentRasterThreadMerger,
                     const fml::RefPtr<fml::RasterThreadMerger>());
  MOCK_CONST_METHOD0(GetIsGpuDisabledSyncSwitch,
                     std::shared_ptr<const fml::SyncSwitch>());
  MOCK_METHOD0(CreateSnapshotSurface, std::unique_ptr<Surface>());
  MOCK_CONST_METHOD0(GetSettings, const Settings&());
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
  MOCK_CONST_METHOD0(AllowsDrawingWhenGpuDisabled, bool());
};

class MockExternalViewEmbedder : public ExternalViewEmbedder {
 public:
  MOCK_METHOD0(GetRootCanvas, DlCanvas*());
  MOCK_METHOD0(CancelFrame, void());
  MOCK_METHOD4(BeginFrame,
               void(SkISize frame_size,
                    GrDirectContext* context,
                    double device_pixel_ratio,
                    fml::RefPtr<fml::RasterThreadMerger> raster_thread_merger));
  MOCK_METHOD2(PrerollCompositeEmbeddedView,
               void(int64_t view_id,
                    std::unique_ptr<EmbeddedViewParams> params));
  MOCK_METHOD1(PostPrerollAction,
               PostPrerollResult(
                   fml::RefPtr<fml::RasterThreadMerger> raster_thread_merger));
  MOCK_METHOD1(CompositeEmbeddedView, DlCanvas*(int64_t view_id));
  MOCK_METHOD2(SubmitFrame,
               void(GrDirectContext* context,
                    std::unique_ptr<SurfaceFrame> frame));
  MOCK_METHOD2(EndFrame,
               void(bool should_resubmit_frame,
                    fml::RefPtr<fml::RasterThreadMerger> raster_thread_merger));
  MOCK_METHOD0(SupportsDynamicThreadMerging, bool());
};
}  // namespace

TEST(RasterizerTest, create) {
  NiceMock<MockDelegate> delegate;
  Settings settings;
  ON_CALL(delegate, GetSettings()).WillByDefault(ReturnRef(settings));
  auto rasterizer = std::make_unique<Rasterizer>(delegate);
  EXPECT_TRUE(rasterizer != nullptr);
}

static std::unique_ptr<FrameTimingsRecorder> CreateFinishedBuildRecorder(
    fml::TimePoint timestamp) {
  std::unique_ptr<FrameTimingsRecorder> recorder =
      std::make_unique<FrameTimingsRecorder>();
  recorder->RecordVsync(timestamp, timestamp);
  recorder->RecordBuildStart(timestamp);
  recorder->RecordBuildEnd(timestamp);
  return recorder;
}

static std::unique_ptr<FrameTimingsRecorder> CreateFinishedBuildRecorder() {
  return CreateFinishedBuildRecorder(fml::TimePoint::Now());
}

TEST(RasterizerTest, drawEmptyPipeline) {
  std::string test_name =
      ::testing::UnitTest::GetInstance()->current_test_info()->name();
  ThreadHost thread_host("io.flutter.test." + test_name + ".",
                         ThreadHost::Type::Platform | ThreadHost::Type::RASTER |
                             ThreadHost::Type::IO | ThreadHost::Type::UI);
  TaskRunners task_runners("test", thread_host.platform_thread->GetTaskRunner(),
                           thread_host.raster_thread->GetTaskRunner(),
                           thread_host.ui_thread->GetTaskRunner(),
                           thread_host.io_thread->GetTaskRunner());
  NiceMock<MockDelegate> delegate;
  Settings settings;
  ON_CALL(delegate, GetSettings()).WillByDefault(ReturnRef(settings));
  ON_CALL(delegate, GetTaskRunners()).WillByDefault(ReturnRef(task_runners));
  auto rasterizer = std::make_unique<Rasterizer>(delegate);
  auto surface = std::make_unique<NiceMock<MockSurface>>();
  EXPECT_CALL(*surface, MakeRenderContextCurrent())
      .WillOnce(Return(ByMove(std::make_unique<GLContextDefaultResult>(true))));
  rasterizer->Setup(std::move(surface));
  fml::AutoResetWaitableEvent latch;
  thread_host.raster_thread->GetTaskRunner()->PostTask([&] {
    auto pipeline = std::make_shared<LayerTreePipeline>(/*depth=*/10);
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
                         ThreadHost::Type::Platform | ThreadHost::Type::RASTER |
                             ThreadHost::Type::IO | ThreadHost::Type::UI);
  TaskRunners task_runners("test", thread_host.platform_thread->GetTaskRunner(),
                           thread_host.raster_thread->GetTaskRunner(),
                           thread_host.ui_thread->GetTaskRunner(),
                           thread_host.io_thread->GetTaskRunner());
  NiceMock<MockDelegate> delegate;
  Settings settings;
  ON_CALL(delegate, GetSettings()).WillByDefault(ReturnRef(settings));
  EXPECT_CALL(delegate, GetTaskRunners())
      .WillRepeatedly(ReturnRef(task_runners));
  EXPECT_CALL(delegate, OnFrameRasterized(_));
  auto rasterizer = std::make_unique<Rasterizer>(delegate);
  auto surface = std::make_unique<NiceMock<MockSurface>>();

  std::shared_ptr<NiceMock<MockExternalViewEmbedder>> external_view_embedder =
      std::make_shared<NiceMock<MockExternalViewEmbedder>>();
  rasterizer->SetExternalViewEmbedder(external_view_embedder);

  SurfaceFrame::FramebufferInfo framebuffer_info;
  framebuffer_info.supports_readback = true;

  auto surface_frame = std::make_unique<SurfaceFrame>(
      /*surface=*/nullptr, framebuffer_info,
      /*submit_callback=*/[](const SurfaceFrame&, DlCanvas*) { return true; },
      /*frame_size=*/SkISize::Make(800, 600));
  EXPECT_CALL(*surface, AllowsDrawingWhenGpuDisabled()).WillOnce(Return(true));
  EXPECT_CALL(*surface, AcquireFrame(SkISize()))
      .WillOnce(Return(ByMove(std::move(surface_frame))));
  EXPECT_CALL(*surface, MakeRenderContextCurrent())
      .WillOnce(Return(ByMove(std::make_unique<GLContextDefaultResult>(true))));

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
    auto pipeline = std::make_shared<LayerTreePipeline>(/*depth=*/10);
    auto layer_tree = std::make_shared<LayerTree>(/*frame_size=*/SkISize(),
                                                  /*device_pixel_ratio=*/2.0f);
    auto layer_tree_item = std::make_unique<LayerTreeItem>(
        std::move(layer_tree), CreateFinishedBuildRecorder());
    PipelineProduceResult result =
        pipeline->Produce().Complete(std::move(layer_tree_item));
    EXPECT_TRUE(result.success);
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
                         ThreadHost::Type::Platform | ThreadHost::Type::RASTER |
                             ThreadHost::Type::IO | ThreadHost::Type::UI);
  TaskRunners task_runners("test", thread_host.platform_thread->GetTaskRunner(),
                           thread_host.raster_thread->GetTaskRunner(),
                           thread_host.ui_thread->GetTaskRunner(),
                           thread_host.io_thread->GetTaskRunner());
  NiceMock<MockDelegate> delegate;
  Settings settings;
  ON_CALL(delegate, GetSettings()).WillByDefault(ReturnRef(settings));
  EXPECT_CALL(delegate, GetTaskRunners())
      .WillRepeatedly(ReturnRef(task_runners));
  EXPECT_CALL(delegate, OnFrameRasterized(_));
  auto rasterizer = std::make_unique<Rasterizer>(delegate);
  auto surface = std::make_unique<NiceMock<MockSurface>>();
  std::shared_ptr<NiceMock<MockExternalViewEmbedder>> external_view_embedder =
      std::make_shared<NiceMock<MockExternalViewEmbedder>>();
  rasterizer->SetExternalViewEmbedder(external_view_embedder);
  EXPECT_CALL(*external_view_embedder, SupportsDynamicThreadMerging)
      .WillRepeatedly(Return(true));
  SurfaceFrame::FramebufferInfo framebuffer_info;
  framebuffer_info.supports_readback = true;
  auto surface_frame = std::make_unique<SurfaceFrame>(
      /*surface=*/nullptr, framebuffer_info,
      /*submit_callback=*/[](const SurfaceFrame&, DlCanvas*) { return true; },
      /*frame_size=*/SkISize::Make(800, 600));
  EXPECT_CALL(*surface, AllowsDrawingWhenGpuDisabled()).WillOnce(Return(true));
  EXPECT_CALL(*surface, AcquireFrame(SkISize()))
      .WillOnce(Return(ByMove(std::move(surface_frame))));
  EXPECT_CALL(*surface, MakeRenderContextCurrent())
      .WillOnce(Return(ByMove(std::make_unique<GLContextDefaultResult>(true))));

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
    auto pipeline = std::make_shared<LayerTreePipeline>(/*depth=*/10);
    auto layer_tree = std::make_shared<LayerTree>(/*frame_size=*/SkISize(),
                                                  /*device_pixel_ratio=*/2.0f);
    auto layer_tree_item = std::make_unique<LayerTreeItem>(
        std::move(layer_tree), CreateFinishedBuildRecorder());
    PipelineProduceResult result =
        pipeline->Produce().Complete(std::move(layer_tree_item));
    EXPECT_TRUE(result.success);
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
                         ThreadHost::Type::Platform | ThreadHost::Type::RASTER |
                             ThreadHost::Type::IO | ThreadHost::Type::UI);
  fml::MessageLoop::EnsureInitializedForCurrentThread();
  TaskRunners task_runners("test",
                           fml::MessageLoop::GetCurrent().GetTaskRunner(),
                           fml::MessageLoop::GetCurrent().GetTaskRunner(),
                           thread_host.ui_thread->GetTaskRunner(),
                           thread_host.io_thread->GetTaskRunner());

  NiceMock<MockDelegate> delegate;
  Settings settings;
  ON_CALL(delegate, GetSettings()).WillByDefault(ReturnRef(settings));
  EXPECT_CALL(delegate, GetTaskRunners())
      .WillRepeatedly(ReturnRef(task_runners));
  EXPECT_CALL(delegate, OnFrameRasterized(_));

  auto rasterizer = std::make_unique<Rasterizer>(delegate);
  auto surface = std::make_unique<NiceMock<MockSurface>>();

  std::shared_ptr<NiceMock<MockExternalViewEmbedder>> external_view_embedder =
      std::make_shared<NiceMock<MockExternalViewEmbedder>>();
  rasterizer->SetExternalViewEmbedder(external_view_embedder);

  SurfaceFrame::FramebufferInfo framebuffer_info;
  framebuffer_info.supports_readback = true;

  auto surface_frame = std::make_unique<SurfaceFrame>(
      /*surface=*/nullptr, framebuffer_info,
      /*submit_callback=*/[](const SurfaceFrame&, DlCanvas*) { return true; },
      /*frame_size=*/SkISize::Make(800, 600));
  EXPECT_CALL(*surface, AllowsDrawingWhenGpuDisabled()).WillOnce(Return(true));
  EXPECT_CALL(*surface, AcquireFrame(SkISize()))
      .WillOnce(Return(ByMove(std::move(surface_frame))));
  EXPECT_CALL(*surface, MakeRenderContextCurrent())
      .WillOnce(Return(ByMove(std::make_unique<GLContextDefaultResult>(true))));
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

  auto pipeline = std::make_shared<LayerTreePipeline>(/*depth=*/10);
  auto layer_tree = std::make_shared<LayerTree>(/*frame_size=*/SkISize(),
                                                /*device_pixel_ratio=*/2.0f);
  auto layer_tree_item = std::make_unique<LayerTreeItem>(
      std::move(layer_tree), CreateFinishedBuildRecorder());
  PipelineProduceResult result =
      pipeline->Produce().Complete(std::move(layer_tree_item));
  EXPECT_TRUE(result.success);
  auto no_discard = [](LayerTree&) { return false; };
  rasterizer->Draw(pipeline, no_discard);
}

TEST(RasterizerTest,
     drawLastLayerTreeWithThreadsMergedExternalViewEmbedderAndEndFrameCalled) {
  std::string test_name =
      ::testing::UnitTest::GetInstance()->current_test_info()->name();
  ThreadHost thread_host("io.flutter.test." + test_name + ".",
                         ThreadHost::Type::Platform | ThreadHost::Type::RASTER |
                             ThreadHost::Type::IO | ThreadHost::Type::UI);
  fml::MessageLoop::EnsureInitializedForCurrentThread();
  TaskRunners task_runners("test",
                           fml::MessageLoop::GetCurrent().GetTaskRunner(),
                           fml::MessageLoop::GetCurrent().GetTaskRunner(),
                           thread_host.ui_thread->GetTaskRunner(),
                           thread_host.io_thread->GetTaskRunner());

  NiceMock<MockDelegate> delegate;
  Settings settings;
  ON_CALL(delegate, GetSettings()).WillByDefault(ReturnRef(settings));
  EXPECT_CALL(delegate, GetTaskRunners())
      .WillRepeatedly(ReturnRef(task_runners));
  EXPECT_CALL(delegate, OnFrameRasterized(_));

  auto rasterizer = std::make_unique<Rasterizer>(delegate);
  auto surface = std::make_unique<NiceMock<MockSurface>>();

  std::shared_ptr<NiceMock<MockExternalViewEmbedder>> external_view_embedder =
      std::make_shared<NiceMock<MockExternalViewEmbedder>>();
  rasterizer->SetExternalViewEmbedder(external_view_embedder);

  SurfaceFrame::FramebufferInfo framebuffer_info;
  framebuffer_info.supports_readback = true;

  auto surface_frame1 = std::make_unique<SurfaceFrame>(
      /*surface=*/nullptr, framebuffer_info,
      /*submit_callback=*/[](const SurfaceFrame&, DlCanvas*) { return true; },
      /*frame_size=*/SkISize::Make(800, 600));
  auto surface_frame2 = std::make_unique<SurfaceFrame>(
      /*surface=*/nullptr, framebuffer_info,
      /*submit_callback=*/[](const SurfaceFrame&, DlCanvas*) { return true; },
      /*frame_size=*/SkISize::Make(800, 600));
  EXPECT_CALL(*surface, AllowsDrawingWhenGpuDisabled())
      .WillRepeatedly(Return(true));
  // Prepare two frames for Draw() and DrawLastLayerTree().
  EXPECT_CALL(*surface, AcquireFrame(SkISize()))
      .WillOnce(Return(ByMove(std::move(surface_frame1))))
      .WillOnce(Return(ByMove(std::move(surface_frame2))));
  EXPECT_CALL(*surface, MakeRenderContextCurrent())
      .WillOnce(Return(ByMove(std::make_unique<GLContextDefaultResult>(true))));
  EXPECT_CALL(*external_view_embedder, SupportsDynamicThreadMerging)
      .WillRepeatedly(Return(true));

  EXPECT_CALL(*external_view_embedder,
              BeginFrame(/*frame_size=*/SkISize(), /*context=*/nullptr,
                         /*device_pixel_ratio=*/2.0,
                         /*raster_thread_merger=*/_))
      .Times(2);
  EXPECT_CALL(*external_view_embedder, SubmitFrame).Times(2);
  EXPECT_CALL(*external_view_embedder, EndFrame(/*should_resubmit_frame=*/false,
                                                /*raster_thread_merger=*/_))
      .Times(2);

  rasterizer->Setup(std::move(surface));

  auto pipeline = std::make_shared<LayerTreePipeline>(/*depth=*/10);
  auto layer_tree = std::make_shared<LayerTree>(/*frame_size=*/SkISize(),
                                                /*device_pixel_ratio=*/2.0f);
  auto layer_tree_item = std::make_unique<LayerTreeItem>(
      std::move(layer_tree), CreateFinishedBuildRecorder());
  PipelineProduceResult result =
      pipeline->Produce().Complete(std::move(layer_tree_item));
  EXPECT_TRUE(result.success);
  auto no_discard = [](LayerTree&) { return false; };

  // The Draw() will respectively call BeginFrame(), SubmitFrame() and
  // EndFrame() one time.
  rasterizer->Draw(pipeline, no_discard);

  // The DrawLastLayerTree() will respectively call BeginFrame(), SubmitFrame()
  // and EndFrame() one more time, totally 2 times.
  rasterizer->DrawLastLayerTree(CreateFinishedBuildRecorder());
}

TEST(RasterizerTest, externalViewEmbedderDoesntEndFrameWhenNoSurfaceIsSet) {
  std::string test_name =
      ::testing::UnitTest::GetInstance()->current_test_info()->name();
  ThreadHost thread_host("io.flutter.test." + test_name + ".",
                         ThreadHost::Type::Platform | ThreadHost::Type::RASTER |
                             ThreadHost::Type::IO | ThreadHost::Type::UI);
  TaskRunners task_runners("test", thread_host.platform_thread->GetTaskRunner(),
                           thread_host.raster_thread->GetTaskRunner(),
                           thread_host.ui_thread->GetTaskRunner(),
                           thread_host.io_thread->GetTaskRunner());
  NiceMock<MockDelegate> delegate;
  Settings settings;
  ON_CALL(delegate, GetSettings()).WillByDefault(ReturnRef(settings));
  EXPECT_CALL(delegate, GetTaskRunners())
      .WillRepeatedly(ReturnRef(task_runners));
  auto rasterizer = std::make_unique<Rasterizer>(delegate);

  std::shared_ptr<NiceMock<MockExternalViewEmbedder>> external_view_embedder =
      std::make_shared<NiceMock<MockExternalViewEmbedder>>();
  rasterizer->SetExternalViewEmbedder(external_view_embedder);

  EXPECT_CALL(
      *external_view_embedder,
      EndFrame(/*should_resubmit_frame=*/false,
               /*raster_thread_merger=*/fml::RefPtr<fml::RasterThreadMerger>(
                   nullptr)))
      .Times(0);

  fml::AutoResetWaitableEvent latch;
  thread_host.raster_thread->GetTaskRunner()->PostTask([&] {
    auto pipeline = std::make_shared<LayerTreePipeline>(/*depth=*/10);
    auto layer_tree = std::make_shared<LayerTree>(/*frame_size=*/SkISize(),
                                                  /*device_pixel_ratio=*/2.0f);
    auto layer_tree_item = std::make_unique<LayerTreeItem>(
        std::move(layer_tree), CreateFinishedBuildRecorder());
    PipelineProduceResult result =
        pipeline->Produce().Complete(std::move(layer_tree_item));
    EXPECT_TRUE(result.success);
    auto no_discard = [](LayerTree&) { return false; };
    rasterizer->Draw(pipeline, no_discard);
    latch.Signal();
  });
  latch.Wait();
}

TEST(RasterizerTest, externalViewEmbedderDoesntEndFrameWhenNotUsedThisFrame) {
  std::string test_name =
      ::testing::UnitTest::GetInstance()->current_test_info()->name();
  ThreadHost thread_host("io.flutter.test." + test_name + ".",
                         ThreadHost::Type::Platform | ThreadHost::Type::RASTER |
                             ThreadHost::Type::IO | ThreadHost::Type::UI);
  TaskRunners task_runners("test", thread_host.platform_thread->GetTaskRunner(),
                           thread_host.raster_thread->GetTaskRunner(),
                           thread_host.ui_thread->GetTaskRunner(),
                           thread_host.io_thread->GetTaskRunner());
  NiceMock<MockDelegate> delegate;
  Settings settings;
  ON_CALL(delegate, GetSettings()).WillByDefault(ReturnRef(settings));
  EXPECT_CALL(delegate, GetTaskRunners())
      .WillRepeatedly(ReturnRef(task_runners));

  auto rasterizer = std::make_unique<Rasterizer>(delegate);
  auto surface = std::make_unique<NiceMock<MockSurface>>();
  EXPECT_CALL(*surface, MakeRenderContextCurrent())
      .WillOnce(Return(ByMove(std::make_unique<GLContextDefaultResult>(true))));

  std::shared_ptr<NiceMock<MockExternalViewEmbedder>> external_view_embedder =
      std::make_shared<NiceMock<MockExternalViewEmbedder>>();
  rasterizer->SetExternalViewEmbedder(external_view_embedder);
  rasterizer->Setup(std::move(surface));

  EXPECT_CALL(*external_view_embedder,
              BeginFrame(/*frame_size=*/SkISize(), /*context=*/nullptr,
                         /*device_pixel_ratio=*/2.0,
                         /*raster_thread_merger=*/_))
      .Times(0);
  EXPECT_CALL(
      *external_view_embedder,
      EndFrame(/*should_resubmit_frame=*/false,
               /*raster_thread_merger=*/fml::RefPtr<fml::RasterThreadMerger>(
                   nullptr)))
      .Times(0);

  fml::AutoResetWaitableEvent latch;
  thread_host.raster_thread->GetTaskRunner()->PostTask([&] {
    auto pipeline = std::make_shared<LayerTreePipeline>(/*depth=*/10);
    auto layer_tree = std::make_shared<LayerTree>(/*frame_size=*/SkISize(),
                                                  /*device_pixel_ratio=*/2.0f);
    auto layer_tree_item = std::make_unique<LayerTreeItem>(
        std::move(layer_tree), CreateFinishedBuildRecorder());
    PipelineProduceResult result =
        pipeline->Produce().Complete(std::move(layer_tree_item));
    EXPECT_TRUE(result.success);
    // Always discard the layer tree.
    auto discard_callback = [](LayerTree&) { return true; };
    RasterStatus status = rasterizer->Draw(pipeline, discard_callback);
    EXPECT_EQ(status, RasterStatus::kDiscarded);
    latch.Signal();
  });
  latch.Wait();
}

TEST(RasterizerTest, externalViewEmbedderDoesntEndFrameWhenPipelineIsEmpty) {
  std::string test_name =
      ::testing::UnitTest::GetInstance()->current_test_info()->name();
  ThreadHost thread_host("io.flutter.test." + test_name + ".",
                         ThreadHost::Type::Platform | ThreadHost::Type::RASTER |
                             ThreadHost::Type::IO | ThreadHost::Type::UI);
  TaskRunners task_runners("test", thread_host.platform_thread->GetTaskRunner(),
                           thread_host.raster_thread->GetTaskRunner(),
                           thread_host.ui_thread->GetTaskRunner(),
                           thread_host.io_thread->GetTaskRunner());
  NiceMock<MockDelegate> delegate;
  Settings settings;
  ON_CALL(delegate, GetSettings()).WillByDefault(ReturnRef(settings));
  EXPECT_CALL(delegate, GetTaskRunners())
      .WillRepeatedly(ReturnRef(task_runners));

  auto rasterizer = std::make_unique<Rasterizer>(delegate);
  auto surface = std::make_unique<NiceMock<MockSurface>>();
  EXPECT_CALL(*surface, MakeRenderContextCurrent())
      .WillOnce(Return(ByMove(std::make_unique<GLContextDefaultResult>(true))));

  std::shared_ptr<NiceMock<MockExternalViewEmbedder>> external_view_embedder =
      std::make_shared<NiceMock<MockExternalViewEmbedder>>();
  rasterizer->SetExternalViewEmbedder(external_view_embedder);
  rasterizer->Setup(std::move(surface));

  EXPECT_CALL(
      *external_view_embedder,
      EndFrame(/*should_resubmit_frame=*/false,
               /*raster_thread_merger=*/fml::RefPtr<fml::RasterThreadMerger>(
                   nullptr)))
      .Times(0);

  fml::AutoResetWaitableEvent latch;
  thread_host.raster_thread->GetTaskRunner()->PostTask([&] {
    auto pipeline = std::make_shared<LayerTreePipeline>(/*depth=*/10);
    auto no_discard = [](LayerTree&) { return false; };
    RasterStatus status = rasterizer->Draw(pipeline, no_discard);
    EXPECT_EQ(status, RasterStatus::kFailed);
    latch.Signal();
  });
  latch.Wait();
}

TEST(RasterizerTest,
     drawWithGpuEnabledAndSurfaceAllowsDrawingWhenGpuDisabledDoesAcquireFrame) {
  std::string test_name =
      ::testing::UnitTest::GetInstance()->current_test_info()->name();
  ThreadHost thread_host("io.flutter.test." + test_name + ".",
                         ThreadHost::Type::Platform | ThreadHost::Type::RASTER |
                             ThreadHost::Type::IO | ThreadHost::Type::UI);
  TaskRunners task_runners("test", thread_host.platform_thread->GetTaskRunner(),
                           thread_host.raster_thread->GetTaskRunner(),
                           thread_host.ui_thread->GetTaskRunner(),
                           thread_host.io_thread->GetTaskRunner());
  NiceMock<MockDelegate> delegate;
  Settings settings;
  ON_CALL(delegate, GetSettings()).WillByDefault(ReturnRef(settings));
  EXPECT_CALL(delegate, GetTaskRunners())
      .WillRepeatedly(ReturnRef(task_runners));
  EXPECT_CALL(delegate, OnFrameRasterized(_));

  auto rasterizer = std::make_unique<Rasterizer>(delegate);
  auto surface = std::make_unique<NiceMock<MockSurface>>();
  auto is_gpu_disabled_sync_switch =
      std::make_shared<const fml::SyncSwitch>(false);

  SurfaceFrame::FramebufferInfo framebuffer_info;
  framebuffer_info.supports_readback = true;
  auto surface_frame = std::make_unique<SurfaceFrame>(
      /*surface=*/nullptr, /*framebuffer_info=*/framebuffer_info,
      /*submit_callback=*/[](const SurfaceFrame&, DlCanvas*) { return true; },
      /*frame_size=*/SkISize::Make(800, 600));
  EXPECT_CALL(*surface, AllowsDrawingWhenGpuDisabled()).WillOnce(Return(true));
  ON_CALL(delegate, GetIsGpuDisabledSyncSwitch())
      .WillByDefault(Return(is_gpu_disabled_sync_switch));
  EXPECT_CALL(delegate, GetIsGpuDisabledSyncSwitch()).Times(0);
  EXPECT_CALL(*surface, AcquireFrame(SkISize()))
      .WillOnce(Return(ByMove(std::move(surface_frame))));
  EXPECT_CALL(*surface, MakeRenderContextCurrent())
      .WillOnce(Return(ByMove(std::make_unique<GLContextDefaultResult>(true))));

  rasterizer->Setup(std::move(surface));
  fml::AutoResetWaitableEvent latch;
  thread_host.raster_thread->GetTaskRunner()->PostTask([&] {
    auto pipeline = std::make_shared<LayerTreePipeline>(/*depth=*/10);
    auto layer_tree = std::make_shared<LayerTree>(/*frame_size=*/SkISize(),
                                                  /*device_pixel_ratio=*/2.0f);
    auto layer_tree_item = std::make_unique<LayerTreeItem>(
        std::move(layer_tree), CreateFinishedBuildRecorder());
    PipelineProduceResult result =
        pipeline->Produce().Complete(std::move(layer_tree_item));
    EXPECT_TRUE(result.success);
    auto no_discard = [](LayerTree&) { return false; };
    rasterizer->Draw(pipeline, no_discard);
    latch.Signal();
  });
  latch.Wait();
}

TEST(
    RasterizerTest,
    drawWithGpuDisabledAndSurfaceAllowsDrawingWhenGpuDisabledDoesAcquireFrame) {
  std::string test_name =
      ::testing::UnitTest::GetInstance()->current_test_info()->name();
  ThreadHost thread_host("io.flutter.test." + test_name + ".",
                         ThreadHost::Type::Platform | ThreadHost::Type::RASTER |
                             ThreadHost::Type::IO | ThreadHost::Type::UI);
  TaskRunners task_runners("test", thread_host.platform_thread->GetTaskRunner(),
                           thread_host.raster_thread->GetTaskRunner(),
                           thread_host.ui_thread->GetTaskRunner(),
                           thread_host.io_thread->GetTaskRunner());
  NiceMock<MockDelegate> delegate;
  Settings settings;
  ON_CALL(delegate, GetSettings()).WillByDefault(ReturnRef(settings));
  EXPECT_CALL(delegate, GetTaskRunners())
      .WillRepeatedly(ReturnRef(task_runners));
  EXPECT_CALL(delegate, OnFrameRasterized(_));
  auto rasterizer = std::make_unique<Rasterizer>(delegate);
  auto surface = std::make_unique<NiceMock<MockSurface>>();
  auto is_gpu_disabled_sync_switch =
      std::make_shared<const fml::SyncSwitch>(true);

  SurfaceFrame::FramebufferInfo framebuffer_info;
  framebuffer_info.supports_readback = true;

  auto surface_frame = std::make_unique<SurfaceFrame>(
      /*surface=*/nullptr, /*framebuffer_info=*/framebuffer_info,
      /*submit_callback=*/[](const SurfaceFrame&, DlCanvas*) { return true; },
      /*frame_size=*/SkISize::Make(800, 600));
  EXPECT_CALL(*surface, AllowsDrawingWhenGpuDisabled()).WillOnce(Return(true));
  ON_CALL(delegate, GetIsGpuDisabledSyncSwitch())
      .WillByDefault(Return(is_gpu_disabled_sync_switch));
  EXPECT_CALL(delegate, GetIsGpuDisabledSyncSwitch()).Times(0);
  EXPECT_CALL(*surface, AcquireFrame(SkISize()))
      .WillOnce(Return(ByMove(std::move(surface_frame))));
  EXPECT_CALL(*surface, MakeRenderContextCurrent())
      .WillOnce(Return(ByMove(std::make_unique<GLContextDefaultResult>(true))));

  rasterizer->Setup(std::move(surface));
  fml::AutoResetWaitableEvent latch;
  thread_host.raster_thread->GetTaskRunner()->PostTask([&] {
    auto pipeline = std::make_shared<LayerTreePipeline>(/*depth=*/10);
    auto layer_tree = std::make_shared<LayerTree>(/*frame_size=*/SkISize(),
                                                  /*device_pixel_ratio=*/2.0f);
    auto layer_tree_item = std::make_unique<LayerTreeItem>(
        std::move(layer_tree), CreateFinishedBuildRecorder());
    PipelineProduceResult result =
        pipeline->Produce().Complete(std::move(layer_tree_item));
    EXPECT_TRUE(result.success);
    auto no_discard = [](LayerTree&) { return false; };
    RasterStatus status = rasterizer->Draw(pipeline, no_discard);
    EXPECT_EQ(status, RasterStatus::kSuccess);
    latch.Signal();
  });
  latch.Wait();
}

TEST(
    RasterizerTest,
    drawWithGpuEnabledAndSurfaceDisallowsDrawingWhenGpuDisabledDoesAcquireFrame) {
  std::string test_name =
      ::testing::UnitTest::GetInstance()->current_test_info()->name();
  ThreadHost thread_host("io.flutter.test." + test_name + ".",
                         ThreadHost::Type::Platform | ThreadHost::Type::RASTER |
                             ThreadHost::Type::IO | ThreadHost::Type::UI);
  TaskRunners task_runners("test", thread_host.platform_thread->GetTaskRunner(),
                           thread_host.raster_thread->GetTaskRunner(),
                           thread_host.ui_thread->GetTaskRunner(),
                           thread_host.io_thread->GetTaskRunner());
  NiceMock<MockDelegate> delegate;
  Settings settings;
  ON_CALL(delegate, GetSettings()).WillByDefault(ReturnRef(settings));
  EXPECT_CALL(delegate, GetTaskRunners())
      .WillRepeatedly(ReturnRef(task_runners));
  EXPECT_CALL(delegate, OnFrameRasterized(_));
  auto rasterizer = std::make_unique<Rasterizer>(delegate);
  auto surface = std::make_unique<NiceMock<MockSurface>>();
  auto is_gpu_disabled_sync_switch =
      std::make_shared<const fml::SyncSwitch>(false);

  SurfaceFrame::FramebufferInfo framebuffer_info;
  framebuffer_info.supports_readback = true;

  auto surface_frame = std::make_unique<SurfaceFrame>(
      /*surface=*/nullptr, /*framebuffer_info=*/framebuffer_info,
      /*submit_callback=*/[](const SurfaceFrame&, DlCanvas*) { return true; },
      /*frame_size=*/SkISize::Make(800, 600));
  EXPECT_CALL(*surface, AllowsDrawingWhenGpuDisabled()).WillOnce(Return(false));
  EXPECT_CALL(delegate, GetIsGpuDisabledSyncSwitch())
      .WillOnce(Return(is_gpu_disabled_sync_switch));
  EXPECT_CALL(*surface, AcquireFrame(SkISize()))
      .WillOnce(Return(ByMove(std::move(surface_frame))));
  EXPECT_CALL(*surface, MakeRenderContextCurrent())
      .WillOnce(Return(ByMove(std::make_unique<GLContextDefaultResult>(true))));

  rasterizer->Setup(std::move(surface));
  fml::AutoResetWaitableEvent latch;
  thread_host.raster_thread->GetTaskRunner()->PostTask([&] {
    auto pipeline = std::make_shared<LayerTreePipeline>(/*depth=*/10);
    auto layer_tree = std::make_shared<LayerTree>(/*frame_size=*/SkISize(),
                                                  /*device_pixel_ratio=*/2.0f);
    auto layer_tree_item = std::make_unique<LayerTreeItem>(
        std::move(layer_tree), CreateFinishedBuildRecorder());
    PipelineProduceResult result =
        pipeline->Produce().Complete(std::move(layer_tree_item));
    EXPECT_TRUE(result.success);
    auto no_discard = [](LayerTree&) { return false; };
    RasterStatus status = rasterizer->Draw(pipeline, no_discard);
    EXPECT_EQ(status, RasterStatus::kSuccess);
    latch.Signal();
  });
  latch.Wait();
}

TEST(
    RasterizerTest,
    drawWithGpuDisabledAndSurfaceDisallowsDrawingWhenGpuDisabledDoesntAcquireFrame) {
  std::string test_name =
      ::testing::UnitTest::GetInstance()->current_test_info()->name();
  ThreadHost thread_host("io.flutter.test." + test_name + ".",
                         ThreadHost::Type::Platform | ThreadHost::Type::RASTER |
                             ThreadHost::Type::IO | ThreadHost::Type::UI);
  TaskRunners task_runners("test", thread_host.platform_thread->GetTaskRunner(),
                           thread_host.raster_thread->GetTaskRunner(),
                           thread_host.ui_thread->GetTaskRunner(),
                           thread_host.io_thread->GetTaskRunner());
  NiceMock<MockDelegate> delegate;
  Settings settings;
  ON_CALL(delegate, GetSettings()).WillByDefault(ReturnRef(settings));
  EXPECT_CALL(delegate, GetTaskRunners())
      .WillRepeatedly(ReturnRef(task_runners));
  EXPECT_CALL(delegate, OnFrameRasterized(_)).Times(0);
  auto rasterizer = std::make_unique<Rasterizer>(delegate);
  auto surface = std::make_unique<NiceMock<MockSurface>>();
  auto is_gpu_disabled_sync_switch =
      std::make_shared<const fml::SyncSwitch>(true);

  SurfaceFrame::FramebufferInfo framebuffer_info;
  framebuffer_info.supports_readback = true;

  auto surface_frame = std::make_unique<SurfaceFrame>(
      /*surface=*/nullptr, /*framebuffer_info=*/framebuffer_info,
      /*submit_callback=*/[](const SurfaceFrame&, DlCanvas*) { return true; },
      /*frame_size=*/SkISize::Make(800, 600));
  EXPECT_CALL(*surface, AllowsDrawingWhenGpuDisabled()).WillOnce(Return(false));
  EXPECT_CALL(delegate, GetIsGpuDisabledSyncSwitch())
      .WillOnce(Return(is_gpu_disabled_sync_switch));
  EXPECT_CALL(*surface, AcquireFrame(SkISize())).Times(0);
  EXPECT_CALL(*surface, MakeRenderContextCurrent())
      .WillOnce(Return(ByMove(std::make_unique<GLContextDefaultResult>(true))));

  rasterizer->Setup(std::move(surface));
  fml::AutoResetWaitableEvent latch;
  thread_host.raster_thread->GetTaskRunner()->PostTask([&] {
    auto pipeline = std::make_shared<LayerTreePipeline>(/*depth=*/10);
    auto layer_tree = std::make_shared<LayerTree>(/*frame_size=*/SkISize(),
                                                  /*device_pixel_ratio=*/2.0f);
    auto layer_tree_item = std::make_unique<LayerTreeItem>(
        std::move(layer_tree), CreateFinishedBuildRecorder());
    PipelineProduceResult result =
        pipeline->Produce().Complete(std::move(layer_tree_item));
    EXPECT_TRUE(result.success);
    auto no_discard = [](LayerTree&) { return false; };
    RasterStatus status = rasterizer->Draw(pipeline, no_discard);
    EXPECT_EQ(status, RasterStatus::kDiscarded);
    latch.Signal();
  });
  latch.Wait();
}

TEST(
    RasterizerTest,
    FrameTimingRecorderShouldStartRecordingRasterTimeBeforeSurfaceAcquireFrame) {
  std::string test_name =
      ::testing::UnitTest::GetInstance()->current_test_info()->name();
  ThreadHost thread_host("io.flutter.test." + test_name + ".",
                         ThreadHost::Type::Platform | ThreadHost::Type::RASTER |
                             ThreadHost::Type::IO | ThreadHost::Type::UI);
  TaskRunners task_runners("test", thread_host.platform_thread->GetTaskRunner(),
                           thread_host.raster_thread->GetTaskRunner(),
                           thread_host.ui_thread->GetTaskRunner(),
                           thread_host.io_thread->GetTaskRunner());
  NiceMock<MockDelegate> delegate;
  Settings settings;
  ON_CALL(delegate, GetSettings()).WillByDefault(ReturnRef(settings));
  EXPECT_CALL(delegate, GetTaskRunners())
      .WillRepeatedly(ReturnRef(task_runners));
  EXPECT_CALL(delegate, OnFrameRasterized(_))
      .WillOnce([&](const FrameTiming& frame_timing) {
        fml::TimePoint now = fml::TimePoint::Now();
        fml::TimePoint raster_start =
            frame_timing.Get(FrameTiming::kRasterStart);
        EXPECT_TRUE(now - raster_start < fml::TimeDelta::FromSecondsF(1));
      });

  auto rasterizer = std::make_unique<Rasterizer>(delegate);
  auto surface = std::make_unique<NiceMock<MockSurface>>();
  auto is_gpu_disabled_sync_switch =
      std::make_shared<const fml::SyncSwitch>(false);
  ON_CALL(delegate, GetIsGpuDisabledSyncSwitch())
      .WillByDefault(Return(is_gpu_disabled_sync_switch));
  ON_CALL(*surface, AcquireFrame(SkISize()))
      .WillByDefault(::testing::Invoke([] { return nullptr; }));
  EXPECT_CALL(*surface, AcquireFrame(SkISize()));
  EXPECT_CALL(*surface, MakeRenderContextCurrent())
      .WillOnce(Return(ByMove(std::make_unique<GLContextDefaultResult>(true))));
  rasterizer->Setup(std::move(surface));
  fml::AutoResetWaitableEvent latch;
  thread_host.raster_thread->GetTaskRunner()->PostTask([&] {
    auto pipeline = std::make_shared<LayerTreePipeline>(/*depth=*/10);
    auto layer_tree = std::make_shared<LayerTree>(/*frame_size=*/SkISize(),
                                                  /*device_pixel_ratio=*/2.0f);
    auto layer_tree_item = std::make_unique<LayerTreeItem>(
        std::move(layer_tree), CreateFinishedBuildRecorder());
    PipelineProduceResult result =
        pipeline->Produce().Complete(std::move(layer_tree_item));
    EXPECT_TRUE(result.success);
    auto no_discard = [](LayerTree&) { return false; };
    RasterStatus status = rasterizer->Draw(pipeline, no_discard);
    EXPECT_EQ(status, RasterStatus::kFailed);
    latch.Signal();
  });
  latch.Wait();
}

TEST(RasterizerTest,
     drawLayerTreeWithCorrectFrameTimingWhenPipelineIsMoreAvailable) {
  std::string test_name =
      ::testing::UnitTest::GetInstance()->current_test_info()->name();
  ThreadHost thread_host("io.flutter.test." + test_name + ".",
                         ThreadHost::Type::Platform | ThreadHost::Type::RASTER |
                             ThreadHost::Type::IO | ThreadHost::Type::UI);
  TaskRunners task_runners("test", thread_host.platform_thread->GetTaskRunner(),
                           thread_host.raster_thread->GetTaskRunner(),
                           thread_host.ui_thread->GetTaskRunner(),
                           thread_host.io_thread->GetTaskRunner());
  NiceMock<MockDelegate> delegate;
  Settings settings;
  ON_CALL(delegate, GetSettings()).WillByDefault(ReturnRef(settings));
  ON_CALL(delegate, GetTaskRunners()).WillByDefault(ReturnRef(task_runners));

  fml::AutoResetWaitableEvent latch;
  std::unique_ptr<Rasterizer> rasterizer;
  thread_host.raster_thread->GetTaskRunner()->PostTask([&] {
    rasterizer = std::make_unique<Rasterizer>(delegate);
    latch.Signal();
  });
  latch.Wait();

  auto surface = std::make_unique<NiceMock<MockSurface>>();
  EXPECT_CALL(*surface, AllowsDrawingWhenGpuDisabled())
      .WillRepeatedly(Return(true));
  ON_CALL(*surface, AcquireFrame(SkISize()))
      .WillByDefault(::testing::Invoke([] {
        SurfaceFrame::FramebufferInfo framebuffer_info;
        framebuffer_info.supports_readback = true;
        return std::make_unique<SurfaceFrame>(
            /*surface=*/nullptr, framebuffer_info,
            /*submit_callback=*/
            [](const SurfaceFrame& frame, DlCanvas*) { return true; },
            /*frame_size=*/SkISize::Make(800, 600));
      }));
  ON_CALL(*surface, MakeRenderContextCurrent())
      .WillByDefault(::testing::Invoke(
          [] { return std::make_unique<GLContextDefaultResult>(true); }));

  fml::CountDownLatch count_down_latch(2);
  auto first_timestamp = fml::TimePoint::Now();
  auto second_timestamp = first_timestamp + fml::TimeDelta::FromMilliseconds(8);
  std::vector<fml::TimePoint> timestamps = {first_timestamp, second_timestamp};
  int frame_rasterized_count = 0;
  EXPECT_CALL(delegate, OnFrameRasterized(_))
      .Times(2)
      .WillRepeatedly([&](const FrameTiming& frame_timing) {
        EXPECT_EQ(timestamps[frame_rasterized_count],
                  frame_timing.Get(FrameTiming::kVsyncStart));
        EXPECT_EQ(timestamps[frame_rasterized_count],
                  frame_timing.Get(FrameTiming::kBuildStart));
        EXPECT_EQ(timestamps[frame_rasterized_count],
                  frame_timing.Get(FrameTiming::kBuildFinish));
        frame_rasterized_count++;
        count_down_latch.CountDown();
      });

  thread_host.raster_thread->GetTaskRunner()->PostTask([&] {
    rasterizer->Setup(std::move(surface));
    auto pipeline = std::make_shared<LayerTreePipeline>(/*depth=*/10);
    for (int i = 0; i < 2; i++) {
      auto layer_tree =
          std::make_shared<LayerTree>(/*frame_size=*/SkISize(),
                                      /*device_pixel_ratio=*/2.0f);
      auto layer_tree_item = std::make_unique<LayerTreeItem>(
          std::move(layer_tree), CreateFinishedBuildRecorder(timestamps[i]));
      PipelineProduceResult result =
          pipeline->Produce().Complete(std::move(layer_tree_item));
      EXPECT_TRUE(result.success);
      EXPECT_EQ(result.is_first_item, i == 0);
    }
    auto no_discard = [](LayerTree&) { return false; };
    // Although we only call 'Rasterizer::Draw' once, it will be called twice
    // finally because there are two items in the pipeline.
    rasterizer->Draw(pipeline, no_discard);
  });
  count_down_latch.Wait();
  thread_host.raster_thread->GetTaskRunner()->PostTask([&] {
    rasterizer.reset();
    latch.Signal();
  });
  latch.Wait();
}

TEST(RasterizerTest, TeardownFreesResourceCache) {
  std::string test_name =
      ::testing::UnitTest::GetInstance()->current_test_info()->name();
  ThreadHost thread_host("io.flutter.test." + test_name + ".",
                         ThreadHost::Type::Platform | ThreadHost::Type::RASTER |
                             ThreadHost::Type::IO | ThreadHost::Type::UI);
  TaskRunners task_runners("test", thread_host.platform_thread->GetTaskRunner(),
                           thread_host.raster_thread->GetTaskRunner(),
                           thread_host.ui_thread->GetTaskRunner(),
                           thread_host.io_thread->GetTaskRunner());

  NiceMock<MockDelegate> delegate;
  Settings settings;
  ON_CALL(delegate, GetSettings()).WillByDefault(ReturnRef(settings));
  EXPECT_CALL(delegate, GetTaskRunners())
      .WillRepeatedly(ReturnRef(task_runners));

  auto rasterizer = std::make_unique<Rasterizer>(delegate);
  auto surface = std::make_unique<NiceMock<MockSurface>>();
  auto context = GrDirectContext::MakeMock(nullptr);
  context->setResourceCacheLimit(0);

  EXPECT_CALL(*surface, MakeRenderContextCurrent())
      .WillRepeatedly([]() -> std::unique_ptr<GLContextResult> {
        return std::make_unique<GLContextDefaultResult>(true);
      });
  EXPECT_CALL(*surface, GetContext()).WillRepeatedly(Return(context.get()));

  rasterizer->Setup(std::move(surface));
  EXPECT_EQ(context->getResourceCacheLimit(), 0ul);

  rasterizer->SetResourceCacheMaxBytes(10000000, false);
  EXPECT_EQ(context->getResourceCacheLimit(), 10000000ul);
  EXPECT_EQ(context->getResourceCachePurgeableBytes(), 0ul);

  int count = 0;
  size_t bytes = 0;
  context->getResourceCacheUsage(&count, &bytes);
  EXPECT_EQ(bytes, 0ul);

  auto image_info =
      SkImageInfo::MakeN32Premul(500, 500, SkColorSpace::MakeSRGB());
  auto sk_surface = SkSurface::MakeRenderTarget(
      context.get(), skgpu::Budgeted::kYes, image_info);
  EXPECT_TRUE(sk_surface);

  SkPaint paint;
  sk_surface->getCanvas()->drawPaint(paint);
  sk_surface->getCanvas()->flush();
  context->flushAndSubmit(true);

  EXPECT_EQ(context->getResourceCachePurgeableBytes(), 0ul);

  sk_surface.reset();

  context->getResourceCacheUsage(&count, &bytes);
  EXPECT_GT(bytes, 0ul);
  EXPECT_GT(context->getResourceCachePurgeableBytes(), 0ul);

  rasterizer->Teardown();
  EXPECT_EQ(context->getResourceCachePurgeableBytes(), 0ul);
}

TEST(RasterizerTest, TeardownNoSurface) {
  std::string test_name =
      ::testing::UnitTest::GetInstance()->current_test_info()->name();
  ThreadHost thread_host("io.flutter.test." + test_name + ".",
                         ThreadHost::Type::Platform | ThreadHost::Type::RASTER |
                             ThreadHost::Type::IO | ThreadHost::Type::UI);
  TaskRunners task_runners("test", thread_host.platform_thread->GetTaskRunner(),
                           thread_host.raster_thread->GetTaskRunner(),
                           thread_host.ui_thread->GetTaskRunner(),
                           thread_host.io_thread->GetTaskRunner());

  NiceMock<MockDelegate> delegate;
  Settings settings;
  ON_CALL(delegate, GetSettings()).WillByDefault(ReturnRef(settings));
  EXPECT_CALL(delegate, GetTaskRunners())
      .WillRepeatedly(ReturnRef(task_runners));

  auto rasterizer = std::make_unique<Rasterizer>(delegate);

  EXPECT_TRUE(rasterizer);
  rasterizer->Teardown();
}

TEST(RasterizerTest, presentationTimeSetWhenVsyncTargetInFuture) {
  GTEST_SKIP() << "eglPresentationTime is disabled due to "
                  "https://github.com/flutter/flutter/issues/112503";
  std::string test_name =
      ::testing::UnitTest::GetInstance()->current_test_info()->name();
  ThreadHost thread_host("io.flutter.test." + test_name + ".",
                         ThreadHost::Type::Platform | ThreadHost::Type::RASTER |
                             ThreadHost::Type::IO | ThreadHost::Type::UI);
  TaskRunners task_runners("test", thread_host.platform_thread->GetTaskRunner(),
                           thread_host.raster_thread->GetTaskRunner(),
                           thread_host.ui_thread->GetTaskRunner(),
                           thread_host.io_thread->GetTaskRunner());

  NiceMock<MockDelegate> delegate;
  Settings settings;
  ON_CALL(delegate, GetSettings()).WillByDefault(ReturnRef(settings));
  ON_CALL(delegate, GetTaskRunners()).WillByDefault(ReturnRef(task_runners));

  fml::AutoResetWaitableEvent latch;
  std::unique_ptr<Rasterizer> rasterizer;
  thread_host.raster_thread->GetTaskRunner()->PostTask([&] {
    rasterizer = std::make_unique<Rasterizer>(delegate);
    latch.Signal();
  });
  latch.Wait();

  const auto millis_16 = fml::TimeDelta::FromMilliseconds(16);
  const auto first_timestamp = fml::TimePoint::Now() + millis_16;
  auto second_timestamp = first_timestamp + millis_16;
  std::vector<fml::TimePoint> timestamps = {first_timestamp, second_timestamp};

  int frames_submitted = 0;
  fml::CountDownLatch submit_latch(2);
  auto surface = std::make_unique<MockSurface>();
  ON_CALL(*surface, AllowsDrawingWhenGpuDisabled()).WillByDefault(Return(true));
  ON_CALL(*surface, AcquireFrame(SkISize()))
      .WillByDefault(::testing::Invoke([&] {
        SurfaceFrame::FramebufferInfo framebuffer_info;
        framebuffer_info.supports_readback = true;
        return std::make_unique<SurfaceFrame>(
            /*surface=*/nullptr, framebuffer_info,
            /*submit_callback=*/
            [&](const SurfaceFrame& frame, DlCanvas*) {
              const auto pres_time = *frame.submit_info().presentation_time;
              const auto diff = pres_time - first_timestamp;
              int num_frames_submitted = frames_submitted++;
              EXPECT_EQ(diff.ToMilliseconds(),
                        num_frames_submitted * millis_16.ToMilliseconds());
              submit_latch.CountDown();
              return true;
            },
            /*frame_size=*/SkISize::Make(800, 600));
      }));

  ON_CALL(*surface, MakeRenderContextCurrent())
      .WillByDefault(::testing::Invoke(
          [] { return std::make_unique<GLContextDefaultResult>(true); }));

  thread_host.raster_thread->GetTaskRunner()->PostTask([&] {
    rasterizer->Setup(std::move(surface));
    auto pipeline = std::make_shared<LayerTreePipeline>(/*depth=*/10);
    for (int i = 0; i < 2; i++) {
      auto layer_tree =
          std::make_shared<LayerTree>(/*frame_size=*/SkISize(),
                                      /*device_pixel_ratio=*/2.0f);
      auto layer_tree_item = std::make_unique<LayerTreeItem>(
          std::move(layer_tree), CreateFinishedBuildRecorder(timestamps[i]));
      PipelineProduceResult result =
          pipeline->Produce().Complete(std::move(layer_tree_item));
      EXPECT_TRUE(result.success);
      EXPECT_EQ(result.is_first_item, i == 0);
    }
    auto no_discard = [](LayerTree&) { return false; };
    // Although we only call 'Rasterizer::Draw' once, it will be called twice
    // finally because there are two items in the pipeline.
    rasterizer->Draw(pipeline, no_discard);
  });

  submit_latch.Wait();
  thread_host.raster_thread->GetTaskRunner()->PostTask([&] {
    rasterizer.reset();
    latch.Signal();
  });
  latch.Wait();
}

TEST(RasterizerTest, presentationTimeNotSetWhenVsyncTargetInPast) {
  GTEST_SKIP() << "eglPresentationTime is disabled due to "
                  "https://github.com/flutter/flutter/issues/112503";
  std::string test_name =
      ::testing::UnitTest::GetInstance()->current_test_info()->name();
  ThreadHost thread_host("io.flutter.test." + test_name + ".",
                         ThreadHost::Type::Platform | ThreadHost::Type::RASTER |
                             ThreadHost::Type::IO | ThreadHost::Type::UI);
  TaskRunners task_runners("test", thread_host.platform_thread->GetTaskRunner(),
                           thread_host.raster_thread->GetTaskRunner(),
                           thread_host.ui_thread->GetTaskRunner(),
                           thread_host.io_thread->GetTaskRunner());

  NiceMock<MockDelegate> delegate;
  Settings settings;
  ON_CALL(delegate, GetSettings()).WillByDefault(ReturnRef(settings));
  ON_CALL(delegate, GetTaskRunners()).WillByDefault(ReturnRef(task_runners));

  fml::AutoResetWaitableEvent latch;
  std::unique_ptr<Rasterizer> rasterizer;
  thread_host.raster_thread->GetTaskRunner()->PostTask([&] {
    rasterizer = std::make_unique<Rasterizer>(delegate);
    latch.Signal();
  });
  latch.Wait();

  const auto millis_16 = fml::TimeDelta::FromMilliseconds(16);
  const auto first_timestamp = fml::TimePoint::Now() - millis_16;

  fml::CountDownLatch submit_latch(1);
  auto surface = std::make_unique<MockSurface>();
  ON_CALL(*surface, AllowsDrawingWhenGpuDisabled()).WillByDefault(Return(true));
  ON_CALL(*surface, AcquireFrame(SkISize()))
      .WillByDefault(::testing::Invoke([&] {
        SurfaceFrame::FramebufferInfo framebuffer_info;
        framebuffer_info.supports_readback = true;
        return std::make_unique<SurfaceFrame>(
            /*surface=*/nullptr, framebuffer_info,
            /*submit_callback=*/
            [&](const SurfaceFrame& frame, DlCanvas*) {
              const std::optional<fml::TimePoint> pres_time =
                  frame.submit_info().presentation_time;
              EXPECT_EQ(pres_time, std::nullopt);
              submit_latch.CountDown();
              return true;
            },
            /*frame_size=*/SkISize::Make(800, 600));
      }));

  ON_CALL(*surface, MakeRenderContextCurrent())
      .WillByDefault(::testing::Invoke(
          [] { return std::make_unique<GLContextDefaultResult>(true); }));

  thread_host.raster_thread->GetTaskRunner()->PostTask([&] {
    rasterizer->Setup(std::move(surface));
    auto pipeline = std::make_shared<LayerTreePipeline>(/*depth=*/10);
    auto layer_tree = std::make_shared<LayerTree>(/*frame_size=*/SkISize(),
                                                  /*device_pixel_ratio=*/2.0f);
    auto layer_tree_item = std::make_unique<LayerTreeItem>(
        std::move(layer_tree), CreateFinishedBuildRecorder(first_timestamp));
    PipelineProduceResult result =
        pipeline->Produce().Complete(std::move(layer_tree_item));
    EXPECT_TRUE(result.success);
    EXPECT_EQ(result.is_first_item, true);
    auto no_discard = [](LayerTree&) { return false; };
    rasterizer->Draw(pipeline, no_discard);
  });

  submit_latch.Wait();
  thread_host.raster_thread->GetTaskRunner()->PostTask([&] {
    rasterizer.reset();
    latch.Signal();
  });
  latch.Wait();
}

}  // namespace flutter
