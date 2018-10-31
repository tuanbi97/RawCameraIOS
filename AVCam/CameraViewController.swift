/*
See LICENSE.txt for this sample’s licensing information.

Abstract:
View controller for camera interface.
*/

import UIKit
import AVFoundation
import Photos
import CoreMotion

class CameraViewController: UIViewController {
	// MARK: View Controller Life Cycle
    
    let motion = CMMotionManager()
    var timerSensor = Timer()
    let orientationEstimator = objcMadgwickAHRS()
    func startSensors(){
        if self.motion.isAccelerometerAvailable && self.motion.isGyroAvailable {
            self.motion.accelerometerUpdateInterval = 1.0 / 50.0
            self.motion.startAccelerometerUpdates()
            
            self.motion.gyroUpdateInterval = 1.0 / 50.0
            self.motion.startGyroUpdates()
            
            self.timerSensor = Timer(fire: Date(), interval: (1.0 / 50.0), repeats: true, block: {(timer) in
                if  let acc = self.motion.accelerometerData, let gyr = self.motion.gyroData{
                    var ax = [-Double(acc.acceleration.x)]
                    var ay = [-Double(acc.acceleration.y)]
                    var az = [-Double(acc.acceleration.z)]
                    var gx = [Double(gyr.rotationRate.x)]
                    var gy = [Double(gyr.rotationRate.y)]
                    var gz = [Double(gyr.rotationRate.z)]

                    //Solve orientation
                    var stime = [Double(CFAbsoluteTimeGetCurrent())]
                    //print(stime)
                    //print("\(gx[0]) \(gy[0]) \(gz[0]) \(ax[0]) \(ay[0]) \(az[0]) \(stime[0])")
                    self.orientationEstimator.madgwickUpdate(&gx, gy: &gy, gz: &gz, ax: &ax, ay: &ay, az: &az, withTime: &stime)
                    //self.orientationEstimator.madgwickUpdate("\(gx)", gy: "\(gy)", gz: "\(gz)", ax: "\(ax)", ay: "\(ay)", az: "\(az)", withTime: "\(stime)")
                    var angles:[Double] = [0, 0, 0]
                    self.orientationEstimator.quaternion2YPR(&angles)
                    
                    //print("\(angles[0]) \(angles[1]) \(angles[2])\n")
                    self.orientView.text = "P: \(Int(angles[1]))| R: \(Int(angles[2]))"
                }
            })
            
            RunLoop.current.add(self.timerSensor, forMode: .defaultRunLoopMode)
        }
    }
	
