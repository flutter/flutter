// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/core/inspector/ConsoleMessage.h"

#include "sky/engine/wtf/CurrentTime.h"
#include "sky/engine/wtf/PassOwnPtr.h"

namespace blink {

ConsoleMessage::ConsoleMessage(MessageSource source,
    MessageLevel level,
    const String& message,
    const String& url,
    unsigned lineNumber,
    unsigned columnNumber)
    : m_source(source)
    , m_level(level)
    , m_type(LogMessageType)
    , m_message(message)
    , m_scriptId(0)
    , m_url(url)
    , m_lineNumber(lineNumber)
    , m_columnNumber(columnNumber)
    , m_requestIdentifier(0)
    , m_timestamp(WTF::currentTime())
{
}

ConsoleMessage::~ConsoleMessage()
{
}

MessageType ConsoleMessage::type() const
{
    return m_type;
}

void ConsoleMessage::setType(MessageType type)
{
    m_type = type;
}

int ConsoleMessage::scriptId() const
{
    return m_scriptId;
}

void ConsoleMessage::setScriptId(int scriptId)
{
    m_scriptId = scriptId;
}

const String& ConsoleMessage::url() const
{
    return m_url;
}

void ConsoleMessage::setURL(const String& url)
{
    m_url = url;
}

unsigned ConsoleMessage::lineNumber() const
{
    return m_lineNumber;
}

void ConsoleMessage::setLineNumber(unsigned lineNumber)
{
    m_lineNumber = lineNumber;
}

unsigned long ConsoleMessage::requestIdentifier() const
{
    return m_requestIdentifier;
}

void ConsoleMessage::setRequestIdentifier(unsigned long requestIdentifier)
{
    m_requestIdentifier = requestIdentifier;
}

double ConsoleMessage::timestamp() const
{
    return m_timestamp;
}

void ConsoleMessage::setTimestamp(double timestamp)
{
    m_timestamp = timestamp;
}

MessageSource ConsoleMessage::source() const
{
    return m_source;
}

MessageLevel ConsoleMessage::level() const
{
    return m_level;
}

const String& ConsoleMessage::message() const
{
    return m_message;
}

unsigned ConsoleMessage::columnNumber() const
{
    return m_columnNumber;
}

} // namespace blink
