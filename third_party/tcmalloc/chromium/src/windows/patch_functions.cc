// Copyright (c) 2007, Google Inc.
// All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
// 
//     * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//     * Neither the name of Google Inc. nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// ---
// Author: Craig Silverstein
//
// The main purpose of this file is to patch the libc allocation
// routines (malloc and friends, but also _msize and other
// windows-specific libc-style routines).  However, we also patch
// windows routines to do accounting.  We do better at the former than
// the latter.  Here are some comments from Paul Pluzhnikov about what
// it might take to do a really good job patching windows routines to
// keep track of memory usage:
//
// "You should intercept at least the following:
//     HeapCreate HeapDestroy HeapAlloc HeapReAlloc HeapFree
//     RtlCreateHeap RtlDestroyHeap RtlAllocateHeap RtlFreeHeap
//     malloc calloc realloc free
//     malloc_dbg calloc_dbg realloc_dbg free_dbg
// Some of these call the other ones (but not always), sometimes
// recursively (i.e. HeapCreate may call HeapAlloc on a different
// heap, IIRC)."
//
// Since Paul didn't mention VirtualAllocEx, he may not have even been
// considering all the mmap-like functions that windows has (or he may
// just be ignoring it because he's seen we already patch it).  Of the
// above, we do not patch the *_dbg functions, and of the windows
// functions, we only patch HeapAlloc and HeapFree.
//
// The *_dbg functions come into play with /MDd, /MTd, and /MLd,
// probably.  It may be ok to just turn off tcmalloc in those cases --
// if the user wants the windows debug malloc, they probably don't
// want tcmalloc!  We should also test with all of /MD, /MT, and /ML,
// which we're not currently doing.

// TODO(csilvers): try to do better here?  Paul does conclude:
//                 "Keeping track of all of this was a nightmare."

#ifndef _WIN32
# error You should only be including windows/patch_functions.cc in a windows environment!
#endif

#include <config.h>

#ifdef WIN32_OVERRIDE_ALLOCATORS
#error This file is intended for patching allocators - use override_functions.cc instead.
#endif

// We use psapi.  Non-MSVC systems will have to link this in themselves.
#ifdef _MSC_VER
#pragma comment(lib, "Psapi.lib")
#endif

// Make sure we always use the 'old' names of the psapi functions.
#ifndef PSAPI_VERSION
#define PSAPI_VERSION 1
#endif

#include <windows.h>
#include <stdio.h>
#include <malloc.h>       // for _msize and _expand
#include <Psapi.h>        // for EnumProcessModules, GetModuleInformation, etc.
#include <set>
#include <map>
#include <vector>
#include <base/logging.h>
#include "base/spinlock.h"
#include "gperftools/malloc_hook.h"
#include "malloc_hook-inl.h"
#include "preamble_patcher.h"

// The maximum number of modules we allow to be in one executable
const int kMaxModules = 8182;

// These are hard-coded, unfortunately. :-( They are also probably
// compiler specific.  See get_mangled_names.cc, in this directory,
// for instructions on how to update these names for your compiler.
const char kMangledNew[] = "??2@YAPAXI@Z";
const char kMangledNewArray[] = "??_U@YAPAXI@Z";
const char kMangledDelete[] = "??3@YAXPAX@Z";
const char kMangledDeleteArray[] = "??_V@YAXPAX@Z";
const char kMangledNewNothrow[] = "??2@YAPAXIABUnothrow_t@std@@@Z";
const char kMangledNewArrayNothrow[] = "??_U@YAPAXIABUnothrow_t@std@@@Z";
const char kMangledDeleteNothrow[] = "??3@YAXPAXABUnothrow_t@std@@@Z";
const char kMangledDeleteArrayNothrow[] = "??_V@YAXPAXABUnothrow_t@std@@@Z";

// This is an unused but exported symbol that we can use to tell the
// MSVC linker to bring in libtcmalloc, via the /INCLUDE linker flag.
// Without this, the linker will likely decide that libtcmalloc.dll
// doesn't add anything to the executable (since it does all its work
// through patching, which the linker can't see), and ignore it
// entirely.  (The name 'tcmalloc' is already reserved for a
// namespace.  I'd rather export a variable named "_tcmalloc", but I
// couldn't figure out how to get that to work.  This function exports
// the symbol "__tcmalloc".)
extern "C" PERFTOOLS_DLL_DECL void _tcmalloc();
void _tcmalloc() { }

// This is the version needed for windows x64, which has a different
// decoration scheme which doesn't auto-add a leading underscore.
extern "C" PERFTOOLS_DLL_DECL void __tcmalloc();
void __tcmalloc() { }

namespace {    // most everything here is in an unnamed namespace

typedef void (*GenericFnPtr)();

using sidestep::PreamblePatcher;

struct ModuleEntryCopy;   // defined below

// These functions are how we override the memory allocation
// functions, just like tcmalloc.cc and malloc_hook.cc do.

// This is information about the routines we're patching, for a given
// module that implements libc memory routines.  A single executable
// can have several libc implementations running about (in different
// .dll's), and we need to patch/unpatch them all.  This defines
// everything except the new functions we're patching in, which
// are defined in LibcFunctions, below.
class LibcInfo {
 public:
  LibcInfo() {
    memset(this, 0, sizeof(*this));  // easiest way to initialize the array
  }

  bool patched() const { return is_valid(); }
  void set_is_valid(bool b) { is_valid_ = b; }
  // According to http://msdn.microsoft.com/en-us/library/ms684229(VS.85).aspx:
  // "The load address of a module (lpBaseOfDll) is the same as the HMODULE
  // value."
  HMODULE hmodule() const {
    return reinterpret_cast<HMODULE>(const_cast<void*>(module_base_address_));
  }

  // Populates all the windows_fn_[] vars based on our module info.
  // Returns false if windows_fn_ is all NULL's, because there's
  // nothing to patch.  Also populates the rest of the module_entry
  // info, such as the module's name.
  bool PopulateWindowsFn(const ModuleEntryCopy& module_entry);

