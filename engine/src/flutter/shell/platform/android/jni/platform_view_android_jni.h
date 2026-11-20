// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_JNI_PLATFORM_VIEW_ANDROID_JNI_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_JNI_PLATFORM_VIEW_ANDROID_JNI_H_

#include <atomic>
#include <cstdint>
#include <functional>
#include <type_traits>
#include <utility>

#include "flutter/fml/mapping.h"

#include "flutter/flow/embedded_views.h"
#include "flutter/lib/ui/window/platform_message.h"
#include "flutter/shell/platform/android/surface/android_native_window.h"

#if FML_OS_ANDROID
#include "flutter/fml/platform/android/scoped_java_ref.h"
#endif

struct ASurfaceTransaction;

namespace flutter {

#if FML_OS_ANDROID
using JavaLocalRef = fml::jni::ScopedJavaLocalRef<jobject>;
#else
using JavaLocalRef = std::nullptr_t;
#endif

//------------------------------------------------------------------------------
/// Move-only RAII wrapper for cross-thread JNI global references used by
/// Hybrid Composition Frame Packets (`HybridImageReader` and `Image`).
///
/// Copy construction and copy assignment are deleted on all platforms so
/// ownership of a `HybridImageReader` or `Image` reference can never be
/// duplicated accidentally across threads. Move operations transfer ownership
/// in O(1) without invoking JNI and zero out the moved-from instance.
///
class HybridJavaGlobalRef {
 public:
  HybridJavaGlobalRef() noexcept = default;

#if FML_OS_ANDROID
  HybridJavaGlobalRef(JNIEnv* env, jobject local_or_global_obj);

  jobject obj() const noexcept { return global_ref_; }
#endif

  /// Creates a synthetic non-JNI handle for host unit tests (or native tests
  /// mocking `PlatformViewAndroidJNI` without a live JVM).
  static HybridJavaGlobalRef ForTest(intptr_t token) noexcept {
    HybridJavaGlobalRef ref;
    ref.token_ = token;
    return ref;
  }

  ~HybridJavaGlobalRef() { Reset(); }

  HybridJavaGlobalRef(const HybridJavaGlobalRef&) = delete;
  HybridJavaGlobalRef& operator=(const HybridJavaGlobalRef&) = delete;

  HybridJavaGlobalRef(HybridJavaGlobalRef&& other) noexcept
      :
#if FML_OS_ANDROID
        global_ref_(std::exchange(other.global_ref_, nullptr)),
#endif
        token_(std::exchange(other.token_, 0)) {
  }

  HybridJavaGlobalRef& operator=(HybridJavaGlobalRef&& other) noexcept {
    if (this != &other) {
      Reset();
#if FML_OS_ANDROID
      global_ref_ = std::exchange(other.global_ref_, nullptr);
#endif
      token_ = std::exchange(other.token_, 0);
    }
    return *this;
  }

  void Reset() noexcept;

  bool is_null() const noexcept {
#if FML_OS_ANDROID
    return global_ref_ == nullptr && token_ == 0;
#else
    return token_ == 0;
#endif
  }

  explicit operator bool() const noexcept { return !is_null(); }

  intptr_t token() const noexcept {
#if FML_OS_ANDROID
    return global_ref_ != nullptr ? reinterpret_cast<intptr_t>(global_ref_)
                                  : token_;
#else
    return token_;
#endif
  }

 private:
#if FML_OS_ANDROID
  jobject global_ref_ = nullptr;
#endif
  intptr_t token_ = 0;
};

static_assert(!std::is_copy_constructible_v<HybridJavaGlobalRef>);
static_assert(!std::is_copy_assignable_v<HybridJavaGlobalRef>);
static_assert(std::is_nothrow_move_constructible_v<HybridJavaGlobalRef>);
static_assert(std::is_nothrow_move_assignable_v<HybridJavaGlobalRef>);

//------------------------------------------------------------------------------
/// Cross-thread atomic state coordinating Java `PlatformViewsController`,
/// `PlatformViewAndroid`, `DeferredRootSurface`, and
/// `AndroidExternalViewEmbedder`.
///
struct HybridCompositionState {
  /// True while at least one Classic Hybrid Composition `PlatformView` is
  /// registered in Java `PlatformViewsController`. Written on the platform
  /// thread, read on the raster thread.
  std::atomic<bool> hc_views_alive{false};

