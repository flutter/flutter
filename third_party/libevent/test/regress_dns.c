/*
 * Copyright (c) 2003-2006 Niels Provos <provos@citi.umich.edu>
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

#ifdef WIN32
#include <winsock2.h>
#include <windows.h>
#endif

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include <sys/types.h>
#include <sys/stat.h>
#ifdef HAVE_SYS_TIME_H
#include <sys/time.h>
#endif
#include <sys/queue.h>
#ifndef WIN32
#include <sys/socket.h>
#include <signal.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>
#endif
#ifdef HAVE_NETINET_IN6_H
#include <netinet/in6.h>
#endif
#ifdef HAVE_NETDB_H
#include <netdb.h>
#endif
#include <fcntl.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>

#include "event.h"
#include "evdns.h"
#include "log.h"

static int dns_ok = 0;
static int dns_err = 0;

void dns_suite(void);

static void
dns_gethostbyname_cb(int result, char type, int count, int ttl,
    void *addresses, void *arg)
{
	dns_ok = dns_err = 0;

	if (result == DNS_ERR_TIMEOUT) {
		fprintf(stdout, "[Timed out] ");
		dns_err = result;
		goto out;
	}

	if (result != DNS_ERR_NONE) {
		fprintf(stdout, "[Error code %d] ", result);
		goto out;
	}

	fprintf(stderr, "type: %d, count: %d, ttl: %d: ", type, count, ttl);

	switch (type) {
	case DNS_IPv6_AAAA: {
#if defined(HAVE_STRUCT_IN6_ADDR) && defined(HAVE_INET_NTOP) && defined(INET6_ADDRSTRLEN)
		struct in6_addr *in6_addrs = addresses;
		char buf[INET6_ADDRSTRLEN+1];
		int i;
		/* a resolution that's not valid does not help */
		if (ttl < 0)
			goto out;
		for (i = 0; i < count; ++i) {
			const char *b = inet_ntop(AF_INET6, &in6_addrs[i], buf,sizeof(buf));
			if (b)
				fprintf(stderr, "%s ", b);
			else
				fprintf(stderr, "%s ", strerror(errno));
		}
#endif
		break;
	}
	case DNS_IPv4_A: {
		struct in_addr *in_addrs = addresses;
		int i;
		/* a resolution that's not valid does not help */
		if (ttl < 0)
			goto out;
		for (i = 0; i < count; ++i)
			fprintf(stderr, "%s ", inet_ntoa(in_addrs[i]));
		break;
	}
	case DNS_PTR:
		/* may get at most one PTR */
		if (count != 1)
			goto out;

		fprintf(stderr, "%s ", *(char **)addresses);
		break;
	default:
		goto out;
	}

	dns_ok = type;

out:
	event_loopexit(NULL);
}

static void
dns_gethostbyname(void)
{
	fprintf(stdout, "Simple DNS resolve: ");
	dns_ok = 0;
	evdns_resolve_ipv4("www.monkey.org", 0, dns_gethostbyname_cb, NULL);
	event_dispatch();

	if (dns_ok == DNS_IPv4_A) {
		fprintf(stdout, "OK\n");
	} else {
		fprintf(stdout, "FAILED\n");
		exit(1);
	}
}

static void
dns_gethostbyname6(void)
{
	fprintf(stdout, "IPv6 DNS resolve: ");
	dns_ok = 0;
	evdns_resolve_ipv6("www.ietf.org", 0, dns_gethostbyname_cb, NULL);
	event_dispatch();

	if (dns_ok == DNS_IPv6_AAAA) {
		fprintf(stdout, "OK\n");
	} else if (!dns_ok && dns_err == DNS_ERR_TIMEOUT) {
		fprintf(stdout, "SKIPPED\n");
	} else {
		fprintf(stdout, "FAILED (%d)\n", dns_ok);
		exit(1);
	}
}

static void
dns_gethostbyaddr(void)
{
	struct in_addr in;
	in.s_addr = htonl(0x7f000001ul); /* 127.0.0.1 */
	fprintf(stdout, "Simple reverse DNS resolve: ");
	dns_ok = 0;
	evdns_resolve_reverse(&in, 0, dns_gethostbyname_cb, NULL);
	event_dispatch();

	if (dns_ok == DNS_PTR) {
		fprintf(stdout, "OK\n");
	} else {
		fprintf(stdout, "FAILED\n");
		exit(1);
	}
}

static int n_server_responses = 0;

static void
dns_server_request_cb(struct evdns_server_request *req, void *data)
{
	int i, r;
	const char TEST_ARPA[] = "11.11.168.192.in-addr.arpa";
	for (i = 0; i < req->nquestions; ++i) {
		struct in_addr ans;
		ans.s_addr = htonl(0xc0a80b0bUL); /* 192.168.11.11 */
		if (req->questions[i]->type == EVDNS_TYPE_A &&
			req->questions[i]->dns_question_class == EVDNS_CLASS_INET &&
			!strcmp(req->questions[i]->name, "zz.example.com")) {
			r = evdns_server_request_add_a_reply(req, "zz.example.com",
												 1, &ans.s_addr, 12345);
			if (r<0)
				dns_ok = 0;
		} else if (req->questions[i]->type == EVDNS_TYPE_AAAA &&
				   req->questions[i]->dns_question_class == EVDNS_CLASS_INET &&
				   !strcmp(req->questions[i]->name, "zz.example.com")) {
			char addr6[17] = "abcdefghijklmnop";
			r = evdns_server_request_add_aaaa_reply(req, "zz.example.com",
												 1, addr6, 123);
			if (r<0)
				dns_ok = 0;
		} else if (req->questions[i]->type == EVDNS_TYPE_PTR &&
				   req->questions[i]->dns_question_class == EVDNS_CLASS_INET &&
				   !strcmp(req->questions[i]->name, TEST_ARPA)) {
			r = evdns_server_request_add_ptr_reply(req, NULL, TEST_ARPA,
					   "ZZ.EXAMPLE.COM", 54321);
			if (r<0)
				dns_ok = 0;
		} else {
			fprintf(stdout, "Unexpected question %d %d \"%s\" ",
					req->questions[i]->type,
					req->questions[i]->dns_question_class,
					req->questions[i]->name);
			dns_ok = 0;
		}
	}
	r = evdns_server_request_respond(req, 0);
	if (r<0) {
		fprintf(stdout, "Couldn't send reply. ");
		dns_ok = 0;
	}
}

