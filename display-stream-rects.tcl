source "lib/c.tcl"

set cc [c create]
$cc include <CoreGraphics/CoreGraphics.h>
$cc proc startDisplayStream {} void {
    CGRect displayBounds = CGDisplayBounds(CGMainDisplayID());
    CGFloat width = displayBounds.size.width;
    CGFloat height = displayBounds.size.height / 2.0;

    const void *keys[] = {
        kCGDisplayStreamSourceRect,
        kCGDisplayStreamShowCursor,
    };
    const void *values[] = {
        CGRectCreateDictionaryRepresentation(CGRectMake(0, 0, width, height)),
        0,
    };
    CFDictionaryRef properties = CFDictionaryCreate(NULL, keys, values, 1, NULL, NULL);

//        (NSString *) kCGDisplayStreamMinimumFrameTime: @0.1

//    NSLog(@"stream bounds %fx%f", width, height);
//    dispatch_queue_t queue = dispatch_queue_create("Screen Matching", NULL);
//    __block int dispatchNumber = 0;
    CGDisplayStreamRef stream = CGDisplayStreamCreateWithDispatchQueue(CGMainDisplayID(),
                                           width,
                                           height,
                                           'BGRA',
                                           properties, // TODO: should cursor show?
                                           dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                                           ^(CGDisplayStreamFrameStatus status,
                                             uint64_t displayTime,
                                             IOSurfaceRef  _Nullable frameSurface,
                                             CGDisplayStreamUpdateRef  _Nullable updateRef) {
        size_t dirtyRectsCount;
        const CGRect *dirtyRects = CGDisplayStreamUpdateGetRects(updateRef, kCGDisplayStreamUpdateDirtyRects, &dirtyRectsCount);
        for (size_t i = 0; i < dirtyRectsCount; i++) {
            const CGRect rect = dirtyRects[i];
            if (!(rect.size.width > width - 4 && rect.size.height > height - 4)) {
                printf("hello\n");
                // [dirtyRectsArr addObject:[NSValue valueWithRect:rect]];
            }
        }
    });
    CGDisplayStreamStart(stream);
}
$cc cflags -framework CoreGraphics -framework CoreFoundation
$cc compile

startDisplayStream

package require Tk
