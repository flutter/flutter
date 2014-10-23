# Copyright (C) 2011 Google Inc. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
#     * Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above
# copyright notice, this list of conditions and the following disclaimer
# in the documentation and/or other materials provided with the
# distribution.
#     * Neither the Google name nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import copy


class TestConfiguration(object):
    def __init__(self, version, architecture, build_type):
        self.version = version
        self.architecture = architecture
        self.build_type = build_type

    @classmethod
    def category_order(cls):
        """The most common human-readable order in which the configuration properties are listed."""
        return ['version', 'architecture', 'build_type']

    def items(self):
        return self.__dict__.items()

    def keys(self):
        return self.__dict__.keys()

    def __str__(self):
        return ("<%(version)s, %(architecture)s, %(build_type)s>" %
                self.__dict__)

    def __repr__(self):
        return "TestConfig(version='%(version)s', architecture='%(architecture)s', build_type='%(build_type)s')" % self.__dict__

    def __hash__(self):
        return hash(self.version + self.architecture + self.build_type)

    def __eq__(self, other):
        return self.__hash__() == other.__hash__()

    def values(self):
        """Returns the configuration values of this instance as a tuple."""
        return self.__dict__.values()


class SpecifierSorter(object):
    def __init__(self, all_test_configurations=None, macros=None):
        self._specifier_to_category = {}

        if not all_test_configurations:
            return
        for test_configuration in all_test_configurations:
            for category, specifier in test_configuration.items():
                self.add_specifier(category, specifier)

        self.add_macros(macros)

    def add_specifier(self, category, specifier):
        self._specifier_to_category[specifier] = category

    def add_macros(self, macros):
        if not macros:
            return
        # Assume well-formed macros.
        for macro, specifier_list in macros.items():
            self.add_specifier(self.category_for_specifier(specifier_list[0]), macro)

    @classmethod
    def category_priority(cls, category):
        return TestConfiguration.category_order().index(category)

    def specifier_priority(self, specifier):
        return self.category_priority(self._specifier_to_category[specifier])

    def category_for_specifier(self, specifier):
        return self._specifier_to_category.get(specifier)

    def sort_specifiers(self, specifiers):
        category_slots = map(lambda x: [], TestConfiguration.category_order())
        for specifier in specifiers:
            category_slots[self.specifier_priority(specifier)].append(specifier)

        def sort_and_return(result, specifier_list):
            specifier_list.sort()
            return result + specifier_list

        return reduce(sort_and_return, category_slots, [])


