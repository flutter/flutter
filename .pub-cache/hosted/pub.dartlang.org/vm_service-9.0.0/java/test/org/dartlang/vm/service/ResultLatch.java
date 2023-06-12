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

/**
 * {@link ResultLatch} is used by one thread to communicate a result to another thread.
 */
public class ResultLatch<T> extends OpLatch {
  private T value;

  public T getValue() {
    waitAndAssertOpComplete();
    return value;
  }

  public void setValue(T value) {
    this.value = value;
    opComplete();
  }
}
