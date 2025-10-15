package com.acuantsdk

import android.app.Activity
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.util.Base64
import com.acuant.acuantcommon.background.AcuantListener
import com.acuant.acuantcommon.exception.AcuantException
import com.acuant.acuantcommon.initializer.AcuantInitializer
import com.acuant.acuantcommon.initializer.IAcuantPackageCallback
import com.acuant.acuantcommon.model.AcuantError
import com.acuant.acuantcommon.model.Credential
import com.acuant.acuantcommon.model.Error
import com.acuant.acuantfacecapture.constant.Constants.ACUANT_EXTRA_FACE_CAPTURE_OPTIONS
import com.acuant.acuantfacecapture.constant.Constants.ACUANT_EXTRA_FACE_IMAGE_URL
import com.acuant.acuantfacecapture.detector.FaceCaptureOptions
import com.acuant.acuantfacecapture.ui.AcuantFaceCameraActivity
import com.acuant.acuantfacematch.model.FacialMatchData
import com.acuant.acuantfacematch.model.FacialMatchResult
import com.acuant.acuantfacematch.service.AcuantFaceMatch
import com.acuant.acuantfacematch.service.FacialMatchListener
import com.acuant.acuantpassiveliveness.model.PassiveLivenessData
import com.acuant.acuantpassiveliveness.model.PassiveLivenessResult
import com.acuant.acuantpassiveliveness.service.AcuantPassiveLiveness
import com.acuant.acuantpassiveliveness.service.PassiveLivenessListener
import com.facebook.react.bridge.*
import java.io.ByteArrayOutputStream
import java.io.File

/**
 * AcuantSdkModule
 *
 * React Native bridge for Acuant SDK on Android
 *
 * Design Principles (Linus Torvalds):
 * 1. Thin bridge layer - no business logic
 * 2. Direct mapping to Acuant SDK methods
 * 3. All async methods return via Promise
 * 4. No special cases - consistent error handling
 *
 * Data Flow:
 * JS Layer -> RN Bridge -> This Kotlin module -> Acuant SDK
 */
