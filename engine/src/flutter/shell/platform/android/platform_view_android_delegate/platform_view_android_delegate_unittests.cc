// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/platform_view_android_delegate/platform_view_android_delegate.h"

#include <functional>

#include "flutter/shell/platform/android/jni/jni_mock.h"
#include "flutter/shell/platform/embedder/embedder_semantics_update.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {

namespace {
// What PlatformViewAndroidDelegate hands to Java for one update.
struct EncodedSemantics {
  std::vector<uint8_t> buffer;
  std::vector<std::string> strings;
  std::vector<std::vector<uint8_t>> string_attribute_args;
  std::vector<uint8_t> actions_buffer;
  std::vector<std::string> action_strings;
};

EncodedSemantics Encode(
    const std::function<void(PlatformViewAndroidDelegate&)>& update) {
  auto jni_mock = std::make_shared<JNIMock>();
  EncodedSemantics encoded;
  EXPECT_CALL(*jni_mock, FlutterViewUpdateSemantics)
      .WillOnce([&encoded](std::vector<uint8_t> buffer,
                           std::vector<std::string> strings,
                           std::vector<std::vector<uint8_t>> args) {
        encoded.buffer = std::move(buffer);
        encoded.strings = std::move(strings);
        encoded.string_attribute_args = std::move(args);
      });
  EXPECT_CALL(*jni_mock, FlutterViewUpdateCustomAccessibilityActions)
      .WillOnce([&encoded](std::vector<uint8_t> actions_buffer,
                           std::vector<std::string> strings) {
        encoded.actions_buffer = std::move(actions_buffer);
        encoded.action_strings = std::move(strings);
      });
  PlatformViewAndroidDelegate delegate(jni_mock);
  update(delegate);
  return encoded;
}

StringAttributes BothAttributeKinds(const std::string& locale) {
  auto spell_out = std::make_shared<SpellOutStringAttribute>();
  spell_out->start = 0;
  spell_out->end = 1;
  spell_out->type = StringAttributeType::kSpellOut;
  auto locale_attribute = std::make_shared<LocaleStringAttribute>();
  locale_attribute->start = 1;
  locale_attribute->end = 2;
  locale_attribute->type = StringAttributeType::kLocale;
  locale_attribute->locale = locale;
  return {spell_out, locale_attribute};
}

// A node in which every field the encoder writes differs from its default.
// `tristate` and `check_state` vary the flags between nodes so that every
// bit of the encoded flags is covered by some node.
SemanticsNode NodeWithEveryField(int32_t id,
                                 SemanticsTristate tristate,
                                 SemanticsCheckState check_state) {
  SemanticsNode node;
  node.id = id;
  node.flags.isChecked = check_state;
  node.flags.isSelected = tristate;
  node.flags.isEnabled = tristate;
  node.flags.isToggled = tristate;
  node.flags.isExpanded = tristate;
  node.flags.isRequired = tristate;
  node.flags.isFocused = tristate;
  node.flags.isButton = true;
  node.flags.isTextField = true;
  node.flags.isInMutuallyExclusiveGroup = true;
  node.flags.isHeader = true;
  node.flags.isObscured = true;
  node.flags.scopesRoute = true;
  node.flags.namesRoute = true;
  node.flags.isHidden = true;
  node.flags.isImage = true;
  node.flags.isLiveRegion = true;
  node.flags.hasImplicitScrolling = true;
  node.flags.isMultiline = true;
  node.flags.isReadOnly = true;
  node.flags.isLink = true;
  node.flags.isSlider = true;
  node.flags.isKeyboardKey = true;
  node.flags.isAccessibilityFocusBlocked = true;
  // Arbitrary distinct values.
  node.actions = 0x3F;
  node.maxValueLength = 20 + id;
  node.currentValueLength = 5 + id;
  node.textSelectionBase = 1;
  node.textSelectionExtent = 3;
  node.platformViewId = 9;
  node.scrollChildren = 4;
  node.scrollIndex = 2;
  node.traversalParent = 7;
  node.scrollPosition = 12.5;
  node.scrollExtentMax = 100.25;
  node.scrollExtentMin = -3.5;
  node.role = SemanticsRole::kSlider;
  node.identifier = "identifier" + std::to_string(id);
  node.label = "label";
  node.labelAttributes = BothAttributeKinds("fr-FR");
  node.value = "value";
  node.valueAttributes = BothAttributeKinds("de-DE");
  node.increasedValue = "increased";
  node.increasedValueAttributes = BothAttributeKinds("es-ES");
  node.decreasedValue = "decreased";
  node.decreasedValueAttributes = BothAttributeKinds("it-IT");
  node.hint = "hint";
  node.hintAttributes = BothAttributeKinds("ja-JP");
  node.tooltip = "tooltip";
  node.linkUrl = "https://flutter.dev";
  node.locale = "he-IL";
  node.minValue = "0";
  node.maxValue = "100";
  node.headingLevel = 2;
  node.textDirection = 2;
  node.rect = SkRect::MakeLTRB(1.5, 2.25, 30.75, 40.125);
  // 3D, so that a 3x3 matrix would lose information.
  node.transform = SkM44::Rotate({1, 0, 0}, 0.25);
  node.transform.setRC(2, 3, 5);
  node.hitTestTransform = SkM44::Translate(1, 2, 3);
  // Traversal and hit test order lists of different lengths.
  node.childrenInTraversalOrder = {id * 10 + 1, id * 10 + 2};
  node.childrenInHitTestOrder = {id * 10 + 2, id * 10 + 1, id * 10 + 3};
  node.customAccessibilityActions = {100 + id};
  return node;
}
}  // namespace