    var photoConstraint1 = NSLayoutConstraint()
    var photoConstraint2 = NSLayoutConstraint()
    var previewConstraints: [NSLayoutConstraint] = []
    var timerConstraints: [NSLayoutConstraint] = []
    var orientConstraints: [NSLayoutConstraint] = []
    @IBOutlet weak var orientView: UILabel!
    @IBOutlet weak var centerbox: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startSensors()
        centerbox.layer.borderWidth = 4.0
        centerbox.layer.borderColor = UIColor.green.cgColor
        // Disable UI. The UI is enabled if and only if the session starts running.
        photoButton.isEnabled = false
        if UIDeviceOrientationIsLandscape(UIDevice.current.orientation){
            print("Landscape")
            photoConstraint1 = NSLayoutConstraint(item: photoButton, attribute: .centerY, relatedBy: .equal, toItem: self.view, attribute: .centerY, multiplier: 1, constant: 0)
            photoConstraint2 = NSLayoutConstraint(item: photoButton, attribute: .trailing, relatedBy: .equal, toItem: self.view, attribute: .trailing, multiplier: 1, constant: 0)
            previewConstraints.append(NSLayoutConstraint(item: previewView, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1, constant: 0))
            previewConstraints.append(NSLayoutConstraint(item: previewView, attribute: .trailing, relatedBy: .equal, toItem: self.view, attribute: .trailing, multiplier: 1, constant: -140))
            timerConstraints.append(NSLayoutConstraint(item: timerView, attribute: .trailing, relatedBy: .equal, toItem: self.view, attribute: .trailing, multiplier: 1, constant: -60))
            timerConstraints.append(NSLayoutConstraint(item: timerView, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1, constant: -30))
            orientConstraints.append(NSLayoutConstraint(item: orientView, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1, constant: 50))
            orientConstraints.append(NSLayoutConstraint(item: orientView, attribute: .trailing, relatedBy: .equal, toItem: self.view, attribute: .trailing, multiplier: 1, constant: -20))
            centerbox.layer.borderWidth = 4.0
            self.view.addConstraint(photoConstraint1)
            self.view.addConstraint(photoConstraint2)
            self.view.addConstraints(previewConstraints)
            self.view.addConstraints(timerConstraints)
            self.view.addConstraints(orientConstraints)
        }
        else{
            print("Portrait")
            photoConstraint1 = NSLayoutConstraint(item: photoButton, attribute: .centerX, relatedBy: .equal, toItem: self.view, attribute: .centerX, multiplier: 1, constant: 0)
            photoConstraint2 = NSLayoutConstraint(item: photoButton, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1, constant: 0)
            previewConstraints.append(NSLayoutConstraint(item: previewView, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1, constant: -140))
            previewConstraints.append(NSLayoutConstraint(item: previewView, attribute: .trailing, relatedBy: .equal, toItem: self.view, attribute: .trailing, multiplier: 1, constant: 0))
            timerConstraints.append(NSLayoutConstraint(item: timerView, attribute: .leading, relatedBy: .equal, toItem: self.view, attribute: .leading, multiplier: 1, constant: 30))
            timerConstraints.append(NSLayoutConstraint(item: timerView, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1, constant: -30))
            orientConstraints.append(NSLayoutConstraint(item: orientView, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1, constant: -30))
            orientConstraints.append(NSLayoutConstraint(item: orientView, attribute: .trailing, relatedBy: .equal, toItem: self.view, attribute: .trailing, multiplier: 1, constant: -20))
            centerbox.layer.borderWidth = 0.0
            self.view.addConstraint(photoConstraint1)
            self.view.addConstraint(photoConstraint2)
            self.view.addConstraints(previewConstraints)
            self.view.addConstraints(timerConstraints)
            self.view.addConstraints(orientConstraints)
        }
        
        // Set up the video preview view.
        previewView.session = session
        
        /*
            Check video authorization status. Video access is required and audio
            access is optional. If audio access is denied, audio is not recorded
            during movie recording.
        */
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                // The user has previously granted access to the camera.
                break
            
