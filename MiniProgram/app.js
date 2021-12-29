// app.js
App({
  onLaunch() {
    this.globalData = {
      userInfo: {
        sdkAppID: 0,
        userId: '',
        userSig: '',
      },
      TUIScene: 'TUIVoiceRoom',
    };
  },
});
