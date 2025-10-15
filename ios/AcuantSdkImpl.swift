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

@objc(AcuantSdk)
class AcuantSdk: NSObject {

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
