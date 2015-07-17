/* include/wsockcompat.h
 * Windows -> Berkeley Sockets compatibility things.
 */

#if !defined __XML_WSOCKCOMPAT_H__
#define __XML_WSOCKCOMPAT_H__

#ifdef _WIN32_WCE
#include <winsock.h>
#else
#undef HAVE_ERRNO_H
#include <winsock2.h>

/* the following is a workaround a problem for 'inline' keyword in said
   header when compiled with Borland C++ 6 */
#if defined(__BORLANDC__) && !defined(__cplusplus)
#define inline __inline
#define _inline __inline
#endif

#include <ws2tcpip.h>

/* Check if ws2tcpip.h is a recent version which provides getaddrinfo() */
#if defined(GetAddrInfo)
#include <wspiapi.h>
#define HAVE_GETADDRINFO
#endif
#endif

#if defined( __MINGW32__ ) || defined( _MSC_VER )
/* Include <errno.h> here to ensure that it doesn't get included later
 * (e.g. by iconv.h) and overwrites the definition of EWOULDBLOCK. */
#include <errno.h>
#undef EWOULDBLOCK
#endif

#if !defined SOCKLEN_T
#define SOCKLEN_T int
#endif

#define EWOULDBLOCK             WSAEWOULDBLOCK
#define ESHUTDOWN               WSAESHUTDOWN

#if (!defined(_MSC_VER) || (_MSC_VER < 1600))
#define EINPROGRESS             WSAEINPROGRESS
#define EALREADY                WSAEALREADY
#define ENOTSOCK                WSAENOTSOCK
#define EDESTADDRREQ            WSAEDESTADDRREQ
#define EMSGSIZE                WSAEMSGSIZE
#define EPROTOTYPE              WSAEPROTOTYPE
#define ENOPROTOOPT             WSAENOPROTOOPT
#define EPROTONOSUPPORT         WSAEPROTONOSUPPORT
#define ESOCKTNOSUPPORT         WSAESOCKTNOSUPPORT
#define EOPNOTSUPP              WSAEOPNOTSUPP
#define EPFNOSUPPORT            WSAEPFNOSUPPORT
#define EAFNOSUPPORT            WSAEAFNOSUPPORT
#define EADDRINUSE              WSAEADDRINUSE
#define EADDRNOTAVAIL           WSAEADDRNOTAVAIL
#define ENETDOWN                WSAENETDOWN
#define ENETUNREACH             WSAENETUNREACH
#define ENETRESET               WSAENETRESET
#define ECONNABORTED            WSAECONNABORTED
#define ECONNRESET              WSAECONNRESET
#define ENOBUFS                 WSAENOBUFS
#define EISCONN                 WSAEISCONN
#define ENOTCONN                WSAENOTCONN
#define ETOOMANYREFS            WSAETOOMANYREFS
#define ETIMEDOUT               WSAETIMEDOUT
#define ECONNREFUSED            WSAECONNREFUSED
#define ELOOP                   WSAELOOP
#define EHOSTDOWN               WSAEHOSTDOWN
#define EHOSTUNREACH            WSAEHOSTUNREACH
#define EPROCLIM                WSAEPROCLIM
#define EUSERS                  WSAEUSERS
#define EDQUOT                  WSAEDQUOT
#define ESTALE                  WSAESTALE
#define EREMOTE                 WSAEREMOTE
/* These cause conflicts with the codes from errno.h. Since they are 
   not used in the relevant code (nanoftp, nanohttp), we can leave 
   them disabled.
#define ENAMETOOLONG            WSAENAMETOOLONG
#define ENOTEMPTY               WSAENOTEMPTY
*/
#endif /* _MSC_VER */

#endif /* __XML_WSOCKCOMPAT_H__ */