 protected:
  void CopyFrom(const LibcInfo& that) {
    if (this == &that)
      return;
    this->is_valid_ = that.is_valid_;
    memcpy(this->windows_fn_, that.windows_fn_, sizeof(windows_fn_));
    this->module_base_address_ = that.module_base_address_;
    this->module_base_size_ = that.module_base_size_;
  }

  enum {
    kMalloc, kFree, kRealloc, kCalloc,
    kNew, kNewArray, kDelete, kDeleteArray,
    kNewNothrow, kNewArrayNothrow, kDeleteNothrow, kDeleteArrayNothrow,
    // These are windows-only functions from malloc.h
    k_Msize, k_Expand,
    // A MS CRT "internal" function, implemented using _calloc_impl
    k_CallocCrt,
    kNumFunctions
  };

  // I'd like to put these together in a struct (perhaps in the
  // subclass, so we can put in perftools_fn_ as well), but vc8 seems
  // to have a bug where it doesn't initialize the struct properly if
  // we try to take the address of a function that's not yet loaded
  // from a dll, as is the common case for static_fn_.  So we need
  // each to be in its own array. :-(
  static const char* const function_name_[kNumFunctions];

  // This function is only used when statically linking the binary.
  // In that case, loading malloc/etc from the dll (via
  // PatchOneModule) won't work, since there are no dlls.  Instead,
  // you just want to be taking the address of malloc/etc directly.
  // In the common, non-static-link case, these pointers will all be
  // NULL, since this initializer runs before msvcrt.dll is loaded.
  static const GenericFnPtr static_fn_[kNumFunctions];

  // This is the address of the function we are going to patch
  // (malloc, etc).  Other info about the function is in the
  // patch-specific subclasses, below.
  GenericFnPtr windows_fn_[kNumFunctions];

  // This is set to true when this structure is initialized (because
  // we're patching a new library) and set to false when it's
  // uninitialized (because we've freed that library).
  bool is_valid_;

  const void *module_base_address_;
  size_t module_base_size_;

 public:
  // These shouldn't have to be public, since only subclasses of
  // LibcInfo need it, but they do.  Maybe something to do with
  // templates.  Shrug.  I hide them down here so users won't see
  // them. :-)  (OK, I also need to define ctrgProcAddress late.)
  bool is_valid() const { return is_valid_; }
  GenericFnPtr windows_fn(int ifunction) const {
    return windows_fn_[ifunction];
  }
  // These three are needed by ModuleEntryCopy.
  static const int ctrgProcAddress = kNumFunctions;
  static GenericFnPtr static_fn(int ifunction) {
    return static_fn_[ifunction];
  }
  static const char* const function_name(int ifunction) {
    return function_name_[ifunction];
  }
};

// Template trickiness: logically, a LibcInfo would include
// Windows_malloc_, origstub_malloc_, and Perftools_malloc_: for a
// given module, these three go together.  And in fact,
// Perftools_malloc_ may need to call origstub_malloc_, which means we
// either need to change Perftools_malloc_ to take origstub_malloc_ as
// an arugment -- unfortunately impossible since it needs to keep the
// same API as normal malloc -- or we need to write a different
// version of Perftools_malloc_ for each LibcInfo instance we create.
// We choose the second route, and use templates to implement it (we
// could have also used macros).  So to get multiple versions
// of the struct, we say "struct<1> var1; struct<2> var2;".  The price
// we pay is some code duplication, and more annoying, each instance
// of this var is a separate type.
template<int> class LibcInfoWithPatchFunctions : public LibcInfo {
 public:
  // me_info should have had PopulateWindowsFn() called on it, so the
  // module_* vars and windows_fn_ are set up.
  bool Patch(const LibcInfo& me_info);
  void Unpatch();

 private:
  // This holds the original function contents after we patch the function.
  // This has to be defined static in the subclass, because the perftools_fns
  // reference origstub_fn_.
  static GenericFnPtr origstub_fn_[kNumFunctions];

  // This is the function we want to patch in
  static const GenericFnPtr perftools_fn_[kNumFunctions];

  static void* Perftools_malloc(size_t size) __THROW;
  static void Perftools_free(void* ptr) __THROW;
  static void* Perftools_realloc(void* ptr, size_t size) __THROW;
  static void* Perftools_calloc(size_t nmemb, size_t size) __THROW;
  static void* Perftools_new(size_t size);
  static void* Perftools_newarray(size_t size);
  static void Perftools_delete(void *ptr);
  static void Perftools_deletearray(void *ptr);
  static void* Perftools_new_nothrow(size_t size,
                                     const std::nothrow_t&) __THROW;
  static void* Perftools_newarray_nothrow(size_t size,
                                          const std::nothrow_t&) __THROW;
  static void Perftools_delete_nothrow(void *ptr,
                                       const std::nothrow_t&) __THROW;
  static void Perftools_deletearray_nothrow(void *ptr,
                                            const std::nothrow_t&) __THROW;
  static size_t Perftools__msize(void *ptr) __THROW;
  static void* Perftools__expand(void *ptr, size_t size) __THROW;
  // malloc.h also defines these functions:
  //   _aligned_malloc, _aligned_free,
  //   _recalloc, _aligned_offset_malloc, _aligned_realloc, _aligned_recalloc
  //   _aligned_offset_realloc, _aligned_offset_recalloc, _malloca, _freea
  // But they seem pretty obscure, and I'm fine not overriding them for now.
  // It may be they all call into malloc/free anyway.
};

// This is a subset of MODDULEENTRY32, that we need for patching.
struct ModuleEntryCopy {
  LPVOID  modBaseAddr;     // the same as hmodule
  DWORD   modBaseSize;
  // This is not part of MODDULEENTRY32, but is needed to avoid making
  // windows syscalls while we're holding patch_all_modules_lock (see
  // lock-inversion comments at patch_all_modules_lock definition, below).
  GenericFnPtr rgProcAddresses[LibcInfo::ctrgProcAddress];

