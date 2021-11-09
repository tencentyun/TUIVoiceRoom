//
//  TRTCVoiceRoomViewModel.swift
//  TRTCVoiceRoomDemo
//
//  Created by abyyxwang on 2020/6/8.
//  Copyright © 2020 tencent. All rights reserved.
//

import Foundation

protocol TRTCVoiceRoomViewResponder: class {
    func showToast(message: String)
    func showToastActivity()
    func hiddenToastActivity()
    func popToPrevious()
    func switchView(type: VoiceRoomViewType)
    func changeRoom(info: VoiceRoomInfo)
    func refreshAnchorInfos()
    func onSeatMute(isMute: Bool)
    func onAnchorMute(isMute: Bool)
    func showAlert(info: (title: String, message: String), sureAction: @escaping () -> Void, cancelAction: (() -> Void)?)
    func showActionSheet(actionTitles:[String], actions: @escaping (Int) -> Void)
    func refreshMsgView()
    func msgInput(show: Bool)
    func audiceneList(show: Bool)
    func audienceListRefresh()
    func showAudioEffectView()
    func stopPlayBGM() // 停止播放音乐
    func recoveryVoiceSetting() // 恢复音效设置
    func showBgMusicAlert()
    func showMoreAlert()
    func showAudienceAlert(seat: SeatInfoModel)
}

class TRTCVoiceRoomViewModel: NSObject {
    private let dependencyContainer: TRTCVoiceRoomEnteryControl
    private(set) var roomType: VoiceRoomViewType {
        didSet {
            roleChange(viewType: roomType)
        }
    }
    public weak var viewResponder: TRTCVoiceRoomViewResponder?
    var isOwner: Bool {
        return dependencyContainer.userId == roomInfo.ownerId
    }
    private(set) var isSelfMute: Bool = false {
        didSet {
            // 同步本地userMuteMap用户静音状态
            userMuteMap[dependencyContainer.userId] = isSelfMute
        }
    }
    // 防止多次退房
    private var isExitingRoom: Bool = false
    
    private(set) var roomInfo: VoiceRoomInfo
    private(set) var isSeatInitSuccess: Bool = false
    private(set) var mSelfSeatIndex: Int = -1
    
    // UI相关属性
    private(set) var masterAnchor: SeatInfoModel?
    private(set) var anchorSeatList: [SeatInfoModel] = []
    /// 观众信息记录
    private(set) var memberAudienceList: [AudienceInfoModel] = []
    private(set) var memberAudienceDic: [String: AudienceInfoModel] = [:]
    public func getRealMemberAudienceList() -> [AudienceInfoModel] {
        var res : [AudienceInfoModel] = []
        for audience in memberAudienceList {
            if memberAudienceDic.keys.contains(audience.userInfo.userId) {
                res.append(audience)
            }
        }
        return res
    }
    
    public enum RoomUserType {
        case owner
        case anchor
        case audience
    }
    
    public var userType : RoomUserType = .audience
    
    private(set) var msgEntityList: [MsgEntity] = []
    /// 当前邀请操作的座位号记录
    private var currentInvitateSeatIndex: Int = -1 // -1 表示没有操作
    /// 上麦信息记录(观众端)
    private var mInvitationSeatDic: [String: Int] = [:]
    /// 上麦信息记录(主播端)
    private var mTakeSeatInvitationDic: [String: String] = [:]
    /// 抱麦信息记录
    private var mPickSeatInvitationDic: [String: SeatInvitation] = [:]
    
    public var userMuteMap : [String : Bool] = [:]
    
    /// 初始化方法
    /// - Parameter container: 依赖管理容器，负责VoiceRoom模块的依赖管理
    init(container: TRTCVoiceRoomEnteryControl, roomInfo: VoiceRoomInfo, roomType: VoiceRoomViewType) {
        self.dependencyContainer = container
        self.roomType = roomType
        self.roomInfo = roomInfo
        super.init()
        voiceRoom.setDelegate(delegate: self)
        roleChange(viewType: self.roomType)
        initAnchorListData()
    }
    
    deinit {
        TRTCLog.out("deinit \(type(of: self))")
    }
    
    public var voiceRoom: TRTCVoiceRoom {
        return dependencyContainer.getVoiceRoom()
    }
    
    lazy var effectViewModel: TRTCVoiceRoomSoundEffectViewModel = {
        return TRTCVoiceRoomSoundEffectViewModel(self)
    }()
    
    func exitRoom() {
        guard !isExitingRoom else { return }
        viewResponder?.popToPrevious()
        isExitingRoom = true
        if voiceEarMonitor {
            voiceEarMonitor = false
        }
        if dependencyContainer.userId == roomInfo.ownerId && roomType == .anchor {
            dependencyContainer.destroyRoom(roomID: "\(roomInfo.roomID)", success: {
                TRTCLog.out("---deinit room success")
            }) { (code, message) in
                TRTCLog.out("---deinit room failed")
            }
            voiceRoom.destroyRoom { [weak self] (code, message) in
                guard let `self` = self else { return }
                self.isExitingRoom = false
            }
            return
        }
        voiceRoom.exitRoom { [weak self] (code, message) in
            guard let `self` = self else { return }
            self.isExitingRoom = false
        }
    }
    
    public var voiceEarMonitor: Bool = false {
        willSet {
            self.voiceRoom.setVoiceEarMonitor(enable: newValue)
        }
    }
    
    public func refreshView() {
        roleChange(viewType: roomType)
    }
    
    public func openMessageTextInput() {
        viewResponder?.msgInput(show: true)
    }
    
    public func openAudioEffectMenu() {
        guard checkButtonPermission() else { return }
        viewResponder?.showAudioEffectView()
    }
    
    public func muteAction(isMute: Bool) -> Bool {
        guard checkButtonPermission() else { return false }
        if let userSeatInfo = getUserSeatInfo(userId: dependencyContainer.userId)?.seatInfo, userSeatInfo.mute {
            viewResponder?.showToast(message: .seatmutedText)
            return false
        }
        
        isSelfMute = isMute
        voiceRoom.muteLocalAudio(mute: isMute)
        if isMute {
            viewResponder?.showToast(message: .micmutedText)
        } else {
            viewResponder?.recoveryVoiceSetting()
            viewResponder?.showToast(message: .micunmutedText)
        }
        return true
    }
    
