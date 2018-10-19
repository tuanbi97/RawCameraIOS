#include "MadgwickAHRS.h"
#include <math.h>
#include <stdio.h>
#include <iostream>
#include <time.h>
#include <vector>
using namespace std;

MadgwickAHRS::MadgwickAHRS(){
	beta = 0.1;
	//M_PI = 3.14159265358979323846;
	q0 = 1.0;
	q1 = q2 = q3 = 0.0;
	lastUpdate = -1;
}

void MadgwickAHRS::MadgwickAHRSupdateIMU(double gx, double gy, double gz, double ax, double ay, double az, double nanoTime) {
	if (lastUpdate == -1){
        lastUpdate = (1.0 * nanoTime); // 1000000000;
		return;
	}
	double deltaT = (1.0 * nanoTime) - lastUpdate;
    lastUpdate = nanoTime;
	double recipNorm;
	double s0, s1, s2, s3;
	double qDot1, qDot2, qDot3, qDot4;
	double _2q0, _2q1, _2q2, _2q3, _4q0, _4q1, _4q2 ,_8q1, _8q2, q0q0, q1q1, q2q2, q3q3;
    
    //printf("%f %f %f %f %f\n", deltaT, q0, q1, q2, q3);

	// Rate of change of quaternion from gyroscope
	qDot1 = 0.5 * (-q1 * gx - q2 * gy - q3 * gz);
	qDot2 = 0.5 * (q0 * gx + q2 * gz - q3 * gy);
	qDot3 = 0.5 * (q0 * gy - q1 * gz + q3 * gx);
	qDot4 = 0.5 * (q0 * gz + q1 * gy - q2 * gx);

	// Compute feedback only if accelerometer measurement valid (avoids NaN in accelerometer normalisation)
	if(!((ax == 0.0) && (ay == 0.0) && (az == 0.0))) {

		// Normalise accelerometer measurement
		recipNorm = invSqrt(ax * ax + ay * ay + az * az);
		ax *= recipNorm;
		ay *= recipNorm;
		az *= recipNorm;

		// Auxiliary variables to avoid repeated arithmetic
		_2q0 = 2.0 * q0;
		_2q1 = 2.0 * q1;
		_2q2 = 2.0 * q2;
		_2q3 = 2.0 * q3;
		_4q0 = 4.0 * q0;
		_4q1 = 4.0 * q1;
		_4q2 = 4.0 * q2;
		_8q1 = 8.0 * q1;
		_8q2 = 8.0 * q2;
		q0q0 = q0 * q0;
		q1q1 = q1 * q1;
		q2q2 = q2 * q2;
		q3q3 = q3 * q3;

		// Gradient decent algorithm corrective step
		s0 = _4q0 * q2q2 + _2q2 * ax + _4q0 * q1q1 - _2q1 * ay;
		s1 = _4q1 * q3q3 - _2q3 * ax + 4.0 * q0q0 * q1 - _2q0 * ay - _4q1 + _8q1 * q1q1 + _8q1 * q2q2 + _4q1 * az;
		s2 = 4.0 * q0q0 * q2 + _2q0 * ax + _4q2 * q3q3 - _2q3 * ay - _4q2 + _8q2 * q1q1 + _8q2 * q2q2 + _4q2 * az;
		s3 = 4.0 * q1q1 * q3 - _2q1 * ax + 4.0 * q2q2 * q3 - _2q2 * ay;
		recipNorm = invSqrt(s0 * s0 + s1 * s1 + s2 * s2 + s3 * s3); // normalise step magnitude
		s0 *= recipNorm;
		s1 *= recipNorm;
		s2 *= recipNorm;
		s3 *= recipNorm;

		// Apply feedback step
		qDot1 -= beta * s0;
		qDot2 -= beta * s1;
		qDot3 -= beta * s2;
		qDot4 -= beta * s3;
	}

	// Integrate rate of change of quaternion to yield quaternion
	q0 += qDot1 * deltaT;
	q1 += qDot2 * deltaT;
	q2 += qDot3 * deltaT;
	q3 += qDot4 * deltaT;

	// Normalise quaternion
	recipNorm = invSqrt(q0 * q0 + q1 * q1 + q2 * q2 + q3 * q3);
	q0 *= recipNorm;
	q1 *= recipNorm;
	q2 *= recipNorm;
	q3 *= recipNorm;
}

//---------------------------------------------------------------------------------------------------
// Fast inverse square-root
// See: http://en.wikipedia.org/wiki/Fast_inverse_square_root

double MadgwickAHRS::invSqrt(double number) {
    double y = number;
    double x2 = y * 0.5;
    std::int64_t i = *(std::int64_t *) &y;
    // The magic number is for doubles is from https://cs.uwaterloo.ca/~m32rober/rsqrt.pdf
    i = 0x5fe6eb50c7b537a9 - (i >> 1);
    y = *(double *) &i;
    y = y * (1.5 - (x2 * y * y));   // 1st iteration
    //      y  = y * ( 1.5 - ( x2 * y * y ) );   // 2nd iteration, this can be removed
    return y;
}

void MadgwickAHRS::Quaternion2YPR(double * angles){
    double roll = atan2(2 * (q0 * q1 + q2 * q3), q0 * q0 * 2 - 1 + q3 * q3 * 2) * 180 / M_PI;
    double pitch = -asin(2 * (q1 * q3 - q0 * q2)) * 180 / M_PI;
    double yaw = atan2(2 * (q1 * q2 + q0 * q3), q0 * q0 * 2 + q1 * q1 * 2 - 1) * 180 / M_PI;
    angles[0] = yaw;
    angles[1] = pitch;
    angles[2] = roll;
}
