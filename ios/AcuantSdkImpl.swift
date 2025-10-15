//
//  AcuantSdkImpl.swift
//  react-native-acuant-sdk
//
//  Swift implementation for Acuant SDK bridge
//
//  Data Flow:
//  JS Layer -> RN Bridge (AcuantSdk.m) -> This Swift impl -> Acuant SDK
//

import Foundation
import React
import UIKit
import AcuantCommon
import AcuantImagePreparation
import AcuantFaceCapture
import AcuantPassiveLiveness
import AcuantFaceMatch
import AcuantiOSSDKV11  // For DocumentCameraViewController
import AcuantDocumentProcessing

@objc(AcuantSdk)
class AcuantSdk: NSObject {

    // MARK: - State Management

    // Store document capture state for multi-step workflow
    private var documentCapturePromise: RCTPromiseResolveBlock?
    private var documentCaptureReject: RCTPromiseRejectBlock?
    private var capturedFrontImage: UIImage?
    private var capturedBackImage: UIImage?
    private var capturedBarcodeString: String?
    private var documentInstance: AcuantIdDocumentInstance?
    private var capturingFrontSide = true

    // MARK: - Initialization

    @objc
    func initialize(_ options: NSDictionary,
                   resolver resolve: @escaping RCTPromiseResolveBlock,
                   rejecter reject: @escaping RCTPromiseRejectBlock) {

        // Extract credentials or token
        if let token = options["token"] as? String {
            // Token-based initialization
            if !Credential.setToken(token: token) {
                reject("INVALID_TOKEN", "Invalid or expired token", nil)
                return
            }
        } else if let credentials = options["credentials"] as? NSDictionary {
            // Credential-based initialization
            guard let username = credentials["username"] as? String,
                  let password = credentials["password"] as? String,
                  let subscription = credentials["subscription"] as? String else {
                reject("INVALID_CREDENTIALS", "Missing required credentials: username, password, subscription", nil)
                return
            }

            Credential.setUsername(username: username)
            Credential.setPassword(password: password)
            Credential.setSubscription(subscription: subscription)
        } else {
            reject("INVALID_OPTIONS", "Must provide either token or credentials", nil)
            return
        }

        // Set endpoints if provided
        if let endpointsDict = options["endpoints"] as? NSDictionary {
            let endpoints = Endpoints()

            if let frmEndpoint = endpointsDict["frmEndpoint"] as? String {
                endpoints.frmEndpoint = frmEndpoint
            }
            if let passiveLivenessEndpoint = endpointsDict["passiveLivenessEndpoint"] as? String {
                endpoints.passiveLivenessEndpoint = passiveLivenessEndpoint
            }
            if let idEndpoint = endpointsDict["idEndpoint"] as? String {
                endpoints.idEndpoint = idEndpoint
            }
            if let acasEndpoint = endpointsDict["acasEndpoint"] as? String {
                endpoints.acasEndpoint = acasEndpoint
            }
            if let ozoneEndpoint = endpointsDict["ozoneEndpoint"] as? String {
                endpoints.ozoneEndpoint = ozoneEndpoint
            }
            if let healthInsuranceEndpoint = endpointsDict["healthInsuranceEndpoint"] as? String {
                endpoints.healthInsuranceEndpoint = healthInsuranceEndpoint
            }

            Credential.setEndpoints(endpoints: endpoints)
        } else if let region = options["region"] as? String {
            // Set endpoints based on region
            setEndpointsForRegion(region)
        }

        // Initialize SDK with required packages
        let packages: [IAcuantPackage] = [ImagePreparationPackage()]
        let initializer: IAcuantInitializer = AcuantInitializer()

        _ = initializer.initialize(packages: packages) { error in
            if let err = error {
                let errorCode = err.errorCode?.rawValue ?? "UNKNOWN"
                let errorMessage = err.errorDescription ?? "Initialization failed"
                reject(errorCode, errorMessage, nil)
            } else {
                resolve(nil)
            }
        }
    }

    // MARK: - Face Capture

