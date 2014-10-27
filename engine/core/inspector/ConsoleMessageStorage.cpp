// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "core/inspector/ConsoleMessageStorage.h"

#include "core/dom/Document.h"
#include "core/frame/LocalDOMWindow.h"
#include "core/frame/LocalFrame.h"
#include "core/inspector/ConsoleMessage.h"

namespace blink {

static const unsigned maxConsoleMessageCount = 1000;

ConsoleMessageStorage::ConsoleMessageStorage(ExecutionContext* context)
    : m_expiredCount(0)
    , m_context(context)
    , m_frame(nullptr)
{
}

ConsoleMessageStorage::ConsoleMessageStorage(LocalFrame* frame)
    : m_expiredCount(0)
    , m_context(nullptr)
    , m_frame(frame)
{
}

void ConsoleMessageStorage::reportMessage(PassRefPtr<ConsoleMessage> prpMessage)
{
    RefPtr<ConsoleMessage> message = prpMessage;
    message->collectCallStack();

    if (message->type() == ClearMessageType)
        clear();

    ASSERT(m_messages.size() <= maxConsoleMessageCount);
    if (m_messages.size() == maxConsoleMessageCount) {
        ++m_expiredCount;
        m_messages.removeFirst();
    }
    m_messages.append(message);
}

void ConsoleMessageStorage::clear()
{
    m_messages.clear();
    m_expiredCount = 0;
}

Vector<unsigned> ConsoleMessageStorage::argumentCounts() const
{
    Vector<unsigned> result(m_messages.size());
    for (size_t i = 0; i < m_messages.size(); ++i)
        result[i] = m_messages[i]->argumentCount();
    return result;
}

void ConsoleMessageStorage::frameWindowDiscarded(LocalDOMWindow* window)
{
    for (size_t i = 0; i < m_messages.size(); ++i)
        m_messages[i]->frameWindowDiscarded(window);
}

size_t ConsoleMessageStorage::size() const
{
    return m_messages.size();
}

ConsoleMessage* ConsoleMessageStorage::at(size_t index) const
{
    return m_messages[index].get();
}

int ConsoleMessageStorage::expiredCount() const
{
    return m_expiredCount;
}

ExecutionContext* ConsoleMessageStorage::executionContext() const
{
    return m_frame ? m_frame->document() : m_context;
}

void ConsoleMessageStorage::trace(Visitor* visitor)
{
    visitor->trace(m_messages);
    visitor->trace(m_context);
}

} // namespace blink
