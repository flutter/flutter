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

import org.dartlang.vm.service.consumer.GetInstanceConsumer;
import org.dartlang.vm.service.element.BoundField;
import org.dartlang.vm.service.element.ClassRef;
import org.dartlang.vm.service.element.Instance;
import org.dartlang.vm.service.element.InstanceKind;
import org.dartlang.vm.service.element.InstanceRef;
import org.dartlang.vm.service.element.Isolate;
import org.dartlang.vm.service.element.RPCError;

/**
 * Utility class for converting {@link InstanceRef} to a human readable string.
 */
public class InstanceRefToString {
  private Isolate isolate;
  private final VmService service;
  private final OpLatch masterLatch;

  /**
   * Construct a new instance for converting one or more {@link InstanceRef} to human readable
   * strings. Specify an {@link OpLatch} so that this class can update the expiration time for any
   * waiting thread as it makes {@link VmService} class to obtain details about each
   * {@link InstanceRef}.
   */
  public InstanceRefToString(Isolate isolate, VmService service, OpLatch latch) {
    this.isolate = isolate;
    this.service = service;
    this.masterLatch = latch;
  }

  /**
   * Return a human readable string for the given {@link InstanceRef}.
   */
  public String toString(InstanceRef ref) {
    StringBuilder result = new StringBuilder();
    printInstance(result, ref, 4);
    return result.toString();
  }

  /**
   * Request the instance information from the {@link VmService}.
   * 
   * @param ref the instance reference (not {@code null})
   * @return the instance or {@code null} if there was a problem.
   */
  private Instance getInstance(InstanceRef ref) {

    // Request master latch extend its timeout because we are making another call to VmService
    masterLatch.opWorking();

    final ResultLatch<Instance> instLatch = new ResultLatch<Instance>();
    service.getInstance(isolate.getId(), ref.getId(), new GetInstanceConsumer() {
      @Override
      public void onError(RPCError error) {
        instLatch.setValue(null);
      }

      @Override
      public void received(Instance instance) {
        instLatch.setValue(instance);
      }
    });
    return instLatch.getValue();
  }

  /**
   * Convert the given {@link InstanceRef} into a human readable string.
   * 
   * @param result the buffer to which the human readable string is added
   * @param ref the instance to be converted (not {@code null})
   * @param maxDepth the maximum number of recursions this method can make on itself to determine
   *          human readable strings for child objects
   */
  private void printInstance(StringBuilder result, InstanceRef ref, int maxDepth) {
    if (ref == null) {
      result.append("-- no value --");
      return;
    }
    InstanceKind kind = ref.getKind();
    if (kind == null) {
      result.append("-- unknown instance kind --");
      return;
    }
    switch (kind) {
      case Bool:
      case Double:
      case Float32x4:
      case Float64x2:
      case Int:
      case Int32x4:
      case Null:
      case StackTrace:
        result.append(ref.getValueAsString());
        return;
      case String:
        result.append("'");
        // Should escape chars such as newline before printing
        result.append(ref.getValueAsString());
        if (ref.getValueAsStringIsTruncated()) {
          result.append("...");
        }
        result.append("'");
        return;
      case List:
        printList(result, ref, maxDepth);
        return;
      case PlainInstance:
        printPlainInstance(result, ref, maxDepth);
        return;
      case BoundedType:
      case Closure:
      case Float32List:
      case Float32x4List:
      case Float64List:
      case Float64x2List:
      case Int16List:
      case Int32List:
      case Int32x4List:
      case Int64List:
      case Int8List:
      case Map:
      case MirrorReference:
      case RegExp:
      case Type:
      case TypeParameter:
      case TypeRef:
      case Uint16List:
      case Uint32List:
      case Uint64List:
      case Uint8ClampedList:
      case Uint8List:
      case WeakProperty:
    }
    result.append("a " + kind);
  }

  /**
   * Convert the given list into a human readable string.
   * 
   * @param result the buffer to which the human readable string is added
   * @param ref an instance reference of type "List" (not {@code null})
   * @param maxDepth the maximum number of recursions this method can make on itself to determine
   *          human readable strings for child objects
   */
  private void printList(StringBuilder result, InstanceRef ref, int maxDepth) {
    if (maxDepth == 0) {
      result.append("a List");
      return;
    }
    result.append("[");
    Instance list = getInstance(ref);
    if (list == null) {
      result.append("?error?]");
      return;
    }
    int count = 0;
    for (InstanceRef elem : list.getElements()) {
      if (count > 10) {
        result.append(", ...");
        break;
      }
      if (count > 0) {
        result.append(", ");
      }
      ++count;
      printInstance(result, elem, maxDepth - 1);
    }
    result.append("]");
  }

  /**
   * Convert the given instance into a human readable string.
   * 
   * @param result the buffer to which the human readable string is added
   * @param ref an instance reference of type "PlainInstance" (not {@code null})
   * @param maxDepth the maximum number of recursions this method can make on itself to determine
   *          human readable strings for child objects
   */
  private void printPlainInstance(StringBuilder result, InstanceRef ref, int maxDepth) {
    ClassRef classRef = ref.getClassRef();
    String className = classRef.getName();
    if (maxDepth == 0) {
      result.append("a " + className);
      return;
    }
    result.append(className);
    result.append("(");
    Instance inst = getInstance(ref);
    boolean first = true;
    for (BoundField field : inst.getFields()) {
      if (first) {
        first = false;
      } else {
        result.append(", ");
      }
      printInstance(result, field.getValue(), maxDepth - 1);
    }
    result.append(")");
  }
}
