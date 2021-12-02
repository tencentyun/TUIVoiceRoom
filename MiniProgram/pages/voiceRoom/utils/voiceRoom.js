import TIM from '../lib/tim-wx-sdk';
import TSignaling from '../lib/tsignaling-wx';

import { EVENT_TYPE, SEAT_STATUS, IM_STATUS, SIGNAL } from './const'

class VoiceRoom {
    #events = {}
    #timEvents = {}
    #isBindTimEvent = false
    EVENT_TYPE = EVENT_TYPE
    SEAT_STATUS = SEAT_STATUS
    IM_STATUS = IM_STATUS
    SIGNAL = SIGNAL
    SDKAppID
    userId
    userSig
    tim
    tsignaling

    groupID
    inviteMap = new Map()
    _groupAttributes
    _seatIndex
    _seatInfoList

    _getSeatInfoList(groupAttributes) {
        let seatInfoList = {}
        for (let key in groupAttributes) {
            if (groupAttributes[key].user) {
                seatInfoList[groupAttributes[key].user] = groupAttributes[key]
            }
        }
        return seatInfoList
    }
    _handleGroupAttributes(groupAttributes) {
        let mgroupAttributes = {}
        for (let key in groupAttributes) {
            try {
                mgroupAttributes[key] = JSON.parse(groupAttributes[key])
            } catch (e) {
                mgroupAttributes[key] = groupAttributes[key]
            }
        }
        return mgroupAttributes
    }
    _handleNewMessage(data) {
        return {
            businessID: SIGNAL.BUSINESS_ID,
            data: {
                cmd: data.cmd,
                room_id: Number(this.groupID),
                ...data.content
            },
            platform: SIGNAL.PLATFORM,
            version: 1
        }
    }
    /**事件监听 */
    on(type, callBack) {
        if (!this.#isBindTimEvent) this.#bindTimEvent()
        if (!this.#events[type]) this.#events[type] = []
        this.#events[type].push(callBack)
    }
    emit(type, params = []) {
        let evts = this.#events[type]
        if (Array.isArray(evts)) {
            evts.forEach(callback => {
                if (typeof callback === 'function') {
                    if (Array.isArray(params)) callback.apply(this, params)
                    else callback.call(this, params)
                }
            })
        }

    }
    #bindTimEvent() {
        this.#isBindTimEvent = true
        this.#handleTimEvent('on')
    }
    #handleTimEvent(type) {
        this.tim[type](TIM.EVENT.SDK_READY, this.#timEvents.onReady, this);
        this.tim[type](TIM.EVENT.MESSAGE_RECEIVED, this.#timEvents.messageReceived, this);
        this.tim[type](TIM.EVENT.ERROR, this.#timEvents.onError, this)
        this.tim[type](TIM.EVENT.KICKED_OUT, this.#timEvents.onError, this);
        this.tsignaling[type](TSignaling.EVENT.NEW_INVITATION_RECEIVED, type == 'on' ? this.#timEvents.onNewInvitationReceived : null, this);
        this.tsignaling[type](TSignaling.EVENT.INVITEE_ACCEPTED, type == 'on' ? this.#timEvents.onInviteeAccepted : null, this);
        this.tsignaling[type](TSignaling.EVENT.INVITEE_REJECTED, type == 'on' ? this.#timEvents.onInviteeRejected : null, this);
        this.tsignaling[type](TSignaling.EVENT.INVITATION_CANCELLED, type == 'on' ? this.#timEvents.onInvitationCancelled : null, this);
    }
    clearEvents() {
        this.#isBindTimEvent = false
        this.#handleTimEvent('off')
        this.#events = {}
    }
    #timEventsInit() {
        this.#timEvents = {}
        this.#timEvents.messageReceived = function messageReceived(event) {
            event.data.forEach(message => {
                const payload = message.payload
                if (message.type == TIM.TYPES.MSG_TEXT) {
                    //文本消息
                    this.getUserInfoList([message.from]).then(userInfoList => {
                        this.emit(EVENT_TYPE.onRecvRoomTextMsg, [message, userInfoList[0]])
                    })
                }
                if (message.type == TIM.TYPES.MSG_GRP_TIP) {
                    //群提示消息
                    if (payload.operationType === TIM.TYPES.GRP_TIP_MBR_JOIN) {
                        //有成员加群
                        this.getUserInfoList([payload.operatorID]).then(userInfoList => {
                            this.emit(EVENT_TYPE.onAudienceEnter, [userInfoList[0]])
                            this.emit(EVENT_TYPE.onSeatListChange, this._groupAttributes)
                        })
                    }
                    if (payload.operationType === TIM.TYPES.GRP_TIP_MBR_QUIT) {
                        //有群成员退群
                        this.getUserInfoList([payload.operatorID]).then(userInfoList => {
                            this.emit(EVENT_TYPE.onAudienceExit, [userInfoList[0]])
                        })
                    }
                    // 群组资料变更
                    if (payload.operationType === TIM.TYPES.GRP_TIP_GRP_PROFILE_UPDATED) {
                        //群属性变更
                        const groupAttributeList = payload.newGroupProfile.groupAttributeOption.groupAttributeList
                        groupAttributeList.forEach(item => {
                            const value = JSON.parse(item.value)
                            if (!this._groupAttributes[item.key].user && value.user) {
                                //有成员上麦(主动上麦/房主抱人上麦)。
                                this.getUserInfoList([value.user]).then(userInfoList => {
                                    this.emit(EVENT_TYPE.onAnchorEnterSeat, [Number(item.key.slice(SEAT_STATUS.SEAT_LENGTH)), userInfoList[0]])
                                })
                            } else if (this._groupAttributes[item.key].user && !value.user) {
                                //有成员下麦(主动下麦/房主踢人下麦)。
                                this.getUserInfoList([this._groupAttributes[item.key].user]).then(userInfoList => {
                                    this.emit(EVENT_TYPE.onAnchorLeaveSeat, [Number(item.key.slice(SEAT_STATUS.SEAT_LENGTH)), userInfoList[0]])
                                })
                            } else if (value.mute != this._groupAttributes[item.key].mute) {
                                //房主禁麦。
                                this.emit(EVENT_TYPE.onSeatMute, [Number(item.key.slice(SEAT_STATUS.SEAT_LENGTH)), value.mute])
                            } else if (value.status != this._groupAttributes[item.key].status) {
                                //房主封麦。
                                this.emit(EVENT_TYPE.onSeatClose, [Number(item.key.slice(SEAT_STATUS.SEAT_LENGTH)), value.status == SEAT_STATUS.CLOSE])
                            }
                            this._groupAttributes[item.key] = value
                        })
                        this.tim.getGroupAttributes({
                            groupID: this.groupID,
                            keyList: []
                        }).then((imResponse) => {
                            this._groupAttributes = this._handleGroupAttributes(imResponse.data.groupAttributes)
                            this.emit(EVENT_TYPE.onSeatListChange, this._groupAttributes)
                        })
                    }
                }
                if (message.type == TIM.TYPES.MSG_GRP_SYS_NOTICE) {
                    //群系统通知消息
                    if (payload.operationType == IM_STATUS.GROUP_DISMISSED) {
                        // 群组被解散
                        this.emit(EVENT_TYPE.onRoomDestroy, this.groupID)
                    }
                }


            })
        }.bind(this)
        this.#timEvents.onError = function onError(event) {
            this.emit(EVENT_TYPE.onError, [event])
        }.bind(this)
        this.#timEvents.onReady = function onReady(event) {
            this.emit(EVENT_TYPE.onReady, [event])
        }.bind(this)
        this.#timEvents.onNewInvitationReceived = (event) => {
            const data = JSON.parse(event.data.data).data
            this.emit(EVENT_TYPE.onReceiveNewInvitation, [event.data.inviteID, event.data.inviter, data.cmd, data])
        }
        this.#timEvents.onInviteeAccepted = (event) => {
            this.emit(EVENT_TYPE.onInviteeAccepted, [event.data.inviteID, event.data.invitee])
        }
        this.#timEvents.onInviteeRejected = (event) => {
            this.emit(EVENT_TYPE.onInviteeRejected, [event.data.inviteID, event.data.invitee])
        }
        this.#timEvents.onInvitationCancelled = (event) => {
            this.emit(EVENT_TYPE.onInvitationCancelled, [event.data.inviteID, event.data.inviter])
        }
    }
    init(options) {
        this.#events = {}
        this.SDKAppID = options.SDKAppID
        this.userId = options.userId
        this.userSig = options.userSig
        this.tim = options.tim || TIM.create({ SDKAppID: options.SDKAppID })
        if (!wx.$TSignaling) {
            wx.$TSignaling = new TSignaling({ SDKAppID: options.SDKAppID, tim: this.tim })
        }
        this.tsignaling = wx.$TSignaling
        this.#timEventsInit()
        this.#bindTimEvent()
        return this.tsignaling.login({ userID: this.userId, userSig: this.userSig })
    }
    logout() {
        return this.tim.logout();
    }
    destroy() {
        this.clearEvents()
        this.groupID = undefined
        this._groupAttributes = undefined
        this._seatIndex = undefined
        this._seatInfoList = undefined
    }
    /**房间相关接口 */
    //创建房间
    createRoom(roomId, roomParam) {
        let groupAttributes = {}
        groupAttributes.roomInfo = JSON.stringify({
            cover: roomParam.coverUrl,
            ownerId: this.userId,
            roomName: roomParam.roomName,
            seatSize: roomParam.seatCount,
            needRequest: roomParam.needRequest
        })
        for (let i = 0; i < roomParam.seatCount; i++) {
            groupAttributes['seat' + i] = JSON.stringify({
                mute: false,
                status: SEAT_STATUS.NO_USER,
                user: ''
            })
        }
        return this.tim.createGroup({
            type: TIM.TYPES.GRP_AVCHATROOM,
            name: roomParam.roomName,
            groupID: roomId
        }).then(() => {
            return Promise.all([
                this.tim.updateGroupProfile({
                    groupID: roomId,
                    avatar: roomParam.coverUrl,
                    name: roomParam.roomName, // 修改群名称
                    introduction: roomParam.roomName
                }),
                this.tim.joinGroup({ groupID: roomId })
            ])
        }, (imError) => {
            return Promise.all([
                this.tim.updateGroupProfile({
                    groupID: roomId,
                    avatar: roomParam.coverUrl,
                    name: roomParam.roomName, // 修改群名称
                    introduction: roomParam.roomName,
                }),
                this.tim.joinGroup({ groupID: roomId })
            ])
        }).then(() => {
            return this.tim.initGroupAttributes({
                groupID: roomId,
                groupAttributes
            })
        }).then(() => {
            this.groupID = roomId
            this._groupAttributes = this._handleGroupAttributes(groupAttributes)
            this.emit(EVENT_TYPE.onSeatListChange, this._groupAttributes)
            return
        })
    }
    //销毁房间
    destroyRoom() {
        return this.tim.dismissGroup(this.groupID).then(() => {
            this.destroy()
        })
    }
    //进入房间
    enterRoom(roomId) {
        return this.tim.joinGroup({ groupID: roomId })
            .then(() => {
                return this.tim.getGroupAttributes({
                    groupID: roomId,
                    keyList: []
                })
            })
            .then(imResponse => {
                this.groupID = roomId
                this._groupAttributes = this._handleGroupAttributes(imResponse.data.groupAttributes)
            })
    }
    //退出房间-房主不能退出
    exitRoom() {
        if (this._groupAttributes.roomInfo.ownerId == this.userId) {
            throw new Error('房主不能主动退出')
        }
        return Promise.all([
            this.leaveSeat(),
            this.tim.quitGroup(this.groupID)
        ]).then(() => this.destroy())
    }
    //批量获取房间信息
    async getRoomInfoList(roomIdList) {
        let ans = []
        for (let i = 0; i < roomIdList.length; i++) {
            await this.tim.getGroupProfile({ groupID: roomIdList[i] }).then((imResponse) => {
                ans.push(imResponse.data.group)
            }, (err) => {
                console.error(err)
            })
        }
        return ans
    }
    //批量获取用户信息
    getUserInfoList(userIdList, count = 15, offset = 0) {
        if (userIdList.length == 0) {
            return this.tim.getGroupMemberList({ groupID: this.groupID, count, offset })
                .then(imResponse => {
                    return imResponse.data.memberList
                })
        } else {
            return this.tim.getUserProfile({
                userIDList: userIdList
            }).then(imResponse => {
                return imResponse.data
            })
        }
    }
    //获取房间在线人数
    getGroupOnlineMemberCount() {
        return this.tim.getGroupOnlineMemberCount(this.groupID).then(imResponse => {
            return imResponse.data.memberCount
        })
    }
    /**麦位管理接口 */
    //主动上麦（听众端和房主均可调用）
    enterSeat(seatIndex) {
        return this.tim.getGroupAttributes({
            groupID: this.groupID,
            keyList: []
        }).then(imResponse => {
            this._groupAttributes = this._handleGroupAttributes(imResponse.data.groupAttributes)
            return this.tim.setGroupAttributes({
                groupID: this.groupID,
                groupAttributes: {
                    ['seat' + seatIndex]: JSON.stringify({
                        mute: false,
                        status: SEAT_STATUS.EXIST_USER,
                        user: this.userId
                    })
                }
            }).then(() => {
                this._seatIndex = seatIndex
            })
        })
    }
    //主动下麦
    leaveSeat() {
        this._seatIndex = undefined //先清空
        for (let key in this._groupAttributes) {
            if (this._groupAttributes[key].user == this.userId) {
                this._seatIndex = Number(key.slice(SEAT_STATUS.SEAT_LENGTH))
                break
            }
        }
        if (this._seatIndex == undefined) return
        return this.tim.getGroupAttributes({
            groupID: this.groupID,
            keyList: []
        }).then(imResponse => {
            this._groupAttributes = this._handleGroupAttributes(imResponse.data.groupAttributes)
            return this.tim.setGroupAttributes({
                groupID: this.groupID,
                groupAttributes: {
                    ['seat' + this._seatIndex]: JSON.stringify({
                        mute: false,
                        status: SEAT_STATUS.NO_USER,
                        user: ''
                    })
                }
            });
        })
    }
    //主动禁言
    muteSeatSelf(isMute) {
        for (let key in this._groupAttributes) {
            if (this._groupAttributes[key].user == this.userId) {
                this._seatIndex = Number(key.slice(SEAT_STATUS.SEAT_LENGTH))
                break
            }
        }
        return this.tim.setGroupAttributes({
            groupID: this.groupID,
            groupAttributes: {
                ['seat' + this._seatIndex]: JSON.stringify({
                    mute: isMute,
                    status: SEAT_STATUS.EXIST_USER,
                    user: this.userId
                })
            }
        });
    }
    //让某个用户上麦
    pickSeat(seatIndex, userId) {
        return this.tim.setGroupAttributes({
            groupID: this.groupID,
            groupAttributes: {
                ['seat' + seatIndex]: JSON.stringify({
                    mute: false,
                    status: SEAT_STATUS.EXIST_USER,
                    user: userId
                })
            }
        })
    }
    //踢用户下麦
    kickSeat(seatIndex) {
        return this.tim.setGroupAttributes({
            groupID: this.groupID,
            groupAttributes: {
                ['seat' + seatIndex]: JSON.stringify({
                    mute: false,
                    status: SEAT_STATUS.NO_USER,
                    user: ''
                })
            }
        })
    }
    //对麦位禁言
    muteSeat(seatIndex, isMute) {
        return this.tim.getGroupAttributes({
            groupID: this.groupID,
            keyList: []
        }).then(imResponse => {
            this._groupAttributes = this._handleGroupAttributes(imResponse.data.groupAttributes)
            return this.tim.setGroupAttributes({
                groupID: this.groupID,
                groupAttributes: {
                    ['seat' + seatIndex]: JSON.stringify({
                        mute: isMute,
                        status: this._groupAttributes['seat' + seatIndex].status,
                        user: this._groupAttributes['seat' + seatIndex].user
                    })
                }
            });
        })

    }
    //封禁麦位
    closeSeat(seatIndex, isClose) {
        return this.tim.getGroupAttributes({
            groupID: this.groupID,
            keyList: []
        }).then(imResponse => {
            this._groupAttributes = this._handleGroupAttributes(imResponse.data.groupAttributes)
            return this.tim.setGroupAttributes({
                groupID: this.groupID,
                groupAttributes: {
                    ['seat' + seatIndex]: JSON.stringify({
                        mute: false,
                        status: isClose ? SEAT_STATUS.CLOSE : SEAT_STATUS.NO_USER,
                        user: ''
                    })
                }
            });
        })
    }
    /**消息发送相关接口函数 */
    //发送文字消息
    sendRoomTextMsg(text) {
        let message = this.tim.createTextMessage({
            to: this.groupID,
            conversationType: TIM.TYPES.CONV_GROUP,
            payload: { text },
        })
        return this.tim.sendMessage(message).then(data => {
            return data.data.message
        })
    }
    /**邀请信令相关接口 */
    //发送邀请信令
    sendInvitation(options) {
        return this.tsignaling.invite({
            userID: options.userId,
            data: JSON.stringify(this._handleNewMessage(options)),
        }).then(res => {
            this.inviteMap.set(res.inviteID, options)
            return res
        })
    }
    //同意邀请信令
    acceptInvitation(id, options = {}) {
        return this.tsignaling.accept({
            inviteID: id,
            data: JSON.stringify(this._handleNewMessage(options)),
        }).then(res => {
            this.inviteMap.delete(id)
            return res
        })
    }
    //拒绝邀请信令
    rejectInvitation(id) {
        return this.tsignaling.reject({ inviteID: id })
    }
    //取消邀请信令
    cancelInvitation(id) {
        return this.tsignaling.cancel({ inviteID: id })
    }
}

export default VoiceRoom