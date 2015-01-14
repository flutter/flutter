// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/core/loader/MojoLoader.h"

#include "base/bind.h"
#include "mojo/public/cpp/system/data_pipe.h"
#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/dom/DocumentInit.h"
#include "sky/engine/core/dom/DocumentParser.h"
#include "sky/engine/core/frame/LocalDOMWindow.h"
#include "sky/engine/core/frame/LocalFrame.h"
#include "sky/engine/core/loader/FrameLoaderClient.h"
#include "sky/engine/core/page/Page.h"

namespace blink {

using namespace mojo;

MojoLoader::MojoLoader(LocalFrame& frame)
    : m_frame(frame)
{
}

void MojoLoader::load(const KURL& url, ScopedDataPipeConsumerHandle responseStream)
{
    DocumentInit init(url, &m_frame);

    // FIXME(sky): Poorly named method for creating the FrameView:
    m_frame.loaderClient()->transitionToCommittedForNewPage();
    // Only needed for UseCounter, and thus probably can be removed:
    m_frame.page()->didCommitLoad(&m_frame);

    m_frame.setDOMWindow(LocalDOMWindow::create(m_frame));
    RefPtr<Document> document = m_frame.domWindow()->installNewDocument(init);
    // Unclear if we care about DocumentLoadTiming in Sky.
    document->timing()->markNavigationStart();
    document->setReadyState(Document::Loading);
    // FIXME: This should read the Content-Language out of the
    // response headers and set them on Document::contentLanguage.

    document->startParsing()->parse(responseStream.Pass(), base::Bind(base::DoNothing));
}

}
