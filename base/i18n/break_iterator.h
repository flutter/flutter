// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_I18N_BREAK_ITERATOR_H_
#define BASE_I18N_BREAK_ITERATOR_H_

#include "base/basictypes.h"
#include "base/i18n/base_i18n_export.h"
#include "base/strings/string16.h"
#include "base/strings/string_piece.h"

// The BreakIterator class iterates through the words, word breaks, and
// line breaks in a UTF-16 string.
//
// It provides several modes, BREAK_WORD, BREAK_LINE, and BREAK_NEWLINE,
// which modify how characters are aggregated into the returned string.
//
// Under BREAK_WORD mode, once a word is encountered any non-word
// characters are not included in the returned string (e.g. in the
// UTF-16 equivalent of the string " foo bar! ", the word breaks are at
// the periods in ". .foo. .bar.!. .").
// Note that Chinese/Japanese/Thai do not use spaces between words so that
// boundaries can fall in the middle of a continuous run of non-space /
// non-punctuation characters.
//
// Under BREAK_LINE mode, once a line breaking opportunity is encountered,
// any non-word  characters are included in the returned string, breaking
// only when a space-equivalent character or a line breaking opportunity
// is encountered (e.g. in the UTF16-equivalent of the string " foo bar! ",
// the breaks are at the periods in ". .foo .bar! .").
//
// Note that lines can be broken at any character/syllable/grapheme cluster
// boundary in Chinese/Japanese/Korean and at word boundaries in Thai
// (Thai does not use spaces between words). Therefore, this is NOT the same
// as breaking only at space-equivalent characters where its former
// name (BREAK_SPACE) implied.
//
// Under BREAK_NEWLINE mode, all characters are included in the returned
// string, breaking only when a newline-equivalent character is encountered
// (eg. in the UTF-16 equivalent of the string "foo\nbar!\n\n", the line
// breaks are at the periods in ".foo\n.bar\n.\n.").
//
// To extract the words from a string, move a BREAK_WORD BreakIterator
// through the string and test whether IsWord() is true. E.g.,
//   BreakIterator iter(str, BreakIterator::BREAK_WORD);
//   if (!iter.Init())
//     return false;
//   while (iter.Advance()) {
//     if (iter.IsWord()) {
//       // Region [iter.prev(), iter.pos()) contains a word.
//       VLOG(1) << "word: " << iter.GetString();
//     }
//   }

namespace base {
namespace i18n {

class BASE_I18N_EXPORT BreakIterator {
 public:
  enum BreakType {
    BREAK_WORD,
    BREAK_LINE,
    // TODO(jshin): Remove this after reviewing call sites.
    // If call sites really need break only on space-like characters
    // implement it separately.
    BREAK_SPACE = BREAK_LINE,
    BREAK_NEWLINE,
    BREAK_CHARACTER,
    // But don't remove this one!
    RULE_BASED,
  };

  // Requires |str| to live as long as the BreakIterator does.
  BreakIterator(const StringPiece16& str, BreakType break_type);
  // Make a rule-based iterator. BreakType == RULE_BASED is implied.
  // TODO(andrewhayden): This signature could easily be misinterpreted as
  // "(const string16& str, const string16& locale)". We should do something
  // better.
  BreakIterator(const StringPiece16& str, const string16& rules);
  ~BreakIterator();

  // Init() must be called before any of the iterators are valid.
  // Returns false if ICU failed to initialize.
  bool Init();

  // Advance to the next break.  Returns false if we've run past the end of
  // the string.  (Note that the very last "break" is after the final
  // character in the string, and when we advance to that position it's the
  // last time Advance() returns true.)
  bool Advance();

  // Updates the text used by the iterator, resetting the iterator as if
  // if Init() had been called again. Any old state is lost. Returns true
  // unless there is an error setting the text.
  bool SetText(const base::char16* text, const size_t length);

  // Under BREAK_WORD mode, returns true if the break we just hit is the
  // end of a word. (Otherwise, the break iterator just skipped over e.g.
  // whitespace or punctuation.)  Under BREAK_LINE and BREAK_NEWLINE modes,
  // this distinction doesn't apply and it always returns false.
  bool IsWord() const;

  // Under BREAK_WORD mode, returns true if |position| is at the end of word or
  // at the start of word. It always returns false under BREAK_LINE and
  // BREAK_NEWLINE modes.
  bool IsEndOfWord(size_t position) const;
  bool IsStartOfWord(size_t position) const;

  // Under BREAK_CHARACTER mode, returns whether |position| is a Unicode
  // grapheme boundary.
  bool IsGraphemeBoundary(size_t position) const;

  // Returns the string between prev() and pos().
  // Advance() must have been called successfully at least once for pos() to
  // have advanced to somewhere useful.
  string16 GetString() const;

  StringPiece16 GetStringPiece() const;

  // Returns the value of pos() returned before Advance() was last called.
  size_t prev() const { return prev_; }

  // Returns the current break position within the string,
  // or BreakIterator::npos when done.
  size_t pos() const { return pos_; }

 private:
  // ICU iterator, avoiding ICU ubrk.h dependence.
  // This is actually an ICU UBreakiterator* type, which turns out to be
  // a typedef for a void* in the ICU headers. Using void* directly prevents
  // callers from needing access to the ICU public headers directory.
  void* iter_;

  // The string we're iterating over. Can be changed with SetText(...)
  StringPiece16 string_;

  // Rules for our iterator. Mutually exclusive with break_type_.
  const string16 rules_;

  // The breaking style (word/space/newline). Mutually exclusive with rules_
  BreakType break_type_;

  // Previous and current iterator positions.
  size_t prev_, pos_;

  DISALLOW_COPY_AND_ASSIGN(BreakIterator);
};

}  // namespace i18n
}  // namespace base

#endif  // BASE_I18N_BREAK_ITERATOR_H_
