// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/viewer/document_view.h"

#include "base/bind.h"
#include "base/location.h"
#include "base/message_loop/message_loop_proxy.h"
#include "base/single_thread_task_runner.h"
#include "base/strings/string_util.h"
#include "base/thread_task_runner_handle.h"
#include "mojo/converters/geometry/geometry_type_converters.h"
#include "mojo/public/cpp/application/connect.h"
#include "mojo/public/cpp/system/data_pipe.h"
#include "mojo/public/interfaces/application/shell.mojom.h"
#include "mojo/services/public/cpp/view_manager/view.h"
#include "mojo/services/public/interfaces/surfaces/surfaces_service.mojom.h"
#include "skia/ext/refptr.h"
#include "sky/engine/public/platform/Platform.h"
#include "sky/engine/public/platform/WebHTTPHeaderVisitor.h"
#include "sky/engine/public/web/WebConsoleMessage.h"
#include "sky/engine/public/web/WebDocument.h"
#include "sky/engine/public/web/WebElement.h"
#include "sky/engine/public/web/WebInputEvent.h"
#include "sky/engine/public/web/WebLocalFrame.h"
#include "sky/engine/public/web/WebScriptSource.h"
#include "sky/engine/public/web/WebSettings.h"
#include "sky/engine/public/web/WebView.h"
#include "sky/viewer/converters/input_event_types.h"
#include "sky/viewer/converters/url_request_types.h"
#include "sky/viewer/internals.h"
#include "sky/viewer/platform/weblayertreeview_impl.h"
#include "sky/viewer/platform/weburlloader_impl.h"
#include "sky/viewer/script/script_runner.h"
#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkColor.h"
#include "third_party/skia/include/core/SkDevice.h"
#include "v8/include/v8.h"

