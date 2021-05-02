// stb_wingraph.h  v0.01 - public domain windows graphics programming
// wraps WinMain, ChoosePixelFormat, ChangeDisplayResolution, etc. for
// doing OpenGL graphics
//
// in ONE source file, put '#define STB_DEFINE' before including this
// OR put '#define STB_WINMAIN' to define a WinMain that calls stbwingraph_main(void)
//
// @TODO:
//    2d rendering interface (that can be done easily in software)
//    STB_WINGRAPH_SOFTWARE -- 2d software rendering only
//    STB_WINGRAPH_OPENGL   -- OpenGL only


#ifndef INCLUDE_STB_WINGRAPH_H
#define INCLUDE_STB_WINGRAPH_H

#ifdef STB_WINMAIN
   #ifndef STB_DEFINE
      #define STB_DEFINE
      #define STB_WINGRAPH_DISABLE_DEFINE_AT_END
   #endif
#endif

#ifdef STB_DEFINE
   #pragma comment(lib, "opengl32.lib")
   #pragma comment(lib, "glu32.lib")
   #pragma comment(lib, "winmm.lib")
   #pragma comment(lib, "gdi32.lib")
   #pragma comment(lib, "user32.lib")
#endif

#ifdef __cplusplus
#define STB_EXTERN extern "C"
#else
#define STB_EXTERN
#endif

#ifdef STB_DEFINE
#ifndef _WINDOWS_
   #ifdef APIENTRY
   #undef APIENTRY
   #endif
   #ifdef WINGDIAPI
   #undef WINGDIAPI
   #endif
   #define _WIN32_WINNT 0x0400  // WM_MOUSEWHEEL
   #include <windows.h>
#endif
#include <stdio.h>
#include <math.h>
#include <time.h>
#include <string.h>
#include <assert.h>
#endif

typedef void * stbwingraph_hwnd;
typedef void * stbwingraph_hinstance;

enum
{
   STBWINGRAPH_unprocessed = -(1 << 24),
   STBWINGRAPH_do_not_show,
   STBWINGRAPH_winproc_exit,
   STBWINGRAPH_winproc_update,
   STBWINGRAPH_update_exit,
   STBWINGRAPH_update_pause,
};

typedef enum
{
   STBWGE__none=0,

   STBWGE_create,
   STBWGE_create_postshow,
   STBWGE_draw,
   STBWGE_destroy,
   STBWGE_char,
   STBWGE_keydown,
   STBWGE_syskeydown,
   STBWGE_keyup,
   STBWGE_syskeyup,
   STBWGE_deactivate,
   STBWGE_activate,
   STBWGE_size,

   STBWGE_mousemove ,
   STBWGE_leftdown  , STBWGE_leftup  ,
   STBWGE_middledown, STBWGE_middleup,
   STBWGE_rightdown , STBWGE_rightup ,
   STBWGE_mousewheel,
} stbwingraph_event_type;

typedef struct
{
   stbwingraph_event_type type;

   // for input events (mouse, keyboard)
   int mx,my; // mouse x & y
   int dx,dy;
   int shift, ctrl, alt;

   // for keyboard events
   int key;

   // for STBWGE_size:
   int width, height;

   // for STBWGE_crate
   int did_share_lists;  // if true, wglShareLists succeeded

   void *handle;

} stbwingraph_event;

typedef int (*stbwingraph_window_proc)(void *data, stbwingraph_event *event);

extern stbwingraph_hinstance   stbwingraph_app;
extern stbwingraph_hwnd        stbwingraph_primary_window;
extern int                     stbwingraph_request_fullscreen;
extern int                     stbwingraph_request_windowed;

STB_EXTERN void stbwingraph_ods(char *str, ...);
STB_EXTERN int stbwingraph_MessageBox(stbwingraph_hwnd win, unsigned int type,
                                              char *caption, char *text, ...);
STB_EXTERN int stbwingraph_ChangeResolution(unsigned int w, unsigned int h,
                                      unsigned int bits, int use_message_box);
STB_EXTERN int stbwingraph_SetPixelFormat(stbwingraph_hwnd win, int color_bits,
            int alpha_bits, int depth_bits, int stencil_bits, int accum_bits);
STB_EXTERN int stbwingraph_DefineClass(void *hinstance, char *iconname);
STB_EXTERN void stbwingraph_SwapBuffers(void *win);
STB_EXTERN void stbwingraph_Priority(int n);