  ModuleEntryCopy() {
    modBaseAddr = NULL;
    modBaseSize = 0;
    for (int i = 0; i < sizeof(rgProcAddresses)/sizeof(*rgProcAddresses); i++)
      rgProcAddresses[i] = LibcInfo::static_fn(i);
  }
  ModuleEntryCopy(const MODULEINFO& mi) {
    this->modBaseAddr = mi.lpBaseOfDll;
    this->modBaseSize = mi.SizeOfImage;
    LPVOID modEndAddr = (char*)mi.lpBaseOfDll + mi.SizeOfImage;
    for (int i = 0; i < sizeof(rgProcAddresses)/sizeof(*rgProcAddresses); i++) {
      FARPROC target = ::GetProcAddress(
          reinterpret_cast<const HMODULE>(mi.lpBaseOfDll),
          LibcInfo::function_name(i));
      // Sometimes a DLL forwards a function to a function in another
      // DLL.  We don't want to patch those forwarded functions --
      // they'll get patched when the other DLL is processed.
      if (target >= modBaseAddr && target < modEndAddr)
        rgProcAddresses[i] = (GenericFnPtr)target;
      else
        rgProcAddresses[i] = (GenericFnPtr)NULL;
    }
  }
};

// This class is easier because there's only one of them.
class WindowsInfo {
 public:
  void Patch();
  void Unpatch();

 private:
  // TODO(csilvers): should we be patching GlobalAlloc/LocalAlloc instead,
  //                 for pre-XP systems?
  enum {
    kHeapAlloc, kHeapFree, kVirtualAllocEx, kVirtualFreeEx,
    kMapViewOfFileEx, kUnmapViewOfFile, kLoadLibraryExW, kFreeLibrary,
    kNumFunctions
  };

  struct FunctionInfo {
    const char* const name;          // name of fn in a module (eg "malloc")
    GenericFnPtr windows_fn;         // the fn whose name we call (&malloc)
    GenericFnPtr origstub_fn;        // original fn contents after we patch
    const GenericFnPtr perftools_fn; // fn we want to patch in
  };

  static FunctionInfo function_info_[kNumFunctions];

