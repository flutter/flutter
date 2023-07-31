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

import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;

/**
 * {@link OpLatch} is used by one thread to wait for another thread to complete (see
 * {@link OpLatch#waitOpComplete()} and {@link OpLatch#waitAndAssertOpComplete()}). If the operation
 * does not complete before the expiration time then {@link OpLatch#waitOpComplete()} returns
 * {@code false} and {@link OpLatch#waitAndAssertOpComplete()} throws an exception.
 */
class OpLatch {
  final CountDownLatch latch = new CountDownLatch(1);
  private long endTime;

  /**
   * Set or increase the time after which the operation is considered failed. This is automatically
   * called by {@link #waitAndAssertOp()} and {@link #waitOpComplete()}.
   */
  public void opWorking() {
    endTime = System.currentTimeMillis() + 5000;
  }

  /**
   * Call to indicate that the operation completed successfully.
   */
  void opComplete() {
    latch.countDown();
  }

  /**
   * Wait for the operation to complete or the time limit to expire. Periodically call
   * {@link #opWorking()} to increase the expiration time. Throw a {@link RuntimeException} if the
   * operation did not complete before the expiration time.
   */
  void waitAndAssertOpComplete() {
    if (!waitOpComplete()) {
      System.out.println(">>> No response received");
      throw new RuntimeException("No response received");
    }
  }

  /**
   * Wait for the operation to complete or the time limit to expire. Periodically call
   * {@link #opWorking()} to increase the expiration time.
   * 
   * @return {@code true} if the operation completed, or {@code false} otherwise
   */
  boolean waitOpComplete() {
    opWorking();
    while (true) {
      long waitTimeMillis = endTime - System.currentTimeMillis();
      if (waitTimeMillis <= 0) {
        return latch.getCount() == 0;
      }
      try {
        if (latch.await(waitTimeMillis, TimeUnit.MILLISECONDS)) {
          return true;
        }
      } catch (InterruptedException e) {
        // ignore and loop to check if timeout has changed
      }
    }
  }
}
