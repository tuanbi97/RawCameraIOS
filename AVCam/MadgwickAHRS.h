class MadgwickAHRS{
	private:
		float beta;				// algorithm gain
		float q0, q1, q2, q3;	// quaternion of sensor frame relative to auxiliary frame
//		float M_PI;
		float lastUpdate;

	public:
		MadgwickAHRS();
		void MadgwickAHRSupdateIMU(float gx, float gy, float gz, float ax, float ay, float az, float nanoTime);
		void Quaternion2YPR(float * angles);
		float invSqrt(float x);
};
