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
package org.dartlang.vm.service.element;

import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import org.dartlang.vm.service.internal.VmServiceConst;

/**
 * When an RPC encounters an error, it is provided in the _error_ property of the response object.
 * JSON-RPC errors always provide _code_, _message_, and _data_ properties. <br/>
 * Here is an example error response for our [streamListen](#streamlisten) request above. This error
 * would be generated if we were attempting to subscribe to the _GC_ stream multiple times from the
 * same client.
 *
 * <pre>
 * {
 *   "jsonrpc": "2.0",
 *   "error": {
 *     "code": 103,
 *     "message": "Stream already subscribed",
 *     "data": {
 *       "details": "The stream 'GC' is already subscribed"
 *     }
 *   }
 *   "id": "2"
 * }
 * </pre>
 * <p>
 * In addition the [error codes](http://www.jsonrpc.org/specification#error_object) specified in
 * the JSON-RPC spec, we use the following application specific error codes:
 *
 * <pre>
 * code | message | meaning
 * ---- | ------- | -------
 * 100 | Feature is disabled | The operation is unable to complete because a feature is disabled
 * 101 | VM must be paused | This operation is only valid when the VM is paused
 * 102 | Cannot add breakpoint | The VM is unable to add a breakpoint at the specified line or function
 * 103 | Stream already subscribed | The client is already subscribed to the specified _streamId_
 * 104 | Stream not subscribed | The client is not subscribed to the specified _streamId_
 * </pre>
 */
public class RPCError extends Element implements VmServiceConst {

  /**
   * The response code used by the client when it receives a response from the server that it did
   * not expect. For example, it requested a library element but received a list.
   */
  public static final int UNEXPECTED_RESPONSE = 5;

  public static RPCError unexpected(String expectedType, Response response) {
    String errMsg = "Expected type " + expectedType + " but received " + response.getType();
    if (response instanceof Sentinel) {
      errMsg += ": " + ((Sentinel) response).getKind();
    }
    JsonObject json = new JsonObject();
    json.addProperty("code", UNEXPECTED_RESPONSE);
    json.addProperty("message", errMsg);
    JsonObject data = new JsonObject();
    data.addProperty("details", errMsg);
    data.add("response", response.getJson());
    json.add("data", data);
    return new RPCError(json);
  }

  public RPCError(JsonObject json) {
    super(json);
  }

  public int getCode() {
    return json.get("code").getAsInt();
  }

  public String getDetails() {
    JsonElement data = json.get("data");
    if (data instanceof JsonObject) {
      JsonElement details = ((JsonObject) data).get("details");
      if (details != null) {
        return details.getAsString();
      }
    }
    return null;
  }

  public String getMessage() {
    return json.get("message").getAsString();
  }

  public JsonObject getRequest() {
    JsonElement data = json.get("data");
    if (data instanceof JsonObject) {
      JsonElement request = ((JsonObject) data).get("request");
      if (request instanceof JsonObject) {
        return (JsonObject) request;
      }
    }
    return null;
  }
}
