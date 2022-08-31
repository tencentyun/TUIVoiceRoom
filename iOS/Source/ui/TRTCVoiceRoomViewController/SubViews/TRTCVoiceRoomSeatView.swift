//
//  TRTCVoiceRoomRootView.swift
//  TRTCVoiceRoomDemo
//
//  Created by abyyxwang on 2020/6/8.
//Copyright © 2020 tencent. All rights reserved.
//
import UIKit
import TXAppBasic
import SnapKit

enum TRTCSeatState {
    case cellSeatEmpty
    case cellSeatFull
    case masterSeatEmpty
    case masterSeatFull
}

class TRTCVoiceRoomSeatView: UIView {
    private var isViewReady: Bool = false
    private var isGetBounds: Bool = false
    private var state: TRTCSeatState {
        didSet {
            stateChange()
        }
    }
    
    init(frame: CGRect = .zero, state: TRTCSeatState) {
        self.state = state
        super.init(frame: frame)
        bindInteraction()
        stateChange()
        setupStyle()
    }
    
    required init?(coder: NSCoder) {
        fatalError("can't init this viiew from coder")
    }
    
    deinit {
        TRTCLog.out("seat view deinit")
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        avatarImageView.layer.cornerRadius = avatarImageView.frame.height*0.5
        
        speakView.layer.cornerRadius = speakView.frame.height*0.5
        speakView.layer.borderWidth = 4
        speakView.layer.borderColor = UIColor.init(0x0FA968).cgColor
    }
    let speakView: UIView = {
        let view = UIView.init()
        view.backgroundColor = UIColor.clear
        view.isHidden = true
        return view
    }()
    let avatarImageView: UIImageView = {
        let imageView = UIImageView.init(frame: .zero)
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage.init(named: "voiceroom_placeholder_avatar", in: voiceRoomBundle(), compatibleWith: nil)
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    let muteImageView: UIImageView = {
        let imageView = UIImageView.init(frame: .zero)
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage.init(named: "audience_voice_off", in: voiceRoomBundle(), compatibleWith: nil)
        imageView.isHidden = true
        return imageView
    }()
    
    let nameLabel: UILabel = {
        let label = UILabel.init(frame: .zero)
        label.text = .handsupText
        label.font = UIFont.systemFont(ofSize: 14.0)
        label.textColor = UIColor.init(0xEBF4FF)
        label.textAlignment = .center
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        return label
    }()
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard !isViewReady else {
            return
        }
        isViewReady = true
        constructViewHierarchy()
        activateConstraints()
    }

    func setupStyle() {
        backgroundColor = .clear
    }
    
    func constructViewHierarchy() {
        addSubview(avatarImageView)
        addSubview(muteImageView)
        addSubview(nameLabel)
        avatarImageView.addSubview(speakView)
    }

    func activateConstraints() {
        avatarImageView.snp.makeConstraints { (make) in
            make.top.centerX.width.equalToSuperview()
            make.height.equalTo(avatarImageView.snp.width)
        }
        muteImageView.snp.makeConstraints { (make) in
            make.trailing.bottom.equalTo(avatarImageView)
        }
        nameLabel.snp.makeConstraints { (make) in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(avatarImageView.snp.bottom).offset(8)
            make.width.lessThanOrEqualTo(120)
        }
        speakView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }
    
    func prepareForReuse() {
        avatarImageView.kf.cancelDownloadTask()
        avatarImageView.image = nil;
        nameLabel.text = ""
        speakView.isHidden = true
        muteImageView.isHidden = true
    }

    func bindInteraction() {
        
    }
    
    func isMute(userId: String, map: [String:Bool]) -> Bool {
        if map.keys.contains(userId) {
            return map[userId]!
        }
        return true
    }
    
    func setSeatInfo(model: SeatInfoModel, userMuteMap: [String:Bool]) {
        if model.isClosed {
            avatarImageView.image = UIImage.init(named: "room_lockseat", in: voiceRoomBundle(), compatibleWith: nil)
            nameLabel.text = ""//.lockedText
            speakView.isHidden = true
            muteImageView.isHidden = true
            return
        }
        
        if let user = model.seatUser {
            let userMute = isMute(userId: user.userId, map: userMuteMap)
            muteImageView.isHidden = !((model.seatInfo?.mute ?? false) || userMute)
        }
        else {
            muteImageView.isHidden = true
        }
        
        if model.isUsed {
            if let userSeatInfo = model.seatUser {
                let placeholder = UIImage.init(named: "avatar2_100", in: voiceRoomBundle(), compatibleWith: nil)
                if userSeatInfo.userAvatar.count > 0, let avatarURL = URL.init(string: userSeatInfo.userAvatar) {
                    avatarImageView.kf.setImage(with: avatarURL, placeholder: placeholder)
                } else {
                    avatarImageView.image = placeholder
                }
                nameLabel.text = userSeatInfo.userName
            }
        } else {
            avatarImageView.image = UIImage.init(named: "Servingwheat", in: voiceRoomBundle(), compatibleWith: nil)
            nameLabel.text = ""
                //model.isOwner ? .inviteHandsupText : .handsupText
        }
        if (model.isTalking) {
            speakView.isHidden = false
        } else {
            speakView.isHidden = true
        }
    }
}

extension TRTCVoiceRoomSeatView {
    
    private func stateChange() {
        switch state {
        case .cellSeatEmpty:
            toEmptyStates(isMaster: false)
        case .masterSeatEmpty:
            toEmptyStates(isMaster: true)
        case .cellSeatFull:
            toFullStates(isMaster: false)
        case .masterSeatFull:
            toFullStates(isMaster: true)
        }
    }
    
    private func toEmptyStates(isMaster: Bool) {
        let fontSize: CGFloat = isMaster ? 18.0 : 14.0
        nameLabel.font = UIFont.systemFont(ofSize: fontSize)
        nameLabel.textColor = .placeholderBackColor
    }
    
    private func toFullStates(isMaster: Bool) {
        let fontSize: CGFloat = isMaster ? 18.0 : 14.0
        nameLabel.font = UIFont.systemFont(ofSize: fontSize)
        nameLabel.textColor = UIColor.init(0xEBF4FF)
    }
}

/// MARK: - internationalization string
fileprivate extension String {
    static let handsupText = voiceRoomLocalize("Demo.TRTC.VoiceRoom.presshandsup")
    static let lockedText = voiceRoomLocalize("Demo.TRTC.VoiceRoom.islocked")
    static let inviteHandsupText = voiceRoomLocalize("Demo.TRTC.VoiceRoom.invitehandsup")
}



