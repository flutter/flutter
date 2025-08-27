// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterDisplayLink.h"

#include <algorithm>
#include <mutex>
#include <optional>
#include <thread>
#include <vector>

#include "flutter/fml/logging.h"
#import "flutter/shell/platform/darwin/macos/InternalFlutterSwift/InternalFlutterSwift.h"

@class _FlutterDisplayLinkView;

@interface _FlutterDisplayLink : FlutterDisplayLink {
  _FlutterDisplayLinkView* _view;
  std::optional<CGDirectDisplayID> _display_id;
  BOOL _paused;
}

- (void)didFireWithTimestamp:(CFTimeInterval)timestamp
             targetTimestamp:(CFTimeInterval)targetTimestamp;

@end

namespace {
class DisplayLinkManager {
 public:
  static DisplayLinkManager& Instance() {
    static DisplayLinkManager instance;
    return instance;
  }

  void UnregisterDisplayLink(_FlutterDisplayLink* display_link);
  void RegisterDisplayLink(_FlutterDisplayLink* display_link, CGDirectDisplayID display_id);
  void PausedDidChange(_FlutterDisplayLink* display_link);
  CFTimeInterval GetNominalOutputPeriod(CGDirectDisplayID display_id);

 private:
  void OnDisplayLink(CVDisplayLinkRef display_link,
                     const CVTimeStamp* in_now,
                     const CVTimeStamp* in_output_time,
                     CVOptionFlags flags_in,
                     CVOptionFlags* flags_out);

  struct ScreenEntry {
    CGDirectDisplayID display_id;
    std::vector<_FlutterDisplayLink*> clients;
    CVDisplayLinkRef display_link;

    bool ShouldBeRunning() {
      return std::any_of(clients.begin(), clients.end(),
                         [](FlutterDisplayLink* link) { return !link.paused; });
    }
  };
  std::vector<ScreenEntry> entries_;
};

void RunOrStopDisplayLink(CVDisplayLinkRef display_link, bool should_be_running) {
  bool is_running = CVDisplayLinkIsRunning(display_link);
  if (should_be_running && !is_running) {
    CVDisplayLinkStart(display_link);
  } else if (!should_be_running && is_running) {
    CVDisplayLinkStop(display_link);
  }
}

void DisplayLinkManager::UnregisterDisplayLink(_FlutterDisplayLink* display_link) {
  FML_DCHECK(NSThread.isMainThread);
  for (auto entry = entries_.begin(); entry != entries_.end(); ++entry) {
    auto it = std::find(entry->clients.begin(), entry->clients.end(), display_link);
    if (it != entry->clients.end()) {
      entry->clients.erase(it);
      if (entry->clients.empty()) {
        // Erasing the entry - take the display link instance and stop / release it
        // outside of the mutex.
        CVDisplayLinkStop(entry->display_link);
        CVDisplayLinkRelease(entry->display_link);
        entries_.erase(entry);
      } else {
        // Update the display link state outside of the mutex.
        RunOrStopDisplayLink(entry->display_link, entry->ShouldBeRunning());
      }
      return;
    }
  }
}

void DisplayLinkManager::RegisterDisplayLink(_FlutterDisplayLink* display_link,
                                             CGDirectDisplayID display_id) {
  FML_DCHECK(NSThread.isMainThread);
  for (ScreenEntry& entry : entries_) {
    if (entry.display_id == display_id) {
      entry.clients.push_back(display_link);
      RunOrStopDisplayLink(entry.display_link, entry.ShouldBeRunning());
      return;
    }
  }

  ScreenEntry entry;
  entry.display_id = display_id;
  entry.clients.push_back(display_link);
  CVDisplayLinkCreateWithCGDisplay(display_id, &entry.display_link);

  CVDisplayLinkSetOutputHandler(
      entry.display_link,
      ^(CVDisplayLinkRef display_link, const CVTimeStamp* in_now, const CVTimeStamp* in_output_time,
        CVOptionFlags flags_in, CVOptionFlags* flags_out) {
        OnDisplayLink(display_link, in_now, in_output_time, flags_in, flags_out);
        return 0;
      });

  // This is a new display link so it is safe to start it with mutex held.
  RunOrStopDisplayLink(entry.display_link, entry.ShouldBeRunning());
  entries_.push_back(entry);
}

void DisplayLinkManager::PausedDidChange(_FlutterDisplayLink* display_link) {
  for (ScreenEntry& entry : entries_) {
    auto it = std::find(entry.clients.begin(), entry.clients.end(), display_link);
    if (it != entry.clients.end()) {
      RunOrStopDisplayLink(entry.display_link, entry.ShouldBeRunning());
      return;
    }
  }
}

CFTimeInterval DisplayLinkManager::GetNominalOutputPeriod(CGDirectDisplayID display_id) {
  for (ScreenEntry& entry : entries_) {
    if (entry.display_id == display_id) {
      CVTime latency = CVDisplayLinkGetNominalOutputVideoRefreshPeriod(entry.display_link);
      return (CFTimeInterval)latency.timeValue / (CFTimeInterval)latency.timeScale;
    }
  }
  return 0;
}

void DisplayLinkManager::OnDisplayLink(CVDisplayLinkRef display_link,
                                       const CVTimeStamp* in_now,
                                       const CVTimeStamp* in_output_time,
                                       CVOptionFlags flags_in,
                                       CVOptionFlags* flags_out) {
  CVTimeStamp inNow = *in_now;
  CVTimeStamp inOutputTime = *in_output_time;
  [FlutterRunLoop.mainRunLoop performBlock:^{
    std::vector<_FlutterDisplayLink*> clients;
    for (ScreenEntry& entry : entries_) {
      if (entry.display_link == display_link) {
        clients = entry.clients;
        break;
      }
    }

    CFTimeInterval timestamp = (CFTimeInterval)inNow.hostTime / CVGetHostClockFrequency();
    CFTimeInterval target_timestamp =
        (CFTimeInterval)inOutputTime.hostTime / CVGetHostClockFrequency();

    for (_FlutterDisplayLink* client : clients) {
      [client didFireWithTimestamp:timestamp targetTimestamp:target_timestamp];
    }
  }];
}
}  // namespace

