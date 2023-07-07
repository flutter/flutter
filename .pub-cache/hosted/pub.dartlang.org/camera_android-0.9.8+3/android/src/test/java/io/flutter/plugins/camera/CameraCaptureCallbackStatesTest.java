// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.camera;

import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.mockStatic;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import android.hardware.camera2.CameraCaptureSession;
import android.hardware.camera2.CaptureRequest;
import android.hardware.camera2.CaptureResult;
import android.hardware.camera2.CaptureResult.Key;
import android.hardware.camera2.TotalCaptureResult;
import io.flutter.plugins.camera.CameraCaptureCallback.CameraCaptureStateListener;
import io.flutter.plugins.camera.types.CameraCaptureProperties;
import io.flutter.plugins.camera.types.CaptureTimeoutsWrapper;
import io.flutter.plugins.camera.types.Timeout;
import io.flutter.plugins.camera.utils.TestUtils;
import java.util.HashMap;
import java.util.Map;
import junit.framework.TestCase;
import junit.framework.TestSuite;
import org.mockito.MockedStatic;

public class CameraCaptureCallbackStatesTest extends TestCase {
  private final Integer aeState;
  private final Integer afState;
  private final CameraState cameraState;
  private final boolean isTimedOut;

  private Runnable validate;

  private CameraCaptureCallback cameraCaptureCallback;
  private CameraCaptureStateListener mockCaptureStateListener;
  private CameraCaptureSession mockCameraCaptureSession;
  private CaptureRequest mockCaptureRequest;
  private CaptureResult mockPartialCaptureResult;
  private CaptureTimeoutsWrapper mockCaptureTimeouts;
  private CameraCaptureProperties mockCaptureProps;
  private TotalCaptureResult mockTotalCaptureResult;
  private MockedStatic<Timeout> mockedStaticTimeout;
  private Timeout mockTimeout;

  public static TestSuite suite() {
    TestSuite suite = new TestSuite();

    setUpPreviewStateTest(suite);
    setUpWaitingFocusTests(suite);
    setUpWaitingPreCaptureStartTests(suite);
    setUpWaitingPreCaptureDoneTests(suite);

    return suite;
  }

  protected CameraCaptureCallbackStatesTest(
      String name, CameraState cameraState, Integer afState, Integer aeState) {
    this(name, cameraState, afState, aeState, false);
  }

  protected CameraCaptureCallbackStatesTest(
      String name, CameraState cameraState, Integer afState, Integer aeState, boolean isTimedOut) {
    super(name);

    this.aeState = aeState;
    this.afState = afState;
    this.cameraState = cameraState;
    this.isTimedOut = isTimedOut;
  }

  @Override
  @SuppressWarnings("unchecked")
  protected void setUp() throws Exception {
    super.setUp();

    mockedStaticTimeout = mockStatic(Timeout.class);
    mockCaptureStateListener = mock(CameraCaptureStateListener.class);
    mockCameraCaptureSession = mock(CameraCaptureSession.class);
    mockCaptureRequest = mock(CaptureRequest.class);
    mockPartialCaptureResult = mock(CaptureResult.class);
    mockTotalCaptureResult = mock(TotalCaptureResult.class);
    mockTimeout = mock(Timeout.class);
    mockCaptureTimeouts = mock(CaptureTimeoutsWrapper.class);
    mockCaptureProps = mock(CameraCaptureProperties.class);
    when(mockCaptureTimeouts.getPreCaptureFocusing()).thenReturn(mockTimeout);
    when(mockCaptureTimeouts.getPreCaptureMetering()).thenReturn(mockTimeout);

    Key<Integer> mockAeStateKey = mock(Key.class);
    Key<Integer> mockAfStateKey = mock(Key.class);

    TestUtils.setFinalStatic(CaptureResult.class, "CONTROL_AE_STATE", mockAeStateKey);
    TestUtils.setFinalStatic(CaptureResult.class, "CONTROL_AF_STATE", mockAfStateKey);

    mockedStaticTimeout.when(() -> Timeout.create(1000)).thenReturn(mockTimeout);

    cameraCaptureCallback =
        CameraCaptureCallback.create(
            mockCaptureStateListener, mockCaptureTimeouts, mockCaptureProps);
  }

