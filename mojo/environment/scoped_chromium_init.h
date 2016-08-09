// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_ENVIRONMENT_SCOPED_CHROMIUM_INIT_H_
#define MOJO_ENVIRONMENT_SCOPED_CHROMIUM_INIT_H_

#include "base/at_exit.h"
#include "base/macros.h"

namespace mojo {

// Using code from //base typically requires that a number of things be
// initialized/present. In particular the global |base::CommandLine| singleton
// should be initialized and an |AtExitManager| should be present.
//
// This class is a simple helper that does these things (and tears down the
// |AtExitManager| on destruction). Typically, it should be used in |MojoMain()|
// as follows:
//
//   MojoResult MojoMain(MojoHandle application_request) {
//     mojo::ScopedBaseInit init;
//     ...
//   }
//
// TODO(vtl): Maybe this should be called |ScopedBaseInit|, but for now I'm
// being consistent with everything else that refers to things that use //base
// as "chromium".
class ScopedChromiumInit {
 public:
  ScopedChromiumInit();
  ~ScopedChromiumInit();

 private:
  base::AtExitManager at_exit_manager_;

  DISALLOW_COPY_AND_ASSIGN(ScopedChromiumInit);
};

}  // namespace mojo

#endif  // MOJO_ENVIRONMENT_SCOPED_CHROMIUM_INIT_H_
