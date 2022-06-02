package com.tencent.liteav.trtcvoiceroom.model;

import android.content.Context;

import com.tencent.liteav.audio.TXAudioEffectManager;
import com.tencent.liteav.trtcvoiceroom.model.impl.TRTCVoiceRoomImpl;

import java.util.List;

public abstract class TRTCVoiceRoom {

    /**
     * Get a `TRTCVoiceRoom` singleton object
     *
     * @param context Android context, which will be internally converted to `ApplicationContext` for system API calls
     * @return `TRTCVoiceRoom` instance
     * @note To terminate a singleton object, call `{@link TRTCVoiceRoom#destroySharedInstance()}`.
     */
    public static synchronized TRTCVoiceRoom sharedInstance(Context context) {
        return TRTCVoiceRoomImpl.sharedInstance(context);
    }

    /**
     * Terminate a `TRTCVoiceRoom` singleton object
     *
     * @note After the instance is terminated, the externally cached `TRTCVoiceRoom` instance can no longer be used.
     * You need to call `{@link TRTCVoiceRoom#sharedInstance(Context context)}` again to get a new instance.
     */
    public static void destroySharedInstance() {
        TRTCVoiceRoomImpl.destroySharedInstance();
    }

    //////////////////////////////////////////////////////////
    //
    //                 Basic APIs
    //
    //////////////////////////////////////////////////////////

    /**
     * Set the event callbacks of the component
     * <p>
     * You can use `TRTCVoiceRoomDelegate` to get different status notifications of `TRTCVoiceRoom`
     *
     * @param delegate Callback API
     * @note Callbacks from `TRTCVoiceRoom` are sent to you in the main thread by default. If you need to specify a
     * thread for event callbacks.
     */
    public abstract void setDelegate(TRTCVoiceRoomDelegate delegate);

    /**
     * Logs in
     *
     * @param sdkAppId You can view `SDKAppID` in **[Application Management](https://console.cloud.tencent
     *                 .com/trtc/app)** > **Application Info** in the TRTC console.
     * @param userId   ID of the current user, which is a string that can contain only letters (a–z and A–Z), digits
     *                 (0–9), hyphens (-), and underscores (_)
     * @param userSig  Tencent Cloud's proprietary security protection signature. For more information on how to get
     *                 it, see [UserSig](https://cloud.tencent.com/document/product/647/17275).
     * @param callback Callback for login. The return code will be `0` if login is successful.
     */
    public abstract void login(int sdkAppId, String userId, String userSig,
                               TRTCVoiceRoomCallback.ActionCallback callback);

    /**
     * Logs out
     */
    public abstract void logout(TRTCVoiceRoomCallback.ActionCallback callback);

    /**
     * Set user information. The user information you set will be stored in Tencent Cloud IM.
     *
     * @param userName  Username
     * @param avatarURL User profile photo
     * @param callback  Result callback for whether the setting succeeds
     */
    public abstract void setSelfProfile(String userName, String avatarURL,
                                        TRTCVoiceRoomCallback.ActionCallback callback);

    //////////////////////////////////////////////////////////
    //
    //                 Room management APIs
    //
    //////////////////////////////////////////////////////////

    /**
     * Creates a room (called by anchor)
     * <p>
     * The normal calling process of the anchor is as follows:
     * 1. The anchor calls `createRoom` to create an audio chat room, passing in room attribute information such as
     * the room ID, whether mic-on needs confirmation by the room owner, and the number of seats.
     * 2. After successfully creating the room, the anchor calls `enterSeat` to become a speaker.
     * 3. The anchor receives the `onSeatListChange` seat list change event notification from the component. At this
     * time, the seat list change can be refreshed and displayed on the UI.
     * 4. The user will receive an `onAnchorEnterSeat` notification that someone became a speaker, and mic capturing
     * will be enabled automatically.
     *
     * @param roomId    Room ID. You need to assign and manage the IDs in a centralized manner.
     * @param roomParam Room information, such as room name and cover information. If both the room list and room
     *                  information are managed on your server, you can ignore this parameter.
     * @param callback  Callback for room creation result. The `code` will be 0 if the operation succeeds.
     */
    public abstract void createRoom(int roomId, TRTCVoiceRoomDef.RoomParam roomParam,
                                    TRTCVoiceRoomCallback.ActionCallback callback);

    /**
     * Terminates a room (called by anchor)
     * <p>
     * After creating a room, the anchor can call this API to terminate it.
     */
    public abstract void destroyRoom(TRTCVoiceRoomCallback.ActionCallback callback);

