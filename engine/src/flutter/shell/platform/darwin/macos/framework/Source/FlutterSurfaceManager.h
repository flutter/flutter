#import <Cocoa/Cocoa.h>

// Manages the IOSurfaces for FlutterView
@interface FlutterSurfaceManager : NSObject

- (instancetype)initWithLayer:(CALayer*)layer openGLContext:(NSOpenGLContext*)opengLContext;

- (void)ensureSurfaceSize:(CGSize)size;
- (void)swapBuffers;

- (uint32_t)glFrameBufferId;

@end
