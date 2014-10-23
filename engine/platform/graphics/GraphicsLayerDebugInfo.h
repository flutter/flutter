/*
 * Copyright (C) 2014 Google Inc. All rights reserved.
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

#ifndef GraphicsLayerDebugInfo_h
#define GraphicsLayerDebugInfo_h

#include "platform/JSONValues.h"
#include "platform/geometry/LayoutRect.h"
#include "platform/graphics/CompositingReasons.h"
#include "public/platform/WebGraphicsLayerDebugInfo.h"

#include "wtf/Vector.h"

namespace blink {

class GraphicsLayerDebugInfo FINAL : public WebGraphicsLayerDebugInfo {
public:
    GraphicsLayerDebugInfo();
    virtual ~GraphicsLayerDebugInfo();

    virtual void appendAsTraceFormat(WebString* out) const OVERRIDE;

    GraphicsLayerDebugInfo* clone() const;

    void setDebugName(const String& name) { m_debugName = name; }
    CompositingReasons compositingReasons() const { return m_compositingReasons; }
    void setCompositingReasons(CompositingReasons reasons) { m_compositingReasons = reasons; }
    void setOwnerNodeId(int id) { m_ownerNodeId = id; }
    Vector<LayoutRect>& currentLayoutRects() { return m_currentLayoutRects; }

private:
    void appendLayoutRects(JSONObject*) const;
    void appendCompositingReasons(JSONObject*) const;
    void appendDebugName(JSONObject*) const;
    void appendOwnerNodeId(JSONObject*) const;

    String m_debugName;
    CompositingReasons m_compositingReasons;
    int m_ownerNodeId;
    Vector<LayoutRect> m_currentLayoutRects;
};

} // namespace blink

#endif
