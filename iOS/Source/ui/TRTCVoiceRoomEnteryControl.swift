//
//  TRTCVoiceRoomEnteryControl.swift
//  TRTCVoiceRoomDemo
//
//  Created by abyyxwang on 2020/6/3.
//  Copyright © 2020 tencent. All rights reserved.
//

import UIKit

public protocol TRTCVoiceRoomEnteryControlDelegate: NSObject {
    func voiceRoomCreateRoom(roomId: String, success: @escaping () -> Void, failed: @escaping (Int32, String) -> Void)
    func voiceRoomDestroyRoom(roomId: String, success: @escaping () -> Void, failed: @escaping (Int32, String) -> Void)
}

public class TRTCVoiceRoomEnteryControl: NSObject {
    public private(set) var mSDKAppID: Int32 = 0
    public private(set) var userId: String = ""
    
    public weak var delegate: TRTCVoiceRoomEnteryControlDelegate?
    
    @objc public convenience init(sdkAppId:Int32, userId: String) {
        self.init()
        self.mSDKAppID = sdkAppId
        self.userId = userId
    }
    
    deinit {
        TRTCLog.out("deinit \(type(of: self))")
    }
    
    /*
     `TRTCVoice` is a terminatable singleton.
     In the demo, a singleton object can be obtained or generated through `shardInstance` (OC) or `shared` (Swift)
     After terminating the singleton object, you need to call the `sharedInstance` API again to generate the instance again.
     This method is called in `VoiceRoomListRoomViewModel`, `CreateVoiceRoomViewModel`, and `VoiceRoomViewModel`
     Since it is a terminatable singleton, the purpose of generating and placing the object here is to manage the singleton generation path in a unified way and facilitate maintenance
     */
    private var voiceRoom: TRTCVoiceRoom?

    public func getVoiceRoom() -> TRTCVoiceRoom {
        if let room = voiceRoom {
            return room
        }
        voiceRoom = TRTCVoiceRoom.shared()
        return voiceRoom!
    }
    /*
     When `VoiceRoom` is no longer needed, the singleton object can be terminated.
     For example, when you log off.
     This termination method is not called in this demo.
    */
    func clearVoiceRoom() {
        TRTCVoiceRoom.destroyShared()
        voiceRoom = nil
    }
    
    
    
    public func makeCreateVoiceRoomViewController() -> UIViewController {
         let vc =  TRTCCreateVoiceRoomViewController.init(dependencyContainer: self)
        vc.modalPresentationStyle = .fullScreen
        return vc
    }
    
    
    
    public func makeVoiceRoomViewController(roomInfo: VoiceRoomInfo, role: VoiceRoomViewType, toneQuality:VoiceRoomToneQuality = .music) -> UIViewController {
        return TRTCVoiceRoomViewController.init(viewModelFactory: self, roomInfo: roomInfo, role: role, toneQuality: toneQuality)
    }
}

extension TRTCVoiceRoomEnteryControl: TRTCVoiceRoomViewModelFactory {
    
    func makeCreateVoiceRoomViewModel() -> TRTCCreateVoiceRoomViewModel {
        return TRTCCreateVoiceRoomViewModel.init(container: self)
    }
    
    func makeVoiceRoomViewModel(roomInfo: VoiceRoomInfo, roomType: VoiceRoomViewType) -> TRTCVoiceRoomViewModel {
        return TRTCVoiceRoomViewModel.init(container: self, roomInfo: roomInfo, roomType: roomType)
    }
    
}

extension TRTCVoiceRoomEnteryControl {
    
    public func createRoom(roomID: String, success: @escaping () -> Void, failed: @escaping (Int32, String) -> Void) {
        if let delegate = self.delegate {
            delegate.voiceRoomCreateRoom(roomId: roomID, success: success, failed: failed)
        }
    }
    
    public func destroyRoom(roomID: String, success: @escaping () -> Void, failed: @escaping (Int32, String) -> Void) {
        if let delegate = self.delegate {
            delegate.voiceRoomDestroyRoom(roomId: roomID, success: success, failed: failed)
        }
    }
    
}
