//
//  ScanViewController.swift
//  Indigen
//
//  Created by Walid on 31/10/2022.
//

import Foundation
import UIKit
import AVFoundation

protocol QRSCannerDelegate {
    func didGetCode(_ code: String)
}

class ScanViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    @IBOutlet weak var middleView: UIView!
    @IBOutlet weak var flashButton: UIImageView!
    @IBOutlet weak var chooseImgBuuton: UIButton!
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var delegate: QRSCannerDelegate?
    var zoomFactor: Float = 1.0
    var imagePicker = UIImagePickerController()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavBar()
        if (captureSession?.isRunning == false) {
            captureSession.startRunning()
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initView()
    }
    
    func initView() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTouchFlashButton))
        flashButton.addGestureRecognizer(tap)
        
        chooseImgBuuton.addTarget(self, action: #selector(selectPicture), for: .touchUpInside)
        
        view.backgroundColor = UIColor.black
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }
        
        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            failed()
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            failed()
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.insertSublayer(previewLayer, at: 0)
        
        captureSession.startRunning()
        fadeOut(finished: true)
    }
    
    func fadeIn(finished: Bool) {
        UIView.animate(withDuration: 0.3, animations: {[weak self] in
            self?.middleView.alpha = 0
        }) {[weak self] (finished) in
            self?.fadeOut(finished: finished)
        }
    }
    
    func fadeOut(finished: Bool) {
        UIView.animate(withDuration: 0.3, animations: {[weak self] in
            self?.middleView.alpha = 1
        }) {[weak self] (finished) in
            self?.fadeIn(finished: finished)
        }
    }
    
    func failed() {
        presentSimpleAlert("Erreur", message: "Votre iPhone ne supporte pas le scan du QR Code", buttonTitle: "Ok")
        captureSession = nil
    }
    
    @objc func didTouchFlashButton() {
        if let avDevice = AVCaptureDevice.default(for: AVMediaType.video) {
            if (avDevice.hasTorch) {
                do {
                    try avDevice.lockForConfiguration()
                } catch {
                    print("Error")
                }
                
                if avDevice.isTorchActive {
                    avDevice.torchMode = AVCaptureDevice.TorchMode.off
                    flashButton.image = UIImage(named: "flash-off")
                } else {
                    avDevice.torchMode = AVCaptureDevice.TorchMode.on
                    flashButton.image = UIImage(named: "flash-on")
                }
            }
            avDevice.unlockForConfiguration()
        }
    }
    
    @objc func selectPicture() {
        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum){
            imagePicker.delegate = self
            imagePicker.sourceType = .savedPhotosAlbum
            imagePicker.allowsEditing = false
            present(imagePicker, animated: true, completion: nil)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if (captureSession?.isRunning == true) {
            captureSession.stopRunning()
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession.stopRunning()
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            found(code: stringValue)
        }
    }
    
    func found(code: String) {
        print("message: \(code)")
        self.dismiss(animated: true)
        delegate?.didGetCode(code)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
}

extension ScanViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    //MARK: Function called when photo selected
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        self.dismiss(animated: true)
        guard
            let qrcodeImg = info[UIImagePickerController.InfoKey(rawValue: UIImagePickerController.InfoKey.originalImage.rawValue) ] as? UIImage,
            let detector: CIDetector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy:CIDetectorAccuracyHigh]),
            let ciImage: CIImage = CIImage(image:qrcodeImg),
            let features = detector.features(in: ciImage) as? [CIQRCodeFeature]
        else {
            print("Something went wrong")
            return
        }
        var qrCode = ""
        features.forEach { feature in
            if let messageString = feature.messageString {
                qrCode += messageString
            }
        }
        if qrCode.isEmpty {
            print("qrCode is empty!")
            self.presentSimpleAlert("QRCode", message: "Aucune données", buttonTitle: "Fermer")
        } else {
            self.presentSimpleAlert("QRCode", message: qrCode, buttonTitle: "Fermer")
        }
    }
}
