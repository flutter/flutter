/*
 * Copyright (c) 2004-2006, 2008, 2009, 2011 Apple Inc. All rights reserved.
 *
 * @APPLE_LICENSE_HEADER_START@
 * 
 * This file contains Original Code and/or Modifications of Original Code
 * as defined in and that are subject to the Apple Public Source License
 * Version 2.0 (the 'License'). You may not use this file except in
 * compliance with the License. Please obtain a copy of the License at
 * http://www.opensource.apple.com/apsl/ and read it before using this
 * file.
 * 
 * The Original Code and all software distributed under the License are
 * distributed on an 'AS IS' basis, WITHOUT WARRANTY OF ANY KIND, EITHER
 * EXPRESS OR IMPLIED, AND APPLE HEREBY DISCLAIMS ALL SUCH WARRANTIES,
 * INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE, QUIET ENJOYMENT OR NON-INFRINGEMENT.
 * Please see the License for the specific language governing rights and
 * limitations under the License.
 * 
 * @APPLE_LICENSE_HEADER_END@
 */

#ifndef __DNSINFO_H__
#define __DNSINFO_H__

/*
 * These routines provide access to the systems DNS configuration
 */

#include <sys/cdefs.h>
#include <stdint.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>

#define	DNSINFO_VERSION		20111104

#define DEFAULT_SEARCH_ORDER    200000   /* search order for the "default" resolver domain name */

#define	DNS_PTR(type, name)				\
	union {						\
		type		name;			\
		uint64_t	_ ## name ## _p;	\
	}

#define	DNS_VAR(type, name)				\
	type	name


#pragma pack(4)
typedef struct {
	struct in_addr	address;
	struct in_addr	mask;
} dns_sortaddr_t;
#pragma pack()


#pragma pack(4)
typedef struct {
	DNS_PTR(char *,			domain);	/* domain */
	DNS_VAR(int32_t,		n_nameserver);	/* # nameserver */
	DNS_PTR(struct sockaddr **,	nameserver);
	DNS_VAR(uint16_t,		port);		/* port (in host byte order) */
	DNS_VAR(int32_t,		n_search);	/* # search */
	DNS_PTR(char **,		search);
	DNS_VAR(int32_t,		n_sortaddr);	/* # sortaddr */
	DNS_PTR(dns_sortaddr_t **,	sortaddr);
	DNS_PTR(char *,			options);	/* options */
	DNS_VAR(uint32_t,		timeout);	/* timeout */
	DNS_VAR(uint32_t,		search_order);	/* search_order */
	DNS_VAR(uint32_t,		if_index);
	DNS_VAR(uint32_t,		flags);
	DNS_VAR(uint32_t,		reach_flags);	/* SCNetworkReachabilityFlags */
	DNS_VAR(uint32_t,		reserved[5]);
} dns_resolver_t;
#pragma pack()


#define DNS_RESOLVER_FLAGS_SCOPED	1		/* configuration is for scoped questions */


#pragma pack(4)
typedef struct {
	DNS_VAR(int32_t,		n_resolver);		/* resolver configurations */
	DNS_PTR(dns_resolver_t **,	resolver);
	DNS_VAR(int32_t,		n_scoped_resolver);	/* "scoped" resolver configurations */
	DNS_PTR(dns_resolver_t **,	scoped_resolver);
	DNS_VAR(uint32_t,		reserved[5]);
} dns_config_t;
#pragma pack()


__BEGIN_DECLS

/*
 * DNS configuration access APIs
 */
const char *
dns_configuration_notify_key    ();

dns_config_t *
dns_configuration_copy		();

void
dns_configuration_free		(dns_config_t	*config);

void
_dns_configuration_ack		(dns_config_t	*config,
				 const char	*bundle_id);

__END_DECLS

#endif	/* __DNSINFO_H__ */
