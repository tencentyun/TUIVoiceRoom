package com.tencent.liteav.demo;

import android.content.Intent;
import android.graphics.Color;
import android.net.Uri;
import android.os.Build;

import androidx.appcompat.app.AppCompatActivity;

import android.os.Bundle;

import androidx.appcompat.widget.Toolbar;

import android.text.Editable;
import android.text.TextUtils;
import android.text.TextWatcher;
import android.util.Log;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;
import android.widget.EditText;
import android.widget.RelativeLayout;
import android.widget.TextView;


import com.blankj.utilcode.util.ToastUtils;
import com.tencent.imsdk.v2.V2TIMGroupInfoResult;
import com.tencent.liteav.basic.IntentUtils;
import com.tencent.liteav.basic.UserModel;
import com.tencent.liteav.basic.UserModelManager;
import com.tencent.liteav.debug.GenerateTestUserSig;
import com.tencent.liteav.trtcvoiceroom.model.TRTCVoiceRoom;
import com.tencent.liteav.trtcvoiceroom.model.TRTCVoiceRoomCallback;
import com.tencent.liteav.trtcvoiceroom.model.VoiceRoomManager;
import com.tencent.liteav.trtcvoiceroom.ui.room.VoiceRoomAudienceActivity;
import com.tencent.liteav.trtcvoiceroom.ui.room.VoiceRoomCreateDialog;
import com.tencent.trtc.TRTCCloudDef;

import java.util.Random;

public class MainActivity extends AppCompatActivity {
    private static final String TAG = "MainActivity";

    private Toolbar        mToolbar;
    private EditText       mEditRoomId;
    private TextView       mTextEnterRoom;
    private TRTCVoiceRoom  mTRTCVoiceRoom;
    private RelativeLayout mButtonCreateRoom;

    private static final String[] ROOM_COVER_ARRAY = {
            "https://liteav-test-1252463788.cos.ap-guangzhou.myqcloud.com/voice_room/voice_room_cover1.png",
            "https://liteav-test-1252463788.cos.ap-guangzhou.myqcloud.com/voice_room/voice_room_cover2.png",
            "https://liteav-test-1252463788.cos.ap-guangzhou.myqcloud.com/voice_room/voice_room_cover3.png",
            "https://liteav-test-1252463788.cos.ap-guangzhou.myqcloud.com/voice_room/voice_room_cover4.png",
            "https://liteav-test-1252463788.cos.ap-guangzhou.myqcloud.com/voice_room/voice_room_cover5.png",
            "https://liteav-test-1252463788.cos.ap-guangzhou.myqcloud.com/voice_room/voice_room_cover6.png",
            "https://liteav-test-1252463788.cos.ap-guangzhou.myqcloud.com/voice_room/voice_room_cover7.png",
            "https://liteav-test-1252463788.cos.ap-guangzhou.myqcloud.com/voice_room/voice_room_cover8.png",
            "https://liteav-test-1252463788.cos.ap-guangzhou.myqcloud.com/voice_room/voice_room_cover9.png",
            "https://liteav-test-1252463788.cos.ap-guangzhou.myqcloud.com/voice_room/voice_room_cover10.png",
            "https://liteav-test-1252463788.cos.ap-guangzhou.myqcloud.com/voice_room/voice_room_cover11.png",
            "https://liteav-test-1252463788.cos.ap-guangzhou.myqcloud.com/voice_room/voice_room_cover12.png",
    };

