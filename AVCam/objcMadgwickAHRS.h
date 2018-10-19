#import <Foundation/Foundation.h>

@interface objcMadgwickAHRS : NSObject
- (void) MadgwickUpdate: (float)gx gy:(float)gy gz:(float)gz ax:(float)ax ay:(float)ay az:(float)az withTime:(float)nanoTime;
- (void) Quaternion2YPR: (float[])angles;
@end
