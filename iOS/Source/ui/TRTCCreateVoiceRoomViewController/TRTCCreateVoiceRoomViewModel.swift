//
//  TRTCCreateVoiceRoomViewModel.swift
//  TRTCVoiceRoomDemo
//
//  Created by abyyxwang on 2020/6/8.
//  Copyright © 2020 tencent. All rights reserved.
//

import UIKit
import ImSDK_Plus

public enum VoiceRoomRole {
    case anchor
    case audience
}

public enum VoiceRoomToneQuality: Int {
    case speech = 1
    case defaultQuality
    case music
}

protocol TRTCCreateVoiceRoomViewResponder: class {
    func push(viewController: UIViewController)
}

class TRTCCreateVoiceRoomViewModel {
    private let dependencyContainer: TRTCVoiceRoomEnteryControl
    
    public weak var viewResponder: TRTCCreateVoiceRoomViewResponder?
    
    var voiceRoom: TRTCVoiceRoom {
        return dependencyContainer.getVoiceRoom()
    }
    
    var screenShot : UIView?
    
    var roomName: String = ""
    var userName: String {
        get {
            return TRTCVoiceRoomIMManager.shared.curUserName
        }
    }
    var userID: String? {
        return V2TIMManager.sharedInstance()?.getLoginUser()
    }

    var toneQuality: VoiceRoomToneQuality = .defaultQuality
    
    init(container: TRTCVoiceRoomEnteryControl) {
        self.dependencyContainer = container
    }
    
    deinit {
        TRTCLog.out("deinit \(type(of: self))")
    }
    
    private func randomBgImageLink() -> String {
        let random = arc4random() % 12 + 1
        return "https://liteav-test-1252463788.cos.ap-guangzhou.myqcloud.com/voice_room/voice_room_cover\(random).png"
    }
    func createRoom(needRequest:Bool = true) {
        let userId = userID ?? dependencyContainer.userId
        let coverAvatar = randomBgImageLink()
        let roomId = getRoomId()
        let roomInfo = VoiceRoomInfo.init(roomID: roomId, ownerId: userId, memberCount: 9)
        roomInfo.ownerName = userName
        roomInfo.coverUrl = coverAvatar
        roomInfo.roomName = roomName
        // Whether users need to request to speak
        roomInfo.needRequest = needRequest
        let vc = self.dependencyContainer.makeVoiceRoomViewController(roomInfo:roomInfo, role: .anchor, toneQuality: self.toneQuality)
        viewResponder?.push(viewController: vc)
    }
    
    func getRoomId() -> Int {
        let userId = userID ?? dependencyContainer.userId
        let result = "\(userId)_voice_room".hash & 0x7FFFFFFF
        TRTCLog.out("hashValue:room id:\(result), userId: \(userId)")
        return result
    }
}