    @objc
    func captureFace(_ options: NSDictionary,
                    resolver resolve: @escaping RCTPromiseResolveBlock,
                    rejecter reject: @escaping RCTPromiseRejectBlock) {

        DispatchQueue.main.async {
            guard let rootViewController = self.getRootViewController() else {
                reject("NO_VIEW_CONTROLLER", "Unable to get root view controller", nil)
                return
            }

            let controller = FaceCaptureController()
            controller.callback = { [weak self] faceCaptureResult in
                guard let self = self else { return }

                if let result = faceCaptureResult {
                    // Convert image to JPEG data
                    guard let image = result.image,
                          let jpegData = self.imageToJpegData(image, quality: 0.8) else {
                        reject("IMAGE_CONVERSION_FAILED", "Failed to convert image to JPEG", nil)
                        return
                    }

                    let base64String = self.dataToBase64(jpegData)

                    let resultDict: [String: Any] = [
                        "jpegData": base64String
                    ]

                    resolve(resultDict)
                } else {
                    reject("CAPTURE_FAILED", "Face capture failed or was cancelled", nil)
                }
            }

            rootViewController.present(controller, animated: true, completion: nil)
        }
    }

    // MARK: - Passive Liveness

    @objc
    func processPassiveLiveness(_ request: NSDictionary,
                               resolver resolve: @escaping RCTPromiseResolveBlock,
                               rejecter reject: @escaping RCTPromiseRejectBlock) {

        guard let jpegDataString = request["jpegData"] as? String else {
            reject("INVALID_REQUEST", "Missing jpegData", nil)
            return
        }

        guard let jpegData = base64ToData(jpegDataString) else {
            reject("INVALID_IMAGE", "Failed to decode base64 image data", nil)
            return
        }

        let livenessRequest = AcuantLivenessRequest(jpegData: jpegData)

        PassiveLiveness.postLiveness(request: livenessRequest) { [weak self] result, error in
            guard let self = self else { return }

            if let err = error {
                let errorCode = err.errorCode?.rawValue ?? "UNKNOWN"
                let errorMessage = err.description ?? "Passive liveness processing failed"
                reject(errorCode, errorMessage, nil)
                return
            }

            if let livenessResult = result {
                let assessment = self.mapLivenessAssessment(livenessResult.result)

                let resultDict: [String: Any] = [
                    "score": livenessResult.score,
                    "assessment": assessment
                ]

                resolve(resultDict)
            } else {
                reject("NO_RESULT", "No result returned from liveness processing", nil)
            }
        }
    }

    // MARK: - Face Match

    @objc
    func processFaceMatch(_ request: NSDictionary,
                         resolver resolve: @escaping RCTPromiseResolveBlock,
                         rejecter reject: @escaping RCTPromiseRejectBlock) {

        guard let faceOneDataString = request["faceOneData"] as? String,
              let faceTwoDataString = request["faceTwoData"] as? String else {
            reject("INVALID_REQUEST", "Missing faceOneData or faceTwoData", nil)
            return
        }

        guard let faceOneData = base64ToData(faceOneDataString),
              let faceTwoData = base64ToData(faceTwoDataString) else {
            reject("INVALID_IMAGE", "Failed to decode base64 image data", nil)
            return
        }

        let facialMatchData = FacialMatchData(faceOneData: faceOneData, faceTwoData: faceTwoData)

        FaceMatch.processFacialMatch(facialData: facialMatchData, delegate: FacialMatchDelegateImpl(
            onSuccess: { result in
                if let error = result.error {
                    reject("FACE_MATCH_ERROR", error.errorDescription ?? "Face match failed", nil)
                    return
                }

                let resultDict: [String: Any] = [
                    "isMatch": result.isMatch,
                    "score": result.score
                ]

                resolve(resultDict)
            },
            onError: { errorMessage in
                reject("FACE_MATCH_ERROR", errorMessage, nil)
            }
        ))
    }

    // MARK: - Helper Methods

    private func base64ToData(_ base64String: String) -> Data? {
        return Data(base64Encoded: base64String)
    }

    private func dataToBase64(_ data: Data) -> String {
        return data.base64EncodedString()
    }

    private func imageToJpegData(_ image: UIImage, quality: CGFloat = 0.8) -> Data? {
        return image.jpegData(compressionQuality: quality)
    }

