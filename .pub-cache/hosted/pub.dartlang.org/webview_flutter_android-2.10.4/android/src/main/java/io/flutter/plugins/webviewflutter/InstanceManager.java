// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.webviewflutter;

import android.os.Handler;
import android.os.Looper;
import androidx.annotation.Nullable;
import java.lang.ref.ReferenceQueue;
import java.lang.ref.WeakReference;
import java.util.HashMap;
import java.util.WeakHashMap;

/**
 * Maintains instances used to communicate with the corresponding objects in Dart.
 *
 * <p>Objects stored in this container are represented by an object in Dart that is also stored in
 * an InstanceManager with the same identifier.
 *
 * <p>When an instance is added with an identifier, either can be used to retrieve the other.
 *
 * <p>Added instances are added as a weak reference and a strong reference. When the strong
 * reference is removed with `{@link #remove(long)}` and the weak reference is deallocated, the
 * `finalizationListener` is made with the instance's identifier. However, if the strong reference
 * is removed and then the identifier is retrieved with the intention to pass the identifier to Dart
 * (e.g. calling {@link #getIdentifierForStrongReference(Object)}), the strong reference to the
 * instance is recreated. The strong reference will then need to be removed manually again.
 */
@SuppressWarnings("unchecked")
public class InstanceManager {
  // Identifiers are locked to a specific range to avoid collisions with objects
  // created simultaneously from Dart.
  // Host uses identifiers >= 2^16 and Dart is expected to use values n where,
  // 0 <= n < 2^16.
  private static final long MIN_HOST_CREATED_IDENTIFIER = 65536;
  private static final long CLEAR_FINALIZED_WEAK_REFERENCES_INTERVAL = 30000;

  /** Interface for listening when a weak reference of an instance is removed from the manager. */
  public interface FinalizationListener {
    void onFinalize(long identifier);
  }

  private final WeakHashMap<Object, Long> identifiers = new WeakHashMap<>();
  private final HashMap<Long, WeakReference<Object>> weakInstances = new HashMap<>();
  private final HashMap<Long, Object> strongInstances = new HashMap<>();

  private final ReferenceQueue<Object> referenceQueue = new ReferenceQueue<>();
  private final HashMap<WeakReference<Object>, Long> weakReferencesToIdentifiers = new HashMap<>();

  private final Handler handler = new Handler(Looper.getMainLooper());

  private final FinalizationListener finalizationListener;

  private long nextIdentifier = MIN_HOST_CREATED_IDENTIFIER;
  private boolean isClosed = false;

  /**
   * Instantiate a new manager.
   *
   * <p>When the manager is no longer needed, {@link #close()} must be called.
   *
   * @param finalizationListener the listener for garbage collected weak references.
   * @return a new `InstanceManager`.
   */
  public static InstanceManager open(FinalizationListener finalizationListener) {
    return new InstanceManager(finalizationListener);
  }

  private InstanceManager(FinalizationListener finalizationListener) {
    this.finalizationListener = finalizationListener;
    handler.postDelayed(
        this::releaseAllFinalizedInstances, CLEAR_FINALIZED_WEAK_REFERENCES_INTERVAL);
  }

  /**
   * Removes `identifier` and its associated strongly referenced instance, if present, from the
   * manager.
   *
   * @param identifier the identifier paired to an instance.
   * @param <T> the expected return type.
   * @return the removed instance if the manager contains the given identifier, otherwise null.
   */
  @Nullable
  public <T> T remove(long identifier) {
    assertManagerIsNotClosed();
    return (T) strongInstances.remove(identifier);
  }

  /**
   * Retrieves the identifier paired with an instance.
   *
   * <p>If the manager contains `instance`, as a strong or weak reference, the strong reference to
   * `instance` will be recreated and will need to be removed again with {@link #remove(long)}.
   *
   * @param instance an instance that may be stored in the manager.
   * @return the identifier associated with `instance` if the manager contains the value, otherwise
   *     null.
   */
  @Nullable
  public Long getIdentifierForStrongReference(Object instance) {
    assertManagerIsNotClosed();
    final Long identifier = identifiers.get(instance);
    if (identifier != null) {
      strongInstances.put(identifier, instance);
    }
    return identifier;
  }

  /**
   * Adds a new instance that was instantiated from Dart.
   *
   * <p>If an instance or identifier has already been added, it will be replaced by the new values.
   * The Dart InstanceManager is considered the source of truth and has the capability to overwrite
   * stored pairs in response to hot restarts.
   *
   * @param instance the instance to be stored.
   * @param identifier the identifier to be paired with instance. This value must be >= 0.
   */
  public void addDartCreatedInstance(Object instance, long identifier) {
    assertManagerIsNotClosed();
    addInstance(instance, identifier);
  }

  /**
   * Adds a new instance that was instantiated from the host platform.
   *
   * @param instance the instance to be stored.
   * @return the unique identifier stored with instance.
   */
  public long addHostCreatedInstance(Object instance) {
    assertManagerIsNotClosed();
    final long identifier = nextIdentifier++;
    addInstance(instance, identifier);
    return identifier;
  }

  /**
   * Retrieves the instance associated with identifier.
   *
   * @param identifier the identifier paired to an instance.
   * @param <T> the expected return type.
   * @return the instance associated with `identifier` if the manager contains the value, otherwise
   *     null.
   */
  @Nullable
  public <T> T getInstance(long identifier) {
    assertManagerIsNotClosed();
    final WeakReference<T> instance = (WeakReference<T>) weakInstances.get(identifier);
    if (instance != null) {
      return instance.get();
    }
    return (T) strongInstances.get(identifier);
  }

  /**
   * Returns whether this manager contains the given `instance`.
   *
   * @param instance the instance whose presence in this manager is to be tested.
   * @return whether this manager contains the given `instance`.
   */
  public boolean containsInstance(Object instance) {
    assertManagerIsNotClosed();
    return identifiers.containsKey(instance);
  }

  /**
   * Closes the manager and releases resources.
   *
   * <p>Calling a method after calling this one will throw an {@link AssertionError}. This method
   * excluded.
   */
  public void close() {
    handler.removeCallbacks(this::releaseAllFinalizedInstances);
    isClosed = true;
  }

  private void releaseAllFinalizedInstances() {
    WeakReference<Object> reference;
    while ((reference = (WeakReference<Object>) referenceQueue.poll()) != null) {
      final Long identifier = weakReferencesToIdentifiers.remove(reference);
      if (identifier != null) {
        weakInstances.remove(identifier);
        strongInstances.remove(identifier);
        finalizationListener.onFinalize(identifier);
      }
    }
    handler.postDelayed(
        this::releaseAllFinalizedInstances, CLEAR_FINALIZED_WEAK_REFERENCES_INTERVAL);
  }

  private void addInstance(Object instance, long identifier) {
    if (identifier < 0) {
      throw new IllegalArgumentException("Identifier must be >= 0.");
    }
    final WeakReference<Object> weakReference = new WeakReference<>(instance, referenceQueue);
    identifiers.put(instance, identifier);
    weakInstances.put(identifier, weakReference);
    weakReferencesToIdentifiers.put(weakReference, identifier);
    strongInstances.put(identifier, instance);
  }

  private void assertManagerIsNotClosed() {
    if (isClosed) {
      throw new AssertionError("Manager has already been closed.");
    }
  }
}
