/* $Id: evdns.c 6979 2006-08-04 18:31:13Z nickm $ */

/* The original version of this module was written by Adam Langley; for
 * a history of modifications, check out the subversion logs.
 *
 * When editing this module, try to keep it re-mergeable by Adam.  Don't
 * reformat the whitespace, add Tor dependencies, or so on.
 *
 * TODO:
 *   - Support IPv6 and PTR records.
 *   - Replace all externally visible magic numbers with #defined constants.
 *   - Write doccumentation for APIs of all external functions.
 */

/* Async DNS Library
 * Adam Langley <agl@imperialviolet.org>
 * http://www.imperialviolet.org/eventdns.html
 * Public Domain code
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
 *
 * Version: 0.1b
 */

#include <sys/types.h>
#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#ifdef DNS_USE_FTIME_FOR_ID
#include <sys/timeb.h>
#endif

#ifndef DNS_USE_CPU_CLOCK_FOR_ID
#ifndef DNS_USE_GETTIMEOFDAY_FOR_ID
#ifndef DNS_USE_OPENSSL_FOR_ID
#ifndef DNS_USE_FTIME_FOR_ID
#error Must configure at least one id generation method.
#error Please see the documentation.
#endif
#endif
#endif
#endif

/* #define _POSIX_C_SOURCE 200507 */
#if !defined(_GNU_SOURCE)
#define _GNU_SOURCE
#endif

#ifdef DNS_USE_CPU_CLOCK_FOR_ID
#ifdef DNS_USE_OPENSSL_FOR_ID
#error Multiple id options selected
#endif
#ifdef DNS_USE_GETTIMEOFDAY_FOR_ID
#error Multiple id options selected
#endif
#include <time.h>
#endif

#ifdef DNS_USE_OPENSSL_FOR_ID
#ifdef DNS_USE_GETTIMEOFDAY_FOR_ID
#error Multiple id options selected
#endif
#include <openssl/rand.h>
#endif

#ifndef _FORTIFY_SOURCE
#define _FORTIFY_SOURCE 3
#endif

#include <string.h>
#include <fcntl.h>
#ifdef HAVE_SYS_TIME_H
#include <sys/time.h>
#endif
#ifdef HAVE_STDINT_H
#include <stdint.h>
#endif
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <assert.h>
#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif
#include <limits.h>
#include <sys/stat.h>
#include <ctype.h>
#include <stdio.h>
#include <stdarg.h>

#include "evdns.h"
#include "evutil.h"
#include "log.h"
#ifdef WIN32
#include <winsock2.h>
#include <windows.h>
#include <iphlpapi.h>
#include <io.h>
#else
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#endif

#ifdef HAVE_NETINET_IN6_H
#include <netinet/in6.h>
#endif

#define EVDNS_LOG_DEBUG 0
#define EVDNS_LOG_WARN 1

#ifndef HOST_NAME_MAX
#define HOST_NAME_MAX 255
#endif

#include <stdio.h>

#undef MIN
#define MIN(a,b) ((a)<(b)?(a):(b))

#ifdef __USE_ISOC99B
/* libevent doesn't work without this */
typedef ev_uint8_t u_char;
typedef unsigned int uint;
#endif
#include "event.h"

#define u64 ev_uint64_t
#define u32 ev_uint32_t
#define u16 ev_uint16_t
#define u8  ev_uint8_t

#ifdef WIN32
#define open _open
#define read _read
#define close _close
#define strdup _strdup
#endif

#define MAX_ADDRS 32  /* maximum number of addresses from a single packet */
/* which we bother recording */

#define TYPE_A         EVDNS_TYPE_A
#define TYPE_CNAME     5
#define TYPE_PTR       EVDNS_TYPE_PTR
#define TYPE_AAAA      EVDNS_TYPE_AAAA

#define CLASS_INET     EVDNS_CLASS_INET

struct request {
	u8 *request;  /* the dns packet data */
	unsigned int request_len;
	int reissue_count;
	int tx_count;  /* the number of times that this packet has been sent */
	unsigned int request_type; /* TYPE_PTR or TYPE_A */
	void *user_pointer;  /* the pointer given to us for this request */
	evdns_callback_type user_callback;
	struct nameserver *ns;  /* the server which we last sent it */

	/* elements used by the searching code */
	int search_index;
	struct search_state *search_state;
	char *search_origname;  /* needs to be free()ed */
	int search_flags;

	/* these objects are kept in a circular list */
	struct request *next, *prev;

	struct event timeout_event;

	u16 trans_id;  /* the transaction id */
	char request_appended;  /* true if the request pointer is data which follows this struct */
	char transmit_me;  /* needs to be transmitted */
};

#ifndef HAVE_STRUCT_IN6_ADDR
struct in6_addr {
	u8 s6_addr[16];
};
#endif

struct reply {
	unsigned int type;
	unsigned int have_answer;
	union {
		struct {
			u32 addrcount;
			u32 addresses[MAX_ADDRS];
		} a;
		struct {
			u32 addrcount;
			struct in6_addr addresses[MAX_ADDRS];
		} aaaa;
		struct {
			char name[HOST_NAME_MAX];
		} ptr;
	} data;
};

struct nameserver {
	int socket;  /* a connected UDP socket */
	u32 address;
	u16 port;
	int failed_times;  /* number of times which we have given this server a chance */
	int timedout;  /* number of times in a row a request has timed out */
	struct event event;
	/* these objects are kept in a circular list */
	struct nameserver *next, *prev;
	struct event timeout_event;  /* used to keep the timeout for */
				     /* when we next probe this server. */
				     /* Valid if state == 0 */
	char state;  /* zero if we think that this server is down */
	char choked;  /* true if we have an EAGAIN from this server's socket */
	char write_waiting;  /* true if we are waiting for EV_WRITE events */
};

static struct request *req_head = NULL, *req_waiting_head = NULL;
static struct nameserver *server_head = NULL;

/* Represents a local port where we're listening for DNS requests. Right now, */
/* only UDP is supported. */
struct evdns_server_port {
	int socket; /* socket we use to read queries and write replies. */
	int refcnt; /* reference count. */
	char choked; /* Are we currently blocked from writing? */
	char closing; /* Are we trying to close this port, pending writes? */
	evdns_request_callback_fn_type user_callback; /* Fn to handle requests */
	void *user_data; /* Opaque pointer passed to user_callback */
	struct event event; /* Read/write event */
	/* circular list of replies that we want to write. */
	struct server_request *pending_replies;
};

/* Represents part of a reply being built.	(That is, a single RR.) */
struct server_reply_item {
	struct server_reply_item *next; /* next item in sequence. */
	char *name; /* name part of the RR */
	u16 type : 16; /* The RR type */
	u16 class : 16; /* The RR class (usually CLASS_INET) */
	u32 ttl; /* The RR TTL */
	char is_name; /* True iff data is a label */
	u16 datalen; /* Length of data; -1 if data is a label */
	void *data; /* The contents of the RR */
};

/* Represents a request that we've received as a DNS server, and holds */
/* the components of the reply as we're constructing it. */
struct server_request {
	/* Pointers to the next and previous entries on the list of replies */
	/* that we're waiting to write.	 Only set if we have tried to respond */
	/* and gotten EAGAIN. */
	struct server_request *next_pending;
	struct server_request *prev_pending;

	u16 trans_id; /* Transaction id. */
	struct evdns_server_port *port; /* Which port received this request on? */
	struct sockaddr_storage addr; /* Where to send the response */
	socklen_t addrlen; /* length of addr */

	int n_answer; /* how many answer RRs have been set? */
	int n_authority; /* how many authority RRs have been set? */
	int n_additional; /* how many additional RRs have been set? */

	struct server_reply_item *answer; /* linked list of answer RRs */
	struct server_reply_item *authority; /* linked list of authority RRs */
	struct server_reply_item *additional; /* linked list of additional RRs */

	/* Constructed response.  Only set once we're ready to send a reply. */
	/* Once this is set, the RR fields are cleared, and no more should be set. */
	char *response;
	size_t response_len;

	/* Caller-visible fields: flags, questions. */
	struct evdns_server_request base;
};

/* helper macro */
#define OFFSET_OF(st, member) ((off_t) (((char*)&((st*)0)->member)-(char*)0))

/* Given a pointer to an evdns_server_request, get the corresponding */
/* server_request. */
#define TO_SERVER_REQUEST(base_ptr)										\
	((struct server_request*)											\
	 (((char*)(base_ptr) - OFFSET_OF(struct server_request, base))))

/* The number of good nameservers that we have */
static int global_good_nameservers = 0;

/* inflight requests are contained in the req_head list */
/* and are actually going out across the network */
static int global_requests_inflight = 0;
/* requests which aren't inflight are in the waiting list */
/* and are counted here */
static int global_requests_waiting = 0;

static int global_max_requests_inflight = 64;

static struct timeval global_timeout = {5, 0};  /* 5 seconds */
static int global_max_reissues = 1;  /* a reissue occurs when we get some errors from the server */
static int global_max_retransmits = 3;  /* number of times we'll retransmit a request which timed out */
/* number of timeouts in a row before we consider this server to be down */
static int global_max_nameserver_timeout = 3;

/* These are the timeout values for nameservers. If we find a nameserver is down */
/* we try to probe it at intervals as given below. Values are in seconds. */
static const struct timeval global_nameserver_timeouts[] = {{10, 0}, {60, 0}, {300, 0}, {900, 0}, {3600, 0}};
static const int global_nameserver_timeouts_length = sizeof(global_nameserver_timeouts)/sizeof(struct timeval);

static struct nameserver *nameserver_pick(void);
static void evdns_request_insert(struct request *req, struct request **head);
static void nameserver_ready_callback(int fd, short events, void *arg);
static int evdns_transmit(void);
static int evdns_request_transmit(struct request *req);
static void nameserver_send_probe(struct nameserver *const ns);
static void search_request_finished(struct request *const);
static int search_try_next(struct request *const req);
static int search_request_new(int type, const char *const name, int flags, evdns_callback_type user_callback, void *user_arg);
static void evdns_requests_pump_waiting_queue(void);
static u16 transaction_id_pick(void);
static struct request *request_new(int type, const char *name, int flags, evdns_callback_type callback, void *ptr);
static void request_submit(struct request *const req);

static int server_request_free(struct server_request *req);
static void server_request_free_answers(struct server_request *req);
static void server_port_free(struct evdns_server_port *port);
static void server_port_ready_callback(int fd, short events, void *arg);

static int strtoint(const char *const str);

#ifdef WIN32
static int
last_error(int sock)
{
	int optval, optvallen=sizeof(optval);
	int err = WSAGetLastError();
	if (err == WSAEWOULDBLOCK && sock >= 0) {
		if (getsockopt(sock, SOL_SOCKET, SO_ERROR, (void*)&optval,
			       &optvallen))
			return err;
		if (optval)
			return optval;
	}
	return err;

}
static int
error_is_eagain(int err)
{
	return err == EAGAIN || err == WSAEWOULDBLOCK;
}
static int
inet_aton(const char *c, struct in_addr *addr)
{
	ev_uint32_t r;
	if (strcmp(c, "255.255.255.255") == 0) {
		addr->s_addr = 0xffffffffu;
	} else {
		r = inet_addr(c);
		if (r == INADDR_NONE)
			return 0;
		addr->s_addr = r;
	}
	return 1;
}
#else
#define last_error(sock) (errno)
#define error_is_eagain(err) ((err) == EAGAIN)
#endif
#define CLOSE_SOCKET(s) EVUTIL_CLOSESOCKET(s)

#define ISSPACE(c) isspace((int)(unsigned char)(c))
#define ISDIGIT(c) isdigit((int)(unsigned char)(c))

static const char *
debug_ntoa(u32 address)
{
	static char buf[32];
	u32 a = ntohl(address);
	evutil_snprintf(buf, sizeof(buf), "%d.%d.%d.%d",
                      (int)(u8)((a>>24)&0xff),
                      (int)(u8)((a>>16)&0xff),
                      (int)(u8)((a>>8 )&0xff),
  		      (int)(u8)((a    )&0xff));
	return buf;
}

static evdns_debug_log_fn_type evdns_log_fn = NULL;

