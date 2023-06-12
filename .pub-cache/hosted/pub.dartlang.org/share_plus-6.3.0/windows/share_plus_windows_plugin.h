#ifndef FLUTTER_PLUGIN_SHARE_PLUS_WINDOWS_PLUGIN_H_
#define FLUTTER_PLUGIN_SHARE_PLUS_WINDOWS_PLUGIN_H_

#include <Windows.h>
// Must be present after Windows.h.
#include <ShObjIdl.h>
#include <roapi.h>
#include <windows.applicationmodel.datatransfer.h>
#include <windows.foundation.collections.h>
#include <windows.foundation.h>
#include <windows.storage.h>
#include <wrl.h>
#include <wrl/client.h>
#include <wrl/event.h>
#include <wrl/wrappers/corewrappers.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#pragma comment(lib, "runtimeobject.lib")

namespace WRL = Microsoft::WRL;
namespace WindowsFoundation = ABI::Windows::Foundation;
namespace WindowsStorage = ABI::Windows::Storage;
namespace DataTransfer = ABI::Windows::ApplicationModel::DataTransfer;

namespace share_plus_windows {

class SharePlusWindowsPlugin : public flutter::Plugin {
public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  SharePlusWindowsPlugin(flutter::PluginRegistrarWindows *registrar);

  virtual ~SharePlusWindowsPlugin();

  SharePlusWindowsPlugin(const SharePlusWindowsPlugin &) = delete;
  SharePlusWindowsPlugin &operator=(const SharePlusWindowsPlugin &) = delete;

private:
  static constexpr auto kSharePlusChannelName =
      "dev.fluttercommunity.plus/share";

  static constexpr auto kShareResultUnavailable =
      "dev.fluttercommunity.plus/share/unavailable";

  static constexpr auto kShare = "share";
  static constexpr auto kShareFiles = "shareFiles";
  static constexpr auto kShareWithResult = "shareWithResult";
  static constexpr auto kShareFilesWithResult = "shareFilesWithResult";

  HWND GetWindow();

  WRL::ComPtr<DataTransfer::IDataTransferManager> GetDataTransferManager();

  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  static HRESULT GetStorageFileFromPath(wchar_t *path,
                                        WindowsStorage::IStorageFile **file);

  static std::wstring SharePlusWindowsPlugin::Utf16FromUtf8(std::string string);

  flutter::PluginRegistrarWindows *registrar_ = nullptr;
  WRL::ComPtr<IDataTransferManagerInterop> data_transfer_manager_interop_ =
      nullptr;
  WRL::ComPtr<DataTransfer::IDataTransferManager> data_transfer_manager_ =
      nullptr;
  EventRegistrationToken data_transfer_manager_token_;

  // Present here to keep |std::string| in memory until data request callback
  // from |IDataTransferManager| takes place.
  // Subsequent calls on the platform channel will overwrite the existing value.
  std::string share_text_ = "";
  std::optional<std::string> share_subject_ = std::nullopt;
  std::vector<std::string> paths_ = {};
  std::vector<std::string> mime_types_ = {};
};

} // namespace share_plus_windows

#endif // FLUTTER_PLUGIN_SHARE_PLUS_WINDOWS_PLUGIN_H_
