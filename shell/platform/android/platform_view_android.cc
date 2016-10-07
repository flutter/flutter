// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/platform_view_android.h"

#include <android/native_window.h>
#include <android/native_window_jni.h>
#include <sys/resource.h>
#include <sys/time.h>
#include <sys/types.h>
#include <memory>
#include <utility>
#include "base/android/jni_android.h"
#include "base/android/jni_string.h"
#include "base/bind.h"
#include "base/location.h"
#include "base/trace_event/trace_event.h"
#include "flutter/common/threads.h"
#include "flutter/flow/compositor_context.h"
#include "flutter/runtime/dart_service_isolate.h"
#include "flutter/shell/common/engine.h"
#include "flutter/shell/common/shell.h"
#include "flutter/shell/gpu/gpu_rasterizer.h"
#include "jni/FlutterView_jni.h"
#include "lib/ftl/functional/wrap_lambda.h"
#include "third_party/skia/include/core/SkSurface.h"

namespace shell {

PlatformViewAndroid::PlatformViewAndroid()
    : PlatformView(std::make_unique<GPURasterizer>()), weak_factory_(this) {}

PlatformViewAndroid::~PlatformViewAndroid() = default;

void PlatformViewAndroid::Detach(JNIEnv* env, jobject obj) {
  ReleaseSurface();
  delete this;
}

void PlatformViewAndroid::SurfaceCreated(JNIEnv* env,
                                         jobject obj,
                                         jobject jsurface) {
  // Note: This frame ensures that any local references used by
  // ANativeWindow_fromSurface are released immediately. This is needed as a
  // workaround for https://code.google.com/p/android/issues/detail?id=68174
  base::android::ScopedJavaLocalFrame scoped_local_reference_frame(env);
  ANativeWindow* window = ANativeWindow_fromSurface(env, jsurface);

  // Use the default onscreen configuration.
  PlatformView::SurfaceConfig onscreen_config;

  // The offscreen config is the same as the default except we know we don't
  // need the stencil buffer.
  PlatformView::SurfaceConfig offscreen_config;
  offscreen_config.stencil_bits = 0;

  auto surface = std::make_unique<AndroidSurfaceGL>(window, onscreen_config,
                                                    offscreen_config);

  if (surface->IsValid()) {
    surface_gl_ = std::move(surface);
  } else {
    LOG(INFO) << "Could not create the OpenGL Android Surface.";
  }

  ANativeWindow_release(window);
}

void PlatformViewAndroid::SurfaceChanged(JNIEnv* env,
                                         jobject obj,
                                         jint backgroundColor) {
  if (!surface_gl_) {
    return;
  }

  auto surface = std::make_unique<GPUSurfaceGL>(surface_gl_.get());
  NotifyCreated(std::move(surface), [this, backgroundColor] {
    rasterizer().Clear(backgroundColor, GetSize());
  });
  SetupResourceContextOnIOThread();
  UpdateThreadPriorities();
}

void PlatformViewAndroid::UpdateThreadPriorities() {
  blink::Threads::Gpu()->PostTask(
      []() { ::setpriority(PRIO_PROCESS, gettid(), -2); });

  blink::Threads::UI()->PostTask(
      []() { ::setpriority(PRIO_PROCESS, gettid(), -1); });
}

void PlatformViewAndroid::SurfaceDestroyed(JNIEnv* env, jobject obj) {
  ReleaseSurface();
}

void PlatformViewAndroid::DispatchPointerDataPacket(JNIEnv* env,
                                                    jobject obj,
                                                    jobject buffer,
                                                    jint position) {
  char* data = static_cast<char*>(env->GetDirectBufferAddress(buffer));

  blink::Threads::UI()->PostTask(ftl::WrapLambda([
    engine = engine_->GetWeakPtr(),
    packet = std::make_unique<PointerDataPacket>(data, position)
  ] {
    if (engine.get())
      engine->DispatchPointerDataPacket(*packet);
  }));
}

void PlatformViewAndroid::InvokePlatformMessageResponseCallback(
    JNIEnv* env,
    jobject obj,
    jint response_id,
    jstring java_response) {
  if (!response_id)
    return;
  auto it = pending_messages_.find(response_id);
  if (it == pending_messages_.end())
    return;
  std::string response =
      base::android::ConvertJavaStringToUTF8(env, java_response);
  // TODO(abarth): There's an extra copy here.
  it->second->InvokeCallback(
      std::vector<char>(response.data(), response.data() + response.size()));
  pending_messages_.erase(it);
}

void PlatformViewAndroid::HandlePlatformMessage(
    ftl::RefPtr<blink::PlatformMessage> message) {
  JNIEnv* env = base::android::AttachCurrentThread();
  {
    base::android::ScopedJavaLocalRef<jobject> view = flutter_view_.get(env);
    if (view.is_null())
      return;

    int response_id = 0;
    if (message->has_callback()) {
      response_id = next_response_id_++;
      pending_messages_[response_id] = message;
    }

    base::StringPiece message_name = message->name();

    auto data = message->data();
    base::StringPiece message_data(data.data(), data.size());

    auto java_message_name =
        base::android::ConvertUTF8ToJavaString(env, message_name);
    auto java_message_data =
        base::android::ConvertUTF8ToJavaString(env, message_data);
    message->ClearData();

    // This call can re-enter in InvokePlatformMessageResponseCallback.
    Java_FlutterView_handlePlatformMessage(
        env, view.obj(), java_message_name.obj(), java_message_data.obj(),
        response_id);
  }
}

void PlatformViewAndroid::ReleaseSurface() {
  if (surface_gl_) {
    NotifyDestroyed();
    surface_gl_ = nullptr;
  }
}

ftl::WeakPtr<shell::PlatformView> PlatformViewAndroid::GetWeakViewPtr() {
  return weak_factory_.GetWeakPtr();
}

bool PlatformViewAndroid::ResourceContextMakeCurrent() {
  return surface_gl_ ? surface_gl_->GLOffscreenContextMakeCurrent() : false;
}

SkISize PlatformViewAndroid::GetSize() {
  return surface_gl_ ? surface_gl_->OnScreenSurfaceSize() : SkISize::Make(0, 0);
}

void PlatformViewAndroid::Resize(const SkISize& size) {
  if (surface_gl_) {
    surface_gl_->OnScreenSurfaceResize(size);
  }
}

void PlatformViewAndroid::RunFromSource(const std::string& main,
                                        const std::string& packages,
                                        const std::string& assets_directory) {
  FTL_CHECK(base::android::IsVMInitialized());
  JNIEnv* env = base::android::AttachCurrentThread();
  FTL_CHECK(env);

  {
    base::android::ScopedJavaLocalRef<jobject> local_flutter_view =
        flutter_view_.get(env);
    if (local_flutter_view.is_null()) {
      // Collected.
      return;
    }

    // Grab the class of the flutter view.
    jclass flutter_view_class = env->GetObjectClass(local_flutter_view.obj());
    FTL_CHECK(flutter_view_class);

    // Grab the runFromSource method id.
    jmethodID run_from_source_method_id = env->GetMethodID(
        flutter_view_class, "runFromSource",
        "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V");
    FTL_CHECK(run_from_source_method_id);

    // Invoke runFromSource on the Android UI thread.
    jstring java_main = env->NewStringUTF(main.c_str());
    FTL_CHECK(java_main);
    jstring java_packages = env->NewStringUTF(packages.c_str());
    FTL_CHECK(java_packages);
    jstring java_assets_directory = env->NewStringUTF(assets_directory.c_str());
    FTL_CHECK(java_assets_directory);
    env->CallVoidMethod(local_flutter_view.obj(), run_from_source_method_id,
                        java_main, java_packages, java_assets_directory);
  }

  // Detaching from the VM deletes any stray local references.
  base::android::DetachFromVM();
}

base::android::ScopedJavaLocalRef<jobject> PlatformViewAndroid::GetBitmap(
    JNIEnv* env,
    jobject obj) {
  // Render the last frame to an array of pixels on the GPU thread.
  // The pixels will be returned as a global JNI reference to an int array.
  ftl::AutoResetWaitableEvent latch;
  jobject pixels_ref = nullptr;
  SkISize frame_size;
  blink::Threads::Gpu()->PostTask([this, &latch, &pixels_ref, &frame_size]() {
    GetBitmapGpuTask(&latch, &pixels_ref, &frame_size);
  });

  latch.Wait();

  // Convert the pixel array to an Android bitmap.
  if (pixels_ref == nullptr)
    return base::android::ScopedJavaLocalRef<jobject>();

  base::android::ScopedJavaGlobalRef<jobject> pixels(env, pixels_ref);

  jclass bitmap_class = env->FindClass("android/graphics/Bitmap");
  FTL_CHECK(bitmap_class);

  jmethodID create_bitmap = env->GetStaticMethodID(
      bitmap_class, "createBitmap",
      "([IIILandroid/graphics/Bitmap$Config;)Landroid/graphics/Bitmap;");
  FTL_CHECK(create_bitmap);

  jclass bitmap_config_class = env->FindClass("android/graphics/Bitmap$Config");
  FTL_CHECK(bitmap_config_class);

  jmethodID bitmap_config_value_of = env->GetStaticMethodID(
      bitmap_config_class, "valueOf",
      "(Ljava/lang/String;)Landroid/graphics/Bitmap$Config;");
  FTL_CHECK(bitmap_config_value_of);

  jstring argb = env->NewStringUTF("ARGB_8888");
  FTL_CHECK(argb);

  jobject bitmap_config = env->CallStaticObjectMethod(
      bitmap_config_class, bitmap_config_value_of, argb);
  FTL_CHECK(bitmap_config);

  jobject bitmap = env->CallStaticObjectMethod(
      bitmap_class, create_bitmap, pixels.obj(), frame_size.width(),
      frame_size.height(), bitmap_config);

  return base::android::ScopedJavaLocalRef<jobject>(env, bitmap);
}

void PlatformViewAndroid::GetBitmapGpuTask(ftl::AutoResetWaitableEvent* latch,
                                           jobject* pixels_out,
                                           SkISize* size_out) {
  flow::LayerTree* layer_tree = rasterizer_->GetLastLayerTree();
  if (layer_tree == nullptr)
    return;

  JNIEnv* env = base::android::AttachCurrentThread();
  FTL_CHECK(env);

  const SkISize& frame_size = layer_tree->frame_size();
  jsize pixels_size = frame_size.width() * frame_size.height();
  jintArray pixels_array = env->NewIntArray(pixels_size);
  FTL_CHECK(pixels_array);

  jint* pixels = env->GetIntArrayElements(pixels_array, nullptr);
  FTL_CHECK(pixels);

  SkImageInfo image_info =
      SkImageInfo::Make(frame_size.width(), frame_size.height(),
                        kRGBA_8888_SkColorType, kPremul_SkAlphaType);

  sk_sp<SkSurface> surface = SkSurface::MakeRasterDirect(
      image_info, pixels, frame_size.width() * sizeof(jint));

  flow::CompositorContext compositor_context;
  SkCanvas* canvas = surface->getCanvas();
  flow::CompositorContext::ScopedFrame frame =
      compositor_context.AcquireFrame(nullptr, *canvas, false);

  canvas->clear(SK_ColorBLACK);
  layer_tree->Raster(frame);
  canvas->flush();

  // Our configuration of Skia does not support rendering to the
  // BitmapConfig.ARGB_8888 format expected by android.graphics.Bitmap.
  // Convert from kRGBA_8888 to kBGRA_8888 (equivalent to ARGB_8888).
  for (int i = 0; i < pixels_size; i++) {
    uint8_t* bytes = reinterpret_cast<uint8_t*>(pixels + i);
    std::swap(bytes[0], bytes[2]);
  }

  env->ReleaseIntArrayElements(pixels_array, pixels, 0);

  *pixels_out = env->NewGlobalRef(pixels_array);
  *size_out = frame_size;

  base::android::DetachFromVM();

  latch->Signal();
}

jint GetObservatoryPort(JNIEnv* env, jclass clazz) {
  return blink::DartServiceIsolate::GetObservatoryPort();
}

bool PlatformViewAndroid::Register(JNIEnv* env) {
  return RegisterNativesImpl(env);
}

static jlong Attach(JNIEnv* env,
                    jclass clazz,
                    jint skyEngineHandle,
                    jobject flutterView) {
  PlatformViewAndroid* view = new PlatformViewAndroid();
  view->ConnectToEngine(mojo::InterfaceRequest<sky::SkyEngine>(
      mojo::ScopedMessagePipeHandle(mojo::MessagePipeHandle(skyEngineHandle))));

  // Create a weak reference to the flutterView Java object so that we can make
  // calls into it later.
  view->set_flutter_view(JavaObjectWeakGlobalRef(env, flutterView));
  return reinterpret_cast<jlong>(view);
}

}  // namespace shell
