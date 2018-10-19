class MadgwickAHRS{
	private:
		double beta;				// algorithm gain
		double q0, q1, q2, q3;	// quaternion of sensor frame relative to auxiliary frame
//		double M_PI;
		double lastUpdate;

	public:
		MadgwickAHRS();
		void MadgwickAHRSupdateIMU(double gx, double gy, double gz, double ax, double ay, double az, double nanoTime);
		void Quaternion2YPR(double * angles);
		double invSqrt(double x);
};