TEST(PlatformViewShell,
     UpdateSemanticsFromEmbedderUpdateEncodesLikeEngineUpdate) {
  SemanticsNodeUpdates nodes;
  nodes[1] = NodeWithEveryField(1, SemanticsTristate::kTrue,
                                SemanticsCheckState::kTrue);
  nodes[2] = NodeWithEveryField(2, SemanticsTristate::kFalse,
                                SemanticsCheckState::kMixed);
  nodes[3] = NodeWithEveryField(3, SemanticsTristate::kNone,
                                SemanticsCheckState::kNone);
  CustomAccessibilityActionUpdates actions;
  for (int32_t id : {101, 102}) {
    CustomAccessibilityAction action;
    action.id = id;
    action.overrideId = id % 2 == 0 ? 0 : 1 << 4;
    action.label = "action" + std::to_string(id);
    action.hint = "hint" + std::to_string(id);
    actions[id] = action;
  }

  EncodedSemantics from_engine =
      Encode([&](PlatformViewAndroidDelegate& delegate) {
        delegate.UpdateSemantics(nodes, actions);
      });
  // The embedder update points into `nodes` and `actions`, which outlive it.
  EmbedderSemanticsUpdate2 embedder_update(/*view_id=*/0, nodes, actions);
  EncodedSemantics from_embedder =
      Encode([&](PlatformViewAndroidDelegate& delegate) {
        delegate.UpdateSemantics(*embedder_update.get());
      });

  ASSERT_FALSE(from_engine.buffer.empty());
  EXPECT_EQ(from_embedder.buffer, from_engine.buffer);
  EXPECT_EQ(from_embedder.strings, from_engine.strings);
  EXPECT_EQ(from_embedder.string_attribute_args,
            from_engine.string_attribute_args);
  EXPECT_EQ(from_embedder.actions_buffer, from_engine.actions_buffer);
  EXPECT_EQ(from_embedder.action_strings, from_engine.action_strings);
}