void
evdns_set_log_fn(evdns_debug_log_fn_type fn)
{
  evdns_log_fn = fn;
}

#ifdef __GNUC__
#define EVDNS_LOG_CHECK  __attribute__ ((format(printf, 2, 3)))
#else
#define EVDNS_LOG_CHECK
#endif

static void _evdns_log(int warn, const char *fmt, ...) EVDNS_LOG_CHECK;
static void
_evdns_log(int warn, const char *fmt, ...)
{
  va_list args;
  static char buf[512];
  if (!evdns_log_fn)
    return;
  va_start(args,fmt);
  evutil_vsnprintf(buf, sizeof(buf), fmt, args);
  buf[sizeof(buf)-1] = '\0';
  evdns_log_fn(warn, buf);
  va_end(args);
}

#define log _evdns_log

/* This walks the list of inflight requests to find the */
/* one with a matching transaction id. Returns NULL on */
/* failure */
static struct request *
request_find_from_trans_id(u16 trans_id) {
	struct request *req = req_head, *const started_at = req_head;

	if (req) {
		do {
			if (req->trans_id == trans_id) return req;
			req = req->next;
		} while (req != started_at);
	}

	return NULL;
}

/* a libevent callback function which is called when a nameserver */
/* has gone down and we want to test if it has came back to life yet */
static void
nameserver_prod_callback(int fd, short events, void *arg) {
	struct nameserver *const ns = (struct nameserver *) arg;
        (void)fd;
        (void)events;

	nameserver_send_probe(ns);
}

/* a libevent callback which is called when a nameserver probe (to see if */
/* it has come back to life) times out. We increment the count of failed_times */
/* and wait longer to send the next probe packet. */
static void
nameserver_probe_failed(struct nameserver *const ns) {
	const struct timeval * timeout;
	(void) evtimer_del(&ns->timeout_event);
	if (ns->state == 1) {
		/* This can happen if the nameserver acts in a way which makes us mark */
		/* it as bad and then starts sending good replies. */
		return;
	}

	timeout =
	  &global_nameserver_timeouts[MIN(ns->failed_times,
					  global_nameserver_timeouts_length - 1)];
	ns->failed_times++;

	if (evtimer_add(&ns->timeout_event, (struct timeval *) timeout) < 0) {
          log(EVDNS_LOG_WARN,
              "Error from libevent when adding timer event for %s",
              debug_ntoa(ns->address));
          /* ???? Do more? */
        }
}

/* called when a nameserver has been deemed to have failed. For example, too */
/* many packets have timed out etc */
static void
nameserver_failed(struct nameserver *const ns, const char *msg) {
	struct request *req, *started_at;
	/* if this nameserver has already been marked as failed */
	/* then don't do anything */
	if (!ns->state) return;

	log(EVDNS_LOG_WARN, "Nameserver %s has failed: %s",
            debug_ntoa(ns->address), msg);
	global_good_nameservers--;
	assert(global_good_nameservers >= 0);
	if (global_good_nameservers == 0) {
		log(EVDNS_LOG_WARN, "All nameservers have failed");
	}

	ns->state = 0;
	ns->failed_times = 1;

	if (evtimer_add(&ns->timeout_event, (struct timeval *) &global_nameserver_timeouts[0]) < 0) {
		log(EVDNS_LOG_WARN,
		    "Error from libevent when adding timer event for %s",
		    debug_ntoa(ns->address));
		/* ???? Do more? */
        }

	/* walk the list of inflight requests to see if any can be reassigned to */
	/* a different server. Requests in the waiting queue don't have a */
	/* nameserver assigned yet */

	/* if we don't have *any* good nameservers then there's no point */
	/* trying to reassign requests to one */
	if (!global_good_nameservers) return;

	req = req_head;
	started_at = req_head;
	if (req) {
		do {
			if (req->tx_count == 0 && req->ns == ns) {
				/* still waiting to go out, can be moved */
				/* to another server */
				req->ns = nameserver_pick();
			}
			req = req->next;
		} while (req != started_at);
	}
}

static void
nameserver_up(struct nameserver *const ns) {
	if (ns->state) return;
	log(EVDNS_LOG_WARN, "Nameserver %s is back up",
	    debug_ntoa(ns->address));
	evtimer_del(&ns->timeout_event);
	ns->state = 1;
	ns->failed_times = 0;
	ns->timedout = 0;
	global_good_nameservers++;
}

static void
request_trans_id_set(struct request *const req, const u16 trans_id) {
	req->trans_id = trans_id;
	*((u16 *) req->request) = htons(trans_id);
}

/* Called to remove a request from a list and dealloc it. */
/* head is a pointer to the head of the list it should be */
/* removed from or NULL if the request isn't in a list. */
static void
request_finished(struct request *const req, struct request **head) {
	if (head) {
		if (req->next == req) {
			/* only item in the list */
			*head = NULL;
		} else {
			req->next->prev = req->prev;
			req->prev->next = req->next;
			if (*head == req) *head = req->next;
		}
	}

	log(EVDNS_LOG_DEBUG, "Removing timeout for request %lx",
	    (unsigned long) req);
	evtimer_del(&req->timeout_event);

	search_request_finished(req);
	global_requests_inflight--;

	if (!req->request_appended) {
		/* need to free the request data on it's own */
		free(req->request);
	} else {
		/* the request data is appended onto the header */
		/* so everything gets free()ed when we: */
	}

	free(req);

	evdns_requests_pump_waiting_queue();
}

/* This is called when a server returns a funny error code. */
/* We try the request again with another server. */
/* */
/* return: */
/*   0 ok */
/*   1 failed/reissue is pointless */
static int
request_reissue(struct request *req) {
	const struct nameserver *const last_ns = req->ns;
	/* the last nameserver should have been marked as failing */
	/* by the caller of this function, therefore pick will try */
	/* not to return it */
	req->ns = nameserver_pick();
	if (req->ns == last_ns) {
		/* ... but pick did return it */
		/* not a lot of point in trying again with the */
		/* same server */
		return 1;
	}

	req->reissue_count++;
	req->tx_count = 0;
	req->transmit_me = 1;

	return 0;
}

/* this function looks for space on the inflight queue and promotes */
/* requests from the waiting queue if it can. */
static void
evdns_requests_pump_waiting_queue(void) {
	while (global_requests_inflight < global_max_requests_inflight &&
	    global_requests_waiting) {
		struct request *req;
		/* move a request from the waiting queue to the inflight queue */
		assert(req_waiting_head);
		if (req_waiting_head->next == req_waiting_head) {
			/* only one item in the queue */
			req = req_waiting_head;
			req_waiting_head = NULL;
		} else {
			req = req_waiting_head;
			req->next->prev = req->prev;
			req->prev->next = req->next;
			req_waiting_head = req->next;
		}

		global_requests_waiting--;
		global_requests_inflight++;

		req->ns = nameserver_pick();
		request_trans_id_set(req, transaction_id_pick());

		evdns_request_insert(req, &req_head);
		evdns_request_transmit(req);
		evdns_transmit();
	}
}

static void
reply_callback(struct request *const req, u32 ttl, u32 err, struct reply *reply) {
	switch (req->request_type) {
	case TYPE_A:
		if (reply)
			req->user_callback(DNS_ERR_NONE, DNS_IPv4_A,
							   reply->data.a.addrcount, ttl,
						 reply->data.a.addresses,
							   req->user_pointer);
		else
			req->user_callback(err, 0, 0, 0, NULL, req->user_pointer);
		return;
	case TYPE_PTR:
		if (reply) {
			char *name = reply->data.ptr.name;
			req->user_callback(DNS_ERR_NONE, DNS_PTR, 1, ttl,
							   &name, req->user_pointer);
		} else {
			req->user_callback(err, 0, 0, 0, NULL,
							   req->user_pointer);
		}
		return;
	case TYPE_AAAA:
		if (reply)
			req->user_callback(DNS_ERR_NONE, DNS_IPv6_AAAA,
							   reply->data.aaaa.addrcount, ttl,
							   reply->data.aaaa.addresses,
							   req->user_pointer);
		else
			req->user_callback(err, 0, 0, 0, NULL, req->user_pointer);
                return;
	}
	assert(0);
}

/* this processes a parsed reply packet */
static void
reply_handle(struct request *const req, u16 flags, u32 ttl, struct reply *reply) {
	int error;
	static const int error_codes[] = {
		DNS_ERR_FORMAT, DNS_ERR_SERVERFAILED, DNS_ERR_NOTEXIST,
		DNS_ERR_NOTIMPL, DNS_ERR_REFUSED
	};

	if (flags & 0x020f || !reply || !reply->have_answer) {
		/* there was an error */
		if (flags & 0x0200) {
			error = DNS_ERR_TRUNCATED;
		} else {
			u16 error_code = (flags & 0x000f) - 1;
			if (error_code > 4) {
				error = DNS_ERR_UNKNOWN;
			} else {
				error = error_codes[error_code];
			}
		}

		switch(error) {
		case DNS_ERR_NOTIMPL:
		case DNS_ERR_REFUSED:
			/* we regard these errors as marking a bad nameserver */
			if (req->reissue_count < global_max_reissues) {
				char msg[64];
				evutil_snprintf(msg, sizeof(msg),
				    "Bad response %d (%s)",
					 error, evdns_err_to_string(error));
				nameserver_failed(req->ns, msg);
				if (!request_reissue(req)) return;
			}
			break;
		case DNS_ERR_SERVERFAILED:
			/* rcode 2 (servfailed) sometimes means "we
			 * are broken" and sometimes (with some binds)
			 * means "that request was very confusing."
			 * Treat this as a timeout, not a failure.
			 */
			log(EVDNS_LOG_DEBUG, "Got a SERVERFAILED from nameserver %s; "
				"will allow the request to time out.",
				debug_ntoa(req->ns->address));
			break;
		default:
			/* we got a good reply from the nameserver */
			nameserver_up(req->ns);
		}

		if (req->search_state && req->request_type != TYPE_PTR) {
			/* if we have a list of domains to search in,
			 * try the next one */
			if (!search_try_next(req)) {
				/* a new request was issued so this
				 * request is finished and */
				/* the user callback will be made when
				 * that request (or a */
				/* child of it) finishes. */
				request_finished(req, &req_head);
				return;
			}
		}

		/* all else failed. Pass the failure up */
		reply_callback(req, 0, error, NULL);
		request_finished(req, &req_head);
	} else {
		/* all ok, tell the user */
		reply_callback(req, ttl, 0, reply);
		nameserver_up(req->ns);
		request_finished(req, &req_head);
	}
}

static int
name_parse(u8 *packet, int length, int *idx, char *name_out, int name_out_len) {
	int name_end = -1;
	int j = *idx;
	int ptr_count = 0;
#define GET32(x) do { if (j + 4 > length) goto err; memcpy(&_t32, packet + j, 4); j += 4; x = ntohl(_t32); } while(0)
#define GET16(x) do { if (j + 2 > length) goto err; memcpy(&_t, packet + j, 2); j += 2; x = ntohs(_t); } while(0)
#define GET8(x) do { if (j >= length) goto err; x = packet[j++]; } while(0)

	char *cp = name_out;
	const char *const end = name_out + name_out_len;

	/* Normally, names are a series of length prefixed strings terminated */
	/* with a length of 0 (the lengths are u8's < 63). */
	/* However, the length can start with a pair of 1 bits and that */
	/* means that the next 14 bits are a pointer within the current */
	/* packet. */

	for(;;) {
		u8 label_len;
		if (j >= length) return -1;
		GET8(label_len);
		if (!label_len) break;
		if (label_len & 0xc0) {
			u8 ptr_low;
			GET8(ptr_low);
			if (name_end < 0) name_end = j;
			j = (((int)label_len & 0x3f) << 8) + ptr_low;
			/* Make sure that the target offset is in-bounds. */
			if (j < 0 || j >= length) return -1;
			/* If we've jumped more times than there are characters in the
			 * message, we must have a loop. */
			if (++ptr_count > length) return -1;
			continue;
		}
		if (label_len > 63) return -1;
		if (cp != name_out) {
			if (cp + 1 >= end) return -1;
			*cp++ = '.';
		}
		if (cp + label_len >= end) return -1;
		memcpy(cp, packet + j, label_len);
		cp += label_len;
		j += label_len;
	}
	if (cp >= end) return -1;
	*cp = '\0';
	if (name_end < 0)
		*idx = j;
	else
		*idx = name_end;
	return 0;
 err:
	return -1;
}

