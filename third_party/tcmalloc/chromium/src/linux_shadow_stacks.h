// Copyright (c) 2006-2010 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef THIRD_PARTY_TCMALLOC_CHROMIUM_SRC_LINUX_SHADOW_STACKS_H__
#define THIRD_PARTY_TCMALLOC_CHROMIUM_SRC_LINUX_SHADOW_STACKS_H__

#define NO_INSTRUMENT __attribute__((no_instrument_function))

extern "C" {
void init()  NO_INSTRUMENT;
void __cyg_profile_func_enter(void *this_fn, void *call_site)  NO_INSTRUMENT;
void __cyg_profile_func_exit(void *this_fn, void *call_site)  NO_INSTRUMENT;
void *get_shadow_ip_stack(int *index /*OUT*/) NO_INSTRUMENT;
void *get_shadow_sp_stack(int *index /*OUT*/) NO_INSTRUMENT;
}

#undef NO_INSTRUMENT

#endif  // THIRD_PARTY_TCMALLOC_CHROMIUM_SRC_LINUX_SHADOW_STACKS_H__
