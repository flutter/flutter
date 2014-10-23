# Copyright (C) 2010 Chris Jerdonek (chris.jerdonek@gmail.com)
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1.  Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
# 2.  Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS'' AND ANY
# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

"""Contains filter-related code."""


def validate_filter_rules(filter_rules, all_categories):
    """Validate the given filter rules, and raise a ValueError if not valid.

    Args:
      filter_rules: A list of boolean filter rules, for example--
                    ["-whitespace", "+whitespace/braces"]
      all_categories: A list of all available category names, for example--
                      ["whitespace/tabs", "whitespace/braces"]

    Raises:
      ValueError: An error occurs if a filter rule does not begin
                  with "+" or "-" or if a filter rule does not match
                  the beginning of some category name in the list
                  of all available categories.

    """
    for rule in filter_rules:
        if not (rule.startswith('+') or rule.startswith('-')):
            raise ValueError('Invalid filter rule "%s": every rule '
                             "must start with + or -." % rule)

        for category in all_categories:
            if category.startswith(rule[1:]):
                break
        else:
            raise ValueError('Suspected incorrect filter rule "%s": '
                             "the rule does not match the beginning "
                             "of any category name." % rule)


class _CategoryFilter(object):

    """Filters whether to check style categories."""

    def __init__(self, filter_rules=None):
        """Create a category filter.

        Args:
          filter_rules: A list of strings that are filter rules, which
                        are strings beginning with the plus or minus
                        symbol (+/-).  The list should include any
                        default filter rules at the beginning.
                        Defaults to the empty list.

        Raises:
          ValueError: Invalid filter rule if a rule does not start with
                      plus ("+") or minus ("-").

        """
        if filter_rules is None:
            filter_rules = []

        self._filter_rules = filter_rules
        self._should_check_category = {} # Cached dictionary of category to True/False

    def __str__(self):
        return ",".join(self._filter_rules)

    # Useful for unit testing.
    def __eq__(self, other):
        """Return whether this CategoryFilter instance is equal to another."""
        return self._filter_rules == other._filter_rules

    # Useful for unit testing.
    def __ne__(self, other):
        # Python does not automatically deduce from __eq__().
        return not (self == other)

    def should_check(self, category):
        """Return whether the category should be checked.

        The rules for determining whether a category should be checked
        are as follows.  By default all categories should be checked.
        Then apply the filter rules in order from first to last, with
        later flags taking precedence.

        A filter rule applies to a category if the string after the
        leading plus/minus (+/-) matches the beginning of the category
        name.  A plus (+) means the category should be checked, while a
        minus (-) means the category should not be checked.

        """
        if category in self._should_check_category:
            return self._should_check_category[category]

        should_check = True # All categories checked by default.
        for rule in self._filter_rules:
            if not category.startswith(rule[1:]):
                continue
            should_check = rule.startswith('+')
        self._should_check_category[category] = should_check # Update cache.
        return should_check


