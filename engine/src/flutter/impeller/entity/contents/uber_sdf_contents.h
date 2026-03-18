#ifndef FLUTTER_IMPELLER_ENTITY_CONTENTS_UBER_SDF_CONTENTS_H_
#define FLUTTER_IMPELLER_ENTITY_CONTENTS_UBER_SDF_CONTENTS_H_

#include <memory>

#include "flutter/impeller/entity/contents/color_source_contents.h"
#include "flutter/impeller/entity/contents/contents.h"
#include "impeller/geometry/color.h"
#include "impeller/geometry/rect.h"

namespace impeller {

class UberSDFContents : public ColorSourceContents {
 public:
  enum class Type {
    kCircle,
    kRect,
  };

  static std::unique_ptr<UberSDFContents> Make(Type type,
                                               Rect rect,
                                               Color color,
                                               Scalar stroke_width,
                                               bool stroked);

  UberSDFContents(Type type,
                  Rect rect,
                  Color color,
                  Scalar stroke_width,
                  bool stroked);

  ~UberSDFContents() override;

  bool Render(const ContentContext& renderer,
              const Entity& entity,
              RenderPass& pass) const override;

  std::optional<Rect> GetCoverage(const Entity& entity) const override;

 private:
  Type type_ = Type::kCircle;
  Rect rect_;
  Color color_;
  Scalar stroke_width_ = 0.0f;
  bool stroked_ = false;

  UberSDFContents(const UberSDFContents&) = delete;

  UberSDFContents& operator=(const UberSDFContents&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_CONTENTS_UBER_SDF_CONTENTS_H_
