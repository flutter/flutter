// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef HTMLIFrameElement_h
#define HTMLIFrameElement_h

#include "core/HTMLNames.h"
#include "core/dom/DOMURLUtils.h"
#include "core/dom/Document.h"
#include "core/html/HTMLElement.h"

namespace blink {

class HTMLIFrameElement : public HTMLElement {
    DEFINE_WRAPPERTYPEINFO();
public:
    static PassRefPtr<HTMLIFrameElement> create(Document&);

    virtual ~HTMLIFrameElement();

private:
    explicit HTMLIFrameElement(Document&);

    virtual RenderObject* createRenderer(RenderStyle* style) override;

    virtual InsertionNotificationRequest insertedInto(ContainerNode*) override;
    virtual void removedFrom(ContainerNode*) override;

private:
    void createView();
};

} // namespace blink

#endif // HTMLIFrameElement_h