TEST(PlatformViewShell, UpdateSemanticsDoesFlutterViewUpdateSemantics) {
  auto jni_mock = std::make_shared<JNIMock>();
  auto delegate = std::make_unique<PlatformViewAndroidDelegate>(jni_mock);

  flutter::SemanticsNodeUpdates update;
  flutter::SemanticsNode node0;
  node0.id = 0;
  node0.identifier = "identifier";
  node0.label = "label";
  node0.tooltip = "tooltip";
  update.insert(std::make_pair(0, node0));

  std::vector<uint8_t> expected_buffer(
      PlatformViewAndroidDelegate::kBytesPerNode);
  std::vector<std::vector<uint8_t>> expected_string_attribute_args(0);
  size_t position = 0;
  int32_t* buffer_int32 = reinterpret_cast<int32_t*>(&expected_buffer[0]);
  float* buffer_float32 = reinterpret_cast<float*>(&expected_buffer[0]);
  std::vector<std::string> expected_strings;
  buffer_int32[position++] = node0.id;
  std::memcpy(&buffer_int32[position], &node0.flags, 2);
  position += 2;
  buffer_int32[position++] = node0.actions;
  buffer_int32[position++] = node0.maxValueLength;
  buffer_int32[position++] = node0.currentValueLength;
  buffer_int32[position++] = node0.textSelectionBase;
  buffer_int32[position++] = node0.textSelectionExtent;
  buffer_int32[position++] = node0.platformViewId;
  buffer_int32[position++] = node0.scrollChildren;
  buffer_int32[position++] = node0.scrollIndex;
  buffer_int32[position++] = node0.traversalParent;
  buffer_float32[position++] = static_cast<float>(node0.scrollPosition);
  buffer_float32[position++] = static_cast<float>(node0.scrollExtentMax);
  buffer_float32[position++] = static_cast<float>(node0.scrollExtentMin);
  buffer_int32[position++] = static_cast<int32_t>(node0.role);
  buffer_int32[position++] = expected_strings.size();  // node0.identifier
  expected_strings.push_back(node0.identifier);
  buffer_int32[position++] = expected_strings.size();  // node0.label
  expected_strings.push_back(node0.label);
  buffer_int32[position++] = -1;  // node0.labelAttributes
  buffer_int32[position++] = -1;  // node0.value
  buffer_int32[position++] = -1;  // node0.valueAttributes
  buffer_int32[position++] = -1;  // node0.increasedValue
  buffer_int32[position++] = -1;  // node0.increasedValueAttributes
  buffer_int32[position++] = -1;  // node0.decreasedValue
  buffer_int32[position++] = -1;  // node0.decreasedValueAttributes
  buffer_int32[position++] = -1;  // node0.hint
  buffer_int32[position++] = -1;  // node0.hintAttributes
  buffer_int32[position++] = expected_strings.size();  // node0.tooltip
  expected_strings.push_back(node0.tooltip);
  buffer_int32[position++] = -1;  // node0.linkUrl
  buffer_int32[position++] = -1;  // node0.locale
  buffer_int32[position++] = -1;  // node0.minValue
  buffer_int32[position++] = -1;  // node0.maxValue
  buffer_int32[position++] = node0.headingLevel;
  buffer_int32[position++] = node0.textDirection;
  buffer_float32[position++] = node0.rect.left();
  buffer_float32[position++] = node0.rect.top();
  buffer_float32[position++] = node0.rect.right();
  buffer_float32[position++] = node0.rect.bottom();
  node0.transform.getColMajor(&buffer_float32[position]);
  position += 16;
  node0.hitTestTransform.getColMajor(&buffer_float32[position]);
  position += 16;
  buffer_int32[position++] = 0;  // node0.childrenInTraversalOrder.size();
  buffer_int32[position++] = 0;  // node0.customAccessibilityActions.size();
  EXPECT_CALL(*jni_mock,
              FlutterViewUpdateSemantics(expected_buffer, expected_strings,
                                         expected_string_attribute_args));
  // Creates empty custom actions.
  flutter::CustomAccessibilityActionUpdates actions;
  delegate->UpdateSemantics(update, actions);
}