  // A Windows-API equivalent of malloc and free
  static LPVOID WINAPI Perftools_HeapAlloc(HANDLE hHeap, DWORD dwFlags,
                                           DWORD_PTR dwBytes);
  static BOOL WINAPI Perftools_HeapFree(HANDLE hHeap, DWORD dwFlags,
                                        LPVOID lpMem);
  // A Windows-API equivalent of mmap and munmap, for "anonymous regions"
  static LPVOID WINAPI Perftools_VirtualAllocEx(HANDLE process, LPVOID address,
                                                SIZE_T size, DWORD type,
                                                DWORD protect);
  static BOOL WINAPI Perftools_VirtualFreeEx(HANDLE process, LPVOID address,
                                             SIZE_T size, DWORD type);
  // A Windows-API equivalent of mmap and munmap, for actual files
  static LPVOID WINAPI Perftools_MapViewOfFileEx(HANDLE hFileMappingObject,
                                                 DWORD dwDesiredAccess,
                                                 DWORD dwFileOffsetHigh,
                                                 DWORD dwFileOffsetLow,
                                                 SIZE_T dwNumberOfBytesToMap,
                                                 LPVOID lpBaseAddress);
  static BOOL WINAPI Perftools_UnmapViewOfFile(LPCVOID lpBaseAddress);
  // We don't need the other 3 variants because they all call this one. */
  static HMODULE WINAPI Perftools_LoadLibraryExW(LPCWSTR lpFileName,
                                                 HANDLE hFile,
                                                 DWORD dwFlags);
  static BOOL WINAPI Perftools_FreeLibrary(HMODULE hLibModule);
};

// If you run out, just add a few more to the array.  You'll also need
// to update the switch statement in PatchOneModule(), and the list in
// UnpatchWindowsFunctions().
// main_executable and main_executable_windows are two windows into
// the same executable.  One is responsible for patching the libc
// routines that live in the main executable (if any) to use tcmalloc;
// the other is responsible for patching the windows routines like
// HeapAlloc/etc to use tcmalloc.
static LibcInfoWithPatchFunctions<0> main_executable;
static LibcInfoWithPatchFunctions<1> libc1;
static LibcInfoWithPatchFunctions<2> libc2;
static LibcInfoWithPatchFunctions<3> libc3;
static LibcInfoWithPatchFunctions<4> libc4;
static LibcInfoWithPatchFunctions<5> libc5;
static LibcInfoWithPatchFunctions<6> libc6;
static LibcInfoWithPatchFunctions<7> libc7;
static LibcInfoWithPatchFunctions<8> libc8;
static LibcInfo* g_module_libcs[] = {
  &libc1, &libc2, &libc3, &libc4, &libc5, &libc6, &libc7, &libc8
};
static WindowsInfo main_executable_windows;

const char* const LibcInfo::function_name_[] = {
  "malloc", "free", "realloc", "calloc",
  kMangledNew, kMangledNewArray, kMangledDelete, kMangledDeleteArray,
  // Ideally we should patch the nothrow versions of new/delete, but
  // at least in msvcrt, nothrow-new machine-code is of a type we
  // can't patch.  Since these are relatively rare, I'm hoping it's ok
  // not to patch them.  (NULL name turns off patching.)
  NULL,  // kMangledNewNothrow,
  NULL,  // kMangledNewArrayNothrow,
  NULL,  // kMangledDeleteNothrow,
  NULL,  // kMangledDeleteArrayNothrow,
  "_msize", "_expand", "_calloc_crt",
};

// For mingw, I can't patch the new/delete here, because the
// instructions are too small to patch.  Luckily, they're so small
// because all they do is call into malloc/free, so they still end up
// calling tcmalloc routines, and we don't actually lose anything
// (except maybe some stacktrace goodness) by not patching.
const GenericFnPtr LibcInfo::static_fn_[] = {
  (GenericFnPtr)&::malloc,
  (GenericFnPtr)&::free,
  (GenericFnPtr)&::realloc,
  (GenericFnPtr)&::calloc,
#ifdef __MINGW32__
  NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,
#else
  (GenericFnPtr)(void*(*)(size_t))&::operator new,
  (GenericFnPtr)(void*(*)(size_t))&::operator new[],
  (GenericFnPtr)(void(*)(void*))&::operator delete,
  (GenericFnPtr)(void(*)(void*))&::operator delete[],
  (GenericFnPtr)
  (void*(*)(size_t, struct std::nothrow_t const &))&::operator new,
  (GenericFnPtr)
  (void*(*)(size_t, struct std::nothrow_t const &))&::operator new[],
  (GenericFnPtr)
  (void(*)(void*, struct std::nothrow_t const &))&::operator delete,
  (GenericFnPtr)
  (void(*)(void*, struct std::nothrow_t const &))&::operator delete[],
#endif
  (GenericFnPtr)&::_msize,
  (GenericFnPtr)&::_expand,
  (GenericFnPtr)&::calloc,
};

template<int T> GenericFnPtr LibcInfoWithPatchFunctions<T>::origstub_fn_[] = {
  // This will get filled in at run-time, as patching is done.
};

template<int T>
const GenericFnPtr LibcInfoWithPatchFunctions<T>::perftools_fn_[] = {
  (GenericFnPtr)&Perftools_malloc,
  (GenericFnPtr)&Perftools_free,
  (GenericFnPtr)&Perftools_realloc,
  (GenericFnPtr)&Perftools_calloc,
  (GenericFnPtr)&Perftools_new,
  (GenericFnPtr)&Perftools_newarray,
  (GenericFnPtr)&Perftools_delete,
  (GenericFnPtr)&Perftools_deletearray,
  (GenericFnPtr)&Perftools_new_nothrow,
  (GenericFnPtr)&Perftools_newarray_nothrow,
  (GenericFnPtr)&Perftools_delete_nothrow,
  (GenericFnPtr)&Perftools_deletearray_nothrow,
  (GenericFnPtr)&Perftools__msize,
  (GenericFnPtr)&Perftools__expand,
  (GenericFnPtr)&Perftools_calloc,
};

/*static*/ WindowsInfo::FunctionInfo WindowsInfo::function_info_[] = {
  { "HeapAlloc", NULL, NULL, (GenericFnPtr)&Perftools_HeapAlloc },
  { "HeapFree", NULL, NULL, (GenericFnPtr)&Perftools_HeapFree },
  { "VirtualAllocEx", NULL, NULL, (GenericFnPtr)&Perftools_VirtualAllocEx },
  { "VirtualFreeEx", NULL, NULL, (GenericFnPtr)&Perftools_VirtualFreeEx },
  { "MapViewOfFileEx", NULL, NULL, (GenericFnPtr)&Perftools_MapViewOfFileEx },
  { "UnmapViewOfFile", NULL, NULL, (GenericFnPtr)&Perftools_UnmapViewOfFile },
  { "LoadLibraryExW", NULL, NULL, (GenericFnPtr)&Perftools_LoadLibraryExW },
  { "FreeLibrary", NULL, NULL, (GenericFnPtr)&Perftools_FreeLibrary },
};

bool LibcInfo::PopulateWindowsFn(const ModuleEntryCopy& module_entry) {
  // First, store the location of the function to patch before
  // patching it.  If none of these functions are found in the module,
  // then this module has no libc in it, and we just return false.
  for (int i = 0; i < kNumFunctions; i++) {
    if (!function_name_[i])     // we can turn off patching by unsetting name
      continue;
    // The ::GetProcAddress calls were done in the ModuleEntryCopy
    // constructor, so we don't have to make any windows calls here.
    const GenericFnPtr fn = module_entry.rgProcAddresses[i];
    if (fn) {
      windows_fn_[i] = PreamblePatcher::ResolveTarget(fn);
    }
  }

  // Some modules use the same function pointer for new and new[].  If
  // we find that, set one of the pointers to NULL so we don't double-
  // patch.  Same may happen with new and nothrow-new, or even new[]
  // and nothrow-new.  It's easiest just to check each fn-ptr against
  // every other.
  for (int i = 0; i < kNumFunctions; i++) {
    for (int j = i+1; j < kNumFunctions; j++) {
      if (windows_fn_[i] == windows_fn_[j]) {
        // We NULL the later one (j), so as to minimize the chances we
        // NULL kFree and kRealloc.  See comments below.  This is fragile!
        windows_fn_[j] = NULL;
      }
    }
  }

  // There's always a chance that our module uses the same function
  // as another module that we've already loaded.  In that case, we
  // need to set our windows_fn to NULL, to avoid double-patching.
  for (int ifn = 0; ifn < kNumFunctions; ifn++) {
    for (int imod = 0;
         imod < sizeof(g_module_libcs)/sizeof(*g_module_libcs);  imod++) {
      if (g_module_libcs[imod]->is_valid() &&
          this->windows_fn(ifn) == g_module_libcs[imod]->windows_fn(ifn)) {
        windows_fn_[ifn] = NULL;
      }
    }
  }

  bool found_non_null = false;
  for (int i = 0; i < kNumFunctions; i++) {
    if (windows_fn_[i])
      found_non_null = true;
  }
  if (!found_non_null)
    return false;

  // It's important we didn't NULL out windows_fn_[kFree] or [kRealloc].
  // The reason is, if those are NULL-ed out, we'll never patch them
  // and thus never get an origstub_fn_ value for them, and when we
  // try to call origstub_fn_[kFree/kRealloc] in Perftools_free and
  // Perftools_realloc, below, it will fail.  We could work around
  // that by adding a pointer from one patch-unit to the other, but we
  // haven't needed to yet.
  CHECK(windows_fn_[kFree]);
  CHECK(windows_fn_[kRealloc]);

  // OK, we successfully populated.  Let's store our member information.
  module_base_address_ = module_entry.modBaseAddr;
  module_base_size_ = module_entry.modBaseSize;
  return true;
}

template<int T>
bool LibcInfoWithPatchFunctions<T>::Patch(const LibcInfo& me_info) {
  CopyFrom(me_info);   // copies the module_entry and the windows_fn_ array
  for (int i = 0; i < kNumFunctions; i++) {
    if (windows_fn_[i] && windows_fn_[i] != perftools_fn_[i]) {
      // if origstub_fn_ is not NULL, it's left around from a previous
      // patch.  We need to set it to NULL for the new Patch call.
      // Since we've patched Unpatch() not to delete origstub_fn_ (it
      // causes problems in some contexts, though obviously not this
      // one), we should delete it now, before setting it to NULL.
      // NOTE: casting from a function to a pointer is contra the C++
      //       spec.  It's not safe on IA64, but is on i386.  We use
      //       a C-style cast here to emphasize this is not legal C++.
      delete[] (char*)(origstub_fn_[i]);
      origstub_fn_[i] = NULL;   // Patch() will fill this in
      CHECK_EQ(sidestep::SIDESTEP_SUCCESS,
               PreamblePatcher::Patch(windows_fn_[i], perftools_fn_[i],
                                      &origstub_fn_[i]));
    }
  }
  set_is_valid(true);
  return true;
}

template<int T>
void LibcInfoWithPatchFunctions<T>::Unpatch() {
  // We have to cast our GenericFnPtrs to void* for unpatch.  This is
  // contra the C++ spec; we use C-style casts to empahsize that.
  for (int i = 0; i < kNumFunctions; i++) {
    if (windows_fn_[i])
      CHECK_EQ(sidestep::SIDESTEP_SUCCESS,
               PreamblePatcher::Unpatch((void*)windows_fn_[i],
                                        (void*)perftools_fn_[i],
                                        (void*)origstub_fn_[i]));
  }
  set_is_valid(false);
}

void WindowsInfo::Patch() {
  HMODULE hkernel32 = ::GetModuleHandleA("kernel32");
  CHECK_NE(hkernel32, NULL);

  // Unlike for libc, we know these exist in our module, so we can get
  // and patch at the same time.
  for (int i = 0; i < kNumFunctions; i++) {
    function_info_[i].windows_fn = (GenericFnPtr)
        ::GetProcAddress(hkernel32, function_info_[i].name);
    // If origstub_fn is not NULL, it's left around from a previous
    // patch.  We need to set it to NULL for the new Patch call.
    // Since we've patched Unpatch() not to delete origstub_fn_ (it
    // causes problems in some contexts, though obviously not this
    // one), we should delete it now, before setting it to NULL.
    // NOTE: casting from a function to a pointer is contra the C++
    //       spec.  It's not safe on IA64, but is on i386.  We use
    //       a C-style cast here to emphasize this is not legal C++.
    delete[] (char*)(function_info_[i].origstub_fn);
    function_info_[i].origstub_fn = NULL;  // Patch() will fill this in
    CHECK_EQ(sidestep::SIDESTEP_SUCCESS,
             PreamblePatcher::Patch(function_info_[i].windows_fn,
                                    function_info_[i].perftools_fn,
                                    &function_info_[i].origstub_fn));
  }
}

void WindowsInfo::Unpatch() {
  // We have to cast our GenericFnPtrs to void* for unpatch.  This is
  // contra the C++ spec; we use C-style casts to empahsize that.
  for (int i = 0; i < kNumFunctions; i++) {
    CHECK_EQ(sidestep::SIDESTEP_SUCCESS,
             PreamblePatcher::Unpatch((void*)function_info_[i].windows_fn,
                                      (void*)function_info_[i].perftools_fn,
                                      (void*)function_info_[i].origstub_fn));
  }
}

// You should hold the patch_all_modules_lock when calling this.
void PatchOneModuleLocked(const LibcInfo& me_info) {
  // If we don't already have info on this module, let's add it.  This
  // is where we're sad that each libcX has a different type, so we
  // can't use an array; instead, we have to use a switch statement.
  // Patch() returns false if there were no libc functions in the module.
  for (int i = 0; i < sizeof(g_module_libcs)/sizeof(*g_module_libcs); i++) {
    if (!g_module_libcs[i]->is_valid()) {   // found an empty spot to add!
      switch (i) {
        case 0: libc1.Patch(me_info); return;
        case 1: libc2.Patch(me_info); return;
        case 2: libc3.Patch(me_info); return;
        case 3: libc4.Patch(me_info); return;
        case 4: libc5.Patch(me_info); return;
        case 5: libc6.Patch(me_info); return;
        case 6: libc7.Patch(me_info); return;
        case 7: libc8.Patch(me_info); return;
      }
    }
  }
  printf("PERFTOOLS ERROR: Too many modules containing libc in this executable\n");
}

void PatchMainExecutableLocked() {
  if (main_executable.patched())
    return;    // main executable has already been patched
  ModuleEntryCopy fake_module_entry;   // make a fake one to pass into Patch()
  // No need to call PopulateModuleEntryProcAddresses on the main executable.
  main_executable.PopulateWindowsFn(fake_module_entry);
  main_executable.Patch(main_executable);
}

// This lock is subject to a subtle and annoying lock inversion
// problem: it may interact badly with unknown internal windows locks.
// In particular, windows may be holding a lock when it calls
// LoadLibraryExW and FreeLibrary, which we've patched.  We have those
// routines call PatchAllModules, which acquires this lock.  If we
// make windows system calls while holding this lock, those system
// calls may need the internal windows locks that are being held in
// the call to LoadLibraryExW, resulting in deadlock.  The solution is
// to be very careful not to call *any* windows routines while holding
// patch_all_modules_lock, inside PatchAllModules().
static SpinLock patch_all_modules_lock(SpinLock::LINKER_INITIALIZED);

// last_loaded: The set of modules that were loaded the last time
// PatchAllModules was called.  This is an optimization for only
// looking at modules that were added or removed from the last call.
static std::set<HMODULE> *g_last_loaded;

// Iterates over all the modules currently loaded by the executable,
// according to windows, and makes sure they're all patched.  Most
// modules will already be in loaded_modules, meaning we have already
// loaded and either patched them or determined they did not need to
// be patched.  Others will not, which means we need to patch them
// (if necessary).  Finally, we have to go through the existing
// g_module_libcs and see if any of those are *not* in the modules
// currently loaded by the executable.  If so, we need to invalidate
// them.  Returns true if we did any work (patching or invalidating),
// false if we were a noop.  May update loaded_modules as well.
// NOTE: you must hold the patch_all_modules_lock to access loaded_modules.
bool PatchAllModules() {
  std::vector<ModuleEntryCopy> modules;
  bool made_changes = false;

  const HANDLE hCurrentProcess = GetCurrentProcess();
  DWORD num_modules = 0;
  HMODULE hModules[kMaxModules];  // max # of modules we support in one process
  if (!::EnumProcessModules(hCurrentProcess, hModules, sizeof(hModules),
                            &num_modules)) {
    num_modules = 0;
  }
  // EnumProcessModules actually set the bytes written into hModules,
  // so we need to divide to make num_modules actually be a module-count.
  num_modules /= sizeof(*hModules);
  if (num_modules >= kMaxModules) {
    printf("PERFTOOLS ERROR: Too many modules in this executable to try"
           " to patch them all (if you need to, raise kMaxModules in"
           " patch_functions.cc).\n");
    num_modules = kMaxModules;
  }

  // Now we handle the unpatching of modules we have in g_module_libcs
  // but that were not found in EnumProcessModules.  We need to
  // invalidate them.  To speed that up, we store the EnumProcessModules
  // output in a set.
  // At the same time, we prepare for the adding of new modules, by
  // removing from hModules all the modules we know we've already
  // patched (or decided don't need to be patched).  At the end,
  // hModules will hold only the modules that we need to consider patching.
  std::set<HMODULE> currently_loaded_modules;
  {
    SpinLockHolder h(&patch_all_modules_lock);
    if (!g_last_loaded)  g_last_loaded = new std::set<HMODULE>;
    // At the end of this loop, currently_loaded_modules contains the
    // full list of EnumProcessModules, and hModules just the ones we
    // haven't handled yet.
    for (int i = 0; i < num_modules; ) {
      currently_loaded_modules.insert(hModules[i]);
      if (g_last_loaded->count(hModules[i]) > 0) {
        hModules[i] = hModules[--num_modules];  // replace element i with tail
      } else {
        i++;                                    // keep element i
      }
    }
    // Now we do the unpatching/invalidation.
    for (int i = 0; i < sizeof(g_module_libcs)/sizeof(*g_module_libcs); i++) {
      if (g_module_libcs[i]->patched() &&
          currently_loaded_modules.count(g_module_libcs[i]->hmodule()) == 0) {
        // Means g_module_libcs[i] is no longer loaded (no me32 matched).
        // We could call Unpatch() here, but why bother?  The module
        // has gone away, so nobody is going to call into it anyway.
        g_module_libcs[i]->set_is_valid(false);
        made_changes = true;
      }
    }
    // Update the loaded module cache.
    g_last_loaded->swap(currently_loaded_modules);
  }

  // Now that we know what modules are new, let's get the info we'll
  // need to patch them.  Note this *cannot* be done while holding the
  // lock, since it needs to make windows calls (see the lock-inversion
  // comments before the definition of patch_all_modules_lock).
  MODULEINFO mi;
  for (int i = 0; i < num_modules; i++) {
    if (::GetModuleInformation(hCurrentProcess, hModules[i], &mi, sizeof(mi)))
      modules.push_back(ModuleEntryCopy(mi));
  }

  // Now we can do the patching of new modules.
  {
    SpinLockHolder h(&patch_all_modules_lock);
    for (std::vector<ModuleEntryCopy>::iterator it = modules.begin();
         it != modules.end(); ++it) {
      LibcInfo libc_info;
      if (libc_info.PopulateWindowsFn(*it)) { // true==module has libc routines
        PatchOneModuleLocked(libc_info);
        made_changes = true;
      }
    }

    // Now that we've dealt with the modules (dlls), update the main
    // executable.  We do this last because PatchMainExecutableLocked
    // wants to look at how other modules were patched.
    if (!main_executable.patched()) {
      PatchMainExecutableLocked();
      made_changes = true;
    }
  }
  // TODO(csilvers): for this to be reliable, we need to also take
  // into account if we *would* have patched any modules had they not
  // already been loaded.  (That is, made_changes should ignore
  // g_last_loaded.)
  return made_changes;
}


}  // end unnamed namespace

