#include "flutter/flow/gl_context_switch.h"
#include "flutter/fml/memory/thread_checker.h"

#import <Cocoa/Cocoa.h>

class MacOSSwitchableGLContext final : public flutter::SwitchableGLContext {
 public:
  explicit MacOSSwitchableGLContext(NSOpenGLContext* context);

  bool SetCurrent() override;

  bool RemoveCurrent() override;

 private:
  NSOpenGLContext* context_;
  NSOpenGLContext* previous_context_;

  FML_DECLARE_THREAD_CHECKER(checker);

  FML_DISALLOW_COPY_AND_ASSIGN(MacOSSwitchableGLContext);
};
