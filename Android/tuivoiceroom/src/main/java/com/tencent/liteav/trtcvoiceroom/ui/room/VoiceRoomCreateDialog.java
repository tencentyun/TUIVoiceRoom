package com.tencent.liteav.trtcvoiceroom.ui.room;

import android.content.Context;

import androidx.annotation.NonNull;
import androidx.appcompat.widget.SwitchCompat;

import com.google.android.material.bottomsheet.BottomSheetDialog;

import android.text.Editable;
import android.text.TextUtils;
import android.text.TextWatcher;
import android.view.View;
import android.widget.EditText;
import android.widget.TextView;

import com.blankj.utilcode.util.ToastUtils;
import com.tencent.liteav.basic.RTCubeUtils;
import com.tencent.liteav.basic.UserModelManager;
import com.tencent.liteav.trtcvoiceroom.R;

public class VoiceRoomCreateDialog extends BottomSheetDialog {
    private static final int MAX_LEN = 30;

    private EditText     mRoomNameEt;
    private TextView     mEnterTv;
    private SwitchCompat mSwitchBtn;
    private String       mUserName;
    private String       mUserId;
    private String       mCoverUrl;
    private int          mAudioQuality;
    private boolean      mNeedRequest;

    public void showVoiceRoomCreateDialog(String userId, String userName, String coverUrl, int audioQuality,
                                          boolean needRequest) {
        mUserId = userId;
        mUserName = userName;
        mCoverUrl = coverUrl;
        mAudioQuality = audioQuality;
        mNeedRequest = needRequest;
        show();
    }

    private TextWatcher mEditTextWatcher = new TextWatcher() {
        @Override
        public void beforeTextChanged(CharSequence s, int start, int count, int after) {

        }

        @Override
        public void onTextChanged(CharSequence s, int start, int before, int count) {
            if (!TextUtils.isEmpty(mRoomNameEt.getText().toString())) {
                mEnterTv.setEnabled(true);
            } else {
                mEnterTv.setEnabled(false);
            }
        }

        @Override
        public void afterTextChanged(Editable s) {
        }
    };

    public VoiceRoomCreateDialog(@NonNull Context context) {
        super(context, R.style.TRTCVoiceRoomDialogTheme);
        setContentView(R.layout.trtcvoiceroom_dialog_create_voice_room);
        initView();
        initData();
    }

    private void initData() {
        mUserName = UserModelManager.getInstance().getUserModel().userName;
        mUserId = UserModelManager.getInstance().getUserModel().userId;
        mRoomNameEt.addTextChangedListener(mEditTextWatcher);
        mEnterTv.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                createRoom();
            }
        });
        String showName = TextUtils.isEmpty(mUserName) ? mUserId : mUserName;
        mRoomNameEt.setText(getContext().getString(R.string.trtcvoiceroom_create_theme, showName));
    }

    private void createRoom() {
        String roomName = mRoomNameEt.getText().toString();
        if (TextUtils.isEmpty(roomName)) {
            return;
        }
        if (roomName.getBytes().length > MAX_LEN) {
            ToastUtils.showLong(getContext().getText(R.string.trtcvoiceroom_warning_room_name_too_long));
            return;
        }
        VoiceRoomAnchorActivity.createRoom(getContext(), roomName, mUserId, mUserName, mCoverUrl, mAudioQuality,
                mSwitchBtn.isChecked());
        dismiss();
    }

    private void initView() {
        mRoomNameEt = (EditText) findViewById(R.id.et_room_name);
        mEnterTv = (TextView) findViewById(R.id.tv_enter);
        mSwitchBtn = (SwitchCompat) findViewById(R.id.switch_item);
        mRoomNameEt.setFocusableInTouchMode(!RTCubeUtils.isRTCubeApp(getContext()));
    }
}
