// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/config/gpu_info_collector.h"

#include <vector>

#include "base/logging.h"
#include "base/mac/mac_util.h"
#include "base/mac/scoped_cftyperef.h"
#include "base/memory/scoped_ptr.h"
#include "base/strings/string_number_conversions.h"
#include "base/strings/string_piece.h"
#include "base/strings/string_util.h"
#include "base/strings/sys_string_conversions.h"
#include "base/trace_event/trace_event.h"
#include "ui/gl/gl_bindings.h"
#include "ui/gl/gl_context.h"
#include "ui/gl/gl_implementation.h"

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import <IOKit/IOKitLib.h>

namespace gpu {

namespace {

const UInt32 kVendorIDIntel = 0x8086;
const UInt32 kVendorIDNVidia = 0x10de;
const UInt32 kVendorIDAMD = 0x1002;

// Return 0 if we couldn't find the property.
// The property values we use should not be 0, so it's OK to use 0 as failure.
UInt32 GetEntryProperty(io_registry_entry_t entry, CFStringRef property_name) {
  base::ScopedCFTypeRef<CFDataRef> data_ref(
      static_cast<CFDataRef>(IORegistryEntrySearchCFProperty(
          entry,
          kIOServicePlane,
          property_name,
          kCFAllocatorDefault,
          kIORegistryIterateRecursively | kIORegistryIterateParents)));
  if (!data_ref)
    return 0;

  UInt32 value = 0;
  const UInt32* value_pointer =
      reinterpret_cast<const UInt32*>(CFDataGetBytePtr(data_ref));
  if (value_pointer != NULL)
    value = *value_pointer;
  return value;
}

// Find the info of the current GPU.
GPUInfo::GPUDevice GetActiveGPU() {
  GPUInfo::GPUDevice gpu;
  io_registry_entry_t dsp_port = CGDisplayIOServicePort(kCGDirectMainDisplay);
  gpu.vendor_id = GetEntryProperty(dsp_port, CFSTR("vendor-id"));
  gpu.device_id = GetEntryProperty(dsp_port, CFSTR("device-id"));
  return gpu;
}

// Scan IO registry for PCI video cards.
CollectInfoResult CollectPCIVideoCardInfo(GPUInfo* gpu_info) {
  DCHECK(gpu_info);
  GPUInfo::GPUDevice active_gpu = GetActiveGPU();

  // Collect all GPUs' info.
  // match_dictionary will be consumed by IOServiceGetMatchingServices, no need
  // to release it.
  CFMutableDictionaryRef match_dictionary = IOServiceMatching("IOPCIDevice");
  io_iterator_t entry_iterator;
  std::vector<GPUInfo::GPUDevice> gpu_list;
  if (IOServiceGetMatchingServices(kIOMasterPortDefault,
                                   match_dictionary,
                                   &entry_iterator) == kIOReturnSuccess) {
    io_registry_entry_t entry;
    while ((entry = IOIteratorNext(entry_iterator))) {
      GPUInfo::GPUDevice gpu;
      if (GetEntryProperty(entry, CFSTR("class-code")) != 0x30000) {
        // 0x30000 : DISPLAY_VGA
        continue;
      }
      gpu.vendor_id = GetEntryProperty(entry, CFSTR("vendor-id"));
      gpu.device_id = GetEntryProperty(entry, CFSTR("device-id"));
      if (gpu.vendor_id && gpu.device_id) {
        if (gpu.vendor_id == active_gpu.vendor_id &&
            gpu.device_id == active_gpu.device_id) {
          gpu.active = true;
        }
        gpu_list.push_back(gpu);
      }
    }
    IOObjectRelease(entry_iterator);
  }

  switch (gpu_list.size()) {
    case 0:
      return kCollectInfoNonFatalFailure;
    case 1:
      gpu_info->gpu = gpu_list[0];
      break;
    case 2:
      {
        int integrated = -1;
        int discrete = -1;
        if (gpu_list[0].vendor_id == kVendorIDIntel)
          integrated = 0;
        else if (gpu_list[1].vendor_id == kVendorIDIntel)
          integrated = 1;
        if (integrated >= 0) {
          switch (gpu_list[1 - integrated].vendor_id) {
            case kVendorIDAMD:
              gpu_info->amd_switchable = true;
              discrete = 1 - integrated;
              break;
            case kVendorIDNVidia:
              gpu_info->optimus = true;
              discrete = 1 - integrated;
              break;
            default:
              break;
          }
        }
        if (integrated >= 0 && discrete >= 0) {
          // We always put discrete GPU as primary for blacklisting purpose.
          gpu_info->gpu = gpu_list[discrete];
          gpu_info->secondary_gpus.push_back(gpu_list[integrated]);
          break;
        }
        // If it's not optimus or amd_switchable, we put the current GPU as
        // primary.  Fall through to default.
      }
    default:
      {
        size_t current = gpu_list.size();
        for (size_t i = 0; i < gpu_list.size(); ++i) {
          if (gpu_list[i].active) {
            current = i;
            break;
          }
        }
        if (current == gpu_list.size()) {
          // If we fail to identify the current GPU, select any one as primary.
          current = 0;
        }
        for (size_t i = 0; i < gpu_list.size(); ++i) {
          if (i == current)
            gpu_info->gpu = gpu_list[i];
          else
            gpu_info->secondary_gpus.push_back(gpu_list[i]);
        }
      }
      break;
  }
  if (gpu_info->gpu.vendor_id == 0 || gpu_info->gpu.device_id == 0)
    return kCollectInfoNonFatalFailure;
  return kCollectInfoSuccess;
}

}  // namespace anonymous

CollectInfoResult CollectContextGraphicsInfo(GPUInfo* gpu_info) {
  DCHECK(gpu_info);

  TRACE_EVENT0("gpu", "gpu_info_collector::CollectGraphicsInfo");

  gpu_info->can_lose_context =
      (gfx::GetGLImplementation() == gfx::kGLImplementationEGLGLES2);
  CollectInfoResult result = CollectGraphicsInfoGL(gpu_info);
  gpu_info->context_info_state = result;
  return result;
}

CollectInfoResult CollectGpuID(uint32* vendor_id, uint32* device_id) {
  DCHECK(vendor_id && device_id);

  GPUInfo::GPUDevice gpu = GetActiveGPU();
  *vendor_id = gpu.vendor_id;
  *device_id = gpu.device_id;

  if (*vendor_id != 0 && *device_id != 0)
    return kCollectInfoSuccess;
  return kCollectInfoNonFatalFailure;
}

CollectInfoResult CollectBasicGraphicsInfo(GPUInfo* gpu_info) {
  DCHECK(gpu_info);

  int32 model_major = 0, model_minor = 0;
  base::mac::ParseModelIdentifier(base::mac::GetModelIdentifier(),
                                  &gpu_info->machine_model_name,
                                  &model_major, &model_minor);
  gpu_info->machine_model_version =
      base::IntToString(model_major) + "." + base::IntToString(model_minor);

  CollectInfoResult result = CollectPCIVideoCardInfo(gpu_info);
  gpu_info->basic_info_state = result;
  return result;
}

CollectInfoResult CollectDriverInfoGL(GPUInfo* gpu_info) {
  DCHECK(gpu_info);

  // Extract the OpenGL driver version string from the GL_VERSION string.
  // Mac OpenGL drivers have the driver version
  // at the end of the gl version string preceded by a dash.
  // Use some jiggery-pokery to turn that utf8 string into a std::wstring.
  size_t pos = gpu_info->gl_version.find_last_of('-');
  if (pos == std::string::npos)
    return kCollectInfoNonFatalFailure;
  gpu_info->driver_version = gpu_info->gl_version.substr(pos + 1);
  return kCollectInfoSuccess;
}

void MergeGPUInfo(GPUInfo* basic_gpu_info,
                  const GPUInfo& context_gpu_info) {
  MergeGPUInfoGL(basic_gpu_info, context_gpu_info);
}

}  // namespace gpu
