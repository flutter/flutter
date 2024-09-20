// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_internal' show patch;
import 'dart:async';
import 'dart:convert';
import 'dart:isolate' show SendPort;
import 'dart:typed_data';

@patch
class _Directory {
  @patch
  static _current(_Namespace namespace) {
    throw UnsupportedError("Directory._current");
  }

  @patch
  static _setCurrent(_Namespace namespace, Uint8List rawPath) {
    throw UnsupportedError("Directory_SetCurrent");
  }

  @patch
  static _createTemp(_Namespace namespace, Uint8List rawPath) {
    throw UnsupportedError("Directory._createTemp");
  }

  @patch
  static String _systemTemp(_Namespace namespace) {
    throw UnsupportedError("Directory._systemTemp");
  }

  @patch
  static _exists(_Namespace namespace, Uint8List rawPath) {
    throw UnsupportedError("Directory._exists");
  }

  @patch
  static _create(_Namespace namespace, Uint8List rawPath) {
    throw UnsupportedError("Directory._create");
  }

  @patch
  static _deleteNative(
      _Namespace namespace, Uint8List rawPath, bool recursive) {
    throw UnsupportedError("Directory._deleteNative");
  }

  @patch
  static _rename(_Namespace namespace, Uint8List rawPath, String newPath) {
    throw UnsupportedError("Directory._rename");
  }

  @patch
  static void _fillWithDirectoryListing(
      _Namespace namespace,
      List<FileSystemEntity> list,
      Uint8List rawPath,
      bool recursive,
      bool followLinks) {
    throw UnsupportedError("Directory._fillWithDirectoryListing");
  }
}

@patch
class _AsyncDirectoryListerOps {
  @patch
  factory _AsyncDirectoryListerOps(int pointer) {
    throw UnsupportedError("Directory._list");
  }
}

@patch
class _EventHandler {
  @patch
  static void _sendData(Object? sender, SendPort sendPort, int data) {
    throw UnsupportedError("EventHandler._sendData");
  }
}

@patch
class FileStat {
  @patch
  static _statSync(_Namespace namespace, String path) {
    throw UnsupportedError("FileStat.stat");
  }
}

@patch
class FileSystemEntity {
  @patch
  static _getTypeNative(
      _Namespace namespace, Uint8List rawPath, bool followLinks) {
    throw UnsupportedError("FileSystemEntity._getType");
  }

  @patch
  static _identicalNative(_Namespace namespace, String path1, String path2) {
    throw UnsupportedError("FileSystemEntity._identical");
  }

  @patch
  static _resolveSymbolicLinks(_Namespace namespace, Uint8List rawPath) {
    throw UnsupportedError("FileSystemEntity._resolveSymbolicLinks");
  }
}

@patch
class _File {
  @patch
  static _exists(_Namespace namespace, Uint8List rawPath) {
    throw UnsupportedError("File._exists");
  }

  @patch
  static _create(_Namespace namespace, Uint8List rawPath, bool exclusive) {
    throw UnsupportedError("File._create");
  }

  @patch
  static _createLink(_Namespace namespace, Uint8List rawPath, String target) {
    throw UnsupportedError("File._createLink");
  }

  @patch
  static List<dynamic> _createPipe(_Namespace namespace) {
    throw UnsupportedError("File._createPipe");
  }

  @patch
  static _linkTarget(_Namespace namespace, Uint8List rawPath) {
    throw UnsupportedError("File._linkTarget");
  }

  @patch
  static _deleteNative(_Namespace namespace, Uint8List rawPath) {
    throw UnsupportedError("File._deleteNative");
  }

  @patch
  static _deleteLinkNative(_Namespace namespace, Uint8List rawPath) {
    throw UnsupportedError("File._deleteLinkNative");
  }

  @patch
  static _rename(_Namespace namespace, Uint8List oldPath, String newPath) {
    throw UnsupportedError("File._rename");
  }

