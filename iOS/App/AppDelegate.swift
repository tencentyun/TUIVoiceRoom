//
//  AppDelegate.swift
//  TRTCVoiceRoom
//
//  Created by abyyxwang on 2021/5/6.
//

import UIKit
import TUIVoiceRoom
import ImSDK_Plus

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    let LICENCEURL = ""
    let LICENCEKEY = ""

    func setLicence() {
        TXLiveBase.setLicenceURL(LICENCEURL, key: LICENCEKEY)
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        setLicence()
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    func showMainViewController() {
        guard let userId = ProfileManager.shared.curUserID() else {
            debugPrint("not login")
            return
        }
        TRTCVoiceRoom.shared().login(sdkAppID: Int32(SDKAPPID), userId: userId, userSig: ProfileManager.shared.curUserSig()) { code, message in
            if code == 0 {
                TRTCVoiceRoomIMManager.shared.SDKAPPID = Int32(SDKAPPID)
                TRTCVoiceRoomIMManager.shared.loadData()
                let listVC = VoiceRoomMainViewController.init()
                let rootVC = UINavigationController.init(rootViewController: listVC)
                if let keyWindow = SceneDelegate.getCurrentWindow() {
                    keyWindow.rootViewController = rootVC
                    keyWindow.makeKeyAndVisible()
                }
            } else {
                debugPrint("im login error, code = \(code), message = \(message)")
            }
        }
    }
    
    func showLoginViewController() {
        let loginVC = TRTCLoginViewController.init()
        let nav = UINavigationController(rootViewController: loginVC)
        if let keyWindow = SceneDelegate.getCurrentWindow() {
            keyWindow.rootViewController = nav
            keyWindow.makeKeyAndVisible()
        }
        else {
            debugPrint("window error")
        }
    }

}

