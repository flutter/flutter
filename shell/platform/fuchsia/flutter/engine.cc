// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#include "engine.h"

#include <lib/async/cpp/task.h>
#include <zircon/status.h>

#include "flutter/common/graphics/persistent_cache.h"
#include "flutter/common/task_runners.h"
#include "flutter/fml/make_copyable.h"
#include "flutter/fml/message_loop.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/fml/task_runner.h"
#include "flutter/runtime/dart_vm_lifecycle.h"
#include "flutter/shell/common/rasterizer.h"
#include "flutter/shell/common/run_configuration.h"
#include "flutter/shell/common/serialization_callbacks.h"
#include "third_party/skia/include/core/SkPicture.h"
#include "third_party/skia/include/core/SkSerialProcs.h"
#include "third_party/skia/include/ports/SkFontMgr_fuchsia.h"

#include "../runtime/dart/utils/files.h"
#include "focus_delegate.h"
#include "fuchsia_intl.h"
#include "platform_view.h"
#include "surface.h"
#include "vsync_waiter.h"

namespace flutter_runner {
namespace {

void UpdateNativeThreadLabelNames(const std::string& label,
                                  const flutter::TaskRunners& runners) {
  auto set_thread_name = [](fml::RefPtr<fml::TaskRunner> runner,
                            std::string prefix, std::string suffix) {
    if (!runner) {
      return;
    }
    fml::TaskRunner::RunNowOrPostTask(runner, [name = prefix + suffix]() {
      zx::thread::self()->set_property(ZX_PROP_NAME, name.c_str(), name.size());
    });
  };
  set_thread_name(runners.GetPlatformTaskRunner(), label, ".platform");
  set_thread_name(runners.GetUITaskRunner(), label, ".ui");
  set_thread_name(runners.GetRasterTaskRunner(), label, ".raster");
  set_thread_name(runners.GetIOTaskRunner(), label, ".io");
}

std::unique_ptr<flutter::PlatformMessage> MakeLocalizationPlatformMessage(
    const fuchsia::intl::Profile& intl_profile) {
  return std::make_unique<flutter::PlatformMessage>(
      "flutter/localization", MakeLocalizationPlatformMessageData(intl_profile),
      nullptr);
}

}  // namespace

Engine::Engine(Delegate& delegate,
               std::string thread_label,
               std::shared_ptr<sys::ServiceDirectory> svc,
               std::shared_ptr<sys::ServiceDirectory> runner_services,
               flutter::Settings settings,
               fuchsia::ui::views::ViewToken view_token,
               scenic::ViewRefPair view_ref_pair,
               UniqueFDIONS fdio_ns,
               fidl::InterfaceRequest<fuchsia::io::Directory> directory_request,
               FlutterRunnerProductConfiguration product_config)
    : delegate_(delegate),
      thread_label_(std::move(thread_label)),
      intercept_all_input_(product_config.get_intercept_all_input()),
      weak_factory_(this) {
  // Get the task runners from the managed threads. The current thread will be
  // used as the "platform" thread.
  fml::RefPtr<fml::TaskRunner> platform_task_runner =
      fml::MessageLoop::GetCurrent().GetTaskRunner();

  const flutter::TaskRunners task_runners(
      thread_label_,                // Dart thread labels
      platform_task_runner,         // platform
      threads_[0].GetTaskRunner(),  // raster
      threads_[1].GetTaskRunner(),  // ui
      threads_[2].GetTaskRunner()   // io
  );
  UpdateNativeThreadLabelNames(thread_label_, task_runners);

  // Connect to Scenic.
  auto scenic = svc->Connect<fuchsia::ui::scenic::Scenic>();
  fuchsia::ui::scenic::SessionEndpoints endpoints;
  fidl::InterfaceHandle<fuchsia::ui::scenic::Session> session;
  endpoints.set_session(session.NewRequest());
  fidl::InterfaceHandle<fuchsia::ui::scenic::SessionListener> session_listener;
  auto session_listener_request = session_listener.NewRequest();
  endpoints.set_session_listener(session_listener.Bind());
  fidl::InterfaceHandle<fuchsia::ui::views::Focuser> focuser;
  endpoints.set_view_focuser(focuser.NewRequest());
  fidl::InterfaceHandle<fuchsia::ui::views::ViewRefFocused> view_ref_focused;
  endpoints.set_view_ref_focused(view_ref_focused.NewRequest());
  scenic->CreateSessionT(std::move(endpoints), [] {});

  // Make clones of the `ViewRef` before sending it down to Scenic, since the
  // refs are not copyable, and multiple consumers need view refs.
  fuchsia::ui::views::ViewRef platform_view_ref;
  view_ref_pair.view_ref.Clone(&platform_view_ref);
  fuchsia::ui::views::ViewRef accessibility_bridge_view_ref;
  view_ref_pair.view_ref.Clone(&accessibility_bridge_view_ref);
  fuchsia::ui::views::ViewRef isolate_view_ref;
  view_ref_pair.view_ref.Clone(&isolate_view_ref);
  // Input3 keyboard listener registration requires a ViewRef as an event
  // filter. So we clone it here, as ViewRefs can not be reused, only cloned.
  fuchsia::ui::views::ViewRef keyboard_view_ref;
  view_ref_pair.view_ref.Clone(&keyboard_view_ref);

  // Session is terminated on the raster thread, but we must terminate ourselves
  // on the platform thread.
  //
  // This handles the fidl error callback when the Session connection is
  // broken. The SessionListener interface also has an OnError method, which is
  // invoked on the platform thread (in PlatformView).
  fml::closure session_error_callback = [task_runner = platform_task_runner,
                                         weak = weak_factory_.GetWeakPtr()]() {
    task_runner->PostTask([weak]() {
      if (weak) {
        weak->Terminate();
      }
    });
  };

  // Set up the session connection and other Scenic helpers on the raster
  // thread. We also need to wait for the external view embedder to be set up
  // before creating the shell.
  fml::AutoResetWaitableEvent view_embedder_latch;
  task_runners.GetRasterTaskRunner()->PostTask(fml::MakeCopyable(
      [this, session = std::move(session),
       session_error_callback = std::move(session_error_callback),
       view_token = std::move(view_token),
       view_ref_pair = std::move(view_ref_pair),
       max_frames_in_flight = product_config.get_max_frames_in_flight(),
       &view_embedder_latch,
       vsync_offset = product_config.get_vsync_offset()]() mutable {
        session_connection_ = std::make_shared<DefaultSessionConnection>(
            thread_label_, std::move(session),
            std::move(session_error_callback), [](auto) {},
            max_frames_in_flight, vsync_offset);
        surface_producer_.emplace(session_connection_->get());
        external_view_embedder_ = std::make_shared<FuchsiaExternalViewEmbedder>(
            thread_label_, std::move(view_token), std::move(view_ref_pair),
            *session_connection_.get(), surface_producer_.value(),
            intercept_all_input_);
        view_embedder_latch.Signal();
      }));
  view_embedder_latch.Wait();

  // Grab the parent environment services. The platform view may want to
  // access some of these services.
  fuchsia::sys::EnvironmentPtr environment;
  svc->Connect(environment.NewRequest());
  fidl::InterfaceHandle<fuchsia::sys::ServiceProvider>
      parent_environment_service_provider;
  environment->GetServices(parent_environment_service_provider.NewRequest());
  environment.Unbind();

  AccessibilityBridge::SetSemanticsEnabledCallback
      set_semantics_enabled_callback = [this](bool enabled) {
        auto platform_view = shell_->GetPlatformView();

        if (platform_view) {
          platform_view->SetSemanticsEnabled(enabled);
        }
      };

  AccessibilityBridge::DispatchSemanticsActionCallback
      dispatch_semantics_action_callback =
          [this](int32_t node_id, flutter::SemanticsAction action) {
            auto platform_view = shell_->GetPlatformView();

            if (platform_view) {
              platform_view->DispatchSemanticsAction(node_id, action, {});
            }
          };

  accessibility_bridge_ = std::make_unique<AccessibilityBridge>(
      std::move(set_semantics_enabled_callback),
      std::move(dispatch_semantics_action_callback), svc,
      std::move(accessibility_bridge_view_ref));

  OnEnableWireframe on_enable_wireframe_callback = std::bind(
      &Engine::DebugWireframeSettingsChanged, this, std::placeholders::_1);

  OnCreateView on_create_view_callback = std::bind(
      &Engine::CreateView, this, std::placeholders::_1, std::placeholders::_2,
      std::placeholders::_3, std::placeholders::_4, std::placeholders::_5);

  OnUpdateView on_update_view_callback = std::bind(
      &Engine::UpdateView, this, std::placeholders::_1, std::placeholders::_2,
      std::placeholders::_3, std::placeholders::_4);

  OnDestroyView on_destroy_view_callback = std::bind(
      &Engine::DestroyView, this, std::placeholders::_1, std::placeholders::_2);

  OnCreateSurface on_create_surface_callback =
      std::bind(&Engine::CreateSurface, this);

  // SessionListener has a OnScenicError method; invoke this callback on the
  // platform thread when that happens. The Session itself should also be
  // disconnected when this happens, and it will also attempt to terminate.
  fit::closure on_session_listener_error_callback =
      [task_runner = platform_task_runner,
       weak = weak_factory_.GetWeakPtr()]() {
        task_runner->PostTask([weak]() {
          if (weak) {
            weak->Terminate();
          }
        });
      };

  // Launch the engine in the appropriate configuration.
  // Note: this initializes the Asset Manager on the global PersistantCache
  // so it must be called before WarmupSkps() is called below.
  auto run_configuration = flutter::RunConfiguration::InferFromSettings(
      settings, task_runners.GetIOTaskRunner());

  // Connect to fuchsia.ui.input3.Keyboard to hand out a listener.
  using fuchsia::ui::input3::Keyboard;
  using fuchsia::ui::input3::KeyboardListener;

  // Keyboard client-side stub.
  keyboard_svc_ = svc->Connect<Keyboard>();
  ZX_ASSERT(keyboard_svc_.is_bound());
  // KeyboardListener handle pair is not initialized until NewRequest() is
  // called.
  fidl::InterfaceHandle<KeyboardListener> keyboard_listener;

  // Server side of KeyboardListener.  Initializes the keyboard_listener
  // handle.
  fidl::InterfaceRequest<KeyboardListener> keyboard_listener_request =
      keyboard_listener.NewRequest();
  ZX_ASSERT(keyboard_listener_request.is_valid());

  keyboard_svc_->AddListener(std::move(keyboard_view_ref),
                             keyboard_listener.Bind(), [] {});

  OnSemanticsNodeUpdate on_semantics_node_update_callback =
      [this](flutter::SemanticsNodeUpdates updates, float pixel_ratio) {
        accessibility_bridge_->AddSemanticsNodeUpdate(updates, pixel_ratio);
      };

  OnRequestAnnounce on_request_announce_callback =
      [this](const std::string& message) {
        accessibility_bridge_->RequestAnnounce(message);
      };

  // Setup the callback that will instantiate the platform view.
  flutter::Shell::CreateCallback<flutter::PlatformView>
      on_create_platform_view = fml::MakeCopyable(
          [this, debug_label = thread_label_,
           view_ref = std::move(platform_view_ref), runner_services,
           parent_environment_service_provider =
               std::move(parent_environment_service_provider),
           session_listener_request = std::move(session_listener_request),
           focuser = std::move(focuser),
           view_ref_focused = std::move(view_ref_focused),
           on_session_listener_error_callback =
               std::move(on_session_listener_error_callback),
           on_enable_wireframe_callback =
               std::move(on_enable_wireframe_callback),
           on_create_view_callback = std::move(on_create_view_callback),
           on_update_view_callback = std::move(on_update_view_callback),
           on_destroy_view_callback = std::move(on_destroy_view_callback),
           on_create_surface_callback = std::move(on_create_surface_callback),
           on_semantics_node_update_callback =
               std::move(on_semantics_node_update_callback),
           on_request_announce_callback =
               std::move(on_request_announce_callback),
           external_view_embedder = GetExternalViewEmbedder(),
           keyboard_listener_request = std::move(keyboard_listener_request),
           await_vsync_callback =
               [this](FireCallbackCallback cb) {
                 session_connection_->AwaitVsync(cb);
               },
           await_vsync_for_secondary_callback_callback =
               [this](FireCallbackCallback cb) {
                 session_connection_->AwaitVsyncForSecondaryCallback(cb);
               },
           product_config](flutter::Shell& shell) mutable {
            OnShaderWarmup on_shader_warmup = nullptr;
            if (product_config.enable_shader_warmup()) {
              FML_DCHECK(surface_producer_);
              if (product_config.enable_shader_warmup_dart_hooks()) {
                on_shader_warmup =
                    [this, &shell](
                        const std::vector<std::string>& skp_names,
                        std::function<void(uint32_t)> completion_callback,
                        uint64_t width, uint64_t height) {
                      WarmupSkps(
                          shell.GetDartVM()
                              ->GetConcurrentMessageLoop()
                              ->GetTaskRunner()
                              .get(),
                          shell.GetTaskRunners().GetRasterTaskRunner().get(),
                          surface_producer_.value(), width, height,
                          flutter::PersistentCache::GetCacheForProcess()
                              ->asset_manager(),
                          skp_names, completion_callback);
                    };
              } else {
                WarmupSkps(shell.GetDartVM()
                               ->GetConcurrentMessageLoop()
                               ->GetTaskRunner()
                               .get(),
                           shell.GetTaskRunners().GetRasterTaskRunner().get(),
                           surface_producer_.value(), 1024, 600,
                           flutter::PersistentCache::GetCacheForProcess()
                               ->asset_manager(),
                           std::nullopt, std::nullopt);
              }
            }

            return std::make_unique<flutter_runner::PlatformView>(
                shell,                   // delegate
                debug_label,             // debug label
                std::move(view_ref),     // view ref
                shell.GetTaskRunners(),  // task runners
                std::move(runner_services),
                std::move(parent_environment_service_provider),  // services
                std::move(session_listener_request),  // session listener
                std::move(view_ref_focused), std::move(focuser),
                // Server-side part of the fuchsia.ui.input3.KeyboardListener
                // connection.
                std::move(keyboard_listener_request),
                std::move(on_session_listener_error_callback),
                std::move(on_enable_wireframe_callback),
                std::move(on_create_view_callback),
                std::move(on_update_view_callback),
                std::move(on_destroy_view_callback),
                std::move(on_create_surface_callback),
                std::move(on_semantics_node_update_callback),
                std::move(on_request_announce_callback),
                std::move(on_shader_warmup), external_view_embedder,
                // Callbacks for VsyncWaiter to call into SessionConnection.
                await_vsync_callback,
                await_vsync_for_secondary_callback_callback);
          });

  // Setup the callback that will instantiate the rasterizer.
  flutter::Shell::CreateCallback<flutter::Rasterizer> on_create_rasterizer =
      [](flutter::Shell& shell) {
        return std::make_unique<flutter::Rasterizer>(shell);
      };

  settings.root_isolate_create_callback =
      std::bind(&Engine::OnMainIsolateStart, this);
  settings.root_isolate_shutdown_callback =
      std::bind([weak = weak_factory_.GetWeakPtr(),
                 runner = task_runners.GetPlatformTaskRunner()]() {
        runner->PostTask([weak = std::move(weak)] {
          if (weak) {
            weak->OnMainIsolateShutdown();
          }
        });
      });

  {
    TRACE_EVENT0("flutter", "CreateShell");
    shell_ = flutter::Shell::Create(
        flutter::PlatformData(),             // default window data
        std::move(task_runners),             // host task runners
        std::move(settings),                 // shell launch settings
        std::move(on_create_platform_view),  // platform view create callback
        std::move(on_create_rasterizer)      // rasterizer create callback
    );
  }

  if (!shell_) {
    FML_LOG(ERROR) << "Could not launch the shell.";
    return;
  }

  // Shell has been created. Before we run the engine, set up the isolate
  // configurator.
  {
    fuchsia::sys::EnvironmentPtr environment;
    svc->Connect(environment.NewRequest());

    isolate_configurator_ = std::make_unique<IsolateConfigurator>(
        std::move(fdio_ns),                    //
        std::move(environment),                //
        directory_request.TakeChannel(),       //
        std::move(isolate_view_ref.reference)  //
    );
  }

  //  This platform does not get a separate surface platform view creation
  //  notification. Fire one eagerly.
  shell_->GetPlatformView()->NotifyCreated();

  // Connect to the intl property provider.  If the connection fails, the
  // initialization of the engine will simply proceed, printing a warning
  // message.  The engine will be fully functional, except that the user's
  // locale preferences would not be communicated to flutter engine.
  {
    intl_property_provider_.set_error_handler([](zx_status_t status) {
      FML_LOG(WARNING) << "Failed to connect to "
                       << fuchsia::intl::PropertyProvider::Name_ << ": "
                       << zx_status_get_string(status)
                       << " This is not a fatal error, but the user locale "
                       << " preferences will not be forwarded to flutter apps";
    });

    // Note that we're using the runner's services, not the component's.
    // Flutter locales should be updated regardless of whether the component has
    // direct access to the fuchsia.intl.PropertyProvider service.
    ZX_ASSERT(runner_services->Connect(intl_property_provider_.NewRequest()) ==
              ZX_OK);

    auto get_profile_callback = [flutter_runner_engine =
                                     weak_factory_.GetWeakPtr()](
                                    const fuchsia::intl::Profile& profile) {
      if (!flutter_runner_engine) {
        return;
      }
      if (!profile.has_locales()) {
        FML_LOG(WARNING) << "Got intl Profile without locales";
      }
      auto message = MakeLocalizationPlatformMessage(profile);
      FML_VLOG(-1) << "Sending LocalizationPlatformMessage";
      flutter_runner_engine->shell_->GetPlatformView()->DispatchPlatformMessage(
          std::move(message));
    };

    FML_VLOG(-1) << "Requesting intl Profile";

    // Make the initial request
    intl_property_provider_->GetProfile(get_profile_callback);

    // And register for changes
    intl_property_provider_.events().OnChange = [this, runner_services,
                                                 get_profile_callback]() {
      FML_VLOG(-1) << fuchsia::intl::PropertyProvider::Name_ << ": OnChange";
      runner_services->Connect(intl_property_provider_.NewRequest());
      intl_property_provider_->GetProfile(get_profile_callback);
    };
  }

  auto on_run_failure = [weak = weak_factory_.GetWeakPtr()]() {
    // The engine could have been killed by the caller right after the
    // constructor was called but before it could run on the UI thread.
    if (weak) {
      weak->Terminate();
    }
  };

  // Connect to the system font provider.
  fuchsia::fonts::ProviderSyncPtr sync_font_provider;
  svc->Connect(sync_font_provider.NewRequest());

  shell_->GetTaskRunners().GetUITaskRunner()->PostTask(
      fml::MakeCopyable([engine = shell_->GetEngine(),                        //
                         run_configuration = std::move(run_configuration),    //
                         sync_font_provider = std::move(sync_font_provider),  //
                         on_run_failure                                       //
  ]() mutable {
        if (!engine) {
          return;
        }

        // Set default font manager.
        engine->GetFontCollection().GetFontCollection()->SetDefaultFontManager(
            SkFontMgr_New_Fuchsia(std::move(sync_font_provider)));

        if (engine->Run(std::move(run_configuration)) ==
            flutter::Engine::RunStatus::Failure) {
          on_run_failure();
        }
      }));
}

Engine::~Engine() {
  shell_.reset();
  for (auto& thread : threads_) {
    thread.Join();
  }
}

std::optional<uint32_t> Engine::GetEngineReturnCode() const {
  if (!shell_) {
    return std::nullopt;
  }
  std::optional<uint32_t> code;
  fml::AutoResetWaitableEvent latch;
  fml::TaskRunner::RunNowOrPostTask(
      shell_->GetTaskRunners().GetUITaskRunner(),
      [&latch, &code, engine = shell_->GetEngine()]() {
        if (engine) {
          code = engine->GetUIIsolateReturnCode();
        }
        latch.Signal();
      });
  latch.Wait();
  return code;
}

void Engine::OnMainIsolateStart() {
  if (!isolate_configurator_ ||
      !isolate_configurator_->ConfigureCurrentIsolate()) {
    FML_LOG(ERROR) << "Could not configure some native embedder bindings for a "
                      "new root isolate.";
  }
  FML_DLOG(INFO) << "Main isolate for engine '" << thread_label_
                 << "' was started.";
}

void Engine::OnMainIsolateShutdown() {
  FML_DLOG(INFO) << "Main isolate for engine '" << thread_label_
                 << "' shutting down.";
  Terminate();
}

void Engine::Terminate() {
  delegate_.OnEngineTerminate(this);
  // Warning. Do not do anything after this point as the delegate may have
  // collected this object.
}

void Engine::DebugWireframeSettingsChanged(bool enabled) {
  FML_CHECK(shell_);

  shell_->GetTaskRunners().GetRasterTaskRunner()->PostTask([this, enabled]() {
    FML_CHECK(external_view_embedder_);
    external_view_embedder_->EnableWireframe(enabled);
  });
}

void Engine::CreateView(int64_t view_id,
                        ViewCallback on_view_created,
                        ViewIdCallback on_view_bound,
                        bool hit_testable,
                        bool focusable) {
  FML_CHECK(shell_);

  shell_->GetTaskRunners().GetRasterTaskRunner()->PostTask(
      [this, view_id, hit_testable, focusable,
       on_view_created = std::move(on_view_created),
       on_view_bound = std::move(on_view_bound)]() {
        FML_CHECK(external_view_embedder_);
        external_view_embedder_->CreateView(view_id, std::move(on_view_created),
                                            std::move(on_view_bound));
        external_view_embedder_->SetViewProperties(view_id, SkRect::MakeEmpty(),
                                                   hit_testable, focusable);
      });
}

void Engine::UpdateView(int64_t view_id,
                        SkRect occlusion_hint,
                        bool hit_testable,
                        bool focusable) {
  FML_CHECK(shell_);

  shell_->GetTaskRunners().GetRasterTaskRunner()->PostTask(
      [this, view_id, occlusion_hint, hit_testable, focusable]() {
        FML_CHECK(external_view_embedder_);
        external_view_embedder_->SetViewProperties(view_id, occlusion_hint,
                                                   hit_testable, focusable);
      });
}

void Engine::DestroyView(int64_t view_id, ViewIdCallback on_view_unbound) {
  FML_CHECK(shell_);

  shell_->GetTaskRunners().GetRasterTaskRunner()->PostTask(
      [this, view_id, on_view_unbound = std::move(on_view_unbound)]() {
        FML_CHECK(external_view_embedder_);
        external_view_embedder_->DestroyView(view_id,
                                             std::move(on_view_unbound));
      });
}

std::unique_ptr<flutter::Surface> Engine::CreateSurface() {
  return std::make_unique<Surface>(thread_label_, GetExternalViewEmbedder(),
                                   surface_producer_->gr_context());
}

std::shared_ptr<flutter::ExternalViewEmbedder>
Engine::GetExternalViewEmbedder() {
  FML_CHECK(external_view_embedder_);

  return external_view_embedder_;
}

#if !defined(DART_PRODUCT)
void Engine::WriteProfileToTrace() const {
  Dart_Port main_port = shell_->GetEngine()->GetUIIsolateMainPort();
  char* error = NULL;
  bool success = Dart_WriteProfileToTimeline(main_port, &error);
  if (!success) {
    FML_LOG(ERROR) << "Failed to write Dart profile to trace: " << error;
    free(error);
  }
}
#endif  // !defined(DART_PRODUCT)

void Engine::WarmupSkps(
    fml::BasicTaskRunner* concurrent_task_runner,
    fml::BasicTaskRunner* raster_task_runner,
    VulkanSurfaceProducer& surface_producer,
    uint64_t width,
    uint64_t height,
    std::shared_ptr<flutter::AssetManager> asset_manager,
    std::optional<const std::vector<std::string>> skp_names,
    std::optional<std::function<void(uint32_t)>> completion_callback) {
  SkISize size = SkISize::Make(width, height);

  // We use a raw pointer here because we want to keep this alive until all gpu
  // work is done and the callbacks skia takes for this are function pointers
  // so we are unable to use a lambda that captures the smart pointer.
  SurfaceProducerSurface* skp_warmup_surface =
      surface_producer.ProduceOffscreenSurface(size).release();
  if (!skp_warmup_surface) {
    FML_LOG(ERROR) << "Failed to create offscreen warmup surface";
    return;
  }

  // tell concurrent task runner to deserialize all skps available from
  // the asset manager
  concurrent_task_runner->PostTask([raster_task_runner, skp_warmup_surface,
                                    &surface_producer, asset_manager, skp_names,
                                    completion_callback]() {
    TRACE_DURATION("flutter", "DeserializeSkps");
    std::vector<std::unique_ptr<fml::Mapping>> skp_mappings;
    if (skp_names) {
      for (auto& skp_name : skp_names.value()) {
        auto skp_mapping = asset_manager->GetAsMapping(skp_name);
        if (skp_mapping) {
          skp_mappings.push_back(std::move(skp_mapping));
        } else {
          FML_LOG(ERROR) << "Failed to get mapping for " << skp_name;
        }
      }
    } else {
      skp_mappings = asset_manager->GetAsMappings(".*\\.skp$", "shaders");
    }

    size_t total_size = 0;
    for (auto& mapping : skp_mappings) {
      total_size += mapping->GetSize();
    }

    FML_LOG(INFO) << "Shader warmup got " << skp_mappings.size()
                  << " skp's with a total size of " << total_size << " bytes";

    std::vector<sk_sp<SkPicture>> pictures;
    unsigned int i = 0;
    for (auto& mapping : skp_mappings) {
      std::unique_ptr<SkMemoryStream> stream =
          SkMemoryStream::MakeDirect(mapping->GetMapping(), mapping->GetSize());
      SkDeserialProcs procs = {0};
      procs.fImageProc = flutter::DeserializeImageWithoutData;
      procs.fTypefaceProc = flutter::DeserializeTypefaceWithoutData;
      sk_sp<SkPicture> picture =
          SkPicture::MakeFromStream(stream.get(), &procs);
      if (!picture) {
        FML_LOG(ERROR) << "Failed to deserialize picture " << i;
        continue;
      }

      // Tell raster task runner to warmup have the compositor
      // context warm up the newly deserialized picture
      raster_task_runner->PostTask([skp_warmup_surface, picture,
                                    &surface_producer, completion_callback, i,
                                    count = skp_mappings.size()] {
        TRACE_DURATION("flutter", "WarmupSkp");
        skp_warmup_surface->GetSkiaSurface()->getCanvas()->drawPicture(picture);

        if (i < count - 1) {
          // For all but the last skp we fire and forget
          surface_producer.gr_context()->flushAndSubmit();
        } else {
          // For the last skp we provide a callback that frees the warmup
          // surface and calls the completion callback
          struct GrFlushInfo flush_info;
          flush_info.fFinishedContext = skp_warmup_surface;
          flush_info.fFinishedProc = [](void* skp_warmup_surface) {
            delete static_cast<SurfaceProducerSurface*>(skp_warmup_surface);
          };

          surface_producer.gr_context()->flush(flush_info);
          surface_producer.gr_context()->submit();

          // We call this here instead of inside fFinishedProc above because
          // we want to unblock the dart animation code as soon as the raster
          // thread is free to enque work, rather than waiting for the GPU work
          // itself to finish.
          if (completion_callback) {
            completion_callback.value()(count);
          }
        }
      });
      i++;
    }
  });
}

}  // namespace flutter_runner