STB_EXTERN void stbwingraph_MakeFonts(void *window, int font_base);
STB_EXTERN void stbwingraph_ShowWindow(void *window);
STB_EXTERN void *stbwingraph_CreateWindow(int primary, stbwingraph_window_proc func, void *data, char *text, int width, int height, int fullscreen, int resizeable, int dest_alpha, int stencil);
STB_EXTERN void *stbwingraph_CreateWindowSimple(stbwingraph_window_proc func, int width, int height);
STB_EXTERN void *stbwingraph_CreateWindowSimpleFull(stbwingraph_window_proc func, int fullscreen, int ww, int wh, int fw, int fh);
STB_EXTERN void stbwingraph_DestroyWindow(void *window);
STB_EXTERN void stbwingraph_ShowCursor(void *window, int visible);
STB_EXTERN float stbwingraph_GetTimestep(float minimum_time);
STB_EXTERN void stbwingraph_SetGLWindow(void *win);
typedef int (*stbwingraph_update)(float timestep, int real, int in_client);
STB_EXTERN int stbwingraph_MainLoop(stbwingraph_update func, float mintime);

#ifdef STB_DEFINE
stbwingraph_hinstance   stbwingraph_app;
stbwingraph_hwnd        stbwingraph_primary_window;
int stbwingraph_request_fullscreen;
int stbwingraph_request_windowed;

void stbwingraph_ods(char *str, ...)
{
   char buffer[1024];
   va_list v;
   va_start(v,str);
   vsprintf(buffer, str, v);
   va_end(v);
   OutputDebugString(buffer);
}

int stbwingraph_MessageBox(stbwingraph_hwnd win, unsigned int type, char *caption, char *text, ...)
{
   va_list v;
   char buffer[1024];
   va_start(v, text);
   vsprintf(buffer, text, v);
   va_end(v);
   return MessageBox(win, buffer, caption, type);
}

void stbwingraph_Priority(int n)
{
   int p;
   switch (n) {
      case -1: p = THREAD_PRIORITY_BELOW_NORMAL; break;
      case 0: p = THREAD_PRIORITY_NORMAL; break;
      case 1: p = THREAD_PRIORITY_ABOVE_NORMAL; break;
      default:
         if (n < 0) p = THREAD_PRIORITY_LOWEST;
         else p = THREAD_PRIORITY_HIGHEST;
   }
   SetThreadPriority(GetCurrentThread(), p);
}

static void stbwingraph_ResetResolution(void)
{
   ChangeDisplaySettings(NULL, 0);
}

static void stbwingraph_RegisterResetResolution(void)
{
   static int done=0;
   if (!done) {
      done = 1;
      atexit(stbwingraph_ResetResolution);
   }
}

int stbwingraph_ChangeResolution(unsigned int w, unsigned int h, unsigned int bits, int use_message_box)
{
   DEVMODE mode;
   int res;
   
   int i, tries=0;
   for (i=0; ; ++i) {
      int success = EnumDisplaySettings(NULL, i, &mode);
      if (!success) break;
      if (mode.dmBitsPerPel == bits && mode.dmPelsWidth == w && mode.dmPelsHeight == h) {
         ++tries;
         success = ChangeDisplaySettings(&mode, CDS_FULLSCREEN); 
         if (success == DISP_CHANGE_SUCCESSFUL) {
            stbwingraph_RegisterResetResolution();
            return TRUE;
         }
         break;
      }
   }

   if (!tries) {
      if (use_message_box)
         stbwingraph_MessageBox(stbwingraph_primary_window, MB_ICONERROR, NULL, "The resolution %d x %d x %d-bits is not supported.", w, h, bits);
      return FALSE;
   }

   // we tried but failed, so try explicitly doing it without specifying refresh rate

   // Win95 support logic
   mode.dmBitsPerPel = bits; 
   mode.dmPelsWidth = w; 
   mode.dmPelsHeight = h; 
   mode.dmFields = DM_BITSPERPEL | DM_PELSWIDTH | DM_PELSHEIGHT; 

   res = ChangeDisplaySettings(&mode, CDS_FULLSCREEN);

   switch (res) {
      case DISP_CHANGE_SUCCESSFUL:
         stbwingraph_RegisterResetResolution();
         return TRUE;

      case DISP_CHANGE_RESTART:
         if (use_message_box)
            stbwingraph_MessageBox(stbwingraph_primary_window, MB_ICONERROR, NULL, "Please set your desktop to %d-bit color and then try again.");
         return FALSE;

      case DISP_CHANGE_FAILED:
         if (use_message_box)
            stbwingraph_MessageBox(stbwingraph_primary_window, MB_ICONERROR, NULL, "The hardware failed to change modes.");
         return FALSE;

      case DISP_CHANGE_BADMODE:
         if (use_message_box)
            stbwingraph_MessageBox(stbwingraph_primary_window, MB_ICONERROR, NULL, "The resolution %d x %d x %d-bits is not supported.", w, h, bits);
         return FALSE;

      default:
         if (use_message_box)
            stbwingraph_MessageBox(stbwingraph_primary_window, MB_ICONERROR, NULL, "An unknown error prevented a change to a %d x %d x %d-bit display.", w, h, bits);
         return FALSE;
   }
}