TEST(PlatformViewShell, UpdateSemanticsDoesUpdateLinkUrl) {
  auto jni_mock = std::make_shared<JNIMock>();
  auto delegate = std::make_unique<PlatformViewAndroidDelegate>(jni_mock);

  flutter::SemanticsNodeUpdates update;
  flutter::SemanticsNode node0;
  node0.id = 0;
  node0.identifier = "identifier";
  node0.label = "label";
  node0.linkUrl = "url";
  update.insert(std::make_pair(0, node0));

  std::vector<uint8_t> expected_buffer(
      PlatformViewAndroidDelegate::kBytesPerNode);
  std::vector<std::vector<uint8_t>> expected_string_attribute_args(0);
  size_t position = 0;
  int32_t* buffer_int32 = reinterpret_cast<int32_t*>(&expected_buffer[0]);
  float* buffer_float32 = reinterpret_cast<float*>(&expected_buffer[0]);
  std::vector<std::string> expected_strings;
  buffer_int32[position++] = node0.id;
  std::memcpy(&buffer_int32[position], &node0.flags, 2);
  position += 2;
  buffer_int32[position++] = node0.actions;
  buffer_int32[position++] = node0.maxValueLength;
  buffer_int32[position++] = node0.currentValueLength;
  buffer_int32[position++] = node0.textSelectionBase;
  buffer_int32[position++] = node0.textSelectionExtent;
  buffer_int32[position++] = node0.platformViewId;
  buffer_int32[position++] = node0.scrollChildren;
  buffer_int32[position++] = node0.scrollIndex;
  buffer_int32[position++] = node0.traversalParent;
  buffer_float32[position++] = static_cast<float>(node0.scrollPosition);
  buffer_float32[position++] = static_cast<float>(node0.scrollExtentMax);
  buffer_float32[position++] = static_cast<float>(node0.scrollExtentMin);
  buffer_int32[position++] = static_cast<int32_t>(node0.role);
  buffer_int32[position++] = expected_strings.size();  // node0.identifier
  expected_strings.push_back(node0.identifier);
  buffer_int32[position++] = expected_strings.size();  // node0.label
  expected_strings.push_back(node0.label);
  buffer_int32[position++] = -1;  // node0.labelAttributes
  buffer_int32[position++] = -1;  // node0.value
  buffer_int32[position++] = -1;  // node0.valueAttributes
  buffer_int32[position++] = -1;  // node0.increasedValue
  buffer_int32[position++] = -1;  // node0.increasedValueAttributes
  buffer_int32[position++] = -1;  // node0.decreasedValue
  buffer_int32[position++] = -1;  // node0.decreasedValueAttributes
  buffer_int32[position++] = -1;  // node0.hint
  buffer_int32[position++] = -1;  // node0.hintAttributes
  buffer_int32[position++] = -1;  // node0.tooltip
  buffer_int32[position++] = expected_strings.size();  // node0.linkUrl
  expected_strings.push_back(node0.linkUrl);
  buffer_int32[position++] = -1;  // node0.locale
  buffer_int32[position++] = -1;  // node0.minValue
  buffer_int32[position++] = -1;  // node0.maxValue
  buffer_int32[position++] = node0.headingLevel;
  buffer_int32[position++] = node0.textDirection;
  buffer_float32[position++] = node0.rect.left();
  buffer_float32[position++] = node0.rect.top();
  buffer_float32[position++] = node0.rect.right();
  buffer_float32[position++] = node0.rect.bottom();
  node0.transform.getColMajor(&buffer_float32[position]);
  position += 16;
  node0.hitTestTransform.getColMajor(&buffer_float32[position]);
  position += 16;
  buffer_int32[position++] = 0;  // node0.childrenInTraversalOrder.size();
  buffer_int32[position++] = 0;  // node0.customAccessibilityActions.size();
  EXPECT_CALL(*jni_mock,
              FlutterViewUpdateSemantics(expected_buffer, expected_strings,
                                         expected_string_attribute_args));
  // Creates empty custom actions.
  flutter::CustomAccessibilityActionUpdates actions;
  delegate->UpdateSemantics(update, actions);
}

