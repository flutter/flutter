// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.base;

import android.app.Activity;
import android.app.Application;
import android.app.Application.ActivityLifecycleCallbacks;
import android.content.Context;
import android.os.Bundle;

import java.lang.ref.WeakReference;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Provides information about the current activity's status, and a way
 * to register / unregister listeners for state changes.
 */
@JNINamespace("base::android")
public class ApplicationStatus {
    private static class ActivityInfo {
        private int mStatus = ActivityState.DESTROYED;
        private ObserverList<ActivityStateListener> mListeners =
                new ObserverList<ActivityStateListener>();

        /**
         * @return The current {@link ActivityState} of the activity.
         */
        public int getStatus() {
            return mStatus;
        }

        /**
         * @param status The new {@link ActivityState} of the activity.
         */
        public void setStatus(int status) {
            mStatus = status;
        }

        /**
         * @return A list of {@link ActivityStateListener}s listening to this activity.
         */
        public ObserverList<ActivityStateListener> getListeners() {
            return mListeners;
        }
    }

    private static Application sApplication;

    private static Object sCachedApplicationStateLock = new Object();
    private static Integer sCachedApplicationState;

    /** Last activity that was shown (or null if none or it was destroyed). */
    private static Activity sActivity;

    /** A lazily initialized listener that forwards application state changes to native. */
    private static ApplicationStateListener sNativeApplicationStateListener;

    /**
     * A map of which observers listen to state changes from which {@link Activity}.
     */
    private static final Map<Activity, ActivityInfo> sActivityInfo =
            new ConcurrentHashMap<Activity, ActivityInfo>();

    /**
     * A list of observers to be notified when any {@link Activity} has a state change.
     */
    private static final ObserverList<ActivityStateListener> sGeneralActivityStateListeners =
            new ObserverList<ActivityStateListener>();

    /**
     * A list of observers to be notified when the visibility state of this {@link Application}
     * changes.  See {@link #getStateForApplication()}.
     */
    private static final ObserverList<ApplicationStateListener> sApplicationStateListeners =
            new ObserverList<ApplicationStateListener>();

    /**
     * Interface to be implemented by listeners.
     */
    public interface ApplicationStateListener {
        /**
         * Called when the application's state changes.
         * @param newState The application state.
         */
        public void onApplicationStateChange(int newState);
    }

    /**
     * Interface to be implemented by listeners.
     */
    public interface ActivityStateListener {
        /**
         * Called when the activity's state changes.
         * @param activity The activity that had a state change.
         * @param newState New activity state.
         */
        public void onActivityStateChange(Activity activity, int newState);
    }

    private ApplicationStatus() {}

    /**
     * Initializes the activity status for a specified application.
     *
     * @param application The application whose status you wish to monitor.
     */
    public static void initialize(BaseChromiumApplication application) {
        sApplication = application;

        application.registerWindowFocusChangedListener(
                new BaseChromiumApplication.WindowFocusChangedListener() {
                    @Override
                    public void onWindowFocusChanged(Activity activity, boolean hasFocus) {
                        if (!hasFocus || activity == sActivity) return;

                        int state = getStateForActivity(activity);

                        if (state != ActivityState.DESTROYED && state != ActivityState.STOPPED) {
                            sActivity = activity;
                        }

                        // TODO(dtrainor): Notify of active activity change?
                    }
                });

        application.registerActivityLifecycleCallbacks(new ActivityLifecycleCallbacks() {
            @Override
            public void onActivityCreated(final Activity activity, Bundle savedInstanceState) {
                onStateChange(activity, ActivityState.CREATED);
            }

            @Override
            public void onActivityDestroyed(Activity activity) {
                onStateChange(activity, ActivityState.DESTROYED);
            }

            @Override
            public void onActivityPaused(Activity activity) {
                onStateChange(activity, ActivityState.PAUSED);
            }

            @Override
            public void onActivityResumed(Activity activity) {
                onStateChange(activity, ActivityState.RESUMED);
            }

            @Override
            public void onActivitySaveInstanceState(Activity activity, Bundle outState) {}

            @Override
            public void onActivityStarted(Activity activity) {
                onStateChange(activity, ActivityState.STARTED);
            }

            @Override
            public void onActivityStopped(Activity activity) {
                onStateChange(activity, ActivityState.STOPPED);
            }
        });
    }

