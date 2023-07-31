/*
 * Copyright (c) 2017, the Dart project authors.
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

import com.google.gson.JsonObject;

/**
 * Interface used by {@link VmService} to register callbacks to services.
 */
public interface RemoteServiceRunner {
  /**
   * Called when a service request has been received.
   *
   * @param params    the parameters of the request
   * @param completer the completer to invoke at the end of the execution
   */
  void run(JsonObject params, RemoteServiceCompleter completer);
}