  /// Mirrors `PlatformViewsController.synchronizeToNativeViewHierarchy`.
  /// Written on the platform thread, read on the raster thread.
  std::atomic<bool> synchronize_to_native_view_hierarchy{true};

  /// True when the root `FlutterSurfaceView` renders transparently
  /// (`setZOrderOnTop(true)`). Written on the platform thread, read on the
  /// raster thread.
  std::atomic<bool> root_surface_transparent{false};

  /// True while `AndroidExternalViewEmbedder` has an active Frame-Packet
  /// Hybrid Composition session. Mutated only on the raster thread; read
  /// atomically on both raster and platform threads.
  std::atomic<bool> hc_session_active{false};

  /// Monotonic fencing counter incremented on `OnPreEngineRestart`,
  /// `NotifyDestroyed`, and `Teardown` so `Drain` deterministically discards
  /// pre-teardown packets.
  std::atomic<uint64_t> hc_epoch{0};

  bool ShouldDeferRootSurface() const noexcept {
    return hc_views_alive.load(std::memory_order_acquire) ||
           hc_session_active.load(std::memory_order_acquire);
  }
};

//------------------------------------------------------------------------------
/// Allows to call Java code running in the JVM from any thread. However, most
/// methods can only be called from the platform thread as that is where the
/// Java code runs.
///
/// This interface must not depend on the Android toolchain directly, so it can
/// be used in unit tests compiled with the host toolchain.
///
class PlatformViewAndroidJNI {
 public:
  virtual ~PlatformViewAndroidJNI();

  //----------------------------------------------------------------------------
  /// @brief      Sends a platform message. The message may be empty.
  ///
  virtual void FlutterViewHandlePlatformMessage(
      std::unique_ptr<flutter::PlatformMessage> message,
      int responseId) = 0;

  //----------------------------------------------------------------------------
  /// @brief      Responds to a platform message. The data may be a `nullptr`.
  ///
  virtual void FlutterViewHandlePlatformMessageResponse(
      int responseId,
      std::unique_ptr<fml::Mapping> data) = 0;

  //----------------------------------------------------------------------------
  /// @brief      Sends semantics tree updates.
  ///
  /// @note       Must be called from the platform thread.
  ///
  virtual void FlutterViewUpdateSemantics(
      std::vector<uint8_t> buffer,
      std::vector<std::string> strings,
      std::vector<std::vector<uint8_t>> string_attribute_args) = 0;

  //----------------------------------------------------------------------------
  /// @brief      Set application locale to a given language.
  ///
  /// @note       Must be called from the platform thread.
  ///
  virtual void FlutterViewSetApplicationLocale(std::string locale) = 0;

  //----------------------------------------------------------------------------
  /// @brief      Enables or disables the semantics tree.
  ///
  /// @note       Must be called from the platform thread.
  ///
  virtual void FlutterViewSetSemanticsTreeEnabled(bool enabled) = 0;

  //----------------------------------------------------------------------------
  /// @brief      Sends new custom accessibility events.
  ///
  /// @note       Must be called from the platform thread.
  ///
  virtual void FlutterViewUpdateCustomAccessibilityActions(
      std::vector<uint8_t> actions_buffer,
      std::vector<std::string> strings) = 0;

  //----------------------------------------------------------------------------
  /// @brief      Indicates that FlutterView should start painting pixels.
  ///
  /// @note       Must be called from the platform thread.
  ///
  virtual void FlutterViewOnFirstFrame() = 0;