/* parses a raw request from a nameserver */
static int
reply_parse(u8 *packet, int length) {
	int j = 0, k = 0;  /* index into packet */
	u16 _t;  /* used by the macros */
	u32 _t32;  /* used by the macros */
	char tmp_name[256], cmp_name[256]; /* used by the macros */

	u16 trans_id, questions, answers, authority, additional, datalength;
        u16 flags = 0;
	u32 ttl, ttl_r = 0xffffffff;
	struct reply reply;
	struct request *req = NULL;
	unsigned int i;

	GET16(trans_id);
	GET16(flags);
	GET16(questions);
	GET16(answers);
	GET16(authority);
	GET16(additional);
	(void) authority; /* suppress "unused variable" warnings. */
	(void) additional; /* suppress "unused variable" warnings. */

	req = request_find_from_trans_id(trans_id);
	if (!req) return -1;

	memset(&reply, 0, sizeof(reply));

	/* If it's not an answer, it doesn't correspond to any request. */
	if (!(flags & 0x8000)) return -1;  /* must be an answer */
	if (flags & 0x020f) {
		/* there was an error */
		goto err;
	}
	/* if (!answers) return; */  /* must have an answer of some form */

	/* This macro skips a name in the DNS reply. */
#define SKIP_NAME \
	do { tmp_name[0] = '\0';				\
		if (name_parse(packet, length, &j, tmp_name, sizeof(tmp_name))<0)\
			goto err;				\
	} while(0)
#define TEST_NAME \
	do { tmp_name[0] = '\0';				\
		cmp_name[0] = '\0';				\
		k = j;						\
		if (name_parse(packet, length, &j, tmp_name, sizeof(tmp_name))<0)\
			goto err;					\
		if (name_parse(req->request, req->request_len, &k, cmp_name, sizeof(cmp_name))<0)	\
			goto err;				\
		if (memcmp(tmp_name, cmp_name, strlen (tmp_name)) != 0)	\
			return (-1); /* we ignore mismatching names */	\
	} while(0)

	reply.type = req->request_type;

	/* skip over each question in the reply */
	for (i = 0; i < questions; ++i) {
		/* the question looks like
		 *   <label:name><u16:type><u16:class>
		 */
		TEST_NAME;
		j += 4;
		if (j > length) goto err;
	}

	/* now we have the answer section which looks like
	 * <label:name><u16:type><u16:class><u32:ttl><u16:len><data...>
	 */

	for (i = 0; i < answers; ++i) {
		u16 type, class;

		SKIP_NAME;
		GET16(type);
		GET16(class);
		GET32(ttl);
		GET16(datalength);

		if (type == TYPE_A && class == CLASS_INET) {
			int addrcount, addrtocopy;
			if (req->request_type != TYPE_A) {
				j += datalength; continue;
			}
			if ((datalength & 3) != 0) /* not an even number of As. */
			    goto err;
			addrcount = datalength >> 2;
			addrtocopy = MIN(MAX_ADDRS - reply.data.a.addrcount, (unsigned)addrcount);

			ttl_r = MIN(ttl_r, ttl);
			/* we only bother with the first four addresses. */
			if (j + 4*addrtocopy > length) goto err;
			memcpy(&reply.data.a.addresses[reply.data.a.addrcount],
				   packet + j, 4*addrtocopy);
			j += 4*addrtocopy;
			reply.data.a.addrcount += addrtocopy;
			reply.have_answer = 1;
			if (reply.data.a.addrcount == MAX_ADDRS) break;
		} else if (type == TYPE_PTR && class == CLASS_INET) {
			if (req->request_type != TYPE_PTR) {
				j += datalength; continue;
			}
			if (name_parse(packet, length, &j, reply.data.ptr.name,
						   sizeof(reply.data.ptr.name))<0)
				goto err;
			ttl_r = MIN(ttl_r, ttl);
			reply.have_answer = 1;
			break;
		} else if (type == TYPE_AAAA && class == CLASS_INET) {
			int addrcount, addrtocopy;
			if (req->request_type != TYPE_AAAA) {
				j += datalength; continue;
			}
			if ((datalength & 15) != 0) /* not an even number of AAAAs. */
				goto err;
			addrcount = datalength >> 4;  /* each address is 16 bytes long */
			addrtocopy = MIN(MAX_ADDRS - reply.data.aaaa.addrcount, (unsigned)addrcount);
			ttl_r = MIN(ttl_r, ttl);

			/* we only bother with the first four addresses. */
			if (j + 16*addrtocopy > length) goto err;
			memcpy(&reply.data.aaaa.addresses[reply.data.aaaa.addrcount],
				   packet + j, 16*addrtocopy);
			reply.data.aaaa.addrcount += addrtocopy;
			j += 16*addrtocopy;
			reply.have_answer = 1;
			if (reply.data.aaaa.addrcount == MAX_ADDRS) break;
		} else {
			/* skip over any other type of resource */
			j += datalength;
		}
	}

	reply_handle(req, flags, ttl_r, &reply);
	return 0;
 err:
	if (req)
		reply_handle(req, flags, 0, NULL);
	return -1;
}

/* Parse a raw request (packet,length) sent to a nameserver port (port) from */
/* a DNS client (addr,addrlen), and if it's well-formed, call the corresponding */
/* callback. */
static int
request_parse(u8 *packet, int length, struct evdns_server_port *port, struct sockaddr *addr, socklen_t addrlen)
{
	int j = 0;	/* index into packet */
	u16 _t;	 /* used by the macros */
	char tmp_name[256]; /* used by the macros */

	int i;
	u16 trans_id, flags, questions, answers, authority, additional;
	struct server_request *server_req = NULL;

	/* Get the header fields */
	GET16(trans_id);
	GET16(flags);
	GET16(questions);
	GET16(answers);
	GET16(authority);
	GET16(additional);

	if (flags & 0x8000) return -1; /* Must not be an answer. */
	flags &= 0x0110; /* Only RD and CD get preserved. */

	server_req = malloc(sizeof(struct server_request));
	if (server_req == NULL) return -1;
	memset(server_req, 0, sizeof(struct server_request));

	server_req->trans_id = trans_id;
	memcpy(&server_req->addr, addr, addrlen);
	server_req->addrlen = addrlen;

	server_req->base.flags = flags;
	server_req->base.nquestions = 0;
	server_req->base.questions = malloc(sizeof(struct evdns_server_question *) * questions);
	if (server_req->base.questions == NULL)
		goto err;

	for (i = 0; i < questions; ++i) {
		u16 type, class;
		struct evdns_server_question *q;
		int namelen;
		if (name_parse(packet, length, &j, tmp_name, sizeof(tmp_name))<0)
			goto err;
		GET16(type);
		GET16(class);
		namelen = strlen(tmp_name);
		q = malloc(sizeof(struct evdns_server_question) + namelen);
		if (!q)
			goto err;
		q->type = type;
		q->dns_question_class = class;
		memcpy(q->name, tmp_name, namelen+1);
		server_req->base.questions[server_req->base.nquestions++] = q;
	}

	/* Ignore answers, authority, and additional. */

	server_req->port = port;
	port->refcnt++;

	/* Only standard queries are supported. */
	if (flags & 0x7800) {
		evdns_server_request_respond(&(server_req->base), DNS_ERR_NOTIMPL);
		return -1;
	}

	port->user_callback(&(server_req->base), port->user_data);

	return 0;
err:
	if (server_req) {
		if (server_req->base.questions) {
			for (i = 0; i < server_req->base.nquestions; ++i)
				free(server_req->base.questions[i]);
			free(server_req->base.questions);
		}
		free(server_req);
	}
	return -1;

#undef SKIP_NAME
#undef GET32
#undef GET16
#undef GET8
}

static u16
default_transaction_id_fn(void)
{
	u16 trans_id;
#ifdef DNS_USE_CPU_CLOCK_FOR_ID
	struct timespec ts;
	static int clkid = -1;
	if (clkid == -1) {
		clkid = CLOCK_REALTIME;
#ifdef CLOCK_MONOTONIC
		if (clock_gettime(CLOCK_MONOTONIC, &ts) != -1)
			clkid = CLOCK_MONOTONIC;
#endif
	}
	if (clock_gettime(clkid, &ts) == -1)
		event_err(1, "clock_gettime");
	trans_id = ts.tv_nsec & 0xffff;
#endif

#ifdef DNS_USE_FTIME_FOR_ID
	struct _timeb tb;
	_ftime(&tb);
	trans_id = tb.millitm & 0xffff;
#endif

#ifdef DNS_USE_GETTIMEOFDAY_FOR_ID
	struct timeval tv;
	evutil_gettimeofday(&tv, NULL);
	trans_id = tv.tv_usec & 0xffff;
#endif

#ifdef DNS_USE_OPENSSL_FOR_ID
	if (RAND_pseudo_bytes((u8 *) &trans_id, 2) == -1) {
		/* in the case that the RAND call fails we back */
		/* down to using gettimeofday. */
		/*
		  struct timeval tv;
		  evutil_gettimeofday(&tv, NULL);
		  trans_id = tv.tv_usec & 0xffff;
		*/
		abort();
	}
#endif
	return trans_id;
}

static ev_uint16_t (*trans_id_function)(void) = default_transaction_id_fn;

void
evdns_set_transaction_id_fn(ev_uint16_t (*fn)(void))
{
	if (fn)
		trans_id_function = fn;
	else
		trans_id_function = default_transaction_id_fn;
}

/* Try to choose a strong transaction id which isn't already in flight */
static u16
transaction_id_pick(void) {
	for (;;) {
		const struct request *req = req_head, *started_at;
		u16 trans_id = trans_id_function();

		if (trans_id == 0xffff) continue;
		/* now check to see if that id is already inflight */
		req = started_at = req_head;
		if (req) {
			do {
				if (req->trans_id == trans_id) break;
				req = req->next;
			} while (req != started_at);
		}
		/* we didn't find it, so this is a good id */
		if (req == started_at) return trans_id;
	}
}

/* choose a namesever to use. This function will try to ignore */
/* nameservers which we think are down and load balance across the rest */
/* by updating the server_head global each time. */
static struct nameserver *
nameserver_pick(void) {
	struct nameserver *started_at = server_head, *picked;
	if (!server_head) return NULL;

	/* if we don't have any good nameservers then there's no */
	/* point in trying to find one. */
	if (!global_good_nameservers) {
		server_head = server_head->next;
		return server_head;
	}

	/* remember that nameservers are in a circular list */
	for (;;) {
		if (server_head->state) {
			/* we think this server is currently good */
			picked = server_head;
			server_head = server_head->next;
			return picked;
		}

		server_head = server_head->next;
		if (server_head == started_at) {
			/* all the nameservers seem to be down */
			/* so we just return this one and hope for the */
			/* best */
			assert(global_good_nameservers == 0);
			picked = server_head;
			server_head = server_head->next;
			return picked;
		}
	}
}

static int
address_is_correct(struct nameserver *ns, struct sockaddr *sa, socklen_t slen)
{
	struct sockaddr_in *sin = (struct sockaddr_in*) sa;
	if (sa->sa_family != AF_INET || slen != sizeof(struct sockaddr_in))
		return 0;
	if (sin->sin_addr.s_addr != ns->address)
		return 0;
	return 1;
}

/* this is called when a namesever socket is ready for reading */
static void
nameserver_read(struct nameserver *ns) {
	u8 packet[1500];
	struct sockaddr_storage ss;
	socklen_t addrlen = sizeof(ss);

	for (;;) {
          	const int r = recvfrom(ns->socket, packet, sizeof(packet), 0,
		    (struct sockaddr*)&ss, &addrlen);
		if (r < 0) {
			int err = last_error(ns->socket);
			if (error_is_eagain(err)) return;
			nameserver_failed(ns, strerror(err));
			return;
		}
		if (!address_is_correct(ns, (struct sockaddr*)&ss, addrlen)) {
			log(EVDNS_LOG_WARN, "Address mismatch on received "
			    "DNS packet.");
			return;
		}
		ns->timedout = 0;
		reply_parse(packet, r);
	}
}

