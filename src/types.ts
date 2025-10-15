/**
 * Acuant SDK React Native Wrapper - Type Definitions
 * Phase 1: Face Recognition and Identity Verification
 */

// ============================================================================
// Initialization Types
// ============================================================================

export enum AcuantRegion {
  USA = 'USA',
  EU = 'EU',
  AUS = 'AUS',
  PREVIEW = 'PREVIEW',
}

export interface AcuantCredentials {
  username: string;
  password: string;
  subscription: string;
}

export interface AcuantEndpoints {
  frmEndpoint?: string;
  passiveLivenessEndpoint?: string;
  assureIdEndpoint?: string;
  acasEndpoint?: string;
  ozoneEndpoint?: string;
  medEndpoint?: string;
}

export interface AcuantInitializationOptions {
  credentials?: AcuantCredentials;
  token?: string;
  endpoints?: AcuantEndpoints;
  region?: AcuantRegion;
}

// ============================================================================
// Face Capture Types
// ============================================================================

export interface FaceCaptureOptions {
  totalCaptureTime?: number;
  showOval?: boolean;
}

export interface FaceCaptureResult {
  jpegData: string; // Base64 encoded
  imageUri?: string; // File URI (platform dependent)
}

// ============================================================================
// Passive Liveness Types
// ============================================================================

export enum LivenessAssessment {
  Error = 'Error',
  PoorQuality = 'PoorQuality',
  Live = 'Live',
  NotLive = 'NotLive',
}

export enum LivenessErrorCode {
  Unknown = 'Unknown',
  FaceTooClose = 'FaceTooClose',
  FaceNotFound = 'FaceNotFound',
  FaceTooSmall = 'FaceTooSmall',
  FaceAngleTooLarge = 'FaceAngleTooLarge',
  FailedToReadImage = 'FailedToReadImage',
  InvalidRequest = 'InvalidRequest',
  InvalidRequestSettings = 'InvalidRequestSettings',
  Unauthorized = 'Unauthorized',
  NotFound = 'NotFound',
}

export interface PassiveLivenessRequest {
  jpegData: string; // Base64 encoded
}

export interface PassiveLivenessResult {
  score: number;
  assessment: LivenessAssessment;
  transactionId?: string;
}

export interface PassiveLivenessError {
  errorCode: LivenessErrorCode;
  description: string;
}

// ============================================================================
// Face Match Types
// ============================================================================

export interface FaceMatchRequest {
  faceOneData: string; // Base64 encoded - from ID document
  faceTwoData: string; // Base64 encoded - from selfie
}

export interface FaceMatchResult {
  isMatch: boolean;
  score: number;
}

// ============================================================================
// Document Capture Types (for future Phase 2)
// ============================================================================

export enum DocumentSide {
  Front = 'Front',
  Back = 'Back',
}

export interface DocumentCaptureOptions {
  autoCapture?: boolean;
  showDetectionBox?: boolean;
}

export interface DocumentCaptureResult {
  imageData: string; // Base64 encoded
  barcodeString?: string;
  imageUri?: string;
}

// ============================================================================
// Error Types
// ============================================================================

export enum AcuantErrorCode {
  InvalidCredentials = -1,
  InvalidEndpoint = -3,
  InitializationNotFinished = -4,
  Network = -5,
  InvalidJson = -6,
  CouldNotCrop = -7,
  LowResolutionImage = -21,
  BlurryImage = -22,
  ImageWithGlare = -23,
  NotALiveFace = -25,
  UserCanceled = -28,
  InvalidParameter = -29,
  UnexpectedError = -9999,
}

export interface AcuantError {
  code: AcuantErrorCode;
  message: string;
}
