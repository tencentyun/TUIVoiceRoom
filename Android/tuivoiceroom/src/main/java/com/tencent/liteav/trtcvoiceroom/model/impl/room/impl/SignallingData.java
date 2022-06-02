package com.tencent.liteav.trtcvoiceroom.model.impl.room.impl;

import com.google.gson.annotations.SerializedName;

public class SignallingData {

    private int      version;
    private String   businessID;
    private String   platform;
    private String   extInfo;
    private DataInfo data;

    public int getVersion() {
        return version;
    }

    public void setVersion(int version) {
        this.version = version;
    }

    public String getBusinessID() {
        return businessID;
    }

    public void setBusinessID(String businessID) {
        this.businessID = businessID;
    }

    public String getPlatform() {
        return platform;
    }

    public void setPlatform(String platform) {
        this.platform = platform;
    }

    public String getExtInfo() {
        return extInfo;
    }

    public void setExtInfo(String extInfo) {
        this.extInfo = extInfo;
    }

    public DataInfo getData() {
        return data;
    }

    public void setData(DataInfo data) {
        this.data = data;
    }

    public static class DataInfo {

        @SerializedName("room_id")
        private int    roomId;
        private String cmd;

        @SerializedName("seat_number")
        private String seatNumber;

        public int getRoomID() {
            return roomId;
        }

        public void setRoomID(int roomId) {
            this.roomId = roomId;
        }

        public String getCmd() {
            return cmd;
        }

        public void setCmd(String cmd) {
            this.cmd = cmd;
        }

        public String getSeatNumber() {
            return seatNumber;
        }

        public void setSeatNumber(String seatNumber) {
            this.seatNumber = seatNumber;
        }

    }
}