  @Override
  protected void tearDown() throws Exception {
    super.tearDown();

    mockedStaticTimeout.close();

    TestUtils.setFinalStatic(CaptureResult.class, "CONTROL_AE_STATE", null);
    TestUtils.setFinalStatic(CaptureResult.class, "CONTROL_AF_STATE", null);
  }

  @Override
  protected void runTest() throws Throwable {
    when(mockPartialCaptureResult.get(CaptureResult.CONTROL_AF_STATE)).thenReturn(afState);
    when(mockPartialCaptureResult.get(CaptureResult.CONTROL_AE_STATE)).thenReturn(aeState);
    when(mockTotalCaptureResult.get(CaptureResult.CONTROL_AF_STATE)).thenReturn(afState);
    when(mockTotalCaptureResult.get(CaptureResult.CONTROL_AE_STATE)).thenReturn(aeState);

    cameraCaptureCallback.setCameraState(cameraState);
    if (isTimedOut) {
      when(mockTimeout.getIsExpired()).thenReturn(true);
      cameraCaptureCallback.onCaptureCompleted(
          mockCameraCaptureSession, mockCaptureRequest, mockTotalCaptureResult);
    } else {
      cameraCaptureCallback.onCaptureProgressed(
          mockCameraCaptureSession, mockCaptureRequest, mockPartialCaptureResult);
    }

    validate.run();
  }

  private static void setUpPreviewStateTest(TestSuite suite) {
    CameraCaptureCallbackStatesTest previewStateTest =
        new CameraCaptureCallbackStatesTest(
            "process_should_not_converge_or_pre_capture_when_state_is_preview",
            CameraState.STATE_PREVIEW,
            null,
            null);
    previewStateTest.validate =
        () -> {
          verify(previewStateTest.mockCaptureStateListener, never()).onConverged();
          verify(previewStateTest.mockCaptureStateListener, never()).onConverged();
          assertEquals(
              CameraState.STATE_PREVIEW, previewStateTest.cameraCaptureCallback.getCameraState());
        };
    suite.addTest(previewStateTest);
  }