    public func moreBtnClick() {
        viewResponder?.showMoreAlert()
    }
    
    public func spechAction(isMute: Bool) {
        voiceRoom.muteAllRemoteAudio(isMute: isMute)
        if isMute {
            viewResponder?.showToast(message: .mutedText)
        } else {
            viewResponder?.showToast(message: .unmutedText)
        }
    }
    
    public func clickSeat(model: SeatInfoModel) {
        guard isSeatInitSuccess else {
            viewResponder?.showToast(message: .seatuninitText)
            return
        }
        if roomType == .audience || dependencyContainer.userId != roomInfo.ownerId {
            audienceClickItem(model: model)
        } else {
            anchorClickItem(model: model)
        }
    }
    
    public func clickAudienceAgree(model: AudienceInfoModel) {
        
    }
    
    public func clickSeatLock(isLock: Bool, model: SeatInfoModel) {
        self.voiceRoom.closeSeat(seatIndex: model.seatIndex, isClose: isLock, callback: nil)
    }
    
    public func enterRoom(toneQuality: Int = VoiceRoomToneQuality.defaultQuality.rawValue) {
        voiceRoom.enterRoom(roomID: roomInfo.roomID) { [weak self] (code, message) in
            guard let `self` = self else { return }
            if code == 0 {
                self.viewResponder?.showToast(message: .enterSuccessText)
                self.voiceRoom.setAuidoQuality(quality: toneQuality)
                self.getAudienceList()
            } else {
                self.viewResponder?.showToast(message: .enterFailedText)
                self.viewResponder?.popToPrevious()
            }
        }
    }
    public func createRoom(toneQuality: Int = 0) {
        let faceUrl = TRTCVoiceRoomIMManager.shared.curUserAvatar
        voiceRoom.setAuidoQuality(quality: toneQuality)
        voiceRoom.setSelfProfile(userName: roomInfo.ownerName, avatarURL: faceUrl) { [weak self] (code, message) in
            guard let `self` = self else { return }
            TRTCLog.out("setSelfProfile\(code)\(message)")
            self.dependencyContainer.createRoom(roomID: "\(self.roomInfo.roomID)") {  [weak self] in
                guard let `self` = self else { return }
                self.internalCreateRoom()
            } failed: { [weak self] code, message in
                guard let `self` = self else { return }
                if code == -1301 {
                    self.internalCreateRoom()
                } else {
                    self.viewResponder?.showToast(message: .createRoomFailedText)
                    self.viewResponder?.popToPrevious()
                }
            }
        }
    }
    
    public func onTextMsgSend(message: String) {
        if message.count == 0 {
            return
        }
        // 消息回显示
        let entity = MsgEntity.init(userId: dependencyContainer.userId, userName: .meText, content: message, invitedId: "", type: MsgEntity.TYPE_NORMAL)
        notifyMsg(entity: entity)
        voiceRoom.sendRoomTextMsg(message: message) { [weak self] (code, message) in
            guard let `self` = self else { return }
            self.viewResponder?.showToast(message: code == 0 ? .sendSuccessText :  LocalizeReplaceXX(.sendFailedText, message))
        }
    }
    
    public func acceptTakeSeat(identifier: String) {
        if let audience = memberAudienceDic[identifier] {
            acceptTakeSeatInvitation(userInfo: audience.userInfo)
        }
    }
}

// MARK: - private method
extension TRTCVoiceRoomViewModel {
    