/* Read a packet from a DNS client on a server port s, parse it, and */
/* act accordingly. */
static void
server_port_read(struct evdns_server_port *s) {
	u8 packet[1500];
	struct sockaddr_storage addr;
	socklen_t addrlen;
	int r;

	for (;;) {
		addrlen = sizeof(struct sockaddr_storage);
		r = recvfrom(s->socket, packet, sizeof(packet), 0,
					 (struct sockaddr*) &addr, &addrlen);
		if (r < 0) {
			int err = last_error(s->socket);
			if (error_is_eagain(err)) return;
			log(EVDNS_LOG_WARN, "Error %s (%d) while reading request.",
				strerror(err), err);
			return;
		}
		request_parse(packet, r, s, (struct sockaddr*) &addr, addrlen);
	}
}

/* Try to write all pending replies on a given DNS server port. */
static void
server_port_flush(struct evdns_server_port *port)
{
	while (port->pending_replies) {
		struct server_request *req = port->pending_replies;
		int r = sendto(port->socket, req->response, req->response_len, 0,
			   (struct sockaddr*) &req->addr, req->addrlen);
		if (r < 0) {
			int err = last_error(port->socket);
			if (error_is_eagain(err))
				return;
			log(EVDNS_LOG_WARN, "Error %s (%d) while writing response to port; dropping", strerror(err), err);
		}
		if (server_request_free(req)) {
			/* we released the last reference to req->port. */
			return;
		}
	}

	/* We have no more pending requests; stop listening for 'writeable' events. */
	(void) event_del(&port->event);
	event_set(&port->event, port->socket, EV_READ | EV_PERSIST,
			  server_port_ready_callback, port);
	if (event_add(&port->event, NULL) < 0) {
		log(EVDNS_LOG_WARN, "Error from libevent when adding event for DNS server.");
		/* ???? Do more? */
	}
}

/* set if we are waiting for the ability to write to this server. */
/* if waiting is true then we ask libevent for EV_WRITE events, otherwise */
/* we stop these events. */
static void
nameserver_write_waiting(struct nameserver *ns, char waiting) {
	if (ns->write_waiting == waiting) return;

	ns->write_waiting = waiting;
	(void) event_del(&ns->event);
	event_set(&ns->event, ns->socket, EV_READ | (waiting ? EV_WRITE : 0) | EV_PERSIST,
			nameserver_ready_callback, ns);
	if (event_add(&ns->event, NULL) < 0) {
          log(EVDNS_LOG_WARN, "Error from libevent when adding event for %s",
              debug_ntoa(ns->address));
          /* ???? Do more? */
        }
}

/* a callback function. Called by libevent when the kernel says that */
/* a nameserver socket is ready for writing or reading */
static void
nameserver_ready_callback(int fd, short events, void *arg) {
	struct nameserver *ns = (struct nameserver *) arg;
        (void)fd;

	if (events & EV_WRITE) {
		ns->choked = 0;
		if (!evdns_transmit()) {
			nameserver_write_waiting(ns, 0);
		}
	}
	if (events & EV_READ) {
		nameserver_read(ns);
	}
}

/* a callback function. Called by libevent when the kernel says that */
/* a server socket is ready for writing or reading. */
static void
server_port_ready_callback(int fd, short events, void *arg) {
	struct evdns_server_port *port = (struct evdns_server_port *) arg;
	(void) fd;

	if (events & EV_WRITE) {
		port->choked = 0;
		server_port_flush(port);
	}
	if (events & EV_READ) {
		server_port_read(port);
	}
}

/* This is an inefficient representation; only use it via the dnslabel_table_*
 * functions, so that is can be safely replaced with something smarter later. */
#define MAX_LABELS 128
/* Structures used to implement name compression */
struct dnslabel_entry { char *v; off_t pos; };
struct dnslabel_table {
	int n_labels; /* number of current entries */
	/* map from name to position in message */
	struct dnslabel_entry labels[MAX_LABELS];
};

/* Initialize dnslabel_table. */
static void
dnslabel_table_init(struct dnslabel_table *table)
{
	table->n_labels = 0;
}

/* Free all storage held by table, but not the table itself. */
static void
dnslabel_clear(struct dnslabel_table *table)
{
	int i;
	for (i = 0; i < table->n_labels; ++i)
		free(table->labels[i].v);
	table->n_labels = 0;
}

/* return the position of the label in the current message, or -1 if the label */
/* hasn't been used yet. */
static int
dnslabel_table_get_pos(const struct dnslabel_table *table, const char *label)
{
	int i;
	for (i = 0; i < table->n_labels; ++i) {
		if (!strcmp(label, table->labels[i].v))
			return table->labels[i].pos;
	}
	return -1;
}

/* remember that we've used the label at position pos */
static int
dnslabel_table_add(struct dnslabel_table *table, const char *label, off_t pos)
{
	char *v;
	int p;
	if (table->n_labels == MAX_LABELS)
		return (-1);
	v = strdup(label);
	if (v == NULL)
		return (-1);
	p = table->n_labels++;
	table->labels[p].v = v;
	table->labels[p].pos = pos;

	return (0);
}

/* Converts a string to a length-prefixed set of DNS labels, starting */
/* at buf[j]. name and buf must not overlap. name_len should be the length */
/* of name.	 table is optional, and is used for compression. */
/* */
/* Input: abc.def */
/* Output: <3>abc<3>def<0> */
/* */
/* Returns the first index after the encoded name, or negative on error. */
/*	 -1	 label was > 63 bytes */
/*	 -2	 name too long to fit in buffer. */
/* */
static off_t
dnsname_to_labels(u8 *const buf, size_t buf_len, off_t j,
				  const char *name, const int name_len,
				  struct dnslabel_table *table) {
	const char *end = name + name_len;
	int ref = 0;
	u16 _t;

#define APPEND16(x) do {						   \
		if (j + 2 > (off_t)buf_len)				   \
			goto overflow;						   \
		_t = htons(x);							   \
		memcpy(buf + j, &_t, 2);				   \
		j += 2;									   \
	} while (0)
#define APPEND32(x) do {						   \
		if (j + 4 > (off_t)buf_len)				   \
			goto overflow;						   \
		_t32 = htonl(x);						   \
		memcpy(buf + j, &_t32, 4);				   \
		j += 4;									   \
	} while (0)

	if (name_len > 255) return -2;

	for (;;) {
		const char *const start = name;
		if (table && (ref = dnslabel_table_get_pos(table, name)) >= 0) {
			APPEND16(ref | 0xc000);
			return j;
		}
		name = strchr(name, '.');
		if (!name) {
			const unsigned int label_len = end - start;
			if (label_len > 63) return -1;
			if ((size_t)(j+label_len+1) > buf_len) return -2;
			if (table) dnslabel_table_add(table, start, j);
			buf[j++] = label_len;

			memcpy(buf + j, start, end - start);
			j += end - start;
			break;
		} else {
			/* append length of the label. */
			const unsigned int label_len = name - start;
			if (label_len > 63) return -1;
			if ((size_t)(j+label_len+1) > buf_len) return -2;
			if (table) dnslabel_table_add(table, start, j);
			buf[j++] = label_len;

			memcpy(buf + j, start, name - start);
			j += name - start;
			/* hop over the '.' */
			name++;
		}
	}

	/* the labels must be terminated by a 0. */
	/* It's possible that the name ended in a . */
	/* in which case the zero is already there */
	if (!j || buf[j-1]) buf[j++] = 0;
	return j;
 overflow:
	return (-2);
}

/* Finds the length of a dns request for a DNS name of the given */
/* length. The actual request may be smaller than the value returned */
/* here */
static int
evdns_request_len(const int name_len) {
	return 96 + /* length of the DNS standard header */
		name_len + 2 +
		4;  /* space for the resource type */
}

/* build a dns request packet into buf. buf should be at least as long */
/* as evdns_request_len told you it should be. */
/* */
/* Returns the amount of space used. Negative on error. */
static int
evdns_request_data_build(const char *const name, const int name_len,
    const u16 trans_id, const u16 type, const u16 class,
    u8 *const buf, size_t buf_len) {
	off_t j = 0;  /* current offset into buf */
	u16 _t;  /* used by the macros */

	APPEND16(trans_id);
	APPEND16(0x0100);  /* standard query, recusion needed */
	APPEND16(1);  /* one question */
	APPEND16(0);  /* no answers */
	APPEND16(0);  /* no authority */
	APPEND16(0);  /* no additional */

	j = dnsname_to_labels(buf, buf_len, j, name, name_len, NULL);
	if (j < 0) {
		return (int)j;
	}
	
	APPEND16(type);
	APPEND16(class);

	return (int)j;
 overflow:
	return (-1);
}

/* exported function */
struct evdns_server_port *
evdns_add_server_port(int socket, int is_tcp, evdns_request_callback_fn_type cb, void *user_data)
{
	struct evdns_server_port *port;
	if (!(port = malloc(sizeof(struct evdns_server_port))))
		return NULL;
	memset(port, 0, sizeof(struct evdns_server_port));

	assert(!is_tcp); /* TCP sockets not yet implemented */
	port->socket = socket;
	port->refcnt = 1;
	port->choked = 0;
	port->closing = 0;
	port->user_callback = cb;
	port->user_data = user_data;
	port->pending_replies = NULL;

	event_set(&port->event, port->socket, EV_READ | EV_PERSIST,
			  server_port_ready_callback, port);
	event_add(&port->event, NULL); /* check return. */
	return port;
}

/* exported function */
void
evdns_close_server_port(struct evdns_server_port *port)
{
	if (--port->refcnt == 0)
		server_port_free(port);
	port->closing = 1;
}

/* exported function */
int
evdns_server_request_add_reply(struct evdns_server_request *_req, int section, const char *name, int type, int class, int ttl, int datalen, int is_name, const char *data)
{
	struct server_request *req = TO_SERVER_REQUEST(_req);
	struct server_reply_item **itemp, *item;
	int *countp;

	if (req->response) /* have we already answered? */
		return (-1);

	switch (section) {
	case EVDNS_ANSWER_SECTION:
		itemp = &req->answer;
		countp = &req->n_answer;
		break;
	case EVDNS_AUTHORITY_SECTION:
		itemp = &req->authority;
		countp = &req->n_authority;
		break;
	case EVDNS_ADDITIONAL_SECTION:
		itemp = &req->additional;
		countp = &req->n_additional;
		break;
	default:
		return (-1);
	}
	while (*itemp) {
		itemp = &((*itemp)->next);
	}
	item = malloc(sizeof(struct server_reply_item));
	if (!item)
		return -1;
	item->next = NULL;
	if (!(item->name = strdup(name))) {
		free(item);
		return -1;
	}
	item->type = type;
	item->dns_question_class = class;
	item->ttl = ttl;
	item->is_name = is_name != 0;
	item->datalen = 0;
	item->data = NULL;
	if (data) {
		if (item->is_name) {
			if (!(item->data = strdup(data))) {
				free(item->name);
				free(item);
				return -1;
			}
			item->datalen = (u16)-1;
		} else {
			if (!(item->data = malloc(datalen))) {
				free(item->name);
				free(item);
				return -1;
			}
			item->datalen = datalen;
			memcpy(item->data, data, datalen);
		}
	}

	*itemp = item;
	++(*countp);
	return 0;
}

/* exported function */
int
evdns_server_request_add_a_reply(struct evdns_server_request *req, const char *name, int n, void *addrs, int ttl)
{
	return evdns_server_request_add_reply(
		  req, EVDNS_ANSWER_SECTION, name, TYPE_A, CLASS_INET,
		  ttl, n*4, 0, addrs);
}

/* exported function */
int
evdns_server_request_add_aaaa_reply(struct evdns_server_request *req, const char *name, int n, void *addrs, int ttl)
{
	return evdns_server_request_add_reply(
		  req, EVDNS_ANSWER_SECTION, name, TYPE_AAAA, CLASS_INET,
		  ttl, n*16, 0, addrs);
}