    /**
     * Must be called by the main activity when it changes state.
     *
     * @param activity Current activity.
     * @param newState New state value.
     */
    private static void onStateChange(Activity activity, int newState) {
        if (activity == null) throw new IllegalArgumentException("null activity is not supported");

        if (sActivity == null
                || newState == ActivityState.CREATED
                || newState == ActivityState.RESUMED
                || newState == ActivityState.STARTED) {
            sActivity = activity;
        }

        int oldApplicationState = getStateForApplication();

        if (newState == ActivityState.CREATED) {
            assert !sActivityInfo.containsKey(activity);
            sActivityInfo.put(activity, new ActivityInfo());
        }

        // Invalidate the cached application state.
        synchronized (sCachedApplicationStateLock) {
            sCachedApplicationState = null;
        }

        ActivityInfo info = sActivityInfo.get(activity);
        info.setStatus(newState);

        // Notify all state observers that are specifically listening to this activity.
        for (ActivityStateListener listener : info.getListeners()) {
            listener.onActivityStateChange(activity, newState);
        }

        // Notify all state observers that are listening globally for all activity state
        // changes.
        for (ActivityStateListener listener : sGeneralActivityStateListeners) {
            listener.onActivityStateChange(activity, newState);
        }

        int applicationState = getStateForApplication();
        if (applicationState != oldApplicationState) {
            for (ApplicationStateListener listener : sApplicationStateListeners) {
                listener.onApplicationStateChange(applicationState);
            }
        }

        if (newState == ActivityState.DESTROYED) {
            sActivityInfo.remove(activity);
            if (activity == sActivity) sActivity = null;
        }
    }

    /**
     * Testing method to update the state of the specified activity.
     */
    @VisibleForTesting
    public static void onStateChangeForTesting(Activity activity, int newState) {
        onStateChange(activity, newState);
    }

    /**
     * @return The most recent focused {@link Activity} tracked by this class.  Being focused means
     *         out of all the activities tracked here, it has most recently gained window focus.
     */
    public static Activity getLastTrackedFocusedActivity() {
        return sActivity;
    }

    /**
     * @return A {@link List} of all non-destroyed {@link Activity}s.
     */
    public static List<WeakReference<Activity>> getRunningActivities() {
        List<WeakReference<Activity>> activities = new ArrayList<WeakReference<Activity>>();
        for (Activity activity : sActivityInfo.keySet()) {
            activities.add(new WeakReference<Activity>(activity));
        }
        return activities;
    }

    /**
     * @return The {@link Context} for the {@link Application}.
     */
    public static Context getApplicationContext() {
        return sApplication != null ? sApplication.getApplicationContext() : null;
    }

    /**
     * Query the state for a given activity.  If the activity is not being tracked, this will
     * return {@link ActivityState#DESTROYED}.
     *
     * <p>
     * Please note that Chrome can have multiple activities running simultaneously.  Please also
     * look at {@link #getStateForApplication()} for more details.
     *
     * <p>
     * When relying on this method, be familiar with the expected life cycle state
     * transitions:
     * <a href="http://developer.android.com/guide/components/activities.html#Lifecycle">
     *   Activity Lifecycle
     * </a>
     *
     * <p>
     * During activity transitions (activity B launching in front of activity A), A will completely
     * paused before the creation of activity B begins.
     *
     * <p>
     * A basic flow for activity A starting, followed by activity B being opened and then closed:
     * <ul>
     *   <li> -- Starting Activity A --
     *   <li> Activity A - ActivityState.CREATED
     *   <li> Activity A - ActivityState.STARTED
     *   <li> Activity A - ActivityState.RESUMED
     *   <li> -- Starting Activity B --
     *   <li> Activity A - ActivityState.PAUSED
     *   <li> Activity B - ActivityState.CREATED
     *   <li> Activity B - ActivityState.STARTED
     *   <li> Activity B - ActivityState.RESUMED
     *   <li> Activity A - ActivityState.STOPPED
     *   <li> -- Closing Activity B, Activity A regaining focus --
     *   <li> Activity B - ActivityState.PAUSED
     *   <li> Activity A - ActivityState.STARTED
     *   <li> Activity A - ActivityState.RESUMED
     *   <li> Activity B - ActivityState.STOPPED
     *   <li> Activity B - ActivityState.DESTROYED
     * </ul>
     *
     * @param activity The activity whose state is to be returned.
     * @return The state of the specified activity (see {@link ActivityState}).
     */
    public static int getStateForActivity(Activity activity) {
        ActivityInfo info = sActivityInfo.get(activity);
        return info != null ? info.getStatus() : ActivityState.DESTROYED;
    }

    /**
     * @return The state of the application (see {@link ApplicationState}).
     */
    public static int getStateForApplication() {
        synchronized (sCachedApplicationStateLock) {
            if (sCachedApplicationState == null) {
                sCachedApplicationState = determineApplicationState();
            }
            return sCachedApplicationState.intValue();
        }
    }

