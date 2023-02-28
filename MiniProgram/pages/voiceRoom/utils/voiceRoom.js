import TIM from "../lib/tim-wx-sdk";
import TSignaling from "../lib/tsignaling-wx";

import { EVENT_TYPE, SEAT_STATUS, IM_STATUS, SIGNAL } from "./const";

class VoiceRoom {
  events = {};
  timEvents = {};
  isBindTimEvent = false;
  EVENT_TYPE = EVENT_TYPE;
  SEAT_STATUS = SEAT_STATUS;
  IM_STATUS = IM_STATUS;
  SIGNAL = SIGNAL;
  SDKAppID;
  userId;
  userSig;
  tim;
  tsignaling;

  groupID;
  inviteMap = new Map();
  _groupAttributes;
  _seatIndex;
  _seatInfoList;

  _getSeatInfoList(groupAttributes) {
    const seatInfoList = {};
    for (const key in groupAttributes) {
      if (groupAttributes[key].user) {
        seatInfoList[groupAttributes[key].user] = groupAttributes[key];
      }
    }
    return seatInfoList;
  }

  _handleGroupAttributes(groupAttributes) {
    const mgroupAttributes = {};
    for (const key in groupAttributes) {
      try {
        mgroupAttributes[key] = JSON.parse(groupAttributes[key]);
      } catch (e) {
        mgroupAttributes[key] = groupAttributes[key];
      }
    }
    return mgroupAttributes;
  }

  _handleNewMessage(data) {
    return {
      businessID: SIGNAL.BUSINESS_ID,
      data: {
        cmd: data.cmd,
        room_id: Number(this.groupID),
        ...data.content,
      },
      platform: SIGNAL.PLATFORM,
      version: 1,
    };
  }

  /** 事件监听 */
  on(type, callBack) {
    if (!this.isBindTimEvent) this.bindTimEvent();
    if (!this.events[type]) this.events[type] = [];
    this.events[type].push(callBack);
  }

  emit(type, params = []) {
    const evts = this.events[type];
    if (Array.isArray(evts)) {
      evts.forEach((callback) => {
        if (typeof callback === "function") {
          if (Array.isArray(params)) callback.apply(this, params);
          else callback.call(this, params);
        }
      });
    }
  }

  bindTimEvent() {
    this.isBindTimEvent = true;
    this.handleTimEvent("on");
  }

  handleTimEvent(type) {
    this.tim[type](TIM.EVENT.SDK_READY, this.timEvents.onReady, this);
    this.tim[type](
      TIM.EVENT.MESSAGE_RECEIVED,
      this.timEvents.messageReceived,
      this
    );
    this.tim[type](
      TIM.EVENT.GROUP_ATTRIBUTES_UPDATED,
      this.timEvents.groupAttributeUpdated,
      this
    );
    this.tim[type](TIM.EVENT.ERROR, this.timEvents.onError, this);
    this.tim[type](TIM.EVENT.KICKED_OUT, this.timEvents.onError, this);
    this.tsignaling[type](
      TSignaling.EVENT.NEW_INVITATION_RECEIVED,
      this.timEvents.onNewInvitationReceived,
      this
    );
    this.tsignaling[type](
      TSignaling.EVENT.INVITEE_ACCEPTED,
      this.timEvents.onInviteeAccepted,
      this
    );
    this.tsignaling[type](
      TSignaling.EVENT.INVITEE_REJECTED,
      this.timEvents.onInviteeRejected,
      this
    );
    this.tsignaling[type](
      TSignaling.EVENT.INVITATION_CANCELLED,
      this.timEvents.onInvitationCancelled,
      this
    );
  }

  clearEvents() {
    this.isBindTimEvent = false;
    this.handleTimEvent("off");
    this.events = {};
  }

