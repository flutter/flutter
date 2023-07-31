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

import com.google.gson.JsonObject;
import org.dartlang.vm.service.consumer.*;
import org.dartlang.vm.service.element.*;
import org.dartlang.vm.service.logging.Logger;
import org.dartlang.vm.service.logging.Logging;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;

public class VmServiceTest {
  private static File dartVm;
  private static File sampleDart;
  private static File sampleDartWithException;
  private static int vmPort = 7575;
  private static Process process;
  private static VmService vmService;
  private static SampleOutPrinter sampleOut;
  private static SampleOutPrinter sampleErr;
  private static int actualVmServiceVersionMajor;

  public static void main(String[] args) {
    setupLogging();
    parseArgs(args);

    try {
      echoDartVmVersion();
      runSample();
      runSampleWithException();
      System.out.println("Test Complete");
    } finally {
      vmDisconnect();
      stopSample();
    }
  }

  private static void echoDartVmVersion() {
    // Echo Dart VM version
    List<String> processArgs = new ArrayList<>();
    processArgs.add(dartVm.getAbsolutePath());
    processArgs.add("--version");
    ProcessBuilder processBuilder = new ProcessBuilder(processArgs);
    try {
      process = processBuilder.start();
    } catch (IOException e) {
      throw new RuntimeException("Failed to launch Dart VM", e);
    }
    new SampleOutPrinter("version output", process.getInputStream());
    new SampleOutPrinter("version output", process.getErrorStream());
  }

  private static void finishExecution(SampleVmServiceListener vmListener, ElementList<IsolateRef> isolates) {
    // Finish execution
    vmResume(isolates.get(0), null);
    vmListener.waitFor(VmService.DEBUG_STREAM_ID, EventKind.Resume);

    // VM pauses on exit and must be resumed to cleanly terminate process
    vmListener.waitFor(VmService.DEBUG_STREAM_ID, EventKind.PauseExit);
    vmResume(isolates.get(0), null);
    vmListener.waitFor(VmService.ISOLATE_STREAM_ID, EventKind.IsolateExit);
    waitForProcessExit();

    sampleOut.assertLastLine("exiting");
    // TODO(devoncarew):
    //   vm-service: isolate(544050040) 'sample_main.dart:main()' has no debugger attached and is paused at start.
    //sampleErr.assertLastLine(null);
    process = null;
  }

  private static boolean isWindows() {
    return System.getProperty("os.name").startsWith("Win");
  }

  private static void parseArgs(String[] args) {
    if (args.length != 1) {
      showErrorAndExit("Expected absolute path to Dart SDK");
    }
    File sdkDir = new File(args[0]);
    if (!sdkDir.isDirectory()) {
      showErrorAndExit("Specified directory does not exist: " + sdkDir);
    }
    File binDir = new File(sdkDir, "bin");
    dartVm = new File(binDir, isWindows() ? "dart.exe" : "dart");
    if (!dartVm.isFile()) {
      showErrorAndExit("Cannot find Dart VM in SDK: " + dartVm);
    }
    File currentDir = new File(".").getAbsoluteFile();
    File projDir = currentDir;
    String projName = "vm_service";
    while (!projDir.getName().equals(projName)) {
      projDir = projDir.getParentFile();
      if (projDir == null) {
        showErrorAndExit("Cannot find project " + projName + " from " + currentDir);
        return;
      }
    }
    sampleDart = new File(projDir, "java/example/sample_main.dart".replace("/", File.separator));
    if (!sampleDart.isFile()) {
      showErrorAndExit("Cannot find sample: " + sampleDart);
    }
    sampleDartWithException = new File(projDir,
            "java/example/sample_exception.dart".replace("/", File.separator));
    if (!sampleDartWithException.isFile()) {
      showErrorAndExit("Cannot find sample: " + sampleDartWithException);
    }
    System.out.println("Using Dart SDK: " + sdkDir);
  }

