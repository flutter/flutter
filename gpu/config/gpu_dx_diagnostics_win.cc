// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Functions to enumerate the Dx Diagnostic Tool hierarchy and build up
// a tree of nodes with name / value properties.

#define INITGUID
#include <dxdiag.h>
#include <windows.h>

#include "base/strings/string_number_conversions.h"
#include "base/strings/utf_string_conversions.h"
#include "base/win/scoped_com_initializer.h"
#include "gpu/config/gpu_info_collector.h"

namespace gpu {

namespace {

// Traverses the IDxDiagContainer tree and populates a tree of DxDiagNode
// structures that contains property name / value pairs and subtrees of DirectX
// diagnostic information.
void RecurseDiagnosticTree(DxDiagNode* output,
                           IDxDiagContainer* container,
                           int depth) {
  HRESULT hr;

  VARIANT variant;
  VariantInit(&variant);

  DWORD prop_count;
  hr = container->GetNumberOfProps(&prop_count);
  if (SUCCEEDED(hr)) {
    for (DWORD i = 0; i < prop_count; i++) {
      WCHAR prop_name16[256];
      hr = container->EnumPropNames(i, prop_name16, arraysize(prop_name16));
      if (SUCCEEDED(hr)) {
        std::string prop_name8 = base::WideToUTF8(prop_name16);

        hr = container->GetProp(prop_name16, &variant);
        if (SUCCEEDED(hr)) {
          switch (variant.vt) {
            case VT_UI4:
              output->values[prop_name8] = base::UintToString(variant.ulVal);
              break;
            case VT_I4:
              output->values[prop_name8] = base::IntToString(variant.lVal);
              break;
            case VT_BOOL:
              output->values[prop_name8] = variant.boolVal ? "true" : "false";
              break;
            case VT_BSTR:
              output->values[prop_name8] = base::WideToUTF8(variant.bstrVal);
              break;
            default:
              break;
          }

          // Clear the variant (this is needed to free BSTR memory).
          VariantClear(&variant);
        }
      }
    }
  }

  if (depth > 0) {
    DWORD child_count;
    hr = container->GetNumberOfChildContainers(&child_count);
    if (SUCCEEDED(hr)) {
      for (DWORD i = 0; i < child_count; i++) {
        WCHAR child_name16[256];
        hr = container->EnumChildContainerNames(i,
                                                child_name16,
                                                arraysize(child_name16));
        if (SUCCEEDED(hr)) {
          std::string child_name8 = base::WideToUTF8(child_name16);
          DxDiagNode* output_child = &output->children[child_name8];

          IDxDiagContainer* child_container = NULL;
          hr = container->GetChildContainer(child_name16, &child_container);
          if (SUCCEEDED(hr)) {
            RecurseDiagnosticTree(output_child, child_container, depth - 1);

            child_container->Release();
          }
        }
      }
    }
  }
}
}  // namespace anonymous

bool GetDxDiagnostics(DxDiagNode* output) {
  HRESULT hr;
  bool success = false;
  base::win::ScopedCOMInitializer com_initializer;

  IDxDiagProvider* provider = NULL;
  hr = CoCreateInstance(CLSID_DxDiagProvider,
                         NULL,
                         CLSCTX_INPROC_SERVER,
                         IID_IDxDiagProvider,
                         reinterpret_cast<void**>(&provider));
  if (SUCCEEDED(hr)) {
    DXDIAG_INIT_PARAMS params = { sizeof(params) };
    params.dwDxDiagHeaderVersion = DXDIAG_DX9_SDK_VERSION;
    params.bAllowWHQLChecks = FALSE;
    params.pReserved = NULL;

    hr = provider->Initialize(&params);
    if (SUCCEEDED(hr)) {
      IDxDiagContainer* root = NULL;
      hr = provider->GetRootContainer(&root);
      if (SUCCEEDED(hr)) {
        // Limit to the DisplayDevices subtree. The tree in its entirity is
        // enormous and only this branch contains useful information.
        IDxDiagContainer* display_devices = NULL;
        hr = root->GetChildContainer(L"DxDiag_DisplayDevices",
                                     &display_devices);
        if (SUCCEEDED(hr)) {
          RecurseDiagnosticTree(output, display_devices, 1);
          success = true;
          display_devices->Release();
        }

        root->Release();
      }
    }
    provider->Release();
  }

  return success;
}
}  // namespace gpu
