/*
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
 * THIS SOFTWARE IS PROVIDED BY GOOGLE AND ITS CONTRIBUTORS "AS IS" AND ANY
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

#include "sky/engine/config.h"
#include "sky/engine/core/inspector/InspectorState.h"

// #include "core/inspector/InspectorStateClient.h"
#include "sky/engine/core/inspector/JSONParser.h"
#include "sky/engine/wtf/PassOwnPtr.h"

namespace blink {

InspectorState::InspectorState(InspectorStateUpdateListener* listener, PassRefPtr<JSONObject> properties)
    : m_listener(listener)
    , m_properties(properties)
{
}

void InspectorState::updateCookie()
{
    if (m_listener)
        m_listener->inspectorStateUpdated();
}

void InspectorState::setFromCookie(PassRefPtr<JSONObject> properties)
{
    m_properties = properties;
}

void InspectorState::setValue(const String& propertyName, PassRefPtr<JSONValue> value)
{
    m_properties->setValue(propertyName, value);
    updateCookie();
}

void InspectorState::remove(const String& propertyName)
{
    m_properties->remove(propertyName);
    updateCookie();
}

bool InspectorState::getBoolean(const String& propertyName)
{
    JSONObject::iterator it = m_properties->find(propertyName);
    bool value = false;
    if (it != m_properties->end())
        it->value->asBoolean(&value);
    return value;
}

String InspectorState::getString(const String& propertyName)
{
    JSONObject::iterator it = m_properties->find(propertyName);
    String value;
    if (it != m_properties->end())
        it->value->asString(&value);
    return value;
}

long InspectorState::getLong(const String& propertyName)
{
    return getLong(propertyName, 0);
}


long InspectorState::getLong(const String& propertyName, long defaultValue)
{
    JSONObject::iterator it = m_properties->find(propertyName);
    long value = defaultValue;
    if (it != m_properties->end())
        it->value->asNumber(&value);
    return value;
}

double InspectorState::getDouble(const String& propertyName)
{
    return getDouble(propertyName, 0);
}

double InspectorState::getDouble(const String& propertyName, double defaultValue)
{
    JSONObject::iterator it = m_properties->find(propertyName);
    double value = defaultValue;
    if (it != m_properties->end())
        it->value->asNumber(&value);
    return value;
}

PassRefPtr<JSONObject> InspectorState::getObject(const String& propertyName)
{
    JSONObject::iterator it = m_properties->find(propertyName);
    if (it == m_properties->end()) {
        m_properties->setObject(propertyName, JSONObject::create());
        it = m_properties->find(propertyName);
    }
    return it->value->asObject();
}

InspectorState* InspectorCompositeState::createAgentState(const String& agentName)
{
    ASSERT(m_stateObject->find(agentName) == m_stateObject->end());
    ASSERT(m_inspectorStateMap.find(agentName) == m_inspectorStateMap.end());
    RefPtr<JSONObject> stateProperties = JSONObject::create();
    m_stateObject->setObject(agentName, stateProperties);
    OwnPtr<InspectorState> statePtr = adoptPtr(new InspectorState(this, stateProperties));
    InspectorState* state = statePtr.get();
    m_inspectorStateMap.add(agentName, statePtr.release());
    return state;
}

void InspectorCompositeState::loadFromCookie(const String& inspectorCompositeStateCookie)
{
    RefPtr<JSONValue> cookie = parseJSON(inspectorCompositeStateCookie);
    if (cookie)
        m_stateObject = cookie->asObject();
    if (!m_stateObject)
        m_stateObject = JSONObject::create();

    InspectorStateMap::iterator end = m_inspectorStateMap.end();
    for (InspectorStateMap::iterator it = m_inspectorStateMap.begin(); it != end; ++it) {
        RefPtr<JSONObject> agentStateObject = m_stateObject->getObject(it->key);
        if (!agentStateObject) {
            agentStateObject = JSONObject::create();
            m_stateObject->setObject(it->key, agentStateObject);
        }
        it->value->setFromCookie(agentStateObject);
    }
}

void InspectorCompositeState::mute()
{
    m_isMuted = true;
}

void InspectorCompositeState::unmute()
{
    m_isMuted = false;
}

void InspectorCompositeState::inspectorStateUpdated()
{
    // FIXME(Sky): tell clients?
}

} // namespace blink