  /**
   * Exercise VM service with "normal" sample.
   */
  private static void runSample() {
    SampleVmServiceListener vmListener = startSampleAndConnect(sampleDart);
    vmGetVersion();
    ElementList<IsolateRef> isolates = vmGetVmIsolates();
    Isolate sampleIsolate = vmGetIsolate(isolates.get(0));
    Library rootLib = vmGetLibrary(sampleIsolate, sampleIsolate.getRootLib());
    vmGetScript(sampleIsolate, rootLib.getScripts().get(0));
    vmCallServiceExtension(sampleIsolate);

    // Run to breakpoint on line "foo(1);"
    vmAddBreakpoint(sampleIsolate, rootLib.getScripts().get(0), 25);
    vmListener.waitFor(VmService.DEBUG_STREAM_ID, EventKind.BreakpointAdded);
    vmResume(isolates.get(0), null);
    vmListener.waitFor(VmService.DEBUG_STREAM_ID, EventKind.Resume);
    vmListener.waitFor(VmService.DEBUG_STREAM_ID, EventKind.PauseBreakpoint);
    sampleOut.assertLastLine("hello");

    // Get stack trace
    vmGetStack(sampleIsolate);

    // Evaluate
    vmEvaluateInFrame(sampleIsolate, 0, "deepList[0]");

    // Get coverage information
    vmGetSourceReport(sampleIsolate);

    // Step over line "foo(1);"
    vmResume(isolates.get(0), StepOption.Over);
    vmListener.waitFor(VmService.DEBUG_STREAM_ID, EventKind.Resume);
    vmListener.waitFor(VmService.DEBUG_STREAM_ID, EventKind.PauseBreakpoint);
    sampleOut.assertLastLine("val: 1");

    finishExecution(vmListener, isolates);
  }

  /**
   * Exercise VM service with sample that throws exceptions.
   */
  private static void runSampleWithException() {
    SampleVmServiceListener vmListener = startSampleAndConnect(sampleDartWithException);
    ElementList<IsolateRef> isolates = vmGetVmIsolates();
    Isolate sampleIsolate = vmGetIsolate(isolates.get(0));

    // Run until exception occurs
    vmPauseOnException(isolates.get(0), ExceptionPauseMode.All);
    vmResume(isolates.get(0), null);
    vmListener.waitFor(VmService.DEBUG_STREAM_ID, EventKind.Resume);
    Event event = vmListener.waitFor(VmService.DEBUG_STREAM_ID, EventKind.PauseException);
    InstanceRefToString convert = new InstanceRefToString(sampleIsolate, vmService, new OpLatch());
    System.out.println("Received PauseException event");
    System.out.println("  Exception: " + convert.toString(event.getException()));
    System.out.println("  Top Frame:");
    showFrame(convert, event.getTopFrame());
    sampleOut.assertLastLine("hello");

    finishExecution(vmListener, isolates);
  }

  private static void setupLogging() {
    Logging.setLogger(new Logger() {
      @Override
      public void logError(String message) {
        System.out.println("Log error: " + message);
      }

      @Override
      public void logError(String message, Throwable exception) {
        System.out.println("Log error: " + message);
        if (exception != null) {
          System.out.println("Log error exception: " + exception);
          exception.printStackTrace();
        }
      }

      @Override
      public void logInformation(String message) {
        System.out.println("Log info: " + message);
      }

      @Override
      public void logInformation(String message, Throwable exception) {
        System.out.println("Log info: " + message);
        if (exception != null) {
          System.out.println("Log info exception: " + exception);
          exception.printStackTrace();
        }
      }
    });
  }

  private static void showErrorAndExit(String errMsg) {
    System.out.println(errMsg);
    System.out.flush();
    sleep(10);
    System.out.println("Usage: VmServiceTest /path/to/Dart/SDK");
    System.exit(1);
  }

  private static void showFrame(InstanceRefToString convert, Frame frame) {
    System.out.println("    #" + frame.getIndex() + " " + frame.getFunction().getName() + " ("
            + frame.getLocation().getScript().getUri() + ")");
    for (BoundVariable var : frame.getVars()) {
      InstanceRef instanceRef = (InstanceRef)var.getValue();
      System.out.println("      " + var.getName() + " = " + convert.toString(instanceRef));
    }
  }

  private static void showRPCError(RPCError error) {
    System.out.println(">>> Received error response");
    System.out.println("  Code: " + error.getCode());
    System.out.println("  Message: " + error.getMessage());
    System.out.println("  Details: " + error.getDetails());
    System.out.println("  Request: " + error.getRequest());
  }

  private static void showSentinel(Sentinel sentinel) {
    System.out.println(">>> Received sentinel response");
    System.out.println("  Sentinel kind: " + sentinel.getKind());
    System.out.println("  Sentinel value: " + sentinel.getValueAsString());
  }

