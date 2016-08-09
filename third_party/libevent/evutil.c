/*
 * Copyright (c) 2007 Niels Provos <provos@citi.umich.edu>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. The name of the author may not be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 * NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#ifdef WIN32
#include <winsock2.h>
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#undef WIN32_LEAN_AND_MEAN
#endif

#include <sys/types.h>
#ifdef HAVE_SYS_SOCKET_H
#include <sys/socket.h>
#endif
#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif
#ifdef HAVE_FCNTL_H
#include <fcntl.h>
#endif
#ifdef HAVE_STDLIB_H
#include <stdlib.h>
#endif
#include <errno.h>
#if defined WIN32 && !defined(HAVE_GETTIMEOFDAY_H)
#include <sys/timeb.h>
#endif
#include <stdio.h>
#include <signal.h>

#include <sys/queue.h>
#include "event.h"
#include "event-internal.h"
#include "evutil.h"
#include "log.h"

int
evutil_socketpair(int family, int type, int protocol, int fd[2])
{
#ifndef WIN32
	return socketpair(family, type, protocol, fd);
#else
	/* This code is originally from Tor.  Used with permission. */

	/* This socketpair does not work when localhost is down. So
	 * it's really not the same thing at all. But it's close enough
	 * for now, and really, when localhost is down sometimes, we
	 * have other problems too.
	 */
	int listener = -1;
	int connector = -1;
	int acceptor = -1;
	struct sockaddr_in listen_addr;
	struct sockaddr_in connect_addr;
	int size;
	int saved_errno = -1;

	if (protocol
#ifdef AF_UNIX
		|| family != AF_UNIX
#endif
		) {
		EVUTIL_SET_SOCKET_ERROR(WSAEAFNOSUPPORT);
		return -1;
	}
	if (!fd) {
		EVUTIL_SET_SOCKET_ERROR(WSAEINVAL);
		return -1;
	}

	listener = socket(AF_INET, type, 0);
	if (listener < 0)
		return -1;
	memset(&listen_addr, 0, sizeof(listen_addr));
	listen_addr.sin_family = AF_INET;
	listen_addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
	listen_addr.sin_port = 0;	/* kernel chooses port.	 */
	if (bind(listener, (struct sockaddr *) &listen_addr, sizeof (listen_addr))
		== -1)
		goto tidy_up_and_fail;
	if (listen(listener, 1) == -1)
		goto tidy_up_and_fail;

	connector = socket(AF_INET, type, 0);
	if (connector < 0)
		goto tidy_up_and_fail;
	/* We want to find out the port number to connect to.  */
	size = sizeof(connect_addr);
	if (getsockname(listener, (struct sockaddr *) &connect_addr, &size) == -1)
		goto tidy_up_and_fail;
	if (size != sizeof (connect_addr))
		goto abort_tidy_up_and_fail;
	if (connect(connector, (struct sockaddr *) &connect_addr,
				sizeof(connect_addr)) == -1)
		goto tidy_up_and_fail;

	size = sizeof(listen_addr);
	acceptor = accept(listener, (struct sockaddr *) &listen_addr, &size);
	if (acceptor < 0)
		goto tidy_up_and_fail;
	if (size != sizeof(listen_addr))
		goto abort_tidy_up_and_fail;
	EVUTIL_CLOSESOCKET(listener);
	/* Now check we are talking to ourself by matching port and host on the
	   two sockets.	 */
	if (getsockname(connector, (struct sockaddr *) &connect_addr, &size) == -1)
		goto tidy_up_and_fail;
	if (size != sizeof (connect_addr)
		|| listen_addr.sin_family != connect_addr.sin_family
		|| listen_addr.sin_addr.s_addr != connect_addr.sin_addr.s_addr
		|| listen_addr.sin_port != connect_addr.sin_port)
		goto abort_tidy_up_and_fail;
	fd[0] = connector;
	fd[1] = acceptor;

	return 0;

 abort_tidy_up_and_fail:
	saved_errno = WSAECONNABORTED;
 tidy_up_and_fail:
	if (saved_errno < 0)
		saved_errno = WSAGetLastError();
	if (listener != -1)
		EVUTIL_CLOSESOCKET(listener);
	if (connector != -1)
		EVUTIL_CLOSESOCKET(connector);
	if (acceptor != -1)
		EVUTIL_CLOSESOCKET(acceptor);

	EVUTIL_SET_SOCKET_ERROR(saved_errno);
	return -1;
#endif
}

int
evutil_make_socket_nonblocking(int fd)
{
#ifdef WIN32
	{
		unsigned long nonblocking = 1;
		ioctlsocket(fd, FIONBIO, (unsigned long*) &nonblocking);
	}
#else
	if (fcntl(fd, F_SETFL, O_NONBLOCK) == -1) {
		event_warn("fcntl(O_NONBLOCK)");
		return -1;
}	
#endif
	return 0;
}

ev_int64_t
evutil_strtoll(const char *s, char **endptr, int base)
{
#ifdef HAVE_STRTOLL
	return (ev_int64_t)strtoll(s, endptr, base);
#elif SIZEOF_LONG == 8
	return (ev_int64_t)strtol(s, endptr, base);
#elif defined(WIN32) && defined(_MSC_VER) && _MSC_VER < 1300
	/* XXXX on old versions of MS APIs, we only support base
	 * 10. */
	ev_int64_t r;
	if (base != 10)
		return 0;
	r = (ev_int64_t) _atoi64(s);
	while (isspace(*s))
		++s;
	while (isdigit(*s))
		++s;
	if (endptr)
		*endptr = (char*) s;
	return r;
#elif defined(WIN32)
	return (ev_int64_t) _strtoi64(s, endptr, base);
#else
#error "I don't know how to parse 64-bit integers."
#endif
}

#ifndef _EVENT_HAVE_GETTIMEOFDAY
int
evutil_gettimeofday(struct timeval *tv, struct timezone *tz)
{
	struct _timeb tb;

	if(tv == NULL)
		return -1;

	_ftime(&tb);
	tv->tv_sec = (long) tb.time;
	tv->tv_usec = ((int) tb.millitm) * 1000;
	return 0;
}
#endif

int
evutil_snprintf(char *buf, size_t buflen, const char *format, ...)
{
	int r;
	va_list ap;
	va_start(ap, format);
	r = evutil_vsnprintf(buf, buflen, format, ap);
	va_end(ap);
	return r;
}

int
evutil_vsnprintf(char *buf, size_t buflen, const char *format, va_list ap)
{
#ifdef _MSC_VER
	int r = _vsnprintf(buf, buflen, format, ap);
	buf[buflen-1] = '\0';
	if (r >= 0)
		return r;
	else
		return _vscprintf(format, ap);
#else
	int r = vsnprintf(buf, buflen, format, ap);
	buf[buflen-1] = '\0';
	return r;
#endif
}

static int
evutil_issetugid(void)
{
#ifdef _EVENT_HAVE_ISSETUGID
	return issetugid();
#else

#ifdef _EVENT_HAVE_GETEUID
	if (getuid() != geteuid())
		return 1;
#endif
#ifdef _EVENT_HAVE_GETEGID
	if (getgid() != getegid())
		return 1;
#endif
	return 0;
#endif
}

const char *
evutil_getenv(const char *varname)
{
	if (evutil_issetugid())
		return NULL;

	return getenv(varname);
}
