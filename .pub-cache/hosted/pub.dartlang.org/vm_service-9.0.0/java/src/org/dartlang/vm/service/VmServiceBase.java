/*
 * Copyright (c) 2015, the Dart project authors.
 *
 * Licensed under the Eclipse Public License v1.0 (the "License"); you may not use this file except
 * in compliance with the License. You may obtain a copy of the License at
 *
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Unless required by applicable law or agreed to in writing, software distributed under the License
 * is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
 * or implied. See the License for the specific language governing permissions and limitations under
 * the License.
 */
package org.dartlang.vm.service;

import com.google.common.collect.Maps;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import de.roderick.weberknecht.WebSocket;
import de.roderick.weberknecht.WebSocketEventHandler;
import de.roderick.weberknecht.WebSocketException;
import de.roderick.weberknecht.WebSocketMessage;
import org.dartlang.vm.service.consumer.*;
import org.dartlang.vm.service.element.*;
import org.dartlang.vm.service.internal.RequestSink;
import org.dartlang.vm.service.internal.VmServiceConst;
import org.dartlang.vm.service.internal.WebSocketRequestSink;
import org.dartlang.vm.service.logging.Logging;

import java.io.IOException;
import java.net.URI;
import java.net.URISyntaxException;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * Internal {@link VmService} base class containing non-generated code.
 */
@SuppressWarnings({"unused", "WeakerAccess"})
abstract class VmServiceBase implements VmServiceConst {
  /**
   * Connect to the VM observatory service via the specified URI
   *
   * @return an API object for interacting with the VM service (not {@code null}).
   */
  public static VmService connect(final String url) throws IOException {
    // Validate URL
    URI uri;
    try {
      uri = new URI(url);
    } catch (URISyntaxException e) {
      throw new IOException("Invalid URL: " + url, e);
    }
    String wsScheme = uri.getScheme();
    if (!"ws".equals(wsScheme) && !"wss".equals(wsScheme)) {
      throw new IOException("Unsupported URL scheme: " + wsScheme);
    }

    // Create web socket and observatory
    WebSocket webSocket;
    try {
      webSocket = new WebSocket(uri);
    } catch (WebSocketException e) {
      throw new IOException("Failed to create websocket: " + url, e);
    }
    final VmService vmService = new VmService();

    // Setup event handler for forwarding responses
    webSocket.setEventHandler(new WebSocketEventHandler() {
      @Override
      public void onClose() {
        Logging.getLogger().logInformation("VM connection closed: " + url);

        vmService.connectionClosed();
      }

      @Override
      public void onMessage(WebSocketMessage message) {
        Logging.getLogger().logInformation("VM message: " + message.getText());
        try {
          vmService.processMessage(message.getText());
        } catch (Exception e) {
          Logging.getLogger().logError(e.getMessage(), e);
        }
      }

      @Override
      public void onOpen() {
        vmService.connectionOpened();

        Logging.getLogger().logInformation("VM connection open: " + url);
      }

      @Override
      public void onPing() {
      }

      @Override
      public void onPong() {
      }
    });

    // Establish WebSocket Connection
    //noinspection TryWithIdenticalCatches
    try {
      webSocket.connect();
    } catch (WebSocketException e) {
      throw new IOException("Failed to connect: " + url, e);
    } catch (ArrayIndexOutOfBoundsException e) {
      // The weberknecht can occasionally throw an array index exception if a connect terminates on initial connect
      // (de.roderick.weberknecht.WebSocket.connect, WebSocket.java:126).
      throw new IOException("Failed to connect: " + url, e);
    }
    vmService.requestSink = new WebSocketRequestSink(webSocket);

    // Check protocol version
    final CountDownLatch latch = new CountDownLatch(1);
    final String[] errMsg = new String[1];
    vmService.getVersion(new VersionConsumer() {
      @Override
      public void onError(RPCError error) {
        String msg = "Failed to determine protocol version: " + error.getCode() + "\n  message: "
            + error.getMessage() + "\n  details: " + error.getDetails();
        Logging.getLogger().logInformation(msg);
        errMsg[0] = msg;
      }

      @Override
      public void received(Version version) {
        vmService.runtimeVersion = version;

        latch.countDown();
      }
    });

    try {
      if (!latch.await(5, TimeUnit.SECONDS)) {
        throw new IOException("Failed to determine protocol version");
      }
      if (errMsg[0] != null) {
        throw new IOException(errMsg[0]);
      }
    } catch (InterruptedException e) {
      throw new RuntimeException("Interrupted while waiting for response", e);
    }

    return vmService;
  }