    private TextWatcher mEditTextWatcher = new TextWatcher() {
        @Override
        public void beforeTextChanged(CharSequence s, int start, int count, int after) {

        }

        @Override
        public void onTextChanged(CharSequence s, int start, int before, int count) {
            if (!TextUtils.isEmpty(mEditRoomId.getText().toString())) {
                mTextEnterRoom.setEnabled(true);
            } else {
                mTextEnterRoom.setEnabled(false);
            }
        }

        @Override
        public void afterTextChanged(Editable s) {

        }
    };

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        initStatusBar();
        setContentView(R.layout.activity_main);
        initView();
        initData();
    }

    private void initView() {
        findViewById(R.id.btn_link).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Intent intent = new Intent(Intent.ACTION_VIEW);
                intent.setData(Uri.parse("https://cloud.tencent.com/document/product/647/45667"));
                IntentUtils.safeStartActivity(MainActivity.this, intent);
            }
        });

        mToolbar = findViewById(R.id.toolbar);
        mToolbar.setNavigationOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                finish();
            }
        });

        mEditRoomId = findViewById(R.id.et_room_id);
        mEditRoomId.addTextChangedListener(mEditTextWatcher);

        mTextEnterRoom = findViewById(R.id.tv_enter);
        mTextEnterRoom.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                enterRoom(mEditRoomId.getText().toString());
            }
        });

        mButtonCreateRoom = findViewById(R.id.rl_create_room);
        mButtonCreateRoom.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                createRoom();
            }
        });
    }

    private void initData() {
        final UserModel userModel = UserModelManager.getInstance().getUserModel();
        mTRTCVoiceRoom = TRTCVoiceRoom.sharedInstance(this);
        mTRTCVoiceRoom.login(GenerateTestUserSig.SDKAPPID, userModel.userId, userModel.userSig,
                new TRTCVoiceRoomCallback.ActionCallback() {
                    @Override
                    public void onCallback(int code, String msg) {
                        if (code == 0) {
                            mTRTCVoiceRoom.setSelfProfile(userModel.userName, userModel.userAvatar,
                                    new TRTCVoiceRoomCallback.ActionCallback() {
                                        @Override
                                        public void onCallback(int code, String msg) {
                                            if (code == 0) {
                                                Log.d(TAG, "setSelfProfile success");
                                            }
                                        }
                                    });
                        }
                    }
                });
    }

    private void createRoom() {
        int index = new Random().nextInt(ROOM_COVER_ARRAY.length);
        String coverUrl = ROOM_COVER_ARRAY[index];
        String userName = UserModelManager.getInstance().getUserModel().userName;
        String userId = UserModelManager.getInstance().getUserModel().userId;
        VoiceRoomCreateDialog dialog = new VoiceRoomCreateDialog(this);
        dialog.showVoiceRoomCreateDialog(userId, userName, coverUrl, TRTCCloudDef.TRTC_AUDIO_QUALITY_DEFAULT, true);
    }

    private void enterRoom(final String roomIdStr) {
        VoiceRoomManager.getInstance().getGroupInfo(roomIdStr, new VoiceRoomManager.GetGroupInfoCallback() {
            @Override
            public void onSuccess(V2TIMGroupInfoResult result) {
                if (isRoomExist(result)) {
                    realEnterRoom(roomIdStr);
                } else {
                    ToastUtils.showLong(R.string.room_not_exist);
                }
            }

            @Override
            public void onFailed(int code, String msg) {
                ToastUtils.showLong(msg);
            }
        });
    }

    private void realEnterRoom(String roomIdStr) {
        UserModel userModel = UserModelManager.getInstance().getUserModel();
        String userId = userModel.userId;
        int roomId;
        try {
            roomId = Integer.parseInt(roomIdStr);
        } catch (Exception e) {
            roomId = 10000;
        }
        VoiceRoomAudienceActivity.enterRoom(this, roomId, userId, TRTCCloudDef.TRTC_AUDIO_QUALITY_DEFAULT);
    }

    private boolean isRoomExist(V2TIMGroupInfoResult result) {
        if (result == null) {
            Log.e(TAG, "room not exist result is null");
            return false;
        }
        return result.getResultCode() == 0;
    }

    private void initStatusBar() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            Window window = getWindow();
            window.clearFlags(WindowManager.LayoutParams.FLAG_TRANSLUCENT_STATUS);
            window.getDecorView().setSystemUiVisibility(View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                    | View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR);
            window.addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS);
            window.setStatusBarColor(Color.TRANSPARENT);
        }
    }
}