TEST(PlatformViewShell, UpdateSemanticsDoesUpdateLocale) {
  auto jni_mock = std::make_shared<JNIMock>();
  auto delegate = std::make_unique<PlatformViewAndroidDelegate>(jni_mock);

  flutter::SemanticsNodeUpdates update;
  flutter::SemanticsNode node0;
  node0.id = 0;
  node0.identifier = "identifier";
  node0.label = "label";
  node0.locale = "es-MX";
  node0.traversalParent = -1;
  update.insert(std::make_pair(0, node0));

  std::vector<uint8_t> expected_buffer(
      PlatformViewAndroidDelegate::kBytesPerNode);
  std::vector<std::vector<uint8_t>> expected_string_attribute_args(0);
  size_t position = 0;
  int32_t* buffer_int32 = reinterpret_cast<int32_t*>(&expected_buffer[0]);
  float* buffer_float32 = reinterpret_cast<float*>(&expected_buffer[0]);
  std::vector<std::string> expected_strings;
  buffer_int32[position++] = node0.id;
  std::memcpy(&buffer_int32[position], &node0.flags, 2);
  position += 2;
  buffer_int32[position++] = node0.actions;
  buffer_int32[position++] = node0.maxValueLength;
  buffer_int32[position++] = node0.currentValueLength;
  buffer_int32[position++] = node0.textSelectionBase;
  buffer_int32[position++] = node0.textSelectionExtent;
  buffer_int32[position++] = node0.platformViewId;
  buffer_int32[position++] = node0.scrollChildren;
  buffer_int32[position++] = node0.scrollIndex;
  buffer_int32[position++] = node0.traversalParent;
  buffer_float32[position++] = static_cast<float>(node0.scrollPosition);
  buffer_float32[position++] = static_cast<float>(node0.scrollExtentMax);
  buffer_float32[position++] = static_cast<float>(node0.scrollExtentMin);
  buffer_int32[position++] = static_cast<int32_t>(node0.role);
  buffer_int32[position++] = expected_strings.size();  // node0.identifier
  expected_strings.push_back(node0.identifier);
  buffer_int32[position++] = expected_strings.size();  // node0.label
  expected_strings.push_back(node0.label);
  buffer_int32[position++] = -1;  // node0.labelAttributes
  buffer_int32[position++] = -1;  // node0.value
  buffer_int32[position++] = -1;  // node0.valueAttributes
  buffer_int32[position++] = -1;  // node0.increasedValue
  buffer_int32[position++] = -1;  // node0.increasedValueAttributes
  buffer_int32[position++] = -1;  // node0.decreasedValue
  buffer_int32[position++] = -1;  // node0.decreasedValueAttributes
  buffer_int32[position++] = -1;  // node0.hint
  buffer_int32[position++] = -1;  // node0.hintAttributes
  buffer_int32[position++] = -1;  // node0.tooltip
  buffer_int32[position++] = -1;  // node0.linkUrl
  buffer_int32[position++] = expected_strings.size();
  expected_strings.push_back(node0.locale);  // node0.locale
  buffer_int32[position++] = -1;             // node0.minValue
  buffer_int32[position++] = -1;             // node0.maxValue
  buffer_int32[position++] = node0.headingLevel;
  buffer_int32[position++] = node0.textDirection;
  buffer_float32[position++] = node0.rect.left();
  buffer_float32[position++] = node0.rect.top();
  buffer_float32[position++] = node0.rect.right();
  buffer_float32[position++] = node0.rect.bottom();
  node0.transform.getColMajor(&buffer_float32[position]);
  position += 16;
  node0.hitTestTransform.getColMajor(&buffer_float32[position]);
  position += 16;
  buffer_int32[position++] = 0;  // node0.childrenInTraversalOrder.size();
  buffer_int32[position++] = 0;  // node0.customAccessibilityActions.size();
  EXPECT_CALL(*jni_mock,
              FlutterViewUpdateSemantics(expected_buffer, expected_strings,
                                         expected_string_attribute_args));
  // Creates empty custom actions.
  flutter::CustomAccessibilityActionUpdates actions;
  delegate->UpdateSemantics(update, actions);
}

