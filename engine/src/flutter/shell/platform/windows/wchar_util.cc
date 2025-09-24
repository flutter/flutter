// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/wchar_util.h"

#include <dwmapi.h>

namespace flutter {

std::string WCharBufferToString(const wchar_t* wstr) {
  if (!wstr) {
    return "";
  }

  int buffer_size = WideCharToMultiByte(CP_UTF8,  //
                                        0,        //
                                        wstr,     //
                                        -1,       //
                                        nullptr,  //
                                        0,        //
                                        nullptr,  //
                                        nullptr   //
  );
  if (buffer_size <= 0) {
    return "";
  }

  std::string result(buffer_size - 1, 0);
  WideCharToMultiByte(CP_UTF8,        //
                      0,              //
                      wstr,           //
                      -1,             //
                      result.data(),  //
                      buffer_size,    //
                      nullptr,        //
                      nullptr         //
  );
  return result;
}

}  // namespace flutter
