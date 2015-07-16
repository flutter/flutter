// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Windows doesn't support pthread_key_create's destr_function, and in fact
// it's a bit tricky to get code to run when a thread exits.  This is
// cargo-cult magic from http://www.codeproject.com/threads/tls.asp.
// We are trying to be compatible with both a LoadLibrary style invocation, as
// well as static linking. This code only needs to be included if we use
// LoadLibrary, but it hooks into the "standard" set of TLS callbacks that are
// provided for static linking.

// This code is deliberately written to match the style of calls seen in
// base/threading/thread_local_storage_win.cc.  Please keep the two in sync if
// coding conventions are changed.

// WARNING: Do *NOT* try to include this in the construction of the base
// library, even though it potentially drives code in
// base/threading/thread_local_storage_win.cc.  If you do, some users will end
// up getting duplicate definition of DllMain() in some of their later links.

// Force a reference to _tls_used to make the linker create the TLS directory
// if it's not already there (that is, even if __declspec(thread) is not used).
// Force a reference to p_thread_callback_dllmain_typical_entry to prevent whole
// program optimization from discarding the variables.

#include <windows.h>

#include "base/compiler_specific.h"
#include "base/win/win_util.h"

// Indicate if another service is scanning the callbacks.  When this becomes
// set to true, then DllMain() will stop supporting the callback service. This
// value is set to true the first time any of our callbacks are called, as that
// shows that some other service is handling callbacks.
static bool linker_notifications_are_active = false;

// This will be our mostly no-op callback that we'll list.  We won't
// deliberately call it, and if it is called, that means we don't need to do any
// of the callbacks anymore.  We expect such a call to arrive via a
// THREAD_ATTACH message, long before we'd have to perform our THREAD_DETACH
// callbacks.
static void NTAPI on_callback(PVOID h, DWORD reason, PVOID reserved);

#ifdef _WIN64

#pragma comment(linker, "/INCLUDE:_tls_used")
#pragma comment(linker, "/INCLUDE:p_thread_callback_dllmain_typical_entry")

#else  // _WIN64

#pragma comment(linker, "/INCLUDE:__tls_used")
#pragma comment(linker, "/INCLUDE:_p_thread_callback_dllmain_typical_entry")

#endif  // _WIN64

// Explicitly depend on VC\crt\src\tlssup.c variables
// to bracket the list of TLS callbacks.
extern "C" PIMAGE_TLS_CALLBACK __xl_a, __xl_z;

// extern "C" suppresses C++ name mangling so we know the symbol names for the
// linker /INCLUDE:symbol pragmas above.
extern "C" {
#ifdef _WIN64

// .CRT section is merged with .rdata on x64 so it must be constant data.
#pragma data_seg(push, old_seg)
// Use a typical possible name in the .CRT$XL? list of segments.
#pragma const_seg(".CRT$XLB")
// When defining a const variable, it must have external linkage to be sure the
// linker doesn't discard it.
extern const PIMAGE_TLS_CALLBACK p_thread_callback_dllmain_typical_entry;
const PIMAGE_TLS_CALLBACK p_thread_callback_dllmain_typical_entry = on_callback;
#pragma data_seg(pop, old_seg)

#else  // _WIN64

#pragma data_seg(push, old_seg)
// Use a typical possible name in the .CRT$XL? list of segments.
#pragma data_seg(".CRT$XLB")
PIMAGE_TLS_CALLBACK p_thread_callback_dllmain_typical_entry = on_callback;
#pragma data_seg(pop, old_seg)

#endif  // _WIN64
}  // extern "C"

// Custom crash code to get a unique entry in crash reports.
NOINLINE static void CrashOnProcessDetach() {
  *static_cast<volatile int*>(0) = 0x356;
}

// Make DllMain call the listed callbacks.  This way any third parties that are
// linked in will also be called.
BOOL WINAPI DllMain(PVOID h, DWORD reason, PVOID reserved) {
  if (DLL_PROCESS_DETACH == reason && base::win::ShouldCrashOnProcessDetach())
    CrashOnProcessDetach();

  if (DLL_THREAD_DETACH != reason && DLL_PROCESS_DETACH != reason)
    return true;  // We won't service THREAD_ATTACH calls.

  if (linker_notifications_are_active)
    return true;  // Some other service is doing this work.

  for (PIMAGE_TLS_CALLBACK* it = &__xl_a; it < &__xl_z; ++it) {
    if (*it == NULL || *it == on_callback)
      continue;  // Don't bother to call our own callback.
    (*it)(h, reason, reserved);
  }
  return true;
}

static void NTAPI on_callback(PVOID h, DWORD reason, PVOID reserved) {
  // Do nothing.  We were just a place holder in the list used to test that we
  // call all items.
  // If we are called, it means that some other system is scanning the callbacks
  // and we don't need to do so in DllMain().
  linker_notifications_are_active = true;
  // Note: If some other routine some how plays this same game... we could both
  // decide not to do the scanning <sigh>, but this trick should suppress
  // duplicate calls on Vista, where the runtime takes care of the callbacks,
  // and allow us to do the callbacks on XP, where we are currently devoid of
  // callbacks (due to an explicit LoadLibrary call).
}
