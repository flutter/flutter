
#include "flutter/shell/platform/android/hardware_buffer_external_texture.h"

#include <android/hardware_buffer_jni.h>
#include <android/sensor.h>
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
    FML_LOG(WARNING)
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

AHardwareBuffer* HardwareBufferExternalTexture::GetLatestHardwareBuffer() {
  JNIEnv* env = fml::jni::AttachCurrentThread();
  FML_CHECK(env != nullptr);

  // ImageTextureEntry.acquireLatestImage.
  JavaLocalRef image_java = jni_facade_->ImageTextureEntryAcquireLatestImage(
      JavaLocalRef(image_texture_entry_));
  if (image_java.obj() == nullptr) {
    return nullptr;
  }

  // Image.getHardwareBuffer.
  JavaLocalRef hardware_buffer_java =
      jni_facade_->ImageGetHardwareBuffer(image_java);
  if (hardware_buffer_java.obj() == nullptr) {
    jni_facade_->ImageClose(image_java);
    return nullptr;
  }

  // Convert into NDK HardwareBuffer.
  AHardwareBuffer* latest_hardware_buffer =
      NDKHelpers::AHardwareBuffer_fromHardwareBuffer(
          env, hardware_buffer_java.obj());
  if (latest_hardware_buffer == nullptr) {
    jni_facade_->HardwareBufferClose(hardware_buffer_java);
    jni_facade_->ImageClose(image_java);
    return nullptr;
  }

  // Keep hardware buffer alive.
  NDKHelpers::AHardwareBuffer_acquire(latest_hardware_buffer);

  // Now that we have referenced the native hardware buffer, close the Java
  // Image and HardwareBuffer objects.
  jni_facade_->HardwareBufferClose(hardware_buffer_java);
  jni_facade_->ImageClose(image_java);

  return latest_hardware_buffer;
}

// Implementing flutter::ContextListener.
void HardwareBufferExternalTexture::OnGrContextDestroyed() {
  if (state_ == AttachmentState::kAttached) {
    dl_image_.reset();
    Detach();
  }
  state_ = AttachmentState::kDetached;
}

}  // namespace flutter