  @patch
  static _renameLink(_Namespace namespace, Uint8List oldPath, String newPath) {
    throw UnsupportedError("File._renameLink");
  }

  @patch
  static _copy(_Namespace namespace, Uint8List oldPath, String newPath) {
    throw UnsupportedError("File._copy");
  }

  @patch
  static _lengthFromPath(_Namespace namespace, Uint8List rawPath) {
    throw UnsupportedError("File._lengthFromPath");
  }

  @patch
  static _lastModified(_Namespace namespace, Uint8List rawPath) {
    throw UnsupportedError("File._lastModified");
  }

  @patch
  static _lastAccessed(_Namespace namespace, Uint8List rawPath) {
    throw UnsupportedError("File._lastAccessed");
  }

  @patch
  static _setLastModified(_Namespace namespace, Uint8List rawPath, int millis) {
    throw UnsupportedError("File._setLastModified");
  }

  @patch
  static _setLastAccessed(_Namespace namespace, Uint8List rawPath, int millis) {
    throw UnsupportedError("File._setLastAccessed");
  }

  @patch
  static _open(_Namespace namespace, Uint8List rawPath, int mode) {
    throw UnsupportedError("File._open");
  }

  @patch
  static int _openStdio(int fd) {
    throw UnsupportedError("File._openStdio");
  }
}

@patch
class _Namespace {
  @patch
  static void _setupNamespace(var namespace) {
    throw UnsupportedError("_Namespace");
  }

  @patch
  static _Namespace get _namespace {
    throw UnsupportedError("_Namespace");
  }

  @patch
  static int get _namespacePointer {
    throw UnsupportedError("_Namespace");
  }
}

@patch
class _RandomAccessFileOps {
  @patch
  factory _RandomAccessFileOps(int pointer) {
    throw UnsupportedError("RandomAccessFile");
  }
}

@patch
class _IOCrypto {
  @patch
  static Uint8List getRandomBytes(int count) {
    throw UnsupportedError("_IOCrypto.getRandomBytes");
  }
}

@patch
class _Platform {
  @patch
  static int _numberOfProcessors() {
    throw UnsupportedError("Platform._numberOfProcessors");
  }

  @patch
  static String _pathSeparator() {
    throw UnsupportedError("Platform._pathSeparator");
  }

  @patch
  static String _operatingSystem() {
    throw UnsupportedError("Platform._operatingSystem");
  }

  @patch
  static _operatingSystemVersion() {
    throw UnsupportedError("Platform._operatingSystemVersion");
  }

  @patch
  static _localHostname() {
    throw UnsupportedError("Platform._localHostname");
  }

  @patch
  static _executable() {
    throw UnsupportedError("Platform._executable");
  }

  @patch
  static _resolvedExecutable() {
    throw UnsupportedError("Platform._resolvedExecutable");
  }

  @patch
  static List<String> _executableArguments() {
    throw UnsupportedError("Platform._executableArguments");
  }

  @patch
  static String _packageConfig() {
    throw UnsupportedError("Platform._packageConfig");
  }

  @patch
  static _environment() {
    throw UnsupportedError("Platform._environment");
  }

  @patch
  static String _version() {
    throw UnsupportedError("Platform._version");
  }

  @patch
  static String _localeName() {
    throw UnsupportedError("Platform._localeName");
  }

  @patch
  static Uri _script() {
    throw UnsupportedError("Platform._script");
  }
}

@patch
class _ProcessUtils {
  @patch
  static Never _exit(int status) {
    throw UnsupportedError("ProcessUtils._exit");
  }

  @patch
  static void _setExitCode(int status) {
    throw UnsupportedError("ProcessUtils._setExitCode");
  }

  @patch
  static int _getExitCode() {
    throw UnsupportedError("ProcessUtils._getExitCode");
  }

  @patch
  static void _sleep(int millis) {
    throw UnsupportedError("ProcessUtils._sleep");
  }

  @patch
  static int _pid(Process? process) {
    throw UnsupportedError("ProcessUtils._pid");
  }