static void
dns_server_gethostbyname_cb(int result, char type, int count, int ttl,
							void *addresses, void *arg)
{
	if (result != DNS_ERR_NONE) {
		fprintf(stdout, "Unexpected result %d. ", result);
		dns_ok = 0;
		goto out;
	}
	if (count != 1) {
		fprintf(stdout, "Unexpected answer count %d. ", count);
		dns_ok = 0;
		goto out;
	}
	switch (type) {
	case DNS_IPv4_A: {
		struct in_addr *in_addrs = addresses;
		if (in_addrs[0].s_addr != htonl(0xc0a80b0bUL) || ttl != 12345) {
			fprintf(stdout, "Bad IPv4 response \"%s\" %d. ",
					inet_ntoa(in_addrs[0]), ttl);
			dns_ok = 0;
			goto out;
		}
		break;
	}
	case DNS_IPv6_AAAA: {
#if defined (HAVE_STRUCT_IN6_ADDR) && defined(HAVE_INET_NTOP) && defined(INET6_ADDRSTRLEN)
		struct in6_addr *in6_addrs = addresses;
		char buf[INET6_ADDRSTRLEN+1];
		if (memcmp(&in6_addrs[0].s6_addr, "abcdefghijklmnop", 16)
			|| ttl != 123) {
			const char *b = inet_ntop(AF_INET6, &in6_addrs[0],buf,sizeof(buf));
			fprintf(stdout, "Bad IPv6 response \"%s\" %d. ", b, ttl);
			dns_ok = 0;
			goto out;
		}
#endif
		break;
	}
	case DNS_PTR: {
		char **addrs = addresses;
		if (strcmp(addrs[0], "ZZ.EXAMPLE.COM") || ttl != 54321) {
			fprintf(stdout, "Bad PTR response \"%s\" %d. ",
					addrs[0], ttl);
			dns_ok = 0;
			goto out;
		}
		break;
	}
	default:
		fprintf(stdout, "Bad response type %d. ", type);
		dns_ok = 0;
	}

 out:
	if (++n_server_responses == 3) {
		event_loopexit(NULL);
	}
}

static void
dns_server(void)
{
	int sock;
	struct sockaddr_in my_addr;
	struct evdns_server_port *port;
	struct in_addr resolve_addr;

	dns_ok = 1;
	fprintf(stdout, "DNS server support: ");

	/* Add ourself as the only nameserver, and make sure we really are
	 * the only nameserver. */
	evdns_nameserver_ip_add("127.0.0.1:35353");
	if (evdns_count_nameservers() != 1) {
		fprintf(stdout, "Couldn't set up.\n");
		exit(1);
	}

	/* Now configure a nameserver port. */
	sock = socket(AF_INET, SOCK_DGRAM, 0);
	if (sock == -1) {
		perror("socket");
		exit(1);
	}
#ifdef WIN32
	{
		u_long nonblocking = 1;
		ioctlsocket(sock, FIONBIO, &nonblocking);
	}
#else
	fcntl(sock, F_SETFL, O_NONBLOCK);
#endif
	memset(&my_addr, 0, sizeof(my_addr));
	my_addr.sin_family = AF_INET;
	my_addr.sin_port = htons(35353);
	my_addr.sin_addr.s_addr = htonl(0x7f000001UL);
	if (bind(sock, (struct sockaddr*)&my_addr, sizeof(my_addr)) < 0) {
		perror("bind");
		exit (1);
	}
	port = evdns_add_server_port(sock, 0, dns_server_request_cb, NULL);

	/* Send two queries. */
	evdns_resolve_ipv4("zz.example.com", DNS_QUERY_NO_SEARCH,
					   dns_server_gethostbyname_cb, NULL);
	evdns_resolve_ipv6("zz.example.com", DNS_QUERY_NO_SEARCH,
					   dns_server_gethostbyname_cb, NULL);
	resolve_addr.s_addr = htonl(0xc0a80b0bUL); /* 192.168.11.11 */
	evdns_resolve_reverse(&resolve_addr, 0,
						  dns_server_gethostbyname_cb, NULL);

	event_dispatch();

	if (dns_ok) {
		fprintf(stdout, "OK\n");
	} else {
		fprintf(stdout, "FAILED\n");
		exit(1);
	}

	evdns_close_server_port(port);
	evdns_shutdown(0); /* remove ourself as nameserver. */
#ifdef WIN32
	closesocket(sock);
#else
	close(sock);
#endif
}

void
dns_suite(void)
{
	dns_server(); /* Do this before we call evdns_init. */

	evdns_init();
	dns_gethostbyname();
	dns_gethostbyname6();
	dns_gethostbyaddr();

	evdns_shutdown(0);
}
