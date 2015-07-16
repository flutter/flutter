// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This tool is used to benchmark the render model used by the compositor

// Most of this file is derived from the source of the tile_render_bench tool,
// and has been changed to  support running a sequence of independent
// simulations for our different render models and test cases.

#include <stdio.h>
#include <sys/dir.h>
#include <sys/file.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <X11/keysym.h>
#include <X11/Xlib.h>
#include <X11/Xutil.h>

#include <queue>
#include <string>
#include <vector>

#include "base/at_exit.h"
#include "base/basictypes.h"
#include "base/bind.h"
#include "base/command_line.h"
#include "base/files/file_enumerator.h"
#include "base/files/file_path.h"
#include "base/files/file_util.h"
#include "base/memory/scoped_ptr.h"
#include "base/message_loop/message_loop.h"
#include "base/time/time.h"
#include "gpu/tools/compositor_model_bench/render_model_utils.h"
#include "gpu/tools/compositor_model_bench/render_models.h"
#include "gpu/tools/compositor_model_bench/render_tree.h"
#include "ui/gl/gl_surface.h"

using base::TimeTicks;
using base::DirectoryExists;
using base::PathExists;
using std::queue;
using std::string;

struct SimulationSpecification {
  string simulation_name;
  base::FilePath input_path;
  RenderModel model_under_test;
  TimeTicks simulation_start_time;
  int frames_rendered;
};

// Forward declarations
class Simulator;
void _process_events(Simulator* sim);
void _update_loop(Simulator* sim);

class Simulator {
 public:
  Simulator(int seconds_per_test, const base::FilePath& output_path)
     : current_sim_(NULL),
       output_path_(output_path),
       seconds_per_test_(seconds_per_test),
       display_(NULL),
       window_(0),
       gl_context_(NULL),
       window_width_(WINDOW_WIDTH),
       window_height_(WINDOW_HEIGHT),
       weak_factory_(this) {
  }

  ~Simulator() {
    // Cleanup GL.
    glXMakeCurrent(display_, 0, NULL);
    glXDestroyContext(display_, gl_context_);

    // Destroy window and display.
    XDestroyWindow(display_, window_);
    XCloseDisplay(display_);
  }

  void QueueTest(const base::FilePath& path) {
    SimulationSpecification spec;

    // To get a std::string, we'll try to get an ASCII simulation name.
    // If the name of the file wasn't ASCII, this will give an empty simulation
    //  name, but that's not really harmful (we'll still warn about it though.)
    spec.simulation_name = path.BaseName().RemoveExtension().MaybeAsASCII();
    if (spec.simulation_name.empty()) {
      LOG(WARNING) << "Simulation for path " << path.LossyDisplayName() <<
        " will have a blank simulation name, since the file name isn't ASCII";
    }
    spec.input_path = path;
    spec.model_under_test = ForwardRenderModel;
    spec.frames_rendered = 0;

    sims_remaining_.push(spec);

    // The following lines are commented out pending the addition
    // of the new render model once this version gets fully checked in.
    //
    //  spec.model_under_test = KDTreeRenderModel;
    //  sims_remaining_.push(spec);
  }

  void Run() {
    if (!sims_remaining_.size()) {
      LOG(WARNING) << "No configuration files loaded.";
      return;
    }

    base::AtExitManager at_exit;
    base::MessageLoop loop;
    if (!InitX11() || !InitGLContext()) {
      LOG(FATAL) << "Failed to set up GUI.";
    }

    InitBuffers();

    LOG(INFO) << "Running " << sims_remaining_.size() << " simulations.";

    loop.PostTask(FROM_HERE,
                  base::Bind(&Simulator::ProcessEvents,
                             weak_factory_.GetWeakPtr()));
    loop.Run();
  }

  void ProcessEvents() {
    // Consume all the X events.
    while (XPending(display_)) {
      XEvent e;
      XNextEvent(display_, &e);
      switch (e.type) {
        case Expose:
          UpdateLoop();
          break;
        case ConfigureNotify:
          Resize(e.xconfigure.width, e.xconfigure.height);
          break;
        default:
          break;
      }
    }
  }

