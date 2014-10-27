/*
 * Copyright (c) 2014, Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "config.h"
#include "core/dom/Document.h"

#include "core/html/HTMLLinkElement.h"
#include "core/testing/DummyPageHolder.h"
#include "platform/heap/Handle.h"
#include <gmock/gmock.h>
#include <gtest/gtest.h>

using namespace blink;

namespace {

class DocumentTest : public ::testing::Test {
protected:
    virtual void SetUp() override;

    Document& document() const { return m_dummyPageHolder->document(); }
    Page& page() const { return m_dummyPageHolder->page(); }

private:
    OwnPtr<DummyPageHolder> m_dummyPageHolder;
};

void DocumentTest::SetUp()
{
    m_dummyPageHolder = DummyPageHolder::create(IntSize(800, 600));
}

class MockDocumentVisibilityObserver
    : public NoBaseWillBeGarbageCollectedFinalized<MockDocumentVisibilityObserver>
    , public DocumentVisibilityObserver {
    WILL_BE_USING_GARBAGE_COLLECTED_MIXIN(MockDocumentVisibilityObserver);
public:
    static PassOwnPtrWillBeRawPtr<MockDocumentVisibilityObserver> create(Document& document)
    {
        return adoptPtrWillBeNoop(new MockDocumentVisibilityObserver(document));
    }

    virtual void trace(Visitor*) { }

    MOCK_METHOD1(didChangeVisibilityState, void(PageVisibilityState));

private:
    MockDocumentVisibilityObserver(Document& document) : DocumentVisibilityObserver(document) { }
};

TEST_F(DocumentTest, VisibilityOberver)
{
    page().setVisibilityState(PageVisibilityStateVisible, true); // initial state
    OwnPtrWillBeRawPtr<MockDocumentVisibilityObserver> observer1 = MockDocumentVisibilityObserver::create(document());

    {
        OwnPtrWillBeRawPtr<MockDocumentVisibilityObserver> observer2 = MockDocumentVisibilityObserver::create(document());
        EXPECT_CALL(*observer1, didChangeVisibilityState(PageVisibilityStateHidden)).Times(0);
        EXPECT_CALL(*observer1, didChangeVisibilityState(PageVisibilityStateVisible)).Times(0);
        EXPECT_CALL(*observer2, didChangeVisibilityState(PageVisibilityStateHidden)).Times(0);
        EXPECT_CALL(*observer2, didChangeVisibilityState(PageVisibilityStateVisible)).Times(0);
        ::testing::Mock::VerifyAndClearExpectations(observer1.get());
        ::testing::Mock::VerifyAndClearExpectations(observer2.get());

        EXPECT_CALL(*observer1, didChangeVisibilityState(PageVisibilityStateHidden)).Times(1);
        EXPECT_CALL(*observer1, didChangeVisibilityState(PageVisibilityStateVisible)).Times(0);
        EXPECT_CALL(*observer2, didChangeVisibilityState(PageVisibilityStateHidden)).Times(1);
        EXPECT_CALL(*observer2, didChangeVisibilityState(PageVisibilityStateVisible)).Times(0);
        page().setVisibilityState(PageVisibilityStateHidden, false);
        ::testing::Mock::VerifyAndClearExpectations(observer1.get());
        ::testing::Mock::VerifyAndClearExpectations(observer2.get());

        EXPECT_CALL(*observer1, didChangeVisibilityState(PageVisibilityStateHidden)).Times(0);
        EXPECT_CALL(*observer1, didChangeVisibilityState(PageVisibilityStateVisible)).Times(0);
        EXPECT_CALL(*observer2, didChangeVisibilityState(PageVisibilityStateHidden)).Times(0);
        EXPECT_CALL(*observer2, didChangeVisibilityState(PageVisibilityStateVisible)).Times(0);
        page().setVisibilityState(PageVisibilityStateHidden, false);
        ::testing::Mock::VerifyAndClearExpectations(observer1.get());
        ::testing::Mock::VerifyAndClearExpectations(observer2.get());

        EXPECT_CALL(*observer1, didChangeVisibilityState(PageVisibilityStateHidden)).Times(0);
        EXPECT_CALL(*observer1, didChangeVisibilityState(PageVisibilityStateVisible)).Times(1);
        EXPECT_CALL(*observer2, didChangeVisibilityState(PageVisibilityStateHidden)).Times(0);
        EXPECT_CALL(*observer2, didChangeVisibilityState(PageVisibilityStateVisible)).Times(0);
        OwnPtr<DummyPageHolder> alternatePage = DummyPageHolder::create(IntSize(800, 600));
        Document& alternateDocument = alternatePage->document();
        observer2->setObservedDocument(alternateDocument);
        page().setVisibilityState(PageVisibilityStateVisible, false);
        ::testing::Mock::VerifyAndClearExpectations(observer1.get());
        ::testing::Mock::VerifyAndClearExpectations(observer2.get());

        EXPECT_CALL(*observer1, didChangeVisibilityState(PageVisibilityStateHidden)).Times(1);
        EXPECT_CALL(*observer1, didChangeVisibilityState(PageVisibilityStateVisible)).Times(0);
        EXPECT_CALL(*observer2, didChangeVisibilityState(PageVisibilityStateHidden)).Times(1);
        EXPECT_CALL(*observer2, didChangeVisibilityState(PageVisibilityStateVisible)).Times(0);
        observer2->setObservedDocument(document());
        page().setVisibilityState(PageVisibilityStateHidden, false);
        ::testing::Mock::VerifyAndClearExpectations(observer1.get());
        ::testing::Mock::VerifyAndClearExpectations(observer2.get());
    }

    // observer2 destroyed
    EXPECT_CALL(*observer1, didChangeVisibilityState(PageVisibilityStateHidden)).Times(0);
    EXPECT_CALL(*observer1, didChangeVisibilityState(PageVisibilityStateVisible)).Times(1);
    page().setVisibilityState(PageVisibilityStateVisible, false);
}

} // unnamed namespace