namespace sky {
namespace {

void ConfigureSettings(blink::WebSettings* settings) {
  settings->setDefaultFixedFontSize(13);
  settings->setDefaultFontSize(16);
  settings->setLoadsImagesAutomatically(true);
}

mojo::Target WebNavigationPolicyToNavigationTarget(
    blink::WebNavigationPolicy policy) {
  switch (policy) {
    case blink::WebNavigationPolicyCurrentTab:
      return mojo::TARGET_SOURCE_NODE;
    case blink::WebNavigationPolicyNewBackgroundTab:
    case blink::WebNavigationPolicyNewForegroundTab:
    case blink::WebNavigationPolicyNewWindow:
    case blink::WebNavigationPolicyNewPopup:
      return mojo::TARGET_NEW_NODE;
    default:
      return mojo::TARGET_DEFAULT;
  }
}

}  // namespace

static int s_next_debugger_id = 1;

DocumentView::DocumentView(
    mojo::URLResponsePtr response,
    mojo::ShellPtr shell,
    scoped_refptr<base::MessageLoopProxy> compositor_thread)
    : response_(response.Pass()),
      shell_(shell.Pass()),
      web_view_(NULL),
      root_(NULL),
      view_manager_client_factory_(shell_.get(), this),
      inspector_service_factory_(this),
      compositor_thread_(compositor_thread),
      debugger_id_(s_next_debugger_id++),
      weak_factory_(this) {
  shell_.set_client(this);
}

DocumentView::~DocumentView() {
  if (web_view_)
    web_view_->close();
  if (root_)
    root_->RemoveObserver(this);
}

base::WeakPtr<DocumentView> DocumentView::GetWeakPtr() {
  return weak_factory_.GetWeakPtr();
}

void DocumentView::AcceptConnection(const mojo::String& requestor_url,
                                    mojo::ServiceProviderPtr provider) {
  exported_services_.AddService(&view_manager_client_factory_);
  mojo::WeakBindToPipe(&exported_services_, provider.PassMessagePipe());
}

void DocumentView::Initialize(mojo::Array<mojo::String> args) {
}

void DocumentView::OnEmbed(
    mojo::ViewManager* view_manager,
    mojo::View* root,
    mojo::ServiceProviderImpl* exported_services,
    scoped_ptr<mojo::ServiceProvider> imported_services) {

  root_ = root;
  imported_services_ = imported_services.Pass();
  navigator_host_.set_service_provider(imported_services_.get());
  exported_services->AddService(&inspector_service_factory_);

  Load(response_.Pass());

  gfx::Size size = root_->bounds().To<gfx::Rect>().size();
  web_view_->resize(size);
  // TODO(abarth): We should ask the view whether it is focused instead of
  // assuming that we're focused.
  web_view_->setFocus(true);
  web_layer_tree_view_impl_->setViewportSize(size);
  web_layer_tree_view_impl_->set_view(root_);
  root_->AddObserver(this);
}

void DocumentView::OnViewManagerDisconnected(mojo::ViewManager* view_manager) {
  // TODO(aa): Need to figure out how shutdown works.
}

void DocumentView::Load(mojo::URLResponsePtr response) {
  web_view_ = blink::WebView::create(this);
  web_layer_tree_view_impl_->set_widget(web_view_);
  ConfigureSettings(web_view_->settings());
  web_view_->setMainFrame(blink::WebLocalFrame::create(this));
  GURL url(response->url);
  web_view_->mainFrame()->load(url, response->body.Pass());
}

blink::WebLayerTreeView* DocumentView::initializeLayerTreeView() {
  mojo::ServiceProviderPtr surfaces_service_provider;
  shell_->ConnectToApplication("mojo:surfaces_service",
                               mojo::GetProxy(&surfaces_service_provider));
  mojo::InterfacePtr<mojo::SurfacesService> surfaces_service;
  mojo::ConnectToService(surfaces_service_provider.get(), &surfaces_service);

  mojo::ServiceProviderPtr gpu_service_provider;
  // TODO(jamesr): Should be mojo:gpu_service
  shell_->ConnectToApplication("mojo:native_viewport_service",
                               mojo::GetProxy(&gpu_service_provider));
  mojo::InterfacePtr<mojo::Gpu> gpu_service;
  mojo::ConnectToService(gpu_service_provider.get(), &gpu_service);
  web_layer_tree_view_impl_.reset(new WebLayerTreeViewImpl(
      compositor_thread_, surfaces_service.Pass(), gpu_service.Pass()));

  return web_layer_tree_view_impl_.get();
}

void DocumentView::scheduleAnimation() {
  DCHECK(web_view_);

  if (!web_view_->settings()->compositorIsEnabled())
    web_layer_tree_view_impl_->setNeedsAnimate();
}

mojo::View* DocumentView::createChildFrame(const blink::WebURL& url) {
  if (!root_)
    return nullptr;

  mojo::View* child = mojo::View::Create(root_->view_manager());
  root_->AddChild(child);
  child->Embed(mojo::String::From(url.string().utf8()));

  return child;
}

void DocumentView::frameDetached(blink::WebFrame* frame) {
  // |frame| is invalid after here.
  frame->close();
}

blink::WebNavigationPolicy DocumentView::decidePolicyForNavigation(
    const blink::WebFrameClient::NavigationPolicyInfo& info) {

  navigator_host_->RequestNavigate(
      WebNavigationPolicyToNavigationTarget(info.defaultPolicy),
      mojo::URLRequest::From(info.urlRequest).Pass());

  return blink::WebNavigationPolicyIgnore;
}

void DocumentView::didAddMessageToConsole(
    const blink::WebConsoleMessage& message,
    const blink::WebString& source_name,
    unsigned source_line,
    const blink::WebString& stack_trace) {
}

void DocumentView::didCreateScriptContext(blink::WebLocalFrame* frame,
                                          v8::Handle<v8::Context> context,
                                          int extensionGroup,
                                          int worldId) {
  script_runner_.reset(new ScriptRunner(frame, context));

  v8::Isolate* isolate = context->GetIsolate();
  gin::Handle<Internals> internals = Internals::Create(isolate, this);
  context->Global()->Set(gin::StringToV8(isolate, "internals"),
                         gin::ConvertToV8(isolate, internals));
}

blink::ServiceProvider& DocumentView::services() {
  return *this;
}

mojo::NavigatorHost* DocumentView::NavigatorHost() {
  return navigator_host_.get();
}

mojo::Shell* DocumentView::Shell() {
  return shell_.get();
}

void DocumentView::OnViewBoundsChanged(mojo::View* view,
                                       const mojo::Rect& old_bounds,
                                       const mojo::Rect& new_bounds) {
  DCHECK_EQ(view, root_);
  gfx::Size size = new_bounds.To<gfx::Rect>().size();
  web_view_->resize(size);
  web_layer_tree_view_impl_->setViewportSize(size);
}

void DocumentView::OnViewFocusChanged(mojo::View* gained_focus,
                                      mojo::View* lost_focus) {
  if (root_ == lost_focus) {
    web_view_->setFocus(false);
  } else if (root_ == gained_focus) {
    web_view_->setFocus(true);
  }
}

void DocumentView::OnViewDestroyed(mojo::View* view) {
  DCHECK_EQ(view, root_);

  delete this;
}

void DocumentView::OnViewInputEvent(
    mojo::View* view, const mojo::EventPtr& event) {
  scoped_ptr<blink::WebInputEvent> web_event =
      event.To<scoped_ptr<blink::WebInputEvent> >();
  if (web_event)
    web_view_->handleInputEvent(*web_event);
}

}  // namespace sky