/* exported function */
int
evdns_server_request_add_ptr_reply(struct evdns_server_request *req, struct in_addr *in, const char *inaddr_name, const char *hostname, int ttl)
{
	u32 a;
	char buf[32];
	assert(in || inaddr_name);
	assert(!(in && inaddr_name));
	if (in) {
		a = ntohl(in->s_addr);
		evutil_snprintf(buf, sizeof(buf), "%d.%d.%d.%d.in-addr.arpa",
				(int)(u8)((a	)&0xff),
				(int)(u8)((a>>8 )&0xff),
				(int)(u8)((a>>16)&0xff),
				(int)(u8)((a>>24)&0xff));
		inaddr_name = buf;
	}
	return evdns_server_request_add_reply(
		  req, EVDNS_ANSWER_SECTION, inaddr_name, TYPE_PTR, CLASS_INET,
		  ttl, -1, 1, hostname);
}

/* exported function */
int
evdns_server_request_add_cname_reply(struct evdns_server_request *req, const char *name, const char *cname, int ttl)
{
	return evdns_server_request_add_reply(
		  req, EVDNS_ANSWER_SECTION, name, TYPE_CNAME, CLASS_INET,
		  ttl, -1, 1, cname);
}


static int
evdns_server_request_format_response(struct server_request *req, int err)
{
	unsigned char buf[1500];
	size_t buf_len = sizeof(buf);
	off_t j = 0, r;
	u16 _t;
	u32 _t32;
	int i;
	u16 flags;
	struct dnslabel_table table;

	if (err < 0 || err > 15) return -1;

	/* Set response bit and error code; copy OPCODE and RD fields from
	 * question; copy RA and AA if set by caller. */
	flags = req->base.flags;
	flags |= (0x8000 | err);

	dnslabel_table_init(&table);
	APPEND16(req->trans_id);
	APPEND16(flags);
	APPEND16(req->base.nquestions);
	APPEND16(req->n_answer);
	APPEND16(req->n_authority);
	APPEND16(req->n_additional);

	/* Add questions. */
	for (i=0; i < req->base.nquestions; ++i) {
		const char *s = req->base.questions[i]->name;
		j = dnsname_to_labels(buf, buf_len, j, s, strlen(s), &table);
		if (j < 0) {
			dnslabel_clear(&table);
			return (int) j;
		}
		APPEND16(req->base.questions[i]->type);
		APPEND16(req->base.questions[i]->dns_question_class);
	}

	/* Add answer, authority, and additional sections. */
	for (i=0; i<3; ++i) {
		struct server_reply_item *item;
		if (i==0)
			item = req->answer;
		else if (i==1)
			item = req->authority;
		else
			item = req->additional;
		while (item) {
			r = dnsname_to_labels(buf, buf_len, j, item->name, strlen(item->name), &table);
			if (r < 0)
				goto overflow;
			j = r;

			APPEND16(item->type);
			APPEND16(item->dns_question_class);
			APPEND32(item->ttl);
			if (item->is_name) {
				off_t len_idx = j, name_start;
				j += 2;
				name_start = j;
				r = dnsname_to_labels(buf, buf_len, j, item->data, strlen(item->data), &table);
				if (r < 0)
					goto overflow;
				j = r;
				_t = htons( (short) (j-name_start) );
				memcpy(buf+len_idx, &_t, 2);
			} else {
				APPEND16(item->datalen);
				if (j+item->datalen > (off_t)buf_len)
					goto overflow;
				memcpy(buf+j, item->data, item->datalen);
				j += item->datalen;
			}
			item = item->next;
		}
	}

	if (j > 512) {
overflow:
		j = 512;
		buf[2] |= 0x02; /* set the truncated bit. */
	}

	req->response_len = j;

	if (!(req->response = malloc(req->response_len))) {
		server_request_free_answers(req);
		dnslabel_clear(&table);
		return (-1);
	}
	memcpy(req->response, buf, req->response_len);
	server_request_free_answers(req);
	dnslabel_clear(&table);
	return (0);
}

/* exported function */
int
evdns_server_request_respond(struct evdns_server_request *_req, int err)
{
	struct server_request *req = TO_SERVER_REQUEST(_req);
	struct evdns_server_port *port = req->port;
	int r;
	if (!req->response) {
		if ((r = evdns_server_request_format_response(req, err))<0)
			return r;
	}

	r = sendto(port->socket, req->response, req->response_len, 0,
			   (struct sockaddr*) &req->addr, req->addrlen);
	if (r<0) {
		int sock_err = last_error(port->socket);
		if (! error_is_eagain(sock_err))
			return -1;

		if (port->pending_replies) {
			req->prev_pending = port->pending_replies->prev_pending;
			req->next_pending = port->pending_replies;
			req->prev_pending->next_pending =
				req->next_pending->prev_pending = req;
		} else {
			req->prev_pending = req->next_pending = req;
			port->pending_replies = req;
			port->choked = 1;

			(void) event_del(&port->event);
			event_set(&port->event, port->socket, (port->closing?0:EV_READ) | EV_WRITE | EV_PERSIST, server_port_ready_callback, port);

			if (event_add(&port->event, NULL) < 0) {
				log(EVDNS_LOG_WARN, "Error from libevent when adding event for DNS server");
			}

		}

		return 1;
	}
	if (server_request_free(req))
		return 0;

	if (port->pending_replies)
		server_port_flush(port);

	return 0;
}

/* Free all storage held by RRs in req. */
static void
server_request_free_answers(struct server_request *req)
{
	struct server_reply_item *victim, *next, **list;
	int i;
	for (i = 0; i < 3; ++i) {
		if (i==0)
			list = &req->answer;
		else if (i==1)
			list = &req->authority;
		else
			list = &req->additional;

		victim = *list;
		while (victim) {
			next = victim->next;
			free(victim->name);
			if (victim->data)
				free(victim->data);
			free(victim);
			victim = next;
		}
		*list = NULL;
	}
}

/* Free all storage held by req, and remove links to it. */
/* return true iff we just wound up freeing the server_port. */
static int
server_request_free(struct server_request *req)
{
	int i, rc=1;
	if (req->base.questions) {
		for (i = 0; i < req->base.nquestions; ++i)
			free(req->base.questions[i]);
		free(req->base.questions);
	}

	if (req->port) {
		if (req->port->pending_replies == req) {
			if (req->next_pending)
				req->port->pending_replies = req->next_pending;
			else
				req->port->pending_replies = NULL;
		}
		rc = --req->port->refcnt;
	}

	if (req->response) {
		free(req->response);
	}

	server_request_free_answers(req);

	if (req->next_pending && req->next_pending != req) {
		req->next_pending->prev_pending = req->prev_pending;
		req->prev_pending->next_pending = req->next_pending;
	}

	if (rc == 0) {
		server_port_free(req->port);
		free(req);
		return (1);
	}
	free(req);
	return (0);
}

/* Free all storage held by an evdns_server_port.  Only called when  */
static void
server_port_free(struct evdns_server_port *port)
{
	assert(port);
	assert(!port->refcnt);
	assert(!port->pending_replies);
	if (port->socket > 0) {
		CLOSE_SOCKET(port->socket);
		port->socket = -1;
	}
	(void) event_del(&port->event);
	/* XXXX actually free the port? -NM */
}

/* exported function */
int
evdns_server_request_drop(struct evdns_server_request *_req)
{
	struct server_request *req = TO_SERVER_REQUEST(_req);
	server_request_free(req);
	return 0;
}

/* exported function */
int
evdns_server_request_get_requesting_addr(struct evdns_server_request *_req, struct sockaddr *sa, int addr_len)
{
	struct server_request *req = TO_SERVER_REQUEST(_req);
	if (addr_len < (int)req->addrlen)
		return -1;
	memcpy(sa, &(req->addr), req->addrlen);
	return req->addrlen;
}

#undef APPEND16
#undef APPEND32

/* this is a libevent callback function which is called when a request */
/* has timed out. */
static void
evdns_request_timeout_callback(int fd, short events, void *arg) {
	struct request *const req = (struct request *) arg;
        (void) fd;
        (void) events;

	log(EVDNS_LOG_DEBUG, "Request %lx timed out", (unsigned long) arg);

	req->ns->timedout++;
	if (req->ns->timedout > global_max_nameserver_timeout) {
		req->ns->timedout = 0;
		nameserver_failed(req->ns, "request timed out.");
	}

	(void) evtimer_del(&req->timeout_event);
	if (req->tx_count >= global_max_retransmits) {
		/* this request has failed */
		reply_callback(req, 0, DNS_ERR_TIMEOUT, NULL);
		request_finished(req, &req_head);
	} else {
		/* retransmit it */
		evdns_request_transmit(req);
	}
}

/* try to send a request to a given server. */
/* */
/* return: */
/*   0 ok */
/*   1 temporary failure */
/*   2 other failure */
static int
evdns_request_transmit_to(struct request *req, struct nameserver *server) {
	struct sockaddr_in sin;
	int r;
	memset(&sin, 0, sizeof(sin));
	sin.sin_addr.s_addr = req->ns->address;
	sin.sin_port = req->ns->port;
	sin.sin_family = AF_INET;

	r = sendto(server->socket, req->request, req->request_len, 0,
	    (struct sockaddr*)&sin, sizeof(sin));
	if (r < 0) {
		int err = last_error(server->socket);
		if (error_is_eagain(err)) return 1;
		nameserver_failed(req->ns, strerror(err));
		return 2;
	} else if (r != (int)req->request_len) {
		return 1;  /* short write */
	} else {
		return 0;
	}
}

/* try to send a request, updating the fields of the request */
/* as needed */
/* */
/* return: */
/*   0 ok */
/*   1 failed */
static int
evdns_request_transmit(struct request *req) {
	int retcode = 0, r;

	/* if we fail to send this packet then this flag marks it */
	/* for evdns_transmit */
	req->transmit_me = 1;
	if (req->trans_id == 0xffff) abort();

	if (req->ns->choked) {
		/* don't bother trying to write to a socket */
		/* which we have had EAGAIN from */
		return 1;
	}

	r = evdns_request_transmit_to(req, req->ns);
	switch (r) {
	case 1:
		/* temp failure */
		req->ns->choked = 1;
		nameserver_write_waiting(req->ns, 1);
		return 1;
	case 2:
		/* failed in some other way */
		retcode = 1;
		/* fall through */
	default:
		/* all ok */
		log(EVDNS_LOG_DEBUG,
		    "Setting timeout for request %lx", (unsigned long) req);
		if (evtimer_add(&req->timeout_event, &global_timeout) < 0) {
                  log(EVDNS_LOG_WARN,
		      "Error from libevent when adding timer for request %lx",
                      (unsigned long) req);
                  /* ???? Do more? */
                }
		req->tx_count++;
		req->transmit_me = 0;
		return retcode;
	}
}

static void
nameserver_probe_callback(int result, char type, int count, int ttl, void *addresses, void *arg) {
	struct nameserver *const ns = (struct nameserver *) arg;
        (void) type;
        (void) count;
        (void) ttl;
        (void) addresses;

	if (result == DNS_ERR_NONE || result == DNS_ERR_NOTEXIST) {
		/* this is a good reply */
		nameserver_up(ns);
	} else nameserver_probe_failed(ns);
}

static void
nameserver_send_probe(struct nameserver *const ns) {
	struct request *req;
	/* here we need to send a probe to a given nameserver */
	/* in the hope that it is up now. */

  	log(EVDNS_LOG_DEBUG, "Sending probe to %s", debug_ntoa(ns->address));

	req = request_new(TYPE_A, "www.google.com", DNS_QUERY_NO_SEARCH, nameserver_probe_callback, ns);
        if (!req) return;
	/* we force this into the inflight queue no matter what */
	request_trans_id_set(req, transaction_id_pick());
	req->ns = ns;
	request_submit(req);
}

/* returns: */
/*   0 didn't try to transmit anything */
/*   1 tried to transmit something */
static int
evdns_transmit(void) {
	char did_try_to_transmit = 0;

	if (req_head) {
		struct request *const started_at = req_head, *req = req_head;
		/* first transmit all the requests which are currently waiting */
		do {
			if (req->transmit_me) {
				did_try_to_transmit = 1;
				evdns_request_transmit(req);
			}

			req = req->next;
		} while (req != started_at);
	}

	return did_try_to_transmit;
}

