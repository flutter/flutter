#include "flutter/flow/paint_region.h"

namespace flutter {

#ifdef FLUTTER_ENABLE_DIFF_CONTEXT

SkRect PaintRegion::ComputeBounds() const {
  SkRect res = SkRect::MakeEmpty();
  for (const auto& r : *this) {
    res.join(r);
  }
  return res;
}

#endif  // FLUTTER_ENABLE_DIFF_CONTEXT

}  // namespace flutter
