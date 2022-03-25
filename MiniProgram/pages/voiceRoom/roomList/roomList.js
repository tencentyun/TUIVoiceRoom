import VoiceRoom from '../utils/voiceRoom';
import { genTestUserSig } from '../../../debug/GenerateTestUserSig';
const pageOptions = {
  // 页面数据
  data: {
    voiceRoom: undefined,
    userID: '',
    roomID: '',
    isLogin: false,
  },
  // 页面载入时
  onLoad(e) {
    this.data.voiceRoom = new VoiceRoom();
  },
  login() {
    if (!this.data.userID) {
      wx.showToast({ title: '请输入用户ID', icon: 'error' });
      return;
    }
    wx.showLoading({ title: '登录中', mask: true });
    const Signature = genTestUserSig(this.data.userID);
    const { voiceRoom } = this.data;
    voiceRoom
      .init({
        SDKAppID: Signature.sdkAppID,
        userId: this.data.userID,
        userSig: Signature.userSig,
      })
      .then(() => {
        getApp().globalData.userInfo = {
          SDKAppID: Signature.sdkAppID,
          userId: this.data.userID,
          userSig: Signature.userSig,
        };
        this.setData({ isLogin: true });
        wx.hideLoading(); // 防止多次登录，提示不取消
      });
    voiceRoom.on(voiceRoom.EVENT_TYPE.onReady, () => {
      wx.hideLoading();
      this.setData({ isLogin: true });
    });
    getApp().aegisReportEvent('login', 'login-success')
    wx.$VoiceRoom = voiceRoom;
  },
  enterRoom() {
    if (!this.data.isLogin) {
      wx.showToast({ title: '请先登录', icon: 'error' });
      return;
    }
    if (!this.data.roomID) {
      wx.showToast({ title: '请输入房间号', icon: 'error' });
      return;
    }
    wx.showLoading({ title: '请等待', mask: true });
    const { voiceRoom } = this.data;
    voiceRoom
      .enterRoom(this.data.roomID)
      .then(() => {
        wx.hideLoading();
        wx.navigateTo({ url: `/pages/voiceRoom/roomDetail/roomDetail?groupID=${this.data.roomID}` });
      })
      .catch((err) => {
        wx.hideLoading();
      });
  },
  createRoom() {
    if (!this.data.isLogin) {
      wx.showToast({ title: '请先登录', icon: 'error' });
      return;
    }
    if (!this.data.roomID) {
      wx.showToast({ title: '请输入房间号', icon: 'error' });
      return;
    }
    wx.showLoading({ title: '请等待', mask: true });
    const { voiceRoom } = this.data;

    // 随机生成房间背景图片
    const randomId = parseInt(Math.random() * 10, 10) + 1;
    const cover = `https://liteav-test-1252463788.cos.ap-guangzhou.myqcloud.com/voice_room/voice_room_cover${randomId}.png`;
    voiceRoom
      .createRoom(this.data.roomID, {
        roomName: this.data.roomID,
        coverUrl: cover,
        seatCount: 9,
        needRequest: 1,
      })
      .then(() => {
        this.data.voiceRoom.enterSeat(0);
        wx.navigateTo({ url: `/pages/voiceRoom/roomDetail/roomDetail?groupID=${this.data.roomID}` });
        wx.hideLoading();
      })
      .catch((err) => {
        wx.hideLoading();
      });
  },

  bindUserID(e) {
    this.setData({ userID: e.detail.value, isLogin: false });
  },
  bindRoomID(e) {
    this.setData({ roomID: e.detail.value });
  },
};

Page(pageOptions);