// ---------------------------------------------------------------------
// Now that we've done all the patching machinery, let's actually
// define the functions we're patching in.  Mostly these are
// simple wrappers around the do_* routines in tcmalloc.cc.
//
// In fact, we #include tcmalloc.cc to get at the tcmalloc internal
// do_* functions, the better to write our own hook functions.
// U-G-L-Y, I know.  But the alternatives are, perhaps, worse.  This
// also lets us define _msize(), _expand(), and other windows-specific
// functions here, using tcmalloc internals, without polluting
// tcmalloc.cc.
// -------------------------------------------------------------------

// TODO(csilvers): refactor tcmalloc.cc into two files, so I can link
// against the file with do_malloc, and ignore the one with malloc.
#include "tcmalloc.cc"

template<int T>
void* LibcInfoWithPatchFunctions<T>::Perftools_malloc(size_t size) __THROW {
  void* result = do_malloc_or_cpp_alloc(size);
  MallocHook::InvokeNewHook(result, size);
  return result;
}

template<int T>
void LibcInfoWithPatchFunctions<T>::Perftools_free(void* ptr) __THROW {
  MallocHook::InvokeDeleteHook(ptr);
  // This calls the windows free if do_free decides ptr was not
  // allocated by tcmalloc.  Note it calls the origstub_free from
  // *this* templatized instance of LibcInfo.  See "template
  // trickiness" above.
  do_free_with_callback(ptr, (void (*)(void*))origstub_fn_[kFree]);
}