  @patch
  static Stream<ProcessSignal> _watchSignal(ProcessSignal signal) {
    throw UnsupportedError("ProcessUtils._watchSignal");
  }
}

@patch
class ProcessInfo {
  @patch
  static int get currentRss {
    throw UnsupportedError("ProcessInfo.currentRss");
  }

  @patch
  static int get maxRss {
    throw UnsupportedError("ProcessInfo.maxRss");
  }
}

@patch
class Process {
  @patch
  static Future<Process> start(String executable, List<String> arguments,
      {String? workingDirectory,
      Map<String, String>? environment,
      bool includeParentEnvironment = true,
      bool runInShell = false,
      ProcessStartMode mode = ProcessStartMode.normal}) {
    throw UnsupportedError("Process.start");
  }

  @patch
  static Future<ProcessResult> run(String executable, List<String> arguments,
      {String? workingDirectory,
      Map<String, String>? environment,
      bool includeParentEnvironment = true,
      bool runInShell = false,
      Encoding? stdoutEncoding = systemEncoding,
      Encoding? stderrEncoding = systemEncoding}) {
    throw UnsupportedError("Process.run");
  }

  @patch
  static ProcessResult runSync(String executable, List<String> arguments,
      {String? workingDirectory,
      Map<String, String>? environment,
      bool includeParentEnvironment = true,
      bool runInShell = false,
      Encoding? stdoutEncoding = systemEncoding,
      Encoding? stderrEncoding = systemEncoding}) {
    throw UnsupportedError("Process.runSync");
  }

  @patch
  static bool killPid(int pid, [ProcessSignal signal = ProcessSignal.sigterm]) {
    throw UnsupportedError("Process.killPid");
  }
}

@patch
class InternetAddress {
  @patch
  static InternetAddress get loopbackIPv4 {
    throw UnsupportedError("InternetAddress.loopbackIPv4");
  }

  @patch
  static InternetAddress get loopbackIPv6 {
    throw UnsupportedError("InternetAddress.loopbackIPv6");
  }

  @patch
  static InternetAddress get anyIPv4 {
    throw UnsupportedError("InternetAddress.anyIPv4");
  }

  @patch
  static InternetAddress get anyIPv6 {
    throw UnsupportedError("InternetAddress.anyIPv6");
  }

  @patch
  factory InternetAddress(String address, {InternetAddressType? type}) {
    throw UnsupportedError("InternetAddress");
  }

  @patch
  factory InternetAddress.fromRawAddress(Uint8List rawAddress,
      {InternetAddressType? type}) {
    throw UnsupportedError("InternetAddress.fromRawAddress");
  }

  @patch
  static Future<List<InternetAddress>> lookup(String host,
      {InternetAddressType type = InternetAddressType.any}) {
    throw UnsupportedError("InternetAddress.lookup");
  }

  @patch
  static InternetAddress _cloneWithNewHost(
      InternetAddress address, String host) {
    throw UnsupportedError("InternetAddress._cloneWithNewHost");
  }

  @patch
  static InternetAddress? tryParse(String address) {
    throw UnsupportedError("InternetAddress.tryParse");
  }
}

@patch
class NetworkInterface {
  @patch
  static bool get listSupported {
    throw UnsupportedError("NetworkInterface.listSupported");
  }

  @patch
  static Future<List<NetworkInterface>> list(
      {bool includeLoopback = false,
      bool includeLinkLocal = false,
      InternetAddressType type = InternetAddressType.any}) {
    throw UnsupportedError("NetworkInterface.list");
  }
}

@patch
class RawServerSocket {
  @patch
  static Future<RawServerSocket> bind(address, int port,
      {int backlog = 0, bool v6Only = false, bool shared = false}) {
    throw UnsupportedError("RawServerSocket.bind");
  }
}

