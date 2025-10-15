//
//  AcuantSdk.m
//  react-native-acuant-sdk
//
//  React Native bridge implementation for Acuant SDK
//
//  Design Principles:
//  1. Thin bridge layer - no business logic here
//  2. Direct mapping to Acuant SDK methods
//  3. All methods return via Promise (resolve/reject)
//  4. Main implementation in Swift (AcuantSdkImpl.swift)
//

#import "AcuantSdk.h"

@interface RCT_EXTERN_MODULE(AcuantSdk, NSObject)

// Initialization
RCT_EXTERN_METHOD(initialize:(NSDictionary *)options
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

// Face Capture
RCT_EXTERN_METHOD(captureFace:(NSDictionary *)options
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

// Passive Liveness
RCT_EXTERN_METHOD(processPassiveLiveness:(NSDictionary *)request
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

// Face Match
RCT_EXTERN_METHOD(processFaceMatch:(NSDictionary *)request
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

// Document Capture and Processing (Phase 2)
RCT_EXTERN_METHOD(captureAndProcessDocument:(NSDictionary *)options
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

+ (BOOL)requiresMainQueueSetup
{
  return NO;
}

@end
