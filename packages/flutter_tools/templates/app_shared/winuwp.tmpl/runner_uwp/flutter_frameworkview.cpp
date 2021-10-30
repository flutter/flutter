#include "winrt/Windows.ApplicationModel.Core.h"
#include "winrt/Windows.Foundation.h"
#include "winrt/Windows.System.Profile.h"
#include "winrt/Windows.System.Threading.h"
#include "winrt/Windows.UI.Core.h"
#include <winrt/Windows.Foundation.Collections.h>
#include <winrt/Windows.Graphics.Display.h>
#include <winrt/Windows.Storage.h>
#include <winrt/Windows.UI.Popups.h>
#include <winrt/Windows.UI.ViewManagement.Core.h>
#include <winrt/Windows.UI.ViewManagement.h>

#include <chrono>
#include <memory>
#include <thread>

#include <flutter/flutter_view_controller.h>
#include <flutter/flutter_windows.h>
#include <flutter/generated_plugin_registrant.h>
#include <flutter/plugin_registry.h>

struct FlutterFrameworkView
    : winrt::implements<
          FlutterFrameworkView,
          winrt::Windows::ApplicationModel::Core::IFrameworkView> {
  // |winrt::Windows::ApplicationModel::Core::IFrameworkView|
  void
  Initialize(winrt::Windows::ApplicationModel::Core::CoreApplicationView const
                 &applicationView) {

    // Layout scaling must be disabled in the appinitialization phase in order
    // to take effect correctly.
    if (winrt::Windows::System::Profile::AnalyticsInfo::VersionInfo()
            .DeviceFamily() == L"Windows.Xbox") {

      bool result = winrt::Windows::UI::ViewManagement::ApplicationViewScaling::
          TrySetDisableLayoutScaling(true);
      if (!result) {
        OutputDebugString(L"Couldn't disable layout scaling");
      }
    }

    main_view_ = applicationView;
    main_view_.Activated({this, &FlutterFrameworkView::OnActivated});
  }

  // |winrt::Windows::ApplicationModel::Core::IFrameworkView|
  void Uninitialize() {
    main_view_.Activated(nullptr);
    main_view_ = nullptr;
  }

  // |winrt::Windows::ApplicationModel::Core::IFrameworkView|
  void Load(winrt::hstring const &) {}

  // |winrt::Windows::ApplicationModel::Core::IFrameworkView|
  void Run() {
    winrt::Windows::UI::Core::CoreWindow window =
        winrt::Windows::UI::Core::CoreWindow::GetForCurrentThread();

    winrt::Windows::UI::Core::CoreDispatcher dispatcher = window.Dispatcher();
    dispatcher.ProcessEvents(
        winrt::Windows::UI::Core::CoreProcessEventsOption::ProcessUntilQuit);
  }

  // |winrt::Windows::ApplicationModel::Core::IFrameworkView|
  winrt::Windows::Foundation::IAsyncAction
  SetWindow(winrt::Windows::UI::Core::CoreWindow const &window) {

    // Capture reference to window.
    window_ = window;

    // Lay out the window's content within the region occupied by the
    // CoreWindow.
    auto appView = winrt::Windows::UI::ViewManagement::ApplicationView::
        GetForCurrentView();

    appView.SetDesiredBoundsMode(winrt::Windows::UI::ViewManagement::
                                     ApplicationViewBoundsMode::UseCoreWindow);

    // Configure folder paths.
    try {
      winrt::Windows::Storage::StorageFolder folder =
          winrt::Windows::ApplicationModel::Package::Current()
              .InstalledLocation();

      winrt::Windows::Storage::StorageFolder assets =
          co_await folder.GetFolderAsync(L"Assets");
      winrt::Windows::Storage::StorageFolder data =
          co_await assets.GetFolderAsync(L"data");
      winrt::Windows::Storage::StorageFolder flutter_assets =
          co_await data.GetFolderAsync(L"flutter_assets");
      winrt::Windows::Storage::StorageFile icu_data =
          co_await data.GetFileAsync(L"icudtl.dat");

#if NDEBUG
      winrt::Windows::Storage::StorageFile aot_data =
          co_await data.GetFileAsync(L"app.so");
#endif

      std::wstring flutter_assets_path{flutter_assets.Path()};
      std::wstring icu_data_path{icu_data.Path()};
      std::wstring aot_data_path {
#if NDEBUG
        aot_data.Path()
#endif
      };

      flutter::DartProject project(flutter_assets_path, icu_data_path,
                                   aot_data_path);

      // Construct viewcontroller using the Window and project
            flutter_view_controller_ = std::make_unique<flutter::FlutterViewController>(
                static_cast<ABI::Windows::ApplicationModel::Core::CoreApplicationView*>(winrt::get_abi(main_view_)),
                static_cast<ABI::Windows::ApplicationModel::Activation::IActivatedEventArgs*>(winrt::get_abi(launch_args_)),
                project);

      // If plugins present, register them.
      RegisterPlugins(flutter_view_controller_.get()->engine());
    } catch (winrt::hresult_error &err) {
      winrt::Windows::UI::Popups::MessageDialog md =
          winrt::Windows::UI::Popups::MessageDialog::MessageDialog(
              L"There was a problem starting the engine: " + err.message());
      md.ShowAsync();
    }
  }

  void OnActivated(
      winrt::Windows::ApplicationModel::Core::CoreApplicationView const
          &applicationView,
      winrt::Windows::ApplicationModel::Activation::IActivatedEventArgs const
          &args) {
    // Activate the application window, making it visible and enabling it to
    // receive events.
    applicationView.CoreWindow().Activate();

    // Capture launch args to later pass to Flutter.
    launch_args_ = args;
  }

  // Current CoreApplicationView.
  winrt::Windows::ApplicationModel::Core::CoreApplicationView main_view_{
      nullptr};

  // Current CoreWindow.
  winrt::Windows::UI::Core::CoreWindow window_{nullptr};

  // Current FlutterViewController.
  std::unique_ptr<flutter::FlutterViewController> flutter_view_controller_{
      nullptr};

  // Launch args that were passed in on activation.
  winrt::Windows::ApplicationModel::Activation::IActivatedEventArgs
      launch_args_;
};