@patch
class ServerSocket {
  @patch
  static Future<ServerSocket> _bind(address, int port,
      {int backlog = 0, bool v6Only = false, bool shared = false}) {
    throw UnsupportedError("ServerSocket.bind");
  }
}

@patch
class RawSocket {
  @patch
  static Future<RawSocket> connect(dynamic host, int port,
      {dynamic sourceAddress, int sourcePort = 0, Duration? timeout}) {
    throw UnsupportedError("RawSocket constructor");
  }

  @patch
  static Future<ConnectionTask<RawSocket>> startConnect(dynamic host, int port,
      {dynamic sourceAddress, int sourcePort = 0}) {
    throw UnsupportedError("RawSocket constructor");
  }
}

@patch
class Socket {
  @patch
  static Future<Socket> _connect(dynamic host, int port,
      {dynamic sourceAddress, int sourcePort = 0, Duration? timeout}) {
    throw UnsupportedError("Socket constructor");
  }

  @patch
  static Future<ConnectionTask<Socket>> _startConnect(dynamic host, int port,
      {dynamic sourceAddress, int sourcePort = 0}) {
    throw UnsupportedError("Socket constructor");
  }
}

@patch
class SocketControlMessage {
  @patch
  factory SocketControlMessage.fromHandles(List<ResourceHandle> handles) {
    throw UnsupportedError("SocketControlMessage constructor");
  }
}

@patch
class ResourceHandle {
  @patch
  factory ResourceHandle.fromFile(RandomAccessFile file) {
    throw UnsupportedError("ResourceHandle.fromFile constructor");
  }

  @patch
  factory ResourceHandle.fromSocket(Socket socket) {
    throw UnsupportedError("ResourceHandle.fromSocket constructor");
  }

  @patch
  factory ResourceHandle.fromRawSocket(RawSocket rawSocket) {
    throw UnsupportedError("ResourceHandle.fromRawSocket constructor");
  }

  @patch
  factory ResourceHandle.fromRawDatagramSocket(
      RawDatagramSocket rawDatagramSocket) {
    throw UnsupportedError("ResourceHandle.fromRawDatagramSocket constructor");
  }

  @patch
  factory ResourceHandle.fromStdin(Stdin stdin) {
    throw UnsupportedError("ResourceHandle.fromStdin constructor");
  }

  @patch
  factory ResourceHandle.fromStdout(Stdout stdout) {
    throw UnsupportedError("ResourceHandle.fromStdout constructor");
  }

  @patch
  factory ResourceHandle.fromReadPipe(ReadPipe pipe) {
    throw UnsupportedError("ResourceHandle.fromReadPipe constructor");
  }

  @patch
  factory ResourceHandle.fromWritePipe(WritePipe pipe) {
    throw UnsupportedError("ResourceHandle.fromWritePipe constructor");
  }
}

@patch
class SecureSocket {
  @patch
  factory SecureSocket._(RawSecureSocket rawSocket) {
    throw UnsupportedError("SecureSocket constructor");
  }
}

@patch
class RawSynchronousSocket {
  @patch
  static RawSynchronousSocket connectSync(dynamic host, int port) {
    throw UnsupportedError("RawSynchronousSocket.connectSync");
  }
}

@patch
class RawSocketOption {
  @patch
  static int _getOptionValue(int key) {
    throw UnsupportedError("RawSocketOption._getOptionValue");
  }
}

@patch
class SecurityContext {
  @patch
  factory SecurityContext({bool withTrustedRoots = false}) {
    throw UnsupportedError("SecurityContext constructor");
  }

  @patch
  static SecurityContext get defaultContext {
    throw UnsupportedError("default SecurityContext getter");
  }

  @patch
  static bool get alpnSupported {
    throw UnsupportedError("SecurityContext alpnSupported getter");
  }
}

@patch
class X509Certificate {
  @patch
  factory X509Certificate._() {
    throw UnsupportedError("X509Certificate constructor");
  }
}

