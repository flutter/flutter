/* Copied from Linux version and changed the features according Android, which
 * is close to Linux */
#ifndef _EVENT_CONFIG_H_
#define _EVENT_CONFIG_H_
/* config.h.  Generated from config.h.in by configure.  */
/* config.h.in.  Generated from configure.in by autoheader.  */

/* Define if clock_gettime is available in libc */
#define _EVENT_DNS_USE_CPU_CLOCK_FOR_ID 1

/* Define is no secure id variant is available */
/* #undef _EVENT_DNS_USE_GETTIMEOFDAY_FOR_ID */

/* Define to 1 if you have the `clock_gettime' function. */
#define _EVENT_HAVE_CLOCK_GETTIME 1

/* Define if /dev/poll is available */
/* #undef _EVENT_HAVE_DEVPOLL */

/* Define to 1 if you have the <dlfcn.h> header file. */
#define _EVENT_HAVE_DLFCN_H 1

/* Define if your system supports the epoll system calls */
#define _EVENT_HAVE_EPOLL 1

/* Define to 1 if you have the `epoll_ctl' function. */
#define _EVENT_HAVE_EPOLL_CTL 1

/* Define if your system supports event ports */
/* #undef _EVENT_HAVE_EVENT_PORTS */

/* Define to 1 if you have the `fcntl' function. */
#define _EVENT_HAVE_FCNTL 1

/* Define to 1 if you have the <fcntl.h> header file. */
#define _EVENT_HAVE_FCNTL_H 1

/* Define to 1 if the system has the type `fd_mask'. */
/* #undef _EVENT_HAVE_FD_MASK 1 */

/* Define to 1 if you have the `getaddrinfo' function. */
#define _EVENT_HAVE_GETADDRINFO 1

/* Define to 1 if you have the `getegid' function. */
#define _EVENT_HAVE_GETEGID 1

/* Define to 1 if you have the `geteuid' function. */
#define _EVENT_HAVE_GETEUID 1

/* Define to 1 if you have the `getnameinfo' function. */
#define _EVENT_HAVE_GETNAMEINFO 1

/* Define to 1 if you have the `gettimeofday' function. */
#define _EVENT_HAVE_GETTIMEOFDAY 1

/* Define to 1 if you have the `inet_ntop' function. */
#define _EVENT_HAVE_INET_NTOP 1

/* Define to 1 if you have the <inttypes.h> header file. */
#define _EVENT_HAVE_INTTYPES_H 1

/* Define to 1 if you have the `issetugid' function. */
/* #undef _EVENT_HAVE_ISSETUGID */

/* Define to 1 if you have the `kqueue' function. */
/* #undef _EVENT_HAVE_KQUEUE */

/* Define to 1 if you have the `nsl' library (-lnsl). */
#define _EVENT_HAVE_LIBNSL 1

/* Define to 1 if you have the `resolv' library (-lresolv). */
#define _EVENT_HAVE_LIBRESOLV 1

/* Define to 1 if you have the `rt' library (-lrt). */
#define _EVENT_HAVE_LIBRT 1

/* Define to 1 if you have the `socket' library (-lsocket). */
/* #undef _EVENT_HAVE_LIBSOCKET */

/* Define to 1 if you have the <memory.h> header file. */
#define _EVENT_HAVE_MEMORY_H 1

/* Define to 1 if you have the <netinet/in6.h> header file. */
/* #undef _EVENT_HAVE_NETINET_IN6_H */

/* Define to 1 if you have the `poll' function. */
#define _EVENT_HAVE_POLL 1

/* Define to 1 if you have the <poll.h> header file. */
#define _EVENT_HAVE_POLL_H 1

/* Define to 1 if you have the `port_create' function. */
/* #undef _EVENT_HAVE_PORT_CREATE */

/* Define to 1 if you have the <port.h> header file. */
/* #undef _EVENT_HAVE_PORT_H */

/* Define to 1 if you have the `select' function. */
#define _EVENT_HAVE_SELECT 1

/* Define if F_SETFD is defined in <fcntl.h> */
#define _EVENT_HAVE_SETFD 1

/* Define to 1 if you have the `sigaction' function. */
#define _EVENT_HAVE_SIGACTION 1

/* Define to 1 if you have the `signal' function. */
#define _EVENT_HAVE_SIGNAL 1

/* Define to 1 if you have the <signal.h> header file. */
#define _EVENT_HAVE_SIGNAL_H 1

/* Define to 1 if you have the <stdarg.h> header file. */
#define _EVENT_HAVE_STDARG_H 1

/* Define to 1 if you have the <stdint.h> header file. */
#define _EVENT_HAVE_STDINT_H 1

/* Define to 1 if you have the <stdlib.h> header file. */
#define _EVENT_HAVE_STDLIB_H 1

/* Define to 1 if you have the <strings.h> header file. */
#define _EVENT_HAVE_STRINGS_H 1

/* Define to 1 if you have the <string.h> header file. */
#define _EVENT_HAVE_STRING_H 1

/* Define to 1 if you have the `strlcpy' function. */
#define _EVENT_HAVE_STRLCPY 1

/* Define to 1 if you have the `strsep' function. */
#define _EVENT_HAVE_STRSEP 1

