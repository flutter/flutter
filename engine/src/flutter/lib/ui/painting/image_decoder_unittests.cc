// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/common/task_runners.h"
#include "flutter/fml/mapping.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/lib/ui/painting/image_decoder.h"
#include "flutter/lib/ui/painting/multi_frame_codec.h"
#include "flutter/runtime/dart_vm.h"
#include "flutter/runtime/dart_vm_lifecycle.h"
#include "flutter/testing/dart_isolate_runner.h"
#include "flutter/testing/elf_loader.h"
#include "flutter/testing/fixture_test.h"
#include "flutter/testing/test_dart_native_resolver.h"
#include "flutter/testing/test_gl_surface.h"
#include "flutter/testing/testing.h"
#include "third_party/skia/include/codec/SkCodec.h"

namespace flutter {
namespace testing {

class TestIOManager final : public IOManager {
 public:
  explicit TestIOManager(fml::RefPtr<fml::TaskRunner> task_runner,
                         bool has_gpu_context = true)
      : gl_surface_(SkISize::Make(1, 1)),
        gl_context_(has_gpu_context ? gl_surface_.CreateGrContext() : nullptr),
        weak_gl_context_factory_(
            has_gpu_context
                ? std::make_unique<fml::WeakPtrFactory<GrDirectContext>>(
                      gl_context_.get())
                : nullptr),
        unref_queue_(fml::MakeRefCounted<SkiaUnrefQueue>(
            task_runner,
            fml::TimeDelta::FromNanoseconds(0))),
        runner_(task_runner),
        weak_factory_(this),
        is_gpu_disabled_sync_switch_(std::make_shared<fml::SyncSwitch>()) {
    FML_CHECK(task_runner->RunsTasksOnCurrentThread())
        << "The IO manager must be initialized its primary task runner. The "
           "test harness may not be setup correctly/safely.";
    weak_prototype_ = weak_factory_.GetWeakPtr();
  }

  ~TestIOManager() override {
    fml::AutoResetWaitableEvent latch;
    fml::TaskRunner::RunNowOrPostTask(runner_,
                                      [&latch, queue = unref_queue_]() {
                                        queue->Drain();
                                        latch.Signal();
                                      });
    latch.Wait();
  }

  // |IOManager|
  fml::WeakPtr<IOManager> GetWeakIOManager() const override {
    return weak_prototype_;
  }

  // |IOManager|
  fml::WeakPtr<GrDirectContext> GetResourceContext() const override {
    return weak_gl_context_factory_ ? weak_gl_context_factory_->GetWeakPtr()
                                    : fml::WeakPtr<GrDirectContext>{};
  }

  // |IOManager|
  fml::RefPtr<flutter::SkiaUnrefQueue> GetSkiaUnrefQueue() const override {
    return unref_queue_;
  }

  // |IOManager|
  std::shared_ptr<fml::SyncSwitch> GetIsGpuDisabledSyncSwitch() override {
    did_access_is_gpu_disabled_sync_switch_ = true;
    return is_gpu_disabled_sync_switch_;
  }

  bool did_access_is_gpu_disabled_sync_switch_ = false;

 private:
  TestGLSurface gl_surface_;
  sk_sp<GrDirectContext> gl_context_;
  std::unique_ptr<fml::WeakPtrFactory<GrDirectContext>>
      weak_gl_context_factory_;
  fml::RefPtr<SkiaUnrefQueue> unref_queue_;
  fml::WeakPtr<TestIOManager> weak_prototype_;
  fml::RefPtr<fml::TaskRunner> runner_;
  fml::WeakPtrFactory<TestIOManager> weak_factory_;
  std::shared_ptr<fml::SyncSwitch> is_gpu_disabled_sync_switch_;

