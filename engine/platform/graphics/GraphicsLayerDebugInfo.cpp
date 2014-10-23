/*
 * Copyright (C) 2014 Google Inc. All rights reserved.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this library; see the file COPYING.LIB.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 */

#include "config.h"

#include "platform/graphics/GraphicsLayerDebugInfo.h"

#include "wtf/text/CString.h"

namespace blink {

GraphicsLayerDebugInfo::GraphicsLayerDebugInfo()
    : m_compositingReasons(CompositingReasonNone)
{
}

GraphicsLayerDebugInfo::~GraphicsLayerDebugInfo() { }

void GraphicsLayerDebugInfo::appendAsTraceFormat(WebString* out) const
{
    RefPtr<JSONObject> jsonObject = JSONObject::create();
    appendLayoutRects(jsonObject.get());
    appendCompositingReasons(jsonObject.get());
    appendDebugName(jsonObject.get());
    appendOwnerNodeId(jsonObject.get());
    *out = jsonObject->toJSONString();
}

GraphicsLayerDebugInfo* GraphicsLayerDebugInfo::clone() const
{
    GraphicsLayerDebugInfo* toReturn = new GraphicsLayerDebugInfo();
    for (size_t i = 0; i < m_currentLayoutRects.size(); ++i)
        toReturn->currentLayoutRects().append(m_currentLayoutRects[i]);
    toReturn->setCompositingReasons(m_compositingReasons);
    toReturn->setOwnerNodeId(m_ownerNodeId);
    return toReturn;
}

void GraphicsLayerDebugInfo::appendLayoutRects(JSONObject* jsonObject) const
{
    RefPtr<JSONArray> jsonArray = JSONArray::create();
    for (size_t i = 0; i < m_currentLayoutRects.size(); i++) {
        const LayoutRect& rect = m_currentLayoutRects[i];
        RefPtr<JSONObject> rectContainer = JSONObject::create();
        RefPtr<JSONArray> rectArray = JSONArray::create();
        rectArray->pushNumber(rect.x().toFloat());
        rectArray->pushNumber(rect.y().toFloat());
        rectArray->pushNumber(rect.maxX().toFloat());
        rectArray->pushNumber(rect.maxY().toFloat());
        rectContainer->setArray("geometry_rect", rectArray);
        jsonArray->pushObject(rectContainer);
    }
    jsonObject->setArray("layout_rects", jsonArray);
}

void GraphicsLayerDebugInfo::appendCompositingReasons(JSONObject* jsonObject) const
{
    RefPtr<JSONArray> jsonArray = JSONArray::create();
    for (size_t i = 0; i < kNumberOfCompositingReasons; ++i) {
        if (!(m_compositingReasons & kCompositingReasonStringMap[i].reason))
            continue;
        jsonArray->pushString(kCompositingReasonStringMap[i].description);
    }
    jsonObject->setArray("compositing_reasons", jsonArray);
}

void GraphicsLayerDebugInfo::appendDebugName(JSONObject* jsonObject) const
{
    if (m_debugName.isEmpty())
        return;

    jsonObject->setString("layer_name", m_debugName);
}

void GraphicsLayerDebugInfo::appendOwnerNodeId(JSONObject* jsonObject) const
{
    if (!m_ownerNodeId)
        return;

    jsonObject->setNumber("owner_node", m_ownerNodeId);
}

} // namespace blink
