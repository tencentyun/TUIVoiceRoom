package com.tencent.liteav.trtcvoiceroom.model.impl.room.impl;

public class SignallingData {

    private int version;
    private String businessID;
    private String platform;
    private String extInfo;
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

        private int room_id;
        private String cmd;
        private String seat_number;

        public int getRoomID() {
            return room_id;
        }

        public void setRoomID(int roomId) {
            this.room_id = roomId;
        }

        public String getCmd() {
            return cmd;
        }

        public void setCmd(String cmd) {
            this.cmd = cmd;
        }

        public String getSeatNumber() {
            return seat_number;
        }

        public void setSeatNumber(String seatNumber) {
            this.seat_number = seatNumber;
        }

    }
}