    /**
     * Enters a room (called by audience)
     * <p>
     * The process of entering a room as a listener user is as follows:
     * 1. An **audience member** gets the latest audio chat room list from your server, which may contain `roomId`
     * and other information of multiple rooms.
     * 2. The audience member selects an audio chat room and calls `enterRoom` with the room ID passed in to enter
     * the room.
     * 3. After entering the room, the audience member receives an `onRoomInfoChange` notification about the room
     * attribute change from the component. The room attributes can be recorded, and corresponding changes can be
     * made. The attributes include the room name displayed on the UI and whether room owner’s consent is required
     * for listeners to speak.
     * 4. The user will receive an `onSeatListChange` seat list change notification and can update the change to the UI.
     * 5. The user will also receive an `onAnchorEnterSeat` notification that someone became an anchor.
     *
     * @param roomId   Room ID
     * @param callback Result callback for whether room entry succeeds
     */
    public abstract void enterRoom(int roomId, TRTCVoiceRoomCallback.ActionCallback callback);

    /**
     * Exits a room
     *
     * @param callback Result callback for whether room exit succeeds
     */
    public abstract void exitRoom(TRTCVoiceRoomCallback.ActionCallback callback);

    /**
     * Get the user information of the specified `userId`. If the value is `null`, the information of all users in
     * the room will be obtained
     *
     * @param userlistcallback Callback for user details
     */
    public abstract void getUserInfoList(List<String> userIdList,
                                         TRTCVoiceRoomCallback.UserListCallback userlistcallback);

    //////////////////////////////////////////////////////////
    //
    //                 Seat management APIs
    //
    //////////////////////////////////////////////////////////

    /**
     * Turns the mic on (called by anchor or audience)
     * <p>
     * After a user becomes a speaker, all members in the room will receive `onSeatListChange` and
     * `onAnchorEnterSeat` notifications.
     *
     * @param seatIndex Number of the seat to take
     * @param callback  Callback for the operation
     */
    public abstract void enterSeat(int seatIndex, TRTCVoiceRoomCallback.ActionCallback callback);

    /**
     * Turns the mic off (called by anchor or audience)
     * <p>
     * After a speaker becomes a listener, all members in the room will receive `onSeatListChange` and
     * `onAnchorLeaveSeat` notifications.
     *
     * @param callback Callback for the operation
     */
    public abstract void leaveSeat(TRTCVoiceRoomCallback.ActionCallback callback);

    /**
     * Places a user in a seat (called by anchor)
     * <p>
     * After the anchor places a user in a seat, all members in the room will receive `onSeatListChange` and
     * `onAnchorEnterSeat` notifications.
     *
     * @param seatIndex Number of the target seat
     * @param userId    User ID
     * @param callback  Callback for the operation
     */
    public abstract void pickSeat(int seatIndex, String userId, TRTCVoiceRoomCallback.ActionCallback callback);

    /**
     * Removes a speaker (called by anchor)
     * <p>
     * After the anchor removes a speaker, all members in the room will receive `onSeatListChange` and
     * `onAnchorLeaveSeat` notifications.
     *
     * @param seatIndex Number of the seat to remove the speaker from
     * @param callback  Callback for the operation
     */
    public abstract void kickSeat(int seatIndex, TRTCVoiceRoomCallback.ActionCallback callback);

    /**
     * Mute/Unmute seat (called by anchor)
     * <p>
     * All members in the room will receive `onSeatListChange` and `onSeatMute` notifications.
     * The speaker on the seat specified by `seatIndex` will call `muteAudio` to mute/unmute his or her audio.
     *
     * @param seatIndex Seat number
     * @param isMute    true: Mute; false: Unmute
     * @param callback  Callback for the operation
     */
    public abstract void muteSeat(int seatIndex, boolean isMute, TRTCVoiceRoomCallback.ActionCallback callback);

    /**
     * Blocks/Unblocks a seat (called by anchor)
     * <p>
     * All members in the room will receive `onSeatListChange` and `onSeatClose` notifications.
     *
     * @param seatIndex Seat number
     * @param isClose   true: Block; false: Unblock
     * @param callback  Callback for the operation
     */
    public abstract void closeSeat(int seatIndex, boolean isClose, TRTCVoiceRoomCallback.ActionCallback callback);

