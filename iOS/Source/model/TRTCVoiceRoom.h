//
//  TRTCVoiceRoom.h
//  TRTCVoiceRoomOCDemo
//
//  Created by abyyxwang on 2020/6/30.
//  Copyright © 2020 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TRTCVoiceRoomDelegate.h"
#import "TRTCVoiceRoomDef.h"

NS_ASSUME_NONNULL_BEGIN

@class TXAudioEffectManager;
@interface TRTCVoiceRoom : NSObject

/**
 * Get a `TRTCVoiceRoom` singleton object
 *
 * @return: `TRTCVoiceRoom` instance
 * @note: To terminate a singleton object, call {@link TRTCVoiceRoom#destroySharedInstance()}.
 */
+ (instancetype)sharedInstance NS_SWIFT_NAME(shared());

/**
 * Terminate a `TRTCVoiceRoom` singleton object
 *
 * @note: After the instance is terminated, the externally cached `TRTCVoiceRoom` instance can no longer be used. You need to call {@link TRTCVoiceRoom#sharedInstance()} again to get a new instance.
 */
+ (void)destroySharedInstance NS_SWIFT_NAME(destroyShared());

#pragma mark: - Basic APIs
/**
 * Set the event callbacks of the component
 *
 * You can use `TRTCVoiceRoomDelegate` to get different status notifications of `TRTCVoiceRoom`
 *
 * @param delegate Callback API
 * @note: Callback events in `TRTCVoiceRoom` are called back to you in the main queue by default. If you need to specify a queue for event callback, please use {@link TRTCVoiceRoom#setDelegateQueue(queue)}.
 */
- (void)setDelegate:(id<TRTCVoiceRoomDelegate>)delegate NS_SWIFT_NAME(setDelegate(delegate:));

/**
 * Set the queue for event callbacks
 *
 * @param queue Queue. Various status callback notifications in `TRTCVoiceRoom` will be sent to the queue you specify.
 */
- (void)setDelegateQueue:(dispatch_queue_t)queue NS_SWIFT_NAME(setDelegateQueue(queue:));

/**
 * Logs in
 *
 * @param sdkAppID You can view `SDKAppID` in **[Application Management](https://console.cloud.tencent.com/trtc/app)** > **Application Info** in the TRTC console.
 * @param userId   ID of the current user, which is a string that can contain only letters (a–z and A–Z), digits (0–9), hyphens (-), and underscores (_)
 * @param userSig  Tencent Cloud's proprietary security protection signature. For more information on how to get it, see [UserSig](https://cloud.tencent.com/document/product/647/17275).
 * @param callback Login callback. The `code` will be 0 if login is successful
 */
- (void)login:(int)sdkAppID
       userId:(NSString *)userId
      userSig:(NSString *)userSig
     callback:(ActionCallback _Nullable)callback NS_SWIFT_NAME(login(sdkAppID:userId:userSig:callback:));

/**
 * Logs out
 */
- (void)logout:(ActionCallback _Nullable)callback NS_SWIFT_NAME(logout(callback:));


/**
 * Set user information. The user information you set will be stored in Tencent Cloud IM.
 *
 * @param userName     Username, which cannot be null
 * @param avatarURL    User profile photo
 * @param callback     Result callback for whether the setting succeeds
 */
- (void)setSelfProfile:(NSString *)userName avatarURL:(NSString *)avatarURL callback:(ActionCallback _Nullable)callback NS_SWIFT_NAME(setSelfProfile(userName:avatarURL:callback:));

#pragma mark - Room management APIs
/**
 * Creates a room (called by anchor)
 *
 * The normal calling process of the anchor is as follows:
 * 1. The anchor calls `createRoom` to create an audio chat room, passing in room attribute information such as the room ID, whether mic-on needs confirmation by the room owner, and the number of seats.
 * 2. After successfully creating the room, the anchor calls `enterSeat` to become a speaker.
 * 3. The anchor receives the `onSeatListChange` seat list change event notification from the component. At this time, the seat list change can be refreshed and displayed on the UI.
 * 4. The user will receive an `onAnchorEnterSeat` notification that someone became a speaker, and mic capturing will be enabled automatically.
 *
 * @param roomID       Room ID. You need to assign and manage the IDs in a centralized manner.
 * @param roomParam    Room information, such as room name and cover information. If both the room list and room information are managed on your server, you can ignore this parameter.
 * @param callback     Callback for room creation result. The `code` will be 0 if the operation succeeds.
 */
- (void)createRoom:(int)roomID roomParam:(VoiceRoomParam *)roomParam callback:(ActionCallback _Nullable)callback NS_SWIFT_NAME(createRoom(roomID:roomParam:callback:));

/**
 * Terminates a room (called by anchor)
 *
 * After creating a room, the anchor can call this API to terminate it.
 */
- (void)destroyRoom:(ActionCallback _Nullable)callback NS_SWIFT_NAME(destroyRoom(callback:));

