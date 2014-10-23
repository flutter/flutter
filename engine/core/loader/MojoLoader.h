// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MojoLoader_h
#define MojoLoader_h

#include "base/memory/weak_ptr.h"
#include "mojo/common/handle_watcher.h"
#include "mojo/public/cpp/system/data_pipe.h"
#include "platform/weborigin/KURL.h"

namespace blink {

class LocalFrame;

class MojoLoader {
public:
    explicit MojoLoader(LocalFrame&);

    void load(const KURL&, mojo::ScopedDataPipeConsumerHandle);

private:
    LocalFrame& m_frame;

    // FIXME: These belong on a helper object for async reading from mojo pipes.
    void readMore();
    void waitToReadMore();
    void moreDataReady(MojoResult);

    mojo::common::HandleWatcher m_handleWatcher;
    mojo::ScopedDataPipeConsumerHandle m_responseStream;
    base::WeakPtrFactory<MojoLoader> m_weakFactory;
};

}

#endif
