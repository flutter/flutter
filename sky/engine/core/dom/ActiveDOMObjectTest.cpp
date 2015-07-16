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


#include <gmock/gmock.h>
#include <gtest/gtest.h>
#include "core/testing/DummyPageHolder.h"
#include "sky/engine/core/dom/Document.h"

using namespace blink;

namespace {

class MockActiveDOMObject : public ActiveDOMObject {
public:
    MockActiveDOMObject(ExecutionContext* context) : ActiveDOMObject(context) { }

    MOCK_METHOD0(suspend, void());
    MOCK_METHOD0(resume, void());
    MOCK_METHOD0(stop, void());
};

class ActiveDOMObjectTest : public ::testing::Test {
protected:
    ActiveDOMObjectTest();

    Document& srcDocument() const { return m_srcPageHolder->document(); }
    Document& destDocument() const { return m_destPageHolder->document(); }
    MockActiveDOMObject& activeDOMObject() { return m_activeDOMObject; }

private:
    OwnPtr<DummyPageHolder> m_srcPageHolder;
    OwnPtr<DummyPageHolder> m_destPageHolder;
    MockActiveDOMObject m_activeDOMObject;
};

ActiveDOMObjectTest::ActiveDOMObjectTest()
    : m_srcPageHolder(DummyPageHolder::create(IntSize(800, 600)))
    , m_destPageHolder(DummyPageHolder::create(IntSize(800, 600)))
    , m_activeDOMObject(&m_srcPageHolder->document())
{
    m_activeDOMObject.suspendIfNeeded();
}

TEST_F(ActiveDOMObjectTest, NewContextObserved)
{
    unsigned initialSrcCount = srcDocument().activeDOMObjectCount();
    unsigned initialDestCount = destDocument().activeDOMObjectCount();

    EXPECT_CALL(activeDOMObject(), resume());
    activeDOMObject().didMoveToNewExecutionContext(&destDocument());

    EXPECT_EQ(initialSrcCount - 1, srcDocument().activeDOMObjectCount());
    EXPECT_EQ(initialDestCount + 1, destDocument().activeDOMObjectCount());
}

TEST_F(ActiveDOMObjectTest, MoveToActiveDocument)
{
    EXPECT_CALL(activeDOMObject(), resume());
    activeDOMObject().didMoveToNewExecutionContext(&destDocument());
}

TEST_F(ActiveDOMObjectTest, MoveToStoppedDocument)
{
    destDocument().detach();

    EXPECT_CALL(activeDOMObject(), stop());
    activeDOMObject().didMoveToNewExecutionContext(&destDocument());
}

} // unnamed namespace
