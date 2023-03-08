#include "flutter_window.h"
#include <Windows.h>
#include <optional>
#include <WinHttp.h>
#include <flutter/binary_messenger.h>
#include <flutter/standard_method_codec.h>
#include <flutter/method_channel.h>
#include <flutter/method_result_functions.h>
#include "flutter/generated_plugin_registrant.h"
#include <string>
#pragma comment(lib, "winhttp")

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}


std::string convertLPWSTRToStdString(LPWSTR lpwszStr) {
    // Determine the length of the LPWSTR string
    int strLength = WideCharToMultiByte(CP_UTF8, 0, lpwszStr, -1, NULL, 0, NULL, NULL);

    // Allocate a buffer for the converted string
    char* pszStr = new char[strLength];

    // Convert the LPWSTR string to a UTF-8 encoded std::string
    WideCharToMultiByte(CP_UTF8, 0, lpwszStr, -1, pszStr, strLength, NULL, NULL);
    std::string str(pszStr);

    // Free the buffer
    delete[] pszStr;

    return str;
}

std::string ConvertProxyConfigToString(const WINHTTP_CURRENT_USER_IE_PROXY_CONFIG& proxyConfig) {
    std::string result = convertLPWSTRToStdString(proxyConfig.lpszProxy);
    return result;
}

void initMethodChannel(flutter::FlutterEngine* flutter_instance) {
    // name your channel
    const static std::string channel_name("system_proxy");

    auto channel =
        std::make_unique<flutter::MethodChannel<>>(
            flutter_instance->messenger(), channel_name,
            &flutter::StandardMethodCodec::GetInstance());

    channel->SetMethodCallHandler(
        [](const flutter::MethodCall<>& call,
    std::unique_ptr<flutter::MethodResult<>> result) {
            if (call.method_name().compare("getProxySettings") == 0) {
                WINHTTP_CURRENT_USER_IE_PROXY_CONFIG proxyConfig;
                if (WinHttpGetIEProxyConfigForCurrentUser(&proxyConfig)) {
                    std::string proxyConfigString = ConvertProxyConfigToString(proxyConfig);
                    // free memory
                    GlobalFree(proxyConfig.lpszAutoConfigUrl);
                    GlobalFree(proxyConfig.lpszProxy);
                    GlobalFree(proxyConfig.lpszProxyBypass);
                    result->Success(proxyConfigString);
                } else {
                    result->Success(NULL);
                }
            }
            else {
                result->NotImplemented();
            }
        });
}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  // initialize method channel here
  initMethodChannel(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