int stbwingraph_SetPixelFormat(stbwingraph_hwnd win, int color_bits, int alpha_bits, int depth_bits, int stencil_bits, int accum_bits)
{
   HDC dc = GetDC(win);
   PIXELFORMATDESCRIPTOR pfd = { sizeof(pfd) };
   int                   pixel_format;

   pfd.nVersion = 1;
   pfd.dwFlags = PFD_SUPPORT_OPENGL | PFD_DRAW_TO_WINDOW | PFD_DOUBLEBUFFER;
   pfd.dwLayerMask = PFD_MAIN_PLANE;
   pfd.iPixelType = PFD_TYPE_RGBA;
   pfd.cColorBits = color_bits;
   pfd.cAlphaBits = alpha_bits;
   pfd.cDepthBits = depth_bits;
   pfd.cStencilBits = stencil_bits;
   pfd.cAccumBits = accum_bits;

   pixel_format = ChoosePixelFormat(dc, &pfd);
   if (!pixel_format) return FALSE;

   if (!DescribePixelFormat(dc, pixel_format, sizeof(PIXELFORMATDESCRIPTOR), &pfd))
      return FALSE;
   SetPixelFormat(dc, pixel_format, &pfd);

   return TRUE;
}

typedef struct
{
   // app data
   stbwingraph_window_proc func;
   void *data;
   // creation parameters
   int   color, alpha, depth, stencil, accum;
   HWND  share_window;
   HWND  window;
   // internal data
   HGLRC rc;
   HDC   dc;
   int   hide_mouse;
   int   in_client;
   int   active;
   int   did_share_lists;
   int   mx,my; // last mouse positions
} stbwingraph__window;

static void stbwingraph__inclient(stbwingraph__window *win, int state)
{
   if (state != win->in_client) {
      win->in_client = state;
      if (win->hide_mouse)
         ShowCursor(!state);
   }
}

static void stbwingraph__key(stbwingraph_event *e, int type, int key, stbwingraph__window *z)
{
   e->type  = type;
   e->key   = key;
   e->shift = (GetKeyState(VK_SHIFT)   < 0);
   e->ctrl  = (GetKeyState(VK_CONTROL) < 0);
   e->alt   = (GetKeyState(VK_MENU)    < 0);
   if  (z) {
      e->mx    = z->mx;
      e->my    = z->my;
   } else {
      e->mx = e->my = 0;
   }
   e->dx = e->dy = 0;
}

static void stbwingraph__mouse(stbwingraph_event *e, int type, WPARAM wparam, LPARAM lparam, int capture, void *wnd, stbwingraph__window *z)
{
   static int captured = 0;
   e->type = type;
   e->mx = (short) LOWORD(lparam);
   e->my = (short) HIWORD(lparam);
   if (!z || z->mx == -(1 << 30)) {
      e->dx = e->dy = 0;
   } else {
      e->dx = e->mx - z->mx;
      e->dy = e->my - z->my;
   }
   e->shift = (wparam & MK_SHIFT) != 0;
   e->ctrl  = (wparam & MK_CONTROL) != 0;
   e->alt   = (wparam & MK_ALT) != 0;
   if (z) {
      z->mx = e->mx;
      z->my = e->my;
   }
   if (capture) {
      if (!captured && capture == 1)
         SetCapture(wnd);
      captured += capture;
      if (!captured && capture == -1)
         ReleaseCapture();
      if (captured < 0) captured = 0;
   }
}

