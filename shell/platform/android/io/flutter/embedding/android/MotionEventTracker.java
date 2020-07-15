package io.flutter.embedding.android;

import android.util.LongSparseArray;
import android.view.MotionEvent;
import androidx.annotation.Nullable;
import java.util.PriorityQueue;
import java.util.concurrent.atomic.AtomicLong;

/** Tracks the motion events received by the FlutterView. */
public final class MotionEventTracker {

  /** Represents a unique identifier corresponding to a motion event. */
  public static class MotionEventId {
    private static final AtomicLong ID_COUNTER = new AtomicLong(0);
    private final long id;

    private MotionEventId(long id) {
      this.id = id;
    }

    public static MotionEventId from(long id) {
      return new MotionEventId(id);
    }

    public static MotionEventId createUnique() {
      return MotionEventId.from(ID_COUNTER.incrementAndGet());
    }

    public long getId() {
      return id;
    }
  }

  private final LongSparseArray<MotionEvent> eventById;
  private final PriorityQueue<Long> unusedEvents;
  private static MotionEventTracker INSTANCE;

  public static MotionEventTracker getInstance() {
    if (INSTANCE == null) {
      INSTANCE = new MotionEventTracker();
    }
    return INSTANCE;
  }

  private MotionEventTracker() {
    eventById = new LongSparseArray<>();
    unusedEvents = new PriorityQueue<>();
  }

  /** Tracks the event and returns a unique MotionEventId identifying the event. */
  public MotionEventId track(MotionEvent event) {
    MotionEventId eventId = MotionEventId.createUnique();
    eventById.put(eventId.id, MotionEvent.obtain(event));
    unusedEvents.add(eventId.id);
    return eventId;
  }

  /**
   * Returns the MotionEvent corresponding to the eventId while discarding all the motion events
   * that occured prior to the event represented by the eventId. Returns null if this event was
   * popped or discarded.
   */
  @Nullable
  public MotionEvent pop(MotionEventId eventId) {
    // remove all the older events.
    while (!unusedEvents.isEmpty() && unusedEvents.peek() < eventId.id) {
      eventById.remove(unusedEvents.poll());
    }

    // remove the current event from the heap if it exists.
    if (!unusedEvents.isEmpty() && unusedEvents.peek() == eventId.id) {
      unusedEvents.poll();
    }

    MotionEvent event = eventById.get(eventId.id);
    eventById.remove(eventId.id);
    return event;
  }
}
