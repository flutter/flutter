// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.videoplayer;

import java.io.IOException;
import java.net.InetAddress;
import java.net.Socket;
import java.security.KeyManagementException;
import java.security.NoSuchAlgorithmException;
import javax.net.ssl.SSLContext;
import javax.net.ssl.SSLSocket;
import javax.net.ssl.SSLSocketFactory;

public class CustomSSLSocketFactory extends SSLSocketFactory {
  private SSLSocketFactory sslSocketFactory;

  public CustomSSLSocketFactory() throws KeyManagementException, NoSuchAlgorithmException {
    SSLContext context = SSLContext.getInstance("TLS");
    context.init(null, null, null);
    sslSocketFactory = context.getSocketFactory();
  }

  @Override
  public String[] getDefaultCipherSuites() {
    return sslSocketFactory.getDefaultCipherSuites();
  }

  @Override
  public String[] getSupportedCipherSuites() {
    return sslSocketFactory.getSupportedCipherSuites();
  }

  @Override
  public Socket createSocket() throws IOException {
    return enableProtocols(sslSocketFactory.createSocket());
  }

  @Override
  public Socket createSocket(Socket s, String host, int port, boolean autoClose)
      throws IOException {
    return enableProtocols(sslSocketFactory.createSocket(s, host, port, autoClose));
  }

  @Override
  public Socket createSocket(String host, int port) throws IOException {
    return enableProtocols(sslSocketFactory.createSocket(host, port));
  }

  @Override
  public Socket createSocket(String host, int port, InetAddress localHost, int localPort)
      throws IOException {
    return enableProtocols(sslSocketFactory.createSocket(host, port, localHost, localPort));
  }

  @Override
  public Socket createSocket(InetAddress host, int port) throws IOException {
    return enableProtocols(sslSocketFactory.createSocket(host, port));
  }

  @Override
  public Socket createSocket(InetAddress address, int port, InetAddress localAddress, int localPort)
      throws IOException {
    return enableProtocols(sslSocketFactory.createSocket(address, port, localAddress, localPort));
  }

  private Socket enableProtocols(Socket socket) {
    if (socket instanceof SSLSocket) {
      ((SSLSocket) socket).setEnabledProtocols(new String[] {"TLSv1.1", "TLSv1.2"});
    }
    return socket;
  }
}