  private static void sleep(int milliseconds) {
    try {
      Thread.sleep(milliseconds);
    } catch (InterruptedException e) {
      // ignored
    }
  }

  private static void startSample(File dartFile) {
    List<String> processArgs;
    ProcessBuilder processBuilder;

    // Use new port to prevent race conditions
    // between one sample releasing a port
    // and the next sample using it.
    ++vmPort;

    processArgs = new ArrayList<>();
    processArgs.add(dartVm.getAbsolutePath());
    processArgs.add("--pause_isolates_on_start");
    processArgs.add("--observe");
    processArgs.add("--enable-vm-service=" + vmPort);
    processArgs.add("--disable-service-auth-codes");
    processArgs.add(dartFile.getAbsolutePath());
    processBuilder = new ProcessBuilder(processArgs);
    System.out.println("=================================================");
    System.out.println("Launching sample: " + dartFile);
    try {
      process = processBuilder.start();
    } catch (IOException e) {
      throw new RuntimeException("Failed to launch Dart sample", e);
    }
    // Echo sample application output to System.out
    sampleOut = new SampleOutPrinter("stdout", process.getInputStream());
    sampleErr = new SampleOutPrinter("stderr", process.getErrorStream());
    System.out.println("Dart process started - port " + vmPort);
  }

  private static SampleVmServiceListener startSampleAndConnect(File dartFile) {
    startSample(dartFile);
    sleep(1000);
    vmConnect();
    SampleVmServiceListener vmListener = new SampleVmServiceListener(
            new HashSet<>(Collections.singletonList(EventKind.BreakpointResolved)));
    vmService.addVmServiceListener(vmListener);
    vmStreamListen(VmService.DEBUG_STREAM_ID);
    vmStreamListen(VmService.ISOLATE_STREAM_ID);
    return vmListener;
  }

  private static void stopSample() {
    if (process == null) {
      return;
    }
    final Process processToStop = process;
    process = null;
    long endTime = System.currentTimeMillis() + 5000;
    while (System.currentTimeMillis() < endTime) {
      try {
        int exit = processToStop.exitValue();
        if (exit != 0) {
          System.out.println("Sample exit code: " + exit);
        }
        return;
      } catch (IllegalThreadStateException e) {
        //$FALL-THROUGH$
      }
      try {
        Thread.sleep(20);
      } catch (InterruptedException e) {
        //$FALL-THROUGH$
      }
    }
    processToStop.destroy();
    System.out.println("Terminated sample process");
  }

  @SuppressWarnings("SameParameterValue")
  private static void vmAddBreakpoint(Isolate isolate, ScriptRef script, int lineNum) {
    final OpLatch latch = new OpLatch();
    vmService.addBreakpoint(isolate.getId(), script.getId(), lineNum, new BreakpointConsumer() {
      @Override
      public void onError(RPCError error) {
        showRPCError(error);
      }

      @Override
      public void received(Breakpoint response) {
        System.out.println("Received Breakpoint response");
        System.out.println("  BreakpointNumber:" + response.getBreakpointNumber());
        latch.opComplete();
      }
    });
    latch.waitAndAssertOpComplete();
  }

  private static void vmConnect() {
    try {
      vmService = VmService.localConnect(vmPort);
    } catch (IOException e) {
      throw new RuntimeException("Failed to connect to the VM vmService service", e);
    }
  }

  private static void vmDisconnect() {
    if (vmService != null) {
      vmService.disconnect();
    }
  }

  @SuppressWarnings("SameParameterValue")
  private static void vmEvaluateInFrame(Isolate isolate, int frameIndex, String expression) {
    System.out.println("Evaluating: " + expression);
    final ResultLatch<InstanceRef> latch = new ResultLatch<>();
    vmService.evaluateInFrame(isolate.getId(), frameIndex, expression, new EvaluateInFrameConsumer() {
      @Override
      public void onError(RPCError error) {
        showRPCError(error);
      }

      @Override
      public void received(ErrorRef response) {
        showErrorAndExit(response.getMessage());
      }

      public void received(Sentinel response) {
        System.out.println(response.getValueAsString());
      }

      @Override
      public void received(InstanceRef response) {
        System.out.println("Received InstanceRef response");
        System.out.println("  Id: " + response.getId());
        System.out.println("  Kind: " + response.getKind());
        System.out.println("  Json: " + response.getJson());
        latch.setValue(response);
      }
    });
    InstanceRef instanceRef = latch.getValue();
    InstanceRefToString convert = new InstanceRefToString(isolate, vmService, latch);
    System.out.println("Result: " + convert.toString(instanceRef));
  }

