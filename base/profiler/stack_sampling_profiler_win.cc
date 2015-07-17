// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <objbase.h>
#include <windows.h>

#include <map>
#include <utility>

#include "base/logging.h"
#include "base/profiler/native_stack_sampler.h"
#include "base/strings/string_util.h"
#include "base/strings/stringprintf.h"
#include "base/strings/utf_string_conversions.h"
#include "base/time/time.h"
#include "base/win/pe_image.h"
#include "base/win/scoped_handle.h"

namespace base {

namespace {

// Walks the stack represented by |context| from the current frame downwards,
// recording the instruction pointers for each frame in |instruction_pointers|.
int RecordStack(CONTEXT* context,
                int max_stack_size,
                const void* instruction_pointers[],
                bool* last_frame_is_unknown_function) {
#ifdef _WIN64
  *last_frame_is_unknown_function = false;

  int i = 0;
  for (; (i < max_stack_size) && context->Rip; ++i) {
    // Try to look up unwind metadata for the current function.
    ULONG64 image_base;
    PRUNTIME_FUNCTION runtime_function =
        RtlLookupFunctionEntry(context->Rip, &image_base, nullptr);

    instruction_pointers[i] = reinterpret_cast<const void*>(context->Rip);

    if (runtime_function) {
      KNONVOLATILE_CONTEXT_POINTERS nvcontext = {};
      void* handler_data;
      ULONG64 establisher_frame;
      RtlVirtualUnwind(0, image_base, context->Rip, runtime_function, context,
                       &handler_data, &establisher_frame, &nvcontext);
    } else {
      // If we don't have a RUNTIME_FUNCTION, then in theory this should be a
      // leaf function whose frame contains only a return address, at
      // RSP. However, crash data also indicates that some third party libraries
      // do not provide RUNTIME_FUNCTION information for non-leaf functions. We
      // could manually unwind the stack in the former case, but attempting to
      // do so in the latter case would produce wrong results and likely crash,
      // so just bail out.
      //
      // Ad hoc runs with instrumentation show that ~5% of stack traces end with
      // a valid leaf function. To avoid selectively omitting these traces it
      // makes sense to ultimately try to distinguish these two cases and
      // selectively unwind the stack for legitimate leaf functions. For the
      // purposes of avoiding crashes though, just ignore them all for now.
      return i;
    }
  }
  return i;
#else
  return 0;
#endif
}

// Fills in |module_handles| corresponding to the pointers to code in
// |addresses|. The module handles are returned with reference counts
// incremented and should be freed with FreeModuleHandles. See note in
// SuspendThreadAndRecordStack for why |addresses| and |module_handles| are
// arrays.
void FindModuleHandlesForAddresses(const void* const addresses[],
                             HMODULE module_handles[], int stack_depth,
                             bool last_frame_is_unknown_function) {
  const int module_frames =
      last_frame_is_unknown_function ? stack_depth - 1 : stack_depth;
  for (int i = 0; i < module_frames; ++i) {
    HMODULE module_handle = NULL;
    if (GetModuleHandleEx(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS,
                          reinterpret_cast<LPCTSTR>(addresses[i]),
                          &module_handle)) {
      // HMODULE actually represents the base address of the module, so we can
      // use it directly as an address.
      DCHECK_LE(reinterpret_cast<const void*>(module_handle), addresses[i]);
      module_handles[i] = module_handle;
    }
  }
}

// Frees the modules handles returned by FindModuleHandlesForAddresses. See note
// in SuspendThreadAndRecordStack for why |module_handles| is an array.
void FreeModuleHandles(int stack_depth, HMODULE module_handles[]) {
  for (int i = 0; i < stack_depth; ++i) {
    if (module_handles[i])
      ::FreeLibrary(module_handles[i]);
  }
}

// Gets the unique build ID for a module. Windows build IDs are created by a
// concatenation of a GUID and AGE fields found in the headers of a module. The
// GUID is stored in the first 16 bytes and the AGE is stored in the last 4
// bytes. Returns the empty string if the function fails to get the build ID.
//
// Example:
// dumpbin chrome.exe /headers | find "Format:"
//   ... Format: RSDS, {16B2A428-1DED-442E-9A36-FCE8CBD29726}, 10, ...
//
// The resulting buildID string of this instance of chrome.exe is
// "16B2A4281DED442E9A36FCE8CBD2972610".
//
// Note that the AGE field is encoded in decimal, not hex.
std::string GetBuildIDForModule(HMODULE module_handle) {
  GUID guid;
  DWORD age;
  win::PEImage(module_handle).GetDebugId(&guid, &age);
  const int kGUIDSize = 39;
  std::wstring build_id;
  int result =
      ::StringFromGUID2(guid, WriteInto(&build_id, kGUIDSize), kGUIDSize);
  if (result != kGUIDSize)
    return std::string();
  RemoveChars(build_id, L"{}-", &build_id);
  build_id += StringPrintf(L"%d", age);
  return WideToUTF8(build_id);
}

// Disables priority boost on a thread for the lifetime of the object.
class ScopedDisablePriorityBoost {
 public:
  ScopedDisablePriorityBoost(HANDLE thread_handle);
  ~ScopedDisablePriorityBoost();