            case .notDetermined:
                /*
                    The user has not yet been presented with the option to grant
                    video access. We suspend the session queue to delay session
                    setup until the access request has completed.
                
                    Note that audio access will be implicitly requested when we
                    create an AVCaptureDeviceInput for audio during session setup.
                */
                sessionQueue.suspend()
                AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                    if !granted {
                        self.setupResult = .notAuthorized
                    }
                    self.sessionQueue.resume()
                })
            
            default:
                // The user has previously denied access.
                setupResult = .notAuthorized
        }
        
        /*
            Setup the capture session.
            In general it is not safe to mutate an AVCaptureSession or any of its
            inputs, outputs, or connections from multiple threads at the same time.
        
            Why not do all of this on the main queue?
            Because AVCaptureSession.startRunning() is a blocking call which can
            take a long time. We dispatch session setup to the sessionQueue so
            that the main queue isn't blocked, which keeps the UI responsive.
        */
        sessionQueue.async {
            self.configureSession()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        sessionQueue.async {
            switch self.setupResult {
                case .success:
                    // Only setup observers and start the session running if setup succeeded.
                    self.addObservers()
                    self.session.startRunning()
                    self.isSessionRunning = self.session.isRunning
                
                case .notAuthorized:
                    DispatchQueue.main.async {
                        let changePrivacySetting = "AVCam doesn't have permission to use the camera, please change privacy settings"
                        let message = NSLocalizedString(changePrivacySetting, comment: "Alert message when the user has denied access to the camera")
                        let alertController = UIAlertController(title: "AVCam", message: message, preferredStyle: .alert)
                        
                        alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"),
                                                                style: .cancel,
                                                                handler: nil))
                        
                        alertController.addAction(UIAlertAction(title: NSLocalizedString("Settings", comment: "Alert button to open Settings"),
                                                                style: .`default`,
                                                                handler: { _ in
                            UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!, options: [:], completionHandler: nil)
                        }))
                        
                        self.present(alertController, animated: true, completion: nil)
                    }
                
                case .configurationFailed:
                    DispatchQueue.main.async {
                        let alertMsg = "Alert message when something goes wrong during capture session configuration"
                        let message = NSLocalizedString("Unable to capture media", comment: alertMsg)
                        let alertController = UIAlertController(title: "AVCam", message: message, preferredStyle: .alert)
                        
                        alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"),
                                                                style: .cancel,
                                                                handler: nil))
                        
                        self.present(alertController, animated: true, completion: nil)
                    }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        sessionQueue.async {
            if self.setupResult == .success {
                self.session.stopRunning()
                self.isSessionRunning = self.session.isRunning
                self.removeObservers()
            }
        }
        
        super.viewWillDisappear(animated)
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        if let videoPreviewLayerConnection = previewView.videoPreviewLayer.connection {
            let deviceOrientation = UIDevice.current.orientation
            guard let newVideoOrientation = AVCaptureVideoOrientation(deviceOrientation: deviceOrientation),
                deviceOrientation.isPortrait || deviceOrientation.isLandscape else {
                return
            }
            
            videoPreviewLayerConnection.videoOrientation = newVideoOrientation
        }
    }

    // MARK: Session Management
    
    private enum SessionSetupResult {
        case success
        case notAuthorized
        case configurationFailed
    }
    
    private let session = AVCaptureSession()
    
    private var isSessionRunning = false
    
    private let sessionQueue = DispatchQueue(label: "session queue") // Communicate with the session and other session objects on this queue.
    
    private var setupResult: SessionSetupResult = .success
    
    var videoDeviceInput: AVCaptureDeviceInput!
    
    @IBOutlet private weak var previewView: PreviewView!
    
    // Call this on the session queue.
    private func configureSession() {
        if setupResult != .success {
            return
        }
        
        session.beginConfiguration()
        
        session.sessionPreset = .photo
        
        // Add video input.
        do {
            var defaultVideoDevice: AVCaptureDevice?
            
            // Choose the back dual camera if available, otherwise default to a wide angle camera.
            if let dualCameraDevice = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) {
                defaultVideoDevice = dualCameraDevice
            } else if let backCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                // If the back dual camera is not available, default to the back wide angle camera.
                defaultVideoDevice = backCameraDevice
            }
            
            let videoDeviceInput = try AVCaptureDeviceInput(device: defaultVideoDevice!)
            
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
                
                DispatchQueue.main.async {
                    /*
                        Why are we dispatching this to the main queue?
                        Because AVCaptureVideoPreviewLayer is the backing layer for PreviewView and UIView
                        can only be manipulated on the main thread.
                        Note: As an exception to the above rule, it is not necessary to serialize video orientation changes
                        on the AVCaptureVideoPreviewLayer’s connection with other session manipulation.
                    
                        Use the status bar orientation as the initial video orientation. Subsequent orientation changes are
                        handled by CameraViewController.viewWillTransition(to:with:).
                    */
                    let statusBarOrientation = UIApplication.shared.statusBarOrientation
                    var initialVideoOrientation: AVCaptureVideoOrientation = .portrait
                    if statusBarOrientation != .unknown {
                            if let videoOrientation = AVCaptureVideoOrientation(interfaceOrientation: statusBarOrientation) {
                            initialVideoOrientation = videoOrientation
                        }
                    }
                    
                    self.previewView.videoPreviewLayer.connection?.videoOrientation = initialVideoOrientation
                }
            } else {
                print("Could not add video device input to the session")
                setupResult = .configurationFailed
                session.commitConfiguration()
                return
            }
        } catch {
            print("Could not create video device input: \(error)")
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }
        
        // Add photo output.
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            
            photoOutput.isHighResolutionCaptureEnabled = true
            
        } else {
            print("Could not add photo output to the session")
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }
        
        session.commitConfiguration()
    }
    
    private enum CaptureMode: Int {
        case photo = 0
    }
    // MARK: Device Configuration
    
    private let videoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera],
                                                                               mediaType: .video, position: .unspecified)
    
    @IBAction private func focusAndExposeTap(_ gestureRecognizer: UITapGestureRecognizer) {
        let devicePoint = previewView.videoPreviewLayer.captureDevicePointConverted(fromLayerPoint: gestureRecognizer.location(in: gestureRecognizer.view))
        focus(with: .autoFocus, exposureMode: .autoExpose, wbMode: .autoWhiteBalance, at: devicePoint, monitorSubjectAreaChange: true)
    }
    
    private func focus(with focusMode: AVCaptureDevice.FocusMode, exposureMode: AVCaptureDevice.ExposureMode, wbMode: AVCaptureDevice.WhiteBalanceMode, at devicePoint: CGPoint, monitorSubjectAreaChange: Bool) {
        sessionQueue.async {
            let device = self.videoDeviceInput.device
            do {
                try device.lockForConfiguration()
                
                /*
                    Setting (focus/exposure)PointOfInterest alone does not initiate a (focus/exposure) operation.
                    Call set(Focus/Exposure)Mode() to apply the new point of interest.
                */
                
                if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(focusMode) {
                    device.focusPointOfInterest = devicePoint
                    device.focusMode = focusMode
                }
                
                if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(exposureMode) {
                    device.exposurePointOfInterest = devicePoint
                    device.exposureMode = exposureMode
                }
                
                if device.isWhiteBalanceModeSupported(wbMode){
                    device.whiteBalanceMode = wbMode
                }
                
                device.isSubjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange
                device.unlockForConfiguration()
            } catch {
                print("Could not lock device for configuration: \(error)")
            }
        }
    }
    
    //Capture timer
    var timer = Timer()
    var seconds = 4
    
    @IBOutlet weak var timerView: UILabel!
    @objc func displayTimer(){
        seconds -= 1
        timerView.text = "\(seconds)"
        if seconds == 0 {
            timer.invalidate()
        }
    }
    
    // MARK: Capturing Photos

    private let photoOutput = AVCapturePhotoOutput()
    
    private var inProgressPhotoCaptureDelegates = [Int64: PhotoCaptureProcessor]()
    
    @IBOutlet private weak var photoButton: UIButton!
    @IBAction private func capturePhoto(_ photoButton: UIButton) {
        /*
            Retrieve the video preview layer's video orientation on the main queue before
            entering the session queue. We do this to ensure UI elements are accessed on
            the main thread and session configuration is done on the session queue.
        */        
        let videoPreviewLayerOrientation = previewView.videoPreviewLayer.connection?.videoOrientation
        self.seconds = 4
        self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: (#selector(CameraViewController.displayTimer)), userInfo: nil, repeats: true)
        sessionQueue.asyncAfter(deadline: .now() + 4) {
            // Update the photo output's connection to match the video orientation of the video preview layer.
            if let photoOutputConnection = self.photoOutput.connection(with: .video) {
                photoOutputConnection.videoOrientation = videoPreviewLayerOrientation!
            }
            
            var photoSettings = AVCapturePhotoSettings()
            // Capture HEIF photo when supported, with flash set to auto and high resolution photo enabled.
            
            if  self.photoOutput.availablePhotoCodecTypes.contains(.jpeg) {
                
                guard let availableRawFormat = self.photoOutput.availableRawPhotoPixelFormatTypes.first else {return}
                photoSettings = AVCapturePhotoSettings(rawPixelFormatType: availableRawFormat, processedFormat: [AVVideoCodecKey: AVVideoCodecType.jpeg])

            }
            
            if self.videoDeviceInput.device.isFlashAvailable {
                photoSettings.flashMode = .off
            }
            
            photoSettings.isHighResolutionPhotoEnabled = true
            if !photoSettings.__availablePreviewPhotoPixelFormatTypes.isEmpty {
                photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: photoSettings.__availablePreviewPhotoPixelFormatTypes.first!]
            }
            
            // Use a separate object for the photo capture delegate to isolate each capture life cycle.
            var photoCaptureProcessor = PhotoCaptureProcessor(with: photoSettings, completionHandler: { photoCaptureProcessor in
                    // When the capture is complete, remove a reference to the photo capture delegate so it can be deallocated.
                    self.sessionQueue.async {
                        self.inProgressPhotoCaptureDelegates[photoCaptureProcessor.requestedPhotoSettings.uniqueID] = nil
                    }
                }
            )
            
            /*
                The Photo Output keeps a weak reference to the photo capture delegate so
                we store it in an array to maintain a strong reference to this object
                until the capture is completed.
            */
            self.inProgressPhotoCaptureDelegates[photoCaptureProcessor.requestedPhotoSettings.uniqueID] = photoCaptureProcessor
            self.photoOutput.capturePhoto(with: photoSettings, delegate: photoCaptureProcessor)
            
            // Second camera
            // Update the photo output's connection to match the video orientation of the video preview layer.
            if let photoOutputConnection = self.photoOutput.connection(with: .video) {
                photoOutputConnection.videoOrientation = videoPreviewLayerOrientation!
            }
            
            photoSettings = AVCapturePhotoSettings()
            // Capture HEIF photo when supported, with flash set to auto and high resolution photo enabled.
            
            if  self.photoOutput.availablePhotoCodecTypes.contains(.jpeg) {
                
                guard let availableRawFormat = self.photoOutput.availableRawPhotoPixelFormatTypes.first else {return}
                photoSettings = AVCapturePhotoSettings(rawPixelFormatType: availableRawFormat, processedFormat: [AVVideoCodecKey: AVVideoCodecType.jpeg])
                
            }
            
            if self.videoDeviceInput.device.isFlashAvailable {
                photoSettings.flashMode = .on
            }
            
            photoSettings.isHighResolutionPhotoEnabled = true
            if !photoSettings.__availablePreviewPhotoPixelFormatTypes.isEmpty {
                photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: photoSettings.__availablePreviewPhotoPixelFormatTypes.first!]
            }
            
            // Use a separate object for the photo capture delegate to isolate each capture life cycle.
            photoCaptureProcessor = PhotoCaptureProcessor(with: photoSettings, completionHandler: { photoCaptureProcessor in
                // When the capture is complete, remove a reference to the photo capture delegate so it can be deallocated.
                self.sessionQueue.async {
                    self.inProgressPhotoCaptureDelegates[photoCaptureProcessor.requestedPhotoSettings.uniqueID] = nil
                }
            }
            )
            
            /*
             The Photo Output keeps a weak reference to the photo capture delegate so
             we store it in an array to maintain a strong reference to this object
             until the capture is completed.
             */
            self.inProgressPhotoCaptureDelegates[photoCaptureProcessor.requestedPhotoSettings.uniqueID] = photoCaptureProcessor
            self.photoOutput.capturePhoto(with: photoSettings, delegate: photoCaptureProcessor)
        }
    }
    
    // MARK: KVO and Notifications
    
    private var keyValueObservations = [NSKeyValueObservation]()
    
    private func addObservers() {
        let keyValueObservation = session.observe(\.isRunning, options: .new) { _, change in
            guard let isSessionRunning = change.newValue else { return }
            
            DispatchQueue.main.async {
                // Only enable the ability to change camera if the device has more than one camera.
                self.photoButton.isEnabled = isSessionRunning
            }
        }
        keyValueObservations.append(keyValueObservation)
        
        NotificationCenter.default.addObserver(self, selector: #selector(subjectAreaDidChange), name: .AVCaptureDeviceSubjectAreaDidChange, object: videoDeviceInput.device)
//        NotificationCenter.default.addObserver(self, selector: #selector(screenRotated), name: .UIDeviceOrientationDidChange, object: nil)
    }
    
    private func removeObservers() {
        NotificationCenter.default.removeObserver(self)
        
        for keyValueObservation in keyValueObservations {
            keyValueObservation.invalidate()
        }
        keyValueObservations.removeAll()
    }
    
    @objc
    func subjectAreaDidChange(notification: NSNotification) {
        let devicePoint = CGPoint(x: 0.5, y: 0.5)
        focus(with: .continuousAutoFocus, exposureMode: .continuousAutoExposure, wbMode: .continuousAutoWhiteBalance, at: devicePoint, monitorSubjectAreaChange: false)
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        if UIDeviceOrientationIsLandscape(UIDevice.current.orientation){
            print("Landscape")
            self.view.removeConstraints([photoConstraint1, photoConstraint2])
            self.view.removeConstraints(previewConstraints)
            self.view.removeConstraints(timerConstraints)
            self.view.removeConstraints(orientConstraints)
            photoConstraint1 = NSLayoutConstraint(item: photoButton, attribute: .centerY, relatedBy: .equal, toItem: self.view, attribute: .centerY, multiplier: 1, constant: 0)
            photoConstraint2 = NSLayoutConstraint(item: photoButton, attribute: .trailing, relatedBy: .equal, toItem: self.view, attribute: .trailing, multiplier: 1, constant: 0)
            previewConstraints[0] = NSLayoutConstraint(item: previewView, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1, constant: 0)
            previewConstraints[1] = NSLayoutConstraint(item: previewView, attribute: .trailing, relatedBy: .equal, toItem: self.view, attribute: .trailing, multiplier: 1, constant: -140)
            timerConstraints[0] = NSLayoutConstraint(item: timerView, attribute: .trailing, relatedBy: .equal, toItem: self.view, attribute: .trailing, multiplier: 1, constant: -60)
            timerConstraints[1] = NSLayoutConstraint(item: timerView, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1, constant: -30)
            orientConstraints[0] = NSLayoutConstraint(item: orientView, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1, constant: 50)
            orientConstraints[1] = NSLayoutConstraint(item: orientView, attribute: .trailing, relatedBy: .equal, toItem: self.view, attribute: .trailing, multiplier: 1, constant: -20)
            self.view.addConstraint(photoConstraint1)
            self.view.addConstraint(photoConstraint2)
            self.view.addConstraints(previewConstraints)
            self.view.addConstraints(timerConstraints)
            self.view.addConstraints(orientConstraints)
            centerbox.layer.borderWidth = 4.0
        }
        else{
            print("Portrait")
            self.view.removeConstraints([photoConstraint1, photoConstraint2])
            self.view.removeConstraints(previewConstraints)
            self.view.removeConstraints(timerConstraints)
            self.view.removeConstraints(orientConstraints)
            photoConstraint1 = NSLayoutConstraint(item: photoButton, attribute: .centerX, relatedBy: .equal, toItem: self.view, attribute: .centerX, multiplier: 1, constant: 0)
            photoConstraint2 = NSLayoutConstraint(item: photoButton, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1, constant: 0)
            previewConstraints[0] = NSLayoutConstraint(item: previewView, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1, constant: -140)
            previewConstraints[1] = NSLayoutConstraint(item: previewView, attribute: .trailing, relatedBy: .equal, toItem: self.view, attribute: .trailing, multiplier: 1, constant: 0)
            timerConstraints[0] = NSLayoutConstraint(item: timerView, attribute: .leading, relatedBy: .equal, toItem: self.view, attribute: .leading, multiplier: 1, constant: 30)
            timerConstraints[1] = NSLayoutConstraint(item: timerView, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1, constant: -60)
            orientConstraints[0] = NSLayoutConstraint(item: orientView, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1, constant: -30)
            orientConstraints[1] = NSLayoutConstraint(item: orientView, attribute: .trailing, relatedBy: .equal, toItem: self.view, attribute: .trailing, multiplier: 1, constant: -20)
            self.view.addConstraint(photoConstraint1)
            self.view.addConstraint(photoConstraint2)
            self.view.addConstraints(previewConstraints)
            self.view.addConstraints(timerConstraints)
            self.view.addConstraints(orientConstraints)
            centerbox.layer.borderWidth = 0
        }
    }
}

extension AVCaptureVideoOrientation {
    init?(deviceOrientation: UIDeviceOrientation) {
        switch deviceOrientation {
            case .portrait: self = .portrait
            case .portraitUpsideDown: self = .portraitUpsideDown
            case .landscapeLeft: self = .landscapeRight
            case .landscapeRight: self = .landscapeLeft
            default: return nil
        }
    }
    
    init?(interfaceOrientation: UIInterfaceOrientation) {
        switch interfaceOrientation {
            case .portrait: self = .portrait
            case .portraitUpsideDown: self = .portraitUpsideDown
            case .landscapeLeft: self = .landscapeLeft
            case .landscapeRight: self = .landscapeRight
            default: return nil
        }
    }
}

extension AVCaptureDevice.DiscoverySession {
    var uniqueDevicePositionsCount: Int {
        var uniqueDevicePositions: [AVCaptureDevice.Position] = []
        
        for device in devices {
            if !uniqueDevicePositions.contains(device.position) {
                uniqueDevicePositions.append(device.position)
            }
        }
        
        return uniqueDevicePositions.count
    }
}
