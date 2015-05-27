// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_PAINTING_LAYOUTROOT_H_
#define SKY_ENGINE_CORE_PAINTING_LAYOUTROOT_H_

#include "sky/engine/core/dom/Node.h"
#include "sky/engine/core/frame/FrameHost.h"
#include "sky/engine/core/painting/Paint.h"
#include "sky/engine/core/painting/Picture.h"
#include "sky/engine/platform/graphics/DisplayList.h"
#include "sky/engine/tonic/dart_wrappable.h"
#include "sky/engine/wtf/PassRefPtr.h"
#include "sky/engine/wtf/RefCounted.h"

namespace blink {
class Canvas;
class Document;
class Element;
class LocalFrame;

class LayoutRoot : public RefCounted<LayoutRoot>, public DartWrappable {
    DEFINE_WRAPPERTYPEINFO();
public:
    LayoutRoot();
    ~LayoutRoot() override;

    static PassRefPtr<LayoutRoot> create();

    Element* rootElement() const;
    void setRootElement(Element*);

    void layout();
    void paint(Canvas*);

    LayoutUnit minWidth() const { return m_minWidth; }
    void setMinWidth(LayoutUnit width) { m_minWidth = width; }

    LayoutUnit maxWidth() const { return m_maxWidth; }
    void setMaxWidth(LayoutUnit width) { m_maxWidth = width; }

    LayoutUnit minHeight() const { return m_minHeight; }
    void setMinHeight(LayoutUnit height) { m_minHeight = height; }

    LayoutUnit maxHeight() const { return m_maxHeight; }
    void setMaxHeight(LayoutUnit height) { m_maxHeight = height; }

private:
    LayoutUnit m_minWidth;
    LayoutUnit m_maxWidth;
    LayoutUnit m_minHeight;
    LayoutUnit m_maxHeight;
    RefPtr<Document> m_document;
    RefPtr<LocalFrame> m_frame;

    // TODO(eseidel): All of these should be removed:
    OwnPtr<Settings> m_settings;
    OwnPtr<FrameHost> m_frameHost;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_PAINTING_LAYOUTROOT_H_
