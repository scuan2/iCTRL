#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LockStateMonitor : NSObject

+ (instancetype)sharedMonitor;

@property (nonatomic, readonly) BOOL isLocked;

- (BOOL)lockScreenWithTimeout:(NSTimeInterval)timeout error:(NSError *__autoreleasing _Nullable * _Nullable)error;
- (BOOL)unlockScreenWithTimeout:(NSTimeInterval)timeout error:(NSError *__autoreleasing _Nullable * _Nullable)error;

/// Reset iOS's user-idle timer without changing the visible UI. Sends F13
/// (keyboard HID page 0x07, usage 0x68), which iOS treats as user activity but
/// maps to no action. Returns nil on success or a short error description.
- (nullable NSString *)resetIdleTimer;

@end

NS_ASSUME_NONNULL_END