/* exported function */
int
evdns_count_nameservers(void)
{
	const struct nameserver *server = server_head;
	int n = 0;
	if (!server)
		return 0;
	do {
		++n;
		server = server->next;
	} while (server != server_head);
	return n;
}

/* exported function */
int
evdns_clear_nameservers_and_suspend(void)
{
	struct nameserver *server = server_head, *started_at = server_head;
	struct request *req = req_head, *req_started_at = req_head;

	if (!server)
		return 0;
	while (1) {
		struct nameserver *next = server->next;
		(void) event_del(&server->event);
		if (evtimer_initialized(&server->timeout_event))
			(void) evtimer_del(&server->timeout_event);
		if (server->socket >= 0)
			CLOSE_SOCKET(server->socket);
		free(server);
		if (next == started_at)
			break;
		server = next;
	}
	server_head = NULL;
	global_good_nameservers = 0;

	while (req) {
		struct request *next = req->next;
		req->tx_count = req->reissue_count = 0;
		req->ns = NULL;
		/* ???? What to do about searches? */
		(void) evtimer_del(&req->timeout_event);
		req->trans_id = 0;
		req->transmit_me = 0;

		global_requests_waiting++;
		evdns_request_insert(req, &req_waiting_head);
		/* We want to insert these suspended elements at the front of
		 * the waiting queue, since they were pending before any of
		 * the waiting entries were added.  This is a circular list,
		 * so we can just shift the start back by one.*/
		req_waiting_head = req_waiting_head->prev;

		if (next == req_started_at)
			break;
		req = next;
	}
	req_head = NULL;
	global_requests_inflight = 0;

	return 0;
}


/* exported function */
int
evdns_resume(void)
{
	evdns_requests_pump_waiting_queue();
	return 0;
}

static int
_evdns_nameserver_add_impl(unsigned long int address, int port) {
	/* first check to see if we already have this nameserver */

	const struct nameserver *server = server_head, *const started_at = server_head;
	struct nameserver *ns;
	int err = 0;
	if (server) {
		do {
			if (server->address == address) return 3;
			server = server->next;
		} while (server != started_at);
	}

	ns = (struct nameserver *) malloc(sizeof(struct nameserver));
        if (!ns) return -1;

	memset(ns, 0, sizeof(struct nameserver));

	evtimer_set(&ns->timeout_event, nameserver_prod_callback, ns);

	ns->socket = socket(PF_INET, SOCK_DGRAM, 0);
	if (ns->socket < 0) { err = 1; goto out1; }
        evutil_make_socket_nonblocking(ns->socket);

	ns->address = address;
	ns->port = htons(port);
	ns->state = 1;
	event_set(&ns->event, ns->socket, EV_READ | EV_PERSIST, nameserver_ready_callback, ns);
	if (event_add(&ns->event, NULL) < 0) {
          err = 2;
          goto out2;
        }

	log(EVDNS_LOG_DEBUG, "Added nameserver %s", debug_ntoa(address));

	/* insert this nameserver into the list of them */
	if (!server_head) {
		ns->next = ns->prev = ns;
		server_head = ns;
	} else {
		ns->next = server_head->next;
		ns->prev = server_head;
		server_head->next = ns;
		if (server_head->prev == server_head) {
			server_head->prev = ns;
		}
	}

	global_good_nameservers++;

	return 0;

out2:
	CLOSE_SOCKET(ns->socket);
out1:
	free(ns);
	log(EVDNS_LOG_WARN, "Unable to add nameserver %s: error %d", debug_ntoa(address), err);
	return err;
}

/* exported function */
int
evdns_nameserver_add(unsigned long int address) {
	return _evdns_nameserver_add_impl(address, 53);
}

/* exported function */
int
evdns_nameserver_ip_add(const char *ip_as_string) {
	struct in_addr ina;
	int port;
	char buf[20];
	const char *cp;
	cp = strchr(ip_as_string, ':');
	if (! cp) {
		cp = ip_as_string;
		port = 53;
	} else {
		port = strtoint(cp+1);
		if (port < 0 || port > 65535) {
			return 4;
		}
		if ((cp-ip_as_string) >= (int)sizeof(buf)) {
			return 4;
		}
		memcpy(buf, ip_as_string, cp-ip_as_string);
		buf[cp-ip_as_string] = '\0';
		cp = buf;
	}
	if (!inet_aton(cp, &ina)) {
		return 4;
	}
	return _evdns_nameserver_add_impl(ina.s_addr, port);
}

/* insert into the tail of the queue */
static void
evdns_request_insert(struct request *req, struct request **head) {
	if (!*head) {
		*head = req;
		req->next = req->prev = req;
		return;
	}

	req->prev = (*head)->prev;
	req->prev->next = req;
	req->next = *head;
	(*head)->prev = req;
}

static int
string_num_dots(const char *s) {
	int count = 0;
	while ((s = strchr(s, '.'))) {
		s++;
		count++;
	}
	return count;
}

static struct request *
request_new(int type, const char *name, int flags,
    evdns_callback_type callback, void *user_ptr) {
	const char issuing_now =
	    (global_requests_inflight < global_max_requests_inflight) ? 1 : 0;

	const int name_len = strlen(name);
	const int request_max_len = evdns_request_len(name_len);
	const u16 trans_id = issuing_now ? transaction_id_pick() : 0xffff;
	/* the request data is alloced in a single block with the header */
	struct request *const req =
	    (struct request *) malloc(sizeof(struct request) + request_max_len);
	int rlen;
        (void) flags;

        if (!req) return NULL;
	memset(req, 0, sizeof(struct request));

	evtimer_set(&req->timeout_event, evdns_request_timeout_callback, req);

	/* request data lives just after the header */
	req->request = ((u8 *) req) + sizeof(struct request);
	/* denotes that the request data shouldn't be free()ed */
	req->request_appended = 1;
	rlen = evdns_request_data_build(name, name_len, trans_id,
	    type, CLASS_INET, req->request, request_max_len);
	if (rlen < 0)
		goto err1;
	req->request_len = rlen;
	req->trans_id = trans_id;
	req->tx_count = 0;
	req->request_type = type;
	req->user_pointer = user_ptr;
	req->user_callback = callback;
	req->ns = issuing_now ? nameserver_pick() : NULL;
	req->next = req->prev = NULL;

	return req;
err1:
	free(req);
	return NULL;
}

static void
request_submit(struct request *const req) {
	if (req->ns) {
		/* if it has a nameserver assigned then this is going */
		/* straight into the inflight queue */
		evdns_request_insert(req, &req_head);
		global_requests_inflight++;
		evdns_request_transmit(req);
	} else {
		evdns_request_insert(req, &req_waiting_head);
		global_requests_waiting++;
	}
}

/* exported function */
int evdns_resolve_ipv4(const char *name, int flags,
    evdns_callback_type callback, void *ptr) {
	log(EVDNS_LOG_DEBUG, "Resolve requested for %s", name);
	if (flags & DNS_QUERY_NO_SEARCH) {
		struct request *const req =
			request_new(TYPE_A, name, flags, callback, ptr);
		if (req == NULL)
			return (1);
		request_submit(req);
		return (0);
	} else {
		return (search_request_new(TYPE_A, name, flags, callback, ptr));
	}
}

/* exported function */
int evdns_resolve_ipv6(const char *name, int flags,
					   evdns_callback_type callback, void *ptr) {
	log(EVDNS_LOG_DEBUG, "Resolve requested for %s", name);
	if (flags & DNS_QUERY_NO_SEARCH) {
		struct request *const req =
			request_new(TYPE_AAAA, name, flags, callback, ptr);
		if (req == NULL)
			return (1);
		request_submit(req);
		return (0);
	} else {
		return (search_request_new(TYPE_AAAA, name, flags, callback, ptr));
	}
}

int evdns_resolve_reverse(const struct in_addr *in, int flags, evdns_callback_type callback, void *ptr) {
	char buf[32];
	struct request *req;
	u32 a;
	assert(in);
	a = ntohl(in->s_addr);
	evutil_snprintf(buf, sizeof(buf), "%d.%d.%d.%d.in-addr.arpa",
			(int)(u8)((a	)&0xff),
			(int)(u8)((a>>8 )&0xff),
			(int)(u8)((a>>16)&0xff),
			(int)(u8)((a>>24)&0xff));
	log(EVDNS_LOG_DEBUG, "Resolve requested for %s (reverse)", buf);
	req = request_new(TYPE_PTR, buf, flags, callback, ptr);
	if (!req) return 1;
	request_submit(req);
	return 0;
}

int evdns_resolve_reverse_ipv6(const struct in6_addr *in, int flags, evdns_callback_type callback, void *ptr) {
	/* 32 nybbles, 32 periods, "ip6.arpa", NUL. */
	char buf[73];
	char *cp;
	struct request *req;
	int i;
	assert(in);
	cp = buf;
	for (i=15; i >= 0; --i) {
		u8 byte = in->s6_addr[i];
		*cp++ = "0123456789abcdef"[byte & 0x0f];
		*cp++ = '.';
		*cp++ = "0123456789abcdef"[byte >> 4];
		*cp++ = '.';
	}
	assert(cp + strlen("ip6.arpa") < buf+sizeof(buf));
	memcpy(cp, "ip6.arpa", strlen("ip6.arpa")+1);
	log(EVDNS_LOG_DEBUG, "Resolve requested for %s (reverse)", buf);
	req = request_new(TYPE_PTR, buf, flags, callback, ptr);
	if (!req) return 1;
	request_submit(req);
	return 0;
}

/*/////////////////////////////////////////////////////////////////// */
/* Search support */
/* */
/* the libc resolver has support for searching a number of domains */
/* to find a name. If nothing else then it takes the single domain */
/* from the gethostname() call. */
/* */
/* It can also be configured via the domain and search options in a */
/* resolv.conf. */
/* */
/* The ndots option controls how many dots it takes for the resolver */
/* to decide that a name is non-local and so try a raw lookup first. */

struct search_domain {
	int len;
	struct search_domain *next;
	/* the text string is appended to this structure */
};

struct search_state {
	int refcount;
	int ndots;
	int num_domains;
	struct search_domain *head;
};

static struct search_state *global_search_state = NULL;

static void
search_state_decref(struct search_state *const state) {
	if (!state) return;
	state->refcount--;
	if (!state->refcount) {
		struct search_domain *next, *dom;
		for (dom = state->head; dom; dom = next) {
			next = dom->next;
			free(dom);
		}
		free(state);
	}
}

static struct search_state *
search_state_new(void) {
	struct search_state *state = (struct search_state *) malloc(sizeof(struct search_state));
        if (!state) return NULL;
	memset(state, 0, sizeof(struct search_state));
	state->refcount = 1;
	state->ndots = 1;

	return state;
}

static void
search_postfix_clear(void) {
	search_state_decref(global_search_state);

	global_search_state = search_state_new();
}

/* exported function */
void
evdns_search_clear(void) {
	search_postfix_clear();
}

static void
search_postfix_add(const char *domain) {
	int domain_len;
	struct search_domain *sdomain;
	while (domain[0] == '.') domain++;
	domain_len = strlen(domain);

	if (!global_search_state) global_search_state = search_state_new();
        if (!global_search_state) return;
	global_search_state->num_domains++;

	sdomain = (struct search_domain *) malloc(sizeof(struct search_domain) + domain_len);
        if (!sdomain) return;
	memcpy( ((u8 *) sdomain) + sizeof(struct search_domain), domain, domain_len);
	sdomain->next = global_search_state->head;
	sdomain->len = domain_len;

	global_search_state->head = sdomain;
}

/* reverse the order of members in the postfix list. This is needed because, */
/* when parsing resolv.conf we push elements in the wrong order */
static void
search_reverse(void) {
	struct search_domain *cur, *prev = NULL, *next;
	cur = global_search_state->head;
	while (cur) {
		next = cur->next;
		cur->next = prev;
		prev = cur;
		cur = next;
	}

	global_search_state->head = prev;
}

