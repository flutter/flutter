/*
 * Copyright (C) 2013 Google Inc. All rights reserved.
 * Copyright (C) 2013 Samsung Electronics. All rights reserved.
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
#include "core/rendering/GraphicsContextAnnotator.h"

#include "core/inspector/InspectorNodeIds.h"
#include "core/rendering/PaintInfo.h"
#include "core/rendering/RenderObject.h"
#include "platform/graphics/GraphicsContextAnnotation.h"
#include "wtf/text/StringBuilder.h"

namespace {

const char AnnotationKeyRendererName[]    = "RENDERER";
const char AnnotationKeyPaintPhase[]      = "PHASE";
const char AnnotationKeyElementId[]       = "ID";
const char AnnotationKeyElementClass[]    = "CLASS";
const char AnnotationKeyElementTag[]      = "TAG";
const char AnnotationKeyInspectorNodeId[] = "INSPECTOR_ID";

static const char* paintPhaseName(blink::PaintPhase phase)
{
    switch (phase) {
    case blink::PaintPhaseBlockBackground:
        return "BlockBackground";
    case blink::PaintPhaseChildBlockBackground:
        return "ChildBlockBackground";
    case blink::PaintPhaseChildBlockBackgrounds:
        return "ChildBlockBackgrounds";
    case blink::PaintPhaseFloat:
        return "Float";
    case blink::PaintPhaseForeground:
        return "Foreground";
    case blink::PaintPhaseOutline:
        return "Outline";
    case blink::PaintPhaseChildOutlines:
        return "ChildOutlines";
    case blink::PaintPhaseSelfOutline:
        return "SelfOutline";
    case blink::PaintPhaseSelection:
        return "Selection";
    case blink::PaintPhaseCollapsedTableBorders:
        return "CollapsedTableBorders";
    case blink::PaintPhaseTextClip:
        return "TextClip";
    case blink::PaintPhaseMask:
        return "Mask";
    case blink::PaintPhaseClippingMask:
        return "ClippingMask";
    default:
        ASSERT_NOT_REACHED();
        return "<unknown>";
    }
}

}

namespace blink {

void GraphicsContextAnnotator::annotate(const PaintInfo& paintInfo, const RenderObject* object)
{
    ASSERT(!m_context);

    ASSERT(paintInfo.context);
    ASSERT(object);

    AnnotationList annotations;
    AnnotationModeFlags mode = paintInfo.context->annotationMode();
    Element* element = object->node() && object->node()->isElementNode() ? toElement(object->node()) : 0;

    if (mode & AnnotateRendererName)
        annotations.append(std::make_pair(AnnotationKeyRendererName, object->renderName()));

    if (mode & AnnotatePaintPhase)
        annotations.append(std::make_pair(AnnotationKeyPaintPhase, paintPhaseName(paintInfo.phase)));

    if ((mode & AnnotateElementId) && element && element->hasID())
        annotations.append(std::make_pair(AnnotationKeyElementId, element->getIdAttribute().string()));

    if ((mode & AnnotateElementClass) && element && element->hasClass()) {
        SpaceSplitString classes = element->classNames();
        if (!classes.isNull() && classes.size() > 0) {
            StringBuilder classBuilder;
            for (size_t i = 0; i < classes.size(); ++i) {
                if (i > 0)
                    classBuilder.append(' ');
                classBuilder.append(classes[i]);
            }

            annotations.append(std::make_pair(AnnotationKeyElementClass, classBuilder.toString()));
        }
    }

    if ((mode & AnnotateElementTag) && element)
        annotations.append(std::make_pair(AnnotationKeyElementTag, element->tagName()));

    if (mode & AnnotateInspectorId) {
        if (Node* ownerNode = object->generatingNode()) {
            annotations.append(std::make_pair(AnnotationKeyInspectorNodeId,
                String::number(InspectorNodeIds::idForNode(ownerNode))));
        }
    }

    m_context = paintInfo.context;
    m_context->beginAnnotation(annotations);
}

void GraphicsContextAnnotator::finishAnnotation()
{
    ASSERT(m_context);
    m_context->endAnnotation();
}

} // namespace blink
