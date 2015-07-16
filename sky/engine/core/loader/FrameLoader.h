/*
 * Copyright (C) 2006, 2007, 2008, 2009, 2011 Apple Inc. All rights reserved.
 * Copyright (C) 2008, 2009 Torch Mobile Inc. All rights reserved. (http://www.torchmobile.com/)
 * Copyright (C) Research In Motion Limited 2009. All rights reserved.
 * Copyright (C) 2011 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 * 3.  Neither the name of Apple Computer, Inc. ("Apple") nor the names of
 *     its contributors may be used to endorse or promote products derived
 *     from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE AND ITS CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef SKY_ENGINE_CORE_LOADER_FRAMELOADER_H_
#define SKY_ENGINE_CORE_LOADER_FRAMELOADER_H_

#include "sky/engine/core/loader/FrameLoaderTypes.h"
#include "sky/engine/platform/Timer.h"
#include "sky/engine/wtf/Forward.h"
#include "sky/engine/wtf/HashSet.h"
#include "sky/engine/wtf/OwnPtr.h"

namespace blink {

class Chrome;
class DOMWrapperWorld;
class Document;
class Event;
class Frame;
class FrameLoaderClient;
class LocalFrame;
class NavigationAction;
class Page;
class ResourceError;
class ResourceResponse;

class FrameLoader {
    WTF_MAKE_NONCOPYABLE(FrameLoader);
public:
    FrameLoader(LocalFrame*);
    ~FrameLoader();

    void init();

    LocalFrame* frame() const { return m_frame; }

    static void reportLocalLoadFailed(LocalFrame*, const String& url);

    // FIXME: These are all functions which stop loads. We have too many.
    // Warning: stopAllLoaders can and will detach the LocalFrame out from under you. All callers need to either protect the LocalFrame
    // or guarantee they won't in any way access the LocalFrame after stopAllLoaders returns.
    void stopAllLoaders();
    void stopLoading();
    bool closeURL();
    // FIXME: clear() is trying to do too many things. We should break it down into smaller functions.
    void clear();

    void finishedParsing();

private:
    LocalFrame* m_frame;

    bool m_inStopAllLoaders;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_LOADER_FRAMELOADER_H_