static void stbwingraph__mousewheel(stbwingraph_event *e, int type, WPARAM wparam, LPARAM lparam, int capture, void *wnd, stbwingraph__window *z)
{
   // lparam seems bogus!
   static int captured = 0;
   e->type = type;
   if (z) {
      e->mx = z->mx;
      e->my = z->my;
   }
   e->dx = e->dy = 0;
   e->shift = (wparam & MK_SHIFT) != 0;
   e->ctrl  = (wparam & MK_CONTROL) != 0;
   e->alt   = (GetKeyState(VK_MENU)    < 0);
   e->key = ((int) wparam >> 16);
}

int stbwingraph_force_update;
static int WINAPI stbwingraph_WinProc(HWND wnd, UINT msg, WPARAM wparam, LPARAM lparam)
{
   int allow_default = TRUE;
   stbwingraph_event e = { STBWGE__none };
   // the following line is wrong for 64-bit windows, but VC6 doesn't have GetWindowLongPtr
   stbwingraph__window *z = (stbwingraph__window *) GetWindowLong(wnd, GWL_USERDATA);

   switch (msg) {

      case WM_CREATE:
      {
         LPCREATESTRUCT lpcs = (LPCREATESTRUCT) lparam;
         assert(z == NULL);
         z = (stbwingraph__window *) lpcs->lpCreateParams;
         SetWindowLong(wnd, GWL_USERDATA, (LONG) z);
         z->dc = GetDC(wnd);
         if (stbwingraph_SetPixelFormat(wnd, z->color, z->alpha, z->depth, z->stencil, z->accum)) {
            z->rc = wglCreateContext(z->dc);
            if (z->rc) {
               e.type = STBWGE_create;
               z->did_share_lists = FALSE;
               if (z->share_window) {
                  stbwingraph__window *y = (stbwingraph__window *) GetWindowLong(z->share_window, GWL_USERDATA);
                  if (wglShareLists(z->rc, y->rc))
                     z->did_share_lists = TRUE;
               }
               wglMakeCurrent(z->dc, z->rc);
               return 0;
            }
         }
         return -1;
      }

      case WM_PAINT: {
         PAINTSTRUCT ps;
         HDC hdc = BeginPaint(wnd, &ps);
         SelectObject(hdc, GetStockObject(NULL_BRUSH));
         e.type = STBWGE_draw;
         e.handle = wnd;
         z->func(z->data, &e);
         EndPaint(wnd, &ps);
         return 0;
      }

      case WM_DESTROY:
         e.type = STBWGE_destroy;
         e.handle = wnd;
         if (z && z->func)
            z->func(z->data, &e);
         wglMakeCurrent(NULL, NULL) ; 
         if (z) {
            if (z->rc) wglDeleteContext(z->rc);
            z->dc = 0;
            z->rc = 0;
         }
         if (wnd == stbwingraph_primary_window)
            PostQuitMessage (0);
         return 0;

      case WM_CHAR:         stbwingraph__key(&e, STBWGE_char   , wparam, z); break;
      case WM_KEYDOWN:      stbwingraph__key(&e, STBWGE_keydown, wparam, z); break;
      case WM_KEYUP:        stbwingraph__key(&e, STBWGE_keyup  , wparam, z); break;

      case WM_NCMOUSEMOVE:  stbwingraph__inclient(z,0); break;
      case WM_MOUSEMOVE:    stbwingraph__inclient(z,1); stbwingraph__mouse(&e, STBWGE_mousemove,  wparam, lparam,0,wnd, z); break;
      case WM_LBUTTONDOWN:  stbwingraph__mouse(&e, STBWGE_leftdown,   wparam, lparam,1,wnd, z); break;
      case WM_MBUTTONDOWN:  stbwingraph__mouse(&e, STBWGE_middledown, wparam, lparam,1,wnd, z); break;
      case WM_RBUTTONDOWN:  stbwingraph__mouse(&e, STBWGE_rightdown,  wparam, lparam,1,wnd, z); break;
      case WM_LBUTTONUP:    stbwingraph__mouse(&e, STBWGE_leftup,     wparam, lparam,-1,wnd, z); break;
      case WM_MBUTTONUP:    stbwingraph__mouse(&e, STBWGE_middleup,   wparam, lparam,-1,wnd, z); break;
      case WM_RBUTTONUP:    stbwingraph__mouse(&e, STBWGE_rightup,    wparam, lparam,-1,wnd, z); break;
      case WM_MOUSEWHEEL:   stbwingraph__mousewheel(&e, STBWGE_mousewheel, wparam, lparam,0,wnd, z); break;

      case WM_ACTIVATE:
         allow_default = FALSE;
         if (LOWORD(wparam)==WA_INACTIVE ) {
            wglMakeCurrent(z->dc, NULL);
            e.type = STBWGE_deactivate;
            z->active = FALSE;
         } else {
            wglMakeCurrent(z->dc, z->rc);
            e.type = STBWGE_activate;
            z->active = TRUE;
         }
         e.handle = wnd;
         z->func(z->data, &e);
         return 0;

      case WM_SIZE: {
         RECT rect;
         allow_default = FALSE;
         GetClientRect(wnd, &rect);
         e.type = STBWGE_size;
         e.width = rect.right;
         e.height = rect.bottom;
         e.handle = wnd;
         z->func(z->data, &e);
         return 0;
      }

      default:
         return DefWindowProc (wnd, msg, wparam, lparam);
   }

   if (e.type != STBWGE__none) {
      int n;
      e.handle = wnd;
      n = z->func(z->data, &e);
      if (n == STBWINGRAPH_winproc_exit) {
         PostQuitMessage(0);
         n = 0;
      }
      if (n == STBWINGRAPH_winproc_update) {
         stbwingraph_force_update = TRUE;
         return 1;
      }
      if (n != STBWINGRAPH_unprocessed)
         return n;
   }
   return DefWindowProc (wnd, msg, wparam, lparam);
}

