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
    , m_weakFactory(this)
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

    document->startParsing();
    m_responseStream = responseStream.Pass();
    readMore();
}

void MojoLoader::readMore()
{
    const void* buf = nullptr;
    uint32_t buf_size = 0;
    MojoResult rv = BeginReadDataRaw(m_responseStream.get(),
        &buf, &buf_size, MOJO_READ_DATA_FLAG_NONE);
    if (rv == MOJO_RESULT_OK) {
        m_frame.document()->parser()->appendBytes(static_cast<const char*>(buf), buf_size);
        EndReadDataRaw(m_responseStream.get(), buf_size);
        waitToReadMore();
    } else if (rv == MOJO_RESULT_SHOULD_WAIT) {
        waitToReadMore();
    } else if (rv == MOJO_RESULT_FAILED_PRECONDITION) {
        m_frame.document()->parser()->finish();
    } else {
        ASSERT_NOT_REACHED();
    }
}

void MojoLoader::waitToReadMore()
{
    m_handleWatcher.Start(m_responseStream.get(),
        MOJO_HANDLE_SIGNAL_READABLE, MOJO_DEADLINE_INDEFINITE,
        base::Bind(&MojoLoader::moreDataReady,m_weakFactory.GetWeakPtr()));
}

void MojoLoader::moreDataReady(MojoResult result)
{
    readMore();
}

}