template<int T>
void* LibcInfoWithPatchFunctions<T>::Perftools_realloc(
    void* old_ptr, size_t new_size) __THROW {
  if (old_ptr == NULL) {
    void* result = do_malloc_or_cpp_alloc(new_size);
    MallocHook::InvokeNewHook(result, new_size);
    return result;
  }
  if (new_size == 0) {
    MallocHook::InvokeDeleteHook(old_ptr);
    do_free_with_callback(old_ptr,
                          (void (*)(void*))origstub_fn_[kFree]);
    return NULL;
  }
  return do_realloc_with_callback(
      old_ptr, new_size,
      (void (*)(void*))origstub_fn_[kFree],
      (size_t (*)(const void*))origstub_fn_[k_Msize]);
}

template<int T>
void* LibcInfoWithPatchFunctions<T>::Perftools_calloc(
    size_t n, size_t elem_size) __THROW {
  void* result = do_calloc(n, elem_size);
  MallocHook::InvokeNewHook(result, n * elem_size);
  return result;
}

template<int T>
void* LibcInfoWithPatchFunctions<T>::Perftools_new(size_t size) {
  void* p = cpp_alloc(size, false);
  MallocHook::InvokeNewHook(p, size);
  return p;
}

template<int T>
void* LibcInfoWithPatchFunctions<T>::Perftools_newarray(size_t size) {
  void* p = cpp_alloc(size, false);
  MallocHook::InvokeNewHook(p, size);
  return p;
}