int stbwingraph_DefineClass(HINSTANCE hInstance, char *iconname)
{
   WNDCLASSEX  wndclass;

   stbwingraph_app = hInstance;

   wndclass.cbSize        = sizeof(wndclass);
   wndclass.style         = CS_OWNDC;
   wndclass.lpfnWndProc   = (WNDPROC) stbwingraph_WinProc;
   wndclass.cbClsExtra    = 0;
   wndclass.cbWndExtra    = 0;
   wndclass.hInstance     = hInstance;
   wndclass.hIcon         = LoadIcon(hInstance, iconname);
   wndclass.hCursor       = LoadCursor(NULL,IDC_ARROW);
   wndclass.hbrBackground = GetStockObject(NULL_BRUSH);
   wndclass.lpszMenuName  = "zwingraph";
   wndclass.lpszClassName = "zwingraph";
   wndclass.hIconSm       = NULL;

   if (!RegisterClassEx(&wndclass))
      return FALSE;
   return TRUE;
}

void stbwingraph_ShowWindow(void *window)
{
   stbwingraph_event e = { STBWGE_create_postshow };
   stbwingraph__window *z = (stbwingraph__window *) GetWindowLong(window, GWL_USERDATA);
   ShowWindow(window, SW_SHOWNORMAL);
   InvalidateRect(window, NULL, TRUE);
   UpdateWindow(window);
   e.handle = window;
   z->func(z->data, &e);
}