    /**
     * Changes a seat (called by speaker)
     * <p>
     * After seat changing, all members in the room will receive the `onSeatListChange` notification.
     *
     * @param seatIndex Number of the seat to change to
     * @param callback  Callback for the operation
     * @return Callback result. Valid values: 0: Success; Other values indicate failure, and `10001` indicates the
     * API call frequency limit
     */
    public abstract int moveSeat(int seatIndex, TRTCVoiceRoomCallback.ActionCallback callback);

    //////////////////////////////////////////////////////////
    //
    //                 Local audio APIs
    //
    //////////////////////////////////////////////////////////

    /**
     * Starts mic capturing
     */
    public abstract void startMicrophone();

    /**
     * Stops mic capturing
     */
    public abstract void stopMicrophone();

    /**
     * Enables/Disables in-ear monitoring
     *
     * @param enable Enables/Disables
     */
    public abstract void setVoiceEarMonitorEnable(boolean enable);

    /**
     * Sets the audio quality
     *
     * @param quality TRTC_AUDIO_QUALITY_MUSIC/TRTC_AUDIO_QUALITY_DEFAULT/TRTC_AUDIO_QUALITY_SPEECH
     */
    public abstract void setAudioQuality(int quality);

    /**
     * Mute local audio
     *
     * @param mute Whether to mute
     */
    public abstract void muteLocalAudio(boolean mute);

    /**
     * Sets whether to use the device’s speaker or receiver
     *
     * @param useSpeaker true: Speaker; false: Receiver
     */
    public abstract void setSpeaker(boolean useSpeaker);

    /**
     * Sets the mic capturing volume
     *
     * @param volume Capturing volume level. Value range: 0–100
     */
    public abstract void setAudioCaptureVolume(int volume);

    /**
     * Sets the playback volume level
     *
     * @param volume Playback volume level. Value range: 0–100
     */
    public abstract void setAudioPlayoutVolume(int volume);

    //////////////////////////////////////////////////////////
    //
    //                 Remote user APIs
    //
    //////////////////////////////////////////////////////////

    /**
     * Mutes the specified user
     *
     * @param userId User ID
     * @param mute   true: Mute; false: Unmute
     */
    public abstract void muteRemoteAudio(String userId, boolean mute);

    /**
     * Mutes all users
     *
     * @param mute true: Mute; false: Unmute
     */
    public abstract void muteAllRemoteAudio(boolean mute);

    /**
     * Audio effect control APIs
     */
    public abstract TXAudioEffectManager getAudioEffectManager();

    //////////////////////////////////////////////////////////
    //
    //                 Message sending APIs
    //
    //////////////////////////////////////////////////////////

    /**
     * Broadcasts a text chat message in the room. This API is generally used for on-screen comments.
     *
     * @param message  Text chat message
     * @param callback Callback for the sending result
     */
    public abstract void sendRoomTextMsg(String message, TRTCVoiceRoomCallback.ActionCallback callback);

    /**
     * Broadcast a custom (command) message in the room, which is generally used to broadcast liking and gifting
     * messages
     *
     * @param cmd      Custom command word used to distinguish between different message types
     * @param message  Text chat message
     * @param callback Callback for the sending result
     */
    public abstract void sendRoomCustomMsg(String cmd, String message, TRTCVoiceRoomCallback.ActionCallback callback);

    //////////////////////////////////////////////////////////
    //
    //                 Invitation signaling message APIs
    //
    //////////////////////////////////////////////////////////

    /**
     * Sends an invitation to a user
     *
     * @param cmd      Custom command of business
     * @param userId   User ID of invitee
     * @param content  Invitation content
     * @param callback Callback for the sending result
     * @return inviteId Invitation ID
     */
    public abstract String sendInvitation(String cmd, String userId, String content,
                                          TRTCVoiceRoomCallback.ActionCallback callback);

    /**
     * Accepts an invitation
     *
     * @param id       Invitation ID
     * @param callback Operation callback for invitation acceptance
     */
    public abstract void acceptInvitation(String id, TRTCVoiceRoomCallback.ActionCallback callback);

    /**
     * Rejects an invitation
     *
     * @param id       Invitation ID
     * @param callback Operation callback for rejecting an invitation
     */
    public abstract void rejectInvitation(String id, TRTCVoiceRoomCallback.ActionCallback callback);

    /**
     * Cancels an invitation
     *
     * @param id       Invitation ID
     * @param callback Callback for canceling an invitation
     */
    public abstract void cancelInvitation(String id, TRTCVoiceRoomCallback.ActionCallback callback);
}