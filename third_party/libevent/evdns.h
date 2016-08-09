/*
 * Copyright (c) 2006 Niels Provos <provos@citi.umich.edu>
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

/*
 * The original DNS code is due to Adam Langley with heavy
 * modifications by Nick Mathewson.  Adam put his DNS software in the
 * public domain.  You can find his original copyright below.  Please,
 * aware that the code as part of libevent is governed by the 3-clause
 * BSD license above.
 *
 * This software is Public Domain. To view a copy of the public domain dedication,
 * visit http://creativecommons.org/licenses/publicdomain/ or send a letter to
 * Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.
 *
 * I ask and expect, but do not require, that all derivative works contain an
 * attribution similar to:
 * 	Parts developed by Adam Langley <agl@imperialviolet.org>
 *
 * You may wish to replace the word "Parts" with something else depending on
 * the amount of original code.
 *
 * (Derivative works does not include programs which link against, run or include
 * the source verbatim in their source distributions)
 */

/** @file evdns.h
 *
 * Welcome, gentle reader
 *
 * Async DNS lookups are really a whole lot harder than they should be,
 * mostly stemming from the fact that the libc resolver has never been
 * very good at them. Before you use this library you should see if libc
 * can do the job for you with the modern async call getaddrinfo_a
 * (see http://www.imperialviolet.org/page25.html#e498). Otherwise,
 * please continue.
 *
 * This code is based on libevent and you must call event_init before
 * any of the APIs in this file. You must also seed the OpenSSL random
 * source if you are using OpenSSL for ids (see below).
 *
 * This library is designed to be included and shipped with your source
 * code. You statically link with it. You should also test for the
 * existence of strtok_r and define HAVE_STRTOK_R if you have it.
 *
 * The DNS protocol requires a good source of id numbers and these
 * numbers should be unpredictable for spoofing reasons. There are
 * three methods for generating them here and you must define exactly
 * one of them. In increasing order of preference:
 *
 * DNS_USE_GETTIMEOFDAY_FOR_ID:
 *   Using the bottom 16 bits of the usec result from gettimeofday. This
 *   is a pretty poor solution but should work anywhere.
 * DNS_USE_CPU_CLOCK_FOR_ID:
 *   Using the bottom 16 bits of the nsec result from the CPU's time
 *   counter. This is better, but may not work everywhere. Requires
 *   POSIX realtime support and you'll need to link against -lrt on
 *   glibc systems at least.
 * DNS_USE_OPENSSL_FOR_ID:
 *   Uses the OpenSSL RAND_bytes call to generate the data. You must
 *   have seeded the pool before making any calls to this library.
 *
 * The library keeps track of the state of nameservers and will avoid
 * them when they go down. Otherwise it will round robin between them.
 *
 * Quick start guide:
 *   #include "evdns.h"
 *   void callback(int result, char type, int count, int ttl,
 *		 void *addresses, void *arg);
 *   evdns_resolv_conf_parse(DNS_OPTIONS_ALL, "/etc/resolv.conf");
 *   evdns_resolve("www.hostname.com", 0, callback, NULL);
 *
 * When the lookup is complete the callback function is called. The
 * first argument will be one of the DNS_ERR_* defines in evdns.h.
 * Hopefully it will be DNS_ERR_NONE, in which case type will be
 * DNS_IPv4_A, count will be the number of IP addresses, ttl is the time
 * which the data can be cached for (in seconds), addresses will point
 * to an array of uint32_t's and arg will be whatever you passed to
 * evdns_resolve.
 *
 * Searching:
 *
 * In order for this library to be a good replacement for glibc's resolver it
 * supports searching. This involves setting a list of default domains, in
 * which names will be queried for. The number of dots in the query name
 * determines the order in which this list is used.
 *
 * Searching appears to be a single lookup from the point of view of the API,
 * although many DNS queries may be generated from a single call to
 * evdns_resolve. Searching can also drastically slow down the resolution
 * of names.
 *
 * To disable searching:
 *   1. Never set it up. If you never call evdns_resolv_conf_parse or
 *   evdns_search_add then no searching will occur.
 *
 *   2. If you do call evdns_resolv_conf_parse then don't pass
 *   DNS_OPTION_SEARCH (or DNS_OPTIONS_ALL, which implies it).
 *
 *   3. When calling evdns_resolve, pass the DNS_QUERY_NO_SEARCH flag.
 *
 * The order of searches depends on the number of dots in the name. If the
 * number is greater than the ndots setting then the names is first tried
 * globally. Otherwise each search domain is appended in turn.
 *
 * The ndots setting can either be set from a resolv.conf, or by calling
 * evdns_search_ndots_set.
 *
 * For example, with ndots set to 1 (the default) and a search domain list of
 * ["myhome.net"]:
 *  Query: www
 *  Order: www.myhome.net, www.
 *
 *  Query: www.abc
 *  Order: www.abc., www.abc.myhome.net
 *
 * Internals:
 *
 * Requests are kept in two queues. The first is the inflight queue. In
 * this queue requests have an allocated transaction id and nameserver.
 * They will soon be transmitted if they haven't already been.
 *
 * The second is the waiting queue. The size of the inflight ring is
 * limited and all other requests wait in waiting queue for space. This
 * bounds the number of concurrent requests so that we don't flood the
 * nameserver. Several algorithms require a full walk of the inflight
 * queue and so bounding its size keeps thing going nicely under huge
 * (many thousands of requests) loads.
 *
 * If a nameserver loses too many requests it is considered down and we
 * try not to use it. After a while we send a probe to that nameserver
 * (a lookup for google.com) and, if it replies, we consider it working
 * again. If the nameserver fails a probe we wait longer to try again
 * with the next probe.
 */

