// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_TESSELLATOR_TESSELLATOR_H_
#define FLUTTER_IMPELLER_TESSELLATOR_TESSELLATOR_H_

#include <functional>
#include <memory>
#include <vector>

#include "impeller/core/formats.h"
#include "impeller/geometry/path.h"
#include "impeller/geometry/point.h"
#include "impeller/geometry/trig.h"

struct TESStesselator;

namespace impeller {

void DestroyTessellator(TESStesselator* tessellator);

using CTessellator =
    std::unique_ptr<TESStesselator, decltype(&DestroyTessellator)>;

//------------------------------------------------------------------------------
/// @brief      A utility that generates triangles of the specified fill type
///             given a polyline. This happens on the CPU.
///
///             This object is not thread safe, and its methods must not be
///             called from multiple threads.
///
class Tessellator {
 private:
  /// Essentially just a vector of Trig objects, but supports storing a
  /// reference to either a cached vector or a locally generated vector.
  /// The constructor will fill the vector with quarter circular samples
  /// for the indicated number of equal divisions if the vector is new.
  class Trigs {
   public:
    explicit Trigs(std::vector<Trig>& trigs, size_t divisions) : trigs_(trigs) {
      init(divisions);
      FML_DCHECK(trigs_.size() == divisions + 1);
    }

    explicit Trigs(size_t divisions)
        : local_storage_(std::make_unique<std::vector<Trig>>()),
          trigs_(*local_storage_) {
      init(divisions);
      FML_DCHECK(trigs_.size() == divisions + 1);
    }

    // Utility forwards of the indicated vector methods.
    auto inline size() const { return trigs_.size(); }
    auto inline begin() const { return trigs_.begin(); }
    auto inline end() const { return trigs_.end(); }

   private:
    // nullptr if a cached vector is used, otherwise the actual storage
    std::unique_ptr<std::vector<Trig>> local_storage_;

    // Whether or not a cached vector or the local storage is used, this
    // this reference will always be valid
    std::vector<Trig>& trigs_;

    // Fill the vector with the indicated number of equal divisions of
    // trigonometric values if it is empty.
    void init(size_t divisions);
  };

 public:
  enum class Result {
    kSuccess,
    kInputError,
    kTessellationError,
  };

  /// @brief  A callback function for a |VertexGenerator| to deliver
  ///         the vertices it computes as |Point| objects.
  using TessellatedVertexProc = std::function<void(const Point& p)>;

  /// @brief  An object which produces a list of vertices as |Point|s that
  ///         tessellate a previously provided shape and delivers the vertices
  ///         through a |TessellatedVertexProc| callback.
  ///
  ///         The object can also provide advance information on how many
  ///         vertices it will generate.
  ///
  /// @see |Tessellator::FilledCircle|
  /// @see |Tessellator::StrokedCircle|
  /// @see |Tessellator::RoundCapLine|
  /// @see |Tessellator::FilledEllipse|
  class VertexGenerator {
   public:
    /// @brief  Returns the |PrimitiveType| that describes the relationship
    ///         among the list of vertices produced by the |GenerateVertices|
    ///         method.
    ///
    ///         Most generators will deliver |kTriangleStrip| triangles
    virtual PrimitiveType GetTriangleType() const = 0;

    /// @brief  Returns the number of vertices that the generator plans to
    ///         produce, if known.
    ///
    ///         This value is advisory only and can be used to reserve space
    ///         where the vertices will be placed, but the count may be an
    ///         estimate.
    ///
    ///         Implementations are encouraged to avoid overestimating
    ///         the count by too large a number and to provide a best
    ///         guess so as to minimize potential buffer reallocations
    ///         as the vertices are delivered.
    virtual size_t GetVertexCount() const = 0;

    /// @brief  Generate the vertices and deliver them in the necessary
    ///         order (as required by the PrimitiveType) to the given
    ///         callback function.
    virtual void GenerateVertices(const TessellatedVertexProc& proc) const = 0;
  };

