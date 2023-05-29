// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Maps FFI prototypes onto the corresponding Win32 API function calls

// THIS FILE IS GENERATED AUTOMATICALLY AND SHOULD NOT BE EDITED DIRECTLY.

// ignore_for_file: unused_import, non_constant_identifier_names
// ignore_for_file: constant_identifier_names, camel_case_types

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../callbacks.dart';
import '../combase.dart';
import '../guid.dart';
import '../structs.g.dart';
import '../variant.dart';

final _ws2_32 = DynamicLibrary.open('ws2_32.dll');

/// The accept function permits an incoming connection attempt on a socket.
///
/// ```c
/// SOCKET accept(
///   SOCKET   s,
///   sockaddr *addr,
///   int      *addrlen
/// );
/// ```
/// {@category winsock}
int accept(int s, Pointer<SOCKADDR> addr, Pointer<Int32> addrlen) =>
    _accept(s, addr, addrlen);

final _accept = _ws2_32.lookupFunction<
    IntPtr Function(IntPtr s, Pointer<SOCKADDR> addr, Pointer<Int32> addrlen),
    int Function(
        int s, Pointer<SOCKADDR> addr, Pointer<Int32> addrlen)>('accept');

/// The bind function associates a local address with a socket.
///
/// ```c
/// int bind(
///   SOCKET         s,
///   const sockaddr *name,
///   int            namelen
/// );
/// ```
/// {@category winsock}
int bind(int s, Pointer<SOCKADDR> name, int namelen) => _bind(s, name, namelen);

final _bind = _ws2_32.lookupFunction<
    Int32 Function(IntPtr s, Pointer<SOCKADDR> name, Int32 namelen),
    int Function(int s, Pointer<SOCKADDR> name, int namelen)>('bind');

/// The closesocket function closes an existing socket.
///
/// ```c
/// int closesocket(
///   SOCKET s
/// );
/// ```
/// {@category winsock}
int closesocket(int s) => _closesocket(s);

final _closesocket =
    _ws2_32.lookupFunction<Int32 Function(IntPtr s), int Function(int s)>(
        'closesocket');

/// The connect function establishes a connection to a specified socket.
///
/// ```c
/// int connect(
///   SOCKET         s,
///   const sockaddr *name,
///   int            namelen
/// );
/// ```
/// {@category winsock}
int connect(int s, Pointer<SOCKADDR> name, int namelen) =>
    _connect(s, name, namelen);

final _connect = _ws2_32.lookupFunction<
    Int32 Function(IntPtr s, Pointer<SOCKADDR> name, Int32 namelen),
    int Function(int s, Pointer<SOCKADDR> name, int namelen)>('connect');

/// The GetAddrInfoW function provides protocol-independent translation from
/// a Unicode host name to an address.
///
/// ```c
/// INT GetAddrInfoW(
///   PCWSTR          pNodeName,
///   PCWSTR          pServiceName,
///   const ADDRINFOW *pHints,
///   PADDRINFOW      *ppResult
/// );
/// ```
/// {@category winsock}
int GetAddrInfo(Pointer<Utf16> pNodeName, Pointer<Utf16> pServiceName,
        Pointer<ADDRINFO> pHints, Pointer<Pointer<ADDRINFO>> ppResult) =>
    _GetAddrInfo(pNodeName, pServiceName, pHints, ppResult);

final _GetAddrInfo = _ws2_32.lookupFunction<
    Int32 Function(Pointer<Utf16> pNodeName, Pointer<Utf16> pServiceName,
        Pointer<ADDRINFO> pHints, Pointer<Pointer<ADDRINFO>> ppResult),
    int Function(
        Pointer<Utf16> pNodeName,
        Pointer<Utf16> pServiceName,
        Pointer<ADDRINFO> pHints,
        Pointer<Pointer<ADDRINFO>> ppResult)>('GetAddrInfoW');

/// The gethostbyaddr function retrieves the host information corresponding
/// to a network address.
///
/// ```c
/// hostent* gethostbyaddr(
///    const char *addr,
///    int        len,
///    int        type
/// );
/// ```
/// {@category winsock}
Pointer<HOSTENT> gethostbyaddr(Pointer<Utf8> addr, int len, int type) =>
    _gethostbyaddr(addr, len, type);

