// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "core/loader/MojoLoader.h"

#include "base/bind.h"
#include "core/dom/Document.h"
#include "core/dom/DocumentInit.h"
#include "core/frame/LocalDOMWindow.h"
#include "core/frame/LocalFrame.h"
#include "mojo/public/cpp/system/data_pipe.h"
#include "core/loader/FrameLoaderClient.h"
#include "core/page/Page.h"
#include "core/dom/DocumentParser.h"

namespace blink {

using namespace mojo;

MojoLoader::MojoLoader(LocalFrame& frame)
    : m_frame(frame)
{
}

void MojoLoader::load(const KURL& url, ScopedDataPipeConsumerHandle responseStream)
{
    DocumentInit init(url, &m_frame);
    init.withNewRegistrationContext();

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
