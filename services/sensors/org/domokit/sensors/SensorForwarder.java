// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package org.domokit.sensors;

import android.content.Context;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import android.util.Log;

import org.chromium.mojo.bindings.ConnectionErrorHandler;
import org.chromium.mojo.system.MojoException;
import org.chromium.mojom.sensors.SensorData;
import org.chromium.mojom.sensors.SensorListener;
import org.chromium.mojom.sensors.SensorType;

/**
 * A class to forward sensor data to a SensorListener.
 */
public class SensorForwarder implements ConnectionErrorHandler, SensorEventListener {
    private static final String TAG = "SensorForwarder";

    private SensorListener.Proxy mListener;
    private SensorManager mManager;
    private Sensor mSensor;

    private static int getAndroidTypeForSensor(int sensorType) {
        switch (sensorType) {
            case SensorType.ACCELEROMETER:
                return Sensor.TYPE_ACCELEROMETER;
            case SensorType.AMBIENT_TEMPERATURE:
                return Sensor.TYPE_AMBIENT_TEMPERATURE;
            case SensorType.GAME_ROTATION_VECTOR:
                return Sensor.TYPE_GAME_ROTATION_VECTOR;
            case SensorType.GEOMAGNETIC_ROTATION_VECTOR:
                return Sensor.TYPE_GEOMAGNETIC_ROTATION_VECTOR;
            case SensorType.GRAVITY:
                return Sensor.TYPE_GRAVITY;
            case SensorType.GYROSCOPE:
                return Sensor.TYPE_GYROSCOPE;
            case SensorType.GYROSCOPE_UNCALIBRATED:
                return Sensor.TYPE_GYROSCOPE_UNCALIBRATED;
            case SensorType.HEART_RATE:
                return Sensor.TYPE_HEART_RATE;
            case SensorType.LIGHT:
                return Sensor.TYPE_LIGHT;
            case SensorType.LINEAR_ACCELERATION:
                return Sensor.TYPE_LINEAR_ACCELERATION;
            case SensorType.MAGNETIC_FIELD:
                return Sensor.TYPE_MAGNETIC_FIELD;
            case SensorType.MAGNETIC_FIELD_UNCALIBRATED:
                return Sensor.TYPE_MAGNETIC_FIELD_UNCALIBRATED;
            case SensorType.PRESSURE:
                return Sensor.TYPE_PRESSURE;
            case SensorType.PROXIMITY:
                return Sensor.TYPE_PROXIMITY;
            case SensorType.RELATIVE_HUMIDITY:
                return Sensor.TYPE_RELATIVE_HUMIDITY;
            case SensorType.ROTATION_VECTOR:
                return Sensor.TYPE_ROTATION_VECTOR;
            case SensorType.SIGNIFICANT_MOTION:
                return Sensor.TYPE_SIGNIFICANT_MOTION;
            case SensorType.STEP_COUNTER:
                return Sensor.TYPE_STEP_COUNTER;
            case SensorType.STEP_DETECTOR:
                return Sensor.TYPE_STEP_DETECTOR;
            default:
                return -1;
        }
    }

    public SensorForwarder(Context context, int mojoSensorType, SensorListener.Proxy listener) {
        int androidSensorType = getAndroidTypeForSensor(mojoSensorType);
        mListener = listener;
        mManager = (SensorManager) context.getSystemService(Context.SENSOR_SERVICE);
        mSensor = mManager.getDefaultSensor(androidSensorType);

        if (mSensor == null) {
            Log.e(TAG, "No default sensor for sensor type " + mojoSensorType);
            mListener.close();
            return;
        }

        // TODO(abarth): We should expose a way for clients to request different
        // update rates.
        mManager.registerListener(this, mSensor, SensorManager.SENSOR_DELAY_NORMAL);
        mListener.setErrorHandler(this);
    }

    @Override
    public void onConnectionError(MojoException e) {
        mManager.unregisterListener(this);
    }

    @Override
    public void onAccuracyChanged(Sensor sensor, int accuracy) {
        mListener.onAccuracyChanged(accuracy);
    }

    @Override
    public void onSensorChanged(SensorEvent event) {
        SensorData data = new SensorData();
        data.accuracy = event.accuracy;
        data.timeStamp = event.timestamp;
        data.values = event.values;
        mListener.onSensorChanged(data);
    }
}
