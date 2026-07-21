// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <array>
#include <memory>
#include <optional>
#include <sstream>

#include "fml/closure.h"
#include "fml/time/time_point.h"
#include "impeller/core/host_buffer.h"
#include "impeller/playground/image/backends/skia/compressed_image_skia.h"
#include "impeller/playground/image/decompressed_image.h"
#include "impeller/renderer/command_buffer.h"
#include "impeller/renderer/render_target.h"
#include "impeller/runtime_stage/runtime_stage.h"
#include "third_party/googletest/googletest/include/gtest/gtest.h"

#define GLFW_INCLUDE_NONE
#include "third_party/glfw/include/GLFW/glfw3.h"

#include "flutter/fml/paths.h"
#include "flutter/testing/test_swiftshader_utils.h"
#include "impeller/base/validation.h"
#include "impeller/core/allocator.h"
#include "impeller/core/formats.h"
#include "impeller/playground/image/compressed_image.h"
#include "impeller/playground/imgui/imgui_impl_impeller.h"
#include "impeller/playground/playground.h"
#include "impeller/playground/playground_impl.h"
#include "impeller/renderer/backend/gles/context_gles.h"
#include "impeller/renderer/context.h"
#include "impeller/renderer/render_pass.h"
#include "impeller/testing/golden_digest_manager.h"
#include "impeller/testing/screenshotter.h"
#include "impeller/typographer/backends/skia/typographer_context_skia.h"
#include "third_party/imgui/backends/imgui_impl_glfw.h"
#include "third_party/imgui/imgui.h"

#if FML_OS_MACOSX
#include "fml/platform/darwin/scoped_nsautorelease_pool.h"
#endif  // FML_OS_MACOSX

#if IMPELLER_ENABLE_VULKAN
#include "impeller/playground/backend/vulkan/playground_impl_vk.h"
#endif  // IMPELLER_ENABLE_VULKAN

