/**
 * Acuant SDK React Native Wrapper
 * Phase 1: Face Recognition and Identity Verification
 * Phase 2: Document Scanning and OCR
 *
 * Design Philosophy (Linus Torvalds principles):
 * 1. Simple, direct mapping to native SDK - no unnecessary abstraction
 * 2. Single responsibility per method
 * 3. Errors are explicit, not hidden
 * 4. No special cases - same API for both platforms
 */

import { NativeModules, Platform } from 'react-native';
import type {
  AcuantInitializationOptions,
  FaceCaptureOptions,
  FaceCaptureResult,
  PassiveLivenessRequest,
  PassiveLivenessResult,
  FaceMatchRequest,
  FaceMatchResult,
  DocumentCaptureOptions,
  DocumentResult,
  AcuantError,
} from './types';

const LINKING_ERROR =
  `The package 'react-native-acuant-sdk' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo managed workflow\n';

const AcuantSdk = NativeModules.AcuantSdk
  ? NativeModules.AcuantSdk
  : new Proxy(
      {},
      {
        get() {
          throw new Error(LINKING_ERROR);
        },
      }
    );

// ============================================================================
// SDK Initialization
// ============================================================================

/**
 * Initialize the Acuant SDK
 *
 * Must be called before any other SDK methods.
 * Either provide credentials or token, not both.
 *
 * @param options - Initialization options (credentials or token + endpoints)
 * @throws {AcuantError} If initialization fails
 */
export async function initialize(
  options: AcuantInitializationOptions
): Promise<void> {
  return AcuantSdk.initialize(options);
}

// ============================================================================
// Face Capture
// ============================================================================

/**
 * Launch the face capture UI
 *
 * Opens a native camera UI optimized for capturing a face image
 * suitable for passive liveness detection.
 *
 * @param options - Face capture options
 * @returns Promise with captured face image data
 * @throws {AcuantError} If capture fails or user cancels
 */
export async function captureFace(
  options?: FaceCaptureOptions
): Promise<FaceCaptureResult> {
  return AcuantSdk.captureFace(options || {});
}

// ============================================================================
// Passive Liveness
// ============================================================================

/**
 * Process passive liveness detection on a face image
 *
 * Analyzes a single face image to determine if it's from a live person.
 * Use the LivenessAssessment (not score) for decision making.
 *
 * @param request - Liveness request with face image data
 * @returns Promise with liveness result
 * @throws {AcuantError} If processing fails
 */
export async function processPassiveLiveness(
  request: PassiveLivenessRequest
): Promise<PassiveLivenessResult> {
  return AcuantSdk.processPassiveLiveness(request);
}

// ============================================================================
// Face Match
// ============================================================================

/**
 * Match two face images
 *
 * Compares two facial images to determine if they are the same person.
 * Typically used to match ID photo with selfie.
 *
 * @param request - Face match request with two face images
 * @returns Promise with match result and score
 * @throws {AcuantError} If matching fails
 */
export async function processFaceMatch(
  request: FaceMatchRequest
): Promise<FaceMatchResult> {
  return AcuantSdk.processFaceMatch(request);
}

// ============================================================================
// Document Capture and Processing (Phase 2)
// ============================================================================

/**
 * Capture and process a document in one call
 *
 * Launches camera UI to capture document images (front/back),
 * then automatically processes them to extract OCR data.
 *
 * This is the simplest workflow - one method does everything.
 * No need to manually upload images or poll for results.
 *
 * @param options - Document capture options
 * @returns Promise with document images and extracted data
 * @throws {AcuantError} If capture or processing fails
 */
export async function captureAndProcessDocument(
  options?: DocumentCaptureOptions
): Promise<DocumentResult> {
  return AcuantSdk.captureAndProcessDocument(options || {});
}

// ============================================================================
// Exports
// ============================================================================

export * from './types';

export default {
  initialize,
  captureFace,
  processPassiveLiveness,
  processFaceMatch,
  captureAndProcessDocument,
};
