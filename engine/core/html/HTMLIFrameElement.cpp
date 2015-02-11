// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/config.h"
#include "sky/engine/core/html/HTMLIFrameElement.h"

#include "gen/sky/core/HTMLNames.h"
#include "mojo/edk/js/handle.h"
#include "sky/engine/core/frame/LocalFrame.h"
#include "sky/engine/core/html/parser/HTMLParserIdioms.h"
#include "sky/engine/core/loader/FrameLoaderClient.h"
#include "sky/engine/core/rendering/RenderIFrame.h"

namespace blink {

PassRefPtr<HTMLIFrameElement> HTMLIFrameElement::create(Document& document)
{
    return adoptRef(new HTMLIFrameElement(document));
}

HTMLIFrameElement::HTMLIFrameElement(Document& document)
    : HTMLElement(HTMLNames::iframeTag, document),
      m_contentView(nullptr)
{
}

HTMLIFrameElement::~HTMLIFrameElement()
{
    if (m_contentView)
        m_contentView->RemoveObserver(this);
}

void HTMLIFrameElement::insertedInto(ContainerNode* insertionPoint)
{
    HTMLElement::insertedInto(insertionPoint);
    if (insertionPoint->inDocument()) {
        if (LocalFrame* frame = document().frame()) {
            m_contentView = frame->loaderClient()->createChildFrame();
            m_contentView->AddObserver(this);
        }
        navigateView();
    }
}

void HTMLIFrameElement::removedFrom(ContainerNode* insertionPoint)
{
    HTMLElement::removedFrom(insertionPoint);
    if (m_contentView)
        m_contentView->Destroy();
}

void HTMLIFrameElement::parseAttribute(const QualifiedName& name, const AtomicString& value)
{
    if (name == HTMLNames::srcAttr) {
        navigateView();
    } else {
        HTMLElement::parseAttribute(name, value);
    }
}

RenderObject* HTMLIFrameElement::createRenderer(RenderStyle* style)
{
    return new RenderIFrame(this);
}

void HTMLIFrameElement::OnViewDestroyed(mojo::View* view)
{
    DCHECK_EQ(view, m_contentView);
    m_contentView = nullptr;
}

ScriptValue HTMLIFrameElement::takeServicesHandle(ScriptState* scriptState)
{
    return ScriptValue(scriptState, gin::ConvertToV8(scriptState->isolate(), m_services.PassMessagePipe().release()));
}

ScriptValue HTMLIFrameElement::takeExposedServicesHandle(ScriptState* scriptState)
{
    return ScriptValue(scriptState, gin::ConvertToV8(scriptState->isolate(), m_exposedServices.release()));
}

void HTMLIFrameElement::embedViewManagerClient(const ScriptValue& client) {
  if (!m_contentView)
    return;

  mojo::MessagePipeHandle handle;
  if (gin::ConvertFromV8(client.isolate(), client.v8Value(), &handle))
    m_contentView->Embed(mojo::MakeProxy<mojo::ViewManagerClient>(mojo::MakeScopedHandle(handle)));
}

void HTMLIFrameElement::navigateView()
{
    if (!m_contentView)
        return;

    String urlString = stripLeadingAndTrailingHTMLSpaces(getAttribute(HTMLNames::srcAttr));
    if (urlString.isEmpty())
        urlString = blankURL().string();

    KURL url = document().completeURL(urlString);

    mojo::MessagePipe exposedServicesPipe;
    m_exposedServices = exposedServicesPipe.handle0.Pass();

    m_contentView->Embed(mojo::String::From(url.string().utf8().data()),
        mojo::GetProxy(&m_services),
        mojo::MakeProxy<mojo::ServiceProvider>(exposedServicesPipe.handle1.Pass()));
}

}