    private func internalCreateRoom() {
        let param = VoiceRoomParam.init()
        param.roomName = roomInfo.roomName
        param.needRequest = roomInfo.needRequest
        param.seatCount = roomInfo.memberCount
        param.coverUrl = roomInfo.coverUrl
        param.seatCount = 9
        param.seatInfoList = []
        for _ in 0..<param.seatCount {
            let seatInfo = VoiceRoomSeatInfo.init()
            param.seatInfoList.append(seatInfo)
        }
        voiceRoom.createRoom(roomID: Int32(roomInfo.roomID), roomParam: param) { [weak self] (code, message) in
            guard let `self` = self else { return }
            if code == 0 {
                self.viewResponder?.changeRoom(info: self.roomInfo)
                self.takeMainSeat()
                self.getAudienceList()
            } else {
                self.viewResponder?.showToast(message: .enterFailedText)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    guard let `self` = self else { return }
                    self.viewResponder?.popToPrevious()
                }
            }
        }
    }
    
    private func takeMainSeat() {
        voiceRoom.enterSeat(seatIndex: 0) { [weak self] (code, message) in
            guard let `self` = self else { return }
            if code == 0 {
                self.userMuteMap[self.roomInfo.ownerId] = false
                self.viewResponder?.showToast(message: .cupySeatSuccessText)
            } else {
                self.viewResponder?.showToast(message: .cupySeatFailedText)
            }
        }
    }
    
    private func getAudienceList() {
        voiceRoom.getUserInfoList(userIDList: nil) { [weak self] (code, message, infos) in
            guard let `self` = self else { return }
            if code == 0 {
                let audienceInfoModels = infos.map { (userInfo) -> AudienceInfoModel in
                    return AudienceInfoModel.init(userInfo: userInfo) { [weak self] (index) in
                        // 点击邀请上麦事件，以及接受邀请事件
                        guard let `self` = self else { return }
                        if index == 0 {
                            self.sendInvitation(userInfo: userInfo)
                        } else {
                            self.acceptTakeSeatInvitation(userInfo: userInfo)
                        }
                    }
                }
                self.memberAudienceList.removeAll()
                // 此处会有数据重复，需要做一次去重判断
                for item in audienceInfoModels {
                    if !self.memberAudienceList.contains(where: {$0.userInfo.userId == item.userInfo.userId}) {
                        self.memberAudienceList.append(item)
                    }
                }
                audienceInfoModels.forEach { (info) in
                    self.memberAudienceDic[info.userInfo.userId] = info
                }
                self.viewResponder?.audienceListRefresh()
            }
        }
    }
    
    func checkButtonPermission() -> Bool {
        if roomType == .audience {
            viewResponder?.showToast(message: .onlyAnchorOperationText)
            return false
        }
        return true
    }
    
    private func roleChange(viewType: VoiceRoomViewType) {
        viewResponder?.switchView(type: viewType)
    }
    
    private func initAnchorListData() {
        for _ in 0...7 {
            var model = SeatInfoModel.init { [weak self] (seatIndex) in
                guard let `self` = self else { return }
                if seatIndex > 0 && seatIndex <= self.anchorSeatList.count {
                    let model = self.anchorSeatList[seatIndex - 1]
                    print("=====\(model.seatIndex)")
                    self.clickSeat(model: model)
                }
            }
            model.isOwner = dependencyContainer.userId == roomInfo.ownerId
            model.isClosed = false
            model.isUsed = false
            anchorSeatList.append(model)
        }
    }
    
    public func audienceClickMicoff(model: SeatInfoModel) {
        leaveSeat()
    }
    
    private func audienceClickItem(model: SeatInfoModel) {
        guard model.seatIndex != -1 else {
            viewResponder?.showToast(message: .notInitText)
            return
        }
        guard !model.isClosed else {
            viewResponder?.showToast(message: .seatLockedText)
            return
        }
        if model.isUsed {
            if dependencyContainer.userId == model.seatUser?.userId ?? "" {
                // 麦位被自己使用
            } else {
                // 麦位被他人占用
                viewResponder?.showToast(message: "\(model.seatUser?.userName ?? .otherAnchorText)")
            }
        } else {
            // 查找当前用户是否在麦位
            let currentSeatInfo = isInSeat(userId: dependencyContainer.userId)
            if currentSeatInfo.inSeat {
                // 用户已经在麦位
                if currentSeatInfo.seatIndex == model.seatIndex {
                    viewResponder?.showToast(message: LocalizeReplaceXX(.isInxxSeatText, String(currentSeatInfo.seatIndex)))
                    return
                }
                // 用户已在麦位: 需要申请移麦
                viewResponder?.showActionSheet(actionTitles: [.moveSeatText], actions: { [weak self] (index) in
                    guard let `self` = self else { return }
                    self.startMoveToSeat(targetIndex: model.seatIndex)
                })
            } else {
                // 用户不在麦位: 申请上麦
                viewResponder?.showActionSheet(actionTitles: [.handsupText], actions: { [weak self] (index) in
                    guard let `self` = self else { return }
                    self.startTakeSeat(seatIndex: model.seatIndex)
                })
            }
        }
    }
    
    private func anchorClickItem(model: SeatInfoModel) {
        if model.isUsed {
            // 弹出禁言， 踢人
            let isMute = model.seatInfo?.mute ?? false
            viewResponder?.showActionSheet(actionTitles: [LocalizeReplaceXX(.totaxxText, (isMute ? String.unmuteOneText : String.muteOneText)), .makeAudienceText], actions: { [weak self] (index) in
                guard let `self` = self else { return }
                if index == 0 {
                    // 禁言
                    self.voiceRoom.muteSeat(seatIndex: model.seatIndex, isMute: !isMute, callback: nil)
                } else {
                    // 下麦
                    self.voiceRoom.kickSeat(seatIndex: model.seatIndex, callback: nil)
                }
            })
            return
        }
        viewResponder?.showAudienceAlert(seat: model)
        currentInvitateSeatIndex = model.seatIndex
    }
    
    private func onAnchorSeatSelected(seatIndex: Int) {
        viewResponder?.audiceneList(show: true)
        currentInvitateSeatIndex = seatIndex
    }
    
    private func sendInvitation(userInfo: VoiceRoomUserInfo) {
        guard currentInvitateSeatIndex != -1 else { return }
        // 邀请
        let seatEntity = anchorSeatList[currentInvitateSeatIndex - 1]
        if seatEntity.isUsed {
            viewResponder?.showToast(message: .seatBusyText)
            return
        }
        let seatInvitation = SeatInvitation.init(seatIndex: currentInvitateSeatIndex, inviteUserId: userInfo.userId)
        let inviteId = voiceRoom.sendInvitation(cmd: VoiceRoomConstants.CMD_PICK_UP_SEAT,
                                                userId: seatInvitation.inviteUserId,
                                                content: "\(seatInvitation.seatIndex)") { [weak self] (code, message) in
                                                    guard let `self` = self else { return }
                                                    if code == 0 {
                                                        self.viewResponder?.showToast(message: .sendInviteSuccessText)
                                                    }
        }
        mPickSeatInvitationDic[inviteId] = seatInvitation
        viewResponder?.audiceneList(show: false)
    }
    
    private func acceptTakeSeatInvitation(userInfo: VoiceRoomUserInfo) {
        // 接受
        guard let inviteID = mTakeSeatInvitationDic[userInfo.userId] else {
            viewResponder?.showToast(message: .reqExpiredText)
            return
        }
        voiceRoom.acceptInvitation(identifier: inviteID) { [weak self] (code, message) in
            guard let `self` = self else { return }
            if code == 0 {
                // 接受请求成功，刷新外部对话列表
                if let index = self.msgEntityList.firstIndex(where: { (msg) -> Bool in
                    return msg.invitedId == inviteID
                }) {
                    var msg = self.msgEntityList[index]
                    msg.type = MsgEntity.TYPE_AGREED
                    self.msgEntityList[index] = msg
                    self.viewResponder?.refreshMsgView()
                }
            } else {
                self.viewResponder?.showToast(message: .acceptReqFailedText)
            }
        }
    }
    
    private func leaveSeat() {
        voiceRoom.leaveSeat { [weak self] (code, message) in
            guard let `self` = self else { return }
            if code == 0 {
                self.viewResponder?.showToast(message: .audienceSuccessText)
            } else {
                self.viewResponder?.showToast(message: LocalizeReplaceXX(.audienceFailedxxText, message))
            }
        }
    }
    
    /// 观众开始上麦
    /// - Parameter seatIndex: 上的作为号
    private func startTakeSeat(seatIndex: Int) {
        if roomType == .anchor {
            viewResponder?.showToast(message: .beingArchonText)
            return
        }
        if roomInfo.needRequest {
            // 需要申请上麦
            guard roomInfo.ownerId != "" else {
                viewResponder?.showToast(message: .roomNotReadyText)
                return
            }
            let cmd = VoiceRoomConstants.CMD_REQUEST_TAKE_SEAT
            let targetUserId = roomInfo.ownerId
            let inviteId = voiceRoom.sendInvitation(cmd: cmd, userId: targetUserId, content: "\(seatIndex)") { [weak self] (code, message) in
                guard let `self` = self else { return }
                if code == 0 {
                    self.viewResponder?.showToast(message: .reqSentText)
                } else {
                    self.viewResponder?.showToast(message: LocalizeReplaceXX(.reqSendFailedxxText, message))
                }
            }
            mInvitationSeatDic[inviteId] = seatIndex
        } else {
            // 显示Loading指示框， 回调结束消失
            self.viewResponder?.showToastActivity()
            // 不需要申请上麦的情况下直接发起上麦
            voiceRoom.enterSeat(seatIndex: seatIndex) { [weak self] (code, message) in
                guard let `self` = self else { return }
                // 隐藏loading指示框
                self.viewResponder?.hiddenToastActivity()
                if code == 0 {
                    self.viewResponder?.showToast(message: .handsupSuccessText)
                } else {
                    self.viewResponder?.showToast(message: .handsupFailedText)
                }
            }
        }
    }
    
    /// 观众开始移麦
    /// - Parameter targetIndex: 需要移动的麦位号
    private func startMoveToSeat(targetIndex: Int) {
        if roomInfo.needRequest {
            // 需要申请上麦
            guard roomInfo.ownerId != "" else {
                viewResponder?.showToast(message: .roomNotReadyText)
                return
            }
            let cmd = VoiceRoomConstants.CMD_REQUEST_TAKE_SEAT
            let targetUserId = roomInfo.ownerId
            let inviteId = voiceRoom.sendInvitation(cmd: cmd, userId: targetUserId, content: "\(targetIndex)") { [weak self] (code, message) in
                guard let `self` = self else { return }
                if code == 0 {
                    self.viewResponder?.showToast(message: .reqSentText)
                } else {
                    self.viewResponder?.showToast(message: LocalizeReplaceXX(.reqSendFailedxxText, message))
                }
            }
            mInvitationSeatDic[inviteId] = targetIndex
        } else {
            // 显示Loading指示框， 回调结束消失
            self.viewResponder?.showToastActivity()
            // 不需要申请上麦的情况下直接发起移动麦位
            voiceRoom.moveSeat(seatIndex: targetIndex) { [weak self](code, message) in
                guard let `self` = self else { return }
                // 隐藏loading指示框
                self.viewResponder?.hiddenToastActivity()
                if code == 0 {
                    self.viewResponder?.showToast(message: .handsupSuccessText)
                } else {
                    self.viewResponder?.showToast(message: .handsupFailedText)
                }
            }
        }
    }
    
    private func recvPickSeat(identifier: String, cmd: String, content: String) {
        guard let seatIndex = Int.init(content) else { return }
        viewResponder?.showAlert(info: (title: .alertText, message: LocalizeReplaceXX(.invitexxSeatText, String(seatIndex))), sureAction: { [weak self] in
            guard let `self` = self else { return }
            self.voiceRoom.acceptInvitation(identifier: identifier) { [weak self] (code, message) in
                guard let `self` = self else { return }
                if code != 0 {
                    self.viewResponder?.showToast(message: .acceptReqFailedText)
                }
            }
        }, cancelAction: { [weak self] in
            guard let `self` = self else { return }
            self.voiceRoom.rejectInvitation(identifier: identifier) { [weak self] (code, message) in
                guard let `self` = self else { return }
                self.viewResponder?.showToast(message: .refuseHandsupText)
            }
        })
    }
    
    private func recvTakeSeat(identifier: String, inviter: String, content: String) {
        // 收到新的邀请后，更新列表,其他的信息
        if let index = msgEntityList.firstIndex(where: { (msg) -> Bool in
            return msg.userId == inviter && msg.type == MsgEntity.TYPE_WAIT_AGREE
        }) {
            var msg = msgEntityList[index]
            msg.type = MsgEntity.TYPE_AGREED
            msgEntityList[index] = msg
        }
        // 显示到通知栏
        let audinece = memberAudienceDic[inviter]
        let seatIndex = (Int.init(content) ?? 0)
        let content = LocalizeReplaceXX(.applyxxSeatText, String(seatIndex))
        let msgEntity = MsgEntity.init(userId: inviter, userName: audinece?.userInfo.userName ?? inviter, content: content, invitedId: identifier, type: MsgEntity.TYPE_WAIT_AGREE)
        msgEntityList.append(msgEntity)
        viewResponder?.refreshMsgView()
        if var audienceModel = audinece {
            audienceModel.type = AudienceInfoModel.TYPE_WAIT_AGREE
            memberAudienceDic[audienceModel.userInfo.userId] = audienceModel
            if let index = memberAudienceList.firstIndex(where: { (model) -> Bool in
                return model.userInfo.userId == audienceModel.userInfo.userId
            }) {
                memberAudienceList[index] = audienceModel
            }
            viewResponder?.audienceListRefresh()
        }
        mTakeSeatInvitationDic[inviter] = identifier
    }
    
    private func notifyMsg(entity: MsgEntity) {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }
            if self.msgEntityList.count > 1000 {
                self.msgEntityList.removeSubrange(0...99)
            }
            self.msgEntityList.append(entity)
            self.viewResponder?.refreshMsgView()
        }
    }
    
    private func showNotifyMsg(messsage: String, userName: String) {
        let msgEntity = MsgEntity.init(userId: "", userName: userName, content: messsage, invitedId: "", type: MsgEntity.TYPE_NORMAL)
        if msgEntityList.count > 1000 {
            msgEntityList.removeSubrange(0...99)
        }
        msgEntityList.append(msgEntity)
        viewResponder?.refreshMsgView()
    }
    
    private func changeAudience(status: Int, user: VoiceRoomUserInfo) {
        guard [AudienceInfoModel.TYPE_IDEL, AudienceInfoModel.TYPE_IN_SEAT, AudienceInfoModel.TYPE_WAIT_AGREE].contains(status) else { return }
        if dependencyContainer.userId == roomInfo.ownerId && roomType == .anchor {
            let audience = memberAudienceDic[user.userId]
            if var audienceModel = audience {
                if audienceModel.type == status { return }
                audienceModel.type = status
                memberAudienceDic[audienceModel.userInfo.userId] = audienceModel
                if let index = memberAudienceList.firstIndex(where: { (model) -> Bool in
                    return model.userInfo.userId == audienceModel.userInfo.userId
                }) {
                    memberAudienceList[index] = audienceModel
                }
            }
        }
        viewResponder?.audienceListRefresh()
    }
    
    /// 根据userId查询用户是否在麦位
    /// - Parameter userId: 需要查询的用户id
    /// - Returns: 查询到的用户麦位信息，
    ///            inSeat: Bool 当前用户是否在麦位
    ///            seatIndex: Int 麦位索引，不存在则为-1
    private func isInSeat(userId:String) -> (inSeat:Bool, seatIndex:Int) {
        if userId.isEmpty {
            return (false, -1)
        }
        if let user = masterAnchor?.seatUser, user.userId == userId {
            return (true, 0)
        }
        for item in anchorSeatList {
            if let seatInfo = item.seatInfo, seatInfo.userId == userId {
                return (true, item.seatIndex)
            }
        }
        return (false, -1)
    }
    
    /// 下麦 - 重置麦位相关状态
    private func resetSelfDatasOnSeatLeave() {
        // 麦位索引重置
        mSelfSeatIndex = -1
        // 静音状态重置
        isSelfMute = false
        // 耳返重置
        if voiceEarMonitor {
            voiceEarMonitor = false
        }
    }
    
    /// 根据userId查询用户的麦位信息
    /// - Parameter userId: 需要查询的用户id
    /// - Returns: 查询到的用户麦位信息 SeatInfoModel， 找不到返回nil
    private func getUserSeatInfo(userId:String) -> SeatInfoModel?{
        if userId.isEmpty {
            return nil
        }
        if let user = masterAnchor?.seatUser, user.userId == userId {
            return masterAnchor
        }
        for item in anchorSeatList {
            if let seatInfo = item.seatInfo, seatInfo.userId == userId {
                return item
            }
        }
        return nil
    }
}