    private func getRootViewController() -> UIViewController? {
        guard let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }),
              let rootViewController = window.rootViewController else {
            return nil
        }

        var topViewController = rootViewController
        while let presentedViewController = topViewController.presentedViewController {
            topViewController = presentedViewController
        }

        return topViewController
    }

    private func mapLivenessAssessment(_ assessment: AcuantLivenessAssessment) -> String {
        switch assessment {
        case .live:
            return "Live"
        case .notLive:
            return "NotLive"
        case .poorQuality:
            return "PoorQuality"
        case .error:
            return "Error"
        @unknown default:
            return "Error"
        }
    }

    private func setEndpointsForRegion(_ region: String) {
        let endpoints = Endpoints()

        switch region.uppercased() {
        case "USA":
            endpoints.frmEndpoint = "https://frm.acuant.net"
            endpoints.passiveLivenessEndpoint = "https://us.passlive.acuant.net"
            endpoints.healthInsuranceEndpoint = "https://medicscan.acuant.net"
            endpoints.idEndpoint = "https://services.assureid.net"
            endpoints.acasEndpoint = "https://acas.acuant.net"
            endpoints.ozoneEndpoint = "https://ozone.acuant.net"

        case "EU":
            endpoints.frmEndpoint = "https://eu.frm.acuant.net"
            endpoints.passiveLivenessEndpoint = "https://eu.passlive.acuant.net"
            endpoints.idEndpoint = "https://eu.assureid.acuant.net"
            endpoints.acasEndpoint = "https://eu.acas.acuant.net"
            endpoints.ozoneEndpoint = "https://eu.ozone.acuant.net"

        case "AUS":
            endpoints.frmEndpoint = "https://aus.frm.acuant.net"
            endpoints.passiveLivenessEndpoint = "https://aus.passlive.acuant.net"
            endpoints.idEndpoint = "https://aus.assureid.acuant.net"
            endpoints.acasEndpoint = "https://aus.acas.acuant.net"
            endpoints.ozoneEndpoint = "https://aus.ozone.acuant.net"

        case "PREVIEW":
            endpoints.frmEndpoint = "https://preview.face.acuant.net"
            endpoints.passiveLivenessEndpoint = "https://preview.passlive.acuant.net"
            endpoints.healthInsuranceEndpoint = "https://preview.medicscan.acuant.net"
            endpoints.idEndpoint = "https://preview.assureid.acuant.net"
            endpoints.acasEndpoint = "https://preview.acas.acuant.net"
            endpoints.ozoneEndpoint = "https://preview.ozone.acuant.net"

        default:
            // Default to USA
            endpoints.frmEndpoint = "https://frm.acuant.net"
            endpoints.passiveLivenessEndpoint = "https://us.passlive.acuant.net"
            endpoints.healthInsuranceEndpoint = "https://medicscan.acuant.net"
            endpoints.idEndpoint = "https://services.assureid.net"
            endpoints.acasEndpoint = "https://acas.acuant.net"
            endpoints.ozoneEndpoint = "https://ozone.acuant.net"
        }

        Credential.setEndpoints(endpoints: endpoints)
    }

    // MARK: - Document Capture and Processing (Phase 2)

    @objc
    func captureAndProcessDocument(_ options: NSDictionary,
                                   resolver resolve: @escaping RCTPromiseResolveBlock,
                                   rejecter reject: @escaping RCTPromiseRejectBlock) {

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // Reset state
            self.documentCapturePromise = resolve
            self.documentCaptureReject = reject
            self.capturedFrontImage = nil
            self.capturedBackImage = nil
            self.capturedBarcodeString = nil
            self.capturingFrontSide = true

            self.launchDocumentCamera()
        }
    }

    private func launchDocumentCamera() {
        guard let rootViewController = getRootViewController() else {
            documentCaptureReject?("NO_VIEW_CONTROLLER", "Unable to get root view controller", nil)
            cleanup()
            return
        }

        // Configure camera options
        let textForState: (DocumentCameraState) -> String = { state in
            switch state {
            case .align: return "ALIGN DOCUMENT"
            case .moveCloser: return "MOVE CLOSER"
            case .tooClose: return "TOO CLOSE"
            case .steady: return "HOLD STEADY"
            case .hold: return "HOLD"
            case .capture: return "CAPTURING"
            @unknown default: return ""
            }
        }

        let options = DocumentCameraOptions(autoCapture: true, hideNavigationBar: false, textForState: textForState)
        let documentCameraViewController = DocumentCameraViewController(options: options)
        documentCameraViewController.delegate = self

        // Present with navigation controller for back button
        let navController = UINavigationController(rootViewController: documentCameraViewController)
        navController.modalPresentationStyle = .fullScreen
        rootViewController.present(navController, animated: true, completion: nil)
    }

    private func processDocument() {
        guard let frontImage = capturedFrontImage else {
            documentCaptureReject?("NO_FRONT_IMAGE", "Front image not captured", nil)
            cleanup()
            return
        }

        // Evaluate front image quality
        guard let frontImageData = imageToJpegData(frontImage, quality: 1.0) else {
            documentCaptureReject?("IMAGE_CONVERSION_FAILED", "Failed to convert front image", nil)
            cleanup()
            return
        }

        let cropOptions = CroppingData()
        ImagePreparation.evaluateImage(data: frontImageData, cropping: cropOptions) { [weak self] image, error in
            guard let self = self else { return }

            if let err = error {
                self.documentCaptureReject?("IMAGE_EVALUATION_FAILED", err.errorDescription ?? "Failed to evaluate image", nil)
                self.cleanup()
                return
            }

            guard let evaluatedImage = image else {
                self.documentCaptureReject?("IMAGE_EVALUATION_FAILED", "No image returned from evaluation", nil)
                self.cleanup()
                return
            }

            // Check image quality
            if evaluatedImage.sharpness < 50 {
                self.documentCaptureReject?("IMAGE_TOO_BLURRY", "Image is too blurry (sharpness: \\(evaluatedImage.sharpness))", nil)
                self.cleanup()
                return
            }

            if evaluatedImage.glare < 50 {
                self.documentCaptureReject?("IMAGE_HAS_GLARE", "Image has too much glare (glare: \\(evaluatedImage.glare))", nil)
                self.cleanup()
                return
            }

            // Create document instance
            let instanceOptions = IdOptions()

            DocumentProcessing.createInstance(options: instanceOptions, callback: { [weak self] result in
                guard let self = self else { return }

                if let err = result.error {
                    self.documentCaptureReject?("CREATE_INSTANCE_FAILED", err.errorDescription ?? "Failed to create instance", nil)
                    self.cleanup()
                    return
                }

                guard let instance = result.instance else {
                    self.documentCaptureReject?("CREATE_INSTANCE_FAILED", "No instance returned", nil)
                    self.cleanup()
                    return
                }

                self.documentInstance = instance
                self.uploadFrontImage(evaluatedImage)
            })
        }
    }

    private func uploadFrontImage(_ image: Image) {
        guard let instance = documentInstance else {
            documentCaptureReject?("NO_INSTANCE", "Document instance not created", nil)
            cleanup()
            return
        }

        let uploadData = EvaluatedImageData(image: image)

        instance.uploadFront(evaluatedImageData: uploadData, callback: { [weak self] result in
            guard let self = self else { return }

            if let err = result.error {
                self.documentCaptureReject?("UPLOAD_FRONT_FAILED", err.errorDescription ?? "Failed to upload front image", nil)
                self.cleanup()
                return
            }

            // Check if we have a back image to upload
            if let backImage = self.capturedBackImage {
                self.evaluateAndUploadBackImage(backImage)
            } else {
                // No back image - process with front only (e.g., passport)
                self.getDocumentData()
            }
        })
    }

    private func evaluateAndUploadBackImage(_ backImage: UIImage) {
        guard let instance = documentInstance else {
            documentCaptureReject?("NO_INSTANCE", "Document instance not created", nil)
            cleanup()
            return
        }

        guard let backImageData = imageToJpegData(backImage, quality: 1.0) else {
            documentCaptureReject?("IMAGE_CONVERSION_FAILED", "Failed to convert back image", nil)
            cleanup()
            return
        }

        let cropOptions = CroppingData()
        ImagePreparation.evaluateImage(data: backImageData, cropping: cropOptions) { [weak self] image, error in
            guard let self = self else { return }

            if let err = error {
                self.documentCaptureReject?("IMAGE_EVALUATION_FAILED", err.errorDescription ?? "Failed to evaluate back image", nil)
                self.cleanup()
                return
            }

            guard let evaluatedImage = image else {
                self.documentCaptureReject?("IMAGE_EVALUATION_FAILED", "No back image returned from evaluation", nil)
                self.cleanup()
                return
            }

            let uploadData = EvaluatedImageData(image: evaluatedImage)

            instance.uploadBack(evaluatedImageData: uploadData, callback: { [weak self] result in
                guard let self = self else { return }

                if let err = result.error {
                    self.documentCaptureReject?("UPLOAD_BACK_FAILED", err.errorDescription ?? "Failed to upload back image", nil)
                    self.cleanup()
                    return
                }

                self.getDocumentData()
            })
        }
    }

    private func getDocumentData() {
        guard let instance = documentInstance else {
            documentCaptureReject?("NO_INSTANCE", "Document instance not created", nil)
            cleanup()
            return
        }

        instance.getData(callback: { [weak self] result in
            guard let self = self else { return }

            if let err = result.error {
                self.documentCaptureReject?("GET_DATA_FAILED", err.errorDescription ?? "Failed to get document data", nil)
                self.cleanup()
                return
            }

            guard let idResult = result.result else {
                self.documentCaptureReject?("GET_DATA_FAILED", "No data returned", nil)
                self.cleanup()
                return
            }

            // Build response dictionary
            var resultDict: [String: Any] = [:]

            // Add captured images
            if let frontImage = self.capturedFrontImage,
               let frontJpeg = self.imageToJpegData(frontImage, quality: 0.8) {
                resultDict["frontImage"] = self.dataToBase64(frontJpeg)
            }

            if let backImage = self.capturedBackImage,
               let backJpeg = self.imageToJpegData(backImage, quality: 0.8) {
                resultDict["backImage"] = self.dataToBase64(backJpeg)
            }

            // Add OCR data (flat structure)
            if let name = idResult.name {
                resultDict["fullName"] = name
            }
            if let firstName = idResult.firstName {
                resultDict["firstName"] = firstName
            }
            if let lastName = idResult.lastName {
                resultDict["lastName"] = lastName
            }
            if let dob = idResult.dateOfBirth {
                resultDict["dateOfBirth"] = dob
            }
            if let docNumber = idResult.documentNumber {
                resultDict["documentNumber"] = docNumber
            }
            if let expDate = idResult.expirationDate {
                resultDict["expirationDate"] = expDate
            }
            if let issueDate = idResult.issueDate {
                resultDict["issueDate"] = issueDate
            }
            if let address = idResult.address {
                resultDict["address"] = address
            }
            if let country = idResult.country {
                resultDict["country"] = country
            }
            if let nationality = idResult.nationality {
                resultDict["nationality"] = nationality
            }
            if let sex = idResult.sex {
                resultDict["sex"] = sex
            }

            // Metadata
            resultDict["isProcessed"] = true
            resultDict["documentType"] = idResult.type ?? "Unknown"
            if let classification = idResult.classification {
                resultDict["classificationDetails"] = classification
            }

            self.documentCapturePromise?(resultDict)
            self.cleanup()

            // Delete instance
            instance.deleteInstance(callback: { _ in })
        })
    }

    private func cleanup() {
        documentCapturePromise = nil
        documentCaptureReject = nil
        capturedFrontImage = nil
        capturedBackImage = nil
        capturedBarcodeString = nil
        documentInstance = nil
        capturingFrontSide = true
    }
}

