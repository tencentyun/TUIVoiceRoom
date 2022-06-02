package com.tencent.liteav.trtcvoiceroom.ui.utils;

import android.content.Context;
import android.content.pm.ApplicationInfo;
import android.content.res.Resources;
import android.text.TextUtils;

import androidx.annotation.IntDef;

import com.tencent.liteav.trtcvoiceroom.R;
import com.tencent.qcloud.tuicore.util.PermissionRequester;

public class PermissionHelper {
    public static final int PERMISSION_MICROPHONE = 1;

    @IntDef({PERMISSION_MICROPHONE})
    public @interface PermissionType {
    }

    public static void requestPermission(Context context, @PermissionType int type, final PermissionCallback callback) {
        String permission = null;
        String reason = null;
        String reasonTitle = null;
        String deniedAlert = null;
        ApplicationInfo applicationInfo = context.getApplicationContext().getApplicationInfo();
        Resources resources = context.getResources();
        String appName = resources.getString(applicationInfo.labelRes);
        switch (type) {
            case PERMISSION_MICROPHONE: {
                permission = PermissionRequester.PermissionConstants.MICROPHONE;
                reasonTitle = resources.getString(R.string.trtcvoiceroom_permission_mic_reason_title, appName);
                reason = resources.getString(R.string.trtcvoiceroom_permission_mic_reason);
                deniedAlert = resources.getString(R.string.trtcvoiceroom_tips_start_audio);
                break;
            }
            default:
                break;
        }

        PermissionRequester.SimpleCallback simpleCallback = new PermissionRequester.SimpleCallback() {
            @Override
            public void onGranted() {
                if (callback != null) {
                    callback.onGranted();
                }
            }

            @Override
            public void onDenied() {
                if (callback != null) {
                    callback.onDenied();
                }
            }
        };
        if (!TextUtils.isEmpty(permission)) {
            PermissionRequester.permission(permission)
                    .reason(reason)
                    .reasonTitle(reasonTitle)
                    .deniedAlert(deniedAlert)
                    .callback(simpleCallback)
                    .permissionDialogCallback(new PermissionRequester.PermissionDialogCallback() {
                        @Override
                        public void onApproved() {
                            if (callback != null) {
                                callback.onDialogApproved();
                            }
                        }

                        @Override
                        public void onRefused() {
                            if (callback != null) {
                                callback.onDialogRefused();
                            }
                        }
                    })
                    .request();
        }
    }

    public interface PermissionCallback {
        void onGranted();

        void onDenied();

        void onDialogApproved();

        void onDialogRefused();
    }
}