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

import org.dartlang.vm.service.element.Event;
import org.dartlang.vm.service.element.EventKind;

import java.util.Set;

/**
 * Sample VmListener for responding to state changes in the running application
 */
public class SampleVmServiceListener implements VmServiceListener {
  private final Object lock = new Object();
  private String lastStreamId;
  private Event lastEvent;
  private final Set<EventKind> ignoreAll;

  SampleVmServiceListener(Set<EventKind> ignoreAll) {
    this.ignoreAll = ignoreAll;
  }

  @Override
  public void connectionOpened() {

  }

  @Override
  public void received(String streamId, Event event) {
    synchronized (lock) {
      if (ignoreAll.contains(event.getKind())) {
        return;
      }
      if (lastStreamId != null) {
        unexpectedEvent(lastStreamId, lastEvent);
      }
      lastStreamId = streamId;
      lastEvent = event;
      lock.notifyAll();
    }
  }

  @Override
  public void connectionClosed() {

  }

  public Event waitFor(String expectedStreamId, EventKind expectedEventKind) {
    long end = System.currentTimeMillis() + 5000;
    synchronized (lock) {
      while (true) {
        if (expectedStreamId.equals(lastStreamId) && expectedEventKind.equals(lastEvent.getKind())) {
          Event event = lastEvent;
          lastStreamId = null;
          lastEvent = null;
          return event;
        }
        long timeout = end - System.currentTimeMillis();
        if (timeout <= 0) {
          break;
        }
        try {
          lock.wait(timeout);
        } catch (InterruptedException e) {
          // ignored
        }
      }
    }
    throw new RuntimeException("Expected event: " + expectedStreamId + ", " + expectedEventKind);
  }

  private void unexpectedEvent(String streamId, Event event) {
    System.out.println("****** Unexpected Event: " + streamId + ", " + event.getKind());
  }
}
