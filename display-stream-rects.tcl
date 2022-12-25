package require Tk
text .t -yscrollcommand ".scroll set" -wrap none
scrollbar .scroll -command ".t yview"
pack .scroll -side right -fill y
pack .t -expand yes -fill both
wm geometry . "800x[expr {[winfo screenheight .]/2 - 100}]+0-50"

proc handleDisplayStreamUpdate {seq width height args} {
    wm title . "Stream with bounds ${width}x${height}, update number $seq"
    .t insert end "$seq $args\n"
    .t yview moveto 1
}

source "lib/c.tcl"

set cc [c create]
$cc include <CoreGraphics/CoreGraphics.h>
$cc proc startDisplayStream {Tcl_Interp* interp} void {
    CGRect displayBounds = CGDisplayBounds(CGMainDisplayID());
    CGFloat width = displayBounds.size.width;
    CGFloat height = displayBounds.size.height / 2.0; // half-height (top half of screen)

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

    __block int nextSequenceNumber = 0;
    CGDisplayStreamRef stream = CGDisplayStreamCreateWithDispatchQueue(
            CGMainDisplayID(),
            width, height,
            'BGRA',
            properties, // TODO: should cursor show?
            dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
            ^(CGDisplayStreamFrameStatus status,
              uint64_t displayTime,
              IOSurfaceRef  _Nullable frameSurface,
              CGDisplayStreamUpdateRef  _Nullable updateRef) {

        __block int sequenceNumber = nextSequenceNumber++;

        size_t dirtyRectsCount;
        const CGRect *dirtyRects = CGDisplayStreamUpdateGetRects(updateRef, kCGDisplayStreamUpdateDirtyRects, &dirtyRectsCount);

        char *s = calloc(10000, 1);
        int si = snprintf(s, 10000, "handleDisplayStreamUpdate %d %f %f",
                          sequenceNumber, width, height);

        for (size_t i = 0; i < dirtyRectsCount; i++) {
            const CGRect rect = dirtyRects[i];
            if (!(rect.size.width > width - 4 && rect.size.height > height - 4)) {
                // [dirtyRectsArr addObject:[NSValue valueWithRect:rect]];
                si += snprintf(s + si, 10000 - si,
                               " {%f %f %f %f}",
                               rect.origin.x, rect.origin.y,
                               rect.size.width, rect.size.height);
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{ Tcl_Eval(interp, s); });
    });
    CGDisplayStreamStart(stream);
}
$cc cflags -framework CoreGraphics -framework CoreFoundation
$cc compile

startDisplayStream
