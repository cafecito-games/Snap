#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Creates the invocations that XCTest runs for dynamically generated tests.
///
/// `NSInvocation` is not constructible from Swift, which is why this tiny
/// Objective-C helper exists at all.
@interface SnapTestInvocationFactory : NSObject

/// Returns an invocation for a `void` method with no arguments.
+ (NSInvocation *)invocationForSelector:(SEL)selector;

@end

/// Ensures `+[SnapDynamicTestCase testInvocations]` exists so every Snap test
/// subclass enumerates its previews through the invocation-based path.
///
/// Safe to call any number of times, from any image, and at any point during
/// process startup: installation waits until the Swift base class has been
/// registered by its owning image.
void SnapInstallDynamicTestInvocations(void);

NS_ASSUME_NONNULL_END
