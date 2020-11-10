// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <memory>

#include "flutter/assets/directory_asset_bundle.h"
#include "flutter/common/graphics/persistent_cache.h"
#include "flutter/flow/layers/container_layer.h"
#include "flutter/flow/layers/layer.h"
#include "flutter/flow/layers/physical_shape_layer.h"
#include "flutter/flow/layers/picture_layer.h"
#include "flutter/fml/command_line.h"
#include "flutter/fml/file.h"
#include "flutter/fml/log_settings.h"
#include "flutter/fml/unique_fd.h"
#include "flutter/shell/common/serialization_callbacks.h"
#include "flutter/shell/common/shell_test.h"
#include "flutter/shell/common/switches.h"
#include "flutter/shell/version/version.h"
#include "flutter/testing/testing.h"
#include "include/core/SkFont.h"
#include "include/core/SkPicture.h"
#include "include/core/SkPictureRecorder.h"
#include "include/core/SkSerialProcs.h"
#include "include/core/SkTextBlob.h"

#if defined(OS_FUCHSIA)
#include "lib/sys/cpp/component_context.h"
#include "third_party/skia/include/ports/SkFontMgr_fuchsia.h"

namespace flutter {
namespace testing {

static void WaitForIO(Shell* shell) {
  std::promise<bool> io_task_finished;
  shell->GetTaskRunners().GetIOTaskRunner()->PostTask(
      [&io_task_finished]() { io_task_finished.set_value(true); });
  io_task_finished.get_future().wait();
}

class SkpWarmupTest : public ShellTest {
 public:
  SkpWarmupTest() {}

