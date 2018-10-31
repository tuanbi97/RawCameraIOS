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
    private var jpgImageFileURL: URL?
    private var flashMode: Int?
    private var fileName: String?

    init(with requestedPhotoSettings: AVCapturePhotoSettings,
         completionHandler: @escaping (PhotoCaptureProcessor) -> Void) {
        self.requestedPhotoSettings = requestedPhotoSettings
        self.completionHandler = completionHandler
        self.flashMode = requestedPhotoSettings.flashMode.rawValue
        self.fileName = ""
    }
    
    private func makeUniqueFileName() -> String{
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
        let uniqueFileName = String(format: "%d_%02d_%02d_%02d_%02d_%02d_%03d", date.year!, date.month!, date.day!, date.hour!, date.minute!, date.second!, date.nanosecond! / 1000000)
        return uniqueFileName
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
                    //print(dngFileURL)
                    try photo.fileDataRepresentation()!.write(to: dngFileURL)
                } catch {
                    fatalError("Couldn't write DNG file to URL")
                }
            }
            else{
                let jpgFileURL = self.makeUniqueTempFileURL(extension: "jpg")
                jpgImageFileURL = jpgFileURL
                do{
//                    let uiImage = UIImage(data: photo.fileDataRepresentation()!)
//                    try UIImageJPEGRepresentation(uiImage!, 1.0)!.write(to: jpgFileURL)
                    try photo.fileDataRepresentation()!.write(to: jpgFileURL)
                } catch{
                    fatalError("Couldn't write JPG file to URL")
                }
                //photoData = photo.fileDataRepresentation()
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
        if self.fileName == "" {
            self.fileName = self.makeUniqueFileName()
        }
        var uniqueFileName = "RAW_" + self.fileName! + (self.flashMode == 0 ? "_noflash" : "_flash")
        if (type == "jpg"){
            uniqueFileName = "JPEG_" + self.fileName! + (self.flashMode == 0 ? "_noflash" : "_flash")
        }
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
        
        guard let rawURL = self.rawImageFileURL else {
            print("No raw photo url resource")
            didFinish()
            return
        }
        
        guard let jpgURL = self.jpgImageFileURL else {
            print("No jpg photo url resource")
            didFinish()
            return
        }
        
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                PHPhotoLibrary.shared().performChanges({
//                    let options = PHAssetResourceCreationOptions()
//                    let creationRequest = PHAssetCreationRequest.forAsset()
//                    options.uniformTypeIdentifier = self.requestedPhotoSettings.processedFileType.map { $0.rawValue }
//                    creationRequest.addResource(with: .photo, data: photoData, options: options)
                    
                    let creationRequest = PHAssetCreationRequest.forAsset()
                    let jpgOptions = PHAssetResourceCreationOptions()
                    creationRequest.addResource(with: .alternatePhoto, fileURL: jpgURL, options: jpgOptions)
                    
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
