#include "sky/engine/config.h"
#include "sky/engine/bindings-dart/dart_master.h"

#include "base/logging.h"

namespace mojo {
namespace dart {

extern const uint8_t* snapshot_buffer;
}
}

namespace blink {

static Dart_Isolate IsolateCreateCallback(const char* script_uri,
                                          const char* main,
                                          const char* package_root,
                                          void* callback_data,
                                          char** error) {
  // LOG(INFO) << "IsolateCreateCallback";
  return nullptr;
}

static void UnhandledExceptionCallback(Dart_Handle error) {
  // LOG(INFO) << "UnhandledExceptionCallback";
}

static void IsolateShutdownCallback(void* callback_data) {
  // LOG(INFO) << "IsolateShutdownCallback";
}

static Dart_Isolate ServiceIsolateCreateCallback(void* callback_data,
                                                 char** error) {
  // LOG(INFO) << "ServiceIsolateCreateCallback";
  return nullptr;
}

void DartMaster::InitVM() {
  bool result = Dart_SetVMFlags(0, NULL);

  result = Dart_Initialize(IsolateCreateCallback,
                           nullptr,  // Isolate interrupt callback.
                           UnhandledExceptionCallback, IsolateShutdownCallback,
                           // File IO callbacks.
                           nullptr, nullptr, nullptr, nullptr, nullptr,
                           ServiceIsolateCreateCallback);

  char* error;
  Dart_Isolate isolate = Dart_CreateIsolate(
      "bogus:uri", "main", mojo::dart::snapshot_buffer, nullptr, &error);

  CHECK(isolate);

  Dart_EnterScope();

  Dart_Handle library = Dart_LoadLibrary(
      Dart_NewStringFromCString("foo:bar"),
      Dart_NewStringFromCString("main() { int foo = 2; foo++; return foo; }"),
      0, 0);

  Dart_FinalizeLoading(true);

  if (Dart_IsError(library)) {
    LOG(INFO) << Dart_GetError(library);
    abort();
  }

  Dart_Handle invoke_result =
      Dart_Invoke(library, Dart_NewStringFromCString("main"), 0, nullptr);
  if (Dart_IsError(invoke_result)) {
    LOG(INFO) << Dart_GetError(invoke_result);
    abort();
  }

  CHECK(Dart_IsInteger(invoke_result));
  Dart_Handle str = Dart_ToString(invoke_result);
  const char* xyz = "invalid";
  Dart_StringToCString(str, &xyz);
  LOG(INFO) << xyz;
}
}
