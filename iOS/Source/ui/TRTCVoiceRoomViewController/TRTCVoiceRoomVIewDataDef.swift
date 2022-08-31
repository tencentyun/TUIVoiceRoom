//
//  TRTCVoiceRoomModelDef.swift
//  TRTCVoiceRoomDemo
//
//  Created by abyyxwang on 2020/6/15.
//  Copyright © 2020 tencent. All rights reserved.
//

import UIKit

public enum VoiceRoomViewType {
    case anchor
    case audience
}

class VoiceRoomConstants {
    public static let TYPE_VOICE_ROOM = "voiceRoom"
    public static let CMD_REQUEST_TAKE_SEAT = "takeSeat"
    public static let CMD_PICK_UP_SEAT = "pickSeat"
}

struct SeatInfoModel {
    var seatIndex: Int = -1
    var isClosed: Bool = false
    var isUsed: Bool = false
    var isOwner: Bool = false
    var seatInfo: VoiceRoomSeatInfo?
    var seatUser: VoiceRoomUserInfo?
    var action: ((Int) -> Void)?
    var isTalking: Bool = false
}

struct MsgEntity {
    public static let TYPE_NORMAL     = 0
    public static let TYPE_WAIT_AGREE = 1
    public static let TYPE_AGREED     = 2
    
    let userId: String
    let userName: String
    let content: String
    let invitedId: String
    var type: Int
}

struct AudienceInfoModel {
    
    static let TYPE_IDEL = 0
    static let TYPE_IN_SEAT = 1
    static let TYPE_WAIT_AGREE = 2
    
    var type: Int = 0
    var userInfo: VoiceRoomUserInfo
    var action: (Int) -> Void 
}

struct SeatInvitation {
    let seatIndex: Int
    let inviteUserId: String
}
