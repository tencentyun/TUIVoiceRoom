# Quick Run of TUIVoiceRoom Demo for iOS
_[中文](README.md) | English_

This document describes how to quickly run the TUIVoiceRoom demo project to try out high-quality audio interaction. For more information on the TUIVoiceRoom component connection process, see **[Integrating TUIVoiceRoom (iOS)](https://www.tencentcloud.com/document/product/647/37287)**.

## Directory Structure
    
```
TUIVoiceRoom
├─ Example                   // Project module, which provides the TUIVoiceRoom testing page
├─ Resources                 // Images and internationalization string resources required by the audio chat room feature
├─ Source                    // Core business logic code of audio chat room
├─ TXAppBasic                // Dependent basic components of the project
└─ TUIVoiceRoom.podspec      // CocoaPods podspec file of the TUIVoiceRoom component
```
    
## Environment Requirements

- Xcode 11.0 or above
- Operating system: iOS 13.0 or later
- A valid developer signature for your project
    
## Demo Run Example

### Step 1. Create a TRTC application
1. Go to the [Application management](https://console.cloud.tencent.com/trtc/app) page in the TRTC console, select **Create Application**, enter an application name such as `TUIKitDemo`, and click **Confirm**.
2. Click **Application Information** on the right of the application as shown below:
    <img src="https://qcloudimg.tencent-cloud.cn/raw/62f58d310dde3de2d765e9a460b8676a.png" width="900">
3. On the application information page, note down the `SDKAppID` and key as shown below:
    <img src="https://qcloudimg.tencent-cloud.cn/raw/bea06852e22a33c77cb41d287cac25db.png" width="900">
>! This feature uses two basic PaaS services of Tencent Cloud: [TRTC](https://www.tencentcloud.com/document/product/647/35078) and [IM](https://www.tencentcloud.com/document/product/1047/33513). When you activate TRTC, IM will be activated automatically. IM is a value-added service.

### Step 2. Download the source code and configure the project

1. Clone or directly download the source code in the repository. **Feel free to star our project if you like it.**
2. The SDK is integrated by using `Cocoapods` by default. `pod 'TXLiteAVSDK_TRTC'` depended on by the SDK has been added to the `Example/Podfile` file in the project directory. You only need to open Terminal, enter the project directory, and run `pod install`, and the SDK will be automatically integrated.

```
pod install
```
>?If the error message `CocoaPods could not find compatible versions for pod "TXIMSDK_Plus_iOS"` is reported for version inconsistence, run `pod update TXIMSDK_Plus_iOS`.
3. Open the demo project `Example/TUIVoiceRoomApp.xcworkspace` with Xcode 11.0 or later and find the `Example/Debug/GenerateTestUserSig.swift` file in the project.
4. Set parameters in `GenerateTestUserSig.swift`:
<ul>
<li>SDKAPPID: 0 by default. Replace it with your actual `SDKAPPID`.</li>
<li>SECRETKEY: An empty string by default. Replace it with your actual `SECRETKEY`.</li>
</ul>
<img src="https://liteav.sdk.qcloud.com/doc/res/trtc/picture/zh-cn/sdkappid_secretkey_ios.png" width="650" height="295"/>


### Step 3. Compile and run the application

Open the demo project `Example/TUIVoiceRoomApp.xcworkspace` with Xcode 11.0 or later and click **Run**.


### Step 4. Try out the demo

Note: You need to prepare at least two devices to try out TUIVoiceRoom. Here, users A and B represent two different devices:

**Device A (userId: 111)**
- Step 1: On the welcome page, enter the username (which must be unique), such as `111`.
- Step 2: Click **Create Room**.
- Step 3: Enter a room subject and click **Start**.
- Step 4: After successful creation, you will enter the main UI of the audio chat room. Note down the room number at this time.


**Device B (userId: 222)**
- Step 1: Enter the username (which must be unique), such as `222`.
- Step 2: Click **Enter Room** and enter the ID of the room created by user A (the room ID noted down in step 4 on device A).


## Have any questions?
Welcome to join our Telegram Group to communicate with our professional engineers! We are more than happy to hear from you~
Click to join: https://t.me/+EPk6TMZEZMM5OGY1
Or scan the QR code

<img src="https://qcloudimg.tencent-cloud.cn/raw/9c67ed5746575e256b81ce5a60216c5a.jpg" width="320"/>
