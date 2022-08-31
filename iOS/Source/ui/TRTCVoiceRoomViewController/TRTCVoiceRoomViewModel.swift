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
    func stopPlayBGM()
    func recoveryVoiceSetting()
    func showBgMusicAlert()
    func showMoreAlert()
    func showAudienceAlert(seat: SeatInfoModel)
    func showConnectTimeoutAlert()
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
            // Sync the muting status of the local `userMuteMap` user
            userMuteMap[dependencyContainer.userId] = isSelfMute
        }
    }
    // Prevent multiple room exits
    private var isExitingRoom: Bool = false
    
    private(set) var roomInfo: VoiceRoomInfo
    private(set) var isSeatInitSuccess: Bool = false
    private(set) var mSelfSeatIndex: Int = -1
    
    private(set) var masterAnchor: SeatInfoModel?
    private(set) var anchorSeatList: [SeatInfoModel] = []
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
    /// Seat for invitation
    private var currentInvitateSeatIndex: Int = -1
    /// Mic-on information (audience member))
    private var mInvitationSeatDic: [String: Int] = [:]
    /// Mic-on information (anchor)
    private var mTakeSeatInvitationDic: [String: String] = [:]
    /// Information of user seat placement
    private var mPickSeatInvitationDic: [String: SeatInvitation] = [:]
    
    public var userMuteMap : [String : Bool] = [:]
    
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
        let entity = MsgEntity.init(userId: dependencyContainer.userId, userName: .meText, content: message, invitedId: "", type: MsgEntity.TYPE_NORMAL)
        notifyMsg(entity: entity)
        voiceRoom.sendRoomTextMsg(message: message) { [weak self] (code, message) in
            guard let `self` = self else { return }
            self.viewResponder?.showToast(message: code == 0 ? .sendSuccessText :  localizeReplaceXX(.sendFailedText, message))
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
                        // Event of clicking to send mic-on invitation and invitation acceptance event
                        guard let `self` = self else { return }
                        if index == 0 {
                            self.sendInvitation(userInfo: userInfo)
                        } else {
                            self.acceptTakeSeatInvitation(userInfo: userInfo)
                        }
                    }
                }
                self.memberAudienceList.removeAll()
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
                // The seat is used by yourself
            } else {
                // The seat is used by another user
                viewResponder?.showToast(message: "\(model.seatUser?.userName ?? .otherAnchorText)")
            }
        } else {
            // Check whether the current user is in a seat
            let currentSeatInfo = isInSeat(userId: dependencyContainer.userId)
            if currentSeatInfo.inSeat {
                // The user is already in a seat
                if currentSeatInfo.seatIndex == model.seatIndex {
                    viewResponder?.showToast(message: localizeReplaceXX(.isInxxSeatText, String(currentSeatInfo.seatIndex)))
                    return
                }
                // The user is already in a seat and needs to apply to move to another seat
                viewResponder?.showActionSheet(actionTitles: [.moveSeatText], actions: { [weak self] (index) in
                    guard let `self` = self else { return }
                    self.startMoveToSeat(targetIndex: model.seatIndex)
                })
            } else {
                // The user is not in a seat and requests to speak
                viewResponder?.showActionSheet(actionTitles: [.handsupText], actions: { [weak self] (index) in
                    guard let `self` = self else { return }
                    self.startTakeSeat(seatIndex: model.seatIndex)
                })
            }
        }
    }
    
    private func anchorClickItem(model: SeatInfoModel) {
        if model.isUsed {
            let isMute = model.seatInfo?.mute ?? false
            viewResponder?.showActionSheet(actionTitles: [localizeReplaceXX(.totaxxText, (isMute ? String.unmuteOneText : String.muteOneText)), .makeAudienceText], actions: { [weak self] (index) in
                guard let `self` = self else { return }
                if index == 0 {
                    // Mute
                    self.voiceRoom.muteSeat(seatIndex: model.seatIndex, isMute: !isMute, callback: nil)
                } else {
                    // Mic off
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
        // Invite
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
        // Agree
        guard let inviteID = mTakeSeatInvitationDic[userInfo.userId] else {
            viewResponder?.showToast(message: .reqExpiredText)
            return
        }
        voiceRoom.acceptInvitation(identifier: inviteID) { [weak self] (code, message) in
            guard let `self` = self else { return }
            if code == 0 {
                // The request is accepted. Update the external chat list
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
                self.viewResponder?.showToast(message: localizeReplaceXX(.audienceFailedxxText, message))
            }
        }
    }
    
    private func startTakeSeat(seatIndex: Int) {
        if roomType == .anchor {
            viewResponder?.showToast(message: .beingArchonText)
            return
        }
        if roomInfo.needRequest {
            // A request to speak is required
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
                    self.viewResponder?.showToast(message: localizeReplaceXX(.reqSendFailedxxText, message))
                }
            }
            mInvitationSeatDic[inviteId] = seatIndex
        } else {
            self.viewResponder?.showToastActivity()
            // Directly mic on when a mic-on request is not required
            voiceRoom.enterSeat(seatIndex: seatIndex) { [weak self] (code, message) in
                guard let `self` = self else { return }
                self.viewResponder?.hiddenToastActivity()
                if code == 0 {
                    self.viewResponder?.showToast(message: .handsupSuccessText)
                } else {
                    self.viewResponder?.showToast(message: .handsupFailedText)
                }
            }
        }
    }
    
    private func startMoveToSeat(targetIndex: Int) {
        if roomInfo.needRequest {
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
                    self.viewResponder?.showToast(message: localizeReplaceXX(.reqSendFailedxxText, message))
                }
            }
            mInvitationSeatDic[inviteId] = targetIndex
        } else {
            self.viewResponder?.showToastActivity()
            // Directly move to a different seat when a request to speak is not required
            voiceRoom.moveSeat(seatIndex: targetIndex) { [weak self](code, message) in
                guard let `self` = self else { return }
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
        viewResponder?.showAlert(info: (title: .alertText, message: localizeReplaceXX(.invitexxSeatText, String(seatIndex))), sureAction: { [weak self] in
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
        if let index = msgEntityList.firstIndex(where: { (msg) -> Bool in
            return msg.userId == inviter && msg.type == MsgEntity.TYPE_WAIT_AGREE
        }) {
            var msg = msgEntityList[index]
            msg.type = MsgEntity.TYPE_AGREED
            msgEntityList[index] = msg
        }
        let audinece = memberAudienceDic[inviter]
        let seatIndex = (Int.init(content) ?? 0)
        let content = localizeReplaceXX(.applyxxSeatText, String(seatIndex))
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
    
    private func resetSelfDatasOnSeatLeave() {
        mSelfSeatIndex = -1
        isSelfMute = false
        if voiceEarMonitor {
            voiceEarMonitor = false
        }
    }
    
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
        if code == gERR_CONNECT_SERVICE_TIMEOUT {
            viewResponder?.showConnectTimeoutAlert()
        }
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
#if RTCube_APPSTORE
        guard isOwner else { return }
        let selector = NSSelectorFromString("showAlertUserLiveTimeOut")
        if UIViewController.responds(to: selector) {
            UIViewController.perform(selector)
        }
#endif
    }
    
    func onRoomInfoChange(roomInfo: VoiceRoomInfo) {
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
                anchorSeatInfo.seatInfo?.mute = seatInfo.mute
            }
            else {
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
                    let anchorSeatModel = anchorSeatList[listIndex]
                    anchorSeatInfo.seatUser = anchorSeatModel.seatUser
                    if !anchorSeatInfo.isUsed {
                        anchorSeatInfo.seatUser = nil
                    }
                    anchorSeatList[listIndex] = anchorSeatInfo
                } else {
                    anchorSeatList.append(anchorSeatInfo)
                }
            }
        }
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
            for index in 0..<self.anchorSeatList.count {
                let seatInfo = seatInfoList[index + 1]
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
            return;
        }
        showNotifyMsg(messsage: localizeReplace(.beyySeatText, "xxx", String(index)), userName: user.userName)
        if user.userId == dependencyContainer.userId {
            roomType = .anchor
            mSelfSeatIndex = index
            viewResponder?.recoveryVoiceSetting()
            let seatMute = getUserSeatInfo(userId: user.userId)?.seatInfo?.mute ?? false
            if seatMute {
                isSelfMute = true
            }
            let mute = isSelfMute || seatMute
            viewResponder?.onAnchorMute(isMute: mute)
            viewResponder?.onSeatMute(isMute: mute)
        }
        
        changeAudience(status: AudienceInfoModel.TYPE_IN_SEAT, user: user)
    }
    
    func onAnchorLeaveSeat(index: Int, user: VoiceRoomUserInfo) {
        if index == 0{
            return;
        }
        showNotifyMsg(messsage: localizeReplace(.audienceyySeatText, "xxx", String(index)), userName: user.userName)
        if user.userId == dependencyContainer.userId {
            let currentSeatInfo = isInSeat(userId: user.userId)
            if currentSeatInfo.inSeat {
                return
            }
            // 身份切换
            roomType = .audience
            viewResponder?.stopPlayBGM()
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
            showNotifyMsg(messsage: localizeReplaceXX(.bemutedxxText, String(index)), userName: "")
        } else {
            showNotifyMsg(messsage: localizeReplaceXX(.beunmutedxxText, String(index)), userName: "")
        }
        if index > 0 && index <= anchorSeatList.count {
            anchorSeatList[index-1].seatInfo?.mute = isMute
        }
        if let userSeatInfo = getUserSeatInfo(userId: dependencyContainer.userId), userSeatInfo.seatIndex == index {
            userSeatInfo.seatInfo?.mute = isMute
            if isMute {
                isSelfMute = true
            }
            let userMute = isMute || isSelfMute
            viewResponder?.onSeatMute(isMute: userMute)
        }
        viewResponder?.onAnchorMute(isMute: isMute)
    }
    
    func onUserMicrophoneMute(userId: String, mute: Bool) {
        if dependencyContainer.userId == userId {
            isSelfMute = mute
        }
        userMuteMap[userId] = mute
        viewResponder?.onAnchorMute(isMute: mute)
    }
    
    func onSeatClose(index: Int, isClose: Bool) {
        showNotifyMsg(messsage: localizeReplace(.ownerxxSeatText, isClose ? .banSeatText : .unmuteOneText, String(index)), userName: "")
        if isClose {
            // Disable the seat, mic off, and initialize the relevant settings
            // 1. mSelfSeatIndex == index The current user is in a seat. The user’s mic is turned off and the user is removed from the seat
            // 2. mSelfSeatIndex == -1 The current user is not in a seat. Initialize the data again
            if mSelfSeatIndex == index || mSelfSeatIndex == -1{
                // Reset seat configuration data
                resetSelfDatasOnSeatLeave()
            }
        }
    }
    
    func onAudienceEnter(userInfo: VoiceRoomUserInfo) {
        showNotifyMsg(messsage: localizeReplaceXX(.inRoomText, "xxx"), userName: userInfo.userName)
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
            memberAudienceList.removeAll(where: {$0.userInfo.userId == userInfo.userId})
            memberAudienceList.append(memberEntityModel)
        }
        viewResponder?.audienceListRefresh()
        changeAudience(status: AudienceInfoModel.TYPE_IDEL, user: userInfo)
    }
    
    func onAudienceExit(userInfo: VoiceRoomUserInfo) {
        showNotifyMsg(messsage: localizeReplaceXX(.exitRoomText, "xxx"), userName: userInfo.userName)
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
                self.viewResponder?.showToastActivity()
                if roomType == .audience {
                    voiceRoom.enterSeat(seatIndex: seatIndex) { [weak self] (code, message) in
                        guard let `self` = self else { return }
                        self.viewResponder?.hiddenToastActivity()
                        if code == 0 {
                            self.viewResponder?.showToast(message: .handsupSuccessText)
                        } else {
                            self.viewResponder?.showToast(message: .handsupFailedText)
                        }
                    }
                } else if roomType == .anchor  {
                    voiceRoom.moveSeat(seatIndex: seatIndex) { [weak self] (code, message) in
                        guard let `self` = self else { return }
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
                        self.viewResponder?.showToast(message: localizeReplaceXX(.hugHandsupSuccessText, audience.userInfo.userName))
                    }
                }
            }
        }
    }
    
    func onInviteeRejected(identifier: String, invitee: String) {
        if let seatInvitation = mPickSeatInvitationDic.removeValue(forKey: identifier) {
            guard let audience = memberAudienceDic[seatInvitation.inviteUserId] else { return }
            viewResponder?.showToast(message: localizeReplaceXX(.refuseBespeakerText, audience.userInfo.userName))
            changeAudience(status: AudienceInfoModel.TYPE_IDEL, user: audience.userInfo)
        }
        
    }
    
    func onInvitationCancelled(identifier: String, invitee: String) {
        
    }
}

