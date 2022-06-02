package com.tencent.liteav.trtcvoiceroom.model;

import java.util.List;

public class TRTCVoiceRoomDef {
    // Version number defined by the current app module
    public static final String APP_VERSION = "9.5.0.1674";

    // Group attribute write conflict. Get the
    // latest group attribute first before writing. This error code is supported in IM SDK 5.6 or later. The seat
    // information has changed and needs to be pulled again.
    public static final int ERR_SVR_GROUP_ATTRIBUTE_WRITE_CONFLICT = 10056;

    public static final int ERR_CALL_METHOD_LIMIT = 10001; // API call frequency limit

    public static final int ERR_CONNECT_SERVICE_TIMEOUT = 10002;

    public static class SeatInfo {
        public static final transient int STATUS_UNUSED = 0;
        public static final transient int STATUS_USED   = 1;
        public static final transient int STATUS_CLOSE  = 2;

        // Seat status. Valid values: 0: Unused; 1: Used; 2: Closed
        public int     status;
        // Whether the seat is muted
        public boolean mute;
        public String  userId;

        @Override
        public String toString() {
            return "SeatInfo{"
                    + "status=" + status
                    + ", mute=" + mute
                    + ", userId='" + userId + '\''
                    + '}';
        }
    }


    public static class RoomParam {
        public String         roomName;
        // Room cover image
        public String         coverUrl;
        // Whether users need the room owner’s consent to speak
        public boolean        needRequest;
        public int            seatCount;
        public List<SeatInfo> seatInfoList;

        @Override
        public String toString() {
            return "RoomParam{"
                    + "roomName='" + roomName + '\''
                    + ", coverUrl='" + coverUrl + '\''
                    + ", needRequest=" + needRequest
                    + ", seatCount=" + seatCount
                    + ", seatInfoList=" + seatInfoList
                    + '}';
        }
    }

    public static class UserInfo {
        public String userId;
        public String userName;
        public String userAvatar;

        @Override
        public String toString() {
            return "UserInfo{"
                    + "userId='" + userId + '\''
                    + ", userName='" + userName + '\''
                    + ", userAvatar='" + userAvatar + '\''
                    + '}';
        }
    }

    public static class RoomInfo {
        public int     roomId;
        public String  roomName;
        public String  coverUrl;
        public String  ownerId;
        public String  ownerName;
        public int     memberCount;
        public boolean needRequest;

        @Override
        public String toString() {
            return "RoomInfo{"
                    + "roomId=" + roomId
                    + ", roomName='" + roomName + '\''
                    + ", coverUrl='" + coverUrl + '\''
                    + ", ownerId='" + ownerId + '\''
                    + ", ownerName='" + ownerName + '\''
                    + ", memberCount=" + memberCount
                    + ", needRequest=" + needRequest
                    + '}';
        }
    }
}