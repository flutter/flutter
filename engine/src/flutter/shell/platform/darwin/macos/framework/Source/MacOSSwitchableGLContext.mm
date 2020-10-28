#import "flutter/shell/platform/darwin/macos/framework/Source/MacOSSwitchableGLContext.h"

MacOSSwitchableGLContext::MacOSSwitchableGLContext(NSOpenGLContext* context) : context_(context) {}

bool MacOSSwitchableGLContext::SetCurrent() {
  FML_DCHECK_CREATION_THREAD_IS_CURRENT(checker);
  previous_context_ = [NSOpenGLContext currentContext];
  [context_ makeCurrentContext];
  return true;
}

bool MacOSSwitchableGLContext::RemoveCurrent() {
  if (previous_context_) {
    [previous_context_ makeCurrentContext];
  } else {
    [NSOpenGLContext clearCurrentContext];
  }
  return true;
}
