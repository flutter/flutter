The Independent JPEG Group's JPEG software
==========================================

README for release 6b of 27-Mar-1998
====================================

This distribution contains the sixth public release of the Independent JPEG
Group's free JPEG software.  You are welcome to redistribute this software and
to use it for any purpose, subject to the conditions under LEGAL ISSUES, below.

Serious users of this software (particularly those incorporating it into
larger programs) should contact IJG at jpeg-info@uunet.uu.net to be added to
our electronic mailing list.  Mailing list members are notified of updates
and have a chance to participate in technical discussions, etc.

This software is the work of Tom Lane, Philip Gladstone, Jim Boucher,
Lee Crocker, Julian Minguillon, Luis Ortiz, George Phillips, Davide Rossi,
Guido Vollbeding, Ge' Weijers, and other members of the Independent JPEG
Group.

IJG is not affiliated with the official ISO JPEG standards committee.


DOCUMENTATION ROADMAP
=====================

This file contains the following sections:

OVERVIEW            General description of JPEG and the IJG software.
LEGAL ISSUES        Copyright, lack of warranty, terms of distribution.
REFERENCES          Where to learn more about JPEG.
ARCHIVE LOCATIONS   Where to find newer versions of this software.
RELATED SOFTWARE    Other stuff you should get.
FILE FORMAT WARS    Software *not* to get.
TO DO               Plans for future IJG releases.

Other documentation files in the distribution are:

User documentation:
  install.doc       How to configure and install the IJG software.
  usage.doc         Usage instructions for cjpeg, djpeg, jpegtran,
                    rdjpgcom, and wrjpgcom.
  *.1               Unix-style man pages for programs (same info as usage.doc).
  wizard.doc        Advanced usage instructions for JPEG wizards only.
  change.log        Version-to-version change highlights.
Programmer and internal documentation:
  libjpeg.doc       How to use the JPEG library in your own programs.
  example.c         Sample code for calling the JPEG library.
  structure.doc     Overview of the JPEG library's internal structure.
  filelist.doc      Road map of IJG files.
  coderules.doc     Coding style rules --- please read if you contribute code.

Please read at least the files install.doc and usage.doc.  Useful information
can also be found in the JPEG FAQ (Frequently Asked Questions) article.  See
ARCHIVE LOCATIONS below to find out where to obtain the FAQ article.

If you want to understand how the JPEG code works, we suggest reading one or
more of the REFERENCES, then looking at the documentation files (in roughly
the order listed) before diving into the code.


OVERVIEW
========

This package contains C software to implement JPEG image compression and
decompression.  JPEG (pronounced "jay-peg") is a standardized compression
method for full-color and gray-scale images.  JPEG is intended for compressing
"real-world" scenes; line drawings, cartoons and other non-realistic images
are not its strong suit.  JPEG is lossy, meaning that the output image is not
exactly identical to the input image.  Hence you must not use JPEG if you
have to have identical output bits.  However, on typical photographic images,
very good compression levels can be obtained with no visible change, and
remarkably high compression levels are possible if you can tolerate a
low-quality image.  For more details, see the references, or just experiment
with various compression settings.

This software implements JPEG baseline, extended-sequential, and progressive
compression processes.  Provision is made for supporting all variants of these
processes, although some uncommon parameter settings aren't implemented yet.
For legal reasons, we are not distributing code for the arithmetic-coding
variants of JPEG; see LEGAL ISSUES.  We have made no provision for supporting
the hierarchical or lossless processes defined in the standard.

We provide a set of library routines for reading and writing JPEG image files,
plus two sample applications "cjpeg" and "djpeg", which use the library to
perform conversion between JPEG and some other popular image file formats.
The library is intended to be reused in other applications.

In order to support file conversion and viewing software, we have included
considerable functionality beyond the bare JPEG coding/decoding capability;
for example, the color quantization modules are not strictly part of JPEG
decoding, but they are essential for output to colormapped file formats or
colormapped displays.  These extra functions can be compiled out of the
library if not required for a particular application.  We have also included
"jpegtran", a utility for lossless transcoding between different JPEG
processes, and "rdjpgcom" and "wrjpgcom", two simple applications for
inserting and extracting textual comments in JFIF files.

The emphasis in designing this software has been on achieving portability and
flexibility, while also making it fast enough to be useful.  In particular,
the software is not intended to be read as a tutorial on JPEG.  (See the
REFERENCES section for introductory material.)  Rather, it is intended to
be reliable, portable, industrial-strength code.  We do not claim to have
achieved that goal in every aspect of the software, but we strive for it.

