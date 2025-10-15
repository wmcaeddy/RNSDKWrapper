# React Native Acuant SDK Wrapper - Phase 1 Initialization Report

**Date:** 2025-10-15
**Status:** Structure Complete, Ready for Implementation
**Phase:** 1 - Face Recognition & Identity Verification

---

## Executive Summary

项目结构已成功初始化。基于 Linus Torvalds 的代码设计原则,我创建了一个简洁、实用、可扩展的 React Native 封装层,用于 Acuant SDK 的人脸识别和身份验证功能。

**关键成果:**
- ✅ TypeScript API 设计完成
- ✅ iOS 原生模块结构就绪
- ✅ Android 原生模块结构就绪
- ✅ 构建配置完成
- ✅ 子模块隔离(只读)

---

## 1. Current Project State

### 1.1 Repository Structure
```
/home/eddy/github/RNSDKWrapper/
├── android-sdk/              # Git submodule (11.6.3) - READ ONLY
├── ios-sdk/                  # Git submodule (11.6.5) - READ ONLY
├── src/                      # React Native TypeScript layer
│   ├── index.ts             # Public API
│   └── types.ts             # Type definitions
├── ios/                      # iOS native module (Swift + Obj-C)
│   ├── AcuantSdk.h
│   ├── AcuantSdk.m
│   └── AcuantSdkImpl.swift
├── android/                  # Android native module (Kotlin)
│   ├── build.gradle
│   ├── AndroidManifest.xml
│   └── src/main/java/com/acuantsdk/
│       ├── AcuantSdkPackage.kt
│       └── AcuantSdkModule.kt
├── docs/                     # Documentation
├── examples/                 # Example apps (future)
├── package.json
├── tsconfig.json
├── tsconfig.build.json
└── react-native-acuant-sdk.podspec
```

### 1.2 Git Submodules Status
```
Submodule                    Version    Status
android-sdk                  11.6.3     Initialized, read-only
ios-sdk                      11.6.5     Initialized, read-only
```

**子模块策略:**
- 原生 SDK 保持只读,通过 git submodule 管理
- 升级时只需 `git submodule update --remote`
- 不修改原生 SDK 代码,保证未来可升级

---

## 2. Key Findings from Acuant SDK Documentation

### 2.1 Android SDK (v11.6.3)

**核心模块 (Phase 1 需要):**
- `AcuantCommon`: 共享模型和基础类
- `AcuantFaceCapture`: 人脸捕获 UI (基于 CameraX)
- `AcuantPassiveLiveness`: 被动活体检测
- `AcuantFaceMatch`: 人脸匹配
- `AcuantImagePreparation`: 图像处理(裁剪、清晰度、反光检测)

**初始化要求:**
```kotlin
// 凭证初始化
AcuantInitializer.initialize(
    "path/to/config.xml",
    context,
    listOf(), // Phase 1 不需要 MRZ 等特殊模块
    listener
)

// 或使用 Token
AcuantInitializer.initializeWithToken(
    "path/to/config.xml",
    token,
    context,
    listOf(),
    listener
)
```

**人脸捕获流程:**
```kotlin
val intent = Intent(context, AcuantFaceCameraActivity::class.java)
intent.putExtra(ACUANT_EXTRA_FACE_CAPTURE_OPTIONS, FaceCaptureOptions())
startActivityForResult(intent, REQUEST_CODE)
```

**被动活体检测:**
```kotlin
AcuantPassiveLiveness.processFaceLiveness(
    PassiveLivenessData(bitmap),
    listener
)
```

### 2.2 iOS SDK (v11.6.5)

**核心模块 (Phase 1 需要):**
- `AcuantCommon`: 共享模型
- `AcuantFaceCapture`: 人脸捕获
- `AcuantPassiveLiveness`: 被动活体检测
- `AcuantFaceMatch`: 人脸匹配
- `AcuantImagePreparation`: 图像处理

**初始化要求:**
```swift
let packages = [ImagePreparationPackage()]
let initializer: IAcuantInitializer = AcuantInitializer()

initializer.initialize(packages: packages) { error in
    if let err = error {
        // Handle error
    } else {
        // Success
    }
}
```

