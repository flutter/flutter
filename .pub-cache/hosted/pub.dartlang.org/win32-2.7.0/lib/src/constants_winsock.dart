// Windows Sockets library constants

// ignore_for_file: camel_case_types, constant_identifier_names

// -----------------------------------------------------------------------------
// Socket types
// -----------------------------------------------------------------------------

/// Stream socket.
///
/// A socket type that provides sequenced, reliable, two-way, connection-based
/// byte streams with an OOB data transmission mechanism. This socket type uses
/// the Transmission Control Protocol (TCP) for the Internet address family
/// (AF_INET or AF_INET6).
const SOCK_STREAM = 1;

/// Datagram socket.
///
/// A socket type that supports datagrams, which are connectionless, unreliable
/// buffers of a fixed (typically small) maximum length. This socket type uses
/// the User Datagram Protocol (UDP) for the Internet address family (AF_INET or
/// AF_INET6).
const SOCK_DGRAM = 2;

/// Raw protocol interface.
///
/// A socket type that provides a raw socket that allows an application to
/// manipulate the next upper-layer protocol header. To manipulate the IPv4
/// header, the IP_HDRINCL socket option must be set on the socket. To
/// manipulate the IPv6 header, the IPV6_HDRINCL socket option must be set on
/// the socket.
const SOCK_RAW = 3;

/// Reliably-delivered message.
///
/// A socket type that provides a reliable message datagram. An example of this
/// type is the Pragmatic General Multicast (PGM) multicast protocol
/// implementation in Windows, often referred to as reliable multicast
/// programming.
const SOCK_RDM = 4;

/// Sequenced packet stream.
///
/// A socket type that provides a pseudo-stream packet based on datagrams.
const SOCK_SEQPACKET = 5;

// -----------------------------------------------------------------------------
// Per-socket option types
// -----------------------------------------------------------------------------

/// Enables debug output. Microsoft providers currently do not output any debug
/// information.
const SO_DEBUG = 0x0001;

/// Returns whether a socket is in listening mode. This option is only Valid for
/// connection-oriented protocols. This socket option is not supported for the
/// setting.
const SO_ACCEPTCONN = 0x0002;

/// Allows the socket to be bound to an address that is already in use. For more
/// information, see bind. Not applicable on ATM sockets.
const SO_REUSEADDR = 0x0004;

/// Enables sending keep-alive packets for a socket connection. Not supported on
/// ATM sockets (results in an error).
const SO_KEEPALIVE = 0x0008;

/// Sets whether outgoing data should be sent on interface the socket is bound
/// to and not a routed on some other interface. This option is not supported on
/// ATM sockets (results in an error).
const SO_DONTROUTE = 0x0010;

/// Configures a socket for sending broadcast data.
const SO_BROADCAST = 0x0020;

/// Use the local loopback address when sending data from this socket. This
/// option should only be used when all data sent will also be received
/// locally. This option is not supported by the Windows TCP/IP provider.
const SO_USELOOPBACK = 0x0040;

/// Lingers on close if unsent data is present.
const SO_LINGER = 0x0080;

/// Indicates that out-of-bound data should be returned in-line with regular
/// data. This option is only valid for connection-oriented protocols that
/// support out-of-band data.
const SO_OOBINLINE = 0x0100;

/// Does not block close waiting for unsent data to be sent.
const SO_DONTLINGER = ~SO_LINGER;

/*
 * Additional options.
 */

/// Specifies the total per-socket buffer space reserved for sends.
const SO_SNDBUF = 0x1001;

/// Specifies the total per-socket buffer space reserved for receives.
const SO_RCVBUF = 0x1002;

/// A socket option from BSD UNIX included for backward compatibility. This
/// option sets the minimum number of bytes to process for socket output
/// operations.
const SO_SNDLOWAT = 0x1003;

/// A socket option from BSD UNIX included for backward compatibility. This
/// option sets the minimum number of bytes to process for socket input
/// operations.
const SO_RCVLOWAT = 0x1004;

/// The timeout, in milliseconds, for blocking send calls.
const SO_SNDTIMEO = 0x1005;

/// Sets the timeout, in milliseconds, for blocking receive calls.
const SO_RCVTIMEO = 0x1006;

/// Returns the last error code on this socket. This per-socket error code is
/// not always immediately set.
const SO_ERROR = 0x1007;

/// Returns the socket type for the given socket (SOCK_STREAM or SOCK_DGRAM, for
/// example).
const SO_TYPE = 0x1008;

