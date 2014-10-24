/*
 * Copyright (C) 2012 Google Inc. All rights reserved.
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

#include "public/platform/WebMediaConstraints.h"

#include "wtf/PassRefPtr.h"
#include "wtf/RefCounted.h"

namespace blink {

class WebMediaConstraintsPrivate final : public RefCounted<WebMediaConstraintsPrivate> {
public:
    static PassRefPtr<WebMediaConstraintsPrivate> create();
    static PassRefPtr<WebMediaConstraintsPrivate> create(const WebVector<WebMediaConstraint>& optional, const WebVector<WebMediaConstraint>& mandatory);

    void getOptionalConstraints(WebVector<WebMediaConstraint>&);
    void getMandatoryConstraints(WebVector<WebMediaConstraint>&);
    bool getMandatoryConstraintValue(const WebString& name, WebString& value);
    bool getOptionalConstraintValue(const WebString& name, WebString& value);

private:
    WebMediaConstraintsPrivate(const WebVector<WebMediaConstraint>& optional, const WebVector<WebMediaConstraint>& mandatory);

    WebVector<WebMediaConstraint> m_optional;
    WebVector<WebMediaConstraint> m_mandatory;
};

PassRefPtr<WebMediaConstraintsPrivate> WebMediaConstraintsPrivate::create()
{
    WebVector<WebMediaConstraint> optional;
    WebVector<WebMediaConstraint> mandatory;
    return adoptRef(new WebMediaConstraintsPrivate(optional, mandatory));
}

PassRefPtr<WebMediaConstraintsPrivate> WebMediaConstraintsPrivate::create(const WebVector<WebMediaConstraint>& optional, const WebVector<WebMediaConstraint>& mandatory)
{
    return adoptRef(new WebMediaConstraintsPrivate(optional, mandatory));
}

WebMediaConstraintsPrivate::WebMediaConstraintsPrivate(const WebVector<WebMediaConstraint>& optional, const WebVector<WebMediaConstraint>& mandatory)
    : m_optional(optional)
    , m_mandatory(mandatory)
{
}

void WebMediaConstraintsPrivate::getOptionalConstraints(WebVector<WebMediaConstraint>& constraints)
{
    constraints = m_optional;
}

void WebMediaConstraintsPrivate::getMandatoryConstraints(WebVector<WebMediaConstraint>& constraints)
{
    constraints = m_mandatory;
}

bool WebMediaConstraintsPrivate::getMandatoryConstraintValue(const WebString& name, WebString& value)
{
    for (size_t i = 0; i < m_mandatory.size(); ++i) {
        if (m_mandatory[i].m_name == name) {
            value = m_mandatory[i].m_value;
            return true;
        }
    }
    return false;
}

bool WebMediaConstraintsPrivate::getOptionalConstraintValue(const WebString& name, WebString& value)
{
    for (size_t i = 0; i < m_optional.size(); ++i) {
        if (m_optional[i].m_name == name) {
            value = m_optional[i].m_value;
            return true;
        }
    }
    return false;
}

// WebMediaConstraints

void WebMediaConstraints::assign(const WebMediaConstraints& other)
{
    m_private = other.m_private;
}

void WebMediaConstraints::reset()
{
    m_private.reset();
}

void WebMediaConstraints::getMandatoryConstraints(WebVector<WebMediaConstraint>& constraints) const
{
    ASSERT(!isNull());
    m_private->getMandatoryConstraints(constraints);
}

void WebMediaConstraints::getOptionalConstraints(WebVector<WebMediaConstraint>& constraints) const
{
    ASSERT(!isNull());
    m_private->getOptionalConstraints(constraints);
}

bool WebMediaConstraints::getMandatoryConstraintValue(const WebString& name, WebString& value) const
{
    ASSERT(!isNull());
    return m_private->getMandatoryConstraintValue(name, value);
}

bool WebMediaConstraints::getOptionalConstraintValue(const WebString& name, WebString& value) const
{
    ASSERT(!isNull());
    return m_private->getOptionalConstraintValue(name, value);
}

void WebMediaConstraints::initialize()
{
    ASSERT(isNull());
    m_private = WebMediaConstraintsPrivate::create();
}

void WebMediaConstraints::initialize(const WebVector<WebMediaConstraint>& optional, const WebVector<WebMediaConstraint>& mandatory)
{
    ASSERT(isNull());
    m_private = WebMediaConstraintsPrivate::create(optional, mandatory);
}

} // namespace blink