  void UpdateLoop() {
    if (UpdateTestStatus())
      UpdateCurrentTest();
  }

 private:
  // Initialize X11. Returns true if successful. This method creates the
  // X11 window. Further initialization is done in X11VideoRenderer.
  bool InitX11() {
    display_ = XOpenDisplay(NULL);
    if (!display_) {
      LOG(FATAL) << "Cannot open display";
      return false;
    }

    // Get properties of the screen.
    int screen = DefaultScreen(display_);
    int root_window = RootWindow(display_, screen);

    // Creates the window.
    window_ = XCreateSimpleWindow(display_,
                                  root_window,
                                  1,
                                  1,
                                  window_width_,
                                  window_height_,
                                  0,
                                  BlackPixel(display_, screen),
                                  BlackPixel(display_, screen));
    XStoreName(display_, window_, "Compositor Model Bench");

    XSelectInput(display_, window_,
                 ExposureMask | KeyPressMask | StructureNotifyMask);
    XMapWindow(display_, window_);

    XResizeWindow(display_, window_, WINDOW_WIDTH, WINDOW_HEIGHT);

    return true;
  }

  // Initialize the OpenGL context.
  bool InitGLContext() {
    if (!gfx::GLSurface::InitializeOneOff()) {
      LOG(FATAL) << "gfx::GLSurface::InitializeOneOff failed";
      return false;
    }

    XWindowAttributes attributes;
    XGetWindowAttributes(display_, window_, &attributes);
    XVisualInfo visual_info_template;
    visual_info_template.visualid = XVisualIDFromVisual(attributes.visual);
    int visual_info_count = 0;
    XVisualInfo* visual_info_list = XGetVisualInfo(display_, VisualIDMask,
                                                   &visual_info_template,
                                                   &visual_info_count);

    for (int i = 0; i < visual_info_count && !gl_context_; ++i) {
      gl_context_ = glXCreateContext(display_, visual_info_list + i, 0,
                                     True /* Direct rendering */);
    }

    XFree(visual_info_list);
    if (!gl_context_) {
      return false;
    }

    if (!glXMakeCurrent(display_, window_, gl_context_)) {
      glXDestroyContext(display_, gl_context_);
      gl_context_ = NULL;
      return false;
    }

    return true;
  }

  bool InitializeNextTest() {
    SimulationSpecification& spec = sims_remaining_.front();
    LOG(INFO) << "Initializing test for " << spec.simulation_name <<
        "(" << ModelToString(spec.model_under_test) << ")";
    const base::FilePath& path = spec.input_path;

    RenderNode* root = NULL;
    if (!(root = BuildRenderTreeFromFile(path))) {
      LOG(ERROR) << "Couldn't parse test configuration file " <<
          path.LossyDisplayName();
      return false;
    }

    current_sim_ = ConstructSimulationModel(spec.model_under_test,
                                            root,
                                            window_width_,
                                            window_height_);
    if (!current_sim_)
      return false;

    return true;
  }

  void CleanupCurrentTest() {
    LOG(INFO) << "Finished test " << sims_remaining_.front().simulation_name;

    delete current_sim_;
    current_sim_ = NULL;
  }

  void UpdateCurrentTest() {
    ++sims_remaining_.front().frames_rendered;

    if (current_sim_)
      current_sim_->Update();

    glXSwapBuffers(display_, window_);

    XExposeEvent ev = { Expose, 0, 1, display_, window_,
                        0, 0, WINDOW_WIDTH, WINDOW_HEIGHT, 0 };
    XSendEvent(display_,
      window_,
      False,
      ExposureMask,
      reinterpret_cast<XEvent*>(&ev));

    base::MessageLoop::current()->PostTask(
        FROM_HERE,
        base::Bind(&Simulator::UpdateLoop, weak_factory_.GetWeakPtr()));
  }