 private:
  HANDLE thread_handle_;
  BOOL got_previous_boost_state_;
  BOOL boost_state_was_disabled_;

  DISALLOW_COPY_AND_ASSIGN(ScopedDisablePriorityBoost);
};

ScopedDisablePriorityBoost::ScopedDisablePriorityBoost(HANDLE thread_handle)
    : thread_handle_(thread_handle),
      got_previous_boost_state_(false),
      boost_state_was_disabled_(false) {
  got_previous_boost_state_ =
      ::GetThreadPriorityBoost(thread_handle_, &boost_state_was_disabled_);
  if (got_previous_boost_state_) {
    // Confusingly, TRUE disables priority boost.
    ::SetThreadPriorityBoost(thread_handle_, TRUE);
  }
}

ScopedDisablePriorityBoost::~ScopedDisablePriorityBoost() {
  if (got_previous_boost_state_)
    ::SetThreadPriorityBoost(thread_handle_, boost_state_was_disabled_);
}

// Suspends the thread with |thread_handle|, records the stack into
// |instruction_pointers|, then resumes the thread. Returns the size of the
// stack.
//
// IMPORTANT NOTE: No heap allocations may occur between SuspendThread and
// ResumeThread. Otherwise this code can deadlock on heap locks acquired by the
// target thread before it was suspended. This is why we pass instruction
// pointers and module handles as preallocated arrays rather than vectors, since
// vectors make it too easy to subtly allocate memory.
int SuspendThreadAndRecordStack(HANDLE thread_handle, int max_stack_size,
                                const void* instruction_pointers[],
                                bool* last_frame_is_unknown_function) {
  if (::SuspendThread(thread_handle) == -1)
    return 0;

  int stack_depth = 0;
  CONTEXT thread_context = {0};
  thread_context.ContextFlags = CONTEXT_FULL;
  if (::GetThreadContext(thread_handle, &thread_context)) {
    stack_depth = RecordStack(&thread_context, max_stack_size,
                              instruction_pointers,
                              last_frame_is_unknown_function);
  }

  // Disable the priority boost that the thread would otherwise receive on
  // resume. We do this to avoid artificially altering the dynamics of the
  // executing application any more than we already are by suspending and
  // resuming the thread.
  //
  // Note that this can racily disable a priority boost that otherwise would
  // have been given to the thread, if the thread is waiting on other wait
  // conditions at the time of SuspendThread and those conditions are satisfied
  // before priority boost is reenabled. The measured length of this window is
  // ~100us, so this should occur fairly rarely.
  ScopedDisablePriorityBoost disable_priority_boost(thread_handle);
  bool resume_thread_succeeded = ::ResumeThread(thread_handle) != -1;
  CHECK(resume_thread_succeeded) << "ResumeThread failed: " << GetLastError();

  return stack_depth;
}

class NativeStackSamplerWin : public NativeStackSampler {
 public:
  explicit NativeStackSamplerWin(win::ScopedHandle thread_handle);
  ~NativeStackSamplerWin() override;

  // StackSamplingProfiler::NativeStackSampler:
  void ProfileRecordingStarting(
      std::vector<StackSamplingProfiler::Module>* modules) override;
  void RecordStackSample(StackSamplingProfiler::Sample* sample) override;
  void ProfileRecordingStopped() override;

 private:
  // Attempts to query the module filename, base address, and id for
  // |module_handle|, and store them in |module|. Returns true if it succeeded.
  static bool GetModuleForHandle(HMODULE module_handle,
                                 StackSamplingProfiler::Module* module);

  // Gets the index for the Module corresponding to |module_handle| in
  // |modules|, adding it if it's not already present. Returns
  // StackSamplingProfiler::Frame::kUnknownModuleIndex if no Module can be
  // determined for |module|.
  size_t GetModuleIndex(HMODULE module_handle,
                        std::vector<StackSamplingProfiler::Module>* modules);

