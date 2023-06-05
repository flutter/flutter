// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/display_list/geometry/dl_region.h"

#include "flutter/fml/logging.h"

namespace flutter {

DlRegion::DlRegion(std::vector<SkIRect>&& rects) {
  // If SpanLines can not be memmoved `addRect` would be signifantly slower
  // due to cost of inserting and removing elements from the `lines_` vector.
  static_assert(std::is_trivially_constructible<SpanLine>::value,
                "SpanLine must be trivially constructible.");
  addRects(std::move(rects));

  for (auto& spanvec : spanvec_pool_) {
    delete spanvec;
  }
  spanvec_pool_.clear();
}

DlRegion::~DlRegion() {
  for (auto& line : lines_) {
    delete line.spans;
  }
}

std::vector<SkIRect> DlRegion::getRects(bool deband) const {
  std::vector<SkIRect> rects;
  size_t previous_span_end = 0;
  for (const auto& line : lines_) {
    for (const Span& span : *line.spans) {
      SkIRect rect{span.left, line.top, span.right, line.bottom};
      if (deband) {
        auto iter = rects.begin() + previous_span_end;
        // If there is rectangle previously in rects on which this one is a
        // vertical continuation, remove the previous rectangle and expand
        // this one vertically to cover the area.
        while (iter != rects.begin()) {
          --iter;
          if (iter->bottom() < rect.top()) {
            // Went all the way to previous span line.
            break;
          } else if (iter->left() == rect.left() &&
                     iter->right() == rect.right()) {
            FML_DCHECK(iter->bottom() == rect.top());
            rect.fTop = iter->fTop;
            rects.erase(iter);
            --previous_span_end;
            break;
          }
        }
      }
      rects.push_back(rect);
    }
    previous_span_end = rects.size();
  }
  return rects;
}

void DlRegion::SpanLine::insertSpan(int32_t left, int32_t right) {
  auto& spans = *this->spans;
  auto size = spans.size();
  for (size_t i = 0; i < size; ++i) {
    Span& span = spans[i];
    if (right < span.left) {
      spans.insert(spans.begin() + i, {left, right});
      return;
    }
    if (left > span.right) {
      continue;
    }
    size_t last_index = i;
    while (last_index + 1 < size && right >= spans[last_index + 1].left) {
      ++last_index;
    }
    span.left = std::min(span.left, left);
    span.right = std::max(spans[last_index].right, right);
    if (last_index > i) {
      spans.erase(spans.begin() + i + 1, spans.begin() + last_index + 1);
    }
    return;
  }

  spans.push_back({left, right});
}

bool DlRegion::SpanLine::spansEqual(const SpanLine& l2) const {
  SpanVec& spans = *this->spans;
  SpanVec& otherSpans = *l2.spans;
  FML_DCHECK(this != &l2);

  if (spans.size() != otherSpans.size()) {
    return false;
  }
  return memcmp(spans.data(), otherSpans.data(), spans.size() * sizeof(Span)) ==
         0;
}

void DlRegion::insertLine(size_t position, SpanLine line) {
  lines_.insert(lines_.begin() + position, line);
}

DlRegion::LineVec::iterator DlRegion::removeLine(
    DlRegion::LineVec::iterator line) {
  spanvec_pool_.push_back(line->spans);
  return lines_.erase(line);
}

DlRegion::SpanLine DlRegion::makeLine(int32_t top,
                                      int32_t bottom,
                                      int32_t spanLeft,
                                      int32_t spanRight) {
  SpanVec* span_vec;
  if (!spanvec_pool_.empty()) {
    span_vec = spanvec_pool_.back();
    spanvec_pool_.pop_back();
    span_vec->clear();
  } else {
    span_vec = new SpanVec();
  }
  span_vec->push_back({spanLeft, spanRight});
  return {top, bottom, span_vec};
}

DlRegion::SpanLine DlRegion::makeLine(int32_t top,
                                      int32_t bottom,
                                      const SpanVec& spans) {
  SpanVec* span_vec;
  if (!spanvec_pool_.empty()) {
    span_vec = spanvec_pool_.back();
    spanvec_pool_.pop_back();
  } else {
    span_vec = new SpanVec();
  }
  *span_vec = spans;
  return {top, bottom, span_vec};
}

void DlRegion::addRects(std::vector<SkIRect>&& rects) {
  std::sort(rects.begin(), rects.end(), [](const SkIRect& a, const SkIRect& b) {
    // Sort the rectangles by Y axis. Because the rectangles have varying
    // height, they are added to span lines in non-deterministic order and thus
    // it makes no difference if they are also sorted by the X axis.
    return a.top() < b.top();
  });

  size_t start_index = 0;

  size_t dirty_start = std::numeric_limits<size_t>::max();
  size_t dirty_end = 0;

  // Marks line as dirty. Dirty lines will be checked for equality
  // later and merged as needed.
  auto mark_dirty = [&](size_t line) {
    dirty_start = std::min(dirty_start, line);
    dirty_end = std::max(dirty_end, line);
  };

  for (const SkIRect& rect : rects) {
    if (rect.isEmpty()) {
      continue;
    }

    int32_t y1 = rect.fTop;
    int32_t y2 = rect.fBottom;

    for (size_t i = start_index; i < lines_.size() && y1 < y2; ++i) {
      SpanLine& line = lines_[i];

      if (rect.fTop >= line.bottom) {
        start_index = i;
        continue;
      }

      if (y2 <= line.top) {
        insertLine(i, makeLine(y1, y2, rect.fLeft, rect.fRight));
        mark_dirty(i);
        y1 = y2;
        break;
      }
      if (y1 < line.top) {
        auto prevLineStart = line.top;
        insertLine(i, makeLine(y1, prevLineStart, rect.fLeft, rect.fRight));
        mark_dirty(i);
        y1 = prevLineStart;
        continue;
      }
      if (y1 > line.top) {
        // duplicate line
        auto prevLineEnd = line.bottom;
        line.bottom = y1;
        mark_dirty(i);
        insertLine(i + 1, makeLine(y1, prevLineEnd, *line.spans));
        continue;
      }
      FML_DCHECK(y1 == line.top);
      if (y2 < line.bottom) {
        // duplicate line
        auto newLine = makeLine(y2, line.bottom, *line.spans);
        line.bottom = y2;
        line.insertSpan(rect.fLeft, rect.fRight);
        insertLine(i + 1, newLine);
        y1 = y2;
        mark_dirty(i);
        break;
      }
      FML_DCHECK(y2 >= line.bottom);
      line.insertSpan(rect.fLeft, rect.fRight);
      mark_dirty(i);
      y1 = line.bottom;
    }

    if (y1 < y2) {
      lines_.push_back(makeLine(y1, y2, rect.fLeft, rect.fRight));
      mark_dirty(lines_.size() - 1);
    }

    // Check for duplicate lines and merge them.
    if (dirty_start <= dirty_end) {
      // Expand the region by one if possible.
      if (dirty_start > 0) {
        --dirty_start;
      }
      if (dirty_end + 1 < lines_.size()) {
        ++dirty_end;
      }
      for (auto i = lines_.begin() + dirty_start;
           i < lines_.begin() + dirty_end;) {
        auto& line = *i;
        auto& next = *(i + 1);
        if (line.bottom == next.top && line.spansEqual(next)) {
          --dirty_end;
          next.top = line.top;
          i = removeLine(i);
        } else {
          ++i;
        }
      }
    }
    dirty_start = std::numeric_limits<size_t>::max();
    dirty_end = 0;
  }
}

}  // namespace flutter
