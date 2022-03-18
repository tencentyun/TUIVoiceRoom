// app.js
import Aegis from './static/aegis'
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
    this.aegisInit()
    wx.aegis.reportEvent({
      name: 'onLaunch',
      ext1: 'onLaunch-success',
      ext2: 'wxTUIVoiceRoomExternal',
      ext3: genTestUserSig('').sdkAppID,
    })
  },
  aegisInit() {
    wx.aegis = new Aegis({
      id: 'iHWefAYqxqlqtLQVcA', // 项目key
      reportApiSpeed: true, // 接口测速
      reportAssetSpeed: true, // 静态资源测速
      pagePerformance: true, // 开启页面测速
    });
  },
});
