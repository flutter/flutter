/*
 * Copyright (C) 2004, 2005, 2006, 2007, 2008, 2009 Apple Inc. All rights reserved.
 * Copyright (C) 2008, 2009, 2010, 2011 Google Inc. All rights reserved.
 * Copyright (C) 2011 Igalia S.L.
 * Copyright (C) 2011 Motorola Mobility. All rights reserved.
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

#include "config.h"
#include "core/editing/markup.h"

#include "bindings/core/v8/ExceptionState.h"
#include "core/CSSPropertyNames.h"
#include "core/CSSValueKeywords.h"
#include "core/HTMLNames.h"
#include "core/css/CSSPrimitiveValue.h"
#include "core/css/CSSValue.h"
#include "core/css/StylePropertySet.h"
#include "core/dom/ChildListMutationScope.h"
#include "core/dom/DocumentFragment.h"
#include "core/dom/ElementTraversal.h"
#include "core/dom/ExceptionCode.h"
#include "core/dom/NodeTraversal.h"
#include "core/dom/Range.h"
#include "core/dom/Text.h"
#include "core/editing/Editor.h"
#include "core/editing/MarkupAccumulator.h"
#include "core/editing/TextIterator.h"
#include "core/editing/VisibleSelection.h"
#include "core/editing/VisibleUnits.h"
#include "core/editing/htmlediting.h"
#include "core/frame/LocalFrame.h"
#include "core/html/HTMLAnchorElement.h"
#include "core/html/HTMLElement.h"
#include "core/rendering/RenderObject.h"
#include "platform/weborigin/KURL.h"
#include "wtf/StdLibExtras.h"
#include "wtf/text/StringBuilder.h"

namespace blink {

static bool propertyMissingOrEqualToNone(StylePropertySet*, CSSPropertyID);

class AttributeChange {
    ALLOW_ONLY_INLINE_ALLOCATION();
public:
    AttributeChange()
        : m_name(nullAtom)
    {
    }

    AttributeChange(PassRefPtr<Element> element, const QualifiedName& name, const String& value)
        : m_element(element), m_name(name), m_value(value)
    {
    }

    void apply()
    {
        m_element->setAttribute(m_name, AtomicString(m_value));
    }

private:
    RefPtr<Element> m_element;
    QualifiedName m_name;
    String m_value;
};

} // namespace blink

WTF_ALLOW_INIT_WITH_MEM_FUNCTIONS(blink::AttributeChange);

namespace blink {

class StyledMarkupAccumulator final : public MarkupAccumulator {
public:
    StyledMarkupAccumulator(Vector<RawPtr<Node> >* nodes, EAbsoluteURLs, EAnnotateForInterchange, RawPtr<const Range>, Node* highestNodeToBeSerialized = 0);
    Node* serializeNodes(Node* startNode, Node* pastEnd);
    void appendString(const String& s) { return MarkupAccumulator::appendString(s); }
    void wrapWithNode(ContainerNode&, bool convertBlocksToInlines = false);
    void wrapWithStyleNode(StylePropertySet*, const Document&, bool isBlock = false);
    String takeResults();

private:
    void appendStyleNodeOpenTag(StringBuilder&, StylePropertySet*, const Document&, bool isBlock = false);
    const String& styleNodeCloseTag(bool isBlock = false);
    virtual void appendText(StringBuilder& out, Text&) override;
    String renderedText(Node&, const Range*);
    String stringValueForRange(const Node&, const Range*);
    void appendElement(StringBuilder& out, Element&, bool addDisplayInline);
    virtual void appendElement(StringBuilder& out, Element& element, Namespaces*) override { appendElement(out, element, false); }

    enum NodeTraversalMode { EmitString, DoNotEmitString };
    Node* traverseNodesForSerialization(Node* startNode, Node* pastEnd, NodeTraversalMode);

    bool shouldAnnotate() const { return m_shouldAnnotate == AnnotateForInterchange || m_shouldAnnotate == AnnotateForNavigationTransition; }
    bool shouldApplyWrappingStyle(const Node& node) const
    {
        return m_highestNodeToBeSerialized && m_highestNodeToBeSerialized->parentNode() == node.parentNode()
            && m_wrappingStyle && m_wrappingStyle->style();
    }

    Vector<String> m_reversedPrecedingMarkup;
    const EAnnotateForInterchange m_shouldAnnotate;
    RawPtr<Node> m_highestNodeToBeSerialized;
    RefPtr<EditingStyle> m_wrappingStyle;
};

inline StyledMarkupAccumulator::StyledMarkupAccumulator(Vector<RawPtr<Node> >* nodes, EAbsoluteURLs shouldResolveURLs, EAnnotateForInterchange shouldAnnotate, RawPtr<const Range> range, Node* highestNodeToBeSerialized)
    : MarkupAccumulator(nodes, shouldResolveURLs, range)
    , m_shouldAnnotate(shouldAnnotate)
    , m_highestNodeToBeSerialized(highestNodeToBeSerialized)
{
}

void StyledMarkupAccumulator::wrapWithNode(ContainerNode& node, bool convertBlocksToInlines)
{
    StringBuilder markup;
    if (node.isElementNode())
        appendElement(markup, toElement(node), convertBlocksToInlines && isBlock(&node));
    else
        appendStartMarkup(markup, node, 0);
    m_reversedPrecedingMarkup.append(markup.toString());
    if (node.isElementNode())
        appendEndTag(toElement(node));
    if (m_nodes)
        m_nodes->append(&node);
}

void StyledMarkupAccumulator::wrapWithStyleNode(StylePropertySet* style, const Document& document, bool isBlock)
{
    StringBuilder openTag;
    appendStyleNodeOpenTag(openTag, style, document, isBlock);
    m_reversedPrecedingMarkup.append(openTag.toString());
    appendString(styleNodeCloseTag(isBlock));
}

void StyledMarkupAccumulator::appendStyleNodeOpenTag(StringBuilder& out, StylePropertySet* style, const Document& document, bool isBlock)
{
    // wrappingStyleForSerialization should have removed -webkit-text-decorations-in-effect
    ASSERT(propertyMissingOrEqualToNone(style, CSSPropertyWebkitTextDecorationsInEffect));
    if (isBlock)
        out.appendLiteral("<div style=\"");
    else
        out.appendLiteral("<span style=\"");
    appendAttributeValue(out, style->asText(), document.isHTMLDocument());
    out.appendLiteral("\">");
}

const String& StyledMarkupAccumulator::styleNodeCloseTag(bool isBlock)
{
    DEFINE_STATIC_LOCAL(const String, divClose, ("</div>"));
    DEFINE_STATIC_LOCAL(const String, styleSpanClose, ("</span>"));
    return isBlock ? divClose : styleSpanClose;
}

String StyledMarkupAccumulator::takeResults()
{
    StringBuilder result;
    result.reserveCapacity(totalLength(m_reversedPrecedingMarkup) + length());

    for (size_t i = m_reversedPrecedingMarkup.size(); i > 0; --i)
        result.append(m_reversedPrecedingMarkup[i - 1]);

    concatenateMarkup(result);

    // We remove '\0' characters because they are not visibly rendered to the user.
    return result.toString().replace(0, "");
}

void StyledMarkupAccumulator::appendText(StringBuilder& out, Text& text)
{
}

String StyledMarkupAccumulator::renderedText(Node& node, const Range* range)
{
    if (!node.isTextNode())
        return String();

    Text& textNode = toText(node);
    unsigned startOffset = 0;
    unsigned endOffset = textNode.length();

    if (range && textNode == range->startContainer())
        startOffset = range->startOffset();
    if (range && textNode == range->endContainer())
        endOffset = range->endOffset();

    Position start = createLegacyEditingPosition(&textNode, startOffset);
    Position end = createLegacyEditingPosition(&textNode, endOffset);
    return plainText(Range::create(textNode.document(), start, end).get());
}

String StyledMarkupAccumulator::stringValueForRange(const Node& node, const Range* range)
{
    if (!node.isTextNode())
        return emptyString();
    String text = toText(node).data();
    if (!range)
        return text;
    if (node == range->endContainer())
        text.truncate(range->endOffset());
    if (node == range->startContainer())
        text.remove(0, range->startOffset());
    return text;
}

void StyledMarkupAccumulator::appendElement(StringBuilder& out, Element& element, bool addDisplayInline)
{
    const bool documentIsHTML = element.document().isHTMLDocument();
    appendOpenTag(out, element, 0);

    const bool shouldAnnotateOrForceInline = element.isHTMLElement() && (shouldAnnotate() || addDisplayInline);
    const bool shouldOverrideStyleAttr = shouldAnnotateOrForceInline || shouldApplyWrappingStyle(element);

    AttributeCollection attributes = element.attributes();
    AttributeCollection::iterator end = attributes.end();
    for (AttributeCollection::iterator it = attributes.begin(); it != end; ++it) {
        // We'll handle the style attribute separately, below.
        if (it->name() == HTMLNames::styleAttr && shouldOverrideStyleAttr)
            continue;
        appendAttribute(out, element, *it, 0);
    }

    if (shouldOverrideStyleAttr) {
        RefPtr<EditingStyle> newInlineStyle = nullptr;

        if (shouldApplyWrappingStyle(element)) {
            newInlineStyle = m_wrappingStyle->copy();
            newInlineStyle->removePropertiesInElementDefaultStyle(&element);
            newInlineStyle->removeStyleConflictingWithStyleOfElement(&element);
        } else
            newInlineStyle = EditingStyle::create();

        if (element.isStyledElement() && element.inlineStyle())
            newInlineStyle->overrideWithStyle(element.inlineStyle());

        if (shouldAnnotateOrForceInline) {
            if (shouldAnnotate())
                newInlineStyle->mergeStyleFromRulesForSerialization(&toHTMLElement(element));

            if (&element == m_highestNodeToBeSerialized && m_shouldAnnotate == AnnotateForNavigationTransition)
                newInlineStyle->addAbsolutePositioningFromElement(element);

            if (addDisplayInline)
                newInlineStyle->forceInline();
        }

        if (!newInlineStyle->isEmpty()) {
            out.appendLiteral(" style=\"");
            appendAttributeValue(out, newInlineStyle->style()->asText(), documentIsHTML);
            out.append('\"');
        }
    }

    appendCloseTag(out, element);
}

Node* StyledMarkupAccumulator::serializeNodes(Node* startNode, Node* pastEnd)
{
    if (!m_highestNodeToBeSerialized) {
        Node* lastClosed = traverseNodesForSerialization(startNode, pastEnd, DoNotEmitString);
        m_highestNodeToBeSerialized = lastClosed;
    }

    if (m_highestNodeToBeSerialized && m_highestNodeToBeSerialized->parentNode()) {
        m_wrappingStyle = EditingStyle::wrappingStyleForSerialization(m_highestNodeToBeSerialized->parentNode(), shouldAnnotate());
        if (m_shouldAnnotate == AnnotateForNavigationTransition) {
            m_wrappingStyle->style()->removeProperty(CSSPropertyBackgroundColor);
            m_wrappingStyle->style()->removeProperty(CSSPropertyBackgroundImage);
        }
    }


    return traverseNodesForSerialization(startNode, pastEnd, EmitString);
}

Node* StyledMarkupAccumulator::traverseNodesForSerialization(Node* startNode, Node* pastEnd, NodeTraversalMode traversalMode)
{
    const bool shouldEmit = traversalMode == EmitString;
    Vector<RawPtr<ContainerNode> > ancestorsToClose;
    Node* next;
    Node* lastClosed = 0;
    for (Node* n = startNode; n != pastEnd; n = next) {
        // According to <rdar://problem/5730668>, it is possible for n to blow
        // past pastEnd and become null here. This shouldn't be possible.
        // This null check will prevent crashes (but create too much markup)
        // and the ASSERT will hopefully lead us to understanding the problem.
        ASSERT(n);
        if (!n)
            break;

        next = NodeTraversal::next(*n);
        bool openedTag = false;

        if (isBlock(n) && canHaveChildrenForEditing(n) && next == pastEnd)
            // Don't write out empty block containers that aren't fully selected.
            continue;

        if (!n->renderer() && m_shouldAnnotate != AnnotateForNavigationTransition) {
            next = NodeTraversal::nextSkippingChildren(*n);
            // Don't skip over pastEnd.
            if (pastEnd && pastEnd->isDescendantOf(n))
                next = pastEnd;
        } else {
            // Add the node to the markup if we're not skipping the descendants
            if (shouldEmit)
                appendStartTag(*n);

            // If node has no children, close the tag now.
            if (n->isContainerNode() && toContainerNode(n)->hasChildren()) {
                openedTag = true;
                ancestorsToClose.append(toContainerNode(n));
            } else {
                if (shouldEmit && n->isElementNode())
                    appendEndTag(toElement(*n));
                lastClosed = n;
            }
        }

        // If we didn't insert open tag and there's no more siblings or we're at the end of the traversal, take care of ancestors.
        // FIXME: What happens if we just inserted open tag and reached the end?
        if (!openedTag && (!n->nextSibling() || next == pastEnd)) {
            // Close up the ancestors.
            while (!ancestorsToClose.isEmpty()) {
                ContainerNode* ancestor = ancestorsToClose.last();
                ASSERT(ancestor);
                if (next != pastEnd && next->isDescendantOf(ancestor))
                    break;
                // Not at the end of the range, close ancestors up to sibling of next node.
                if (shouldEmit && ancestor->isElementNode())
                    appendEndTag(toElement(*ancestor));
                lastClosed = ancestor;
                ancestorsToClose.removeLast();
            }

            // Surround the currently accumulated markup with markup for ancestors we never opened as we leave the subtree(s) rooted at those ancestors.
            ContainerNode* nextParent = next ? next->parentNode() : 0;
            if (next != pastEnd && n != nextParent) {
                Node* lastAncestorClosedOrSelf = n->isDescendantOf(lastClosed) ? lastClosed : n;
                for (ContainerNode* parent = lastAncestorClosedOrSelf->parentNode(); parent && parent != nextParent; parent = parent->parentNode()) {
                    // All ancestors that aren't in the ancestorsToClose list should either be a) unrendered:
                    if (!parent->renderer())
                        continue;
                    // or b) ancestors that we never encountered during a pre-order traversal starting at startNode:
                    ASSERT(startNode->isDescendantOf(parent));
                    if (shouldEmit)
                        wrapWithNode(*parent);
                    lastClosed = parent;
                }
            }
        }
    }

    return lastClosed;
}

static bool propertyMissingOrEqualToNone(StylePropertySet* style, CSSPropertyID propertyID)
{
    if (!style)
        return false;
    RefPtr<CSSValue> value = style->getPropertyCSSValue(propertyID);
    if (!value)
        return true;
    if (!value->isPrimitiveValue())
        return false;
    return toCSSPrimitiveValue(value.get())->getValueID() == CSSValueNone;
}

static bool needInterchangeNewlineAfter(const VisiblePosition& v)
{
    return isEndOfParagraph(v) && isStartOfParagraph(v.next());
}

static PassRefPtr<EditingStyle> styleFromMatchedRulesAndInlineDecl(const HTMLElement* element)
{
    RefPtr<EditingStyle> style = EditingStyle::create(element->inlineStyle());
    // FIXME: Having to const_cast here is ugly, but it is quite a bit of work to untangle
    // the non-const-ness of styleFromMatchedRulesForElement.
    style->mergeStyleFromRules(const_cast<HTMLElement*>(element));
    return style.release();
}

static bool isPresentationalHTMLElement(const Node* node)
{
    return false;
}

static HTMLElement* highestAncestorToWrapMarkup(const Range* range, EAnnotateForInterchange shouldAnnotate, Node* constrainingAncestor)
{
    Node* commonAncestor = range->commonAncestorContainer();
    ASSERT(commonAncestor);
    HTMLElement* specialCommonAncestor = 0;
    Node* checkAncestor = specialCommonAncestor ? specialCommonAncestor : commonAncestor;
    if (checkAncestor->renderer()) {
        HTMLElement* newSpecialCommonAncestor = toHTMLElement(highestEnclosingNodeOfType(firstPositionInNode(checkAncestor), &isPresentationalHTMLElement, CanCrossEditingBoundary, constrainingAncestor));
        if (newSpecialCommonAncestor)
            specialCommonAncestor = newSpecialCommonAncestor;
    }

    if (HTMLAnchorElement* enclosingAnchor = toHTMLAnchorElement(enclosingElementWithTag(firstPositionInNode(specialCommonAncestor ? specialCommonAncestor : commonAncestor), HTMLNames::aTag)))
        specialCommonAncestor = enclosingAnchor;

    return specialCommonAncestor;
}

// FIXME: Shouldn't we omit style info when annotate == DoNotAnnotateForInterchange?
// FIXME: At least, annotation and style info should probably not be included in range.markupString()
static String createMarkupInternal(Document& document, const Range* range, const Range* updatedRange, Vector<RawPtr<Node> >* nodes,
    EAnnotateForInterchange shouldAnnotate, bool convertBlocksToInlines, EAbsoluteURLs shouldResolveURLs, Node* constrainingAncestor)
{
    ASSERT(range);
    ASSERT(updatedRange);
    DEFINE_STATIC_LOCAL(const String, interchangeNewlineString, ("<br class=\"" AppleInterchangeNewline "\">"));

    bool collapsed = updatedRange->collapsed();
    if (collapsed)
        return emptyString();
    Node* commonAncestor = updatedRange->commonAncestorContainer();
    if (!commonAncestor)
        return emptyString();

    document.updateLayoutIgnorePendingStylesheets();

    // FIXME(sky): Remove this variable.
    HTMLElement* fullySelectedRoot = 0;
    // FIXME: Do this for all fully selected blocks, not just the body.

    HTMLElement* specialCommonAncestor = highestAncestorToWrapMarkup(updatedRange, shouldAnnotate, constrainingAncestor);
    StyledMarkupAccumulator accumulator(nodes, shouldResolveURLs, shouldAnnotate, updatedRange, specialCommonAncestor);
    Node* pastEnd = updatedRange->pastLastNode();

    Node* startNode = updatedRange->firstNode();
    VisiblePosition visibleStart(updatedRange->startPosition(), VP_DEFAULT_AFFINITY);
    VisiblePosition visibleEnd(updatedRange->endPosition(), VP_DEFAULT_AFFINITY);
    if (shouldAnnotate == AnnotateForInterchange && needInterchangeNewlineAfter(visibleStart)) {
        if (visibleStart == visibleEnd.previous())
            return interchangeNewlineString;

        accumulator.appendString(interchangeNewlineString);
        startNode = visibleStart.next().deepEquivalent().deprecatedNode();

        if (pastEnd && Range::compareBoundaryPoints(startNode, 0, pastEnd, 0, ASSERT_NO_EXCEPTION) >= 0)
            return interchangeNewlineString;
    }

    Node* lastClosed = accumulator.serializeNodes(startNode, pastEnd);

    if (specialCommonAncestor && lastClosed) {
        // Also include all of the ancestors of lastClosed up to this special ancestor.
        for (ContainerNode* ancestor = lastClosed->parentNode(); ancestor; ancestor = ancestor->parentNode()) {
            if (ancestor == fullySelectedRoot && !convertBlocksToInlines) {
                RefPtr<EditingStyle> fullySelectedRootStyle = styleFromMatchedRulesAndInlineDecl(fullySelectedRoot);

                if (fullySelectedRootStyle->style()) {
                    // Reset the CSS properties to avoid an assertion error in addStyleMarkup().
                    // This assertion is caused at least when we select all text of a <body> element whose
                    // 'text-decoration' property is "inherit", and copy it.
                    if (!propertyMissingOrEqualToNone(fullySelectedRootStyle->style(), CSSPropertyTextDecoration))
                        fullySelectedRootStyle->style()->setProperty(CSSPropertyTextDecoration, CSSValueNone);
                    if (!propertyMissingOrEqualToNone(fullySelectedRootStyle->style(), CSSPropertyWebkitTextDecorationsInEffect))
                        fullySelectedRootStyle->style()->setProperty(CSSPropertyWebkitTextDecorationsInEffect, CSSValueNone);
                    accumulator.wrapWithStyleNode(fullySelectedRootStyle->style(), document, true);
                }
            } else {
                accumulator.wrapWithNode(*ancestor, convertBlocksToInlines);
            }
            if (nodes)
                nodes->append(ancestor);

            if (ancestor == specialCommonAncestor)
                break;
        }
    }

    // FIXME: The interchange newline should be placed in the block that it's in, not after all of the content, unconditionally.
    if (shouldAnnotate == AnnotateForInterchange && needInterchangeNewlineAfter(visibleEnd.previous()))
        accumulator.appendString(interchangeNewlineString);

    return accumulator.takeResults();
}

String createMarkup(const Range* range, Vector<RawPtr<Node> >* nodes, EAnnotateForInterchange shouldAnnotate, bool convertBlocksToInlines, EAbsoluteURLs shouldResolveURLs, Node* constrainingAncestor)
{
    if (!range)
        return emptyString();

    Document& document = range->ownerDocument();
    const Range* updatedRange = range;

    return createMarkupInternal(document, range, updatedRange, nodes, shouldAnnotate, convertBlocksToInlines, shouldResolveURLs, constrainingAncestor);
}

String createMarkup(const Node* node, EChildrenOnly childrenOnly, Vector<RawPtr<Node> >* nodes, EAbsoluteURLs shouldResolveURLs, Vector<QualifiedName>* tagNamesToSkip)
{
    if (!node)
        return "";

    MarkupAccumulator accumulator(nodes, shouldResolveURLs);
    return accumulator.serializeNodes(const_cast<Node&>(*node), childrenOnly, tagNamesToSkip);
}

void replaceChildrenWithFragment(ContainerNode* container, PassRefPtr<DocumentFragment> fragment, ExceptionState& exceptionState)
{
    ASSERT(container);
    RefPtr<ContainerNode> containerNode(container);

    ChildListMutationScope mutation(*containerNode);

    if (!fragment->firstChild()) {
        containerNode->removeChildren();
        return;
    }

    // FIXME: This is wrong if containerNode->firstChild() has more than one ref!
    if (containerNode->hasOneTextChild() && fragment->hasOneTextChild()) {
        toText(containerNode->firstChild())->setData(toText(fragment->firstChild())->data());
        return;
    }

    // FIXME: No need to replace the child it is a text node and its contents are already == text.
    if (containerNode->hasOneChild()) {
        containerNode->replaceChild(fragment, containerNode->firstChild(), exceptionState);
        return;
    }

    containerNode->removeChildren();
    containerNode->appendChild(fragment, exceptionState);
}

void mergeWithNextTextNode(Text* textNode, ExceptionState& exceptionState)
{
    ASSERT(textNode);
    Node* next = textNode->nextSibling();
    if (!next || !next->isTextNode())
        return;

    RefPtr<Text> textNext = toText(next);
    textNode->appendData(textNext->data());
    if (textNext->parentNode()) // Might have been removed by mutation event.
        textNext->remove(exceptionState);
}

}