/**
 * Enters a room (called by audience)
 *
 * The process of entering a room and starting playback as an audience member is as follows:
 * 1. An **audience member** gets the latest audio chat room list from your server, which may contain `roomId` and other information of multiple rooms.
 * 2. The audience member selects an audio chat room and calls `enterRoom` with the room ID to enter the room.
 * 3. After entering the room, the audience member receives an `onRoomInfoChange` notification about the room attribute change from the component. The room attributes can be recorded, and corresponding changes can be made. The attributes include the room name displayed on the UI and whether room owner’s consent is required for listeners to speak.
 * 4. The user will receive an `onSeatListChange` notification about the change of the seat list and can update the change to the UI.
 * 5. The user will also receive an `onAnchorEnterSeat` notification that someone became an anchor.
 *
 * @param roomID   Room ID
 * @param callback Result callback for whether room entry succeeds
 */
- (void)enterRoom:(NSInteger)roomID callback:(ActionCallback _Nullable)callback NS_SWIFT_NAME(enterRoom(roomID:callback:));

/**
 * Exits a room
 * @note: The room owner cannot exit the room but only call `destroyRoom` to terminate it.
 * @param callback Result callback for whether room exit succeeds
 */
- (void)exitRoom:(ActionCallback _Nullable)callback NS_SWIFT_NAME(exitRoom(callback:));

/**
 * Get room list details
 *
 * The details are set through `roomParam` by the anchor during `createRoom()`. If both the room list and room information are managed on your server, you can ignore this function.
 *
 * @param roomIdList   Room ID list
 * @param callback     Callback for room details
 */
- (void)getRoomInfoList:(NSArray<NSNumber *> *)roomIdList callback:(VoiceRoomInfoCallback _Nullable)callback NS_SWIFT_NAME(getRoomInfoList(roomIdList:callback:));

/**
 * Get the user information of the specified `userId`. If the value is `null`, the information of all users in the room will be obtained
 *
 * @param userIDList   User ID list
 * @param callback     Callback for user details
 */
- (void)getUserInfoList:(NSArray<NSString *> * _Nullable)userIDList callback:(VoiceRoomUserListCallback _Nullable)callback NS_SWIFT_NAME(getUserInfoList(userIDList:callback:));

#pragma mark - seat management APIs
/**
 * Turns the mic on (called by anchor or audience)
 *
 * After a user becomes a speaker, all members in the room will receive `onSeatListChange` and `onAnchorEnterSeat` notifications.
 *
 * @param seatIndex    Seat number for mic-on
 * @param callback     Operation callback
 */
- (void)enterSeat:(NSInteger)seatIndex callback:(ActionCallback _Nullable)callback NS_SWIFT_NAME(enterSeat(seatIndex:callback:));

/**
 * @brief Changes a seat (called by speaker)
 *
 * @note After seat change, all members in the room will receive the `onSeatListChange` notification.
 *
 * @param seatIndex   Number of the seat to change to
 * @param callback    Callback for the operation
 * @return Callback result. Valid values: 0: Success; Other values indicate failure, and `10001` indicates the API call frequency limit
 */
- (NSInteger)moveSeat:(NSInteger)seatIndex callback:(ActionCallback _Nullable)callback NS_SWIFT_NAME(moveSeat(seatIndex:callback:));

/**
 * Turns the mic off (called by anchor or audience)
 *
 * After a speaker becomes a listener, all members in the room will receive `onSeatListChange` and `onAnchorLeaveSeat` notifications.
 *
 * @param callback Operation callback
 */
- (void)leaveSeat:(ActionCallback _Nullable)callback NS_SWIFT_NAME(leaveSeat(callback:));

/**
 * Places a user in a seat (called by anchor)
 *
 * After the anchor places a user in a seat, all members in the room will receive `onSeatListChange` and `onAnchorEnterSeat` notifications.
 *
 * @param seatIndex    The number of the seat to place the user in
 * @param userId       User ID
 * @param callback     Operation callback
 */
- (void)pickSeat:(NSInteger)seatIndex userId:(NSString *)userId callback:(ActionCallback _Nullable)callback NS_SWIFT_NAME(pickSeat(seatIndex:userId:callback:));

/**
 * Removes a speaker (called by anchor)
 *
 * After the anchor removes a speaker, all members in the room will receive `onSeatListChange` and `onAnchorLeaveSeat` notifications.
 *
 * @param seatIndex    Seat number for kicked mic-off
 * @param callback     Operation callback
 */
- (void)kickSeat:(NSInteger)seatIndex callback:(ActionCallback _Nullable)callback NS_SWIFT_NAME(kickSeat(seatIndex:callback:));

/**
 * Mute/Unmute seat (called by anchor)
 *
 * @param seatIndex    Seat number
 * @param isMute       true: Mute; false: Unmute
 * @param callback     Operation callback
 */
- (void)muteSeat:(NSInteger)seatIndex isMute:(BOOL)isMute callback:(ActionCallback _Nullable)callback NS_SWIFT_NAME(muteSeat(seatIndex:isMute:callback:));