/*
 * Options for connect and disconnect data and options.  Used only by
 * non-TCP/IP transports such as DECNet, OSI TP4, etc.
 */

/// Additional data, not in the normal network data stream, that is sent with
/// network requests to establish a connection. This option is used by legacy
/// protocols such as DECNet, OSI TP4, and others. This option is not supported
/// by the TCP/IP protocol in Windows.
const SO_CONNDATA = 0x7000;

/// Additional connect option data, not in the normal network data stream, that
/// is sent with network requests to establish a connection. This option is used
/// by legacy protocols such as DECNet, OSI TP4, and others. This option is not
/// supported by the TCP/IP protocol in Windows.
const SO_CONNOPT = 0x7001;

/// Additional data, not in the normal network data stream, that is sent with
/// network requests to disconnect a connection. This option is used by legacy
/// protocols such as DECNet, OSI TP4, and others. This option is not supported
/// by the TCP/IP protocol in Windows.
const SO_DISCDATA = 0x7002;

/// Additional disconnect option data, not in the normal network data stream,
/// that is sent with network requests to disconnect a connection. This option
/// is used by legacy protocols such as DECNet, OSI TP4, and others. This option
/// is not supported by the TCP/IP protocol in Windows.
const SO_DISCOPT = 0x7003;

/// The length, in bytes, of additional data, not in the normal network data
/// stream, that is sent with network requests to establish a connection. This
/// option is used by legacy protocols such as DECNet, OSI TP4, and others. This
/// option is not supported by the TCP/IP protocol in Windows.
const SO_CONNDATALEN = 0x7004;

/// The length, in bytes, of connect option data, not in the normal network data
/// stream, that is sent with network requests to establish a connection. This
/// option is used by legacy protocols such as DECNet, OSI TP4, and others. This
/// option is not supported by the TCP/IP protocol in Windows.
const SO_CONNOPTLEN = 0x7005;

/// The length, in bytes, of additional data, not in the normal network data
/// stream, that is sent with network requests to disconnect a connection. This
/// option is used by legacy protocols such as DECNet, OSI TP4, and others. This
/// option is not supported by the TCP/IP protocol in Windows.
const SO_DISCDATALEN = 0x7006;

/// The length, in bytes, of additional disconnect option data, not in the
/// normal network data stream, that is sent with network requests to disconnect
/// a connection. This option is used by legacy protocols such as DECNet, OSI
/// TP4, and others. This option is not supported by the TCP/IP protocol in
/// Windows.
const SO_DISCOPTLEN = 0x7007;

/*
 * Option for opening sockets for synchronous access.
 */

/// Once set, affects whether subsequent sockets that are created will be
/// non-overlapped. The possible values for this option are SO_SYNCHRONOUS_ALERT
/// and SO_SYNCHRONOUS_NONALERT. This option should not be used. Instead use the
/// WSASocket function and leave the WSA_FLAG_OVERLAPPED bit in the dwFlags
/// parameter turned off
const SO_OPENTYPE = 0x7008;

const SO_SYNCHRONOUS_ALERT = 0x10;
const SO_SYNCHRONOUS_NONALERT = 0x20;

/*
 * Other NT-specific options.
 */

/// Returns the maximum size, in bytes, for outbound datagrams supported by the
/// protocol. This socket option has no meaning for stream-oriented sockets.
const SO_MAXDG = 0x7009;

/// Returns the maximum size, in bytes, for outbound datagrams supported by the
/// protocol to a given destination address. This socket option has no meaning
/// for stream-oriented sockets. Microsoft providers may silently treat this as
/// SO_MAXDG.
const SO_MAXPATHDG = 0x700A;

/// This option is used with the AcceptEx function. This option updates the
/// properties of the socket which are inherited from the listening socket. This
/// option should be set if the getpeername, getsockname, getsockopt, or
/// setsockopt functions are to be used on the accepted socket.
const SO_UPDATE_ACCEPT_CONTEXT = 0x700B;

/// Returns the number of seconds a socket has been connected. This option is
/// only valid for connection-oriented protocols.
const SO_CONNECT_TIME = 0x700C;

/*
 * TCP options.
 */
const TCP_NODELAY = 0x0001;
const TCP_BSDURGENT = 0x7000;

const FD_READ = 0x01;
const FD_WRITE = 0x02;
const FD_OOB = 0x04;
const FD_ACCEPT = 0x08;
const FD_CONNECT = 0x10;
const FD_CLOSE = 0x20;
