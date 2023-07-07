/*
 * Copyright (c) 2012, the Dart project authors.
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
package org.dartlang.vm.service.logging;

/**
 * The interface {@code Logger} defines the behavior of objects that can be used to receive
 * information about errors. Implementations usually write this information to a file, but can also
 * record the information for later use (such as during testing) or even ignore the information.
 */
public interface Logger {

  /**
   * Implementation of {@link Logger} that does nothing.
   */
  class NullLogger implements Logger {
    @Override
    public void logError(String message) {
    }

    @Override
    public void logError(String message, Throwable exception) {
    }

    @Override
    public void logInformation(String message) {
    }

    @Override
    public void logInformation(String message, Throwable exception) {
    }
  }

  static final Logger NULL = new NullLogger();

  /**
   * Log the given message as an error.
   *
   * @param message an explanation of why the error occurred or what it means
   */
  void logError(String message);

  /**
   * Log the given exception as one representing an error.
   *
   * @param message   an explanation of why the error occurred or what it means
   * @param exception the exception being logged
   */
  void logError(String message, Throwable exception);

  /**
   * Log the given informational message.
   *
   * @param message an explanation of why the error occurred or what it means
   */
  void logInformation(String message);

  /**
   * Log the given exception as one representing an informational message.
   *
   * @param message   an explanation of why the error occurred or what it means
   * @param exception the exception being logged
   */
  void logInformation(String message, Throwable exception);
}
