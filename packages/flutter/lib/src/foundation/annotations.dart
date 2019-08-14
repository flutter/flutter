// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Examples can assume:
// class Cat { }

/// A category with which to annotate a class, for documentation purposes.
///
/// The engineering team that owns the library to which the class belongs
/// defines the categories used for classes in that library. For example, the
/// Flutter engineering team has defined categories like "Basic/Buttons" and
/// "Material Design/Buttons" for Flutter widgets.
///
/// A class can have multiple categories.
///
/// {@tool sample}
///
/// ```dart
/// /// A copper coffee pot, as desired by Ben Turpin.
/// /// ...documentation...
/// @Category('Pots')
/// @Category('Copper')
/// @Subcategory('Coffee')
/// @Subcategory('Cookware')
/// @Summary('A proper cup of coffee is made in a proper copper coffee pot.')
/// class CopperCoffeePot {
///   // ...code...
/// }
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [Subcategory], to help place the class in a subcategory index.
///  * [Summary], which is used to provide a one-line description of a
///    class that overrides the inline documentations' own description.
class Category {
  /// Create an annotation to provide a categorization of a class.
  const Category(this.value) : assert(value != null);

  /// The string that corresponds to the category represented by this object.
  ///
  /// The allowed values are defined by the team that owns the library to which
  /// the annotated class belongs.
  final String value;
}

/// A subcategory with which to annotate a class, for documentation purposes.
///
/// The engineering team that owns the library to which the class belongs
/// defines the categories and subcategories used for classes in that library.
///
/// A class can have multiple subcategories.
///
/// {@tool sample}
///
/// ```dart
/// /// ...documentation...
/// @Category('Pots')
/// @Subcategory('Coffee')
/// class FrenchPress {
///   // ...code...
/// }
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [Category], to help place the class in a subcategory index.
///  * [Summary], which is used to provide a one-line description of a
///    class that overrides the inline documentations' own description.
class Subcategory {
  /// Create an annotation to provide a subcategory of a class.
  const Subcategory(this.value);

  /// The string that corresponds to the subcategory represented by this object.
  ///
  /// The allowed values are defined by the team that owns the library to which
  /// the annotated class belongs.
  final String value;
}

/// A class annotation to provide a URL to an image that represents the class.
///
/// Each class should only have one [DocumentationIcon].
///
/// {@tool sample}
///
/// ```dart
/// /// Utility class for beginning a dream-sharing sequence.
/// /// ...documentation...
/// @Category('Military Technology')
/// @Subcategory('Experimental')
/// @DocumentationIcon('https://docs.example.org/icons/top.png')
/// class DreamSharing {
///   // ...code...
/// }
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [Category], to help place the class in an index.
///  * [Subcategory], to help place the class in a subcategory index.
///  * [Summary], which is used to provide a one-line description of a
///    class that overrides the inline documentations' own description.
class DocumentationIcon {
  /// Create an annotation to provide a URL to an image describing a class.
  const DocumentationIcon(this.url) : assert(url != null);

  /// The URL to an image that represents the annotated class.
  final String url;
}

/// An annotation that provides a short description of a class for use in an
/// index.
///
/// Usually the first paragraph of the documentation for a class can be used for
/// this purpose, but on occasion the first paragraph is either too short or too
/// long for use in isolation, without the remainder of the documentation.
///
/// {@tool sample}
///
/// ```dart
/// /// A famous cat.
/// ///
/// /// Instances of this class can hunt small animals.
/// /// This cat has three legs.
/// @Category('Animals')
/// @Subcategory('Cute')
/// @Summary('A famous three-legged cat.')
/// class Pillar extends Cat {
///   // ...code...
/// }
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [Category], to help place the class in an index.
///  * [Subcategory], to help place the class in a subcategory index.
class Summary {
  /// Create an annotation to provide a short description of a class.
  const Summary(this.text) : assert(text != null);

  /// The text of the summary of the annotated class.
  final String text;
}