class AcuantSdkModule(reactContext: ReactApplicationContext) :
  ReactContextBaseJavaModule(reactContext) {

  private var faceCapturePromise: Promise? = null

  companion object {
    private const val FACE_CAPTURE_REQUEST_CODE = 1001
  }

  override fun getName(): String {
    return "AcuantSdk"
  }

  // MARK: - Initialization

  @ReactMethod
  fun initialize(options: ReadableMap, promise: Promise) {
    try {
      // Extract credentials or token
      if (options.hasKey("token")) {
        val token = options.getString("token")
        if (token.isNullOrEmpty()) {
          promise.reject("INVALID_TOKEN", "Token is empty")
          return
        }
        // Token-based initialization would be handled here
        // For now, we'll proceed with credential-based init
      } else if (options.hasKey("credentials")) {
        val credentials = options.getMap("credentials")
        if (credentials == null) {
          promise.reject("INVALID_CREDENTIALS", "Credentials map is null")
          return
        }

        val username = credentials.getString("username")
        val password = credentials.getString("password")
        val subscription = credentials.getString("subscription")

        if (username.isNullOrEmpty() || password.isNullOrEmpty() || subscription.isNullOrEmpty()) {
          promise.reject("INVALID_CREDENTIALS", "Missing required credentials: username, password, subscription")
          return
        }

        // Set endpoints based on region or custom endpoints
        var acasEndpoint = "https://us.acas.acuant.net"
        var assureIdEndpoint = "https://us.assureid.acuant.net"
        var frmEndpoint: String? = "https://frm.acuant.net"
        var passiveLivenessEndpoint: String? = "https://us.passlive.acuant.net"
        var ozoneEndpoint: String? = "https://ozone.acuant.net"
        var healthInsuranceEndpoint: String? = "https://medicscan.acuant.net"

        if (options.hasKey("endpoints")) {
          val endpoints = options.getMap("endpoints")
          if (endpoints != null) {
            if (endpoints.hasKey("acasEndpoint")) {
              acasEndpoint = endpoints.getString("acasEndpoint") ?: acasEndpoint
            }
            if (endpoints.hasKey("assureIdEndpoint")) {
              assureIdEndpoint = endpoints.getString("assureIdEndpoint") ?: assureIdEndpoint
            }
            if (endpoints.hasKey("frmEndpoint")) {
              frmEndpoint = endpoints.getString("frmEndpoint")
            }
            if (endpoints.hasKey("passiveLivenessEndpoint")) {
              passiveLivenessEndpoint = endpoints.getString("passiveLivenessEndpoint")
            }
            if (endpoints.hasKey("ozoneEndpoint")) {
              ozoneEndpoint = endpoints.getString("ozoneEndpoint")
            }
            if (endpoints.hasKey("healthInsuranceEndpoint")) {
              healthInsuranceEndpoint = endpoints.getString("healthInsuranceEndpoint")
            }
          }
        } else if (options.hasKey("region")) {
          val region = options.getString("region")?.uppercase() ?: "USA"
          when (region) {
            "USA" -> {
              acasEndpoint = "https://us.acas.acuant.net"
              assureIdEndpoint = "https://us.assureid.acuant.net"
              frmEndpoint = "https://frm.acuant.net"
              passiveLivenessEndpoint = "https://us.passlive.acuant.net"
              ozoneEndpoint = "https://ozone.acuant.net"
              healthInsuranceEndpoint = "https://medicscan.acuant.net"
            }
            "EU" -> {
              acasEndpoint = "https://eu.acas.acuant.net"
              assureIdEndpoint = "https://eu.assureid.acuant.net"
              frmEndpoint = "https://eu.frm.acuant.net"
              passiveLivenessEndpoint = "https://eu.passlive.acuant.net"
              ozoneEndpoint = "https://eu.ozone.acuant.net"
            }
            "AUS" -> {
              acasEndpoint = "https://aus.acas.acuant.net"
              assureIdEndpoint = "https://aus.assureid.acuant.net"
              frmEndpoint = "https://aus.frm.acuant.net"
              passiveLivenessEndpoint = "https://aus.passlive.acuant.net"
              ozoneEndpoint = "https://aus.ozone.acuant.net"
            }
            "PREVIEW" -> {
              acasEndpoint = "https://preview.acas.acuant.net"
              assureIdEndpoint = "https://preview.assureid.acuant.net"
              frmEndpoint = "https://preview.face.acuant.net"
              passiveLivenessEndpoint = "https://preview.passlive.acuant.net"
              ozoneEndpoint = "https://preview.ozone.acuant.net"
              healthInsuranceEndpoint = "https://preview.medicscan.acuant.net"
            }
          }
        }

        // Initialize credential
        Credential.init(
          username = username,
          password = password,
          subscription = subscription,
          acasEndpoint = acasEndpoint,
          assureIdEndpoint = assureIdEndpoint,
          frmEndpoint = frmEndpoint,
          passiveLivenessEndpoint = passiveLivenessEndpoint,
          ozoneEndpoint = ozoneEndpoint,
          healthInsuranceEndpoint = healthInsuranceEndpoint
        )
      } else {
        promise.reject("INVALID_OPTIONS", "Must provide either token or credentials")
        return
      }

      // Initialize SDK
      AcuantInitializer.initialize(
        null,
        reactApplicationContext,
        emptyList(),
        object : IAcuantPackageCallback {
          override fun onInitializeSuccess() {
            promise.resolve(null)
          }

          override fun onInitializeFailed(errors: List<Error>) {
            val errorMessage = errors.joinToString(", ") { it.errorDescription ?: "Unknown error" }
            promise.reject("INITIALIZATION_FAILED", errorMessage)
          }
        }
      )

    } catch (e: AcuantException) {
      promise.reject("INIT_ERROR", e.message, e)
    } catch (e: Exception) {
      promise.reject("INIT_ERROR", e.message, e)
    }
  }

  // MARK: - Face Capture

  @ReactMethod
  fun captureFace(options: ReadableMap, promise: Promise) {
    val activity = currentActivity
    if (activity == null) {
      promise.reject("NO_ACTIVITY", "Current activity is null")
      return
    }

    try {
      faceCapturePromise = promise

      val cameraIntent = Intent(activity, AcuantFaceCameraActivity::class.java)

      // Parse options if provided
      val faceCaptureOptions = FaceCaptureOptions()
      cameraIntent.putExtra(ACUANT_EXTRA_FACE_CAPTURE_OPTIONS, faceCaptureOptions)

      activity.startActivityForResult(cameraIntent, FACE_CAPTURE_REQUEST_CODE)

    } catch (e: Exception) {
      promise.reject("CAPTURE_ERROR", e.message, e)
    }
  }

  // MARK: - Passive Liveness

  @ReactMethod
  fun processPassiveLiveness(request: ReadableMap, promise: Promise) {
    try {
      if (!request.hasKey("jpegData")) {
        promise.reject("INVALID_REQUEST", "Missing jpegData")
        return
      }

      val jpegDataString = request.getString("jpegData")
      if (jpegDataString.isNullOrEmpty()) {
        promise.reject("INVALID_REQUEST", "jpegData is empty")
        return
      }

      val bitmap = base64ToBitmap(jpegDataString)
      if (bitmap == null) {
        promise.reject("INVALID_IMAGE", "Failed to decode base64 image data")
        return
      }

      val passiveLivenessData = PassiveLivenessData(bitmap)

      AcuantPassiveLiveness.processFaceLiveness(passiveLivenessData, object : PassiveLivenessListener {
        override fun passiveLivenessFinished(result: PassiveLivenessResult) {
          val assessment = when (result.livenessResult?.livenessAssessment) {
            AcuantPassiveLiveness.LivenessAssessment.Live -> "Live"
            AcuantPassiveLiveness.LivenessAssessment.NotLive -> "NotLive"
            AcuantPassiveLiveness.LivenessAssessment.PoorQuality -> "PoorQuality"
            AcuantPassiveLiveness.LivenessAssessment.Error -> "Error"
            else -> "Error"
          }

          val score = result.livenessResult?.score ?: 0

          val resultMap = Arguments.createMap().apply {
            putInt("score", score)
            putString("assessment", assessment)
            result.transactionId?.let { putString("transactionId", it) }
          }

          promise.resolve(resultMap)
        }

        override fun onError(error: AcuantError) {
          val errorCode = error.errorCode?.name ?: "UNKNOWN"
          val errorMessage = error.errorDescription ?: "Passive liveness processing failed"
          promise.reject(errorCode, errorMessage)
        }
      })

    } catch (e: Exception) {
      promise.reject("LIVENESS_ERROR", e.message, e)
    }
  }

  // MARK: - Face Match

  @ReactMethod
  fun processFaceMatch(request: ReadableMap, promise: Promise) {
    try {
      if (!request.hasKey("faceOneData") || !request.hasKey("faceTwoData")) {
        promise.reject("INVALID_REQUEST", "Missing faceOneData or faceTwoData")
        return
      }

      val faceOneDataString = request.getString("faceOneData")
      val faceTwoDataString = request.getString("faceTwoData")

      if (faceOneDataString.isNullOrEmpty() || faceTwoDataString.isNullOrEmpty()) {
        promise.reject("INVALID_REQUEST", "faceOneData or faceTwoData is empty")
        return
      }

      val faceOneBitmap = base64ToBitmap(faceOneDataString)
      val faceTwoBitmap = base64ToBitmap(faceTwoDataString)

      if (faceOneBitmap == null || faceTwoBitmap == null) {
        promise.reject("INVALID_IMAGE", "Failed to decode base64 image data")
        return
      }

      val facialMatchData = FacialMatchData().apply {
        faceImageOne = faceOneBitmap
        faceImageTwo = faceTwoBitmap
      }

      AcuantFaceMatch.processFacialMatch(facialMatchData, object : FacialMatchListener {
        override fun facialMatchFinished(result: FacialMatchResult) {
          if (result.error != null) {
            val errorMessage = result.error?.errorDescription ?: "Face match failed"
            promise.reject("FACE_MATCH_ERROR", errorMessage)
            return
          }

          val resultMap = Arguments.createMap().apply {
            putBoolean("isMatch", result.isMatch)
            putInt("score", result.score)
          }

          promise.resolve(resultMap)
        }

        override fun onError(error: AcuantError) {
          val errorMessage = error.errorDescription ?: "Face match processing failed"
          promise.reject("FACE_MATCH_ERROR", errorMessage)
        }
      })

    } catch (e: Exception) {
      promise.reject("FACE_MATCH_ERROR", e.message, e)
    }
  }

  // MARK: - Activity Result Handling

  private val activityEventListener = object : BaseActivityEventListener() {
    override fun onActivityResult(
      activity: Activity?,
      requestCode: Int,
      resultCode: Int,
      data: Intent?
    ) {
      if (requestCode == FACE_CAPTURE_REQUEST_CODE) {
        handleFaceCaptureResult(resultCode, data)
      }
    }
  }

  init {
    reactApplicationContext.addActivityEventListener(activityEventListener)
  }

  private fun handleFaceCaptureResult(resultCode: Int, data: Intent?) {
    val promise = faceCapturePromise ?: return
    faceCapturePromise = null

    when (resultCode) {
      Activity.RESULT_OK -> {
        val imageUrl = data?.getStringExtra(ACUANT_EXTRA_FACE_IMAGE_URL)
        if (imageUrl.isNullOrEmpty()) {
          promise.reject("CAPTURE_FAILED", "No image URL returned from face capture")
          return
        }

        try {
          // Read image from file
          val bytes = readFromFile(imageUrl)
          val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size)

          if (bitmap == null) {
            promise.reject("IMAGE_CONVERSION_FAILED", "Failed to decode captured image")
            return
          }

          // Convert to JPEG base64
          val base64String = bitmapToBase64(bitmap)

          val resultMap = Arguments.createMap().apply {
            putString("jpegData", base64String)
            putString("imageUri", imageUrl)
          }

          promise.resolve(resultMap)

        } catch (e: Exception) {
          promise.reject("CAPTURE_ERROR", "Failed to process captured image: ${e.message}", e)
        }
      }
      Activity.RESULT_CANCELED -> {
        promise.reject("USER_CANCELED", "User canceled face capture")
      }
      else -> {
        promise.reject("CAPTURE_FAILED", "Face capture failed with result code: $resultCode")
      }
    }
  }

  // MARK: - Helper Methods

  private fun base64ToBitmap(base64String: String): Bitmap? {
    return try {
      val decodedBytes = Base64.decode(base64String, Base64.DEFAULT)
      BitmapFactory.decodeByteArray(decodedBytes, 0, decodedBytes.size)
    } catch (e: Exception) {
      null
    }
  }

  private fun bitmapToBase64(bitmap: Bitmap): String {
    val byteArrayOutputStream = ByteArrayOutputStream()
    bitmap.compress(Bitmap.CompressFormat.JPEG, 80, byteArrayOutputStream)
    val byteArray = byteArrayOutputStream.toByteArray()
    return Base64.encodeToString(byteArray, Base64.NO_WRAP)
  }

  private fun readFromFile(path: String): ByteArray {
    val file = File(path)
    return file.readBytes()
  }
}