template<int T>
void LibcInfoWithPatchFunctions<T>::Perftools_delete(void *p) {
  MallocHook::InvokeDeleteHook(p);
  do_free_with_callback(p, (void (*)(void*))origstub_fn_[kFree]);
}

template<int T>
void LibcInfoWithPatchFunctions<T>::Perftools_deletearray(void *p) {
  MallocHook::InvokeDeleteHook(p);
  do_free_with_callback(p, (void (*)(void*))origstub_fn_[kFree]);
}

template<int T>
void* LibcInfoWithPatchFunctions<T>::Perftools_new_nothrow(
    size_t size, const std::nothrow_t&) __THROW {
  void* p = cpp_alloc(size, true);
  MallocHook::InvokeNewHook(p, size);
  return p;
}

template<int T>
void* LibcInfoWithPatchFunctions<T>::Perftools_newarray_nothrow(
    size_t size, const std::nothrow_t&) __THROW {
  void* p = cpp_alloc(size, true);
  MallocHook::InvokeNewHook(p, size);
  return p;
}

template<int T>
void LibcInfoWithPatchFunctions<T>::Perftools_delete_nothrow(
    void *p, const std::nothrow_t&) __THROW {
  MallocHook::InvokeDeleteHook(p);
  do_free_with_callback(p, (void (*)(void*))origstub_fn_[kFree]);
}

template<int T>
void LibcInfoWithPatchFunctions<T>::Perftools_deletearray_nothrow(
    void *p, const std::nothrow_t&) __THROW {
  MallocHook::InvokeDeleteHook(p);
  do_free_with_callback(p, (void (*)(void*))origstub_fn_[kFree]);
}


// _msize() lets you figure out how much space is reserved for a
// pointer, in Windows.  Even if applications don't call it, any DLL
// with global constructors will call (transitively) something called
// __dllonexit_lk in order to make sure the destructors get called
// when the dll unloads.  And that will call msize -- horrible things
// can ensue if this is not hooked.  Other parts of libc may also call
// this internally.

template<int T>
size_t LibcInfoWithPatchFunctions<T>::Perftools__msize(void* ptr) __THROW {
  return GetSizeWithCallback(ptr, (size_t (*)(const void*))origstub_fn_[k_Msize]);
}

// We need to define this because internal windows functions like to
// call into it(?).  _expand() is like realloc but doesn't move the
// pointer.  We punt, which will cause callers to fall back on realloc.
template<int T>
void* LibcInfoWithPatchFunctions<T>::Perftools__expand(void *ptr,
                                                       size_t size) __THROW {
  return NULL;
}

LPVOID WINAPI WindowsInfo::Perftools_HeapAlloc(HANDLE hHeap, DWORD dwFlags,
                                               DWORD_PTR dwBytes) {
  LPVOID result = ((LPVOID (WINAPI *)(HANDLE, DWORD, DWORD_PTR))
                   function_info_[kHeapAlloc].origstub_fn)(
                       hHeap, dwFlags, dwBytes);
  MallocHook::InvokeNewHook(result, dwBytes);
  return result;
}

BOOL WINAPI WindowsInfo::Perftools_HeapFree(HANDLE hHeap, DWORD dwFlags,
                                            LPVOID lpMem) {
  MallocHook::InvokeDeleteHook(lpMem);
  return ((BOOL (WINAPI *)(HANDLE, DWORD, LPVOID))
          function_info_[kHeapFree].origstub_fn)(
              hHeap, dwFlags, lpMem);
}

LPVOID WINAPI WindowsInfo::Perftools_VirtualAllocEx(HANDLE process,
                                                    LPVOID address,
                                                    SIZE_T size, DWORD type,
                                                    DWORD protect) {
  LPVOID result = ((LPVOID (WINAPI *)(HANDLE, LPVOID, SIZE_T, DWORD, DWORD))
                   function_info_[kVirtualAllocEx].origstub_fn)(
                       process, address, size, type, protect);
  // VirtualAllocEx() seems to be the Windows equivalent of mmap()
  MallocHook::InvokeMmapHook(result, address, size, protect, type, -1, 0);
  return result;
}