TEST(PlatformViewShell,
     UpdateSemanticsDoesFlutterViewUpdateSemanticsWithStringAttribtes) {
  auto jni_mock = std::make_shared<JNIMock>();
  auto delegate = std::make_unique<PlatformViewAndroidDelegate>(jni_mock);

  flutter::SemanticsNodeUpdates update;
  flutter::SemanticsNode node0;
  std::shared_ptr<SpellOutStringAttribute> spell_out_attribute =
      std::make_shared<SpellOutStringAttribute>();
  spell_out_attribute->start = 2;
  spell_out_attribute->end = 4;
  spell_out_attribute->type = flutter::StringAttributeType::kSpellOut;
  std::shared_ptr<LocaleStringAttribute> locale_attribute =
      std::make_shared<LocaleStringAttribute>();
  locale_attribute->start = 1;
  locale_attribute->end = 3;
  locale_attribute->type = flutter::StringAttributeType::kLocale;
  locale_attribute->locale = "en-US";
  node0.id = 0;
  node0.identifier = "identifier";
  node0.label = "label";
  node0.labelAttributes.push_back(spell_out_attribute);
  node0.hint = "hint";
  node0.hintAttributes.push_back(locale_attribute);
  update.insert(std::make_pair(0, node0));

  std::vector<uint8_t> expected_buffer(
      PlatformViewAndroidDelegate::kBytesPerNode +
      // 1 label attribute + 1 hint attribute.
      2 * PlatformViewAndroidDelegate::kBytesPerStringAttribute);
  std::vector<std::vector<uint8_t>> expected_string_attribute_args;
  size_t position = 0;
  int32_t* buffer_int32 = reinterpret_cast<int32_t*>(&expected_buffer[0]);
  float* buffer_float32 = reinterpret_cast<float*>(&expected_buffer[0]);
  std::vector<std::string> expected_strings;
  buffer_int32[position++] = node0.id;
  std::memcpy(&buffer_int32[position], &node0.flags, 2);
  position += 2;
  buffer_int32[position++] = node0.actions;
  buffer_int32[position++] = node0.maxValueLength;
  buffer_int32[position++] = node0.currentValueLength;
  buffer_int32[position++] = node0.textSelectionBase;
  buffer_int32[position++] = node0.textSelectionExtent;
  buffer_int32[position++] = node0.platformViewId;
  buffer_int32[position++] = node0.scrollChildren;
  buffer_int32[position++] = node0.scrollIndex;
  buffer_int32[position++] = node0.traversalParent;
  buffer_float32[position++] = static_cast<float>(node0.scrollPosition);
  buffer_float32[position++] = static_cast<float>(node0.scrollExtentMax);
  buffer_float32[position++] = static_cast<float>(node0.scrollExtentMin);
  buffer_int32[position++] = static_cast<int32_t>(node0.role);
  buffer_int32[position++] = expected_strings.size();  // node0.identifier
  expected_strings.push_back(node0.identifier);
  buffer_int32[position++] = expected_strings.size();  // node0.label
  expected_strings.push_back(node0.label);
  buffer_int32[position++] = 1;   // node0.labelAttributes
  buffer_int32[position++] = 2;   // node0.labelAttributes[0].start
  buffer_int32[position++] = 4;   // node0.labelAttributes[0].end
  buffer_int32[position++] = 0;   // node0.labelAttributes[0].type
  buffer_int32[position++] = -1;  // node0.labelAttributes[0].args
  buffer_int32[position++] = -1;  // node0.value
  buffer_int32[position++] = -1;  // node0.valueAttributes
  buffer_int32[position++] = -1;  // node0.increasedValue
  buffer_int32[position++] = -1;  // node0.increasedValueAttributes
  buffer_int32[position++] = -1;  // node0.decreasedValue
  buffer_int32[position++] = -1;  // node0.decreasedValueAttributes
  buffer_int32[position++] = expected_strings.size();  // node0.hint
  expected_strings.push_back(node0.hint);
  buffer_int32[position++] = 1;  // node0.hintAttributes
  buffer_int32[position++] = 1;  // node0.hintAttributes[0].start
  buffer_int32[position++] = 3;  // node0.hintAttributes[0].end
  buffer_int32[position++] = 1;  // node0.hintAttributes[0].type
  buffer_int32[position++] =
      expected_string_attribute_args.size();  // node0.hintAttributes[0].args
  expected_string_attribute_args.push_back(
      {locale_attribute->locale.begin(), locale_attribute->locale.end()});
  buffer_int32[position++] = -1;  // node0.tooltip
  buffer_int32[position++] = -1;  // node0.linkUrl
  buffer_int32[position++] = -1;  // node0.locale
  buffer_int32[position++] = -1;  // node0.minValue
  buffer_int32[position++] = -1;  // node0.maxValue
  buffer_int32[position++] = node0.headingLevel;
  buffer_int32[position++] = node0.textDirection;
  buffer_float32[position++] = node0.rect.left();
  buffer_float32[position++] = node0.rect.top();
  buffer_float32[position++] = node0.rect.right();
  buffer_float32[position++] = node0.rect.bottom();
  node0.transform.getColMajor(&buffer_float32[position]);
  position += 16;
  node0.hitTestTransform.getColMajor(&buffer_float32[position]);
  position += 16;
  buffer_int32[position++] = 0;  // node0.childrenInTraversalOrder.size();
  buffer_int32[position++] = 0;  // node0.customAccessibilityActions.size();
  EXPECT_CALL(*jni_mock,
              FlutterViewUpdateSemantics(expected_buffer, expected_strings,
                                         expected_string_attribute_args));
  // Creates empty custom actions.
  flutter::CustomAccessibilityActionUpdates actions;
  delegate->UpdateSemantics(update, actions);
}

