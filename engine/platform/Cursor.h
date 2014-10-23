/*
 * Copyright (C) 2004, 2006, 2008 Apple Inc. All rights reserved.
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

#ifndef Cursor_h
#define Cursor_h

#include "platform/PlatformExport.h"
#include "platform/geometry/IntPoint.h"
#include "platform/graphics/Image.h"
#include "wtf/Assertions.h"
#include "wtf/RefPtr.h"

namespace blink {

class PLATFORM_EXPORT Cursor {
    WTF_MAKE_FAST_ALLOCATED;
public:
    enum Type {
        Pointer = 0,
        Cross,
        Hand,
        IBeam,
        Wait,
        Help,
        EastResize,
        NorthResize,
        NorthEastResize,
        NorthWestResize,
        SouthResize,
        SouthEastResize,
        SouthWestResize,
        WestResize,
        NorthSouthResize,
        EastWestResize,
        NorthEastSouthWestResize,
        NorthWestSouthEastResize,
        ColumnResize,
        RowResize,
        MiddlePanning,
        EastPanning,
        NorthPanning,
        NorthEastPanning,
        NorthWestPanning,
        SouthPanning,
        SouthEastPanning,
        SouthWestPanning,
        WestPanning,
        Move,
        VerticalText,
        Cell,
        ContextMenu,
        Alias,
        Progress,
        NoDrop,
        Copy,
        None,
        NotAllowed,
        ZoomIn,
        ZoomOut,
        Grab,
        Grabbing,
        Custom
    };

    static const Cursor& fromType(Cursor::Type);

    Cursor()
        // This is an invalid Cursor and should never actually get used.
        : m_type(static_cast<Type>(-1))
    {
    }

    Cursor(Image*, const IntPoint& hotSpot);

    // Hot spot is in image pixels.
    Cursor(Image*, const IntPoint& hotSpot, float imageScaleFactor);

    Cursor(const Cursor&);
    ~Cursor();
    Cursor& operator=(const Cursor&);

    explicit Cursor(Type);
    Type type() const
    {
        ASSERT(m_type >= 0 && m_type <= Custom);
        return m_type;
    }
    Image* image() const { return m_image.get(); }
    const IntPoint& hotSpot() const { return m_hotSpot; }
    // Image scale in image pixels per logical (UI) pixel.
    float imageScaleFactor() const { return m_imageScaleFactor; }

private:
    Type m_type;
    RefPtr<Image> m_image;
    IntPoint m_hotSpot;
    float m_imageScaleFactor;
};

PLATFORM_EXPORT IntPoint determineHotSpot(Image*, const IntPoint& specifiedHotSpot);

PLATFORM_EXPORT const Cursor& pointerCursor();
PLATFORM_EXPORT const Cursor& crossCursor();
PLATFORM_EXPORT const Cursor& handCursor();
PLATFORM_EXPORT const Cursor& moveCursor();
PLATFORM_EXPORT const Cursor& iBeamCursor();
PLATFORM_EXPORT const Cursor& waitCursor();
PLATFORM_EXPORT const Cursor& helpCursor();
PLATFORM_EXPORT const Cursor& eastResizeCursor();
PLATFORM_EXPORT const Cursor& northResizeCursor();
PLATFORM_EXPORT const Cursor& northEastResizeCursor();
PLATFORM_EXPORT const Cursor& northWestResizeCursor();
PLATFORM_EXPORT const Cursor& southResizeCursor();
PLATFORM_EXPORT const Cursor& southEastResizeCursor();
PLATFORM_EXPORT const Cursor& southWestResizeCursor();
PLATFORM_EXPORT const Cursor& westResizeCursor();
PLATFORM_EXPORT const Cursor& northSouthResizeCursor();
PLATFORM_EXPORT const Cursor& eastWestResizeCursor();
PLATFORM_EXPORT const Cursor& northEastSouthWestResizeCursor();
PLATFORM_EXPORT const Cursor& northWestSouthEastResizeCursor();
PLATFORM_EXPORT const Cursor& columnResizeCursor();
PLATFORM_EXPORT const Cursor& rowResizeCursor();
PLATFORM_EXPORT const Cursor& middlePanningCursor();
PLATFORM_EXPORT const Cursor& eastPanningCursor();
PLATFORM_EXPORT const Cursor& northPanningCursor();
PLATFORM_EXPORT const Cursor& northEastPanningCursor();
PLATFORM_EXPORT const Cursor& northWestPanningCursor();
PLATFORM_EXPORT const Cursor& southPanningCursor();
PLATFORM_EXPORT const Cursor& southEastPanningCursor();
PLATFORM_EXPORT const Cursor& southWestPanningCursor();
PLATFORM_EXPORT const Cursor& westPanningCursor();
PLATFORM_EXPORT const Cursor& verticalTextCursor();
PLATFORM_EXPORT const Cursor& cellCursor();
PLATFORM_EXPORT const Cursor& contextMenuCursor();
PLATFORM_EXPORT const Cursor& noDropCursor();
PLATFORM_EXPORT const Cursor& notAllowedCursor();
PLATFORM_EXPORT const Cursor& progressCursor();
PLATFORM_EXPORT const Cursor& aliasCursor();
PLATFORM_EXPORT const Cursor& zoomInCursor();
PLATFORM_EXPORT const Cursor& zoomOutCursor();
PLATFORM_EXPORT const Cursor& copyCursor();
PLATFORM_EXPORT const Cursor& noneCursor();
PLATFORM_EXPORT const Cursor& grabCursor();
PLATFORM_EXPORT const Cursor& grabbingCursor();

} // namespace blink

#endif // Cursor_h
