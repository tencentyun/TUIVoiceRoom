# Quick Run of TUIVoiceRoom Demo for Android
_[中文](README.md) | English_

This document describes how to quickly run the TUIVoiceRoom demo project to make a high-quality audio/video chat. For more information on the TUIVoiceRoom component connection process, see **[Integrating TUIVoiceRoom (Android)](https://cloud.tencent.com/document/product/647/45737)**.

## Directory Structure

```
TUIVoiceRoom
├─ App          // Main panel, which provides entries of various scenarios
├─ Debug        // Debugging code
└─ Source       // Video meeting business logic
```

## Environment Requirements
- Compatibility with Android 4.2 (SDK API Level 17) or above is required. Android 5.0 (SDK API Level 21) or above is recommended
- Android Studio 3.5 or above

## Demo Run Example

### Step 1. Create a TRTC application
1. Go to the [Application management](https://console.cloud.tencent.com/trtc/app) page in the TRTC console, click **Create Application**, enter an application name such as `TUIKitDemo`, and then click **Confirm**.
2. Click **Application Information** on the right of the application as shown below:
    <img src="https://qcloudimg.tencent-cloud.cn/raw/62f58d310dde3de2d765e9a460b8676a.png" width="900">
3. On the application information page, note down the `SDKAppID` and key as shown below:
    <img src="https://qcloudimg.tencent-cloud.cn/raw/bea06852e22a33c77cb41d287cac25db.png" width="900">

>! This feature uses two basic PaaS services of Tencent Cloud: [TRTC](https://cloud.tencent.com/document/product/647/16788) and [IM](https://cloud.tencent.com/document/product/269). When you activate TRTC, IM will be activated automatically. IM is a value-added service. See [Pricing](https://cloud.tencent.com/document/product/269/11673) for its billing details.


[](id:ui.step2)
### Step 2. Download the source code and configure the project
1. Clone or directly download the source code in the repository. **Feel free to star our project if you like it.**
2. Find and open the `Android/Debug/src/main/java/com/tencent/liteav/debug/GenerateTestUserSig.java` file.
3. Set parameters in `GenerateTestUserSig.java`:
	<img src="https://main.qcloudimg.com/raw/f9b23b8632058a75b78d1f6fdcdca7da.png" width="900">
	- SDKAPPID: A placeholder by default. Set it to the `SDKAppID` that you noted down in step 1.
	- SECRETKEY: A placeholder by default. Set it to the key information that you noted down in step 1.

### Step 3. Compile and run the application
You can open the source code directory `TUIVoiceRoom/Android` in Android Studio 3.5 or later, wait for the Android Studio project to be synced, connect to a real device, and click **Run** to try out the application.

### Step 4. Try out the demo

Note: You need to prepare at least two devices to try out TUIVoiceRoom. Here, users A and B represent two different devices:

**Device A (userId: 111)**

- Step 1: On the welcome page, enter the username (which must be unique), such as `111`.
- Step 2: Click **Create Room**.
- Step 3: Enter a room subject and click **Start**.
- Step 4: Enter the room.

| Step 1 | Step 2 | Step 3 | Step 4 |
|---------|---------|---------|---------|
| <img src="https://liteav.sdk.qcloud.com/doc/res/trtc/picture/zh-cn/user_a.png" width="250"> | <img src="https://liteav.sdk.qcloud.com/doc/res/trtc/picture/zh-cn/tuivoiceroom_create_room.png" width="250"> | <img src="https://qcloudimg.tencent-cloud.cn/raw/d974a54fa71b221ff342e9789d6e125a.png" width="250"> |<img src="https://qcloudimg.tencent-cloud.cn/raw/b2d8de0412d5378a8b269d277338902d.jpg" width="250"> |

**Device B (userId: 222)**

- Step 1: Enter the username (which must be unique), such as `222`.
- Step 2: Click **Enter Room** and enter the ID of the room created by use A (the room ID that you noted down in step 4 on device A) to enter the room.

| Step 1 | Step 2 |
|---------|---------|
| <img src="https://liteav.sdk.qcloud.com/doc/res/trtc/picture/zh-cn/user_b.png" width="320"/> | <img src="https://liteav.sdk.qcloud.com/doc/res/trtc/picture/zh-cn/tuivoiceroom_enter_room.png" width="320"/> |
## FAQs

- [FAQs About TUI Scenario-Specific Solution](https://cloud.tencent.com/developer/article/1952880)
- If you have any questions or feedback, feel free to [contact us](https://intl.cloud.tencent.com/contact-us).