// MARK: - DocumentCameraViewControllerDelegate

extension AcuantSdk: DocumentCameraViewControllerDelegate {
    func onCaptured(image: Image, barcodeString: String?) {
        // Dismiss camera
        getRootViewController()?.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }

            if let capturedImage = image.image {
                if self.capturingFrontSide {
                    // Captured front side
                    self.capturedFrontImage = capturedImage
                    self.capturedBarcodeString = barcodeString
                    self.capturingFrontSide = false

                    // Ask user if they want to capture back side
                    self.promptForBackSideCapture()
                } else {
                    // Captured back side
                    self.capturedBackImage = capturedImage

                    // Process document with both sides
                    self.processDocument()
                }
            } else {
                // User cancelled
                self.documentCaptureReject?("USER_CANCELED", "User canceled document capture", nil)
                self.cleanup()
            }
        }
    }

    private func promptForBackSideCapture() {
        guard let rootViewController = getRootViewController() else {
            // No back side - process with front only
            processDocument()
            return
        }

        let alert = UIAlertController(
            title: "Capture Back Side?",
            message: "Do you want to capture the back side of the document?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Yes", style: .default) { [weak self] _ in
            self?.launchDocumentCamera()
        })

        alert.addAction(UIAlertAction(title: "No (Front Only)", style: .default) { [weak self] _ in
            self?.processDocument()
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            self?.documentCaptureReject?("USER_CANCELED", "User canceled document capture", nil)
            self?.cleanup()
        })

        rootViewController.present(alert, animated: true, completion: nil)
    }
}

// MARK: - FacialMatch Delegate Implementation

private class FacialMatchDelegateImpl: NSObject, FacialMatchDelegate {
    let onSuccess: (FacialMatchResult) -> Void
    let onError: (String) -> Void

    init(onSuccess: @escaping (FacialMatchResult) -> Void, onError: @escaping (String) -> Void) {
        self.onSuccess = onSuccess
        self.onError = onError
    }

    func facialMatchFinished(result: FacialMatchResult?) {
        if let result = result {
            onSuccess(result)
        } else {
            onError("No result returned from face match")
        }
    }
}
