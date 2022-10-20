// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/metal/gpu_tracer_mtl.h"
#include <fml/logging.h>

namespace impeller {

GPUTracerMTL::GPUTracerMTL(id<MTLDevice> device) : device_(device) {}

GPUTracerMTL::~GPUTracerMTL() = default;

bool GPUTracerMTL::StartCapturingFrame(GPUTracerConfiguration configuration) {
  if (!device_) {
    return false;
  }

  MTLCaptureManager* captureManager = [MTLCaptureManager sharedCaptureManager];
  if (captureManager.isCapturing) {
    return false;
  }

  if (@available(iOS 13.0, macOS 10.15, *)) {
    MTLCaptureDescriptor* desc = [[MTLCaptureDescriptor alloc] init];
    desc.captureObject = device_;

    MTLCaptureDestination targetDestination =
        configuration.mtl_frame_capture_save_trace_as_document
            ? MTLCaptureDestinationGPUTraceDocument
            : MTLCaptureDestinationDeveloperTools;
    if (![captureManager supportsDestination:targetDestination]) {
      return false;
    }
    desc.destination = targetDestination;

    if (configuration.mtl_frame_capture_save_trace_as_document) {
      if (!CreateGPUTraceSavedDictionaryIfNeeded()) {
        return false;
      }
      NSURL* outputURL = GetUniqueGPUTraceSavedURL();
      desc.outputURL = outputURL;
    }
    return [captureManager startCaptureWithDescriptor:desc error:nil];
  }

  [captureManager startCaptureWithDevice:device_];
  return captureManager.isCapturing;
}

bool GPUTracerMTL::StopCapturingFrame() {
  if (!device_) {
    return false;
  }

  MTLCaptureManager* captureManager = [MTLCaptureManager sharedCaptureManager];
  if (!captureManager.isCapturing) {
    return false;
  }

  [captureManager stopCapture];
  return !captureManager.isCapturing;
}

NSURL* GPUTracerMTL::GetUniqueGPUTraceSavedURL() const {
  NSURL* savedDictionaryURL = GetGPUTraceSavedDictionaryURL();
  NSString* uniqueID = [NSUUID UUID].UUIDString;
  return [[savedDictionaryURL URLByAppendingPathComponent:uniqueID]
      URLByAppendingPathExtension:@"gputrace"];
}

bool GPUTracerMTL::CreateGPUTraceSavedDictionaryIfNeeded() const {
  NSFileManager* fileManager = [NSFileManager defaultManager];
  NSURL* gpuTraceSavedDictionaryURL = GetGPUTraceSavedDictionaryURL();
  if ([fileManager fileExistsAtPath:gpuTraceSavedDictionaryURL.path]) {
    return true;
  }

  NSError* error = nil;
  [fileManager createDirectoryAtURL:gpuTraceSavedDictionaryURL
        withIntermediateDirectories:NO
                         attributes:nil
                              error:&error];
  if (error != nil) {
    FML_LOG(ERROR) << "Metal frame capture "
                      "CreateGPUTraceSavedDictionaryIfNeeded failed.";
    return false;
  }
  return true;
}

NSURL* GPUTracerMTL::GetGPUTraceSavedDictionaryURL() const {
  NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                       NSUserDomainMask, YES);
  NSString* docPath = [paths objectAtIndex:0];
  NSURL* docURL = [NSURL fileURLWithPath:docPath];
  NSURL* gpuTraceDictionaryURL =
      [docURL URLByAppendingPathComponent:@"MetalCaptureGPUTrace"];
  return gpuTraceDictionaryURL;
}

}  // namespace impeller