  /// @brief  The |VertexGenerator| implementation common to all shapes
  ///         that are based on a polygonal representation of an ellipse.
  class EllipticalVertexGenerator : public virtual VertexGenerator {
   public:
    /// |VertexGenerator|
    PrimitiveType GetTriangleType() const override {
      return PrimitiveType::kTriangleStrip;
    }

    /// |VertexGenerator|
    size_t GetVertexCount() const override {
      return trigs_.size() * vertices_per_trig_;
    }

    /// |VertexGenerator|
    void GenerateVertices(const TessellatedVertexProc& proc) const override {
      impl_(trigs_, data_, proc);
    }

   private:
    friend class Tessellator;

    struct Data {
      // Circles and Ellipses only use one of these points.
      // RoundCapLines use both as the endpoints of the unexpanded line.
      // A round rect can specify its interior rectangle by using the
      // 2 points as opposing corners.
      const Point reference_centers[2];
      // Circular shapes have the same value in radii.width and radii.height
      const Size radii;
      // half_width is only used in cases where the generator will be
      // generating 2 different outlines, such as StrokedCircle
      const Scalar half_width;
    };

    typedef void GeneratorProc(const Trigs& trigs,
                               const Data& data,
                               const TessellatedVertexProc& proc);

    GeneratorProc& impl_;
    const Trigs trigs_;
    const Data data_;
    const size_t vertices_per_trig_;

    EllipticalVertexGenerator(GeneratorProc& generator,
                              Trigs&& trigs,
                              PrimitiveType triangle_type,
                              size_t vertices_per_trig,
                              Data&& data);
  };

  Tessellator();

  ~Tessellator();

  /// @brief A callback that returns the results of the tessellation.
  ///
  ///        The index buffer may not be populated, in which case [indices] will
  ///        be nullptr and indices_count will be 0.
  using BuilderCallback = std::function<bool(const float* vertices,
                                             size_t vertices_count,
                                             const uint16_t* indices,
                                             size_t indices_count)>;

  //----------------------------------------------------------------------------
  /// @brief      Generates filled triangles from the path. A callback is
  ///             invoked once for the entire tessellation.
  ///
  /// @param[in]  path  The path to tessellate.
  /// @param[in]  tolerance  The tolerance value for conversion of the path to
  ///                        a polyline. This value is often derived from the
  ///                        Matrix::GetMaxBasisLength of the CTM applied to the
  ///                        path for rendering.
  /// @param[in]  callback  The callback, return false to indicate failure.
  ///
  /// @return The result status of the tessellation.
  ///
  Tessellator::Result Tessellate(const Path& path,
                                 Scalar tolerance,
                                 const BuilderCallback& callback);

  //----------------------------------------------------------------------------
  /// @brief      Given a convex path, create a triangle fan structure.
  ///
  /// @param[in]  path  The path to tessellate.
  /// @param[in]  tolerance  The tolerance value for conversion of the path to
  ///                        a polyline. This value is often derived from the
  ///                        Matrix::GetMaxBasisLength of the CTM applied to the
  ///                        path for rendering.
  ///
  /// @return A point vector containing the vertices in triangle strip format.
  ///
  std::vector<Point> TessellateConvex(const Path& path, Scalar tolerance);

  //----------------------------------------------------------------------------
  /// @brief      Create a temporary polyline. Only one per-process can exist at
  ///             a time.
  ///
  ///             The tessellator itself is not a thread safe class and should
  ///             only be used from the raster thread.
  Path::Polyline CreateTempPolyline(const Path& path, Scalar tolerance);

  /// @brief   The pixel tolerance used by the algorighm to determine how
  ///          many divisions to create for a circle.
  ///
  ///          No point on the polygon of vertices should deviate from the
  ///          true circle by more than this tolerance.
  static constexpr Scalar kCircleTolerance = 0.1f;

  /// @brief   Create a |VertexGenerator| that can produce vertices for
  ///          a filled circle of the given radius around the given center
  ///          with enough polygon sub-divisions to provide reasonable
  ///          fidelity when viewed under the given view transform.
  ///
  ///          Note that the view transform is only used to choose the
  ///          number of sample points to use per quarter circle and the
  ///          returned points are not transformed by it, instead they are
  ///          relative to the coordinate space of the center point.
  EllipticalVertexGenerator FilledCircle(const Matrix& view_transform,
                                         const Point& center,
                                         Scalar radius);

