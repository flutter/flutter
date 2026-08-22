// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/platform/android/jni_util.h"
#include "flutter/shell/platform/android/image_external_texture_gl.h"
#include "flutter/shell/platform/android/jni/jni_mock.h"
#include "flutter/shell/platform/android/jni/mock_jni_env.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

using ::testing::_;
using ::testing::Return;
using ::testing::ReturnArg;

class ImageExternalTextureReproduceTest : public ::testing::Test {
 public:
  static void SetUpTestSuite() {
    static std::once_flag jvm_init_flag;
    std::call_once(jvm_init_flag, SetUpJVM);
  }

 private:
  friend class MockJNIEnvProvider;
  static MockJavaVM jvm_;
  static void SetUpJVM();
};

MockJavaVM ImageExternalTextureReproduceTest::jvm_;

class MockJNIEnvProvider {
 public:
  MockJNIEnvProvider() {
    ImageExternalTextureReproduceTest::jvm_.SetJNIEnv(&env_);
  }
  ~MockJNIEnvProvider() {
    ImageExternalTextureReproduceTest::jvm_.SetJNIEnv(nullptr);
  }
  MockJNIEnv& env() { return env_; }

 private:
  MockJNIEnv env_;
};

void ImageExternalTextureReproduceTest::SetUpJVM() {
  fml::jni::InitJavaVM(&jvm_);

  MockJNIEnvProvider env_provider;
  MockJNIEnv& mock_env = env_provider.env();

  EXPECT_CALL(mock_env, GetObjectRefType(_))
      .WillRepeatedly(Return(JNILocalRefType));
  EXPECT_CALL(mock_env, NewLocalRef(_)).WillRepeatedly(ReturnArg<0>());
  EXPECT_CALL(mock_env, DeleteLocalRef(_)).WillRepeatedly(Return());
  EXPECT_CALL(mock_env, NewGlobalRef(_)).WillRepeatedly(ReturnArg<0>());
  EXPECT_CALL(mock_env, DeleteGlobalRef(_)).WillRepeatedly(Return());
  EXPECT_CALL(mock_env, ExceptionCheck()).WillRepeatedly(Return(JNI_FALSE));
}

class MockImageExternalTextureGL : public ImageExternalTextureGL {
 public:
  MockImageExternalTextureGL(
      int64_t id,
      const fml::jni::ScopedJavaGlobalRef<jobject>& image_texture_entry,
      const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade,
      ImageExternalTexture::ImageLifecycle lifecycle)
      : ImageExternalTextureGL(id, image_texture_entry, jni_facade, lifecycle) {
  }

  sk_sp<flutter::DlImage> CreateDlImage(
      PaintContext& context,
      const SkRect& bounds,
      std::optional<HardwareBufferKey> id,
      impeller::UniqueEGLImageKHR&& egl_image) override {
    return nullptr;
  }

  void CallProcessFrame(PaintContext& context, const SkRect& bounds) {
    ProcessFrame(context, bounds);
  }
};

TEST_F(ImageExternalTextureReproduceTest,
       DISABLED_CloseImageCalledOnProcessFrame) {
  MockJNIEnvProvider env_provider;
  MockJNIEnv& mock_env = env_provider.env();

  EXPECT_CALL(mock_env, GetObjectRefType(_))
      .WillRepeatedly(Return(JNILocalRefType));
  EXPECT_CALL(mock_env, NewLocalRef(_)).WillRepeatedly(ReturnArg<0>());
  EXPECT_CALL(mock_env, DeleteLocalRef(_)).WillRepeatedly(Return());

  auto jni_mock = std::make_shared<JNIMock>();

  jobject fake_image = reinterpret_cast<jobject>(0x123);
  jobject fake_hardware_buffer = reinterpret_cast<jobject>(0x456);

  EXPECT_CALL(*jni_mock, ImageProducerTextureEntryAcquireLatestImage(_))
      .WillRepeatedly(Return(JavaLocalRef(&mock_env, fake_image)));

  EXPECT_CALL(*jni_mock, ImageGetHardwareBuffer(_))
      .WillRepeatedly(Return(JavaLocalRef(&mock_env, fake_hardware_buffer)));

  EXPECT_CALL(*jni_mock, HardwareBufferClose(_)).Times(1);

  // Expect that CloseImage is called on the acquired image.
  // This expectation should fail with the buggy code.
  EXPECT_CALL(*jni_mock, ImageClose(_)).Times(1);

  fml::jni::ScopedJavaGlobalRef<jobject> fake_entry;
  MockImageExternalTextureGL texture(
      0, fake_entry, jni_mock, ImageExternalTexture::ImageLifecycle::kReset);

  flutter::Texture::PaintContext context;
  texture.CallProcessFrame(context, SkRect::MakeWH(100, 100));
}

TEST_F(ImageExternalTextureReproduceTest,
       CloseImageCalledOnProcessFrameWhenHardwareBufferIsNull) {
  MockJNIEnvProvider env_provider;
  MockJNIEnv& mock_env = env_provider.env();

  EXPECT_CALL(mock_env, GetObjectRefType(_))
      .WillRepeatedly(Return(JNILocalRefType));
  EXPECT_CALL(mock_env, NewLocalRef(_)).WillRepeatedly(ReturnArg<0>());
  EXPECT_CALL(mock_env, DeleteLocalRef(_)).WillRepeatedly(Return());

  auto jni_mock = std::make_shared<JNIMock>();

  jobject fake_image = reinterpret_cast<jobject>(0x123);

  EXPECT_CALL(*jni_mock, ImageProducerTextureEntryAcquireLatestImage(_))
      .WillRepeatedly(Return(JavaLocalRef(&mock_env, fake_image)));

  // Simulate that ImageGetHardwareBuffer returns null.
  EXPECT_CALL(*jni_mock, ImageGetHardwareBuffer(_))
      .WillRepeatedly(Return(JavaLocalRef()));

  // HardwareBufferClose should NOT be called since we never got a valid buffer.
  EXPECT_CALL(*jni_mock, HardwareBufferClose(_)).Times(0);

  // Expect that CloseImage is still called on the acquired image to prevent
  // leaks.
  EXPECT_CALL(*jni_mock, ImageClose(_)).Times(1);

  fml::jni::ScopedJavaGlobalRef<jobject> fake_entry;
  MockImageExternalTextureGL texture(
      0, fake_entry, jni_mock, ImageExternalTexture::ImageLifecycle::kReset);

  flutter::Texture::PaintContext context;
  texture.CallProcessFrame(context, SkRect::MakeWH(100, 100));
}

}  // namespace testing
}  // namespace flutter
