package com.tencent.liteav.trtcvoiceroom.ui.widget;

import android.content.Context;

import androidx.annotation.NonNull;

import com.google.android.material.bottomsheet.BottomSheetDialog;

import androidx.appcompat.widget.AppCompatImageButton;

import android.util.TypedValue;
import android.view.View;
import android.widget.TextView;

import com.tencent.liteav.trtcvoiceroom.R;
import com.tencent.liteav.trtcvoiceroom.model.TRTCVoiceRoom;
import com.tencent.liteav.trtcvoiceroom.ui.base.EarMonitorInstance;

import java.util.Locale;

public class MoreActionDialog extends BottomSheetDialog {
    protected AppCompatImageButton mBtnEarMonitor;
    protected TRTCVoiceRoom        mTRTCVoiceRoom;
    protected TextView             mTvEarMonitor;

    public MoreActionDialog(@NonNull Context context) {
        super(context, R.style.TRTCVoiceRoomDialogTheme);
        setContentView(R.layout.trtcvoiceroom_dialog_more_action);
        initView();
        mTRTCVoiceRoom = TRTCVoiceRoom.sharedInstance(getContext());
    }


    private void initView() {
        mBtnEarMonitor = (AppCompatImageButton) findViewById(R.id.btn_ear_monitor);
        mTvEarMonitor = (TextView) findViewById(R.id.tv_ear_monitor);
        boolean isOpen = EarMonitorInstance.getInstance().ismEarMonitorOpen();
        mBtnEarMonitor.setActivated(true);
        mBtnEarMonitor.setSelected(isOpen);
        mBtnEarMonitor.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                boolean currentMode = !mBtnEarMonitor.isSelected();
                mBtnEarMonitor.setSelected(currentMode);
                if (currentMode) {
                    mTRTCVoiceRoom.setVoiceEarMonitorEnable(true);
                } else {
                    mTRTCVoiceRoom.setVoiceEarMonitorEnable(false);
                }
                EarMonitorInstance.getInstance().updateEarMonitorState(currentMode);
            }
        });
        if (!isZh(getContext())) {
            mTvEarMonitor.setTextSize(TypedValue.COMPLEX_UNIT_SP, 8);
        }
    }

    public boolean isZh(Context context) {
        Locale locale = context.getResources().getConfiguration().locale;
        String language = locale.getLanguage();
        if (language.endsWith("zh")) {
            return true;
        } else {
            return false;
        }
    }
}
