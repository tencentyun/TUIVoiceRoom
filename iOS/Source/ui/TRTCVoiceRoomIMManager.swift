//
//  TRTCVoiceRoomIMManager.swift
//  Pods
//
//  Created by gg on 2021/5/26.
//  Copyright © 2022 Tencent. All rights reserved.

import Foundation
import ImSDK_Plus

public class TRTCVoiceRoomIMManager: NSObject {
    public static let shared = TRTCVoiceRoomIMManager()
    public var curUserID: String = ""
    public var curUserName: String = ""
    public var curUserAvatar: String = ""
    public var isLoaded = false
    public var SDKAPPID: Int32 = 0
    
    public func loadData() {
        curUserID = V2TIMManager.sharedInstance()?.getLoginUser() ?? ""
        V2TIMManager.sharedInstance()?.getUsersInfo([curUserID], succ: { [weak self] (infos) in
            guard let `self` = self else { return }
            guard let info = infos?.first else {
                return
            }
            self.isLoaded = true
            self.curUserName = info.nickName ?? ""
            self.curUserAvatar = info.faceURL ?? ""
        }, fail: { (code, msg) in
            
        })
    }
}
