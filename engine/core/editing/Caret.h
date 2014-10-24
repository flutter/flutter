/*
 * Copyright (C) 2004, 2005, 2006, 2007, 2008, 2009, 2010 Apple Inc. All rights reserved.
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

#ifndef Caret_h
#define Caret_h

#include "core/editing/VisiblePosition.h"
#include "platform/geometry/IntRect.h"
#include "platform/geometry/LayoutRect.h"
#include "wtf/Noncopyable.h"

namespace blink {

class LocalFrame;
class GraphicsContext;
class PositionWithAffinity;
class RenderBlock;
class RenderView;

class CaretBase {
    WTF_MAKE_NONCOPYABLE(CaretBase);
    WTF_MAKE_FAST_ALLOCATED_WILL_BE_REMOVED;
protected:
    enum CaretVisibility { Visible, Hidden };
    explicit CaretBase(CaretVisibility = Hidden);

    void invalidateCaretRect(Node*, bool caretRectChanged = false);
    void clearCaretRect();
    // Creating VisiblePosition causes synchronous layout so we should use the
    // PositionWithAffinity version if possible.
    // A position in HTMLTextFromControlElement is a typical example.
    bool updateCaretRect(Document*, const PositionWithAffinity& caretPosition);
    bool updateCaretRect(Document*, const VisiblePosition& caretPosition);
    IntRect absoluteBoundsForLocalRect(Node*, const LayoutRect&) const;
    bool shouldRepaintCaret(const RenderView*, bool isContentEditable) const;
    void paintCaret(Node*, GraphicsContext*, const LayoutPoint&, const LayoutRect& clipRect) const;

    const LayoutRect& localCaretRectWithoutUpdate() const { return m_caretLocalRect; }

    bool shouldUpdateCaretRect() const { return m_caretRectNeedsUpdate; }
    void setCaretRectNeedsUpdate() { m_caretRectNeedsUpdate = true; }

    void setCaretVisibility(CaretVisibility visibility) { m_caretVisibility = visibility; }
    bool caretIsVisible() const { return m_caretVisibility == Visible; }
    CaretVisibility caretVisibility() const { return m_caretVisibility; }

protected:
    static RenderBlock* caretRenderer(Node*);
    static void invalidateLocalCaretRect(Node*, const LayoutRect&);

private:
    LayoutRect m_caretLocalRect; // caret rect in coords local to the renderer responsible for painting the caret
    bool m_caretRectNeedsUpdate; // true if m_caretRect (and m_absCaretBounds in FrameSelection) need to be calculated
    CaretVisibility m_caretVisibility;
};

class DragCaretController final : public NoBaseWillBeGarbageCollected<DragCaretController>, private CaretBase {
    WTF_MAKE_NONCOPYABLE(DragCaretController);
    WTF_MAKE_FAST_ALLOCATED_WILL_BE_REMOVED;
public:
    static PassOwnPtrWillBeRawPtr<DragCaretController> create();

    RenderBlock* caretRenderer() const;
    void paintDragCaret(LocalFrame*, GraphicsContext*, const LayoutPoint&, const LayoutRect& clipRect) const;

    bool isContentEditable() const { return m_position.rootEditableElement(); }
    bool isContentRichlyEditable() const;

    bool hasCaret() const { return m_position.isNotNull(); }
    const VisiblePosition& caretPosition() { return m_position; }
    void setCaretPosition(const VisiblePosition&);
    void clear() { setCaretPosition(VisiblePosition()); }

    void nodeWillBeRemoved(Node&);

    void trace(Visitor*);

private:
    DragCaretController();

    VisiblePosition m_position;
};

} // namespace blink


#endif // Caret_h
