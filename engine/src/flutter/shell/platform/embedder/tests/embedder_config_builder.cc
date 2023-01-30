// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/tests/embedder_config_builder.h"

#include "flutter/runtime/dart_vm.h"
#include "flutter/shell/platform/embedder/embedder.h"
#include "tests/embedder_test_context.h"
#include "third_party/skia/include/core/SkBitmap.h"
#include "vulkan/vulkan_core.h"

#ifdef SHELL_ENABLE_GL
#include "flutter/shell/platform/embedder/tests/embedder_test_compositor_gl.h"
#include "flutter/shell/platform/embedder/tests/embedder_test_context_gl.h"
#endif

#ifdef SHELL_ENABLE_VULKAN
#include "flutter/shell/platform/embedder/tests/embedder_test_context_vulkan.h"
#include "flutter/vulkan/vulkan_device.h"
#endif

#ifdef SHELL_ENABLE_METAL
#include "flutter/shell/platform/embedder/tests/embedder_test_context_metal.h"
#endif

namespace flutter {
namespace testing {

EmbedderConfigBuilder::EmbedderConfigBuilder(
    EmbedderTestContext& context,
    InitializationPreference preference)
    : context_(context) {
  project_args_.struct_size = sizeof(project_args_);
  project_args_.shutdown_dart_vm_when_done = true;
  project_args_.platform_message_callback =
      [](const FlutterPlatformMessage* message, void* context) {
        reinterpret_cast<EmbedderTestContext*>(context)
            ->PlatformMessageCallback(message);
      };

  custom_task_runners_.struct_size = sizeof(FlutterCustomTaskRunners);

#ifdef SHELL_ENABLE_GL
  opengl_renderer_config_.struct_size = sizeof(FlutterOpenGLRendererConfig);
  opengl_renderer_config_.make_current = [](void* context) -> bool {
    return reinterpret_cast<EmbedderTestContextGL*>(context)->GLMakeCurrent();
  };
  opengl_renderer_config_.clear_current = [](void* context) -> bool {
    return reinterpret_cast<EmbedderTestContextGL*>(context)->GLClearCurrent();
  };
  opengl_renderer_config_.present_with_info =
      [](void* context, const FlutterPresentInfo* present_info) -> bool {
    return reinterpret_cast<EmbedderTestContextGL*>(context)->GLPresent(
        *present_info);
  };
  opengl_renderer_config_.fbo_with_frame_info_callback =
      [](void* context, const FlutterFrameInfo* frame_info) -> uint32_t {
    return reinterpret_cast<EmbedderTestContextGL*>(context)->GLGetFramebuffer(
        *frame_info);
  };
  opengl_renderer_config_.populate_existing_damage = nullptr;
  opengl_renderer_config_.make_resource_current = [](void* context) -> bool {
    return reinterpret_cast<EmbedderTestContextGL*>(context)
        ->GLMakeResourceCurrent();
  };
  opengl_renderer_config_.gl_proc_resolver = [](void* context,
                                                const char* name) -> void* {
    return reinterpret_cast<EmbedderTestContextGL*>(context)->GLGetProcAddress(
        name);
  };
  opengl_renderer_config_.fbo_reset_after_present = true;
  opengl_renderer_config_.surface_transformation =
      [](void* context) -> FlutterTransformation {
    return reinterpret_cast<EmbedderTestContext*>(context)
        ->GetRootSurfaceTransformation();
  };
#endif

#ifdef SHELL_ENABLE_METAL
  InitializeMetalRendererConfig();
#endif

#ifdef SHELL_ENABLE_VULKAN
  InitializeVulkanRendererConfig();
#endif

  software_renderer_config_.struct_size = sizeof(FlutterSoftwareRendererConfig);
  software_renderer_config_.surface_present_callback =
      [](void* context, const void* allocation, size_t row_bytes,
         size_t height) {
        auto image_info =
            SkImageInfo::MakeN32Premul(SkISize::Make(row_bytes / 4, height));
        SkBitmap bitmap;
        if (!bitmap.installPixels(image_info, const_cast<void*>(allocation),
                                  row_bytes)) {
          FML_LOG(ERROR) << "Could not copy pixels for the software "
                            "composition from the engine.";
          return false;
        }
        bitmap.setImmutable();
        return reinterpret_cast<EmbedderTestContextSoftware*>(context)->Present(
            SkImage::MakeFromBitmap(bitmap));
      };

  // The first argument is always the executable name. Don't make tests have to
  // do this manually.
  AddCommandLineArgument("embedder_unittest");

  if (preference != InitializationPreference::kNoInitialize) {
    SetAssetsPath();
    SetIsolateCreateCallbackHook();
    SetSemanticsCallbackHooks();
    SetLogMessageCallbackHook();
    SetLocalizationCallbackHooks();
    AddCommandLineArgument("--disable-vm-service");

    if (preference == InitializationPreference::kSnapshotsInitialize ||
        preference == InitializationPreference::kMultiAOTInitialize) {
      SetSnapshots();
    }
    if (preference == InitializationPreference::kAOTDataInitialize ||
        preference == InitializationPreference::kMultiAOTInitialize) {
      SetAOTDataElf();
    }
  }
}

EmbedderConfigBuilder::~EmbedderConfigBuilder() = default;

FlutterProjectArgs& EmbedderConfigBuilder::GetProjectArgs() {
  return project_args_;
}

void EmbedderConfigBuilder::SetSoftwareRendererConfig(SkISize surface_size) {
  renderer_config_.type = FlutterRendererType::kSoftware;
  renderer_config_.software = software_renderer_config_;
  context_.SetupSurface(surface_size);
}

void EmbedderConfigBuilder::SetOpenGLFBOCallBack() {
#ifdef SHELL_ENABLE_GL
  // SetOpenGLRendererConfig must be called before this.
  FML_CHECK(renderer_config_.type == FlutterRendererType::kOpenGL);
  renderer_config_.open_gl.fbo_callback = [](void* context) -> uint32_t {
    FlutterFrameInfo frame_info = {};
    // fbo_callback doesn't use the frame size information, only
    // fbo_callback_with_frame_info does.
    frame_info.struct_size = sizeof(FlutterFrameInfo);
    frame_info.size.width = 0;
    frame_info.size.height = 0;
    return reinterpret_cast<EmbedderTestContextGL*>(context)->GLGetFramebuffer(
        frame_info);
  };
#endif
}

void EmbedderConfigBuilder::SetOpenGLPresentCallBack() {
#ifdef SHELL_ENABLE_GL
  // SetOpenGLRendererConfig must be called before this.
  FML_CHECK(renderer_config_.type == FlutterRendererType::kOpenGL);
  renderer_config_.open_gl.present = [](void* context) -> bool {
    // passing a placeholder fbo_id.
    return reinterpret_cast<EmbedderTestContextGL*>(context)->GLPresent(
        FlutterPresentInfo{
            .fbo_id = 0,
        });
  };
#endif
}

void EmbedderConfigBuilder::SetRendererConfig(EmbedderTestContextType type,
                                              SkISize surface_size) {
  switch (type) {
    case EmbedderTestContextType::kOpenGLContext:
      SetOpenGLRendererConfig(surface_size);
      break;
    case EmbedderTestContextType::kMetalContext:
      SetMetalRendererConfig(surface_size);
      break;
    case EmbedderTestContextType::kVulkanContext:
      SetVulkanRendererConfig(surface_size);
      break;
    case EmbedderTestContextType::kSoftwareContext:
      SetSoftwareRendererConfig(surface_size);
      break;
  }
}

void EmbedderConfigBuilder::SetOpenGLRendererConfig(SkISize surface_size) {
#ifdef SHELL_ENABLE_GL
  renderer_config_.type = FlutterRendererType::kOpenGL;
  renderer_config_.open_gl = opengl_renderer_config_;
  context_.SetupSurface(surface_size);
#endif
}

void EmbedderConfigBuilder::SetMetalRendererConfig(SkISize surface_size) {
#ifdef SHELL_ENABLE_METAL
  renderer_config_.type = FlutterRendererType::kMetal;
  renderer_config_.metal = metal_renderer_config_;
  context_.SetupSurface(surface_size);
#endif
}

void EmbedderConfigBuilder::SetVulkanRendererConfig(SkISize surface_size) {
#ifdef SHELL_ENABLE_VULKAN
  renderer_config_.type = FlutterRendererType::kVulkan;
  renderer_config_.vulkan = vulkan_renderer_config_;
  context_.SetupSurface(surface_size);
#endif
}

void EmbedderConfigBuilder::SetAssetsPath() {
  project_args_.assets_path = context_.GetAssetsPath().c_str();
}

void EmbedderConfigBuilder::SetSnapshots() {
  if (auto mapping = context_.GetVMSnapshotData()) {
    project_args_.vm_snapshot_data = mapping->GetMapping();
    project_args_.vm_snapshot_data_size = mapping->GetSize();
  }

  if (auto mapping = context_.GetVMSnapshotInstructions()) {
    project_args_.vm_snapshot_instructions = mapping->GetMapping();
    project_args_.vm_snapshot_instructions_size = mapping->GetSize();
  }

  if (auto mapping = context_.GetIsolateSnapshotData()) {
    project_args_.isolate_snapshot_data = mapping->GetMapping();
    project_args_.isolate_snapshot_data_size = mapping->GetSize();
  }

  if (auto mapping = context_.GetIsolateSnapshotInstructions()) {
    project_args_.isolate_snapshot_instructions = mapping->GetMapping();
    project_args_.isolate_snapshot_instructions_size = mapping->GetSize();
  }
}

void EmbedderConfigBuilder::SetAOTDataElf() {
  project_args_.aot_data = context_.GetAOTData();
}

void EmbedderConfigBuilder::SetIsolateCreateCallbackHook() {
  project_args_.root_isolate_create_callback =
      EmbedderTestContext::GetIsolateCreateCallbackHook();
}

void EmbedderConfigBuilder::SetSemanticsCallbackHooks() {
  project_args_.update_semantics_callback =
      context_.GetUpdateSemanticsCallbackHook();
  project_args_.update_semantics_node_callback =
      context_.GetUpdateSemanticsNodeCallbackHook();
  project_args_.update_semantics_custom_action_callback =
      context_.GetUpdateSemanticsCustomActionCallbackHook();
}

void EmbedderConfigBuilder::SetLogMessageCallbackHook() {
  project_args_.log_message_callback =
      EmbedderTestContext::GetLogMessageCallbackHook();
}

void EmbedderConfigBuilder::SetLogTag(std::string tag) {
  log_tag_ = std::move(tag);
  project_args_.log_tag = log_tag_.c_str();
}

void EmbedderConfigBuilder::SetLocalizationCallbackHooks() {
  project_args_.compute_platform_resolved_locale_callback =
      EmbedderTestContext::GetComputePlatformResolvedLocaleCallbackHook();
}

void EmbedderConfigBuilder::SetExecutableName(std::string executable_name) {
  if (executable_name.empty()) {
    return;
  }
  command_line_arguments_[0] = std::move(executable_name);
}

void EmbedderConfigBuilder::SetDartEntrypoint(std::string entrypoint) {
  if (entrypoint.empty()) {
    return;
  }

  dart_entrypoint_ = std::move(entrypoint);
  project_args_.custom_dart_entrypoint = dart_entrypoint_.c_str();
}

void EmbedderConfigBuilder::AddCommandLineArgument(std::string arg) {
  if (arg.empty()) {
    return;
  }

  command_line_arguments_.emplace_back(std::move(arg));
}

void EmbedderConfigBuilder::AddDartEntrypointArgument(std::string arg) {
  if (arg.empty()) {
    return;
  }

  dart_entrypoint_arguments_.emplace_back(std::move(arg));
}

void EmbedderConfigBuilder::SetPlatformTaskRunner(
    const FlutterTaskRunnerDescription* runner) {
  if (runner == nullptr) {
    return;
  }
  custom_task_runners_.platform_task_runner = runner;
  project_args_.custom_task_runners = &custom_task_runners_;
}

void EmbedderConfigBuilder::SetupVsyncCallback() {
  project_args_.vsync_callback = [](void* user_data, intptr_t baton) {
    auto context = reinterpret_cast<EmbedderTestContext*>(user_data);
    context->RunVsyncCallback(baton);
  };
}

FlutterRendererConfig& EmbedderConfigBuilder::GetRendererConfig() {
  return renderer_config_;
}

void EmbedderConfigBuilder::SetRenderTaskRunner(
    const FlutterTaskRunnerDescription* runner) {
  if (runner == nullptr) {
    return;
  }

  custom_task_runners_.render_task_runner = runner;
  project_args_.custom_task_runners = &custom_task_runners_;
}

void EmbedderConfigBuilder::SetPlatformMessageCallback(
    const std::function<void(const FlutterPlatformMessage*)>& callback) {
  context_.SetPlatformMessageCallback(callback);
}

void EmbedderConfigBuilder::SetCompositor(bool avoid_backing_store_cache) {
  context_.SetupCompositor();
  auto& compositor = context_.GetCompositor();
  compositor_.struct_size = sizeof(compositor_);
  compositor_.user_data = &compositor;
  compositor_.create_backing_store_callback =
      [](const FlutterBackingStoreConfig* config,  //
         FlutterBackingStore* backing_store_out,   //
         void* user_data                           //
      ) {
        return reinterpret_cast<EmbedderTestCompositor*>(user_data)
            ->CreateBackingStore(config, backing_store_out);
      };
  compositor_.collect_backing_store_callback =
      [](const FlutterBackingStore* backing_store,  //
         void* user_data                            //
      ) {
        return reinterpret_cast<EmbedderTestCompositor*>(user_data)
            ->CollectBackingStore(backing_store);
      };
  compositor_.present_layers_callback = [](const FlutterLayer** layers,  //
                                           size_t layers_count,          //
                                           void* user_data               //
                                        ) {
    return reinterpret_cast<EmbedderTestCompositor*>(user_data)->Present(
        layers,       //
        layers_count  //

    );
  };
  compositor_.avoid_backing_store_cache = avoid_backing_store_cache;
  project_args_.compositor = &compositor_;
}

FlutterCompositor& EmbedderConfigBuilder::GetCompositor() {
  return compositor_;
}

void EmbedderConfigBuilder::SetRenderTargetType(
    EmbedderTestBackingStoreProducer::RenderTargetType type,
    FlutterSoftwarePixelFormat software_pixfmt) {
  auto& compositor = context_.GetCompositor();
  // TODO(wrightgeorge): figure out a better way of plumbing through the
  // GrDirectContext
  compositor.SetBackingStoreProducer(
      std::make_unique<EmbedderTestBackingStoreProducer>(
          compositor.GetGrContext(), type, software_pixfmt));
}

UniqueEngine EmbedderConfigBuilder::LaunchEngine() const {
  return SetupEngine(true);
}

UniqueEngine EmbedderConfigBuilder::InitializeEngine() const {
  return SetupEngine(false);
}

UniqueEngine EmbedderConfigBuilder::SetupEngine(bool run) const {
  FlutterEngine engine = nullptr;
  FlutterProjectArgs project_args = project_args_;

  std::vector<const char*> args;
  args.reserve(command_line_arguments_.size());

  for (const auto& arg : command_line_arguments_) {
    args.push_back(arg.c_str());
  }

  if (!args.empty()) {
    project_args.command_line_argv = args.data();
    project_args.command_line_argc = args.size();
  } else {
    // Clear it out in case this is not the first engine launch from the
    // embedder config builder.
    project_args.command_line_argv = nullptr;
    project_args.command_line_argc = 0;
  }

  std::vector<const char*> dart_args;
  dart_args.reserve(dart_entrypoint_arguments_.size());

  for (const auto& arg : dart_entrypoint_arguments_) {
    dart_args.push_back(arg.c_str());
  }

  if (!dart_args.empty()) {
    project_args.dart_entrypoint_argv = dart_args.data();
    project_args.dart_entrypoint_argc = dart_args.size();
  } else {
    // Clear it out in case this is not the first engine launch from the
    // embedder config builder.
    project_args.dart_entrypoint_argv = nullptr;
    project_args.dart_entrypoint_argc = 0;
  }

  auto result =
      run ? FlutterEngineRun(FLUTTER_ENGINE_VERSION, &renderer_config_,
                             &project_args, &context_, &engine)
          : FlutterEngineInitialize(FLUTTER_ENGINE_VERSION, &renderer_config_,
                                    &project_args, &context_, &engine);

  if (result != kSuccess) {
    return {};
  }

  return UniqueEngine{engine};
}

#ifdef SHELL_ENABLE_METAL

void EmbedderConfigBuilder::InitializeMetalRendererConfig() {
  if (context_.GetContextType() != EmbedderTestContextType::kMetalContext) {
    return;
  }

  metal_renderer_config_.struct_size = sizeof(metal_renderer_config_);
  EmbedderTestContextMetal& metal_context =
      reinterpret_cast<EmbedderTestContextMetal&>(context_);

  metal_renderer_config_.device =
      metal_context.GetTestMetalContext()->GetMetalDevice();
  metal_renderer_config_.present_command_queue =
      metal_context.GetTestMetalContext()->GetMetalCommandQueue();
  metal_renderer_config_.get_next_drawable_callback =
      [](void* user_data, const FlutterFrameInfo* frame_info) {
        return reinterpret_cast<EmbedderTestContextMetal*>(user_data)
            ->GetNextDrawable(frame_info);
      };
  metal_renderer_config_.present_drawable_callback =
      [](void* user_data, const FlutterMetalTexture* texture) -> bool {
    EmbedderTestContextMetal* metal_context =
        reinterpret_cast<EmbedderTestContextMetal*>(user_data);
    return metal_context->Present(texture->texture_id);
  };
  metal_renderer_config_.external_texture_frame_callback =
      [](void* user_data, int64_t texture_id, size_t width, size_t height,
         FlutterMetalExternalTexture* texture_out) -> bool {
    EmbedderTestContextMetal* metal_context =
        reinterpret_cast<EmbedderTestContextMetal*>(user_data);
    return metal_context->PopulateExternalTexture(texture_id, width, height,
                                                  texture_out);
  };
}

#endif  // SHELL_ENABLE_METAL

#ifdef SHELL_ENABLE_VULKAN

void EmbedderConfigBuilder::InitializeVulkanRendererConfig() {
  if (context_.GetContextType() != EmbedderTestContextType::kVulkanContext) {
    return;
  }

  vulkan_renderer_config_.struct_size = sizeof(FlutterVulkanRendererConfig);
  vulkan_renderer_config_.version =
      static_cast<EmbedderTestContextVulkan&>(context_)
          .vulkan_context_->application_->GetAPIVersion();
  vulkan_renderer_config_.instance =
      static_cast<EmbedderTestContextVulkan&>(context_)
          .vulkan_context_->application_->GetInstance();
  vulkan_renderer_config_.physical_device =
      static_cast<EmbedderTestContextVulkan&>(context_)
          .vulkan_context_->device_->GetPhysicalDeviceHandle();
  vulkan_renderer_config_.device =
      static_cast<EmbedderTestContextVulkan&>(context_)
          .vulkan_context_->device_->GetHandle();
  vulkan_renderer_config_.queue_family_index =
      static_cast<EmbedderTestContextVulkan&>(context_)
          .vulkan_context_->device_->GetGraphicsQueueIndex();
  vulkan_renderer_config_.queue =
      static_cast<EmbedderTestContextVulkan&>(context_)
          .vulkan_context_->device_->GetQueueHandle();
  vulkan_renderer_config_.get_instance_proc_address_callback =
      [](void* context, FlutterVulkanInstanceHandle instance,
         const char* name) -> void* {
    auto proc_addr = reinterpret_cast<EmbedderTestContextVulkan*>(context)
                         ->vulkan_context_->vk_->GetInstanceProcAddr(
                             reinterpret_cast<VkInstance>(instance), name);
    return reinterpret_cast<void*>(proc_addr);
  };
  vulkan_renderer_config_.get_next_image_callback =
      [](void* context,
         const FlutterFrameInfo* frame_info) -> FlutterVulkanImage {
    VkImage image =
        reinterpret_cast<EmbedderTestContextVulkan*>(context)->GetNextImage(
            {static_cast<int>(frame_info->size.width),
             static_cast<int>(frame_info->size.height)});
    return {
        .struct_size = sizeof(FlutterVulkanImage),
        .image = reinterpret_cast<uint64_t>(image),
        .format = VK_FORMAT_R8G8B8A8_UNORM,
    };
  };
  vulkan_renderer_config_.present_image_callback =
      [](void* context, const FlutterVulkanImage* image) -> bool {
    return reinterpret_cast<EmbedderTestContextVulkan*>(context)->PresentImage(
        reinterpret_cast<VkImage>(image->image));
  };
}

#endif

}  // namespace testing
}  // namespace flutter
