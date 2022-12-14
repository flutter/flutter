#import <Cocoa/Cocoa.h>

/**
 * Takes care of synchronization between raster and platform thread.
 */
@interface FlutterThreadSynchronizer : NSObject

/**
 * Blocks current thread until there is frame available.
 * Used in FlutterEngineTest.
 */
- (void)blockUntilFrameAvailable;

/**
 * Called from platform thread. Blocks until commit with given size (or empty)
 * is requested.
 */
- (void)beginResize:(CGSize)size notify:(nonnull dispatch_block_t)notify;

/**
 * Called from raster thread. Schedules the given block on platform thread
 * and blocks until it is performed.
 *
 * If platform thread is blocked in `beginResize:` for given size (or size is empty),
 * unblocks platform thread.
 *
 * The notify block is guaranteed to be called within a core animation transaction.
 */
- (void)performCommit:(CGSize)size notify:(nonnull dispatch_block_t)notify;

/**
 * Called when shutting down. Unblocks everything and prevents any further synchronization.
 */
- (void)shutdown;

@end
