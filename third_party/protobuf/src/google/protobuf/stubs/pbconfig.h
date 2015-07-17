/* Modified for Chromium to support stlport and libc++ adaptively */
/* protobuf config.h for MSVC.  On other platforms, this is generated
 * automatically by autoheader / autoconf / configure. */

// NOTE: if you add new macros in this file manually, please propagate the macro
// to vsprojects/config.h.

/* the namespace of hash_map/hash_set */
// Apparently Microsoft decided to move hash_map *back* to the std namespace
// in MSVC 2010:
//   http://blogs.msdn.com/vcblog/archive/2009/05/25/stl-breaking-changes-in-visual-studio-2010-beta-1.aspx
// And.. they are moved back to stdext in MSVC 2013 (haven't checked 2012). That
// said, use unordered_map for MSVC 2010 and beyond is our safest bet.
#if _MSC_VER >= 1600
#define GOOGLE_PROTOBUF_HASH_NAMESPACE std
#define GOOGLE_PROTOBUF_HASH_MAP_H <unordered_map>
#define GOOGLE_PROTOBUF_HASH_MAP_CLASS unordered_map
#define GOOGLE_PROTOBUF_HASH_SET_H <unordered_set>
#define GOOGLE_PROTOBUF_HASH_SET_CLASS unordered_set
#elif _MSC_VER >= 1310
#define GOOGLE_PROTOBUF_HASH_NAMESPACE stdext
#define GOOGLE_PROTOBUF_HASH_MAP_H <hash_map>
#define GOOGLE_PROTOBUF_HASH_MAP_CLASS hash_map
#define GOOGLE_PROTOBUF_HASH_SET_H <hash_set>
#define GOOGLE_PROTOBUF_HASH_SET_CLASS hash_set
#else
/* the name of <hash_map> */
#if defined(_LIBCPP_VERSION)
#define GOOGLE_PROTOBUF_HASH_MAP_CLASS unordered_map
#else
#define GOOGLE_PROTOBUF_HASH_MAP_CLASS hash_map
#endif

/* the location of <unordered_map> or <hash_map> */
#if defined(USE_STLPORT)
#define GOOGLE_PROTOBUF_HASH_MAP_H <hash_map>
#elif defined(_LIBCPP_VERSION)
#define GOOGLE_PROTOBUF_HASH_MAP_H <unordered_map>
#else
#define GOOGLE_PROTOBUF_HASH_MAP_H <ext/hash_map>
#endif

/* the namespace of hash_map/hash_set */
#if defined(USE_STLPORT) || defined(_LIBCPP_VERSION)
#define GOOGLE_PROTOBUF_HASH_NAMESPACE std
#else
#define GOOGLE_PROTOBUF_HASH_NAMESPACE __gnu_cxx
#endif

/* the name of <hash_set> */
#if defined(_LIBCPP_VERSION)
#define GOOGLE_PROTOBUF_HASH_SET_CLASS unordered_set
#else
#define GOOGLE_PROTOBUF_HASH_SET_CLASS hash_set
#endif

/* the location of <unordered_set> or <hash_set> */
#if defined(USE_STLPORT)
#define GOOGLE_PROTOBUF_HASH_SET_H <hash_set>
#elif defined(_LIBCPP_VERSION)
#define GOOGLE_PROTOBUF_HASH_SET_H <unordered_set>
#else
#define GOOGLE_PROTOBUF_HASH_SET_H <ext/hash_set>
#endif

#endif  // _MSC_VER >= 1600

/* the location of <hash_set> */

/* define if the compiler has hash_map */
#define GOOGLE_PROTOBUF_HAVE_HASH_MAP 1

/* define if the compiler has hash_set */
#define GOOGLE_PROTOBUF_HAVE_HASH_SET 1
