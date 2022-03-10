package com.tencent.liteav.trtcvoiceroom.model.impl.base;


import android.util.Log;

public class TRTCLogger {

    public static void e(String tag, String message) {
        Log.e(tag, message);
        callback("e", tag, message);
    }

    public static void w(String tag, String message) {
        Log.w(tag, message);
        callback("w", tag, message);
    }

    public static void i(String tag, String message) {
        Log.i(tag, message);
        callback("i", tag, message);
    }

    public static void d(String tag, String message) {
        Log.d(tag, message);
        callback("d", tag, message);
    }

    private static void callback(String level, String tag, String message) {
    }
}
