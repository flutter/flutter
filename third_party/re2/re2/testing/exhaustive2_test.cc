// Copyright 2008 The RE2 Authors.  All Rights Reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// Exhaustive testing of regular expression matching.

#include "util/test.h"
#include "re2/re2.h"
#include "re2/testing/exhaustive_tester.h"

DECLARE_string(regexp_engines);

namespace re2 {

// Test empty string matches (aka "(?:)")
TEST(EmptyString, Exhaustive) {
  ExhaustiveTest(2, 2, Split(" ", "(?:) a"),
                 RegexpGenerator::EgrepOps(),
                 5, Split("", "ab"), "", "");
}

// Test escaped versions of regexp syntax.
TEST(Punctuation, Literals) {
  vector<string> alphabet = Explode("()*+?{}[]\\^$.");
  vector<string> escaped = alphabet;
  for (int i = 0; i < escaped.size(); i++)
    escaped[i] = "\\" + escaped[i];
  ExhaustiveTest(1, 1, escaped, RegexpGenerator::EgrepOps(),
                 2, alphabet, "", "");
}

// Test ^ $ . \A \z in presence of line endings.
// Have to wrap the empty-width ones in (?:) so that
// they can be repeated -- PCRE rejects ^* but allows (?:^)*
TEST(LineEnds, Exhaustive) {
  ExhaustiveTest(2, 2, Split(" ", "(?:^) (?:$) . a \\n (?:\\A) (?:\\z)"),
                 RegexpGenerator::EgrepOps(),
                 4, Explode("ab\n"), "", "");
}

// Test what does and does not match \n.
// This would be a good test, except that PCRE seems to have a bug:
// in single-byte character set mode (the default),
// [^a] matches \n, but in UTF-8 mode it does not.
// So when we run the test, the tester complains that
// we don't agree with PCRE, but it's PCRE that is at fault.
// For what it's worth, Perl gets this right (matches
// regardless of whether UTF-8 input is selected):
//
//     #!/usr/bin/perl
//     use POSIX qw(locale_h);
//     print "matches in latin1\n" if "\n" =~ /[^a]/;
//     setlocale("en_US.utf8");
//     print "matches in utf8\n" if "\n" =~ /[^a]/;
//
// The rule chosen for RE2 is that by default, like Perl,
// dot does not match \n but negated character classes [^a] do.
// (?s) will allow dot to match \n; there is no way in RE2
// to stop [^a] from matching \n, though the underlying library
// provides a mechanism, and RE2 could add new syntax if needed.
//
// TEST(Newlines, Exhaustive) {
//   vector<string> empty_vector;
//   ExhaustiveTest(1, 1, Split(" ", "\\n . a [^a]"),
//                  RegexpGenerator::EgrepOps(),
//                  4, Explode("a\n"), "");
// }

}  // namespace re2