  //----------------------------------------------------------------------------
  /// @brief      Indicates that a hot restart is about to happen.
  ///
  virtual void FlutterViewOnPreEngineRestart() = 0;

  //----------------------------------------------------------------------------
  /// @brief      Attach the SurfaceTexture to the OpenGL ES context that is
  ///             current on the calling thread.
  ///
  virtual void SurfaceTextureAttachToGLContext(JavaLocalRef surface_texture,
                                               int textureId) = 0;

  //----------------------------------------------------------------------------
  /// @brief      Returns true if surface_texture should be updated.
  ///
  virtual bool SurfaceTextureShouldUpdate(JavaLocalRef surface_texture) = 0;

  //----------------------------------------------------------------------------
  /// @brief      Updates the texture image to the most recent frame from the
  ///             image stream.
  ///
  virtual void SurfaceTextureUpdateTexImage(JavaLocalRef surface_texture) = 0;

  //----------------------------------------------------------------------------
  /// @brief      Gets the transform matrix from the SurfaceTexture.
  ///             Then, it updates the `transform` matrix, so it fill the canvas
  ///             and preserve the aspect ratio.
  ///
  virtual SkM44 SurfaceTextureGetTransformMatrix(
      JavaLocalRef surface_texture) = 0;

  //----------------------------------------------------------------------------
  /// @brief      Detaches a SurfaceTexture from the OpenGL ES context.
  ///
  virtual void SurfaceTextureDetachFromGLContext(
      JavaLocalRef surface_texture) = 0;

  //----------------------------------------------------------------------------
  /// @brief      Acquire the latest image available.
  ///
  virtual JavaLocalRef ImageProducerTextureEntryAcquireLatestImage(
      JavaLocalRef image_texture_entry) = 0;

  //----------------------------------------------------------------------------
  /// @brief      Grab the HardwareBuffer from image.
  ///
  virtual JavaLocalRef ImageGetHardwareBuffer(JavaLocalRef image) = 0;

  //----------------------------------------------------------------------------
  /// @brief      Call close on image.
  ///
  virtual void ImageClose(JavaLocalRef image) = 0;

  //----------------------------------------------------------------------------
  /// @brief      Call close on hardware_buffer.
  ///
  virtual void HardwareBufferClose(JavaLocalRef hardware_buffer) = 0;

  //----------------------------------------------------------------------------
  /// @brief      Positions and sizes a platform view if using hybrid
  ///             composition.
  ///
  /// @note       Must be called from the platform thread.
  ///
  virtual void FlutterViewOnDisplayPlatformView(
      int view_id,
      int x,
      int y,
      int width,
      int height,
      int viewWidth,
      int viewHeight,
      MutatorsStack mutators_stack) = 0;

  //----------------------------------------------------------------------------
  /// @brief      Positions and sizes an overlay surface in hybrid composition.
  ///
  /// @note       Must be called from the platform thread.
  ///
  virtual void FlutterViewDisplayOverlaySurface(int surface_id,
                                                int x,
                                                int y,
                                                int width,
                                                int height) = 0;

  //----------------------------------------------------------------------------
  /// @brief      Initiates a frame if using hybrid composition.
  ///
  ///
  /// @note       Must be called from the platform thread.
  ///
  virtual void FlutterViewBeginFrame() = 0;

  //----------------------------------------------------------------------------
  /// @brief      Indicates that the current frame ended.
  ///             It's used to clean up state.
  ///
  /// @note       Must be called from the platform thread.
  ///
  virtual void FlutterViewEndFrame() = 0;

  //------------------------------------------------------------------------------
  /// The metadata returned from Java which is converted into an |OverlayLayer|
  /// by |SurfacePool|.
  ///
  struct OverlayMetadata {
    OverlayMetadata(int id, fml::RefPtr<AndroidNativeWindow> window)
        : id(id), window(std::move(window)) {};

    ~OverlayMetadata() = default;

    // A unique id to identify the overlay when it gets recycled.
    const int id;