// MARK: - room delegate TRTCVoiceRoomDelegate
extension TRTCVoiceRoomViewModel: TRTCVoiceRoomDelegate {
    func onError(code: Int32, message: String) {
        
    }
    
    func onWarning(code: Int32, message: String) {
        
    }
    
    func onDebugLog(message: String) {
        
    }
    
    func onRoomDestroy(message: String) {
        if let window = UIApplication.shared.windows.first {
            window.makeToast(.closeRoomText)
        }
        viewResponder?.showToast(message: .closeRoomText)
        voiceRoom.exitRoom(callback: nil)
        viewResponder?.popToPrevious()
    }
    
    func onRoomInfoChange(roomInfo: VoiceRoomInfo) {
        // 值为-1表示该接口没有返回数量信息
        if roomInfo.memberCount == -1 {
            roomInfo.memberCount = self.roomInfo.memberCount
        }
        self.roomInfo = roomInfo
        viewResponder?.changeRoom(info: self.roomInfo)
    }
    
    func onSeatListChange(seatInfoList: [VoiceRoomSeatInfo]) {
        TRTCLog.out("roomLog: onSeatListChange: \(seatInfoList)")
        isSeatInitSuccess = true
        var currentUserSeatIndex:Int = -1
        seatInfoList.enumerated().forEach { (item) in
            let seatIndex = item.offset
            let seatInfo = item.element
            var anchorSeatInfo = SeatInfoModel.init { [weak self] (seatIndex) in
                guard let `self` = self else { return }
                if seatIndex > 0 && seatIndex <= self.anchorSeatList.count {
                    let model = self.anchorSeatList[seatIndex - 1]
                    self.clickSeat(model: model)
                }
            }
            anchorSeatInfo.seatInfo = seatInfo
            if seatIndex == 0 {
                // 座位禁言的状态从回调数据中同步
                anchorSeatInfo.seatInfo?.mute = seatInfo.mute
            }
            else {
                // 座位禁言的状态从回调数据中同步
                anchorSeatInfo.seatInfo?.mute = seatInfo.mute
            }
            anchorSeatInfo.isUsed = seatInfo.status == 1
            anchorSeatInfo.isClosed = seatInfo.status == 2
            anchorSeatInfo.seatIndex = seatIndex
            anchorSeatInfo.isOwner = roomInfo.ownerId == dependencyContainer.userId
            if seatInfo.userId == dependencyContainer.userId {
                currentUserSeatIndex = seatIndex
            }
            if seatIndex == 0 {
                anchorSeatInfo.seatUser = masterAnchor?.seatUser
                masterAnchor = anchorSeatInfo
            } else {
                let listIndex = seatIndex - 1
                if anchorSeatList.count == seatInfoList.count - 1 {
                    // 说明有数据
                    let anchorSeatModel = anchorSeatList[listIndex]
                    anchorSeatInfo.seatUser = anchorSeatModel.seatUser
                    if !anchorSeatInfo.isUsed {
                        anchorSeatInfo.seatUser = nil
                    }
                    anchorSeatList[listIndex] = anchorSeatInfo
                } else {
                    // 说明没数据
                    anchorSeatList.append(anchorSeatInfo)
                }
            }
        }
        // 更新当前用户麦位索引
        mSelfSeatIndex = currentUserSeatIndex
        let seatUserIds = seatInfoList.filter({ (seat) -> Bool in
            return seat.userId != ""
        }).map { (seatInfo) -> String in
            return seatInfo.userId
        }
        voiceRoom.getUserInfoList(userIDList: seatUserIds) { [weak self] (code, message, userInfos) in
            guard let `self` = self else { return }
            guard code == 0 else { return }
            var userdic: [String : VoiceRoomUserInfo] = [:]
            userInfos.forEach { (info) in
                userdic[info.userId] = info
            }
            if seatInfoList.count > 0 {
                if self.masterAnchor?.seatUser == nil, !self.userMuteMap.keys.contains(seatInfoList[0].userId) {
                    self.userMuteMap[seatInfoList[0].userId] = true
                }
                self.masterAnchor?.seatUser = userdic[seatInfoList[0].userId]
            } else {
                return
            }
            if self.anchorSeatList.count != seatInfoList.count - 1 {
                TRTCLog.out(String.seatlistWrongText)
                return
            }
            // 修改座位列表的user信息
            for index in 0..<self.anchorSeatList.count {
                let seatInfo = seatInfoList[index + 1] // 从观众开始更新
                if self.anchorSeatList[index].seatUser == nil, let user = userdic[seatInfo.userId], !self.userMuteMap.keys.contains(user.userId) {
                    self.userMuteMap[user.userId] = true
                }
                self.anchorSeatList[index].seatUser = userdic[seatInfo.userId]
            }
            self.viewResponder?.refreshAnchorInfos()
            self.viewResponder?.onAnchorMute(isMute: false)
        }
    }
    
