// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Standard constants exposed by the Win32 API

// ignore_for_file: camel_case_types
// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'macros.dart';

// -----------------------------------------------------------------------------
// General constants
// -----------------------------------------------------------------------------

/// A zero value; used to represent an empty bitmask.
const NULL = 0;

/// Boolean false value returned from the Win32 API
const FALSE = 0;

/// Boolean true value returned from the Win32 API
const TRUE = 1;

/// Success status
const STATUS_SUCCESS = 0;

// Path length
const MAX_PATH = 260;

/// The default locale for the operating system.
const LOCALE_SYSTEM_DEFAULT = 0x0800;

/// The default locale for the user or process.
const LOCALE_USER_DEFAULT = 0x0400;

/// All processor groups.
const ALL_PROCESSOR_GROUPS = 0xFFFF;

// -----------------------------------------------------------------------------
// COM Error Codes
// -----------------------------------------------------------------------------

/// For broadly applicable common status codes such as S_OK.
const FACILITY_NULL = 0;

/// For status codes returned from remote procedure calls.
const FACILITY_RPC = 1;

/// For late-binding IDispatch interface errors.
const FACILITY_DISPATCH = 2;

/// For status codes returned from IStorage or IStream method calls relating to
/// structured storage. Status codes whose code (lower 16 bits) value is in the
/// range of MS-DOS error codes (that is, less than 256) have the same meaning
/// as the corresponding MS-DOS error.
const FACILITY_STORAGE = 3;

/// For most status codes returned from interface methods. The actual meaning of
/// the error is defined by the interface. That is, two HRESULTs with exactly
/// the same 32-bit value returned from two different interfaces might have
/// different meanings.
const FACILITY_ITF = 4;

/// Used to provide a means of handling error codes from functions in the
/// Windows API as an HRESULT. Error codes in 16-bit OLE that duplicated system
/// error codes have also been changed to FACILITY_WIN32.
const FACILITY_WIN32 = 7;

/// Used for additional error codes from Microsoft-defined interfaces.
const FACILITY_WINDOWS = 8;

/// The source of the error code is the Security API layer.
const FACILITY_SSPI = 9;

/// The source of the error code is the Security API layer.
const FACILITY_SECURITY = 9;

/// The source of the error code is the control mechanism.
const FACILITY_CONTROL = 10;

/// The source of the error code is a certificate client or server
const FACILITY_CERT = 11;

/// The source of the error code is Wininet related.
const FACILITY_INTERNET = 12;

/// The code that creates and manages objects of this class is a DLL that runs
/// in the same process as the caller of the function specifying the class
/// context.
const CLSCTX_INPROC_SERVER = 0x1;

/// The code that manages objects of this class is an in-process handler. This
/// is a DLL that runs in the client process and implements client-side
/// structures of this class when instances of the class are accessed remotely.
const CLSCTX_INPROC_HANDLER = 0x2;

/// The EXE code that creates and manages objects of this class runs on same
/// machine but is loaded in a separate process space.
const CLSCTX_LOCAL_SERVER = 0x4;

/// A remote context. The LocalServer32 or LocalService code that creates and
/// manages objects of this class is run on a different computer.
const CLSCTX_REMOTE_SERVER = 0x10;

/// The combination of `CLSCTX_INPROC_SERVER`, `CLSCTX_INPROC_HANDLER`,
/// `CLSCTX_LOCAL_SERVER`, and `CLSCTX_REMOTE_SERVER`.
const CLSCTX_ALL = CLSCTX_INPROC_SERVER |
    CLSCTX_INPROC_HANDLER |
    CLSCTX_LOCAL_SERVER |
    CLSCTX_REMOTE_SERVER;

// -----------------------------------------------------------------------------
// IDispatch constants
// -----------------------------------------------------------------------------

/// The member is invoked as a method. If a property has the same name, both
/// this and the DISPATCH_PROPERTYGET flag can be set.
const DISPATCH_METHOD = 0x1;

/// The member is retrieved as a property or data member.
const DISPATCH_PROPERTYGET = 0x2;

/// The member is changed as a property or data member.
const DISPATCH_PROPERTYPUT = 0x4;

/// The member is changed by a reference assignment, rather than a value
/// assignment. This flag is valid only when the property accepts a reference to
/// an object.
const DISPATCH_PROPERTYPUTREF = 0x8;

// -----------------------------------------------------------------------------
// Error constants
// -----------------------------------------------------------------------------

/// The operation completed successfully.
const ERROR_SUCCESS = 0;

/// The operation completed successfully.
const NO_ERROR = 0;

/// The operation completed successfully.
const SEC_E_OK = 0;

/// Incorrect function.
const ERROR_INVALID_FUNCTION = 1;

/// The system cannot find the file specified.
const ERROR_FILE_NOT_FOUND = 2;

/// The system cannot find the path specified.
const ERROR_PATH_NOT_FOUND = 3;

/// The system cannot open the file.
const ERROR_TOO_MANY_OPEN_FILES = 4;

/// Access is denied.
const ERROR_ACCESS_DENIED = 5;

/// The handle is invalid.
const ERROR_INVALID_HANDLE = 6;

/// The storage control blocks were destroyed.
const ERROR_ARENA_TRASHED = 7;

/// Not enough memory resources are available to process this command.
const ERROR_NOT_ENOUGH_MEMORY = 8;

/// The storage control block address is invalid.
const ERROR_INVALID_BLOCK = 9;

/// The environment is incorrect.
const ERROR_BAD_ENVIRONMENT = 10;

/// An attempt was made to load a program with an incorrect format.
const ERROR_BAD_FORMAT = 11;

/// The access code is invalid.
const ERROR_INVALID_ACCESS = 12;

/// The data is invalid.
const ERROR_INVALID_DATA = 13;

/// Not enough storage is available to complete this operation.
const ERROR_OUTOFMEMORY = 14;

/// The system cannot find the drive specified.
const ERROR_INVALID_DRIVE = 15;

/// The directory cannot be removed.
const ERROR_CURRENT_DIRECTORY = 16;

/// The system cannot move the file to a different disk drive.
const ERROR_NOT_SAME_DEVICE = 17;

/// There are no more files.
const ERROR_NO_MORE_FILES = 18;

/// The media is write protected.
const ERROR_WRITE_PROTECT = 19;

/// The system cannot find the device specified.
const ERROR_BAD_UNIT = 20;

/// The device is not ready.
const ERROR_NOT_READY = 21;

/// The device does not recognize the command.
const ERROR_BAD_COMMAND = 22;

/// Data error (cyclic redundancy check).
const ERROR_CRC = 23;

/// The program issued a command but the command length is incorrect.
const ERROR_BAD_LENGTH = 24;

/// The drive cannot locate a specific area or track on the disk.
const ERROR_SEEK = 25;

/// The specified disk or diskette cannot be accessed.
const ERROR_NOT_DOS_DISK = 26;

/// The drive cannot find the sector requested.
const ERROR_SECTOR_NOT_FOUND = 27;

/// The printer is out of paper.
const ERROR_OUT_OF_PAPER = 28;

/// The system cannot write to the specified device.
const ERROR_WRITE_FAULT = 29;

/// The system cannot read from the specified device.
const ERROR_READ_FAULT = 30;

/// A device attached to the system is not functioning.
const ERROR_GEN_FAILURE = 31;

/// The process cannot access the file because it is being used by another
/// process.
const ERROR_SHARING_VIOLATION = 32;

/// The process cannot access the file because another process has locked a
/// portion of the file.
const ERROR_LOCK_VIOLATION = 33;

/// The wrong diskette is in the drive.
const ERROR_WRONG_DISK = 34;

/// Too many files opened for sharing.
const ERROR_SHARING_BUFFER_EXCEEDED = 36;

/// Reached the end of the file.
const ERROR_HANDLE_EOF = 38;

/// The disk is full.
const ERROR_HANDLE_DISK_FULL = 39;

/// The request is not supported.
const ERROR_NOT_SUPPORTED = 50;

/// Windows cannot find the network path. Verify that the network path is
/// correct and the destination computer is not busy or turned off. If Windows
/// still cannot find the network path, contact your network administrator.
const ERROR_REM_NOT_LIST = 51;

/// You were not connected because a duplicate name exists on the network. If
/// joining a domain, go to System in Control Panel to change the computer name
/// and try again. If joining a workgroup, choose another workgroup name.
const ERROR_DUP_NAME = 52;

/// The network path was not found.
const ERROR_BAD_NETPATH = 53;

/// The network is busy.
const ERROR_NETWORK_BUSY = 54;

/// The specified network resource or device is no longer available.
const ERROR_DEV_NOT_EXIST = 55;

/// The network BIOS command limit has been reached.
const ERROR_TOO_MANY_CMDS = 56;

/// A network adapter hardware error occurred.
const ERROR_ADAP_HDW_ERR = 57;

/// The specified server cannot perform the requested operation.
const ERROR_BAD_NET_RESP = 58;

/// An unexpected network error occurred.
const ERROR_UNEXP_NET_ERR = 59;

/// The remote adapter is not compatible.
const ERROR_BAD_REM_ADAP = 60;

/// The printer queue is full.
const ERROR_PRINTQ_FULL = 61;

/// Space to store the file waiting to be printed is not available on the
/// server.
const ERROR_NO_SPOOL_SPACE = 62;

/// Your file waiting to be printed was deleted.
const ERROR_PRINT_CANCELLED = 63;

/// The specified network name is no longer available.
const ERROR_NETNAME_DELETED = 64;

/// Network access is denied.
const ERROR_NETWORK_ACCESS_DENIED = 65;

/// The network resource type is not correct.
const ERROR_BAD_DEV_TYPE = 66;

/// The network name cannot be found.
const ERROR_BAD_NET_NAME = 67;

/// The name limit for the local computer network adapter card was exceeded.
const ERROR_TOO_MANY_NAMES = 68;

/// The network BIOS session limit was exceeded.
const ERROR_TOO_MANY_SESS = 69;

/// The remote server has been paused or is in the process of being started.
const ERROR_SHARING_PAUSED = 70;

/// No more connections can be made to this remote computer at this time because
/// there are already as many connections as the computer can accept.
const ERROR_REQ_NOT_ACCEP = 71;

/// The specified printer or disk device has been paused.
const ERROR_REDIR_PAUSED = 72;

/// The file exists.
const ERROR_FILE_EXISTS = 80;

/// The directory or file cannot be created.
const ERROR_CANNOT_MAKE = 82;

/// Fail on INT 24.
const ERROR_FAIL_I24 = 83;

/// Storage to process this request is not available.
const ERROR_OUT_OF_STRUCTURES = 84;

/// The local device name is already in use.
const ERROR_ALREADY_ASSIGNED = 85;

/// The specified network password is not correct.
const ERROR_INVALID_PASSWORD = 86;

/// The parameter is incorrect.
const ERROR_INVALID_PARAMETER = 87;

/// A write fault occurred on the network.
const ERROR_NET_WRITE_FAULT = 88;

/// The system cannot start another process at this time.
const ERROR_NO_PROC_SLOTS = 89;

/// Cannot create another system semaphore.
const ERROR_TOO_MANY_SEMAPHORES = 100;

/// The exclusive semaphore is owned by another process.
const ERROR_EXCL_SEM_ALREADY_OWNED = 101;

/// The semaphore is set and cannot be closed.
const ERROR_SEM_IS_SET = 102;

/// The semaphore cannot be set again.
const ERROR_TOO_MANY_SEM_REQUESTS = 103;

/// Cannot request exclusive semaphores at interrupt time.
const ERROR_INVALID_AT_INTERRUPT_TIME = 104;

/// The device is not connected.
const ERROR_DEVICE_NOT_CONNECTED = 1167;

// -----------------------------------------------------------------------------
// Windows Runtime errors
// -----------------------------------------------------------------------------

/// Typename or Namespace was not found in metadata file.
const RO_E_METADATA_NAME_NOT_FOUND = 0x8000000F;

/// Name is an existing namespace rather than a typename.
const RO_E_METADATA_NAME_IS_NAMESPACE = 0x80000010;

/// Typename has an invalid format.
const RO_E_METADATA_INVALID_TYPE_FORMAT = 0x80000011;

/// Metadata file is invalid or corrupted.
const RO_E_INVALID_METADATA_FILE = 0x80000012;

/// The object has been closed.
const RO_E_CLOSED = 0x80000013;

/// Only one thread may access the object during a write operation.
const RO_E_EXCLUSIVE_WRITE = 0x80000014;

/// Operation is prohibited during change notification.
const RO_E_CHANGE_NOTIFICATION_IN_PROGRESS = 0x80000015;

/// The text associated with this error code could not be found.
const RO_E_ERROR_STRING_NOT_FOUND = 0x80000016;

// -----------------------------------------------------------------------------
// Process and file access types
// -----------------------------------------------------------------------------

/// The right to delete the object.
const DELETE = 0x00010000;

/// The right to read the information in the object's security descriptor, not
/// including the information in the system access control list (SACL).
const READ_CONTROL = 0x00020000;

/// The right to modify the discretionary access control list (DACL) in the
/// object's security descriptor.
const WRITE_DAC = 0x00040000;

/// The right to change the owner in the object's security descriptor.
const WRITE_OWNER = 0x00080000;

/// The right to use the object for synchronization. This enables a thread to
/// wait until the object is in the signaled state.
const SYNCHRONIZE = 0x00100000;

/// Combines DELETE, READ_CONTROL, WRITE_DAC, and WRITE_OWNER access.
const STANDARD_RIGHTS_REQUIRED = 0x000F0000;

/// Currently defined to equal READ_CONTROL.
const STANDARD_RIGHTS_READ = READ_CONTROL;

/// Currently defined to equal READ_CONTROL.
const STANDARD_RIGHTS_WRITE = READ_CONTROL;

/// Currently defined to equal READ_CONTROL.
const STANDARD_RIGHTS_EXECUTE = READ_CONTROL;

/// Combines DELETE, READ_CONTROL, WRITE_DAC, WRITE_OWNER, and SYNCHRONIZE
/// access.
const STANDARD_RIGHTS_ALL = 0x001F0000;

/// Specifies access to the system security portion of the security descriptor.
const ACCESS_SYSTEM_SECURITY = 0x01000000;

/// Indicates that the caller is requesting the most access possible to the
/// object.
const MAXIMUM_ALLOWED = 0x02000000;

/// Specifies access control suitable for reading the object.
const GENERIC_READ = 0x80000000;

/// Specifies access control suitable for updating attributes on the object.
const GENERIC_WRITE = 0x40000000;

/// Specifies access control suitable for executing an action on the object.
const GENERIC_EXECUTE = 0x20000000;

/// Specifies all defined access control on the object.
const GENERIC_ALL = 0x10000000;

/// Creates a new file, only if it does not already exist.
const CREATE_NEW = 1;

/// Creates a new file, always.
const CREATE_ALWAYS = 2;

/// Opens a file or device, only if it exists.
const OPEN_EXISTING = 3;

/// Opens a file, always.
const OPEN_ALWAYS = 4;

/// Opens a file and truncates it so that its size is zero bytes, only if it
/// exists.
const TRUNCATE_EXISTING = 5;

// -----------------------------------------------------------------------------
// Access rights for access token objects
// -----------------------------------------------------------------------------

/// Required to attach a primary token to a process. The
/// SE_ASSIGNPRIMARYTOKEN_NAME privilege is also required to accomplish this
/// task.
const TOKEN_ASSIGN_PRIMARY = 0x0001;

/// Required to duplicate an access token.
const TOKEN_DUPLICATE = 0x0002;

/// Required to attach an impersonation access token to a process.
const TOKEN_IMPERSONATE = 0x0004;

/// Required to query an access token.
const TOKEN_QUERY = 0x0008;

/// Required to query the source of an access token.
const TOKEN_QUERY_SOURCE = 0x0010;

/// Required to enable or disable the privileges in an access token.
const TOKEN_ADJUST_PRIVILEGES = 0x0020;

/// Required to adjust the attributes of the groups in an access token.
const TOKEN_ADJUST_GROUPS = 0x0040;

/// Required to change the default owner, primary group, or DACL of an access
/// token.
const TOKEN_ADJUST_DEFAULT = 0x0080;

/// Required to adjust the session ID of an access token. The SE_TCB_NAME
/// privilege is required.
const TOKEN_ADJUST_SESSIONID = 0x0100;

/// Combines all possible access rights for a token.
const TOKEN_ALL_ACCESS = STANDARD_RIGHTS_REQUIRED |
    TOKEN_ASSIGN_PRIMARY |
    TOKEN_DUPLICATE |
    TOKEN_IMPERSONATE |
    TOKEN_QUERY |
    TOKEN_QUERY_SOURCE |
    TOKEN_ADJUST_PRIVILEGES |
    TOKEN_ADJUST_GROUPS |
    TOKEN_ADJUST_DEFAULT |
    TOKEN_ADJUST_SESSIONID;

/// Combines STANDARD_RIGHTS_READ and TOKEN_QUERY.
const TOKEN_READ = STANDARD_RIGHTS_READ | TOKEN_QUERY;

/// Combines STANDARD_RIGHTS_WRITE, TOKEN_ADJUST_PRIVILEGES,
/// TOKEN_ADJUST_GROUPS, and TOKEN_ADJUST_DEFAULT.
const TOKEN_WRITE = STANDARD_RIGHTS_WRITE |
    TOKEN_ADJUST_PRIVILEGES |
    TOKEN_ADJUST_GROUPS |
    TOKEN_ADJUST_DEFAULT;

/// Same as STANDARD_RIGHTS_EXECUTE.
const TOKEN_EXECUTE = STANDARD_RIGHTS_EXECUTE;

// -----------------------------------------------------------------------------
// Heap allocation flags
// -----------------------------------------------------------------------------

/// Serialized access will not be used for this allocation.
const HEAP_NO_SERIALIZE = 0x00000001;

/// The system will raise an exception to indicate a function failure, such as
/// an out-of-memory condition, instead of returning NULL.
const HEAP_GENERATE_EXCEPTIONS = 0x00000004;

/// The allocated memory will be initialized to zero. Otherwise, the memory is
/// not initialized to zero.
const HEAP_ZERO_MEMORY = 0x00000008;

/// There can be no movement when reallocating a memory block.
const HEAP_REALLOC_IN_PLACE_ONLY = 0x00000010;

/// All memory blocks that are allocated from this heap allow code execution, if
/// the hardware enforces data execution prevention.
const HEAP_CREATE_ENABLE_EXECUTE = 0x00040000;

// -----------------------------------------------------------------------------
// Thread execution states
// -----------------------------------------------------------------------------

/// Forces the system to be in the working state by resetting the system idle
/// timer.
const ES_SYSTEM_REQUIRED = 0x00000001;

/// Forces the display to be on by resetting the display idle timer.
const ES_DISPLAY_REQUIRED = 0x00000002;

/// This value is not supported. If ES_USER_PRESENT is combined with other
/// esFlags values, the call will fail and none of the specified states will be
/// set.
const ES_USER_PRESENT = 0x00000004;

/// Enables away mode. This value must be specified with ES_CONTINUOUS.
const ES_AWAYMODE_REQUIRED = 0x00000040;

/// Informs the system that the state being set should remain in effect until
/// the next call that uses ES_CONTINUOUS and one of the other state flags is
/// cleared.
const ES_CONTINUOUS = 0x80000000;

/// The thread is still active.
const STILL_ACTIVE = 259;

// -----------------------------------------------------------------------------
// Version constants
// -----------------------------------------------------------------------------

// The current value must be equal to the specified value.
const VER_EQUAL = 1;

/// The current value must be greater than the specified value.
const VER_GREATER = 2;

/// The current value must be greater than or equal to the specified value.
const VER_GREATER_EQUAL = 3;

/// The current value must be less than the specified value.
const VER_LESS = 4;

/// The current value must be less than or equal to the specified value.
const VER_LESS_EQUAL = 5;

/// All product suites specified in the wSuiteMask member must be present in the
/// current system.
const VER_AND = 6;

/// At least one of the specified product suites must be present in the current
/// system.
const VER_OR = 7;

// -----------------------------------------------------------------------------
// Named pipe flags
// -----------------------------------------------------------------------------

/// The flow of data in the pipe goes from client to server only. This mode
/// gives the server the equivalent of GENERIC_READ access to the pipe. The
/// client must specify GENERIC_WRITE access when connecting to the pipe. If the
/// client must read pipe settings by calling the GetNamedPipeInfo or
/// GetNamedPipeHandleState functions, the client must specify GENERIC_WRITE and
/// FILE_READ_ATTRIBUTES access when connecting to the pipe.
const PIPE_ACCESS_INBOUND = 0x00000001;

/// The flow of data in the pipe goes from server to client only. This mode
/// gives the server the equivalent of GENERIC_WRITE access to the pipe. The
/// client must specify GENERIC_READ access when connecting to the pipe. If the
/// client must change pipe settings by calling the SetNamedPipeHandleState
/// function, the client must specify GENERIC_READ and FILE_WRITE_ATTRIBUTES
/// access when connecting to the pipe.
const PIPE_ACCESS_OUTBOUND = 0x00000002;

/// The pipe is bi-directional; both server and client processes can read from
/// and write to the pipe. This mode gives the server the equivalent of
/// GENERIC_READ and GENERIC_WRITE access to the pipe. The client can specify
/// GENERIC_READ or GENERIC_WRITE, or both, when it connects to the pipe using
/// the CreateFile function.
const PIPE_ACCESS_DUPLEX = 0x00000003;

/// The handle refers to the client end of a named pipe instance. This is the
/// default.
const PIPE_CLIENT_END = 0x00000000;

/// The handle refers to the server end of a named pipe instance. If this value
/// is not specified, the handle refers to the client end of a named pipe
/// instance.
const PIPE_SERVER_END = 0x00000001;

/// Blocking mode is enabled. When the pipe handle is specified in the ReadFile,
/// WriteFile, or ConnectNamedPipe function, the operations are not completed
/// until there is data to read, all data is written, or a client is connected.
/// Use of this mode can mean waiting indefinitely in some situations for a
/// client process to perform an action.
const PIPE_WAIT = 0x00000000;

/// Nonblocking mode is enabled. In this mode, ReadFile, WriteFile, and
/// ConnectNamedPipe always return immediately.
const PIPE_NOWAIT = 0x00000001;

/// Data is read from the pipe as a stream of bytes. This mode can be used with
/// either PIPE_TYPE_MESSAGE or PIPE_TYPE_BYTE.
const PIPE_READMODE_BYTE = 0x00000000;

/// Data is read from the pipe as a stream of messages. This mode can be only
/// used if PIPE_TYPE_MESSAGE is also specified.
const PIPE_READMODE_MESSAGE = 0x00000002;

/// The named pipe is a byte pipe. This is the default.
const PIPE_TYPE_BYTE = 0x00000000;

/// The named pipe is a message pipe. If this value is not specified, the pipe
/// is a byte pipe.
const PIPE_TYPE_MESSAGE = 0x00000004;

/// Connections from remote clients can be accepted and checked against the
/// security descriptor for the pipe.
const PIPE_ACCEPT_REMOTE_CLIENTS = 0x00000000;

/// Connections from remote clients are automatically rejected.
const PIPE_REJECT_REMOTE_CLIENTS = 0x00000008;

/// The number of pipe instances that can be created is limited only by the
/// availability of system resources.
const PIPE_UNLIMITED_INSTANCES = 255;

// -----------------------------------------------------------------------------
// File create flags
// -----------------------------------------------------------------------------

/// Write operations will not go through any intermediate cache, they will go
/// directly to disk.
const FILE_FLAG_WRITE_THROUGH = 0x80000000;

/// The file or device is being opened or created for asynchronous I/O. When
/// subsequent I/O operations are completed on this handle, the event specified
/// in the OVERLAPPED structure will be set to the signaled state. If this flag
/// is specified, the file can be used for simultaneous read and write
/// operations. If this flag is not specified, then I/O operations are
/// serialized, even if the calls to the read and write functions specify an
/// OVERLAPPED structure.
const FILE_FLAG_OVERLAPPED = 0x40000000;

/// The file or device is being opened with no system caching for data reads and
/// writes. This flag does not affect hard disk caching or memory mapped files
const FILE_FLAG_NO_BUFFERING = 0x20000000;

/// Access is intended to be random. The system can use this as a hint to
/// optimize file caching.
const FILE_FLAG_RANDOM_ACCESS = 0x10000000;

/// Access is intended to be sequential from beginning to end. The system can
/// use this as a hint to optimize file caching.
const FILE_FLAG_SEQUENTIAL_SCAN = 0x08000000;

/// The file is to be deleted immediately after all of its handles are closed,
/// which includes the specified handle and any other open or duplicated
/// handles.
const FILE_FLAG_DELETE_ON_CLOSE = 0x04000000;

/// The file is being opened or created for a backup or restore operation. The
/// system ensures that the calling process overrides file security checks when
/// the process has SE_BACKUP_NAME and SE_RESTORE_NAME privileges.
const FILE_FLAG_BACKUP_SEMANTICS = 0x02000000;

/// Access will occur according to POSIX rules. This includes allowing multiple
/// files with names, differing only in case, for file systems that support that
/// naming.
const FILE_FLAG_POSIX_SEMANTICS = 0x01000000;

/// The file or device is being opened with session awareness. If this flag is
/// not specified, then per-session devices (such as a device using RemoteFX USB
/// Redirection) cannot be opened by processes running in session 0. This flag
/// has no effect for callers not in session 0. This flag is supported only on
/// server editions of Windows.
const FILE_FLAG_SESSION_AWARE = 0x00800000;

/// Normal reparse point processing will not occur; CreateFile will attempt to
/// open the reparse point. When a file is opened, a file handle is returned,
/// whether or not the filter that controls the reparse point is operational.
const FILE_FLAG_OPEN_REPARSE_POINT = 0x00200000;

/// The file data is requested, but it should continue to be located in remote
/// storage. It should not be transported back to local storage. This flag is
/// for use by remote storage systems.
const FILE_FLAG_OPEN_NO_RECALL = 0x00100000;

/// If you attempt to create multiple instances of a pipe with this flag,
/// creation of the first instance succeeds, but creation of the next instance
/// fails with ERROR_ACCESS_DENIED.
const FILE_FLAG_FIRST_PIPE_INSTANCE = 0x00080000;

// -----------------------------------------------------------------------------
// Handle flags
// -----------------------------------------------------------------------------

/// If this flag is set, a child process created with the bInheritHandles
/// parameter of CreateProcess set to TRUE will inherit the object handle.
const HANDLE_FLAG_INHERIT = 0x00000001;

/// If this flag is set, calling the CloseHandle function will not close the
/// object handle.
const HANDLE_FLAG_PROTECT_FROM_CLOSE = 0x00000002;

// -----------------------------------------------------------------------------
// Serial port flags
// -----------------------------------------------------------------------------

/// No parity.
const NOPARITY = 0;

/// Odd parity.
const ODDPARITY = 1;

/// Even parity.
const EVENPARITY = 2;

/// Mark parity.
const MARKPARITY = 3;

/// Space parity.
const SPACEPARITY = 4;

/// 1 stop bit.
const ONESTOPBIT = 0;

/// 1.5 stop bits.
const ONE5STOPBITS = 1;

/// 2 stop bits.
const TWOSTOPBITS = 2;

/// 110 bps.
const CBR_110 = 110;

/// 300 bps.
const CBR_300 = 300;

/// 600 bps.
const CBR_600 = 600;

/// 1200 bps.
const CBR_1200 = 1200;

/// 2400 bps.
const CBR_2400 = 2400;

/// 4800 bps.
const CBR_4800 = 4800;

/// 9600 bps.
const CBR_9600 = 9600;

/// 14400 bps.
const CBR_14400 = 14400;

/// 19200 bps.
const CBR_19200 = 19200;

/// 38400 bps.
const CBR_38400 = 38400;

/// 56000 bps.
const CBR_56000 = 56000;

/// 57600 bps.
const CBR_57600 = 57600;

/// 115200 bps.
const CBR_115200 = 115200;

/// 128000 bps.
const CBR_128000 = 128000;

/// 256000 bps.
const CBR_256000 = 256000;

/// Disables the DTR line when the device is opened and leaves it disabled.
const DTR_CONTROL_DISABLE = 0x00;

/// Enables the DTR line when the device is opened and leaves it on.
const DTR_CONTROL_ENABLE = 0x01;

/// Enables DTR handshaking. If handshaking is enabled, it is an error for the
/// application to adjust the line by using the EscapeCommFunction function.
const DTR_CONTROL_HANDSHAKE = 0x02;

/// Disables the RTS line when the device is opened and leaves it disabled.
const RTS_CONTROL_DISABLE = 0x00;

/// Enables the RTS line when the device is opened and leaves it on.
const RTS_CONTROL_ENABLE = 0x01;

/// Enables RTS handshaking. The driver raises the RTS line when the
/// "type-ahead" (input) buffer is less than one-half full and lowers the RTS
/// line when the buffer is more than three-quarters full. If handshaking is
/// enabled, it is an error for the application to adjust the line by using the
/// EscapeCommFunction function.
const RTS_CONTROL_HANDSHAKE = 0x02;

/// Specifies that the RTS line will be high if bytes are available for
/// transmission. After all buffered bytes have been sent, the RTS line will be
/// low.
const RTS_CONTROL_TOGGLE = 0x03;

// -----------------------------------------------------------------------------
// Get Binary Type flags
// -----------------------------------------------------------------------------

/// A 32-bit Windows-based application
const SCS_32BIT_BINARY = 0;

/// An MS-DOS – based application
const SCS_DOS_BINARY = 1;

/// A 16-bit Windows-based application
const SCS_WOW_BINARY = 2;

/// A PIF file that executes an MS-DOS–based application
const SCS_PIF_BINARY = 3;

/// A POSIX–based application
const SCS_POSIX_BINARY = 4;

/// A 16-bit OS/2-based application
const SCS_OS216_BINARY = 5;

/// A 64-bit Windows-based application.
const SCS_64BIT_BINARY = 6;

// -----------------------------------------------------------------------------
// Format message flags
// -----------------------------------------------------------------------------

/// Insert sequences in the message definition are to be ignored and passed
/// through to the output buffer unchanged. This flag is useful for fetching a
/// message for later formatting. If this flag is set, the Arguments parameter
/// is ignored.
const FORMAT_MESSAGE_IGNORE_INSERTS = 0x00000200;

/// The lpSource parameter is a pointer to a null-terminated string that
/// contains a message definition. The message definition may contain insert
/// sequences, just as the message text in a message table resource may. This
/// flag cannot be used with FORMAT_MESSAGE_FROM_HMODULE or
/// FORMAT_MESSAGE_FROM_SYSTEM.
const FORMAT_MESSAGE_FROM_STRING = 0x00000400;

/// The lpSource parameter is a module handle containing the message-table
/// resource(s) to search. If this lpSource handle is NULL, the current
/// process's application image file will be searched. This flag cannot be used
/// with FORMAT_MESSAGE_FROM_STRING.
const FORMAT_MESSAGE_FROM_HMODULE = 0x00000800;

/// The function should search the system message-table resource(s) for the
/// requested message. If this flag is specified with
/// FORMAT_MESSAGE_FROM_HMODULE, the function searches the system message table
/// if the message is not found in the module specified by lpSource. This flag
/// cannot be used with FORMAT_MESSAGE_FROM_STRING.
const FORMAT_MESSAGE_FROM_SYSTEM = 0x00001000;

/// The Arguments parameter is not a va_list structure, but is a pointer to an
/// array of values that represent the arguments.
const FORMAT_MESSAGE_ARGUMENT_ARRAY = 0x00002000;

/// The function ignores regular line breaks in the message definition text. The
/// function stores hard-coded line breaks in the message definition text into
/// the output buffer. The function generates no new line breaks.
const FORMAT_MESSAGE_MAX_WIDTH_MASK = 0x000000FF;

// -----------------------------------------------------------------------------
// StartupInfo flags
// -----------------------------------------------------------------------------

/// The wShowWindow member contains additional information.
const STARTF_USESHOWWINDOW = 0x00000001;

/// The dwXSize and dwYSize members contain additional information.
const STARTF_USESIZE = 0x00000002;

/// The dwX and dwY members contain additional information.
const STARTF_USEPOSITION = 0x00000004;

/// The dwXCountChars and dwYCountChars members contain additional information.
const STARTF_USECOUNTCHARS = 0x00000008;

/// The dwFillAttribute member contains additional information.
const STARTF_USEFILLATTRIBUTE = 0x00000010;

/// Indicates that the process should be run in full-screen mode, rather than in
/// windowed mode. This flag is only valid for console applications running on
/// an x86 computer.
const STARTF_RUNFULLSCREEN = 0x00000020;

/// Indicates that the cursor is in feedback mode for two seconds after
/// CreateProcess is called. The Working in Background cursor is displayed (see
/// the Pointers tab in the Mouse control panel utility).
const STARTF_FORCEONFEEDBACK = 0x00000040;

/// Indicates that the feedback cursor is forced off while the process is
/// starting. The Normal Select cursor is displayed.
const STARTF_FORCEOFFFEEDBACK = 0x00000080;

/// The hStdInput, hStdOutput, and hStdError members contain additional
/// information.
const STARTF_USESTDHANDLES = 0x00000100;

/// The hStdInput member contains additional information.
const STARTF_USEHOTKEY = 0x00000200;

/// The lpTitle member contains the path of the shortcut file (.lnk) that the
/// user invoked to start this process. This is typically set by the shell when
/// a .lnk file pointing to the launched application is invoked. Most
/// applications will not need to set this value.
const STARTF_TITLEISLINKNAME = 0x00000800;

/// The lpTitle member contains an AppUserModelID. This identifier controls how
/// the taskbar and Start menu present the application, and enables it to be
/// associated with the correct shortcuts and Jump Lists. Generally,
/// applications will use the SetCurrentProcessExplicitAppUserModelID and
/// GetCurrentProcessExplicitAppUserModelID functions instead of setting this
/// flag.
const STARTF_TITLEISAPPID = 0x00001000;

/// Indicates that any windows created by the process cannot be pinned on the
/// taskbar.
const STARTF_PREVENTPINNING = 0x00002000;

/// The command line came from an untrusted source.
const STARTF_UNTRUSTEDSOURCE = 0x00008000;

// -----------------------------------------------------------------------------
// WindowStyle constants
// -----------------------------------------------------------------------------

/// The window is active.
const WS_ACTIVECAPTION = 0x0001;

/// The window has a thin-line border.
const WS_BORDER = 0x00800000;

/// The window has a title bar (includes the WS_BORDER style).
const WS_CAPTION = 0x00C00000;

/// The window is a child window. A window with this style cannot have a menu
/// bar. This style cannot be used with the WS_POPUP style.
const WS_CHILD = 0x40000000;

/// Same as the WS_CHILD style.
const WS_CHILDWINDOW = WS_CHILD;

/// Excludes the area occupied by child windows when drawing occurs within the
/// parent window. This style is used when creating the parent window.
const WS_CLIPCHILDREN = 0x02000000;

/// Clips child windows relative to each other; that is, when a particular child
/// window receives a WM_PAINT message, the WS_CLIPSIBLINGS style clips all
/// other overlapping child windows out of the region of the child window to be
/// updated. If WS_CLIPSIBLINGS is not specified and child windows overlap, it
/// is possible, when drawing within the client area of a child window, to draw
/// within the client area of a neighboring child window.
const WS_CLIPSIBLINGS = 0x04000000;

/// The window is initially disabled. A disabled window cannot receive input
/// from the user. To change this after a window has been created, use the
/// EnableWindow function.
const WS_DISABLED = 0x08000000;

/// The window has a border of a style typically used with dialog boxes. A
/// window with this style cannot have a title bar.
const WS_DLGFRAME = 0x00400000;

/// The window is the first control of a group of controls.
///
/// The group consists of this first control and all controls defined after it,
/// up to the next control with the WS_GROUP style. The first control in each
/// group usually has the WS_TABSTOP style so that the user can move from group
/// to group. The user can subsequently change the keyboard focus from one
/// control in the group to the next control in the group by using the direction
/// keys.
///
/// You can turn this style on and off to change dialog box navigation. To
/// change this style after a window has been created, use the SetWindowLong
/// function.
const WS_GROUP = 0x00020000;

/// The window has a horizontal scroll bar.
const WS_HSCROLL = 0x00100000;

/// The window is initially minimized. Same as the WS_MINIMIZE style.
const WS_ICONIC = WS_MINIMIZE;

/// The window is initially maximized.
const WS_MAXIMIZE = 0x01000000;

/// The window has a maximize button. Cannot be combined with the
/// WS_EX_CONTEXTHELP style. The WS_SYSMENU style must also be specified.
const WS_MAXIMIZEBOX = 0x00010000;

/// The window is initially minimized. Same as the WS_ICONIC style.
const WS_MINIMIZE = 0x20000000;

/// The window has a minimize button. Cannot be combined with the
/// WS_EX_CONTEXTHELP style. The WS_SYSMENU style must also be specified.
const WS_MINIMIZEBOX = 0x00020000;

/// The window is an overlapped window. An overlapped window has a title bar and
/// a border. Same as the WS_TILED style.
const WS_OVERLAPPED = 0x00000000;

/// The window is an overlapped window. Same as the WS_TILEDWINDOW style.
const WS_OVERLAPPEDWINDOW = WS_OVERLAPPED |
    WS_CAPTION |
    WS_SYSMENU |
    WS_THICKFRAME |
    WS_MINIMIZEBOX |
    WS_MAXIMIZEBOX;

/// The window is a pop-up window. This style cannot be used with the WS_CHILD
/// style.
const WS_POPUP = 0x80000000;

/// The window is a pop-up window. The WS_CAPTION and WS_POPUPWINDOW styles must
/// be combined to make the window menu visible.
const WS_POPUPWINDOW = WS_POPUP | WS_BORDER | WS_SYSMENU;

/// The window has a sizing border. Same as the WS_THICKFRAME style.
const WS_SIZEBOX = WS_THICKFRAME;

/// The window has a window menu on its title bar. The WS_CAPTION style must
/// also be specified.
const WS_SYSMENU = 0x00080000;

/// The window is a control that can receive the keyboard focus when the user
/// presses the TAB key.
///
/// Pressing the TAB key changes the keyboard focus to the next control with the
/// WS_TABSTOP style.
///
/// You can turn this style on and off to change dialog box navigation. To
/// change this style after a window has been created, use the SetWindowLong
/// function. For user-created windows and modeless dialogs to work with tab
/// stops, alter the message loop to call the IsDialogMessage function.
const WS_TABSTOP = 0x00010000;

/// The window has a sizing border. Same as the WS_SIZEBOX style.
const WS_THICKFRAME = 0x00040000;

/// The window is an overlapped window. An overlapped window has a title bar and
/// a border. Same as the WS_OVERLAPPED style.
const WS_TILED = WS_OVERLAPPED;

/// The window is an overlapped window. Same as the WS_OVERLAPPEDWINDOW style.
const WS_TILEDWINDOW = WS_OVERLAPPEDWINDOW;

/// The window is initially visible.
///
/// This style can be turned on and off by using the ShowWindow or SetWindowPos
/// function.
const WS_VISIBLE = 0x10000000;

/// The window has a vertical scroll bar.
const WS_VSCROLL = 0x00200000;

/// The window has a double border; the window can, optionally, be created with
/// a title bar by specifying the WS_CAPTION style in the dwStyle parameter.
const WS_EX_DLGMODALFRAME = 0x00000001;

/// The child window created with this style does not send the WM_PARENTNOTIFY
/// message to its parent window when it is created or destroyed.
const WS_EX_NOPARENTNOTIFY = 0x00000004;

/// The window should be placed above all non-topmost windows and should stay
/// above them, even when the window is deactivated. To add or remove this
/// style, use the SetWindowPos function.
const WS_EX_TOPMOST = 0x00000008;

/// The window accepts drag-drop files.
const WS_EX_ACCEPTFILES = 0x00000010;

/// The window should not be painted until siblings beneath the window (that
/// were created by the same thread) have been painted. The window appears
/// transparent because the bits of underlying sibling windows have already been
/// painted.
const WS_EX_TRANSPARENT = 0x00000020;

/// The window is a MDI child window.
const WS_EX_MDICHILD = 0x00000040;

/// The window is intended to be used as a floating toolbar. A tool window has a
/// title bar that is shorter than a normal title bar, and the window title is
/// drawn using a smaller font. A tool window does not appear in the taskbar or
/// in the dialog that appears when the user presses ALT+TAB. If a tool window
/// has a system menu, its icon is not displayed on the title bar. However, you
/// can display the system menu by right-clicking or by typing ALT+SPACE.
const WS_EX_TOOLWINDOW = 0x00000080;

/// The window has a border with a raised edge.
const WS_EX_WINDOWEDGE = 0x00000100;

/// The window has a border with a sunken edge.
const WS_EX_CLIENTEDGE = 0x00000200;

/// The title bar of the window includes a question mark.
///
/// When the user clicks the question mark, the cursor changes to a question
/// mark with a pointer. If the user then clicks a child window, the child
/// receives a WM_HELP message. The child window should pass the message to the
/// parent window procedure, which should call the WinHelp function using the
/// HELP_WM_HELP command. The Help application displays a pop-up window that
/// typically contains help for the child window. WS_EX_CONTEXTHELP cannot be
/// used with the WS_MAXIMIZEBOX or WS_MINIMIZEBOX styles.
const WS_EX_CONTEXTHELP = 0x00000400;

/// The window has generic "right-aligned" properties. This depends on the
/// window class. This style has an effect only if the shell language is Hebrew,
/// Arabic, or another language that supports reading-order alignment;
/// otherwise, the style is ignored.
const WS_EX_RIGHT = 0x00001000;

/// The window has generic left-aligned properties. This is the default.
const WS_EX_LEFT = 0x00000000;

/// If the shell language is Hebrew, Arabic, or another language that supports
/// reading-order alignment, the window text is displayed using right-to-left
/// reading-order properties. For other languages, the style is ignored.
const WS_EX_RTLREADING = 0x00002000;

/// The window text is displayed using left-to-right reading-order properties.
/// This is the default.
const WS_EX_LTRREADING = 0x00000000;

/// If the shell language is Hebrew, Arabic, or another language that supports
/// reading order alignment, the vertical scroll bar (if present) is to the left
/// of the client area. For other languages, the style is ignored.
const WS_EX_LEFTSCROLLBAR = 0x00004000;

/// The vertical scroll bar (if present) is to the right of the client area.
/// This is the default.
const WS_EX_RIGHTSCROLLBAR = 0x00000000;

/// The window itself contains child windows that should take part in dialog box
/// navigation.
///
/// If this style is specified, the dialog manager recurses into children of
/// this window when performing navigation operations such as handling the TAB
/// key, an arrow key, or a keyboard mnemonic.
const WS_EX_CONTROLPARENT = 0x00010000;

/// The window has a three-dimensional border style intended to be used for
/// items that do not accept user input.
const WS_EX_STATICEDGE = 0x00020000;

/// Forces a top-level window onto the taskbar when the window is visible.
const WS_EX_APPWINDOW = 0x00040000;

/// The window is an overlapped window.
const WS_EX_OVERLAPPEDWINDOW = WS_EX_WINDOWEDGE | WS_EX_CLIENTEDGE;

/// The window is palette window, which is a modeless dialog box that presents
/// an array of commands.
const WS_EX_PALETTEWINDOW = WS_EX_WINDOWEDGE | WS_EX_TOOLWINDOW | WS_EX_TOPMOST;

/// The window is a layered window. This style cannot be used if the window has
/// a class style of either CS_OWNDC or CS_CLASSDC.
const WS_EX_LAYERED = 0x00080000;

/// The window does not pass its window layout to its child windows.
const WS_EX_NOINHERITLAYOUT = 0x00100000;

/// The window does not render to a redirection surface. This is for windows
/// that do not have visible content or that use mechanisms other than surfaces
/// to provide their visual.
const WS_EX_NOREDIRECTIONBITMAP = 0x00200000;

/// If the shell language is Hebrew, Arabic, or another language that supports
/// reading order alignment, the horizontal origin of the window is on the right
/// edge. Increasing horizontal values advance to the left.
const WS_EX_LAYOUTRTL = 0x00400000;

/// Paints all descendants of a window in bottom-to-top painting order using
/// double-buffering.
///
/// Bottom-to-top painting order allows a descendent window to have translucency
/// (alpha) and transparency (color-key) effects, but only if the descendent
/// window also has the WS_EX_TRANSPARENT bit set. Double-buffering allows the
/// window and its descendents to be painted without flicker. This cannot be
/// used if the window has a class style of either CS_OWNDC or CS_CLASSDC.
const WS_EX_COMPOSITED = 0x02000000;

/// A top-level window created with this style does not become the foreground
/// window when the user clicks it. The system does not bring this window to the
/// foreground when the user minimizes or closes the foreground window.
const WS_EX_NOACTIVATE = 0x08000000;

// -----------------------------------------------------------------------------
// WindowMessage constants
// -----------------------------------------------------------------------------

/// Performs no operation.
///
/// An application sends the WM_NULL message if it wants to post a message that
/// the recipient window will ignore.
const WM_NULL = 0x0000;

/// Sent when an application requests that a window be created by calling the
/// CreateWindowEx or CreateWindow function.
///
/// (The message is sent before the function returns.) The window procedure of
/// the new window receives this message after the window is created, but before
/// the window becomes visible.
const WM_CREATE = 0x0001;

/// Sent when a window is being destroyed.
///
/// It is sent to the window procedure of the window being destroyed after the
/// window is removed from the screen.
///
/// This message is sent first to the window being destroyed and then to the
/// child windows (if any) as they are destroyed. During the processing of the
/// message, it can be assumed that all child windows still exist.
const WM_DESTROY = 0x0002;

/// Sent after a window has been moved.
const WM_MOVE = 0x0003;

/// Sent to a window after its size has changed.
const WM_SIZE = 0x0005;

/// Sent to both the window being activated and the window being deactivated.
///
/// If the windows use the same input queue, the message is sent synchronously,
/// first to the window procedure of the top-level window being deactivated,
/// then to the window procedure of the top-level window being activated. If the
/// windows use different input queues, the message is sent asynchronously, so
/// the window is activated immediately.
const WM_ACTIVATE = 0x0006;

/// Sent to a window after it has gained the keyboard focus.
const WM_SETFOCUS = 0x0007;

/// Sent to a window immediately before it loses the keyboard focus.
const WM_KILLFOCUS = 0x0008;

/// Sent when an application changes the enabled state of a window.
///
/// It is sent to the window whose enabled state is changing. This message is
/// sent before the EnableWindow function returns, but after the enabled state
/// (WS_DISABLED style bit) of the window has changed.
const WM_ENABLE = 0x000A;

/// An application sends the WM_SETREDRAW message to a window to allow changes
/// in that window to be redrawn or to prevent changes in that window from being
/// redrawn.
const WM_SETREDRAW = 0x000B;

/// Sets the text of a window.
const WM_SETTEXT = 0x000C;

/// Copies the text that corresponds to a window into a buffer provided by the
/// caller.
const WM_GETTEXT = 0x000D;

/// Determines the length, in characters, of the text associated with a window.
const WM_GETTEXTLENGTH = 0x000E;

/// The WM_PAINT message is sent when the system or another application makes a
/// request to paint a portion of an application's window.
///
/// The message is sent when the UpdateWindow or RedrawWindow function is
/// called, or by the DispatchMessage function when the application obtains a
/// WM_PAINT message by using the GetMessage or PeekMessage function.
const WM_PAINT = 0x000F;

/// Sent as a signal that a window or an application should terminate.
const WM_CLOSE = 0x0010;

/// The WM_QUERYENDSESSION message is sent when the user chooses to end the
/// session or when an application calls one of the system shutdown functions.
///
/// If any application returns zero, the session is not ended. The system stops
/// sending WM_QUERYENDSESSION messages as soon as one application returns zero.
///
/// After processing this message, the system sends the WM_ENDSESSION message
/// with the wParam parameter set to the results of the WM_QUERYENDSESSION
/// message.
const WM_QUERYENDSESSION = 0x0011;

/// Sent to an icon when the user requests that the window be restored to its
/// previous size and position.
const WM_QUERYOPEN = 0x0013;

/// The WM_ENDSESSION message is sent to an application after the system
/// processes the results of the WM_QUERYENDSESSION message. The WM_ENDSESSION
/// message informs the application whether the session is ending.
const WM_ENDSESSION = 0x0016;

/// Indicates a request to terminate an application, and is generated when the
/// application calls the PostQuitMessage function. This message causes the
/// GetMessage function to return zero.
const WM_QUIT = 0x0012;

/// Sent when the window background must be erased (for example, when a window
/// is resized). The message is sent to prepare an invalidated portion of a
/// window for painting.
const WM_ERASEBKGND = 0x0014;

/// The WM_SYSCOLORCHANGE message is sent to all top-level windows when a change
/// is made to a system color setting.
const WM_SYSCOLORCHANGE = 0x0015;

/// Sent to a window when the window is about to be hidden or shown.
const WM_SHOWWINDOW = 0x0018;

/// An application sends the WM_WININICHANGE message to all top-level windows
/// after making a change to the WIN.INI file. The SystemParametersInfo function
/// sends this message after an application uses the function to change a
/// setting in WIN.INI.
const WM_WININICHANGE = 0x001A;

/// A message that is sent to all top-level windows when the
/// SystemParametersInfo function changes a system-wide setting or when policy
/// settings have changed.
///
/// Applications should send WM_SETTINGCHANGE to all top-level windows when they
/// make changes to system parameters. (This message cannot be sent directly to
/// a window.) To send the WM_SETTINGCHANGE message to all top-level windows,
/// use the SendMessageTimeout function with the hwnd parameter set to
/// HWND_BROADCAST.
const WM_SETTINGCHANGE = WM_WININICHANGE;

/// The WM_DEVMODECHANGE message is sent to all top-level windows whenever the
/// user changes device-mode settings.
const WM_DEVMODECHANGE = 0x001B;

/// Sent when a window belonging to a different application than the active
/// window is about to be activated. The message is sent to the application
/// whose window is being activated and to the application whose window is being
/// deactivated.
const WM_ACTIVATEAPP = 0x001C;

/// An application sends the WM_FONTCHANGE message to all top-level windows in
/// the system after changing the pool of font resources.
const WM_FONTCHANGE = 0x001D;

/// A message that is sent whenever there is a change in the system time.
const WM_TIMECHANGE = 0x001E;

/// Sent to cancel certain modes, such as mouse capture. For example, the system
/// sends this message to the active window when a dialog box or message box is
/// displayed. Certain functions also send this message explicitly to the
/// specified window regardless of whether it is the active window. For example,
/// the EnableWindow function sends this message when disabling the specified
/// window.
const WM_CANCELMODE = 0x001F;

/// Sent to a window if the mouse causes the cursor to move within a window and
/// mouse input is not captured.
const WM_SETCURSOR = 0x0020;

/// Sent when the cursor is in an inactive window and the user presses a mouse
/// button. The parent window receives this message only if the child window
/// passes it to the DefWindowProc function.
const WM_MOUSEACTIVATE = 0x0021;

/// Sent to a child window when the user clicks the window's title bar or when
/// the window is activated, moved, or sized.
const WM_CHILDACTIVATE = 0x0022;

/// Sent by a computer-based training (CBT) application to separate user-input
/// messages from other messages sent through the WH_JOURNALPLAYBACK procedure.
const WM_QUEUESYNC = 0x0023;

/// Sent to a window when the size or position of the window is about to change.
/// An application can use this message to override the window's default
/// maximized size and position, or its default minimum or maximum tracking
/// size.
const WM_GETMINMAXINFO = 0x0024;

/// Deprecated. This message is not sent in modern versions of Windows.
const WM_PAINTICON = 0x0026;

/// Deprecated. This message is not sent in modern versions of Windows.
const WM_ICONERASEBKGND = 0x0027;

/// Sent to a dialog box procedure to set the keyboard focus to a different
/// control in the dialog box.
const WM_NEXTDLGCTL = 0x0028;

/// The WM_SPOOLERSTATUS message is sent from Print Manager whenever a job is
/// added to or removed from the Print Manager queue.
const WM_SPOOLERSTATUS = 0x002A;

/// Sent to the parent window of an owner-drawn button, combo box, list box, or
/// menu when a visual aspect of the button, combo box, list box, or menu has
/// changed.
const WM_DRAWITEM = 0x002B;

/// Sent to the owner window of a combo box, list box, list-view control, or
/// menu item when the control or menu is created.
const WM_MEASUREITEM = 0x002C;

/// Sent to the owner of a list box or combo box when the list box or combo box
/// is destroyed or when items are removed by the LB_DELETESTRING,
/// LB_RESETCONTENT, CB_DELETESTRING, or CB_RESETCONTENT message. The system
/// sends a WM_DELETEITEM message for each deleted item. The system sends the
/// WM_DELETEITEM message for any deleted list box or combo box item with
/// nonzero item data.
const WM_DELETEITEM = 0x002D;

/// Sent by a list box with the LBS_WANTKEYBOARDINPUT style to its owner in
/// response to a WM_KEYDOWN message.
const WM_VKEYTOITEM = 0x002E;

/// Sent by a list box with the LBS_WANTKEYBOARDINPUT style to its owner in
/// response to a WM_CHAR message.
const WM_CHARTOITEM = 0x002F;

/// Sets the font that a control is to use when drawing text.
const WM_SETFONT = 0x0030;

/// Retrieves the font with which the control is currently drawing its text.
const WM_GETFONT = 0x0031;

/// Sent to a window to associate a hot key with the window. When the user
/// presses the hot key, the system activates the window.
const WM_SETHOTKEY = 0x0032;

/// Sent to determine the hot key associated with a window.
const WM_GETHOTKEY = 0x0033;

/// Sent to a minimized (iconic) window. The window is about to be dragged by
/// the user but does not have an icon defined for its class. An application can
/// return a handle to an icon or cursor. The system displays this cursor or
/// icon while the user drags the icon.
const WM_QUERYDRAGICON = 0x0037;

/// Sent to determine the relative position of a new item in the sorted list of
/// an owner-drawn combo box or list box. Whenever the application adds a new
/// item, the system sends this message to the owner of a combo box or list box
/// created with the CBS_SORT or LBS_SORT style.
const WM_COMPAREITEM = 0x0039;

/// Sent by both Microsoft Active Accessibility and Microsoft UI Automation to
/// obtain information about an accessible object contained in a server
/// application.
///
/// Applications never send this message directly. Microsoft Active
/// Accessibility sends this message in response to calls to
/// AccessibleObjectFromPoint, AccessibleObjectFromEvent, or
/// AccessibleObjectFromWindow. However, server applications handle this
/// message. UI Automation sends this message in response to calls to
/// IUIAutomation::ElementFromHandle, ElementFromPoint, and GetFocusedElement,
/// and when handling events for which a client has registered.
const WM_GETOBJECT = 0x003D;

/// Sent to all top-level windows when the system detects more than 12.5 percent
/// of system time over a 30- to 60-second interval is being spent compacting
/// memory. This indicates that system memory is low.
const WM_COMPACTING = 0x0041;

/// Deprecated. This message is not sent in modern versions of Windows.
const WM_COMMNOTIFY = 0x0044;

/// Sent to a window whose size, position, or place in the Z order is about to
/// change as a result of a call to the SetWindowPos function or another
/// window-management function.
const WM_WINDOWPOSCHANGING = 0x0046;

/// Sent to a window whose size, position, or place in the Z order has changed
/// as a result of a call to the SetWindowPos function or another
/// window-management function.
const WM_WINDOWPOSCHANGED = 0x0047;

/// Notifies applications that the system, typically a battery-powered personal
/// computer, is about to enter a suspended mode.
const WM_POWER = 0x0048;

/// Sent by a common control to its parent window when an event has occurred or
/// the control requires some information.
const WM_NOTIFY = 0x004E;

/// Posted to the window with the focus when the user chooses a new input
/// language, either with the hotkey (specified in the Keyboard control panel
/// application) or from the indicator on the system taskbar. An application can
/// accept the change by passing the message to the DefWindowProc function or
/// reject the change (and prevent it from taking place) by returning
/// immediately.
const WM_INPUTLANGCHANGEREQUEST = 0x0050;

/// Sent to the topmost affected window after an application's input language
/// has been changed. You should make any application-specific settings and pass
/// the message to the DefWindowProc function, which passes the message to all
/// first-level child windows. These child windows can pass the message to
/// DefWindowProc to have it pass the message to their child windows, and so on.
const WM_INPUTLANGCHANGE = 0x0051;

/// Sent to an application that has initiated a training card with Windows Help.
/// The message informs the application when the user clicks an authorable
/// button. An application initiates a training card by specifying the
/// HELP_TCARD command in a call to the WinHelp function.
const WM_TCARD = 0x0052;

/// Indicates that the user pressed the F1 key. If a menu is active when F1 is
/// pressed, WM_HELP is sent to the window associated with the menu; otherwise,
/// WM_HELP is sent to the window that has the keyboard focus. If no window has
/// the keyboard focus, WM_HELP is sent to the currently active window.
const WM_HELP = 0x0053;

/// Sent to all windows after the user has logged on or off. When the user logs
/// on or off, the system updates the user-specific settings. The system sends
/// this message immediately after updating the settings.
const WM_USERCHANGED = 0x0054;

/// Determines if a window accepts ANSI or Unicode structures in the WM_NOTIFY
/// notification message. WM_NOTIFYFORMAT messages are sent from a common
/// control to its parent window and from the parent window to the common
/// control.
const WM_NOTIFYFORMAT = 0x0055;

/// Notifies a window that the user clicked the right mouse button
/// (right-clicked) in the window.
const WM_CONTEXTMENU = 0x007B;

/// Sent to a window when the SetWindowLong function is about to change one or
/// more of the window's styles.
const WM_STYLECHANGING = 0x007C;

/// Sent to a window after the SetWindowLong function has changed one or more of
/// the window's styles.
const WM_STYLECHANGED = 0x007D;

/// The WM_DISPLAYCHANGE message is sent to all windows when the display
/// resolution has changed.
const WM_DISPLAYCHANGE = 0x007E;

/// Sent to a window to retrieve a handle to the large or small icon associated
/// with a window. The system displays the large icon in the ALT+TAB dialog, and
/// the small icon in the window caption.
const WM_GETICON = 0x007F;

/// Associates a new large or small icon with a window. The system displays the
/// large icon in the ALT+TAB dialog box, and the small icon in the window
/// caption.
const WM_SETICON = 0x0080;

/// Sent prior to the WM_CREATE message when a window is first created.
const WM_NCCREATE = 0x0081;

/// Notifies a window that its nonclient area is being destroyed. The
/// DestroyWindow function sends the WM_NCDESTROY message to the window
/// following the WM_DESTROY message.WM_DESTROY is used to free the allocated
/// memory object associated with the window.
///
/// The WM_NCDESTROY message is sent after the child windows have been
/// destroyed. In contrast, WM_DESTROY is sent before the child windows are
/// destroyed.
const WM_NCDESTROY = 0x0082;

/// Sent when the size and position of a window's client area must be
/// calculated. By processing this message, an application can control the
/// content of the window's client area when the size or position of the window
/// changes.
const WM_NCCALCSIZE = 0x0083;

/// Sent to a window in order to determine what part of the window corresponds
/// to a particular screen coordinate. This can happen, for example, when the
/// cursor moves, when a mouse button is pressed or released, or in response to
/// a call to a function such as WindowFromPoint. If the mouse is not captured,
/// the message is sent to the window beneath the cursor. Otherwise, the message
/// is sent to the window that has captured the mouse.
const WM_NCHITTEST = 0x0084;

/// The WM_NCPAINT message is sent to a window when its frame must be painted.
const WM_NCPAINT = 0x0085;

/// Sent to a window when its nonclient area needs to be changed to indicate an
/// active or inactive state.
const WM_NCACTIVATE = 0x0086;

/// Sent to the window procedure associated with a control. By default, the
/// system handles all keyboard input to the control; the system interprets
/// certain types of keyboard input as dialog box navigation keys. To override
/// this default behavior, the control can respond to the WM_GETDLGCODE message
/// to indicate the types of input it wants to process itself.
const WM_GETDLGCODE = 0x0087;

/// The WM_SYNCPAINT message is used to synchronize painting while avoiding
/// linking independent GUI threads.
const WM_SYNCPAINT = 0x0088;

/// Posted to a window when the cursor is moved within the nonclient area of the
/// window. This message is posted to the window that contains the cursor. If a
/// window has captured the mouse, this message is not posted.
const WM_NCMOUSEMOVE = 0x00A0;

/// Posted when the user presses the left mouse button while the cursor is
/// within the nonclient area of a window. This message is posted to the window
/// that contains the cursor. If a window has captured the mouse, this message
/// is not posted.
const WM_NCLBUTTONDOWN = 0x00A1;

/// Posted when the user releases the left mouse button while the cursor is
/// within the nonclient area of a window. This message is posted to the window
/// that contains the cursor. If a window has captured the mouse, this message
/// is not posted.
const WM_NCLBUTTONUP = 0x00A2;

/// Posted when the user double-clicks the left mouse button while the cursor is
/// within the nonclient area of a window. This message is posted to the window
/// that contains the cursor. If a window has captured the mouse, this message
/// is not posted.
const WM_NCLBUTTONDBLCLK = 0x00A3;

/// Posted when the user presses the right mouse button while the cursor is
/// within the nonclient area of a window. This message is posted to the window
/// that contains the cursor. If a window has captured the mouse, this message
/// is not posted.
const WM_NCRBUTTONDOWN = 0x00A4;

/// Posted when the user releases the right mouse button while the cursor is
/// within the nonclient area of a window. This message is posted to the window
/// that contains the cursor. If a window has captured the mouse, this message
/// is not posted.
const WM_NCRBUTTONUP = 0x00A5;

/// Posted when the user double-clicks the middle mouse button while the cursor
/// is within the nonclient area of a window. This message is posted to the
/// window that contains the cursor. If a window has captured the mouse, this
/// message is not posted.
const WM_NCRBUTTONDBLCLK = 0x00A6;

/// Posted when the user presses the middle mouse button while the cursor is
/// within the nonclient area of a window. This message is posted to the window
/// that contains the cursor. If a window has captured the mouse, this message
/// is not posted.
const WM_NCMBUTTONDOWN = 0x00A7;

/// Posted when the user releases the middle mouse button while the cursor is
/// within the nonclient area of a window. This message is posted to the window
/// that contains the cursor. If a window has captured the mouse, this message
/// is not posted.
const WM_NCMBUTTONUP = 0x00A8;

/// Posted when the user double-clicks the middle mouse button while the cursor
/// is within the nonclient area of a window. This message is posted to the
/// window that contains the cursor. If a window has captured the mouse, this
/// message is not posted.
const WM_NCMBUTTONDBLCLK = 0x00A9;

/// Posted when the user presses the first or second X button while the cursor
/// is in the nonclient area of a window. This message is posted to the window
/// that contains the cursor. If a window has captured the mouse, this message
/// is not posted.
const WM_NCXBUTTONDOWN = 0x00AB;

/// Posted when the user releases the first or second X button while the cursor
/// is in the nonclient area of a window. This message is posted to the window
/// that contains the cursor. If a window has captured the mouse, this message
/// is not posted.
const WM_NCXBUTTONUP = 0x00AC;

/// Posted when the user double-clicks the first or second X button while the
/// cursor is in the nonclient area of a window. This message is posted to the
/// window that contains the cursor. If a window has captured the mouse, this
/// message is not posted.
const WM_NCXBUTTONDBLCLK = 0x00AD;

/// Sent to the window that registered to receive raw input.
///
/// Raw input notifications are available only after the application calls
/// RegisterRawInputDevices with RIDEV_DEVNOTIFY flag.
const WM_INPUT_DEVICE_CHANGE = 0x00FE;

/// Sent to the window that is getting raw input.
const WM_INPUT = 0x00FF;

/// Posted to the window with the keyboard focus when a nonsystem key is
/// pressed. A nonsystem key is a key that is pressed when the ALT key is not
/// pressed.
const WM_KEYDOWN = 0x0100;

/// Posted to the window with the keyboard focus when a nonsystem key is
/// released. A nonsystem key is a key that is pressed when the ALT key is not
/// pressed, or a keyboard key that is pressed when a window has the keyboard
/// focus.
const WM_KEYUP = 0x0101;

/// Posted to the window with the keyboard focus when a WM_KEYDOWN message is
/// translated by the TranslateMessage function. The WM_CHAR message contains
/// the character code of the key that was pressed.
const WM_CHAR = 0x0102;

/// Posted to the window with the keyboard focus when a WM_KEYUP message is
/// translated by the TranslateMessage function. WM_DEADCHAR specifies a
/// character code generated by a dead key. A dead key is a key that generates a
/// character, such as the umlaut (double-dot), that is combined with another
/// character to form a composite character. For example, the umlaut-O character
/// (Ö) is generated by typing the dead key for the umlaut character, and then
/// typing the O key.
const WM_DEADCHAR = 0x0103;

/// Posted to the window with the keyboard focus when the user presses the F10
/// key (which activates the menu bar) or holds down the ALT key and then
/// presses another key. It also occurs when no window currently has the
/// keyboard focus; in this case, the WM_SYSKEYDOWN message is sent to the
/// active window. The window that receives the message can distinguish between
/// these two contexts by checking the context code in the lParam parameter.
const WM_SYSKEYDOWN = 0x0104;

/// Posted to the window with the keyboard focus when the user releases a key
/// that was pressed while the ALT key was held down. It also occurs when no
/// window currently has the keyboard focus; in this case, the WM_SYSKEYUP
/// message is sent to the active window. The window that receives the message
/// can distinguish between these two contexts by checking the context code in
/// the lParam parameter.
const WM_SYSKEYUP = 0x0105;

/// Posted to the window with the keyboard focus when a WM_SYSKEYDOWN message is
/// translated by the TranslateMessage function. It specifies the character code
/// of a system character key that is, a character key that is pressed while the
/// ALT key is down.
const WM_SYSCHAR = 0x0106;

/// Sent to the window with the keyboard focus when a WM_SYSKEYDOWN message is
/// translated by the TranslateMessage function. WM_SYSDEADCHAR specifies the
/// character code of a system dead key that is, a dead key that is pressed
/// while holding down the ALT key.
const WM_SYSDEADCHAR = 0x0107;

/// Sent to the dialog box procedure immediately before a dialog box is
/// displayed. Dialog box procedures typically use this message to initialize
/// controls and carry out any other initialization tasks that affect the
/// appearance of the dialog box.
const WM_INITDIALOG = 0x0110;

/// Sent when the user selects a command item from a menu, when a control sends
/// a notification message to its parent window, or when an accelerator
/// keystroke is translated.
const WM_COMMAND = 0x0111;

/// A window receives this message when the user chooses a command from the
/// Window menu (formerly known as the system or control menu) or when the user
/// chooses the maximize button, minimize button, restore button, or close
/// button.
const WM_SYSCOMMAND = 0x0112;

/// Posted to the installing thread's message queue when a timer expires. The
/// message is posted by the GetMessage or PeekMessage function.
const WM_TIMER = 0x0113;

/// The WM_HSCROLL message is sent to a window when a scroll event occurs in the
/// window's standard horizontal scroll bar. This message is also sent to the
/// owner of a horizontal scroll bar control when a scroll event occurs in the
/// control.
const WM_HSCROLL = 0x0114;

/// The WM_VSCROLL message is sent to a window when a scroll event occurs in the
/// window's standard vertical scroll bar. This message is also sent to the
/// owner of a vertical scroll bar control when a scroll event occurs in the
/// control.
const WM_VSCROLL = 0x0115;

/// Sent when a menu is about to become active. It occurs when the user clicks
/// an item on the menu bar or presses a menu key. This allows the application
/// to modify the menu before it is displayed.
const WM_INITMENU = 0x0116;

/// Sent when a drop-down menu or submenu is about to become active. This allows
/// an application to modify the menu before it is displayed, without changing
/// the entire menu.
const WM_INITMENUPOPUP = 0x0117;

/// Passes information about a gesture.
const WM_GESTURE = 0x0119;

/// Gives you a chance to set the gesture configuration.
const WM_GESTURENOTIFY = 0x011A;

/// Sent to a menu's owner window when the user selects a menu item.
const WM_MENUSELECT = 0x011F;

/// Sent when a menu is active and the user presses a key that does not
/// correspond to any mnemonic or accelerator key. This message is sent to the
/// window that owns the menu.
const WM_MENUCHAR = 0x0120;

/// Sent to the owner window of a modal dialog box or menu that is entering an
/// idle state. A modal dialog box or menu enters an idle state when no messages
/// are waiting in its queue after it has processed one or more previous
/// messages.
const WM_ENTERIDLE = 0x0121;

/// Sent when the user releases the right mouse button while the cursor is on a
/// menu item.
const WM_MENURBUTTONUP = 0x0122;

/// Sent to the owner of a drag-and-drop menu when the user drags a menu item.
const WM_MENUDRAG = 0x0123;

/// Sent to the owner of a drag-and-drop menu when the mouse cursor enters a
/// menu item or moves from the center of the item to the top or bottom of the
/// item.
const WM_MENUGETOBJECT = 0x0124;

/// Sent when a drop-down menu or submenu has been destroyed.
const WM_UNINITMENUPOPUP = 0x0125;

/// Sent when the user makes a selection from a menu.c
const WM_MENUCOMMAND = 0x0126;

/// An application sends the WM_CHANGEUISTATE message to indicate that the UI
/// state should be changed.
const WM_CHANGEUISTATE = 0x0127;

/// An application sends the WM_UPDATEUISTATE message to change the UI state for
/// the specified window and all its child windows.
const WM_UPDATEUISTATE = 0x0128;

/// An application sends the WM_QUERYUISTATE message to retrieve the UI state
/// for a window.
const WM_QUERYUISTATE = 0x0129;

/// Posted to a window when the cursor moves. If the mouse is not captured, the
/// message is posted to the window that contains the cursor. Otherwise, the
/// message is posted to the window that has captured the mouse.
const WM_MOUSEMOVE = 0x0200;

/// Posted when the user presses the left mouse button while the cursor is in
/// the client area of a window. If the mouse is not captured, the message is
/// posted to the window beneath the cursor. Otherwise, the message is posted to
/// the window that has captured the mouse.
const WM_LBUTTONDOWN = 0x0201;

/// Posted when the user releases the left mouse button while the cursor is in
/// the client area of a window. If the mouse is not captured, the message is
/// posted to the window beneath the cursor. Otherwise, the message is posted to
/// the window that has captured the mouse.
const WM_LBUTTONUP = 0x0202;

/// Posted when the user double-clicks the left mouse button while the cursor is
/// in the client area of a window. If the mouse is not captured, the message is
/// posted to the window beneath the cursor. Otherwise, the message is posted to
/// the window that has captured the mouse.
const WM_LBUTTONDBLCLK = 0x0203;

/// Posted when the user presses the right mouse button while the cursor is in
/// the client area of a window. If the mouse is not captured, the message is
/// posted to the window beneath the cursor. Otherwise, the message is posted to
/// the window that has captured the mouse.
const WM_RBUTTONDOWN = 0x0204;

/// Posted when the user releases the right mouse button while the cursor is in
/// the client area of a window. If the mouse is not captured, the message is
/// posted to the window beneath the cursor. Otherwise, the message is posted to
/// the window that has captured the mouse.
const WM_RBUTTONUP = 0x0205;

/// Posted when the user double-clicks the right mouse button while the cursor
/// is in the client area of a window. If the mouse is not captured, the message
/// is posted to the window beneath the cursor. Otherwise, the message is posted
/// to the window that has captured the mouse.
const WM_RBUTTONDBLCLK = 0x0206;

/// Posted when the user presses the middle mouse button while the cursor is
/// within the nonclient area of a window. This message is posted to the window
/// that contains the cursor. If a window has captured the mouse, this message
/// is not posted.
const WM_MBUTTONDOWN = 0x0207;

/// Posted when the user releases the middle mouse button while the cursor is
/// within the nonclient area of a window. This message is posted to the window
/// that contains the cursor. If a window has captured the mouse, this message
/// is not posted.
const WM_MBUTTONUP = 0x0208;

/// Posted when the user double-clicks the middle mouse button while the cursor
/// is within the nonclient area of a window. This message is posted to the
/// window that contains the cursor. If a window has captured the mouse, this
/// message is not posted.
const WM_MBUTTONDBLCLK = 0x0209;

/// Sent to the focus window when the mouse wheel is rotated. The DefWindowProc
/// function propagates the message to the window's parent. There should be no
/// internal forwarding of the message, since DefWindowProc propagates it up the
/// parent chain until it finds a window that processes it.
const WM_MOUSEWHEEL = 0x020A;

/// Posted when the user presses the first or second X button while the cursor
/// is in the client area of a window. If the mouse is not captured, the message
/// is posted to the window beneath the cursor. Otherwise, the message is posted
/// to the window that has captured the mouse.
const WM_XBUTTONDOWN = 0x020B;

/// Posted when the user releases the first or second X button while the cursor
/// is in the client area of a window. If the mouse is not captured, the message
/// is posted to the window beneath the cursor. Otherwise, the message is posted
/// to the window that has captured the mouse.
const WM_XBUTTONUP = 0x020C;

/// Posted when the user double-clicks the first or second X button while the
/// cursor is in the client area of a window. If the mouse is not captured, the
/// message is posted to the window beneath the cursor. Otherwise, the message
/// is posted to the window that has captured the mouse.
const WM_XBUTTONDBLCLK = 0x020D;

/// Sent to the active window when the mouse's horizontal scroll wheel is tilted
/// or rotated. The DefWindowProc function propagates the message to the
/// window's parent. There should be no internal forwarding of the message,
/// since DefWindowProc propagates it up the parent chain until it finds a
/// window that processes it.
const WM_MOUSEHWHEEL = 0x020E;

/// Notifies applications that a power-management event has occurred.
const WM_POWERBROADCAST = 0x0218;

/// Sent when the effective dots per inch (dpi) for a window has changed.
/// Requires Windows 8.1 or above.
const WM_DPICHANGED = 0x02E0;

/// For Per Monitor v2 top-level windows, this message is sent to all HWNDs in
/// the child HWND tree of the window that is undergoing a DPI change. This
/// message occurs before the top-level window receives WM_DPICHANGED, and
/// traverses the child tree from the bottom up. Requires Windows 10, version
/// 1703 or higher.
const WM_DPICHANGED_BEFOREPARENT = 0x02E2;

/// For Per Monitor v2 top-level windows, this message is sent to all HWNDs in
/// the child HWND tree of the window that is undergoing a DPI change. This
/// message occurs after the top-level window receives WM_DPICHANGED, and
/// traverses the child tree from the bottom up. Requires Windows 10, version
/// 1703 or higher.
const WM_DPICHANGED_AFTERPARENT = 0x02E3;

/// This message tells the operating system that the window will be sized to
/// dimensions other than the default. Requires Windows 10, version
/// 1703 or higher.
const WM_GETDPISCALEDSIZE = 0x02E4;

/// An application sends a WM_CUT message to an edit control or combo box to
/// delete (cut) the current selection, if any, in the edit control and copy the
/// deleted text to the clipboard in CF_TEXT format.
const WM_CUT = 0x0300;

/// An application sends the WM_COPY message to an edit control or combo box to
/// copy the current selection to the clipboard in CF_TEXT format.
const WM_COPY = 0x0301;

/// An application sends a WM_PASTE message to an edit control or combo box to
/// copy the current content of the clipboard to the edit control at the current
/// caret position. Data is inserted only if the clipboard contains data in
/// CF_TEXT format.
const WM_PASTE = 0x0302;

/// An application sends a WM_CLEAR message to an edit control or combo box to
/// delete (clear) the current selection, if any, from the edit control.
const WM_CLEAR = 0x0303;

/// An application sends a WM_UNDO message to an edit control to undo the last
/// operation. When this message is sent to an edit control, the previously
/// deleted text is restored or the previously added text is deleted.
const WM_UNDO = 0x0304;

/// Sent to the clipboard owner if it has delayed rendering a specific clipboard
/// format and if an application has requested data in that format. The
/// clipboard owner must render data in the specified format and place it on the
/// clipboard by calling the SetClipboardData function.
const WM_RENDERFORMAT = 0x0305;

/// Sent to the clipboard owner before it is destroyed, if the clipboard owner
/// has delayed rendering one or more clipboard formats. For the content of the
/// clipboard to remain available to other applications, the clipboard owner
/// must render data in all the formats it is capable of generating, and place
/// the data on the clipboard by calling the SetClipboardData function.
const WM_RENDERALLFORMATS = 0x0306;

/// Sent to the clipboard owner when a call to the EmptyClipboard function
/// empties the clipboard.
const WM_DESTROYCLIPBOARD = 0x0307;

/// Sent to the first window in the clipboard viewer chain when the content of
/// the clipboard changes. This enables a clipboard viewer window to display the
/// new content of the clipboard.
const WM_DRAWCLIPBOARD = 0x0308;

/// Sent to the clipboard owner by a clipboard viewer window when the clipboard
/// contains data in the CF_OWNERDISPLAY format and the clipboard viewer's
/// client area needs repainting.
const WM_PAINTCLIPBOARD = 0x0309;

/// Sent to the clipboard owner by a clipboard viewer window when the clipboard
/// contains data in the CF_OWNERDISPLAY format and an event occurs in the
/// clipboard viewer's vertical scroll bar. The owner should scroll the
/// clipboard image and update the scroll bar values.
const WM_VSCROLLCLIPBOARD = 0x030A;

/// Sent to the clipboard owner by a clipboard viewer window when the clipboard
/// contains data in the CF_OWNERDISPLAY format and the clipboard viewer's
/// client area has changed size.
const WM_SIZECLIPBOARD = 0x030B;

/// Sent to the clipboard owner by a clipboard viewer window to request the name
/// of a CF_OWNERDISPLAY clipboard format.
const WM_ASKCBFORMATNAME = 0x030C;

/// Sent to the first window in the clipboard viewer chain when a window is
/// being removed from the chain.
const WM_CHANGECBCHAIN = 0x030D;

/// Sent to the clipboard owner by a clipboard viewer window. This occurs when
/// the clipboard contains data in the CF_OWNERDISPLAY format and an event
/// occurs in the clipboard viewer's horizontal scroll bar. The owner should
/// scroll the clipboard image and update the scroll bar values.
const WM_HSCROLLCLIPBOARD = 0x030E;

/// The WM_QUERYNEWPALETTE message informs a window that it is about to receive
/// the keyboard focus, giving the window the opportunity to realize its logical
/// palette when it receives the focus.
const WM_QUERYNEWPALETTE = 0x030F;

/// The WM_PALETTEISCHANGING message informs applications that an application is
/// going to realize its logical palette.
const WM_PALETTEISCHANGING = 0x0310;

/// The WM_PALETTECHANGED message is sent to all top-level and overlapped
/// windows after the window with the keyboard focus has realized its logical
/// palette, thereby changing the system palette. This message enables a window
/// that uses a color palette but does not have the keyboard focus to realize
/// its logical palette and update its client area.
const WM_PALETTECHANGED = 0x0311;

/// Posted when the user presses a hot key registered by the RegisterHotKey
/// function. The message is placed at the top of the message queue associated
/// with the thread that registered the hot key.
const WM_HOTKEY = 0x0312;

/// Used to define private messages for use by private window classes, usually
/// in the form WM_USER+x, where x is an integer value.
const WM_USER = 0x0400;

/// A message-only window enables you to send and receive messages. It is not
/// visible, has no z-order, cannot be enumerated, and does not receive
/// broadcast messages. The window simply dispatches messages.
const HWND_MESSAGE = 0xFFFFFFFFFFFFFFFD; // (HWND) -3

/// Special HWND value for use with PostMessage() and SendMessage(). The message
/// is sent to all top-level windows in the system, including disabled or
/// invisible unowned windows, overlapped windows, and pop-up windows; but the
/// message is not sent to child windows.
const HWND_BROADCAST = 0xffff;

// -----------------------------------------------------------------------------
// Pre-defined resource types
// -----------------------------------------------------------------------------

/// Hardware-dependent cursor resource.
final RT_CURSOR = MAKEINTRESOURCE(1);

/// Bitmap resource.
final RT_BITMAP = MAKEINTRESOURCE(2);

/// Hardware-dependent icon resource.
final RT_ICON = MAKEINTRESOURCE(3);

/// Menu resource.
final RT_MENU = MAKEINTRESOURCE(4);

/// Dialog box.
final RT_DIALOG = MAKEINTRESOURCE(5);

/// String-table entry.
final RT_STRING = MAKEINTRESOURCE(6);

/// Font directory resource.
final RT_FONTDIR = MAKEINTRESOURCE(7);

/// Font resource.
final RT_FONT = MAKEINTRESOURCE(8);

/// Accelerator table.
final RT_ACCELERATOR = MAKEINTRESOURCE(9);

/// Application-defined resource (raw data).
final RT_RCDATA = MAKEINTRESOURCE(10);

/// Message-table entry.
final RT_MESSAGETABLE = MAKEINTRESOURCE(11);

/// Hardware-independent cursor resource.
final RT_GROUP_CURSOR = MAKEINTRESOURCE(11 + RT_CURSOR.address);

/// Hardware-independent icon resource.
final RT_GROUP_ICON = MAKEINTRESOURCE(11 + RT_ICON.address);

/// Version resource.
final RT_VERSION = MAKEINTRESOURCE(16);

/// Allows a resource editing tool to associate a string with an .rc file.
final RT_DLGINCLUDE = MAKEINTRESOURCE(17);

/// Plug and Play resource.
final RT_PLUGPLAY = MAKEINTRESOURCE(19);

/// VXD.
final RT_VXD = MAKEINTRESOURCE(20);

/// Animated cursor.
final RT_ANICURSOR = MAKEINTRESOURCE(21);

/// Animated icon.
final RT_ANIICON = MAKEINTRESOURCE(22);

/// HTML resource.
final RT_HTML = MAKEINTRESOURCE(23);

/// Side-by-Side Assembly Manifest.
final RT_MANIFEST = MAKEINTRESOURCE(24);

// -----------------------------------------------------------------------------
// SendMessageTimeout values
// -----------------------------------------------------------------------------

/// The calling thread is not prevented from processing other requests while
/// waiting for the function to return.
const SMTO_NORMAL = 0x0000;

/// Prevents the calling thread from processing any other requests until the
/// function returns.
const SMTO_BLOCK = 0x0001;

/// The function returns without waiting for the time-out period to elapse if
/// the receiving thread appears to not respond or "hangs."
const SMTO_ABORTIFHUNG = 0x0002;

/// The function does not enforce the time-out period as long as the receiving
/// thread is processing messages.
const SMTO_NOTIMEOUTIFNOTHUNG = 0x0008;

/// The function should return 0 if the receiving window is destroyed or its
/// owning thread dies while the message is being processed.
const SMTO_ERRORONEXIT = 0x0020;

// -----------------------------------------------------------------------------
// Power management events
// -----------------------------------------------------------------------------

/// Notifies applications that the computer is about to enter a suspended state.
/// This event is typically broadcast when all applications and installable
/// drivers have returned TRUE to a previous PBT_APMQUERYSUSPEND event.
const PBT_APMSUSPEND = 0x0004;

/// Notifies applications that the system has resumed operation after being
/// suspended.
const PBT_APMRESUMESUSPEND = 0x0007;

/// Notifies applications that the battery power is low.
const PBT_APMBATTERYLOW = 0x0009;

/// Notifies applications of a change in the power status of the computer, such
/// as a switch from battery power to A/C. The system also broadcasts this event
/// when remaining battery power slips below the threshold specified by the user
/// or if the battery power changes by a specified percentage.
const PBT_APMPOWERSTATUSCHANGE = 0x000A;

/// Notifies applications that the system is resuming from sleep or hibernation.
/// This event is delivered every time the system resumes and does not indicate
/// whether a user is present.
const PBT_APMRESUMEAUTOMATIC = 0x0012;

/// Power setting change event sent with a WM_POWERBROADCAST window message or
/// in a HandlerEx notification callback for services.
const PBT_POWERSETTINGCHANGE = 0x8013;

// -----------------------------------------------------------------------------
// Size constants (from WM_SIZE)
// -----------------------------------------------------------------------------

/// The window has been resized, but neither the SIZE_MINIMIZED nor
/// SIZE_MAXIMIZED value applies.
const SIZE_RESTORED = 0;

/// The window has been minimized.
const SIZE_MINIMIZED = 1;

/// The window has been maximized.
const SIZE_MAXIMIZED = 2;

/// Message is sent to all pop-up windows when some other window has been
/// restored to its former size.
const SIZE_MAXSHOW = 3;

/// Message is sent to all pop-up windows when some other window is maximized.
const SIZE_MAXHIDE = 4;

// -----------------------------------------------------------------------------
// Window z-ordering constants
// -----------------------------------------------------------------------------

/// Places the window at the top of the Z order.
const HWND_TOP = 0;

/// Places the window at the bottom of the Z order. If the hWnd parameter
/// identifies a topmost window, the window loses its topmost status and is
/// placed at the bottom of all other windows.
const HWND_BOTTOM = 1;

/// Places the window above all non-topmost windows. The window maintains its
/// topmost position even when it is deactivated.
const HWND_TOPMOST = -1;

/// Places the window above all non-topmost windows (that is, behind all topmost
/// windows). This flag has no effect if the window is already a non-topmost
/// window.
const HWND_NOTOPMOST = -2;

// -----------------------------------------------------------------------------
// Queue status flags
// -----------------------------------------------------------------------------

/// A WM_KEYUP, WM_KEYDOWN, WM_SYSKEYUP, or WM_SYSKEYDOWN message is in the
/// queue.
const QS_KEY = 0x0001;

/// A WM_MOUSEMOVE message is in the queue.
const QS_MOUSEMOVE = 0x0002;

/// A mouse-button message (WM_LBUTTONUP, WM_RBUTTONDOWN, and so on).
const QS_MOUSEBUTTON = 0x0004;

/// A posted message (other than those listed here) is in the queue.
const QS_POSTMESSAGE = 0x0008;

/// A WM_TIMER message is in the queue.
const QS_TIMER = 0x0010;

/// A WM_PAINT message is in the queue.
const QS_PAINT = 0x0020;

/// A message sent by another thread or application is in the queue.
const QS_SENDMESSAGE = 0x0040;

/// A WM_HOTKEY message is in the queue.
const QS_HOTKEY = 0x0080;

/// A posted message (other than those listed here) is in the queue.
const QS_ALLPOSTMESSAGE = 0x0100;

/// A raw input message is in the queue.
const QS_RAWINPUT = 0x0400;

/// A touch message is in the queue.
const QS_TOUCH = 0x0800;

/// A pointer message is in the queue.
const QS_POINTER = 0x1000;

/// A WM_MOUSEMOVE message or mouse-button message (WM_LBUTTONUP,
/// WM_RBUTTONDOWN, and so on).
const QS_MOUSE = QS_MOUSEMOVE | QS_MOUSEBUTTON;

/// An input message is in the queue.
const QS_INPUT = QS_MOUSE | QS_KEY | QS_RAWINPUT | QS_TOUCH | QS_POINTER;

/// An input, WM_TIMER, WM_PAINT, WM_HOTKEY, or posted message is in the queue.
const QS_ALLEVENTS =
    QS_INPUT | QS_POSTMESSAGE | QS_TIMER | QS_PAINT | QS_HOTKEY;

/// Any message is in the queue.
const QS_ALLINPUT = QS_INPUT |
    QS_POSTMESSAGE |
    QS_TIMER |
    QS_PAINT |
    QS_HOTKEY |
    QS_SENDMESSAGE;

// -----------------------------------------------------------------------------
// Hook constants
// -----------------------------------------------------------------------------

/// Installs a hook procedure that monitors messages generated as a result of an
/// input event in a dialog box, message box, menu, or scroll bar.
const WH_MSGFILTER = -1;

/// Installs a hook procedure that records input messages posted to the system
/// message queue.
const WH_JOURNALRECORD = 0;

/// Installs a hook procedure that posts messages previously recorded by a
/// WH_JOURNALRECORD hook procedure.
const WH_JOURNALPLAYBACK = 1;

/// Installs a hook procedure that monitors keystroke messages.
const WH_KEYBOARD = 2;

/// Installs a hook procedure that monitors messages posted to a message queue.
const WH_GETMESSAGE = 3;

/// Installs a hook procedure that monitors messages before the system sends
/// them to the destination window procedure.
const WH_CALLWNDPROC = 4;

/// Installs a hook procedure that receives notifications useful to a CBT
/// application.
const WH_CBT = 5;

/// Installs a hook procedure that monitors messages generated as a result of an
/// input event in a dialog box, message box, menu, or scroll bar. The hook
/// procedure monitors these messages for all applications in the same desktop
/// as the calling thread.
const WH_SYSMSGFILTER = 6;

/// Installs a hook procedure that monitors mouse messages.
const WH_MOUSE = 7;

/// Installs a hook procedure useful for debugging other hook procedures.
const WH_DEBUG = 9;

/// Installs a hook procedure that receives notifications useful to shell
/// applications.
const WH_SHELL = 10;

/// Installs a hook procedure that will be called when the application's
/// foreground thread is about to become idle. This hook is useful for
/// performing low priority tasks during idle time.
const WH_FOREGROUNDIDLE = 11;

/// Installs a hook procedure that monitors messages after they have been
/// processed by the destination window procedure.
const WH_CALLWNDPROCRET = 12;

/// Installs a hook procedure that monitors low-level keyboard input events.
const WH_KEYBOARD_LL = 13;

/// Installs a hook procedure that monitors low-level mouse input events.
const WH_MOUSE_LL = 14;

// -----------------------------------------------------------------------------
// System colors
// -----------------------------------------------------------------------------

/// Scroll bar gray area.
const COLOR_SCROLLBAR = 0;

/// Desktop.
const COLOR_BACKGROUND = 1;

/// Active window title bar.
const COLOR_ACTIVECAPTION = 2;

/// Inactive window caption.
const COLOR_INACTIVECAPTION = 3;

/// Menu background.
const COLOR_MENU = 4;

/// Window background.
const COLOR_WINDOW = 5;

/// Window frame.
const COLOR_WINDOWFRAME = 6;

/// Text in menus.
const COLOR_MENUTEXT = 7;

/// Text in windows.
const COLOR_WINDOWTEXT = 8;

/// Text in caption, size box, and scroll bar arrow box.
const COLOR_CAPTIONTEXT = 9;

/// Active window border.
const COLOR_ACTIVEBORDER = 10;

/// Inactive window border.
const COLOR_INACTIVEBORDER = 11;

/// Background color of multiple document interface (MDI) applications.
const COLOR_APPWORKSPACE = 12;

/// Item(s) selected in a control.
const COLOR_HIGHLIGHT = 13;

/// Text of item(s) selected in a control.
const COLOR_HIGHLIGHTTEXT = 14;

/// Face color for three-dimensional display elements and for dialog box
/// backgrounds.
const COLOR_BTNFACE = 15;

/// Shadow color for three-dimensional display elements (for edges facing away
/// from the light source).
const COLOR_BTNSHADOW = 16;

/// Grayed (disabled) text.
const COLOR_GRAYTEXT = 17;

/// Text on push buttons.
const COLOR_BTNTEXT = 18;

/// Color of text in an inactive caption.
const COLOR_INACTIVECAPTIONTEXT = 19;

/// Highlight color for three-dimensional display elements (for edges facing the
/// light source.)
const COLOR_BTNHIGHLIGHT = 20;

// -----------------------------------------------------------------------------
// GetWindowLong styles
// -----------------------------------------------------------------------------

/// Gets/sets the extended window styles.
const GWL_EXSTYLE = -20;

/// Gets/sets a new application instance handle.
const GWL_HINSTANCE = -6;

/// Gets/sets a new identifier of the child window. The window cannot be a
/// top-level window.
const GWL_ID = -12;

/// Gets/sets a new window style.
const GWL_STYLE = -16;

/// Gets/sets the user data associated with the window. This data is intended
/// for use by the application that created the window. Its value is initially
/// zero.
const GWL_USERDATA = -21;

/// Sets a new address for the window procedure. You cannot change this
/// attribute if the window does not belong to the same process as the calling
/// thread.
const GWL_WNDPROC = -4;

/// Sets a new address for the window procedure.
const GWLP_WNDPROC = -4;

/// Sets a new application instance handle.
const GWLP_HINSTANCE = -6;

/// Retrieves a handle to the parent window, if there is one.
const GWLP_HWNDPARENT = -8;

/// Sets the user data associated with the window. This data is intended for use
/// by the application that created the window. Its value is initially zero.
const GWLP_USERDATA = -21;

/// Sets a new identifier of the child window. The window cannot be a top-level
/// window.
const GWLP_ID = -12;

// -----------------------------------------------------------------------------
// Hit testing constants
// -----------------------------------------------------------------------------

/// On the screen background or on a dividing line between windows (same as
/// HTNOWHERE, except that the DefWindowProc function produces a system beep to
/// indicate an error).
const HTERROR = -2;

/// In a window currently covered by another window in the same thread (the
/// message will be sent to underlying windows in the same thread until one of
/// them returns a code that is not HTTRANSPARENT).
const HTTRANSPARENT = -1;

/// On the screen background or on a dividing line between windows.
const HTNOWHERE = 0;

/// In a client area.
const HTCLIENT = 1;

/// In a title bar.
const HTCAPTION = 2;

/// In a window menu or in a Close button in a child window.
const HTSYSMENU = 3;

/// In a size box (same as HTSIZE).
const HTGROWBOX = 4;

/// In a size box (same as HTGROWBOX).
const HTSIZE = HTGROWBOX;

/// In a menu.
const HTMENU = 5;

/// In a horizontal scroll bar.
const HTHSCROLL = 6;

/// In the vertical scroll bar.
const HTVSCROLL = 7;

/// In a Minimize button.
const HTMINBUTTON = 8;

/// In a Maximize button.
const HTMAXBUTTON = 9;

/// In the left border of a resizable window (the user can click the mouse to
/// resize the window horizontally).
const HTLEFT = 10;

/// In the right border of a resizable window (the user can click the mouse to
/// resize the window horizontally).
const HTRIGHT = 11;

/// In the upper-horizontal border of a window.
const HTTOP = 12;

/// In the upper-left corner of a window border.
const HTTOPLEFT = 13;

/// In the upper-right corner of a window border.
const HTTOPRIGHT = 14;

/// In the lower-horizontal border of a resizable window (the user can click the
/// mouse to resize the window vertically).
const HTBOTTOM = 15;

/// In the lower-left corner of a border of a resizable window (the user can
/// click the mouse to resize the window diagonally).
const HTBOTTOMLEFT = 16;

/// In the lower-right corner of a border of a resizable window (the user can
/// click the mouse to resize the window diagonally).
const HTBOTTOMRIGHT = 17;

/// In the border of a window that does not have a sizing border.
const HTBORDER = 18;

/// In a Minimize button.
const HTREDUCE = HTMINBUTTON;

/// In a Maximize button.
const HTZOOM = HTMAXBUTTON;

/// In a Close button.
const HTCLOSE = 20;

/// In a Help button.
const HTHELP = 21;

// -----------------------------------------------------------------------------
// System-wide parameters
// -----------------------------------------------------------------------------

/// Determines whether the warning beeper is on.
const SPI_GETBEEP = 0x0001;

/// Turns the warning beeper on or off. The uiParam parameter specifies TRUE for
/// on, or FALSE for off.
const SPI_SETBEEP = 0x0002;

/// Retrieves the two mouse threshold values and the mouse acceleration. The
/// pvParam parameter must point to an array of three integers that receives
/// these values. See mouse_event for further information.
const SPI_GETMOUSE = 0x0003;

/// Sets the two mouse threshold values and the mouse acceleration. The pvParam
/// parameter must point to an array of three integers that specifies these
/// values. See mouse_event for further information.
const SPI_SETMOUSE = 0x0004;

/// Retrieves the border multiplier factor that determines the width of a
/// window's sizing border. The pvParamparameter must point to an integer
/// variable that receives this value.
const SPI_GETBORDER = 0x0005;

/// Sets the border multiplier factor that determines the width of a window's
/// sizing border. The uiParam parameter specifies the new value.
const SPI_SETBORDER = 0x0006;

/// Retrieves the keyboard repeat-speed setting, which is a value in the range
/// from 0 (approximately 2.5 repetitions per second) through 31 (approximately
/// 30 repetitions per second). The actual repeat rates are hardware-dependent
/// and may vary from a linear scale by as much as 20%. The pvParam parameter
/// must point to a DWORD variable that receives the setting.
const SPI_GETKEYBOARDSPEED = 0x000A;

/// Sets the keyboard repeat-speed setting. The uiParam parameter must specify a
/// value in the range from 0 (approximately 2.5 repetitions per second) through
/// 31 (approximately 30 repetitions per second). The actual repeat rates are
/// hardware-dependent and may vary from a linear scale by as much as 20%. If
/// uiParam is greater than 31, the parameter is set to 31.
const SPI_SETKEYBOARDSPEED = 0x000B;

/// Sets or retrieves the width, in pixels, of an icon cell.
///
/// The system uses this rectangle to arrange icons in large icon view.
///
/// To set this value, set uiParam to the new value and set pvParam to NULL. You
/// cannot set this value to less than SM_CXICON.
///
/// To retrieve this value, pvParam must point to an integer that receives the
/// current value.
const SPI_ICONHORIZONTALSPACING = 0x000D;

/// Retrieves the screen saver time-out value, in seconds. The pvParam parameter
/// must point to an integer variable that receives the value.
const SPI_GETSCREENSAVETIMEOUT = 0x000E;

/// Sets the screen saver time-out value to the value of the uiParam parameter.
/// This value is the amount of time, in seconds, that the system must be idle
/// before the screen saver activates.
///
/// If the machine has entered power saving mode or system lock state, an
/// ERROR_OPERATION_IN_PROGRESS exception occurs.
const SPI_SETSCREENSAVETIMEOUT = 0x000F;

/// Determines whether screen saving is enabled. The pvParam parameter must
/// point to a BOOL variable that receives TRUE if screen saving is enabled, or
/// FALSE otherwise.
const SPI_GETSCREENSAVEACTIVE = 0x0010;

/// Sets the state of the screen saver. The uiParam parameter specifies TRUE to
/// activate screen saving, or FALSE to deactivate it.
const SPI_SETSCREENSAVEACTIVE = 0x0011;

/// @nodoc
const SPI_GETGRIDGRANULARITY = 0x0012;

/// @nodoc
const SPI_SETGRIDGRANULARITY = 0x0013;

/// Sets the desktop wallpaper.
const SPI_SETDESKWALLPAPER = 0x0014;

/// Sets the current desktop pattern.
const SPI_SETDESKPATTERN = 0x0015;

/// Retrieves the keyboard repeat-delay setting, which is a value in the range
/// from 0 (approximately 250 ms delay) through 3 (approximately 1 second
/// delay).
///
/// The actual delay associated with each value may vary depending on the
/// hardware. The pvParam parameter must point to an integer variable that
/// receives the setting.
const SPI_GETKEYBOARDDELAY = 0x0016;

/// Sets the keyboard repeat-delay setting.
///
/// The uiParam parameter must specify 0, 1, 2, or 3, where zero sets the
/// shortest delay approximately 250 ms) and 3 sets the longest delay
/// (approximately 1 second). The actual delay associated with each value may
/// vary depending on the hardware.
const SPI_SETKEYBOARDDELAY = 0x0017;

/// Sets or retrieves the height, in pixels, of an icon cell.
///
/// To set this value, set uiParam to the new value and set pvParam to NULL. You
/// cannot set this value to less than SM_CYICON.
///
/// To retrieve this value, pvParam must point to an integer that receives the
/// current value.
const SPI_ICONVERTICALSPACING = 0x0018;

/// Determines whether icon-title wrapping is enabled. The pvParam parameter
/// must point to a BOOL variable that receives TRUE if enabled, or FALSE
/// otherwise.
const SPI_GETICONTITLEWRAP = 0x0019;

/// Turns icon-title wrapping on or off. The uiParam parameter specifies TRUE
/// for on, or FALSE for off.
const SPI_SETICONTITLEWRAP = 0x001A;

/// Determines whether pop-up menus are left-aligned or right-aligned, relative
/// to the corresponding menu-bar item. The pvParam parameter must point to a
/// BOOL variable that receives TRUE if right-aligned, or FALSE otherwise.
const SPI_GETMENUDROPALIGNMENT = 0x001B;

/// Sets the alignment value of pop-up menus. The uiParam parameter specifies
/// TRUE for right alignment, or FALSE for left alignment.
const SPI_SETMENUDROPALIGNMENT = 0x001C;

/// Sets the width of the double-click rectangle to the value of the uiParam
/// parameter.
///
/// The double-click rectangle is the rectangle within which the second click of
/// a double-click must fall for it to be registered as a double-click.
///
/// To retrieve the width of the double-click rectangle, call GetSystemMetrics
/// with the SM_CXDOUBLECLK flag.
const SPI_SETDOUBLECLKWIDTH = 0x001D;

/// Sets the height of the double-click rectangle to the value of the uiParam
/// parameter.
///
/// The double-click rectangle is the rectangle within which the second click of
/// a double-click must fall for it to be registered as a double-click.
///
/// To retrieve the height of the double-click rectangle, call GetSystemMetrics
/// with the SM_CYDOUBLECLK flag.
const SPI_SETDOUBLECLKHEIGHT = 0x001E;

/// Retrieves the logical font information for the current icon-title font. The
/// uiParam parameter specifies the size of a LOGFONT structure, and the pvParam
/// parameter must point to the LOGFONT structure to fill in.
const SPI_GETICONTITLELOGFONT = 0x001F;

/// Sets the double-click time for the mouse to the value of the uiParam
/// parameter. If the uiParam value is greater than 5000 milliseconds, the
/// system sets the double-click time to 5000 milliseconds.
///
/// The double-click time is the maximum number of milliseconds that can occur
/// between the first and second clicks of a double-click. You can also call the
/// SetDoubleClickTime function to set the double-click time. To get the current
/// double-click time, call the GetDoubleClickTime function.
const SPI_SETDOUBLECLICKTIME = 0x0020;

/// Swaps or restores the meaning of the left and right mouse buttons. The
/// uiParam parameter specifies TRUE to swap the meanings of the buttons, or
/// FALSE to restore their original meanings.
///
/// To retrieve the current setting, call GetSystemMetrics with the
/// SM_SWAPBUTTON flag.
const SPI_SETMOUSEBUTTONSWAP = 0x0021;

/// Sets the font that is used for icon titles. The uiParam parameter specifies
/// the size of a LOGFONT structure, and the pvParam parameter must point to a
/// LOGFONT structure.
const SPI_SETICONTITLELOGFONT = 0x0022;

/// @nodoc
const SPI_GETFASTTASKSWITCH = 0x0023;

/// @nodoc
const SPI_SETFASTTASKSWITCH = 0x0024;

/// Sets dragging of full windows either on or off. The uiParam parameter
/// specifies TRUE for on, or FALSE for off.
const SPI_SETDRAGFULLWINDOWS = 0x0025;

/// Determines whether dragging of full windows is enabled. The pvParam
/// parameter must point to a BOOL variable that receives TRUE if enabled, or
/// FALSE otherwise.
const SPI_GETDRAGFULLWINDOWS = 0x0026;

/// Retrieves the metrics associated with the nonclient area of nonminimized
/// windows. The pvParam parameter must point to a NONCLIENTMETRICS structure
/// that receives the information. Set the cbSize member of this structure and
/// the uiParam parameter to sizeof(NONCLIENTMETRICS).
const SPI_GETNONCLIENTMETRICS = 0x0029;

/// Sets the metrics associated with the nonclient area of nonminimized windows.
/// The pvParam parameter must point to a NONCLIENTMETRICS structure that
/// contains the new parameters. Set the cbSize member of this structure and the
/// uiParam parameter to sizeof(NONCLIENTMETRICS). Also, the lfHeight member of
/// the LOGFONT structure must be a negative value.
const SPI_SETNONCLIENTMETRICS = 0x002A;

/// Retrieves the metrics associated with minimized windows. The pvParam
/// parameter must point to a MINIMIZEDMETRICS structure that receives the
/// information. Set the cbSize member of this structure and the uiParam
/// parameter to sizeof(MINIMIZEDMETRICS).
const SPI_GETMINIMIZEDMETRICS = 0x002B;

/// Sets the metrics associated with minimized windows. The pvParam parameter
/// must point to a MINIMIZEDMETRICS structure that contains the new parameters.
/// Set the cbSize member of this structure and the uiParam parameter to
/// sizeof(MINIMIZEDMETRICS).
const SPI_SETMINIMIZEDMETRICS = 0x002C;

/// Retrieves the metrics associated with icons. The pvParam parameter must
/// point to an ICONMETRICS structure that receives the information. Set the
/// cbSize member of this structure and the uiParam parameter to
/// sizeof(ICONMETRICS).
const SPI_GETICONMETRICS = 0x002D;

/// Sets the metrics associated with icons. The pvParam parameter must point to
/// an ICONMETRICS structure that contains the new parameters. Set the cbSize
/// member of this structure and the uiParam parameter to sizeof(ICONMETRICS).
const SPI_SETICONMETRICS = 0x002E;

/// Sets the size of the work area. The work area is the portion of the screen
/// not obscured by the system taskbar or by application desktop toolbars. The
/// pvParam parameter is a pointer to a RECT structure that specifies the new
/// work area rectangle, expressed in virtual screen coordinates. In a system
/// with multiple display monitors, the function sets the work area of the
/// monitor that contains the specified rectangle.
const SPI_SETWORKAREA = 0x002F;

/// Retrieves the size of the work area on the primary display monitor. The work
/// area is the portion of the screen not obscured by the system taskbar or by
/// application desktop toolbars. The pvParam parameter must point to a RECT
/// structure that receives the coordinates of the work area, expressed in
/// physical pixel size. Any DPI virtualization mode of the caller has no effect
/// on this output.
///
/// To get the work area of a monitor other than the primary display monitor,
/// call the GetMonitorInfo function.
const SPI_GETWORKAREA = 0x0030;

/// @nodoc
const SPI_SETPENWINDOWS = 0x0031;

/// Retrieves information about the HighContrast accessibility feature. The
/// pvParam parameter must point to a HIGHCONTRAST structure that receives the
/// information. Set the cbSize member of this structure and the uiParam
/// parameter to sizeof(HIGHCONTRAST).
const SPI_GETHIGHCONTRAST = 0x0042;

/// Sets the parameters of the HighContrast accessibility feature. The pvParam
/// parameter must point to a HIGHCONTRAST structure that contains the new
/// parameters. Set the cbSize member of this structure and the uiParam
/// parameter to sizeof(HIGHCONTRAST).
const SPI_SETHIGHCONTRAST = 0x0043;

/// Determines whether the user relies on the keyboard instead of the mouse, and
/// wants applications to display keyboard interfaces that would otherwise be
/// hidden. The pvParam parameter must point to a BOOL variable that receives
/// TRUE if the user relies on the keyboard; or FALSE otherwise.
const SPI_GETKEYBOARDPREF = 0x0044;

/// Sets the keyboard preference. The uiParam parameter specifies TRUE if the
/// user relies on the keyboard instead of the mouse, and wants applications to
/// display keyboard interfaces that would otherwise be hidden; uiParam is FALSE
/// otherwise.
const SPI_SETKEYBOARDPREF = 0x0045;

/// Determines whether a screen reviewer utility is running. A screen reviewer
/// utility directs textual information to an output device, such as a speech
/// synthesizer or Braille display. When this flag is set, an application should
/// provide textual information in situations where it would otherwise present
/// the information graphically.
///
/// The pvParam parameter is a pointer to a BOOL variable that receives TRUE if
/// a screen reviewer utility is running, or FALSE otherwise.
///
/// Note: Narrator, the screen reader that is included with Windows, does not
/// set the SPI_SETSCREENREADER or SPI_GETSCREENREADER flags.
const SPI_GETSCREENREADER = 0x0046;

/// Determines whether a screen review utility is running. The uiParam parameter
/// specifies TRUE for on, or FALSE for off.
///
/// Note: Narrator, the screen reader that is included with Windows, does not
/// set the SPI_SETSCREENREADER or SPI_GETSCREENREADER flags.
const SPI_SETSCREENREADER = 0x0047;

/// Retrieves the animation effects associated with user actions. The pvParam
/// parameter must point to an ANIMATIONINFO structure that receives the
/// information. Set the cbSize member of this structure and the uiParam
/// parameter to sizeof(ANIMATIONINFO).
const SPI_GETANIMATION = 0x0048;

/// Sets the animation effects associated with user actions. The pvParam
/// parameter must point to an ANIMATIONINFO structure that contains the new
/// parameters. Set the cbSize member of this structure and the uiParam
/// parameter to sizeof(ANIMATIONINFO).
const SPI_SETANIMATION = 0x0049;

/// Determines whether the font smoothing feature is enabled. This feature uses
/// font antialiasing to make font curves appear smoother by painting pixels at
/// different gray levels.
///
/// The pvParam parameter must point to a BOOL variable that receives TRUE if
/// the feature is enabled, or FALSE if it is not.
const SPI_GETFONTSMOOTHING = 0x004A;

/// Enables or disables the font smoothing feature, which uses font antialiasing
/// to make font curves appear smoother by painting pixels at different gray
/// levels.
///
/// To enable the feature, set the uiParam parameter to TRUE. To disable the
/// feature, set uiParam to FALSE.
const SPI_SETFONTSMOOTHING = 0x004B;

/// Sets the width, in pixels, of the rectangle used to detect the start of a
/// drag operation. Set uiParam to the new value. To retrieve the drag width,
/// call GetSystemMetrics with the SM_CXDRAG flag.
const SPI_SETDRAGWIDTH = 0x004C;

/// Sets the height, in pixels, of the rectangle used to detect the start of a
/// drag operation. Set uiParam to the new value. To retrieve the drag height,
/// call GetSystemMetrics with the SM_CYDRAG flag.
const SPI_SETDRAGHEIGHT = 0x004D;

/// @nodoc
const SPI_SETHANDHELD = 0x004E;

/// This parameter is not supported.
const SPI_GETLOWPOWERTIMEOUT = 0x004F;

/// This parameter is not supported.
const SPI_GETPOWEROFFTIMEOUT = 0x0050;

/// This parameter is not supported.
const SPI_SETLOWPOWERTIMEOUT = 0x0051;

/// This parameter is not supported.
const SPI_SETPOWEROFFTIMEOUT = 0x0052;

/// @nodoc
const SPI_GETLOWPOWERACTIVE = 0x0053;

/// This parameter is not supported.
const SPI_GETPOWEROFFACTIVE = 0x0054;

/// This parameter is not supported.
const SPI_SETLOWPOWERACTIVE = 0x0055;

/// This parameter is not supported.
const SPI_SETPOWEROFFACTIVE = 0x0056;

/// Reloads the system cursors. Set the uiParam parameter to zero and the
/// pvParam parameter to NULL.
const SPI_SETCURSORS = 0x0057;

/// Reloads the system icons. Set the uiParam parameter to zero and the pvParam
/// parameter to NULL.
const SPI_SETICONS = 0x0058;

/// Retrieves the input locale identifier for the system default input language.
///
/// The pvParam parameter must point to an HKL variable that receives this
/// value.
const SPI_GETDEFAULTINPUTLANG = 0x0059;

/// Sets the default input language for the system shell and applications.
///
/// The specified language must be displayable using the current system
/// character set. The pvParam parameter must point to an HKL variable that
/// contains the input locale identifier for the default language.
const SPI_SETDEFAULTINPUTLANG = 0x005A;

/// Sets the hot key set for switching between input languages.
///
/// The uiParam and pvParam parameters are not used. The value sets the shortcut
/// keys in the keyboard property sheets by reading the registry again. The
/// registry must be set before this flag is used.
///
/// The path in the registry is HKEY_CURRENT_USER\Keyboard Layout\Toggle. Valid
/// values are "1" = ALT+SHIFT, "2" = CTRL+SHIFT, and "3" = none.
const SPI_SETLANGTOGGLE = 0x005B;

/// @nodoc
const SPI_GETWINDOWSEXTENSION = 0x005C;

/// Enables or disables the Mouse Trails feature, which improves the visibility
/// of mouse cursor movements by briefly showing a trail of cursors and quickly
/// erasing them.
///
/// To disable the feature, set the uiParam parameter to zero or 1. To enable
/// the feature, set uiParam to a value greater than 1 to indicate the number of
/// cursors drawn in the trail.
const SPI_SETMOUSETRAILS = 0x005D;

/// Determines whether the Mouse Trails feature is enabled. This feature
/// improves the visibility of mouse cursor movements by briefly showing a trail
/// of cursors and quickly erasing them.
///
/// The pvParam parameter must point to an integer variable that receives a
/// value. if the value is zero or 1, the feature is disabled. If the value is
/// greater than 1, the feature is enabled and the value indicates the number of
/// cursors drawn in the trail. The uiParam parameter is not used.
const SPI_GETMOUSETRAILS = 0x005E;

/// @nodoc
const SPI_SETSCREENSAVERRUNNING = 0x0061;

/// @nodoc
const SPI_SCREENSAVERRUNNING = SPI_SETSCREENSAVERRUNNING;

/// Retrieves information about the FilterKeys accessibility feature. The
/// pvParam parameter must point to a FILTERKEYS structure that receives the
/// information. Set the cbSize member of this structure and the uiParam
/// parameter to sizeof(FILTERKEYS).
const SPI_GETFILTERKEYS = 0x0032;

/// Sets the parameters of the FilterKeys accessibility feature. The pvParam
/// parameter must point to a FILTERKEYS structure that contains the new
/// parameters. Set the cbSize member of this structure and the uiParam
/// parameter to sizeof(FILTERKEYS).
const SPI_SETFILTERKEYS = 0x0033;

/// Retrieves information about the ToggleKeys accessibility feature. The
/// pvParam parameter must point to a TOGGLEKEYS structure that receives the
/// information. Set the cbSize member of this structure and the uiParam
/// parameter to sizeof(TOGGLEKEYS).
const SPI_GETTOGGLEKEYS = 0x0034;

/// Sets the parameters of the ToggleKeys accessibility feature. The pvParam
/// parameter must point to a TOGGLEKEYS structure that contains the new
/// parameters. Set the cbSize member of this structure and the uiParam
/// parameter to sizeof(TOGGLEKEYS).
const SPI_SETTOGGLEKEYS = 0x0035;

/// Retrieves information about the MouseKeys accessibility feature. The pvParam
/// parameter must point to a MOUSEKEYS structure that receives the information.
/// Set the cbSize member of this structure and the uiParam parameter to
/// sizeof(MOUSEKEYS).
const SPI_GETMOUSEKEYS = 0x0036;

/// Sets the parameters of the MouseKeys accessibility feature. The pvParam
/// parameter must point to a MOUSEKEYS structure that contains the new
/// parameters. Set the cbSize member of this structure and the uiParam
/// parameter to sizeof(MOUSEKEYS).
const SPI_SETMOUSEKEYS = 0x0037;

// -----------------------------------------------------------------------------
// ShowWindow constants
// -----------------------------------------------------------------------------

/// Hides the window and activates another window.
const SW_HIDE = 0;

/// If the window is minimized or maximized, the system restores it to its
/// original size and position.
const SW_NORMAL = 1;

/// Activates and displays a window.
///
/// If the window is minimized or maximized, the system restores it to its
/// original size and position. An application should specify this flag when
/// displaying the window for the first time.
const SW_SHOWNORMAL = 1;

/// Activates the window and displays it as a minimized window.
const SW_SHOWMINIMIZED = 2;

/// Maximizes the specified window.
const SW_MAXIMIZE = 3;

/// Activates the window and displays it as a maximized window.
const SW_SHOWMAXIMIZED = 3;

/// Displays a window in its most recent size and position.
///
/// This value is similar to SW_SHOWNORMAL, except that the window is not
/// activated.
const SW_SHOWNOACTIVATE = 4;

/// Activates the window and displays it in its current size and position.
const SW_SHOW = 5;

/// Minimizes the specified window and activates the next top-level window in
/// the Z order.
const SW_MINIMIZE = 6;

/// Displays the window as a minimized window.
///
/// This value is similar to SW_SHOWMINIMIZED, except the window is not
/// activated.
const SW_SHOWMINNOACTIVE = 7;

/// Displays the window in its current size and position.
///
/// This value is similar to SW_SHOW, except that the window is not activated.
const SW_SHOWNA = 8;

/// Activates and displays the window.
///
/// If the window is minimized or maximized, the system restores it to its
/// original size and position. An application should specify this flag when
/// restoring a minimized window.
const SW_RESTORE = 9;

/// Sets the show state based on the SW_ value specified in the STARTUPINFO
/// structure passed to the CreateProcess function by the program that started
/// the application.
const SW_SHOWDEFAULT = 10;

/// Minimizes a window, even if the thread that owns the window is not
/// responding.
///
/// This flag should only be used when minimizing windows from a different
/// thread.
const SW_FORCEMINIMIZE = 11;

// -----------------------------------------------------------------------------
// Mapping mode constants
// -----------------------------------------------------------------------------

/// Each logical unit is mapped to one device pixel. Positive x is to the right;
/// positive y is down.
const MM_TEXT = 1;

/// Each logical unit is mapped to 0.1 millimeter. Positive x is to the right;
/// positive y is up.
const MM_LOMETRIC = 2;

/// Each logical unit is mapped to 0.01 millimeter. Positive x is to the right;
/// positive y is up.
const MM_HIMETRIC = 3;

/// Each logical unit is mapped to 0.01 inch. Positive x is to the right;
/// positive y is up.
const MM_LOENGLISH = 4;

/// Each logical unit is mapped to 0.001 inch. Positive x is to the right;
/// positive y is up.
const MM_HIENGLISH = 5;

/// Each logical unit is mapped to one twentieth of a printer's point (1/1440
/// inch, also called a twip). Positive x is to the right; positive y is up.
const MM_TWIPS = 6;

/// Logical units are mapped to arbitrary units with equally scaled axes; that
/// is, one unit along the x-axis is equal to one unit along the y-axis. Use the
/// SetWindowExtEx and SetViewportExtEx functions to specify the units and the
/// orientation of the axes. Graphics device interface (GDI) makes adjustments
/// as necessary to ensure the x and y units remain the same size (When the
/// window extent is set, the viewport will be adjusted to keep the units
/// isotropic).
const MM_ISOTROPIC = 7;

/// Logical units are mapped to arbitrary units with arbitrarily scaled axes.
/// Use the SetWindowExtEx and SetViewportExtEx functions to specify the units,
/// orientation, and scaling.
const MM_ANISOTROPIC = 8;

// -----------------------------------------------------------------------------
// SetWindowPos flags
// -----------------------------------------------------------------------------

/// Retains the current size (ignores the cx and cy parameters).
const SWP_NOSIZE = 0x0001;

/// Retains the current position (ignores X and Y parameters).
const SWP_NOMOVE = 0x0002;

/// Retains the current Z order (ignores the hWndInsertAfter parameter).
const SWP_NOZORDER = 0x0004;

/// Does not redraw changes. If this flag is set, no repainting of any kind
/// occurs. This applies to the client area, the nonclient area (including the
/// title bar and scroll bars), and any part of the parent window uncovered as a
/// result of the window being moved. When this flag is set, the application
/// must explicitly invalidate or redraw any parts of the window and parent
/// window that need redrawing.
const SWP_NOREDRAW = 0x0008;

/// Does not activate the window. If this flag is not set, the window is
/// activated and moved to the top of either the topmost or non-topmost group
/// (depending on the setting of the hWndInsertAfter parameter).
const SWP_NOACTIVATE = 0x0010;

/// Applies new frame styles set using the SetWindowLong function. Sends a
/// WM_NCCALCSIZE message to the window, even if the window's size is not being
/// changed. If this flag is not specified, WM_NCCALCSIZE is sent only when the
/// window's size is being changed.
const SWP_FRAMECHANGED = 0x0020;

/// Displays the window.
const SWP_SHOWWINDOW = 0x0040;

/// Hides the window.
const SWP_HIDEWINDOW = 0x0080;

/// Discards the entire contents of the client area. If this flag is not
/// specified, the valid contents of the client area are saved and copied back
/// into the client area after the window is sized or repositioned.
const SWP_NOCOPYBITS = 0x0100;

/// Does not change the owner window's position in the Z order.
const SWP_NOOWNERZORDER = 0x0200;

/// Prevents the window from receiving the WM_WINDOWPOSCHANGING message.
const SWP_NOSENDCHANGING = 0x0400;

/// Draws a frame (defined in the window's class description) around the window.
const SWP_DRAWFRAME = SWP_FRAMECHANGED;

/// Same as the SWP_NOOWNERZORDER flag.
const SWP_NOREPOSITION = SWP_NOOWNERZORDER;

/// Prevents generation of the WM_SYNCPAINT message.
const SWP_DEFERERASE = 0x2000;

/// If the calling thread and the thread that owns the window are attached to
/// different input queues, the system posts the request to the thread that owns
/// the window. This prevents the calling thread from blocking its execution
/// while other threads process the request.
const SWP_ASYNCWINDOWPOS = 0x4000;

// -----------------------------------------------------------------------------
// Animate Window constants
// -----------------------------------------------------------------------------

/// Animates the window from left to right. This flag can be used with roll or
/// slide animation.
const AW_HOR_POSITIVE = 0x00000001;

/// Animates the window from right to left. This flag can be used with roll or
/// slide animation
const AW_HOR_NEGATIVE = 0x00000002;

/// Animates the window from top to bottom. This flag can be used with roll or
/// slide animation.
const AW_VER_POSITIVE = 0x00000004;

/// Animates the window from bottom to top. This flag can be used with roll or
/// slide animation.
const AW_VER_NEGATIVE = 0x00000008;

/// Makes the window appear to collapse inward if AW_HIDE is used or expand
/// outward if the AW_HIDE is not used. The various direction flags have no
/// effect.
const AW_CENTER = 0x00000010;

/// Hides the window. By default, the window is shown.
const AW_HIDE = 0x00010000;

/// Activates the window.
const AW_ACTIVATE = 0x00020000;

/// Uses slide animation. By default, roll animation is used.
const AW_SLIDE = 0x00040000;

/// Uses a fade effect.
const AW_BLEND = 0x00080000;

// -----------------------------------------------------------------------------
// System Command messages
// -----------------------------------------------------------------------------

/// Sizes the window.
const SC_SIZE = 0xF000;

/// Moves the window.
const SC_MOVE = 0xF010;

/// Minimizes the window.
const SC_MINIMIZE = 0xF020;

/// Maximizes the window.
const SC_MAXIMIZE = 0xF030;

/// Moves to the next window.
const SC_NEXTWINDOW = 0xF040;

/// Moves to the previous window.
const SC_PREVWINDOW = 0xF050;

/// Closes the window.
const SC_CLOSE = 0xF060;

/// Scrolls vertically.
const SC_VSCROLL = 0xF070;

/// Scrolls horizontally.
const SC_HSCROLL = 0xF080;

/// Retrieves the window menu as a result of a mouse click.
const SC_MOUSEMENU = 0xF090;

/// Retrieves the window menu as a result of a keystroke.
const SC_KEYMENU = 0xF100;

/// Restores the window to its normal position and size.
const SC_RESTORE = 0xF120;

/// Activates the Start menu.
const SC_TASKLIST = 0xF130;

/// Executes the screen saver application.
const SC_SCREENSAVE = 0xF140;

/// Activates the window associated with the application-specified hot key. The
/// lParam parameter identifies the window to activate.
const SC_HOTKEY = 0xF150;

/// Selects the default item; the user double-clicked the window menu.
const SC_DEFAULT = 0xF160;

/// Sets the state of the display. This command supports devices that have
/// power-saving features, such as a battery-powered personal computer.
const SC_MONITORPOWER = 0xF170;

/// Changes the cursor to a question mark with a pointer. If the user then
/// clicks a control in the dialog box, the control receives a WM_HELP message.
const SC_CONTEXTHELP = 0xF180;

/// Indicates whether the screen saver is secure.
const SCF_ISSECURE = 0x00000001;

// -----------------------------------------------------------------------------
// System Metrics constants
// -----------------------------------------------------------------------------

/// The width of the screen of the primary display monitor, in pixels.
const SM_CXSCREEN = 0;

/// The height of the screen of the primary display monitor, in pixels.
const SM_CYSCREEN = 1;

/// The width of a vertical scroll bar, in pixels.
const SM_CXVSCROLL = 2;

/// The height of a horizontal scroll bar, in pixels.
const SM_CYHSCROLL = 3;

/// The height of a caption area, in pixels.
const SM_CYCAPTION = 4;

/// The width of a window border, in pixels.
const SM_CXBORDER = 5;

/// The height of a window border, in pixels.
const SM_CYBORDER = 6;

/// This value is the same as SM_CXFIXEDFRAME.
const SM_CXDLGFRAME = 7;

/// This value is the same as SM_CYFIXEDFRAME.
const SM_CYDLGFRAME = 8;

/// The height of the thumb box in a vertical scroll bar, in pixels.
const SM_CYVTHUMB = 9;

/// The width of the thumb box in a horizontal scroll bar, in pixels.
const SM_CXHTHUMB = 10;

/// The default width of an icon, in pixels.
const SM_CXICON = 11;

/// The default height of an icon, in pixels.
const SM_CYICON = 12;

/// The width of a cursor, in pixels.
const SM_CXCURSOR = 13;

/// The height of a cursor, in pixels.
const SM_CYCURSOR = 14;

/// The height of a single-line menu bar, in pixels.
const SM_CYMENU = 15;

/// The width of the client area for a full-screen window on the primary display
/// monitor, in pixels.
const SM_CXFULLSCREEN = 16;

/// The height of the client area for a full-screen window on the primary
/// display monitor, in pixels.
const SM_CYFULLSCREEN = 17;

/// For double byte character set versions of the system, this is the height of
/// the Kanji window at the bottom of the screen, in pixels.
const SM_CYKANJIWINDOW = 18;

/// Nonzero if a mouse is installed; otherwise, 0. This value is rarely zero,
/// because of support for virtual mice and because some systems detect the
/// presence of the port instead of the presence of a mouse.
const SM_MOUSEPRESENT = 19;

/// The height of the arrow bitmap on a vertical scroll bar, in pixels.
const SM_CYVSCROLL = 20;

/// The width of the arrow bitmap on a horizontal scroll bar, in pixels.
const SM_CXHSCROLL = 21;

/// Nonzero if the debug version of User.exe is installed; otherwise, 0.
const SM_DEBUG = 22;

/// Nonzero if the meanings of the left and right mouse buttons are swapped;
/// otherwise, 0.
const SM_SWAPBUTTON = 23;

/// The minimum width of a window, in pixels.
const SM_CXMIN = 28;

/// The minimum height of a window, in pixels.
const SM_CYMIN = 29;

/// The width of a button in a window caption or title bar, in pixels.
const SM_CXSIZE = 30;

/// The height of a button in a window caption or title bar, in pixels.
const SM_CYSIZE = 31;

/// This value is the same as SM_CXSIZEFRAME.
const SM_CXFRAME = 32;

/// This value is the same as SM_CYSIZEFRAME.
const SM_CYFRAME = 33;

/// The minimum tracking width of a window, in pixels. The user cannot drag the
/// window frame to a size smaller than these dimensions.
const SM_CXMINTRACK = 34;

/// The minimum tracking height of a window, in pixels. The user cannot drag the
/// window frame to a size smaller than these dimensions.
const SM_CYMINTRACK = 35;

/// The width of the rectangle around the location of a first click in a
/// double-click sequence, in pixels. The second click must occur within the
/// rectangle that is defined by SM_CXDOUBLECLK and SM_CYDOUBLECLK for the
/// system to consider the two clicks a double-click.
const SM_CXDOUBLECLK = 36;

/// The height of the rectangle around the location of a first click in a
/// double-click sequence, in pixels. The second click must occur within the
/// rectangle defined by SM_CXDOUBLECLK and SM_CYDOUBLECLK for the system to
/// consider the two clicks a double-click. The two clicks must also occur
/// within a specified time.
const SM_CYDOUBLECLK = 37;

/// The width of a grid cell for items in large icon view, in pixels. Each item
/// fits into a rectangle of size SM_CXICONSPACING by SM_CYICONSPACING when
/// arranged. This value is always greater than or equal to SM_CXICON.
const SM_CXICONSPACING = 38;

/// The height of a grid cell for items in large icon view, in pixels. Each item
/// fits into a rectangle of size SM_CXICONSPACING by SM_CYICONSPACING when
/// arranged. This value is always greater than or equal to SM_CYICON.
const SM_CYICONSPACING = 39;

/// Nonzero if drop-down menus are right-aligned with the corresponding menu-bar
/// item; 0 if the menus are left-aligned.
const SM_MENUDROPALIGNMENT = 40;

/// Nonzero if the Microsoft Windows for Pen computing extensions are installed;
/// zero otherwise.
const SM_PENWINDOWS = 41;

/// Nonzero if User32.dll supports DBCS; otherwise, 0.
const SM_DBCSENABLED = 42;

/// The number of buttons on a mouse, or zero if no mouse is installed.
const SM_CMOUSEBUTTONS = 43;

/// The thickness of the frame around the perimeter of a window that has a
/// caption but is not sizable, in pixels. SM_CXFIXEDFRAME is the height of the
/// horizontal border, and SM_CYFIXEDFRAME is the width of the vertical border.
const SM_CXFIXEDFRAME = SM_CXDLGFRAME;

/// The thickness of the frame around the perimeter of a window that has a
/// caption but is not sizable, in pixels. SM_CXFIXEDFRAME is the height of the
/// horizontal border, and SM_CYFIXEDFRAME is the width of the vertical border.
const SM_CYFIXEDFRAME = SM_CYDLGFRAME;

/// The thickness of the sizing border around the perimeter of a window that can
/// be resized, in pixels. SM_CXSIZEFRAME is the width of the horizontal border,
/// and SM_CYSIZEFRAME is the height of the vertical border.
const SM_CXSIZEFRAME = SM_CXFRAME;

/// The thickness of the sizing border around the perimeter of a window that can
/// be resized, in pixels. SM_CXSIZEFRAME is the width of the horizontal border,
/// and SM_CYSIZEFRAME is the height of the vertical border.
const SM_CYSIZEFRAME = SM_CYFRAME;

/// This system metric should be ignored; it always returns 0.
const SM_SECURE = 44;

/// The width of a 3-D border, in pixels.
const SM_CXEDGE = 45;

/// The height of a 3-D border, in pixels.
const SM_CYEDGE = 46;

/// The width of a grid cell for a minimized window, in pixels. Each minimized
/// window fits into a rectangle this size when arranged. This value is always
/// greater than or equal to SM_CXMINIMIZED.
const SM_CXMINSPACING = 47;

/// The height of a grid cell for a minimized window, in pixels. Each minimized
/// window fits into a rectangle this size when arranged. This value is always
/// greater than or equal to SM_CYMINIMIZED.
const SM_CYMINSPACING = 48;

/// The recommended width of a small icon, in pixels. Small icons typically
/// appear in window captions and in small icon view.
const SM_CXSMICON = 49;

/// The recommended height of a small icon, in pixels. Small icons typically
/// appear in window captions and in small icon view.
const SM_CYSMICON = 50;

/// The height of a small caption, in pixels.
const SM_CYSMCAPTION = 51;

/// The width of small caption buttons, in pixels.
const SM_CXSMSIZE = 52;

/// The height of small caption buttons, in pixels.
const SM_CYSMSIZE = 53;

/// The width of menu bar buttons, such as the child window close button that is
/// used in the multiple document interface, in pixels.
const SM_CXMENUSIZE = 54;

/// The height of menu bar buttons, such as the child window close button that
/// is used in the multiple document interface, in pixels.
const SM_CYMENUSIZE = 55;

/// The flags that specify how the system arranged minimized windows.
const SM_ARRANGE = 56;

/// The width of a minimized window, in pixels.
const SM_CXMINIMIZED = 57;

/// The height of a minimized window, in pixels.
const SM_CYMINIMIZED = 58;

/// The default maximum width of a window that has a caption and sizing borders,
/// in pixels. This metric refers to the entire desktop. The user cannot drag
/// the window frame to a size larger than these dimensions.
const SM_CXMAXTRACK = 59;

/// The default maximum height of a window that has a caption and sizing
/// borders, in pixels. This metric refers to the entire desktop. The user
/// cannot drag the window frame to a size larger than these dimensions.
const SM_CYMAXTRACK = 60;

/// The default width, in pixels, of a maximized top-level window on the primary
/// display monitor.
const SM_CXMAXIMIZED = 61;

/// The default height, in pixels, of a maximized top-level window on the
/// primary display monitor.
const SM_CYMAXIMIZED = 62;

/// The least significant bit is set if a network is present; otherwise, it is
/// cleared.
const SM_NETWORK = 63;

/// The value that specifies how the system is started.
const SM_CLEANBOOT = 67;

/// The number of pixels on either side of a mouse-down point that the mouse
/// pointer can move before a drag operation begins. This allows the user to
/// click and release the mouse button easily without unintentionally starting a
/// drag operation. If this value is negative, it is subtracted from the left of
/// the mouse-down point and added to the right of it.
const SM_CXDRAG = 68;

/// The number of pixels above and below a mouse-down point that the mouse
/// pointer can move before a drag operation begins. This allows the user to
/// click and release the mouse button easily without unintentionally starting a
/// drag operation. If this value is negative, it is subtracted from above the
/// mouse-down point and added below it.
const SM_CYDRAG = 69;

/// Nonzero if the user requires an application to present information visually
/// in situations where it would otherwise present the information only in
/// audible form; otherwise, 0.
const SM_SHOWSOUNDS = 70;

/// The width of the default menu check-mark bitmap, in pixels.
const SM_CXMENUCHECK = 71;

/// The height of the default menu check-mark bitmap, in pixels.
const SM_CYMENUCHECK = 72;

/// Nonzero if the computer has a low-end (slow) processor; otherwise, 0.
const SM_SLOWMACHINE = 73;

/// Nonzero if the system is enabled for Hebrew and Arabic languages, 0 if not.
const SM_MIDEASTENABLED = 74;

/// Nonzero if a mouse with a vertical scroll wheel is installed; otherwise 0.
const SM_MOUSEWHEELPRESENT = 75;

/// The coordinates for the left side of the virtual screen. The virtual screen
/// is the bounding rectangle of all display monitors. The SM_CXVIRTUALSCREEN
/// metric is the width of the virtual screen.
const SM_XVIRTUALSCREEN = 76;

/// The coordinates for the top of the virtual screen. The virtual screen is the
/// bounding rectangle of all display monitors. The SM_CYVIRTUALSCREEN metric is
/// the height of the virtual screen.
const SM_YVIRTUALSCREEN = 77;

/// The width of the virtual screen, in pixels. The virtual screen is the
/// bounding rectangle of all display monitors. The SM_XVIRTUALSCREEN metric is
/// the coordinates for the left side of the virtual screen.
const SM_CXVIRTUALSCREEN = 78;

/// The height of the virtual screen, in pixels. The virtual screen is the
/// bounding rectangle of all display monitors. The SM_YVIRTUALSCREEN metric is
/// the coordinates for the top of the virtual screen.
const SM_CYVIRTUALSCREEN = 79;

/// The number of display monitors on a desktop.
const SM_CMONITORS = 80;

/// Nonzero if all the display monitors have the same color format, otherwise,
/// 0. Two displays can have the same bit depth, but different color formats.
/// For example, the red, green, and blue pixels can be encoded with different
/// numbers of bits, or those bits can be located in different places in a pixel
/// color value.
const SM_SAMEDISPLAYFORMAT = 81;

/// Nonzero if Input Method Manager/Input Method Editor features are enabled;
/// otherwise, 0.
const SM_IMMENABLED = 82;

/// The width of the left and right edges of the focus rectangle that the
/// DrawFocusRect draws. This value is in pixels.
const SM_CXFOCUSBORDER = 83;

/// The height of the top and bottom edges of the focus rectangle drawn by
/// DrawFocusRect. This value is in pixels.
const SM_CYFOCUSBORDER = 84;

/// Nonzero if the current operating system is the Windows XP Tablet PC edition
/// or if the current operating system is Windows Vista or Windows 7 and the
/// Tablet PC Input service is started; otherwise, 0.
const SM_TABLETPC = 86;

/// Nonzero if the current operating system is the Windows XP, Media Center
/// Edition, 0 if not.
const SM_MEDIACENTER = 87;

/// Nonzero if the current operating system is Windows 7 Starter Edition,
/// Windows Vista Starter, or Windows XP Starter Edition; otherwise, 0.
const SM_STARTER = 88;

/// The build number if the system is Windows Server 2003 R2; otherwise, 0.
const SM_SERVERR2 = 89;

/// Nonzero if a mouse with a horizontal scroll wheel is installed; otherwise 0.
const SM_MOUSEHORIZONTALWHEELPRESENT = 91;

/// The amount of border padding for captioned windows, in pixels.
const SM_CXPADDEDBORDER = 92;

/// Nonzero if the current operating system is Windows 7 or Windows Server 2008
/// R2 and the Tablet PC Input service is started; otherwise, 0. The return
/// value is a bitmask that specifies the type of digitizer input supported by
/// the device.
const SM_DIGITIZER = 94;

/// Nonzero if there are digitizers in the system; otherwise, 0.
/// SM_MAXIMUMTOUCHES returns the aggregate maximum of the maximum number of
/// contacts supported by every digitizer in the system. If the system has only
/// single-touch digitizers, the return value is 1. If the system has
/// multi-touch digitizers, the return value is the number of simultaneous
/// contacts the hardware can provide.
const SM_MAXIMUMTOUCHES = 95;

/// This system metric is used in a Terminal Services environment. If the
/// calling process is associated with a Terminal Services client session, the
/// return value is nonzero. If the calling process is associated with the
/// Terminal Services console session, the return value is 0
const SM_REMOTESESSION = 0x1000;

/// Nonzero if the current session is shutting down; otherwise, 0.
const SM_SHUTTINGDOWN = 0x2000;

/// This system metric is used in a Terminal Services environment to determine
/// if the current Terminal Server session is being remotely controlled. Its
/// value is nonzero if the current session is remotely controlled; otherwise,
/// 0.
const SM_REMOTECONTROL = 0x2001;

/// Reflects the state of the laptop or slate mode, 0 for Slate Mode and
/// non-zero otherwise.
const SM_CONVERTIBLESLATEMODE = 0x2003;

/// Reflects the state of the docking mode, 0 for Undocked Mode and non-zero
/// otherwise.
const SM_SYSTEMDOCKED = 0x2004;

// -----------------------------------------------------------------------------
// Scrollbar constants
// -----------------------------------------------------------------------------

/// Apply to the window's standard horizontal scroll bar.
const SB_HORZ = 0;

/// Apply to the window's standard vertical scroll bar.
const SB_VERT = 1;

/// Apply to a scroll bar control.
const SB_CTL = 2;

/// Apply to the window's standard horizontal and vertical scroll bars.
const SB_BOTH = 3;

/// Scrolls one line up.
const SB_LINEUP = 0;

/// Scrolls left by one unit.
const SB_LINELEFT = 0;

/// Scrolls one line down.
const SB_LINEDOWN = 1;

/// Scrolls right by one unit.
const SB_LINERIGHT = 1;

/// Scrolls one page up.
const SB_PAGEUP = 2;

/// Scrolls left by the width of the window.
const SB_PAGELEFT = 2;

/// Scrolls one page down.
const SB_PAGEDOWN = 3;

/// Scrolls right by the width of the window.
const SB_PAGERIGHT = 3;

/// The user has dragged the scroll box (thumb) and released the mouse button.
const SB_THUMBPOSITION = 4;

/// The user is dragging the scroll box. This message is sent repeatedly until
/// the user releases the mouse button.
const SB_THUMBTRACK = 5;

/// Scrolls to the upper left.
const SB_TOP = 6;

/// Scrolls to the upper left.
const SB_LEFT = 6;

/// Scrolls to the lower right.
const SB_BOTTOM = 7;

/// Scrolls to the lower right.
const SB_RIGHT = 7;

/// Ends scroll.
const SB_ENDSCROLL = 8;

// -----------------------------------------------------------------------------
// Up/Down Control styles
// -----------------------------------------------------------------------------

/// Causes the position to "wrap" if it is incremented or decremented beyond the
/// ending or beginning of the range.
const UDS_WRAP = 0x0001;

/// Causes the up-down control to set the text of the buddy window (using the
/// WM_SETTEXT message) when the position changes. The text consists of the
/// position formatted as a decimal or hexadecimal string.
const UDS_SETBUDDYINT = 0x0002;

/// Positions the up-down control next to the right edge of the buddy window.
/// The width of the buddy window is decreased to accommodate the width of the
/// up-down control.
const UDS_ALIGNRIGHT = 0x0004;

/// Positions the up-down control next to the left edge of the buddy window. The
/// buddy window is moved to the right, and its width is decreased to
/// accommodate the width of the up-down control.
const UDS_ALIGNLEFT = 0x0008;

/// Automatically selects the previous window in the z-order as the up-down
/// control's buddy window.
const UDS_AUTOBUDDY = 0x0010;

/// Causes the up-down control to increment and decrement the position when the
/// UP ARROW and DOWN ARROW keys are pressed.
const UDS_ARROWKEYS = 0x0020;

/// Causes the up-down control's arrows to point left and right instead of up
/// and down.
const UDS_HORZ = 0x0040;

/// Does not insert a thousands separator between every three decimal digits.
const UDS_NOTHOUSANDS = 0x0080;

/// Causes the control to exhibit "hot tracking" behavior. That is, it
/// highlights the UP ARROW and DOWN ARROW on the control as the pointer passes
/// over them.
const UDS_HOTTRACK = 0x0100;

// -----------------------------------------------------------------------------
// Progress Bar styles
// -----------------------------------------------------------------------------

/// The progress bar displays progress status in a smooth scrolling bar instead
/// of the default segmented bar.
const PBS_SMOOTH = 0x01;

/// The progress bar displays progress status vertically, from bottom to top.
const PBS_VERTICAL = 0x04;

/// Sets the minimum and maximum values for a progress bar and redraws the bar
/// to reflect the new range.
const PBM_SETRANGE = WM_USER + 1;

/// Sets the current position for a progress bar and redraws the bar to reflect
/// the new position.
const PBM_SETPOS = WM_USER + 2;

/// Advances the current position of a progress bar by a specified increment and
/// redraws the bar to reflect the new position.
const PBM_DELTAPOS = WM_USER + 3;

/// Specifies the step increment for a progress bar. The step increment is the
/// amount by which the progress bar increases its current position whenever it
/// receives a PBM_STEPIT message. By default, the step increment is set to 10.
const PBM_SETSTEP = WM_USER + 4;

/// Advances the current position for a progress bar by the step increment and
/// redraws the bar to reflect the new position. An application sets the step
/// increment by sending the PBM_SETSTEP message.
const PBM_STEPIT = WM_USER + 5;

/// Sets the minimum and maximum values for a progress bar to 32-bit values, and
/// redraws the bar to reflect the new range
const PBM_SETRANGE32 = WM_USER + 6;

/// Retrieves information about the current high and low limits of a given
/// progress bar control.
const PBM_GETRANGE = WM_USER + 7;

/// Retrieves the current position of the progress bar.
const PBM_GETPOS = WM_USER + 8;

/// Sets the color of the progress indicator bar in the progress bar control.
const PBM_SETBARCOLOR = WM_USER + 9;

/// Sets the background color in the progress bar.
const PBM_SETBKCOLOR = 0x2001;

/// The progress indicator does not grow in size but instead moves repeatedly
/// along the length of the bar, indicating activity without specifying what
/// proportion of the progress is complete.
const PBS_MARQUEE = 0x08;

/// Sets the progress bar to marquee mode. This causes the progress bar to move
/// like a marquee.
const PBM_SETMARQUEE = WM_USER + 10;

/// Determines the animation behavior that the progress bar should use when
/// moving backward (from a higher value to a lower value). If this is set, then
/// a "smooth" transition will occur, otherwise the control will "jump" to the
/// lower value.
const PBS_SMOOTHREVERSE = 0x10;

/// Retrieves the step increment from a progress bar. The step increment is the
/// amount by which the progress bar increases its current position whenever it
/// receives a PBM_STEPIT message. By default, the step increment is set to 10.
const PBM_GETSTEP = WM_USER + 13;

/// Gets the background color of the progress bar.
const PBM_GETBKCOLOR = WM_USER + 14;

/// Gets the color of the progress bar.
const PBM_GETBARCOLOR = WM_USER + 15;

/// Sets the state of the progress bar.
const PBM_SETSTATE = WM_USER + 16;

/// Gets the state of the progress bar.
const PBM_GETSTATE = WM_USER + 17;

/// In progress.
const PBST_NORMAL = 0x0001;

/// Error.
const PBST_ERROR = 0x0002;

/// Paused.
const PBST_PAUSED = 0x0003;

// -----------------------------------------------------------------------------
// Clipboard Format constants
// -----------------------------------------------------------------------------

/// Text format. Each line ends with a carriage return/linefeed (CR-LF)
/// combination. A null character signals the end of the data. Use this format
/// for ANSI text.
const CF_TEXT = 1;

/// A handle to a bitmap (HBITMAP).
const CF_BITMAP = 2;

/// Handle to a metafile picture format as defined by the METAFILEPICT
/// structure. When passing a CF_METAFILEPICT handle by means of DDE, the
/// application responsible for deleting hMem should also free the metafile
/// referred to by the CF_METAFILEPICT handle.
const CF_METAFILEPICT = 3;

/// Microsoft Symbolic Link (SYLK) format.
const CF_SYLK = 4;

/// Software Arts' Data Interchange Format.
const CF_DIF = 5;

// Tagged-image file format.
const CF_TIFF = 6;

/// Text format containing characters in the OEM character set. Each line ends
/// with a carriage return/linefeed (CR-LF) combination. A null character
/// signals the end of the data.
const CF_OEMTEXT = 7;

/// A memory object containing a BITMAPINFO structure followed by the bitmap
/// bits.
const CF_DIB = 8;

/// Handle to a color palette. Whenever an application places data in the
/// clipboard that depends on or assumes a color palette, it should place the
/// palette on the clipboard as well.
const CF_PALETTE = 9;

/// Data for the pen extensions to the Microsoft Windows for Pen Computing.
const CF_PENDATA = 10;

/// Represents audio data more complex than can be represented in a CF_WAVE
/// standard wave format.
const CF_RIFF = 11;

/// Represents audio data in one of the standard wave formats, such as 11 kHz or
/// 22 kHz PCM.
const CF_WAVE = 12;

/// Unicode text format. Each line ends with a carriage return/linefeed (CR-LF)
/// combination. A null character signals the end of the data.
const CF_UNICODETEXT = 13;

/// A handle to an enhanced metafile (HENHMETAFILE).
const CF_ENHMETAFILE = 14;

/// A handle to type HDROP that identifies a list of files. An application can
/// retrieve information about the files by passing the handle to the
/// DragQueryFile function.
const CF_HDROP = 15;

/// The data is a handle (HGLOBAL) to the locale identifier (LCID) associated
/// with text in the clipboard. When you close the clipboard, if it contains
/// CF_TEXT data but no CF_LOCALE data, the system automatically sets the
/// CF_LOCALE format to the current input language. You can use the CF_LOCALE
/// format to associate a different locale with the clipboard text.
const CF_LOCALE = 16;

/// A memory object containing a BITMAPV5HEADER structure followed by the bitmap
/// color space information and the bitmap bits.
const CF_DIBV5 = 17;

/// Owner-display format. The clipboard owner must display and update the
/// clipboard viewer window, and receive the WM_ASKCBFORMATNAME,
/// WM_HSCROLLCLIPBOARD, WM_PAINTCLIPBOARD, WM_SIZECLIPBOARD, and
/// WM_VSCROLLCLIPBOARD messages.
const CF_OWNERDISPLAY = 0x0080;

/// Text display format associated with a private format.
const CF_DSPTEXT = 0x0081;

/// Bitmap display format associated with a private format.
const CF_DSPBITMAP = 0x0082;

/// Metafile-picture display format associated with a private format.
const CF_DSPMETAFILEPICT = 0x0083;

/// Enhanced metafile display format associated with a private format.
const CF_DSPENHMETAFILE = 0x008E;

/// Start of a range of integer values for private clipboard formats. The range
/// ends with CF_PRIVATELAST.
const CF_PRIVATEFIRST = 0x0200;

/// End of a range of integer values for private clipboard formats.
const CF_PRIVATELAST = 0x02FF;

/// Start of a range of integer values for application-defined GDI object
/// clipboard formats. The range ends with CF_GDIOBJLAST.
const CF_GDIOBJFIRST = 0x0300;

/// End of a range of integer values for application-defined GDI object
/// clipboard formats.
const CF_GDIOBJLAST = 0x03FF;

// -----------------------------------------------------------------------------
// Edit Control constants
// -----------------------------------------------------------------------------

/// Aligns text with the left margin.
const ES_LEFT = 0x0000;

/// Centers text in a single-line or multiline edit control.
const ES_CENTER = 0x0001;

/// Right-aligns text in a single-line or multiline edit control.
const ES_RIGHT = 0x0002;

/// Designates a multiline edit control. The default is single-line edit
/// control.
const ES_MULTILINE = 0x0004;

/// Converts all characters to uppercase as they are typed into the edit
/// control.
const ES_UPPERCASE = 0x0008;

/// Converts all characters to lowercase as they are typed into the edit
/// control.
const ES_LOWERCASE = 0x0010;

/// Displays an asterisk (*) for each character typed into the edit control.
/// This style is valid only for single-line edit controls.
const ES_PASSWORD = 0x0020;

/// Automatically scrolls text up one page when the user presses the ENTER key
/// on the last line.
const ES_AUTOVSCROLL = 0x0040;

/// Automatically scrolls text to the right by 10 characters when the user types
/// a character at the end of the line. When the user presses the ENTER key, the
/// control scrolls all text back to position zero.
const ES_AUTOHSCROLL = 0x0080;

/// Negates the default behavior for an edit control. The default behavior hides
/// the selection when the control loses the input focus and inverts the
/// selection when the control receives the input focus. If you specify
/// ES_NOHIDESEL, the selected text is inverted, even if the control does not
/// have the focus.
const ES_NOHIDESEL = 0x0100;

/// Converts text entered in the edit control. The text is converted from the
/// Windows character set to the OEM character set and then back to the Windows
/// character set. This ensures proper character conversion when the application
/// calls the CharToOem function to convert a Windows string in the edit control
/// to OEM characters. This style is most useful for edit controls that contain
/// file names that will be used on file systems that do not support Unicode.
const ES_OEMCONVERT = 0x0400;

/// Prevents the user from typing or editing text in the edit control.
const ES_READONLY = 0x0800;

/// Specifies that a carriage return be inserted when the user presses the ENTER
/// key while entering text into a multiline edit control in a dialog box. If
/// you do not specify this style, pressing the ENTER key has the same effect as
/// pressing the dialog box's default push button. This style has no effect on a
/// single-line edit control.
const ES_WANTRETURN = 0x1000;

/// Allows only digits to be entered into the edit control. Note that, even with
/// this set, it is still possible to paste non-digits into the edit control.
const ES_NUMBER = 0x2000;

// -----------------------------------------------------------------------------
// Edit control notifications
// -----------------------------------------------------------------------------

/// Sent when an edit control receives the keyboard focus.
const EN_SETFOCUS = 0x0100;

/// Sent when an edit control loses the keyboard focus.
const EN_KILLFOCUS = 0x0200;

/// Sent when the user has taken an action that may have altered text in an edit
/// control.
///
/// Unlike the EN_UPDATE notification code, this notification code is sent after
/// the system updates the screen.
const EN_CHANGE = 0x0300;

/// Sent when an edit control is about to redraw itself. This notification code
/// is sent after the control has formatted the text, but before it displays the
/// text. This makes it possible to resize the edit control window, if
/// necessary.
const EN_UPDATE = 0x0400;

/// Sent when an edit control cannot allocate enough memory to meet a specific
/// request.
const EN_ERRSPACE = 0x0500;

/// Sent when the current text insertion has exceeded the specified number of
/// characters for the edit control. The text insertion has been truncated.
const EN_MAXTEXT = 0x0501;

/// Sent when the user clicks an edit control's horizontal scroll bar.
const EN_HSCROLL = 0x0601;

/// Sent when the user clicks an edit control's vertical scroll bar or when the
/// user scrolls the mouse wheel over the edit control.
const EN_VSCROLL = 0x0602;

/// Sent when the user has changed the edit control direction to left-to-right.
const EN_ALIGN_LTR_EC = 0x0700;

/// Sent when the user has changed the edit control direction to right-to-left.
const EN_ALIGN_RTL_EC = 0x0701;

// -----------------------------------------------------------------------------
// Edit Control messages
// -----------------------------------------------------------------------------

/// Sets the left margin.
const EC_LEFTMARGIN = 0x0001;

/// Sets the right margin.
const EC_RIGHTMARGIN = 0x0002;

/// Rich edit controls: Sets the left and right margins to a narrow width
/// calculated using the text metrics of the control's current font.
///
/// If no font has been set for the control, the margins are set to zero. The
/// lParam parameter is ignored.
const EC_USEFONTINFO = 0xffff;

/// Gets the starting and ending character positions (in TCHARs) of the current
/// selection in an edit control.
///
/// You can send this message to either an edit control or a rich edit control.
const EM_GETSEL = 0x00B0;

/// Selects a range of characters in an edit control.
///
/// You can send this message to either an edit control or a rich edit control.
const EM_SETSEL = 0x00B1;

/// Gets the formatting rectangle of an edit control.
///
/// The formatting rectangle is the limiting rectangle into which the control
/// draws the text. The limiting rectangle is independent of the size of the
/// edit-control window. You can send this message to either an edit control or
/// a rich edit control.
const EM_GETRECT = 0x00B2;

/// Sets the formatting rectangle of a multiline edit control.
///
/// The formatting rectangle is the limiting rectangle into which the control
/// draws the text. The limiting rectangle is independent of the size of the
/// edit control window.
///
/// This message is processed only by multiline edit controls. You can send this
/// message to either an edit control or a rich edit control.
const EM_SETRECT = 0x00B3;

/// Sets the formatting rectangle of a multiline edit control.
///
/// The EM_SETRECTNP message is identical to the EM_SETRECT message, except that
/// EM_SETRECTNP does not redraw the edit control window.
///
/// The formatting rectangle is the limiting rectangle into which the control
/// draws the text. The limiting rectangle is independent of the size of the
/// edit control window.
///
/// This message is processed only by multiline edit controls. You can send this
/// message to either an edit control or a rich edit control.
const EM_SETRECTNP = 0x00B4;

/// Scrolls the text vertically in a multiline edit control.
///
/// This message is equivalent to sending a WM_VSCROLL message to the edit
/// control. You can send this message to either an edit control or a rich edit
/// control.
const EM_SCROLL = 0x00B5;

/// Scrolls the text in a multiline edit control.
const EM_LINESCROLL = 0x00B6;

/// Scrolls the caret into view in an edit control.
///
/// You can send this message to either an edit control or a rich edit control.
const EM_SCROLLCARET = 0x00B7;

/// Gets the state of an edit control's modification flag.
///
/// The flag indicates whether the contents of the edit control have been
/// modified. You can send this message to either an edit control or a rich edit
/// control.
const EM_GETMODIFY = 0x00B8;

/// Sets or clears the modification flag for an edit control.
///
/// The modification flag indicates whether the text within the edit control has
/// been modified. You can send this message to either an edit control or a rich
/// edit control.
const EM_SETMODIFY = 0x00B9;

/// Gets the number of lines in a multiline edit control.
///
/// You can send this message to either an edit control or a rich edit control.
const EM_GETLINECOUNT = 0x00BA;

/// Gets the character index of the first character of a specified line in a
/// multiline edit control.
///
/// A character index is the zero-based index of the character from the
/// beginning of the edit control. You can send this message to either an edit
/// control or a rich edit control.
const EM_LINEINDEX = 0x00BB;

/// Sets the handle of the memory that will be used by a multiline edit control.
const EM_SETHANDLE = 0x00BC;

/// Gets a handle of the memory currently allocated for a multiline edit
/// control's text.
const EM_GETHANDLE = 0x00BD;

/// Gets the position of the scroll box (thumb) in the vertical scroll bar of a
/// multiline edit control.
///
/// You can send this message to either an edit control or a rich edit control.
const EM_GETTHUMB = 0x00BE;

/// Retrieves the length, in characters, of a line in an edit control.
///
/// You can send this message to either an edit control or a rich edit control.
const EM_LINELENGTH = 0x00C1;

/// Replaces the selected text in an edit control or a rich edit control with
/// the specified text.
const EM_REPLACESEL = 0x00C2;

/// Copies a line of text from an edit control and places it in a specified
/// buffer.
///
/// You can send this message to either an edit control or a rich edit control.
const EM_GETLINE = 0x00C4;

/// Sets the text limit of an edit control.
///
/// The text limit is the maximum amount
/// of text, in TCHARs, that the user can type into the edit control. You can
/// send this message to either an edit control or a rich edit control.
const EM_LIMITTEXT = 0x00C5;

/// Determines whether there are any actions in an edit control's undo queue.
///
/// You can send this message to either an edit control or a rich edit control.
const EM_CANUNDO = 0x00C6;

/// This message undoes the last edit control operation in the control's undo
/// queue.
///
/// You can send this message to either an edit control or a rich edit control.
const EM_UNDO = 0x00C7;

/// Sets a flag that determines whether a multiline edit control includes soft
/// line-break characters.
///
/// A soft line break consists of two carriage returns and a line feed and is
/// inserted at the end of a line that is broken because of wordwrapping.
const EM_FMTLINES = 0x00C8;

/// Gets the index of the line that contains the specified character index in a
/// multiline edit control.
///
/// A character index is the zero-based index of the character from the
/// beginning of the edit control. You can send this message to either an edit
/// control or a rich edit control.
const EM_LINEFROMCHAR = 0x00C9;

/// The EM_SETTABSTOPS message sets the tab stops in a multiline edit control.
/// When text is copied to the control, any tab character in the text causes
/// space to be generated up to the next tab stop.
///
/// This message is processed only by multiline edit controls. You can send this
/// message to either an edit control or a rich edit control.
const EM_SETTABSTOPS = 0x00CB;

/// Sets or removes the password character for an edit control.
///
/// When a password character is set, that character is displayed in place of
/// the characters typed by the user. You can send this message to either an
/// edit control or a rich edit control.
const EM_SETPASSWORDCHAR = 0x00CC;

/// Resets the undo flag of an edit control.
///
/// The undo flag is set whenever an
/// operation within the edit control can be undone. You can send this message
/// to either an edit control or a rich edit control.
const EM_EMPTYUNDOBUFFER = 0x00CD;

/// Gets the zero-based index of the uppermost visible line in a multiline edit
/// control.
///
/// You can send this message to either an edit control or a rich edit control.
const EM_GETFIRSTVISIBLELINE = 0x00CE;

/// Sets or removes the read-only style (ES_READONLY) of an edit control.
///
/// You can send this message to either an edit control or a rich edit control.
const EM_SETREADONLY = 0x00CF;

/// Replaces an edit control's default Wordwrap function with an
/// application-defined Wordwrap function.
///
/// You can send this message to either an edit control or a rich edit control.
const EM_SETWORDBREAKPROC = 0x00D0;

/// Gets the address of the current Wordwrap function.
///
/// You can send this message to either an edit control or a rich edit control.
const EM_GETWORDBREAKPROC = 0x00D1;

/// Gets the password character that an edit control displays when the user
/// enters text.
///
/// You can send this message to either an edit control or a rich edit control.
const EM_GETPASSWORDCHAR = 0x00D2;

/// Sets the widths of the left and right margins for an edit control.
///
/// The message redraws the control to reflect the new margins. You can send
/// this message to either an edit control or a rich edit control.
const EM_SETMARGINS = 0x00D3;

/// Gets the widths of the left and right margins for an edit control.
const EM_GETMARGINS = 0x00D4;

/// Sets the text limit of an edit control.
///
/// The text limit is the maximum amount of text, in TCHARs, that the user can
/// type into the edit control. You can send this message to either an edit
/// control or a rich edit control.
const EM_SETLIMITTEXT = EM_LIMITTEXT;

/// Gets the current text limit for an edit control.
///
/// You can send this message to either an edit control or a rich edit control.
const EM_GETLIMITTEXT = 0x00D5;

/// Retrieves the client area coordinates of a specified character in an edit
/// control.
///
/// You can send this message to either an edit control or a rich edit control.
const EM_POSFROMCHAR = 0x00D6;

/// Gets information about the character closest to a specified point in the
/// client area of an edit control.
///
/// You can send this message to either an edit control or a rich edit control.
const EM_CHARFROMPOS = 0x00D7;

/// Sets the status flags that determine how an edit control interacts with the
/// Input Method Editor (IME).
const EM_SETIMESTATUS = 0x00D8;

/// Gets a set of status flags that indicate how the edit control interacts with
/// the Input Method Editor (IME).
const EM_GETIMESTATUS = 0x00D9;

/// Allows enterprise data protection support and paste notifications to be set.
const EM_ENABLEFEATURE = 0x00DA;

// -----------------------------------------------------------------------------
// Button Style constants
// -----------------------------------------------------------------------------

/// Creates a push button that posts a WM_COMMAND message to the owner window
/// when the user selects the button.
const BS_PUSHBUTTON = 0x00000000;

/// Creates a push button that behaves like a BS_PUSHBUTTON style button, but
/// has a distinct appearance. If the button is in a dialog box, the user can
/// select the button by pressing the ENTER key, even when the button does not
/// have the input focus. This style is useful for enabling the user to quickly
/// select the most likely (default) option.
const BS_DEFPUSHBUTTON = 0x00000001;

/// Creates a small, empty check box with text. By default, the text is
/// displayed to the right of the check box. To display the text to the left of
/// the check box, combine this flag with the BS_LEFTTEXT style (or with the
/// equivalent BS_RIGHTBUTTON style).
const BS_CHECKBOX = 0x00000002;

/// Creates a button that is the same as a check box, except that the check
/// state automatically toggles between checked and cleared each time the user
/// selects the check box.
const BS_AUTOCHECKBOX = 0x00000003;

/// Creates a small circle with text. By default, the text is displayed to the
/// right of the circle. To display the text to the left of the circle, combine
/// this flag with the BS_LEFTTEXT style (or with the equivalent BS_RIGHTBUTTON
/// style). Use radio buttons for groups of related, but mutually exclusive
/// choices.
const BS_RADIOBUTTON = 0x00000004;

/// Creates a button that is the same as a check box, except that the box can be
/// grayed as well as checked or cleared. Use the grayed state to show that the
/// state of the check box is not determined.
const BS_3STATE = 0x00000005;

/// Creates a button that is the same as a three-state check box, except that
/// the box changes its state when the user selects it. The state cycles through
/// checked, indeterminate, and cleared.
const BS_AUTO3STATE = 0x00000006;

/// Creates a rectangle in which other controls can be grouped. Any text
/// associated with this style is displayed in the rectangle's upper left
/// corner.
const BS_GROUPBOX = 0x00000007;

/// Obsolete, but provided for compatibility with 16-bit versions of Windows.
/// Applications should use BS_OWNERDRAW instead.
const BS_USERBUTTON = 0x00000008;

/// Creates a button that is the same as a radio button, except that when the
/// user selects it, the system automatically sets the button's check state to
/// checked and automatically sets the check state for all other buttons in the
/// same group to cleared.
const BS_AUTORADIOBUTTON = 0x00000009;

/// Defines a push-box control, which is identical to a PUSHBUTTON, except that
/// it does not display a button face or frame; only the text appears.
const BS_PUSHBOX = 0x0000000A;

/// Creates an owner-drawn button. The owner window receives a WM_DRAWITEM
/// message when a visual aspect of the button has changed. Do not combine the
/// BS_OWNERDRAW style with any other button styles.
const BS_OWNERDRAW = 0x0000000B;

/// Do not use this style. A composite style bit that results from using the OR
/// operator on BS_* style bits. It can be used to mask out valid BS_* bits from
/// a given bitmask. Note that this is out of date and does not correctly
/// include all valid styles. Thus, you should not use this style.
const BS_TYPEMASK = 0x0000000F;

/// Places text on the left side of the radio button or check box when combined
/// with a radio button or check box style. Same as the BS_RIGHTBUTTON style.
const BS_LEFTTEXT = 0x00000020;

/// Specifies that the button displays text.
const BS_TEXT = 0x00000000;

/// Specifies that the button displays an icon. See the Remarks section for its
/// interaction with BS_BITMAP.
const BS_ICON = 0x00000040;

/// Specifies that the button displays a bitmap. See the Remarks section for its
/// interaction with BS_ICON.
const BS_BITMAP = 0x00000080;

/// Left-justifies the text in the button rectangle. However, if the button is a
/// check box or radio button that does not have the BS_RIGHTBUTTON style, the
/// text is left justified on the right side of the check box or radio button.
const BS_LEFT = 0x00000100;

/// Right-justifies text in the button rectangle. However, if the button is a
/// check box or radio button that does not have the BS_RIGHTBUTTON style, the
/// text is right justified on the right side of the check box or radio button.
const BS_RIGHT = 0x00000200;

/// Centers text horizontally in the button rectangle.
const BS_CENTER = 0x00000300;

/// Places text at the top of the button rectangle.
const BS_TOP = 0x00000400;

/// Places text at the bottom of the button rectangle.
const BS_BOTTOM = 0x00000800;

/// Places text in the middle (vertically) of the button rectangle.
const BS_VCENTER = 0x00000C00;

/// Makes a button (such as a check box, three-state check box, or radio button)
/// look and act like a push button. The button looks raised when it isn't
/// pushed or checked, and sunken when it is pushed or checked.
const BS_PUSHLIKE = 0x00001000;

/// Wraps the button text to multiple lines if the text string is too long to
/// fit on a single line in the button rectangle.
const BS_MULTILINE = 0x00002000;

/// Enables a button to send BN_KILLFOCUS and BN_SETFOCUS notification codes to
/// its parent window. Note that buttons send the BN_CLICKED notification code
/// regardless of whether it has this style. To get BN_DBLCLK notification
/// codes, the button must have the BS_RADIOBUTTON or BS_OWNERDRAW style.
const BS_NOTIFY = 0x00004000;

/// Specifies that the button is two-dimensional; it does not use the default
/// shading to create a 3-D image.
const BS_FLAT = 0x00008000;

/// Positions a radio button's circle or a check box's square on the right side
/// of the button rectangle. Same as the BS_LEFTTEXT style.
const BS_RIGHTBUTTON = BS_LEFTTEXT;

// -----------------------------------------------------------------------------
// ScrollInfo constants
// -----------------------------------------------------------------------------

/// Copies the scroll range to the nMin and nMax members of the SCROLLINFO
/// structure pointed to by lpsi.
const SIF_RANGE = 0x0001;

/// Copies the scroll page to the nPage member of the SCROLLINFO structure
/// pointed to by lpsi.
const SIF_PAGE = 0x0002;

/// Copies the scroll position to the nPos member of the SCROLLINFO structure
/// pointed to by lpsi.
const SIF_POS = 0x0004;

/// Disables the scroll bar instead of removing it, if the scroll bar's new
/// parameters make the scroll bar unnecessary.
const SIF_DISABLENOSCROLL = 0x0008;

/// Copies the current scroll box tracking position to the nTrackPos member of
/// the SCROLLINFO structure pointed to by lpsi.
const SIF_TRACKPOS = 0x0010;

/// Combines SIF_RANGE,  SIF_PAGE, SIF_POS and SIF_TRACKPOS.
const SIF_ALL = SIF_RANGE | SIF_PAGE | SIF_POS | SIF_TRACKPOS;

// -----------------------------------------------------------------------------
// PeekMessage options
// -----------------------------------------------------------------------------

/// Messages are not removed from the queue after processing by PeekMessage.
const PM_NOREMOVE = 0x0000;

/// Messages are removed from the queue after processing by PeekMessage.
const PM_REMOVE = 0x0001;

/// Prevents the system from releasing any thread that is waiting for the caller
/// to go idle.
const PM_NOYIELD = 0x0002;

// -----------------------------------------------------------------------------
// DrawText constants
// -----------------------------------------------------------------------------

/// Justifies the text to the top of the rectangle.
const DT_TOP = 0x000;

/// Aligns text to the left.
const DT_LEFT = 0x000;

/// Centers text horizontally in the rectangle.
const DT_CENTER = 0x001;

/// Aligns text to the right.
const DT_RIGHT = 0x002;

/// Centers text vertically. This value is used only with the DT_SINGLELINE
/// value.
const DT_VCENTER = 0x004;

/// Justifies the text to the bottom of the rectangle. This value is used only
/// with the DT_SINGLELINE value.
const DT_BOTTOM = 0x008;

/// Breaks words. Lines are automatically broken between words if a word would
/// extend past the edge of the rectangle specified by the lpRect parameter. A
/// carriage return-line feed sequence also breaks the line.
const DT_WORDBREAK = 0x0010;

/// Displays text on a single line only. Carriage returns and line feeds do not
/// break the line.
const DT_SINGLELINE = 0x0020;

/// Expands tab characters. The default number of characters per tab is eight.
/// The DT_WORD_ELLIPSIS, DT_PATH_ELLIPSIS, and DT_END_ELLIPSIS values cannot be
/// used with the DT_EXPANDTABS value.
const DT_EXPANDTABS = 0x00000040;

/// Sets tab stops. Bits 15-8 (high-order byte of the low-order word) of the
/// uFormat parameter specify the number of characters for each tab. The default
/// number of characters per tab is eight. The DT_CALCRECT, DT_EXTERNALLEADING,
/// DT_INTERNAL, DT_NOCLIP, and DT_NOPREFIX values cannot be used with the
/// DT_TABSTOP value.
const DT_TABSTOP = 0x00000080;

/// Draws without clipping. DrawText is somewhat faster when DT_NOCLIP is used.
const DT_NOCLIP = 0x00000100;

/// Includes the font external leading in line height. Normally, external
/// leading is not included in the height of a line of text.
const DT_EXTERNALLEADING = 0x00000200;

/// Determines the width and height of the rectangle. If there are multiple
/// lines of text, DrawText uses the width of the rectangle pointed to by the
/// lpRect parameter and extends the base of the rectangle to bound the last
/// line of text. If the largest word is wider than the rectangle, the width is
/// expanded. If the text is less than the width of the rectangle, the width is
/// reduced. If there is only one line of text, DrawText modifies the right side
/// of the rectangle so that it bounds the last character in the line. In either
/// case, DrawText returns the height of the formatted text but does not draw
/// the text.
const DT_CALCRECT = 0x00000400;

/// Turns off processing of prefix characters. Normally, DrawText interprets the
/// mnemonic-prefix character & as a directive to underscore the character that
/// follows, and the mnemonic-prefix characters && as a directive to print a
/// single &. By specifying DT_NOPREFIX, this processing is turned off.
const DT_NOPREFIX = 0x00000800;

/// Uses the system font to calculate text metrics.
const DT_INTERNAL = 0x00001000;

/// Duplicates the text-displaying characteristics of a multiline edit control.
/// Specifically, the average character width is calculated in the same manner
/// as for an edit control, and the function does not display a partially
/// visible last line.
const DT_EDITCONTROL = 0x00002000;

/// For displayed text, replaces characters in the middle of the string with
/// ellipses so that the result fits in the specified rectangle. If the string
/// contains backslash (\\) characters, DT_PATH_ELLIPSIS preserves as much as
/// possible of the text after the last backslash.
const DT_PATH_ELLIPSIS = 0x00004000;

/// For displayed text, if the end of a string does not fit in the rectangle, it
/// is truncated and ellipses are added. If a word that is not at the end of the
/// string goes beyond the limits of the rectangle, it is truncated without
/// ellipses.
const DT_END_ELLIPSIS = 0x00008000;

/// Modifies the specified string to match the displayed text. This value has no
/// effect unless DT_END_ELLIPSIS or DT_PATH_ELLIPSIS is specified.
const DT_MODIFYSTRING = 0x00010000;

/// Layout in right-to-left reading order for bidirectional text when the font
/// selected into the hdc is a Hebrew or Arabic font. The default reading order
/// for all text is left-to-right.
const DT_RTLREADING = 0x00020000;

/// Truncates any word that does not fit in the rectangle and adds ellipses.
const DT_WORD_ELLIPSIS = 0x00040000;

/// Prevents a line break at a DBCS (double-wide character string), so that the
/// line breaking rule is equivalent to SBCS strings. For example, this can be
/// used in Korean windows, for more readability of icon labels. This value has
/// no effect unless DT_WORDBREAK is specified.
const DT_NOFULLWIDTHCHARBREAK = 0x00080000;

/// Ignores the ampersand (&) prefix character in the text. The letter that
/// follows will not be underlined, but other mnemonic-prefix characters are
/// still processed.
const DT_HIDEPREFIX = 0x00100000;

/// Draws only an underline at the position of the character following the
/// ampersand (&) prefix character. Does not draw any other characters in the
/// string.
const DT_PREFIXONLY = 0x00200000;

// -----------------------------------------------------------------------------
// Class styles
// -----------------------------------------------------------------------------

/// Redraws the entire window if a movement or size adjustment changes the
/// height of the client area.
const CS_VREDRAW = 0x0001;

/// Redraws the entire window if a movement or size adjustment changes the width
/// of the client area.
const CS_HREDRAW = 0x0002;

/// Sends a double-click message to the window procedure when the user
/// double-clicks the mouse while the cursor is within a window belonging to the
/// class.
const CS_DBLCLKS = 0x0008;

/// Allocates a unique device context for each window in the class.
const CS_OWNDC = 0x0020;

/// Allocates one device context to be shared by all windows in the class.
/// Because window classes are process specific, it is possible for multiple
/// threads of an application to create a window of the same class. It is also
/// possible for the threads to attempt to use the device context
/// simultaneously. When this happens, the system allows only one thread to
/// successfully finish its drawing operation.
const CS_CLASSDC = 0x0040;

/// Sets the clipping rectangle of the child window to that of the parent window
/// so that the child can draw on the parent. A window with the CS_PARENTDC
/// style bit receives a regular device context from the system's cache of
/// device contexts. It does not give the child the parent's device context or
/// device context settings. Specifying CS_PARENTDC enhances an application's
/// performance.
const CS_PARENTDC = 0x0080;

/// Disables Close on the window menu.
const CS_NOCLOSE = 0x0200;

/// Saves, as a bitmap, the portion of the screen image obscured by a window of
/// this class. When the window is removed, the system uses the saved bitmap to
/// restore the screen image, including other windows that were obscured.
/// Therefore, the system does not send WM_PAINT messages to windows that were
/// obscured if the memory used by the bitmap has not been discarded and if
/// other screen actions have not invalidated the stored image.
const CS_SAVEBITS = 0x0800;

/// Aligns the window's client area on a byte boundary (in the x direction).
/// This style affects the width of the window and its horizontal placement on
/// the display.
const CS_BYTEALIGNCLIENT = 0x1000;

/// Aligns the window on a byte boundary (in the x direction). This style
/// affects the width of the window and its horizontal placement on the display.
const CS_BYTEALIGNWINDOW = 0x2000;

/// Indicates that the window class is an application global class.
const CS_GLOBALCLASS = 0x4000;

/// @nodoc
const CS_IME = 0x00010000;

/// Enables the drop shadow effect on a window. The effect is turned on and off
/// through SPI_SETDROPSHADOW. Typically, this is enabled for small, short-lived
/// windows such as menus to emphasize their Z-order relationship to other
/// windows. Windows created from a class with this style must be top-level
/// windows; they may not be child windows.
const CS_DROPSHADOW = 0x00020000;

// ControlWord constant

/// @nodoc
const CW_USEDEFAULT = 0x80000000;

// -----------------------------------------------------------------------------
// MessageBox flags
// -----------------------------------------------------------------------------

/// The message box contains one push button: OK. This is the default.
const MB_OK = 0x00000000;

/// The message box contains two push buttons: OK and Cancel.
const MB_OKCANCEL = 0x00000001;

/// The message box contains three push buttons: Abort, Retry, and Ignore.
const MB_ABORTRETRYIGNORE = 0x00000002;

/// The message box contains three push buttons: Yes, No, and Cancel.
const MB_YESNOCANCEL = 0x00000003;

/// The message box contains two push buttons: Yes and No.
const MB_YESNO = 0x00000004;

/// The message box contains two push buttons: Retry and Cancel.
const MB_RETRYCANCEL = 0x00000005;

/// The message box contains three push buttons: Cancel, Try Again, Continue.
/// Use this message box type instead of MB_ABORTRETRYIGNORE.
const MB_CANCELTRYCONTINUE = 0x00000006;

/// A stop-sign icon appears in the message box.
const MB_ICONHAND = 0x00000010;

/// A question-mark icon appears in the message box.
///
/// The question-mark message icon is no longer recommended because it does not
/// clearly represent a specific type of message and because the phrasing of a
/// message as a question could apply to any message type. In addition, users
/// can confuse the message symbol question mark with Help information.
/// Therefore, do not use this question mark message symbol in your message
/// boxes. The system continues to support its inclusion only for backward
/// compatibility.
const MB_ICONQUESTION = 0x00000020;

/// An exclamation-point icon appears in the message box.
const MB_ICONEXCLAMATION = 0x00000030;

/// An icon consisting of a lowercase letter i in a circle appears in the
/// message box.
const MB_ICONASTERISK = 0x00000040;

/// An exclamation-point icon appears in the message box.
const MB_ICONWARNING = MB_ICONEXCLAMATION;

/// A stop-sign icon appears in the message box.
const MB_ICONERROR = MB_ICONHAND;

/// An icon consisting of a lowercase letter i in a circle appears in the
/// message box.
const MB_ICONINFORMATION = MB_ICONASTERISK;

/// A stop-sign icon appears in the message box.
const MB_ICONSTOP = MB_ICONHAND;

/// The first button is the default button.
///
/// MB_DEFBUTTON1 is the default unless MB_DEFBUTTON2, MB_DEFBUTTON3, or
/// MB_DEFBUTTON4 is specified.
const MB_DEFBUTTON1 = 0x00000000;

/// The second button is the default button.
const MB_DEFBUTTON2 = 0x00000100;

/// The third button is the default button.
const MB_DEFBUTTON3 = 0x00000200;

/// The fourth button is the default button.
const MB_DEFBUTTON4 = 0x00000300;

/// The user must respond to the message box before continuing work in the
/// window identified by the hWnd parameter. However, the user can move to the
/// windows of other threads and work in those windows.
const MB_APPLMODAL = 0x00000000;

/// Same as MB_APPLMODAL except that the message box has the WS_EX_TOPMOST
/// style.
///
/// Use system-modal message boxes to notify the user of serious, potentially
/// damaging errors that require immediate attention (for example, running out
/// of memory). This flag has no effect on the user's ability to interact with
/// windows other than those associated with hWnd.
const MB_SYSTEMMODAL = 0x00001000;

/// Same as MB_APPLMODAL except that all the top-level windows belonging to the
/// current thread are disabled if the hWnd parameter is NULL.
///
/// Use this flag when the calling application or library does not have a window
/// handle available but still needs to prevent input to other windows in the
/// calling thread without suspending other threads.
const MB_TASKMODAL = 0x00002000;

/// Adds a Help button to the message box. When the user clicks the Help button
/// or presses F1, the system sends a WM_HELP message to the owner.
const MB_HELP = 0x00004000;

/// The message box becomes the foreground window. Internally, the system calls
/// the SetForegroundWindow function for the message box.
const MB_SETFOREGROUND = 0x00010000;

/// Same as desktop of the interactive window station.
///
/// If the current input desktop is not the default desktop, MessageBox does not
/// return until the user switches to the default desktop.
const MB_DEFAULT_DESKTOP_ONLY = 0x00020000;

/// The message box is created with the WS_EX_TOPMOST window style.
const MB_TOPMOST = 0x00040000;

/// The text is right-justified.
const MB_RIGHT = 0x00080000;

/// Displays message and caption text using right-to-left reading order on
/// Hebrew and Arabic systems.
const MB_RTLREADING = 0x00100000;

/// The caller is a service notifying the user of an event. The function
/// displays a message box on the current active desktop, even if there is no
/// user logged on to the computer.
const MB_SERVICE_NOTIFICATION = 0x00200000;

// -----------------------------------------------------------------------------
// Menu flags
// -----------------------------------------------------------------------------

/// Indicates that flag gives the identifier of the menu item.
const MF_BYCOMMAND = 0x00000000;

/// Indicates that flag gives the zero-based relative position of the menu item.
const MF_BYPOSITION = 0x00000400;

/// Draws a horizontal dividing line. This flag is used only in a drop-down
/// menu, submenu, or shortcut menu. The line cannot be grayed, disabled, or
/// highlighted. The lpNewItem and uIDNewItem parameters are ignored.
const MF_SEPARATOR = 0x00000800;

/// Enables the menu item so that it can be selected, and restores it from its
/// grayed state.
const MF_ENABLED = 0x00000000;

/// Disables the menu item and grays it so that it cannot be selected.
const MF_GRAYED = 0x00000001;

/// Disables the menu item so that it cannot be selected, but the flag does not
/// gray it.
const MF_DISABLED = 0x00000002;

/// Does not place a check mark next to the item (default). If the application
/// supplies check-mark bitmaps (see SetMenuItemBitmaps), this flag displays the
/// clear bitmap next to the menu item.
const MF_UNCHECKED = 0x00000000;

/// Places a check mark next to the menu item.
const MF_CHECKED = 0x00000008;

/// Specifies that the menu item is a text string; the lpNewItem parameter is a
/// pointer to the string.
const MF_STRING = 0x00000000;

/// Uses a bitmap as the menu item. The lpNewItem parameter contains a handle to
/// the bitmap.
const MF_BITMAP = 0x00000004;

/// Specifies that the item is an owner-drawn item. Before the menu is displayed
/// for the first time, the window that owns the menu receives a WM_MEASUREITEM
/// message to retrieve the width and height of the menu item. The WM_DRAWITEM
/// message is then sent to the window procedure of the owner window whenever
/// the appearance of the menu item must be updated.
const MF_OWNERDRAW = 0x00000100;

/// Specifies that the menu item opens a drop-down menu or submenu. The
/// uIDNewItem parameter specifies a handle to the drop-down menu or submenu.
/// This flag is used to add a menu name to a menu bar, or a menu item that
/// opens a submenu to a drop-down menu, submenu, or shortcut menu.
const MF_POPUP = 0x00000010;

/// Functions the same as the MF_MENUBREAK flag for a menu bar. For a drop-down
/// menu, submenu, or shortcut menu, the new column is separated from the old
/// column by a vertical line.
const MF_MENUBARBREAK = 0x00000020;

/// Places the item on a new line (for a menu bar) or in a new column (for a
/// drop-down menu, submenu, or shortcut menu) without separating columns.
const MF_MENUBREAK = 0x00000040;

/// Removes highlighting from the menu item.
const MF_UNHILITE = 0x00000000;

/// Highlights the menu item. If this flag is not specified, the highlighting is
/// removed from the item.
const MF_HILITE = 0x00000080;

// -----------------------------------------------------------------------------
// Dialog Box styles
// -----------------------------------------------------------------------------

/// Indicates that the coordinates of the dialog box are screen coordinates. If
/// this style is not specified, the coordinates are client coordinates.
const DS_ABSALIGN = 0x01;

/// Obsolete. Do not use.
const DS_SYSMODAL = 0x02;

/// Obsolete. Do not use.
const DS_LOCALEDIT = 0x20;

/// Indicates that the header of the dialog box template (either standard or
/// extended) contains additional data specifying the font to use for text in
/// the client area and controls of the dialog box.
const DS_SETFONT = 0x40;

/// Creates a dialog box with a modal dialog-box frame that can be combined with
/// a title bar and window menu by specifying the WS_CAPTION and WS_SYSMENU
/// styles.
const DS_MODALFRAME = 0x80;

/// Suppresses WM_ENTERIDLE messages that the system would otherwise send to the
/// owner of the dialog box while the dialog box is displayed.
const DS_NOIDLEMSG = 0x100;

/// Causes the system to use the SetForegroundWindow function to bring the
/// dialog box to the foreground. This style is useful for modal dialog boxes
/// that require immediate attention from the user regardless of whether the
/// owner window is the foreground window.
const DS_SETFOREGROUND = 0x200;

/// Obsolete. Do not use.
const DS_3DLOOK = 0x0004;

/// Causes the dialog box to use the monospace SYSTEM_FIXED_FONT instead of the
/// default SYSTEM_FONT.
const DS_FIXEDSYS = 0x0008;

/// Creates the dialog box even if errors occur for example, if a child window
/// cannot be created or if the system cannot create a special data segment for
/// an edit control.
const DS_NOFAILCREATE = 0x0010;

/// Creates a dialog box that works well as a child window of another dialog
/// box, much like a page in a property sheet. This style allows the user to tab
/// among the control windows of a child dialog box, use its accelerator keys,
/// and so on.
const DS_CONTROL = 0x0400;

/// Centers the dialog box in the working area of the monitor that contains the
/// owner window. If no owner window is specified, the dialog box is centered in
/// the working area of a monitor determined by the system. The working area is
/// the area not obscured by the taskbar or any appbars.
const DS_CENTER = 0x0800;

/// Centers the dialog box on the mouse cursor.
const DS_CENTERMOUSE = 0x1000;

/// Includes a question mark in the title bar of the dialog box. When the user
/// clicks the question mark, the cursor changes to a question mark with a
/// pointer.
const DS_CONTEXTHELP = 0x2000;

/// Indicates that the dialog box should use the system font. The typeface
/// member of the extended dialog box template must be set to MS Shell Dlg.
/// Otherwise, this style has no effect.
const DS_SHELLFONT = DS_SETFONT | DS_FIXEDSYS;

// -----------------------------------------------------------------------------
// Static control styles
// -----------------------------------------------------------------------------

/// A simple rectangle and left-aligns the text in the rectangle.
///
/// The text is formatted before it is displayed. Words that extend past the end
/// of a line are automatically wrapped to the beginning of the next
/// left-aligned line. Words that are longer than the width of the control are
/// truncated.
const SS_LEFT = 0x00000000;

/// A simple rectangle and centers the text in the rectangle.
///
/// The text is formatted before it is displayed. Words that extend past the end
/// of a line are automatically wrapped to the beginning of the next centered
/// line. Words that are longer than the width of the control are truncated.
const SS_CENTER = 0x00000001;

/// A simple rectangle and right-aligns the text in the rectangle.
///
/// The text is formatted before it is displayed. Words that extend past the end
/// of a line are automatically wrapped to the beginning of the next
/// right-aligned line. Words that are longer than the width of the control are
/// truncated.
const SS_RIGHT = 0x00000002;

/// An icon to be displayed in the dialog box.
///
/// If the control is created as part of a dialog box, the text is the name of
/// an icon (not a filename) defined elsewhere in the resource file. If the
/// control is created via CreateWindow or a related function, the text is the
/// name of an icon (not a filename) defined in the resource file associated
/// with the module specified by the hInstance parameter to CreateWindow.
const SS_ICON = 0x00000003;

/// A rectangle filled with the current window frame color. This color is black
/// in the default color scheme.
const SS_BLACKRECT = 0x00000004;

/// A rectangle filled with the current screen background color. This color is
/// gray in the default color scheme.
const SS_GRAYRECT = 0x00000005;

/// A rectangle filled with the current window background color. This color is
/// white in the default color scheme.
const SS_WHITERECT = 0x00000006;

/// A box with a frame drawn in the same color as the window frames. This color
/// is black in the default color scheme.
const SS_BLACKFRAME = 0x00000007;

/// A box with a frame drawn with the same color as the screen background
/// (desktop). This color is gray in the default color scheme.
const SS_GRAYFRAME = 0x00000008;

/// A box with a frame drawn with the same color as the window background. This
/// color is white in the default color scheme.
const SS_WHITEFRAME = 0x00000009;

/// Specifies a user-defined item.
const SS_USERITEM = 0x0000000A;

/// A simple rectangle and displays a single line of left-aligned text in the
/// rectangle.
const SS_SIMPLE = 0x0000000B;

/// A simple rectangle and left-aligns the text in the rectangle.
///
/// Tabs are expanded, but words are not wrapped. Text that extends past the
/// end of a line is clipped.
const SS_LEFTNOWORDWRAP = 0x0000000C;

/// The owner of the static control is responsible for drawing the control. The
/// owner window receives a WM_DRAWITEM message whenever the control needs to be
/// drawn.
const SS_OWNERDRAW = 0x0000000D;

/// A bitmap is to be displayed in the static control.
///
/// The text is the name of a bitmap (not a filename) defined elsewhere in the
/// resource file. The style ignores the nWidth and nHeight parameters; the
/// control automatically sizes itself to accommodate the bitmap.
const SS_BITMAP = 0x0000000E;

/// An enhanced metafile is to be displayed in the static control.
///
/// The text is the name of a metafile. An enhanced metafile static control has
/// a fixed size; the metafile is scaled to fit the static control's client
/// area.
const SS_ENHMETAFILE = 0x0000000F;

/// Draws the top and bottom edges of the static control using the EDGE_ETCHED
/// edge style.
const SS_ETCHEDHORZ = 0x00000010;

/// Draws the left and right edges of the static control using the EDGE_ETCHED
/// edge style.
const SS_ETCHEDVERT = 0x00000011;

/// Draws the frame of the static control using the EDGE_ETCHED edge style.
const SS_ETCHEDFRAME = 0x00000012;

/// A composite style bit that results from using the OR operator on SS_* style
/// bits.
///
/// Can be used to mask out valid SS_* bits from a given bitmask. Note that this
/// is out of date and does not correctly include all valid styles. Thus, you
/// should not use this style.
const SS_TYPEMASK = 0x0000001F;

/// Adjusts the bitmap to fit the size of the static control.
///
/// For example, changing the locale can change the system font, and thus
/// controls might be resized. If a static control had a bitmap, the bitmap
/// would no longer fit the control. This style bit dictates automatic
/// redimensioning of bitmaps to fit their controls.
const SS_REALSIZECONTROL = 0x00000040;

/// Prevents interpretation of any ampersand (&) characters in the control's
/// text as accelerator prefix characters.
///
/// These are displayed with the ampersand removed and the next character in the
/// string underlined. This static control style may be included with any of the
/// defined static controls. You can combine SS_NOPREFIX with other styles. This
/// can be useful when filenames or other strings that may contain an ampersand
/// (&) must be displayed in a static control in a dialog box.
const SS_NOPREFIX = 0x00000080;

/// Sends the parent window STN_CLICKED, STN_DBLCLK, STN_DISABLE, and STN_ENABLE
/// notification codes when the user clicks or double-clicks the control.
const SS_NOTIFY = 0x00000100;

/// A bitmap is centered in the static control that contains it.
///
/// The control is not resized, so that a bitmap too large for the control will
/// be clipped. If the static control contains a single line of text, the text
/// is centered vertically in the client area of the control.
const SS_CENTERIMAGE = 0x00000200;

/// The lower right corner of a static control with the SS_BITMAP or SS_ICON
/// style is to remain fixed when the control is resized.
///
/// Only the top and left sides are adjusted to accommodate a new bitmap or
/// icon.
const SS_RIGHTJUST = 0x00000400;

/// Specifies that the actual resource width is used and the icon is loaded
/// using LoadImage. SS_REALSIZEIMAGE is always used in conjunction with
/// SS_ICON.
const SS_REALSIZEIMAGE = 0x00000800;

/// Draws a half-sunken border around a static control.
const SS_SUNKEN = 0x00001000;

/// The static control duplicates the text-displaying characteristics of a
/// multiline edit control.
///
/// Specifically, the average character width is calculated in the same manner
/// as with an edit control, and the function does not display a partially
/// visible last line.
const SS_EDITCONTROL = 0x00002000;

/// If the end of a string does not fit in the rectangle, it is truncated and
/// ellipses are added.
///
/// If a word that is not at the end of the string goes beyond the limits of the
/// rectangle, it is truncated without ellipses. Using this style will force the
/// control's text to be on one line with no word wrap. Compare with
/// SS_PATHELLIPSIS and SS_WORDELLIPSIS.
const SS_ENDELLIPSIS = 0x00004000;

/// Replaces characters in the middle of the string with ellipses so that the
/// result fits in the specified rectangle.
///
/// If the string contains backslash (\) characters, SS_PATHELLIPSIS preserves
/// as much as possible of the text after the last backslash. Using this style
/// will force the control's text to be on one line with no word wrap.
const SS_PATHELLIPSIS = 0x00008000;

/// Truncates any word that does not fit in the rectangle and adds ellipses.
/// Using this style will force the control s text to be on one line with no
/// word wrap.
const SS_WORDELLIPSIS = 0x0000C000;

/// Mask for text ellipsis styles.
const SS_ELLIPSISMASK = 0x0000C000;

// -----------------------------------------------------------------------------
// Pen Styles
// -----------------------------------------------------------------------------

/// The pen is solid.
const PS_SOLID = 0;

/// The pen is dashed.
const PS_DASH = 1;

/// The pen is dotted.
const PS_DOT = 2;

/// The pen has alternating dashes and dots.
const PS_DASHDOT = 3;

/// The pen has alternating dashes and double dots.
const PS_DASHDOTDOT = 4;

/// The pen is invisible.
const PS_NULL = 5;

/// The pen is solid. When this pen is used in any GDI drawing function that
/// takes a bounding rectangle, the dimensions of the figure are shrunk so that
/// it fits entirely in the bounding rectangle, taking into account the width of
/// the pen. This applies only to geometric pens.
const PS_INSIDEFRAME = 6;

/// The pen uses a styling array supplied by the user.
const PS_USERSTYLE = 7;

/// The pen sets every other pixel. (This style is applicable only for cosmetic
/// pens.)
const PS_ALTERNATE = 8;

// Mask for pen styles.
const PS_STYLE_MASK = 0x0000000F;

/// End caps are round.
const PS_ENDCAP_ROUND = 0x00000000;

/// End caps are square.
const PS_ENDCAP_SQUARE = 0x00000100;

/// End caps are flat.
const PS_ENDCAP_FLAT = 0x00000200;

/// Mask for pen endcap styles.
const PS_ENDCAP_MASK = 0x00000F00;

/// Line joins are round.
const PS_JOIN_ROUND = 0x00000000;

/// Line joins are beveled.
const PS_JOIN_BEVEL = 0x00001000;

/// Line joins are mitered when they are within the current limit set by the
/// SetMiterLimit function. A join is beveled when it would exceed the limit.
const PS_JOIN_MITER = 0x00002000;

/// Mask for pen join values.
const PS_JOIN_MASK = 0x0000F000;

/// The pen is cosmetic.
const PS_COSMETIC = 0x00000000;

/// The pen is geometric.
const PS_GEOMETRIC = 0x00010000;

/// Mask for pen types.
const PS_TYPE_MASK = 0x000F0000;

// -----------------------------------------------------------------------------
// Brush Styles
// -----------------------------------------------------------------------------

/// Solid brush.
const BS_SOLID = 0;

/// Hollow brush.
const BS_NULL = 1;

/// Hollow brush.
const BS_HOLLOW = BS_NULL;

/// Hatched brush.
const BS_HATCHED = 2;

/// Pattern brush defined by a memory bitmap.
const BS_PATTERN = 3;

/// A pattern brush defined by a device-independent bitmap (DIB) specification.
const BS_DIBPATTERN = 5;

/// A pattern brush defined by a device-independent bitmap (DIB) specification.
const BS_DIBPATTERNPT = 6;

/// Pattern brush defined by a memory bitmap.
const BS_PATTERN8X8 = 7;

/// A pattern brush defined by a device-independent bitmap (DIB) specification.
const BS_DIBPATTERN8X8 = 8;

// -----------------------------------------------------------------------------
// Hatch Styles
// -----------------------------------------------------------------------------

/// Horizontal hatch
const HS_HORIZONTAL = 0;

/// Vertical hatch
const HS_VERTICAL = 1;

/// 45-degree downward left-to-right hatch
const HS_FDIAGONAL = 2;

/// 45-degree upward left-to-right hatch
const HS_BDIAGONAL = 3;

/// Horizontal and vertical crosshatch
const HS_CROSS = 4;

/// 45-degree crosshatch
const HS_DIAGCROSS = 5;

// -----------------------------------------------------------------------------
// Stretching mode constants
// -----------------------------------------------------------------------------

/// Performs a Boolean AND operation using the color values for the eliminated
/// and existing pixels. If the bitmap is a monochrome bitmap, this mode
/// preserves black pixels at the expense of white pixels.
const BLACKONWHITE = 1;

/// Performs a Boolean OR operation using the color values for the eliminated
/// and existing pixels. If the bitmap is a monochrome bitmap, this mode
/// preserves white pixels at the expense of black pixels.
const WHITEONBLACK = 2;

/// Deletes the pixels. This mode deletes all eliminated lines of pixels without
/// trying to preserve their information.
const COLORONCOLOR = 3;

/// Maps pixels from the source rectangle into blocks of pixels in the
/// destination rectangle. The average color over the destination block of
/// pixels approximates the color of the source pixels.
const HALFTONE = 4;

/// Performs a Boolean AND operation using the color values for the eliminated
/// and existing pixels. If the bitmap is a monochrome bitmap, this mode
/// preserves black pixels at the expense of white pixels.
const STRETCH_ANDSCANS = BLACKONWHITE;

/// Performs a Boolean OR operation using the color values for the eliminated
/// and existing pixels. If the bitmap is a monochrome bitmap, this mode
/// preserves white pixels at the expense of black pixels.
const STRETCH_ORSCANS = WHITEONBLACK;

/// Deletes the pixels. This mode deletes all eliminated lines of pixels without
/// trying to preserve their information.
const STRETCH_DELETESCANS = COLORONCOLOR;

/// Maps pixels from the source rectangle into blocks of pixels in the
/// destination rectangle. The average color over the destination block of
/// pixels approximates the color of the source pixels.
const STRETCH_HALFTONE = HALFTONE;

// -----------------------------------------------------------------------------
// Console constants
// -----------------------------------------------------------------------------

// Handles

/// The standard input device. Initially, this is the console input buffer,
/// CONIN$.
const STD_INPUT_HANDLE = -10;

/// The standard output device. Initially, this is the active console screen
/// buffer, CONOUT$.
const STD_OUTPUT_HANDLE = -11;

/// The standard error device. Initially, this is the active console screen
/// buffer, CONOUT$.
const STD_ERROR_HANDLE = -12;

/// Return only when the object is signaled.
const INFINITE = 0xFFFFFFFF;

// Input flags

/// Characters read by the ReadFile or ReadConsole function are written to the
/// active screen buffer as they are read. This mode can be used only if the
/// ENABLE_LINE_INPUT mode is also enabled.
const ENABLE_ECHO_INPUT = 0x0004;

/// Required to enable or disable extended flags. See ENABLE_INSERT_MODE and
/// ENABLE_QUICK_EDIT_MODE.
const ENABLE_EXTENDED_FLAGS = 0x0080;

/// When enabled, text entered in a console window will be inserted at the
/// current cursor location and all text following that location will not be
/// overwritten. When disabled, all following text will be overwritten.
///
/// To enable this mode, use ENABLE_INSERT_MODE | ENABLE_EXTENDED_FLAGS. To
/// disable this mode, use ENABLE_EXTENDED_FLAGS without this flag.
const ENABLE_INSERT_MODE = 0x0020;

/// The ReadFile or ReadConsole function returns only when a carriage return
/// character is read. If this mode is disabled, the functions return when one
/// or more characters are available.
const ENABLE_LINE_INPUT = 0x0002;

/// If the mouse pointer is within the borders of the console window and the
/// window has the keyboard focus, mouse events generated by mouse movement and
/// button presses are placed in the input buffer. These events are discarded by
/// ReadFile or ReadConsole, even when this mode is enabled.
const ENABLE_MOUSE_INPUT = 0x0010;

/// CTRL+C is processed by the system and is not placed in the input buffer. If
/// the input buffer is being read by ReadFile or ReadConsole, other control
/// keys are processed by the system and are not returned in the ReadFile or
/// ReadConsole buffer. If the ENABLE_LINE_INPUT mode is also enabled,
/// backspace, carriage return, and line feed characters are handled by the
/// system.
const ENABLE_PROCESSED_INPUT = 0x0001;

/// This flag enables the user to use the mouse to select and edit text.
///
/// To enable this mode, use ENABLE_QUICK_EDIT_MODE | ENABLE_EXTENDED_FLAGS. To
/// disable this mode, use ENABLE_EXTENDED_FLAGS without this flag.
const ENABLE_QUICK_EDIT_MODE = 0x0040;

/// User interactions that change the size of the console screen buffer are
/// reported in the console's input buffer. Information about these events can
/// be read from the input buffer by applications using the ReadConsoleInput
/// function, but not by those using ReadFile or ReadConsole.
const ENABLE_WINDOW_INPUT = 0x0008;

/// Setting this flag directs the Virtual Terminal processing engine to convert
/// user input received by the console window into Console Virtual Terminal
/// Sequences that can be retrieved by a supporting application through ReadFile
/// or ReadConsole functions.
///
/// The typical usage of this flag is intended in conjunction with
/// ENABLE_VIRTUAL_TERMINAL_PROCESSING on the output handle to connect to an
/// application that communicates exclusively via virtual terminal sequences.
const ENABLE_VIRTUAL_TERMINAL_INPUT = 0x0200;

// Output flags

/// Characters written by the WriteFile or WriteConsole function or echoed by
/// the ReadFile or ReadConsole function are examined for ASCII control
/// sequences and the correct action is performed. Backspace, tab, bell,
/// carriage return, and line feed characters are processed.
const ENABLE_PROCESSED_OUTPUT = 0x0001;

/// When writing with WriteFile or WriteConsole or echoing with ReadFile or
/// ReadConsole, the cursor moves to the beginning of the next row when it
/// reaches the end of the current row. This causes the rows displayed in the
/// console window to scroll up automatically when the cursor advances beyond
/// the last row in the window. It also causes the contents of the console
/// screen buffer to scroll up (discarding the top row of the console screen
/// buffer) when the cursor advances beyond the last row in the console screen
/// buffer. If this mode is disabled, the last character in the row is
/// overwritten with any subsequent characters.
const ENABLE_WRAP_AT_EOL_OUTPUT = 0x0002;

/// When writing with WriteFile or WriteConsole, characters are parsed for VT100
/// and similar control character sequences that control cursor movement,
/// color/font mode, and other operations that can also be performed via the
/// existing Console APIs. For more information, see Console Virtual Terminal
/// Sequences.
const ENABLE_VIRTUAL_TERMINAL_PROCESSING = 0x0004;

/// When writing with WriteFile or WriteConsole, this adds an additional state
/// to end-of-line wrapping that can delay the cursor move and buffer scroll
/// operations.
const DISABLE_NEWLINE_AUTO_RETURN = 0x0008;

/// The APIs for writing character attributes including WriteConsoleOutput and
/// WriteConsoleOutputAttribute allow the usage of flags from character
/// attributes to adjust the color of the foreground and background of text.
/// Additionally, a range of DBCS flags was specified with the COMMON_LVB
/// prefix. Historically, these flags only functioned in DBCS code pages for
/// Chinese, Japanese, and Korean languages.
const ENABLE_LVB_GRID_WORLDWIDE = 0x0010;

/// Indicates how the activation context is to be deactivated.
///
/// If this value is set and the cookie specified in the ulCookie parameter is
/// in the top frame of the activation stack, the function returns an
/// ERROR_INVALID_PARAMETER error code. Call GetLastError to obtain this code.
///
/// If this value is set and the cookie is not on the activation stack, a
/// STATUS_SXS_INVALID_DEACTIVATION exception will be thrown.
///
/// If this value is set and the cookie is in a lower frame of the activation
/// stack, all of the frames down to and including the frame the cookie is in is
/// popped from the stack.
const DEACTIVATE_ACTCTX_FLAG_FORCE_EARLY_DEACTIVATION = 1;

// -----------------------------------------------------------------------------
// Raw input flags
// -----------------------------------------------------------------------------

/// Get the raw data from the RAWINPUT structure.
const RID_INPUT = 0x10000003;

/// Get the header information from the RAWINPUT structure.
const RID_HEADER = 0x10000005;

/// pData is a PHIDP_PREPARSED_DATA pointer to a buffer for a top-level
/// collection's preparsed data.
const RIDI_PREPARSEDDATA = 0x20000005;

/// pData points to a string that contains the device interface name.
const RIDI_DEVICENAME = 0x20000007;

/// pData points to an RID_DEVICE_INFO structure.
const RIDI_DEVICEINFO = 0x2000000b;

/// If set, this removes the top level collection from the inclusion list. This
/// tells the operating system to stop reading from a device which matches the
/// top level collection.
const RIDEV_REMOVE = 0x00000001;

/// If set, this specifies the top level collections to exclude when reading a
/// complete usage page. This flag only affects a TLC whose usage page is
/// already specified with RIDEV_PAGEONLY.
const RIDEV_EXCLUDE = 0x00000010;

/// If set, this specifies all devices whose top level collection is from the
/// specified usUsagePage. Note that usUsage must be zero. To exclude a
/// particular top level collection, use RIDEV_EXCLUDE.
const RIDEV_PAGEONLY = 0x00000020;

/// If set, this prevents any devices specified by usUsagePage or usUsage from
/// generating legacy messages. This is only for the mouse and keyboard.
const RIDEV_NOLEGACY = 0x00000030;

/// If set, this enables the caller to receive the input even when the caller is
/// not in the foreground. Note that hwndTarget must be specified.
const RIDEV_INPUTSINK = 0x00000100;

/// If set, the mouse button click does not activate the other window.
/// RIDEV_CAPTUREMOUSE can be specified only if RIDEV_NOLEGACY is specified for
/// a mouse device.
const RIDEV_CAPTUREMOUSE = 0x00000200;

/// If set, the application-defined keyboard device hotkeys are not handled.
/// However, the system hotkeys; for example, ALT+TAB and CTRL+ALT+DEL, are
/// still handled. By default, all keyboard hotkeys are handled. RIDEV_NOHOTKEYS
/// can be specified even if RIDEV_NOLEGACY is not specified and hwndTarget is
/// NULL.
const RIDEV_NOHOTKEYS = 0x00000200;

/// If set, the application command keys are handled. RIDEV_APPKEYS can be
/// specified only if RIDEV_NOLEGACY is specified for a keyboard device.
const RIDEV_APPKEYS = 0x00000400;

/// If set, this enables the caller to receive input in the background only if
/// the foreground application does not process it. In other words, if the
/// foreground application is not registered for raw input, then the background
/// application that is registered will receive the input.
const RIDEV_EXINPUTSINK = 0x00001000;

/// If set, this enables the caller to receive WM_INPUT_DEVICE_CHANGE
/// notifications for device arrival and device removal.
const RIDEV_DEVNOTIFY = 0x00002000;

// -----------------------------------------------------------------------------
// COM Constants
// -----------------------------------------------------------------------------

/// Operation successful
const S_OK = 0;

/// Operation successful
///
/// Some methods use S_FALSE to mean, roughly, a negative condition that is not
/// a failure. It can also indicate a "no-op"—the method succeeded, but had no
/// effect. For example, the CoInitializeEx function returns S_FALSE if you call
/// it a second time from the same thread. If you need to differentiate between
/// S_OK and S_FALSE in your code, you should test the value directly, but still
/// use FAILED or SUCCEEDED to handle the remaining cases.
const S_FALSE = 1;

/// Unexpected failure
final E_UNEXPECTED = 0x8000FFFF.toSigned(32);

/// Not implemented
final E_NOTIMPL = 0x80004001.toSigned(32);

/// Failed to allocate necessary memory
final E_OUTOFMEMORY = 0x8007000E.toSigned(32);

/// One or more arguments are not valid
final E_INVALIDARG = 0x80070057.toSigned(32);

/// No such interface supported
final E_NOINTERFACE = 0x80004002.toSigned(32);

/// Pointer that is not valid
final E_POINTER = 0x80004003.toSigned(32);

/// Handle that is not valid
final E_HANDLE = 0x80070006.toSigned(32);

/// Operation aborted
final E_ABORT = 0x80004004.toSigned(32);

/// Unspecified failure
final E_FAIL = 0x80004005.toSigned(32);

/// General access denied error
final E_ACCESSDENIED = 0x80070005.toSigned(32);

/// The data necessary to complete this operation is not yet available.
final E_PENDING = 0x8000000A.toSigned(32);

/// typedef short VARIANT_BOOL: -1 == TRUE
final VARIANT_TRUE = -1;

/// typedef short VARIANT_BOOL: 0 == FALSE
final VARIANT_FALSE = 0;

/// Specifies the variant types.
///
/// {@category Enum}
class VARENUM {
  static const VT_EMPTY = 0;
  static const VT_NULL = 1;
  static const VT_I2 = 2;
  static const VT_I4 = 3;
  static const VT_R4 = 4;
  static const VT_R8 = 5;
  static const VT_CY = 6;
  static const VT_DATE = 7;
  static const VT_BSTR = 8;
  static const VT_DISPATCH = 9;
  static const VT_ERROR = 10;
  static const VT_BOOL = 11;
  static const VT_VARIANT = 12;
  static const VT_UNKNOWN = 13;
  static const VT_DECIMAL = 14;
  static const VT_I1 = 16;
  static const VT_UI1 = 17;
  static const VT_UI2 = 18;
  static const VT_UI4 = 19;
  static const VT_I8 = 20;
  static const VT_UI8 = 21;
  static const VT_INT = 22;
  static const VT_UINT = 23;
  static const VT_VOID = 24;
  static const VT_HRESULT = 25;
  static const VT_PTR = 26;
  static const VT_SAFEARRAY = 27;
  static const VT_CARRAY = 28;
  static const VT_USERDEFINED = 29;
  static const VT_LPSTR = 30;
  static const VT_LPWSTR = 31;
  static const VT_RECORD = 36;
  static const VT_INT_PTR = 37;
  static const VT_UINT_PTR = 38;
  static const VT_FILETIME = 64;
  static const VT_BLOB = 65;
  static const VT_STREAM = 66;
  static const VT_STORAGE = 67;
  static const VT_STREAMED_OBJECT = 68;
  static const VT_STORED_OBJECT = 69;
  static const VT_BLOB_OBJECT = 70;
  static const VT_CF = 71;
  static const VT_CLSID = 72;
  static const VT_VERSIONED_STREAM = 73;
  static const VT_BSTR_BLOB = 0xfff;
  static const VT_VECTOR = 0x1000;
  static const VT_ARRAY = 0x2000;
  static const VT_BYREF = 0x4000;
  static const VT_RESERVED = 0x8000;
  static const VT_ILLEGAL = 0xffff;
  static const VT_ILLEGALMASKED = 0xfff;
  static const VT_TYPEMASK = 0xff;
}

/// Prevents the function from attempting to coerce an object to a fundamental
/// type by getting the Value property. Applications should set this flag only
/// if necessary, because it makes their behavior inconsistent with other
/// applications.
const VARIANT_NOVALUEPROP = 0x01;

/// Converts a VT_BOOL value to a string containing either "True" or "False".
const VARIANT_ALPHABOOL = 0x02;

/// For conversions to or from VT_BSTR, passes LOCALE_NOUSEROVERRIDE to the core
/// coercion routines.
const VARIANT_NOUSEROVERRIDE = 0x04;

/// For conversions from VT_BOOL to VT_BSTR and back, uses the language
/// specified by the locale in use on the local computer.
const VARIANT_LOCALBOOL = 0x10;

// -----------------------------------------------------------------------------
// Memory constants
// -----------------------------------------------------------------------------

/// Allocates memory charges (from the overall size of memory and the paging
/// files on disk) for the specified reserved memory pages. The function also
/// guarantees that when the caller later initially accesses the memory, the
/// contents will be zero. Actual physical pages are not allocated unless/until
/// the virtual addresses are actually accessed.
const MEM_COMMIT = 0x00001000;

/// Reserves a range of the process's virtual address space without allocating
/// any actual physical storage in memory or in the paging file on disk.
const MEM_RESERVE = 0x00002000;

/// Replaces a placeholder with a mapped view. Only data/pf-backed section views
/// are supported (no images, physical memory, etc.). When you replace a
/// placeholder, BaseAddress and ViewSize must exactly match those of the
/// placeholder.
const MEM_REPLACE_PLACEHOLDER = 0x00004000;

/// A placeholder is a type of reserved memory region.
const MEM_RESERVE_PLACEHOLDER = 0x00040000;

/// Indicates that data in the memory range specified by lpAddress and dwSize is
/// no longer of interest. The pages should not be read from or written to the
/// paging file. However, the memory block will be used again later, so it
/// should not be decommitted. This value cannot be used with any other value.
const MEM_RESET = 0x00080000;

/// Reserves an address range that can be used to map Address Windowing
/// Extensions (AWE) pages.
const MEM_TOP_DOWN = 0x00100000;

/// Causes the system to track pages that are written to in the allocated
/// region.
const MEM_WRITE_WATCH = 0x00200000;

/// Reserves an address range that can be used to map Address Windowing
/// Extensions (AWE) pages.
const MEM_PHYSICAL = 0x00400000;

/// MEM_RESET_UNDO should only be called on an address range to which MEM_RESET
/// was successfully applied earlier. It indicates that the data in the
/// specified memory range specified by lpAddress and dwSize is of interest to
/// the caller and attempts to reverse the effects of MEM_RESET. If the function
/// succeeds, that means all data in the specified address range is intact. If
/// the function fails, at least some of the data in the address range has been
/// replaced with zeroes.
const MEM_RESET_UNDO = 0x01000000;

/// Allocates memory using large page support.
const MEM_LARGE_PAGES = 0x20000000;

/// Specifies that the priority of the pages being unmapped should be
/// temporarily boosted (with automatic short term decay) because the caller
/// expects that these pages will be accessed again shortly from another thread.
const MEM_UNMAP_WITH_TRANSIENT_BOOST = 0x00000001;

/// To coalesce two adjacent placeholders, specify MEM_RELEASE |
/// MEM_COALESCE_PLACEHOLDERS. When you coalesce placeholders, lpAddress and
/// dwSize must exactly match those of the placeholder.
const MEM_COALESCE_PLACEHOLDERS = 0x00000001;

/// Frees an allocation back to a placeholder (after you've replaced a
/// placeholder with a private allocation using VirtualAlloc2 or
/// Virtual2AllocFromApp).
const MEM_PRESERVE_PLACEHOLDER = 0x00000002;

/// Decommits the specified region of committed pages. After the operation, the
/// pages are in the reserved state.
const MEM_DECOMMIT = 0x00004000;

/// Releases the specified region of pages, or placeholder (for a placeholder,
/// the address space is released and available for other allocations). After
/// this operation, the pages are in the free state.
const MEM_RELEASE = 0x00008000;

/// Indicates free pages not accessible to the calling process and available to
/// be allocated.
const MEM_FREE = 0x00010000;

// -----------------------------------------------------------------------------
// Error model constants
// -----------------------------------------------------------------------------

/// The system does not display the critical-error-handler message box. Instead,
/// the system sends the error to the calling thread.
///
/// Best practice is that all applications call the process-wide SetErrorMode
/// function with a parameter of SEM_FAILCRITICALERRORS at startup. This is to
/// prevent error mode dialogs from hanging the application.
const SEM_FAILCRITICALERRORS = 0x0001;

/// The system does not display the Windows Error Reporting dialog.
const SEM_NOGPFAULTERRORBOX = 0x0002;

/// The system automatically fixes memory alignment faults and makes them
/// invisible to the application. It does this for the calling process and any
/// descendant processes. This feature is only supported by certain processor
/// architectures.
const SEM_NOALIGNMENTFAULTEXCEPT = 0x0004;

/// The OpenFile function does not display a message box when it fails to find a
/// file. Instead, the error is returned to the caller. This error mode
/// overrides the OF_PROMPT flag.
const SEM_NOOPENFILEERRORBOX = 0x8000;

// -----------------------------------------------------------------------------
// Volume information constants
// -----------------------------------------------------------------------------

/// The file system supports case-sensitive file names.
const FILE_CASE_SENSITIVE_SEARCH = 0x00000001;

/// The file system supports preserved case of file names when it places a
/// name on disk.
const FILE_CASE_PRESERVED_NAMES = 0x00000002;

/// The file system supports Unicode in file names as they appear on disk.
const FILE_UNICODE_ON_DISK = 0x00000004;

/// The file system preserves and enforces access control lists (ACL). For
/// example, the NTFS file system preserves and enforces ACLs, and the FAT file
/// system does not.
const FILE_PERSISTENT_ACLS = 0x00000008;

/// The file system supports file-based compression.
const FILE_FILE_COMPRESSION = 0x00000010;

/// The file system supports disk quotas.
const FILE_VOLUME_QUOTAS = 0x00000020;

/// The file system supports sparse files.
const FILE_SUPPORTS_SPARSE_FILES = 0x00000040;

/// The file system supports reparse points.
const FILE_SUPPORTS_REPARSE_POINTS = 0x00000080;

/// The file system supports remote storage.
const FILE_SUPPORTS_REMOTE_STORAGE = 0x00000100;

/// On a successful cleanup operation, the file system returns information that
/// describes additional actions taken during cleanup, such as deleting the
/// file. File system filters can examine this information in their post-cleanup
/// callback.
const FILE_RETURNS_CLEANUP_RESULT_INFO = 0x00000200;

/// The file system supports POSIX-style delete and rename operations.
const FILE_SUPPORTS_POSIX_UNLINK_RENAME = 0x00000400;

/// The file system is a compressed volume. This does not affect how data is
/// transferred over the network.
const FILE_VOLUME_IS_COMPRESSED = 0x00008000;

/// The specified volume supports object identifiers.
const FILE_SUPPORTS_OBJECT_IDS = 0x00010000;

/// The file system supports the Encrypted File System (EFS).
const FILE_SUPPORTS_ENCRYPTION = 0x00020000;

/// The file system supports named data streams for a file.
const FILE_NAMED_STREAMS = 0x00040000;

/// The specified volume is read-only.
const FILE_READ_ONLY_VOLUME = 0x00080000;

/// The specified volume can be written to one time only. The write must be
/// performed in sequential order.
const FILE_SEQUENTIAL_WRITE_ONCE = 0x00100000;

/// The file system supports transaction processing.
const FILE_SUPPORTS_TRANSACTIONS = 0x00200000;

/// The file system supports direct links to other devices and partitions.
const FILE_SUPPORTS_HARD_LINKS = 0x00400000;

/// The specified volume supports extended attributes. An extended attribute is
/// a piece of application-specific metadata that an application can associate
/// with a file and is not part of the file's data.
const FILE_SUPPORTS_EXTENDED_ATTRIBUTES = 0x00800000;

/// The file system supports open by FileID.
const FILE_SUPPORTS_OPEN_BY_FILE_ID = 0x01000000;

/// The specified volume supports update sequence number (USN) journals.
const FILE_SUPPORTS_USN_JOURNAL = 0x02000000;

/// The file system supports integrity streams.
const FILE_SUPPORTS_INTEGRITY_STREAMS = 0x04000000;

/// The file system supports block cloning, that is, sharing logical clusters
/// between files on the same volume. The file system reallocates on writes to
/// shared clusters.
const FILE_SUPPORTS_BLOCK_REFCOUNTING = 0x08000000;

/// The file system tracks whether each cluster of a file contains valid data
/// (either from explicit file writes or automatic zeros) or invalid data (has
/// not yet been written to or zeroed). File systems that use sparse valid data
/// length (VDL) do not store a valid data length and do not require that valid
/// data be contiguous within a file.
const FILE_SUPPORTS_SPARSE_VDL = 0x10000000;

/// The specified volume is a direct access (DAX) volume.
const FILE_DAX_VOLUME = 0x20000000;

/// The file system supports ghosting.
const FILE_SUPPORTS_GHOSTING = 0x40000000;

// -----------------------------------------------------------------------------
// Multimedia constants
// -----------------------------------------------------------------------------
/// Time in milliseconds.
const TIME_MS = 0x0001;

/// Number of waveform-audio samples.
const TIME_SAMPLES = 0x0002;

/// Current byte offset from beginning of the file.
const TIME_BYTES = 0x0004;

/// SMPTE (Society of Motion Picture and Television Engineers) time.
const TIME_SMPTE = 0x0008;

/// MIDI time.
const TIME_MIDI = 0x0010;

/// Ticks within a MIDI stream.
const TIME_TICKS = 0x0020;

/// No callback mechanism. This is the default setting.
const CALLBACK_NULL = 0x00000000;

/// The dwCallback parameter is a window handle.
const CALLBACK_WINDOW = 0x00010000;

/// The dwCallback parameter is a thread identifier.
const CALLBACK_THREAD = 0x00020000;

/// The dwCallback parameter is a callback procedure address.
const CALLBACK_FUNCTION = 0x00030000;

/// The dwCallback parameter is an event handle.
const CALLBACK_EVENT = 0x00050000;

/// The function queries the device to determine whether it supports the given
/// format, but it does not open the device.
const WAVE_FORMAT_QUERY = 0x0001;

/// If this flag is specified, a synchronous waveform-audio device can be
/// opened. If this flag is not specified while opening a synchronous driver,
/// the device will fail to open.
const WAVE_ALLOWSYNC = 0x0002;

/// If this flag is specified, the uDeviceID parameter specifies a
/// waveform-audio device to be mapped to by the wave mapper.
const WAVE_MAPPED = 0x0004;

/// If this flag is specified, the ACM driver does not perform conversions on
/// the audio data.
const WAVE_FORMAT_DIRECT = 0x0008;

/// If this flag is specified and the uDeviceID parameter is WAVE_MAPPER, the
/// function opens the default communication device.
const WAVE_MAPPED_DEFAULT_COMMUNICATION_DEVICE = 0x0010;

// -----------------------------------------------------------------------------
// Layered Window Attributes constants
// -----------------------------------------------------------------------------

/// Use crKey as the transparency color.
const LWA_COLORKEY = 0x00000001;

/// Use bAlpha to determine the opacity of the layered window.
const LWA_ALPHA = 0x00000002;

// -----------------------------------------------------------------------------
// Magnifier constants
// -----------------------------------------------------------------------------

/// Displays the magnified system cursor along with the magnified screen
/// content.
const MS_SHOWMAGNIFIEDCURSOR = 0x0001;

/// Clips the area of the magnifier window that surrounds the system cursor.
/// This style enables the user to see screen content that is behind the
/// magnifier window.
const MS_CLIPAROUNDCURSOR = 0x0002;

/// Displays the magnified screen content using inverted colors.
const MS_INVERTCOLORS = 0x0004;

/// Exclude the windows from magnification.
const MW_FILTERMODE_EXCLUDE = 0;

/// Magnify the windows.
const MW_FILTERMODE_INCLUDE = 1;

// -----------------------------------------------------------------------------
// GetDeviceCaps() constants
// -----------------------------------------------------------------------------

/// The device driver version.
const DRIVERVERSION = 0;

/// Device technology
const TECHNOLOGY = 2;

/// Width, in millimeters, of the physical screen.
const HORZSIZE = 4;

/// Height, in millimeters, of the physical screen.
const VERTSIZE = 6;

/// Width, in pixels, of the screen; or for printers, the width, in pixels, of
/// the printable area of the page.
const HORZRES = 8;

/// Height, in raster lines, of the screen; or for printers, the height, in
/// pixels, of the printable area of the page.
const VERTRES = 10;

/// Number of adjacent color bits for each pixel.
const BITSPIXEL = 12;

/// Number of color planes.
const PLANES = 14;

/// Number of device-specific brushes.
const NUMBRUSHES = 16;

/// Number of device-specific pens.
const NUMPENS = 18;

const NUMMARKERS = 20;

/// Number of device-specific fonts.
const NUMFONTS = 22;

/// Number of entries in the device's color table, if the device has a color
/// depth of no more than 8 bits per pixel. For devices with greater color
/// depths, 1 is returned.
const NUMCOLORS = 24;

/// Reserved.
const PDEVICESIZE = 26;

/// Value that indicates the curve capabilities of the device.
const CURVECAPS = 28;

/// Value that indicates the line capabilities of the device.
const LINECAPS = 30;

/// Value that indicates the line capabilities of the device.
const POLYGONALCAPS = 32;

/// Value that indicates the text capabilities of the device.
const TEXTCAPS = 34;

/// Flag that indicates the clipping capabilities of the device. If the device
/// can clip to a rectangle, it is 1. Otherwise, it is 0.
const CLIPCAPS = 36;

/// Value that indicates the raster capabilities of the device.
const RASTERCAPS = 38;

/// Relative width of a device pixel used for line drawing.
const ASPECTX = 40;

/// Relative height of a device pixel used for line drawing.
const ASPECTY = 42;

/// Diagonal width of the device pixel used for line drawing.
const ASPECTXY = 44;

/// Number of pixels per logical inch along the screen width. In a system with
/// multiple display monitors, this value is the same for all monitors.
const LOGPIXELSX = 88;

/// Number of pixels per logical inch along the screen height. In a system with
/// multiple display monitors, this value is the same for all monitors.
const LOGPIXELSY = 90;

/// Number of entries in the system palette. This index is valid only if the
/// device driver sets the RC_PALETTE bit in the RASTERCAPS index and is
/// available only if the driver is compatible with 16-bit Windows.
const SIZEPALETTE = 104;

/// Number of reserved entries in the system palette. This index is valid only
/// if the device driver sets the RC_PALETTE bit in the RASTERCAPS index and is
/// available only if the driver is compatible with 16-bit Windows.
const NUMRESERVED = 106;

/// Actual color resolution of the device, in bits per pixel. This index is
/// valid only if the device driver sets the RC_PALETTE bit in the RASTERCAPS
/// index and is available only if the driver is compatible with 16-bit Windows.
const COLORRES = 108;

/// For printing devices: the width of the physical page, in device units. For
/// example, a printer set to print at 600 dpi on 8.5-x11-inch paper has a
/// physical width value of 5100 device units. Note that the physical page is
/// almost always greater than the printable area of the page, and never
/// smaller.
const PHYSICALWIDTH = 110;

/// For printing devices: the height of the physical page, in device units. For
/// example, a printer set to print at 600 dpi on 8.5-by-11-inch paper has a
/// physical height value of 6600 device units. Note that the physical page is
/// almost always greater than the printable area of the page, and never
/// smaller.
const PHYSICALHEIGHT = 111;

/// For printing devices: the distance from the left edge of the physical page
/// to the left edge of the printable area, in device units. For example, a
/// printer set to print at 600 dpi on 8.5-by-11-inch paper, that cannot print
/// on the leftmost 0.25-inch of paper, has a horizontal physical offset of 150
/// device units.
const PHYSICALOFFSETX = 112;

/// For printing devices: the distance from the top edge of the physical page to
/// the top edge of the printable area, in device units. For example, a printer
/// set to print at 600 dpi on 8.5-by-11-inch paper, that cannot print on the
/// topmost 0.5-inch of paper, has a vertical physical offset of 300 device
/// units.
const PHYSICALOFFSETY = 113;

/// Scaling factor for the x-axis of the printer.
const SCALINGFACTORX = 114;

/// Scaling factor for the y-axis of the printer.
const SCALINGFACTORY = 115;

/// For display devices: the current vertical refresh rate of the device, in
/// cycles per second (Hz). A vertical refresh rate value of 0 or 1 represents
/// the display hardware's default refresh rate.
const VREFRESH = 116;
const DESKTOPVERTRES = 117;
const DESKTOPHORZRES = 118;

/// Preferred horizontal drawing alignment, expressed as a multiple of pixels.
/// For best drawing performance, windows should be horizontally aligned to a
/// multiple of this value. A value of zero indicates that the device is
/// accelerated, and any alignment may be used.
const BLTALIGNMENT = 119;

/// Value that indicates the shading and blending capabilities of the device.
const SHADEBLENDCAPS = 120;

/// Value that indicates the color management capabilities of the device.
const COLORMGMTCAPS = 121;

// -----------------------------------------------------------------------------
// Multimedia Extensions messages
// -----------------------------------------------------------------------------

/// The MM_JOY1MOVE message notifies the window that has captured joystick
/// JOYSTICKID1 that the joystick position has changed.
const MM_JOY1MOVE = 0x3A0;

/// The MM_JOY2MOVE message notifies the window that has captured joystick
/// JOYSTICKID2 that the joystick position has changed.
const MM_JOY2MOVE = 0x3A1;

/// The MM_JOY1ZMOVE message notifies the window that has captured joystick
/// JOYSTICKID1 that the joystick position on the z-axis has changed.
const MM_JOY1ZMOVE = 0x3A2;

/// The MM_JOY2ZMOVE message notifies the window that has captured joystick
/// JOYSTICKID2 that the joystick position on the z-axis has changed.
const MM_JOY2ZMOVE = 0x3A3;

/// The MM_JOY1BUTTONDOWN message notifies the window that has captured joystick
/// JOYSTICKID1 that a button has been pressed.
const MM_JOY1BUTTONDOWN = 0x3B5;

/// The MM_JOY2BUTTONDOWN message notifies the window that has captured joystick
/// JOYSTICKID2 that a button has been pressed.
const MM_JOY2BUTTONDOWN = 0x3B6;

/// The MM_JOY1BUTTONUP message notifies the window that has captured joystick
/// JOYSTICKID1 that a button has been released.
const MM_JOY1BUTTONUP = 0x3B7;

/// The MM_JOY2BUTTONUP message notifies the window that has captured joystick
/// JOYSTICKID2 that a button has been released.
const MM_JOY2BUTTONUP = 0x3B8;

/// The MM_MCINOTIFY message notifies an application that an MCI device has
/// completed an operation. MCI devices send this message only when the
/// MCI_NOTIFY flag is used.
const MM_MCINOTIFY = 0x3B9;

/// The MM_WOM_OPEN message is sent to a window when the given waveform-audio
/// output device is opened.
const MM_WOM_OPEN = 0x3BB;

/// The MM_WOM_CLOSE message is sent to a window when a waveform-audio output
/// device is closed. The device handle is no longer valid after this message
/// has been sent.
const MM_WOM_CLOSE = 0x3BC;

/// The MM_WOM_DONE message is sent to a window when the given output buffer is
/// being returned to the application. Buffers are returned to the application
/// when they have been played, or as the result of a call to the waveOutReset
/// function.
const MM_WOM_DONE = 0x3BD;

/// The MM_WIM_OPEN message is sent to a window when a waveform-audio input
/// device is opened.
const MM_WIM_OPEN = 0x3BE;

/// The MM_WIM_CLOSE message is sent to a window when a waveform-audio input
/// device is closed. The device handle is no longer valid after this message
/// has been sent.
const MM_WIM_CLOSE = 0x3BF;

/// The MM_WIM_DATA message is sent to a window when waveform-audio data is
/// present in the input buffer and the buffer is being returned to the
/// application. The message can be sent either when the buffer is full or after
/// the waveInReset function is called.
const MM_WIM_DATA = 0x3C0;

/// The MM_MIM_OPEN message is sent to a window when a MIDI input device is
/// opened.
const MM_MIM_OPEN = 0x3C1;

/// The MM_MIM_CLOSE message is sent to a window when a MIDI input device is
/// closed.
const MM_MIM_CLOSE = 0x3C2;

/// The MM_MIM_DATA message is sent to a window when a complete MIDI message is
/// received by a MIDI input device.
const MM_MIM_DATA = 0x3C3;

/// The MM_MIM_LONGDATA message is sent to a window when either a complete MIDI
/// system-exclusive message is received or when a buffer has been filled with
/// system-exclusive data.
const MM_MIM_LONGDATA = 0x3C4;

/// The MM_MIM_ERROR message is sent to a window when an invalid MIDI message is
/// received.
const MM_MIM_ERROR = 0x3C5;

/// The MM_MIM_LONGERROR message is sent to a window when an invalid or
/// incomplete MIDI system-exclusive message is received.
const MM_MIM_LONGERROR = 0x3C6;

/// The MM_MOM_OPEN message is sent to a window when a MIDI output device is
/// opened.
const MM_MOM_OPEN = 0x3C7;

/// The MM_MOM_CLOSE message is sent to a window when a MIDI output device is
/// closed.
const MM_MOM_CLOSE = 0x3C8;

/// The MM_MOM_DONE message is sent to a window when the specified MIDI
/// system-exclusive or stream buffer has been played and is being returned to
/// the application.
const MM_MOM_DONE = 0x3C9;

/// The MM_MOM_POSITIONCB message is sent to a window when an MEVT_F_CALLBACK
/// event is reached in the MIDI output stream.
const MM_MOM_POSITIONCB = 0x3CA;

/// The MM_MCISIGNAL message is sent to a window to notify an application that
/// an MCI device has reached a position defined in a previous signal (
/// MCI_SIGNAL) command.
const MM_MCISIGNAL = 0x3CB;

/// The MM_MIM_MOREDATA message is sent to a callback window when a MIDI message
/// is received by a MIDI input device but the application is not processing
/// MIM_DATA messages fast enough to keep up with the input device driver. The
/// window receives this message only when the application specifies
/// MIDI_IO_STATUS in the call to the midiInOpen function.
const MM_MIM_MOREDATA = 0x3CC;

/// The MM_MIXM_LINE_CHANGE message is sent by a mixer device to notify an
/// application that the state of an audio line on the specified device has
/// changed. The application should refresh its display and cached values for
/// the specified audio line.
const MM_MIXM_LINE_CHANGE = 0x3D0;

/// The MM_MIXM_CONTROL_CHANGE message is sent by a mixer device to notify an
/// application that the state of a control associated with an audio line has
/// changed. The application should refresh its display and cached values for
/// the specified control.
const MM_MIXM_CONTROL_CHANGE = 0x3D1;

/// The MIM_OPEN message is sent to a MIDI input callback function when a MIDI
/// input device is opened.
const MIM_OPEN = MM_MIM_OPEN;

/// The MIM_CLOSE message is sent to a MIDI input callback function when a MIDI
/// input device is closed.
const MIM_CLOSE = MM_MIM_CLOSE;

/// The MIM_DATA message is sent to a MIDI input callback function when a MIDI
/// message is received by a MIDI input device.
const MIM_DATA = MM_MIM_DATA;

/// The MIM_LONGDATA message is sent to a MIDI input callback function when a
/// system-exclusive buffer has been filled with data and is being returned to
/// the application.
const MIM_LONGDATA = MM_MIM_LONGDATA;

/// The MIM_ERROR message is sent to a MIDI input callback function when an
/// invalid MIDI message is received.
const MIM_ERROR = MM_MIM_ERROR;

/// The MIM_LONGERROR message is sent to a MIDI input callback function when an
/// invalid or incomplete MIDI system-exclusive message is received.
const MIM_LONGERROR = MM_MIM_LONGERROR;

/// The MOM_OPEN message is sent to a MIDI output callback function when a MIDI
/// output device is opened.
const MOM_OPEN = MM_MOM_OPEN;

/// The MOM_CLOSE message is sent to a MIDI output callback function when a MIDI
/// output device is closed.
const MOM_CLOSE = MM_MOM_CLOSE;

/// The MOM_DONE message is sent to a MIDI output callback function when the
/// specified system-exclusive or stream buffer has been played and is being
/// returned to the application.
const MOM_DONE = MM_MOM_DONE;

/// The MIM_MOREDATA message is sent to a MIDI input callback function when a
/// MIDI message is received by a MIDI input device but the application is not
/// processing MIM_DATA messages fast enough to keep up with the input device
/// driver. The callback function receives this message only when the
/// application specifies MIDI_IO_STATUS in the call to the midiInOpen function.
const MIM_MOREDATA = MM_MIM_MOREDATA;

/// The MOM_POSITION message is sent when an MEVT_F_CALLBACK event is reached in
/// the MIDI output stream.
const MOM_POSITIONCB = MM_MOM_POSITIONCB;

// -----------------------------------------------------------------------------
// LoadLibrary constants
// -----------------------------------------------------------------------------

/// If this value is used, and the executable module is a DLL, the system does
/// not call DllMain for process and thread initialization and termination.
/// Also, the system does not load additional executable modules that are
/// referenced by the specified module.
const DONT_RESOLVE_DLL_REFERENCES = 0x00000001;

/// If this value is used, the system maps the file into the calling process's
/// virtual address space as if it were a data file. Nothing is done to execute
/// or prepare to execute the mapped file. Therefore, you cannot call functions
/// like GetModuleFileName, GetModuleHandle or GetProcAddress with this DLL.
/// Using this value causes writes to read-only memory to raise an access
/// violation. Use this flag when you want to load a DLL only to extract
/// messages or resources from it.
const LOAD_LIBRARY_AS_DATAFILE = 0x00000002;

/// If this value is used and lpFileName specifies an absolute path, the system
/// uses the alternate file search strategy discussed in the Remarks section to
/// find associated executable modules that the specified module causes to be
/// loaded. If this value is used and lpFileName specifies a relative path, the
/// behavior is undefined.
const LOAD_WITH_ALTERED_SEARCH_PATH = 0x00000008;

/// If this value is used, the system does not check AppLocker rules or apply
/// Software Restriction Policies for the DLL. This action applies only to the
/// DLL being loaded and not to its dependencies. This value is recommended for
/// use in setup programs that must run extracted DLLs during installation.
const LOAD_IGNORE_CODE_AUTHZ_LEVEL = 0x00000010;

/// If this value is used, the system maps the file into the process's virtual
/// address space as an image file. However, the loader does not load the static
/// imports or perform the other usual initialization steps. Use this flag when
/// you want to load a DLL only to extract messages or resources from it.
const LOAD_LIBRARY_AS_IMAGE_RESOURCE = 0x00000020;

/// Similar to LOAD_LIBRARY_AS_DATAFILE, except that the DLL file is opened with
/// exclusive write access for the calling process. Other processes cannot open
/// the DLL file for write access while it is in use. However, the DLL can still
/// be opened by other processes.
const LOAD_LIBRARY_AS_DATAFILE_EXCLUSIVE = 0x00000040;

/// Specifies that the digital signature of the binary image must be checked at
/// load time.
const LOAD_LIBRARY_REQUIRE_SIGNED_TARGET = 0x00000080;

/// If this value is used, the directory that contains the DLL is temporarily
/// added to the beginning of the list of directories that are searched for the
/// DLL's dependencies. Directories in the standard search path are not
/// searched.
const LOAD_LIBRARY_SEARCH_DLL_LOAD_DIR = 0x00000100;

/// If this value is used, the application's installation directory is searched
/// for the DLL and its dependencies. Directories in the standard search path
/// are not searched. This value cannot be combined with
/// LOAD_WITH_ALTERED_SEARCH_PATH.
const LOAD_LIBRARY_SEARCH_APPLICATION_DIR = 0x00000200;

/// If this value is used, directories added using the AddDllDirectory or the
/// SetDllDirectory function are searched for the DLL and its dependencies. If
/// more than one directory has been added, the order in which the directories
/// are searched is unspecified. Directories in the standard search path are not
/// searched. This value cannot be combined with LOAD_WITH_ALTERED_SEARCH_PATH.
const LOAD_LIBRARY_SEARCH_USER_DIRS = 0x00000400;

/// If this value is used, %windows%\system32 is searched for the DLL and its
/// dependencies. Directories in the standard search path are not searched. This
/// value cannot be combined with LOAD_WITH_ALTERED_SEARCH_PATH.
const LOAD_LIBRARY_SEARCH_SYSTEM32 = 0x00000800;

/// This value is a combination of LOAD_LIBRARY_SEARCH_APPLICATION_DIR,
/// LOAD_LIBRARY_SEARCH_SYSTEM32, and LOAD_LIBRARY_SEARCH_USER_DIRS. Directories
/// in the standard search path are not searched. This value cannot be combined
/// with LOAD_WITH_ALTERED_SEARCH_PATH.
const LOAD_LIBRARY_SEARCH_DEFAULT_DIRS = 0x00001000;

/// If this value is used, loading a DLL for execution from the current
/// directory is only allowed if it is under a directory in the Safe load list.
const LOAD_LIBRARY_SAFE_CURRENT_DIRS = 0x00002000;

// -----------------------------------------------------------------------------
// Monitor Configuration constants & enumerations
// -----------------------------------------------------------------------------

const GUID_CLASS_MONITOR = '{4d36e96e-e325-11ce-bfc1-08002be10318}';

/// If the point is not contained within any display monitor, return NULL.
const MONITOR_DEFAULTTONULL = 0x00000000;

/// If the point is not contained within any display monitor, return a handle to
/// the primary display monitor.
const MONITOR_DEFAULTTOPRIMARY = 0x00000001;

/// If the point is not contained within any display monitor, return a handle to
/// the display monitor that is nearest to the point.
const MONITOR_DEFAULTTONEAREST = 0x00000002;

/// This is the primary display monitor.
const MONITORINFOF_PRIMARY = 0x00000001;

/// Describes a monitor's color temperature.
///
/// {@category Enum}
class MC_COLOR_TEMPERATURE {
  static const MC_COLOR_TEMPERATURE_UNKNOWN = 0;
  static const MC_COLOR_TEMPERATURE_4000K = 1;
  static const MC_COLOR_TEMPERATURE_5000K = 2;
  static const MC_COLOR_TEMPERATURE_6500K = 3;
  static const MC_COLOR_TEMPERATURE_7500K = 4;
  static const MC_COLOR_TEMPERATURE_8200K = 5;
  static const MC_COLOR_TEMPERATURE_9300K = 6;
  static const MC_COLOR_TEMPERATURE_10000K = 7;
  static const MC_COLOR_TEMPERATURE_11500K = 8;
}

/// Identifies monitor display technologies.
///
/// {@category Enum}
class MC_DISPLAY_TECHNOLOGY_TYPE {
  static const MC_SHADOW_MASK_CATHODE_RAY_TUBE = 0;
  static const MC_APERTURE_GRILL_CATHODE_RAY_TUBE = 1;
  static const MC_THIN_FILM_TRANSISTOR = 2;
  static const MC_LIQUID_CRYSTAL_ON_SILICON = 3;
  static const MC_PLASMA = 4;
  static const MC_ORGANIC_LIGHT_EMITTING_DIODE = 5;
  static const MC_ELECTROLUMINESCENT = 6;
  static const MC_MICROELECTROMECHANICAL = 7;
  static const MC_FIELD_EMISSION_DEVICE = 8;
}

/// Specifies whether to set or get a monitor's red, green, or blue drive.
///
/// {@category Enum}
class MC_DRIVE_TYPE {
  static const MC_RED_DRIVE = 0;
  static const MC_GREEN_DRIVE = 1;
  static const MC_BLUE_DRIVE = 2;
}

/// Specifies whether to get or set a monitor's red, green, or blue gain.
///
/// {@category Enum}
class MC_GAIN_TYPE {
  static const MC_RED_GAIN = 0;
  static const MC_GREEN_GAIN = 1;
  static const MC_BLUE_GAIN = 2;
}

/// Specifies whether to get or set the vertical or horizontal position of a
/// monitor's display area.
///
/// {@category Enum}
class MC_POSITION_TYPE {
  static const MC_HORIZONTAL_POSITION = 0;
  static const MC_VERTICAL_POSITION = 1;
}

/// Specifies whether to get or set the width or height of a monitor's display
/// area.
///
/// {@category Enum}
class MC_SIZE_TYPE {
  static const MC_WIDTH = 0;
  static const MC_HEIGHT = 1;
}

/// Identifies the dots per inch (dpi) setting for a thread, process, or window.
///
/// {@category Enum}
class DPI_AWARENESS {
  /// Invalid DPI awareness. This is an invalid DPI awareness value.
  static const DPI_AWARENESS_INVALID = -1;

  /// DPI unaware. This process does not scale for DPI changes and is always
  /// assumed to have a scale factor of 100% (96 DPI). It will be automatically
  /// scaled by the system on any other DPI setting.
  static const DPI_AWARENESS_UNAWARE = 0;

  /// System DPI aware. This process does not scale for DPI changes. It will
  /// query for the DPI once and use that value for the lifetime of the process.
  /// If the DPI changes, the process will not adjust to the new DPI value. It
  /// will be automatically scaled up or down by the system when the DPI changes
  /// from the system value.
  static const DPI_AWARENESS_SYSTEM_AWARE = 1;

  /// Per monitor DPI aware. This process checks for the DPI when it is created
  /// and adjusts the scale factor whenever the DPI changes. These processes are
  /// not automatically scaled by the system.
  static const DPI_AWARENESS_PER_MONITOR_AWARE = 2;
}

/// DPI unaware. This window does not scale for DPI changes and is always
/// assumed to have a scale factor of 100% (96 DPI). It will be automatically
/// scaled by the system on any other DPI setting.
const DPI_AWARENESS_CONTEXT_UNAWARE = -1;

/// System DPI aware. This window does not scale for DPI changes. It will query
/// for the DPI once and use that value for the lifetime of the process. If the
/// DPI changes, the process will not adjust to the new DPI value. It will be
/// automatically scaled up or down by the system when the DPI changes from the
/// system value.
const DPI_AWARENESS_CONTEXT_SYSTEM_AWARE = -2;

/// Per monitor DPI aware. This window checks for the DPI when it is created and
/// adjusts the scale factor whenever the DPI changes. These processes are not
/// automatically scaled by the system.
const DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE = -3;

/// Also known as Per Monitor v2. An advancement over the original per-monitor
/// DPI awareness mode, which enables applications to access new DPI-related
/// scaling behaviors on a per top-level window basis.
///
/// Per Monitor v2 was made available in the Creators Update of Windows 10, and
/// is not available on earlier versions of the operating system.
const DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2 = -4;

/// DPI unaware with improved quality of GDI-based content. This mode behaves
/// similarly to DPI_AWARENESS_CONTEXT_UNAWARE, but also enables the system to
/// automatically improve the rendering quality of text and other GDI-based
/// primitives when the window is displayed on a high-DPI monitor.
///
/// DPI_AWARENESS_CONTEXT_UNAWARE_GDISCALED was introduced in the October 2018
/// update of Windows 10 (also known as version 1809).
const DPI_AWARENESS_CONTEXT_UNAWARE_GDISCALED = -5;

/// Identifies the DPI hosting behavior for a window. This behavior allows
/// windows created in the thread to host child windows with a different
/// DPI_AWARENESS_CONTEXT.
///
/// {@category Enum}
class DPI_HOSTING_BEHAVIOR {
  /// Invalid DPI hosting behavior. This usually occurs if the previous
  /// SetThreadDpiHostingBehavior call used an invalid parameter.
  static const DPI_HOSTING_BEHAVIOR_INVALID = -1;

  /// Default DPI hosting behavior. The associated window behaves as normal, and
  /// cannot create or re-parent child windows with a different
  /// DPI_AWARENESS_CONTEXT.
  static const DPI_HOSTING_BEHAVIOR_DEFAULT = 0;

  /// Mixed DPI hosting behavior. This enables the creation and re-parenting of
  /// child windows with different DPI_AWARENESS_CONTEXT. These child windows
  /// will be independently scaled by the OS.
  static const DPI_HOSTING_BEHAVIOR_MIXED = 1;
}

/// Identifies dots per inch (dpi) awareness values. DPI awareness indicates how
/// much scaling work an application performs for DPI versus how much is done by
/// the system.
///
/// {@category Enum}
class PROCESS_DPI_AWARENESS {
  /// DPI unaware. This app does not scale for DPI changes and is always assumed
  /// to have a scale factor of 100% (96 DPI). It will be automatically scaled
  /// by the system on any other DPI setting.
  static const PROCESS_DPI_UNAWARE = 0;

  /// System DPI aware. This app does not scale for DPI changes. It will query
  /// for the DPI once and use that value for the lifetime of the app. If the
  /// DPI changes, the app will not adjust to the new DPI value. It will be
  /// automatically scaled up or down by the system when the DPI changes from
  /// the system value.
  static const PROCESS_SYSTEM_DPI_AWARE = 1;

  /// Per monitor DPI aware. This app checks for the DPI when it is created and
  /// adjusts the scale factor whenever the DPI changes. These applications are
  /// not automatically scaled by the system.
  static const PROCESS_PER_MONITOR_DPI_AWARE = 2;
}

/// Identifies the dots per inch (dpi) setting for a monitor.
///
/// {@category Enum}
class MONITOR_DPI_TYPE {
  /// The effective DPI. This value should be used when determining the correct
  /// scale factor for scaling UI elements. This incorporates the scale factor
  /// set by the user for this specific display.
  static const MDT_EFFECTIVE_DPI = 0;

  /// The angular DPI. This DPI ensures rendering at a compliant angular
  /// resolution on the screen. This does not include the scale factor set by
  /// the user for this specific display.
  static const MDT_ANGULAR_DPI = 1;

  /// The raw DPI. This value is the linear DPI of the screen as measured on the
  /// screen itself. Use this value when you want to read the pixel density and
  /// not the recommended scaling setting. This does not include the scale
  /// factor set by the user for this specific display and is not guaranteed to
  /// be a supported DPI value.
  static const MDT_RAW_DPI = 2;

  /// The default DPI setting for a monitor is MDT_EFFECTIVE_DPI.
  static const MDT_DEFAULT = MDT_EFFECTIVE_DPI;
}

// -----------------------------------------------------------------------------
// Window Display Affinity constants
// -----------------------------------------------------------------------------

/// Imposes no restrictions on where the window can be displayed.
const WDA_NONE = 0x00000000;

/// The window content is displayed only on a monitor. Everywhere else, the
/// window appears with no content.
const WDA_MONITOR = 0x00000001;

/// The window is displayed only on a monitor. Everywhere else, the window does
/// not appear at all. One use for this affinity is for windows that show video
/// recording controls, so that the controls are not included in the capture.
const WDA_EXCLUDEFROMCAPTURE = 0x00000011;

// -----------------------------------------------------------------------------
// Bitmap compression constants
// -----------------------------------------------------------------------------

/// An uncompressed format.
const BI_RGB = 0;

/// A run-length encoded (RLE) format for bitmaps with 8 bpp. The compression
/// format is a two-byte format consisting of a count byte followed by a byte
/// containing a color index. If bV5Compression is BI_RGB and the bV5BitCount
/// member is 16, 24, or 32, the bitmap array specifies the actual intensities
/// of blue, green, and red rather than using color table indexes.
const BI_RLE8 = 1;

/// An RLE format for bitmaps with 4 bpp. The compression format is a two-byte
/// format consisting of a count byte followed by two word-length color indexes.
const BI_RLE4 = 2;

/// Specifies that the bitmap is not compressed and that the color masks for the
/// red, green, and blue components of each pixel are specified in the
/// bV5RedMask, bV5GreenMask, and bV5BlueMask members. This is valid when used
/// with 16- and 32-bpp bitmaps.
const BI_BITFIELDS = 3;

/// Specifies that the image is compressed using the JPEG file Interchange
/// Format. JPEG compression trades off compression against loss; it can achieve
/// a compression ratio of 20:1 with little noticeable loss.
const BI_JPEG = 4;

/// Specifies that the image is compressed using the PNG file Interchange
/// Format.
const BI_PNG = 5;

// -----------------------------------------------------------------------------
// Color Common Dialog constants
// -----------------------------------------------------------------------------

/// Causes the dialog box to use the color specified in the rgbResult member as
/// the initial color selection.
const CC_RGBINIT = 0x00000001;

/// Causes the dialog box to display the additional controls that allow the user
/// to create custom colors. If this flag is not set, the user must click the
/// Define Custom Color button to display the custom color controls.
const CC_FULLOPEN = 0x00000002;

/// Disables the Define Custom Color button.
const CC_PREVENTFULLOPEN = 0x00000004;

/// Causes the dialog box to display the Help button. The hwndOwner member must
/// specify the window to receive the HELPMSGSTRING registered messages that the
/// dialog box sends when the user clicks the Help button.
const CC_SHOWHELP = 0x00000008;

/// Enables the hook procedure specified in the lpfnHook member of this
/// structure. This flag is used only to initialize the dialog box.
const CC_ENABLEHOOK = 0x00000010;

/// The hInstance and lpTemplateName members specify a dialog box template to
/// use in place of the default template. This flag is used only to initialize
/// the dialog box.
const CC_ENABLETEMPLATE = 0x00000020;

/// The hInstance member identifies a data block that contains a preloaded
/// dialog box template. The system ignores the lpTemplateName member if this
/// flag is specified. This flag is used only to initialize the dialog box.
const CC_ENABLETEMPLATEHANDLE = 0x00000040;

/// Causes the dialog box to display only solid colors in the set of basic
/// colors.
const CC_SOLIDCOLOR = 0x00000080;

/// Causes the dialog box to display all available colors in the set of basic
/// colors.
const CC_ANYCOLOR = 0x00000100;

// -----------------------------------------------------------------------------
// Font Common Dialog constants
// -----------------------------------------------------------------------------

/// This flag is ignored for font enumeration. In Windows Vista or below, it
/// caused the dialog box to list only the screen fonts supported by the system.
const CF_SCREENFONTS = 0x00000001;

/// This flag is ignored for font enumeration. In Windows Vista or below, it
/// caused the dialog box to list only the fonts supported by the printer
/// associated with the device context or information context identified by the
/// hDC member.
const CF_PRINTERFONTS = 0x00000002;

/// This flag is ignored for font enumeration.
const CF_BOTH = CF_SCREENFONTS | CF_PRINTERFONTS;

/// Causes the dialog box to display the Help button. The hwndOwner member must
/// specify the window to receive the HELPMSGSTRING registered messages that the
/// dialog box sends when the user clicks the Help button.
const CF_SHOWHELP = 0x00000004;

/// Enables the hook procedure specified in the lpfnHook member of this
/// structure.
const CF_ENABLEHOOK = 0x00000008;

/// Indicates that the hInstance and lpTemplateName members specify a dialog box
/// template to use in place of the default template.
const CF_ENABLETEMPLATE = 0x00000010;

/// Indicates that the hInstance member identifies a data block that contains a
/// preloaded dialog box template. The system ignores the lpTemplateName member
/// if this flag is specified.
const CF_ENABLETEMPLATEHANDLE = 0x00000020;

/// ChooseFont should use the structure pointed to by the lpLogFont member to
/// initialize the dialog box controls.
const CF_INITTOLOGFONTSTRUCT = 0x00000040;

/// The lpszStyle member is a pointer to a buffer that contains style data that
/// ChooseFont should use to initialize the Font Style combo box. When the user
/// closes the dialog box, ChooseFont copies style data for the user's selection
/// to this buffer.
const CF_USESTYLE = 0x00000080;

/// Causes the dialog box to display the controls that allow the user to specify
/// strikeout, underline, and text color options. If this flag is set, you can
/// use the rgbColors member to specify the initial text color. You can use the
/// lfStrikeOut and lfUnderline members of the structure pointed to by lpLogFont
/// to specify the initial settings of the strikeout and underline check boxes.
/// ChooseFont can use these members to return the user's selections.
const CF_EFFECTS = 0x00000100;

/// Causes the dialog box to display the Apply button. You should provide a hook
/// procedure to process WM_COMMAND messages for the Apply button. The hook
/// procedure can send the WM_CHOOSEFONT_GETLOGFONT message to the dialog box to
/// retrieve the address of the structure that contains the current selections
/// for the font.
const CF_APPLY = 0x00000200;

/// This flag is obsolete.
const CF_ANSIONLY = 0x00000400;

/// ChooseFont should allow selection of fonts for all non-OEM and Symbol
/// character sets, as well as the ANSI character set.
const CF_SCRIPTSONLY = CF_ANSIONLY;

/// ChooseFont should not allow vector font selections.
const CF_NOVECTORFONTS = 0x00000800;

/// Same as the CF_NOVECTORFONTS flag.
const CF_NOOEMFONTS = CF_NOVECTORFONTS;

/// ChooseFont should not display or allow selection of font simulations.
const CF_NOSIMULATIONS = 0x00001000;

/// ChooseFont should select only font sizes within the range specified by the
/// nSizeMin and nSizeMax members.
const CF_LIMITSIZE = 0x00002000;

/// ChooseFont should enumerate and allow selection of only fixed-pitch fonts.
const CF_FIXEDPITCHONLY = 0x00004000;

/// Obsolete. ChooseFont ignores this flag.
const CF_WYSIWYG = 0x00008000;

/// ChooseFont should indicate an error condition if the user attempts to select
/// a font or style that is not listed in the dialog box.
const CF_FORCEFONTEXIST = 0x00010000;

/// Specifies that ChooseFont should allow only the selection of scalable fonts.
/// Scalable fonts include vector fonts, scalable printer fonts, TrueType fonts,
/// and fonts scaled by other technologies.
const CF_SCALABLEONLY = 0x00020000;

/// ChooseFont should only enumerate and allow the selection of TrueType fonts.
const CF_TTONLY = 0x00040000;

/// When using a LOGFONT structure to initialize the dialog box controls, use
/// this flag to prevent the dialog box from displaying an initial selection for
/// the font name combo box. This is useful when there is no single font name
/// that applies to the text selection.
const CF_NOFACESEL = 0x00080000;

/// When using a LOGFONT structure to initialize the dialog box controls, use
/// this flag to prevent the dialog box from displaying an initial selection for
/// the Font Style combo box. This is useful when there is no single font style
/// that applies to the text selection.
const CF_NOSTYLESEL = 0x00100000;

/// When using a structure to initialize the dialog box controls, use this flag
/// to prevent the dialog box from displaying an initial selection for the Font
/// Size combo box. This is useful when there is no single font size that
/// applies to the text selection.
const CF_NOSIZESEL = 0x00200000;

/// When specified on input, only fonts with the character set identified in the
/// lfCharSet member of the LOGFONT structure are displayed. The user will not
/// be allowed to change the character set specified in the Scripts combo box.
const CF_SELECTSCRIPT = 0x00400000;

/// Disables the Script combo box. When this flag is set, the lfCharSet member
/// of the LOGFONT structure is set to DEFAULT_CHARSET when ChooseFont returns.
/// This flag is used only to initialize the dialog box.
const CF_NOSCRIPTSEL = 0x00800000;

/// Causes the Font dialog box to list only horizontally oriented fonts.
const CF_NOVERTFONTS = 0x01000000;

/// ChooseFont should additionally display fonts that are set to Hide in Fonts
/// Control Panel.
const CF_INACTIVEFONTS = 0x02000000;

// -----------------------------------------------------------------------------
// Find / Replace Common Dialog constants
// -----------------------------------------------------------------------------

/// If set, the Down button of the direction radio buttons in a Find dialog box
/// is selected indicating that you should search from the current location to
/// the end of the document. If not set, the Up button is selected so you should
/// search to the beginning of the document. You can set this flag to initialize
/// the dialog box. If set in a FINDMSGSTRING message, indicates the user's
/// selection.
const FR_DOWN = 0x00000001;

/// If set, the Match Whole Word Only check box is selected indicating that you
/// should search only for whole words that match the search string. If not set,
/// the check box is unselected so you should also search for word fragments
/// that match the search string. You can set this flag to initialize the dialog
/// box. If set in a FINDMSGSTRING message, indicates the user's selection.
const FR_WHOLEWORD = 0x00000002;

/// If set, the Match Case check box is selected indicating that the search
/// should be case-sensitive. If not set, the check box is unselected so the
/// search should be case-insensitive. You can set this flag to initialize the
/// dialog box. If set in a FINDMSGSTRING message, indicates the user's
/// selection.
const FR_MATCHCASE = 0x00000004;

/// If set in a FINDMSGSTRING message, indicates that the user clicked the Find
/// Next button in a Find or Replace dialog box. The lpstrFindWhat member
/// specifies the string to search for.
const FR_FINDNEXT = 0x00000008;

/// If set in a FINDMSGSTRING message, indicates that the user clicked the
/// Replace button in a Replace dialog box. The lpstrFindWhat member specifies
/// the string to be replaced and the lpstrReplaceWith member specifies the
/// replacement string.
const FR_REPLACE = 0x00000010;

/// If set in a FINDMSGSTRING message, indicates that the user clicked the
/// Replace All button in a Replace dialog box. The lpstrFindWhat member
/// specifies the string to be replaced and the lpstrReplaceWith member
/// specifies the replacement string.
const FR_REPLACEALL = 0x00000020;

/// If set in a FINDMSGSTRING message, indicates that the dialog box is closing.
/// When you receive a message with this flag set, the dialog box handle
/// returned by the FindText or ReplaceText function is no longer valid.
const FR_DIALOGTERM = 0x00000040;

/// Causes the dialog box to display the Help button. The hwndOwner member must
/// specify the window to receive the HELPMSGSTRING registered messages that the
/// dialog box sends when the user clicks the Help button.
const FR_SHOWHELP = 0x00000080;

/// Enables the hook function specified in the lpfnHook member. This flag is
/// used only to initialize the dialog box.
const FR_ENABLEHOOK = 0x00000100;

/// Indicates that the hInstance and lpTemplateName members specify a dialog box
/// template to use in place of the default template. This flag is used only to
/// initialize the dialog box.
const FR_ENABLETEMPLATE = 0x00000200;

/// If set when initializing a Find dialog box, disables the search direction
/// radio buttons.
const FR_NOUPDOWN = 0x00000400;

/// If set when initializing a Find or Replace dialog box, disables the Match
/// Case check box.
const FR_NOMATCHCASE = 0x00000800;

/// If set when initializing a Find or Replace dialog box, disables the Whole
/// Word check box.
const FR_NOWHOLEWORD = 0x00001000;

/// Indicates that the hInstance member identifies a data block that contains a
/// preloaded dialog box template. The system ignores the lpTemplateName member
/// if this flag is specified.
const FR_ENABLETEMPLATEHANDLE = 0x00002000;

/// If set when initializing a Find dialog box, hides the search direction radio
/// buttons.
const FR_HIDEUPDOWN = 0x00004000;

/// If set when initializing a Find or Replace dialog box, hides the Match Case
/// check box.
const FR_HIDEMATCHCASE = 0x00008000;

/// If set when initializing a Find or Replace dialog box, hides the Match Whole
/// Word Only check box.
const FR_HIDEWHOLEWORD = 0x00010000;

/// If set, the search operation considers Arabic and Hebrew diacritical marks.
/// If not set, diacritical marks are ignored.
const FR_MATCHDIAC = 0x20000000;

/// If set, the search operation considers Arabic and Hebrew kashidas. If not
/// set, kashidas are ignored.
const FR_MATCHKASHIDA = 0x40000000;

/// If set, the search differentiates between Arabic and Hebrew alefs with
/// different accents. If not set, all alefs are matched by the alef character
/// alone.
const FR_MATCHALEFHAMZA = 0x80000000;

// -----------------------------------------------------------------------------
// Open File Common Dialog constants
// -----------------------------------------------------------------------------

/// Causes the Read Only check box to be selected initially when the dialog box
/// is created. This flag indicates the state of the Read Only check box when
/// the dialog box is closed.
const OFN_READONLY = 0x00000001;

/// Causes the Save As dialog box to generate a message box if the selected file
/// already exists. The user must confirm whether to overwrite the file.
const OFN_OVERWRITEPROMPT = 0x00000002;

/// Hides the Read Only check box.
const OFN_HIDEREADONLY = 0x00000004;

/// Restores the current directory to its original value if the user changed the
/// directory while searching for files.
const OFN_NOCHANGEDIR = 0x00000008;

/// Causes the dialog box to display the Help button. The hwndOwner member must
/// specify the window to receive the HELPMSGSTRING registered messages that the
/// dialog box sends when the user clicks the Help button. An Explorer-style
/// dialog box sends a CDN_HELP notification message to your hook procedure when
/// the user clicks the Help button.
const OFN_SHOWHELP = 0x00000010;

/// Enables the hook function specified in the lpfnHook member.
const OFN_ENABLEHOOK = 0x00000020;

/// The lpTemplateName member is a pointer to the name of a dialog template
/// resource in the module identified by the hInstance member. If the
/// OFN_EXPLORER flag is set, the system uses the specified template to create a
/// dialog box that is a child of the default Explorer-style dialog box. If the
/// OFN_EXPLORER flag is not set, the system uses the template to create an
/// old-style dialog box that replaces the default dialog box.
const OFN_ENABLETEMPLATE = 0x00000040;

/// The hInstance member identifies a data block that contains a preloaded
/// dialog box template. The system ignores lpTemplateName if this flag is
/// specified. If the OFN_EXPLORER flag is set, the system uses the specified
/// template to create a dialog box that is a child of the default
/// Explorer-style dialog box. If the OFN_EXPLORER flag is not set, the system
/// uses the template to create an old-style dialog box that replaces the
/// default dialog box.
const OFN_ENABLETEMPLATEHANDLE = 0x00000080;

/// The common dialog boxes allow invalid characters in the returned file name.
/// Typically, the calling application uses a hook procedure that checks the
/// file name by using the FILEOKSTRING message. If the text box in the edit
/// control is empty or contains nothing but spaces, the lists of files and
/// directories are updated. If the text box in the edit control contains
/// anything else, nFileOffset and nFileExtension are set to values generated by
/// parsing the text. No default extension is added to the text, nor is text
/// copied to the buffer specified by lpstrFileTitle. If the value specified by
/// nFileOffset is less than zero, the file name is invalid. Otherwise, the file
/// name is valid, and nFileExtension and nFileOffset can be used as if the
/// OFN_NOVALIDATE flag had not been specified.
const OFN_NOVALIDATE = 0x00000100;

/// The File Name list box allows multiple selections. If you also set the
/// OFN_EXPLORER flag, the dialog box uses the Explorer-style user interface;
/// otherwise, it uses the old-style user interface.
const OFN_ALLOWMULTISELECT = 0x00000200;

/// The user typed a file name extension that differs from the extension
/// specified by lpstrDefExt. The function does not use this flag if lpstrDefExt
/// is NULL.
const OFN_EXTENSIONDIFFERENT = 0x00000400;

/// The user can type only valid paths and file names. If this flag is used and
/// the user types an invalid path and file name in the File Name entry field,
/// the dialog box function displays a warning in a message box.
const OFN_PATHMUSTEXIST = 0x00000800;

/// The user can type only names of existing files in the File Name entry field.
/// If this flag is specified and the user enters an invalid name, the dialog
/// box procedure displays a warning in a message box. If this flag is
/// specified, the OFN_PATHMUSTEXIST flag is also used. This flag can be used in
/// an Open dialog box. It cannot be used with a Save As dialog box.
const OFN_FILEMUSTEXIST = 0x00001000;

/// If the user specifies a file that does not exist, this flag causes the
/// dialog box to prompt the user for permission to create the file. If the user
/// chooses to create the file, the dialog box closes and the function returns
/// the specified name; otherwise, the dialog box remains open. If you use this
/// flag with the OFN_ALLOWMULTISELECT flag, the dialog box allows the user to
/// specify only one nonexistent file.
const OFN_CREATEPROMPT = 0x00002000;

/// Specifies that if a call to the OpenFile function fails because of a network
/// sharing violation, the error is ignored and the dialog box returns the
/// selected file name. If this flag is not set, the dialog box notifies your
/// hook procedure when a network sharing violation occurs for the file name
/// specified by the user. If you set the OFN_EXPLORER flag, the dialog box
/// sends the CDN_SHAREVIOLATION message to the hook procedure. If you do not
/// set OFN_EXPLORER, the dialog box sends the SHAREVISTRING registered message
/// to the hook procedure.
const OFN_SHAREAWARE = 0x00004000;

/// The returned file does not have the Read Only check box selected and is not
/// in a write-protected directory.
const OFN_NOREADONLYRETURN = 0x00008000;

/// The file is not created before the dialog box is closed. This flag should be
/// specified if the application saves the file on a create-nonmodify network
/// share. When an application specifies this flag, the library does not check
/// for write protection, a full disk, an open drive door, or network
/// protection. Applications using this flag must perform file operations
/// carefully, because a file cannot be reopened once it is closed.
const OFN_NOTESTFILECREATE = 0x00010000;

/// Hides and disables the Network button.
const OFN_NONETWORKBUTTON = 0x00020000;

/// For old-style dialog boxes, this flag causes the dialog box to use short
/// file names (8.3 format). Explorer-style dialog boxes ignore this flag and
/// always display long file names.
const OFN_NOLONGNAMES = 0x00040000;

/// Indicates that any customizations made to the Open or Save As dialog box use
/// the Explorer-style customization methods.
const OFN_EXPLORER = 0x00080000;

/// Directs the dialog box to return the path and file name of the selected
/// shortcut (.LNK) file. If this value is not specified, the dialog box returns
/// the path and file name of the file referenced by the shortcut.
const OFN_NODEREFERENCELINKS = 0x00100000;

/// For old-style dialog boxes, this flag causes the dialog box to use long file
/// names. If this flag is not specified, or if the OFN_ALLOWMULTISELECT flag is
/// also set, old-style dialog boxes use short file names (8.3 format) for file
/// names with spaces. Explorer-style dialog boxes ignore this flag and always
/// display long file names.
const OFN_LONGNAMES = 0x00200000;

/// Causes the dialog box to send CDN_INCLUDEITEM notification messages to your
/// OFNHookProc hook procedure when the user opens a folder. The dialog box
/// sends a notification for each item in the newly opened folder. These
/// messages enable you to control which items the dialog box displays in the
/// folder's item list.
const OFN_ENABLEINCLUDENOTIFY = 0x00400000;

/// Enables the Explorer-style dialog box to be resized using either the mouse
/// or the keyboard. By default, the Explorer-style Open and Save As dialog
/// boxes allow the dialog box to be resized regardless of whether this flag is
/// set. This flag is necessary only if you provide a hook procedure or custom
/// template. The old-style dialog box does not permit resizing.
const OFN_ENABLESIZING = 0x00800000;

/// Prevents the system from adding a link to the selected file in the file
/// system directory that contains the user's most recently used documents. To
/// retrieve the location of this directory, call the SHGetSpecialFolderLocation
/// function with the CSIDL_RECENT flag.
const OFN_DONTADDTORECENT = 0x02000000;

/// Forces the showing of system and hidden files, thus overriding the user
/// setting to show or not show hidden files. However, a file that is marked
/// both system and hidden is not shown.
const OFN_FORCESHOWHIDDEN = 0x10000000;

/// If this flag is set, the places bar is not displayed. If this flag is not
/// set, Explorer-style dialog boxes include a places bar containing icons for
/// commonly-used folders, such as Favorites and Desktop.
const OFN_EX_NOPLACESBAR = 0x00000001;

// -----------------------------------------------------------------------------
// Visual theming constants
// -----------------------------------------------------------------------------

/// The font used by window captions.
const TMT_CAPTIONFONT = 801;

/// The font used by window small captions.
const TMT_SMALLCAPTIONFONT = 802;

/// The font used by menus.
const TMT_MENUFONT = 803;

/// The font used in status messages.
const TMT_STATUSFONT = 804;

/// The font used to display messages in a message box.
const TMT_MSGBOXFONT = 805;

/// The font used for icons.
const TMT_ICONTITLEFONT = 806;

// -----------------------------------------------------------------------------
// DTTOPS flags
// -----------------------------------------------------------------------------

/// The crText member value is valid.
const DTT_TEXTCOLOR = 1 << 0;

/// The crBorder member value is valid.
const DTT_BORDERCOLOR = 1 << 1;

/// The crShadow member value is valid.
const DTT_SHADOWCOLOR = 1 << 2;

/// The iTextShadowType member value is valid.
const DTT_SHADOWTYPE = 1 << 3;

/// The ptShadowOffset member value is valid.
const DTT_SHADOWOFFSET = 1 << 4;

/// The iBorderSize member value is valid.
const DTT_BORDERSIZE = 1 << 5;

/// The iFontPropId member value is valid.
const DTT_FONTPROP = 1 << 6;

/// The iColorPropId member value is valid.
const DTT_COLORPROP = 1 << 7;

/// The iStateId member value is valid.
const DTT_STATEID = 1 << 8;

/// The pRect parameter of the DrawThemeTextEx function that uses this structure
/// will be used as both an in and an out parameter. After the function returns,
/// the pRect parameter will contain the rectangle that corresponds to the
/// region calculated to be drawn.
const DTT_CALCRECT = 1 << 9;

/// The fApplyOverlay member value is valid.
const DTT_APPLYOVERLAY = 1 << 10;

/// The iGlowSize member value is valid.
const DTT_GLOWSIZE = 1 << 11;

/// The pfnDrawTextCallback member value is valid.
const DTT_CALLBACK = 1 << 12;

/// Draws text with antialiased alpha. Use of this flag requires a top-down DIB
/// section. This flag works only if the HDC passed to function DrawThemeTextEx
/// has a top-down DIB section currently selected in it.
const DTT_COMPOSITED = 1 << 13;

/// All valid bits
const DTT_VALIDBITS = DTT_TEXTCOLOR |
    DTT_BORDERCOLOR |
    DTT_SHADOWCOLOR |
    DTT_SHADOWTYPE |
    DTT_SHADOWOFFSET |
    DTT_BORDERSIZE |
    DTT_FONTPROP |
    DTT_COLORPROP |
    DTT_STATEID |
    DTT_CALCRECT |
    DTT_APPLYOVERLAY |
    DTT_GLOWSIZE |
    DTT_COMPOSITED;

// -----------------------------------------------------------------------------
// High DPI constants & enumerations
// -----------------------------------------------------------------------------

/// Describes per-monitor DPI scaling behavior overrides for child windows
/// within dialogs. The values in this enumeration are bitfields and can be
/// combined.
///
/// {@category Enum}
class DIALOG_CONTROL_DPI_CHANGE_BEHAVIORS {
  /// The default behavior of the dialog manager. The dialog managed will update
  /// the font, size, and position of the child window on DPI changes.
  static const DCDC_DEFAULT = 0x0000;

  /// Prevents the dialog manager from sending an updated font to the child
  /// window via WM_SETFONT in response to a DPI change.
  static const DCDC_DISABLE_FONT_UPDATE = 0x0001;

  /// Prevents the dialog manager from resizing and repositioning the child
  /// window in response to a DPI change.
  static const DCDC_DISABLE_RELAYOUT = 0x0002;
}

/// In Per Monitor v2 contexts, dialogs will automatically respond to DPI
/// changes by resizing themselves and re-computing the positions of their child
/// windows (here referred to as re-layouting). This enum works in conjunction
/// with SetDialogDpiChangeBehavior in order to override the default DPI scaling
/// behavior for dialogs.
///
/// {@category Enum}
class DIALOG_DPI_CHANGE_BEHAVIORS {
  /// The default behavior of the dialog manager. In response to a DPI change,
  /// the dialog manager will re-layout each control, update the font on each
  /// control, resize the dialog, and update the dialog's own font.
  static const DDC_DEFAULT = 0x0000;

  /// Prevents the dialog manager from responding to WM_GETDPISCALEDSIZE and
  /// WM_DPICHANGED, disabling all default DPI scaling behavior.
  static const DDC_DISABLE_ALL = 0x0001;

  /// Prevents the dialog manager from resizing the dialog in response to a DPI
  /// change.
  static const DDC_DISABLE_RESIZE = 0x0002;

  /// Prevents the dialog manager from re-layouting all of the dialogue's
  /// immediate children HWNDs in response to a DPI change.
  static const DDC_DISABLE_CONTROL_RELAYOUT = 0x0004;
}

// -----------------------------------------------------------------------------
/// Bluetooth constants & enumerations
// -----------------------------------------------------------------------------

/// The BLUETOOTH_AUTHENTICATION_METHOD enumeration defines the supported
/// authentication types during device pairing.
///
/// {@category Enum}
class BLUETOOTH_AUTHENTICATION_METHOD {
  static const BLUETOOTH_AUTHENTICATION_METHOD_LEGACY = 0;
  static const BLUETOOTH_AUTHENTICATION_METHOD_OOB = 1;
  static const BLUETOOTH_AUTHENTICATION_METHOD_NUMERIC_COMPARISON = 2;
  static const BLUETOOTH_AUTHENTICATION_METHOD_PASSKEY_NOTIFICATION = 3;
  static const BLUETOOTH_AUTHENTICATION_METHOD_PASSKEY = 4;
}

/// The BLUETOOTH_AUTHENTICATION_REQUIREMENTS enumeration specifies the 'Man in
/// the Middle' protection required for authentication.
///
/// {@category Enum}
class BLUETOOTH_AUTHENTICATION_REQUIREMENTS {
  static const BLUETOOTH_MITM_ProtectionNotRequired = 0;
  static const BLUETOOTH_MITM_ProtectionRequired = 1;
  static const BLUETOOTH_MITM_ProtectionNotRequiredBonding = 2;
  static const BLUETOOTH_MITM_ProtectionRequiredBonding = 3;
  static const BLUETOOTH_MITM_ProtectionNotRequiredGeneralBonding = 4;
  static const BLUETOOTH_MITM_ProtectionRequiredGeneralBonding = 5;
  static const BLUETOOTH_MITM_ProtectionNotDefined = 6;
}

/// The BLUETOOTH_IO_CAPABILITY enumeration defines the input/output
/// capabilities of a Bluetooth Device.
///
/// {@category Enum}
class BLUETOOTH_IO_CAPABILITY {
  static const BLUETOOTH_IO_CAPABILITY_DISPLAYONLY = 0;
  static const BLUETOOTH_IO_CAPABILITY_DISPLAYYESNO = 1;
  static const BLUETOOTH_IO_CAPABILITY_KEYBOARDONLY = 2;
  static const BLUETOOTH_IO_CAPABILITY_NOINPUTNOOUTPUT = 3;
  static const BLUETOOTH_IO_CAPABILITY_UNDEFINED = 4;
}

// -----------------------------------------------------------------------------
/// Common dialog constants & enumerations
// -----------------------------------------------------------------------------

/// Defines the set of options available to an Open or Save dialog.
///
/// {@category Enum}
class FILEOPENDIALOGOPTIONS {
  static const FOS_OVERWRITEPROMPT = 0x2;
  static const FOS_STRICTFILETYPES = 0x4;
  static const FOS_NOCHANGEDIR = 0x8;
  static const FOS_PICKFOLDERS = 0x20;
  static const FOS_FORCEFILESYSTEM = 0x40;
  static const FOS_ALLNONSTORAGEITEMS = 0x80;
  static const FOS_NOVALIDATE = 0x100;
  static const FOS_ALLOWMULTISELECT = 0x200;
  static const FOS_PATHMUSTEXIST = 0x800;
  static const FOS_FILEMUSTEXIST = 0x1000;
  static const FOS_CREATEPROMPT = 0x2000;
  static const FOS_SHAREAWARE = 0x4000;
  static const FOS_NOREADONLYRETURN = 0x8000;
  static const FOS_NOTESTFILECREATE = 0x10000;
  static const FOS_HIDEMRUPLACES = 0x20000;
  static const FOS_HIDEPINNEDPLACES = 0x40000;
  static const FOS_NODEREFERENCELINKS = 0x100000;
  static const FOS_OKBUTTONNEEDSINTERACTION = 0x200000;
  static const FOS_DONTADDTORECENT = 0x2000000;
  static const FOS_FORCESHOWHIDDEN = 0x10000000;
  static const FOS_DEFAULTNOMINIMODE = 0x20000000;
  static const FOS_FORCEPREVIEWPANEON = 0x40000000;
  static const FOS_SUPPORTSTREAMABLEITEMS = 0x80000000;
}

// -----------------------------------------------------------------------------
// Desktop shell constants & enumerations
// -----------------------------------------------------------------------------

/// Desktop wallpaper slideshow settings for shuffling images.
///
/// {@category Enum}
class DESKTOP_SLIDESHOW_OPTIONS {
  /// Shuffle is enabled; the images are shown in a random order.
  static const DSO_SHUFFLEIMAGES = 0x1;
}

/// Gets the current status of the slideshow.
///
/// {@category Enum}
class DESKTOP_SLIDESHOW_STATE {
  /// Slideshows are enabled.
  static const DSS_ENABLED = 0x1;

  /// A slideshow is currently configured.
  static const DSS_SLIDESHOW = 0x2;

  /// A remote session has temporarily disabled the slideshow.
  static const DSS_DISABLED_BY_REMOTE_SESSION = 0x4;
}

/// The direction that the slideshow should advance.
///
/// {@category Enum}
class DESKTOP_SLIDESHOW_DIRECTION {
  /// Advance the slideshow forward.
  static const DSD_FORWARD = 0;

  /// Advance the slideshow backward.
  static const DSD_BACKWARD = 1;
}

/// Specifies how the desktop wallpaper should be displayed.
///
/// {@category Enum}
class DESKTOP_WALLPAPER_POSITION {
  /// Center the image; do not stretch.
  static const DWPOS_CENTER = 0;

  /// Tile the image across all monitors.
  static const DWPOS_TILE = 1;

  /// Stretch the image to exactly fit on the monitor.
  static const DWPOS_STRETCH = 2;

  /// Stretch the image to exactly the height or width of the monitor without
  /// changing its aspect ratio or cropping the image.
  static const DWPOS_FIT = 3;

  /// Stretch the image to fill the screen, cropping the image as necessary to
  /// avoid letterbox bars.
  static const DWPOS_FILL = 4;

  /// Spans a single image across all monitors attached to the system.
  static const DWPOS_SPAN = 5;
}

// -----------------------------------------------------------------------------
// PlaySound constants
// -----------------------------------------------------------------------------

/// play synchronously (default)
const SND_SYNC = 0x0000;

/// play asynchronously
const SND_ASYNC = 0x0001;

/// silence (!default) if sound not found
const SND_NODEFAULT = 0x0002;

/// pszSound points to a memory file
const SND_MEMORY = 0x0004;

/// loop the sound until next sndPlaySound
const SND_LOOP = 0x0008;

/// don't stop any currently playing sound
const SND_NOSTOP = 0x0010;

/// don't wait if the driver is busy
const SND_NOWAIT = 0x00002000;

/// name is a registry alias
const SND_ALIAS = 0x00010000;

/// alias is a predefined ID
const SND_ALIAS_ID = 0x00110000;

/// name is file name
const SND_FILENAME = 0x00020000;

/// name is resource name or atom
const SND_RESOURCE = 0x00040004;

/// purge non-static events for task
const SND_PURGE = 0x0040;

/// look for application specific association
const SND_APPLICATION = 0x0080;

/// Generate a SoundSentry event with this sound
const SND_SENTRY = 0x00080000;

/// Treat this as a "ring" from a communications app - don't duck me
const SND_RING = 0x00100000;

/// Treat this as a system sound
const SND_SYSTEM = 0x00200000;

// -----------------------------------------------------------------------------
// PurgeComm() flags
// -----------------------------------------------------------------------------

/// Terminates all outstanding overlapped write operations and returns
/// immediately, even if the write operations have not been completed.
const PURGE_TXABORT = 0x0001;

/// Terminates all outstanding overlapped read operations and returns
/// immediately, even if the read operations have not been completed.
const PURGE_RXABORT = 0x0002;

/// Clears the output buffer (if the device driver has one).
const PURGE_TXCLEAR = 0x0004;

/// Clears the input buffer (if the device driver has one).
const PURGE_RXCLEAR = 0x0008;

// -----------------------------------------------------------------------------
// Shutdown constants
// -----------------------------------------------------------------------------

/// All sessions are forcefully logged off. If this flag is not set and users
/// other than the current user are logged on to the computer specified by the
/// lpMachineName parameter, this function fails with a return value of
/// ERROR_SHUTDOWN_USERS_LOGGED_ON.
const SHUTDOWN_FORCE_OTHERS = 0x0000001;

/// Specifies that the originating session is logged off forcefully. If this
/// flag is not set, the originating session is shut down interactively, so a
/// shutdown is not guaranteed even if the function returns successfully.
const SHUTDOWN_FORCE_SELF = 0x0000002;

/// The computer is shut down and rebooted.
const SHUTDOWN_RESTART = 0x0000004;

/// The computer is shut down and powered down.
const SHUTDOWN_POWEROFF = 0x0000008;

/// The computer is shut down but is not powered down or rebooted.
const SHUTDOWN_NOREBOOT = 0x0000010;

/// Overrides the grace period so that the computer is shut down immediately.
const SHUTDOWN_GRACE_OVERRIDE = 0x0000020;

/// The computer installs any updates before starting the shutdown.
const SHUTDOWN_INSTALL_UPDATES = 0x0000040;

/// The system is rebooted using the ExitWindowsEx function with the
/// EWX_RESTARTAPPS flag. This restarts any applications that have been
/// registered for restart using the RegisterApplicationRestart function.
const SHUTDOWN_RESTARTAPPS = 0x0000080;

/// Beginning with InitiateShutdown running on Windows 8, you must include the
/// SHUTDOWN_HYBRID flag with one or more of the flags in this table to specify
/// options for the shutdown.
const SHUTDOWN_HYBRID = 0x0000200;

// -----------------------------------------------------------------------------
// Shell_NotifyIcon uFlags constants
// -----------------------------------------------------------------------------

/// Adds an icon to the status area. The icon is given an identifier in the
/// NOTIFYICONDATA structure pointed to by lpdata—either through its uID or
/// guidItem member. This identifier is used in subsequent calls to
/// Shell_NotifyIcon to perform later actions on the icon.
const NIM_ADD = 0x00000000;

/// Modifies an icon in the status area. NOTIFYICONDATA structure pointed to by
/// lpdata uses the ID originally assigned to the icon when it was added to the
/// notification area (NIM_ADD) to identify the icon to be modified.
const NIM_MODIFY = 0x00000001;

/// Deletes an icon from the status area. NOTIFYICONDATA structure
/// pointed to by lpdata uses the ID originally assigned to the icon when it was
/// added to the notification area (NIM_ADD) to identify the icon to be deleted.
const NIM_DELETE = 0x00000002;

/// Shell32.dll version 5.0 and later only. Returns focus to the
/// taskbar notification area. Notification area icons should use this message
/// when they have completed their UI operation. For example, if the icon
/// displays a shortcut menu, but the user presses ESC to cancel it, use
/// NIM_SETFOCUS to return focus to the notification area.
const NIM_SETFOCUS = 0x00000003;

/// Shell32.dll version 5.0 and later only. Instructs the notification area to
/// behave according to the version number specified in the uVersion member of
/// the structure pointed to by lpdata. The version number specifies which
/// members are recognized. NIM_SETVERSION must be called every time a
/// notification area icon is added (NIM_ADD)>. It does not need to be called
/// with NIM_MOFIDY. The version setting is not persisted once a user logs off.
const NIM_SETVERSION = 0x00000004;

// -----------------------------------------------------------------------------
// NOTIFYICONDATA::uVersion constants
// Flags that either indicate which of the other members of the structure
// contain valid data or provide additional information to the tooltip as to
// how it should display. This member can be a combination of the following
// values:
// -----------------------------------------------------------------------------
const NOTIFYICON_VERSION = 3;
const NOTIFYICON_VERSION_4 = 4;

// -----------------------------------------------------------------------------
// NOTIFYICONDATA::uFlags constants
// -----------------------------------------------------------------------------

/// The uCallbackMessage member is valid.
const NIF_MESSAGE = 0x00000001;

/// The hIcon member is valid.
const NIF_ICON = 0x00000002;

/// The szTip member is valid.
const NIF_TIP = 0x00000004;

/// The dwState and dwStateMask members are valid.
const NIF_STATE = 0x00000008;

/// To display the balloon notification, specify NIF_INFO and provide
/// text in szInfo.
/// To remove a balloon notification, specify NIF_INFO and provide an empty
/// string through szInfo.
/// To add a notification area icon without displaying a notification,
/// do not set the NIF_INFO flag.
const NIF_INFO = 0x00000010;

/// Windows 7 and later: The guidItem is valid.
/// Windows Vista and earlier: Reserved.
const NIF_GUID = 0x00000020;

/// Windows Vista and later. If the balloon notification cannot be displayed
/// immediately, discard it. Use this flag for notifications that represent
/// real-time information which would be meaningless or misleading if displayed
/// at a later time. For example, a message that states
/// "Your telephone is ringing." NIF_REALTIME is meaningful only when combined
/// with the NIF_INFO flag.
const NIF_REALTIME = 0x00000040;

/// Windows Vista and later. Use the standard tooltip. Normally, when uVersion
/// is set to NOTIFYICON_VERSION_4, the standard tooltip is suppressed and
/// can be replaced by the application-drawn, pop-up UI. If the application
/// wants to show the standard tooltip with NOTIFYICON_VERSION_4, it can
/// specify NIF_SHOWTIP to indicate the standard tooltip should still be shown.
const NIF_SHOWTIP = 0x00000080;

// -----------------------------------------------------------------------------
// NOTIFYICONDATA::dwState constants
// The state of the icon. One or both of the following values.
// -----------------------------------------------------------------------------

/// The icon is hidden.
const NIS_HIDDEN = 0x00000001;

/// The icon resource is shared between multiple icons.
const NIS_SHAREDICON = 0x00000002;

// -----------------------------------------------------------------------------
// NOTIFYICONDATA::dwInfoFlags constants
// Flags that can be set to modify the behavior and appearance of a balloon
// notification. The icon is placed to the left of the title. If the szInfoTitle
// member is zero-length, the icon is not shown.
// -----------------------------------------------------------------------------

/// No icon.
const NIIF_NONE = 0x00000000;

/// An information icon.
const NIIF_INFO = 0x00000001;

/// A warning icon.
const NIIF_WARNING = 0x00000002;

/// An error icon.
const NIIF_ERROR = 0x00000003;

/// Windows Vista and later: Use the icon identified in hBalloonIcon as the
/// notification balloon's title icon.
const NIIF_USER = 0x00000004;

/// Windows XP and later. Reserved.
const NIIF_ICON_MASK = 0x0000000F;

/// Do not play the associated sound. Applies only to notifications.
const NIIF_NOSOUND = 0x00000010;

/// The large version of the icon should be used as the notification icon
const NIIF_LARGE_ICON = 0x00000020;

/// Do not display the balloon notification if the curr user is in "quiet time"
const NIIF_RESPECT_QUIET_TIME = 0x00000080;

/// Used to define private messages, usually of the form WM_APP+x, where x
/// is an integer value.
const WM_APP = 0x8000;

// -----------------------------------------------------------------------------
// Shell_NotifyIcon WndProc callback message contants
// -----------------------------------------------------------------------------

/// If a user selects a notify icon with the mouse and activates it with the
/// ENTER key, the Shell now sends the associated application an NIN_SELECT
/// notification. Earlier versions send WM_RBUTTONDOWN and WM_RBUTTONUP
/// messages.
const NIN_SELECT = WM_USER + 0;

const NINF_KEY = 0x1;

/// If a user selects a notify icon with the keyboard and activates it with
/// the SPACEBAR or ENTER key, the version 5.0 Shell sends the associated
/// application an NIN_KEYSELECT notification. Earlier versions send
/// WM_RBUTTONDOWN and WM_RBUTTONUP messages.
const NIN_KEYSELECT = NIN_SELECT | NINF_KEY;

/// Sent when the balloon is shown (balloons are queued).
const NIN_BALLOONSHOW = WM_USER + 2;

/// Sent when the balloon disappears. For example, when the icon is deleted.
/// This message is not sent if the balloon is dismissed because of a timeout or
/// if the user clicks the mouse.
/// As of Windows 7, NIN_BALLOONHIDE is also sent when a notification with
/// the NIIF_RESPECT_QUIET_TIME flag set attempts to display during quiet time
/// (a user's first hour on a new computer). In that case, the balloon is never
/// displayed at all.
const NIN_BALLOONHIDE = WM_USER + 3;

/// Sent when the balloon is dismissed because of a timeout.
const NIN_BALLOONTIMEOUT = WM_USER + 4;

/// Sent when the balloon is dismissed because the user clicked the mouse.
const NIN_BALLOONUSERCLICK = WM_USER + 5;

/// Sent when the user hovers the cursor over an icon to indicate that the
/// richer pop-up UI should be used in place of a standard textual tooltip.
const NIN_POPUPOPEN = WM_USER + 6;

/// Sent when a cursor no longer hovers over an icon to indicate that the rich
/// pop-up UI should be closed.
const NIN_POPUPCLOSE = WM_USER + 7;

// -----------------------------------------------------------------------------
// Power setting constants
// -----------------------------------------------------------------------------

/// Notifications are sent using WM_POWERBROADCAST messages with a wParam
/// parameter of PBT_POWERSETTINGCHANGE.
const DEVICE_NOTIFY_WINDOW_HANDLE = 0;

/// Notifications are sent to the HandlerEx callback function with a dwControl
/// parameter of SERVICE_CONTROL_POWEREVENT and a dwEventType of
/// PBT_POWERSETTINGCHANGE.
const DEVICE_NOTIFY_SERVICE_HANDLE = 1;

// -----------------------------------------------------------------------------
// TrackPopupMenuEx constants
// -----------------------------------------------------------------------------

/// The user can select menu items with only the left mouse button.
const TPM_LEFTBUTTON = 0x0000;

/// The user can select menu items with both the left and right mouse buttons.
const TPM_RIGHTBUTTON = 0x0002;

/// Positions the shortcut menu so that its left side is aligned with the
/// coordinate specified by the x parameter.
const TPM_LEFTALIGN = 0x0000;

/// Centers the shortcut menu horizontally relative to the coordinate specified
/// by the x parameter.
const TPM_CENTERALIGN = 0x0004;

/// Positions the shortcut menu so that its right side is aligned with the
/// coordinate specified by the x parameter.
const TPM_RIGHTALIGN = 0x0008;

/// Positions the shortcut menu so that its top side is aligned with the
/// coordinate specified by the y parameter.
const TPM_TOPALIGN = 0x0000;

/// Centers the shortcut menu vertically relative to the coordinate specified by
/// the y parameter.
const TPM_VCENTERALIGN = 0x0010;

/// Positions the shortcut menu so that its bottom side is aligned with the
/// coordinate specified by the y parameter.
const TPM_BOTTOMALIGN = 0x0020;

/// If the menu cannot be shown at the specified location without overlapping
/// the excluded rectangle, the system tries to accommodate the requested
/// horizontal alignment before the requested vertical alignment.
const TPM_HORIZONTAL = 0x0000;

/// If the menu cannot be shown at the specified location without overlapping
/// the excluded rectangle, the system tries to accommodate the requested
/// vertical alignment before the requested horizontal alignment.
const TPM_VERTICAL = 0x0040;

/// The function does not send notification messages when the user clicks a menu
/// item.
const TPM_NONOTIFY = 0x0080;

/// The function returns the menu item identifier of the user's selection in the
/// return value.
const TPM_RETURNCMD = 0x0100;

/// Use the TPM_RECURSE flag to display a menu when another menu is already
/// displayed. This is intended to support context menus within a menu.
const TPM_RECURSE = 0x0001;

/// Animates the menu from left to right.
const TPM_HORPOSANIMATION = 0x0400;

/// Animates the menu from right to left.
const TPM_HORNEGANIMATION = 0x0800;

/// Animates the menu from top to bottom.
const TPM_VERPOSANIMATION = 0x1000;

/// Animates the menu from bottom to top.
const TPM_VERNEGANIMATION = 0x2000;

/// Displays menu without animation.
const TPM_NOANIMATION = 0x4000;

/// For right-to-left text layout, use TPM_LAYOUTRTL. By default, the text
/// layout is left-to-right.
const TPM_LAYOUTRTL = 0x8000;

/// Restricts the pop-up window to within the work area.
const TPM_WORKAREA = 0x10000;

// -----------------------------------------------------------------------------
// LoadImage constants
// -----------------------------------------------------------------------------

/// Loads a bitmap.
const IMAGE_BITMAP = 0;

/// Loads an icon.
const IMAGE_ICON = 1;

/// Loads a cursor.
const IMAGE_CURSOR = 2;

/// Loads an enhanced metafile.
const IMAGE_ENHMETAFILE = 3;

// -----------------------------------------------------------------------------
// Stock icons and cursors
// -----------------------------------------------------------------------------

// In the original header files, these take the form:
//   #define IDI_APPLICATION     MAKEINTRESOURCE(32512)
// The MAKEINTRESOURCE() macro creates a pointer to a known memory address. The
// address itself has no meaning other than as a marker.

/// Default application icon.
final IDI_APPLICATION = Pointer<Utf16>.fromAddress(32512);

/// Hand-shaped icon. Same as IDI_ERROR.
final IDI_HAND = Pointer<Utf16>.fromAddress(32513);

/// Question mark icon.
final IDI_QUESTION = Pointer<Utf16>.fromAddress(32514);

/// Exclamation point icon. Same as IDI_WARNING.
final IDI_EXCLAMATION = Pointer<Utf16>.fromAddress(32515);

/// Asterisk icon. Same as IDI_INFORMATION.
final IDI_ASTERISK = Pointer<Utf16>.fromAddress(32516);

/// Windows logo icon.
final IDI_WINLOGO = Pointer<Utf16>.fromAddress(32517);

/// Security Shield icon.
final IDI_SHIELD = Pointer<Utf16>.fromAddress(32518);

/// Exclamation point icon.
final IDI_WARNING = IDI_EXCLAMATION;

/// Hand-shaped icon.
final IDI_ERROR = IDI_HAND;

/// Asterisk icon.
final IDI_INFORMATION = IDI_ASTERISK;

/// Standard arrow
final IDC_ARROW = Pointer<Utf16>.fromAddress(32512);

/// I-beam
final IDC_IBEAM = Pointer<Utf16>.fromAddress(32513);

/// Hourglass
final IDC_WAIT = Pointer<Utf16>.fromAddress(32514);

/// Crosshair
final IDC_CROSS = Pointer<Utf16>.fromAddress(32515);

/// Vertical arrow
final IDC_UPARROW = Pointer<Utf16>.fromAddress(32516);

/// Double-pointed arrow pointing northwest and southeast
final IDC_SIZENWSE = Pointer<Utf16>.fromAddress(32642);

/// Double-pointed arrow pointing northeast and southwest
final IDC_SIZENESW = Pointer<Utf16>.fromAddress(32643);

/// Double-pointed arrow pointing west and east
final IDC_SIZEWE = Pointer<Utf16>.fromAddress(32644);

/// Double-pointed arrow pointing north and south
final IDC_SIZENS = Pointer<Utf16>.fromAddress(32645);

/// Four-pointed arrow pointing north, south, east, and west
final IDC_SIZEALL = Pointer<Utf16>.fromAddress(32646);

/// Slashed circle
final IDC_NO = Pointer<Utf16>.fromAddress(32648);

/// Hand
final IDC_HAND = Pointer<Utf16>.fromAddress(32649);

/// Standard arrow and small hourglass
final IDC_APPSTARTING = Pointer<Utf16>.fromAddress(32650);

/// Arrow and question mark
final IDC_HELP = Pointer<Utf16>.fromAddress(32651);

// -----------------------------------------------------------------------------
// LoadImage fuLoad constants
// -----------------------------------------------------------------------------

/// The default flag; it does nothing.
const LR_DEFAULTCOLOR = 0x00000000;

/// Loads the image in black and white.
const LR_MONOCHROME = 0x00000001;

/// Returns the original hImage if it satisfies the criteria for the copy—that
/// is, correct dimensions and color depth—in which case the LR_COPYDELETEORG
/// flag is ignored. If this flag is not specified, a new object is always
/// created.
const LR_COPYRETURNORG = 0x00000004;

/// Deletes the original image after creating the copy.
const LR_COPYDELETEORG = 0x00000008;

/// Loads the stand-alone image from the file specified by lpszName (icon,
/// cursor, or bitmap file).
const LR_LOADFROMFILE = 0x00000010;

/// Retrieves the color value of the first pixel in the image and replaces the
/// corresponding entry in the color table with the default window color
/// (COLOR_WINDOW). All pixels in the image that use that entry become the
/// default window color. This value applies only to images that have
/// corresponding color tables.
const LR_LOADTRANSPARENT = 0x00000020;

/// Uses the width or height specified by the system metric values for cursors
/// or icons, if the cxDesired or cyDesired values are set to zero.
const LR_DEFAULTSIZE = 0x00000040;

/// Uses true VGA colors.
const LR_VGACOLOR = 0x00000080;

/// Searches the color table for the image and replaces shades of gray with the
/// corresponding 3-D color.
const LR_LOADMAP3DCOLORS = 0x00001000;

/// Causes the function to return a DIB section bitmap rather than a compatible
/// bitmap. This flag is useful for loading a bitmap without mapping it to the
/// colors of the display device.
const LR_CREATEDIBSECTION = 0x00002000;

/// Tries to reload an icon or cursor resource from the original resource file
/// rather than simply copying the current image. This is useful for creating a
/// different-sized copy when the resource file contains multiple sizes of the
/// resource. Without this flag, CopyImage stretches the original image to the
/// new size. If this flag is set, CopyImage uses the size in the resource file
/// closest to the desired size.
const LR_COPYFROMRESOURCE = 0x00004000;

/// Shares the image handle if the image is loaded multiple times. If LR_SHARED
/// is not set, a second call to LoadImage for the same resource will load the
/// image again and return a different handle.
const LR_SHARED = 0x00008000;

// -----------------------------------------------------------------------------
// Windows Runtime constants
// -----------------------------------------------------------------------------

/// Determines the concurrency model used for incoming calls to the objects
/// created by this thread.
///
/// {@category Enum}
class RO_INIT_TYPE {
  static const RO_INIT_SINGLETHREADED = 0;

  /// Initializes the thread for multi-threaded concurrency. The current thread
  /// is initialized in the MTA.
  static const RO_INIT_MULTITHREADED = 1;
}

// -----------------------------------------------------------------------------
// Internationalization for Windows Applications constants
// -----------------------------------------------------------------------------

/// Identifies the type of corrective action to be taken for a spelling error.
///
/// {@category Enum}
class CORRECTIVE_ACTION {
  /// There are no errors.
  static const NONE = 0;

  /// The user should be prompted with a list of suggestions as returned by
  /// ISpellChecker::Suggest.
  static const GET_SUGGESTIONS = 1;

  /// Replace the indicated erroneous text with the text provided in the
  /// suggestion. The user does not need to be prompted.
  static const REPLACE = 2;

  /// The user should be prompted to delete the indicated erroneous text.
  static const DELETE = 3;
}

// -----------------------------------------------------------------------------
// IApplicationActivationManager constants
// -----------------------------------------------------------------------------

/// Flags used to support design mode, debugging, and testing scenarios.
class ACTIVATEOPTIONS {
  /// No flags are set.
  static const AO_NONE = 0;

  /// The app is being activated for design mode, so it can't create its normal
  /// window. The creation of the app's window must be done by design tools that
  /// load the necessary components by communicating with a designer-specified
  /// service on the site chain established through the activation manager. Note
  /// that this means that the splash screen seen during regular activations
  /// won't be seen.
  static const AO_DESIGNMODE = 0x1;

  /// Do not display an error dialog if the app fails to activate.
  static const AO_NOERRORUI = 0x2;

  /// Do not display the app's splash screen when the app is activated. You must
  /// enable debug mode on the app's package when you use this flag; otherwise,
  /// the PLM will terminate the app after a few seconds.
  static const AO_NOSPLASHSCREEN = 0x4;

  /// The application is being activated in prelaunch mode. This value is
  /// supported starting in Windows 10.
  static const AO_PRELAUNCH = 0x2000000;
}

// -----------------------------------------------------------------------------
// Symbol Flag constants
// -----------------------------------------------------------------------------

/// The Value member is used.
const SYMFLAG_VALUEPRESENT = 0x00000001;

/// The symbol is a register. The Register member is used.
const SYMFLAG_REGISTER = 0x00000008;

/// Offsets are register relative.
const SYMFLAG_REGREL = 0x00000010;

/// Offsets are frame relative.
const SYMFLAG_FRAMEREL = 0x00000020;

/// The symbol is a parameter.
const SYMFLAG_PARAMETER = 0x00000040;

/// The symbol is a local variable.
const SYMFLAG_LOCAL = 0x00000080;

/// The symbol is a constant.
const SYMFLAG_CONSTANT = 0x00000100;

/// The symbol is from the export table.
const SYMFLAG_EXPORT = 0x00000200;

/// The symbol is a forwarder.
const SYMFLAG_FORWARDER = 0x00000400;

/// The symbol is a known function.
const SYMFLAG_FUNCTION = 0x00000800;

/// The symbol is a virtual symbol created by the SymAddSymbol function.
const SYMFLAG_VIRTUAL = 0x00001000;

/// The symbol is a thunk.
const SYMFLAG_THUNK = 0x00002000;

/// The symbol is an offset into the TLS data area.
const SYMFLAG_TLSREL = 0x00004000;

/// The symbol is a managed code slot.
const SYMFLAG_SLOT = 0x00008000;

/// The symbol address is an offset relative to the beginning of the
/// intermediate language block. This applies to managed code only.
const SYMFLAG_ILREL = 0x00010000;

/// The symbol is managed metadata.
const SYMFLAG_METADATA = 0x00020000;

/// The symbol is a CLR token.
const SYMFLAG_CLR_TOKEN = 0x00040000;

// -----------------------------------------------------------------------------
// Symbol Option constants
// -----------------------------------------------------------------------------

/// This symbol option causes all searches for symbol names to be
/// case-insensitive.
const SYMOPT_CASE_INSENSITIVE = 0x00000001;

/// This symbol option causes public symbol names to be undecorated when they
/// are displayed, and causes searches for symbol names to ignore symbol
/// decorations. Private symbol names are never decorated, regardless of whether
/// this option is active.
const SYMOPT_UNDNAME = 0x00000002;

/// This symbol option is called deferred symbol loading or lazy symbol loading.
/// When it is active, symbols are not actually loaded when the target modules
/// are loaded. Instead, symbols are loaded by the debugger as they are needed.
const SYMOPT_DEFERRED_LOADS = 0x00000004;

/// This symbol option turns off C++ translation. When this symbol option is
/// set, :: is replaced by __ in all symbols.
const SYMOPT_NO_CPP = 0x00000008;

/// This symbol option allows line number information to be read from source
/// files. This option must be on for source debugging to work correctly.
const SYMOPT_LOAD_LINES = 0x00000010;

/// When code has been optimized and there is no symbol at the expected
/// location, this option causes the nearest symbol to be used instead.
const SYMOPT_OMAP_FIND_NEAREST = 0x00000020;

/// This symbol option reduces the pickiness of the symbol handler when it is
/// attempting to match symbols.
const SYMOPT_LOAD_ANYTHING = 0x00000040;

/// This symbol option causes the symbol handler to ignore the CV record in the
/// loaded image header when searching for symbols.
const SYMOPT_IGNORE_CVREC = 0x00000080;

/// This symbol option disables the symbol handler's automatic loading of
/// modules. When this option is set and the debugger attempts to match a
/// symbol, it will only search modules which have already been loaded.
const SYMOPT_NO_UNQUALIFIED_LOADS = 0x00000100;

/// This symbol option causes file access error dialog boxes to be suppressed.
const SYMOPT_FAIL_CRITICAL_ERRORS = 0x00000200;

/// This symbol option causes the debugger to perform a strict evaluation of all
/// symbol files.
const SYMOPT_EXACT_SYMBOLS = 0x00000400;

/// This symbol option allows DbgHelp to read symbols that are stored at an
/// absolute address in memory. This option is not needed in the vast majority
/// of cases.
const SYMOPT_ALLOW_ABSOLUTE_SYMBOLS = 0x00000800;

/// This symbol option causes the debugger to ignore the environment variable
/// settings for the symbol path and the executable image path.
const SYMOPT_IGNORE_NT_SYMPATH = 0x00001000;

/// When debugging on 64-bit Windows, include any 32-bit modules.
const SYMOPT_INCLUDE_32BIT_MODULES = 0x00002000;

/// This symbol option causes DbgHelp to ignore private symbol data, and search
/// only the public symbol table for symbol information.
const SYMOPT_PUBLICS_ONLY = 0x00004000;

/// This symbol option prevents DbgHelp from searching the public symbol table.
/// This can make symbol enumeration and symbol searches much faster. If you are
/// concerned solely with search speed, the SYMOPT_AUTO_PUBLICS option is
/// generally preferable to this one.
const SYMOPT_NO_PUBLICS = 0x00008000;

/// This symbol option causes DbgHelp to search the public symbol table in a
/// .pdb file only as a last resort. If any matches are found when searching the
/// private symbol data, the public symbols will not be searched. This improves
/// symbol search speed.
const SYMOPT_AUTO_PUBLICS = 0x00010000;

/// This symbol option prevents DbgHelp from searching the disk for a copy of
/// the image when symbols are loaded.
const SYMOPT_NO_IMAGE_SEARCH = 0x00020000;

/// (Kernel mode only) This symbol option indicates whether Secure Mode is
/// active.
const SYMOPT_SECURE = 0x00040000;

/// This symbol option suppresses authentication dialog boxes from the proxy
/// server. This may result in SymSrv being unable to access a symbol store on
/// the internet.
const SYMOPT_NO_PROMPTS = 0x00080000;

/// Overwrite the downlevel store from the symbol store.
const SYMOPT_OVERWRITE = 0x00100000;

/// Ignore the image directory.
const SYMOPT_IGNORE_IMAGEDIR = 0x00200000;

/// Symbols are stored in the root directory of the default downstream store.
const SYMOPT_FLAT_DIRECTORY = 0x00400000;

/// If there is both an uncompressed and a compressed file available, favor the
/// compressed file. This option is good for slow connections.
const SYMOPT_FAVOR_COMPRESSED = 0x00800000;

/// If there is both an uncompressed and a compressed file available, favor the
/// compressed file. This option is good for slow connections.
const SYMOPT_ALLOW_ZERO_ADDRESS = 0x01000000;

/// Disables the auto-detection of symbol server stores in the symbol path, even
/// without the "SRV*" designation, maintaining compatibility with previous
/// behavior.
const SYMOPT_DISABLE_SYMSRV_AUTODETECT = 0x02000000;

/// This symbol option turns on noisy symbol loading. This instructs the
/// debugger to display information about its search for symbols.
const SYMOPT_DEBUG = 0x80000000;

// -----------------------------------------------------------------------------
// DWM constants
// -----------------------------------------------------------------------------

/// Flags used by the DwmGetWindowAttribute and DwmSetWindowAttribute functions
/// to specify window attributes for Desktop Window Manager (DWM) non-client
/// rendering.
class DWMWINDOWATTRIBUTE {
  /// Use with DwmGetWindowAttribute. Discovers whether non-client rendering is
  /// enabled. The retrieved value is of type BOOL. TRUE if non-client rendering
  /// is enabled; otherwise, FALSE.
  static const DWMWA_NCRENDERING_ENABLED = 1;

  /// Use with DwmSetWindowAttribute. Sets the non-client rendering policy. The
  /// pvAttribute parameter points to a value from the DWMNCRENDERINGPOLICY
  /// enumeration.
  static const DWMWA_NCRENDERING_POLICY = 2;

  /// Use with DwmSetWindowAttribute. Enables or forcibly disables DWM
  /// transitions. The pvAttribute parameter points to a value of type BOOL.
  /// TRUE to disable transitions, or FALSE to enable transitions.
  static const DWMWA_TRANSITIONS_FORCEDISABLED = 3;

  /// Use with DwmSetWindowAttribute. Enables content rendered in the non-client
  /// area to be visible on the frame drawn by DWM. The pvAttribute parameter
  /// points to a value of type BOOL. TRUE to enable content rendered in the
  /// non-client area to be visible on the frame; otherwise, FALSE.
  static const DWMWA_ALLOW_NCPAINT = 4;

  /// Use with DwmGetWindowAttribute. Retrieves the bounds of the caption button
  /// area in the window-relative space. The retrieved value is of type RECT. If
  /// the window is minimized or otherwise not visible to the user, then the
  /// value of the RECT retrieved is undefined. You should check whether the
  /// retrieved RECT contains a boundary that you can work with, and if it
  /// doesn't then you can conclude that the window is minimized or otherwise
  /// not visible.
  static const DWMWA_CAPTION_BUTTON_BOUNDS = 5;

  /// Use with DwmSetWindowAttribute. Specifies whether non-client content is
  /// right-to-left (RTL) mirrored. The pvAttribute parameter points to a value
  /// of type BOOL. TRUE if the non-client content is right-to-left (RTL)
  /// mirrored; otherwise, FALSE.
  static const DWMWA_NONCLIENT_RTL_LAYOUT = 6;

  /// Use with DwmSetWindowAttribute. Forces the window to display an iconic
  /// thumbnail or peek representation (a static bitmap), even if a live or
  /// snapshot representation of the window is available. This value is normally
  /// set during a window's creation, and not changed throughout the window's
  /// lifetime. Some scenarios, however, might require the value to change over
  /// time. The pvAttribute parameter points to a value of type BOOL. TRUE to
  /// require a iconic thumbnail or peek representation; otherwise, FALSE.
  static const DWMWA_FORCE_ICONIC_REPRESENTATION = 7;

  /// Use with DwmSetWindowAttribute. Sets how Flip3D treats the window. The
  /// pvAttribute parameter points to a value from the DWMFLIP3DWINDOWPOLICY
  /// enumeration.
  static const DWMWA_FLIP3D_POLICY = 8;

  /// Use with DwmGetWindowAttribute. Retrieves the extended frame bounds
  /// rectangle in screen space. The retrieved value is of type RECT.
  static const DWMWA_EXTENDED_FRAME_BOUNDS = 9;

  /// Use with DwmSetWindowAttribute. The window will provide a bitmap for use
  /// by DWM as an iconic thumbnail or peek representation (a static bitmap) for
  /// the window. DWMWA_HAS_ICONIC_BITMAP can be specified with
  /// DWMWA_FORCE_ICONIC_REPRESENTATION. DWMWA_HAS_ICONIC_BITMAP normally is set
  /// during a window's creation and not changed throughout the window's
  /// lifetime. Some scenarios, however, might require the value to change over
  /// time. The pvAttribute parameter points to a value of type BOOL. TRUE to
  /// inform DWM that the window will provide an iconic thumbnail or peek
  /// representation; otherwise, FALSE.
  static const DWMWA_HAS_ICONIC_BITMAP = 10;

  /// Use with DwmSetWindowAttribute. Do not show peek preview for the window.
  /// The peek view shows a full-sized preview of the window when the mouse
  /// hovers over the window's thumbnail in the taskbar. If this attribute is
  /// set, hovering the mouse pointer over the window's thumbnail dismisses peek
  /// (in case another window in the group has a peek preview showing). The
  /// pvAttribute parameter points to a value of type BOOL. TRUE to prevent peek
  /// functionality, or FALSE to allow it.
  static const DWMWA_DISALLOW_PEEK = 11;

  /// Use with DwmSetWindowAttribute. Prevents a window from fading to a glass
  /// sheet when peek is invoked. The pvAttribute parameter points to a value of
  /// type BOOL. TRUE to prevent the window from fading during another window's
  /// peek, or FALSE for normal behavior.
  static const DWMWA_EXCLUDED_FROM_PEEK = 12;

  /// Use with DwmSetWindowAttribute. Cloaks the window such that it is not
  /// visible to the user. The window is still composed by DWM.
  static const DWMWA_CLOAK = 13;

  /// Use with DwmGetWindowAttribute. If the window is cloaked, provides one of
  /// the following values explaining why.
  ///
  /// - DWM_CLOAKED_APP (value 0x0000001). The window was cloaked by its owner
  ///   application.
  /// - DWM_CLOAKED_SHELL (value 0x0000002). The window was cloaked by the
  ///   Shell.
  /// - DWM_CLOAKED_INHERITED (value 0x0000004). The cloak value was inherited
  ///   from its owner window.
  static const DWMWA_CLOAKED = 14;

  /// Use with DwmSetWindowAttribute. Freeze the window's thumbnail image with
  /// its current visuals. Do no further live updates on the thumbnail image to
  /// match the window's contents.
  static const DWMWA_FREEZE_REPRESENTATION = 15;

  /// Use with DwmSetWindowAttribute. Enables a non-UWP window to use host
  /// backdrop brushes. If this flag is set, then a Win32 app that calls
  /// Windows::UI::Composition APIs can build transparency effects using the
  /// host backdrop brush (see Compositor.CreateHostBackdropBrush). The
  /// retrieved value is of type BOOL. TRUE to enable host backdrop brushes for
  /// the window; otherwise, FALSE. (Supported on Windows 11 and above.)
  static const DWMWA_USE_HOSTBACKDROPBRUSH = 17;

  /// Allows a window to either use the accent color, or
  /// dark, according to the user Color Mode preferences. (Supported on
  /// Windows 11 and above.)
  static const DWMWA_USE_IMMERSIVE_DARK_MODE = 20;

  /// Controls the policy that rounds top-level window corners. (Supported on
  /// Windows 11 and above.)
  static const DWMWA_WINDOW_CORNER_PREFERENCE = 33;

  /// The color of the thin border around a top-level window. (Supported on
  /// Windows 11 and above.)
  static const DWMWA_BORDER_COLOR = 34;

  /// The color of the caption. (Supported on Windows 11 and above.)
  static const DWMWA_CAPTION_COLOR = 35;

  /// The color of the caption text. (Supported on Windows 11 and above.)
  static const DWMWA_TEXT_COLOR = 36;

  /// Width of the visible border around a thick frame window. (Supported on
  /// Windows 11 and above.)
  static const DWMWA_VISIBLE_FRAME_BORDER_THICKNESS = 37;
}

class DWM_WINDOW_CORNER_PREFERENCE {
  /// Let the system decide whether or not to round window corners
  static const DWMWCP_DEFAULT = 0;

  /// Never round window corners
  static const DWMWCP_DONOTROUND = 1;

  /// Round the corners if appropriate
  static const DWMWCP_ROUND = 2;

  /// Round the corners if appropriate, with a small radius
  static const DWMWCP_ROUNDSMALL = 3;
}

// -----------------------------------------------------------------------------
// Token information constants
// -----------------------------------------------------------------------------

/// The TOKEN_INFORMATION_CLASS enumeration contains values that specify the
/// type of information being assigned to or retrieved from an access token.
///
/// {@category Struct}
class TOKEN_INFORMATION_CLASS {
  static const TokenUser = 1;
  static const TokenGroups = 2;
  static const TokenPrivileges = 3;
  static const TokenOwner = 4;
  static const TokenPrimaryGroup = 5;
  static const TokenDefaultDacl = 6;
  static const TokenSource = 7;
  static const TokenType = 8;
  static const TokenImpersonationLevel = 9;
  static const TokenStatistics = 10;
  static const TokenRestrictedSids = 11;
  static const TokenSessionId = 12;
  static const TokenGroupsAndPrivileges = 13;
  static const TokenSessionReference = 14;
  static const TokenSandBoxInert = 15;
  static const TokenAuditPolicy = 16;
  static const TokenOrigin = 17;
  static const TokenElevationType = 18;
  static const TokenLinkedToken = 19;
  static const TokenElevation = 20;
  static const TokenHasRestrictions = 21;
  static const TokenAccessInformation = 22;
  static const TokenVirtualizationAllowed = 23;
  static const TokenVirtualizationEnabled = 24;
  static const TokenIntegrityLevel = 25;
  static const TokenUIAccess = 26;
  static const TokenMandatoryPolicy = 27;
  static const TokenLogonSid = 28;
  static const TokenIsAppContainer = 29;
  static const TokenCapabilities = 30;
  static const TokenAppContainerSid = 31;
  static const TokenAppContainerNumber = 32;
  static const TokenUserClaimAttributes = 33;
  static const TokenDeviceClaimAttributes = 34;
  static const TokenRestrictedUserClaimAttributes = 35;
  static const TokenRestrictedDeviceClaimAttributes = 36;
  static const TokenDeviceGroups = 37;
  static const TokenRestrictedDeviceGroups = 38;
  static const TokenSecurityAttributes = 39;
  static const TokenIsRestricted = 40;
  static const TokenProcessTrustLevel = 41;
  static const TokenPrivateNameSpace = 42;
  static const TokenSingletonAttributes = 43;
  static const TokenBnoIsolation = 44;
  static const TokenChildProcessFlags = 45;
  static const TokenIsLessPrivilegedAppContainer = 46;
  static const TokenIsSandboxed = 47;
  static const TokenOriginatingProcessTrustLevel = 48;
}

// -----------------------------------------------------------------------------
// Smartcard constants
// -----------------------------------------------------------------------------

/// A smart card holder verification (CHV) attempt failed.
const SCARD_AUDIT_CHV_FAILURE = 0x0;

/// A smart card holder verification (CHV) attempt succeeded.
const SCARD_AUDIT_CHV_SUCCESS = 0x1;

/// No transmission protocol is active.
const SCARD_PROTOCOL_UNDEFINED = 0x00000000;

/// The ISO 7816/3 T=0 protocol is in use.
const SCARD_PROTOCOL_T0 = 0x00000001;

/// The ISO 7816/3 T=1 protocol is in use.
const SCARD_PROTOCOL_T1 = 0x00000002;

/// The Raw Transfer protocol is in use.
const SCARD_PROTOCOL_RAW = 0x00010000;

/// Bitwise OR combination of both of the two International Standards
/// Organization (IS0) transmission protocols SCARD_PROTOCOL_T0 and
/// SCARD_PROTOCOL_T1.
const SCARD_PROTOCOL_Tx = SCARD_PROTOCOL_T0 | SCARD_PROTOCOL_T1;

/// Use the implicit protocol of the card with standard parameters.
const SCARD_PROTOCOL_DEFAULT = 0x80000000;

/// Use the best possible communication parameters.
const SCARD_PROTOCOL_OPTIMAL = 0x00000000;

/// Remove power from the smart card.
const SCARD_POWER_DOWN = 0;

/// Power down the smart card and power it up again.
const SCARD_COLD_RESET = 1;

/// Reset the smart card without removing power.
const SCARD_WARM_RESET = 2;

/// The reader driver has no information concerning the current state of the
/// reader.
const SCARD_UNKNOWN = 0;

/// There is no card in the reader.
const SCARD_ABSENT = 1;

/// There is a card in the reader, but it has not been moved into position for
/// use.
const SCARD_PRESENT = 2;

/// There is a card in the reader in position for use. The card is not powered.
const SCARD_SWALLOWED = 3;

/// Power is being provided to the card, but the reader driver is unaware of the
/// mode of the card.
const SCARD_POWERED = 4;

/// The card has been reset and is awaiting PTS negotiation.
const SCARD_NEGOTIABLE = 5;

/// The card has been reset and specific communication protocols have been
/// established.
const SCARD_SPECIFIC = 6;

/// This application is not willing to share the card with other applications.
const SCARD_SHARE_EXCLUSIVE = 1;

/// This application is willing to share the card with other applications.
const SCARD_SHARE_SHARED = 2;

/// This application is allocating the reader for its private use, and will be
/// controlling it directly. No other applications are allowed access to it.
const SCARD_SHARE_DIRECT = 3;

/// Don't do anything special on close.
const SCARD_LEAVE_CARD = 0;

/// Reset the card on close.
const SCARD_RESET_CARD = 1;

/// Power down the card on close.
const SCARD_UNPOWER_CARD = 2;

/// Eject the card on close.
const SCARD_EJECT_CARD = 3;

/// Database operations are performed within the domain of the user.
const SCARD_SCOPE_USER = 0;

/// Database operations are performed within the domain of the current terminal.
const SCARD_SCOPE_TERMINAL = 1;

/// Database operations are performed within the domain of the system. The
/// calling application must have appropriate access permissions for any
/// database actions.
const SCARD_SCOPE_SYSTEM = 2;

/// The function retrieves the name of the smart card's primary service provider
/// as a GUID string.
const SCARD_PROVIDER_PRIMARY = 1;

/// The function retrieves the name of the cryptographic service provider.
const SCARD_PROVIDER_CSP = 2;

/// The function retrieves the name of the smart card key storage provider
/// (KSP).
const SCARD_PROVIDER_KSP = 3;

/// The function retrieves the name of the card module.
const SCARD_PROVIDER_CARD_MODULE = 0x80000001;

/// Selects the smart card if only one smart card meets the criteria, or returns
/// information about the user's selection if more than one smart card meets the
/// criteria.
const SC_DLG_MINIMAL_UI = 0x01;

/// Selects the first available card.
const SC_DLG_NO_UI = 0x02;

/// Connects to the card selected by the user from the smart card Select Card
/// dialog box.
const SC_DLG_FORCE_UI = 0x04;

// -----------------------------------------------------------------------------
// EnumPrinters constants
// -----------------------------------------------------------------------------

/// (Win9.x only) enumerates the default printer.
const PRINTER_ENUM_DEFAULT = 00000001;

/// If the PRINTER_ENUM_NAME flag is not also passed, the function ignores the
/// Name parameter, and enumerates the locally installed printers.
/// If PRINTER_ENUM_NAME is also passed, the function enumerates the local
/// printers on Name.
const PRINTER_ENUM_LOCAL = 00000002;

/// The function enumerates the list of printers to which the user has made
/// previous connections.
const PRINTER_ENUM_CONNECTIONS = 0x00000004;

///
const PRINTER_ENUM_FAVORITE = 0x00000004;

/// The function enumerates the printer identified by Name. This can be a server
/// a domain, or a print provider. If Name is NULL, the function enumerates
/// available print providers.
const PRINTER_ENUM_NAME = 00000008;

/// The function enumerates network printers and print servers in the computer's
/// domain. This value is valid only if Level is 1.
const PRINTER_ENUM_REMOTE = 00000010;

/// The function enumerates printers that have the shared attribute. Cannot be
/// used in isolation; use an OR operation to combine with another PRINTER_ENUM
/// type.
const PRINTER_ENUM_SHARED = 00000020;

/// The function enumerates network printers in the computer's domain. This
/// value is valid only if Level is 1.
const PRINTER_ENUM_NETWORK = 00000040;

/// Indicates that the printer object contains further enumerable child objects.
const PRINTER_ENUM_EXPAND = 00004000;

/// Indicates that the printer object is capable of containing enumerable
/// objects. One such object is a print provider, which is a print server that
/// contains printers.
const PRINTER_ENUM_CONTAINER = 0x00008000;

///
const PRINTER_ENUM_ICONMASK = 0x00ff0000;

///
const PRINTER_ENUM_ICON1 = 00010000;

///
const PRINTER_ENUM_ICON2 = 00020000;

///
const PRINTER_ENUM_ICON3 = 00040000;

///
const PRINTER_ENUM_ICON4 = 00080000;

///
const PRINTER_ENUM_ICON5 = 00100000;

///
const PRINTER_ENUM_ICON6 = 00200000;

///
const PRINTER_ENUM_ICON7 = 00400000;

/// Indicates that, where appropriate, an application treats an object as a
/// print server. A GUI application can<145> choose to display an icon of choice
/// for this type of object.
const PRINTER_ENUM_ICON8 = 00800000;

/// Indicates that an application cannot display the printer object.
const PRINTER_ENUM_HIDE = 01000000;

/// PRINTER_ENUM_CATEGORY_ALL
const PRINTER_ENUM_CATEGORY_ALL = 0x02000000;

/// The function enumerates only 3D printers.
const PRINTER_ENUM_CATEGORY_3D = 0x04000000;

// -----------------------------------------------------------------------------
// GetWindow constants
// -----------------------------------------------------------------------------
/// The retrieved handle identifies the child window at the top of the Z order,
/// if the specified window is a parent window; otherwise, the retrieved handle
/// is NULL. The function examines only child windows of the specified window.
/// It does not examine descendant windows.
const GW_CHILD = 5;

/// The retrieved handle identifies the enabled popup window owned by the
/// specified window (the search uses the first such window found using
/// GW_HWNDNEXT); otherwise, if there are no enabled popup windows, the
/// retrieved handle is that of the specified window.
const GW_ENABLEDPOPUP = 6;

/// The retrieved handle identifies the window of the same type that is highest
/// in the Z order.
/// If the specified window is a topmost window, the handle identifies a topmost
/// window. If the specified window is a top-level window, the handle identifies
/// a top-level window. If the specified window is a child window, the handle
/// identifies a sibling window.
const GW_HWNDFIRST = 0;

/// The retrieved handle identifies the window of the same type that is lowest
/// in the Z order.
/// If the specified window is a topmost window, the handle identifies a topmost
/// window. If the specified window is a top-level window, the handle identifies
/// a top-level window. If the specified window is a child window, the handle
/// identifies a sibling window.
const GW_HWNDLAST = 1;

/// The retrieved handle identifies the window below the specified window in the
/// Z order.
/// If the specified window is a topmost window, the handle identifies a topmost
/// window. If the specified window is a top-level window, the handle identifies
/// a top-level window. If the specified window is a child window, the handle
/// identifies a sibling window.
const GW_HWNDNEXT = 2;

/// The retrieved handle identifies the window above the specified window in the
/// Z order.
/// If the specified window is a topmost window, the handle identifies a topmost
/// window. If the specified window is a top-level window, the handle identifies
/// a top-level window. If the specified window is a child window, the handle
/// identifies a sibling window.
const GW_HWNDPREV = 3;

/// The retrieved handle identifies the specified window's owner window, if any.
/// For more information, see Owned Windows.
const GW_OWNER = 4;

/// The WSL_DISTRIBUTION_FLAGS enumeration specifies the behavior of a
/// distribution in the Windows Subsystem for Linux (WSL).
///
/// {@category Enum}
class WSL_DISTRIBUTION_FLAGS {
  /// No flags are being supplied.
  static const WSL_DISTRIBUTION_FLAGS_NONE = 0x0;

  /// Allow the distribution to interoperate with Windows processes (for
  /// example, the user can invoke "cmd.exe" or "notepad.exe" from within a WSL
  /// session).
  static const WSL_DISTRIBUTION_FLAGS_ENABLE_INTEROP = 0x1;

  /// Add the Windows %PATH% environment variable values to WSL sessions.
  static const WSL_DISTRIBUTION_FLAGS_APPEND_NT_PATH = 0x2;

  /// Automatically mount Windows drives inside of WSL sessions (for example,
  /// "C:" will be available under "/mnt/c").
  static const WSL_DISTRIBUTION_FLAGS_ENABLE_DRIVE_MOUNTING = 0x4;
}

/// Specifies the type of visual style attribute to set on a window.
class WINDOWTHEMEATTRIBUTETYPE {
  /// Non-client area window attributes will be set.
  static const WTA_NONCLIENT = 1;
}

class SPEAKFLAGS {
  /// Specifies that the default settings should be used.
  static const SPF_DEFAULT = 0;

  /// Specifies that the Speak call should be asynchronous. That is, it will
  /// return immediately after the speak request is queued.
  static const SPF_ASYNC = 1;

  /// Purges all pending speak requests prior to this speak call.
  static const SPF_PURGEBEFORESPEAK = 2;

  /// The string passed to ISpVoice::Speak is a file name, and the file text
  /// should be spoken.
  static const SPF_IS_FILENAME = 4;

  /// The input text will be parsed for XML markup.
  static const SPF_IS_XML = 8;

  /// The input text will not be parsed for XML markup.
  static const SPF_IS_NOT_XML = 0x10;

  /// Global state changes in the XML markup will persist across speak calls.
  static const SPF_PERSIST_XML = 0x20;

  /// Punctuation characters should be expanded into words (for example, "This
  /// is a sentence." would become "This is a sentence period").
  static const SPF_NLP_SPEAK_PUNC = 0x40;

  /// Force XML parsing As MS SAPI.
  static const SPF_PARSE_SAPI = 0x80;

  /// Force XML parsing As W3C SSML.
  static const SPF_PARSE_SSML = 0x100;

  /// The TTS XML format is auto-detected. This is the default if none of these
  /// TTS XML format values are present in the bit-field.
  static const SPF_PARSE_AUTODETECT = 0;
}

// -----------------------------------------------------------------------------
// Bluetooth IDs
// -----------------------------------------------------------------------------

/// Bluetooth LE device interface GUID
const GUID_BLUETOOTHLE_DEVICE_INTERFACE =
    '{781aee18-7733-4ce4-add0-91f41c67b592}';

/// Bluetooth LE Service device interface GUID
const GUID_BLUETOOTH_GATT_SERVICE_DEVICE_INTERFACE =
    '{6e3bb679-4372-40c8-9eaa-4509df260cd8}';

/// The client does not have specific GATT requirements (default).
const BLUETOOTH_GATT_FLAG_NONE = 0x00000000;

/// The client requests the data to be transmitted over an encrypted channel.
const BLUETOOTH_GATT_FLAG_CONNECTION_ENCRYPTED = 0x00000001;

/// The client requests the data to be transmitted over an authenticated
/// channel.
const BLUETOOTH_GATT_FLAG_CONNECTION_AUTHENTICATED = 0x00000002;

/// The characteristic value is to be read directly from the device. This
/// overwrites the one in the cache if one is already present.
const BLUETOOTH_GATT_FLAG_FORCE_READ_FROM_DEVICE = 0x00000004;

/// The characteristic value is to be read from the cache (regardless of whether
/// it is present in the cache or not).
const BLUETOOTH_GATT_FLAG_FORCE_READ_FROM_CACHE = 0x00000008;

/// Signed write. Profile drivers must use with
/// BLUETOOTH_GATT_FLAG_WRITE_WITHOUT_RESPONSE in order to produce signed write
/// without a response.
const BLUETOOTH_GATT_FLAG_SIGNED_WRITE = 0x00000010;

/// Write without response.
const BLUETOOTH_GATT_FLAG_WRITE_WITHOUT_RESPONSE = 0x00000020;
const BLUETOOTH_GATT_FLAG_RETURN_ALL = 0x00000040;

// -----------------------------------------------------------------------------
// SetupDiGetClassDevs constants
// -----------------------------------------------------------------------------

/// Return only the device that is associated with the system default device
/// interface, if one is set, for the specified device interface classes.
const DIGCF_DEFAULT = 0x00000001;

/// Return only devices that are currently present in a system.
const DIGCF_PRESENT = 0x00000002;

/// Return a list of installed devices for all device setup classes or all
/// device interface classes.
const DIGCF_ALLCLASSES = 0x00000004;

/// Return only devices that are a part of the current hardware profile.
const DIGCF_PROFILE = 0x00000008;

/// Return devices that support device interfaces for the specified device
/// interface classes.
const DIGCF_DEVICEINTERFACE = 0x00000010;

/// Make the change in all hardware profiles.
const DICS_FLAG_GLOBAL = 0x00000001;

/// Make the change in the specified profile only.
const DICS_FLAG_CONFIGSPECIFIC = 0x00000002;

/// (Obsolete. Do not use.)
const DICS_FLAG_CONFIGGENERAL = 0x00000004;

/// Hardware key for the device.
const DIREG_DEV = 0x00000001;

/// Software key for the device.
const DIREG_DRV = 0x00000002;

/// Both hardware and software keys.
const DIREG_BOTH = 0x00000004;

// -----------------------------------------------------------------------------
// IAudioClient constants
// -----------------------------------------------------------------------------

/// The AUDCLNT_SHAREMODE enumeration defines constants that indicate whether an
/// audio stream will run in shared mode or in exclusive mode.
///
/// {@category Enum}
class AUDCLNT_SHAREMODE {
  /// The audio stream will run in shared mode.
  static const AUDCLNT_SHAREMODE_SHARED = 0;

  /// The audio stream will run in exclusive mode.
  static const AUDCLNT_SHAREMODE_EXCLUSIVE = 1;
}

/// The AUDCLNT_BUFFERFLAGS enumeration defines flags that indicate the status
/// of an audio endpoint buffer.
///
/// {@category Enum}
class AUDCLNT_BUFFERFLAGS {
  /// The data in the packet is not correlated with the previous packet's device
  /// position; this is possibly due to a stream state transition or timing
  /// glitch.
  static const AUDCLNT_BUFFERFLAGS_DATA_DISCONTINUITY = 0x1;

  /// Treat all of the data in the packet as silence and ignore the actual data
  /// values.
  static const AUDCLNT_BUFFERFLAGS_SILENT = 0x2;

  /// The time at which the device's stream position was recorded is uncertain.
  /// Thus, the client might be unable to accurately set the time stamp for the
  /// current data packet.
  static const AUDCLNT_BUFFERFLAGS_TIMESTAMP_ERROR = 0x4;
}

/// Defines values that describe the characteristics of an audio stream.
///
/// {@category Enum}
class AUDCLNT_STREAMOPTIONS {
  /// No stream options.
  static const AUDCLNT_STREAMOPTIONS_NONE = 0;

  /// The audio stream is a 'raw' stream that bypasses all signal processing
  /// except for endpoint specific, always-on processing in the Audio Processing
  /// Object (APO), driver, and hardware.
  static const AUDCLNT_STREAMOPTIONS_RAW = 0x1;

  /// The audio client is requesting that the audio engine match the format
  /// proposed by the client.
  static const AUDCLNT_STREAMOPTIONS_MATCH_FORMAT = 0x2;
  static const AUDCLNT_STREAMOPTIONS_AMBISONICS = 0x4;
}

/// Device registry property codes.
///
/// {@category Enum}
class SPDRP {
  /// The function retrieves a REG_SZ string that contains the description of a
  /// device.
  static const SPDRP_DEVICEDESC = 0x00000000;

  /// The function retrieves a REG_MULTI_SZ string that contains the list of
  /// hardware IDs for a device.
  static const SPDRP_HARDWAREID = 0x00000001;

  /// The function retrieves a REG_MULTI_SZ string that contains the list of
  /// compatible IDs for a device.
  static const SPDRP_COMPATIBLEIDS = 0x00000002;

  /// The function retrieves a REG_SZ string that contains the service name for
  /// a device.
  static const SPDRP_SERVICE = 0x00000004;

  /// The function retrieves a REG_SZ string that contains the device setup
  /// class of a device.
  static const SPDRP_CLASS = 0x00000007;

  /// The function retrieves a REG_SZ string that contains the GUID that
  /// represents the device setup class of a device.
  static const SPDRP_CLASSGUID = 0x00000008;

  /// The function retrieves a string that identifies the device's software key
  /// (sometimes called the driver key).
  static const SPDRP_DRIVER = 0x00000009;

  /// The function retrieves a bitwise OR of a device's configuration flags in a
  /// DWORD value. The configuration flags are represented by the CONFIGFLAG_Xxx
  /// bitmasks that are defined in Regstr.h.
  static const SPDRP_CONFIGFLAGS = 0x0000000A;

  /// The function retrieves a REG_SZ string that contains the name of the
  /// device manufacturer.
  static const SPDRP_MFG = 0x0000000B;

  /// The function retrieves a REG_SZ string that contains the friendly name of
  /// a device.
  static const SPDRP_FRIENDLYNAME = 0x0000000C;

  /// The function retrieves a REG_SZ string that contains the hardware location
  /// of a device.
  static const SPDRP_LOCATION_INFORMATION = 0x0000000D;

  /// The function retrieves a REG_SZ string that contains the name that is
  /// associated with the device's PDO.
  static const SPDRP_PHYSICAL_DEVICE_OBJECT_NAME = 0x0000000E;

  /// The function retrieves a bitwise OR of the following CM_DEVCAP_Xxx flags
  /// in a DWORD. The device capabilities that are represented by these flags
  /// correspond to the device capabilities that are represented by the members
  /// of the DEVICE_CAPABILITIES structure.
  static const SPDRP_CAPABILITIES = 0x0000000F;

  /// The function retrieves a DWORD value set to the value of the UINumber
  /// member of the device's DEVICE_CAPABILITIES structure.
  static const SPDRP_UI_NUMBER = 0x00000010;

  /// The function retrieves a REG_MULTI_SZ string that contains the names of a
  /// device's upper filter drivers.
  static const SPDRP_UPPERFILTERS = 0x00000011;

  /// The function retrieves a REG_MULTI_SZ string that contains the names of a
  /// device's lower-filter drivers.
  static const SPDRP_LOWERFILTERS = 0x00000012;

  /// The function retrieves the GUID for the device's bus type.
  static const SPDRP_BUSTYPEGUID = 0x00000013;

  /// The function retrieves the device's legacy bus type as an INTERFACE_TYPE
  /// value (defined in Wdm.h and Ntddk.h).
  static const SPDRP_LEGACYBUSTYPE = 0x00000014;

  /// The function retrieves the device's bus number.
  static const SPDRP_BUSNUMBER = 0x00000015;

  /// The function retrieves a REG_SZ string that contains the name of the
  /// device's enumerator.
  static const SPDRP_ENUMERATOR_NAME = 0x00000016;

  /// The function retrieves a SECURITY_DESCRIPTOR structure for a device.
  static const SPDRP_SECURITY = 0x00000017;

  /// The function retrieves a REG_SZ string that contains the device's security
  /// descriptor.
  static const SPDRP_SECURITY_SDS = 0x00000018;

  /// The function retrieves a DWORD value that represents the device's type.
  /// For more information, see Specifying Device Types.
  static const SPDRP_DEVTYPE = 0x00000019;

  /// The function retrieves a DWORD value that indicates whether a user can
  /// obtain exclusive use of the device. The returned value is one if exclusive
  /// use is allowed, or zero otherwise.
  static const SPDRP_EXCLUSIVE = 0x0000001A;

  /// The function retrieves a bitwise OR of a device's characteristics flags in
  /// a DWORD.
  static const SPDRP_CHARACTERISTICS = 0x0000001B;

  /// The function retrieves the device's address.
  static const SPDRP_ADDRESS = 0x0000001C;

  /// The function retrieves a format string (REG_SZ) used to display the
  /// UINumber value.
  static const SPDRP_UI_NUMBER_DESC_FORMAT = 0X0000001D;

  /// The function retrieves a CM_POWER_DATA structure that contains the
  /// device's power management information.
  static const SPDRP_DEVICE_POWER_DATA = 0x0000001E;

  /// The function retrieves the device's current removal policy as a DWORD that
  /// contains one of the CM_REMOVAL_POLICY_Xxx values that are defined in
  /// Cfgmgr32.h.
  static const SPDRP_REMOVAL_POLICY = 0x0000001F;

  /// The function retrieves the device's hardware-specified default removal
  /// policy as a DWORD that contains one of the CM_REMOVAL_POLICY_Xxx values
  /// that are defined in Cfgmgr32.h.
  static const SPDRP_REMOVAL_POLICY_HW_DEFAULT = 0x00000020;

  /// The function retrieves the device's override removal policy (if it exists)
  /// from the registry, as a DWORD that contains one of the
  /// CM_REMOVAL_POLICY_Xxx values that are defined in Cfgmgr32.h.
  static const SPDRP_REMOVAL_POLICY_OVERRIDE = 0x00000021;

  /// The function retrieves a DWORD value that indicates the installation state
  /// of a device. The installation state is represented by one of the
  /// CM_INSTALL_STATE_Xxx values that are defined in Cfgmgr32.h. The
  /// CM_INSTALL_STATE_Xxx values correspond to the DEVICE_INSTALL_STATE
  /// enumeration values.
  static const SPDRP_INSTALL_STATE = 0x00000022;

  /// The function retrieves a REG_MULTI_SZ string that represents the location
  /// of the device in the device tree.
  static const SPDRP_LOCATION_PATHS = 0x00000023;
}