    // Holds a reference to the native window. That is, an `ANativeWindow`,
    // which is the C counterpart of the `android.view.Surface` object in Java.
    const fml::RefPtr<AndroidNativeWindow> window;
  };

  //----------------------------------------------------------------------------
  /// @brief      Instantiates an overlay surface in hybrid composition and
  ///             provides the necessary metadata to operate the surface in C.
  ///
  /// @note       Must be called from the platform thread.
  ///
  virtual std::unique_ptr<PlatformViewAndroidJNI::OverlayMetadata>
  FlutterViewCreateOverlaySurface() = 0;

  //----------------------------------------------------------------------------
  /// @brief      Destroys the overlay surfaces.
  ///
  /// @note       Must be called from the platform thread.
  ///
  virtual void FlutterViewDestroyOverlaySurfaces() = 0;

  //----------------------------------------------------------------------------
  /// Metadata returned when allocating a `HybridImageReader` for Frame-Packet
  /// Hybrid Composition.
  ///
  struct HybridImageReaderMetadata {
    HybridImageReaderMetadata(HybridJavaGlobalRef reader,
                              fml::RefPtr<AndroidNativeWindow> window)
        : reader(std::move(reader)), window(std::move(window)) {}

    ~HybridImageReaderMetadata() = default;

    HybridImageReaderMetadata(const HybridImageReaderMetadata&) = delete;
    HybridImageReaderMetadata& operator=(const HybridImageReaderMetadata&) =
        delete;
    HybridImageReaderMetadata(HybridImageReaderMetadata&&) noexcept = default;
    HybridImageReaderMetadata& operator=(HybridImageReaderMetadata&&) noexcept =
        default;

    HybridJavaGlobalRef reader;
    fml::RefPtr<AndroidNativeWindow> window;
  };

  //----------------------------------------------------------------------------
  /// @brief      Allocates a `HybridImageReader` directly via JNI without
  ///             touching `FlutterJNI` or `PlatformViewsController`.
  ///
  /// @note       Thread-safe; typically called from the raster thread.
  ///
  virtual std::unique_ptr<HybridImageReaderMetadata> CreateHybridImageReader(
      int32_t width,
      int32_t height) = 0;

  //----------------------------------------------------------------------------
  /// @brief      Acquires the latest `Image` from `reader` and awaits its GPU
  ///             `SyncFence` on API 33+.
  ///
  /// @note       Thread-safe; typically called from the raster thread.
  ///
  virtual HybridJavaGlobalRef AcquireLatestHybridImage(
      const HybridJavaGlobalRef& reader) = 0;

  //----------------------------------------------------------------------------
  /// @brief      Releases an `Image` previously acquired from `reader`.
  ///
  /// @note       Thread-safe; callable from either raster or platform thread.
  ///
  virtual void ReleaseHybridImage(const HybridJavaGlobalRef& reader,
                                  HybridJavaGlobalRef image) = 0;

  //----------------------------------------------------------------------------
  /// @brief      Retires `reader` so its `ImageReader` closes once all open
  ///             `Image` references have been released.
  ///
  /// @note       Thread-safe; typically called from the raster thread.
  ///
  virtual void RetireHybridImageReader(HybridJavaGlobalRef reader) = 0;

  //----------------------------------------------------------------------------
  /// @brief      Begins applying an immutable Hybrid Composition Frame Packet
  ///             on the platform thread, optionally displaying
  ///             `background_image`.
  ///
  /// @note       Must be called from the platform thread.
  ///
  virtual void FlutterViewBeginHybridFrame(
      HybridJavaGlobalRef background_image,
      const HybridJavaGlobalRef& background_reader) = 0;

  //----------------------------------------------------------------------------
  /// @brief      Positions and displays a Classic Hybrid Composition platform
  ///             view for the current Frame Packet without calling legacy
  ///             `convertToImageView()`.
  ///
  /// @note       Must be called from the platform thread.
  ///
  virtual void FlutterViewOnDisplayHybridPlatformView(
      int view_id,
      int x,
      int y,
      int width,
      int height,
      int viewWidth,
      int viewHeight,
      MutatorsStack mutators_stack) = 0;

