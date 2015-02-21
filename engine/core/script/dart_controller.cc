// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/core/script/dart_controller.h"

#include "base/bind.h"
#include "base/logging.h"
#include "base/single_thread_task_runner.h"
#include "dart/runtime/include/dart_mirrors_api.h"
#include "sky/engine/bindings/builtin.h"
#include "sky/engine/bindings/builtin_natives.h"
#include "sky/engine/bindings/builtin_sky.h"
#include "sky/engine/core/app/AbstractModule.h"
#include "sky/engine/core/app/Module.h"
#include "sky/engine/core/dom/Element.h"
#include "sky/engine/core/frame/LocalFrame.h"
#include "sky/engine/core/html/HTMLScriptElement.h"
#include "sky/engine/core/html/imports/HTMLImport.h"
#include "sky/engine/core/html/imports/HTMLImportChild.h"
#include "sky/engine/core/loader/FrameLoaderClient.h"
#include "sky/engine/core/script/dart_dependency_catcher.h"
#include "sky/engine/core/script/dart_loader.h"
#include "sky/engine/core/script/dom_dart_state.h"
#include "sky/engine/public/platform/Platform.h"
#include "sky/engine/tonic/dart_api_scope.h"
#include "sky/engine/tonic/dart_class_library.h"
#include "sky/engine/tonic/dart_error.h"
#include "sky/engine/tonic/dart_gc_controller.h"
#include "sky/engine/tonic/dart_isolate_scope.h"
#include "sky/engine/tonic/dart_state.h"
#include "sky/engine/tonic/dart_wrappable.h"
#include "sky/engine/wtf/text/TextPosition.h"

