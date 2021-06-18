//
//  VoiceRoomLocalized.m
//  Pods
//
//  Created by abyyxwang on 2021/5/6.
//

#import "VoiceRoomLocalized.h"

#pragma mark - Base
NSBundle *VoiceRoomBundle() {
    NSURL *voiceRoomKitBundleURL = [[NSBundle mainBundle] URLForResource:@"TUIVoiceRoomKitBundle" withExtension:@"bundle"];
    return [NSBundle bundleWithURL:voiceRoomKitBundleURL];
}

NSString *TVRLocalizeFromTable(NSString *key, NSString *table) {
    return [VoiceRoomBundle() localizedStringForKey:key value:@"" table:table];
}

NSString *TVRLocalizeFromTableAndCommon(NSString *key, NSString *common, NSString *table) {
    return TVRLocalizeFromTable(key, table);
}

#pragma mark - Replace String
NSString *LocalizeReplaceXX(NSString *origin, NSString *xxx_replace) {
    if (xxx_replace == nil) { xxx_replace = @"";}
    return [origin stringByReplacingOccurrencesOfString:@"xxx" withString:xxx_replace];
}

NSString *LocalizeReplace(NSString *origin, NSString *xxx_replace, NSString *yyy_replace) {
    if (yyy_replace == nil) { yyy_replace = @"";}
    return [LocalizeReplaceXX(origin, xxx_replace) stringByReplacingOccurrencesOfString:@"yyy" withString:yyy_replace];
}

NSString *LocalizeReplaceThreeCharacter(NSString *origin, NSString *xxx_replace, NSString *yyy_replace, NSString *zzz_replace) {
    if (zzz_replace == nil) { zzz_replace = @"";}
    return [LocalizeReplace(origin, xxx_replace, yyy_replace) stringByReplacingOccurrencesOfString:@"zzz" withString:zzz_replace];
}

NSString *LocalizeReplaceFourCharacter(NSString *origin, NSString *xxx_replace, NSString *yyy_replace, NSString *zzz_replace, NSString *mmm_replace) {
    if (mmm_replace == nil) { mmm_replace = @"";}
    return [LocalizeReplaceThreeCharacter(origin, xxx_replace, yyy_replace, zzz_replace) stringByReplacingOccurrencesOfString:@"mmm" withString:mmm_replace];
}

NSString *LocalizeReplaceFiveCharacter(NSString *origin, NSString *xxx_replace, NSString *yyy_replace, NSString *zzz_replace, NSString *mmm_replace, NSString *nnn_replace) {
    if (nnn_replace == nil) { nnn_replace = @"";}
    return [LocalizeReplaceFourCharacter(origin, xxx_replace, yyy_replace, zzz_replace, mmm_replace) stringByReplacingOccurrencesOfString:@"nnn" withString:nnn_replace];
}


#pragma mark - VoiceRoom
NSString *const VoiceRoom_Localize_TableName = @"VoiceRoomLocalized";
NSString *VoiceRoomLocalize(NSString *key) {
    return TVRLocalizeFromTable(key, VoiceRoom_Localize_TableName);
}
