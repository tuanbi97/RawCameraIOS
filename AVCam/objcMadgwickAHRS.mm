#import "objcMadgwickAHRS.h"
#include "MadgwickAHRS.h"

@interface objcMadgwickAHRS(){
	MadgwickAHRS transformer;
}

@end

@implementation objcMadgwickAHRS
- (void) madgwickUpdate: (double[])gx gy:(double[])gy gz:(double[])gz ax:(double[])ax ay:(double[])ay az:(double[])az withTime:(double[])nanoTime{
    //printf("%f %f %f %f %f %f %f\n", gx[0], gy[0], gz[0], ax[0], ay[0], az[0], nanoTime[0]);
    transformer.MadgwickAHRSupdateIMU(gx[0], gy[0], gz[0], ax[0], ay[0], az[0], nanoTime[0]);
}
- (void) quaternion2YPR: (double[])angles{
	transformer.Quaternion2YPR(angles);
}
@end
