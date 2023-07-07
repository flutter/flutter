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

/**
 * JSON constants used when communicating with the VM observatory service.
 */
public interface VmServiceConst {
  static final String CODE = "code";
  static final String ERROR = "error";
  static final String EVENT = "event";
  static final String ID = "id";
  static final String MESSAGE = "message";
  static final String METHOD = "method";
  static final String PARAMS = "params";
  static final String RESULT = "result";
  static final String STREAM_ID = "streamId";
  static final String TYPE = "type";
  static final String JSONRPC = "jsonrpc";
  static final String JSONRPC_VERSION = "2.0";
  static final String DATA = "data";

  /**
   * Parse error	Invalid JSON was received by the server.
   * An error occurred on the server while parsing the JSON text.
   */
  static final int PARSE_ERROR = -32700;

  /**
   * Invalid Request	The JSON sent is not a valid Request object.
   */
  static final int INVALID_REQUEST = -32600;

  /**
   * Method not found	The method does not exist / is not available.
   */
  static final int METHOD_NOT_FOUND = -32601;

  /**
   * Invalid params	Invalid method parameter(s).
   */
  static final int INVALID_PARAMS = -32602;

  /**
   * Server error	Reserved for implementation-defined server-errors.
   * -32000 to -32099
   */
  static final int SERVER_ERROR = -32000;
}