**人脸捕获流程:**
```swift
let options = FaceCaptureOptions(
    totalCaptureTime: 2,
    showOval: false
)
let controller = FaceCaptureController()
controller.options = options
controller.callback = { result in
    // Handle result
}
navigationController.pushViewController(controller, animated: true)
```

**被动活体检测:**
```swift
PassiveLiveness.postLiveness(
    request: AcuantLivenessRequest(jpegData: data)
) { result, error in
    // Handle result
}
```

### 2.3 关键发现

1. **平台差异最小化:**
   - 两个平台的 API 结构几乎相同
   - 数据流一致: 初始化 → 捕获 → 检测 → 匹配
   - 错误码可以统一映射

2. **初始化模式:**
   - 支持凭证或 Token 两种方式
   - 支持区域端点(USA/EU/AUS/PREVIEW)
   - 可以不提供 Subscription ID(功能受限)

3. **图像格式:**
   - 都使用 JPEG 格式
   - Android: Bitmap
   - iOS: UIImage
   - 需要 Base64 编码才能通过 RN Bridge

4. **活体检测建议:**
   - 使用 `LivenessAssessment` 而非 `score` 做决策
   - 图像最小高度: 480px (推荐 720p 或 1080p)
   - 压缩质量: JPEG 70+ (最好不压缩)

---

## 3. Library Structure Created

### 3.1 JavaScript/TypeScript Layer

**文件: `/home/eddy/github/RNSDKWrapper/src/index.ts`**

核心 API (4 个方法):
```typescript
async function initialize(options: AcuantInitializationOptions): Promise<void>
async function captureFace(options?: FaceCaptureOptions): Promise<FaceCaptureResult>
async function processPassiveLiveness(request: PassiveLivenessRequest): Promise<PassiveLivenessResult>
async function processFaceMatch(request: FaceMatchRequest): Promise<FaceMatchResult>
```

**设计原则:**
- 所有异步操作返回 Promise
- 错误通过 Promise rejection 传递
- 无平台特定 API
- 无状态管理

**文件: `/home/eddy/github/RNSDKWrapper/src/types.ts`**

类型定义:
- 初始化配置类型
- 人脸捕获选项和结果
- 活体检测请求和结果
- 人脸匹配请求和结果
- 统一错误类型

### 3.2 iOS Native Layer

**文件结构:**
```
ios/
├── AcuantSdk.h              # Objective-C bridge header
├── AcuantSdk.m              # RCT_EXTERN_MODULE declarations
└── AcuantSdkImpl.swift      # Swift implementation
```

**桥接策略:**
- Objective-C 作为 React Native bridge
- Swift 实现业务逻辑
- 所有方法通过 Promise (resolve/reject) 返回

**依赖管理 (CocoaPods):**
```ruby
# react-native-acuant-sdk.podspec
s.dependency "AcuantiOSSDKV11/AcuantCommon"
s.dependency "AcuantiOSSDKV11/AcuantFaceCapture"
s.dependency "AcuantiOSSDKV11/AcuantPassiveLiveness"
s.dependency "AcuantiOSSDKV11/AcuantFaceMatch"
s.dependency "AcuantiOSSDKV11/AcuantImagePreparation"
```

### 3.3 Android Native Layer

**文件结构:**
```
android/
├── build.gradle
├── AndroidManifest.xml
└── src/main/java/com/acuantsdk/
    ├── AcuantSdkPackage.kt
    └── AcuantSdkModule.kt
```

**模块注册:**
```kotlin
class AcuantSdkPackage : ReactPackage {
    override fun createNativeModules(): List<NativeModule> {
        return listOf(AcuantSdkModule(reactContext))
    }
}
```

**依赖管理 (Gradle):**
```gradle
implementation 'com.acuant:acuantcommon:11.6.3'
implementation 'com.acuant:acuantfacecapture:11.6.3'
implementation 'com.acuant:acuantpassiveliveness:11.6.3'
implementation 'com.acuant:acuantfacematch:11.6.3'
implementation 'com.acuant:acuantimagepreparation:11.6.3'
```

### 3.4 数据流设计

