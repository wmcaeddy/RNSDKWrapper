require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name         = "react-native-acuant-sdk"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.homepage     = package["homepage"]
  s.license      = package["license"]
  s.authors      = package["author"]

  s.platforms    = { :ios => "11.0" }
  s.source       = { :git => "https://github.com/wmcaeddy/RNSDKWrapper.git", :tag => "#{s.version}" }

  s.source_files = "ios/**/*.{h,m,mm,swift}"

  s.dependency "React-Core"

  # Reference the Acuant iOS SDK as a local podspec
  # The ios-sdk submodule contains the official Acuant SDK

  # Phase 1: Face Recognition & Identity Verification
  s.dependency "AcuantiOSSDKV11/AcuantCommon"
  s.dependency "AcuantiOSSDKV11/AcuantFaceCapture"
  s.dependency "AcuantiOSSDKV11/AcuantPassiveLiveness"
  s.dependency "AcuantiOSSDKV11/AcuantFaceMatch"
  s.dependency "AcuantiOSSDKV11/AcuantImagePreparation"

  # Phase 2: Document Scanning and OCR
  s.dependency "AcuantiOSSDKV11/AcuantCamera/Document"
  s.dependency "AcuantiOSSDKV11/AcuantDocumentProcessing"

  # Point to the local Acuant SDK podspec in the submodule
  s.xcconfig = {
    'HEADER_SEARCH_PATHS' => '$(PODS_ROOT)/../ios-sdk'
  }
end
