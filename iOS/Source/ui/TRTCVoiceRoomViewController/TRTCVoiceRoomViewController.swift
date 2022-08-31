//
//  TRTCVoiceRoomViewController.swift
//  TRTCVoiceRoomDemo
//
//  Created by abyyxwang on 2020/6/8.
//  Copyright © 2020 tencent. All rights reserved.
//
import UIKit
import TUICore

protocol TRTCVoiceRoomViewModelFactory {
   func makeVoiceRoomViewModel(roomInfo: VoiceRoomInfo, roomType: VoiceRoomViewType) -> TRTCVoiceRoomViewModel
}

public class TRTCVoiceRoomViewController: UIViewController {
    // MARK: - properties:
    let viewModelFactory: TRTCVoiceRoomViewModelFactory
    let roomInfo: VoiceRoomInfo
    let role: VoiceRoomViewType
    var viewModel: TRTCVoiceRoomViewModel?
    let toneQuality: VoiceRoomToneQuality
    // MARK: - Methods:
    init(viewModelFactory: TRTCVoiceRoomViewModelFactory, roomInfo: VoiceRoomInfo, role: VoiceRoomViewType, toneQuality: VoiceRoomToneQuality = .music) {
        self.viewModelFactory = viewModelFactory
        self.roomInfo = roomInfo
        self.role = role
        self.toneQuality = toneQuality
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - life cycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        title = "\(roomInfo.roomName)\(roomInfo.roomID)"
        
        let backBtn = UIButton(type: .custom)
        backBtn.setImage(UIImage(named: "navigationbar_back", in: voiceRoomBundle(), compatibleWith: nil), for: .normal)
        backBtn.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        backBtn.sizeToFit()
        let backItem = UIBarButtonItem(customView: backBtn)
        self.navigationItem.leftBarButtonItem = backItem
        guard let model = viewModel else { return }
        if model.roomType == .audience {
            model.enterRoom()
        } else {
            model.createRoom(toneQuality: toneQuality.rawValue)
        }
#if RTCube_APPSTORE
        let selector = NSSelectorFromString("showAlertUserLiveTips")
        if responds(to: selector) {
            perform(selector)
        }
#endif
        TUILogin.add(self)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel?.refreshView()
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    public override func loadView() {
        // Reload view in this function
        let viewModel = viewModelFactory.makeVoiceRoomViewModel(roomInfo: roomInfo, roomType: role)
        let rootView = TRTCVoiceRoomRootView.init(viewModel: viewModel)
        rootView.rootViewController = self
        viewModel.viewResponder = rootView
        self.viewModel = viewModel
        view = rootView
    }
    
    deinit {
        TUILogin.remove(self)
        TRTCLog.out("deinit \(type(of: self))")
    }
    
    @objc func cancel() {
        if viewModel?.roomType == VoiceRoomViewType.anchor {
            presentAlert(title: .exitText, message: .sureToExitText) { [weak self] in
                guard let `self` = self else { return }
                self.viewModel?.exitRoom() // The anchor terminates the room
            }
        } else {
            self.viewModel?.exitRoom()
        }
    }
}

extension TRTCVoiceRoomViewController: TUILoginListener {
    public func onConnecting() {
        
    }
    
    public func onConnectSuccess() {
        
    }
    
    public func onConnectFailed(_ code: Int32, err: String!) {
        
    }
    
    public func onKickedOffline() {
        viewModel?.exitRoom()
    }
    
    public func onUserSigExpired() {
        
    }
}

extension TRTCVoiceRoomViewController {
    func presentAlert(title: String, message: String, sureAction:@escaping () -> Void) {
        let alertVC = UIAlertController.init(title: title, message: message, preferredStyle: .alert)
        let alertOKAction = UIAlertAction.init(title: .confirmText, style: .default) { (action) in
            alertVC.dismiss(animated: true, completion: nil)
            sureAction()
        }
        let alertCancelAction = UIAlertAction.init(title: .cancelText, style: .cancel) { (action) in
            alertVC.dismiss(animated: true, completion: nil)
        }
        alertVC.addAction(alertCancelAction)
        alertVC.addAction(alertOKAction)
        present(alertVC, animated: true, completion: nil)
    }
}

private extension String {
    static let exitText = voiceRoomLocalize("Demo.TRTC.VoiceRoom.exit")
    static let sureToExitText = voiceRoomLocalize("Demo.TRTC.VoiceRoom.isvoicingandsuretoexit")
    static let confirmText = voiceRoomLocalize("Demo.TRTC.LiveRoom.confirm")
    static let cancelText = voiceRoomLocalize("Demo.TRTC.LiveRoom.cancel")
}


