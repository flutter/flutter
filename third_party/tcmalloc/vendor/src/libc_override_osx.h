// Copyright (c) 2011, Google Inc.
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

// ---
// Author: Craig Silverstein <opensource@google.com>
//
// Used to override malloc routines on OS X systems.  We use the
// malloc-zone functionality built into OS X to register our malloc
// routine.
//
// 1) We used to use the normal 'override weak libc malloc/etc'
// technique for OS X.  This is not optimal because mach does not
// support the 'alias' attribute, so we had to have forwarding
// functions.  It also does not work very well with OS X shared
// libraries (dylibs) -- in general, the shared libs don't use
// tcmalloc unless run with the DYLD_FORCE_FLAT_NAMESPACE envvar.
//
// 2) Another approach would be to use an interposition array:
//      static const interpose_t interposers[] __attribute__((section("__DATA, __interpose"))) = {
//        { (void *)tc_malloc, (void *)malloc },
//        { (void *)tc_free, (void *)free },
//      };
// This requires the user to set the DYLD_INSERT_LIBRARIES envvar, so
// is not much better.
//
// 3) Registering a new malloc zone avoids all these issues:
//  http://www.opensource.apple.com/source/Libc/Libc-583/include/malloc/malloc.h
//  http://www.opensource.apple.com/source/Libc/Libc-583/gen/malloc.c
// If we make tcmalloc the default malloc zone (undocumented but
// possible) then all new allocs use it, even those in shared
// libraries.  Allocs done before tcmalloc was installed, or in libs
// that aren't using tcmalloc for some reason, will correctly go
// through the malloc-zone interface when free-ing, and will pick up
// the libc free rather than tcmalloc free.  So it should "never"
// cause a crash (famous last words).
//
// 4) The routines one must define for one's own malloc have changed
// between OS X versions.  This requires some hoops on our part, but
// is only really annoying when it comes to posix_memalign.  The right
// behavior there depends on what OS version tcmalloc was compiled on,
// but also what OS version the program is running on.  For now, we
// punt and don't implement our own posix_memalign.  Apps that really
// care can use tc_posix_memalign directly.

#ifndef TCMALLOC_LIBC_OVERRIDE_OSX_INL_H_
#define TCMALLOC_LIBC_OVERRIDE_OSX_INL_H_

#include <config.h>
#ifdef HAVE_FEATURES_H
#include <features.h>
#endif
#include <gperftools/tcmalloc.h>

#if !defined(__APPLE__)
# error libc_override_glibc-osx.h is for OS X distributions only.
#endif

#include <AvailabilityMacros.h>
#include <malloc/malloc.h>

// from AvailabilityMacros.h
#if defined(MAC_OS_X_VERSION_10_6) && \
    MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6
extern "C" {
  // This function is only available on 10.6 (and later) but the
  // LibSystem headers do not use AvailabilityMacros.h to handle weak
  // importing automatically.  This prototype is a copy of the one in
  // <malloc/malloc.h> with the WEAK_IMPORT_ATTRBIUTE added.
  extern malloc_zone_t *malloc_default_purgeable_zone(void)
      WEAK_IMPORT_ATTRIBUTE;
}
#endif

// We need to provide wrappers around all the libc functions.
namespace {
size_t mz_size(malloc_zone_t* zone, const void* ptr) {
  if (MallocExtension::instance()->GetOwnership(ptr) != MallocExtension::kOwned)
    return 0;  // malloc_zone semantics: return 0 if we don't own the memory

  // TODO(csilvers): change this method to take a const void*, one day.
  return MallocExtension::instance()->GetAllocatedSize(const_cast<void*>(ptr));
}

void* mz_malloc(malloc_zone_t* zone, size_t size) {
  return tc_malloc(size);
}

void* mz_calloc(malloc_zone_t* zone, size_t num_items, size_t size) {
  return tc_calloc(num_items, size);
}

void* mz_valloc(malloc_zone_t* zone, size_t size) {
  return tc_valloc(size);
}

void mz_free(malloc_zone_t* zone, void* ptr) {
  return tc_free(ptr);
}

void* mz_realloc(malloc_zone_t* zone, void* ptr, size_t size) {
  return tc_realloc(ptr, size);
}

void* mz_memalign(malloc_zone_t* zone, size_t align, size_t size) {
  return tc_memalign(align, size);
}

void mz_destroy(malloc_zone_t* zone) {
  // A no-op -- we will not be destroyed!
}

// malloc_introspection callbacks.  I'm not clear on what all of these do.
kern_return_t mi_enumerator(task_t task, void *,
                            unsigned type_mask, vm_address_t zone_address,
                            memory_reader_t reader,
                            vm_range_recorder_t recorder) {
  // Should enumerate all the pointers we have.  Seems like a lot of work.
  return KERN_FAILURE;
}

size_t mi_good_size(malloc_zone_t *zone, size_t size) {
  // I think it's always safe to return size, but we maybe could do better.
  return size;
}

boolean_t mi_check(malloc_zone_t *zone) {
  return MallocExtension::instance()->VerifyAllMemory();
}

void mi_print(malloc_zone_t *zone, boolean_t verbose) {
  int bufsize = 8192;
  if (verbose)
    bufsize = 102400;   // I picked this size arbitrarily
  char* buffer = new char[bufsize];
  MallocExtension::instance()->GetStats(buffer, bufsize);
  fprintf(stdout, "%s", buffer);
  delete[] buffer;
}

void mi_log(malloc_zone_t *zone, void *address) {
  // I don't think we support anything like this
}

void mi_force_lock(malloc_zone_t *zone) {
  // Hopefully unneeded by us!
}

void mi_force_unlock(malloc_zone_t *zone) {
  // Hopefully unneeded by us!
}

void mi_statistics(malloc_zone_t *zone, malloc_statistics_t *stats) {
  // TODO(csilvers): figure out how to fill these out
  stats->blocks_in_use = 0;
  stats->size_in_use = 0;
  stats->max_size_in_use = 0;
  stats->size_allocated = 0;
}

boolean_t mi_zone_locked(malloc_zone_t *zone) {
  return false;  // Hopefully unneeded by us!
}

}  // unnamed namespace

