// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'seo_tag.dart';
import 'seo_widget.dart';

/// A widget that creates a semantic list for SEO purposes.
///
/// [SeoList] generates both:
/// 1. A visual Flutter widget (Column/ListView)
/// 2. A hidden `<ul>` or `<ol>` element in the SEO Shadow Tree
///
/// ## Unordered List
///
/// ```dart
/// SeoList(
///   items: [
///     Text('First item'),
///     Text('Second item'),
///     Text('Third item'),
///   ],
/// )
/// ```
///
/// ## Ordered List
///
/// ```dart
/// SeoList.ordered(
///   items: [
///     Text('Step 1: Open the app'),
///     Text('Step 2: Create an account'),
///     Text('Step 3: Start using'),
///   ],
/// )
/// ```
///
/// ## With Custom Item Builder
///
/// ```dart
/// SeoList.builder(
///   itemCount: products.length,
///   itemBuilder: (context, index) => ProductCard(products[index]),
///   itemTextExtractor: (index) => products[index].name,
/// )
/// ```
///
/// {@category SEO}
class SeoList extends StatelessWidget {
  /// Creates an unordered SEO list.
  const SeoList({
    super.key,
    required this.items,
    this.itemTexts,
    this.spacing = 8.0,
  }) : ordered = false;

  /// Creates an ordered SEO list.
  const SeoList.ordered({
    super.key,
    required this.items,
    this.itemTexts,
    this.spacing = 8.0,
  }) : ordered = true;

  /// The list item widgets.
  final List<Widget> items;

  /// Optional explicit text content for each item.
  ///
  /// If provided, these texts are used in the SEO Shadow Tree instead of
  /// attempting to extract text from the item widgets.
  final List<String>? itemTexts;

  /// Whether this is an ordered list (`<ol>`) or unordered (`<ul>`).
  final bool ordered;

  /// The spacing between list items.
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Seo(
      tag: ordered ? SeoTag.ol : SeoTag.ul,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: _buildItems(),
      ),
    );
  }

  List<Widget> _buildItems() {
    final result = <Widget>[];

    for (var i = 0; i < items.length; i++) {
      if (i > 0 && spacing > 0) {
        result.add(SizedBox(height: spacing));
      }

      final itemText = itemTexts != null && i < itemTexts!.length
          ? itemTexts![i]
          : null;

      result.add(
        Seo(
          tag: SeoTag.li,
          text: itemText,
          child: items[i],
        ),
      );
    }

    return result;
  }
}

/// A builder-based SEO list for large or dynamic lists.
///
/// ```dart
/// SeoListBuilder(
///   itemCount: 100,
///   itemBuilder: (context, index) => ListTile(title: Text('Item $index')),
///   itemTextExtractor: (index) => 'Item $index',
/// )
/// ```
///
/// {@category SEO}
class SeoListBuilder extends StatelessWidget {
  /// Creates an SEO list using a builder pattern.
  const SeoListBuilder({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.itemTextExtractor,
    this.ordered = false,
    this.separatorBuilder,
    this.padding,
    this.scrollDirection = Axis.vertical,
    this.shrinkWrap = false,
    this.physics,
  });

  /// The number of items in the list.
  final int itemCount;

  /// Builds the widget for each list item.
  final Widget Function(BuildContext context, int index) itemBuilder;

  /// Extracts the SEO text for each list item.
  ///
  /// If null, the system will attempt to extract text from the built widget.
  final String Function(int index)? itemTextExtractor;

  /// Whether this is an ordered list.
  final bool ordered;

  /// Builds the separator widget between items.
  final Widget Function(BuildContext context, int index)? separatorBuilder;

  /// Padding around the list.
  final EdgeInsetsGeometry? padding;

  /// The scroll direction of the list.
  final Axis scrollDirection;

  /// Whether the list should shrink-wrap its contents.
  final bool shrinkWrap;

  /// The scroll physics for the list.
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    return Seo(
      tag: ordered ? SeoTag.ol : SeoTag.ul,
      child: ListView.separated(
        padding: padding,
        scrollDirection: scrollDirection,
        shrinkWrap: shrinkWrap,
        physics: physics,
        itemCount: itemCount,
        itemBuilder: (context, index) {
          final text = itemTextExtractor?.call(index);
          return Seo(
            tag: SeoTag.li,
            text: text,
            child: itemBuilder(context, index),
          );
        },
        separatorBuilder: separatorBuilder ??
            (context, index) => const SizedBox(height: 8),
      ),
    );
  }
}

/// A definition list for SEO (term-definition pairs).
///
/// Useful for glossaries, FAQs, or any term-definition content.
///
/// ```dart
/// SeoDefinitionList(
///   items: [
///     SeoDefinitionItem(
///       term: 'Flutter',
///       definition: 'A UI toolkit for building natively compiled applications.',
///     ),
///     SeoDefinitionItem(
///       term: 'Dart',
///       definition: 'The programming language used by Flutter.',
///     ),
///   ],
/// )
/// ```
///
/// {@category SEO}
class SeoDefinitionList extends StatelessWidget {
  /// Creates an SEO definition list.
  const SeoDefinitionList({
    super.key,
    required this.items,
    this.spacing = 16.0,
  });

  /// The definition items.
  final List<SeoDefinitionItem> items;

  /// Spacing between definition items.
  final double spacing;

  @override
  Widget build(BuildContext context) {
    // Note: HTML <dl>, <dt>, <dd> aren't in SeoTag enum yet
    // This would need to be added for full support
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) SizedBox(height: spacing),
          _buildItem(context, items[i]),
        ],
      ],
    );
  }

  Widget _buildItem(BuildContext context, SeoDefinitionItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Seo(
          tag: SeoTag.strong,
          text: item.term,
          child: Text(
            item.term,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Seo(
          tag: SeoTag.p,
          text: item.definition,
          child: Text(item.definition),
        ),
      ],
    );
  }
}

/// An item in a definition list.
class SeoDefinitionItem {
  /// Creates a definition item.
  const SeoDefinitionItem({
    required this.term,
    required this.definition,
  });

  /// The term being defined.
  final String term;

  /// The definition of the term.
  final String definition;
}