void *stbwingraph_CreateWindow(int primary, stbwingraph_window_proc func, void *data, char *text,
           int width, int height, int fullscreen, int resizeable, int dest_alpha, int stencil)
{
   HWND win;
   DWORD dwstyle;
   stbwingraph__window *z = (stbwingraph__window *) malloc(sizeof(*z));

   if (z == NULL) return NULL;
   memset(z, 0, sizeof(*z));
   z->color = 24;
   z->depth = 24;
   z->alpha = dest_alpha;
   z->stencil = stencil;
   z->func = func;
   z->data = data;
   z->mx = -(1 << 30);
   z->my = 0;

   if (primary) {
      if (stbwingraph_request_windowed)
         fullscreen = FALSE;
      else if (stbwingraph_request_fullscreen)
         fullscreen = TRUE;
   }

   if (fullscreen) {
      #ifdef STB_SIMPLE
      stbwingraph_ChangeResolution(width, height, 32, 1);
      #else
      if (!stbwingraph_ChangeResolution(width, height, 32, 0))
         return NULL;
      #endif
      dwstyle = WS_POPUP | WS_CLIPSIBLINGS;
   } else {
      RECT rect;
      dwstyle = WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_MINIMIZEBOX;
      if (resizeable)
         dwstyle |= WS_SIZEBOX | WS_MAXIMIZEBOX;
      rect.top = 0;
      rect.left = 0;
      rect.right = width;
      rect.bottom = height;
      AdjustWindowRect(&rect, dwstyle, FALSE);
      width = rect.right - rect.left;
      height = rect.bottom - rect.top;
   }

   win = CreateWindow("zwingraph", text ? text : "sample", dwstyle,
                      CW_USEDEFAULT,0, width, height,
                      NULL, NULL, stbwingraph_app, z);

   if (win == NULL) return win;

   if (primary) {
      if (stbwingraph_primary_window)
         stbwingraph_DestroyWindow(stbwingraph_primary_window);
      stbwingraph_primary_window = win;
   }

   {
      stbwingraph_event e = { STBWGE_create };
      stbwingraph__window *z = (stbwingraph__window *) GetWindowLong(win, GWL_USERDATA);
      z->window = win;
      e.did_share_lists = z->did_share_lists;
      e.handle = win;
      if (z->func(z->data, &e) != STBWINGRAPH_do_not_show)
         stbwingraph_ShowWindow(win);
   }

   return win;
}

void *stbwingraph_CreateWindowSimple(stbwingraph_window_proc func, int width, int height)
{
   int fullscreen = 0;
   #ifndef _DEBUG
   if (width ==  640 && height ==  480) fullscreen = 1;
   if (width ==  800 && height ==  600) fullscreen = 1;
   if (width == 1024 && height ==  768) fullscreen = 1;
   if (width == 1280 && height == 1024) fullscreen = 1;
   if (width == 1600 && height == 1200) fullscreen = 1;
   //@TODO: widescreen widths
   #endif
   return stbwingraph_CreateWindow(1, func, NULL, NULL, width, height, fullscreen, 1, 0, 0);
}

void *stbwingraph_CreateWindowSimpleFull(stbwingraph_window_proc func, int fullscreen, int ww, int wh, int fw, int fh)
{
   if (fullscreen == -1) {
   #ifdef _DEBUG
      fullscreen = 0;
   #else
      fullscreen = 1;
   #endif
   }

   if (fullscreen) {
      if (fw) ww = fw;
      if (fh) wh = fh;
   }
   return stbwingraph_CreateWindow(1, func, NULL, NULL, ww, wh, fullscreen, 1, 0, 0);
}

void stbwingraph_DestroyWindow(void *window)
{
   stbwingraph__window *z = (stbwingraph__window *) GetWindowLong(window, GWL_USERDATA);
   DestroyWindow(window);
   free(z);
   if (stbwingraph_primary_window == window)
      stbwingraph_primary_window = NULL;
}

void stbwingraph_ShowCursor(void *window, int visible)
{
   int hide;
   stbwingraph__window *win;
   if (!window)
      window = stbwingraph_primary_window;
   win = (stbwingraph__window *) GetWindowLong((HWND) window, GWL_USERDATA);
   hide = !visible;
   if (hide != win->hide_mouse) {
      win->hide_mouse = hide;
      if (!hide)
         ShowCursor(TRUE);
      else if (win->in_client)
         ShowCursor(FALSE);
   }
}

float stbwingraph_GetTimestep(float minimum_time)
{
   float elapsedTime;
   double thisTime;
   static double lastTime = -1;
   
   if (lastTime == -1)
      lastTime = timeGetTime() / 1000.0 - minimum_time;

   for(;;) {
      thisTime = timeGetTime() / 1000.0;
      elapsedTime = (float) (thisTime - lastTime);
      if (elapsedTime >= minimum_time) {
         lastTime = thisTime;         
         return elapsedTime;
      }
      #if 1
      Sleep(2);
      #endif
   }
}

void stbwingraph_SetGLWindow(void *win)
{
   stbwingraph__window *z = (stbwingraph__window *) GetWindowLong(win, GWL_USERDATA);
   if (z)
      wglMakeCurrent(z->dc, z->rc);
}

void stbwingraph_MakeFonts(void *window, int font_base)
{
   wglUseFontBitmaps(GetDC(window ? window : stbwingraph_primary_window), 0, 256, font_base);
}