  private static SourceReport vmGetSourceReport(Isolate isolate) {
    System.out.println("Getting coverage information for " + isolate.getId());
    final long startTime = System.currentTimeMillis();
    final ResultLatch<SourceReport> latch = new ResultLatch<>();
    vmService.getSourceReport(isolate.getId(), Collections.singletonList(SourceReportKind.Coverage), new SourceReportConsumer() {
      @Override
      public void onError(RPCError error) {
        showRPCError(error);
      }

      @Override
      public void received(SourceReport response) {
        System.out.println("Received SourceReport response (" + (System.currentTimeMillis() - startTime) + "ms)");
        System.out.println("  Script count: " + response.getScripts().size());
        System.out.println("  Range count: " + response.getRanges().size());
        latch.setValue(response);
      }
    });
    return latch.getValue();
  }

  private static Isolate vmGetIsolate(IsolateRef isolate) {
    final ResultLatch<Isolate> latch = new ResultLatch<>();
    vmService.getIsolate(isolate.getId(), new GetIsolateConsumer() {
      @Override
      public void onError(RPCError error) {
        showRPCError(error);
      }

      @Override
      public void received(Isolate response) {
        System.out.println("Received Isolate response");
        System.out.println("  Id: " + response.getId());
        System.out.println("  Name: " + response.getName());
        System.out.println("  Number: " + response.getNumber());
        System.out.println("  Start Time: " + response.getStartTime());
        System.out.println("  RootLib Id: " + response.getRootLib().getId());
        System.out.println("  RootLib Uri: " + response.getRootLib().getUri());
        System.out.println("  RootLib Name: " + response.getRootLib().getName());
        System.out.println("  RootLib Json: " + response.getRootLib().getJson());
        System.out.println("  Isolate: " + response);
        latch.setValue(response);
      }

      @Override
      public void received(Sentinel response) {
        showSentinel(response);
      }
    });
    return latch.getValue();
  }

  private static Library vmGetLibrary(Isolate isolateId, LibraryRef library) {
    final ResultLatch<Library> latch = new ResultLatch<>();
    vmService.getLibrary(isolateId.getId(), library.getId(), new GetLibraryConsumer() {
      @Override
      public void onError(RPCError error) {
        showRPCError(error);
      }

      @Override
      public void received(Library response) {
        System.out.println("Received GetLibrary library");
        System.out.println("  uri: " + response.getUri());
        latch.setValue(response);
      }
    });
    return latch.getValue();
  }

  private static void vmGetScript(Isolate isolate, ScriptRef scriptRef) {
    final ResultLatch<Script> latch = new ResultLatch<>();
    vmService.getObject(isolate.getId(), scriptRef.getId(), new GetObjectConsumer() {
      @Override
      public void onError(RPCError error) {
        showRPCError(error);
      }

      @Override
      public void received(Obj response) {
        if (response instanceof Script) {
          latch.setValue((Script) response);
        } else {
          RPCError.unexpected("Script", response);
        }
      }

      @Override
      public void received(Sentinel response) {
        RPCError.unexpected("Script", response);
      }
    });
    Script script = latch.getValue();
    System.out.println("Received Script");
    System.out.println("  Id: " + script.getId());
    System.out.println("  Uri: " + script.getUri());
    System.out.println("  Source: " + script.getSource());
    System.out.println("  TokenPosTable: " + script.getTokenPosTable());
    if (script.getTokenPosTable() == null) {
      showErrorAndExit("Expected TokenPosTable to be non-null");
    }
  }

  private static void vmGetStack(Isolate isolate) {
    final ResultLatch<Stack> latch = new ResultLatch<>();
    vmService.getStack(isolate.getId(), new StackConsumer() {
      @Override
      public void onError(RPCError error) {
        showRPCError(error);
      }

      @Override
      public void received(Stack stack) {
        latch.setValue(stack);
      }
    });
    Stack stack = latch.getValue();
    System.out.println("Received Stack response");
    System.out.println("  Messages:");
    for (Message message : stack.getMessages()) {
      System.out.println("    " + message.getName());
    }
    System.out.println("  Frames:");
    InstanceRefToString convert = new InstanceRefToString(isolate, vmService, latch);
    for (Frame frame : stack.getFrames()) {
      showFrame(convert, frame);
    }
  }