/* exported function */
void
evdns_search_add(const char *domain) {
	search_postfix_add(domain);
}

/* exported function */
void
evdns_search_ndots_set(const int ndots) {
	if (!global_search_state) global_search_state = search_state_new();
        if (!global_search_state) return;
	global_search_state->ndots = ndots;
}

static void
search_set_from_hostname(void) {
	char hostname[HOST_NAME_MAX + 1], *domainname;

	search_postfix_clear();
	if (gethostname(hostname, sizeof(hostname))) return;
	domainname = strchr(hostname, '.');
	if (!domainname) return;
	search_postfix_add(domainname);
}

/* warning: returns malloced string */
static char *
search_make_new(const struct search_state *const state, int n, const char *const base_name) {
	const int base_len = strlen(base_name);
	const char need_to_append_dot = base_name[base_len - 1] == '.' ? 0 : 1;
	struct search_domain *dom;

	for (dom = state->head; dom; dom = dom->next) {
		if (!n--) {
			/* this is the postfix we want */
			/* the actual postfix string is kept at the end of the structure */
			const u8 *const postfix = ((u8 *) dom) + sizeof(struct search_domain);
			const int postfix_len = dom->len;
			char *const newname = (char *) malloc(base_len + need_to_append_dot + postfix_len + 1);
                        if (!newname) return NULL;
			memcpy(newname, base_name, base_len);
			if (need_to_append_dot) newname[base_len] = '.';
			memcpy(newname + base_len + need_to_append_dot, postfix, postfix_len);
			newname[base_len + need_to_append_dot + postfix_len] = 0;
			return newname;
		}
	}

	/* we ran off the end of the list and still didn't find the requested string */
	abort();
	return NULL; /* unreachable; stops warnings in some compilers. */
}

static int
search_request_new(int type, const char *const name, int flags, evdns_callback_type user_callback, void *user_arg) {
	assert(type == TYPE_A || type == TYPE_AAAA);
	if ( ((flags & DNS_QUERY_NO_SEARCH) == 0) &&
	     global_search_state &&
		 global_search_state->num_domains) {
		/* we have some domains to search */
		struct request *req;
		if (string_num_dots(name) >= global_search_state->ndots) {
			req = request_new(type, name, flags, user_callback, user_arg);
			if (!req) return 1;
			req->search_index = -1;
		} else {
			char *const new_name = search_make_new(global_search_state, 0, name);
                        if (!new_name) return 1;
			req = request_new(type, new_name, flags, user_callback, user_arg);
			free(new_name);
			if (!req) return 1;
			req->search_index = 0;
		}
		req->search_origname = strdup(name);
		req->search_state = global_search_state;
		req->search_flags = flags;
		global_search_state->refcount++;
		request_submit(req);
		return 0;
	} else {
		struct request *const req = request_new(type, name, flags, user_callback, user_arg);
		if (!req) return 1;
		request_submit(req);
		return 0;
	}
}

/* this is called when a request has failed to find a name. We need to check */
/* if it is part of a search and, if so, try the next name in the list */
/* returns: */
/*   0 another request has been submitted */
/*   1 no more requests needed */
static int
search_try_next(struct request *const req) {
	if (req->search_state) {
		/* it is part of a search */
		char *new_name;
		struct request *newreq;
		req->search_index++;
		if (req->search_index >= req->search_state->num_domains) {
			/* no more postfixes to try, however we may need to try */
			/* this name without a postfix */
			if (string_num_dots(req->search_origname) < req->search_state->ndots) {
				/* yep, we need to try it raw */
				newreq = request_new(req->request_type, req->search_origname, req->search_flags, req->user_callback, req->user_pointer);
				log(EVDNS_LOG_DEBUG, "Search: trying raw query %s", req->search_origname);
				if (newreq) {
					request_submit(newreq);
					return 0;
				}
			}
			return 1;
		}

		new_name = search_make_new(req->search_state, req->search_index, req->search_origname);
                if (!new_name) return 1;
		log(EVDNS_LOG_DEBUG, "Search: now trying %s (%d)", new_name, req->search_index);
		newreq = request_new(req->request_type, new_name, req->search_flags, req->user_callback, req->user_pointer);
		free(new_name);
		if (!newreq) return 1;
		newreq->search_origname = req->search_origname;
		req->search_origname = NULL;
		newreq->search_state = req->search_state;
		newreq->search_flags = req->search_flags;
		newreq->search_index = req->search_index;
		newreq->search_state->refcount++;
		request_submit(newreq);
		return 0;
	}
	return 1;
}

static void
search_request_finished(struct request *const req) {
	if (req->search_state) {
		search_state_decref(req->search_state);
		req->search_state = NULL;
	}
	if (req->search_origname) {
		free(req->search_origname);
		req->search_origname = NULL;
	}
}

/*/////////////////////////////////////////////////////////////////// */
/* Parsing resolv.conf files */

static void
evdns_resolv_set_defaults(int flags) {
	/* if the file isn't found then we assume a local resolver */
	if (flags & DNS_OPTION_SEARCH) search_set_from_hostname();
	if (flags & DNS_OPTION_NAMESERVERS) evdns_nameserver_ip_add("127.0.0.1");
}

#ifndef HAVE_STRTOK_R
static char *
strtok_r(char *s, const char *delim, char **state) {
	return strtok(s, delim);
}
#endif

/* helper version of atoi which returns -1 on error */
static int
strtoint(const char *const str) {
	char *endptr;
	const int r = strtol(str, &endptr, 10);
	if (*endptr) return -1;
	return r;
}

/* helper version of atoi that returns -1 on error and clips to bounds. */
static int
strtoint_clipped(const char *const str, int min, int max)
{
	int r = strtoint(str);
	if (r == -1)
		return r;
	else if (r<min)
		return min;
	else if (r>max)
		return max;
	else
		return r;
}

/* exported function */
int
evdns_set_option(const char *option, const char *val, int flags)
{
	if (!strncmp(option, "ndots:", 6)) {
		const int ndots = strtoint(val);
		if (ndots == -1) return -1;
		if (!(flags & DNS_OPTION_SEARCH)) return 0;
		log(EVDNS_LOG_DEBUG, "Setting ndots to %d", ndots);
		if (!global_search_state) global_search_state = search_state_new();
		if (!global_search_state) return -1;
		global_search_state->ndots = ndots;
	} else if (!strncmp(option, "timeout:", 8)) {
		const int timeout = strtoint(val);
		if (timeout == -1) return -1;
		if (!(flags & DNS_OPTION_MISC)) return 0;
		log(EVDNS_LOG_DEBUG, "Setting timeout to %d", timeout);
		global_timeout.tv_sec = timeout;
	} else if (!strncmp(option, "max-timeouts:", 12)) {
		const int maxtimeout = strtoint_clipped(val, 1, 255);
		if (maxtimeout == -1) return -1;
		if (!(flags & DNS_OPTION_MISC)) return 0;
		log(EVDNS_LOG_DEBUG, "Setting maximum allowed timeouts to %d",
			maxtimeout);
		global_max_nameserver_timeout = maxtimeout;
	} else if (!strncmp(option, "max-inflight:", 13)) {
		const int maxinflight = strtoint_clipped(val, 1, 65000);
		if (maxinflight == -1) return -1;
		if (!(flags & DNS_OPTION_MISC)) return 0;
		log(EVDNS_LOG_DEBUG, "Setting maximum inflight requests to %d",
			maxinflight);
		global_max_requests_inflight = maxinflight;
	} else if (!strncmp(option, "attempts:", 9)) {
		int retries = strtoint(val);
		if (retries == -1) return -1;
		if (retries > 255) retries = 255;
		if (!(flags & DNS_OPTION_MISC)) return 0;
		log(EVDNS_LOG_DEBUG, "Setting retries to %d", retries);
		global_max_retransmits = retries;
	}
	return 0;
}

static void
resolv_conf_parse_line(char *const start, int flags) {
	char *strtok_state;
	static const char *const delims = " \t";
#define NEXT_TOKEN strtok_r(NULL, delims, &strtok_state)

	char *const first_token = strtok_r(start, delims, &strtok_state);
	if (!first_token) return;

	if (!strcmp(first_token, "nameserver") && (flags & DNS_OPTION_NAMESERVERS)) {
		const char *const nameserver = NEXT_TOKEN;
		struct in_addr ina;

		if (inet_aton(nameserver, &ina)) {
			/* address is valid */
			evdns_nameserver_add(ina.s_addr);
		}
	} else if (!strcmp(first_token, "domain") && (flags & DNS_OPTION_SEARCH)) {
		const char *const domain = NEXT_TOKEN;
		if (domain) {
			search_postfix_clear();
			search_postfix_add(domain);
		}
	} else if (!strcmp(first_token, "search") && (flags & DNS_OPTION_SEARCH)) {
		const char *domain;
		search_postfix_clear();

		while ((domain = NEXT_TOKEN)) {
			search_postfix_add(domain);
		}
		search_reverse();
	} else if (!strcmp(first_token, "options")) {
		const char *option;
		while ((option = NEXT_TOKEN)) {
			const char *val = strchr(option, ':');
			evdns_set_option(option, val ? val+1 : "", flags);
		}
	}
#undef NEXT_TOKEN
}

/* exported function */
/* returns: */
/*   0 no errors */
/*   1 failed to open file */
/*   2 failed to stat file */
/*   3 file too large */
/*   4 out of memory */
/*   5 short read from file */
int
evdns_resolv_conf_parse(int flags, const char *const filename) {
	struct stat st;
	int fd, n, r;
	u8 *resolv;
	char *start;
	int err = 0;

	log(EVDNS_LOG_DEBUG, "Parsing resolv.conf file %s", filename);

	fd = open(filename, O_RDONLY);
	if (fd < 0) {
		evdns_resolv_set_defaults(flags);
		return 1;
	}

	if (fstat(fd, &st)) { err = 2; goto out1; }
	if (!st.st_size) {
		evdns_resolv_set_defaults(flags);
		err = (flags & DNS_OPTION_NAMESERVERS) ? 6 : 0;
		goto out1;
	}
	if (st.st_size > 65535) { err = 3; goto out1; }  /* no resolv.conf should be any bigger */

	resolv = (u8 *) malloc((size_t)st.st_size + 1);
	if (!resolv) { err = 4; goto out1; }

	n = 0;
	while ((r = read(fd, resolv+n, (size_t)st.st_size-n)) > 0) {
		n += r;
		if (n == st.st_size)
			break;
		assert(n < st.st_size);
 	}
	if (r < 0) { err = 5; goto out2; }
	resolv[n] = 0;	 /* we malloced an extra byte; this should be fine. */

	start = (char *) resolv;
	for (;;) {
		char *const newline = strchr(start, '\n');
		if (!newline) {
			resolv_conf_parse_line(start, flags);
			break;
		} else {
			*newline = 0;
			resolv_conf_parse_line(start, flags);
			start = newline + 1;
		}
	}

	if (!server_head && (flags & DNS_OPTION_NAMESERVERS)) {
		/* no nameservers were configured. */
		evdns_nameserver_ip_add("127.0.0.1");
		err = 6;
	}
	if (flags & DNS_OPTION_SEARCH && (!global_search_state || global_search_state->num_domains == 0)) {
		search_set_from_hostname();
	}

out2:
	free(resolv);
out1:
	close(fd);
	return err;
}

#ifdef WIN32
/* Add multiple nameservers from a space-or-comma-separated list. */
static int
evdns_nameserver_ip_add_line(const char *ips) {
	const char *addr;
	char *buf;
	int r;
	while (*ips) {
		while (ISSPACE(*ips) || *ips == ',' || *ips == '\t')
			++ips;
		addr = ips;
		while (ISDIGIT(*ips) || *ips == '.' || *ips == ':')
			++ips;
		buf = malloc(ips-addr+1);
		if (!buf) return 4;
		memcpy(buf, addr, ips-addr);
		buf[ips-addr] = '\0';
		r = evdns_nameserver_ip_add(buf);
		free(buf);
		if (r) return r;
	}
	return 0;
}

typedef DWORD(WINAPI *GetNetworkParams_fn_t)(FIXED_INFO *, DWORD*);

