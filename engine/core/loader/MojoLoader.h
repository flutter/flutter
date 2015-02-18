// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_LOADER_MOJOLOADER_H_
#define SKY_ENGINE_CORE_LOADER_MOJOLOADER_H_

#include "mojo/public/cpp/system/data_pipe.h"
#include "sky/engine/platform/weborigin/KURL.h"

namespace blink {

class LocalFrame;

class MojoLoader {
public:
    explicit MojoLoader(LocalFrame&);

    void init(const KURL&);
    void parse(mojo::ScopedDataPipeConsumerHandle);

private:
    LocalFrame& m_frame;
};

}

#endif  // SKY_ENGINE_CORE_LOADER_MOJOLOADER_H_