  void DumpOutput() {
    LOG(INFO) << "Successfully ran " << sims_completed_.size() << " tests";

    FILE* f = base::OpenFile(output_path_, "w");

    if (!f) {
      LOG(ERROR) << "Failed to open output file " <<
        output_path_.LossyDisplayName();
      exit(-1);
    }

    LOG(INFO) << "Writing results to " << output_path_.LossyDisplayName();

    fputs("{\n\t\"results\": [\n", f);

    while (sims_completed_.size()) {
      SimulationSpecification i = sims_completed_.front();
      fprintf(f,
        "\t\t{\"simulation_name\":\"%s\",\n"
        "\t\t\t\"render_model\":\"%s\",\n"
        "\t\t\t\"frames_drawn\":%d\n"
        "\t\t},\n",
        i.simulation_name.c_str(),
        ModelToString(i.model_under_test),
        i.frames_rendered);
      sims_completed_.pop();
    }

    fputs("\t]\n}", f);
    base::CloseFile(f);
  }

  bool UpdateTestStatus() {
    TimeTicks& current_start = sims_remaining_.front().simulation_start_time;
    base::TimeDelta d = TimeTicks::Now() - current_start;
    if (!current_start.is_null() && d.InSeconds() > seconds_per_test_) {
      CleanupCurrentTest();
      sims_completed_.push(sims_remaining_.front());
      sims_remaining_.pop();
    }

    if (sims_remaining_.size() &&
      sims_remaining_.front().simulation_start_time.is_null()) {
      while (sims_remaining_.size() && !InitializeNextTest()) {
        sims_remaining_.pop();
      }
      if (sims_remaining_.size()) {
        sims_remaining_.front().simulation_start_time = TimeTicks::Now();
      }
    }

    if (!sims_remaining_.size()) {
      DumpOutput();
      base::MessageLoop::current()->Quit();
      return false;
    }

    return true;
  }

  void Resize(int width, int height) {
    window_width_ = width;
    window_height_ = height;
    if (current_sim_)
      current_sim_->Resize(window_width_, window_height_);
  }

  // Simulation task list for this execution
  RenderModelSimulator* current_sim_;
  queue<SimulationSpecification> sims_remaining_;
  queue<SimulationSpecification> sims_completed_;
  base::FilePath output_path_;
  // Amount of time to run each simulation
  int seconds_per_test_;
  // GUI data
  Display* display_;
  Window window_;
  GLXContext gl_context_;
  int window_width_;
  int window_height_;
  base::WeakPtrFactory<Simulator> weak_factory_;
};

int main(int argc, char* argv[]) {
  base::CommandLine::Init(argc, argv);
  const base::CommandLine* cl = base::CommandLine::ForCurrentProcess();

  if (argc != 3 && argc != 4) {
    LOG(INFO) << "Usage: \n" <<
      cl->GetProgram().BaseName().LossyDisplayName() <<
      "--in=[input path] --out=[output path] (duration=[seconds])\n"
      "The input path specifies either a JSON configuration file or\n"
      "a directory containing only these files\n"
      "(if a directory is specified, simulations will be run for\n"
      "all files in that directory and subdirectories)\n"
      "The optional duration parameter specifies the (integer)\n"
      "number of seconds to be spent on each simulation.\n"
      "Performance measurements for the specified simulation(s) are\n"
      "written to the output path.";
    return -1;
  }

  int seconds_per_test = 1;
  if (cl->HasSwitch("duration")) {
    seconds_per_test = atoi(cl->GetSwitchValueASCII("duration").c_str());
  }

  Simulator sim(seconds_per_test, cl->GetSwitchValuePath("out"));
  base::FilePath inPath = cl->GetSwitchValuePath("in");

  if (!PathExists(inPath)) {
    LOG(FATAL) << "Path does not exist: " << inPath.LossyDisplayName();
    return -1;
  }

  if (DirectoryExists(inPath)) {
    LOG(INFO) << "(input path is a directory)";
    base::FileEnumerator dirItr(inPath, true, base::FileEnumerator::FILES);
    for (base::FilePath f = dirItr.Next(); !f.empty(); f = dirItr.Next()) {
      sim.QueueTest(f);
    }
  } else {
    LOG(INFO) << "(input path is a file)";
    sim.QueueTest(inPath);
  }

  sim.Run();

  return 0;
}