// OS X doesn't have pvalloc, cfree, malloc_statc, etc, so we can just
// define our own. :-)  OS X supplies posix_memalign in some versions
// but not others, either strongly or weakly linked, in a way that's
// difficult enough to code to correctly, that I just don't try to
// support either memalign() or posix_memalign().  If you need them
// and are willing to code to tcmalloc, you can use tc_posix_memalign().
extern "C" {
  void  cfree(void* p)                   { tc_cfree(p);               }
  void* pvalloc(size_t s)                { return tc_pvalloc(s);      }
  void malloc_stats(void)                { tc_malloc_stats();         }
  int mallopt(int cmd, int v)            { return tc_mallopt(cmd, v); }
  // No struct mallinfo on OS X, so don't define mallinfo().
  // An alias for malloc_size(), which OS X defines.
  size_t malloc_usable_size(void* p)     { return tc_malloc_size(p); }
}  // extern "C"

static void ReplaceSystemAlloc() {
  static malloc_introspection_t tcmalloc_introspection;
  memset(&tcmalloc_introspection, 0, sizeof(tcmalloc_introspection));

  tcmalloc_introspection.enumerator = &mi_enumerator;
  tcmalloc_introspection.good_size = &mi_good_size;
  tcmalloc_introspection.check = &mi_check;
  tcmalloc_introspection.print = &mi_print;
  tcmalloc_introspection.log = &mi_log;
  tcmalloc_introspection.force_lock = &mi_force_lock;
  tcmalloc_introspection.force_unlock = &mi_force_unlock;

  static malloc_zone_t tcmalloc_zone;
  memset(&tcmalloc_zone, 0, sizeof(malloc_zone_t));

  // Start with a version 4 zone which is used for OS X 10.4 and 10.5.
  tcmalloc_zone.version = 4;
  tcmalloc_zone.zone_name = "tcmalloc";
  tcmalloc_zone.size = &mz_size;
  tcmalloc_zone.malloc = &mz_malloc;
  tcmalloc_zone.calloc = &mz_calloc;
  tcmalloc_zone.valloc = &mz_valloc;
  tcmalloc_zone.free = &mz_free;
  tcmalloc_zone.realloc = &mz_realloc;
  tcmalloc_zone.destroy = &mz_destroy;
  tcmalloc_zone.batch_malloc = NULL;
  tcmalloc_zone.batch_free = NULL;
  tcmalloc_zone.introspect = &tcmalloc_introspection;

  // from AvailabilityMacros.h
#if defined(MAC_OS_X_VERSION_10_6) && \
    MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6
  // Switch to version 6 on OSX 10.6 to support memalign.
  tcmalloc_zone.version = 6;
  tcmalloc_zone.free_definite_size = NULL;
  tcmalloc_zone.memalign = &mz_memalign;
  tcmalloc_introspection.zone_locked = &mi_zone_locked;

  // Request the default purgable zone to force its creation. The
  // current default zone is registered with the purgable zone for
  // doing tiny and small allocs.  Sadly, it assumes that the default
  // zone is the szone implementation from OS X and will crash if it
  // isn't.  By creating the zone now, this will be true and changing
  // the default zone won't cause a problem.  This only needs to
  // happen when actually running on OS X 10.6 and higher (note the
  // ifdef above only checks if we were *compiled* with 10.6 or
  // higher; at runtime we have to check if this symbol is defined.)
  if (malloc_default_purgeable_zone) {
    malloc_default_purgeable_zone();
  }
#endif

  // Register the tcmalloc zone. At this point, it will not be the
  // default zone.
  malloc_zone_register(&tcmalloc_zone);

  // Unregister and reregister the default zone.  Unregistering swaps
  // the specified zone with the last one registered which for the
  // default zone makes the more recently registered zone the default
  // zone.  The default zone is then re-registered to ensure that
  // allocations made from it earlier will be handled correctly.
  // Things are not guaranteed to work that way, but it's how they work now.
  malloc_zone_t *default_zone = malloc_default_zone();
  malloc_zone_unregister(default_zone);
  malloc_zone_register(default_zone);
}

#endif  // TCMALLOC_LIBC_OVERRIDE_OSX_INL_H_