/**
 * Blocks/Unblocks a seat (called by anchor)
 *
 * @param seatIndex    Seat number
 * @param isClose      true: Block; false: Unblock
 * @param callback     Operation callback
 */
- (void)closeSeat:(NSInteger)seatIndex isClose:(BOOL)isClose callback:(ActionCallback _Nullable)callback NS_SWIFT_NAME(closeSeat(seatIndex:isClose:callback:));

#pragma mark - local audio operation APIs

/**
 * Starts mic capturing
 */
- (void)startMicrophone;

/**
 * Stops mic capturing
 */
- (void)stopMicrophone;

/**
 * Sets the audio quality
 *
 * @param quality TRTC_AUDIO_QUALITY_MUSIC/TRTC_AUDIO_QUALITY_DEFAULT/TRTC_AUDIO_QUALITY_SPEECH
 */
- (void)setAuidoQuality:(NSInteger)quality NS_SWIFT_NAME(setAuidoQuality(quality:));

/**
 * Enables/Disables in-ear monitoring
 *
 * @param enable Enables/Disables
 */
- (void)setVoiceEarMonitorEnable:(BOOL)enable NS_SWIFT_NAME(setVoiceEarMonitor(enable:));

/**
 * Mute local audio
 *
 * @param mute Whether to mute
 */
- (void)muteLocalAudio:(BOOL)mute NS_SWIFT_NAME(muteLocalAudio(mute:));

/**
 * Sets whether to use the device’s speaker or receiver
 *
 * @param useSpeaker  true: Speaker; false: Receiver
 */
- (void)setSpeaker:(BOOL)userSpeaker NS_SWIFT_NAME(setSpeaker(userSpeaker:));

/**
 * Sets the mic capturing volume
 *
 * @param volume Capturing volume level between 0 and 100
 */
- (void)setAudioCaptureVolume:(NSInteger)voluem NS_SWIFT_NAME(setAudioCaptureVolume(volume:));

- (void)setAudioPlayoutVolume:(NSInteger)volume NS_SWIFT_NAME(setAudioPlayoutVolume(volume:));

#pragma mark - remote user APIs
/**
 * Mutes the specified user
 *
 * @param userId   User ID
 * @param mute     true: Mute; false: Unmute
 */
- (void)muteRemoteAudio:(NSString *)userId mute:(BOOL)mute NS_SWIFT_NAME(muteRemoteAudio(userId:mute:));

/**
 * Mutes all users
 *
 * @param isMute true: Mute; false: Unmute
 */
- (void)muteAllRemoteAudio:(BOOL)isMute NS_SWIFT_NAME(muteAllRemoteAudio(isMute:));

/**
 * Sound effect control APIs
 */
- (TXAudioEffectManager * _Nullable)getAudioEffectManager;

#pragma mark - message sending APIs
/**
 * Broadcasts a text chat message in the room. This API is generally used for on-screen comments.
 *
 * @param message  Text chat message
 * @param callback Callback for sending result
 */
- (void)sendRoomTextMsg:(NSString *)message callback:(ActionCallback _Nullable)callback NS_SWIFT_NAME(sendRoomTextMsg(message:callback:));

/**
 * Broadcast a custom (command) message in the room, which is generally used to broadcast liking and gifting messages
 *
 * @param cmd      Custom command word used to distinguish between different message types
 * @param message  Text chat message
 * @param callback Callback for sending result
 */
- (void)sendRoomCustomMsg:(NSString *)cmd message:(NSString *)message callback:(ActionCallback _Nullable)callback NS_SWIFT_NAME(sendRoomCustomMsg(cmd:message:callback:));

#pragma mark - invitation command message APIs

/**
 * Sends an invitation to a user
 *
 * @param cmd      Custom command of business
 * @param userId   Invitee user ID
 * @param content  Invitation content
 * @param callback Callback for sending result
 * @return: inviteId Invitation ID
 */
- (NSString *)sendInvitation:(NSString *)cmd
                      userId:(NSString *)userId
                     content:(NSString *)content
                    callback:(ActionCallback _Nullable)callback NS_SWIFT_NAME(sendInvitation(cmd:userId:content:callback:));

/**
 * Accepts an invitation
 *
 * @param identifier   Invitation ID
 * @param callback     Operation callback for invitation acceptance
 */
- (void)acceptInvitation:(NSString *)identifier callback:(ActionCallback _Nullable)callback NS_SWIFT_NAME(acceptInvitation(identifier:callback:));


/**
 * Rejects an invitation
 * @param identifier   Invitation ID
 * @param callback     Operation callback for invitation acceptance
 */
- (void)rejectInvitation:(NSString *)identifier callback:(ActionCallback _Nullable)callback NS_SWIFT_NAME(rejectInvitation(identifier:callback:));

/**
 * Cancels an invitation
 * @param identifier   Invitation ID
 * @param callback     Operation callback for invitation acceptance
 */
- (void)cancelInvitation:(NSString *)identifier callback:(ActionCallback _Nullable)callback NS_SWIFT_NAME(cancelInvitation(identifier:callback:));



@end

NS_ASSUME_NONNULL_END
