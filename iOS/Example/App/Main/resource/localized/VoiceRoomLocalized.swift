//
//  VoiceRoomLocalized.swift
//  TRTCAPP_AppStore
//
//  Created by adams on 2021/6/4.
//

import Foundation

//MARK: VoiceRoom
let VoiceRoomLocalizeTableName = "VoiceRoomLocalized"
func TRTCVoiceRoomLocalize(_ key: String) -> String {
    return localizeFromTable(key: key, table: VoiceRoomLocalizeTableName)
}
