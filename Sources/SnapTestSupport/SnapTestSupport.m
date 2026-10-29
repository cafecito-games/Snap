#import "SnapTestSupport.h"
#import <objc/message.h>
#import <objc/runtime.h>
#import <mach-o/dyld.h>

static BOOL SnapHookInstalled = NO;

static void SnapInstallHook(void) {
    if (SnapHookInstalled) {
        return;
    }
    // The Swift base class is compiled into a different image than this file
    // (SnapTests rather than SnapTestSupport), so it may not be registered
    // yet when this library finishes loading.
    Class baseClass = NSClassFromString(@"SnapDynamicTestCase");
    if (baseClass == nil) {
        return;
    }

    Method buildMethod = class_getClassMethod(baseClass, @selector(snapBuildTestInvocations));
    if (buildMethod == NULL) {
        return;
    }

    // Adding `testInvocations` to the base class's metaclass makes XCTest
    // treat every Snap subclass as overriding it, which routes test
    // enumeration through the invocation-based path that dynamic tests need.
    Class metaclass = object_getClass(baseClass);
    class_addMethod(
        metaclass,
        @selector(testInvocations),
        method_getImplementation(buildMethod),
        method_getTypeEncoding(buildMethod));
    SnapHookInstalled = YES;
}

static void SnapImageWasAdded(const struct mach_header *header, intptr_t slide) {
    (void)header;
    (void)slide;
    SnapInstallHook();
}

void SnapInstallDynamicTestInvocations(void) {
    SnapInstallHook();
    if (!SnapHookInstalled) {
        // Retry for every image that loads later; the callback also fires
        // immediately for all already-loaded images.
        _dyld_register_func_for_add_image(SnapImageWasAdded);
    }
}

@implementation SnapTestInvocationFactory

+ (NSInvocation *)invocationForSelector:(SEL)selector {
    NSMethodSignature *signature = [NSMethodSignature signatureWithObjCTypes:"v@:"];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation setSelector:selector];
    return invocation;
}

@end

__attribute__((constructor))
static void SnapLoad(void) {
    SnapInstallDynamicTestInvocations();
}
