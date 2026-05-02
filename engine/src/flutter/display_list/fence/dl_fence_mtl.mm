#include <Metal/Metal.h>
#include "flutter/display_list/fence/dl_fence.h"
#include "third_party/skia/include/gpu/ganesh/mtl/GrMtlBackendSemaphore.h"

namespace flutter {
class DlFenceMetal : public DlFence {
 public:
  GrBackendSemaphore CreateGrBackendSemaphore(uint64_t increment) const {
    return GrBackendSemaphores::MakeMtl((__bridge_retained GrMTLHandle)event_, value_ + increment);
  }

  void FreeBackendSemaphore(GrBackendSemaphore& semaphore) const {
    GrMTLHandle handle = GrBackendSemaphores::GetMtlHandle(semaphore);
    CFBridgingRelease(handle);
  }

  DlFenceMetal(id<MTLEvent> event, uint64_t value) : event_(event), value_(value) {}

 private:
  id<MTLEvent> event_;
  uint64_t value_;
};

sk_sp<DlFence> DlFence::MakeFromMetalEvent(DlMetalEvent event, uint64_t value) {
  id<MTLEvent> metalEvent = (__bridge id<MTLEvent>)event;
  return sk_make_sp<DlFenceMetal>(metalEvent, value);
}

}  // namespace flutter
