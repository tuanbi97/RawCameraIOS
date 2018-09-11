/*
See LICENSE.txt for this sample’s licensing information.

Abstract:
Photo capture delegate.
*/

import AVFoundation
import Photos

class PhotoCaptureProcessor: NSObject{
	private(set) var requestedPhotoSettings: AVCapturePhotoSettings
	
	private let completionHandler: (PhotoCaptureProcessor) -> Void
	
	private var photoData: Data?
    private var rawImageFileURL: URL?

	init(with requestedPhotoSettings: AVCapturePhotoSettings,
	     completionHandler: @escaping (PhotoCaptureProcessor) -> Void) {
		self.requestedPhotoSettings = requestedPhotoSettings
		self.completionHandler = completionHandler
	}
	
	private func didFinish() {
		completionHandler(self)
	}
    
}

extension PhotoCaptureProcessor: AVCapturePhotoCaptureDelegate {
    /*
     This extension includes all the delegate callbacks for AVCapturePhotoCaptureDelegate protocol
    */
    
    func photoOutput(_ output: AVCapturePhotoOutput, willBeginCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        if let error = error {
            print("Error capturing photo: \(error)")
        } else {
            if photo.isRawPhoto {
                let dngFileURL = self.makeUniqueTempFileURL(extension: "dng")
                rawImageFileURL = dngFileURL
                do{
                    print(dngFileURL)
                    try photo.fileDataRepresentation()!.write(to: dngFileURL)
                } catch {
                    fatalError("Couldn't write DNG file to URL")
                }
            }
            else{
                photoData = photo.fileDataRepresentation()
            }
        }
    }
    
    func makeUniqueTempFileURL(extension type:String) -> URL{
        var temporaryDirectoryURL = FileManager.default.temporaryDirectory
        do{
            temporaryDirectoryURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        }
        catch{
            print(error)
        }
        let currentDateTime = Date()
        let userCalendar = Calendar.current
        let requestedComponents: Set<Calendar.Component> = [
            .year,
            .month,
            .day,
            .hour,
            .minute,
            .second,
            .nanosecond
        ]
        let date = userCalendar.dateComponents(requestedComponents, from: currentDateTime)
        let uniqueFileName = "RAW_\(date.year!)_\(date.month!)_\(date.day!)_\(date.hour!)_\(date.minute!)_\(date.second!)_\(date.nanosecond! / 1000000)"
        let urlNoExt = temporaryDirectoryURL.appendingPathComponent(uniqueFileName)
        let url = urlNoExt.appendingPathExtension(type)
        return url
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error)")
            didFinish()
            return
        }
        
        guard let photoData = photoData else {
            print("No photo data resource")
            didFinish()
            return
        }
        
        guard let rawURL = self.rawImageFileURL else {
            print("No raw photo url resource")
            didFinish()
            return
        }
        
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                PHPhotoLibrary.shared().performChanges({
                    let options = PHAssetResourceCreationOptions()
                    let creationRequest = PHAssetCreationRequest.forAsset()
                    options.uniformTypeIdentifier = self.requestedPhotoSettings.processedFileType.map { $0.rawValue }
                    creationRequest.addResource(with: .photo, data: photoData, options: options)
                    
                    let rawOptions = PHAssetResourceCreationOptions()
                    creationRequest.addResource(with: .alternatePhoto, fileURL: rawURL, options: rawOptions)
                    
                    }, completionHandler: { _, error in
                        if let error = error {
                            print("Error occurered while saving photo to photo library: \(error)")
                        }
                        
                        self.didFinish()
                    }
                )
            } else {
                self.didFinish()
            }
        }
    }
}