  FML_DISALLOW_COPY_AND_ASSIGN(TestIOManager);
};

static sk_sp<SkData> OpenFixtureAsSkData(const char* name) {
  auto fixtures_directory =
      fml::OpenDirectory(GetFixturesPath(), false, fml::FilePermission::kRead);
  if (!fixtures_directory.is_valid()) {
    return nullptr;
  }

  auto fixture_mapping =
      fml::FileMapping::CreateReadOnly(fixtures_directory, name);

  if (!fixture_mapping) {
    return nullptr;
  }

  SkData::ReleaseProc on_release = [](const void* ptr, void* context) -> void {
    delete reinterpret_cast<fml::FileMapping*>(context);
  };

  auto data = SkData::MakeWithProc(fixture_mapping->GetMapping(),
                                   fixture_mapping->GetSize(), on_release,
                                   fixture_mapping.get());

  if (!data) {
    return nullptr;
  }
  // The data is now owned by Skia.
  fixture_mapping.release();
  return data;
}

class ImageDecoderFixtureTest : public FixtureTest {};

TEST_F(ImageDecoderFixtureTest, CanCreateImageDecoder) {
  auto loop = fml::ConcurrentMessageLoop::Create();
  auto thread_task_runner = CreateNewThread();
  TaskRunners runners(GetCurrentTestName(),  // label
                      thread_task_runner,    // platform
                      thread_task_runner,    // raster
                      thread_task_runner,    // ui
                      thread_task_runner     // io

  );

  fml::AutoResetWaitableEvent latch;
  runners.GetIOTaskRunner()->PostTask([&]() {
    TestIOManager manager(runners.GetIOTaskRunner());
    ImageDecoder decoder(std::move(runners), loop->GetTaskRunner(),
                         manager.GetWeakIOManager());
    latch.Signal();
  });
  latch.Wait();
}

TEST_F(ImageDecoderFixtureTest, InvalidImageResultsError) {
  auto loop = fml::ConcurrentMessageLoop::Create();
  auto thread_task_runner = CreateNewThread();
  TaskRunners runners(GetCurrentTestName(),  // label
                      thread_task_runner,    // platform
                      thread_task_runner,    // raster
                      thread_task_runner,    // ui
                      thread_task_runner     // io
  );

  fml::AutoResetWaitableEvent latch;
  thread_task_runner->PostTask([&]() {
    TestIOManager manager(runners.GetIOTaskRunner());
    ImageDecoder decoder(runners, loop->GetTaskRunner(),
                         manager.GetWeakIOManager());

    auto data = OpenFixtureAsSkData("ThisDoesNotExist.jpg");
    ASSERT_FALSE(data);

    fml::RefPtr<ImageDescriptor> image_descriptor =
        fml::MakeRefCounted<ImageDescriptor>(std::move(data),
                                             std::unique_ptr<SkCodec>(nullptr));

    ImageDecoder::ImageResult callback = [&](SkiaGPUObject<SkImage> image) {
      ASSERT_TRUE(runners.GetUITaskRunner()->RunsTasksOnCurrentThread());
      ASSERT_FALSE(image.get());
      latch.Signal();
    };
    decoder.Decode(image_descriptor, 0, 0, callback);
  });
  latch.Wait();
}

TEST_F(ImageDecoderFixtureTest, ValidImageResultsInSuccess) {
  auto loop = fml::ConcurrentMessageLoop::Create();
  TaskRunners runners(GetCurrentTestName(),         // label
                      CreateNewThread("platform"),  // platform
                      CreateNewThread("raster"),    // raster
                      CreateNewThread("ui"),        // ui
                      CreateNewThread("io")         // io
  );

  fml::AutoResetWaitableEvent latch;

  std::unique_ptr<TestIOManager> io_manager;

  auto release_io_manager = [&]() {
    io_manager.reset();
    latch.Signal();
  };
  auto decode_image = [&]() {
    std::unique_ptr<ImageDecoder> image_decoder =
        std::make_unique<ImageDecoder>(runners, loop->GetTaskRunner(),
                                       io_manager->GetWeakIOManager());

    auto data = OpenFixtureAsSkData("DashInNooglerHat.jpg");

    ASSERT_TRUE(data);
    ASSERT_GE(data->size(), 0u);

    std::unique_ptr<SkCodec> codec = SkCodec::MakeFromData(data);
    ASSERT_TRUE(codec);

    auto descriptor =
        fml::MakeRefCounted<ImageDescriptor>(std::move(data), std::move(codec));

    ImageDecoder::ImageResult callback = [&](SkiaGPUObject<SkImage> image) {
      ASSERT_TRUE(runners.GetUITaskRunner()->RunsTasksOnCurrentThread());
      ASSERT_TRUE(image.get());
      EXPECT_TRUE(io_manager->did_access_is_gpu_disabled_sync_switch_);
      runners.GetIOTaskRunner()->PostTask(release_io_manager);
    };
    EXPECT_FALSE(io_manager->did_access_is_gpu_disabled_sync_switch_);
    image_decoder->Decode(descriptor, descriptor->width(), descriptor->height(),
                          callback);
  };

  auto setup_io_manager_and_decode = [&]() {
    io_manager = std::make_unique<TestIOManager>(runners.GetIOTaskRunner());
    runners.GetUITaskRunner()->PostTask(decode_image);
  };

  runners.GetIOTaskRunner()->PostTask(setup_io_manager_and_decode);
  latch.Wait();
}

TEST_F(ImageDecoderFixtureTest, ExifDataIsRespectedOnDecode) {
  auto loop = fml::ConcurrentMessageLoop::Create();
  TaskRunners runners(GetCurrentTestName(),         // label
                      CreateNewThread("platform"),  // platform
                      CreateNewThread("raster"),    // raster
                      CreateNewThread("ui"),        // ui
                      CreateNewThread("io")         // io
  );

  fml::AutoResetWaitableEvent latch;

  std::unique_ptr<IOManager> io_manager;

  auto release_io_manager = [&]() {
    io_manager.reset();
    latch.Signal();
  };

  SkISize decoded_size = SkISize::MakeEmpty();
  auto decode_image = [&]() {
    std::unique_ptr<ImageDecoder> image_decoder =
        std::make_unique<ImageDecoder>(runners, loop->GetTaskRunner(),
                                       io_manager->GetWeakIOManager());

    auto data = OpenFixtureAsSkData("Horizontal.jpg");

    ASSERT_TRUE(data);
    ASSERT_GE(data->size(), 0u);

    std::unique_ptr<SkCodec> codec = SkCodec::MakeFromData(data);
    ASSERT_TRUE(codec);

    auto descriptor =
        fml::MakeRefCounted<ImageDescriptor>(std::move(data), std::move(codec));

    ImageDecoder::ImageResult callback = [&](SkiaGPUObject<SkImage> image) {
      ASSERT_TRUE(runners.GetUITaskRunner()->RunsTasksOnCurrentThread());
      ASSERT_TRUE(image.get());
      decoded_size = image.get()->dimensions();
      runners.GetIOTaskRunner()->PostTask(release_io_manager);
    };
    image_decoder->Decode(descriptor, descriptor->width(), descriptor->height(),
                          callback);
  };

  auto setup_io_manager_and_decode = [&]() {
    io_manager = std::make_unique<TestIOManager>(runners.GetIOTaskRunner());
    runners.GetUITaskRunner()->PostTask(decode_image);
  };

  runners.GetIOTaskRunner()->PostTask(setup_io_manager_and_decode);

  latch.Wait();

  ASSERT_EQ(decoded_size.width(), 600);
  ASSERT_EQ(decoded_size.height(), 200);
}

TEST_F(ImageDecoderFixtureTest, CanDecodeWithoutAGPUContext) {
  auto loop = fml::ConcurrentMessageLoop::Create();
  TaskRunners runners(GetCurrentTestName(),         // label
                      CreateNewThread("platform"),  // platform
                      CreateNewThread("raster"),    // raster
                      CreateNewThread("ui"),        // ui
                      CreateNewThread("io")         // io
  );

  fml::AutoResetWaitableEvent latch;

  std::unique_ptr<IOManager> io_manager;

  auto release_io_manager = [&]() {
    io_manager.reset();
    latch.Signal();
  };

  auto decode_image = [&]() {
    std::unique_ptr<ImageDecoder> image_decoder =
        std::make_unique<ImageDecoder>(runners, loop->GetTaskRunner(),
                                       io_manager->GetWeakIOManager());

    auto data = OpenFixtureAsSkData("DashInNooglerHat.jpg");

    ASSERT_TRUE(data);
    ASSERT_GE(data->size(), 0u);

    std::unique_ptr<SkCodec> codec = SkCodec::MakeFromData(data);
    ASSERT_TRUE(codec);

    auto descriptor =
        fml::MakeRefCounted<ImageDescriptor>(std::move(data), std::move(codec));

    ImageDecoder::ImageResult callback = [&](SkiaGPUObject<SkImage> image) {
      ASSERT_TRUE(runners.GetUITaskRunner()->RunsTasksOnCurrentThread());
      ASSERT_TRUE(image.get());
      runners.GetIOTaskRunner()->PostTask(release_io_manager);
    };
    image_decoder->Decode(descriptor, descriptor->width(), descriptor->height(),
                          callback);
  };

  auto setup_io_manager_and_decode = [&]() {
    io_manager =
        std::make_unique<TestIOManager>(runners.GetIOTaskRunner(), false);
    runners.GetUITaskRunner()->PostTask(decode_image);
  };

  runners.GetIOTaskRunner()->PostTask(setup_io_manager_and_decode);

  latch.Wait();
}

TEST_F(ImageDecoderFixtureTest, CanDecodeWithResizes) {
  const auto image_dimensions =
      SkImage::MakeFromEncoded(OpenFixtureAsSkData("DashInNooglerHat.jpg"))
          ->dimensions();

  ASSERT_FALSE(image_dimensions.isEmpty());

  ASSERT_NE(image_dimensions.width(), image_dimensions.height());

  auto loop = fml::ConcurrentMessageLoop::Create();
  TaskRunners runners(GetCurrentTestName(),         // label
                      CreateNewThread("platform"),  // platform
                      CreateNewThread("raster"),    // raster
                      CreateNewThread("ui"),        // ui
                      CreateNewThread("io")         // io
  );

  fml::AutoResetWaitableEvent latch;
  std::unique_ptr<IOManager> io_manager;
  std::unique_ptr<ImageDecoder> image_decoder;

  // Setup the IO manager.
  runners.GetIOTaskRunner()->PostTask([&]() {
    io_manager = std::make_unique<TestIOManager>(runners.GetIOTaskRunner());
    latch.Signal();
  });
  latch.Wait();

  // Setup the image decoder.
  runners.GetUITaskRunner()->PostTask([&]() {
    image_decoder = std::make_unique<ImageDecoder>(
        runners, loop->GetTaskRunner(), io_manager->GetWeakIOManager());

    latch.Signal();
  });
  latch.Wait();

  // Setup a generic decoding utility that gives us the final decoded size.
  auto decoded_size = [&](uint32_t target_width,
                          uint32_t target_height) -> SkISize {
    SkISize final_size = SkISize::MakeEmpty();
    runners.GetUITaskRunner()->PostTask([&]() {
      auto data = OpenFixtureAsSkData("DashInNooglerHat.jpg");

      ASSERT_TRUE(data);
      ASSERT_GE(data->size(), 0u);

      std::unique_ptr<SkCodec> codec = SkCodec::MakeFromData(data);
      ASSERT_TRUE(codec);

      auto descriptor = fml::MakeRefCounted<ImageDescriptor>(std::move(data),
                                                             std::move(codec));

      ImageDecoder::ImageResult callback = [&](SkiaGPUObject<SkImage> image) {
        ASSERT_TRUE(runners.GetUITaskRunner()->RunsTasksOnCurrentThread());
        ASSERT_TRUE(image.get());
        final_size = image.get()->dimensions();
        latch.Signal();
      };
      image_decoder->Decode(descriptor, target_width, target_height, callback);
    });
    latch.Wait();
    return final_size;
  };

  ASSERT_EQ(SkISize::Make(3024, 4032), image_dimensions);
  ASSERT_EQ(decoded_size(3024, 4032), image_dimensions);
  ASSERT_EQ(decoded_size(100, 100), SkISize::Make(100, 100));

  // Destroy the IO manager
  runners.GetIOTaskRunner()->PostTask([&]() {
    io_manager.reset();
    latch.Signal();
  });
  latch.Wait();

  // Destroy the image decoder
  runners.GetUITaskRunner()->PostTask([&]() {
    image_decoder.reset();
    latch.Signal();
  });
  latch.Wait();
}

TEST_F(ImageDecoderFixtureTest, CanResizeWithoutDecode) {
  SkImageInfo info = {};
  size_t row_bytes;
  sk_sp<SkData> decompressed_data;
  SkISize image_dimensions = SkISize::MakeEmpty();
  {
    auto image =
        SkImage::MakeFromEncoded(OpenFixtureAsSkData("DashInNooglerHat.jpg"))
            ->makeRasterImage();
    image_dimensions = image->dimensions();
    SkPixmap pixmap;
    ASSERT_TRUE(image->peekPixels(&pixmap));
    info = SkImageInfo::MakeN32Premul(image_dimensions);
    row_bytes = pixmap.rowBytes();
    decompressed_data =
        SkData::MakeWithCopy(pixmap.writable_addr(), pixmap.computeByteSize());
  }

  // This is not susceptible to changes in the underlying image decoder.
  ASSERT_EQ(decompressed_data->size(), 48771072u);
  ASSERT_EQ(decompressed_data->size(),
            image_dimensions.width() * image_dimensions.height() * 4u);
  ASSERT_EQ(row_bytes, image_dimensions.width() * 4u);
  ASSERT_FALSE(image_dimensions.isEmpty());
  ASSERT_NE(image_dimensions.width(), image_dimensions.height());

  auto loop = fml::ConcurrentMessageLoop::Create();
  TaskRunners runners(GetCurrentTestName(),         // label
                      CreateNewThread("platform"),  // platform
                      CreateNewThread("raster"),    // raster
                      CreateNewThread("ui"),        // ui
                      CreateNewThread("io")         // io
  );

  fml::AutoResetWaitableEvent latch;
  std::unique_ptr<IOManager> io_manager;
  std::unique_ptr<ImageDecoder> image_decoder;

  // Setup the IO manager.
  runners.GetIOTaskRunner()->PostTask([&]() {
    io_manager = std::make_unique<TestIOManager>(runners.GetIOTaskRunner());
    latch.Signal();
  });
  latch.Wait();

  // Setup the image decoder.
  runners.GetUITaskRunner()->PostTask([&]() {
    image_decoder = std::make_unique<ImageDecoder>(
        runners, loop->GetTaskRunner(), io_manager->GetWeakIOManager());

    latch.Signal();
  });
  latch.Wait();

  // Setup a generic decoding utility that gives us the final decoded size.
  auto decoded_size = [&](uint32_t target_width,
                          uint32_t target_height) -> SkISize {
    SkISize final_size = SkISize::MakeEmpty();
    runners.GetUITaskRunner()->PostTask([&]() {
      ASSERT_TRUE(decompressed_data);
      ASSERT_GE(decompressed_data->size(), 0u);

      auto descriptor = fml::MakeRefCounted<ImageDescriptor>(decompressed_data,
                                                             info, row_bytes);

      ImageDecoder::ImageResult callback = [&](SkiaGPUObject<SkImage> image) {
        ASSERT_TRUE(runners.GetUITaskRunner()->RunsTasksOnCurrentThread());
        ASSERT_TRUE(image.get());
        final_size = image.get()->dimensions();
        latch.Signal();
      };
      image_decoder->Decode(descriptor, target_width, target_height, callback);
    });
    latch.Wait();
    return final_size;
  };

  ASSERT_EQ(SkISize::Make(3024, 4032), image_dimensions);
  ASSERT_EQ(decoded_size(3024, 4032), image_dimensions);
  ASSERT_EQ(decoded_size(100, 100), SkISize::Make(100, 100));

  // Destroy the IO manager
  runners.GetIOTaskRunner()->PostTask([&]() {
    io_manager.reset();
    latch.Signal();
  });
  latch.Wait();

  // Destroy the image decoder
  runners.GetUITaskRunner()->PostTask([&]() {
    image_decoder.reset();
    latch.Signal();
  });
  latch.Wait();
}

// Verifies https://skia-review.googlesource.com/c/skia/+/259161 is present in
// Flutter.
TEST(ImageDecoderTest,
     VerifyCodecRepeatCountsForGifAndWebPAreConsistentWithLoopCounts) {
  auto gif_mapping = OpenFixtureAsSkData("hello_loop_2.gif");
  auto webp_mapping = OpenFixtureAsSkData("hello_loop_2.webp");

  ASSERT_TRUE(gif_mapping);
  ASSERT_TRUE(webp_mapping);

  auto gif_codec = SkCodec::MakeFromData(gif_mapping);
  auto webp_codec = SkCodec::MakeFromData(webp_mapping);

  ASSERT_TRUE(gif_codec);
  ASSERT_TRUE(webp_codec);

  // Both fixtures have a loop count of 2 which should lead to the repeat count
  // of 1
  ASSERT_EQ(gif_codec->getRepetitionCount(), 1);
  ASSERT_EQ(webp_codec->getRepetitionCount(), 1);
}

TEST(ImageDecoderTest, VerifySimpleDecoding) {
  auto data = OpenFixtureAsSkData("Horizontal.jpg");
  auto image = SkImage::MakeFromEncoded(data);
  ASSERT_TRUE(image != nullptr);
  ASSERT_EQ(SkISize::Make(600, 200), image->dimensions());

  auto codec = SkCodec::MakeFromData(data);
  ASSERT_TRUE(codec);
  auto descriptor =
      fml::MakeRefCounted<ImageDescriptor>(std::move(data), std::move(codec));

  ASSERT_EQ(
      ImageFromCompressedData(descriptor, 6, 2, fml::tracing::TraceFlow(""))
          ->dimensions(),
      SkISize::Make(6, 2));
}

TEST(ImageDecoderTest, VerifySubpixelDecodingPreservesExifOrientation) {
  auto data = OpenFixtureAsSkData("Horizontal.jpg");
  auto codec = SkCodec::MakeFromData(data);
  ASSERT_TRUE(codec);
  auto descriptor =
      fml::MakeRefCounted<ImageDescriptor>(data, std::move(codec));

  auto image = SkImage::MakeFromEncoded(data);
  ASSERT_TRUE(image != nullptr);
  ASSERT_EQ(SkISize::Make(600, 200), image->dimensions());

  auto decode = [descriptor](uint32_t target_width, uint32_t target_height) {
    return ImageFromCompressedData(descriptor, target_width, target_height,
                                   fml::tracing::TraceFlow(""));
  };

  auto expected_data = OpenFixtureAsSkData("Horizontal.png");
  ASSERT_TRUE(expected_data != nullptr);
  ASSERT_FALSE(expected_data->isEmpty());

  auto assert_image = [&](auto decoded_image) {
    ASSERT_EQ(decoded_image->dimensions(), SkISize::Make(300, 100));
    ASSERT_TRUE(decoded_image->encodeToData(SkEncodedImageFormat::kPNG, 100)
                    ->equals(expected_data.get()));
  };

  assert_image(decode(300, 100));
}

TEST_F(ImageDecoderFixtureTest,
       MultiFrameCodecCanBeCollectedBeforeIOTasksFinish) {
  // This test verifies that the MultiFrameCodec safely shares state between
  // tasks on the IO and UI runners, and does not allow unsafe memory access if
  // the UI object is collected while the IO thread still has pending decode
  // work. This could happen in a real application if the engine is collected
  // while a multi-frame image is decoding. To exercise this, the test:
  //   - Starts a Dart VM
  //   - Latches the IO task runner
  //   - Create a MultiFrameCodec for an animated gif pointed to a callback
  //     in the Dart fixture
  //   - Calls getNextFrame on the UI task runner
  //   - Collects the MultiFrameCodec object before unlatching the IO task
  //     runner.
  //   - Unlatches the IO task runner
  auto settings = CreateSettingsForFixture();
  auto vm_ref = DartVMRef::Create(settings);
  auto vm_data = vm_ref.GetVMData();

  auto gif_mapping = OpenFixtureAsSkData("hello_loop_2.gif");

  ASSERT_TRUE(gif_mapping);

  auto gif_codec = std::shared_ptr<SkCodecImageGenerator>(
      static_cast<SkCodecImageGenerator*>(
          SkCodecImageGenerator::MakeFromEncodedCodec(gif_mapping).release()));
  ASSERT_TRUE(gif_codec);

  TaskRunners runners(GetCurrentTestName(),         // label
                      CreateNewThread("platform"),  // platform
                      CreateNewThread("raster"),    // raster
                      CreateNewThread("ui"),        // ui
                      CreateNewThread("io")         // io
  );

  fml::AutoResetWaitableEvent latch;
  fml::AutoResetWaitableEvent io_latch;
  std::unique_ptr<TestIOManager> io_manager;

  // Setup the IO manager.
  runners.GetIOTaskRunner()->PostTask([&]() {
    io_manager = std::make_unique<TestIOManager>(runners.GetIOTaskRunner());
    latch.Signal();
  });
  latch.Wait();

  auto isolate =
      RunDartCodeInIsolate(vm_ref, settings, runners, "main", {},
                           GetFixturesPath(), io_manager->GetWeakIOManager());

  // Latch the IO task runner.
  runners.GetIOTaskRunner()->PostTask([&]() { io_latch.Wait(); });

  runners.GetUITaskRunner()->PostTask([&]() {
    fml::AutoResetWaitableEvent isolate_latch;
    fml::RefPtr<MultiFrameCodec> codec;
    EXPECT_TRUE(isolate->RunInIsolateScope([&]() -> bool {
      Dart_Handle library = Dart_RootLibrary();
      if (Dart_IsError(library)) {
        isolate_latch.Signal();
        return false;
      }
      Dart_Handle closure =
          Dart_GetField(library, Dart_NewStringFromCString("frameCallback"));
      if (Dart_IsError(closure) || !Dart_IsClosure(closure)) {
        isolate_latch.Signal();
        return false;
      }

      codec = fml::MakeRefCounted<MultiFrameCodec>(std::move(gif_codec));
      codec->getNextFrame(closure);
      codec = nullptr;
      isolate_latch.Signal();
      return true;
    }));
    isolate_latch.Wait();

    EXPECT_FALSE(codec);

    io_latch.Signal();

    latch.Signal();
  });
  latch.Wait();

  // Destroy the IO manager
  runners.GetIOTaskRunner()->PostTask([&]() {
    io_manager.reset();
    latch.Signal();
  });
  latch.Wait();
}

}  // namespace testing
}  // namespace flutter
