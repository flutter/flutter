// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/config/gpu_info_collector.h"

// This has to be included before windows.h.
#include "third_party/re2/re2/re2.h"

#include <windows.h>
#include <cfgmgr32.h>
#include <d3d9.h>
#include <d3d11.h>
#include <dxgi.h>
#include <setupapi.h>

#include "base/command_line.h"
#include "base/files/file_enumerator.h"
#include "base/files/file_path.h"
#include "base/files/file_util.h"
#include "base/logging.h"
#include "base/message_loop/message_loop.h"
#include "base/metrics/field_trial.h"
#include "base/metrics/histogram.h"
#include "base/scoped_native_library.h"
#include "base/strings/string16.h"
#include "base/strings/string_number_conversions.h"
#include "base/strings/string_util.h"
#include "base/strings/stringprintf.h"
#include "base/strings/utf_string_conversions.h"
#include "base/threading/thread.h"
#include "base/threading/worker_pool.h"
#include "base/trace_event/trace_event.h"
#include "base/win/registry.h"
#include "base/win/scoped_com_initializer.h"
#include "base/win/scoped_comptr.h"
#include "base/win/windows_version.h"
#include "third_party/libxml/chromium/libxml_utils.h"
#include "ui/gl/gl_implementation.h"
#include "ui/gl/gl_surface_egl.h"