  // Copies the stack information represented by |instruction_pointers| into
  // |sample| and |modules|.
  void CopyToSample(const void* const instruction_pointers[],
                    const HMODULE module_handles[],
                    int stack_depth,
                    StackSamplingProfiler::Sample* sample,
                    std::vector<StackSamplingProfiler::Module>* modules);

  win::ScopedHandle thread_handle_;
  // Weak. Points to the modules associated with the profile being recorded
  // between ProfileRecordingStarting() and ProfileRecordingStopped().
  std::vector<StackSamplingProfiler::Module>* current_modules_;
  // Maps a module handle to the corresponding Module's index within
  // current_modules_.
  std::map<HMODULE, size_t> profile_module_index_;

  DISALLOW_COPY_AND_ASSIGN(NativeStackSamplerWin);
};

NativeStackSamplerWin::NativeStackSamplerWin(win::ScopedHandle thread_handle)
    : thread_handle_(thread_handle.Take()) {
}

NativeStackSamplerWin::~NativeStackSamplerWin() {
}

void NativeStackSamplerWin::ProfileRecordingStarting(
    std::vector<StackSamplingProfiler::Module>* modules) {
  current_modules_ = modules;
  profile_module_index_.clear();
}

void NativeStackSamplerWin::RecordStackSample(
    StackSamplingProfiler::Sample* sample) {
  DCHECK(current_modules_);

  const int max_stack_size = 64;
  const void* instruction_pointers[max_stack_size] = {0};
  HMODULE module_handles[max_stack_size] = {0};

  bool last_frame_is_unknown_function = false;
  int stack_depth = SuspendThreadAndRecordStack(
      thread_handle_.Get(), max_stack_size, instruction_pointers,
      &last_frame_is_unknown_function);
  FindModuleHandlesForAddresses(instruction_pointers, module_handles,
                                stack_depth, last_frame_is_unknown_function);
  CopyToSample(instruction_pointers, module_handles, stack_depth, sample,
               current_modules_);
  FreeModuleHandles(stack_depth, module_handles);
}

void NativeStackSamplerWin::ProfileRecordingStopped() {
  current_modules_ = nullptr;
}

// static
bool NativeStackSamplerWin::GetModuleForHandle(
    HMODULE module_handle,
    StackSamplingProfiler::Module* module) {
  wchar_t module_name[MAX_PATH];
  DWORD result_length =
      GetModuleFileName(module_handle, module_name, arraysize(module_name));
  if (result_length == 0)
    return false;

  module->filename = base::FilePath(module_name);

  module->base_address = reinterpret_cast<const void*>(module_handle);

  module->id = GetBuildIDForModule(module_handle);
  if (module->id.empty())
    return false;

  return true;
}

size_t NativeStackSamplerWin::GetModuleIndex(
    HMODULE module_handle,
    std::vector<StackSamplingProfiler::Module>* modules) {
  if (!module_handle)
    return StackSamplingProfiler::Frame::kUnknownModuleIndex;

  auto loc = profile_module_index_.find(module_handle);
  if (loc == profile_module_index_.end()) {
    StackSamplingProfiler::Module module;
    if (!GetModuleForHandle(module_handle, &module))
      return StackSamplingProfiler::Frame::kUnknownModuleIndex;
    modules->push_back(module);
    loc = profile_module_index_.insert(std::make_pair(
        module_handle, modules->size() - 1)).first;
  }

  return loc->second;
}

void NativeStackSamplerWin::CopyToSample(
    const void* const instruction_pointers[],
    const HMODULE module_handles[],
    int stack_depth,
    StackSamplingProfiler::Sample* sample,
    std::vector<StackSamplingProfiler::Module>* module) {
  sample->clear();
  sample->reserve(stack_depth);

  for (int i = 0; i < stack_depth; ++i) {
    sample->push_back(StackSamplingProfiler::Frame(
        instruction_pointers[i],
        GetModuleIndex(module_handles[i], module)));
  }
}

}  // namespace

scoped_ptr<NativeStackSampler> NativeStackSampler::Create(
    PlatformThreadId thread_id) {
#if _WIN64
  // Get the thread's handle.
  HANDLE thread_handle = ::OpenThread(
      THREAD_GET_CONTEXT | THREAD_SUSPEND_RESUME | THREAD_QUERY_INFORMATION,
      FALSE,
      thread_id);

  if (thread_handle) {
    return scoped_ptr<NativeStackSampler>(new NativeStackSamplerWin(
        win::ScopedHandle(thread_handle)));
  }
#endif
  return scoped_ptr<NativeStackSampler>();
}

}  // namespace base
