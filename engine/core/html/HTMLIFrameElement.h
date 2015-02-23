// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_ENGINE_CORE_HTML_HTMLIFRAMEELEMENT_H_
#define SKY_ENGINE_CORE_HTML_HTMLIFRAMEELEMENT_H_

#include "gen/sky/core/HTMLNames.h"
#include "mojo/services/view_manager/public/cpp/view_observer.h"
#include "sky/engine/core/dom/DOMURLUtils.h"
#include "sky/engine/core/dom/Document.h"
#include "sky/engine/core/html/HTMLElement.h"
#include "sky/engine/wtf/OwnPtr.h"

namespace blink {

class RemoteFrame;

class HTMLIFrameElement : public HTMLElement,
                          public mojo::ViewObserver {
    DEFINE_WRAPPERTYPEINFO();
public:
    static PassRefPtr<HTMLIFrameElement> create(Document&);

    ~HTMLIFrameElement() override;

    mojo::View* contentView() const { return m_contentView; }

    PassRefPtr<DartValue> takeServicesHandle(DartState*);
    PassRefPtr<DartValue> takeExposedServicesHandle(DartState*);
    void embedViewManagerClient(RefPtr<DartValue> client);

private:
    explicit HTMLIFrameElement(Document&);

    // HTMLElement methods:
    RenderObject* createRenderer(RenderStyle* style) override;

    void insertedInto(ContainerNode*) override;
    void removedFrom(ContainerNode*) override;
    void parseAttribute(const QualifiedName& name, const AtomicString& value) override;

    // ViewObserver methods:
    void OnViewDestroyed(mojo::View* view) override;

    void createView();
    void navigateView();

    mojo::View* m_contentView;
    mojo::ServiceProviderPtr m_services;
    mojo::ScopedMessagePipeHandle m_exposedServices;
};

} // namespace blink

#endif  // SKY_ENGINE_CORE_HTML_HTMLIFRAMEELEMENT_H_