/* Define to 1 if you have the `strtok_r' function. */
#define _EVENT_HAVE_STRTOK_R 1

/* Define to 1 if you have the `strtoll' function. */
#define _EVENT_HAVE_STRTOLL 1

/* Define to 1 if the system has the type `struct in6_addr'. */
#define _EVENT_HAVE_STRUCT_IN6_ADDR 1

/* Define to 1 if you have the <sys/devpoll.h> header file. */
/* #undef _EVENT_HAVE_SYS_DEVPOLL_H */

/* Define to 1 if you have the <sys/epoll.h> header file. */
#define _EVENT_HAVE_SYS_EPOLL_H 1

/* Define to 1 if you have the <sys/event.h> header file. */
/* #undef _EVENT_HAVE_SYS_EVENT_H */

/* Define to 1 if you have the <sys/ioctl.h> header file. */
#define _EVENT_HAVE_SYS_IOCTL_H 1

/* Define to 1 if you have the <sys/param.h> header file. */
#define _EVENT_HAVE_SYS_PARAM_H 1

/* Define to 1 if you have the <sys/queue.h> header file. */
#define _EVENT_HAVE_SYS_QUEUE_H 1

/* Define to 1 if you have the <sys/select.h> header file. */
#define _EVENT_HAVE_SYS_SELECT_H 1

/* Define to 1 if you have the <sys/socket.h> header file. */
#define _EVENT_HAVE_SYS_SOCKET_H 1

/* Define to 1 if you have the <sys/stat.h> header file. */
#define _EVENT_HAVE_SYS_STAT_H 1

/* Define to 1 if you have the <sys/time.h> header file. */
#define _EVENT_HAVE_SYS_TIME_H 1

/* Define to 1 if you have the <sys/types.h> header file. */
#define _EVENT_HAVE_SYS_TYPES_H 1

/* Define if TAILQ_FOREACH is defined in <sys/queue.h> */
#define _EVENT_HAVE_TAILQFOREACH 1

/* Define if timeradd is defined in <sys/time.h> */
#define _EVENT_HAVE_TIMERADD 1

/* Define if timerclear is defined in <sys/time.h> */
#define _EVENT_HAVE_TIMERCLEAR 1

/* Define if timercmp is defined in <sys/time.h> */
#define _EVENT_HAVE_TIMERCMP 1

/* Define if timerisset is defined in <sys/time.h> */
#define _EVENT_HAVE_TIMERISSET 1

/* Define to 1 if the system has the type `uint16_t'. */
#define _EVENT_HAVE_UINT16_T 1

/* Define to 1 if the system has the type `uint32_t'. */
#define _EVENT_HAVE_UINT32_T 1

/* Define to 1 if the system has the type `uint64_t'. */
#define _EVENT_HAVE_UINT64_T 1

/* Define to 1 if the system has the type `uint8_t'. */
#define _EVENT_HAVE_UINT8_T 1

/* Define to 1 if you have the <unistd.h> header file. */
#define _EVENT_HAVE_UNISTD_H 1

/* Define to 1 if you have the `vasprintf' function. */
#define _EVENT_HAVE_VASPRINTF 1

/* Define if kqueue works correctly with pipes */
/* #undef _EVENT_HAVE_WORKING_KQUEUE */

/* Name of package */
#define _EVENT_PACKAGE "libevent"

/* Define to the address where bug reports for this package should be sent. */
#define _EVENT_PACKAGE_BUGREPORT ""

/* Define to the full name of this package. */
#define _EVENT_PACKAGE_NAME ""

/* Define to the full name and version of this package. */
#define _EVENT_PACKAGE_STRING ""

/* Define to the one symbol short name of this package. */
#define _EVENT_PACKAGE_TARNAME ""

/* Define to the version of this package. */
#define _EVENT_PACKAGE_VERSION ""

/* The size of `int', as computed by sizeof. */
#define _EVENT_SIZEOF_INT 4

/* The size of `long', as computed by sizeof. */
#define _EVENT_SIZEOF_LONG 8

/* The size of `long long', as computed by sizeof. */
#define _EVENT_SIZEOF_LONG_LONG 8

/* The size of `short', as computed by sizeof. */
#define _EVENT_SIZEOF_SHORT 2

/* Define to 1 if you have the ANSI C header files. */
#define _EVENT_STDC_HEADERS 1

/* Define to 1 if you can safely include both <sys/time.h> and <time.h>. */
#define _EVENT_TIME_WITH_SYS_TIME 1

/* Version number of package */
#define _EVENT_VERSION "1.4.13-stable"

/* Define to appropriate substitue if compiler doesnt have __func__ */
/* #undef _EVENT___func__ */

/* Define to empty if `const' does not conform to ANSI C. */
/* #undef _EVENT_const */

/* Define to `__inline__' or `__inline' if that's what the C compiler
   calls it, or to nothing if 'inline' is not supported under any name.  */
#ifndef _EVENT___cplusplus
/* #undef _EVENT_inline */
#endif

/* Define to `int' if <sys/types.h> does not define. */
/* #undef _EVENT_pid_t */

/* Define to `unsigned int' if <sys/types.h> does not define. */
/* #undef _EVENT_size_t */

/* Define to unsigned int if you dont have it */
/* #undef _EVENT_socklen_t */
#endif