    func onAnchorEnterSeat(index: Int, user: VoiceRoomUserInfo) {
        if index == 0{
            // 房主上麦就不提醒了
            return;
        }
        showNotifyMsg(messsage: LocalizeReplace(.beyySeatText, "xxx", String(index)), userName: user.userName)
        if user.userId == dependencyContainer.userId {
            roomType = .anchor
            mSelfSeatIndex = index
            // 自己上麦，恢复音效设置
            viewResponder?.recoveryVoiceSetting()
            // 当前麦位禁言状态
            let seatMute = getUserSeatInfo(userId: user.userId)?.seatInfo?.mute ?? false
            if seatMute {
                isSelfMute = true
            }
            let mute = isSelfMute || seatMute
            // 更新静音UI状态
            viewResponder?.onAnchorMute(isMute: mute)
            viewResponder?.onSeatMute(isMute: mute)
        }
        
        changeAudience(status: AudienceInfoModel.TYPE_IN_SEAT, user: user)
    }
    
    func onAnchorLeaveSeat(index: Int, user: VoiceRoomUserInfo) {
        if index == 0{
            // 房主下麦就不提醒了
            return;
        }
        showNotifyMsg(messsage: LocalizeReplace(.audienceyySeatText, "xxx", String(index)), userName: user.userName)
        if user.userId == dependencyContainer.userId {
            let currentSeatInfo = isInSeat(userId: user.userId)
            if currentSeatInfo.inSeat {
                // 移麦场景: 下麦为当前用户，且当前用户还在麦位上，
                return
            }
            // 身份切换
            roomType = .audience
            // 自己下麦，停止音效播放
            viewResponder?.stopPlayBGM()
            // 重置麦位相关设置数据
            resetSelfDatasOnSeatLeave()
        }
        if !memberAudienceDic.keys.contains(user.userId) {
            for model in memberAudienceList {
                if model.userInfo.userId == user.userId {
                    memberAudienceDic[user.userId] = model
                    break
                }
            }
        }
        changeAudience(status: AudienceInfoModel.TYPE_IDEL, user: user)
    }
    