  private static void vmGetVersion() {
    final OpLatch latch = new OpLatch();
    vmService.getVersion(new VersionConsumer() {
      @Override
      public void onError(RPCError error) {
        showRPCError(error);
      }

      @Override
      public void received(Version response) {
        System.out.println("Received Version response");
        actualVmServiceVersionMajor = response.getMajor();
        System.out.println("  Major: " + actualVmServiceVersionMajor);
        System.out.println("  Minor: " + response.getMinor());
        System.out.println(response.getJson());
        latch.opComplete();
      }
    });
    latch.waitAndAssertOpComplete();
  }

  private static void vmCallServiceExtension(Isolate isolateId) {
    final OpLatch latch = new OpLatch();
    vmService.callServiceExtension(isolateId.getId(), "getIsolate", new ServiceExtensionConsumer() {
      @Override
      public void onError(RPCError error) {
        showRPCError(error);
      }

      @Override
      public void received(JsonObject result) {
        System.out.println("Received response: " + result);
        latch.opComplete();
      }
    });
    latch.waitAndAssertOpComplete();
  }

  private static ElementList<IsolateRef> vmGetVmIsolates() {
    final ResultLatch<ElementList<IsolateRef>> latch = new ResultLatch<>();
    vmService.getVM(new VMConsumer() {
      @Override
      public void onError(RPCError error) {
        showRPCError(error);
      }

      @Override
      public void received(VM response) {
        System.out.println("Received VM response");
        System.out.println("  ArchitectureBits: " + response.getArchitectureBits());
        System.out.println("  HostCPU: " + response.getHostCPU());
        System.out.println("  TargetCPU: " + response.getTargetCPU());
        System.out.println("  Pid: " + response.getPid());
        System.out.println("  StartTime: " + response.getStartTime());
        for (IsolateRef isolate : response.getIsolates()) {
          System.out.println("  Isolate " + isolate.getNumber() + ", " + isolate.getId() + ", "
                  + isolate.getName());
        }
        latch.setValue(response.getIsolates());
      }
    });
    return latch.getValue();
  }

  private static void vmPauseOnException(IsolateRef isolate, ExceptionPauseMode mode) {
    System.out.println("Request pause on exception: " + mode);
    final OpLatch latch = new OpLatch();
    vmService.setExceptionPauseMode(isolate.getId(), mode, new SuccessConsumer() {
      @Override
      public void onError(RPCError error) {
        showRPCError(error);
      }

      @Override
      public void received(Success response) {
        System.out.println("Successfully set pause on exception");
        latch.opComplete();
      }
    });
    latch.waitAndAssertOpComplete();
  }

  private static void vmResume(IsolateRef isolateRef, final StepOption step) {
    final String id = isolateRef.getId();
    vmService.resume(id, step, null, new SuccessConsumer() {
      @Override
      public void onError(RPCError error) {
        showRPCError(error);
      }

      @Override
      public void received(Success response) {
        if (step == null) {
          System.out.println("Resumed isolate " + id);
        } else {
          System.out.println("Step " + step + " isolate " + id);
        }
      }
    });
    // Do not wait for confirmation, but display error if it occurs
  }

  private static void vmStreamListen(String streamId) {
    final OpLatch latch = new OpLatch();
    vmService.streamListen(streamId, new SuccessConsumer() {
      @Override
      public void onError(RPCError error) {
        showRPCError(error);
      }

      @Override
      public void received(Success response) {
        System.out.println("Subscribed to debug event stream");
        latch.opComplete();
      }
    });
    latch.waitAndAssertOpComplete();
  }

  private static void waitForProcessExit() {
    if (actualVmServiceVersionMajor == 2) {
      // Don't wait for VM 1.12 - protocol 2.1
      return;
    }
    long end = System.currentTimeMillis() + 5000;
    while (true) {
      try {
        System.out.println("Exit code: " + process.exitValue());
        return;
      } catch (IllegalThreadStateException e) {
        // fall through to wait for exit
      }
      if (System.currentTimeMillis() >= end) {
        throw new RuntimeException("Expected child process to finish");
      }
      sleep(10);
    }
  }
}