namespace blink {

#if ENABLE(ASSERT)
static const char* kCheckedModeArgs[] = {
  "--enable_asserts",
  "--enable_type_checks",
  "--error_on_bad_type",
  "--error_on_bad_override",
};
#endif

extern const uint8_t* kDartSnapshotBuffer;

DartController::DartController() {
}

DartController::~DartController() {
}

bool DartController::ImportChildLibraries(AbstractModule* module,
                                          Dart_Handle library) {
  // If the document has never seen an <import> tag, it won't have an import
  // controller, and thus will return null for its root HTMLImport.  We could
  // remove this null-check by always creating an ImportController.
  HTMLImport* root = module->document()->import();
  if (!root)
    return true;

  // TODO(abarth): Why doesn't HTMLImport do these casts for us?
  for (HTMLImportChild* child =
           static_cast<HTMLImportChild*>(root->firstChild());
       child; child = static_cast<HTMLImportChild*>(child->next())) {
    if (Element* link = child->link()) {
      String name = link->getAttribute(HTMLNames::asAttr);

      Module* child_module = child->module();
      if (!child_module)
        continue;
      for (const auto& entry : child_module->libraries()) {
        if (entry.library()->is_empty())
          continue;
        if (LogIfError(Dart_LibraryImportLibrary(
                library, entry.library()->dart_value(),
                StringToDart(dart_state(), name))))
          return false;
      }
    }
  }
  return true;
}

Dart_Handle DartController::CreateLibrary(AbstractModule* module,
                                          const String& source,
                                          const TextPosition& textPosition) {
  Dart_Handle library = Dart_LoadLibrary(
      StringToDart(dart_state(), module->UrlForLibraryAt(textPosition)),
      StringToDart(dart_state(), source), textPosition.m_line.zeroBasedInt(),
      textPosition.m_column.zeroBasedInt());

  if (LogIfError(library))
    return nullptr;

  if (!ImportChildLibraries(module, library))
    return nullptr;

  return library;
}

void DartController::LoadScriptInModule(
    AbstractModule* module,
    const String& source,
    const TextPosition& position,
    const LoadFinishedCallback& finished_callback) {
  DartIsolateScope isolate_scope(dart_state()->isolate());
  DartApiScope dart_api_scope;

  DartDependencyCatcher dependency_catcher(dart_state()->loader());
  Dart_Handle library_handle = CreateLibrary(module, source, position);
  if (!library_handle)
    return finished_callback.Run(nullptr, nullptr);
  RefPtr<DartValue> library = DartValue::Create(dart_state(), library_handle);
  module->AddLibrary(library, position);

  // TODO(eseidel): Better if the library/module retained its dependencies and
  // dependency waiting could be separate from library creation.
  dart_state()->loader().WaitForDependencies(
      dependency_catcher.dependencies(),
      base::Bind(finished_callback, module, library));
}

void DartController::ExecuteLibraryInModule(AbstractModule* module,
                                            Dart_Handle library,
                                            HTMLScriptElement* script) {
  ASSERT(library);
  DCHECK(Dart_CurrentIsolate() == dart_state()->isolate());
  DartApiScope dart_api_scope;

  // Don't continue if we failed to load the module.
  if (LogIfError(Dart_FinalizeLoading(true)))
    return;
  const char* name = module->isApplication() ? "main" : "_init";

  // main() is required, but init() is not:
  // TODO(rmacnak): Dart_LookupFunction won't find re-exports, etc.
  Dart_Handle entry = Dart_LookupFunction(library, ToDart(name));
  if (module->isApplication()) {
    LogIfError(Dart_Invoke(library, ToDart(name), 0, nullptr));
    return;
  }

  if (!Dart_IsFunction(entry))
    return;

  Dart_Handle args[] = {
    ToDart(script),
  };
  LogIfError(Dart_Invoke(library, ToDart(name), arraysize(args), args));
}

static void UnhandledExceptionCallback(Dart_Handle error) {
  DCHECK(!Dart_IsError(error));
  LOG(ERROR) << Dart_GetError(error);
}

static Dart_Handle LibraryTagHandler(Dart_LibraryTag tag,
                                     Dart_Handle library,
                                     Dart_Handle url) {
  return DartLoader::HandleLibraryTag(tag, library, url);
}

static void IsolateShutdownCallback(void* callback_data) {
  // TODO(dart)
}

static bool IsServiceIsolateURL(const char* url_name) {
  return url_name != nullptr &&
      String(url_name) == DART_VM_SERVICE_ISOLATE_NAME;
}

// TODO(rafaelw): Right now this only supports the creation of the handle
// watcher isolate. Presumably, we'll want application isolates to spawn their
// own isolates.
static Dart_Isolate IsolateCreateCallback(const char* script_uri,
                                          const char* main,
                                          const char* package_root,
                                          void* callback_data,
                                          char** error) {

  if (IsServiceIsolateURL(script_uri)) {
    return Dart_CreateIsolate(script_uri, "main", kDartSnapshotBuffer, nullptr,
          error);
  }

  // Create & start the handle watcher isolate
  CHECK(kDartSnapshotBuffer);
  DartState* dart_state = new DartState();
  Dart_Isolate isolate = Dart_CreateIsolate("sky:handle_watcher", "",
      kDartSnapshotBuffer, dart_state, error);
  CHECK(isolate) << error;
  dart_state->set_isolate(isolate);

  CHECK(!LogIfError(Dart_SetLibraryTagHandler(LibraryTagHandler)));

  {
    DartApiScope apiScope;
    Builtin::SetNativeResolver(Builtin::kBuiltinLibrary);
    Builtin::SetNativeResolver(Builtin::kMojoCoreLibrary);
  }

  Dart_ExitIsolate();

  CHECK(Dart_IsolateMakeRunnable(isolate));
  return isolate;
}

static void CallHandleMessage(base::WeakPtr<DartState> dart_state) {
  if (!dart_state)
    return;

  DartIsolateScope scope(dart_state->isolate());
  DartApiScope api_scope;
  LogIfError(Dart_HandleMessage());
}

static void MessageNotifyCallback(Dart_Isolate dest_isolate) {
  DCHECK(Platform::current());
  Platform::current()->mainThreadTaskRunner()->PostTask(FROM_HERE,
      base::Bind(&CallHandleMessage, DartState::From(dest_isolate)->GetWeakPtr()));
}

static void EnsureHandleWatcherStarted() {
  static bool handle_watcher_started = false;
  if (handle_watcher_started)
    return;

  // TODO(dart): Call Dart_Cleanup (ensure the handle watcher isolate is closed)
  // during shutdown.
  Dart_Handle mojo_core_lib =
      Builtin::LoadAndCheckLibrary(Builtin::kMojoCoreLibrary);
  CHECK(!LogIfError((mojo_core_lib)));
  Dart_Handle handle_watcher_type = Dart_GetType(
      mojo_core_lib,
      Dart_NewStringFromCString("MojoHandleWatcher"),
      0,
      nullptr);
  CHECK(!LogIfError(handle_watcher_type));
  CHECK(!LogIfError(Dart_Invoke(
      handle_watcher_type,
      Dart_NewStringFromCString("_start"),
      0,
      nullptr)));

  // RunLoop until the handle watcher isolate is spun-up.
  CHECK(!LogIfError(Dart_RunLoop()));
  handle_watcher_started = true;
}

void DartController::CreateIsolateFor(Document* document) {
  DCHECK(document);
  CHECK(kDartSnapshotBuffer);
  char* error = nullptr;
  dom_dart_state_ = adoptPtr(new DOMDartState(document));
  Dart_Isolate isolate = Dart_CreateIsolate(
      document->url().string().utf8().data(), "main", kDartSnapshotBuffer,
      static_cast<DartState*>(dom_dart_state_.get()), &error);
  Dart_SetMessageNotifyCallback(MessageNotifyCallback);
  CHECK(isolate) << error;
  dom_dart_state_->set_isolate(isolate);
  Dart_SetGcCallbacks(DartGCPrologue, DartGCEpilogue);
  CHECK(!LogIfError(Dart_SetLibraryTagHandler(LibraryTagHandler)));

  {
    DartApiScope apiScope;

    Builtin::SetNativeResolver(Builtin::kBuiltinLibrary);
    Builtin::SetNativeResolver(Builtin::kMojoCoreLibrary);
    BuiltinNatives::Init();

    builtin_sky_ = adoptPtr(new BuiltinSky(dart_state()));
    dart_state()->class_library().set_provider(builtin_sky_.get());
    builtin_sky_->InstallWindow(dart_state());

    document->frame()->loaderClient()->didCreateIsolate(isolate);

    EnsureHandleWatcherStarted();
  }
  Dart_ExitIsolate();
}

void DartController::ClearForClose() {
  DartIsolateScope scope(dom_dart_state_->isolate());
  Dart_ShutdownIsolate();
  dom_dart_state_.clear();
}

void DartController::InitVM() {
  int argc = 0;
  const char** argv = nullptr;

#if ENABLE(ASSERT)
  argc = arraysize(kCheckedModeArgs);
  argv = kCheckedModeArgs;
#endif

  CHECK(Dart_SetVMFlags(argc, argv));
  CHECK(Dart_Initialize(IsolateCreateCallback,
                        nullptr,  // Isolate interrupt callback.
                        UnhandledExceptionCallback, IsolateShutdownCallback,
                        // File IO callbacks.
                        nullptr, nullptr, nullptr, nullptr, nullptr));
}

} // namespace blink