    func onSeatMute(index: Int, isMute: Bool) {
        debugPrint("seat \(index) is mute : \(isMute ? "true" : "false")")
        if isMute {
            showNotifyMsg(messsage: LocalizeReplaceXX(.bemutedxxText, String(index)), userName: "")
        } else {
            showNotifyMsg(messsage: LocalizeReplaceXX(.beunmutedxxText, String(index)), userName: "")
        }
        if index > 0 && index <= anchorSeatList.count {
            anchorSeatList[index-1].seatInfo?.mute = isMute
        }
        if let userSeatInfo = getUserSeatInfo(userId: dependencyContainer.userId), userSeatInfo.seatIndex == index {
            // 更新当前用户麦位禁言状态
            userSeatInfo.seatInfo?.mute = isMute
            if isMute {
                // 禁言状态，更新本地静音状态
                isSelfMute = true
            }
            let userMute = isMute || isSelfMute
            viewResponder?.onSeatMute(isMute: userMute)
        }
        viewResponder?.onAnchorMute(isMute: isMute)
    }
    
    func onUserMicrophoneMute(userId: String, mute: Bool) {
        if dependencyContainer.userId == userId {
            // 更新本地麦克风静音状态
            isSelfMute = mute
        }
        userMuteMap[userId] = mute
        viewResponder?.onAnchorMute(isMute: mute)
    }
    
    func onSeatClose(index: Int, isClose: Bool) {
        showNotifyMsg(messsage: LocalizeReplace(.ownerxxSeatText, isClose ? .banSeatText : .unmuteOneText, String(index)), userName: "")
        if isClose {
            // 麦位关闭下麦, 相关设置初始化。
            // 1. mSelfSeatIndex == index 当前用户在麦位, 且麦位被关闭被下麦
            // 2. mSelfSeatIndex == -1    当前用户不在麦位，再初始化一次数据
            if mSelfSeatIndex == index || mSelfSeatIndex == -1{
                // 重置麦位相关设置数据
                resetSelfDatasOnSeatLeave()
            }
        }
    }
    
    func onAudienceEnter(userInfo: VoiceRoomUserInfo) {
        showNotifyMsg(messsage: LocalizeReplaceXX(.inRoomText, "xxx"), userName: userInfo.userName)
        // 主播端(房主)
        let memberEntityModel = AudienceInfoModel.init(type: 0, userInfo: userInfo) { [weak self] (index) in
            guard let `self` = self else { return }
            if index == 0 {
                self.sendInvitation(userInfo: userInfo)
            } else {
                self.acceptTakeSeatInvitation(userInfo: userInfo)
                self.viewResponder?.audiceneList(show: false)
            }
        }
        if !memberAudienceDic.keys.contains(userInfo.userId) {
            memberAudienceDic[userInfo.userId] = memberEntityModel
            // 避免重复添加
            memberAudienceList.removeAll(where: {$0.userInfo.userId == userInfo.userId})
            memberAudienceList.append(memberEntityModel)
        }
        viewResponder?.audienceListRefresh()
        changeAudience(status: AudienceInfoModel.TYPE_IDEL, user: userInfo)
    }
    