  /// @brief   Create a |VertexGenerator| that can produce vertices for
  ///          a stroked circle of the given radius and half_width around
  ///          the given shared center with enough polygon sub-divisions
  ///          to provide reasonable fidelity when viewed under the given
  ///          view transform. The outer edge of the stroked circle is
  ///          generated at (radius + half_width) and the inner edge is
  ///          generated at (radius - half_width).
  ///
  ///          Note that the view transform is only used to choose the
  ///          number of sample points to use per quarter circle and the
  ///          returned points are not transformed by it, instead they are
  ///          relative to the coordinate space of the center point.
  EllipticalVertexGenerator StrokedCircle(const Matrix& view_transform,
                                          const Point& center,
                                          Scalar radius,
                                          Scalar half_width);

  /// @brief   Create a |VertexGenerator| that can produce vertices for
  ///          a line with round end caps of the given radius with enough
  ///          polygon sub-divisions to provide reasonable fidelity when
  ///          viewed under the given view transform.
  ///
  ///          Note that the view transform is only used to choose the
  ///          number of sample points to use per quarter circle and the
  ///          returned points are not transformed by it, instead they are
  ///          relative to the coordinate space of the two points.
  EllipticalVertexGenerator RoundCapLine(const Matrix& view_transform,
                                         const Point& p0,
                                         const Point& p1,
                                         Scalar radius);

  /// @brief   Create a |VertexGenerator| that can produce vertices for
  ///          a filled ellipse inscribed within the given bounds with
  ///          enough polygon sub-divisions to provide reasonable
  ///          fidelity when viewed under the given view transform.
  ///
  ///          Note that the view transform is only used to choose the
  ///          number of sample points to use per quarter circle and the
  ///          returned points are not transformed by it, instead they are
  ///          relative to the coordinate space of the bounds.
  EllipticalVertexGenerator FilledEllipse(const Matrix& view_transform,
                                          const Rect& bounds);

  /// @brief   Create a |VertexGenerator| that can produce vertices for
  ///          a filled round rect within the given bounds and corner radii
  ///          with enough polygon sub-divisions to provide reasonable
  ///          fidelity when viewed under the given view transform.
  ///
  ///          Note that the view transform is only used to choose the
  ///          number of sample points to use per quarter circle and the
  ///          returned points are not transformed by it, instead they are
  ///          relative to the coordinate space of the bounds.
  EllipticalVertexGenerator FilledRoundRect(const Matrix& view_transform,
                                            const Rect& bounds,
                                            const Size& radii);

 private:
  /// Used for polyline generation.
  std::unique_ptr<std::vector<Point>> point_buffer_;
  CTessellator c_tessellator_;

  // Data for variouos Circle/EllipseGenerator classes, cached per
  // Tessellator instance which is usually the foreground life of an app
  // if not longer.
  static constexpr size_t kCachedTrigCount = 300;
  std::vector<Trig> precomputed_trigs_[kCachedTrigCount];

  Trigs GetTrigsForDivisions(size_t divisions);

  static void GenerateFilledCircle(const Trigs& trigs,
                                   const EllipticalVertexGenerator::Data& data,
                                   const TessellatedVertexProc& proc);

  static void GenerateStrokedCircle(const Trigs& trigs,
                                    const EllipticalVertexGenerator::Data& data,
                                    const TessellatedVertexProc& proc);

  static void GenerateRoundCapLine(const Trigs& trigs,
                                   const EllipticalVertexGenerator::Data& data,
                                   const TessellatedVertexProc& proc);

  static void GenerateFilledEllipse(const Trigs& trigs,
                                    const EllipticalVertexGenerator::Data& data,
                                    const TessellatedVertexProc& proc);

  static void GenerateFilledRoundRect(
      const Trigs& trigs,
      const EllipticalVertexGenerator::Data& data,
      const TessellatedVertexProc& proc);

  Tessellator(const Tessellator&) = delete;

  Tessellator& operator=(const Tessellator&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_TESSELLATOR_TESSELLATOR_H_