We welcome the use of this software as a component of commercial products.
No royalty is required, but we do ask for an acknowledgement in product
documentation, as described under LEGAL ISSUES.


LEGAL ISSUES
============

In plain English:

1. We don't promise that this software works.  (But if you find any bugs,
   please let us know!)
2. You can use this software for whatever you want.  You don't have to pay us.
3. You may not pretend that you wrote this software.  If you use it in a
   program, you must acknowledge somewhere in your documentation that
   you've used the IJG code.

In legalese:

The authors make NO WARRANTY or representation, either express or implied,
with respect to this software, its quality, accuracy, merchantability, or
fitness for a particular purpose.  This software is provided "AS IS", and you,
its user, assume the entire risk as to its quality and accuracy.

This software is copyright (C) 1991-1998, Thomas G. Lane.
All Rights Reserved except as specified below.

Permission is hereby granted to use, copy, modify, and distribute this
software (or portions thereof) for any purpose, without fee, subject to these
conditions:
(1) If any part of the source code for this software is distributed, then this
README file must be included, with this copyright and no-warranty notice
unaltered; and any additions, deletions, or changes to the original files
must be clearly indicated in accompanying documentation.
(2) If only executable code is distributed, then the accompanying
documentation must state that "this software is based in part on the work of
the Independent JPEG Group".
(3) Permission for use of this software is granted only if the user accepts
full responsibility for any undesirable consequences; the authors accept
NO LIABILITY for damages of any kind.

These conditions apply to any software derived from or based on the IJG code,
not just to the unmodified library.  If you use our work, you ought to
acknowledge us.

Permission is NOT granted for the use of any IJG author's name or company name
in advertising or publicity relating to this software or products derived from
it.  This software may be referred to only as "the Independent JPEG Group's
software".

We specifically permit and encourage the use of this software as the basis of
commercial products, provided that all warranty or liability claims are
assumed by the product vendor.


ansi2knr.c is included in this distribution by permission of L. Peter Deutsch,
sole proprietor of its copyright holder, Aladdin Enterprises of Menlo Park, CA.
ansi2knr.c is NOT covered by the above copyright and conditions, but instead
by the usual distribution terms of the Free Software Foundation; principally,
that you must include source code if you redistribute it.  (See the file
ansi2knr.c for full details.)  However, since ansi2knr.c is not needed as part
of any program generated from the IJG code, this does not limit you more than
the foregoing paragraphs do.

The Unix configuration script "configure" was produced with GNU Autoconf.
It is copyright by the Free Software Foundation but is freely distributable.
The same holds for its supporting scripts (config.guess, config.sub,
ltconfig, ltmain.sh).  Another support script, install-sh, is copyright
by M.I.T. but is also freely distributable.

It appears that the arithmetic coding option of the JPEG spec is covered by
patents owned by IBM, AT&T, and Mitsubishi.  Hence arithmetic coding cannot
legally be used without obtaining one or more licenses.  For this reason,
support for arithmetic coding has been removed from the free JPEG software.
(Since arithmetic coding provides only a marginal gain over the unpatented
Huffman mode, it is unlikely that very many implementations will support it.)
So far as we are aware, there are no patent restrictions on the remaining
code.

The IJG distribution formerly included code to read and write GIF files.
To avoid entanglement with the Unisys LZW patent, GIF reading support has
been removed altogether, and the GIF writer has been simplified to produce
"uncompressed GIFs".  This technique does not use the LZW algorithm; the
resulting GIF files are larger than usual, but are readable by all standard
GIF decoders.

We are required to state that
    "The Graphics Interchange Format(c) is the Copyright property of
    CompuServe Incorporated.  GIF(sm) is a Service Mark property of
    CompuServe Incorporated."


REFERENCES
==========

We highly recommend reading one or more of these references before trying to
understand the innards of the JPEG software.

The best short technical introduction to the JPEG compression algorithm is
	Wallace, Gregory K.  "The JPEG Still Picture Compression Standard",
	Communications of the ACM, April 1991 (vol. 34 no. 4), pp. 30-44.
(Adjacent articles in that issue discuss MPEG motion picture compression,
applications of JPEG, and related topics.)  If you don't have the CACM issue
handy, a PostScript file containing a revised version of Wallace's article is
available at ftp://ftp.uu.net/graphics/jpeg/wallace.ps.gz.  The file (actually
a preprint for an article that appeared in IEEE Trans. Consumer Electronics)
omits the sample images that appeared in CACM, but it includes corrections
and some added material.  Note: the Wallace article is copyright ACM and IEEE,
and it may not be used for commercial purposes.