    func onAudienceExit(userInfo: VoiceRoomUserInfo) {
        showNotifyMsg(messsage: LocalizeReplaceXX(.exitRoomText, "xxx"), userName: userInfo.userName)
        memberAudienceList.removeAll { (model) -> Bool in
            return model.userInfo.userId == userInfo.userId
        }
        memberAudienceDic.removeValue(forKey: userInfo.userId)
        viewResponder?.refreshAnchorInfos()
        viewResponder?.audienceListRefresh()
        changeAudience(status: AudienceInfoModel.TYPE_IDEL, user: userInfo)
    }
    
    func onUserVolumeUpdate(userVolumes: [TRTCVolumeInfo], totalVolume: Int) {
        var volumeDic: [String: UInt] = [:]
        userVolumes.forEach { (info) in
            if let userId = info.userId {
                volumeDic[userId] = info.volume
            } else {
                volumeDic[dependencyContainer.userId] = info.volume
            }
        }
        var needRefreshUI = false
        if let master = masterAnchor, let userId = master.seatUser?.userId {
            let newIsTalking = (volumeDic[userId] ?? 0) > 25
            if master.isTalking != newIsTalking {
                masterAnchor?.isTalking = newIsTalking
                needRefreshUI = true
            }
        }
        
        for (index, seat) in self.anchorSeatList.enumerated() {
            if let user = seat.seatUser {
                let isTalking = (volumeDic[user.userId] ?? 0) > 25
                if seat.isTalking != isTalking {
                    self.anchorSeatList[index].isTalking = isTalking
                    needRefreshUI = true
                }
            }
        }
        
        if needRefreshUI {
            viewResponder?.refreshAnchorInfos()
        }
    }
    
    func onRecvRoomTextMsg(message: String, userInfo: VoiceRoomUserInfo) {
        let msgEntity = MsgEntity.init(userId: userInfo.userId,
                                       userName: userInfo.userName,
                                       content: message,
                                       invitedId: "",
                                       type: MsgEntity.TYPE_NORMAL)
        notifyMsg(entity: msgEntity)
    }
    
    func onRecvRoomCustomMsg(cmd: String, message: String, userInfo: VoiceRoomUserInfo) {
        
    }
    
    func onReceiveNewInvitation(identifier: String, inviter: String, cmd: String, content: String) {
        TRTCLog.out("receive message: \(cmd) : \(content)")
        if roomType == .audience {
            if cmd == VoiceRoomConstants.CMD_PICK_UP_SEAT {
                recvPickSeat(identifier: identifier, cmd: cmd, content: content)
            }
        }
        if roomType == .anchor && roomInfo.ownerId == dependencyContainer.userId {
            if cmd == VoiceRoomConstants.CMD_REQUEST_TAKE_SEAT {
                recvTakeSeat(identifier: identifier, inviter: inviter, content: content)
            }
        }
    }
    
    func onInviteeAccepted(identifier: String, invitee: String) {
        
        let seatIndexInfo = mInvitationSeatDic.removeValue(forKey: identifier)
        if let seatIndex = seatIndexInfo {
            guard let seatModel = anchorSeatList.filter({ (seatInfo) -> Bool in
                return seatInfo.seatIndex == seatIndex
            }).first else {
                return
            }
            if !seatModel.isUsed {
                // 显示Loading指示框， 回调结束消失
                self.viewResponder?.showToastActivity()
                if roomType == .audience {
                    // 接受上麦邀请
                    voiceRoom.enterSeat(seatIndex: seatIndex) { [weak self] (code, message) in
                        guard let `self` = self else { return }
                        // 隐藏loading指示框
                        self.viewResponder?.hiddenToastActivity()
                        if code == 0 {
                            self.viewResponder?.showToast(message: .handsupSuccessText)
                        } else {
                            self.viewResponder?.showToast(message: .handsupFailedText)
                        }
                    }
                } else if roomType == .anchor  {
                    // 接受移麦邀请
                    voiceRoom.moveSeat(seatIndex: seatIndex) { [weak self] (code, message) in
                        guard let `self` = self else { return }
                        // 隐藏loading指示框
                        self.viewResponder?.hiddenToastActivity()
                        if code == 0 {
                            self.viewResponder?.showToast(message: .handsupSuccessText)
                        } else {
                            self.viewResponder?.showToast(message: .handsupFailedText)
                        }
                    }
                }
            }
        }
        if roomType == .anchor && roomInfo.ownerId == dependencyContainer.userId{
            guard let seatInvitation = mPickSeatInvitationDic.removeValue(forKey: identifier) else {
                return
            }
            guard let seatModel = anchorSeatList.filter({ (model) -> Bool in
                return model.seatIndex == seatInvitation.seatIndex
            }).first else {
                return
            }
            if !seatModel.isUsed {
                voiceRoom.pickSeat(seatIndex: seatInvitation.seatIndex, userId: seatInvitation.inviteUserId) { [weak self] (code, message) in
                    guard let `self` = self else { return }
                    if code == 0 {
                        guard let audience = self.memberAudienceDic[seatInvitation.inviteUserId] else { return }
                        self.viewResponder?.showToast(message: LocalizeReplaceXX(.hugHandsupSuccessText, audience.userInfo.userName))
                    }
                }
            }
        }
    }
    
    func onInviteeRejected(identifier: String, invitee: String) {
        if let seatInvitation = mPickSeatInvitationDic.removeValue(forKey: identifier) {
            guard let audience = memberAudienceDic[seatInvitation.inviteUserId] else { return }
            viewResponder?.showToast(message: LocalizeReplaceXX(.refuseBespeakerText, audience.userInfo.userName))
            changeAudience(status: AudienceInfoModel.TYPE_IDEL, user: audience.userInfo)
        }
        
    }
    
    func onInvitationCancelled(identifier: String, invitee: String) {
        
    }
}

