// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"

#include "platform/TracedValue.h"

#include "platform/JSONValues.h"

namespace blink {

namespace {

String threadSafeCopy(const String& string)
{
    RefPtr<StringImpl> copy(string.impl());
    if (string.isSafeToSendToAnotherThread())
        return string;
    return string.isolatedCopy();
}

}

PassRefPtr<TracedValue> TracedValue::create()
{
    return adoptRef(new TracedValue());
}

TracedValue::TracedValue()
{
    m_stack.append(JSONObject::create());
}

TracedValue::~TracedValue()
{
    ASSERT(m_stack.size() == 1);
}

void TracedValue::setInteger(const char* name, int value)
{
    currentDictionary()->setNumber(name, value);
}

void TracedValue::setDouble(const char* name, double value)
{
    currentDictionary()->setNumber(name, value);
}

void TracedValue::setBoolean(const char* name, bool value)
{
    currentDictionary()->setBoolean(name, value);
}

void TracedValue::setString(const char* name, const String& value)
{
    currentDictionary()->setString(name, threadSafeCopy(value));
}

void TracedValue::beginDictionary(const char* name)
{
    RefPtr<JSONObject> dictionary = JSONObject::create();
    currentDictionary()->setObject(name, dictionary);
    m_stack.append(dictionary);
}

void TracedValue::beginArray(const char* name)
{
    RefPtr<JSONArray> array = JSONArray::create();
    currentDictionary()->setArray(name, array);
    m_stack.append(array);
}

void TracedValue::endDictionary()
{
    ASSERT(m_stack.size() > 1);
    ASSERT(currentDictionary());
    m_stack.removeLast();
}

void TracedValue::pushInteger(int value)
{
    currentArray()->pushInt(value);
}

void TracedValue::pushDouble(double value)
{
    currentArray()->pushNumber(value);
}

void TracedValue::pushBoolean(bool value)
{
    currentArray()->pushBoolean(value);
}

void TracedValue::pushString(const String& value)
{
    currentArray()->pushString(threadSafeCopy(value));
}

void TracedValue::beginArray()
{
    RefPtr<JSONArray> array = JSONArray::create();
    currentArray()->pushArray(array);
    m_stack.append(array);
}

void TracedValue::beginDictionary()
{
    RefPtr<JSONObject> dictionary = JSONObject::create();
    currentArray()->pushObject(dictionary);
    m_stack.append(dictionary);
}

void TracedValue::endArray()
{
    ASSERT(m_stack.size() > 1);
    ASSERT(currentArray());
    m_stack.removeLast();
}

String TracedValue::asTraceFormat() const
{
    ASSERT(m_stack.size() == 1);
    return m_stack.first()->toJSONString();
}

JSONObject* TracedValue::currentDictionary() const
{
    ASSERT(!m_stack.isEmpty());
    ASSERT(m_stack.last()->type() == JSONValue::TypeObject);
    return static_cast<JSONObject*>(m_stack.last().get());
}

JSONArray* TracedValue::currentArray() const
{
    ASSERT(!m_stack.isEmpty());
    ASSERT(m_stack.last()->type() == JSONValue::TypeArray);
    return static_cast<JSONArray*>(m_stack.last().get());
}

}