  void TestWarmup(const SkISize& draw_size, const LayerTreeBuilder& builder) {
    // Create a temp dir to store the persistent cache
    fml::ScopedTemporaryDirectory dir;
    PersistentCache::SetCacheDirectoryPath(dir.path());
    PersistentCache::ResetCacheForProcess();

    auto settings = CreateSettingsForFixture();
    settings.cache_sksl = true;
    settings.dump_skp_on_shader_compilation = true;

    fml::AutoResetWaitableEvent firstFrameLatch;
    settings.frame_rasterized_callback =
        [&firstFrameLatch](const FrameTiming& t) { firstFrameLatch.Signal(); };

    auto config = RunConfiguration::InferFromSettings(settings);
    config.SetEntrypoint("emptyMain");
    std::unique_ptr<Shell> shell = CreateShell(settings);
    PlatformViewNotifyCreated(shell.get());
    RunEngine(shell.get(), std::move(config));

    // Initially, we should have no SkSL cache
    auto cache = PersistentCache::GetCacheForProcess()->LoadSkSLs();
    ASSERT_EQ(cache.size(), 0u);

    PumpOneFrame(shell.get(), draw_size.width(), draw_size.height(), builder);
    firstFrameLatch.Wait();
    WaitForIO(shell.get());

    // Count the number of shaders this builder generated. We use this as a
    // proxy for whether new shaders were generated, since skia will dump an skp
    // any time a new shader is compiled.
    int skp_count = 0;
    fml::FileVisitor skp_count_visitor = [&skp_count](
                                             const fml::UniqueFD& directory,
                                             const std::string& filename) {
      if (filename.size() >= 4 &&
          filename.substr(filename.size() - 4, 4) == ".skp") {
        skp_count += 1;
      }
      return true;
    };
    fml::VisitFilesRecursively(dir.fd(), skp_count_visitor);
    int first_skp_count = skp_count;
    skp_count = 0;
    ASSERT_GT(first_skp_count, 0);

    // Deserialize all skps into memory
    std::vector<sk_sp<SkPicture>> pictures;
    fml::FileVisitor skp_deserialize_visitor =
        [&pictures](const fml::UniqueFD& directory,
                    const std::string& filename) {
          if (filename.size() >= 4 &&
              filename.substr(filename.size() - 4, 4) == ".skp") {
            auto fd = fml::OpenFileReadOnly(directory, filename.c_str());
            if (fd.get() < 0) {
              FML_LOG(ERROR) << "Failed to open " << filename;
              return true;
            }
            // Deserialize
            sk_sp<SkData> data = SkData::MakeFromFD(fd.get());
            std::unique_ptr<SkMemoryStream> stream = SkMemoryStream::Make(data);

            SkDeserialProcs procs = {0};
            procs.fImageProc = DeserializeImageWithoutData;
            procs.fTypefaceProc = DeserializeTypefaceWithoutData;
            sk_sp<SkPicture> picture =
                SkPicture::MakeFromStream(stream.get(), &procs);
            if (!picture) {
              FML_LOG(ERROR) << "Failed to deserialize " << filename;
              return true;
            }
            pictures.push_back(std::move(picture));
            fd.reset();
          }
          return true;
        };
    fml::VisitFilesRecursively(dir.fd(), skp_deserialize_visitor);
    ASSERT_GT(pictures.size(), 0ul);

    // Reinitialize shell with clean cache and verify that drawing again dumps
    // the same number of shaders
    fml::RemoveFilesInDirectory(dir.fd());
    PersistentCache::ResetCacheForProcess();
    DestroyShell(std::move(shell));
    auto config2 = RunConfiguration::InferFromSettings(settings);
    config2.SetEntrypoint("emptyMain");
    shell = CreateShell(settings);
    PlatformViewNotifyCreated(shell.get());
    RunEngine(shell.get(), std::move(config2));
    firstFrameLatch.Reset();
    PumpOneFrame(shell.get(), draw_size.width(), draw_size.height(), builder);
    firstFrameLatch.Wait();
    WaitForIO(shell.get());

    // Verify same number of shaders dumped
    fml::VisitFilesRecursively(dir.fd(), skp_count_visitor);
    int second_skp_count = skp_count;
    skp_count = 0;
    ASSERT_EQ(second_skp_count, first_skp_count);

    // Reinitialize shell and draw deserialized skps to warm up shaders
    fml::RemoveFilesInDirectory(dir.fd());
    PersistentCache::ResetCacheForProcess();
    DestroyShell(std::move(shell));
    auto config3 = RunConfiguration::InferFromSettings(settings);
    config3.SetEntrypoint("emptyMain");
    shell = CreateShell(settings);
    PlatformViewNotifyCreated(shell.get());
    RunEngine(shell.get(), std::move(config3));
    firstFrameLatch.Reset();

    for (auto& picture : pictures) {
      fml::RefPtr<SkiaUnrefQueue> queue = fml::MakeRefCounted<SkiaUnrefQueue>(
          this->GetCurrentTaskRunner(), fml::TimeDelta::FromSeconds(0));
      LayerTreeBuilder picture_builder =
          [picture, queue](std::shared_ptr<ContainerLayer> root) {
            auto picture_layer = std::make_shared<PictureLayer>(
                SkPoint::Make(0, 0), SkiaGPUObject<SkPicture>(picture, queue),
                /* is_complex */ false,
                /* will_change */ false);
            root->Add(picture_layer);
          };
      PumpOneFrame(shell.get(), picture->cullRect().width(),
                   picture->cullRect().height(), picture_builder);
    }
    firstFrameLatch.Wait();
    WaitForIO(shell.get());

    // Verify same number of shaders dumped
    fml::VisitFilesRecursively(dir.fd(), skp_count_visitor);
    int third_skp_count = skp_count;
    skp_count = 0;
    ASSERT_EQ(third_skp_count, first_skp_count);

    // Remove files generated
    fml::RemoveFilesInDirectory(dir.fd());

    // Draw orignal material again
    firstFrameLatch.Reset();
    PumpOneFrame(shell.get(), draw_size.width(), draw_size.height(), builder);

    firstFrameLatch.Wait();
    WaitForIO(shell.get());

    // Verify no new shaders dumped
    fml::VisitFilesRecursively(dir.fd(), skp_count_visitor);
    int fourth_skp_count = skp_count;
    skp_count = 0;
    ASSERT_EQ(fourth_skp_count, 0);

    // Clean Up
    fml::RemoveFilesInDirectory(dir.fd());
  }
};

TEST_F(SkpWarmupTest, Basic) {
  SkISize draw_size = SkISize::Make(100, 100);
  // Draw something to trigger shader compilations.
  LayerTreeBuilder builder =
      [&draw_size](std::shared_ptr<ContainerLayer> root) {
        SkPath path;
        path.addCircle(draw_size.width() / 2, draw_size.height() / 2, 20);
        auto physical_shape_layer = std::make_shared<PhysicalShapeLayer>(
            SK_ColorRED, SK_ColorBLUE, 1.0f, path, Clip::antiAlias);
        root->Add(physical_shape_layer);
      };
  TestWarmup(draw_size, builder);
}

TEST_F(SkpWarmupTest, Image) {
  SkISize draw_size = SkISize::Make(100, 100);
  // We reuse this builder to draw the same content sever times in this test
  LayerTreeBuilder builder = [&draw_size,
                              this](std::shared_ptr<ContainerLayer> root) {
    SkPictureRecorder recorder;
    auto canvas =
        recorder.beginRecording(draw_size.width(), draw_size.height());

    // include an image so we can test that the warmup works even with image
    // data excluded from the skp
    auto image_size =
        SkISize::Make(draw_size.width() / 2, draw_size.height() / 2);
    auto color_space = SkColorSpace::MakeSRGB();
    auto info =
        SkImageInfo::Make(image_size, SkColorType::kRGBA_8888_SkColorType,
                          SkAlphaType::kPremul_SkAlphaType, color_space);
    sk_sp<SkData> image_data =
        SkData::MakeUninitialized(image_size.width() * image_size.height() * 4);
    memset(image_data->writable_data(), 0x0f, image_data->size());
    sk_sp<SkImage> image =
        SkImage::MakeRasterData(info, image_data, image_size.width() * 4);

    canvas->drawImage(image, image_size.width(), image_size.height());

    auto picture = recorder.finishRecordingAsPicture();

    fml::RefPtr<SkiaUnrefQueue> queue = fml::MakeRefCounted<SkiaUnrefQueue>(
        this->GetCurrentTaskRunner(), fml::TimeDelta::FromSeconds(0));
    auto picture_layer = std::make_shared<PictureLayer>(
        SkPoint::Make(0, 0), SkiaGPUObject<SkPicture>(picture, queue),
        /* is_complex */ false,
        /* will_change */ false);
    root->Add(picture_layer);
  };

  TestWarmup(draw_size, builder);
}

// Re-enable once https://bugs.chromium.org/p/skia/issues/detail?id=10404
// is fixed and integrated, or a workaround is found.
TEST_F(SkpWarmupTest, DISABLED_Text) {
  auto context = sys::ComponentContext::Create();
  fuchsia::fonts::ProviderSyncPtr sync_font_provider;
  context->svc()->Connect(sync_font_provider.NewRequest());
  auto font_mgr = SkFontMgr_New_Fuchsia(std::move(sync_font_provider));
  auto raw_typeface =
      font_mgr->matchFamilyStyle(nullptr, SkFontStyle::Normal());
  auto typeface = sk_sp<SkTypeface>(raw_typeface);

  SkFont font(typeface, 12);
  auto text_blob =
      SkTextBlob::MakeFromString("test", font, SkTextEncoding::kUTF8);

  SkISize draw_size =
      SkISize::Make(text_blob->bounds().width(), text_blob->bounds().height());
  // We reuse this builder to draw the same content sever times in this test
  LayerTreeBuilder builder = [&draw_size, &text_blob,
                              this](std::shared_ptr<ContainerLayer> root) {
    SkPictureRecorder recorder;

    auto canvas =
        recorder.beginRecording(draw_size.width(), draw_size.height());

    auto color_space = SkColorSpace::MakeSRGB();
    auto paint = SkPaint(SkColors::kWhite, color_space.get());
    canvas->drawTextBlob(text_blob, draw_size.width() / 2,
                         draw_size.height() / 2, paint);

    auto picture = recorder.finishRecordingAsPicture();

    fml::RefPtr<SkiaUnrefQueue> queue = fml::MakeRefCounted<SkiaUnrefQueue>(
        this->GetCurrentTaskRunner(), fml::TimeDelta::FromSeconds(0));
    auto picture_layer = std::make_shared<PictureLayer>(
        SkPoint::Make(0, 0), SkiaGPUObject<SkPicture>(picture, queue),
        /* is_complex */ false,
        /* will_change */ false);
    root->Add(picture_layer);
  };

  TestWarmup(draw_size, builder);
}

}  // namespace testing
}  // namespace flutter

#endif  // defined(OS_FUCHSIA)
