package com.tencent.liteav.trtcvoiceroom.model;

import com.tencent.liteav.trtcvoiceroom.model.TRTCVoiceRoomDef.SeatInfo;
import com.tencent.trtc.TRTCCloudDef;

import java.util.List;

public interface TRTCVoiceRoomDelegate {
    /**
     * Component error message, which must be listened for and handled
     */
    void onError(int code, String message);

    /**
     * Component warning message
     */
    void onWarning(int code, String message);

    /**
     * Component log message
     */
    void onDebugLog(String message);

    /**
     * Callback for room termination, which will be received by the audience after the anchor calls `destroyRoom`
     */
    void onRoomDestroy(String roomId);

    /**
     * Notification of room information change
     */
    void onRoomInfoChange(TRTCVoiceRoomDef.RoomInfo roomInfo);

    /**
     * The entire seat list changed.
     *
     * @param seatInfoList Full seat list
     */
    void onSeatListChange(List<SeatInfo> seatInfoList);

    /**
     * A member became a speaker or was made a speaker by the anchor
     *
     * @param index Seat
     * @param user  Detailed user information
     */
    void onAnchorEnterSeat(int index, TRTCVoiceRoomDef.UserInfo user);

    /**
     * A member became a listener or was moved to listeners by the anchor
     *
     * @param index Seat
     * @param user  Detailed user information
     */
    void onAnchorLeaveSeat(int index, TRTCVoiceRoomDef.UserInfo user);

    /**
     * The anchor muted a member
     *
     * @param index  Seat
     * @param isMute Muted or unmuted
     */
    void onSeatMute(int index, boolean isMute);

    /**
     * Whether a user's mic was muted.
     *
     * @param userId User ID
     * @param mute   Muted or unmuted
     */
    void onUserMicrophoneMute(String userId, boolean mute);

    /**
     * The anchor blocked a seat
     *
     * @param index   Manipulated seat
     * @param isClose Whether the seat was blocked
     */
    void onSeatClose(int index, boolean isClose);

    /**
     * An audience member entered the room
     *
     * @param userInfo Detailed audience member information
     */
    void onAudienceEnter(TRTCVoiceRoomDef.UserInfo userInfo);

    /**
     * An audience member exited the room
     *
     * @param userInfo Detailed audience member information
     */
    void onAudienceExit(TRTCVoiceRoomDef.UserInfo userInfo);

    /**
     * Volume level change of speakers
     *
     * @param userVolumes User list
     * @param totalVolume Volume level. Value range: 0–100
     */
    void onUserVolumeUpdate(List<TRTCCloudDef.TRTCVolumeInfo> userVolumes, int totalVolume);

    /**
     * A text chat message was received.
     *
     * @param message  Text chat message
     * @param userInfo User information of the sender
     */
    void onRecvRoomTextMsg(String message, TRTCVoiceRoomDef.UserInfo userInfo);

    /**
     * A custom message was received.
     *
     * @param cmd      Custom command word used to distinguish between different message types
     * @param message  Text chat message
     * @param userInfo User information of the sender
     */
    void onRecvRoomCustomMsg(String cmd, String message, TRTCVoiceRoomDef.UserInfo userInfo);

    /**
     * An invitation was received
     *
     * @param id      Invitation ID
     * @param inviter Inviter's `userId`
     * @param cmd     Custom command word
     * @param content Content specified by business
     */
    void onReceiveNewInvitation(String id, String inviter, String cmd, String content);

    /**
     * The invitee accepted the invitation
     *
     * @param id      Invitation ID
     * @param invitee Invitee's `userId`
     */
    void onInviteeAccepted(String id, String invitee);

    /**
     * The invitee declined the invitation
     *
     * @param id      Invitation ID
     * @param invitee Invitee's `userId`
     */
    void onInviteeRejected(String id, String invitee);

    /**
     * The inviter canceled the invitation
     *
     * @param id      Invitation ID
     * @param inviter Inviter's `userId`
     */
    void onInvitationCancelled(String id, String inviter);
}