namespace gpu {

namespace {

// This must be kept in sync with histograms.xml.
enum DisplayLinkInstallationStatus {
  DISPLAY_LINK_NOT_INSTALLED,
  DISPLAY_LINK_7_1_OR_EARLIER,
  DISPLAY_LINK_7_2_OR_LATER,
  DISPLAY_LINK_INSTALLATION_STATUS_MAX
};

float ReadXMLFloatValue(XmlReader* reader) {
  std::string score_string;
  if (!reader->ReadElementContent(&score_string))
    return 0.0;

  double score;
  if (!base::StringToDouble(score_string, &score))
    return 0.0;

  return static_cast<float>(score);
}

// Returns the display link driver version or an invalid version if it is
// not installed.
Version DisplayLinkVersion() {
  base::win::RegKey key;

  if (key.Open(HKEY_LOCAL_MACHINE, L"SOFTWARE", KEY_READ | KEY_WOW64_64KEY))
    return Version();

  if (key.OpenKey(L"DisplayLink", KEY_READ | KEY_WOW64_64KEY))
    return Version();

  if (key.OpenKey(L"Core", KEY_READ | KEY_WOW64_64KEY))
    return Version();

  base::string16 version;
  if (key.ReadValue(L"Version", &version))
    return Version();

  return Version(base::UTF16ToASCII(version));
}

// Returns whether Lenovo dCute is installed.
bool IsLenovoDCuteInstalled() {
  base::win::RegKey key;

  if (key.Open(HKEY_LOCAL_MACHINE, L"SOFTWARE", KEY_READ | KEY_WOW64_64KEY))
    return false;

  if (key.OpenKey(L"Lenovo", KEY_READ | KEY_WOW64_64KEY))
    return false;

  if (key.OpenKey(L"Lenovo dCute", KEY_READ | KEY_WOW64_64KEY))
    return false;

  return true;
}

void DeviceIDToVendorAndDevice(const std::wstring& id,
                               uint32* vendor_id,
                               uint32* device_id) {
  *vendor_id = 0;
  *device_id = 0;
  if (id.length() < 21)
    return;
  base::string16 vendor_id_string = id.substr(8, 4);
  base::string16 device_id_string = id.substr(17, 4);
  int vendor = 0;
  int device = 0;
  base::HexStringToInt(base::UTF16ToASCII(vendor_id_string), &vendor);
  base::HexStringToInt(base::UTF16ToASCII(device_id_string), &device);
  *vendor_id = vendor;
  *device_id = device;
}

}  // namespace anonymous

#if defined(GOOGLE_CHROME_BUILD) && defined(OFFICIAL_BUILD)
// This function has a real implementation for official builds that can
// be found in src/third_party/amd.
void GetAMDVideocardInfo(GPUInfo* gpu_info);
#else
void GetAMDVideocardInfo(GPUInfo* gpu_info) {
  DCHECK(gpu_info);
  return;
}
#endif

CollectInfoResult CollectDriverInfoD3D(const std::wstring& device_id,
                                       GPUInfo* gpu_info) {
  TRACE_EVENT0("gpu", "CollectDriverInfoD3D");

  // Display adapter class GUID from
  // https://msdn.microsoft.com/en-us/library/windows/hardware/ff553426%28v=vs.85%29.aspx
  GUID display_class = {0x4d36e968,
                        0xe325,
                        0x11ce,
                        {0xbf, 0xc1, 0x08, 0x00, 0x2b, 0xe1, 0x03, 0x18}};

  // create device info for the display device
  HDEVINFO device_info;
  if (base::win::GetVersion() <= base::win::VERSION_XP) {
    // Collection of information on all adapters is much slower on XP (almost
    // 100ms), and not very useful (as it's not going to use the GPU anyway), so
    // just collect information on the current device. http://crbug.com/456178
    device_info =
        SetupDiGetClassDevsW(NULL, device_id.c_str(), NULL,
                             DIGCF_PRESENT | DIGCF_PROFILE | DIGCF_ALLCLASSES);
  } else {
    device_info =
        SetupDiGetClassDevsW(&display_class, NULL, NULL, DIGCF_PRESENT);
  }
  if (device_info == INVALID_HANDLE_VALUE) {
    LOG(ERROR) << "Creating device info failed";
    return kCollectInfoNonFatalFailure;
  }

  struct GPUDriver {
    GPUInfo::GPUDevice device;
    std::string driver_vendor;
    std::string driver_version;
    std::string driver_date;
  };

  std::vector<GPUDriver> drivers;

  int primary_device = -1;
  bool found_amd = false;
  bool found_intel = false;

  DWORD index = 0;
  SP_DEVINFO_DATA device_info_data;
  device_info_data.cbSize = sizeof(device_info_data);
  while (SetupDiEnumDeviceInfo(device_info, index++, &device_info_data)) {
    WCHAR value[255];
    if (SetupDiGetDeviceRegistryPropertyW(device_info,
                                        &device_info_data,
                                        SPDRP_DRIVER,
                                        NULL,
                                        reinterpret_cast<PBYTE>(value),
                                        sizeof(value),
                                        NULL)) {
      HKEY key;
      std::wstring driver_key = L"System\\CurrentControlSet\\Control\\Class\\";
      driver_key += value;
      LONG result = RegOpenKeyExW(
          HKEY_LOCAL_MACHINE, driver_key.c_str(), 0, KEY_QUERY_VALUE, &key);
      if (result == ERROR_SUCCESS) {
        DWORD dwcb_data = sizeof(value);
        std::string driver_version;
        result = RegQueryValueExW(
            key, L"DriverVersion", NULL, NULL,
            reinterpret_cast<LPBYTE>(value), &dwcb_data);
        if (result == ERROR_SUCCESS)
          driver_version = base::UTF16ToASCII(std::wstring(value));

        std::string driver_date;
        dwcb_data = sizeof(value);
        result = RegQueryValueExW(
            key, L"DriverDate", NULL, NULL,
            reinterpret_cast<LPBYTE>(value), &dwcb_data);
        if (result == ERROR_SUCCESS)
          driver_date = base::UTF16ToASCII(std::wstring(value));

        std::string driver_vendor;
        dwcb_data = sizeof(value);
        result = RegQueryValueExW(
            key, L"ProviderName", NULL, NULL,
            reinterpret_cast<LPBYTE>(value), &dwcb_data);
        if (result == ERROR_SUCCESS)
          driver_vendor = base::UTF16ToASCII(std::wstring(value));

        wchar_t new_device_id[MAX_DEVICE_ID_LEN];
        CONFIGRET status = CM_Get_Device_ID(
            device_info_data.DevInst, new_device_id, MAX_DEVICE_ID_LEN, 0);

        if (status == CR_SUCCESS) {
          GPUDriver driver;

          driver.driver_vendor = driver_vendor;
          driver.driver_version = driver_version;
          driver.driver_date = driver_date;
          std::wstring id = new_device_id;

          if (id.compare(0, device_id.size(), device_id) == 0)
            primary_device = drivers.size();

          uint32 vendor_id = 0, device_id = 0;
          DeviceIDToVendorAndDevice(id, &vendor_id, &device_id);
          driver.device.vendor_id = vendor_id;
          driver.device.device_id = device_id;
          drivers.push_back(driver);

          if (vendor_id == 0x8086)
            found_intel = true;
          if (vendor_id == 0x1002)
            found_amd = true;
        }

        RegCloseKey(key);
      }
    }
  }
  SetupDiDestroyDeviceInfoList(device_info);
  bool found = false;
  if (found_amd && found_intel) {
    // AMD Switchable system found.
    for (const auto& driver : drivers) {
      if (driver.device.vendor_id == 0x8086) {
        gpu_info->gpu = driver.device;
      }

      if (driver.device.vendor_id == 0x1002) {
        gpu_info->driver_vendor = driver.driver_vendor;
        gpu_info->driver_version = driver.driver_version;
        gpu_info->driver_date = driver.driver_date;
      }
    }
    GetAMDVideocardInfo(gpu_info);

    if (!gpu_info->amd_switchable) {
      // Some machines aren't properly detected as AMD switchable, but count
      // them anyway.
      gpu_info->amd_switchable = true;
      for (const auto& driver : drivers) {
        if (driver.device.vendor_id == 0x1002) {
          gpu_info->gpu = driver.device;
        } else {
          gpu_info->secondary_gpus.push_back(driver.device);
        }
      }
    }
    found = true;
  } else {
    for (size_t i = 0; i < drivers.size(); ++i) {
      const GPUDriver& driver = drivers[i];
      if (static_cast<int>(i) == primary_device) {
        found = true;
        gpu_info->gpu = driver.device;
        gpu_info->driver_vendor = driver.driver_vendor;
        gpu_info->driver_version = driver.driver_version;
        gpu_info->driver_date = driver.driver_date;
      } else {
        gpu_info->secondary_gpus.push_back(driver.device);
      }
    }
  }

  return found ? kCollectInfoSuccess : kCollectInfoNonFatalFailure;
}

CollectInfoResult CollectContextGraphicsInfo(GPUInfo* gpu_info) {
  TRACE_EVENT0("gpu", "CollectGraphicsInfo");

  DCHECK(gpu_info);

  if (base::CommandLine::ForCurrentProcess()->HasSwitch(switches::kUseGL)) {
    std::string requested_implementation_name =
        base::CommandLine::ForCurrentProcess()->GetSwitchValueASCII(
            switches::kUseGL);
    if (requested_implementation_name == "swiftshader") {
      gpu_info->software_rendering = true;
      gpu_info->context_info_state = kCollectInfoNonFatalFailure;
      return kCollectInfoNonFatalFailure;
    }
  }

  CollectInfoResult result = CollectGraphicsInfoGL(gpu_info);
  if (result != kCollectInfoSuccess) {
    gpu_info->context_info_state = result;
    return result;
  }

  // ANGLE's renderer strings are of the form:
  // ANGLE (<adapter_identifier> Direct3D<version> vs_x_x ps_x_x)
  std::string direct3d_version;
  int vertex_shader_major_version = 0;
  int vertex_shader_minor_version = 0;
  int pixel_shader_major_version = 0;
  int pixel_shader_minor_version = 0;
  gpu_info->adapter_luid = 0;
  if (RE2::FullMatch(gpu_info->gl_renderer,
                     "ANGLE \\(.*\\)") &&
      RE2::PartialMatch(gpu_info->gl_renderer,
                        " Direct3D(\\w+)",
                        &direct3d_version) &&
      RE2::PartialMatch(gpu_info->gl_renderer,
                        " vs_(\\d+)_(\\d+)",
                        &vertex_shader_major_version,
                        &vertex_shader_minor_version) &&
      RE2::PartialMatch(gpu_info->gl_renderer,
                        " ps_(\\d+)_(\\d+)",
                        &pixel_shader_major_version,
                        &pixel_shader_minor_version)) {
    gpu_info->can_lose_context = direct3d_version == "9";
    gpu_info->vertex_shader_version =
        base::StringPrintf("%d.%d",
                           vertex_shader_major_version,
                           vertex_shader_minor_version);
    gpu_info->pixel_shader_version =
        base::StringPrintf("%d.%d",
                           pixel_shader_major_version,
                           pixel_shader_minor_version);

    // ANGLE's EGL vendor strings are of the form:
    // Google, Inc. (adapter LUID: 0123456789ABCDEF)
    // The LUID is optional and identifies the GPU adapter ANGLE is using.
    const char* egl_vendor = eglQueryString(
        gfx::GLSurfaceEGL::GetHardwareDisplay(),
        EGL_VENDOR);
    RE2::PartialMatch(egl_vendor,
                      " \\(adapter LUID: ([0-9A-Fa-f]{16})\\)",
                      RE2::Hex(&gpu_info->adapter_luid));

    // DirectX diagnostics are collected asynchronously because it takes a
    // couple of seconds.
  } else {
    gpu_info->dx_diagnostics_info_state = kCollectInfoNonFatalFailure;
  }

  gpu_info->context_info_state = kCollectInfoSuccess;
  return kCollectInfoSuccess;
}

CollectInfoResult CollectGpuID(uint32* vendor_id, uint32* device_id) {
  DCHECK(vendor_id && device_id);
  *vendor_id = 0;
  *device_id = 0;

  // Taken from http://developer.nvidia.com/object/device_ids.html
  DISPLAY_DEVICE dd;
  dd.cb = sizeof(DISPLAY_DEVICE);
  std::wstring id;
  for (int i = 0; EnumDisplayDevices(NULL, i, &dd, 0); ++i) {
    if (dd.StateFlags & DISPLAY_DEVICE_PRIMARY_DEVICE) {
      id = dd.DeviceID;
      break;
    }
  }

  if (id.length() > 20) {
    DeviceIDToVendorAndDevice(id, vendor_id, device_id);
    if (*vendor_id != 0 && *device_id != 0)
      return kCollectInfoSuccess;
  }
  return kCollectInfoNonFatalFailure;
}

CollectInfoResult CollectBasicGraphicsInfo(GPUInfo* gpu_info) {
  TRACE_EVENT0("gpu", "CollectPreliminaryGraphicsInfo");

  DCHECK(gpu_info);

  // nvd3d9wrap.dll is loaded into all processes when Optimus is enabled.
  HMODULE nvd3d9wrap = GetModuleHandleW(L"nvd3d9wrap.dll");
  gpu_info->optimus = nvd3d9wrap != NULL;

  gpu_info->lenovo_dcute = IsLenovoDCuteInstalled();

  gpu_info->display_link_version = DisplayLinkVersion();

  if (!gpu_info->display_link_version .IsValid()) {
    UMA_HISTOGRAM_ENUMERATION("GPU.DisplayLinkInstallationStatus",
                              DISPLAY_LINK_NOT_INSTALLED,
                              DISPLAY_LINK_INSTALLATION_STATUS_MAX);
  } else if (gpu_info->display_link_version.IsOlderThan("7.2")) {
    UMA_HISTOGRAM_ENUMERATION("GPU.DisplayLinkInstallationStatus",
                              DISPLAY_LINK_7_1_OR_EARLIER,
                              DISPLAY_LINK_INSTALLATION_STATUS_MAX);
  } else {
    UMA_HISTOGRAM_ENUMERATION("GPU.DisplayLinkInstallationStatus",
                              DISPLAY_LINK_7_2_OR_LATER,
                              DISPLAY_LINK_INSTALLATION_STATUS_MAX);
  }

  // Taken from http://developer.nvidia.com/object/device_ids.html
  DISPLAY_DEVICE dd;
  dd.cb = sizeof(DISPLAY_DEVICE);
  std::wstring id;
  for (int i = 0; EnumDisplayDevices(NULL, i, &dd, 0); ++i) {
    if (dd.StateFlags & DISPLAY_DEVICE_PRIMARY_DEVICE) {
      id = dd.DeviceID;
      break;
    }
  }

  if (id.length() <= 20) {
    gpu_info->basic_info_state = kCollectInfoNonFatalFailure;
    return kCollectInfoNonFatalFailure;
  }

  DeviceIDToVendorAndDevice(id, &gpu_info->gpu.vendor_id,
                            &gpu_info->gpu.device_id);
  // TODO(zmo): we only need to call CollectDriverInfoD3D() if we use ANGLE.
  if (!CollectDriverInfoD3D(id, gpu_info)) {
    gpu_info->basic_info_state = kCollectInfoNonFatalFailure;
    return kCollectInfoNonFatalFailure;
  }

  gpu_info->basic_info_state = kCollectInfoSuccess;
  return kCollectInfoSuccess;
}

CollectInfoResult CollectDriverInfoGL(GPUInfo* gpu_info) {
  TRACE_EVENT0("gpu", "CollectDriverInfoGL");

  if (!gpu_info->driver_version.empty())
    return kCollectInfoSuccess;

  bool parsed = RE2::PartialMatch(
      gpu_info->gl_version, "([\\d\\.]+)$", &gpu_info->driver_version);
  return parsed ? kCollectInfoSuccess : kCollectInfoNonFatalFailure;
}

void MergeGPUInfo(GPUInfo* basic_gpu_info,
                  const GPUInfo& context_gpu_info) {
  DCHECK(basic_gpu_info);

  if (context_gpu_info.software_rendering) {
    basic_gpu_info->software_rendering = true;
    return;
  }

  // Track D3D Shader Model (if available)
  const std::string& shader_version =
      context_gpu_info.vertex_shader_version;

  // Only gather if this is the first time we're seeing
  // a non-empty shader version string.
  if (!shader_version.empty() &&
      basic_gpu_info->vertex_shader_version.empty()) {

    // Note: do not reorder, used by UMA_HISTOGRAM below
    enum ShaderModel {
      SHADER_MODEL_UNKNOWN,
      SHADER_MODEL_2_0,
      SHADER_MODEL_3_0,
      SHADER_MODEL_4_0,
      SHADER_MODEL_4_1,
      SHADER_MODEL_5_0,
      NUM_SHADER_MODELS
    };

    ShaderModel shader_model = SHADER_MODEL_UNKNOWN;

    if (shader_version == "5.0") {
      shader_model = SHADER_MODEL_5_0;
    } else if (shader_version == "4.1") {
      shader_model = SHADER_MODEL_4_1;
    } else if (shader_version == "4.0") {
      shader_model = SHADER_MODEL_4_0;
    } else if (shader_version == "3.0") {
      shader_model = SHADER_MODEL_3_0;
    } else if (shader_version == "2.0") {
      shader_model = SHADER_MODEL_2_0;
    }

    UMA_HISTOGRAM_ENUMERATION("GPU.D3DShaderModel",
                              shader_model,
                              NUM_SHADER_MODELS);
  }

  MergeGPUInfoGL(basic_gpu_info, context_gpu_info);

  basic_gpu_info->dx_diagnostics_info_state =
      context_gpu_info.dx_diagnostics_info_state;
  basic_gpu_info->dx_diagnostics = context_gpu_info.dx_diagnostics;
}

}  // namespace gpu
