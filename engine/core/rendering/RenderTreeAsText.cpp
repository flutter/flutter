/*
 * Copyright (C) 2004, 2006, 2007 Apple Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE COMPUTER, INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE COMPUTER, INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "sky/engine/config.h"
#include "sky/engine/core/rendering/RenderTreeAsText.h"

#include "sky/engine/core/css/StylePropertySet.h"
#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/editing/FrameSelection.h"
#include "sky/engine/core/frame/FrameView.h"
#include "sky/engine/core/frame/LocalFrame.h"
#include "sky/engine/core/html/HTMLElement.h"
#include "sky/engine/core/rendering/InlineTextBox.h"
#include "sky/engine/core/rendering/RenderInline.h"
#include "sky/engine/core/rendering/RenderLayer.h"
#include "sky/engine/core/rendering/RenderView.h"
#include "sky/engine/wtf/HexNumber.h"
#include "sky/engine/wtf/Vector.h"
#include "sky/engine/wtf/unicode/CharacterNames.h"

namespace blink {

static void printBorderStyle(TextStream& ts, const EBorderStyle borderStyle)
{
    switch (borderStyle) {
        case BNONE:
            ts << "none";
            break;
        case BHIDDEN:
            ts << "hidden";
            break;
        case INSET:
            ts << "inset";
            break;
        case GROOVE:
            ts << "groove";
            break;
        case RIDGE:
            ts << "ridge";
            break;
        case OUTSET:
            ts << "outset";
            break;
        case DOTTED:
            ts << "dotted";
            break;
        case DASHED:
            ts << "dashed";
            break;
        case SOLID:
            ts << "solid";
            break;
        case DOUBLE:
            ts << "double";
            break;
    }

    ts << " ";
}

static bool isEmptyOrUnstyledAppleStyleSpan(const Node* node)
{
    return false;
}

String quoteAndEscapeNonPrintables(const String& s)
{
    StringBuilder result;
    result.append('"');
    for (unsigned i = 0; i != s.length(); ++i) {
        UChar c = s[i];
        if (c == '\\') {
            result.append('\\');
            result.append('\\');
        } else if (c == '"') {
            result.append('\\');
            result.append('"');
        } else if (c == '\n' || c == noBreakSpace)
            result.append(' ');
        else {
            if (c >= 0x20 && c < 0x7F)
                result.append(c);
            else {
                result.append('\\');
                result.append('x');
                result.append('{');
                appendUnsignedAsHex(c, result);
                result.append('}');
            }
        }
    }
    result.append('"');
    return result.toString();
}

void RenderTreeAsText::writeRenderObject(TextStream& ts, const RenderObject& o, RenderAsTextBehavior behavior)
{
    ts << o.renderName();

    if (behavior & RenderAsTextShowAddresses)
        ts << " " << static_cast<const void*>(&o);

    if (o.style() && o.style()->zIndex())
        ts << " zI: " << o.style()->zIndex();

    if (o.node()) {
        String tagName = o.node()->nodeName();
        if (!tagName.isEmpty()) {
            ts << " {" << tagName << "}";
            // flag empty or unstyled AppleStyleSpan because we never
            // want to leave them in the DOM
            if (isEmptyOrUnstyledAppleStyleSpan(o.node()))
                ts << " *empty or unstyled AppleStyleSpan*";
        }
    }

    LayoutRect r;
    if (o.isText()) {
        // FIXME: Would be better to dump the bounding box x and y rather than the first run's x and y, but that would involve updating
        // many test results.
        const RenderText& text = toRenderText(o);
        IntRect linesBox = text.linesBoundingBox();
        r = IntRect(text.firstRunX(), text.firstRunY(), linesBox.width(), linesBox.height());
    } else if (o.isRenderInline()) {
        // FIXME: Would be better not to just dump 0, 0 as the x and y here.
        const RenderInline& inlineFlow = toRenderInline(o);
        r = IntRect(0, 0, inlineFlow.linesBoundingBox().width(), inlineFlow.linesBoundingBox().height());
    } else if (o.isBox())
        r = toRenderBox(&o)->frameRect();

    ts << " " << r;

    if (!o.isText()) {
        if (o.parent()) {
            Color color = o.resolveColor(CSSPropertyColor);
            if (o.parent()->resolveColor(CSSPropertyColor) != color)
                ts << " [color=" << color.nameForRenderTreeAsText() << "]";

            // Do not dump invalid or transparent backgrounds, since that is the default.
            Color backgroundColor = o.resolveColor(CSSPropertyBackgroundColor);
            if (o.parent()->resolveColor(CSSPropertyBackgroundColor) != backgroundColor
                && backgroundColor.rgb())
                ts << " [bgcolor=" << backgroundColor.nameForRenderTreeAsText() << "]";

            Color textFillColor = o.resolveColor(CSSPropertyWebkitTextFillColor);
            if (o.parent()->resolveColor(CSSPropertyWebkitTextFillColor) != textFillColor
                && textFillColor != color && textFillColor.rgb())
                ts << " [textFillColor=" << textFillColor.nameForRenderTreeAsText() << "]";

            Color textStrokeColor = o.resolveColor(CSSPropertyWebkitTextStrokeColor);
            if (o.parent()->resolveColor(CSSPropertyWebkitTextStrokeColor) != textStrokeColor
                && textStrokeColor != color && textStrokeColor.rgb())
                ts << " [textStrokeColor=" << textStrokeColor.nameForRenderTreeAsText() << "]";

            if (o.parent()->style()->textStrokeWidth() != o.style()->textStrokeWidth() && o.style()->textStrokeWidth() > 0)
                ts << " [textStrokeWidth=" << o.style()->textStrokeWidth() << "]";
        }

        if (!o.isBoxModelObject())
            return;

        const RenderBoxModelObject& box = toRenderBoxModelObject(o);
        if (box.borderTop() || box.borderRight() || box.borderBottom() || box.borderLeft()) {
            ts << " [border:";

            BorderValue prevBorder = o.style()->borderTop();
            if (!box.borderTop())
                ts << " none";
            else {
                ts << " (" << box.borderTop() << "px ";
                printBorderStyle(ts, o.style()->borderTopStyle());
                Color col = o.resolveColor(CSSPropertyBorderTopColor);
                ts << col.nameForRenderTreeAsText() << ")";
            }

            if (o.style()->borderRight() != prevBorder) {
                prevBorder = o.style()->borderRight();
                if (!box.borderRight())
                    ts << " none";
                else {
                    ts << " (" << box.borderRight() << "px ";
                    printBorderStyle(ts, o.style()->borderRightStyle());
                    Color col = o.resolveColor(CSSPropertyBorderRightColor);
                    ts << col.nameForRenderTreeAsText() << ")";
                }
            }

            if (o.style()->borderBottom() != prevBorder) {
                prevBorder = box.style()->borderBottom();
                if (!box.borderBottom())
                    ts << " none";
                else {
                    ts << " (" << box.borderBottom() << "px ";
                    printBorderStyle(ts, o.style()->borderBottomStyle());
                    Color col = o.resolveColor(CSSPropertyBorderBottomColor);
                    ts << col.nameForRenderTreeAsText() << ")";
                }
            }

            if (o.style()->borderLeft() != prevBorder) {
                prevBorder = o.style()->borderLeft();
                if (!box.borderLeft())
                    ts << " none";
                else {
                    ts << " (" << box.borderLeft() << "px ";
                    printBorderStyle(ts, o.style()->borderLeftStyle());
                    Color col = o.resolveColor(CSSPropertyBorderLeftColor);
                    ts << col.nameForRenderTreeAsText() << ")";
                }
            }

            ts << "]";
        }
    }

    if (behavior & RenderAsTextShowIDAndClass) {
        Node* node = o.node();
        if (node && node->isElementNode()) {
            Element& element = toElement(*node);
            if (element.hasID())
                ts << " id=\"" + element.getIdAttribute() + "\"";

            if (element.hasClass()) {
                ts << " class=\"";
                for (size_t i = 0; i < element.classNames().size(); ++i) {
                    if (i > 0)
                        ts << " ";
                    ts << element.classNames()[i];
                }
                ts << "\"";
            }
        }
    }

    if (behavior & RenderAsTextShowLayoutState) {
        bool needsLayout = o.selfNeedsLayout() || o.needsPositionedMovementLayout() || o.posChildNeedsLayout() || o.normalChildNeedsLayout();
        if (needsLayout)
            ts << " (needs layout:";

        bool havePrevious = false;
        if (o.selfNeedsLayout()) {
            ts << " self";
            havePrevious = true;
        }

        if (o.needsPositionedMovementLayout()) {
            if (havePrevious)
                ts << ",";
            havePrevious = true;
            ts << " positioned movement";
        }

        if (o.normalChildNeedsLayout()) {
            if (havePrevious)
                ts << ",";
            havePrevious = true;
            ts << " child";
        }

        if (o.posChildNeedsLayout()) {
            if (havePrevious)
                ts << ",";
            ts << " positioned child";
        }

        if (needsLayout)
            ts << ")";
    }
}

static void writeTextRun(TextStream& ts, const RenderText& o, const InlineTextBox& run)
{
    // FIXME: For now use an "enclosingIntRect" model for x, y and logicalWidth, although this makes it harder
    // to detect any changes caused by the conversion to floating point. :(
    int x = run.x();
    int y = run.y();
    int logicalWidth = ceilf(run.left() + run.logicalWidth()) - x;

    ts << "text run at (" << x << "," << y << ") width " << logicalWidth;
    if (!run.isLeftToRightDirection() || run.dirOverride()) {
        ts << (!run.isLeftToRightDirection() ? " RTL" : " LTR");
        if (run.dirOverride())
            ts << " override";
    }
    ts << ": "
        << quoteAndEscapeNonPrintables(String(o.text()).substring(run.start(), run.len()));
    if (run.hasHyphen())
        ts << " + hyphen string " << quoteAndEscapeNonPrintables(o.style()->hyphenString());
    ts << "\n";
}

void write(TextStream& ts, const RenderObject& o, int indent, RenderAsTextBehavior behavior)
{
    writeIndent(ts, indent);

    RenderTreeAsText::writeRenderObject(ts, o, behavior);
    ts << "\n";

    if (o.isText()) {
        const RenderText& text = toRenderText(o);
        for (InlineTextBox* box = text.firstTextBox(); box; box = box->nextTextBox()) {
            writeIndent(ts, indent + 1);
            writeTextRun(ts, text, *box);
        }
    }

    for (RenderObject* child = o.slowFirstChild(); child; child = child->nextSibling()) {
        if (child->hasLayer())
            continue;
        write(ts, *child, indent + 1, behavior);
    }
}

enum LayerPaintPhase {
    LayerPaintPhaseAll = 0,
    LayerPaintPhaseBackground = -1,
    LayerPaintPhaseForeground = 1
};

static void write(TextStream& ts, RenderLayer& l,
                  const LayoutRect& layerBounds, const LayoutRect& backgroundClipRect, const LayoutRect& clipRect,
                  LayerPaintPhase paintPhase = LayerPaintPhaseAll, int indent = 0, RenderAsTextBehavior behavior = RenderAsTextBehaviorNormal)
{
    IntRect adjustedLayoutBounds = pixelSnappedIntRect(layerBounds);
    IntRect adjustedBackgroundClipRect = pixelSnappedIntRect(backgroundClipRect);
    IntRect adjustedClipRect = pixelSnappedIntRect(clipRect);

    writeIndent(ts, indent);

    ts << "layer ";

    if (behavior & RenderAsTextShowAddresses)
        ts << static_cast<const void*>(&l) << " ";

    ts << adjustedLayoutBounds;

    if (!adjustedLayoutBounds.isEmpty()) {
        if (!adjustedBackgroundClipRect.contains(adjustedLayoutBounds))
            ts << " backgroundClip " << adjustedBackgroundClipRect;
        if (!adjustedClipRect.contains(adjustedLayoutBounds))
            ts << " clip " << adjustedClipRect;
    }
    if (l.isTransparent())
        ts << " transparent";

    if (paintPhase == LayerPaintPhaseBackground)
        ts << " layerType: background only";
    else if (paintPhase == LayerPaintPhaseForeground)
        ts << " layerType: foreground only";

    ts << "\n";

    if (paintPhase != LayerPaintPhaseBackground)
        write(ts, *l.renderer(), indent + 1, behavior);
}

void RenderTreeAsText::writeLayers(TextStream& ts, const RenderLayer* rootLayer, RenderLayer* layer,
    const LayoutRect& paintRect, int indent, RenderAsTextBehavior behavior)
{
    // FIXME: Apply overflow to the root layer to not break every test. Complete hack. Sigh.
    LayoutRect paintDirtyRect(paintRect);
    if (rootLayer == layer) {
        paintDirtyRect.setWidth(max<LayoutUnit>(paintDirtyRect.width(), rootLayer->renderBox()->layoutOverflowRect().maxX()));
        paintDirtyRect.setHeight(max<LayoutUnit>(paintDirtyRect.height(), rootLayer->renderBox()->layoutOverflowRect().maxY()));
    }

    // Calculate the clip rects we should use.
    LayoutRect layerBounds;
    ClipRect damageRect, clipRectToApply;
    layer->clipper().calculateRects(ClipRectsContext(rootLayer, UncachedClipRects), paintDirtyRect, layerBounds, damageRect, clipRectToApply);

    // FIXME: Apply overflow to the root layer to not break every test. Complete hack. Sigh.
    if (rootLayer == layer)
        layerBounds.setSize(layer->size().expandedTo(pixelSnappedIntSize(layer->renderBox()->maxLayoutOverflow(), LayoutPoint(0, 0))));

    // Ensure our lists are up-to-date.
    layer->stackingNode()->updateLayerListsIfNeeded();

    bool shouldPaint = (behavior & RenderAsTextShowAllLayers) ? true : layer->intersectsDamageRect(layerBounds, damageRect.rect(), rootLayer);

    if (shouldPaint)
        write(ts, *layer, layerBounds, damageRect.rect(), clipRectToApply.rect(), LayerPaintPhaseAll, indent, behavior);

    if (Vector<RenderLayerStackingNode*>* normalFlowList = layer->stackingNode()->normalFlowList()) {
        int currIndent = indent;
        if (behavior & RenderAsTextShowLayerNesting) {
            writeIndent(ts, indent);
            ts << " normal flow list(" << normalFlowList->size() << ")\n";
            ++currIndent;
        }
        for (unsigned i = 0; i != normalFlowList->size(); ++i)
            writeLayers(ts, rootLayer, normalFlowList->at(i)->layer(), paintDirtyRect, currIndent, behavior);
    }

    if (Vector<RenderLayerStackingNode*>* posList = layer->stackingNode()->zOrderList()) {
        int currIndent = indent;
        if (behavior & RenderAsTextShowLayerNesting) {
            writeIndent(ts, indent);
            ts << " positive z-order list(" << posList->size() << ")\n";
            ++currIndent;
        }
        for (unsigned i = 0; i != posList->size(); ++i)
            writeLayers(ts, rootLayer, posList->at(i)->layer(), paintDirtyRect, currIndent, behavior);
    }
}

String nodePositionAsStringForTesting(Node* node)
{
    StringBuilder result;

    Node* parent;
    for (Node* n = node; n; n = parent) {
        parent = n->parentOrShadowHostNode();
        if (n != node)
            result.appendLiteral(" of ");
        if (parent) {
            if (n->isShadowRoot()) {
                result.append('{');
                result.append(n->nodeName());
                result.append('}');
            } else {
                result.appendLiteral("child ");
                result.appendNumber(n->nodeIndex());
                result.appendLiteral(" {");
                result.append(n->nodeName());
                result.append('}');
            }
        } else
            result.appendLiteral("document");
    }

    return result.toString();
}

static void writeSelection(TextStream& ts, const RenderObject* o)
{
    Node* n = o->node();
    if (!n || !n->isDocumentNode())
        return;

    Document* doc = toDocument(n);
    LocalFrame* frame = doc->frame();
    if (!frame)
        return;

    VisibleSelection selection = frame->selection().selection();
    if (selection.isCaret()) {
        ts << "caret: position " << selection.start().deprecatedEditingOffset() << " of " << nodePositionAsStringForTesting(selection.start().deprecatedNode());
        if (selection.affinity() == UPSTREAM)
            ts << " (upstream affinity)";
        ts << "\n";
    } else if (selection.isRange()) {
        ts << "selection start: position " << selection.start().deprecatedEditingOffset() << " of " << nodePositionAsStringForTesting(selection.start().deprecatedNode()) << "\n"
            << "selection end:   position " << selection.end().deprecatedEditingOffset() << " of " << nodePositionAsStringForTesting(selection.end().deprecatedNode()) << "\n";
    }
}

static String externalRepresentation(RenderBox* renderer, RenderAsTextBehavior behavior)
{
    TextStream ts;
    if (!renderer->hasLayer())
        return ts.release();

    RenderLayer* layer = renderer->layer();
    RenderTreeAsText::writeLayers(ts, layer, layer, layer->rect(), 0, behavior);
    writeSelection(ts, renderer);
    return ts.release();
}

String externalRepresentation(LocalFrame* frame, RenderAsTextBehavior behavior)
{
    if (!(behavior & RenderAsTextDontUpdateLayout))
        frame->document()->updateLayout();

    RenderObject* renderer = frame->contentRenderer();
    if (!renderer || !renderer->isBox())
        return String();

    return externalRepresentation(toRenderBox(renderer), behavior);
}

String externalRepresentation(Element* element, RenderAsTextBehavior behavior)
{
    // Doesn't support printing mode.
    if (!(behavior & RenderAsTextDontUpdateLayout))
        element->document().updateLayout();

    RenderObject* renderer = element->renderer();
    if (!renderer || !renderer->isBox())
        return String();

    return externalRepresentation(toRenderBox(renderer), behavior | RenderAsTextShowAllLayers);
}

} // namespace blink