  timEventsInit() {
    this.timEvents = {};
    this.timEvents.messageReceived = function messageReceived(event) {
      event.data.forEach((message) => {
        const { payload } = message;
        if (message.type === TIM.TYPES.MSG_TEXT) {
          // 文本消息
          this.getUserInfoList([message.from]).then((userInfoList) => {
            this.emit(EVENT_TYPE.onRecvRoomTextMsg, [message, userInfoList[0]]);
          });
        }
        if (message.type === TIM.TYPES.MSG_GRP_TIP) {
          // 群提示消息
          if (payload.operationType === TIM.TYPES.GRP_TIP_MBR_JOIN) {
            // 有成员加群
            this.getUserInfoList([payload.operatorID]).then((userInfoList) => {
              this.emit(EVENT_TYPE.onAudienceEnter, [userInfoList[0]]);
              this.emit(EVENT_TYPE.onSeatListChange, this._groupAttributes);
            });
          }
          if (payload.operationType === TIM.TYPES.GRP_TIP_MBR_QUIT) {
            // 有群成员退群
            this.getUserInfoList([payload.operatorID]).then((userInfoList) => {
              this.emit(EVENT_TYPE.onAudienceExit, [userInfoList[0]]);
            });
          }
        }
        if (message.type === TIM.TYPES.MSG_GRP_SYS_NOTICE) {
          // 群系统通知消息
          if (payload.operationType === IM_STATUS.GROUP_DISMISSED) {
            // 群组被解散
            this.emit(EVENT_TYPE.onRoomDestroy, this.groupID);
          }
        }
      });
    }.bind(this);
    this.timEvents.groupAttributeUpdated = function groupAttributeUpdated(
      event
    ) {
      const { groupAttributes } = event.data;
      Object.keys(groupAttributes).forEach((key) => {
        const attribute = groupAttributes[key];
        const value = JSON.parse(attribute);
        if (!this._groupAttributes[key].user && value.user) {
          // 有成员上麦(主动上麦/房主抱人上麦)。
          this.getUserInfoList([value.user]).then((userInfoList) => {
            this.emit(EVENT_TYPE.onAnchorEnterSeat, [
              Number(key.slice(SEAT_STATUS.SEAT_LENGTH)),
              userInfoList[0],
            ]);
          });
        } else if (this._groupAttributes[key].user && !value.user) {
          // 有成员下麦(主动下麦/房主踢人下麦)。
          this.getUserInfoList([this._groupAttributes[key].user]).then(
            (userInfoList) => {
              this.emit(EVENT_TYPE.onAnchorLeaveSeat, [
                Number(key.slice(SEAT_STATUS.SEAT_LENGTH)),
                userInfoList[0],
              ]);
            }
          );
        } else if (value.mute !== this._groupAttributes[key].mute) {
          // 房主禁麦。
          this.emit(EVENT_TYPE.onSeatMute, [
            Number(key.slice(SEAT_STATUS.SEAT_LENGTH)),
            value.mute,
          ]);
        } else if (value.status !== this._groupAttributes[key].status) {
          // 房主封麦。
          this.emit(EVENT_TYPE.onSeatClose, [
            Number(key.slice(SEAT_STATUS.SEAT_LENGTH)),
            value.status === SEAT_STATUS.CLOSE,
          ]);
        }
        this._groupAttributes[key] = value;
      });
      this.tim
        .getGroupAttributes({
          groupID: this.groupID,
          keyList: [],
        })
        .then((imResponse) => {
          this._groupAttributes = this._handleGroupAttributes(
            imResponse.data.groupAttributes
          );
          this.emit(EVENT_TYPE.onSeatListChange, this._groupAttributes);
        });
    }.bind(this);
    this.timEvents.onError = function onError(event) {
      this.emit(EVENT_TYPE.onError, [event]);
    }.bind(this);
    this.timEvents.onReady = function onReady(event) {
      this.emit(EVENT_TYPE.onReady, [event]);
    }.bind(this);
    this.timEvents.onNewInvitationReceived = (event) => {
      const { data } = JSON.parse(event.data.data);
      this.emit(EVENT_TYPE.onReceiveNewInvitation, [
        event.data.inviteID,
        event.data.inviter,
        data.cmd,
        data,
      ]);
    };
    this.timEvents.onInviteeAccepted = (event) => {
      this.emit(EVENT_TYPE.onInviteeAccepted, [
        event.data.inviteID,
        event.data.invitee,
      ]);
    };
    this.timEvents.onInviteeRejected = (event) => {
      this.emit(EVENT_TYPE.onInviteeRejected, [
        event.data.inviteID,
        event.data.invitee,
      ]);
    };
    this.timEvents.onInvitationCancelled = (event) => {
      this.emit(EVENT_TYPE.onInvitationCancelled, [
        event.data.inviteID,
        event.data.inviter,
      ]);
    };
  }

  init(options) {
    this.events = {};
    this.SDKAppID = options.SDKAppID;
    this.userId = options.userId;
    this.userSig = options.userSig;
    this.tim = options.tim || TIM.create({ SDKAppID: options.SDKAppID });
    if (!wx.$TSignaling) {
      wx.$TSignaling = new TSignaling({
        SDKAppID: options.SDKAppID,
        tim: this.tim,
      });
    }
    this.tsignaling = wx.$TSignaling;
    this.timEventsInit();
    this.bindTimEvent();
    return this.tsignaling.login({
      userID: this.userId,
      userSig: this.userSig,
    });
  }

  logout() {
    return this.tim.logout();
  }

  destroy() {
    this.clearEvents();
    this.groupID = undefined;
    this._groupAttributes = undefined;
    this._seatIndex = undefined;
    this._seatInfoList = undefined;
  }