```
┌─────────────────────────────────────────────────────────────┐
│                    JavaScript Layer                         │
│  (src/index.ts - Public API)                               │
│                                                             │
│  initialize(), captureFace(), processPassiveLiveness()...  │
└──────────────────────┬──────────────────────────────────────┘
                       │ Promise-based calls
                       ↓
┌─────────────────────────────────────────────────────────────┐
│              React Native Bridge                            │
│  (NativeModules.AcuantSdk)                                 │
└──────────────┬────────────────────────┬─────────────────────┘
               │                        │
               ↓                        ↓
    ┌──────────────────┐    ┌──────────────────┐
    │   iOS Native     │    │  Android Native  │
    │  (Swift/Obj-C)   │    │    (Kotlin)      │
    └────────┬─────────┘    └────────┬─────────┘
             │                       │
             ↓                       ↓
    ┌──────────────────┐    ┌──────────────────┐
    │  Acuant iOS SDK  │    │ Acuant Android   │
    │   (Submodule)    │    │   SDK (Submodule)│
    │   READ ONLY      │    │   READ ONLY      │
    └──────────────────┘    └──────────────────┘
```

**关键点:**
1. 单向数据流,无循环依赖
2. 子模块完全隔离,不修改
3. 原生层薄封装,无业务逻辑
4. JS 层统一接口,隐藏平台差异

---

## 4. Phase 1 TypeScript API Interfaces

完整 API 定义见: `/home/eddy/github/RNSDKWrapper/docs/PHASE1_API_DESIGN.md`

### 4.1 核心接口

```typescript
// 初始化
interface AcuantInitializationOptions {
  credentials?: {
    username: string;
    password: string;
    subscription: string;
  };
  token?: string;
  endpoints?: AcuantEndpoints;
  region?: 'USA' | 'EU' | 'AUS' | 'PREVIEW';
}

// 人脸捕获
interface FaceCaptureOptions {
  totalCaptureTime?: number;
  showOval?: boolean;
}

interface FaceCaptureResult {
  jpegData: string;  // Base64
  imageUri?: string;
}

// 被动活体检测
interface PassiveLivenessRequest {
  jpegData: string;
}

interface PassiveLivenessResult {
  score: number;
  assessment: 'Live' | 'NotLive' | 'PoorQuality' | 'Error';
  transactionId?: string;
}

// 人脸匹配
interface FaceMatchRequest {
  faceOneData: string;
  faceTwoData: string;
}

interface FaceMatchResult {
  isMatch: boolean;
  score: number;
}
```

### 4.2 典型使用流程

```typescript
import AcuantSdk from 'react-native-acuant-sdk';

// 1. 初始化
await AcuantSdk.initialize({
  credentials: {
    username: 'xxx',
    password: 'xxx',
    subscription: 'xxx'
  },
  region: 'USA'
});

// 2. 捕获人脸
const faceResult = await AcuantSdk.captureFace();

// 3. 活体检测
const livenessResult = await AcuantSdk.processPassiveLiveness({
  jpegData: faceResult.jpegData
});

if (livenessResult.assessment === 'Live') {
  // 4. 人脸匹配
  const matchResult = await AcuantSdk.processFaceMatch({
    faceOneData: idPhotoBase64,
    faceTwoData: faceResult.jpegData
  });

  console.log('Match:', matchResult.isMatch, matchResult.score);
}
```

---

## 5. Build Configuration Status

### 5.1 iOS Configuration

**文件: `/home/eddy/github/RNSDKWrapper/react-native-acuant-sdk.podspec`**

状态: ✅ 完成

关键配置:
- 支持 iOS 11.0+
- 依赖 Acuant iOS SDK (通过 CocoaPods)
- 源文件: `ios/**/*.{h,m,mm,swift}`
- Header 搜索路径指向 ios-sdk 子模块

**下一步 (用户集成时):**
1. 在宿主应用的 Podfile 中添加:
   ```ruby
   pod 'AcuantiOSSDKV11', :path => '../node_modules/react-native-acuant-sdk/ios-sdk'
   ```
2. 运行 `pod install`
3. 添加 AcuantConfig.plist 配置文件

### 5.2 Android Configuration

**文件: `/home/eddy/github/RNSDKWrapper/android/build.gradle`**

状态: ✅ 完成

关键配置:
- minSdkVersion: 21
- compileSdkVersion: 33
- 依赖 Acuant Android SDK (通过 Maven)
- Kotlin 支持
- AndroidX 兼容