A somewhat less technical, more leisurely introduction to JPEG can be found in
"The Data Compression Book" by Mark Nelson and Jean-loup Gailly, published by
M&T Books (New York), 2nd ed. 1996, ISBN 1-55851-434-1.  This book provides
good explanations and example C code for a multitude of compression methods
including JPEG.  It is an excellent source if you are comfortable reading C
code but don't know much about data compression in general.  The book's JPEG
sample code is far from industrial-strength, but when you are ready to look
at a full implementation, you've got one here...

The best full description of JPEG is the textbook "JPEG Still Image Data
Compression Standard" by William B. Pennebaker and Joan L. Mitchell, published
by Van Nostrand Reinhold, 1993, ISBN 0-442-01272-1.  Price US$59.95, 638 pp.
The book includes the complete text of the ISO JPEG standards (DIS 10918-1
and draft DIS 10918-2).  This is by far the most complete exposition of JPEG
in existence, and we highly recommend it.

The JPEG standard itself is not available electronically; you must order a
paper copy through ISO or ITU.  (Unless you feel a need to own a certified
official copy, we recommend buying the Pennebaker and Mitchell book instead;
it's much cheaper and includes a great deal of useful explanatory material.)
In the USA, copies of the standard may be ordered from ANSI Sales at (212)
642-4900, or from Global Engineering Documents at (800) 854-7179.  (ANSI
doesn't take credit card orders, but Global does.)  It's not cheap: as of
1992, ANSI was charging $95 for Part 1 and $47 for Part 2, plus 7%
shipping/handling.  The standard is divided into two parts, Part 1 being the
actual specification, while Part 2 covers compliance testing methods.  Part 1
is titled "Digital Compression and Coding of Continuous-tone Still Images,
Part 1: Requirements and guidelines" and has document numbers ISO/IEC IS
10918-1, ITU-T T.81.  Part 2 is titled "Digital Compression and Coding of
Continuous-tone Still Images, Part 2: Compliance testing" and has document
numbers ISO/IEC IS 10918-2, ITU-T T.83.

Some extensions to the original JPEG standard are defined in JPEG Part 3,
a newer ISO standard numbered ISO/IEC IS 10918-3 and ITU-T T.84.  IJG
currently does not support any Part 3 extensions.

The JPEG standard does not specify all details of an interchangeable file
format.  For the omitted details we follow the "JFIF" conventions, revision
1.02.  A copy of the JFIF spec is available from:
	Literature Department
	C-Cube Microsystems, Inc.
	1778 McCarthy Blvd.
	Milpitas, CA 95035
	phone (408) 944-6300,  fax (408) 944-6314
A PostScript version of this document is available by FTP at
ftp://ftp.uu.net/graphics/jpeg/jfif.ps.gz.  There is also a plain text
version at ftp://ftp.uu.net/graphics/jpeg/jfif.txt.gz, but it is missing
the figures.

The TIFF 6.0 file format specification can be obtained by FTP from
ftp://ftp.sgi.com/graphics/tiff/TIFF6.ps.gz.  The JPEG incorporation scheme
found in the TIFF 6.0 spec of 3-June-92 has a number of serious problems.
IJG does not recommend use of the TIFF 6.0 design (TIFF Compression tag 6).
Instead, we recommend the JPEG design proposed by TIFF Technical Note #2
(Compression tag 7).  Copies of this Note can be obtained from ftp.sgi.com or
from ftp://ftp.uu.net/graphics/jpeg/.  It is expected that the next revision
of the TIFF spec will replace the 6.0 JPEG design with the Note's design.
Although IJG's own code does not support TIFF/JPEG, the free libtiff library
uses our library to implement TIFF/JPEG per the Note.  libtiff is available
from ftp://ftp.sgi.com/graphics/tiff/.


ARCHIVE LOCATIONS
=================

The "official" archive site for this software is ftp.uu.net (Internet
address 192.48.96.9).  The most recent released version can always be found
there in directory graphics/jpeg.  This particular version will be archived
as ftp://ftp.uu.net/graphics/jpeg/jpegsrc.v6b.tar.gz.  If you don't have
direct Internet access, UUNET's archives are also available via UUCP; contact
help@uunet.uu.net for information on retrieving files that way.

Numerous Internet sites maintain copies of the UUNET files.  However, only
ftp.uu.net is guaranteed to have the latest official version.

You can also obtain this software in DOS-compatible "zip" archive format from
the SimTel archives (ftp://ftp.simtel.net/pub/simtelnet/msdos/graphics/), or
on CompuServe in the Graphics Support forum (GO CIS:GRAPHSUP), library 12
"JPEG Tools".  Again, these versions may sometimes lag behind the ftp.uu.net
release.

The JPEG FAQ (Frequently Asked Questions) article is a useful source of
general information about JPEG.  It is updated constantly and therefore is
not included in this distribution.  The FAQ is posted every two weeks to
Usenet newsgroups comp.graphics.misc, news.answers, and other groups.
It is available on the World Wide Web at http://www.faqs.org/faqs/jpeg-faq/
and other news.answers archive sites, including the official news.answers
archive at rtfm.mit.edu: ftp://rtfm.mit.edu/pub/usenet/news.answers/jpeg-faq/.
If you don't have Web or FTP access, send e-mail to mail-server@rtfm.mit.edu
with body
	send usenet/news.answers/jpeg-faq/part1
	send usenet/news.answers/jpeg-faq/part2


RELATED SOFTWARE
================

Numerous viewing and image manipulation programs now support JPEG.  (Quite a
few of them use this library to do so.)  The JPEG FAQ described above lists
some of the more popular free and shareware viewers, and tells where to
obtain them on Internet.

If you are on a Unix machine, we highly recommend Jef Poskanzer's free
PBMPLUS software, which provides many useful operations on PPM-format image
files.  In particular, it can convert PPM images to and from a wide range of
other formats, thus making cjpeg/djpeg considerably more useful.  The latest
version is distributed by the NetPBM group, and is available from numerous
sites, notably ftp://wuarchive.wustl.edu/graphics/graphics/packages/NetPBM/.
Unfortunately PBMPLUS/NETPBM is not nearly as portable as the IJG software is;
you are likely to have difficulty making it work on any non-Unix machine.

A different free JPEG implementation, written by the PVRG group at Stanford,
is available from ftp://havefun.stanford.edu/pub/jpeg/.  This program
is designed for research and experimentation rather than production use;
it is slower, harder to use, and less portable than the IJG code, but it
is easier to read and modify.  Also, the PVRG code supports lossless JPEG,
which we do not.  (On the other hand, it doesn't do progressive JPEG.)


FILE FORMAT WARS
================

Some JPEG programs produce files that are not compatible with our library.
The root of the problem is that the ISO JPEG committee failed to specify a
concrete file format.  Some vendors "filled in the blanks" on their own,
creating proprietary formats that no one else could read.  (For example, none
of the early commercial JPEG implementations for the Macintosh were able to
exchange compressed files.)

The file format we have adopted is called JFIF (see REFERENCES).  This format
has been agreed to by a number of major commercial JPEG vendors, and it has
become the de facto standard.  JFIF is a minimal or "low end" representation.
We recommend the use of TIFF/JPEG (TIFF revision 6.0 as modified by TIFF
Technical Note #2) for "high end" applications that need to record a lot of
additional data about an image.  TIFF/JPEG is fairly new and not yet widely
supported, unfortunately.

The upcoming JPEG Part 3 standard defines a file format called SPIFF.
SPIFF is interoperable with JFIF, in the sense that most JFIF decoders should
be able to read the most common variant of SPIFF.  SPIFF has some technical
advantages over JFIF, but its major claim to fame is simply that it is an
official standard rather than an informal one.  At this point it is unclear
whether SPIFF will supersede JFIF or whether JFIF will remain the de-facto
standard.  IJG intends to support SPIFF once the standard is frozen, but we
have not decided whether it should become our default output format or not.
(In any case, our decoder will remain capable of reading JFIF indefinitely.)

Various proprietary file formats incorporating JPEG compression also exist.
We have little or no sympathy for the existence of these formats.  Indeed,
one of the original reasons for developing this free software was to help
force convergence on common, open format standards for JPEG files.  Don't
use a proprietary file format!


TO DO
=====

The major thrust for v7 will probably be improvement of visual quality.
The current method for scaling the quantization tables is known not to be
very good at low Q values.  We also intend to investigate block boundary
smoothing, "poor man's variable quantization", and other means of improving
quality-vs-file-size performance without sacrificing compatibility.

In future versions, we are considering supporting some of the upcoming JPEG
Part 3 extensions --- principally, variable quantization and the SPIFF file
format.

As always, speeding things up is of great interest.

Please send bug reports, offers of help, etc. to jpeg-info@uunet.uu.net.
