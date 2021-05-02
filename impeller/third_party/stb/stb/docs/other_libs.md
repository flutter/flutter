# Other single-file public-domain/open source libraries with minimal dependencies

In addition to all of [my libraries](https://github.com/nothings/stb), there are other, similar libraries.

The following is a list of small, easy-to-integrate, portable libraries
which are usable from C and/or C++, and should be able to be compiled on both
32-bit and 64-bit platforms.

### Rules

- Libraries must be usable from C or C++, ideally both
- Libraries should be usable from more than one platform (ideally, all major desktops and/or all major mobile)
- Libraries should compile and work on both 32-bit and 64-bit platforms
- Libraries should use at most two files

Exceptions will be allowed for good reasons.

### New libraries and corrections

See discussion after the list.

## Library listing

**Public domain single-file libraries usable from C and C++ are in bold.** Other
libraries are either non-public domain, or two files, or not usable from both C and C++, or
all three. Libraries of more than two files are mostly forbidden.

For the API column, "C" means C only, "C++" means C++ only, and "C/C++" means C/C++ usable
from either; some files may require *building* as C or C++ but still qualify as "C/C++" as
long as the header file uses `extern "C"` to make it work. (In some cases, a header-file-only
library may compile as both C or C++, but produce an implementation that can only be called from
one or the other, because of a lack of use of `extern "C"`; in this case the table still qualifies it
as C/C++, as this is not an obstacle to most users.)


category          | library                                                               | license              | API |files| description
----------------- | --------------------------------------------------------------------- |:--------------------:|:---:|:---:| -----------
AI                |  [micropather](http://www.grinninglizard.com/MicroPather/)            | zlib                 | C++ |  2  | pathfinding with A*
argv              |  [parg](https://github.com/jibsen/parg)                               | **public domain**    |  C  |  1  | argv parsing
audio             |  [aw_ima.h](https://github.com/afterwise/aw-ima/blob/master/aw-ima.h) | MIT                  |C/C++|**1**| IMA-ADPCM audio decoder
audio             |**[dr_flac](https://github.com/mackron/dr_libs)**                      |  **public domain**   |C/C++|**1**| FLAC audio decoder
compression       |**[miniz.c](https://github.com/richgel999/miniz)**                     |**public&nbsp;domain**|C/C++|**1**| compression,decompression, zip file, png writing
compression       |  [lz4](https://github.com/Cyan4973/lz4)                               | BSD                  |C/C++|  2  | fast but larger LZ compression
compression       |  [fastlz](https://code.google.com/archive/p/fastlz/source/default/source) | MIT                  |C/C++|  2  | fast but larger LZ compression
compression       |  [pithy](https://github.com/johnezang/pithy)                          | BSD                  |C/C++|  2  | fast but larger LZ compression
crypto            |  [TweetNaCl](http://tweetnacl.cr.yp.to/software.html)                 | **public domain**    |  C  |  2  | high-quality tiny cryptography library
data&nbsp;structures|[klib](http://attractivechaos.github.io/klib/)                       | MIT                  |C/C++|  2  | many 2-file libs: hash, sort, b-tree, etc
data structures   |  [uthash](https://github.com/troydhanson/uthash)                      | BSD                  |C/C++|  2  | several 1-header, 1-license-file libs: generic hash, list, etc
data structures   |  [PackedArray](https://github.com/gpakosz/PackedArray)                | **WTFPLv2**          |  C  |  2  | memory-efficient array of elements with non-pow2 bitcount
data structures   |  [minilibs](https://github.com/ccxvii/minilibs)                       | **public domain**    |  C  |  2  | two-file binary tress (also regex, etc)
files & filenames |**[DG_misc.h](https://github.com/DanielGibson/Snippets/)**             | **public domain**    |C/C++|**1**| Daniel Gibson's stb.h-esque cross-platform helpers: path/file, strings
files & filenames |  [whereami](https://github.com/gpakosz/whereami)                      |**WTFPLv2**           |C/C++|  2  | get path/filename of executable or module
files & filenames |  [noc_file_dialog.h](https://github.com/guillaumechereau/noc)         | MIT                  |C/C++|  1  | file open/save dialogs (Linux/OSX/Windows)
files & filenames |  [dirent](https://github.com/tronkko/dirent)                          | MIT                  |C/C++|**1**| dirent for windows: retrieve file & dir info
files & filenames |  [TinyDir](https://github.com/cxong/tinydir)                          | BSD                  |  C  |**1**| cross-platform directory reader
geometry file     |  [tk_objfile](https://github.com/joeld42/tk_objfile)                  | MIT                  |C/C++|**1**| OBJ file loader
geometry file     |  [tinyply](https://github.com/ddiakopoulos/tinyply)                   | **public domain**    | C++ |  2  | PLY mesh file loader
geometry file     |  [tinyobjloader](https://github.com/syoyo/tinyobjloader)              | BSD                  | C++ |**1**| wavefront OBJ file loader
geometry math     |**[nv_voronoi.h](http://www.icculus.org/~mordred/nvlib/)**             | **public domain**    |C/C++|**1**| find voronoi regions on lattice w/ integer inputs
geometry math     |**[sobol.h](https://github.com/Marc-B-Reynolds/Stand-alone-junk/)**    | **public domain**    |C/C++|**1**| sobol & stratified sampling sequences
geometry math     |  [sdf.h](https://github.com/memononen/SDF)                            | MIT                  |C/C++|**1**| compute signed-distance field from antialiased image
geometry math     |  [nanoflann](https://github.com/jlblancoc/nanoflann)                  | BSD                  | C++ |**1**| build KD trees for point clouds
geometry math     |  [jc_voronoi](https://github.com/JCash/voronoi)                       | MIT                  |C/C++|**1**| find voronoi regions on float/double data
geometry math     |  [par_msquares](https://github.com/prideout/par)                      | MIT                  |C/C++|**1**| convert (binarized) image to triangles
geometry math     |  [par_shapes](http://github.prideout.net/shapes)                      | MIT                  |C/C++|**1**| generate various 3d geometric shapes
geometry math     |  [Tomas Akenine-Moller snippets](http://tinyurl.com/ht79ndj)          | **public domain**    |C/C++|  2  | various 3D intersection calculations, not lib-ified
geometry math     |  [Clipper](http://www.angusj.com/delphi/clipper.php)                  | Boost                | C++ |  2  | line & polygon clipping & offsetting
geometry math     |  [PolyPartition](https://github.com/ivanfratric/polypartition)        | MIT                  | C++ |  2  | polygon triangulation, partitioning
geometry math     |  [Voxelizer](https://github.com/karimnaaji/voxelizer)                 | MIT                  |C/C++|**1**| convert triangle mesh to voxel triangle mesh
graphics (2d)     |  [blendish](https://bitbucket.org/duangle/oui-blendish/src)           | MIT                  |C/C++|**1**| blender-style widget rendering
graphics (2d)     |  [tigr](https://bitbucket.org/rmitton/tigr/src)                       | **public domain**    |C/C++|  2  | quick-n-dirty window text/graphics for Windows
graphics (2d)     |  [noc_turtle](https://github.com/guillaumechereau/noc)                | MIT                  |C/C++|  2  | procedural graphics generator
graphics (3-D)    |  [mikktspace](http://tinyurl.com/z6xtucm)                             | zlib                 |C/C++|  2  | compute tangent space for normal mapping
graphics (3-D)    |  [debug-draw](https://github.com/glampert/debug-draw)                 | **public domain**    | C++ |**1**| API-agnostic immediate-mode debug rendering
hardware          |**[EasyTab](https://github.com/ApoorvaJ/EasyTab)**                     | **public domain**    |C/C++|**1**| multi-platform tablet input
images            |  [jo_gif.cpp](http://www.jonolick.com/home/gif-writer)                | **public domain**    | C++ |**1**| animated GIF writer (CPP file can also be used as H file)
images            |**[gif.h](https://github.com/ginsweater/gif-h)**                       | **public domain**    |  C  |**1**| animated GIF writer (can only include once)
images            |**[tiny_jpeg.h](https://github.com/serge-rgb/TinyJPEG/)**              | **public domain**    |C/C++|**1**| JPEG encoder
images            |  [miniexr](https://github.com/aras-p/miniexr)                         | **public domain**    | C++ | 2  | OpenEXR writer, needs header file
images            |  [tinyexr](https://github.com/syoyo/tinyexr)                          | BSD                  |C/C++|**1**| EXR image read/write, uses miniz internally  
images            |  [lodepng](http://lodev.org/lodepng/)                                 | zlib                 |C/C++|  2  | PNG encoder/decoder
images            |  [nanoSVG](https://github.com/memononen/nanosvg)                      | zlib                 |C/C++|**1**| 1-file SVG parser; 1-file SVG rasterizer
images            |  [picopng.cpp](http://lodev.org/lodepng/picopng.cpp)                  | zlib                 | C++ |  2  | tiny PNG loader
images            |  [jpeg-compressor](https://github.com/richgel999/jpeg-compressor)     | **public domain**    | C++ |  2  | 2-file jpeg compress, 2-file jpeg decompress
images            |  [easyexif](https://github.com/mayanklahiri/easyexif)                 | MIT                  | C++ |  2  | EXIF metadata extractor for JPEG images
images            |**[cro_mipmap.h](https://github.com/thebeast33/cro_lib)**              | **public domain**    |C/C++|**1**| average, min, max mipmap generators
math              |  [mm_vec.h](https://github.com/vurtun/mmx)                            | BSD                  |C/C++|**1**| SIMD vector math
math              |  [ShaderFastLibs](https://github.com/michaldrobot/ShaderFastLibs)     | MIT                  | C++ |**1**| (also HLSL) approximate transcendental functions optimized for shaders (esp. GCN)
math              |  [TinyExpr](https://github.com/codeplea/tinyexpr)                     | zlib                 |  C  |  2  | evaluation of math expressions from strings
math              |  [linalg.h](https://github.com/sgorsten/linalg)                      | **unlicense**        | C++ |**1**| vector/matrix/quaternion math
math              |  [PoissonGenerator.h](https://github.com/corporateshark/poisson-disk-generator)     | MIT                  | C++ |**1**| Poisson disk points generator (disk or rect)
multithreading    |  [mm_sched.h](https://github.com/vurtun/mmx)                          | zlib                 |C/C++|**1**| cross-platform multithreaded task scheduler
network           |**[zed_net](https://github.com/ZedZull/zed_net)**                      | **public domain**    |C/C++|**1**| cross-platform socket wrapper
network           |  [mm_web.h](https://github.com/vurtun/mmx)                            | BSD                  |C/C++|**1**| lightweight webserver, fork of webby
network           |  [par_easycurl.h](https://github.com/prideout/par)                    | MIT                  |C/C++|**1**| curl wrapper
network           |  [yocto](https://github.com/tom-seddon/yhs)                           | **public domain**    |C/C++|  2  | non-production-use http server
network           |  [happyhttp](http://scumways.com/happyhttp/happyhttp.html)            | zlib                 | C++ |  2  | http client requests
network           |  [mongoose](https://github.com/cesanta/mongoose)                      |_GPLv2_               |C/C++|  2  | http server
network           |  [LUrlParser](https://github.com/corporateshark/LUrlParser)           | MIT                  | C++ |  2  | lightweight URL & URI parser RFC 1738, RFC 3986
parsing           |  [SLRE](https://github.com/cesanta/slre)                              |_GPLv2_               |C/C++|**1**| regular expression matcher
parsing           |  [PicoJSON](https://github.com/kazuho/picojson)                       | BSD                  | C++ |**1**| JSON parse/serializer
parsing           |  [mm_lexer.h](https://github.com/vurtun/mmx)                          | zlib                 |C/C++|**1**| C-esque language lexer
parsing           |  [json.h](https://github.com/sheredom/json.h)                         | **public domain**    |C/C++|  2  | JSON parser
parsing           |  [jzon.h](https://github.com/Zguy/Jzon)                               | MIT                  | C++ |  2  | JSON parser
parsing           |  [parson](https://github.com/kgabis/parson)                           | MIT                  |C/C++|  2  | JSON parser and serializer
parsing           |  [minilibs](https://github.com/ccxvii/minilibs)                       | **public domain**    |  C  |  2  | two-file regex (also binary tree, etc)
profiling         |  [Remotery](https://github.com/Celtoys/Remotery)                      | Apache 2.0           |C/C++|  2  | CPU/GPU profiler Win/Mac/Linux, using web browser for viewer
profiling         |  [MicroProfile](https://bitbucket.org/jonasmeyer/microprofile)        | **unlicense**        | C++ | 2-4 | CPU (and GPU?) profiler, 1-3 header files, uses miniz internally
scripting         |  [LIL](http://runtimelegend.com/rep/lil/)                             | zlib                 |C/C++|  2  | interpreter for a Tcl-like scripting language
scripting         |  [lualite](https://github.com/janezz55/lualite/)                      | MIT                  | C++ |**1**| generate lua bindings in C++
scripting         |  [Picol](https://chiselapp.com/user/dbohdan/repository/picol/)        | BSD                  |C/C++|**1**| interpreter for a Tcl-like scripting language
strings           |**[DG_misc.h](https://github.com/DanielGibson/Snippets/)**             | **public domain**    |C/C++|**1**| Daniel Gibson's stb.h-esque cross-platform helpers: path/file, strings         
strings           |**[utf8](https://github.com/sheredom/utf8.h)**                         | **public domain**    |C/C++|**1**| utf8 string library
strings           |**[strpool.h](https://github.com/mattiasgustavsson/libs)**             | **public domain**    |C/C++|**1**| string interning
strings           |  [dfa](http://bjoern.hoehrmann.de/utf-8/decoder/dfa/)                 | MIT                  |C/C++|  2  | fast utf8 decoder (need a header file)
strings           |**[gb_string.h](https://github.com/gingerBill/gb)**                    | **public domain**    |C/C++|**1**| dynamic strings
tests             |  [utest](https://github.com/evolutional/utest)                        | MIT                  |C/C++|**1**| unit testing
tests             |  [catch](https://github.com/philsquared/Catch)                        | Boost                | C++ |**1**| unit testing
tests             |  [SPUT](http://www.lingua-systems.com/unit-testing/)                  | BSD                  |C/C++|**1**| unit testing
tests             |  [pempek_assert.cpp](https://github.com/gpakosz/Assert)               | **WTFPLv2**          | C++ |  2  | flexible assertions
tests             |  [minctest](https://github.com/codeplea/minctest)                     | zlib                 |  C  |**1**| unit testing
tests             |  [greatest](https://github.com/silentbicycle/greatest)                | iSC                  |  C  |**1**| unit testing
tests             |  [µnit](https://github.com/nemequ/munit)                              | MIT                  |  C  |**1**| unit testing
user interface    |  [dear imgui](https://github.com/ocornut/imgui)                       | MIT                  | C++*|  9  | an immediate-mode GUI formerly named "ImGui"; [3rd-party C wrapper](https://github.com/Extrawurst/cimgui) 
_misc_            |  [MakeID.h](http://www.humus.name/3D/MakeID.h)                        | **public domain**    | C++ |**1**| allocate/deallocate small integer IDs efficiently
_misc_            |  [loguru](https://github.com/emilk/loguru)                            | **public domain**    | C++ |**1**| flexible logging
_misc_            |  [tinyformat](https://github.com/c42f/tinyformat)                     | Boost                | C++ |**1**| typesafe printf
_misc_            |  [dbgtools](https://github.com/wc-duck/dbgtools)                      | zlib                 |C/C++|  2  | cross-platform debug util libraries
_misc_            |  [stmr](https://github.com/wooorm/stmr.c)                             | MIT                  |  C  |  2  | extract English word stems
_misc_            |  [levenshtein](https://github.com/wooorm/levenshtein.c)               | MIT                  |  C  |  2  | compute edit distance between two strings
                                                                                                                       
There are also these XML libraries, but if you're using XML, shame on you:                                             
                                                                                                                       
- parsing: [tinyxml2](https://github.com/leethomason/tinyxml2): XML                                                    
- parsing: [pugixml](http://pugixml.org/): XML (MIT license)

Also you might be interested in other related, but different lists:

- [clib](https://github.com/clibs/clib/wiki/Packages): list of (mostly) small single C functions (licenses not listed)

## New libraries and corrections

Submissions of new libraries: I accept submissions (as issues or as pull requests). Please
note that every file that must be included in a user's project counts; a header and a source
file is 2 files, but a header file, source file, and LICENSE (if the license isn't in the
source file) is 3 files, and won't be accepted, because it's not 2 files. But actually
'LICENSE' is a problem for just dropping the library in a source tree anyway, since it's
not scoped to just the library, so library authors are encouraged to include the license in the
source file and not require a separate LICENSE.

Corrections: if information for a library above is wrong, please send a correction as an
issue, pull request, or email. Note that if the list indicates a library works from both
C/C++, but it doesn't, this could be an error in the list or it could be a bug in the
library. If you find a library doesn't work in 32-bit or 64-bit, the library should be
removed from this list, unless it's a bug in the library.

## *List FAQ*

### Can I link directly to this list?

Yes, you can just use this page. If you want a shorter, more readable link, you can use [this URL](https://github.com/nothings/stb#other_libs) to link to the FAQ question that links to this page.

### Why isn't library XXX which is made of 3 or more files on this list?

I draw the line arbitrarily at 2 files at most. (Note that some libraries that appear to
be two files require a separate LICENSE file, which made me leave them out). Some of these
libraries are still easy to drop into your project and build, so you might still be ok with them.
But since people come to stb for single-file public domain libraries, I feel that starts
to get too far from what we do here.

### Why isn't library XXX which is at most two files and has minimal other dependencies on this list?

Probably because I don't know about it, feel free to submit a pull request, issue, email, or tweet it at
me (it can be your own library or somebody else's). But I might not include it for various
other reasons, including subtleties of what is 'minimal other dependencies' and subtleties
about what is 'lightweight'.

### Why isn't SQLite's amalgamated build on this list?

Come on.