final _gethostbyaddr = _ws2_32.lookupFunction<
    Pointer<HOSTENT> Function(Pointer<Utf8> addr, Int32 len, Int32 type),
    Pointer<HOSTENT> Function(
        Pointer<Utf8> addr, int len, int type)>('gethostbyaddr');

/// The gethostbyname function retrieves host information corresponding to a
/// host name from a host database.
///
/// ```c
/// hostent* gethostbyname(
///   const char *name
/// );
/// ```
/// {@category winsock}
Pointer<HOSTENT> gethostbyname(Pointer<Utf8> name) => _gethostbyname(name);

final _gethostbyname = _ws2_32.lookupFunction<
    Pointer<HOSTENT> Function(Pointer<Utf8> name),
    Pointer<HOSTENT> Function(Pointer<Utf8> name)>('gethostbyname');

/// The gethostname function retrieves the standard host name for the local
/// computer.
///
/// ```c
/// int gethostname(
///   char *name,
///   int  namelen
/// );
/// ```
/// {@category winsock}
int gethostname(Pointer<Utf8> name, int namelen) => _gethostname(name, namelen);

final _gethostname = _ws2_32.lookupFunction<
    Int32 Function(Pointer<Utf8> name, Int32 namelen),
    int Function(Pointer<Utf8> name, int namelen)>('gethostname');

/// The getnameinfo function provides protocol-independent name resolution
/// from an address to an ANSI host name and from a port number to the ANSI
/// service name.
///
/// ```c
/// INT getnameinfo(
///   const SOCKADDR *pSockaddr,
///   socklen_t      SockaddrLength,
///   PCHAR          pNodeBuffer,
///   DWORD          NodeBufferSize,
///   PCHAR          pServiceBuffer,
///   DWORD          ServiceBufferSize,
///   INT            Flags
/// );
/// ```
/// {@category winsock}
int getnameinfo(
        Pointer<SOCKADDR> pSockaddr,
        int SockaddrLength,
        Pointer<Utf8> pNodeBuffer,
        int NodeBufferSize,
        Pointer<Utf8> pServiceBuffer,
        int ServiceBufferSize,
        int Flags) =>
    _getnameinfo(pSockaddr, SockaddrLength, pNodeBuffer, NodeBufferSize,
        pServiceBuffer, ServiceBufferSize, Flags);

final _getnameinfo = _ws2_32.lookupFunction<
    Int32 Function(
        Pointer<SOCKADDR> pSockaddr,
        Int32 SockaddrLength,
        Pointer<Utf8> pNodeBuffer,
        Uint32 NodeBufferSize,
        Pointer<Utf8> pServiceBuffer,
        Uint32 ServiceBufferSize,
        Int32 Flags),
    int Function(
        Pointer<SOCKADDR> pSockaddr,
        int SockaddrLength,
        Pointer<Utf8> pNodeBuffer,
        int NodeBufferSize,
        Pointer<Utf8> pServiceBuffer,
        int ServiceBufferSize,
        int Flags)>('getnameinfo');

/// The getpeername function retrieves the address of the peer to which a
/// socket is connected.
///
/// ```c
/// int getpeername(
///   SOCKET   s,
///   sockaddr *name,
///   int      *namelen
/// );
/// ```
/// {@category winsock}
int getpeername(int s, Pointer<SOCKADDR> name, Pointer<Int32> namelen) =>
    _getpeername(s, name, namelen);

final _getpeername = _ws2_32.lookupFunction<
    Int32 Function(IntPtr s, Pointer<SOCKADDR> name, Pointer<Int32> namelen),
    int Function(
        int s, Pointer<SOCKADDR> name, Pointer<Int32> namelen)>('getpeername');

/// The getprotobyname function retrieves the protocol information
/// corresponding to a protocol name.
///
/// ```c
/// protoent* getprotobyname(
///   const char *name
/// );
/// ```
/// {@category winsock}
Pointer<PROTOENT> getprotobyname(Pointer<Utf8> name) => _getprotobyname(name);

