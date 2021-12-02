import TRTC from '../lib/trtc-wx';
const VOICE_ROOM_URL = `/pages/voiceRoom/roomList/roomList`;

const app = getApp();
Page({
  data: {
    voiceRoom: null,
    groupAttributes: {}, // 群属性信息
    userInfoList: [],
    seatInfoMap: {},
    usreInfoListObject: {},
    messageView: [],
    seatIndex: null,
    userId: null,
    token: null,
    groupID: null, // onload是进行赋值操作
    message: null,
    maskVisible: false,
    pusher: {},
    enableMic: false,
    isPushing: {},
    playerList: [],
    audioPlayerListObject: {},
  },
  onLoad(options) {
    this.TRTC = new TRTC(this);
    this.EVENT = this.TRTC.EVENT;
    const pusher = this.TRTC.createPusher({
      beautyLevel: 9,
      audioVolumeType: 'media',
    });
    const { EVENT_TYPE, SEAT_STATUS, SIGNAL } = wx.$VoiceRoom;
    this.EVENT_TYPE = EVENT_TYPE;
    this.SEAT_STATUS = SEAT_STATUS;
    this.SIGNAL = SIGNAL;
    // 初始化数据
    this.setData({
      groupID: options.groupID,
      userId: app.globalData.userInfo.userId,
      pusher: pusher.pusherAttributes,
      voiceRoom: wx.$VoiceRoom,
      groupAttributes: wx.$VoiceRoom._groupAttributes,
    });
    this.setUserInfoList();
    this.setData({
      seatInfoMap: this.getSeatInfoMap(this.data.groupAttributes),
    });
    if (this.data.seatInfoMap[this.data.userId]) {
      this.setPusherAttributesHandler({
        enableMic: !this.data.seatInfoMap[this.data.userId].mute,
      });
    }
    this.data.voiceRoom.on(this.EVENT_TYPE.onRoomDestroy, (roomId) => {
      wx.redirectTo({
        url: VOICE_ROOM_URL,
      });
    });
    this.data.voiceRoom.on(this.EVENT_TYPE.onSeatMute, (index, isMute) => {
      const content = isMute ? `${index}号麦被禁言` : `${index}号麦解除禁言`;
      this.data.messageView.push({
        type: 'system',
        content,
      });
      if (isMute) {
        // 接触禁言不做操作，保留麦克风封禁状态
        if (this.data.groupAttributes[`seat${index}`].user === this.data.userId) {
          this.setPusherAttributesHandler({ enableMic: !isMute });
        }
      }
      this.setData({ messageView: this.data.messageView });
    });
    this.data.voiceRoom.on(this.EVENT_TYPE.onSeatClose, (index, isClose) => {
      const content = isClose ? `房主封禁${index}号麦` : `房主解禁${index}号麦`;
      this.data.messageView.push({
        type: 'system',
        content,
      });
      this.setData({ messageView: this.data.messageView });
    });
    this.data.voiceRoom.on(this.EVENT_TYPE.onAudienceEnter, (userInfo) => {
      this.setUserInfoList();
      this.data.messageView.push({
        type: 'system',
        content: `用户${userInfo.userID}进入房间`,
      });
      this.setData({ messageView: this.data.messageView });
    });
    this.data.voiceRoom.on(this.EVENT_TYPE.onAudienceExit, (userInfo) => {
      this.setUserInfoList();
      this.data.messageView.push({
        type: 'system',
        userInfo: {
          userId: userInfo.usaerID,
          nick: userInfo.nick,
          avatar: userInfo.avatar,
        },
        content: `用户${userInfo.userID}退出房间`,
      });
      this.setData({ messageView: this.data.messageView });
    });
    this.data.voiceRoom.on(this.EVENT_TYPE.onSeatListChange, (groupAttributes) => {
      this.setData({
        seatInfoMap: this.getSeatInfoMap(groupAttributes),
        groupAttributes,
      });
    });
    this.data.voiceRoom.on(this.EVENT_TYPE.onAnchorEnterSeat, (index, userInfo) => {
      this.data.messageView.push({
        type: 'system',
        content: `${userInfo.userID}上${index}号麦`,
      });
      this.setData({ messageView: this.data.messageView });
      if (userInfo.userID === this.data.userId) {
        this.setPusherAttributesHandler({ enableMic: true });
      }
    });
    this.data.voiceRoom.on(this.EVENT_TYPE.onAnchorLeaveSeat, (index, userInfo) => {
      this.data.messageView.push({
        type: 'system',
        content: `${userInfo.userID}下${index}号麦`,
      });
      this.setData({ messageView: this.data.messageView });
      if (userInfo.userID === this.data.userId) {
        this.setPusherAttributesHandler({ enableMic: false });
      }
    });
    this.data.voiceRoom.on(this.EVENT_TYPE.onRecvRoomTextMsg, (message, userInfo) => {
      this.data.messageView.push({
        type: 'text',
        userInfo: {
          userId: message.from,
          nick: message.nick,
          avatar: message.avatar,
        },
        content: message.payload.text,
      });
      this.setData({ messageView: this.data.messageView });
    });
    this.data.voiceRoom.on(this.EVENT_TYPE.onReceiveNewInvitation, (id, inviter, cmd, content) => {
      if (cmd === this.SIGNAL.PICK_SEAT) {
        wx.showModal({
          title: `房主邀请你上${content.seat_number}号麦`,
          confirmText: '我确定',
          cancelText: '再等等',
          success: (result) => {
            if (result.confirm) {
              if (this.data.groupAttributes[`seat${content.seat_number}`].status === this.SEAT_STATUS.EXIST_USER) {
                wx.showToast({
                  title: '该麦位有人',
                  icon: 'none',
                  duration: 1000,
                });
                return;
              }
              if (this.data.seatInfoMap[this.data.userId]) {
                wx.showToast({
                  title: '我已经在麦上',
                  icon: 'none',
                  duration: 1000,
                });
                return;
              }
              this.data.voiceRoom
                .acceptInvitation(id, {
                  userId: inviter,
                  cmd,
                  content,
                })
                .then((res) => {
                  wx.showToast({
                    title: '同意上麦成功',
                    icon: 'none',
                    duration: 1000,
                  });
                });
            }
          },
        });
      }
      if (cmd === this.SIGNAL.TAKE_SEAT) {
        this.data.messageView.push({
          type: 'text',
          userInfo: {
            userId: inviter,
            nick: this.data.usreInfoListObject[inviter].nick,
            avatar: this.data.usreInfoListObject[inviter].avatar,
          },
          seatIndex: content.seat_number,
          isInvite: true,
          inviteID: id,
          content: `申请上${content.seat_number}号麦`,
        });
        this.setData({ messageView: this.data.messageView });
      }
    });
    this.data.voiceRoom.on(this.EVENT_TYPE.onInviteeAccepted, (id, invitee) => {
      if (this.data.seatInfoMap[this.inviteUser[invitee]]) {
        wx.showToast({
          title: `该麦位上有人`,
          icon: 'none',
          duration: 1000,
        });
        return;
      }
      if (this.getInviteMap().has(id)) {
        const curInvite = this.getInviteMap().get(id);
        if (curInvite.cmd === this.SIGNAL.TAKE_SEAT) {
          // 成员申请上麦被同意
          this.data.voiceRoom.enterSeat(curInvite.content.seat_number);
        }
        if (curInvite.cmd === this.SIGNAL.PICK_SEAT) {
          // 邀请成员上麦 成员同意
          this.data.voiceRoom.pickSeat(curInvite.content.seat_number, curInvite.userId);
        }
      }
    });
    this.bindTRTCRoomEvent();
    this.enterTrtcRoom({ roomID: options.groupID });
  },
  getInviteMap() {
    return this.data.voiceRoom.inviteMap;
  },
  getSeatInfoMap(groupAttributes) {
    const seatInfoMap = {};
    for (const key in groupAttributes) {
      if (Object.prototype.hasOwnProperty.call(groupAttributes, key)) {
        const cur = groupAttributes[key];
        if (cur.user) {
          seatInfoMap[cur.user] = cur;
        }
      }
    }
    return seatInfoMap;
  },
  setUserInfoList() {
    this.data.voiceRoom.getUserInfoList([]).then((userInfoList) => {
      const usreInfoListObject = {};
      userInfoList.forEach((item) => {
        usreInfoListObject[item.userID] = item;
      });
      this.setData({ userInfoList, usreInfoListObject });
    });
  },
  enterTrtcRoom(options) {
    const { roomID } = options;
    this.setData(
      {
        pusher: this.TRTC.enterRoom({
          sdkAppID: app.globalData.userInfo.SDKAppID,
          userID: app.globalData.userInfo.userId,
          userSig: app.globalData.userInfo.userSig,
          roomID,
        }),
      },
      () => {
        this.TRTC.getPusherInstance().start(); // 开始推流（autoPush的模式下不需要）
      },
    );
  },
  onUnload() {
    this.setPusherAttributesHandler({ enableMic: false });
    if (this.isOwner()) {
      this.data.voiceRoom.destroyRoom();
    } else {
      this.data.voiceRoom.exitRoom();
    }
  },
  seatLock(e) {
    this.data.voiceRoom.closeSeat(this.data.seatIndex, e.currentTarget.dataset.status);
    this.showOrHideGroupMemberList(false);
  },
  seatClick(e) {
    const seatIndex = e.currentTarget.dataset.seatindex;
    const seat = this.data.groupAttributes[`seat${seatIndex}`];
    this.setData({ seatIndex });
    // 为群主的时候才可以邀请别人上麦，非群主发出上麦申请
    if (this.isOwner()) {
      // 如果该麦位有人，则控制他禁言、下麦，如果没人为邀请逻辑
      if (!seat.user) {
        // 麦位没人
        this.showOrHideGroupMemberList(true);
      } else {
        // 麦位有人
        wx.showActionSheet({
          itemList: [seat.mute ? '解除禁言' : '禁言', '下麦'],
          success: (res) => {
            switch (res.tapIndex) {
              case 0:
                this.data.voiceRoom.muteSeat(seatIndex, !seat.mute).then(() => {
                  wx.showToast({
                    title: '操作成功',
                    icon: 'none',
                    duration: 1000,
                  });
                });
                break;
              case 1:
                this.data.voiceRoom.kickSeat(seatIndex).then(() => {
                  wx.showToast({
                    title: '踢人下麦成功',
                    icon: 'none',
                    duration: 1000,
                  });
                });
                break;
            }
          },
        });
      }
    } else {
      // 若麦位锁定，应不能点击
      if (seat.status === this.SEAT_STATUS.CLOSE) return;
      // 非管理员申请上麦
      if (!seat.user && !this.data.seatInfoMap[app.globalData.userInfo.userId]) {
        wx.showActionSheet({
          itemList: ['申请上麦'],
          success: (res) => {
            if (res.tapIndex === 0) {
              this.data.voiceRoom
                .sendInvitation({
                  userId: this.data.groupAttributes.roomInfo.ownerId,
                  cmd: this.SIGNAL.TAKE_SEAT,
                  content: {
                    seat_number: String(seatIndex),
                  },
                })
                .then((res) => {
                  wx.showToast({
                    title: '上麦申请发送成功',
                    icon: 'none',
                    duration: 1000,
                  });
                });
            }
          },
        });
      }
    }
  },
  leaveSeat() {
    this.data.voiceRoom.leaveSeat();
    this.setPusherAttributesHandler({ enableMic: false });
  },
  inviteUser(e) {
    const userInfo = e.currentTarget.dataset.userinfo;
    this.data.voiceRoom
      .sendInvitation({
        userId: userInfo.userID,
        cmd: this.SIGNAL.PICK_SEAT,
        content: {
          seat_number: String(this.data.seatIndex),
        },
      })
      .then(() => {
        wx.showToast({
          title: '邀请发送成功',
          icon: 'none',
          duration: 1000,
        });
      });
    this.inviteUser[userInfo.userID] = this.data.seatIndex;
    this.showOrHideGroupMemberList(false);
  },
  enableMicChange(e) {
    if (this.data.seatInfoMap[this.data.userId].mute) {
      wx.showToast({
        title: '您被主播禁言',
        icon: 'none',
        duration: 1000,
      });
      return;
    }
    const { flag } = e.currentTarget.dataset;
    this.setData({ seatInfoMap: this.data.seatInfoMap });
    this.setPusherAttributesHandler({ enableMic: flag });
  },
  agreeTakeSeat(e) {
    const { message } = e.currentTarget.dataset;
    const { index } = e.currentTarget.dataset;
    if (this.data.seatInfoMap[message.userInfo.userId]) {
      wx.showToast({
        title: `该用户已在麦上`,
        icon: 'none',
        duration: 1000,
      });
      return;
    }
    if (this.data.groupAttributes[`seat${message.seatIndex}`].user) {
      wx.showToast({
        title: `该麦位上有人`,
        icon: 'none',
        duration: 1000,
      });
      return;
    }
    this.data.voiceRoom.acceptInvitation(message.inviteID).then((res) => {
      message.done = true;
      this.data.messageView[index] = message;
      this.setData({ messageView: this.data.messageView });
      wx.showToast({
        title: `同意成功`,
        icon: 'none',
        duration: 1000,
      });
    });
  },
  showOrHideGroupMemberList(flag) {
    this.setData({ maskVisible: flag });
  },
  messageInput(event) {
    this.setData({ message: event.detail.value });
  },
  sendMessage() {
    if (this.data.message === null || this.data.message === '') return;
    this.data.voiceRoom.sendRoomTextMsg(this.data.message).then((message) => {
      this.data.messageView.push({
        type: 'text',
        userInfo: {
          userId: message.from,
          nick: message.nick,
          avatar: message.avatar,
        },
        content: message.payload.text,
      });
      this.setData({ messageView: this.data.messageView, message: null });
    });
  },
  isOwner() {
    if (!this.data.groupAttributes.roomInfo) return true;
    return this.data.userId === this.data.groupAttributes.roomInfo.ownerId;
  },
  // 关闭遮罩层
  maskClick() {
    this.setData({ maskVisible: false });
  },

  // 设置 pusher 属性
  setPusherAttributesHandler(options, isOwner = true) {
    if (isOwner) {
      this.data.isPushing[this.data.userId] = options.enableMic;
      this.setData({ isPushing: this.data.isPushing });

      if (options.enableMic === false) {
        // 苹果手机关掉麦克风本地音量回调不会触发，设置属性是异步的
        setTimeout(() => {
          delete this.data.audioPlayerListObject[this.data.userId];
          this.setData({
            audioPlayerListObject: this.data.audioPlayerListObject,
          });
        }, 500);
      }
    }
    this.setData({
      pusher: this.TRTC.setPusherAttributes(options),
      enableMic: options.enableMic,
    });
  },
  // 设置某个 player 属性
  setPlayerAttributesHandler(player, options) {
    this.setData({
      playerList: this.TRTC.setPlayerAttributes(player.streamID, options),
    });
  },
  // 事件监听
  bindTRTCRoomEvent() {
    const TRTC_EVENT = this.TRTC.EVENT;
    // 初始化事件订阅
    this.TRTC.on(TRTC_EVENT.LOCAL_JOIN, (event) => {
      console.log('* room LOCAL_JOIN', event);
      // 进房成功，触发该事件后可以对本地视频和音频进行设置
      if (this.data.groupAttributes.roomInfo === this.data.userId) {
        this.setPusherAttributesHandler({ enableMic: true });
      }
    });
    this.TRTC.on(TRTC_EVENT.LOCAL_LEAVE, (event) => {
      console.log('* room LOCAL_LEAVE', event);
    });
    this.TRTC.on(TRTC_EVENT.ERROR, (event) => {
      console.log('* room ERROR', event);
    });
    // 远端用户退出
    this.TRTC.on(TRTC_EVENT.REMOTE_USER_LEAVE, (event) => {
      console.log('* room REMOTE_USER_LEAVE', event);
    });
    // 远端用户推送音频
    this.TRTC.on(TRTC_EVENT.REMOTE_AUDIO_ADD, (event) => {
      console.log('* room REMOTE_AUDIO_ADD', event);
      const { player, userList } = event.data;
      userList.forEach((user) => {
        this.data.isPushing[user.userID] = user.hasMainAudio;
      });
      this.setPlayerAttributesHandler(player, { muteAudio: false });
      this.setData({ isPushing: this.data.isPushing });
    });
    // 远端用户取消推送音频
    this.TRTC.on(TRTC_EVENT.REMOTE_AUDIO_REMOVE, (event) => {
      console.log('* room REMOTE_AUDIO_REMOVE', event);
      const { player, userList } = event.data;
      userList.forEach((user) => {
        this.data.isPushing[user.userID] = user.hasMainAudio;
        delete this.data.audioPlayerListObject[user.userID];
      });
      this.setPlayerAttributesHandler(player, { muteAudio: true });
      this.setData({
        isPushing: this.data.isPushing,
        audioPlayerListObject: this.data.audioPlayerListObject,
      });
    });
    // 本地音量状态变更。
    this.TRTC.on(TRTC_EVENT.LOCAL_AUDIO_VOLUME_UPDATE, (event) => {
      const { pusher } = event.data;
      if (pusher.volume > 5) {
        this.setData({
          audioPlayerListObject: {
            ...this.data.audioPlayerListObject,
            [this.data.userId]: pusher,
          },
        });
      } else {
        delete this.data.audioPlayerListObject[this.data.userId];
        this.setData({
          audioPlayerListObject: this.data.audioPlayerListObject,
        });
      }
    });
    // 远端用户音量状态变更。
    this.TRTC.on(TRTC_EVENT.REMOTE_AUDIO_VOLUME_UPDATE, (event) => {
      // 这里会返回更新后的. playerList
      const { playerList } = event.data;
      console.info('REMOTE_AUDIO_VOLUME_UPDATE ***', event);
      playerList.forEach((item) => {
        if (item.volume > 5) {
          this.data.audioPlayerListObject[item.userID] = item;
        } else {
          delete this.data.audioPlayerListObject[item.userID];
        }
      });
      this.setData({ audioPlayerListObject: this.data.audioPlayerListObject });
    });
  },
  // 请保持跟 wxml 中绑定的事件名称一致
  _pusherStateChangeHandler(event) {
    this.TRTC.pusherEventHandler(event);
  },
  _pusherNetStatusHandler(event) {
    this.TRTC.pusherNetStatusHandler(event);
  },
  _pusherErrorHandler(event) {
    this.TRTC.pusherErrorHandler(event);
  },
  _pusherBGMStartHandler(event) {
    this.TRTC.pusherBGMStartHandler(event);
  },
  _pusherBGMProgressHandler(event) {
    this.TRTC.pusherBGMProgressHandler(event);
  },
  _pusherBGMCompleteHandler(event) {
    this.TRTC.pusherBGMCompleteHandler(event);
  },
  _pusherAudioVolumeNotify(event) {
    this.TRTC.pusherAudioVolumeNotify(event);
  },
  _playerStateChange(event) {
    this.TRTC.playerEventHandler(event);
  },
  _playerFullscreenChange(event) {
    this.TRTC.playerFullscreenChange(event);
  },
  _playerNetStatus(event) {
    this.TRTC.playerNetStatus(event);
  },
  _playerAudioVolumeNotify(event) {
    this.TRTC.playerAudioVolumeNotify(event);
  },
});