class TestConfigurationConverter(object):
    def __init__(self, all_test_configurations, configuration_macros=None):
        self._all_test_configurations = all_test_configurations
        self._configuration_macros = configuration_macros or {}
        self._specifier_to_configuration_set = {}
        self._specifier_sorter = SpecifierSorter()
        self._collapsing_sets_by_size = {}
        self._junk_specifier_combinations = {}
        self._collapsing_sets_by_category = {}
        matching_sets_by_category = {}
        for configuration in all_test_configurations:
            for category, specifier in configuration.items():
                self._specifier_to_configuration_set.setdefault(specifier, set()).add(configuration)
                self._specifier_sorter.add_specifier(category, specifier)
                self._collapsing_sets_by_category.setdefault(category, set()).add(specifier)
                # FIXME: This seems extra-awful.
                for cat2, spec2 in configuration.items():
                    if category == cat2:
                        continue
                    matching_sets_by_category.setdefault(specifier, {}).setdefault(cat2, set()).add(spec2)
        for collapsing_set in self._collapsing_sets_by_category.values():
            self._collapsing_sets_by_size.setdefault(len(collapsing_set), set()).add(frozenset(collapsing_set))

        for specifier, sets_by_category in matching_sets_by_category.items():
            for category, set_by_category in sets_by_category.items():
                if len(set_by_category) == 1 and self._specifier_sorter.category_priority(category) > self._specifier_sorter.specifier_priority(specifier):
                    self._junk_specifier_combinations[specifier] = set_by_category

        self._specifier_sorter.add_macros(configuration_macros)

    def specifier_sorter(self):
        return self._specifier_sorter

    def _expand_macros(self, specifier):
        expanded_specifiers = self._configuration_macros.get(specifier)
        return expanded_specifiers or [specifier]

    def to_config_set(self, specifier_set, error_list=None):
        """Convert a list of specifiers into a set of TestConfiguration instances."""
        if len(specifier_set) == 0:
            return copy.copy(self._all_test_configurations)

        matching_sets = {}

        for specifier in specifier_set:
            for expanded_specifier in self._expand_macros(specifier):
                configurations = self._specifier_to_configuration_set.get(expanded_specifier)
                if not configurations:
                    if error_list is not None:
                        error_list.append("Unrecognized specifier '" + expanded_specifier + "'")
                    return set()
                category = self._specifier_sorter.category_for_specifier(expanded_specifier)
                matching_sets.setdefault(category, set()).update(configurations)

        return reduce(set.intersection, matching_sets.values())

    @classmethod
    def collapse_macros(cls, macros_dict, specifiers_list):
        for macro_specifier, macro in macros_dict.items():
            if len(macro) == 1:
                continue

            for combination in cls.combinations(specifiers_list, len(macro)):
                if cls.symmetric_difference(combination) == set(macro):
                    for item in combination:
                        specifiers_list.remove(item)
                    new_specifier_set = cls.intersect_combination(combination)
                    new_specifier_set.add(macro_specifier)
                    specifiers_list.append(frozenset(new_specifier_set))

        def collapse_individual_specifier_set(macro_specifier, macro):
            specifiers_to_remove = []
            specifiers_to_add = []
            for specifier_set in specifiers_list:
                macro_set = set(macro)
                if macro_set.intersection(specifier_set) == macro_set:
                    specifiers_to_remove.append(specifier_set)
                    specifiers_to_add.append(frozenset((set(specifier_set) - macro_set) | set([macro_specifier])))
            for specifier in specifiers_to_remove:
                specifiers_list.remove(specifier)
            for specifier in specifiers_to_add:
                specifiers_list.append(specifier)

        for macro_specifier, macro in macros_dict.items():
            collapse_individual_specifier_set(macro_specifier, macro)

    # FIXME: itertools.combinations in buggy in Python 2.6.1 (the version that ships on SL).
    # It seems to be okay in 2.6.5 or later; until then, this is the implementation given
    # in http://docs.python.org/library/itertools.html (from 2.7).
    @staticmethod
    def combinations(iterable, r):
        # combinations('ABCD', 2) --> AB AC AD BC BD CD
        # combinations(range(4), 3) --> 012 013 023 123
        pool = tuple(iterable)
        n = len(pool)
        if r > n:
            return
        indices = range(r)
        yield tuple(pool[i] for i in indices)
        while True:
            for i in reversed(range(r)):
                if indices[i] != i + n - r:
                    break
            else:
                return
            indices[i] += 1  # pylint: disable=W0631
            for j in range(i + 1, r):  # pylint: disable=W0631
                indices[j] = indices[j - 1] + 1
            yield tuple(pool[i] for i in indices)

    @classmethod
    def intersect_combination(cls, combination):
        return reduce(set.intersection, [set(specifiers) for specifiers in combination])

    @classmethod
    def symmetric_difference(cls, iterable):
        union = set()
        intersection = iterable[0]
        for item in iterable:
            union = union | item
            intersection = intersection.intersection(item)
        return union - intersection

    def to_specifiers_list(self, test_configuration_set):
        """Convert a set of TestConfiguration instances into one or more list of specifiers."""
        # Easy out: if the set is all configurations, the specifier is empty.
        if len(test_configuration_set) == len(self._all_test_configurations):
            return [[]]

        # 1) Build a list of specifier sets, discarding specifiers that don't add value.
        specifiers_list = []
        for config in test_configuration_set:
            values = set(config.values())
            for specifier, junk_specifier_set in self._junk_specifier_combinations.items():
                if specifier in values:
                    values -= junk_specifier_set
            specifiers_list.append(frozenset(values))

        def try_collapsing(size, collapsing_sets):
            if len(specifiers_list) < size:
                return False
            for combination in self.combinations(specifiers_list, size):
                if self.symmetric_difference(combination) in collapsing_sets:
                    for item in combination:
                        specifiers_list.remove(item)
                    specifiers_list.append(frozenset(self.intersect_combination(combination)))
                    return True
            return False

        # 2) Collapse specifier sets with common specifiers:
        #   (xp, release), (xp, debug) --> (xp, x86)
        for size, collapsing_sets in self._collapsing_sets_by_size.items():
            while try_collapsing(size, collapsing_sets):
                pass

        def try_abbreviating(collapsing_sets):
            if len(specifiers_list) < 2:
                return False
            for combination in self.combinations(specifiers_list, 2):
                for collapsing_set in collapsing_sets:
                    diff = self.symmetric_difference(combination)
                    if diff <= collapsing_set:
                        common = self.intersect_combination(combination)
                        for item in combination:
                            specifiers_list.remove(item)
                        specifiers_list.append(frozenset(common | diff))
                        return True
            return False

        # 3) Abbreviate specifier sets by combining specifiers across categories.
        #   (xp, release), (win7, release) --> (xp, win7, release)
        while try_abbreviating(self._collapsing_sets_by_size.values()):
            pass


        # 4) Substitute specifier subsets that match macros witin each set:
        #   (xp, win7, release) -> (win, release)
        self.collapse_macros(self._configuration_macros, specifiers_list)

        macro_keys = set(self._configuration_macros.keys())

        # 5) Collapsing macros may have created combinations the can now be abbreviated.
        #   (xp, release), (linux, x86, release), (linux, x86_64, release) --> (xp, release), (linux, release) --> (xp, linux, release)
        while try_abbreviating([self._collapsing_sets_by_category['version'] | macro_keys]):
            pass

        # 6) Remove cases where we have collapsed but have all macros.
        #   (android, win, mac, linux, release) --> (release)
        specifiers_to_remove = []
        for specifier_set in specifiers_list:
            if macro_keys <= specifier_set:
                specifiers_to_remove.append(specifier_set)

        for specifier_set in specifiers_to_remove:
            specifiers_list.remove(specifier_set)
            specifiers_list.append(frozenset(specifier_set - macro_keys))

        return specifiers_list