**Maven 仓库:**
```gradle
maven { url 'https://raw.githubusercontent.com/Acuant/AndroidSdkMaven/main/maven/' }
maven { url 'https://jitpack.io' }
```

**下一步 (用户集成时):**
1. 在宿主应用的 settings.gradle 中添加:
   ```gradle
   include ':react-native-acuant-sdk'
   project(':react-native-acuant-sdk').projectDir =
     new File(rootProject.projectDir, '../node_modules/react-native-acuant-sdk/android')
   ```
2. 在 AndroidManifest.xml 添加权限(已在库中定义)
3. 添加 Acuant 配置 XML 文件到 assets 目录

### 5.3 TypeScript Configuration

**文件:**
- `tsconfig.json`: 开发配置
- `tsconfig.build.json`: 构建配置

状态: ✅ 完成

编译目标:
- CommonJS (lib/commonjs)
- ES Modules (lib/module)
- TypeScript 类型定义 (lib/typescript)

---

## 6. Risks and Blockers Discovered

### 6.1 已识别风险

#### Risk 1: Acuant SDK 版本差异
**严重程度:** 中等

**问题:**
- Android SDK: v11.6.3
- iOS SDK: v11.6.5

**影响:**
- API 可能有细微差异
- 功能可能不完全对齐

**缓解措施:**
- 子模块锁定版本
- 设计统一 API 屏蔽差异
- 实现阶段仔细测试两端一致性

#### Risk 2: Base64 性能问题
**严重程度:** 低-中等

**问题:**
- 高分辨率图像(1080p)通过 Base64 编码会很大
- RN Bridge 传递大数据可能有性能问题

**缓解措施:**
- Phase 1 使用 Base64(简单)
- 提供 imageUri 作为替代方案
- 未来优化: 使用文件 URI 传递

#### Risk 3: 活体检测参数复杂性
**严重程度:** 低

**问题:**
- Acuant 对图像质量有严格要求
- 用户可能不理解参数含义

**缓解措施:**
- 提供合理默认值
- 文档中明确说明要求
- 示例应用展示最佳实践

#### Risk 4: 初始化配置复杂
**严重程度:** 低

**问题:**
- 多个端点配置
- 区域选择
- 凭证 vs Token

**缓解措施:**
- 提供区域枚举简化端点配置
- 文档提供清晰示例
- 默认值使用 USA 生产环境

### 6.2 当前无阻碍

所有已知问题都有缓解方案,无阻碍项目继续进行。

---

## 7. Implementation Status

### 7.1 完成项

- ✅ 项目结构初始化
- ✅ TypeScript 类型定义
- ✅ JavaScript 公共 API
- ✅ iOS 原生模块骨架
- ✅ Android 原生模块骨架
- ✅ 构建配置(Gradle, CocoaPods)
- ✅ API 设计文档
- ✅ 子模块隔离策略

### 7.2 骨架代码说明

**重要:** 所有原生代码目前是 **骨架实现**

iOS (AcuantSdkImpl.swift) 和 Android (AcuantSdkModule.kt) 中的所有方法当前返回:
```
promise.reject("NOT_IMPLEMENTED", "Method not yet implemented")
```

**为什么是骨架?**
1. 验证结构设计是否正确
2. 确保 API 设计满足需求
3. 避免过早实现(可能需要调整)
4. 清晰标记 TODO 实现点

### 7.3 下一步实现计划

**Phase 1A: 核心功能实现**
1. 实现 SDK 初始化(iOS + Android)
2. 实现人脸捕获(iOS + Android)
3. 实现被动活体检测(iOS + Android)
4. 实现人脸匹配(iOS + Android)

**Phase 1B: 测试和示例**
5. 创建示例应用
6. 单元测试
7. 集成测试
8. 文档完善

**Phase 2: 证件处理(未来)**
- 证件捕获
- 证件分类
- 数据提取
- 条形码读取

---

## 8. Linus Torvalds 设计原则应用

### 8.1 Good Taste (好品味)

**消除特殊情况:**
```typescript
// ❌ 坏设计 - 平台特殊情况
if (Platform.OS === 'ios') {
  await initializeIOS(config);
} else {
  await initializeAndroid(config);
}

// ✅ 好设计 - 无特殊情况
await initialize(config);  // 两个平台相同 API
```