// MARK: - internationalization string
fileprivate extension String {
    static let seatmutedText = voiceRoomLocalize("Demo.TRTC.VoiceRoom.onseatmuted")
    static let micmutedText = voiceRoomLocalize("Demo.TRTC.Salon.micmuted")
    static let micunmutedText = voiceRoomLocalize("Demo.TRTC.Salon.micunmuted")
    static let mutedText = voiceRoomLocalize("Demo.TRTC.VoiceRoom.ismuted")
    static let unmutedText = voiceRoomLocalize("Demo.TRTC.VoiceRoom.isunmuted")
    static let seatuninitText = voiceRoomLocalize("Demo.TRTC.Salon.seatlistnotinit")
    static let enterSuccessText = voiceRoomLocalize("Demo.TRTC.Salon.enterroomsuccess")
    static let enterFailedText = voiceRoomLocalize("Demo.TRTC.Salon.enterroomfailed")
    static let createRoomFailedText = voiceRoomLocalize("Demo.TRTC.LiveRoom.createroomfailed")
    static let meText = voiceRoomLocalize("Demo.TRTC.LiveRoom.me")
    static let sendSuccessText = voiceRoomLocalize("Demo.TRTC.VoiceRoom.sendsuccess")
    static let sendFailedText = voiceRoomLocalize("Demo.TRTC.VoiceRoom.sendfailedxx")
    static let cupySeatSuccessText = voiceRoomLocalize("Demo.TRTC.Salon.hostoccupyseatsuccess")
    static let cupySeatFailedText = voiceRoomLocalize("Demo.TRTC.Salon.hostoccupyseatfailed")
    static let onlyAnchorOperationText = voiceRoomLocalize("Demo.TRTC.VoiceRoom.onlyanchorcanoperation")
    static let seatLockedText = voiceRoomLocalize("Demo.TRTC.VoiceRoom.seatislockedandcanthandup")
    static let audienceText = voiceRoomLocalize("Demo.TRTC.Salon.audience")
    static let otherAnchorText = voiceRoomLocalize("Demo.TRTC.VoiceRoom.otheranchor")
    static let isInxxSeatText = voiceRoomLocalize("Demo.TRTC.VoiceRoom.isinxxseat")
    static let notInitText = voiceRoomLocalize("Demo.TRTC.VoiceRoom.seatisnotinittocanthandsup")
    static let handsupText = voiceRoomLocalize("Demo.TRTC.Salon.handsup")
    static let moveSeatText = voiceRoomLocalize("Demo.TRTC.VoiceRoom.requestmoveseat")
    static let totaxxText = voiceRoomLocalize("Demo.TRTC.VoiceRoom.totaxx")
    static let unmuteOneText = voiceRoomLocalize("Demo.TRTC.VoiceRoom.unmuteone")
    static let muteOneText = voiceRoomLocalize("Demo.TRTC.VoiceRoom.muteone")
    static let makeAudienceText = voiceRoomLocalize("Demo.TRTC.VoiceRoom.makeoneaudience")
    static let inviteHandsupText = voiceRoomLocalize("Demo.TRTC.VoiceRoom.invitehandsup")
    static let banSeatText = voiceRoomLocalize("Demo.TRTC.VoiceRoom.banseat")
    static let liftbanSeatText = voiceRoomLocalize("Demo.TRTC.VoiceRoom.liftbanseat")
    static let seatBusyText = voiceRoomLocalize("Demo.TRTC.VoiceRoom.seatisbusy")
    static let sendInviteSuccessText = voiceRoomLocalize("Demo.TRTC.VoiceRoom.sendinvitesuccess")
    static let reqExpiredText = voiceRoomLocalize("Demo.TRTC.Salon.reqisexpired")
    static let acceptReqFailedText = voiceRoomLocalize("Demo.TRTC.Salon.acceptreqfailed")
    static let audienceSuccessText = voiceRoomLocalize("Demo.TRTC.Salon.audiencesuccess")
    static let audienceFailedxxText = voiceRoomLocalize("Demo.TRTC.Salon.audiencefailedxx")
    static let beingArchonText = voiceRoomLocalize("Demo.TRTC.Salon.isbeingarchon")
    static let roomNotReadyText = voiceRoomLocalize("Demo.TRTC.Salon.roomnotready")
    static let reqSentText = voiceRoomLocalize("Demo.TRTC.VoiceRoom.reqsentandwaitforarchondeal")
    static let reqSendFailedxxText = voiceRoomLocalize("Demo.TRTC.VoiceRoom.reqsendfailedxx")
    static let handsupSuccessText = voiceRoomLocalize("Demo.TRTC.Salon.successbecomespaker")
    static let handsupFailedText = voiceRoomLocalize("Demo.TRTC.Salon.failedbecomespaker")
    
    static let alertText = voiceRoomLocalize("Demo.TRTC.LiveRoom.prompt")
    static let invitexxSeatText = voiceRoomLocalize("Demo.TRTC.VoiceRoom.anchorinvitexxseat")
    static let refuseHandsupText = voiceRoomLocalize("Demo.TRTC.VoiceRoom.refusehandsupreq")
    static let applyxxSeatText = voiceRoomLocalize("Demo.TRTC.VoiceRoom.applyforxxseat")
    static let closeRoomText = voiceRoomLocalize("Demo.TRTC.Salon.archonclosedroom")
    static let seatlistWrongText = voiceRoomLocalize("Demo.TRTC.VoiceRoom.seatlistwentwrong")
    static let beyySeatText = voiceRoomLocalize("Demo.TRTC.VoiceRoom.xxbeyyseat")
    static let audienceyySeatText = voiceRoomLocalize("Demo.TRTC.VoiceRoom.xxaudienceyyseat")
    static let bemutedxxText = voiceRoomLocalize("Demo.TRTC.VoiceRoom.xxisbemuted")
    static let beunmutedxxText = voiceRoomLocalize("Demo.TRTC.VoiceRoom.xxisbeunmuted")
    static let ownerxxSeatText = voiceRoomLocalize("Demo.TRTC.VoiceRoom.ownerxxyyseat")
    static let banText = voiceRoomLocalize("Demo.TRTC.VoiceRoom.ban")
    static let inRoomText = voiceRoomLocalize("Demo.TRTC.LiveRoom.xxinroom")
    static let exitRoomText = voiceRoomLocalize("Demo.TRTC.VoiceRoom.xxexitroom")
    static let hugHandsupSuccessText = voiceRoomLocalize("Demo.TRTC.VoiceRoom.hugxxhandsupsuccess")
    static let refuseBespeakerText = voiceRoomLocalize("Demo.TRTC.VoiceRoom.refusebespeaker")
}