  //----------------------------------------------------------------------------
  /// @brief      Positions and presents an overlay `Image` in a display-only
  ///             `PlatformOverlayView` for the current Frame Packet.
  ///
  /// @note       Must be called from the platform thread.
  ///
  virtual void FlutterViewDisplayHybridOverlaySurface(
      int surface_id,
      int x,
      int y,
      int width,
      int height,
      HybridJavaGlobalRef image,
      const HybridJavaGlobalRef& reader) = 0;

  //----------------------------------------------------------------------------
  /// @brief      Completes applying an immutable Hybrid Composition Frame
  ///             Packet on the platform thread.
  ///
  /// @note       Must be called from the platform thread.
  ///
  virtual void FlutterViewEndHybridFrame(
      bool is_exit_frame,
      bool remove_background_after_traversal) = 0;

  //----------------------------------------------------------------------------
  /// @brief      Releases displayed Hybrid Composition images and hides HC
  ///             views on the platform thread during teardown.
  ///
  /// @note       Must be called from the platform thread.
  ///
  virtual void FlutterViewTeardownHybridComposition() = 0;

  // New Platform View Support.

  //----------------------------------------------------------------------------
  /// @brief      Creates a transaction that is not yet visible to the platform
  ///             thread, along with a callback that publishes it once the
  ///             caller has finished writing into it.
  ///
  ///             The caller must invoke the publish callback only after its
  ///             last write into the transaction (for example, setting buffers
  ///             or completion callbacks). Until then the platform thread
  ///             cannot merge, apply, or close it, and the underlying Java
  ///             object is kept alive.
  ///
  /// @note       Must be called from the raster thread.
  ///
  /// @param[out] out_publish_callback  Receives the callback that publishes
  ///                                   the transaction.
  ///
  /// @return     The native transaction, or null if one could not be created.
  ///
  virtual ASurfaceTransaction* createTransaction(
      std::function<void()>& out_publish_callback) = 0;

  //----------------------------------------------------------------------------
  /// @brief      Seals the transactions published during the current raster
  ///             frame into a batch for the next `swapTransaction()` call.
  ///
  /// @note       Must be called from the raster thread.
  ///
  virtual void sealFrameTransactions() = 0;

  virtual void swapTransaction() = 0;

  virtual std::unique_ptr<PlatformViewAndroidJNI::OverlayMetadata>
  createOverlaySurface2() = 0;

  virtual void destroyOverlaySurface2() = 0;

  virtual void onEndFrame2() = 0;

  virtual void onDisplayPlatformView2(int32_t view_id,
                                      int32_t x,
                                      int32_t y,
                                      int32_t width,
                                      int32_t height,
                                      int32_t viewWidth,
                                      int32_t viewHeight,
                                      MutatorsStack mutators_stack) = 0;

  virtual void hidePlatformView2(int32_t view_id) = 0;

  virtual void showOverlaySurface2() = 0;

  virtual void hideOverlaySurface2() = 0;

  //----------------------------------------------------------------------------
  /// @brief      Computes the locale Android would select.
  ///
  virtual std::unique_ptr<std::vector<std::string>>
  FlutterViewComputePlatformResolvedLocale(
      std::vector<std::string> supported_locales_data) = 0;

  virtual double GetDisplayRefreshRate() = 0;

  virtual double GetDisplayWidth() = 0;

  virtual double GetDisplayHeight() = 0;

  virtual double GetDisplayDensity() = 0;

  virtual bool RequestDartDeferredLibrary(int loading_unit_id) = 0;

  virtual double FlutterViewGetScaledFontSize(double unscaled_font_size,
                                              int configuration_id) const = 0;

  virtual void MaybeResizeSurfaceView(int32_t width, int32_t height) const = 0;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_JNI_PLATFORM_VIEW_ANDROID_JNI_H_