TEST(PlatformViewShell,
     UpdateSemanticsDoesFlutterViewUpdateCustomAccessibilityActions) {
  auto jni_mock = std::make_shared<JNIMock>();
  auto delegate = std::make_unique<PlatformViewAndroidDelegate>(jni_mock);

  flutter::CustomAccessibilityActionUpdates actions;
  flutter::CustomAccessibilityAction action0;
  action0.id = 0;
  action0.overrideId = 1;
  action0.label = "label";
  action0.hint = "hint";
  actions.insert(std::make_pair(0, action0));

  std::vector<uint8_t> expected_actions_buffer(
      PlatformViewAndroidDelegate::kBytesPerAction);
  int32_t* actions_buffer_int32 =
      reinterpret_cast<int32_t*>(&expected_actions_buffer[0]);
  std::vector<std::string> expected_action_strings;
  actions_buffer_int32[0] = action0.id;
  actions_buffer_int32[1] = action0.overrideId;
  actions_buffer_int32[2] = expected_action_strings.size();
  expected_action_strings.push_back(action0.label);
  actions_buffer_int32[3] = expected_action_strings.size();
  expected_action_strings.push_back(action0.hint);

  EXPECT_CALL(*jni_mock, FlutterViewUpdateCustomAccessibilityActions(
                             expected_actions_buffer, expected_action_strings));
  // Creates empty update.
  flutter::SemanticsNodeUpdates update;
  delegate->UpdateSemantics(update, actions);
}

TEST(PlatformViewShell, UpdateSemanticsEmptyDoesNotCrash) {
  auto jni_mock = std::make_shared<JNIMock>();
  auto delegate = std::make_unique<PlatformViewAndroidDelegate>(jni_mock);

  EXPECT_CALL(*jni_mock, FlutterViewUpdateCustomAccessibilityActions(
                             ::testing::_, ::testing::_))
      .Times(0);
  EXPECT_CALL(*jni_mock, FlutterViewUpdateSemantics(::testing::_, ::testing::_,
                                                    ::testing::_))
      .Times(0);

  flutter::SemanticsNodeUpdates update;
  flutter::CustomAccessibilityActionUpdates actions;
  delegate->UpdateSemantics(update, actions);
}

}  // namespace testing
}  // namespace flutter
