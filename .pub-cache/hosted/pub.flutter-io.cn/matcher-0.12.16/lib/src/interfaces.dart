// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Matchers build up their error messages by appending to Description objects.
///
/// This interface is implemented by StringDescription.
///
/// This interface is unlikely to need other implementations, but could be
/// useful to replace in some cases - e.g. language conversion.
abstract class Description {
  int get length;

  /// Change the value of the description.
  Description replace(String text);

  /// This is used to add arbitrary text to the description.
  Description add(String text);

  /// This is used to add a meaningful description of a value.
  Description addDescriptionOf(Object? value);

  /// This is used to add a description of an [Iterable] [list],
  /// with appropriate [start] and [end] markers and inter-element [separator].
  Description addAll(String start, String separator, String end, Iterable list);
}

/// The base class for all matchers.
///
/// [matches] and [describe] must be implemented by subclasses.
///
/// Subclasses can override [describeMismatch] if a more specific description is
/// required when the matcher fails.
abstract class Matcher {
  const Matcher();

  /// Does the matching of the actual vs expected values.
  ///
  /// [item] is the actual value. [matchState] can be supplied
  /// and may be used to add details about the mismatch that are too
  /// costly to determine in [describeMismatch].
  bool matches(dynamic item, Map matchState);

  /// Builds a textual description of the matcher.
  Description describe(Description description);

  /// Builds a textual description of a specific mismatch.
  ///
  /// [item] is the value that was tested by [matches]; [matchState] is
  /// the [Map] that was passed to and supplemented by [matches]
  /// with additional information about the mismatch, and [mismatchDescription]
  /// is the [Description] that is being built to describe the mismatch.
  ///
  /// A few matchers make use of the [verbose] flag to provide detailed
  /// information that is not typically included but can be of help in
  /// diagnosing failures, such as stack traces.
  Description describeMismatch(dynamic item, Description mismatchDescription,
          Map matchState, bool verbose) =>
      mismatchDescription;
}