**简单数据流:**
```
JS → Bridge → Native → SDK
     ↓
  Promise
```
没有回调地狱,没有状态管理,没有循环依赖。

### 8.2 Never Break Userspace (永不破坏用户空间)

**向后兼容设计:**
- Phase 1 API 在 Phase 2 不会改变
- 新功能通过添加方法实现,不修改现有方法
- 使用语义化版本控制
- 废弃功能先警告,再在主版本升级时移除

**示例:**
```typescript
// Phase 1
export { initialize, captureFace, processPassiveLiveness, processFaceMatch }

// Phase 2 (添加,不破坏)
export {
  initialize, captureFace, processPassiveLiveness, processFaceMatch,
  captureDocument, processDocument  // 新增
}
```

### 8.3 Pragmatism (实用主义)

**解决真实问题:**
- ✅ 人脸识别 - 真实需求
- ✅ 活体检测 - 真实需求
- ✅ 身份验证 - 真实需求
- ❌ 复杂状态管理 - 想象问题(不做)
- ❌ 过度抽象 - 想象问题(不做)

**简单实现:**
- 直接映射 Acuant SDK API
- 不创建中间层
- 不做"理论上完美"的架构

### 8.4 Simplicity (简洁性)

**代码简洁:**
- 4 个核心方法
- 每个方法做一件事
- 无嵌套超过 3 层
- 变量命名清晰

**API 简洁:**
```typescript
// 简单,清晰,直接
const face = await captureFace();
const liveness = await processPassiveLiveness({ jpegData: face.jpegData });
```

---

## 9. Next Steps

### 9.1 立即行动项

1. **审查设计:**
   - 检查 API 设计是否满足业务需求
   - 确认类型定义是否完整
   - 验证错误处理策略

2. **开始实现 (如果设计批准):**
   - iOS: 实现 AcuantSdkImpl.swift 中的 TODO 项
   - Android: 实现 AcuantSdkModule.kt 中的 TODO 项
   - 遵循 Acuant SDK 官方文档

3. **测试准备:**
   - 准备测试凭证
   - 创建示例应用骨架

### 9.2 实现建议

**iOS 实现顺序:**
1. `initialize()` - 最基础
2. `captureFace()` - UI 交互
3. `processPassiveLiveness()` - 网络调用
4. `processFaceMatch()` - 网络调用

**Android 实现顺序:**
同上

**测试策略:**
- 每完成一个方法立即测试
- iOS 和 Android 并行开发,保持同步
- 使用真实设备测试相机功能

### 9.3 文档计划

需要补充的文档:
- [ ] 安装指南(用户视角)
- [ ] API 参考(详细示例)
- [ ] 故障排除指南
- [ ] 最佳实践
- [ ] 示例应用说明

---

## 10. Conclusion

### 10.1 总结

**当前状态:**
React Native Acuant SDK Wrapper 的 Phase 1 结构已完成初始化。设计遵循 Linus Torvalds 的核心原则:简洁、实用、无特殊情况、向后兼容。

**架构特点:**
- 薄桥接层,无业务逻辑
- 统一 API,隐藏平台差异
- 子模块隔离,保证可升级性
- Promise-based,易于使用

**下一步:**
完成骨架代码的实际实现,创建示例应用,编写测试。

### 10.2 可交付成果

本次初始化完成的可交付成果:

1. ✅ **项目结构** (`/home/eddy/github/RNSDKWrapper/`)
2. ✅ **TypeScript API 定义** (`src/index.ts`, `src/types.ts`)
3. ✅ **iOS 原生模块骨架** (`ios/`)
4. ✅ **Android 原生模块骨架** (`android/`)
5. ✅ **构建配置** (package.json, Gradle, Podspec)
6. ✅ **API 设计文档** (`docs/PHASE1_API_DESIGN.md`)
7. ✅ **初始化报告** (本文档)

### 10.3 质量保证

**设计质量:**
- 通过 Linus 三问验证
- 五层分析法评估
- 无过度工程
- 清晰的数据流

**代码质量(骨架):**
- TypeScript 严格模式
- 清晰的命名
- TODO 标记完整
- 注释说明设计意图

---

**报告完成时间:** 2025-10-15
**作者:** Claude (Linus Torvalds 模式)
**项目:** RNSDKWrapper Phase 1 Initialization