// MARK: - internationalization string
fileprivate extension String {
    static let seatmutedText = VoiceRoomLocalize("Demo.TRTC.VoiceRoom.onseatmuted")
    static let micmutedText = VoiceRoomLocalize("Demo.TRTC.Salon.micmuted")
    static let micunmutedText = VoiceRoomLocalize("Demo.TRTC.Salon.micunmuted")
    static let mutedText = VoiceRoomLocalize("Demo.TRTC.VoiceRoom.ismuted")
    static let unmutedText = VoiceRoomLocalize("Demo.TRTC.VoiceRoom.isunmuted")
    static let seatuninitText = VoiceRoomLocalize("Demo.TRTC.Salon.seatlistnotinit")
    static let enterSuccessText = VoiceRoomLocalize("Demo.TRTC.Salon.enterroomsuccess")
    static let enterFailedText = VoiceRoomLocalize("Demo.TRTC.Salon.enterroomfailed")
    static let createRoomFailedText = VoiceRoomLocalize("Demo.TRTC.LiveRoom.createroomfailed")
    static let meText = VoiceRoomLocalize("Demo.TRTC.LiveRoom.me")
    static let sendSuccessText = VoiceRoomLocalize("Demo.TRTC.VoiceRoom.sendsuccess")
    static let sendFailedText = VoiceRoomLocalize("Demo.TRTC.VoiceRoom.sendfailedxx")
    static let cupySeatSuccessText = VoiceRoomLocalize("Demo.TRTC.Salon.hostoccupyseatsuccess")
    static let cupySeatFailedText = VoiceRoomLocalize("Demo.TRTC.Salon.hostoccupyseatfailed")
    static let onlyAnchorOperationText = VoiceRoomLocalize("Demo.TRTC.VoiceRoom.onlyanchorcanoperation")
    static let seatLockedText = VoiceRoomLocalize("Demo.TRTC.VoiceRoom.seatislockedandcanthandup")
    static let audienceText = VoiceRoomLocalize("Demo.TRTC.Salon.audience")
    static let otherAnchorText = VoiceRoomLocalize("Demo.TRTC.VoiceRoom.otheranchor")
    static let isInxxSeatText = VoiceRoomLocalize("Demo.TRTC.VoiceRoom.isinxxseat")
    static let notInitText = VoiceRoomLocalize("Demo.TRTC.VoiceRoom.seatisnotinittocanthandsup")
    static let handsupText = VoiceRoomLocalize("Demo.TRTC.Salon.handsup")
    static let moveSeatText = VoiceRoomLocalize("Demo.TRTC.VoiceRoom.requestmoveseat")
    static let totaxxText = VoiceRoomLocalize("Demo.TRTC.VoiceRoom.totaxx")
    static let unmuteOneText = VoiceRoomLocalize("Demo.TRTC.VoiceRoom.unmuteone")
    static let muteOneText = VoiceRoomLocalize("Demo.TRTC.VoiceRoom.muteone")
    static let makeAudienceText = VoiceRoomLocalize("Demo.TRTC.VoiceRoom.makeoneaudience")
    static let inviteHandsupText = VoiceRoomLocalize("Demo.TRTC.VoiceRoom.invitehandsup")
    static let banSeatText = VoiceRoomLocalize("Demo.TRTC.VoiceRoom.banseat")
    static let liftbanSeatText = VoiceRoomLocalize("Demo.TRTC.VoiceRoom.liftbanseat")
    static let seatBusyText = VoiceRoomLocalize("Demo.TRTC.VoiceRoom.seatisbusy")
    static let sendInviteSuccessText = VoiceRoomLocalize("Demo.TRTC.VoiceRoom.sendinvitesuccess")
    static let reqExpiredText = VoiceRoomLocalize("Demo.TRTC.Salon.reqisexpired")
    static let acceptReqFailedText = VoiceRoomLocalize("Demo.TRTC.Salon.acceptreqfailed")
    static let audienceSuccessText = VoiceRoomLocalize("Demo.TRTC.Salon.audiencesuccess")
    static let audienceFailedxxText = VoiceRoomLocalize("Demo.TRTC.Salon.audiencefailedxx")
    static let beingArchonText = VoiceRoomLocalize("Demo.TRTC.Salon.isbeingarchon")
    static let roomNotReadyText = VoiceRoomLocalize("Demo.TRTC.Salon.roomnotready")
    static let reqSentText = VoiceRoomLocalize("Demo.TRTC.VoiceRoom.reqsentandwaitforarchondeal")
    static let reqSendFailedxxText = VoiceRoomLocalize("Demo.TRTC.VoiceRoom.reqsendfailedxx")
    static let handsupSuccessText = VoiceRoomLocalize("Demo.TRTC.Salon.successbecomespaker")
    static let handsupFailedText = VoiceRoomLocalize("Demo.TRTC.Salon.failedbecomespaker")
    
    static let alertText = VoiceRoomLocalize("Demo.TRTC.LiveRoom.prompt")
    static let invitexxSeatText = VoiceRoomLocalize("Demo.TRTC.VoiceRoom.anchorinvitexxseat")
    static let refuseHandsupText = VoiceRoomLocalize("Demo.TRTC.VoiceRoom.refusehandsupreq")
    static let applyxxSeatText = VoiceRoomLocalize("Demo.TRTC.VoiceRoom.applyforxxseat")
    static let closeRoomText = VoiceRoomLocalize("Demo.TRTC.Salon.archonclosedroom")
    static let seatlistWrongText = VoiceRoomLocalize("Demo.TRTC.VoiceRoom.seatlistwentwrong")
    static let beyySeatText = VoiceRoomLocalize("Demo.TRTC.VoiceRoom.xxbeyyseat")
    static let audienceyySeatText = VoiceRoomLocalize("Demo.TRTC.VoiceRoom.xxaudienceyyseat")
    static let bemutedxxText = VoiceRoomLocalize("Demo.TRTC.VoiceRoom.xxisbemuted")
    static let beunmutedxxText = VoiceRoomLocalize("Demo.TRTC.VoiceRoom.xxisbeunmuted")
    static let ownerxxSeatText = VoiceRoomLocalize("Demo.TRTC.VoiceRoom.ownerxxyyseat")
    static let banText = VoiceRoomLocalize("Demo.TRTC.VoiceRoom.ban")
    static let inRoomText = VoiceRoomLocalize("Demo.TRTC.LiveRoom.xxinroom")
    static let exitRoomText = VoiceRoomLocalize("Demo.TRTC.VoiceRoom.xxexitroom")
    static let hugHandsupSuccessText = VoiceRoomLocalize("Demo.TRTC.VoiceRoom.hugxxhandsupsuccess")
    static let refuseBespeakerText = VoiceRoomLocalize("Demo.TRTC.VoiceRoom.refusebespeaker")
}
