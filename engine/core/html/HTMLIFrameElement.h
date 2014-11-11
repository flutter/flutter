// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef HTMLIFrameElement_h
#define HTMLIFrameElement_h

#include "core/HTMLNames.h"
#include "core/dom/DOMURLUtils.h"
#include "core/dom/Document.h"
#include "core/html/HTMLElement.h"
#include "mojo/services/public/cpp/view_manager/view_observer.h"
#include "wtf/OwnPtr.h"

namespace blink {

class RemoteFrame;

class HTMLIFrameElement : public HTMLElement,
                          public mojo::ViewObserver {
    DEFINE_WRAPPERTYPEINFO();
public:
    static PassRefPtr<HTMLIFrameElement> create(Document&);

    virtual ~HTMLIFrameElement();

    mojo::View* contentView() const { return m_contentView; }

private:
    explicit HTMLIFrameElement(Document&);

    // HTMLElement methods:
    virtual RenderObject* createRenderer(RenderStyle* style) override;

    virtual InsertionNotificationRequest insertedInto(ContainerNode*) override;
    virtual void removedFrom(ContainerNode*) override;

    // ViewObserver methods:
    void OnViewDestroyed(mojo::View* view) override;

private:
    void createView();

    mojo::View* m_contentView;
};

} // namespace blink

#endif // HTMLIFrameElement_h
