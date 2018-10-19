#import <Foundation/Foundation.h>

@interface objcMadgwickAHRS : NSObject
- (void) madgwickUpdate: (double[])gx gy:(double[])gy gz:(double[])gz ax:(double[])ax ay:(double[])ay az:(double[])az withTime:(double[])nanoTime;
- (void) quaternion2YPR: (double[])angles;
@end
