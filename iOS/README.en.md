# Quick Run of TUIVoiceRoom Demo for iOS
_[中文](README.md) | English_

This document describes how to quickly run the TUIVoiceRoom demo project to try out high-quality audio interaction. For more information on the TUIVoiceRoom component connection process, see **[Integrating TUIVoiceRoom (iOS)](https://cloud.tencent.com/document/product/647/45753)**.

## Directory Structure
    
```
TUIVoiceRoom
├─ App              // Audio chat room homepage UI code and used images and internationalization string resources
├─ Debug            // Key business code required for project debugging and running
├─ Login            // Login UI and business logic code
├─ Resources        // Images and internationalization string resources required by the audio chat room feature
├─ Source           // Core business logic code of audio chat room
└─ TXAppBasic       // Dependent basic components of the project
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
>! This feature uses two basic PaaS services of Tencent Cloud: [TRTC](https://cloud.tencent.com/document/product/647/16788) and [IM](https://cloud.tencent.com/document/product/269). When you activate TRTC, IM will be activated automatically. IM is a value-added service. See [Pricing](https://cloud.tencent.com/document/product/269/11673) for its billing details.

### Step 2. Download the source code and configure the project

1. Clone or directly download the source code in the repository. **Feel free to star our project if you like it.**
2. The SDK is integrated by using `Cocoapods` by default. `pod 'TXLiteAVSDK_TRTC'` depended on by the SDK has been added to the `Podfile` file in the project directory. You only need to open Terminal, enter the project directory, and run `pod install`, and the SDK will be automatically integrated.

```
pod install
```
>?If the error message `CocoaPods could not find compatible versions for pod "TXIMSDK_Plus_iOS"` is reported for version inconsistence, run `pod update TXIMSDK_Plus_iOS`.
3. Open the demo project `TUIVoiceRoomApp.xcworkspace` with Xcode 11.0 or later and find the `TUIVoiceRoom/Debug/GenerateTestUserSig.swift` file in the project.
4. Set parameters in `GenerateTestUserSig.swift`:
<ul>
<li>SDKAPPID: 0 by default. Replace it with your actual `SDKAPPID`.</li>
<li>SECRETKEY: An empty string by default. Replace it with your actual `SECRETKEY`.</li>
</ul>
<img src="https://liteav.sdk.qcloud.com/doc/res/trtc/picture/zh-cn/sdkappid_secretkey_ios.png" width="650" height="295"/>


### Step 3. Compile and run the application

Open the demo project `TUIVoiceRoom/TUIVoiceRoomApp.xcworkspace` with Xcode 11.0 or later and click **Run**.


### Step 4. Try out the demo

Note: You need to prepare at least two devices to try out TUIVoiceRoom. Here, users A and B represent two different devices:

**Device A (userId: 111)**
- Step 1: On the welcome page, enter the username (which must be unique), such as `111`.
- Step 2: Click **Create Room**.
- Step 3: Enter a room subject and click **Start**.
- Step 4: After successful creation, you will enter the main UI of the audio chat room. Note down the room number at this time.


| Step 1 | Step 2 | Step 3 | Step 4 |
|---------|---------|---------|---------|
| <img src="https://qcloudimg.tencent-cloud.cn/raw/24a76a18049eda3bdb6414493d43e286.png" width="250"> | <img src="https://qcloudimg.tencent-cloud.cn/raw/1b9a92912201d65fdaceb5db12b544af.png" width="250"> | <img src="https://qcloudimg.tencent-cloud.cn/raw/027c36cb954aa58f53f139af302620c6.png" width="250"> |<img src="https://qcloudimg.tencent-cloud.cn/raw/b2d8de0412d5378a8b269d277338902d.jpg" width="250"> |

**Device B (userId: 222)**
- Step 1: Enter the username (which must be unique), such as `222`.
- Step 2: Click **Enter Room** and enter the ID of the room created by user A (the room ID noted down in step 4 on device A).

| Step 1 | Step 2 | 
|---------|---------|
| <img src="https://liteav.sdk.qcloud.com/doc/res/trtc/picture/zh-cn/user_b_ios.png" width="320"/> | <img src="https://liteav.sdk.qcloud.com/doc/res/trtc/picture/zh-cn/tuivoiceroom_roomid_ios.png" width="320"/> | 

- [FAQs About TUI Scenario-Specific Solution](https://cloud.tencent.com/developer/article/1952880)
- If you have any questions or feedback, feel free to [contact us](https://intl.cloud.tencent.com/contact-us).

