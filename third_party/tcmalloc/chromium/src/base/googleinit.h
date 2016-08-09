// Copyright (c) 2005, Google Inc.
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
// Author: Jacob Hoffman-Andrews

#ifndef _GOOGLEINIT_H
#define _GOOGLEINIT_H

#include "base/logging.h"

class GoogleInitializer {
 public:
  typedef void (*VoidFunction)(void);
  GoogleInitializer(const char* name, VoidFunction ctor, VoidFunction dtor)
      : /* name_(name), */ destructor_(dtor) {
    // TODO(dmikurube): Re-enable the commented-out code.
    // We commented out the following line, since Chromium does not have the
    // proper includes to log using these macros.
    //
    // Commended-out code:
    //   RAW_VLOG(10, "<GoogleModuleObject> constructing: %s\n", name_);
    //
    // This googleinit.h is included from out of third_party/tcmalloc, such as
    // net/tools/flip_server/balsa_headers.cc.
    // "base/logging.h" (included above) indicates Chromium's base/logging.h
    // when this googleinit.h is included from out of third_party/tcmalloc.
    if (ctor)
      ctor();
  }
  ~GoogleInitializer() {
    // TODO(dmikurube): Re-enable the commented-out code.
    // The same as above.  The following line is commented out in Chromium.
    //
    // Commended-out code:
    //   RAW_VLOG(10, "<GoogleModuleObject> destroying: %s\n", name_);
    if (destructor_)
      destructor_();
  }

 private:
  // TODO(dmikurube): Re-enable the commented-out code.
  // const char* const name_;
  const VoidFunction destructor_;
};

#define REGISTER_MODULE_INITIALIZER(name, body)                 \
  namespace {                                                   \
    static void google_init_module_##name () { body; }          \
    GoogleInitializer google_initializer_module_##name(#name,   \
            google_init_module_##name, NULL);                   \
  }

#define REGISTER_MODULE_DESTRUCTOR(name, body)                  \
  namespace {                                                   \
    static void google_destruct_module_##name () { body; }      \
    GoogleInitializer google_destructor_module_##name(#name,    \
            NULL, google_destruct_module_##name);               \
  }


#endif /* _GOOGLEINIT_H */
