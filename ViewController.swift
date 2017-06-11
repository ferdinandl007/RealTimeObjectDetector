//
//  ViewController.swift
//  ObjectDetector
//
//  Created by Ferdinand Lösch on 11.06.17.
//  Copyright © 2017 ferdinand. All rights reserved.
//
//

import UIKit
import CoreML
import Vision
import AVFoundation



class ViewController: UIViewController {

  // MARK: - IBOutlets
  @IBOutlet weak var previewView: UIView!
  @IBOutlet weak var answerLabel: UILabel!

  // MARK: - Properties
  let vowels: [Character] = ["a", "e", "i", "o", "u"]
  var captureSession: AVCaptureSession?
  var stillImageOutput: AVCaptureStillImageOutput?
  var previewLayer: AVCaptureVideoPreviewLayer?
  var timer = Timer()
  
  
  // MARK: - View Life Cycle
  override func viewDidLoad() {
    super.viewDidLoad()
   timer = Timer.scheduledTimer(timeInterval: (2), target: self, selector: #selector(ViewController.takePhoto), userInfo: nil, repeats: true)
    
  }
  
  
  
  
  fileprivate func camaraFunc() {
    captureSession = AVCaptureSession()
    captureSession!.sessionPreset = AVCaptureSession.Preset.photo
    
    let backCamera = AVCaptureDevice.default(for: AVMediaType.video)
    
    var error: NSError?
    var input: AVCaptureDeviceInput!
    do {
      input = try AVCaptureDeviceInput(device: backCamera!)
    } catch let error1 as NSError {
      error = error1
      input = nil
    }
    
    
    if error == nil && captureSession!.canAddInput(input) {
      captureSession!.addInput(input)
      stillImageOutput = AVCaptureStillImageOutput()
      stillImageOutput!.outputSettings = [AVVideoCodecKey: AVVideoCodecType.jpeg]
      if captureSession!.canAddOutput(stillImageOutput!) {
        captureSession!.addOutput(stillImageOutput!)
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
        previewLayer!.videoGravity = AVLayerVideoGravity.resizeAspectFill
        previewLayer!.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
        previewView.layer.addSublayer(previewLayer!)
        
        captureSession!.startRunning()
      }
    }
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    camaraFunc()
  }
  
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    previewLayer!.frame = previewView.bounds
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    timer.invalidate()
  }
  
  
  @objc func takePhoto() {
    //Create the UIImage
    if let videoConnection = stillImageOutput!.connection(with: AVMediaType.video) {
      videoConnection.videoOrientation = AVCaptureVideoOrientation.portrait
      stillImageOutput?.captureStillImageAsynchronously(from: videoConnection, completionHandler: {(sampleBuffer, error) in
        if (sampleBuffer != nil) {
          let imageData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: sampleBuffer!, previewPhotoSampleBuffer: sampleBuffer)
          let dataProvider = CGDataProvider(data: imageData! as CFData)
          let cgImageRef = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: CGColorRenderingIntent.defaultIntent)
          
          let image = UIImage(cgImage: cgImageRef!, scale: 1, orientation: UIImageOrientation.left)
          
          guard let ciImage = CIImage(image: image) else {
            fatalError("couldn't convert UIImage to CIImage")
          }
          self.detectScene(image: ciImage)
        }
        
      })
    }
  }
  
  func speak(text: String){
    let synth = AVSpeechSynthesizer()
    let myUtterance = AVSpeechUtterance(string: text)
    myUtterance.rate = 0.5
    synth.speak(myUtterance)
  }
  
  
}








 extension ViewController {
  
   func detectScene(image: CIImage) {
     answerLabel.text = "detecting scene..."
    
     // Load the ML model through its generated class
     guard let model = try? VNCoreMLModel(for: VGG16().model) else {
       fatalError("can't load Places ML model")
     }
     // Create a Vision request with completion handler
     let request = VNCoreMLRequest(model: model) { [weak self] request, error in
       guard let results = request.results as? [VNClassificationObservation],
         let topResult = results.first else {
           fatalError("unexpected result type from VNCoreMLRequest")
      }
      
       // Update UI on main queue
       let article = (self?.vowels.contains(topResult.identifier.first!))! ? "an" : "a"
       DispatchQueue.main.async { [weak self] in
       self?.answerLabel.text = "\(Int(topResult.confidence * 100))% it's \(article) \(topResult.identifier)"
        self?.speak(text: topResult.identifier)
      }
    }
    
    
    
     // Run the Core ML GoogLeNetPlaces classifier on global dispatch queue
     let handler = VNImageRequestHandler(ciImage: image)
     DispatchQueue.global(qos: .userInteractive).async {
       do {
         try handler.perform([request])
        } catch {
         print(error)
       }
    }
    
    
  }
}


// MARK: - UIImagePickerControllerDelegate


extension ViewController: UIImagePickerControllerDelegate {
  
  
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
  dismiss(animated: true)
    
  guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else {
    fatalError("couldn't load image from Photos")
  }
    //    previewView.image = image
  guard let ciImage = CIImage(image: image) else {
    fatalError("couldn't convert UIImage to CIImage")
  }
    
  detectScene(image: ciImage)
    
  }
}

 // MARK: - UINavigationControllerDelegate
 extension ViewController: UINavigationControllerDelegate {
}