@interface _FlutterDisplayLinkView : NSView {
}

@end

static NSString* const kFlutterDisplayLinkViewDidMoveToWindow =
    @"FlutterDisplayLinkViewDidMoveToWindow";

@implementation _FlutterDisplayLinkView

- (void)viewDidMoveToWindow {
  [super viewDidMoveToWindow];
  [[NSNotificationCenter defaultCenter] postNotificationName:kFlutterDisplayLinkViewDidMoveToWindow
                                                      object:self];
}

@end

@implementation _FlutterDisplayLink

@synthesize delegate = _delegate;

- (instancetype)initWithView:(NSView*)view {
  FML_DCHECK(NSThread.isMainThread);
  if (self = [super init]) {
    self->_view = [[_FlutterDisplayLinkView alloc] initWithFrame:CGRectZero];
    [view addSubview:self->_view];
    _paused = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(viewDidChangeWindow:)
                                                 name:kFlutterDisplayLinkViewDidMoveToWindow
                                               object:self->_view];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(windowDidChangeScreen:)
                                                 name:NSWindowDidChangeScreenNotification
                                               object:nil];
    [self updateScreen];
  }
  return self;
}

- (void)invalidate {
  FML_DCHECK(NSThread.isMainThread);
  // Unregister observer before removing the view to ensure
  // that the viewDidChangeWindow notification is not received
  // while in @synchronized block.
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [_view removeFromSuperview];
  _view = nil;
  _delegate = nil;
  DisplayLinkManager::Instance().UnregisterDisplayLink(self);
}

- (void)updateScreen {
  FML_DCHECK(NSThread.isMainThread);
  DisplayLinkManager::Instance().UnregisterDisplayLink(self);
  std::optional<CGDirectDisplayID> displayId;
  NSScreen* screen = _view.window.screen;
  if (screen != nil) {
    // https://developer.apple.com/documentation/appkit/nsscreen/1388360-devicedescription?language=objc
    _display_id = (CGDirectDisplayID)[
        [[screen deviceDescription] objectForKey:@"NSScreenNumber"] unsignedIntValue];
  } else {
    _display_id = std::nullopt;
  }
  displayId = _display_id;

  if (displayId.has_value()) {
    DisplayLinkManager::Instance().RegisterDisplayLink(self, *displayId);
  }
}

- (void)viewDidChangeWindow:(NSNotification*)notification {
  FML_DCHECK(NSThread.isMainThread);
  NSView* view = notification.object;
  if (_view == view) {
    [self updateScreen];
  }
}

- (void)windowDidChangeScreen:(NSNotification*)notification {
  FML_DCHECK(NSThread.isMainThread);
  NSWindow* window = notification.object;
  if (_view.window == window) {
    [self updateScreen];
  }
}

- (void)didFireWithTimestamp:(CFTimeInterval)timestamp
             targetTimestamp:(CFTimeInterval)targetTimestamp {
  FML_DCHECK(NSThread.isMainThread);
  if (!_paused) {
    id<FlutterDisplayLinkDelegate> delegate = _delegate;
    [delegate onDisplayLink:timestamp targetTimestamp:targetTimestamp];
  }
}

- (BOOL)paused {
  FML_DCHECK(NSThread.isMainThread);
  return _paused;
}

- (void)setPaused:(BOOL)paused {
  FML_DCHECK(NSThread.isMainThread);
  if (_paused == paused) {
    return;
  }
  _paused = paused;
  DisplayLinkManager::Instance().PausedDidChange(self);
}

- (CFTimeInterval)nominalOutputRefreshPeriod {
  FML_DCHECK(NSThread.isMainThread);
  CGDirectDisplayID display_id;
  if (_display_id.has_value()) {
    display_id = *_display_id;
  } else {
    return 0;
  }
  return DisplayLinkManager::Instance().GetNominalOutputPeriod(display_id);
}

@end

@implementation FlutterDisplayLink
+ (instancetype)displayLinkWithView:(NSView*)view {
  return [[_FlutterDisplayLink alloc] initWithView:view];
}

- (void)invalidate {
  [self doesNotRecognizeSelector:_cmd];
}

@end