final _getprotobyname = _ws2_32.lookupFunction<
    Pointer<PROTOENT> Function(Pointer<Utf8> name),
    Pointer<PROTOENT> Function(Pointer<Utf8> name)>('getprotobyname');

/// The getprotobynumber function retrieves protocol information
/// corresponding to a protocol number.
///
/// ```c
/// protoent* getprotobynumber(
///   int number
/// );
/// ```
/// {@category winsock}
Pointer<PROTOENT> getprotobynumber(int number) => _getprotobynumber(number);

final _getprotobynumber = _ws2_32.lookupFunction<
    Pointer<PROTOENT> Function(Int32 number),
    Pointer<PROTOENT> Function(int number)>('getprotobynumber');

/// The getservbyname function retrieves service information corresponding
/// to a service name and protocol.
///
/// ```c
/// servent* getservbyname(
///   const char *name,
///   const char *proto
/// );
/// ```
/// {@category winsock}
Pointer<SERVENT> getservbyname(Pointer<Utf8> name, Pointer<Utf8> proto) =>
    _getservbyname(name, proto);

final _getservbyname = _ws2_32.lookupFunction<
    Pointer<SERVENT> Function(Pointer<Utf8> name, Pointer<Utf8> proto),
    Pointer<SERVENT> Function(
        Pointer<Utf8> name, Pointer<Utf8> proto)>('getservbyname');

/// The getservbyport function retrieves service information corresponding
/// to a port and protocol.
///
/// ```c
/// servent* getservbyport(
///   int        port,
///   const char *proto
/// );
/// ```
/// {@category winsock}
Pointer<SERVENT> getservbyport(int port, Pointer<Utf8> proto) =>
    _getservbyport(port, proto);

final _getservbyport = _ws2_32.lookupFunction<
    Pointer<SERVENT> Function(Int32 port, Pointer<Utf8> proto),
    Pointer<SERVENT> Function(int port, Pointer<Utf8> proto)>('getservbyport');

/// The getsockname function retrieves the local name for a socket.
///
/// ```c
/// int getsockname(
///   SOCKET   s,
///   sockaddr *name,
///   int      *namelen
/// );
/// ```
/// {@category winsock}
int getsockname(int s, Pointer<SOCKADDR> name, Pointer<Int32> namelen) =>
    _getsockname(s, name, namelen);

final _getsockname = _ws2_32.lookupFunction<
    Int32 Function(IntPtr s, Pointer<SOCKADDR> name, Pointer<Int32> namelen),
    int Function(
        int s, Pointer<SOCKADDR> name, Pointer<Int32> namelen)>('getsockname');

/// The getsockopt function retrieves a socket option.
///
/// ```c
/// int getsockopt(
///   SOCKET s,
///   int    level,
///   int    optname,
///   char   *optval,
///   int    *optlen
/// );
/// ```
/// {@category winsock}
int getsockopt(int s, int level, int optname, Pointer<Utf8> optval,
        Pointer<Int32> optlen) =>
    _getsockopt(s, level, optname, optval, optlen);

final _getsockopt = _ws2_32.lookupFunction<
    Int32 Function(IntPtr s, Int32 level, Int32 optname, Pointer<Utf8> optval,
        Pointer<Int32> optlen),
    int Function(int s, int level, int optname, Pointer<Utf8> optval,
        Pointer<Int32> optlen)>('getsockopt');

/// The htonl function converts a u_long from host to TCP/IP network byte
/// order (which is big-endian).
///
/// ```c
/// u_long htonl(
///   u_long hostlong
/// );
/// ```
/// {@category winsock}
int htonl(int hostlong) => _htonl(hostlong);

final _htonl = _ws2_32.lookupFunction<Uint32 Function(Uint32 hostlong),
    int Function(int hostlong)>('htonl');

/// The htons function converts a u_short from host to TCP/IP network byte
/// order (which is big-endian).
///
/// ```c
/// u_short htons(
///   u_short hostshort
/// );
/// ```
/// {@category winsock}
int htons(int hostshort) => _htons(hostshort);