  private static void setUpWaitingFocusTests(TestSuite suite) {
    Integer[] actionableAfStates =
        new Integer[] {
          CaptureResult.CONTROL_AF_STATE_FOCUSED_LOCKED,
          CaptureResult.CONTROL_AF_STATE_NOT_FOCUSED_LOCKED
        };

    Integer[] nonActionableAfStates =
        new Integer[] {
          CaptureResult.CONTROL_AF_STATE_ACTIVE_SCAN,
          CaptureResult.CONTROL_AF_STATE_INACTIVE,
          CaptureResult.CONTROL_AF_STATE_PASSIVE_FOCUSED,
          CaptureResult.CONTROL_AF_STATE_PASSIVE_SCAN,
          CaptureResult.CONTROL_AF_STATE_PASSIVE_UNFOCUSED
        };

    Map<Integer, Boolean> aeStatesConvergeMap =
        new HashMap<Integer, Boolean>() {
          {
            put(null, true);
            put(CaptureResult.CONTROL_AE_STATE_CONVERGED, true);
            put(CaptureResult.CONTROL_AE_STATE_PRECAPTURE, false);
            put(CaptureResult.CONTROL_AE_STATE_LOCKED, false);
            put(CaptureResult.CONTROL_AE_STATE_SEARCHING, false);
            put(CaptureResult.CONTROL_AE_STATE_INACTIVE, false);
            put(CaptureResult.CONTROL_AE_STATE_FLASH_REQUIRED, false);
          }
        };

    CameraCaptureCallbackStatesTest nullStateTest =
        new CameraCaptureCallbackStatesTest(
            "process_should_not_converge_or_pre_capture_when_afstate_is_null",
            CameraState.STATE_WAITING_FOCUS,
            null,
            null);
    nullStateTest.validate =
        () -> {
          verify(nullStateTest.mockCaptureStateListener, never()).onConverged();
          verify(nullStateTest.mockCaptureStateListener, never()).onConverged();
          assertEquals(
              CameraState.STATE_WAITING_FOCUS,
              nullStateTest.cameraCaptureCallback.getCameraState());
        };
    suite.addTest(nullStateTest);

    for (Integer afState : actionableAfStates) {
      aeStatesConvergeMap.forEach(
          (aeState, shouldConverge) -> {
            CameraCaptureCallbackStatesTest focusLockedTest =
                new CameraCaptureCallbackStatesTest(
                    "process_should_converge_when_af_state_is_"
                        + afState
                        + "_and_ae_state_is_"
                        + aeState,
                    CameraState.STATE_WAITING_FOCUS,
                    afState,
                    aeState);
            focusLockedTest.validate =
                () -> {
                  if (shouldConverge) {
                    verify(focusLockedTest.mockCaptureStateListener, times(1)).onConverged();
                    verify(focusLockedTest.mockCaptureStateListener, never()).onPrecapture();
                  } else {
                    verify(focusLockedTest.mockCaptureStateListener, times(1)).onPrecapture();
                    verify(focusLockedTest.mockCaptureStateListener, never()).onConverged();
                  }
                  assertEquals(
                      CameraState.STATE_WAITING_FOCUS,
                      focusLockedTest.cameraCaptureCallback.getCameraState());
                };
            suite.addTest(focusLockedTest);
          });
    }

    for (Integer afState : nonActionableAfStates) {
      CameraCaptureCallbackStatesTest focusLockedTest =
          new CameraCaptureCallbackStatesTest(
              "process_should_do_nothing_when_af_state_is_" + afState,
              CameraState.STATE_WAITING_FOCUS,
              afState,
              null);
      focusLockedTest.validate =
          () -> {
            verify(focusLockedTest.mockCaptureStateListener, never()).onConverged();
            verify(focusLockedTest.mockCaptureStateListener, never()).onPrecapture();
            assertEquals(
                CameraState.STATE_WAITING_FOCUS,
                focusLockedTest.cameraCaptureCallback.getCameraState());
          };
      suite.addTest(focusLockedTest);
    }

    for (Integer afState : nonActionableAfStates) {
      aeStatesConvergeMap.forEach(
          (aeState, shouldConverge) -> {
            CameraCaptureCallbackStatesTest focusLockedTest =
                new CameraCaptureCallbackStatesTest(
                    "process_should_converge_when_af_state_is_"
                        + afState
                        + "_and_ae_state_is_"
                        + aeState,
                    CameraState.STATE_WAITING_FOCUS,
                    afState,
                    aeState,
                    true);
            focusLockedTest.validate =
                () -> {
                  if (shouldConverge) {
                    verify(focusLockedTest.mockCaptureStateListener, times(1)).onConverged();
                    verify(focusLockedTest.mockCaptureStateListener, never()).onPrecapture();
                  } else {
                    verify(focusLockedTest.mockCaptureStateListener, times(1)).onPrecapture();
                    verify(focusLockedTest.mockCaptureStateListener, never()).onConverged();
                  }
                  assertEquals(
                      CameraState.STATE_WAITING_FOCUS,
                      focusLockedTest.cameraCaptureCallback.getCameraState());
                };
            suite.addTest(focusLockedTest);
          });
    }
  }

