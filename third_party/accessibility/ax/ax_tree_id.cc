// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/accessibility/ax_tree_id.h"

#include <algorithm>
#include <iostream>

#include "base/check.h"
#include "base/no_destructor.h"
#include "base/notreached.h"
#include "base/util/values/values_util.h"
#include "base/values.h"
#include "ui/accessibility/ax_enums.mojom.h"

namespace ui {

AXTreeID::AXTreeID() : AXTreeID(ax::mojom::AXTreeIDType::kUnknown) {}

AXTreeID::AXTreeID(const AXTreeID& other) = default;

AXTreeID::AXTreeID(ax::mojom::AXTreeIDType type) : type_(type) {
  if (type_ == ax::mojom::AXTreeIDType::kToken)
    token_ = base::UnguessableToken::Create();
}

AXTreeID::AXTreeID(const std::string& string) {
  if (string.empty()) {
    type_ = ax::mojom::AXTreeIDType::kUnknown;
  } else {
    type_ = ax::mojom::AXTreeIDType::kToken;
    base::Optional<base::UnguessableToken> token =
        util::ValueToUnguessableToken(base::Value(string));
    CHECK(token);
    token_ = *token;
  }
}

// static
AXTreeID AXTreeID::FromString(const std::string& string) {
  return AXTreeID(string);
}

// static
AXTreeID AXTreeID::FromToken(const base::UnguessableToken& token) {
  return AXTreeID(token.ToString());
}

// static
AXTreeID AXTreeID::CreateNewAXTreeID() {
  return AXTreeID(ax::mojom::AXTreeIDType::kToken);
}

AXTreeID& AXTreeID::operator=(const AXTreeID& other) = default;

std::string AXTreeID::ToString() const {
  switch (type_) {
    case ax::mojom::AXTreeIDType::kUnknown:
      return "";
    case ax::mojom::AXTreeIDType::kToken:
      return util::UnguessableTokenToValue(*token_).GetString();
  }

  NOTREACHED();
  return std::string();
}

void swap(AXTreeID& first, AXTreeID& second) {
  std::swap(first.type_, second.type_);
  std::swap(first.token_, second.token_);
}

bool AXTreeID::operator==(const AXTreeID& rhs) const {
  return type_ == rhs.type_ && token_ == rhs.token_;
}

bool AXTreeID::operator!=(const AXTreeID& rhs) const {
  return !(*this == rhs);
}

bool AXTreeID::operator<(const AXTreeID& rhs) const {
  return std::tie(type_, token_) < std::tie(rhs.type_, rhs.token_);
}

bool AXTreeID::operator<=(const AXTreeID& rhs) const {
  return std::tie(type_, token_) <= std::tie(rhs.type_, rhs.token_);
}

bool AXTreeID::operator>(const AXTreeID& rhs) const {
  return !(*this <= rhs);
}

bool AXTreeID::operator>=(const AXTreeID& rhs) const {
  return !(*this < rhs);
}

size_t AXTreeIDHash::operator()(const ui::AXTreeID& tree_id) const {
  DCHECK(tree_id.type() == ax::mojom::AXTreeIDType::kToken);
  return base::UnguessableTokenHash()(tree_id.token().value());
}

std::ostream& operator<<(std::ostream& stream, const AXTreeID& value) {
  return stream << value.ToString();
}

const AXTreeID& AXTreeIDUnknown() {
  static const base::NoDestructor<AXTreeID> ax_tree_id_unknown(
      ax::mojom::AXTreeIDType::kUnknown);
  return *ax_tree_id_unknown;
}

}  // namespace ui
