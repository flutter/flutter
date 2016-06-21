// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/public/cpp/application/application_test_base.h"
#include "mojo/public/cpp/environment/logging.h"
#include "mojo/public/cpp/system/macros.h"
#include "mojo/public/cpp/utility/run_loop.h"
#include "mojo/services/gfx/images/cpp/image_pipe_consumer_endpoint.h"
#include "mojo/services/gfx/images/cpp/image_pipe_producer_endpoint.h"

namespace mojo {
namespace {

class ImagePipeApplicationTest : public test::ApplicationTestBase {
 public:
  ImagePipeApplicationTest() : ApplicationTestBase() {}
  ~ImagePipeApplicationTest() override {}

 private:
  MOJO_DISALLOW_COPY_AND_ASSIGN(ImagePipeApplicationTest);
};

class TestImagePipe : image_pipe::ImagePipeConsumerDelegate {
 public:
  TestImagePipe(bool producer_checked, bool consumer_checked);
  ~TestImagePipe() override;
  mojo::gfx::ImagePtr CreateTestImage();

  bool HasExperiencedError() { return has_error_; }

  image_pipe::ImagePipeProducerEndpoint* ProducerEndpoint() {
    return producer_endpoint_.get();
  }
  image_pipe::ImagePipeConsumerEndpoint* ConsumerEndpoint() {
    return consumer_endpoint_.get();
  }

  void OverrideAddImage(
      std::function<void(mojo::gfx::ImagePtr image, uint32_t id)> add_func) {
    add_image_override_ = add_func;
  }
  void OverrideRemoveImage(std::function<void(uint32_t id)> remove_func) {
    remove_image_override_ = remove_func;
  }
  void OverridePresentImage(std::function<void(uint32_t id)> present_func) {
    present_image_override_ = present_func;
  }

 private:
  // Inherited from ImagePipeConsumerDelegate
  void AddImage(mojo::gfx::ImagePtr image, uint32_t id) override;
  void RemoveImage(uint32_t id) override;
  void PresentImage(uint32_t id) override;
  void HandleEndpointClosed() override {
    has_error_ = true;
    mojo::RunLoop::current()->Quit();
  }

  std::unique_ptr<image_pipe::ImagePipeProducerEndpoint> producer_endpoint_;
  std::unique_ptr<image_pipe::ImagePipeConsumerEndpoint> consumer_endpoint_;
  mojo::gfx::SupportedImagePropertiesPtr supported_properties_;

  std::function<void(mojo::gfx::ImagePtr image, uint32_t id)>
      add_image_override_;
  std::function<void(uint32_t id)> remove_image_override_;
  std::function<void(uint32_t id)> present_image_override_;

