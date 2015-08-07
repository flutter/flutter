// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "tracing_controller.h"
#include <string>
#include "base/macros.h"
#include "base/trace_event/trace_config.h"
#include "base/trace_event/trace_event.h"

@interface TracingController ()
@property(nonatomic, retain) NSFileHandle* currentFileHandle;
@end

namespace sky {
namespace shell {

const char kStart[] = "{\"traceEvents\":[";
const char kEnd[] = "]}";

static void Write(const std::string& data) {
  NSFileHandle* handle = [TracingController sharedController].currentFileHandle;
  [handle writeData:[NSData dataWithBytesNoCopy:(void*)data.data()
                                         length:data.size()
                                   freeWhenDone:false]];
}

static void HandleChunk(const scoped_refptr<base::RefCountedString>& chunk,
                        bool has_more_events) {
  Write(chunk->data());

  if (has_more_events) {
    Write(",");
  } else {
    Write(kEnd);
    [TracingController sharedController].currentFileHandle = nil;
  }
}

}  // namespace shell
}  // namespace sky

@implementation TracingController

@synthesize currentFileHandle = _currentFileHandle;

+ (instancetype)sharedController {
  static TracingController* controller = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    controller = [[TracingController alloc] init];
  });
  return controller;
}

- (void)startTracing {
  // Start Tracing
  NSLog(@"Staring Trace");

  base::trace_event::TraceLog::GetInstance()->SetEnabled(
      base::trace_event::TraceConfig("*", base::trace_event::RECORD_UNTIL_FULL),
      base::trace_event::TraceLog::RECORDING_MODE);
}

- (void)stopTracing {
  // Stop Tracing
  NSLog(@"Stopping Trace");
  base::trace_event::TraceLog::GetInstance()->SetDisabled();

  // Save Trace File
  NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                       NSUserDomainMask, YES);
  if (paths.count == 0) {
    NSLog(@"Error: Could not find documents directory to write the trace file "
          @"to");
    return;
  }

  // Prepare a file path that looks sane in the documents directory
  NSURL* pathURL = [NSURL URLWithString:paths[0]];
  NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
  [formatter setDateFormat:@"hh_mm_s"];
  NSString* dateString =
      [NSString stringWithFormat:@"Trace_%@.json",
                                 [formatter stringFromDate:[NSDate date]]];
  [formatter release];
  NSURL* fileURL = [NSURL URLWithString:dateString relativeToURL:pathURL];
  NSError* error = nil;

  // Create the file in the documents directory
  BOOL created =
      [[NSFileManager defaultManager] createFileAtPath:fileURL.absoluteString
                                              contents:nil
                                            attributes:nil];
  if (!created) {
    NSLog(@"Error: Could not create file for writing trace file to");
    return;
  }

  // Fetch a write handle to the created file
  NSFileHandle* handle =
      [NSFileHandle fileHandleForWritingToURL:fileURL error:&error];
  if (error != nil) {
    NSLog(@"Error: Could not write trace file to documents directory: %@",
          error.localizedDescription);
    return;
  }

  self.currentFileHandle = handle;
  sky::shell::Write(sky::shell::kStart);
  auto log = base::trace_event::TraceLog::GetInstance();
  log->Flush(base::Bind(&sky::shell::HandleChunk));
}

- (void)dealloc {
  [_currentFileHandle release];
  [super dealloc];
}

@end
