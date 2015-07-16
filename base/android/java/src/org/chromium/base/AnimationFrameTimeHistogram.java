// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.chromium.base;

import android.animation.Animator;
import android.animation.Animator.AnimatorListener;
import android.animation.AnimatorListenerAdapter;
import android.animation.TimeAnimator;
import android.animation.TimeAnimator.TimeListener;
import android.util.Log;

/**
 * Record Android animation frame rate and save it to UMA histogram. This is mainly for monitoring
 * any jankiness of short Chrome Android animations. It is limited to few seconds of recording.
 */
public class AnimationFrameTimeHistogram {
    private static final String TAG = "AnimationFrameTimeHistogram";
    private static final int MAX_FRAME_TIME_NUM = 600; // 10 sec on 60 fps.

    private final Recorder mRecorder = new Recorder();
    private final String mHistogramName;

    /**
     * @param histogramName The histogram name that the recorded frame times will be saved.
     *                      This must be also defined in histograms.xml
     * @return An AnimatorListener instance that records frame time histogram on start and end
     *         automatically.
     */
    public static AnimatorListener getAnimatorRecorder(final String histogramName) {
        return new AnimatorListenerAdapter() {
            private final AnimationFrameTimeHistogram mAnimationFrameTimeHistogram =
                    new AnimationFrameTimeHistogram(histogramName);

            @Override
            public void onAnimationStart(Animator animation) {
                mAnimationFrameTimeHistogram.startRecording();
            }

            @Override
            public void onAnimationEnd(Animator animation) {
                mAnimationFrameTimeHistogram.endRecording();
            }

            @Override
            public void onAnimationCancel(Animator animation) {
                mAnimationFrameTimeHistogram.endRecording();
            }
        };
    }

    /**
     * @param histogramName The histogram name that the recorded frame times will be saved.
     *                      This must be also defined in histograms.xml
     */
    public AnimationFrameTimeHistogram(String histogramName) {
        mHistogramName = histogramName;
    }

    /**
     * Start recording frame times. The recording can fail if it exceeds a few seconds.
     */
    public void startRecording() {
        mRecorder.startRecording();
    }

    /**
     * End recording and save it to histogram. It won't save histogram if the recording wasn't
     * successful.
     */
    public void endRecording() {
        if (mRecorder.endRecording()) {
            nativeSaveHistogram(mHistogramName,
                    mRecorder.getFrameTimesMs(), mRecorder.getFrameTimesCount());
        }
        mRecorder.cleanUp();
    }

    /**
     * Record Android animation frame rate and return the result.
     */
    private static class Recorder implements TimeListener {
        // TODO(kkimlabs): If we can use in the future, migrate to Choreographer for minimal
        //                 workload.
        private final TimeAnimator mAnimator = new TimeAnimator();
        private long[] mFrameTimesMs;
        private int mFrameTimesCount;

        private Recorder() {
            mAnimator.setTimeListener(this);
        }

        private void startRecording() {
            assert !mAnimator.isRunning();
            mFrameTimesCount = 0;
            mFrameTimesMs = new long[MAX_FRAME_TIME_NUM];
            mAnimator.start();
        }

        /**
         * @return Whether the recording was successful. If successful, the result is available via
         *         getFrameTimesNs and getFrameTimesCount.
         */
        private boolean endRecording() {
            boolean succeeded = mAnimator.isStarted();
            mAnimator.end();
            return succeeded;
        }

        private long[] getFrameTimesMs() {
            return mFrameTimesMs;
        }

        private int getFrameTimesCount() {
            return mFrameTimesCount;
        }

        /**
         * Deallocates the temporary buffer to record frame times. Must be called after ending
         * the recording and getting the result.
         */
        private void cleanUp() {
            mFrameTimesMs = null;
        }

        @Override
        public void onTimeUpdate(TimeAnimator animation, long totalTime, long deltaTime) {
            if (mFrameTimesCount == mFrameTimesMs.length) {
                mAnimator.end();
                cleanUp();
                Log.w(TAG, "Animation frame time recording reached the maximum number. It's either"
                        + "the animation took too long or recording end is not called.");
                return;
            }

            // deltaTime is 0 for the first frame.
            if (deltaTime > 0) {
                mFrameTimesMs[mFrameTimesCount++] = deltaTime;
            }
        }
    }

    private native void nativeSaveHistogram(String histogramName, long[] frameTimesMs, int count);
}
