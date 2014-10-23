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

"""Unit tests for filter.py."""

import unittest

from filter import _CategoryFilter as CategoryFilter
from filter import validate_filter_rules
from filter import FilterConfiguration

# On Testing __eq__() and __ne__():
#
# In the tests below, we deliberately do not use assertEqual() or
# assertNotEquals() to test __eq__() or __ne__().  We do this to be
# very explicit about what we are testing, especially in the case
# of assertNotEquals().
#
# Part of the reason is that it is not immediately clear what
# expression the unittest module uses to assert "not equals" -- the
# negation of __eq__() or __ne__(), which are not necessarily
# equivalent expresions in Python.  For example, from Python's "Data
# Model" documentation--
#
#   "There are no implied relationships among the comparison
#    operators. The truth of x==y does not imply that x!=y is
#    false.  Accordingly, when defining __eq__(), one should
#    also define __ne__() so that the operators will behave as
#    expected."
#
#   (from http://docs.python.org/reference/datamodel.html#object.__ne__ )

class ValidateFilterRulesTest(unittest.TestCase):

    """Tests validate_filter_rules() function."""

    def test_validate_filter_rules(self):
        all_categories = ["tabs", "whitespace", "build/include"]

        bad_rules = [
            "tabs",
            "*tabs",
            " tabs",
            " +tabs",
            "+whitespace/newline",
            "+xxx",
            ]

        good_rules = [
            "+tabs",
            "-tabs",
            "+build"
            ]

        for rule in bad_rules:
            self.assertRaises(ValueError, validate_filter_rules,
                              [rule], all_categories)

        for rule in good_rules:
            # This works: no error.
            validate_filter_rules([rule], all_categories)


class CategoryFilterTest(unittest.TestCase):

    """Tests CategoryFilter class."""

    def test_init(self):
        """Test __init__ method."""
        # Test that the attributes are getting set correctly.
        filter = CategoryFilter(["+"])
        self.assertEqual(["+"], filter._filter_rules)

    def test_init_default_arguments(self):
        """Test __init__ method default arguments."""
        filter = CategoryFilter()
        self.assertEqual([], filter._filter_rules)

    def test_str(self):
        """Test __str__ "to string" operator."""
        filter = CategoryFilter(["+a", "-b"])
        self.assertEqual(str(filter), "+a,-b")

    def test_eq(self):
        """Test __eq__ equality function."""
        filter1 = CategoryFilter(["+a", "+b"])
        filter2 = CategoryFilter(["+a", "+b"])
        filter3 = CategoryFilter(["+b", "+a"])

        # See the notes at the top of this module about testing
        # __eq__() and __ne__().
        self.assertTrue(filter1.__eq__(filter2))
        self.assertFalse(filter1.__eq__(filter3))

    def test_ne(self):
        """Test __ne__ inequality function."""
        # By default, __ne__ always returns true on different objects.
        # Thus, just check the distinguishing case to verify that the
        # code defines __ne__.
        #
        # Also, see the notes at the top of this module about testing
        # __eq__() and __ne__().
        self.assertFalse(CategoryFilter().__ne__(CategoryFilter()))

    def test_should_check(self):
        """Test should_check() method."""
        filter = CategoryFilter()
        self.assertTrue(filter.should_check("everything"))
        # Check a second time to exercise cache.
        self.assertTrue(filter.should_check("everything"))

        filter = CategoryFilter(["-"])
        self.assertFalse(filter.should_check("anything"))
        # Check a second time to exercise cache.
        self.assertFalse(filter.should_check("anything"))

        filter = CategoryFilter(["-", "+ab"])
        self.assertTrue(filter.should_check("abc"))
        self.assertFalse(filter.should_check("a"))

        filter = CategoryFilter(["+", "-ab"])
        self.assertFalse(filter.should_check("abc"))
        self.assertTrue(filter.should_check("a"))


class FilterConfigurationTest(unittest.TestCase):

    """Tests FilterConfiguration class."""

    def _config(self, base_rules, path_specific, user_rules):
        """Return a FilterConfiguration instance."""
        return FilterConfiguration(base_rules=base_rules,
                                   path_specific=path_specific,
                                   user_rules=user_rules)

    def test_init(self):
        """Test __init__ method."""
        # Test that the attributes are getting set correctly.
        # We use parameter values that are different from the defaults.
        base_rules = ["-"]
        path_specific = [(["path"], ["+a"])]
        user_rules = ["+"]

        config = self._config(base_rules, path_specific, user_rules)

        self.assertEqual(base_rules, config._base_rules)
        self.assertEqual(path_specific, config._path_specific)
        self.assertEqual(user_rules, config._user_rules)

    def test_default_arguments(self):
        # Test that the attributes are getting set correctly to the defaults.
        config = FilterConfiguration()

        self.assertEqual([], config._base_rules)
        self.assertEqual([], config._path_specific)
        self.assertEqual([], config._user_rules)

    def test_eq(self):
        """Test __eq__ method."""
        # See the notes at the top of this module about testing
        # __eq__() and __ne__().
        self.assertTrue(FilterConfiguration().__eq__(FilterConfiguration()))

        # Verify that a difference in any argument causes equality to fail.
        config = FilterConfiguration()

        # These parameter values are different from the defaults.
        base_rules = ["-"]
        path_specific = [(["path"], ["+a"])]
        user_rules = ["+"]

        self.assertFalse(config.__eq__(FilterConfiguration(
                                           base_rules=base_rules)))
        self.assertFalse(config.__eq__(FilterConfiguration(
                                           path_specific=path_specific)))
        self.assertFalse(config.__eq__(FilterConfiguration(
                                           user_rules=user_rules)))

    def test_ne(self):
        """Test __ne__ method."""
        # By default, __ne__ always returns true on different objects.
        # Thus, just check the distinguishing case to verify that the
        # code defines __ne__.
        #
        # Also, see the notes at the top of this module about testing
        # __eq__() and __ne__().
        self.assertFalse(FilterConfiguration().__ne__(FilterConfiguration()))

    def test_base_rules(self):
        """Test effect of base_rules on should_check()."""
        base_rules = ["-b"]
        path_specific = []
        user_rules = []

        config = self._config(base_rules, path_specific, user_rules)

        self.assertTrue(config.should_check("a", "path"))
        self.assertFalse(config.should_check("b", "path"))

    def test_path_specific(self):
        """Test effect of path_rules_specifier on should_check()."""
        base_rules = ["-"]
        path_specific = [(["path1"], ["+b"]),
                         (["path2"], ["+c"])]
        user_rules = []

        config = self._config(base_rules, path_specific, user_rules)

        self.assertFalse(config.should_check("c", "path1"))
        self.assertTrue(config.should_check("c", "path2"))
        # Test that first match takes precedence.
        self.assertFalse(config.should_check("c", "path2/path1"))

    def test_path_with_different_case(self):
        """Test a path that differs only in case."""
        base_rules = ["-"]
        path_specific = [(["Foo/"], ["+whitespace"])]
        user_rules = []

        config = self._config(base_rules, path_specific, user_rules)

        self.assertFalse(config.should_check("whitespace", "Fooo/bar.txt"))
        self.assertTrue(config.should_check("whitespace", "Foo/bar.txt"))
        # Test different case.
        self.assertTrue(config.should_check("whitespace", "FOO/bar.txt"))

    def test_user_rules(self):
        """Test effect of user_rules on should_check()."""
        base_rules = ["-"]
        path_specific = []
        user_rules = ["+b"]

        config = self._config(base_rules, path_specific, user_rules)

        self.assertFalse(config.should_check("a", "path"))
        self.assertTrue(config.should_check("b", "path"))