// returns 1 if WM_QUIT, 0 if 'func' returned 0
int stbwingraph_MainLoop(stbwingraph_update func, float mintime)
{
   int needs_drawing = FALSE;
   MSG msg;

   int is_animating = TRUE;
   if (mintime <= 0) mintime = 0.01f;

   for(;;) {
      int n;

      is_animating = TRUE;
      // wait for a message if: (a) we're animating and there's already a message
      // or (b) we're not animating
      if (!is_animating || PeekMessage(&msg, NULL, 0, 0, PM_NOREMOVE)) {
         stbwingraph_force_update = FALSE;
         if (GetMessage(&msg, NULL, 0, 0)) {
            TranslateMessage(&msg);
            DispatchMessage(&msg);
         } else {
            return 1;   // WM_QUIT
         }

         // only force a draw for certain messages...
         // if I don't do this, we peg at 50% for some reason... must
         // be a bug somewhere, because we peg at 100% when rendering...
         // very weird... looks like NVIDIA is pumping some messages
         // through our pipeline? well, ok, I guess if we can get
         // non-user-generated messages we have to do this
         if (!stbwingraph_force_update) {
            switch (msg.message) {
               case WM_MOUSEMOVE:
               case WM_NCMOUSEMOVE:
                  break;
               case WM_CHAR:         
               case WM_KEYDOWN:      
               case WM_KEYUP:        
               case WM_LBUTTONDOWN:  
               case WM_MBUTTONDOWN:  
               case WM_RBUTTONDOWN:  
               case WM_LBUTTONUP:    
               case WM_MBUTTONUP:    
               case WM_RBUTTONUP:    
               case WM_TIMER:
               case WM_SIZE:
               case WM_ACTIVATE:
                  needs_drawing = TRUE;
                  break;
            }
         } else
            needs_drawing = TRUE;
      }

      // if another message, process that first
      // @TODO: i don't think this is working, because I can't key ahead
      // in the SVT demo app
      if (PeekMessage(&msg, NULL, 0,0, PM_NOREMOVE))
         continue;

      // and now call update
      if (needs_drawing || is_animating) {
         int real=1, in_client=1;
         if (stbwingraph_primary_window) {
            stbwingraph__window *z = (stbwingraph__window *) GetWindowLong(stbwingraph_primary_window, GWL_USERDATA);
            if (z && !z->active) {
               real = 0;
            }
            if (z)
               in_client = z->in_client;
         }

         if (stbwingraph_primary_window)
            stbwingraph_SetGLWindow(stbwingraph_primary_window);
         n = func(stbwingraph_GetTimestep(mintime), real, in_client);
         if (n == STBWINGRAPH_update_exit)
            return 0; // update_quit

         is_animating = (n != STBWINGRAPH_update_pause);

         needs_drawing = FALSE;
      }
   }
}

void stbwingraph_SwapBuffers(void *win)
{
   stbwingraph__window *z;
   if (win == NULL) win = stbwingraph_primary_window;
   z = (stbwingraph__window *) GetWindowLong(win, GWL_USERDATA);
   if (z && z->dc)
      SwapBuffers(z->dc);
}
#endif

#ifdef STB_WINMAIN    
void stbwingraph_main(void);

char *stb_wingraph_commandline;

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{
   {
      char buffer[1024];
      // add spaces to either side of the string
      buffer[0] = ' ';
      strcpy(buffer+1, lpCmdLine);
      strcat(buffer, " ");
      if (strstr(buffer, " -reset ")) {
         ChangeDisplaySettings(NULL, 0); 
         exit(0);
      }
      if (strstr(buffer, " -window ") || strstr(buffer, " -windowed "))
         stbwingraph_request_windowed = TRUE;
      else if (strstr(buffer, " -full ") || strstr(buffer, " -fullscreen "))
         stbwingraph_request_fullscreen = TRUE;
   }
   stb_wingraph_commandline = lpCmdLine;

   stbwingraph_DefineClass(hInstance, "appicon");
   stbwingraph_main();

   return 0;
}
#endif

#undef STB_EXTERN
#ifdef STB_WINGRAPH_DISABLE_DEFINE_AT_END
#undef STB_DEFINE
#endif

#endif // INCLUDE_STB_WINGRAPH_H