class FilterConfiguration(object):

    """Supports filtering with path-specific and user-specified rules."""

    def __init__(self, base_rules=None, path_specific=None, user_rules=None):
        """Create a FilterConfiguration instance.

        Args:
          base_rules: The starting list of filter rules to use for
                      processing.  The default is the empty list, which
                      by itself would mean that all categories should be
                      checked.

          path_specific: A list of (sub_paths, path_rules) pairs
                         that stores the path-specific filter rules for
                         appending to the base rules.
                             The "sub_paths" value is a list of path
                         substrings.  If a file path contains one of the
                         substrings, then the corresponding path rules
                         are appended.  The first substring match takes
                         precedence, i.e. only the first match triggers
                         an append.
                             The "path_rules" value is a list of filter
                         rules that can be appended to the base rules.

          user_rules: A list of filter rules that is always appended
                      to the base rules and any path rules.  In other
                      words, the user rules take precedence over the
                      everything.  In practice, the user rules are
                      provided by the user from the command line.

        """
        if base_rules is None:
            base_rules = []
        if path_specific is None:
            path_specific = []
        if user_rules is None:
            user_rules = []

        self._base_rules = base_rules
        self._path_specific = path_specific
        self._path_specific_lower = None
        """The backing store for self._get_path_specific_lower()."""

        self._user_rules = user_rules

        self._path_rules_to_filter = {}
        """Cached dictionary of path rules to CategoryFilter instance."""

        # The same CategoryFilter instance can be shared across
        # multiple keys in this dictionary.  This allows us to take
        # greater advantage of the caching done by
        # CategoryFilter.should_check().
        self._path_to_filter = {}
        """Cached dictionary of file path to CategoryFilter instance."""

    # Useful for unit testing.
    def __eq__(self, other):
        """Return whether this FilterConfiguration is equal to another."""
        if self._base_rules != other._base_rules:
            return False
        if self._path_specific != other._path_specific:
            return False
        if self._user_rules != other._user_rules:
            return False

        return True

    # Useful for unit testing.
    def __ne__(self, other):
        # Python does not automatically deduce this from __eq__().
        return not self.__eq__(other)

    # We use the prefix "_get" since the name "_path_specific_lower"
    # is already taken up by the data attribute backing store.
    def _get_path_specific_lower(self):
        """Return a copy of self._path_specific with the paths lower-cased."""
        if self._path_specific_lower is None:
            self._path_specific_lower = []
            for (sub_paths, path_rules) in self._path_specific:
                sub_paths = map(str.lower, sub_paths)
                self._path_specific_lower.append((sub_paths, path_rules))
        return self._path_specific_lower

    def _path_rules_from_path(self, path):
        """Determine the path-specific rules to use, and return as a tuple.

         This method returns a tuple rather than a list so the return
         value can be passed to _filter_from_path_rules() without change.

        """
        path = path.lower()
        for (sub_paths, path_rules) in self._get_path_specific_lower():
            for sub_path in sub_paths:
                if path.find(sub_path) > -1:
                    return tuple(path_rules)
        return () # Default to the empty tuple.

    def _filter_from_path_rules(self, path_rules):
        """Return the CategoryFilter associated to the given path rules.

        Args:
          path_rules: A tuple of path rules.  We require a tuple rather
                      than a list so the value can be used as a dictionary
                      key in self._path_rules_to_filter.

        """
        # We reuse the same CategoryFilter where possible to take
        # advantage of the caching they do.
        if path_rules not in self._path_rules_to_filter:
            rules = list(self._base_rules) # Make a copy
            rules.extend(path_rules)
            rules.extend(self._user_rules)
            self._path_rules_to_filter[path_rules] = _CategoryFilter(rules)

        return self._path_rules_to_filter[path_rules]

    def _filter_from_path(self, path):
        """Return the CategoryFilter associated to a path."""
        if path not in self._path_to_filter:
            path_rules = self._path_rules_from_path(path)
            filter = self._filter_from_path_rules(path_rules)
            self._path_to_filter[path] = filter

        return self._path_to_filter[path]

    def should_check(self, category, path):
        """Return whether the given category should be checked.

        This method determines whether a category should be checked
        by checking the category name against the filter rules for
        the given path.

        For a given path, the filter rules are the combination of
        the base rules, the path-specific rules, and the user-provided
        rules -- in that order.  As we will describe below, later rules
        in the list take precedence.  The path-specific rules are the
        rules corresponding to the first element of the "path_specific"
        parameter that contains a string case-insensitively matching
        some substring of the path.  If there is no such element,
        there are no path-specific rules for that path.

        Given a list of filter rules, the logic for determining whether
        a category should be checked is as follows.  By default all
        categories should be checked.  Then apply the filter rules in
        order from first to last, with later flags taking precedence.

        A filter rule applies to a category if the string after the
        leading plus/minus (+/-) matches the beginning of the category
        name.  A plus (+) means the category should be checked, while a
        minus (-) means the category should not be checked.

        Args:
          category: The category name.
          path: The path of the file being checked.

        """
        return self._filter_from_path(path).should_check(category)

