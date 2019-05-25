//
// Copyright 2016 Google Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import <UIKit/UIKit.h>

#import <EarlGrey/GREYDefines.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Provides interfaces for taking screenshots of the entire screen and UI elements of the App.
 */
@interface GREYScreenshotUtil : NSObject

/**
 *  Draws the application's main screen using the bitmap graphics context specified by the @c
 *  bitmapContextRef reference, centering it if the context size is different than the screen size.
 *  The provided reference must point to a CGBitmapContext. When @c afterUpdates is set to @c YES,
 *  this method waits for the screen to draw pending changes before taking a screenshot, otherwise
 *  the screenshot contains the current contents of the screen.
 *
 *  @param bitmapContextRef Target bitmap context for rendering.
 *  @param afterUpdates     Boolean indicating whether to render before (@c NO) or after (@c YES)
 *                          screen updates.
 */
+ (void)drawScreenInContext:(CGContextRef)bitmapContextRef afterScreenUpdates:(BOOL)afterUpdates;

/**
 *  @return An image of the current app's screen frame buffer. This method waits for any pending
 *          screen updates to go through before taking a screenshot. Returned image orientation is
 *          same as the current interface orientation.
 */
+ (UIImage *)takeScreenshot;

/**
 *  @return The App Store and iTunes Connect friendly image of the current screen frame buffer.
 */
+ (UIImage *)takeScreenshotForAppStore;

/**
 *  @return A snapshot of the provided @c element. @c element must be an instance of @c UIView or
 *          an accessibility element.
 */
+ (UIImage *)snapshotElement:(id)element;

/**
 *  Saves the provided @c image as a PNG to the given @c filename under the given @c directoryPath.
 *  If the given directory path doesn't exist, it will be created.
 *
 *  @param image         The source image.
 *  @param filename      The target file name.
 *  @param directoryPath The path to the directory where the image must be saved.
 *
 *  @return The complete filepath and name of the saved image or @c nil on failure.
 */
+ (NSString *)saveImageAsPNG:(UIImage *)image
                      toFile:(NSString *)filename
                 inDirectory:(NSString *)directoryPath;

@end

/**
 *  Returns a new buffer that contains XRGB pixels for the provided @c imageRef i.e. the alpha
 *  channel is removed. If @c outBitmapContext is not @c NULL, it is set to the bitmap context of
 *  the returned buffer and caller must call CGContextRelease on it. Each pixel in returned buffer
 *  occupies 4 bytes and the buffer must be free()'d by the caller.
 *
 *  @param imageRef       The source image.
 *  @param[out] outBmpCtx Optional bitmap context that holds the returned buffer.
 *
 *  @return A new buffer that contains XRGB pixels for the provided image.
 */
GREY_EXPORT unsigned char *_Nullable grey_createImagePixelDataFromCGImageRef(
    CGImageRef imageRef, CGContextRef _Nullable *_Nullable outBmpCtx);

NS_ASSUME_NONNULL_END
