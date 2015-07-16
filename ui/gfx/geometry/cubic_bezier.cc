// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gfx/geometry/cubic_bezier.h"

#include <algorithm>
#include <cmath>

#include "base/logging.h"

namespace gfx {

namespace {

static const double kBezierEpsilon = 1e-7;
static const int MAX_STEPS = 30;

static double eval_bezier(double p1, double p2, double t) {
  const double p1_times_3 = 3.0 * p1;
  const double p2_times_3 = 3.0 * p2;
  const double h3 = p1_times_3;
  const double h1 = p1_times_3 - p2_times_3 + 1.0;
  const double h2 = p2_times_3 - 6.0 * p1;
  return t * (t * (t * h1 + h2) + h3);
}

static double eval_bezier_derivative(double p1, double p2, double t) {
  const double h1 = 9.0 * p1 - 9.0 * p2 + 3.0;
  const double h2 = 6.0 * p2 - 12.0 * p1;
  const double h3 = 3.0 * p1;
  return t * (t * h1 + h2) + h3;
}

// Finds t such that eval_bezier(x1, x2, t) = x.
// There is a unique solution if x1 and x2 lie within (0, 1).
static double bezier_interp(double x1,
                            double x2,
                            double x) {
  DCHECK_GE(1.0, x1);
  DCHECK_LE(0.0, x1);
  DCHECK_GE(1.0, x2);
  DCHECK_LE(0.0, x2);

  x1 = std::min(std::max(x1, 0.0), 1.0);
  x2 = std::min(std::max(x2, 0.0), 1.0);
  x = std::min(std::max(x, 0.0), 1.0);

  // We're just going to do bisection for now (for simplicity), but we could
  // easily do some newton steps if this turns out to be a bottleneck.
  double t = 0.0;
  double step = 1.0;
  for (int i = 0; i < MAX_STEPS; ++i, step *= 0.5) {
    const double error = eval_bezier(x1, x2, t) - x;
    if (std::abs(error) < kBezierEpsilon)
      break;
    t += error > 0.0 ? -step : step;
  }

  // We should have terminated the above loop because we got close to x, not
  // because we exceeded MAX_STEPS. Do a DCHECK here to confirm.
  DCHECK_GT(kBezierEpsilon, std::abs(eval_bezier(x1, x2, t) - x));

  return t;
}

}  // namespace

CubicBezier::CubicBezier(double x1, double y1, double x2, double y2)
    : x1_(x1),
      y1_(y1),
      x2_(x2),
      y2_(y2) {
}

CubicBezier::~CubicBezier() {
}

double CubicBezier::Solve(double x) const {
  return eval_bezier(y1_, y2_, bezier_interp(x1_, x2_, x));
}

double CubicBezier::Slope(double x) const {
  double t = bezier_interp(x1_, x2_, x);
  double dx_dt = eval_bezier_derivative(x1_, x2_, t);
  double dy_dt = eval_bezier_derivative(y1_, y2_, t);
  return dy_dt / dx_dt;
}

void CubicBezier::Range(double* min, double* max) const {
  *min = 0;
  *max = 1;
  if (0 <= y1_ && y1_ < 1 && 0 <= y2_ && y2_ <= 1)
    return;

  // Represent the function's derivative in the form at^2 + bt + c.
  // (Technically this is (dy/dt)*(1/3), which is suitable for finding zeros
  // but does not actually give the slope of the curve.)
  double a = 3 * (y1_ - y2_) + 1;
  double b = 2 * (y2_ - 2 * y1_);
  double c = y1_;

  // Check if the derivative is constant.
  if (std::abs(a) < kBezierEpsilon &&
      std::abs(b) < kBezierEpsilon)
    return;

  // Zeros of the function's derivative.
  double t_1 = 0;
  double t_2 = 0;

  if (std::abs(a) < kBezierEpsilon) {
    // The function's derivative is linear.
    t_1 = -c / b;
  } else {
    // The function's derivative is a quadratic. We find the zeros of this
    // quadratic using the quadratic formula.
    double discriminant = b * b - 4 * a * c;
    if (discriminant < 0)
      return;
    double discriminant_sqrt = sqrt(discriminant);
    t_1 = (-b + discriminant_sqrt) / (2 * a);
    t_2 = (-b - discriminant_sqrt) / (2 * a);
  }

  double sol_1 = 0;
  double sol_2 = 0;

  if (0 < t_1 && t_1 < 1)
    sol_1 = eval_bezier(y1_, y2_, t_1);

  if (0 < t_2 && t_2 < 1)
    sol_2 = eval_bezier(y1_, y2_, t_2);

  *min = std::min(std::min(*min, sol_1), sol_2);
  *max = std::max(std::max(*max, sol_1), sol_2);
}

}  // namespace gfx
