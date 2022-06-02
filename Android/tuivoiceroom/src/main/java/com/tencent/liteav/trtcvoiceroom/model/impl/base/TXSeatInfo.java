package com.tencent.liteav.trtcvoiceroom.model.impl.base;

import java.io.Serializable;

public class TXSeatInfo implements Serializable {
    public static final transient int STATUS_UNUSED = 0;
    public static final transient int STATUS_USED   = 1;
    public static final transient int STATUS_CLOSE  = 2;

    public int     status;
    public boolean mute;
    public String  user;

    @Override
    public String toString() {
        return "TXSeatInfo{"
                + "status=" + status
                + ", mute=" + mute
                + ", user='" + user + '\''
                + '}';
    }
}