  bool has_error_;
};

void TestImagePipe::AddImage(mojo::gfx::ImagePtr image, uint32_t id) {
  if (add_image_override_)
    add_image_override_(image.Pass(), id);
}
void TestImagePipe::RemoveImage(uint32_t id) {
  if (remove_image_override_)
    remove_image_override_(id);
}
void TestImagePipe::PresentImage(uint32_t id) {
  if (present_image_override_)
    present_image_override_(id);
}

TestImagePipe::TestImagePipe(bool producer_checked, bool consumer_checked) {
  has_error_ = false;
  supported_properties_ = mojo::gfx::SupportedImageProperties::New();
  supported_properties_->size = mojo::Size::New();
  supported_properties_->size->width = 256;
  supported_properties_->size->height = 256;

  supported_properties_->formats =
      mojo::Array<mojo::gfx::ColorFormatPtr>::New(0);
  mojo::gfx::ColorFormatPtr format = mojo::gfx::ColorFormat::New();
  format->layout = mojo::gfx::PixelLayout::BGRA_8888;
  format->color_space = mojo::gfx::ColorSpace::SRGB;
  supported_properties_->formats.push_back(format.Pass());

  mojo::gfx::ImagePipePtr image_pipe_ptr;
  consumer_endpoint_.reset(new image_pipe::ImagePipeConsumerEndpoint(
      GetProxy(&image_pipe_ptr), this));
  if (!consumer_checked) {
    consumer_endpoint_->DisableFatalErrorsForTesting();
  }

  producer_endpoint_.reset(
      new image_pipe::ImagePipeProducerEndpoint(image_pipe_ptr.Pass(), [this] {
        has_error_ = true;
        mojo::RunLoop::current()->Quit();
      }));
  if (!producer_checked) {
    producer_endpoint_->DisableFatalErrorsForTesting();
  }
}

TestImagePipe::~TestImagePipe() {}

mojo::gfx::ImagePtr TestImagePipe::CreateTestImage() {
  mojo::MessagePipe pipe;

  uint32_t bytes_per_pixel = 32;

  mojo::gfx::ImageBufferPtr image_buffer = mojo::gfx::ImageBuffer::New();
  image_buffer->size = supported_properties_->size->width *
                       supported_properties_->size->width * bytes_per_pixel;
  image_buffer->data = mojo::ScopedHandle(pipe.handle0.Pass());

  mojo::gfx::ImagePtr image = mojo::gfx::Image::New();
  image->buffer = image_buffer.Pass();
  image->format = supported_properties_->formats[0].Clone();
  image->size = supported_properties_->size.Clone();
  image->pitch = supported_properties_->size->width;
  image->stride = image->pitch * bytes_per_pixel;

  return image;
}

// Tests that the usual flow for creating, adding, presenting, and removing
// an image doesnt crash/break/cause-errors etc
TEST_F(ImagePipeApplicationTest, NormalImageLifeCycle) {
  TestImagePipe image_pipe(true, true);

  image_pipe.OverridePresentImage([&image_pipe](uint32_t id) {
    uint32_t acquired_id;
    MOJO_CHECK(image_pipe.ConsumerEndpoint()->AcquireNextImage(&acquired_id));
    MOJO_CHECK(acquired_id == id);
    image_pipe.ConsumerEndpoint()->ReleaseImage(
        id, mojo::gfx::PresentationStatus::PRESENTED);
  });

  uint32_t id = 0, acquired_id = UINT32_MAX;
  image_pipe.ProducerEndpoint()->AddImage(image_pipe.CreateTestImage(), id);
  MOJO_CHECK(image_pipe.ProducerEndpoint()->AcquireImage(&acquired_id));
  MOJO_CHECK(acquired_id == id);
  image_pipe.ProducerEndpoint()->PresentImage(
      id, [&image_pipe](mojo::gfx::PresentationStatus status) {
        EXPECT_EQ(mojo::gfx::PresentationStatus::PRESENTED, status);
        mojo::RunLoop::current()->Quit();
      });

  mojo::RunLoop::current()->Run();
  acquired_id = UINT32_MAX;
  EXPECT_TRUE(image_pipe.ProducerEndpoint()->AcquireImage(&acquired_id));
  MOJO_CHECK(acquired_id == id);
  image_pipe.ProducerEndpoint()->RemoveImage(acquired_id);

  EXPECT_FALSE(image_pipe.HasExperiencedError());
}

// Tests that flushing returns images to the producer with NOT_PRESENTED_FLUSHED
TEST_F(ImagePipeApplicationTest, FlushImages) {
  TestImagePipe image_pipe(true, true);

  uint32_t id = 0, acquired_id = UINT32_MAX;
  image_pipe.ProducerEndpoint()->AddImage(image_pipe.CreateTestImage(), id);
  MOJO_CHECK(image_pipe.ProducerEndpoint()->AcquireImage(&acquired_id));
  MOJO_CHECK(acquired_id == id);
  image_pipe.ProducerEndpoint()->PresentImage(
      id, [](mojo::gfx::PresentationStatus status) {
        EXPECT_EQ(mojo::gfx::PresentationStatus::NOT_PRESENTED_FLUSHED, status);
        mojo::RunLoop::current()->Quit();
      });
  image_pipe.ProducerEndpoint()->FlushImages();

  mojo::RunLoop::current()->Run();
  acquired_id = UINT32_MAX;
  EXPECT_TRUE(image_pipe.ProducerEndpoint()->AcquireImage(&acquired_id));
  EXPECT_TRUE(acquired_id == id);

  EXPECT_FALSE(image_pipe.HasExperiencedError());
}

// Tests that you can safely try to acquire an image when none are available,
// and that you will safely fail
TEST_F(ImagePipeApplicationTest, AcquireImageFromEmptyPool) {
  TestImagePipe image_pipe(true, true);

  uint32_t id = 0xDEADBEEF, acquired_id = id;
  EXPECT_FALSE(image_pipe.ProducerEndpoint()->AcquireImage(&acquired_id));
  EXPECT_TRUE(acquired_id == id);
  EXPECT_FALSE(image_pipe.HasExperiencedError());
}

// Tests that adding an image with an existing ID causes the pipe to error
TEST_F(ImagePipeApplicationTest, ProducerError_AddImageWithReusedID) {
  TestImagePipe image_pipe(false, true);

  uint32_t id = 0;
  image_pipe.ProducerEndpoint()->AddImage(image_pipe.CreateTestImage(), id);
  image_pipe.ProducerEndpoint()->AddImage(image_pipe.CreateTestImage(), id);

  mojo::RunLoop::current()->Run();
  EXPECT_TRUE(image_pipe.HasExperiencedError());
}

// Tests that removing an image that hasnt been added causes the pipe to error
TEST_F(ImagePipeApplicationTest, ProducerError_RemoveImageBeforeAdded) {
  TestImagePipe image_pipe(false, true);

  uint32_t id = 0;
  image_pipe.ProducerEndpoint()->RemoveImage(id);

  mojo::RunLoop::current()->Run();
  EXPECT_TRUE(image_pipe.HasExperiencedError());
}

// Tests that removing an image that has already been removed causes the pipe to
// error (essentially that removing and image takes it out of the pool)
TEST_F(ImagePipeApplicationTest, ProducerError_AddImageThenRemoveTwice) {
  TestImagePipe image_pipe(false, true);

  uint32_t id = 0;
  image_pipe.ProducerEndpoint()->AddImage(image_pipe.CreateTestImage(), id);
  image_pipe.ProducerEndpoint()->RemoveImage(id);
  image_pipe.ProducerEndpoint()->RemoveImage(id);

  mojo::RunLoop::current()->Run();
  EXPECT_TRUE(image_pipe.HasExperiencedError());
}

// Tests that removing an image owned by the consumer causes the pipe to error
TEST_F(ImagePipeApplicationTest, ProducerError_RemoveImageOwnedByConsumer) {
  TestImagePipe image_pipe(false, true);

  uint32_t id = 0, acquired_id = UINT32_MAX;
  image_pipe.ProducerEndpoint()->AddImage(image_pipe.CreateTestImage(), id);
  MOJO_CHECK(image_pipe.ProducerEndpoint()->AcquireImage(&acquired_id));
  MOJO_CHECK(acquired_id == id);
  image_pipe.ProducerEndpoint()->PresentImage(
      id, [](mojo::gfx::PresentationStatus) {});
  image_pipe.ProducerEndpoint()->RemoveImage(id);

  mojo::RunLoop::current()->Run();
  EXPECT_TRUE(image_pipe.HasExperiencedError());
}

// Tests that presenting an image that hasnt been added causes the pipe to error
TEST_F(ImagePipeApplicationTest, ProducerError_PresentImageNotAdded) {
  TestImagePipe image_pipe(false, true);

  uint32_t id = 0;
  image_pipe.ProducerEndpoint()->PresentImage(
      id, [](mojo::gfx::PresentationStatus) {});

  mojo::RunLoop::current()->Run();
  EXPECT_TRUE(image_pipe.HasExperiencedError());
}

// Tests that presenting an image that has already been presented causes the
// pipe to error
TEST_F(ImagePipeApplicationTest, ProducerError_PresentImageTwice) {
  TestImagePipe image_pipe(false, true);

  uint32_t id = 0, acquired_id = UINT32_MAX;
  image_pipe.ProducerEndpoint()->AddImage(image_pipe.CreateTestImage(), id);
  MOJO_CHECK(image_pipe.ProducerEndpoint()->AcquireImage(&acquired_id));
  MOJO_CHECK(acquired_id == id);
  image_pipe.ProducerEndpoint()->PresentImage(
      id, [](mojo::gfx::PresentationStatus) {});
  image_pipe.ProducerEndpoint()->PresentImage(
      id, [](mojo::gfx::PresentationStatus) {});

  mojo::RunLoop::current()->Run();
  EXPECT_TRUE(image_pipe.HasExperiencedError());
}

// Tests that releasing an image that hasnt been added causes the pipe to error
TEST_F(ImagePipeApplicationTest, ConsumerError_ReleaseImageNotInPool) {
  TestImagePipe image_pipe(true, false);

  image_pipe.OverridePresentImage([&image_pipe](uint32_t id) {
    image_pipe.ConsumerEndpoint()->ReleaseImage(
        id + 1, mojo::gfx::PresentationStatus::PRESENTED);
  });

  uint32_t id = 0, acquired_id = UINT32_MAX;
  image_pipe.ProducerEndpoint()->AddImage(image_pipe.CreateTestImage(), id);
  MOJO_CHECK(image_pipe.ProducerEndpoint()->AcquireImage(&acquired_id));
  MOJO_CHECK(acquired_id == id);
  image_pipe.ProducerEndpoint()->PresentImage(
      id, [](mojo::gfx::PresentationStatus) {});

  mojo::RunLoop::current()->Run();
  EXPECT_TRUE(image_pipe.HasExperiencedError());
}

// Tests that releasing an image before acquiring it causes the pipe to error
TEST_F(ImagePipeApplicationTest, ConsumerError_ReleaseBeforeAcquire) {
  TestImagePipe image_pipe(true, false);

  image_pipe.OverridePresentImage([&image_pipe](uint32_t id) {
    image_pipe.ConsumerEndpoint()->ReleaseImage(
        id, mojo::gfx::PresentationStatus::PRESENTED);
  });

  uint32_t id = 0, acquired_id = UINT32_MAX;
  image_pipe.ProducerEndpoint()->AddImage(image_pipe.CreateTestImage(), id);
  MOJO_CHECK(image_pipe.ProducerEndpoint()->AcquireImage(&acquired_id));
  MOJO_CHECK(acquired_id == id);
  image_pipe.ProducerEndpoint()->PresentImage(
      id, [](mojo::gfx::PresentationStatus) {});

  mojo::RunLoop::current()->Run();
  EXPECT_TRUE(image_pipe.HasExperiencedError());
}

// Tests that releasing an image before its presented causes the pipe to error
TEST_F(ImagePipeApplicationTest, ConsumerError_ReleaseImageNotPresented) {
  TestImagePipe image_pipe(true, false);

  image_pipe.OverridePresentImage([&image_pipe](uint32_t id) {
    uint32_t acquired_id;
    MOJO_CHECK(image_pipe.ConsumerEndpoint()->AcquireNextImage(&acquired_id));
    MOJO_CHECK(acquired_id == id);
    image_pipe.ConsumerEndpoint()->ReleaseImage(
        id + 1, mojo::gfx::PresentationStatus::PRESENTED);
  });

  uint32_t id = 0, acquired_id = UINT32_MAX;
  image_pipe.ProducerEndpoint()->AddImage(image_pipe.CreateTestImage(), id);
  image_pipe.ProducerEndpoint()->AddImage(image_pipe.CreateTestImage(), id + 1);
  MOJO_CHECK(image_pipe.ProducerEndpoint()->AcquireImage(&acquired_id));
  MOJO_CHECK(acquired_id == id);
  image_pipe.ProducerEndpoint()->PresentImage(
      id, [](mojo::gfx::PresentationStatus) {});

  mojo::RunLoop::current()->Run();
  EXPECT_TRUE(image_pipe.HasExperiencedError());
}

}  // namespace
}  // namespace mojo
