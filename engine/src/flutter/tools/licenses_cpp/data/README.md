# Licenses_cpp data directory

This directory contains all the data that the licenses_cpp executable needs to
validate the engine repository.  There are 3 main divisions of this data:

- include.txt -- A list of all the files that will be checked.
- exclude.txt -- A list of all the files that will be excluded.
- data/ -- A catalog of all the accepted and known licenses.
- secondary/ -- Secondary licenses to be included.

All regex are in the [re2 format](https://github.com/google/re2/wiki/syntax).

## include.txt

The file format for the include.txt is a list of regular expressions that
describe the files that should be considered for checking.  Each regex is
required to be a **full match** to be considered.

Lines prefixed with `#` will be treated as comments. Comments trailing `#` on
lines that start with other characters are not yet supported.

## exclude.txt

The exclude file format is in the same format as the include.txt.  It's important
to note that the regex's must be full matches on the relative paths to the
"--working_dir" path.

## data/

Each file in the `data/` directory represents an accepted license which can
show up in source code or in its own LICENSE file.  The format is the following:

1) First line - name of the matcher
2) Second line - Unique regex which cannot overlap with other matcher's unique
   regexes.
3) Remaining lines - Matcher regex that will be used to extract the full text
   of the accepted license.  The regexes have the following properties:
   - All whitespace is considered `\s+`.
   - Trailing whitespace is ignored.
   - Matched groups are extracted from the output.  Example:
     `match("\[(.*)\]", "[hi]") -> "[]"`.

## secondary/

This directory structure needs to match the one found in the working directory.
License files here will be added verbatim to the output.
