// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/win/message_window.h"

#include "base/lazy_instance.h"
#include "base/logging.h"
#include "base/process/memory.h"
#include "base/profiler/scoped_tracker.h"
#include "base/win/wrapped_window_proc.h"

const wchar_t kMessageWindowClassName[] = L"Chrome_MessageWindow";

namespace base {
namespace win {

// Used along with LazyInstance to register a window class for message-only
// windows created by MessageWindow.
class MessageWindow::WindowClass {
 public:
  WindowClass();
  ~WindowClass();

  ATOM atom() { return atom_; }
  HINSTANCE instance() { return instance_; }

 private:
  ATOM atom_;
  HINSTANCE instance_;

  DISALLOW_COPY_AND_ASSIGN(WindowClass);
};

static LazyInstance<MessageWindow::WindowClass> g_window_class =
    LAZY_INSTANCE_INITIALIZER;

MessageWindow::WindowClass::WindowClass()
    : atom_(0),
      instance_(base::GetModuleFromAddress(&MessageWindow::WindowProc)) {
  WNDCLASSEX window_class;
  window_class.cbSize = sizeof(window_class);
  window_class.style = 0;
  window_class.lpfnWndProc = &base::win::WrappedWindowProc<WindowProc>;
  window_class.cbClsExtra = 0;
  window_class.cbWndExtra = 0;
  window_class.hInstance = instance_;
  window_class.hIcon = NULL;
  window_class.hCursor = NULL;
  window_class.hbrBackground = NULL;
  window_class.lpszMenuName = NULL;
  window_class.lpszClassName = kMessageWindowClassName;
  window_class.hIconSm = NULL;
  atom_ = RegisterClassEx(&window_class);
  if (atom_ == 0) {
    PLOG(ERROR)
        << "Failed to register the window class for a message-only window";
  }
}

MessageWindow::WindowClass::~WindowClass() {
  if (atom_ != 0) {
    BOOL result = UnregisterClass(MAKEINTATOM(atom_), instance_);
    // Hitting this DCHECK usually means that some MessageWindow objects were
    // leaked. For example not calling
    // ui::Clipboard::DestroyClipboardForCurrentThread() results in a leaked
    // MessageWindow.
    DCHECK(result);
  }
}

MessageWindow::MessageWindow()
    : window_(NULL) {
}

MessageWindow::~MessageWindow() {
  DCHECK(CalledOnValidThread());

  if (window_ != NULL) {
    BOOL result = DestroyWindow(window_);
    DCHECK(result);
  }
}

bool MessageWindow::Create(const MessageCallback& message_callback) {
  return DoCreate(message_callback, NULL);
}

bool MessageWindow::CreateNamed(const MessageCallback& message_callback,
                                const string16& window_name) {
  return DoCreate(message_callback, window_name.c_str());
}

// static
HWND MessageWindow::FindWindow(const string16& window_name) {
  return FindWindowEx(HWND_MESSAGE, NULL, kMessageWindowClassName,
                      window_name.c_str());
}

bool MessageWindow::DoCreate(const MessageCallback& message_callback,
                             const wchar_t* window_name) {
  DCHECK(CalledOnValidThread());
  DCHECK(message_callback_.is_null());
  DCHECK(!window_);

  message_callback_ = message_callback;

  WindowClass& window_class = g_window_class.Get();
  window_ = CreateWindow(MAKEINTATOM(window_class.atom()), window_name, 0, 0, 0,
                         0, 0, HWND_MESSAGE, 0, window_class.instance(), this);
  if (!window_) {
    PLOG(ERROR) << "Failed to create a message-only window";
    return false;
  }

  return true;
}

// static
LRESULT CALLBACK MessageWindow::WindowProc(HWND hwnd,
                                           UINT message,
                                           WPARAM wparam,
                                           LPARAM lparam) {
  MessageWindow* self = reinterpret_cast<MessageWindow*>(
      GetWindowLongPtr(hwnd, GWLP_USERDATA));

  switch (message) {
    // Set up the self before handling WM_CREATE.
    case WM_CREATE: {
      CREATESTRUCT* cs = reinterpret_cast<CREATESTRUCT*>(lparam);
      self = reinterpret_cast<MessageWindow*>(cs->lpCreateParams);

      // Make |hwnd| available to the message handler. At this point the control
      // hasn't returned from CreateWindow() yet.
      self->window_ = hwnd;

      // Store pointer to the self to the window's user data.
      SetLastError(ERROR_SUCCESS);
      LONG_PTR result = SetWindowLongPtr(
          hwnd, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(self));
      CHECK(result != 0 || GetLastError() == ERROR_SUCCESS);
      break;
    }

    // Clear the pointer to stop calling the self once WM_DESTROY is
    // received.
    case WM_DESTROY: {
      SetLastError(ERROR_SUCCESS);
      LONG_PTR result = SetWindowLongPtr(hwnd, GWLP_USERDATA, NULL);
      CHECK(result != 0 || GetLastError() == ERROR_SUCCESS);
      break;
    }
  }

  // Handle the message.
  if (self) {
    LRESULT message_result;
    if (self->message_callback_.Run(message, wparam, lparam, &message_result))
      return message_result;
  }

  return DefWindowProc(hwnd, message, wparam, lparam);
}

}  // namespace win
}  // namespace base
