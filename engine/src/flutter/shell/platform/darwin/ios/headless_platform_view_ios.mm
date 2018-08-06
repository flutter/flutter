
#include "flutter/shell/platform/darwin/ios/headless_platform_view_ios.h"

namespace shell {

HeadlessPlatformViewIOS::HeadlessPlatformViewIOS(PlatformView::Delegate& delegate,
                                                 blink::TaskRunners task_runners)
    : PlatformView(delegate, std::move(task_runners)) {}

HeadlessPlatformViewIOS::~HeadlessPlatformViewIOS() = default;

PlatformMessageRouter& HeadlessPlatformViewIOS::GetPlatformMessageRouter() {
  return platform_message_router_;
}

// |shell::PlatformView|
void HeadlessPlatformViewIOS::HandlePlatformMessage(fml::RefPtr<blink::PlatformMessage> message) {
  platform_message_router_.HandlePlatformMessage(std::move(message));
}
}
