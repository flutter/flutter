// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/ios_external_texture_metal.h"

namespace flutter {

IOSExternalTextureMetal::IOSExternalTextureMetal(
    fml::scoped_nsobject<FlutterDarwinExternalTextureMetal> darwin_external_texture_metal)
    : Texture([darwin_external_texture_metal textureID]),
      darwin_external_texture_metal_(darwin_external_texture_metal) {}

IOSExternalTextureMetal::~IOSExternalTextureMetal() = default;

void IOSExternalTextureMetal::Paint(SkCanvas& canvas,
                                    const SkRect& bounds,
                                    bool freeze,
                                    GrDirectContext* context,
                                    const SkSamplingOptions& sampling,
                                    const SkPaint* paint) {
  [darwin_external_texture_metal_ canvas:canvas
                                  bounds:bounds
                                  freeze:freeze
                               grContext:context
                                sampling:sampling
                                   paint:paint];
}

void IOSExternalTextureMetal::OnGrContextCreated() {
  [darwin_external_texture_metal_ onGrContextCreated];
}

void IOSExternalTextureMetal::OnGrContextDestroyed() {
  [darwin_external_texture_metal_ onGrContextDestroyed];
}

void IOSExternalTextureMetal::MarkNewFrameAvailable() {
  [darwin_external_texture_metal_ markNewFrameAvailable];
}

void IOSExternalTextureMetal::OnTextureUnregistered() {
  [darwin_external_texture_metal_ onTextureUnregistered];
}

}  // namespace flutter