  private static void setUpWaitingPreCaptureStartTests(TestSuite suite) {
    Map<Integer, CameraState> cameraStateMap =
        new HashMap<Integer, CameraState>() {
          {
            put(null, CameraState.STATE_WAITING_PRECAPTURE_DONE);
            put(
                CaptureResult.CONTROL_AE_STATE_INACTIVE,
                CameraState.STATE_WAITING_PRECAPTURE_START);
            put(
                CaptureResult.CONTROL_AE_STATE_SEARCHING,
                CameraState.STATE_WAITING_PRECAPTURE_START);
            put(
                CaptureResult.CONTROL_AE_STATE_CONVERGED,
                CameraState.STATE_WAITING_PRECAPTURE_DONE);
            put(CaptureResult.CONTROL_AE_STATE_LOCKED, CameraState.STATE_WAITING_PRECAPTURE_START);
            put(
                CaptureResult.CONTROL_AE_STATE_FLASH_REQUIRED,
                CameraState.STATE_WAITING_PRECAPTURE_DONE);
            put(
                CaptureResult.CONTROL_AE_STATE_PRECAPTURE,
                CameraState.STATE_WAITING_PRECAPTURE_DONE);
          }
        };

    cameraStateMap.forEach(
        (aeState, cameraState) -> {
          CameraCaptureCallbackStatesTest testCase =
              new CameraCaptureCallbackStatesTest(
                  "process_should_update_camera_state_to_waiting_pre_capture_done_when_ae_state_is_"
                      + aeState,
                  CameraState.STATE_WAITING_PRECAPTURE_START,
                  null,
                  aeState);
          testCase.validate =
              () -> assertEquals(cameraState, testCase.cameraCaptureCallback.getCameraState());
          suite.addTest(testCase);
        });

    cameraStateMap.forEach(
        (aeState, cameraState) -> {
          if (cameraState == CameraState.STATE_WAITING_PRECAPTURE_DONE) {
            return;
          }

          CameraCaptureCallbackStatesTest testCase =
              new CameraCaptureCallbackStatesTest(
                  "process_should_update_camera_state_to_waiting_pre_capture_done_when_ae_state_is_"
                      + aeState,
                  CameraState.STATE_WAITING_PRECAPTURE_START,
                  null,
                  aeState,
                  true);
          testCase.validate =
              () ->
                  assertEquals(
                      CameraState.STATE_WAITING_PRECAPTURE_DONE,
                      testCase.cameraCaptureCallback.getCameraState());
          suite.addTest(testCase);
        });
  }

  private static void setUpWaitingPreCaptureDoneTests(TestSuite suite) {
    Integer[] onConvergeStates =
        new Integer[] {
          null,
          CaptureResult.CONTROL_AE_STATE_CONVERGED,
          CaptureResult.CONTROL_AE_STATE_LOCKED,
          CaptureResult.CONTROL_AE_STATE_SEARCHING,
          CaptureResult.CONTROL_AE_STATE_INACTIVE,
          CaptureResult.CONTROL_AE_STATE_FLASH_REQUIRED,
        };

    for (Integer aeState : onConvergeStates) {
      CameraCaptureCallbackStatesTest shouldConvergeTest =
          new CameraCaptureCallbackStatesTest(
              "process_should_converge_when_ae_state_is_" + aeState,
              CameraState.STATE_WAITING_PRECAPTURE_DONE,
              null,
              null);
      shouldConvergeTest.validate =
          () -> verify(shouldConvergeTest.mockCaptureStateListener, times(1)).onConverged();
      suite.addTest(shouldConvergeTest);
    }

    CameraCaptureCallbackStatesTest shouldNotConvergeTest =
        new CameraCaptureCallbackStatesTest(
            "process_should_not_converge_when_ae_state_is_pre_capture",
            CameraState.STATE_WAITING_PRECAPTURE_DONE,
            null,
            CaptureResult.CONTROL_AE_STATE_PRECAPTURE);
    shouldNotConvergeTest.validate =
        () -> verify(shouldNotConvergeTest.mockCaptureStateListener, never()).onConverged();
    suite.addTest(shouldNotConvergeTest);

    CameraCaptureCallbackStatesTest shouldConvergeWhenTimedOutTest =
        new CameraCaptureCallbackStatesTest(
            "process_should_not_converge_when_ae_state_is_pre_capture",
            CameraState.STATE_WAITING_PRECAPTURE_DONE,
            null,
            CaptureResult.CONTROL_AE_STATE_PRECAPTURE,
            true);
    shouldConvergeWhenTimedOutTest.validate =
        () ->
            verify(shouldConvergeWhenTimedOutTest.mockCaptureStateListener, times(1)).onConverged();
    suite.addTest(shouldConvergeWhenTimedOutTest);
  }
}