  /**
   * Connect to the VM observatory service on the given local port.
   *
   * @return an API object for interacting with the VM service (not {@code null}).
   *
   * @deprecated prefer the Url based constructor {@link VmServiceBase#connect}
   */
  @Deprecated
  public static VmService localConnect(int port) throws IOException {
    return connect("ws://localhost:" + port + "/ws");
  }

  /**
   * A mapping between {@link String} ids' and the associated {@link Consumer} that was passed when
   * the request was made. Synchronize against {@link #consumerMapLock} before accessing this field.
   */
  private final Map<String, Consumer> consumerMap = Maps.newHashMap();

  /**
   * The object used to synchronize access to {@link #consumerMap}.
   */
  private final Object consumerMapLock = new Object();

  /**
   * The unique ID for the next request.
   */
  private final AtomicInteger nextId = new AtomicInteger();

  /**
   * A list of objects to which {@link Event}s from the VM are forwarded.
   */
  private final List<VmServiceListener> vmListeners = new ArrayList<>();

  /**
   * A list of objects to which {@link Event}s from the VM are forwarded.
   */
  private final Map<String, RemoteServiceRunner> remoteServiceRunners = Maps.newHashMap();

  /**
   * The channel through which observatory requests are made.
   */
  RequestSink requestSink;

  Version runtimeVersion;

  /**
   * Add a listener to receive {@link Event}s from the VM.
   */
  public void addVmServiceListener(VmServiceListener listener) {
    vmListeners.add(listener);
  }

  /**
   * Remove the given listener from the VM.
   */
  public void removeVmServiceListener(VmServiceListener listener) {
    vmListeners.remove(listener);
  }

  /**
   * Add a VM RemoteServiceRunner.
   */
  public void addServiceRunner(String service, RemoteServiceRunner runner) {
    remoteServiceRunners.put(service, runner);
  }

  /**
   * Remove a VM RemoteServiceRunner.
   */
  public void removeServiceRunner(String service) {
    remoteServiceRunners.remove(service);
  }

  /**
   * Return the VM service protocol version supported by the current debug connection.
   */
  public Version getRuntimeVersion() {
    return runtimeVersion;
  }

  /**
   * Disconnect from the VM observatory service.
   */
  public void disconnect() {
    requestSink.close();
  }

  /**
   * Return the instance with the given identifier.
   */
  public void getInstance(String isolateId, String instanceId, final GetInstanceConsumer consumer) {
    getObject(isolateId, instanceId, new GetObjectConsumer() {

      @Override
      public void onError(RPCError error) {
        consumer.onError(error);
      }

      @Override
      public void received(Obj response) {
        if (response instanceof Instance) {
          consumer.received((Instance) response);
        } else {
          onError(RPCError.unexpected("Instance", response));
        }
      }

      @Override
      public void received(Sentinel response) {
        onError(RPCError.unexpected("Instance", response));
      }
    });
  }

  /**
   * Return the library with the given identifier.
   */
  public void getLibrary(String isolateId, String libraryId, final GetLibraryConsumer consumer) {
    getObject(isolateId, libraryId, new GetObjectConsumer() {

      @Override
      public void onError(RPCError error) {
        consumer.onError(error);
      }

      @Override
      public void received(Obj response) {
        if (response instanceof Library) {
          consumer.received((Library) response);
        } else {
          onError(RPCError.unexpected("Library", response));
        }
      }

      @Override
      public void received(Sentinel response) {
        onError(RPCError.unexpected("Library", response));
      }
    });
  }

  public abstract void getObject(String isolateId, String objectId, GetObjectConsumer consumer);

  /**
   * Invoke a specific service protocol extension method.
   * <p>
   * See https://api.dart.dev/stable/dart-developer/dart-developer-library.html.
   */
  public void callServiceExtension(String isolateId, String method, ServiceExtensionConsumer consumer) {
    JsonObject params = new JsonObject();
    params.addProperty("isolateId", isolateId);
    request(method, params, consumer);
  }

  /**
   * Invoke a specific service protocol extension method.
   * <p>
   * See https://api.dart.dev/stable/dart-developer/dart-developer-library.html.
   */
  public void callServiceExtension(String isolateId, String method, JsonObject params, ServiceExtensionConsumer consumer) {
    params.addProperty("isolateId", isolateId);
    request(method, params, consumer);
  }

