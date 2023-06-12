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
package org.dartlang.vm.service.internal;

import com.google.gson.JsonObject;
import de.roderick.weberknecht.WebSocket;
import de.roderick.weberknecht.WebSocketException;
import org.dartlang.vm.service.logging.Logging;

/**
 * An {@link WebSocket} based implementation of {@link RequestSink}.
 */
public class WebSocketRequestSink implements RequestSink {

  private WebSocket webSocket;

  public WebSocketRequestSink(WebSocket webSocket) {
    this.webSocket = webSocket;
  }

  @Override
  public void add(JsonObject json) {
    String request = json.toString();
    if (webSocket == null) {
      Logging.getLogger().logInformation("Dropped: " + request);
      return;
    }
    Logging.getLogger().logInformation("Sent: " + request);
    try {
      webSocket.send(request);
    } catch (WebSocketException e) {
      Logging.getLogger().logError("Failed to send request: " + request, e);
    }
  }

  @Override
  public void close() {
    if (webSocket != null) {
      try {
        webSocket.close();
      } catch (WebSocketException e) {
        Logging.getLogger().logError("Failed to close websocket", e);
      }
      webSocket = null;
    }
  }
}
