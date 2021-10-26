
#include <windows.h>

#include "winrt/Windows.ApplicationModel.Core.h"
#include "winrt/Windows.Foundation.h"
#include <winrt/Windows.Foundation.Collections.h>
#include <winrt/Windows.UI.ViewManagement.Core.h>
#include <winrt/Windows.UI.ViewManagement.h>

#include <memory>

#include "flutter_frameworkview.cpp"

struct App
    : winrt::implements<
          App, winrt::Windows::ApplicationModel::Core::IFrameworkViewSource> {
  App() { view_ = winrt::make_self<FlutterFrameworkView>(); }

  // |winrt::Windows::ApplicationModel::Core::IFrameworkViewSource|
  winrt::Windows::ApplicationModel::Core::IFrameworkView CreateView() {
    return view_.as<winrt::Windows::ApplicationModel::Core::IFrameworkView>();
  }

  winrt::com_ptr<FlutterFrameworkView> view_;
};

int __stdcall wWinMain(HINSTANCE, HINSTANCE, PWSTR, int) {
  winrt::Windows::ApplicationModel::Core::CoreApplication::Run(
      winrt::make<App>());
}