  /**
   * Sends the request and associates the request with the passed {@link Consumer}.
   */
  protected void request(String method, JsonObject params, Consumer consumer) {

    // Assemble the request
    String id = Integer.toString(nextId.incrementAndGet());
    JsonObject request = new JsonObject();

    request.addProperty(JSONRPC, JSONRPC_VERSION);
    request.addProperty(ID, id);
    request.addProperty(METHOD, method);
    request.add(PARAMS, params);

    // Cache the consumer to receive the response
    synchronized (consumerMapLock) {
      consumerMap.put(id, consumer);
    }

    // Send the request
    requestSink.add(request);
  }

  public void connectionOpened() {
    for (VmServiceListener listener : new ArrayList<>(vmListeners)) {
      try {
        listener.connectionOpened();
      } catch (Exception e) {
        Logging.getLogger().logError("Exception notifying listener", e);
      }
    }
  }

  private void forwardEvent(String streamId, Event event) {
    for (VmServiceListener listener : new ArrayList<>(vmListeners)) {
      try {
        listener.received(streamId, event);
      } catch (Exception e) {
        Logging.getLogger().logError("Exception processing event: " + streamId + ", " + event.getJson(), e);
      }
    }
  }

  public void connectionClosed() {
    for (VmServiceListener listener : new ArrayList<>(vmListeners)) {
      try {
        listener.connectionClosed();
      } catch (Exception e) {
        Logging.getLogger().logError("Exception notifying listener", e);
      }
    }
  }

  abstract void forwardResponse(Consumer consumer, String type, JsonObject json);

  void logUnknownResponse(Consumer consumer, JsonObject json) {
    Class<? extends Consumer> consumerClass = consumer.getClass();
    StringBuilder msg = new StringBuilder();
    msg.append("Expected response for ").append(consumerClass).append("\n");
    for (Class<?> interf : consumerClass.getInterfaces()) {
      msg.append("  implementing ").append(interf).append("\n");
    }
    msg.append("  but received ").append(json);
    Logging.getLogger().logError(msg.toString());
  }

  /**
   * Process the response from the VM service and forward that response to the consumer associated
   * with the response id.
   */
  void processMessage(String jsonText) {
    if (jsonText == null || jsonText.isEmpty()) {
      return;
    }

    // Decode the JSON
    JsonObject json;
    try {
      json = (JsonObject) new JsonParser().parse(jsonText);
    } catch (Exception e) {
      Logging.getLogger().logError("Parse message failed: " + jsonText, e);
      return;
    }

    if (json.has("method")) {
      if (!json.has(PARAMS)) {
        final String message = "Missing " + PARAMS;
        Logging.getLogger().logError(message);
        final JsonObject response = new JsonObject();
        response.addProperty(JSONRPC, JSONRPC_VERSION);
        final JsonObject error = new JsonObject();
        error.addProperty(CODE, INVALID_REQUEST);
        error.addProperty(MESSAGE, message);
        response.add(ERROR, error);
        requestSink.add(response);
        return;
      }
      if (json.has("id")) {
        processRequest(json);
      } else {
        processNotification(json);
      }
    } else if (json.has("result") || json.has("error")) {
      processResponse(json);
    } else {
      Logging.getLogger().logError("Malformed message");
    }
  }

  void processRequest(JsonObject json) {
    final JsonObject response = new JsonObject();
    response.addProperty(JSONRPC, JSONRPC_VERSION);

    // Get the consumer associated with this request
    String id;
    try {
      id = json.get(ID).getAsString();
    } catch (Exception e) {
      final String message = "Request malformed " + ID;
      Logging.getLogger().logError(message, e);
      final JsonObject error = new JsonObject();
      error.addProperty(CODE, INVALID_REQUEST);
      error.addProperty(MESSAGE, message);
      response.add(ERROR, error);
      requestSink.add(response);
      return;
    }

    response.addProperty(ID, id);

    String method;
    try {
      method = json.get(METHOD).getAsString();
    } catch (Exception e) {
      final String message = "Request malformed " + METHOD;
      Logging.getLogger().logError(message, e);
      final JsonObject error = new JsonObject();
      error.addProperty(CODE, INVALID_REQUEST);
      error.addProperty(MESSAGE, message);
      response.add(ERROR, error);
      requestSink.add(response);
      return;
    }

    JsonObject params;
    try {
      params = json.get(PARAMS).getAsJsonObject();
    } catch (Exception e) {
      final String message = "Request malformed " + METHOD;
      Logging.getLogger().logError(message, e);
      final JsonObject error = new JsonObject();
      error.addProperty(CODE, INVALID_REQUEST);
      error.addProperty(MESSAGE, message);
      response.add(ERROR, error);
      requestSink.add(response);
      return;
    }

    if (!remoteServiceRunners.containsKey(method)) {
      final String message = "Unknown service " + method;
      Logging.getLogger().logError(message);
      final JsonObject error = new JsonObject();
      error.addProperty(CODE, METHOD_NOT_FOUND);
      error.addProperty(MESSAGE, message);
      response.add(ERROR, error);
      requestSink.add(response);
      return;
    }

    final RemoteServiceRunner runner = remoteServiceRunners.get(method);
    try {
      runner.run(params, new RemoteServiceCompleter() {
        public void result(JsonObject result) {
          response.add(RESULT, result);
          requestSink.add(response);
        }

        public void error(int code, String message, JsonObject data) {
          final JsonObject error = new JsonObject();
          error.addProperty(CODE, code);
          error.addProperty(MESSAGE, message);
          if (data != null) {
            error.add(DATA, data);
          }
          response.add(ERROR, error);
          requestSink.add(response);
        }
      });
    } catch (Exception e) {
      final String message = "Internal Server Error";
      Logging.getLogger().logError(message, e);
      final JsonObject error = new JsonObject();
      error.addProperty(CODE, SERVER_ERROR);
      error.addProperty(MESSAGE, message);
      response.add(ERROR, error);
      requestSink.add(response);
    }
  }

