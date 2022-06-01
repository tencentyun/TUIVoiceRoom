//
//  TRTCVoiceRoomDelegate.h
//  TXLiteAVDemo
//
//  Created by abyyxwang on 2020/7/8.
//  Copyright © 2020 Tencent. All rights reserved.
//

#ifndef TRTCVoiceRoomDelegate_h
#define TRTCVoiceRoomDelegate_h

#import "TRTCVoiceRoomDef.h"

NS_ASSUME_NONNULL_BEGIN

@class TRTCVolumeInfo;

@protocol TRTCVoiceRoomDelegate <NSObject>

/// Callback for error
/// @param code Error code
/// @param message Error message
- (void)onError:(int)code
                message:(NSString*)message
NS_SWIFT_NAME(onError(code:message:));

/// Callback for warning
/// @param code Warning code
/// @param message Warning message
- (void)onWarning:(int)code
                  message:(NSString *)message
NS_SWIFT_NAME(onWarning(code:message:));

/// Debugging log
/// @param message Message
- (void)onDebugLog:(NSString *)message
NS_SWIFT_NAME(onDebugLog(message:));

/// Callback for room termination
/// @param message Termination message
- (void)onRoomDestroy:(NSString *)message
NS_SWIFT_NAME(onRoomDestroy(message:));

/// Callback for room information change
/// @param roomInfo Room information
- (void)onRoomInfoChange:(VoiceRoomInfo *)roomInfo
NS_SWIFT_NAME(onRoomInfoChange(roomInfo:));

/// Callback for room seat change
/// @param seatInfolist Seat list information
- (void)onSeatInfoChange:(NSArray<VoiceRoomSeatInfo *> *)seatInfolist
NS_SWIFT_NAME(onSeatListChange(seatInfoList:));

/// Callback for anchor mic-on
/// @param index Seat number
/// @param user User information
- (void)onAnchorEnterSeat:(NSInteger)index
                              user:(VoiceRoomUserInfo *)user
NS_SWIFT_NAME(onAnchorEnterSeat(index:user:));

/// Callback for anchor mic-off
/// @param index Seat number
/// @param user User information
- (void)onAnchorLeaveSeat:(NSInteger)index
                     user:(VoiceRoomUserInfo *)user
NS_SWIFT_NAME(onAnchorLeaveSeat(index:user:));

/// Callback for seat mute status
/// @param index Seat number
/// @param isMute Mute status
- (void)onSeatMute:(NSInteger)index
            isMute:(BOOL)isMute
NS_SWIFT_NAME(onSeatMute(index:isMute:));

/// Whether a user's mic was muted.
/// @param userId User ID
/// @param mute Muted or unmuted
- (void)onUserMicrophoneMute:(NSString *)userId mute:(BOOL)mute
NS_SWIFT_NAME(onUserMicrophoneMute(userId:mute:));

/// Callback for seat closure
/// @param index Seat number
/// @param isClose Whether it is closed
- (void)onSeatClose:(NSInteger)index
            isClose:(BOOL)isClose
NS_SWIFT_NAME(onSeatClose(index:isClose:));

/// Callback for audience member's room entry
/// @param userInfo Audience member information
- (void)onAudienceEnter:(VoiceRoomUserInfo *)userInfo
NS_SWIFT_NAME(onAudienceEnter(userInfo:));

/// Callback for audience member's room exit
/// @param userInfo Audience member information
- (void)onAudienceExit:(VoiceRoomUserInfo *)userInfo
NS_SWIFT_NAME(onAudienceExit(userInfo:));

/// Volume level change of speakers
/// @param userVolumes Volume level information of each user
/// @param totalVolume Overall volume level information
- (void)onUserVolumeUpdate:(NSArray<TRTCVolumeInfo *> *)userVolumes totalVolume:(NSInteger)totalVolume
NS_SWIFT_NAME(onUserVolumeUpdate(userVolumes:totalVolume:));

/// Callback for text chat message receipt
/// @param message Message content
/// @param userInfo Sender information
- (void)onRecvRoomTextMsg:(NSString *)message
                 userInfo:(VoiceRoomUserInfo *)userInfo
NS_SWIFT_NAME(onRecvRoomTextMsg(message:userInfo:));

/// Callback for custom message (command message) receipt
/// @param cmd Command
/// @param message Message content
/// @param userInfo Sender information
- (void)onRecvRoomCustomMsg:(NSString *)cmd
                    message:(NSString *)message
                   userInfo:(VoiceRoomUserInfo *)userInfo
NS_SWIFT_NAME(onRecvRoomCustomMsg(cmd:message:userInfo:));

/// Callback for invitation message receipt
/// @param identifier Invitee ID
/// @param inviter Inviter ID
/// @param cmd Command
/// @param content Content
- (void)onReceiveNewInvitation:(NSString *)identifier
                       inviter:(NSString *)inviter
                           cmd:(NSString *)cmd
                       content:(NSString *)content
NS_SWIFT_NAME(onReceiveNewInvitation(identifier:inviter:cmd:content:));

/// Callback for invitation acceptance
/// @param identifier Invitee ID
/// @param inviter Inviter ID
- (void)onInviteeAccepted:(NSString *)identifier
                  invitee:(NSString *)invitee
NS_SWIFT_NAME(onInviteeAccepted(identifier:invitee:));

/// Callback for invitation decline
/// @param identifier Invitee ID
/// @param inviter Inviter ID
- (void)onInviteeRejected:(NSString *)identifier
                  invitee:(NSString *)invitee
NS_SWIFT_NAME(onInviteeRejected(identifier:invitee:));

/// Callback for invitation cancellation
/// @param identifier Invitee ID
/// @param inviter Inviter ID
- (void)onInvitationCancelled:(NSString *)identifier
                      invitee:(NSString *)invitee NS_SWIFT_NAME(onInvitationCancelled(identifier:invitee:));

@end

NS_ASSUME_NONNULL_END


#endif /* TRTCVoiceRoomDelegate_h */


