#import "objcMadgwickAHRS.h"
#include "MadgwickAHRS.h"

@interface objcMadgwickAHRS(){
	MadgwickAHRS transformer;
}

@end

@implementation objcMadgwickAHRS
- (void) MadgwickUpdate: (float)gx gy:(float)gy gz:(float)gz ax:(float)ax ay:(float)ay az:(float)az withTime:(float)nanoTime{
	transformer.MadgwickAHRSupdateIMU(gx, gy, gz, ax, ay, az, nanoTime);
}
- (void) Quaternion2YPR: (float[])angles{
	transformer.Quaternion2YPR(angles);
}
@end