BOOL WINAPI WindowsInfo::Perftools_VirtualFreeEx(HANDLE process, LPVOID address,
                                                 SIZE_T size, DWORD type) {
  MallocHook::InvokeMunmapHook(address, size);
  return ((BOOL (WINAPI *)(HANDLE, LPVOID, SIZE_T, DWORD))
          function_info_[kVirtualFreeEx].origstub_fn)(
              process, address, size, type);
}

LPVOID WINAPI WindowsInfo::Perftools_MapViewOfFileEx(
    HANDLE hFileMappingObject, DWORD dwDesiredAccess, DWORD dwFileOffsetHigh,
    DWORD dwFileOffsetLow, SIZE_T dwNumberOfBytesToMap, LPVOID lpBaseAddress) {
  // For this function pair, you always deallocate the full block of
  // data that you allocate, so NewHook/DeleteHook is the right API.
  LPVOID result = ((LPVOID (WINAPI *)(HANDLE, DWORD, DWORD, DWORD,
                                      SIZE_T, LPVOID))
                   function_info_[kMapViewOfFileEx].origstub_fn)(
                       hFileMappingObject, dwDesiredAccess, dwFileOffsetHigh,
                       dwFileOffsetLow, dwNumberOfBytesToMap, lpBaseAddress);
  MallocHook::InvokeNewHook(result, dwNumberOfBytesToMap);
  return result;
}

BOOL WINAPI WindowsInfo::Perftools_UnmapViewOfFile(LPCVOID lpBaseAddress) {
  MallocHook::InvokeDeleteHook(lpBaseAddress);
  return ((BOOL (WINAPI *)(LPCVOID))
          function_info_[kUnmapViewOfFile].origstub_fn)(
              lpBaseAddress);
}

// g_load_map holds a copy of windows' refcount for how many times
// each currently loaded module has been loaded and unloaded.  We use
// it as an optimization when the same module is loaded more than
// once: as long as the refcount stays above 1, we don't need to worry
// about patching because it's already patched.  Likewise, we don't
// need to unpatch until the refcount drops to 0.  load_map is
// maintained in LoadLibraryExW and FreeLibrary, and only covers
// modules explicitly loaded/freed via those interfaces.
static std::map<HMODULE, int>* g_load_map = NULL;

HMODULE WINAPI WindowsInfo::Perftools_LoadLibraryExW(LPCWSTR lpFileName,
                                                     HANDLE hFile,
                                                     DWORD dwFlags) {
  HMODULE rv;
  // Check to see if the modules is already loaded, flag 0 gets a
  // reference if it was loaded.  If it was loaded no need to call
  // PatchAllModules, just increase the reference count to match
  // what GetModuleHandleExW does internally inside windows.
  if (::GetModuleHandleExW(0, lpFileName, &rv)) {
    return rv;
  } else {
    // Not already loaded, so load it.
    rv = ((HMODULE (WINAPI *)(LPCWSTR, HANDLE, DWORD))
                  function_info_[kLoadLibraryExW].origstub_fn)(
                      lpFileName, hFile, dwFlags);
    // This will patch any newly loaded libraries, if patching needs
    // to be done.
    PatchAllModules();

    return rv;
  }
}

BOOL WINAPI WindowsInfo::Perftools_FreeLibrary(HMODULE hLibModule) {
  BOOL rv = ((BOOL (WINAPI *)(HMODULE))
             function_info_[kFreeLibrary].origstub_fn)(hLibModule);

  // Check to see if the module is still loaded by passing the base
  // address and seeing if it comes back with the same address.  If it
  // is the same address it's still loaded, so the FreeLibrary() call
  // was a noop, and there's no need to redo the patching.
  HMODULE owner = NULL;
  BOOL result = ::GetModuleHandleExW(
      (GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS |
       GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT),
      (LPCWSTR)hLibModule,
      &owner);
  if (result && owner == hLibModule)
    return rv;

  PatchAllModules();    // this will fix up the list of patched libraries
  return rv;
}


// ---------------------------------------------------------------------
// PatchWindowsFunctions()
//    This is the function that is exposed to the outside world.
//    It should be called before the program becomes multi-threaded,
//    since main_executable_windows.Patch() is not thread-safe.
// ---------------------------------------------------------------------

void PatchWindowsFunctions() {
  // This does the libc patching in every module, and the main executable.
  PatchAllModules();
  main_executable_windows.Patch();
}

#if 0
// It's possible to unpatch all the functions when we are exiting.

// The idea is to handle properly windows-internal data that is
// allocated before PatchWindowsFunctions is called.  If all
// destruction happened in reverse order from construction, then we
// could call UnpatchWindowsFunctions at just the right time, so that
// that early-allocated data would be freed using the windows
// allocation functions rather than tcmalloc.  The problem is that
// windows allocates some structures lazily, so it would allocate them
// late (using tcmalloc) and then try to deallocate them late as well.
// So instead of unpatching, we just modify all the tcmalloc routines
// so they call through to the libc rountines if the memory in
// question doesn't seem to have been allocated with tcmalloc.  I keep
// this unpatch code around for reference.

void UnpatchWindowsFunctions() {
  // We need to go back to the system malloc/etc at global destruct time,
  // so objects that were constructed before tcmalloc, using the system
  // malloc, can destroy themselves using the system free.  This depends
  // on DLLs unloading in the reverse order in which they load!
  //
  // We also go back to the default HeapAlloc/etc, just for consistency.
  // Who knows, it may help avoid weird bugs in some situations.
  main_executable_windows.Unpatch();
  main_executable.Unpatch();
  if (libc1.is_valid()) libc1.Unpatch();
  if (libc2.is_valid()) libc2.Unpatch();
  if (libc3.is_valid()) libc3.Unpatch();
  if (libc4.is_valid()) libc4.Unpatch();
  if (libc5.is_valid()) libc5.Unpatch();
  if (libc6.is_valid()) libc6.Unpatch();
  if (libc7.is_valid()) libc7.Unpatch();
  if (libc8.is_valid()) libc8.Unpatch();
}
#endif