    /**
     * Checks whether or not any Activity in this Application is visible to the user.  Note that
     * this includes the PAUSED state, which can happen when the Activity is temporarily covered
     * by another Activity's Fragment (e.g.).
     * @return Whether any Activity under this Application is visible.
     */
    public static boolean hasVisibleActivities() {
        int state = getStateForApplication();
        return state == ApplicationState.HAS_RUNNING_ACTIVITIES
                || state == ApplicationState.HAS_PAUSED_ACTIVITIES;
    }

    /**
     * Checks to see if there are any active Activity instances being watched by ApplicationStatus.
     * @return True if all Activities have been destroyed.
     */
    public static boolean isEveryActivityDestroyed() {
        return sActivityInfo.isEmpty();
    }

    /**
     * Registers the given listener to receive state changes for all activities.
     * @param listener Listener to receive state changes.
     */
    public static void registerStateListenerForAllActivities(ActivityStateListener listener) {
        sGeneralActivityStateListeners.addObserver(listener);
    }

    /**
     * Registers the given listener to receive state changes for {@code activity}.  After a call to
     * {@link ActivityStateListener#onActivityStateChange(Activity, int)} with
     * {@link ActivityState#DESTROYED} all listeners associated with that particular
     * {@link Activity} are removed.
     * @param listener Listener to receive state changes.
     * @param activity Activity to track or {@code null} to track all activities.
     */
    public static void registerStateListenerForActivity(ActivityStateListener listener,
            Activity activity) {
        assert activity != null;

        ActivityInfo info = sActivityInfo.get(activity);
        assert info != null && info.getStatus() != ActivityState.DESTROYED;
        info.getListeners().addObserver(listener);
    }

    /**
     * Unregisters the given listener from receiving activity state changes.
     * @param listener Listener that doesn't want to receive state changes.
     */
    public static void unregisterActivityStateListener(ActivityStateListener listener) {
        sGeneralActivityStateListeners.removeObserver(listener);

        // Loop through all observer lists for all activities and remove the listener.
        for (ActivityInfo info : sActivityInfo.values()) {
            info.getListeners().removeObserver(listener);
        }
    }

    /**
     * Registers the given listener to receive state changes for the application.
     * @param listener Listener to receive state state changes.
     */
    public static void registerApplicationStateListener(ApplicationStateListener listener) {
        sApplicationStateListeners.addObserver(listener);
    }

    /**
     * Unregisters the given listener from receiving state changes.
     * @param listener Listener that doesn't want to receive state changes.
     */
    public static void unregisterApplicationStateListener(ApplicationStateListener listener) {
        sApplicationStateListeners.removeObserver(listener);
    }

    /**
     * Registers the single thread-safe native activity status listener.
     * This handles the case where the caller is not on the main thread.
     * Note that this is used by a leaky singleton object from the native
     * side, hence lifecycle management is greatly simplified.
     */
    @CalledByNative
    private static void registerThreadSafeNativeApplicationStateListener() {
        ThreadUtils.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                if (sNativeApplicationStateListener != null) return;

                sNativeApplicationStateListener = new ApplicationStateListener() {
                    @Override
                    public void onApplicationStateChange(int newState) {
                        nativeOnApplicationStateChange(newState);
                    }
                };
                registerApplicationStateListener(sNativeApplicationStateListener);
            }
        });
    }

    /**
     * Determines the current application state as defined by {@link ApplicationState}.  This will
     * loop over all the activities and check their state to determine what the general application
     * state should be.
     * @return HAS_RUNNING_ACTIVITIES if any activity is not paused, stopped, or destroyed.
     *         HAS_PAUSED_ACTIVITIES if none are running and one is paused.
     *         HAS_STOPPED_ACTIVITIES if none are running/paused and one is stopped.
     *         HAS_DESTROYED_ACTIVITIES if none are running/paused/stopped.
     */
    private static int determineApplicationState() {
        boolean hasPausedActivity = false;
        boolean hasStoppedActivity = false;

        for (ActivityInfo info : sActivityInfo.values()) {
            int state = info.getStatus();
            if (state != ActivityState.PAUSED
                    && state != ActivityState.STOPPED
                    && state != ActivityState.DESTROYED) {
                return ApplicationState.HAS_RUNNING_ACTIVITIES;
            } else if (state == ActivityState.PAUSED) {
                hasPausedActivity = true;
            } else if (state == ActivityState.STOPPED) {
                hasStoppedActivity = true;
            }
        }

        if (hasPausedActivity) return ApplicationState.HAS_PAUSED_ACTIVITIES;
        if (hasStoppedActivity) return ApplicationState.HAS_STOPPED_ACTIVITIES;
        return ApplicationState.HAS_DESTROYED_ACTIVITIES;
    }

    // Called to notify the native side of state changes.
    // IMPORTANT: This is always called on the main thread!
    private static native void nativeOnApplicationStateChange(int newState);
}
