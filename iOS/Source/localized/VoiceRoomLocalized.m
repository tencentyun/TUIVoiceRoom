//
//  VoiceRoomLocalized.m
//  Pods
//
//  Created by abyyxwang on 2021/5/6.
//  Copyright © 2022 Tencent. All rights reserved.

#import "VoiceRoomLocalized.h"

#pragma mark - Base
NSBundle *voiceRoomBundle() {
    NSURL *voiceRoomKitBundleURL = [[NSBundle mainBundle] URLForResource:@"TUIVoiceRoomKitBundle" withExtension:@"bundle"];
    return [NSBundle bundleWithURL:voiceRoomKitBundleURL];
}

NSString *tvrLocalizeFromTable(NSString *key, NSString *table) {
    return [voiceRoomBundle() localizedStringForKey:key value:@"" table:table];
}

NSString *tvrLocalizeFromTableAndCommon(NSString *key, NSString *common, NSString *table) {
    return tvrLocalizeFromTable(key, table);
}

#pragma mark - Replace String
NSString *localizeReplaceXX(NSString *origin, NSString *xxx_replace) {
    if (xxx_replace == nil) { xxx_replace = @"";}
    return [origin stringByReplacingOccurrencesOfString:@"xxx" withString:xxx_replace];
}

NSString *localizeReplace(NSString *origin, NSString *xxx_replace, NSString *yyy_replace) {
    if (yyy_replace == nil) { yyy_replace = @"";}
    return [localizeReplaceXX(origin, xxx_replace) stringByReplacingOccurrencesOfString:@"yyy" withString:yyy_replace];
}

NSString *localizeReplaceThreeCharacter(NSString *origin, NSString *xxx_replace, NSString *yyy_replace,
 NSString *zzz_replace) {
    if (zzz_replace == nil) { zzz_replace = @"";}
    return [localizeReplace(origin, xxx_replace, yyy_replace) stringByReplacingOccurrencesOfString:@"zzz" withString:zzz_replace];
}

NSString *localizeReplaceFourCharacter(NSString *origin, NSString *xxx_replace, NSString *yyy_replace,
 NSString *zzz_replace, NSString *mmm_replace) {
    if (mmm_replace == nil) { mmm_replace = @"";}
    return [localizeReplaceThreeCharacter(origin, xxx_replace, yyy_replace, zzz_replace)
     stringByReplacingOccurrencesOfString:@"mmm" withString:mmm_replace];
}

NSString *localizeReplaceFiveCharacter(NSString *origin, NSString *xxx_replace, NSString *yyy_replace,
 NSString *zzz_replace, NSString *mmm_replace, NSString *nnn_replace) {
    if (nnn_replace == nil) { nnn_replace = @"";}
    return [localizeReplaceFourCharacter(origin, xxx_replace, yyy_replace, zzz_replace,
     mmm_replace) stringByReplacingOccurrencesOfString:@"nnn" withString:nnn_replace];
}


#pragma mark - VoiceRoom
NSString *const voiceRoom_Localize_TableName = @"VoiceRoomLocalized";
NSString *voiceRoomLocalize(NSString *key) {
    return tvrLocalizeFromTable(key, voiceRoom_Localize_TableName);
}
