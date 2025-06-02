// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_TESSELLATOR_TESSELLATOR_H_
#define FLUTTER_IMPELLER_TESSELLATOR_TESSELLATOR_H_

#include <functional>
#include <memory>
#include <vector>

#include "impeller/core/formats.h"
#include "impeller/core/host_buffer.h"
#include "impeller/core/vertex_buffer.h"
#include "impeller/geometry/path_source.h"
#include "impeller/geometry/point.h"
#include "impeller/geometry/stroke_parameters.h"
#include "impeller/geometry/trig.h"

namespace impeller {

/// The size of the point arena buffer stored on the tessellator.
[[maybe_unused]]
static constexpr size_t kPointArenaSize = 4096u;

//------------------------------------------------------------------------------
/// @brief      A utility that generates triangles of the specified fill type
///             given a polyline. This happens on the CPU.
///
///             Also contains functionality for optimized generation of circles
///             and ellipses.
///
///             This object is not thread safe, and its methods must not be
///             called from multiple threads.
///
class Tessellator {
 public:
  /// Essentially just a vector of Trig objects, but supports storing a
  /// reference to either a cached vector or a locally generated vector.
  /// The constructor will fill the vector with quarter circular samples
  /// for the indicated number of equal divisions if the vector is new.
  ///
  /// A given instance of Trigs will always contain at least 2 entries
  /// which is the minimum number of samples to traverse a quarter circle
  /// in a single step. The first sample will always be (0, 1) and the last
  /// sample will always be (1, 0).
  class Trigs {
   public:
    explicit Trigs(Scalar pixel_radius);

    // Utility forwards of the indicated vector methods.
    size_t inline size() const { return trigs_.size(); }
    std::vector<Trig>::iterator inline begin() const { return trigs_.begin(); }
    std::vector<Trig>::iterator inline end() const { return trigs_.end(); }
    const inline Trig& operator[](size_t index) const { return trigs_[index]; }

   private:
    friend class Tessellator;

    explicit Trigs(std::vector<Trig>& trigs, size_t divisions) : trigs_(trigs) {
      FML_DCHECK(divisions >= 1);
      init(divisions);
      FML_DCHECK(trigs_.size() == divisions + 1);
    }

    explicit Trigs(size_t divisions)
        : local_storage_(std::make_unique<std::vector<Trig>>()),
          trigs_(*local_storage_) {
      FML_DCHECK(divisions >= 1);
      init(divisions);
      FML_DCHECK(trigs_.size() == divisions + 1);
    }

    // nullptr if a cached vector is used, otherwise the actual storage
    std::unique_ptr<std::vector<Trig>> local_storage_;

    // Whether or not a cached vector or the local storage is used, this
    // this reference will always be valid
    std::vector<Trig>& trigs_;

    // Fill the vector with the indicated number of equal divisions of
    // trigonometric values if it is empty.
    void init(size_t divisions);
  };

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

  /// A structure to describe the iteration through a set of angle vectors
  /// in a |Trigs| structure to render the points along an arc. The start
  /// and end vectors and each iteration's axis vector are all unit vectors
  /// that point in the direction of the point on the circle to be emitted.
  ///
  /// Each vector should be rendered by multiplying it by the radius of the
  /// circle, or in the case of a stroked arc, by the inner and outer radii
  /// of the sides of the stroke.
  ///
  /// - The start vector will always be rendered first.
  /// - Then each quadrant will be iterated by composing the trigs vectors
  ///   with the given axis vector, iterating from the start index (inclusive)
  ///   to the end index (exclusive) of the vector of |Trig| values.
  /// - Finally the end vector will be rendered.
  /// For example:
  ///   Insert(arc_iteration.start * radius);
  ///   for (size_t i = 0u, i < arc_iteration.iteration_count; i++) {
  ///     Quadrant quadrant = arc_iteration.quadrants[i];
  ///     for (j = quadrant.start_index; j < quadrant.end_index; j++) {
  ///       Insert(quadrant.axis * trigs[j] * radius);
  ///     }
  ///   }
  ///   Insert(arc_iteration.end * radius);
  ///
  /// The rendering routine may adjust the manner/order in which those vertices
  /// are inserted into the vertex buffer to optimally match the vertex triangle
  /// mode it plans to use, but the description above represents the basic
  /// technique to compute the points along the actual curve.
  struct ArcIteration {
    // The axis to multiply by each |Trig| value and the half-open [start, end)
    // range of the |Trig| vector over which to compute.
    struct Quadrant {
      impeller::Vector2 axis;
      size_t start_index = 0u;
      size_t end_index = 0u;

      size_t GetPointCount() const {
        FML_DCHECK(start_index < end_index);
        return end_index - start_index;
      }
    };

    // The true begin and end angles of the arc, expressed as unit direction
    // vectors.
    impeller::Vector2 start;
    impeller::Vector2 end;

    // The variable number of quadrants that have to be iterated and
    // cross-referenced with values in a |Trigs| object.
    size_t quadrant_count = 0u;
    // We can have at most 5 |Quadrant| entries when an arc starts and ends in
    // the same circle quadrant with the start point later in the quadrant
    // than the end point.
    //
    // Worst case:
    // - First iteration goes from the start angle to the end of that quadrant.
    // - Then 3 full iterations for the 3 other full quarter circles.
    // - Then a last iteration that goes from the start of that quadrant to the
    //   end angle.
    //
    // We can also have 0 quadrants for arcs that are smaller than the
    // step size of the pixel-radius |Trigs| vector.
    Quadrant quadrants[5];

    size_t GetPointCount() const {
      size_t count = 2;
      for (size_t i = 0; i < quadrant_count; i++) {
        count += quadrants[i].GetPointCount();
      }
      return count;
    }
  };