namespace impeller {

namespace {
std::string GetTestName() {
  std::string suite_name =
      ::testing::UnitTest::GetInstance()->current_test_suite()->name();
  std::string test_name =
      ::testing::UnitTest::GetInstance()->current_test_info()->name();
  std::stringstream ss;
  ss << "impeller_" << suite_name << "_" << test_name;
  std::string result = ss.str();
  // Make sure there are no slashes in the test name.
  std::replace(result.begin(), result.end(), '/', '_');
  return result;
}

std::string GetGoldenFilename(const std::string& postfix = "") {
  return GetTestName() + postfix + ".png";
}
}  // namespace

std::string PlaygroundBackendToString(PlaygroundBackend backend) {
  switch (backend) {
    case PlaygroundBackend::kMetal:
      return "Metal";
    case PlaygroundBackend::kMetalSDF:
      return "MetalSDF";
    case PlaygroundBackend::kOpenGLES:
      return "OpenGLES";
    case PlaygroundBackend::kOpenGLESSDF:
      return "OpenGLESSDF";
    case PlaygroundBackend::kVulkan:
      return "Vulkan";
  }
  FML_UNREACHABLE();
}

std::atomic<bool> Playground::glfw_initialized_ = false;

void Playground::InitializeGLFWOnce() {
  // This guard is a hack to work around a problem where glfwCreateWindow
  // hangs when opening a second window after GLFW has been reinitialized (for
  // example, when flipping through multiple playground tests).
  //
  // Explanation:
  //  * glfwCreateWindow calls [NSApp run], which begins running the event
  //    loop on the current thread.
  //  * GLFW then immediately stops the loop when
  //    applicationDidFinishLaunching is fired.
  //  * applicationDidFinishLaunching is only ever fired once during the
  //    application's lifetime, so subsequent calls to [NSApp run] will always
  //    hang with this setup.
  //  * glfwInit resets the flag that guards against [NSApp run] being
  //    called a second time, which causes the subsequent `glfwCreateWindow`
  //    to hang indefinitely in the event loop, because
  //    applicationDidFinishLaunching is never fired.
  static std::once_flag sOnceInitializer;
  std::call_once(sOnceInitializer, []() {
    ::glfwSetErrorCallback([](int code, const char* description) {
      FML_LOG(ERROR) << "GLFW Error '" << description << "'  (" << code << ").";
    });
    FML_CHECK(::glfwInit() == GLFW_TRUE);
    glfw_initialized_ = true;
  });
}

void Playground::OnTearDownTestEnvironment() {
  if (glfw_initialized_) {
    ::glfwTerminate();
  }
}

testing::GoldenDigestManager* Playground::GetGoldenDigestManager() const {
  return nullptr;
}

Playground::Playground(PlaygroundBackend backend,
                       const PlaygroundSwitches& switches)
    : backend_(backend), switches_(switches) {
  InitializeGLFWOnce();
  flutter::testing::SetupSwiftshaderOnce(switches_.use_swiftshader);
}

Playground::~Playground() = default;

void Playground::EnsureContextIsUnique() {
  FML_CHECK(!context_) << "Must be called before a context is created.";
  switches_.can_share_context = false;
}

bool Playground::PlatformSupportsWideGamutTests() const {
#if __arm64__ && FML_OS_MACOSX
  switch (backend_) {
    case PlaygroundBackend::kMetal:
    case PlaygroundBackend::kMetalSDF:
      return true;
    case PlaygroundBackend::kOpenGLES:
    case PlaygroundBackend::kOpenGLESSDF:
    case PlaygroundBackend::kVulkan:
      return false;
  }
#else
  return false;
#endif
}

bool Playground::RenderingSupportsMSAA() const {
  // We could call GetContext(), but we don't want to cause it to be
  // created just yet. So, we make some assumptions here. If they are
  // insufficient then we should beef them up rather than just calling
  // GetContext() if we can.
  // Also, technically, we should check if it supports OffscreenMSAA
  // which might be a subset of supporting MSAA on screen, but for now
  // they seem to be closely related.
  switch (backend_) {
    case PlaygroundBackend::kMetal:
    case PlaygroundBackend::kMetalSDF:
      return true;
    case PlaygroundBackend::kOpenGLES:
    case PlaygroundBackend::kOpenGLESSDF:
      return false;
    case PlaygroundBackend::kVulkan:
      return true;
  }
}

SampleCount Playground::GetDefaultSampleCount() const {
  return RenderingSupportsMSAA() ? SampleCount::kCount4 : SampleCount::kCount1;
}

bool Playground::InitializePipelineDescriptorForRendering(
    PipelineDescriptor& desc) const {
  // Match the golden/verification harness render target:
  // - msaa or single samples depending on the Context
  // - depth and stencil formats from the Context
  std::shared_ptr<Context> context = GetContext();
  if (!context) {
    return false;
  }

  desc.SetSampleCount(GetDefaultSampleCount());
  auto depth_stencil_format =
      context->GetCapabilities()->GetDefaultDepthStencilFormat();
  if (depth_stencil_format != PixelFormat::kUnknown) {
    desc.SetDepthPixelFormat(depth_stencil_format);
    desc.SetStencilPixelFormat(depth_stencil_format);
    desc.SetDepthStencilAttachmentDescriptor(DepthAttachmentDescriptor{});
    desc.SetStencilAttachmentDescriptors(StencilAttachmentDescriptor{});
  } else {
    desc.ClearStencilAttachments();
    desc.ClearDepthAttachment();
  }
  return true;
}

bool Playground::EnsureContextSupportsWideGamut() {
  FML_CHECK(!context_) << "Must be called before a context is created.";
  if (!PlatformSupportsWideGamutTests()) {
    return false;
  }
  switches_.enable_wide_gamut = true;
  return true;
}

bool Playground::EnsureContextSupportsAntialiasLines() {
  FML_CHECK(!context_) << "Must be called before a context is created.";
  switches_.flags.antialiased_lines = true;
  return true;
}

std::shared_ptr<Context> Playground::GetContext() const {
  if (!context_) {
    SetupContext();
  }
  return context_;
}

std::shared_ptr<Context> Playground::MakeContext() const {
  // This method is used to get a unique context that is not shared with
  // other playground tests. It requires that the test has called the
  // |EnsureContextIsUnique| method before it calls this method. We
  // verify those conditions here and then set up the context.
  FML_CHECK(!context_) << "MakeContext can only be called once";
  FML_CHECK(!switches_.can_share_context)
      << "MakeContext should only be called after EnsureContextIsUnique()";
  SetupContext();

  return context_;
}

ContentContext& Playground::GetContentContext() const {
  if (!content_context_) {
    content_context_ =
        std::make_unique<ContentContext>(GetContext(), GetTypographerContext());
    FML_CHECK(content_context_) << "Failed to create ContentContext";
  }
  return *content_context_;
}

std::shared_ptr<TypographerContext> Playground::GetTypographerContext() const {
  if (!typographer_context_) {
    typographer_context_ = TypographerContextSkia::Make();
  }
  return typographer_context_;
}

void Playground::SetTypographerContext(
    std::shared_ptr<TypographerContext> typographer_context) {
  FML_CHECK(!typographer_context_)
      << "SetTypographerContext called after it has already been initialized";
  typographer_context_ = std::move(typographer_context);
}

bool Playground::SupportsBackend(PlaygroundBackend backend) {
  switch (backend) {
    case PlaygroundBackend::kMetal:
    case PlaygroundBackend::kMetalSDF:
#if IMPELLER_ENABLE_METAL
      return true;
#else   // IMPELLER_ENABLE_METAL
      return false;
#endif  // IMPELLER_ENABLE_METAL
    case PlaygroundBackend::kOpenGLES:
    case PlaygroundBackend::kOpenGLESSDF:
#if IMPELLER_ENABLE_OPENGLES
      return true;
#else   // IMPELLER_ENABLE_OPENGLES
      return false;
#endif  // IMPELLER_ENABLE_OPENGLES
    case PlaygroundBackend::kVulkan:
#if IMPELLER_ENABLE_VULKAN
      return PlaygroundImplVK::IsVulkanDriverPresent();
#else   // IMPELLER_ENABLE_VULKAN
      return false;
#endif  // IMPELLER_ENABLE_VULKAN
  }
  FML_UNREACHABLE();
}

bool Playground::IsBackendEnabled(PlaygroundBackend backend) const {
  if (!SupportsBackend(backend)) {
    return false;
  }
  switch (backend) {
    case PlaygroundBackend::kMetal:
      return switches_.backends_enabled.metal;
    case PlaygroundBackend::kMetalSDF:
      return switches_.backends_enabled.metal_sdf;
    case PlaygroundBackend::kOpenGLES:
      return switches_.backends_enabled.opengles;
    case PlaygroundBackend::kOpenGLESSDF:
      return switches_.backends_enabled.opengles_sdf;
    case PlaygroundBackend::kVulkan:
      return switches_.backends_enabled.vulkan;
  }
  FML_UNREACHABLE();
}

std::unique_ptr<PlaygroundImpl>& Playground::GetImpl() const {
  if (!impl_) {
    SetupContext();
  }
  FML_CHECK(impl_);
  return impl_;
}

void Playground::SetupContext() const {
  FML_CHECK(SupportsBackend(backend_));

  impl_ = PlaygroundImpl::Create(backend_, switches_);
  if (!impl_) {
    FML_LOG(WARNING) << "PlaygroundImpl::Create failed.";
    return;
  }

  context_ = impl_->GetContext();
}

void Playground::SetupWindow() {
  if (!context_) {
    FML_LOG(WARNING) << "Asked to set up a window with no context (call "
                        "SetupContext first).";
    return;
  }
  start_time_ = fml::TimePoint::Now().ToEpochDelta();
}

bool Playground::IsPlaygroundEnabled() const {
  return switches_.outputs_enabled.window;
}

void Playground::TearDownContextData() {
  if (content_context_) {
    FML_CHECK(context_);
    [[maybe_unused]] auto result = context_->FlushCommandBuffers();
    content_context_.reset();
  }
  if (host_buffer_) {
    host_buffer_.reset();
  }
  if (context_) {
    context_->Shutdown();
  }
  context_.reset();
  impl_.reset();
}

static std::atomic_bool gShouldOpenNewPlaygrounds = true;

bool Playground::ShouldOpenNewPlaygrounds() {
  return gShouldOpenNewPlaygrounds;
}

static void PlaygroundKeyCallback(GLFWwindow* window,
                                  int key,
                                  int scancode,
                                  int action,
                                  int mods) {
  if ((key == GLFW_KEY_ESCAPE) && action == GLFW_RELEASE) {
    if (mods & (GLFW_MOD_CONTROL | GLFW_MOD_SUPER | GLFW_MOD_SHIFT)) {
      gShouldOpenNewPlaygrounds = false;
    }
    ::glfwSetWindowShouldClose(window, GLFW_TRUE);
  }
}

Point Playground::GetCursorPosition() const {
  return cursor_position_;
}

ISize Playground::GetWindowSize() const {
  return window_size_;
}

IRect Playground::GetWindowBounds() const {
  return IRect::MakeSize(window_size_);
}

Point Playground::GetContentScale() const {
  return GetImpl()->GetContentScale();
}

Scalar Playground::GetSecondsElapsed() const {
  return (fml::TimePoint::Now().ToEpochDelta() - start_time_).ToSecondsF();
}

void Playground::SetCursorPosition(Point pos) {
  cursor_position_ = pos;
}

bool Playground::ShouldWriteGoldenImage() {
  return should_write_golden_;
}

void Playground::SetEnableWriteGolden(bool write_golden) {
  should_write_golden_ = write_golden;
}

bool Playground::RenderImage(const RenderCallback& callback,
                             bool is_onscreen,
                             bool write_result) {
  std::shared_ptr<Context> context = GetContext();
  if (!context) {
    return false;
  }

  AiksContext renderer(context, typographer_context_);
  Point content_scale = GetContentScale();
  ISize size(std::round(GetWindowSize().width * content_scale.x),
             std::round(GetWindowSize().height * content_scale.y));

  std::unique_ptr<Surface> surface;
  RenderTarget render_target;
  if (is_onscreen) {
    surface = GetImpl()->AcquireSurfaceFrame(context);
    if (!surface) {
      return false;
    }
    render_target = surface->GetRenderTarget();
  } else {
    RenderTargetAllocator render_target_allocator(
        context->GetResourceAllocator());
    std::string label =
        write_result ? "Golden Render Pass" : "Playground Verification Pass";
    if (context->GetCapabilities()->SupportsOffscreenMSAA()) {
      render_target = render_target_allocator.CreateOffscreenMSAA(
          *context, size, /*mip_count=*/1, label + " (MSAA)",
          RenderTarget::kDefaultColorAttachmentConfigMSAA);
    } else {
      render_target = render_target_allocator.CreateOffscreen(
          *context, size, /*mip_count=*/1, label,
          RenderTarget::kDefaultColorAttachmentConfig);
    }
  }
  if (!render_target.IsValid()) {
    return false;
  }
  if (!callback(render_target, is_onscreen)) {
    return false;
  }
  if (is_onscreen && !surface->Present()) {
    return false;
  }
  if (write_result && !WriteGoldenImage(render_target)) {
    return false;
  }
  return true;
}

bool Playground::WriteGoldenImage(const RenderTarget& render_target,
                                  const std::string& postfix) {
  testing::GoldenDigestManager* digest = GetGoldenDigestManager();
  if (!digest) {
    FML_LOG(ERROR) << "Golden image has no working directory";
    return false;
  }

  std::shared_ptr<Context> context = GetContext();
  if (!context) {
    return false;
  }

  digest->AddDimension("gpu_string", context->DescribeGpuModel());

  std::string test_name = GetTestName();

  std::unique_ptr<testing::Screenshot> screenshot =
      testing::Screenshotter::MakeScreenshot(
          context, render_target.GetRenderTargetTexture());
  if (!screenshot || !screenshot->GetBytes()) {
    FML_LOG(ERROR) << "Failed to collect screenshot for test " << test_name;
    return false;
  }

  std::string filename = GetGoldenFilename(postfix);
  std::string filenamepath = digest->GetFullPath(filename);
  if (!screenshot->WriteToPNG(filenamepath)) {
    FML_LOG(ERROR) << "Failed to write screenshot to " << filenamepath;
    return false;
  }
  digest->AddImage(test_name, filename,  //
                   screenshot->GetWidth(), screenshot->GetHeight());

  return true;
}

bool Playground::OpenPlaygroundHere(
    const Playground::RenderCallback& render_callback) {
  std::shared_ptr<Context> context = GetContext();
  FML_CHECK(context);

  if (!render_callback) {
    return true;
  }

  auto window = reinterpret_cast<GLFWwindow*>(impl_->GetWindowHandle());
  if (!window) {
    return false;
  }
  ::glfwSetWindowSize(window, GetWindowSize().width, GetWindowSize().height);

  bool writing_golden = switches_.outputs_enabled.golden &&
                        GetGoldenDigestManager() && should_write_golden_;
  if (switches_.outputs_enabled.offscreen ||
      switches_.outputs_enabled.onscreen || writing_golden) {
    if (switches_.outputs_enabled.offscreen ||
        switches_.outputs_enabled.golden) {
      // For golden output, this is the first pass rendering so that the
      // second pass observes warmed pipeline and resource caches.
      if (!RenderImage(render_callback, /*is_onscreen=*/false,
                       /*write_image=*/false)) {
        return false;
      }
    }
    if (switches_.outputs_enabled.onscreen) {
      if (!RenderImage(render_callback, /*is_onscreen=*/true,
                       /*write_image=*/false)) {
        return false;
      }
    }
    if (writing_golden) {
      // The output should have also been rendered above in the offscreen
      // step so that this second pass observes warmed pipeline and resource
      // caches.
      if (!RenderImage(render_callback, /*is_onscreen=*/false,
                       /*write_image=*/true)) {
        return false;
      }
    }
  }
  if (!switches_.outputs_enabled.window) {
    return true;
  }

  IMGUI_CHECKVERSION();
  ImGui::CreateContext();
  fml::ScopedCleanupClosure destroy_imgui_context(
      []() { ImGui::DestroyContext(); });
  ImGui::StyleColorsDark();

  auto& io = ImGui::GetIO();
  io.IniFilename = nullptr;
  io.ConfigFlags |= ImGuiConfigFlags_DockingEnable;
  io.ConfigWindowsResizeFromEdges = true;

  ::glfwSetWindowTitle(window, GetWindowTitle().c_str());
  ::glfwSetWindowUserPointer(window, this);
  ::glfwSetWindowSizeCallback(
      window, [](GLFWwindow* window, int width, int height) -> void {
        auto playground =
            reinterpret_cast<Playground*>(::glfwGetWindowUserPointer(window));
        if (!playground) {
          return;
        }
        playground->SetWindowSize(ISize{width, height}.Max({}));
      });
  ::glfwSetKeyCallback(window, &PlaygroundKeyCallback);
  ::glfwSetCursorPosCallback(window, [](GLFWwindow* window, double x,
                                        double y) {
    reinterpret_cast<Playground*>(::glfwGetWindowUserPointer(window))
        ->SetCursorPosition({static_cast<Scalar>(x), static_cast<Scalar>(y)});
  });

  ImGui_ImplGlfw_InitForOther(window, true);
  fml::ScopedCleanupClosure shutdown_imgui([]() { ImGui_ImplGlfw_Shutdown(); });

  ImGui_ImplImpeller_Init(context);
  fml::ScopedCleanupClosure shutdown_imgui_impeller(
      []() { ImGui_ImplImpeller_Shutdown(); });

  ImGui::SetNextWindowPos({10, 10});

  ::glfwSetWindowPos(window, 200, 100);
  ::glfwShowWindow(window);

  while (true) {
#if FML_OS_MACOSX
    fml::ScopedNSAutoreleasePool pool;
#endif
    ::glfwPollEvents();

    if (::glfwWindowShouldClose(window)) {
      return true;
    }

    ImGui_ImplGlfw_NewFrame();

    auto surface = GetImpl()->AcquireSurfaceFrame(context);
    RenderTarget render_target = surface->GetRenderTarget();

    ImGui::NewFrame();
    ImGui::DockSpaceOverViewport(0, ImGui::GetMainViewport(),
                                 ImGuiDockNodeFlags_PassthruCentralNode);
    bool result = render_callback(render_target, true);
    ImGui::Render();

    // Render ImGui overlay.
    {
      auto buffer = context->CreateCommandBuffer();
      if (!buffer) {
        VALIDATION_LOG << "Could not create command buffer.";
        return false;
      }
      buffer->SetLabel("ImGui Command Buffer");

      auto color0 = render_target.GetColorAttachment(0);
      color0.load_action = LoadAction::kLoad;
      if (color0.resolve_texture) {
        color0.texture = color0.resolve_texture;
        color0.resolve_texture = nullptr;
        color0.store_action = StoreAction::kStore;
      }
      render_target.SetColorAttachment(color0, 0);
      render_target.SetStencilAttachment(std::nullopt);
      render_target.SetDepthAttachment(std::nullopt);

      auto pass = buffer->CreateRenderPass(render_target);
      if (!pass) {
        VALIDATION_LOG << "Could not create render pass.";
        return false;
      }
      pass->SetLabel("ImGui Render Pass");
      if (!host_buffer_) {
        host_buffer_ = HostBuffer::Create(
            context->GetResourceAllocator(), context->GetIdleWaiter(),
            context->GetCapabilities()->GetMinimumUniformAlignment());
      }

      ImGui_ImplImpeller_RenderDrawData(ImGui::GetDrawData(), *pass,
                                        *host_buffer_);

      pass->EncodeCommands();

      if (!context->SubmitOnscreen(std::move(buffer))) {
        return false;
      }
    }

    if (!result || !surface->Present()) {
      return false;
    }

    if (!ShouldKeepRendering()) {
      break;
    }
  }

  ::glfwHideWindow(window);

  return true;
}

bool Playground::OpenPlaygroundHere(const SinglePassCallback& pass_callback) {
  return OpenPlaygroundHere(  //
      [context = GetContext(), &pass_callback](RenderTarget& render_target,
                                               bool is_onscreen) {
        auto buffer = context->CreateCommandBuffer();
        if (!buffer) {
          return false;
        }
        buffer->SetLabel("Playground Command Buffer");

        auto pass = buffer->CreateRenderPass(render_target);
        if (!pass) {
          return false;
        }
        pass->SetLabel("Playground Render Pass");

        if (!pass_callback(*pass)) {
          return false;
        }

        pass->EncodeCommands();

        if (is_onscreen) {
          if (!context->SubmitOnscreen(std::move(buffer))) {
            return false;
          }
        } else {
          if (!context->EnqueueCommandBuffer(std::move(buffer))) {
            return false;
          }
        }

        if (!context->FlushCommandBuffers()) {
          return false;
        }

        return true;
      });
}

std::shared_ptr<CompressedImage> Playground::LoadFixtureImageCompressed(
    std::shared_ptr<fml::Mapping> mapping) {
  auto compressed_image = CompressedImageSkia::Create(std::move(mapping));
  if (!compressed_image) {
    VALIDATION_LOG << "Could not create compressed image.";
    return nullptr;
  }

  return compressed_image;
}

std::optional<DecompressedImage> Playground::DecodeImageRGBA(
    const std::shared_ptr<CompressedImage>& compressed) {
  if (compressed == nullptr) {
    return std::nullopt;
  }
  // The decoded image is immediately converted into RGBA as that format is
  // known to be supported everywhere. For image sources that don't need 32
  // bit pixel strides, this is overkill. Since this is a test fixture we
  // aren't necessarily trying to eke out memory savings here and instead
  // favor simplicity.
  auto image = compressed->Decode().ConvertToRGBA();
  if (!image.IsValid()) {
    VALIDATION_LOG << "Could not decode image.";
    return std::nullopt;
  }

  return image;
}

static std::shared_ptr<Texture> CreateTextureForDecompressedImage(
    const std::shared_ptr<Context>& context,
    DecompressedImage& decompressed_image,
    bool enable_mipmapping) {
  TextureDescriptor texture_descriptor;
  texture_descriptor.storage_mode = StorageMode::kDevicePrivate;
  texture_descriptor.format = PixelFormat::kR8G8B8A8UNormInt;
  texture_descriptor.size = decompressed_image.GetSize();
  texture_descriptor.mip_count =
      enable_mipmapping ? decompressed_image.GetSize().MipCount() : 1u;

  auto texture =
      context->GetResourceAllocator()->CreateTexture(texture_descriptor);
  if (!texture) {
    VALIDATION_LOG << "Could not allocate texture for fixture.";
    return nullptr;
  }

  auto command_buffer = context->CreateCommandBuffer();
  if (!command_buffer) {
    FML_DLOG(ERROR) << "Could not create command buffer for mipmap generation.";
    return nullptr;
  }
  command_buffer->SetLabel("Mipmap Command Buffer");

  auto blit_pass = command_buffer->CreateBlitPass();
  auto buffer_view = DeviceBuffer::AsBufferView(
      context->GetResourceAllocator()->CreateBufferWithCopy(
          *decompressed_image.GetAllocation()));
  blit_pass->AddCopy(buffer_view, texture);
  if (enable_mipmapping) {
    blit_pass->SetLabel("Mipmap Blit Pass");
    blit_pass->GenerateMipmap(texture);
  }
  blit_pass->EncodeCommands();
  if (!context->GetCommandQueue()->Submit({command_buffer}).ok()) {
    FML_DLOG(ERROR) << "Failed to submit blit pass command buffer.";
    return nullptr;
  }
  return texture;
}

std::shared_ptr<Texture> Playground::CreateTextureForMapping(
    const std::shared_ptr<Context>& context,
    std::shared_ptr<fml::Mapping> mapping,
    bool enable_mipmapping) {
  auto image = Playground::DecodeImageRGBA(
      Playground::LoadFixtureImageCompressed(std::move(mapping)));
  if (!image.has_value()) {
    return nullptr;
  }
  return CreateTextureForDecompressedImage(context, image.value(),
                                           enable_mipmapping);
}

std::shared_ptr<Texture> Playground::CreateTextureForFixture(
    const char* fixture_name,
    bool enable_mipmapping) const {
  auto texture = CreateTextureForMapping(
      GetContext(), OpenAssetAsMapping(fixture_name), enable_mipmapping);
  if (texture == nullptr) {
    return nullptr;
  }
  texture->SetLabel(fixture_name);
  return texture;
}

std::shared_ptr<Texture> Playground::CreateTextureCubeForFixture(
    std::array<const char*, 6> fixture_names) const {
  std::array<DecompressedImage, 6> images;
  for (size_t i = 0; i < fixture_names.size(); i++) {
    auto image = DecodeImageRGBA(
        LoadFixtureImageCompressed(OpenAssetAsMapping(fixture_names[i])));
    if (!image.has_value()) {
      return nullptr;
    }
    images[i] = image.value();
  }

  TextureDescriptor texture_descriptor;
  texture_descriptor.storage_mode = StorageMode::kDevicePrivate;
  texture_descriptor.type = TextureType::kTextureCube;
  texture_descriptor.format = PixelFormat::kR8G8B8A8UNormInt;
  texture_descriptor.size = images[0].GetSize();
  texture_descriptor.mip_count = 1u;

  auto texture =
      GetContext()->GetResourceAllocator()->CreateTexture(texture_descriptor);
  if (!texture) {
    VALIDATION_LOG << "Could not allocate texture cube.";
    return nullptr;
  }
  texture->SetLabel("Texture cube");

  auto cmd_buffer = GetContext()->CreateCommandBuffer();
  auto blit_pass = cmd_buffer->CreateBlitPass();
  for (size_t i = 0; i < fixture_names.size(); i++) {
    auto device_buffer =
        GetContext()->GetResourceAllocator()->CreateBufferWithCopy(
            *images[i].GetAllocation());
    blit_pass->AddCopy(DeviceBuffer::AsBufferView(device_buffer), texture, {},
                       "", /*mip_level=*/0, /*slice=*/i);
  }

  if (!blit_pass->EncodeCommands() ||
      !GetContext()->GetCommandQueue()->Submit({std::move(cmd_buffer)}).ok()) {
    VALIDATION_LOG << "Could not upload texture to device memory.";
    return nullptr;
  }

  return texture;
}

void Playground::SetWindowSize(ISize size) {
  window_size_ = size;
}

bool Playground::ShouldKeepRendering() const {
  return true;
}

fml::Status Playground::SetCapabilities(
    const std::shared_ptr<Capabilities>& capabilities) {
  return GetImpl()->SetCapabilities(capabilities);
}

Playground::GLProcAddressResolver Playground::CreateGLProcAddressResolver()
    const {
  return GetImpl()->CreateGLProcAddressResolver();
}

Playground::VKProcAddressResolver Playground::CreateVKProcAddressResolver()
    const {
  return GetImpl()->CreateVKProcAddressResolver();
}

void Playground::SetGPUDisabled(bool value) const {
  GetImpl()->SetGPUDisabled(value);
}

RuntimeStageBackend Playground::GetRuntimeStageBackend() const {
  return GetImpl()->GetRuntimeStageBackend();
}

}  // namespace impeller