  /** 房间相关接口 */
  // 创建房间
  async createRoom(roomId, roomParam) {
    const groupAttributes = {};
    groupAttributes.roomInfo = JSON.stringify({
      cover: roomParam.coverUrl,
      ownerId: this.userId,
      roomName: roomParam.roomName,
      seatSize: roomParam.seatCount,
      needRequest: roomParam.needRequest,
    });
    for (let i = 0; i < roomParam.seatCount; i++) {
      groupAttributes[`seat${i}`] = JSON.stringify({
        mute: false,
        status: SEAT_STATUS.NO_USER,
        user: "",
      });
    }
    try {
      await this.tim.searchGroupByID(roomId);
    } catch (err) {
      // 查不到群组，群组不存在时再创建 因为有可能在此之前有调用后台接口创建群组 在此增加防御措施
      await this.tim.createGroup({
        type: TIM.TYPES.GRP_AVCHATROOM,
        name: roomParam.roomName,
        groupID: roomId,
      });
    }
    await this.tim.joinGroup({ groupID: roomId });
    await this.tim.updateGroupProfile({
      groupID: roomId,
      avatar: roomParam.coverUrl,
      name: roomParam.roomName, // 修改群名称
      introduction: roomParam.roomName,
    });
    await this.tim.initGroupAttributes({ groupID: roomId, groupAttributes });

    this.groupID = roomId;
    this._groupAttributes = this._handleGroupAttributes(groupAttributes);
    this.emit(EVENT_TYPE.onSeatListChange, this._groupAttributes);
  }

  // 销毁房间
  destroyRoom() {
    return this.tim.dismissGroup(this.groupID).then(() => {
      this.destroy();
    });
  }

  // 进入房间
  async enterRoom(roomId) {
    await this.tim.joinGroup({ groupID: roomId });
    const imResponse = await this.tim.getGroupAttributes({
      groupID: roomId,
      keyList: [],
    });
    this.groupID = roomId;
    this._groupAttributes = this._handleGroupAttributes(
      imResponse.data.groupAttributes
    );
  }

  // 退出房间-房主不能退出
  async exitRoom() {
    if (this._groupAttributes)
      if (this._groupAttributes.roomInfo.ownerId === this.userId) {
        throw new Error("房主不能主动退出");
      }
    await this.leaveSeat();
    await this.tim.quitGroup(this.groupID);
    await this.destroy();
  }

  // 批量获取房间信息
  async getRoomInfoList(roomIdList) {
    const ans = [];
    for (let i = 0; i < roomIdList.length; i++) {
      await this.tim.getGroupProfile({ groupID: roomIdList[i] }).then(
        (imResponse) => {
          ans.push(imResponse.data.group);
        },
        (err) => err
      );
    }
    return ans;
  }

  // 批量获取用户信息
  getUserInfoList(userIdList, count = 15, offset = 0) {
    if (userIdList.length !== 0) {
      return this.tim
        .getUserProfile({
          userIDList: userIdList,
        })
        .then((imResponse) => imResponse.data);
    }
    return new Promise((resolve, reject) => {
      // tim.getGroupMemberList 接口后台10s才会更新数据，因此在此增加防抖，时间限制为10s
      clearTimeout(this.getUserInfoList.timer);
      this.getUserInfoList.timer = setTimeout(() => {
        return this.tim
          .getGroupMemberList({ groupID: this.groupID, count, offset })
          .then((imResponse) => {
            resolve(imResponse.data.memberList);
          });
      }, 10000);
    });
  }

  // 获取房间在线人数
  getGroupOnlineMemberCount() {
    return this.tim
      .getGroupOnlineMemberCount(this.groupID)
      .then((imResponse) => imResponse.data.memberCount);
  }

  /** 麦位管理接口 */
  // 主动上麦（听众端和房主均可调用）
  async enterSeat(seatIndex) {
    const imResponse = await this.tim.getGroupAttributes({
      groupID: this.groupID,
      keyList: [],
    });
    this._groupAttributes = this._handleGroupAttributes(
      imResponse.data.groupAttributes
    );
    await this.tim.setGroupAttributes({
      groupID: this.groupID,
      groupAttributes: {
        [`seat${seatIndex}`]: JSON.stringify({
          mute: false,
          status: SEAT_STATUS.EXIST_USER,
          user: this.userId,
        }),
      },
    });
    this._seatIndex = seatIndex;
  }

  // 主动下麦
  async leaveSeat() {
    this._seatIndex = undefined; // 先清空
    for (const key in this._groupAttributes) {
      if (this._groupAttributes[key].user === this.userId) {
        this._seatIndex = Number(key.slice(SEAT_STATUS.SEAT_LENGTH));
        break;
      }
    }
    if (this._seatIndex === undefined) return;
    const imResponse = await this.tim.getGroupAttributes({
      groupID: this.groupID,
      keyList: [],
    });
    this._groupAttributes = this._handleGroupAttributes(
      imResponse.data.groupAttributes
    );
    await this.tim.setGroupAttributes({
      groupID: this.groupID,
      groupAttributes: {
        [`seat${this._seatIndex}`]: JSON.stringify({
          mute: false,
          status: SEAT_STATUS.NO_USER,
          user: "",
        }),
      },
    });
  }

