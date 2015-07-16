What's OTS?
===========

Sanitiser for OpenType (OTS) is a small library which parses OpenType files
(usually from `@font-face`) and attempts to validate and sanitise them. This
library is primarily intended to be used with Chromium. We hope this reduces
the attack surface of the system font libraries.

What the sanitiser does is as follows:

1. Parses an original font. If the parsing fails, OTS rejects the original
   font.
2. Validates the parsed data structure. If the validation fails, it rejects the
   original font as well.
3. Creates a new font on memory by serializing the data structure, and we call
   this "transcoding".

By transcoding fonts in this way, it is ensured that:

1. All information in an original font that OTS doesn't know or can't parse is
   dropped from the transcoded font.
2. All information in the transcoded font is valid (standard compliant).
   Particularly 'length' and 'offset' values, that are often used as attack
   vectors, are ensured to be correct.

Supported OpenType tables
=========================

| Name   | Mandatory table?            | Supported by OTS? | Note   |
|--------|-----------------------------|-------------------|--------|
| `sfnt` | Yes                         | Yes               | Overlapped tables are not allowed; it is treated as a fatal parser error.|
| `maxp` | Yes                         | Yes               |        |
| `head` | Yes                         | Yes               |        |
| `hhea` | Yes                         | Yes               |        |
| `hmtx` | Yes                         | Yes               |        |
| `name` | Yes                         | Yes               |        |
| `OS/2` | Yes                         | Yes               |        |
| `post` | Yes                         | Yes               |        |
| `cmap` | Yes                         | Partialy          | see below |
| `glyf` | Yes, for TrueType fonts     | Yes               | TrueType bytecode is supported, but OTS does **not** validate it.|
| `loca` | Yes, when glyf table exists | Yes               |        |
| `CFF ` | Yes, for OpenType fonts     | Yes               | OpenType bytecode is also supported, and OTS **does** validate it.|
| `cvt ` | No                          | Yes               | Though this table is not mandatory, OTS can't drop the table from a transcoded font since it might be referred from other hinting-related tables. Errors on this table should be treated as fatal.|
| `fpgm` | No                          | Yes               | Ditto. |
| `prep` | No                          | Yes               | Ditto. |
| `VDMX` | No                          | Yes               | This table is important for calculating the correct line spacing, at least on Chromium Windows and Chromium Linux.|
| `hdmx` | No                          | Yes               |        |
| `gasp` | No                          | Yes               |        |
| `VORG` | No                          | Yes               |        |
| `LTSH` | No                          | Yes               |        |
| `kern` | No                          | Yes               |        |
| `GDEF` | No                          | Yes               |        |
| `GSUB` | No                          | Yes               |        |
| `GPOS` | No                          | Yes               |        |
| `morx` | No                          | No                |        |
| `jstf` | No                          | No                |        |
| `vmtx` | No                          | Yes               |        |
| `vhea` | No                          | Yes               |        |
| `EBDT` | No                          | No                | We don't support embedded bitmap strikes.|
| `EBLC` | No                          | No                | Ditto. |
| `EBSC` | No                          | No                | Ditto. |
| `bdat` | No                          | No                | Ditto. |
| `bhed` | No                          | No                | Ditto. |
| `bloc` | No                          | No                | Ditto. |
| `DSIG` | No                          | No                |        |
| All other tables | -                 | No                |        |

Please note that OTS library does not parse "unsupported" tables. These
unsupported tables never appear in a transcoded font.

Supported cmap formats
----------------------

The following 9 formats are supported:

* "MS Unicode" (platform 3 encoding 1 format 4)
    * BMP
* "MS UCS-4" (platform 3 encoding 10 format 12)
* "MS UCS-4 fallback" (platform 3 encoding 10 format 13)
* "MS Symbol" (platform 3 encoding 0 format 4)
* "Mac Roman" (platform 1 encoding 0 format 0)
    * 1-0-0 format is supported while 1-0-6 is not.
* "Unicode default" format (platform 0 encoding 0 format 4)
    * treated as 3-1-4 format
* "Unicode 1.1" format (platform 0 encoding 1 format 4)
    * ditto
* "Unicode 2.0+" format (platform 0 encoding 3 format 4)
* "Unicode UCS-4" format (platform 0 encoding 4 format 12)
    * treated as 3-10-12 format
* Unicode Variation Sequences (platform 0 encoding 5 format 14)

All other types of subtables are not supported and do not appear in transcoded fonts.

Validation strategies
=====================

With regards to 8 mandatory tables, glyph-related tables (`glyf`, `loca` and `CFF`),
and hinting-related tables (`cvt`, `prep`, and `fpgm`):

* If OTS finds table-length, table-offset, or table-alignment errors, in other
  words it cannot continue parsing, OTS treats the error as fatal.
* If OTS finds simple value error which could be automatically fixed (e.g.,
  font weight is greater than 900 - that's undefined), and if the error is
  considered common among non-malicious fonts, OTS rewrites the value and
  continues transcoding.
* If OTS finds a value error which is hard to fix (e.g., values which should be
  sorted are left unsorted), OTS treats the error as fatal.

With regards to optional tables (`VORG`, `gasp`, `hdmx`, `LTSH`, and `VDMX`):

* If OTS finds table-length, table-offset, or table-alignment errors, OTS
  treats the error as fatal.
* If OTS finds other errors, it simply drops the table from a transcoded font.

Files
=====

* include/opentype-sanitiser.h
    * Declaration for the public API, `ots::Process()`.
    * Definition of the `OTSStream` interface, a write-only memory stream.
* include/ots-memory-stream.h
    * Definition of the `MemoryStream` class which implements the `OTSStream`
      interface above.
* src/ots.h
    * Debug macros.
    * Definition of a `Buffer` class which is a read-only memory stream.
* src/ots.cc
    * Definition of the `ots::Process()` function.
    * `sfnt` table parser.
* test/\*.cc
    * test tools. see test/README for details.

Known issues
============

Please check the [issues](https://github.com/khaledhosny/ots/issues) page.