final _htons = _ws2_32.lookupFunction<Uint16 Function(Uint16 hostshort),
    int Function(int hostshort)>('htons');

/// The inet_addr function converts a string containing an IPv4
/// dotted-decimal address into a proper address for the IN_ADDR structure.
///
/// ```c
/// unsigned long inet_addr(
///   const char *cp
/// );
/// ```
/// {@category winsock}
int inet_addr(Pointer<Utf8> cp) => _inet_addr(cp);

final _inet_addr = _ws2_32.lookupFunction<Uint32 Function(Pointer<Utf8> cp),
    int Function(Pointer<Utf8> cp)>('inet_addr');

/// The inet_ntoa function converts an (Ipv4) Internet network address into
/// an ASCII string in Internet standard dotted-decimal format.
///
/// ```c
/// char* inet_ntoa(
///   in_addr in
/// );
/// ```
/// {@category winsock}
Pointer<Utf8> inet_ntoa(IN_ADDR in_) => _inet_ntoa(in_);

final _inet_ntoa = _ws2_32.lookupFunction<Pointer<Utf8> Function(IN_ADDR in_),
    Pointer<Utf8> Function(IN_ADDR in_)>('inet_ntoa');

/// The ioctlsocket function controls the I/O mode of a socket.
///
/// ```c
/// int ioctlsocket(
///   SOCKET s,
///   long   cmd,
///   u_long *argp
/// );
/// ```
/// {@category winsock}
int ioctlsocket(int s, int cmd, Pointer<Uint32> argp) =>
    _ioctlsocket(s, cmd, argp);

final _ioctlsocket = _ws2_32.lookupFunction<
    Int32 Function(IntPtr s, Int32 cmd, Pointer<Uint32> argp),
    int Function(int s, int cmd, Pointer<Uint32> argp)>('ioctlsocket');

/// The listen function places a socket in a state in which it is listening
/// for an incoming connection.
///
/// ```c
/// int listen(
///   SOCKET s,
///   int    backlog
/// );
/// ```
/// {@category winsock}
int listen(int s, int backlog) => _listen(s, backlog);

final _listen = _ws2_32.lookupFunction<Int32 Function(IntPtr s, Int32 backlog),
    int Function(int s, int backlog)>('listen');

/// The ntohl function converts a u_long from TCP/IP network order to host
/// byte order (which is little-endian on Intel processors).
///
/// ```c
/// u_long ntohl(
///   u_long netlong
/// );
/// ```
/// {@category winsock}
int ntohl(int netlong) => _ntohl(netlong);

final _ntohl = _ws2_32.lookupFunction<Uint32 Function(Uint32 netlong),
    int Function(int netlong)>('ntohl');

/// The ntohs function converts a u_short from TCP/IP network byte order to
/// host byte order (which is little-endian on Intel processors).
///
/// ```c
/// u_short ntohs(
///   u_short netshort
/// );
/// ```
/// {@category winsock}
int ntohs(int netshort) => _ntohs(netshort);

final _ntohs = _ws2_32.lookupFunction<Uint16 Function(Uint16 netshort),
    int Function(int netshort)>('ntohs');

/// The recv function receives data from a connected socket or a bound
/// connectionless socket.
///
/// ```c
/// int recv(
///   SOCKET s,
///   char   *buf,
///   int    len,
///   int    flags
/// );
/// ```
/// {@category winsock}
int recv(int s, Pointer<Utf8> buf, int len, int flags) =>
    _recv(s, buf, len, flags);

final _recv = _ws2_32.lookupFunction<
    Int32 Function(IntPtr s, Pointer<Utf8> buf, Int32 len, Int32 flags),
    int Function(int s, Pointer<Utf8> buf, int len, int flags)>('recv');