  // 主动禁言
  async muteSeatSelf(isMute) {
    for (const key in this._groupAttributes) {
      if (this._groupAttributes[key].user === this.userId) {
        this._seatIndex = Number(key.slice(SEAT_STATUS.SEAT_LENGTH));
        break;
      }
    }
    const imResponse = await this.tim.getGroupAttributes({
      groupID: this.groupID,
      keyList: [],
    });
    this._groupAttributes = this._handleGroupAttributes(
      imResponse.data.groupAttributes
    );
    await this.tim.setGroupAttributes({
      groupID: this.groupID,
      groupAttributes: {
        [`seat${this._seatIndex}`]: JSON.stringify({
          mute: isMute,
          status: SEAT_STATUS.EXIST_USER,
          user: this.userId,
        }),
      },
    });
  }

  // 让某个用户上麦
  async pickSeat(seatIndex, userId) {
    const imResponse = await this.tim.getGroupAttributes({
      groupID: this.groupID,
      keyList: [],
    });
    this._groupAttributes = this._handleGroupAttributes(
      imResponse.data.groupAttributes
    );
    await this.tim.setGroupAttributes({
      groupID: this.groupID,
      groupAttributes: {
        [`seat${seatIndex}`]: JSON.stringify({
          mute: false,
          status: SEAT_STATUS.EXIST_USER,
          user: userId,
        }),
      },
    });
  }

  // 踢用户下麦
  async kickSeat(seatIndex) {
    const imResponse = await this.tim.getGroupAttributes({
      groupID: this.groupID,
      keyList: [],
    });
    this._groupAttributes = this._handleGroupAttributes(
      imResponse.data.groupAttributes
    );
    await this.tim.setGroupAttributes({
      groupID: this.groupID,
      groupAttributes: {
        [`seat${seatIndex}`]: JSON.stringify({
          mute: false,
          status: SEAT_STATUS.NO_USER,
          user: "",
        }),
      },
    });
  }

  // 对麦位禁言
  async muteSeat(seatIndex, isMute) {
    const imResponse = await this.tim.getGroupAttributes({
      groupID: this.groupID,
      keyList: [],
    });
    this._groupAttributes = this._handleGroupAttributes(
      imResponse.data.groupAttributes
    );
    await this.tim.setGroupAttributes({
      groupID: this.groupID,
      groupAttributes: {
        [`seat${seatIndex}`]: JSON.stringify({
          mute: isMute,
          status: this._groupAttributes[`seat${seatIndex}`].status,
          user: this._groupAttributes[`seat${seatIndex}`].user,
        }),
      },
    });
  }

  // 封禁麦位
  async closeSeat(seatIndex, isClose) {
    const imResponse = await this.tim.getGroupAttributes({
      groupID: this.groupID,
      keyList: [],
    });
    this._groupAttributes = this._handleGroupAttributes(
      imResponse.data.groupAttributes
    );
    await this.tim.setGroupAttributes({
      groupID: this.groupID,
      groupAttributes: {
        [`seat${seatIndex}`]: JSON.stringify({
          mute: false,
          status: isClose ? SEAT_STATUS.CLOSE : SEAT_STATUS.NO_USER,
          user: "",
        }),
      },
    });
  }

  /** 消息发送相关接口函数 */
  // 发送文字消息
  sendRoomTextMsg(text) {
    const message = this.tim.createTextMessage({
      to: this.groupID,
      conversationType: TIM.TYPES.CONV_GROUP,
      payload: { text },
    });
    return this.tim.sendMessage(message).then((data) => data.data.message);
  }

  /** 邀请信令相关接口 */
  // 发送邀请信令
  sendInvitation(options) {
    return this.tsignaling
      .invite({
        userID: options.userId,
        data: JSON.stringify(this._handleNewMessage(options)),
      })
      .then((res) => {
        this.inviteMap.set(res.inviteID, options);
        return res;
      });
  }

  // 同意邀请信令
  acceptInvitation(id, options = {}) {
    return this.tsignaling
      .accept({
        inviteID: id,
        data: JSON.stringify(this._handleNewMessage(options)),
      })
      .then((res) => {
        this.inviteMap.delete(id);
        return res;
      });
  }

  // 拒绝邀请信令
  rejectInvitation(id) {
    return this.tsignaling.reject({ inviteID: id });
  }

  // 取消邀请信令
  cancelInvitation(id) {
    return this.tsignaling.cancel({ inviteID: id });
  }
}

export default VoiceRoom;
