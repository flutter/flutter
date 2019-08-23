// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/common/task_runners.h"
#include "flutter/fml/mapping.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/lib/ui/painting/image_decoder.h"
#include "flutter/testing/test_gl_surface.h"
#include "flutter/testing/testing.h"
#include "flutter/testing/thread_test.h"

namespace flutter {
namespace testing {

using ImageDecoderFixtureTest = ThreadTest;

class TestIOManager final : public IOManager {
 public:
  TestIOManager(fml::RefPtr<fml::TaskRunner> task_runner,
                bool has_gpu_context = true)
      : gl_context_(has_gpu_context ? gl_surface_.CreateGrContext() : nullptr),
        weak_gl_context_factory_(
            has_gpu_context ? std::make_unique<fml::WeakPtrFactory<GrContext>>(
                                  gl_context_.get())
                            : nullptr),
        unref_queue_(fml::MakeRefCounted<SkiaUnrefQueue>(
            task_runner,
            fml::TimeDelta::FromNanoseconds(0))),
        runner_(task_runner),
        weak_factory_(this) {
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
  fml::WeakPtr<GrContext> GetResourceContext() const override {
    return weak_gl_context_factory_ ? weak_gl_context_factory_->GetWeakPtr()
                                    : fml::WeakPtr<GrContext>{};
  }

  // |IOManager|
  fml::RefPtr<flutter::SkiaUnrefQueue> GetSkiaUnrefQueue() const override {
    return unref_queue_;
  }

 private:
  TestGLSurface gl_surface_;
  sk_sp<GrContext> gl_context_;
  std::unique_ptr<fml::WeakPtrFactory<GrContext>> weak_gl_context_factory_;
  fml::RefPtr<SkiaUnrefQueue> unref_queue_;
  fml::WeakPtr<TestIOManager> weak_prototype_;
  fml::RefPtr<fml::TaskRunner> runner_;
  fml::WeakPtrFactory<TestIOManager> weak_factory_;

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

TEST_F(ImageDecoderFixtureTest, CanCreateImageDecoder) {
  auto loop = fml::ConcurrentMessageLoop::Create();
  auto thread_task_runner = CreateNewThread();
  TaskRunners runners(GetCurrentTestName(),  // label
                      thread_task_runner,    // platform
                      thread_task_runner,    // gpu
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
                      thread_task_runner,    // gpu
                      thread_task_runner,    // ui
                      thread_task_runner     // io
  );

  fml::AutoResetWaitableEvent latch;
  thread_task_runner->PostTask([&]() {
    TestIOManager manager(runners.GetIOTaskRunner());
    ImageDecoder decoder(runners, loop->GetTaskRunner(),
                         manager.GetWeakIOManager());

    ImageDecoder::ImageDescriptor image_descriptor;
    image_descriptor.data = OpenFixtureAsSkData("ThisDoesNotExist.jpg");

    ASSERT_FALSE(image_descriptor.data);

    ImageDecoder::ImageResult callback = [&](SkiaGPUObject<SkImage> image) {
      ASSERT_TRUE(runners.GetUITaskRunner()->RunsTasksOnCurrentThread());
      ASSERT_FALSE(image.get());
      latch.Signal();
    };
    decoder.Decode(std::move(image_descriptor), callback);
  });
  latch.Wait();
}

TEST_F(ImageDecoderFixtureTest, ValidImageResultsInSuccess) {
  auto loop = fml::ConcurrentMessageLoop::Create();
  TaskRunners runners(GetCurrentTestName(),         // label
                      CreateNewThread("platform"),  // platform
                      CreateNewThread("gpu"),       // gpu
                      CreateNewThread("ui"),        // ui
                      CreateNewThread("io")         // io
  );

  fml::AutoResetWaitableEvent latch;

  std::unique_ptr<IOManager> io_manager;
  std::unique_ptr<ImageDecoder> image_decoder;

  auto decode_image = [&]() {
    image_decoder = std::make_unique<ImageDecoder>(
        runners, loop->GetTaskRunner(), io_manager->GetWeakIOManager());

    ImageDecoder::ImageDescriptor image_descriptor;
    image_descriptor.data = OpenFixtureAsSkData("DashInNooglerHat.jpg");

    ASSERT_TRUE(image_descriptor.data);
    ASSERT_GE(image_descriptor.data->size(), 0u);

    ImageDecoder::ImageResult callback = [&](SkiaGPUObject<SkImage> image) {
      ASSERT_TRUE(runners.GetUITaskRunner()->RunsTasksOnCurrentThread());
      ASSERT_TRUE(image.get());
      latch.Signal();
    };
    image_decoder->Decode(std::move(image_descriptor), callback);
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
                      CreateNewThread("gpu"),       // gpu
                      CreateNewThread("ui"),        // ui
                      CreateNewThread("io")         // io
  );

  fml::AutoResetWaitableEvent latch;

  std::unique_ptr<IOManager> io_manager;
  std::unique_ptr<ImageDecoder> image_decoder;

  SkISize decoded_size = SkISize::MakeEmpty();
  auto decode_image = [&]() {
    image_decoder = std::make_unique<ImageDecoder>(
        runners, loop->GetTaskRunner(), io_manager->GetWeakIOManager());

    ImageDecoder::ImageDescriptor image_descriptor;
    image_descriptor.data = OpenFixtureAsSkData("Horizontal.jpg");

    ASSERT_TRUE(image_descriptor.data);
    ASSERT_GE(image_descriptor.data->size(), 0u);

    ImageDecoder::ImageResult callback = [&](SkiaGPUObject<SkImage> image) {
      ASSERT_TRUE(runners.GetUITaskRunner()->RunsTasksOnCurrentThread());
      ASSERT_TRUE(image.get());
      decoded_size = image.get()->dimensions();
      latch.Signal();
    };
    image_decoder->Decode(std::move(image_descriptor), callback);
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
                      CreateNewThread("gpu"),       // gpu
                      CreateNewThread("ui"),        // ui
                      CreateNewThread("io")         // io
  );

  fml::AutoResetWaitableEvent latch;

  std::unique_ptr<IOManager> io_manager;
  std::unique_ptr<ImageDecoder> image_decoder;

  auto decode_image = [&]() {
    image_decoder = std::make_unique<ImageDecoder>(
        runners, loop->GetTaskRunner(), io_manager->GetWeakIOManager());

    ImageDecoder::ImageDescriptor image_descriptor;
    image_descriptor.data = OpenFixtureAsSkData("DashInNooglerHat.jpg");

    ASSERT_TRUE(image_descriptor.data);
    ASSERT_GE(image_descriptor.data->size(), 0u);

    ImageDecoder::ImageResult callback = [&](SkiaGPUObject<SkImage> image) {
      ASSERT_TRUE(runners.GetUITaskRunner()->RunsTasksOnCurrentThread());
      ASSERT_TRUE(image.get());
      latch.Signal();
    };
    image_decoder->Decode(std::move(image_descriptor), callback);
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
                      CreateNewThread("gpu"),       // gpu
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
  auto decoded_size = [&](std::optional<uint32_t> target_width,
                          std::optional<uint32_t> target_height) -> SkISize {
    SkISize final_size = SkISize::MakeEmpty();
    runners.GetUITaskRunner()->PostTask([&]() {
      ImageDecoder::ImageDescriptor image_descriptor;
      image_descriptor.target_width = target_width;
      image_descriptor.target_height = target_height;
      image_descriptor.data = OpenFixtureAsSkData("DashInNooglerHat.jpg");

      ASSERT_TRUE(image_descriptor.data);
      ASSERT_GE(image_descriptor.data->size(), 0u);

      ImageDecoder::ImageResult callback = [&](SkiaGPUObject<SkImage> image) {
        ASSERT_TRUE(runners.GetUITaskRunner()->RunsTasksOnCurrentThread());
        ASSERT_TRUE(image.get());
        final_size = image.get()->dimensions();
        latch.Signal();
      };
      image_decoder->Decode(std::move(image_descriptor), callback);
    });
    latch.Wait();
    return final_size;
  };

  ASSERT_EQ(SkISize::Make(3024, 4032), image_dimensions);
  ASSERT_EQ(decoded_size({}, {}), image_dimensions);
  ASSERT_EQ(decoded_size(100, {}), SkISize::Make(100, 133));
  ASSERT_EQ(decoded_size({}, 100), SkISize::Make(75, 100));
  ASSERT_EQ(decoded_size(100, 100), SkISize::Make(100, 100));
}

TEST_F(ImageDecoderFixtureTest, CanResizeWithoutDecode) {
  ImageDecoder::ImageInfo info = {};
  sk_sp<SkData> decompressed_data;
  SkISize image_dimensions = SkISize::MakeEmpty();
  {
    auto image =
        SkImage::MakeFromEncoded(OpenFixtureAsSkData("DashInNooglerHat.jpg"))
            ->makeRasterImage();
    image_dimensions = image->dimensions();
    SkPixmap pixmap;
    ASSERT_TRUE(image->peekPixels(&pixmap));
    info.sk_info = SkImageInfo::MakeN32Premul(image_dimensions);
    info.row_bytes = pixmap.rowBytes();
    decompressed_data =
        SkData::MakeWithCopy(pixmap.writable_addr(), pixmap.computeByteSize());
  }

  // This is not susecptible to changes in the underlying image decoder.
  ASSERT_EQ(decompressed_data->size(), 48771072u);
  ASSERT_EQ(decompressed_data->size(),
            image_dimensions.width() * image_dimensions.height() * 4u);
  ASSERT_EQ(info.row_bytes, image_dimensions.width() * 4u);
  ASSERT_FALSE(image_dimensions.isEmpty());
  ASSERT_NE(image_dimensions.width(), image_dimensions.height());

  auto loop = fml::ConcurrentMessageLoop::Create();
  TaskRunners runners(GetCurrentTestName(),         // label
                      CreateNewThread("platform"),  // platform
                      CreateNewThread("gpu"),       // gpu
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
  auto decoded_size = [&](std::optional<uint32_t> target_width,
                          std::optional<uint32_t> target_height) -> SkISize {
    SkISize final_size = SkISize::MakeEmpty();
    runners.GetUITaskRunner()->PostTask([&]() {
      ImageDecoder::ImageDescriptor image_descriptor;
      image_descriptor.target_width = target_width;
      image_descriptor.target_height = target_height;
      image_descriptor.data = decompressed_data;
      image_descriptor.decompressed_image_info = info;

      ASSERT_TRUE(image_descriptor.data);
      ASSERT_GE(image_descriptor.data->size(), 0u);

      ImageDecoder::ImageResult callback = [&](SkiaGPUObject<SkImage> image) {
        ASSERT_TRUE(runners.GetUITaskRunner()->RunsTasksOnCurrentThread());
        ASSERT_TRUE(image.get());
        final_size = image.get()->dimensions();
        latch.Signal();
      };
      image_decoder->Decode(std::move(image_descriptor), callback);
    });
    latch.Wait();
    return final_size;
  };

  ASSERT_EQ(SkISize::Make(3024, 4032), image_dimensions);
  ASSERT_EQ(decoded_size({}, {}), image_dimensions);
  ASSERT_EQ(decoded_size(100, {}), SkISize::Make(100, 133));
  ASSERT_EQ(decoded_size({}, 100), SkISize::Make(75, 100));
  ASSERT_EQ(decoded_size(100, 100), SkISize::Make(100, 100));
}

}  // namespace testing
}  // namespace flutter