/// The recvfrom function receives a datagram, and stores the source
/// address.
///
/// ```c
/// int recvfrom(
///   SOCKET   s,
///   char     *buf,
///   int      len,
///   int      flags,
///   sockaddr *from,
///   int      *fromlen
/// );
/// ```
/// {@category winsock}
int recvfrom(int s, Pointer<Utf8> buf, int len, int flags,
        Pointer<SOCKADDR> from, Pointer<Int32> fromlen) =>
    _recvfrom(s, buf, len, flags, from, fromlen);

final _recvfrom = _ws2_32.lookupFunction<
    Int32 Function(IntPtr s, Pointer<Utf8> buf, Int32 len, Int32 flags,
        Pointer<SOCKADDR> from, Pointer<Int32> fromlen),
    int Function(int s, Pointer<Utf8> buf, int len, int flags,
        Pointer<SOCKADDR> from, Pointer<Int32> fromlen)>('recvfrom');

/// The select function determines the status of one or more sockets,
/// waiting if necessary, to perform synchronous I/O.
///
/// ```c
/// int select(
///   int           nfds,
///   fd_set        *readfds,
///   fd_set        *writefds,
///   fd_set        *exceptfds,
///   const timeval *timeout
/// );
/// ```
/// {@category winsock}
int select(int nfds, Pointer<FD_SET> readfds, Pointer<FD_SET> writefds,
        Pointer<FD_SET> exceptfds, Pointer<TIMEVAL> timeout) =>
    _select(nfds, readfds, writefds, exceptfds, timeout);

final _select = _ws2_32.lookupFunction<
    Int32 Function(
        Int32 nfds,
        Pointer<FD_SET> readfds,
        Pointer<FD_SET> writefds,
        Pointer<FD_SET> exceptfds,
        Pointer<TIMEVAL> timeout),
    int Function(int nfds, Pointer<FD_SET> readfds, Pointer<FD_SET> writefds,
        Pointer<FD_SET> exceptfds, Pointer<TIMEVAL> timeout)>('select');

/// The send function sends data on a connected socket.
///
/// ```c
/// int send(
///   SOCKET     s,
///   const char *buf,
///   int        len,
///   int        flags
/// );
/// ```
/// {@category winsock}
int send(int s, Pointer<Utf8> buf, int len, int flags) =>
    _send(s, buf, len, flags);

final _send = _ws2_32.lookupFunction<
    Int32 Function(IntPtr s, Pointer<Utf8> buf, Int32 len, Int32 flags),
    int Function(int s, Pointer<Utf8> buf, int len, int flags)>('send');

/// The sendto function sends data to a specific destination.
///
/// ```c
/// int sendto(
///   SOCKET         s,
///   const char     *buf,
///   int            len,
///   int            flags,
///   const sockaddr *to,
///   int            tolen
/// );
/// ```
/// {@category winsock}
int sendto(int s, Pointer<Utf8> buf, int len, int flags, Pointer<SOCKADDR> to,
        int tolen) =>
    _sendto(s, buf, len, flags, to, tolen);

final _sendto = _ws2_32.lookupFunction<
    Int32 Function(IntPtr s, Pointer<Utf8> buf, Int32 len, Int32 flags,
        Pointer<SOCKADDR> to, Int32 tolen),
    int Function(int s, Pointer<Utf8> buf, int len, int flags,
        Pointer<SOCKADDR> to, int tolen)>('sendto');

/// The shutdown function disables sends or receives on a socket.
///
/// ```c
/// int shutdown(
///   SOCKET s,
///   int    how
/// );
/// ```
/// {@category winsock}
int shutdown(int s, int how) => _shutdown(s, how);

final _shutdown = _ws2_32.lookupFunction<Int32 Function(IntPtr s, Int32 how),
    int Function(int s, int how)>('shutdown');

/// The socket function creates a socket that is bound to a specific
/// transport service provider.
///
/// ```c
/// SOCKET socket(
///   int af,
///   int type,
///   int protocol
/// );
/// ```
/// {@category winsock}
int socket(int af, int type, int protocol) => _socket(af, type, protocol);

final _socket = _ws2_32.lookupFunction<
    IntPtr Function(Int32 af, Int32 type, Int32 protocol),
    int Function(int af, int type, int protocol)>('socket');
