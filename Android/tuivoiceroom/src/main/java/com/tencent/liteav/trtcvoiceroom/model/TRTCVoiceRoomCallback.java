package com.tencent.liteav.trtcvoiceroom.model;

import java.util.List;

public class TRTCVoiceRoomCallback {
    /**
     * General callbacks
     */
    public interface ActionCallback {
        void onCallback(int code, String msg);
    }

    /**
     * Room information was obtained.
     */
    public interface RoomInfoCallback {
        void onCallback(int code, String msg, List<TRTCVoiceRoomDef.RoomInfo> list);
    }

    /**
     * Member information was obtained.
     */
    public interface UserListCallback {
        void onCallback(int code, String msg, List<TRTCVoiceRoomDef.UserInfo> list);
    }
}