@patch
class RawDatagramSocket {
  @patch
  static Future<RawDatagramSocket> bind(dynamic host, int port,
      {bool reuseAddress = true, bool reusePort = false, int ttl = 1}) {
    throw UnsupportedError("RawDatagramSocket.bind");
  }
}

@patch
class _SecureFilter {
  @patch
  factory _SecureFilter._() {
    throw UnsupportedError("_SecureFilter._SecureFilter");
  }
}

@patch
class _StdIOUtils {
  @patch
  static Stdin _getStdioInputStream(int fd) {
    throw UnsupportedError("StdIOUtils._getStdioInputStream");
  }

  @patch
  static _getStdioOutputStream(int fd) {
    throw UnsupportedError("StdIOUtils._getStdioOutputStream");
  }

  @patch
  static int _socketType(Socket socket) {
    throw UnsupportedError("StdIOUtils._socketType");
  }

  @patch
  static _getStdioHandleType(int fd) {
    throw UnsupportedError("StdIOUtils._getStdioHandleType");
  }
}

@patch
class _WindowsCodePageDecoder {
  @patch
  static String _decodeBytes(List<int> bytes) {
    throw UnsupportedError("_WindowsCodePageDecoder._decodeBytes");
  }
}

@patch
class _WindowsCodePageEncoder {
  @patch
  static List<int> _encodeString(String string) {
    throw UnsupportedError("_WindowsCodePageEncoder._encodeString");
  }
}

@patch
class RawZLibFilter {
  @patch
  static RawZLibFilter _makeZLibDeflateFilter(
      bool gzip,
      int level,
      int windowBits,
      int memLevel,
      int strategy,
      List<int>? dictionary,
      bool raw) {
    throw UnsupportedError("_newZLibDeflateFilter");
  }

  @patch
  static RawZLibFilter _makeZLibInflateFilter(
      bool gzip, int windowBits, List<int>? dictionary, bool raw) {
    throw UnsupportedError("_newZLibInflateFilter");
  }
}

@patch
class Stdin {
  @patch
  int readByteSync() {
    throw UnsupportedError("Stdin.readByteSync");
  }

  @patch
  bool get echoMode {
    throw UnsupportedError("Stdin.echoMode");
  }

  @patch
  void set echoMode(bool enabled) {
    throw UnsupportedError("Stdin.echoMode");
  }

  @patch
  bool get echoNewlineMode {
    throw UnsupportedError("Stdin.echoNewlineMode");
  }

  @patch
  void set echoNewlineMode(bool enabled) {
    throw UnsupportedError("Stdin.echoNewlineMode");
  }

  @patch
  bool get lineMode {
    throw UnsupportedError("Stdin.lineMode");
  }

  @patch
  void set lineMode(bool enabled) {
    throw UnsupportedError("Stdin.lineMode");
  }

  @patch
  bool get supportsAnsiEscapes {
    throw UnsupportedError("Stdin.supportsAnsiEscapes");
  }
}

@patch
class Stdout {
  @patch
  bool _hasTerminal(int fd) {
    throw UnsupportedError("Stdout.hasTerminal");
  }

  @patch
  int _terminalColumns(int fd) {
    throw UnsupportedError("Stdout.terminalColumns");
  }

  @patch
  int _terminalLines(int fd) {
    throw UnsupportedError("Stdout.terminalLines");
  }

  @patch
  static bool _supportsAnsiEscapes(int fd) {
    throw UnsupportedError("Stdout.supportsAnsiEscapes");
  }
}

@patch
class _FileSystemWatcher {
  @patch
  static Stream<FileSystemEvent> _watch(
      String path, int events, bool recursive) {
    throw UnsupportedError("_FileSystemWatcher.watch");
  }

  @patch
  static bool get isSupported {
    throw UnsupportedError("_FileSystemWatcher.isSupported");
  }
}

@patch
class _IOService {
  @patch
  static Future<Object?> _dispatch(int request, List data) {
    throw UnsupportedError("_IOService._dispatch");
  }
}