/* Use the windows GetNetworkParams interface in iphlpapi.dll to */
/* figure out what our nameservers are. */
static int
load_nameservers_with_getnetworkparams(void)
{
	/* Based on MSDN examples and inspection of  c-ares code. */
	FIXED_INFO *fixed;
	HMODULE handle = 0;
	ULONG size = sizeof(FIXED_INFO);
	void *buf = NULL;
	int status = 0, r, added_any;
	IP_ADDR_STRING *ns;
	GetNetworkParams_fn_t fn;

	if (!(handle = LoadLibrary("iphlpapi.dll"))) {
		log(EVDNS_LOG_WARN, "Could not open iphlpapi.dll");
		status = -1;
		goto done;
	}
	if (!(fn = (GetNetworkParams_fn_t) GetProcAddress(handle, "GetNetworkParams"))) {
		log(EVDNS_LOG_WARN, "Could not get address of function.");
		status = -1;
		goto done;
	}

	buf = malloc(size);
	if (!buf) { status = 4; goto done; }
	fixed = buf;
	r = fn(fixed, &size);
	if (r != ERROR_SUCCESS && r != ERROR_BUFFER_OVERFLOW) {
		status = -1;
		goto done;
	}
	if (r != ERROR_SUCCESS) {
		free(buf);
		buf = malloc(size);
		if (!buf) { status = 4; goto done; }
		fixed = buf;
		r = fn(fixed, &size);
		if (r != ERROR_SUCCESS) {
			log(EVDNS_LOG_DEBUG, "fn() failed.");
			status = -1;
			goto done;
		}
	}

	assert(fixed);
	added_any = 0;
	ns = &(fixed->DnsServerList);
	while (ns) {
		r = evdns_nameserver_ip_add_line(ns->IpAddress.String);
		if (r) {
			log(EVDNS_LOG_DEBUG,"Could not add nameserver %s to list,error: %d",
				(ns->IpAddress.String),(int)GetLastError());
			status = r;
			goto done;
		} else {
			log(EVDNS_LOG_DEBUG,"Succesfully added %s as nameserver",ns->IpAddress.String);
		}

		added_any++;
		ns = ns->Next;
	}

	if (!added_any) {
		log(EVDNS_LOG_DEBUG, "No nameservers added.");
		status = -1;
	}

 done:
	if (buf)
		free(buf);
	if (handle)
		FreeLibrary(handle);
	return status;
}

static int
config_nameserver_from_reg_key(HKEY key, const char *subkey)
{
	char *buf;
	DWORD bufsz = 0, type = 0;
	int status = 0;

	if (RegQueryValueEx(key, subkey, 0, &type, NULL, &bufsz)
	    != ERROR_MORE_DATA)
		return -1;
	if (!(buf = malloc(bufsz)))
		return -1;

	if (RegQueryValueEx(key, subkey, 0, &type, (LPBYTE)buf, &bufsz)
	    == ERROR_SUCCESS && bufsz > 1) {
		status = evdns_nameserver_ip_add_line(buf);
	}

	free(buf);
	return status;
}

#define SERVICES_KEY "System\\CurrentControlSet\\Services\\"
#define WIN_NS_9X_KEY  SERVICES_KEY "VxD\\MSTCP"
#define WIN_NS_NT_KEY  SERVICES_KEY "Tcpip\\Parameters"

static int
load_nameservers_from_registry(void)
{
	int found = 0;
	int r;
#define TRY(k, name) \
	if (!found && config_nameserver_from_reg_key(k,name) == 0) {	\
		log(EVDNS_LOG_DEBUG,"Found nameservers in %s/%s",#k,name); \
		found = 1;						\
	} else if (!found) {						\
		log(EVDNS_LOG_DEBUG,"Didn't find nameservers in %s/%s", \
		    #k,#name);						\
	}

	if (((int)GetVersion()) > 0) { /* NT */
		HKEY nt_key = 0, interfaces_key = 0;

		if (RegOpenKeyEx(HKEY_LOCAL_MACHINE, WIN_NS_NT_KEY, 0,
				 KEY_READ, &nt_key) != ERROR_SUCCESS) {
			log(EVDNS_LOG_DEBUG,"Couldn't open nt key, %d",(int)GetLastError());
			return -1;
		}
		r = RegOpenKeyEx(nt_key, "Interfaces", 0,
			     KEY_QUERY_VALUE|KEY_ENUMERATE_SUB_KEYS,
			     &interfaces_key);
		if (r != ERROR_SUCCESS) {
			log(EVDNS_LOG_DEBUG,"Couldn't open interfaces key, %d",(int)GetLastError());
			return -1;
		}
		TRY(nt_key, "NameServer");
		TRY(nt_key, "DhcpNameServer");
		TRY(interfaces_key, "NameServer");
		TRY(interfaces_key, "DhcpNameServer");
		RegCloseKey(interfaces_key);
		RegCloseKey(nt_key);
	} else {
		HKEY win_key = 0;
		if (RegOpenKeyEx(HKEY_LOCAL_MACHINE, WIN_NS_9X_KEY, 0,
				 KEY_READ, &win_key) != ERROR_SUCCESS) {
			log(EVDNS_LOG_DEBUG, "Couldn't open registry key, %d", (int)GetLastError());
			return -1;
		}
		TRY(win_key, "NameServer");
		RegCloseKey(win_key);
	}

	if (found == 0) {
		log(EVDNS_LOG_WARN,"Didn't find any nameservers.");
	}

	return found ? 0 : -1;
#undef TRY
}

int
evdns_config_windows_nameservers(void)
{
	if (load_nameservers_with_getnetworkparams() == 0)
		return 0;
	return load_nameservers_from_registry();
}
#endif

int
evdns_init(void)
{
	int res = 0;
#ifdef WIN32
	res = evdns_config_windows_nameservers();
#else
	res = evdns_resolv_conf_parse(DNS_OPTIONS_ALL, "/etc/resolv.conf");
#endif

	return (res);
}

const char *
evdns_err_to_string(int err)
{
    switch (err) {
	case DNS_ERR_NONE: return "no error";
	case DNS_ERR_FORMAT: return "misformatted query";
	case DNS_ERR_SERVERFAILED: return "server failed";
	case DNS_ERR_NOTEXIST: return "name does not exist";
	case DNS_ERR_NOTIMPL: return "query not implemented";
	case DNS_ERR_REFUSED: return "refused";

	case DNS_ERR_TRUNCATED: return "reply truncated or ill-formed";
	case DNS_ERR_UNKNOWN: return "unknown";
	case DNS_ERR_TIMEOUT: return "request timed out";
	case DNS_ERR_SHUTDOWN: return "dns subsystem shut down";
	default: return "[Unknown error code]";
    }
}

void
evdns_shutdown(int fail_requests)
{
	struct nameserver *server, *server_next;
	struct search_domain *dom, *dom_next;

	while (req_head) {
		if (fail_requests)
			reply_callback(req_head, 0, DNS_ERR_SHUTDOWN, NULL);
		request_finished(req_head, &req_head);
	}
	while (req_waiting_head) {
		if (fail_requests)
			reply_callback(req_waiting_head, 0, DNS_ERR_SHUTDOWN, NULL);
		request_finished(req_waiting_head, &req_waiting_head);
	}
	global_requests_inflight = global_requests_waiting = 0;

	for (server = server_head; server; server = server_next) {
		server_next = server->next;
		if (server->socket >= 0)
			CLOSE_SOCKET(server->socket);
		(void) event_del(&server->event);
		if (server->state == 0)
                        (void) event_del(&server->timeout_event);
		free(server);
		if (server_next == server_head)
			break;
	}
	server_head = NULL;
	global_good_nameservers = 0;

	if (global_search_state) {
		for (dom = global_search_state->head; dom; dom = dom_next) {
			dom_next = dom->next;
			free(dom);
		}
		free(global_search_state);
		global_search_state = NULL;
	}
	evdns_log_fn = NULL;
}

#ifdef EVDNS_MAIN
void
main_callback(int result, char type, int count, int ttl,
			  void *addrs, void *orig) {
	char *n = (char*)orig;
	int i;
	for (i = 0; i < count; ++i) {
		if (type == DNS_IPv4_A) {
			printf("%s: %s\n", n, debug_ntoa(((u32*)addrs)[i]));
		} else if (type == DNS_PTR) {
			printf("%s: %s\n", n, ((char**)addrs)[i]);
		}
	}
	if (!count) {
		printf("%s: No answer (%d)\n", n, result);
	}
	fflush(stdout);
}
void
evdns_server_callback(struct evdns_server_request *req, void *data)
{
	int i, r;
	(void)data;
	/* dummy; give 192.168.11.11 as an answer for all A questions,
	 *	give foo.bar.example.com as an answer for all PTR questions. */
	for (i = 0; i < req->nquestions; ++i) {
		u32 ans = htonl(0xc0a80b0bUL);
		if (req->questions[i]->type == EVDNS_TYPE_A &&
			req->questions[i]->dns_question_class == EVDNS_CLASS_INET) {
			printf(" -- replying for %s (A)\n", req->questions[i]->name);
			r = evdns_server_request_add_a_reply(req, req->questions[i]->name,
										  1, &ans, 10);
			if (r<0)
				printf("eeep, didn't work.\n");
		} else if (req->questions[i]->type == EVDNS_TYPE_PTR &&
				   req->questions[i]->dns_question_class == EVDNS_CLASS_INET) {
			printf(" -- replying for %s (PTR)\n", req->questions[i]->name);
			r = evdns_server_request_add_ptr_reply(req, NULL, req->questions[i]->name,
											"foo.bar.example.com", 10);
		} else {
			printf(" -- skipping %s [%d %d]\n", req->questions[i]->name,
				   req->questions[i]->type, req->questions[i]->dns_question_class);
		}
	}

	r = evdns_request_respond(req, 0);
	if (r<0)
		printf("eeek, couldn't send reply.\n");
}

void
logfn(int is_warn, const char *msg) {
  (void) is_warn;
  fprintf(stderr, "%s\n", msg);
}
int
main(int c, char **v) {
	int idx;
	int reverse = 0, verbose = 1, servertest = 0;
	if (c<2) {
		fprintf(stderr, "syntax: %s [-x] [-v] hostname\n", v[0]);
		fprintf(stderr, "syntax: %s [-servertest]\n", v[0]);
		return 1;
	}
	idx = 1;
	while (idx < c && v[idx][0] == '-') {
		if (!strcmp(v[idx], "-x"))
			reverse = 1;
		else if (!strcmp(v[idx], "-v"))
			verbose = 1;
		else if (!strcmp(v[idx], "-servertest"))
			servertest = 1;
		else
			fprintf(stderr, "Unknown option %s\n", v[idx]);
		++idx;
	}
	event_init();
	if (verbose)
		evdns_set_log_fn(logfn);
	evdns_resolv_conf_parse(DNS_OPTION_NAMESERVERS, "/etc/resolv.conf");
	if (servertest) {
		int sock;
		struct sockaddr_in my_addr;
		sock = socket(PF_INET, SOCK_DGRAM, 0);
                evutil_make_socket_nonblocking(sock);
		my_addr.sin_family = AF_INET;
		my_addr.sin_port = htons(10053);
		my_addr.sin_addr.s_addr = INADDR_ANY;
		if (bind(sock, (struct sockaddr*)&my_addr, sizeof(my_addr))<0) {
			perror("bind");
			exit(1);
		}
		evdns_add_server_port(sock, 0, evdns_server_callback, NULL);
	}
	for (; idx < c; ++idx) {
		if (reverse) {
			struct in_addr addr;
			if (!inet_aton(v[idx], &addr)) {
				fprintf(stderr, "Skipping non-IP %s\n", v[idx]);
				continue;
			}
			fprintf(stderr, "resolving %s...\n",v[idx]);
			evdns_resolve_reverse(&addr, 0, main_callback, v[idx]);
		} else {
			fprintf(stderr, "resolving (fwd) %s...\n",v[idx]);
			evdns_resolve_ipv4(v[idx], 0, main_callback, v[idx]);
		}
	}
	fflush(stdout);
	event_dispatch();
	return 0;
}
#endif