  /// @brief  The |VertexGenerator| implementation common to all shapes
  ///         that are based on a polygonal representation of an ellipse.
  class ArcVertexGenerator : public virtual VertexGenerator {
   public:
    /// |VertexGenerator|
    PrimitiveType GetTriangleType() const override;

    /// |VertexGenerator|
    size_t GetVertexCount() const override;

    /// |VertexGenerator|
    void GenerateVertices(const TessellatedVertexProc& proc) const override;

   private:
    friend class Tessellator;

    const ArcIteration iteration_;
    const Trigs trigs_;
    const Rect oval_bounds_;
    const bool use_center_;
    const Scalar half_width_;
    const Cap cap_;
    const bool supports_triangle_fans_;

    ArcVertexGenerator(const ArcIteration& iteration,
                       Trigs&& trigs,
                       const Rect& oval_bounds,
                       bool use_center,
                       bool supports_triangle_fans);

    ArcVertexGenerator(const ArcIteration& iteration,
                       Trigs&& trigs,
                       const Rect& oval_bounds,
                       Scalar half_width,
                       Cap cap);
  };

  Tessellator();

  virtual ~Tessellator();

  //----------------------------------------------------------------------------
  /// @brief      Given a convex path, create a triangle fan structure.
  ///
  /// @param[in]  path  The path to tessellate.
  /// @param[in]  host_buffer  The host buffer for allocation of vertices/index
  ///                          data.
  /// @param[in]  tolerance  The tolerance value for conversion of the path to
  ///                        a polyline. This value is often derived from the
  ///                        Matrix::GetMaxBasisLengthXY of the CTM applied to
  ///                        the path for rendering.
  ///
  /// @return A vertex buffer containing all data from the provided curve.
  VertexBuffer TessellateConvex(const PathSource& path,
                                HostBuffer& host_buffer,
                                Scalar tolerance,
                                bool supports_primitive_restart = false,
                                bool supports_triangle_fan = false);

  /// Visible for testing.
  ///
  /// This method only exists for the ease of benchmarking without using the
  /// real allocator needed by the [host_buffer].
  static void TessellateConvexInternal(const PathSource& path,
                                       std::vector<Point>& point_buffer,
                                       std::vector<uint16_t>& index_buffer,
                                       Scalar tolerance);

  //----------------------------------------------------------------------------
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
  ///          a stroked arc inscribed within the given oval_bounds with
  ///          the given stroke half_width with enough polygon sub-divisions
  ///          to provide reasonable fidelity when viewed under the given
  ///          view transform. The outer edge of the stroked arc is
  ///          generated at (radius + half_width) and the inner edge is
  ///          generated at (radius - half_width).
  ///
  ///          Note that the view transform is only used to choose the
  ///          number of sample points to use per quarter circle and the
  ///          returned points are not transformed by it, instead they are
  ///          relative to the coordinate space of the oval bounds.
  ArcVertexGenerator FilledArc(const Matrix& view_transform,
                               const Rect& oval_bounds,
                               Degrees start,
                               Degrees sweep,
                               bool use_center,
                               bool supports_triangle_fans);

  /// @brief   Create a |VertexGenerator| that can produce vertices for
  ///          a stroked arc inscribed within the given oval_bounds with
  ///          the given stroke half_width with enough polygon sub-divisions
  ///          to provide reasonable fidelity when viewed under the given
  ///          view transform. The outer edge of the stroked arc is
  ///          generated at (radius + half_width) and the inner edge is
  ///          generated at (radius - half_width).
  ///
  ///          Note that the view transform is only used to choose the
  ///          number of sample points to use per quarter circle and the
  ///          returned points are not transformed by it, instead they are
  ///          relative to the coordinate space of the oval bounds.
  ArcVertexGenerator StrokedArc(const Matrix& view_transform,
                                const Rect& oval_bounds,
                                Degrees start,
                                Degrees sweep,
                                Cap cap,
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

  /// Retrieve a pre-allocated arena of kPointArenaSize points.
  std::vector<Point>& GetStrokePointCache();

  /// Return a vector of Trig (cos, sin pairs) structs for a 90 degree
  /// circle quadrant of the specified pixel radius
  Trigs GetTrigsForDeviceRadius(Scalar pixel_radius);

  static ArcIteration ComputeArcQuadrantIterations(size_t trig_count,
                                                   impeller::Degrees start,
                                                   impeller::Degrees sweep);

 protected:
  /// Used for polyline generation.
  std::unique_ptr<std::vector<Point>> point_buffer_;
  std::unique_ptr<std::vector<uint16_t>> index_buffer_;
  /// Used for stroke path generation.
  std::vector<Point> stroke_points_;

 private:
  // Data for various Circle/EllipseGenerator classes, cached per
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

  static void GenerateFilledArcFan(const Trigs& trigs,
                                   const ArcIteration& iteration,
                                   const Rect& oval_bounds,
                                   bool use_center,
                                   const TessellatedVertexProc& proc);

  static void GenerateFilledArcStrip(const Trigs& trigs,
                                     const ArcIteration& iteration,
                                     const Rect& oval_bounds,
                                     bool use_center,
                                     const TessellatedVertexProc& proc);

  static void GenerateStrokedArc(const Trigs& trigs,
                                 const ArcIteration& iteration,
                                 const Rect& oval_bounds,
                                 Scalar half_width,
                                 Cap cap,
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

  static const ArcIteration ComputeCircleArcIterations(size_t count);

  Tessellator(const Tessellator&) = delete;

  Tessellator& operator=(const Tessellator&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_TESSELLATOR_TESSELLATOR_H_
