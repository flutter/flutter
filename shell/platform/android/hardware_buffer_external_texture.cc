
#include "flutter/shell/platform/android/hardware_buffer_external_texture.h"

#include <android/hardware_buffer_jni.h>
#include <android/sensor.h>

#include "flutter/shell/platform/android/jni/platform_view_android_jni.h"
#include "flutter/shell/platform/android/ndk_helpers.h"

namespace flutter {

HardwareBufferExternalTexture::HardwareBufferExternalTexture(
    int64_t id,
    const fml::jni::ScopedJavaGlobalRef<jobject>& image_texture_entry,
    const std::shared_ptr<PlatformViewAndroidJNI>& jni_facade)
    : Texture(id),
      image_texture_entry_(image_texture_entry),
      jni_facade_(jni_facade) {}

// Implementing flutter::Texture.
void HardwareBufferExternalTexture::Paint(PaintContext& context,
                                          const SkRect& bounds,
                                          bool freeze,
                                          const DlImageSampling sampling) {
  if (state_ == AttachmentState::kDetached) {
    return;
  }
  Attach(context);
  const bool should_process_frame =
      (!freeze && new_frame_ready_) || dl_image_ == nullptr;
  if (should_process_frame) {
    ProcessFrame(context, bounds);
    new_frame_ready_ = false;
  }
  if (dl_image_) {
    context.canvas->DrawImageRect(
        dl_image_,                                     // image
        SkRect::Make(dl_image_->bounds()),             // source rect
        bounds,                                        // destination rect
        sampling,                                      // sampling
        context.paint,                                 // paint
        flutter::DlCanvas::SrcRectConstraint::kStrict  // enforce edges
    );
  } else {
    FML_LOG(ERROR)
        << "No DlImage available for HardwareBufferExternalTexture to paint.";
  }
}

// Implementing flutter::Texture.
void HardwareBufferExternalTexture::MarkNewFrameAvailable() {
  new_frame_ready_ = true;
}

// Implementing flutter::Texture.
void HardwareBufferExternalTexture::OnTextureUnregistered() {}

// Implementing flutter::ContextListener.
void HardwareBufferExternalTexture::OnGrContextCreated() {
  state_ = AttachmentState::kUninitialized;
}

// Implementing flutter::ContextListener.
void HardwareBufferExternalTexture::OnGrContextDestroyed() {
  if (state_ == AttachmentState::kAttached) {
    dl_image_.reset();
    Detach();
  }
  state_ = AttachmentState::kDetached;
}

JavaLocalRef HardwareBufferExternalTexture::AcquireLatestImage() {
  JNIEnv* env = fml::jni::AttachCurrentThread();
  FML_CHECK(env != nullptr);

  // ImageTextureEntry.acquireLatestImage.
  JavaLocalRef image_java = jni_facade_->ImageTextureEntryAcquireLatestImage(
      JavaLocalRef(image_texture_entry_));
  return image_java;
}

void HardwareBufferExternalTexture::CloseImage(
    const fml::jni::JavaRef<jobject>& image) {
  if (image.obj() == nullptr) {
    return;
  }
  jni_facade_->ImageClose(JavaLocalRef(image));
}

void HardwareBufferExternalTexture::CloseHardwareBuffer(
    const fml::jni::JavaRef<jobject>& hardware_buffer) {
  if (hardware_buffer.obj() == nullptr) {
    return;
  }
  jni_facade_->HardwareBufferClose(JavaLocalRef(hardware_buffer));
}

JavaLocalRef HardwareBufferExternalTexture::HardwareBufferFor(
    const fml::jni::JavaRef<jobject>& image) {
  if (image.obj() == nullptr) {
    return JavaLocalRef();
  }
  // Image.getHardwareBuffer.
  return jni_facade_->ImageGetHardwareBuffer(JavaLocalRef(image));
}

AHardwareBuffer* HardwareBufferExternalTexture::AHardwareBufferFor(
    const fml::jni::JavaRef<jobject>& hardware_buffer) {
  JNIEnv* env = fml::jni::AttachCurrentThread();
  FML_CHECK(env != nullptr);
  return NDKHelpers::AHardwareBuffer_fromHardwareBuffer(env,
                                                        hardware_buffer.obj());
}

}  // namespace flutter
