//
//  ViewController.swift
//  vision-app
//
//  Created by Aziz on 21/01/2018.
//  Copyright © 2018 vision-coreml. All rights reserved.
//

import UIKit
import AVFoundation
import CoreML
import Vision

enum FlashState{
    case off
    case on
}


class CameraVC: UIViewController {
    
    var captureSession : AVCaptureSession!
    var cameraOutput : AVCapturePhotoOutput!
    var previewLayer : AVCaptureVideoPreviewLayer!
    
    var photoData : Data?
    
    var flashControlState : FlashState = .off
    
    var speechSynthesizer = AVSpeechSynthesizer()
    
    
    @IBOutlet weak var captureImageView: RoundedShadowImageView!
    @IBOutlet weak var flashButton: RoundedShadowButton!
    @IBOutlet weak var identificationLbl: UILabel!
    @IBOutlet weak var confidenceLbl: UILabel!
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var roundedLblView: RoundedShadowView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        previewLayer.frame = cameraView.bounds
        speechSynthesizer.delegate = self
        self.spinner.isHidden = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapCameraView))
        tap.numberOfTapsRequired = 1
        
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = AVCaptureSession.Preset.hd1920x1080
        
        let backCamera = AVCaptureDevice.default(for: AVMediaType.video)
        
        do{
            let input = try AVCaptureDeviceInput(device: backCamera!)
            
            if captureSession.canAddInput(input) == true
            {
                captureSession.addInput(input)
            }
            
            cameraOutput = AVCapturePhotoOutput()
            
            if captureSession.canAddOutput(cameraOutput) == true
            {
                captureSession.addOutput(cameraOutput!)
            
            
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
            previewLayer.videoGravity = AVLayerVideoGravity.resizeAspect
            previewLayer.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
            
            cameraView.layer.addSublayer(previewLayer!)
            cameraView.addGestureRecognizer(tap)
            captureSession.startRunning()
            }
        }catch{
            debugPrint(error)
        }
    }
    
  @objc func didTapCameraView()
    {
        self.cameraView.isUserInteractionEnabled = false
        self.spinner.isHidden = false
        self.spinner.startAnimating()
        
        
        let settings = AVCapturePhotoSettings()
        let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first!
        let previewFormat = [kCVPixelBufferPixelFormatTypeKey as String : previewPixelType , kCVPixelBufferWidthKey as String : 160 , kCVPixelBufferHeightKey as String : 160 ]
        
        settings.previewPhotoFormat = previewFormat
        
        if flashControlState == .off {
            settings.flashMode = .off
        }else{
            settings.flashMode = .on
        }
        
        
        cameraOutput.capturePhoto(with: settings, delegate: self)
        
    }
    
    func resultsMethod(request: VNRequest , error: Error?)
    {
        guard let results = request.results as? [VNClassificationObservation] else{  return }
        
        
        for classification in results{
            
            if  classification.confidence < 0.5{
                let unknownObjectMessage = "Bu nesnenin ne olduğunu bulamadım.Lütfen tekrar deneyin"
                self.identificationLbl.text = unknownObjectMessage
                synthesizeSpeech(fromString: unknownObjectMessage)
                self.confidenceLbl.text = ""
               
                break
            }else{
                let identification = classification.identifier
                let confidence = Int(classification.confidence * 100)
                
                self.identificationLbl.text = identification
                self.confidenceLbl.text = "Tahmin :  \(confidence)%"
                
                let completeSentences = "bu \(identification) gibi görünüyor. tahmin yüzdem \(confidence) "
                synthesizeSpeech(fromString: completeSentences)
                
                break
            }
            
        }
    }
    
    func synthesizeSpeech(fromString string : String){
        
        let speechUtterance = AVSpeechUtterance(string: string)
        speechSynthesizer.speak(speechUtterance)
        
    }

    
    @IBAction func flashBtnWasPressed(_ sender: Any) {
        switch flashControlState {
        case .off:
            flashButton.setTitle("FLASH ON", for: .normal)
            flashControlState = .on
            
        case .on:
            flashButton.setTitle("FLASH OFF", for: .normal)
            flashControlState = .off
            
        }
    }
    
    

}

extension CameraVC : AVCapturePhotoCaptureDelegate{
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error{
            debugPrint(error)
        }else{
            photoData = photo.fileDataRepresentation()
            
            do{
                let model = try VNCoreMLModel(for: SqueezeNet().model)
                let request = VNCoreMLRequest.init(model: model, completionHandler: resultsMethod)
                let handler = VNImageRequestHandler(data: photoData!)
                
                try handler.perform([request])
                
                
              //  model.prediction(input: photoData)
                
            }catch{
                //handle error
                debugPrint(error)
            }
            
            
            let image = UIImage(data : photoData!)
            self.captureImageView.image = image
        }
    }
}

extension CameraVC : AVSpeechSynthesizerDelegate{
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        self.cameraView.isUserInteractionEnabled = true
        self.spinner.isHidden = true
        self.spinner.stopAnimating()
    }
}