  private static final RemoteServiceCompleter ignoreCallback =
      new RemoteServiceCompleter() {
        public void result(JsonObject result) {
          // ignore
        }

        public void error(int code, String message, JsonObject data) {
          // ignore
        }
      };

  void processNotification(JsonObject json) {
    String method;
    try {
      method = json.get(METHOD).getAsString();
    } catch (Exception e) {
      Logging.getLogger().logError("Request malformed " + METHOD, e);
      return;
    }
    JsonObject params;
    try {
      params = json.get(PARAMS).getAsJsonObject();
    } catch (Exception e) {
      Logging.getLogger().logError("Event missing " + PARAMS, e);
      return;
    }
    if ("streamNotify".equals(method)) {
      String streamId;
      try {
        streamId = params.get(STREAM_ID).getAsString();
      } catch (Exception e) {
        Logging.getLogger().logError("Event missing " + STREAM_ID, e);
        return;
      }
      Event event;
      try {
        event = new Event(params.get(EVENT).getAsJsonObject());
      } catch (Exception e) {
        Logging.getLogger().logError("Event missing " + EVENT, e);
        return;
      }
      forwardEvent(streamId, event);
    } else {
      if (!remoteServiceRunners.containsKey(method)) {
        Logging.getLogger().logError("Unknown service " + method);
        return;
      }

      final RemoteServiceRunner runner = remoteServiceRunners.get(method);
      try {
        runner.run(params, ignoreCallback);
      } catch (Exception e) {
        Logging.getLogger().logError("Internal Server Error", e);
      }
    }
  }

  protected String removeNewLines(String str) {
    return str.replaceAll("\r\n", " ").replaceAll("\n", " ");
  }

  void processResponse(JsonObject json) {
    JsonElement idElem = json.get(ID);
    if (idElem == null) {
      Logging.getLogger().logError("Response missing " + ID);
      return;
    }

    // Get the consumer associated with this response
    String id;
    try {
      id = idElem.getAsString();
    } catch (Exception e) {
      Logging.getLogger().logError("Response missing " + ID, e);
      return;
    }
    Consumer consumer = consumerMap.remove(id);
    if (consumer == null) {
      Logging.getLogger().logError("No consumer associated with " + ID + ": " + id);
      return;
    }

    // Forward the response if the request was successfully executed
    JsonElement resultElem = json.get(RESULT);
    if (resultElem != null) {
      JsonObject result;
      try {
        result = resultElem.getAsJsonObject();
      } catch (Exception e) {
        Logging.getLogger().logError("Response has invalid " + RESULT, e);
        return;
      }
      String responseType = "";
      if (result.has(TYPE)) {
        responseType = result.get(TYPE).getAsString();
      }
      // ServiceExtensionConsumers do not care about the response type.
      else if (!(consumer instanceof ServiceExtensionConsumer)) {
        Logging.getLogger().logError("Response missing " + TYPE + ": " + result.toString());
        return;
      }
      forwardResponse(consumer, responseType, result);
      return;
    }

    // Forward an error if the request failed
    resultElem = json.get(ERROR);
    if (resultElem != null) {
      JsonObject error;
      try {
        error = resultElem.getAsJsonObject();
      } catch (Exception e) {
        Logging.getLogger().logError("Response has invalid " + RESULT, e);
        return;
      }
      consumer.onError(new RPCError(error));
      return;
    }

    Logging.getLogger().logError("Response missing " + RESULT + " and " + ERROR);
  }
}