#ifndef EVENTDNS_H
#define EVENTDNS_H

#ifdef __cplusplus
extern "C" {
#endif

/* For integer types. */
#include "evutil.h"

/** Error codes 0-5 are as described in RFC 1035. */
#define DNS_ERR_NONE 0
/** The name server was unable to interpret the query */
#define DNS_ERR_FORMAT 1
/** The name server was unable to process this query due to a problem with the
 * name server */
#define DNS_ERR_SERVERFAILED 2
/** The domain name does not exist */
#define DNS_ERR_NOTEXIST 3
/** The name server does not support the requested kind of query */
#define DNS_ERR_NOTIMPL 4
/** The name server refuses to reform the specified operation for policy
 * reasons */
#define DNS_ERR_REFUSED 5
/** The reply was truncated or ill-formated */
#define DNS_ERR_TRUNCATED 65
/** An unknown error occurred */
#define DNS_ERR_UNKNOWN 66
/** Communication with the server timed out */
#define DNS_ERR_TIMEOUT 67
/** The request was canceled because the DNS subsystem was shut down. */
#define DNS_ERR_SHUTDOWN 68

#define DNS_IPv4_A 1
#define DNS_PTR 2
#define DNS_IPv6_AAAA 3

#define DNS_QUERY_NO_SEARCH 1

#define DNS_OPTION_SEARCH 1
#define DNS_OPTION_NAMESERVERS 2
#define DNS_OPTION_MISC 4
#define DNS_OPTIONS_ALL 7

/**
 * The callback that contains the results from a lookup.
 * - type is either DNS_IPv4_A or DNS_PTR or DNS_IPv6_AAAA
 * - count contains the number of addresses of form type
 * - ttl is the number of seconds the resolution may be cached for.
 * - addresses needs to be cast according to type
 */
typedef void (*evdns_callback_type) (int result, char type, int count, int ttl, void *addresses, void *arg);

/**
  Initialize the asynchronous DNS library.

  This function initializes support for non-blocking name resolution by
  calling evdns_resolv_conf_parse() on UNIX and
  evdns_config_windows_nameservers() on Windows.

  @return 0 if successful, or -1 if an error occurred
  @see evdns_shutdown()
 */
int evdns_init(void);


/**
  Shut down the asynchronous DNS resolver and terminate all active requests.

  If the 'fail_requests' option is enabled, all active requests will return
  an empty result with the error flag set to DNS_ERR_SHUTDOWN. Otherwise,
  the requests will be silently discarded.

  @param fail_requests if zero, active requests will be aborted; if non-zero,
		active requests will return DNS_ERR_SHUTDOWN.
  @see evdns_init()
 */
void evdns_shutdown(int fail_requests);


/**
  Convert a DNS error code to a string.

  @param err the DNS error code
  @return a string containing an explanation of the error code
*/
const char *evdns_err_to_string(int err);


/**
  Add a nameserver.

  The address should be an IPv4 address in network byte order.
  The type of address is chosen so that it matches in_addr.s_addr.

  @param address an IP address in network byte order
  @return 0 if successful, or -1 if an error occurred
  @see evdns_nameserver_ip_add()
 */
int evdns_nameserver_add(unsigned long int address);


/**
  Get the number of configured nameservers.

  This returns the number of configured nameservers (not necessarily the
  number of running nameservers).  This is useful for double-checking
  whether our calls to the various nameserver configuration functions
  have been successful.

  @return the number of configured nameservers
  @see evdns_nameserver_add()
 */
int evdns_count_nameservers(void);


/**
  Remove all configured nameservers, and suspend all pending resolves.

  Resolves will not necessarily be re-attempted until evdns_resume() is called.

  @return 0 if successful, or -1 if an error occurred
  @see evdns_resume()
 */
int evdns_clear_nameservers_and_suspend(void);


/**
  Resume normal operation and continue any suspended resolve requests.

  Re-attempt resolves left in limbo after an earlier call to
  evdns_clear_nameservers_and_suspend().

  @return 0 if successful, or -1 if an error occurred
  @see evdns_clear_nameservers_and_suspend()
 */
int evdns_resume(void);


/**
  Add a nameserver.

  This wraps the evdns_nameserver_add() function by parsing a string as an IP
  address and adds it as a nameserver.

  @return 0 if successful, or -1 if an error occurred
  @see evdns_nameserver_add()
 */
int evdns_nameserver_ip_add(const char *ip_as_string);


/**
  Lookup an A record for a given name.

  @param name a DNS hostname
  @param flags either 0, or DNS_QUERY_NO_SEARCH to disable searching for this query.
  @param callback a callback function to invoke when the request is completed
  @param ptr an argument to pass to the callback function
  @return 0 if successful, or -1 if an error occurred
  @see evdns_resolve_ipv6(), evdns_resolve_reverse(), evdns_resolve_reverse_ipv6()
 */
int evdns_resolve_ipv4(const char *name, int flags, evdns_callback_type callback, void *ptr);


/**
  Lookup an AAAA record for a given name.

  @param name a DNS hostname
  @param flags either 0, or DNS_QUERY_NO_SEARCH to disable searching for this query.
  @param callback a callback function to invoke when the request is completed
  @param ptr an argument to pass to the callback function
  @return 0 if successful, or -1 if an error occurred
  @see evdns_resolve_ipv4(), evdns_resolve_reverse(), evdns_resolve_reverse_ipv6()
 */
int evdns_resolve_ipv6(const char *name, int flags, evdns_callback_type callback, void *ptr);

struct in_addr;
struct in6_addr;

/**
  Lookup a PTR record for a given IP address.

  @param in an IPv4 address
  @param flags either 0, or DNS_QUERY_NO_SEARCH to disable searching for this query.
  @param callback a callback function to invoke when the request is completed
  @param ptr an argument to pass to the callback function
  @return 0 if successful, or -1 if an error occurred
  @see evdns_resolve_reverse_ipv6()
 */
int evdns_resolve_reverse(const struct in_addr *in, int flags, evdns_callback_type callback, void *ptr);


/**
  Lookup a PTR record for a given IPv6 address.

  @param in an IPv6 address
  @param flags either 0, or DNS_QUERY_NO_SEARCH to disable searching for this query.
  @param callback a callback function to invoke when the request is completed
  @param ptr an argument to pass to the callback function
  @return 0 if successful, or -1 if an error occurred
  @see evdns_resolve_reverse_ipv6()
 */
int evdns_resolve_reverse_ipv6(const struct in6_addr *in, int flags, evdns_callback_type callback, void *ptr);


/**
  Set the value of a configuration option.

  The currently available configuration options are:

    ndots, timeout, max-timeouts, max-inflight, and attempts

  @param option the name of the configuration option to be modified
  @param val the value to be set
  @param flags either 0 | DNS_OPTION_SEARCH | DNS_OPTION_MISC
  @return 0 if successful, or -1 if an error occurred
 */
int evdns_set_option(const char *option, const char *val, int flags);


/**
  Parse a resolv.conf file.

  The 'flags' parameter determines what information is parsed from the
  resolv.conf file. See the man page for resolv.conf for the format of this
  file.

  The following directives are not parsed from the file: sortlist, rotate,
  no-check-names, inet6, debug.

  If this function encounters an error, the possible return values are: 1 =
  failed to open file, 2 = failed to stat file, 3 = file too large, 4 = out of
  memory, 5 = short read from file, 6 = no nameservers listed in the file

  @param flags any of DNS_OPTION_NAMESERVERS|DNS_OPTION_SEARCH|DNS_OPTION_MISC|
         DNS_OPTIONS_ALL
  @param filename the path to the resolv.conf file
  @return 0 if successful, or various positive error codes if an error
          occurred (see above)
  @see resolv.conf(3), evdns_config_windows_nameservers()
 */
int evdns_resolv_conf_parse(int flags, const char *const filename);


/**
  Obtain nameserver information using the Windows API.

  Attempt to configure a set of nameservers based on platform settings on
  a win32 host.  Preferentially tries to use GetNetworkParams; if that fails,
  looks in the registry.

  @return 0 if successful, or -1 if an error occurred
  @see evdns_resolv_conf_parse()
 */
#ifdef WIN32
int evdns_config_windows_nameservers(void);
#endif


/**
  Clear the list of search domains.
 */
void evdns_search_clear(void);


/**
  Add a domain to the list of search domains

  @param domain the domain to be added to the search list
 */
void evdns_search_add(const char *domain);


/**
  Set the 'ndots' parameter for searches.

  Sets the number of dots which, when found in a name, causes
  the first query to be without any search domain.

  @param ndots the new ndots parameter
 */
void evdns_search_ndots_set(const int ndots);

/**
  A callback that is invoked when a log message is generated

  @param is_warning indicates if the log message is a 'warning'
  @param msg the content of the log message
 */
typedef void (*evdns_debug_log_fn_type)(int is_warning, const char *msg);


/**
  Set the callback function to handle log messages.

  @param fn the callback to be invoked when a log message is generated
 */
void evdns_set_log_fn(evdns_debug_log_fn_type fn);

/**
   Set a callback that will be invoked to generate transaction IDs.  By
   default, we pick transaction IDs based on the current clock time.

   @param fn the new callback, or NULL to use the default.
 */
void evdns_set_transaction_id_fn(ev_uint16_t (*fn)(void));

#define DNS_NO_SEARCH 1

/*
 * Structures and functions used to implement a DNS server.
 */

struct evdns_server_request {
	int flags;
	int nquestions;
	struct evdns_server_question **questions;
};
struct evdns_server_question {
	int type;
#ifdef __cplusplus
	int dns_question_class;
#else
	/* You should refer to this field as "dns_question_class".  The
	 * name "class" works in C for backward compatibility, and will be
	 * removed in a future version. (1.5 or later). */
	int class;
#define dns_question_class class
#endif
	char name[1];
};
typedef void (*evdns_request_callback_fn_type)(struct evdns_server_request *, void *);
#define EVDNS_ANSWER_SECTION 0
#define EVDNS_AUTHORITY_SECTION 1
#define EVDNS_ADDITIONAL_SECTION 2

#define EVDNS_TYPE_A	   1
#define EVDNS_TYPE_NS	   2
#define EVDNS_TYPE_CNAME   5
#define EVDNS_TYPE_SOA	   6
#define EVDNS_TYPE_PTR	  12
#define EVDNS_TYPE_MX	  15
#define EVDNS_TYPE_TXT	  16
#define EVDNS_TYPE_AAAA	  28

#define EVDNS_QTYPE_AXFR 252
#define EVDNS_QTYPE_ALL	 255

#define EVDNS_CLASS_INET   1

struct evdns_server_port *evdns_add_server_port(int socket, int is_tcp, evdns_request_callback_fn_type callback, void *user_data);
void evdns_close_server_port(struct evdns_server_port *port);

int evdns_server_request_add_reply(struct evdns_server_request *req, int section, const char *name, int type, int dns_class, int ttl, int datalen, int is_name, const char *data);
int evdns_server_request_add_a_reply(struct evdns_server_request *req, const char *name, int n, void *addrs, int ttl);
int evdns_server_request_add_aaaa_reply(struct evdns_server_request *req, const char *name, int n, void *addrs, int ttl);
int evdns_server_request_add_ptr_reply(struct evdns_server_request *req, struct in_addr *in, const char *inaddr_name, const char *hostname, int ttl);
int evdns_server_request_add_cname_reply(struct evdns_server_request *req, const char *name, const char *cname, int ttl);

int evdns_server_request_respond(struct evdns_server_request *req, int err);
int evdns_server_request_drop(struct evdns_server_request *req);
struct sockaddr;
int evdns_server_request_get_requesting_addr(struct evdns_server_request *_req, struct sockaddr *sa, int addr_len);

#ifdef __cplusplus
}
#endif

#endif  /* !EVENTDNS_H */
