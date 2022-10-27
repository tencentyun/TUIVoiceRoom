package com.tencent.liteav.trtcvoiceroom.model.impl.room.impl;

import android.content.Context;
import android.os.Handler;
import android.os.Looper;
import android.os.Message;
import android.text.TextUtils;
import android.util.Pair;

import com.google.gson.Gson;
import com.tencent.imsdk.v2.V2TIMCallback;
import com.tencent.imsdk.v2.V2TIMGroupInfo;
import com.tencent.imsdk.v2.V2TIMGroupListener;
import com.tencent.imsdk.v2.V2TIMGroupMemberFullInfo;
import com.tencent.imsdk.v2.V2TIMGroupMemberInfo;
import com.tencent.imsdk.v2.V2TIMGroupMemberInfoResult;
import com.tencent.imsdk.v2.V2TIMManager;
import com.tencent.imsdk.v2.V2TIMMessage;
import com.tencent.imsdk.v2.V2TIMSDKConfig;
import com.tencent.imsdk.v2.V2TIMSDKListener;
import com.tencent.imsdk.v2.V2TIMSignalingListener;
import com.tencent.imsdk.v2.V2TIMSimpleMsgListener;
import com.tencent.imsdk.v2.V2TIMUserFullInfo;
import com.tencent.imsdk.v2.V2TIMUserStatus;
import com.tencent.imsdk.v2.V2TIMValueCallback;
import com.tencent.liteav.trtcvoiceroom.R;
import com.tencent.liteav.trtcvoiceroom.model.TRTCVoiceRoomDef;
import com.tencent.liteav.trtcvoiceroom.model.impl.TRTCVoiceRoomImpl;
import com.tencent.liteav.trtcvoiceroom.model.impl.base.TRTCLogger;
import com.tencent.liteav.trtcvoiceroom.model.impl.base.TXCallback;
import com.tencent.liteav.trtcvoiceroom.model.impl.base.TXRoomInfo;
import com.tencent.liteav.trtcvoiceroom.model.impl.base.TXSeatInfo;
import com.tencent.liteav.trtcvoiceroom.model.impl.base.TXUserInfo;
import com.tencent.liteav.trtcvoiceroom.model.impl.base.TXUserListCallback;
import com.tencent.liteav.trtcvoiceroom.model.impl.room.ITXRoomServiceDelegate;
import com.tencent.qcloud.tuicore.TUILogin;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Set;

public class TXRoomService extends V2TIMSDKListener {
    private static final String TAG = "TXRoomService";

    private static final int CODE_ERROR               = -1;
    private static final int NOT_IN_SEAT              = -1;
    private static final int MSG_ON_USER_OFFLINE      = 10001;
    private static final int MSG_KICK_USER_ON_OFFLINE = 10002;

    private static TXRoomService          sInstance;
    private        Context                mContext;
    private        ITXRoomServiceDelegate mDelegate;
    private        boolean                mIsInitIMSDK;
    private        boolean                mIsLogin;
    private        boolean                mIsEnterRoom;

    private String                  mRoomId;
    private String                  mSelfUserId;
    private String                  mOwnerUserId;
    private TXRoomInfo              mTXRoomInfo;
    private VoiceRoomSimpleListener mSimpleListener;
    private List<TXSeatInfo>        mTXSeatInfoList;
    private String                  mSelfUserName;
    private VoiceRoomGroupListener  mGroupListener;
    private VoiceRoomSignalListener mSignalListener;
    private UserStatusListener      mUserStatusListener;
    private Handler                 mMainHandler;
    private LinkedList<String>      mOfflineUserList;
    private Map<Integer, String>    mOfflineKickMap;
    private boolean                 mIsKickUserOnOffline;

    public static synchronized TXRoomService getInstance() {
        if (sInstance == null) {
            sInstance = new TXRoomService();
        }
        return sInstance;
    }

    private TXRoomService() {
        mSelfUserId = "";
        mOwnerUserId = "";
        mRoomId = "";
        mTXRoomInfo = null;
        mSimpleListener = new VoiceRoomSimpleListener();
        mGroupListener = new VoiceRoomGroupListener();
        mSignalListener = new VoiceRoomSignalListener();
        mUserStatusListener = new UserStatusListener();
        mOfflineUserList = new LinkedList<>();
        mOfflineKickMap = new HashMap<>();
        mMainHandler = new Handler(Looper.getMainLooper(), new HandlerCallback());
    }

    public void init(Context context) {
        mContext = context;
    }

    public void setDelegate(ITXRoomServiceDelegate delegate) {
        mDelegate = delegate;
    }

    public void login(int sdkAppId, final String userId, String userSig, final TXCallback callback) {
        if (TUILogin.isUserLogined()) {
            mIsLogin = true;
            mSelfUserId = userId;
            TRTCLogger.i(TAG, "already login.");
            if (callback != null) {
                callback.onCallback(0, "login im success.");
            }
            return;
        }
        if (!mIsInitIMSDK) {
            V2TIMSDKConfig config = new V2TIMSDKConfig();
            TUILogin.init(mContext, sdkAppId, config, null);
            mIsInitIMSDK = true;
        }
        TUILogin.login(userId, userSig, new V2TIMCallback() {
            @Override
            public void onError(int code, String msg) {
                TRTCLogger.e(TAG, "login fail code: " + code + " msg:" + msg);
                if (callback != null) {
                    callback.onCallback(code, msg);
                }
            }

            @Override
            public void onSuccess() {
                TRTCLogger.i(TAG, "login onSuccess");
                mIsLogin = true;
                mSelfUserId = userId;
                getSelfInfo();
                if (callback != null) {
                    callback.onCallback(0, "login im success.");
                }
            }
        });
    }

    private void initIMListener() {
        V2TIMManager.getInstance().addGroupListener(mGroupListener);
        V2TIMManager.getSignalingManager().addSignalingListener(mSignalListener);
        V2TIMManager.getMessageManager();
        V2TIMManager.getInstance().addSimpleMsgListener(mSimpleListener);
        V2TIMManager.getInstance().addIMSDKListener(mUserStatusListener);
    }

    private void getSelfInfo() {
        List<String> userIds = new ArrayList<>();
        userIds.add(mSelfUserId);
        V2TIMManager.getInstance().getUsersInfo(userIds, new V2TIMValueCallback<List<V2TIMUserFullInfo>>() {
            @Override
            public void onError(int i, String s) {

            }

            @Override
            public void onSuccess(List<V2TIMUserFullInfo> v2TIMUserFullInfos) {
                mSelfUserName = v2TIMUserFullInfos.get(0).getNickName();
            }
        });
    }


    public void logout(final TXCallback callback) {
        if (!isLogin()) {
            TRTCLogger.e(TAG, "start logout fail, not login yet.");
            if (callback != null) {
                callback.onCallback(CODE_ERROR, "start logout fail, not login yet.");
            }
            return;
        }
        if (isEnterRoom()) {
            TRTCLogger.e(TAG, "start logout fail, you are in room:" + mRoomId + ", please exit room before logout.");
            if (callback != null) {
                callback.onCallback(CODE_ERROR, "start logout fail, you are in room:" + mRoomId
                        + ", please exit room before logout.");
            }
            return;
        }
        mIsLogin = false;
        mSelfUserId = "";
        TUILogin.logout(new V2TIMCallback() {
            @Override
            public void onSuccess() {
                TRTCLogger.i(TAG, "logout im success.");
                if (callback != null) {
                    callback.onCallback(0, "login im success.");
                }
            }

            @Override
            public void onError(int i, String s) {
                TRTCLogger.e(TAG, "logout fail, code:" + i + " msg:" + s);
                if (callback != null) {
                    callback.onCallback(i, s);
                }
            }
        });
    }

    public void setSelfProfile(final String userName, final String avatarUrl, final TXCallback callback) {
        if (!isLogin()) {
            TRTCLogger.e(TAG, "set profile fail, not login yet.");
            if (callback != null) {
                callback.onCallback(CODE_ERROR, "set profile fail, not login yet.");
            }
            return;
        }
        mSelfUserName = userName;
        V2TIMUserFullInfo v2TIMUserFullInfo = new V2TIMUserFullInfo();
        v2TIMUserFullInfo.setNickname(userName);
        v2TIMUserFullInfo.setFaceUrl(avatarUrl);
        V2TIMManager.getInstance().setSelfInfo(v2TIMUserFullInfo, new V2TIMCallback() {
            @Override
            public void onError(int code, String desc) {
                TRTCLogger.e(TAG, "set profile code:" + code + " msg:" + desc);
                if (callback != null) {
                    callback.onCallback(code, desc);
                }
            }

            @Override
            public void onSuccess() {
                TRTCLogger.i(TAG, "set profile success.");
                if (callback != null) {
                    callback.onCallback(0, "set profile success.");
                }
            }
        });
    }

    public void createRoom(final String roomId, final String roomName, final String coverUrl, boolean needRequest,
                           final List<TXSeatInfo> txSeatInfoList, final TXCallback callback) {
        if (isEnterRoom()) {
            TRTCLogger.e(TAG, "you have been in room:" + mRoomId + " can't create another room:" + roomId);
            if (callback != null) {
                callback.onCallback(CODE_ERROR,
                        "you have been in room:" + mRoomId + " can't create another room:" + roomId);
            }
            return;
        }
        if (!isLogin()) {
            TRTCLogger.e(TAG, "im not login yet, create room fail.");
            if (callback != null) {
                callback.onCallback(CODE_ERROR, "im not login yet, create room fail.");
            }
            return;
        }
        resetStatus();
        final V2TIMManager manager = V2TIMManager.getInstance();
        mRoomId = roomId;
        mOwnerUserId = mSelfUserId;
        mTXSeatInfoList = txSeatInfoList;
        mTXRoomInfo = new TXRoomInfo();
        mTXRoomInfo.ownerId = mSelfUserId;
        mTXRoomInfo.ownerName = mSelfUserName;
        mTXRoomInfo.roomName = roomName;
        mTXRoomInfo.cover = coverUrl;
        mTXRoomInfo.seatSize = txSeatInfoList.size();
        mTXRoomInfo.needRequest = needRequest ? 1 : 0;
        manager.createGroup(V2TIMManager.GROUP_TYPE_AVCHATROOM, roomId, roomName, new V2TIMValueCallback<String>() {
            @Override
            public void onError(final int code, String s) {
                TRTCLogger.e(TAG, "createRoom error " + code);
                String msg = s;
                if (code == 10036) {
                    msg = mContext.getString(R.string.trtcvoiceroom_create_room_limit);
                }
                if (code == 10037) {
                    msg = mContext.getString(R.string.trtcvoiceroom_create_or_join_group_limit);
                }
                if (code == 10038) {
                    msg = mContext.getString(R.string.trtcvoiceroom_group_member_limit);
                }
                if (code == 10025 || code == 10021) {
                    // 10025 indicates that the group owner is the local user, and the room is created successfully
                    setGroupInfo(roomId, roomName, coverUrl, mSelfUserName);
                    manager.joinGroup(roomId, "", new V2TIMCallback() {
                        @Override
                        public void onError(int code, String msg) {
                            TRTCLogger.e(TAG, "group has been created.join group failed, code:" + code + " msg:" + msg);
                            if (callback != null) {
                                callback.onCallback(code, msg);
                            }
                        }

                        @Override
                        public void onSuccess() {
                            TRTCLogger.i(TAG, "group has been created.join group success.");
                            onCreateSuccess(callback);
                        }
                    });
                } else {
                    TRTCLogger.e(TAG, "create room fail, code:" + code + " msg:" + msg);
                    if (callback != null) {
                        callback.onCallback(code, msg);
                    }
                }
            }

            @Override
            public void onSuccess(String s) {
                setGroupInfo(roomId, roomName, coverUrl, mSelfUserName);
                onCreateSuccess(callback);
            }
        });
    }

    private void setGroupInfo(String roomId, String roomName, String coverUrl, String userName) {
        V2TIMGroupInfo groupInfo = new V2TIMGroupInfo();
        groupInfo.setGroupID(roomId);
        groupInfo.setGroupName(roomName);
        groupInfo.setFaceUrl(coverUrl);
        groupInfo.setIntroduction(userName);
        V2TIMManager.getGroupManager().setGroupInfo(groupInfo, new V2TIMCallback() {
            @Override
            public void onError(int i, String s) {
                TRTCLogger.w(TAG, "set group info error:" + i + " msg:" + s);
            }

            @Override
            public void onSuccess() {
                TRTCLogger.i(TAG, "set group info success");
            }
        });
    }

    private void onCreateSuccess(final TXCallback callback) {
        initIMListener();
        V2TIMManager.getGroupManager().initGroupAttributes(mRoomId, IMProtocol.getInitRoomMap(mTXRoomInfo,
                mTXSeatInfoList), new V2TIMCallback() {
            @Override
            public void onError(int code, String message) {
                TRTCLogger.e(TAG, "init room info and seat failed. code:" + code);
                if (code == TRTCVoiceRoomDef.ERR_SVR_GROUP_ATTRIBUTE_WRITE_CONFLICT) {
                    getGroupAttrs(new TXCallback() {
                        @Override
                        public void onCallback(int code, String msg) {
                            if (callback != null) {
                                if (code == 0) {
                                    callback.onCallback(0, "create room success.");
                                } else {
                                    callback.onCallback(code, msg);
                                }
                            }
                        }
                    });
                } else {
                    if (callback != null) {
                        callback.onCallback(code, message);
                    }
                }
            }

            @Override
            public void onSuccess() {
                mIsEnterRoom = true;
                TRTCLogger.i(TAG, "create room success.");
                if (callback != null) {
                    callback.onCallback(0, "init room info and seat success");
                }
            }
        });
    }

    public void destroyRoom(final TXCallback callback) {
        if (!isOwner()) {
            TRTCLogger.e(TAG, "only owner could destroy room");
            if (callback != null) {
                callback.onCallback(-1, "only owner could destroy room");
            }
            return;
        }
        V2TIMManager.getInstance().dismissGroup(mRoomId, new V2TIMCallback() {
            @Override
            public void onError(int code, String msg) {
                TRTCLogger.e(TAG, "destroy error, code:" + code + " msg:" + msg);
                if (code == 10007) {
                    //Insufficient permissions
                    TRTCLogger.i(TAG, "you're not real owner, start logic destroy.");
                    cleanGroupAttr();
                    sendGroupMsg(IMProtocol.getRoomDestroyMsg(), callback);
                }
                resetStatus();
            }

            @Override
            public void onSuccess() {
                TRTCLogger.i(TAG, "you're real owner, destroy success.");
                resetStatus();
                if (callback != null) {
                    callback.onCallback(0, "destroy success.");
                }
            }
        });
    }

    public void resetStatus() {
        TRTCLogger.i(TAG, "resetStatus");
        V2TIMManager.getInstance().removeGroupListener(mGroupListener);
        V2TIMManager.getSignalingManager().removeSignalingListener(mSignalListener);
        V2TIMManager.getInstance().removeSimpleMsgListener(mSimpleListener);
        V2TIMManager.getInstance().unsubscribeUserStatus(null, null);
        V2TIMManager.getInstance().removeIMSDKListener(mUserStatusListener);
        mMainHandler.removeMessages(MSG_ON_USER_OFFLINE);
        mMainHandler.removeMessages(MSG_KICK_USER_ON_OFFLINE);
        mIsEnterRoom = false;
        mIsKickUserOnOffline = false;
        mRoomId = "";
        mOwnerUserId = "";
        mOfflineUserList.clear();
        mOfflineKickMap.clear();
    }

    private void cleanGroupAttr() {
        V2TIMManager.getGroupManager().deleteGroupAttributes(mRoomId, null, null);
    }

    public void enterRoom(final String roomId, final TXCallback callback) {
        resetStatus();
        mRoomId = roomId;
        V2TIMManager.getInstance().joinGroup(roomId, "", new V2TIMCallback() {
            @Override
            public void onError(int i, String s) {
                if (i == 10013) {
                    onSuccess();
                } else {
                    TRTCLogger.e(TAG, "join group error, enter room fail. code:" + i + " msg:" + s);
                    if (callback != null) {
                        callback.onCallback(-1, "join group error, enter room fail. code:" + i + " msg:" + s);
                    }
                }
            }

            @Override
            public void onSuccess() {
                V2TIMManager.getGroupManager().getGroupAttributes(roomId, null, new V2TIMValueCallback<Map<String,
                        String>>() {
                    @Override
                    public void onError(int i, String s) {
                        TRTCLogger.e(TAG, "get group attrs error, enter room fail. code:" + i + " msg:" + s);
                        if (callback != null) {
                            callback.onCallback(-1, "get group attrs error, enter room fail. code:" + i + " msg:" + s);
                        }
                    }

                    @Override
                    public void onSuccess(Map<String, String> attrMap) {
                        initIMListener();
                        mTXRoomInfo = IMProtocol.getRoomInfoFromAttr(attrMap);
                        if (mTXRoomInfo == null) {
                            TRTCLogger.e(TAG, "group room info is empty, enter room fail.");
                            if (callback != null) {
                                callback.onCallback(-1, "group room info is empty, enter room fail.");
                            }
                            return;
                        }
                        if (mTXRoomInfo.seatSize == null) {
                            mTXRoomInfo.seatSize = 0;
                        }
                        mTXSeatInfoList = IMProtocol.getSeatListFromAttr(attrMap, mTXRoomInfo.seatSize);
                        mTXRoomInfo.roomId = roomId;
                        TRTCLogger.i(TAG, "enter room success: " + mRoomId);
                        mIsEnterRoom = true;
                        mOwnerUserId = mTXRoomInfo.ownerId;
                        if (mDelegate != null) {
                            mDelegate.onRoomInfoChange(mTXRoomInfo);
                            mDelegate.onSeatInfoListChange(mTXSeatInfoList);
                        }
                        if (callback != null) {
                            callback.onCallback(0, "enter room success.");
                        }
                    }
                });
            }
        });
    }

    public void exitRoom(final TXCallback callback) {
        if (!isEnterRoom()) {
            TRTCLogger.e(TAG, "not enter room yet, can't exit room.");
            if (callback != null) {
                callback.onCallback(CODE_ERROR, "not enter room yet, can't exit room.");
            }
            return;
        }
        V2TIMManager.getInstance().quitGroup(mRoomId, new V2TIMCallback() {
            @Override
            public void onError(int i, String s) {
                TRTCLogger.e(TAG, "exit room fail, code:" + i + " msg:" + s);
                resetStatus();
                if (callback != null) {
                    callback.onCallback(i, s);
                }
            }

            @Override
            public void onSuccess() {
                TRTCLogger.i(TAG, "exit room success.");
                resetStatus();
                if (callback != null) {
                    callback.onCallback(0, "exit room success.");
                }
            }
        });
    }

    public void takeSeat(int index, TXCallback callback) {
        if (mTXSeatInfoList == null || index >= mTXSeatInfoList.size()) {
            TRTCLogger.e(TAG, "seat info list is empty or index error");
            if (callback != null) {
                callback.onCallback(-1, "seat info list is empty or index error");
            }
            return;
        }
        TXSeatInfo info = mTXSeatInfoList.get(index);
        if (info.status == TXSeatInfo.STATUS_USED || info.status == TXSeatInfo.STATUS_CLOSE) {
            TRTCLogger.e(TAG, "seat status is " + info.status);
            if (callback != null) {
                callback.onCallback(-1, info.status == TXSeatInfo.STATUS_USED ? "seat is used" : "seat is close");
            }
            return;
        }
        if (TextUtils.isEmpty(mSelfUserId)) {
            if (callback != null) {
                callback.onCallback(-1, "self userId is null");
            }
            return;
        }
        TXSeatInfo changeInfo = new TXSeatInfo();
        changeInfo.status = TXSeatInfo.STATUS_USED;
        changeInfo.mute = info.mute;
        changeInfo.user = mSelfUserId;
        HashMap<String, String> map = IMProtocol.getSeatInfoJsonStr(index, changeInfo);
        modifyGroupAttrs(map, callback);
    }

    public void leaveSeat(int index, TXCallback callback) {
        if (mTXSeatInfoList == null || index >= mTXSeatInfoList.size()) {
            TRTCLogger.e(TAG, "seat info list is empty or index error");
            if (callback != null) {
                callback.onCallback(-1, "seat info list is empty or index error");
            }
            return;
        }
        TXSeatInfo info = mTXSeatInfoList.get(index);
        if (!mSelfUserId.equals(info.user)) {
            TRTCLogger.e(TAG, mSelfUserId + " not in the seat " + index);
            if (callback != null) {
                callback.onCallback(-1, mSelfUserId + " not in the seat " + index);
            }
            return;
        }

        TXSeatInfo changeInfo = new TXSeatInfo();
        changeInfo.status = TXSeatInfo.STATUS_UNUSED;
        changeInfo.mute = info.mute;
        changeInfo.user = "";
        HashMap<String, String> map = IMProtocol.getSeatInfoJsonStr(index, changeInfo);
        modifyGroupAttrs(map, callback);
    }

    public void pickSeat(int index, String userId, TXCallback callback) {
        if (TextUtils.isEmpty(userId)) {
            if (callback != null) {
                callback.onCallback(-1, "userId is null");
            }
            return;
        }

        if (!isOwner()) {
            TRTCLogger.e(TAG, "only owner could pick seat");
            if (callback != null) {
                callback.onCallback(-1, "only owner could pick seat");
            }
            return;
        }
        if (mTXSeatInfoList == null || index >= mTXSeatInfoList.size()) {
            TRTCLogger.e(TAG, "seat info list is empty");
            if (callback != null) {
                callback.onCallback(-1, "seat info list is empty or index error");
            }
            return;
        }
        TXSeatInfo info = mTXSeatInfoList.get(index);
        if (info.status == TXSeatInfo.STATUS_USED || info.status == TXSeatInfo.STATUS_CLOSE) {
            TRTCLogger.e(TAG, "seat status is " + info.status);
            if (callback != null) {
                callback.onCallback(-1, info.status == TXSeatInfo.STATUS_USED ? "seat is used" : "seat is close");
            }
            return;
        }

        TXSeatInfo changeInfo = new TXSeatInfo();
        changeInfo.status = TXSeatInfo.STATUS_USED;
        changeInfo.mute = info.mute;
        changeInfo.user = userId;
        HashMap<String, String> map = IMProtocol.getSeatInfoJsonStr(index, changeInfo);
        modifyGroupAttrs(map, callback);
    }

    public void kickSeat(int index, TXCallback callback) {
        if (!isOwner()) {
            TRTCLogger.e(TAG, "only owner could kick seat");
            if (callback != null) {
                callback.onCallback(-1, "only owner could kick seat");
            }
            return;
        }
        if (mTXSeatInfoList == null || index >= mTXSeatInfoList.size()) {
            TRTCLogger.e(TAG, "seat info list is empty or index error");
            if (callback != null) {
                callback.onCallback(-1, "seat info list is empty or index error");
            }
            return;
        }

        TXSeatInfo info = mTXSeatInfoList.get(index);

        TXSeatInfo changeInfo = new TXSeatInfo();
        changeInfo.status = TXSeatInfo.STATUS_UNUSED;
        changeInfo.mute = info.mute;
        changeInfo.user = "";
        HashMap<String, String> map = IMProtocol.getSeatInfoJsonStr(index, changeInfo);
        modifyGroupAttrs(map, callback);
    }

    public void muteSeat(int index, boolean mute, TXCallback callback) {
        if (!isOwner()) {
            TRTCLogger.e(TAG, "only owner could kick seat");
            if (callback != null) {
                callback.onCallback(-1, "only owner could kick seat");
            }
            return;
        }

        TXSeatInfo info = mTXSeatInfoList.get(index);

        TXSeatInfo changeInfo = new TXSeatInfo();
        changeInfo.status = info.status;
        changeInfo.mute = mute;
        changeInfo.user = info.user;
        HashMap<String, String> map = IMProtocol.getSeatInfoJsonStr(index, changeInfo);
        modifyGroupAttrs(map, callback);
    }

    public void closeSeat(int index, boolean isClose, TXCallback callback) {
        if (!isOwner()) {
            TRTCLogger.e(TAG, "only owner could close seat");
            if (callback != null) {
                callback.onCallback(-1, "only owner could close seat");
            }
            return;
        }
        int changeStatus = isClose ? TXSeatInfo.STATUS_CLOSE : TXSeatInfo.STATUS_UNUSED;
        TXSeatInfo info = mTXSeatInfoList.get(index);
        if (info.status == changeStatus) {
            if (callback != null) {
                callback.onCallback(0, "already in close");
            }
            return;
        }
        TXSeatInfo changeInfo = new TXSeatInfo();
        changeInfo.status = changeStatus;
        changeInfo.mute = info.mute;
        changeInfo.user = "";
        HashMap<String, String> map = IMProtocol.getSeatInfoJsonStr(index, changeInfo);
        modifyGroupAttrs(map, callback);
    }

    public void moveSeat(int targetIndex, TXCallback callback) {
        if (!isRoomParamsAvailable(callback)) {
            return;
        }

        int srcIndex = getCurrentSeatIndex();
        if (!isSeatIndexAvailable(srcIndex, targetIndex, callback)) {
            return;
        }

        TXSeatInfo srcSeatInfo = mTXSeatInfoList.get(srcIndex);
        if (!mSelfUserId.equals(srcSeatInfo.user)) {
            TRTCLogger.e(TAG, mSelfUserId + " not in the seat " + srcIndex);
            if (callback != null) {
                callback.onCallback(-1, mSelfUserId + " not in the seat " + srcIndex);
            }
            return;
        }

        TXSeatInfo targetSeatInfo = mTXSeatInfoList.get(targetIndex);
        if (targetSeatInfo.status == TXSeatInfo.STATUS_USED || targetSeatInfo.status == TXSeatInfo.STATUS_CLOSE) {
            TRTCLogger.e(TAG, "seat status is " + targetSeatInfo.status);
            if (callback != null) {
                callback.onCallback(-1, targetSeatInfo.status == TXSeatInfo.STATUS_USED
                        ? "seat is used" : "seat is " + "close");
            }
            return;
        }

        TXSeatInfo srcChangeInfo = new TXSeatInfo();
        srcChangeInfo.status = TXSeatInfo.STATUS_UNUSED;
        srcChangeInfo.mute = srcSeatInfo.mute;
        srcChangeInfo.user = "";

        TXSeatInfo targetChangeInfo = new TXSeatInfo();
        targetChangeInfo.status = TXSeatInfo.STATUS_USED;
        targetChangeInfo.mute = targetSeatInfo.mute;
        targetChangeInfo.user = mSelfUserId;

        HashMap<String, String> map = IMProtocol.getMoveSeatInfoJsonStr(srcIndex, srcChangeInfo, targetIndex,
                targetChangeInfo);
        modifyGroupAttrs(map, callback);
    }

    private int getCurrentSeatIndex() {
        int srcIndex = -1;
        for (int i = 0; i < mTXSeatInfoList.size(); i++) {
            TXSeatInfo info = mTXSeatInfoList.get(i);
            if (info != null && mSelfUserId.equals(info.user)) {
                srcIndex = i;
                break;
            }
        }
        return srcIndex;
    }

    private boolean isSeatIndexAvailable(int currentIndex, int targetIndex, TXCallback callback) {
        String message;
        if (currentIndex == -1) {
            message = mSelfUserId + " not in the seat, currentIndex is -1";
        } else if (targetIndex == -1) {
            message = currentIndex + " not in the seat, targetIndex is -1";
        } else if (currentIndex > mTXSeatInfoList.size()) {
            message = "currentIndex is error";
        } else if (targetIndex > mTXSeatInfoList.size()) {
            message = "targetIndex is error";
        } else {
            return true;
        }
        if (callback != null) {
            callback.onCallback(-1, message);
        }
        return false;
    }

    private boolean isRoomParamsAvailable(TXCallback callback) {
        String message;
        if (mTXSeatInfoList == null) {
            message = "seat info list is empty";
        } else if (mSelfUserId == null) {
            message = "self userId  is empty";
        } else {
            return true;
        }
        if (callback != null) {
            callback.onCallback(-1, message);
        }
        return false;
    }

    private void getGroupAttrs(final TXCallback callback) {
        V2TIMManager.getGroupManager().getGroupAttributes(mRoomId, null, new V2TIMValueCallback<Map<String, String>>() {
            @Override
            public void onError(int i, String s) {
                TRTCLogger.e(TAG, "get group attrs error, code:" + i + " msg:" + s);
                if (callback != null) {
                    callback.onCallback(i, s);
                }
            }

            @Override
            public void onSuccess(Map<String, String> attrMap) {
                TRTCLogger.e(TAG, "getGroupAttrs attrMap:" + attrMap);
                mIsEnterRoom = true;
                mOwnerUserId = mTXRoomInfo.ownerId;
                mTXRoomInfo = IMProtocol.getRoomInfoFromAttr(attrMap);
                mTXRoomInfo.roomId = mRoomId;
                if (mTXRoomInfo == null) {
                    TRTCLogger.e(TAG, "group room info is empty");
                    callback.onCallback(-1, "group room info is empty");
                    return;
                }
                if (mTXRoomInfo.seatSize == null) {
                    mTXRoomInfo.seatSize = 0;
                }
                if (mDelegate != null) {
                    mDelegate.onRoomInfoChange(mTXRoomInfo);
                }
                onSeatAttrMapChanged(attrMap, mTXRoomInfo.seatSize);
                if (callback != null) {
                    callback.onCallback(0, "success");
                }
            }
        });
    }

    private void onSeatAttrMapChanged(Map<String, String> attrMap, int seatSize) {
        List<TXSeatInfo> txSeatInfoList = IMProtocol.getSeatListFromAttr(attrMap, seatSize);
        final List<TXSeatInfo> oldTXSeatInfoList = mTXSeatInfoList;
        mTXSeatInfoList = txSeatInfoList;
        if (mDelegate != null) {
            mDelegate.onSeatInfoListChange(txSeatInfoList);
        }
        try {
            for (int i = 0; i < seatSize; i++) {
                TXSeatInfo oldInfo = oldTXSeatInfoList.get(i);
                TXSeatInfo newInfo = txSeatInfoList.get(i);
                if (oldInfo.status == TXSeatInfo.STATUS_CLOSE && newInfo.status == TXSeatInfo.STATUS_UNUSED) {
                    onSeatClose(i, false);
                } else if (oldInfo.status != newInfo.status) {
                    switch (newInfo.status) {
                        case TXSeatInfo.STATUS_UNUSED:
                            onSeatLeave(i, oldInfo.user);
                            break;
                        case TXSeatInfo.STATUS_USED:
                            onSeatTake(i, newInfo.user);
                            break;
                        case TXSeatInfo.STATUS_CLOSE:
                            onSeatClose(i, true);
                            break;
                        default:
                            break;
                    }
                }
                if (oldInfo.mute != newInfo.mute) {
                    onSeatMute(i, newInfo.mute);
                }
            }
        } catch (Exception e) {
            TRTCLogger.e(TAG, "group attr changed, seat compare error:" + e.getCause());
        }
    }

    private void modifyGroupAttrs(HashMap<String, String> map, final TXCallback callback) {
        TRTCLogger.i(TAG, "modify group attrs, map:" + map);
        V2TIMManager.getGroupManager().setGroupAttributes(mRoomId, map, new V2TIMCallback() {
            @Override
            public void onError(int code, String message) {
                TRTCLogger.e(TAG, "modify group attrs error, code:" + code + " message" + message);
                if (callback != null) {
                    callback.onCallback(code, message);
                }
                if (code == TRTCVoiceRoomDef.ERR_SVR_GROUP_ATTRIBUTE_WRITE_CONFLICT) {
                    getGroupAttrs(callback);
                }
            }

            @Override
            public void onSuccess() {
                TRTCLogger.i(TAG, "modify group attrs success");
                if (callback != null) {
                    callback.onCallback(0, "modify group attrs success");
                }
            }
        });
    }

    public void getUserInfo(final List<String> userList, final TXUserListCallback callback) {
        if (!isEnterRoom()) {
            TRTCLogger.e(TAG, "get user info list fail, not enter room yet.");
            if (callback != null) {
                callback.onCallback(CODE_ERROR, "get user info list fail, not enter room yet.",
                        new ArrayList<TXUserInfo>());
            }
            return;
        }
        if (userList == null || userList.size() == 0) {
            TRTCLogger.e(TAG, "get user info list fail, user list is empty.");
            if (callback != null) {
                callback.onCallback(CODE_ERROR, "get user info list fail, user list is empty.",
                        new ArrayList<TXUserInfo>());
            }
            return;
        }
        TRTCLogger.i(TAG, "get user info list " + userList);
        V2TIMManager.getInstance().getUsersInfo(userList, new V2TIMValueCallback<List<V2TIMUserFullInfo>>() {
            @Override
            public void onError(int i, String s) {
                TRTCLogger.e(TAG, "get user info list fail, code:" + i);
                if (callback != null) {
                    callback.onCallback(i, s, null);
                }
            }

            @Override
            public void onSuccess(List<V2TIMUserFullInfo> v2TIMUserFullInfos) {
                List<TXUserInfo> list = new ArrayList<>();
                if (v2TIMUserFullInfos != null && v2TIMUserFullInfos.size() != 0) {
                    for (int i = 0; i < v2TIMUserFullInfos.size(); i++) {
                        TXUserInfo userInfo = new TXUserInfo();
                        userInfo.userName = v2TIMUserFullInfos.get(i).getNickName();
                        userInfo.userId = v2TIMUserFullInfos.get(i).getUserID();
                        userInfo.avatarURL = v2TIMUserFullInfos.get(i).getFaceUrl();
                        list.add(userInfo);
                    }
                }
                if (callback != null) {
                    callback.onCallback(0, "success", list);
                }
            }
        });
    }

    public void sendRoomTextMsg(final String msg, final TXCallback callback) {
        if (!isEnterRoom()) {
            TRTCLogger.e(TAG, "send room text fail, not enter room yet.");
            if (callback != null) {
                callback.onCallback(-1, "send room text fail, not enter room yet.");
            }
            return;
        }

        V2TIMManager.getInstance().sendGroupTextMessage(msg, mRoomId, V2TIMMessage.V2TIM_PRIORITY_NORMAL,
                new V2TIMValueCallback<V2TIMMessage>() {
                    @Override
                    public void onError(int i, String s) {
                        TRTCLogger.e(TAG, "sendGroupTextMessage error " + i + " msg:" + msg);
                        if (callback != null) {
                            callback.onCallback(i, s);
                        }
                    }

                    @Override
                    public void onSuccess(V2TIMMessage v2TIMMessage) {
                        if (callback != null) {
                            callback.onCallback(0, "send group message success.");
                        }
                    }
                });

    }

    public void sendRoomCustomMsg(String cmd, String message, final TXCallback callback) {
        if (!isEnterRoom()) {
            TRTCLogger.e(TAG, "send room custom msg fail, not enter room yet.");
            if (callback != null) {
                callback.onCallback(-1, "send room custom msg fail, not enter room yet.");
            }
            return;
        }
        sendGroupMsg(IMProtocol.getCusMsgJsonStr(cmd, message), callback);
    }

    public void sendGroupMsg(String data, final TXCallback callback) {
        V2TIMManager.getInstance().sendGroupCustomMessage(data.getBytes(), mRoomId,
                V2TIMMessage.V2TIM_PRIORITY_NORMAL, new V2TIMValueCallback<V2TIMMessage>() {
                    @Override
                    public void onError(int i, String s) {
                        TRTCLogger.e(TAG, "sendGroupMsg error " + i + " msg:" + s);
                        if (callback != null) {
                            callback.onCallback(i, s);
                        }
                    }

                    @Override
                    public void onSuccess(V2TIMMessage v2TIMMessage) {
                        if (callback != null) {
                            callback.onCallback(0, "send group message success.");
                        }
                    }
                });
    }

    public boolean isLogin() {
        return mIsLogin;
    }

    public boolean isEnterRoom() {
        return mIsLogin && mIsEnterRoom;
    }

    public boolean isOwner() {
        return mSelfUserId.equals(mOwnerUserId);
    }

    private void onSeatTake(final int index, final String user) {
        TRTCLogger.i(TAG, "onSeatTake " + index + " userInfo:" + user);
        List<String> userIdList = new ArrayList<>();
        userIdList.add(user);
        getUserInfo(userIdList, new TXUserListCallback() {
            @Override
            public void onCallback(int code, String msg, List<TXUserInfo> list) {
                if (code == 0) {
                    if (mDelegate != null) {
                        mDelegate.onSeatTake(index, list.get(0));
                    }
                } else {
                    TRTCLogger.e(TAG, "onSeatTake get user info error!");
                    if (mDelegate != null) {
                        TXUserInfo userInfo = new TXUserInfo();
                        userInfo.userId = user;
                        mDelegate.onSeatTake(index, userInfo);
                    }
                }
            }
        });

        if (isOwner()) {
            List<String> userList = new ArrayList<>();
            userList.add(user);
            V2TIMManager.getInstance().subscribeUserStatus(userList, new V2TIMCallback() {
                @Override
                public void onSuccess() {
                    TRTCLogger.i(TAG, "subscribeUserStatus success id: " + user);
                }

                @Override
                public void onError(int code, String message) {
                    TRTCLogger.e(TAG, "subscribeUserStatus failed, code: " + code
                            + ",message: " + message + " id: " + user);
                }
            });
        }
    }

    private void onSeatClose(int index, boolean isClose) {
        TRTCLogger.i(TAG, "onSeatClose " + index);
        if (mDelegate != null) {
            mDelegate.onSeatClose(index, isClose);
        }
    }

    private void onSeatLeave(final int index, final String user) {
        TRTCLogger.i(TAG, "onSeatLeave " + index + " userInfo:" + user);
        List<String> userIdList = new ArrayList<>();
        userIdList.add(user);
        getUserInfo(userIdList, new TXUserListCallback() {
            @Override
            public void onCallback(int code, String msg, List<TXUserInfo> list) {
                if (code == 0) {
                    if (mDelegate != null) {
                        mDelegate.onSeatLeave(index, list.get(0));
                    }
                } else {
                    TRTCLogger.e(TAG, "onSeatTake get user info error!");
                    if (mDelegate != null) {
                        TXUserInfo userInfo = new TXUserInfo();
                        userInfo.userId = user;
                        mDelegate.onSeatLeave(index, userInfo);
                    }
                }
            }
        });
        if (isOwner()) {
            List<String> userList = new ArrayList<>();
            userList.add(user);
            V2TIMManager.getInstance().unsubscribeUserStatus(userList, new V2TIMCallback() {
                @Override
                public void onSuccess() {
                    TRTCLogger.i(TAG, "unsubscribeUserStatus success id: " + user);
                }

                @Override
                public void onError(int code, String message) {
                    TRTCLogger.e(TAG, "unsubscribeUserStatus failed, code: " + code
                            + ",message: " + message + " id: " + user);
                }
            });
        }

        String userId = mOfflineKickMap.get(index);
        if (!TextUtils.isEmpty(userId)) {
            mOfflineKickMap.remove(userId);
            mMainHandler.sendEmptyMessage(MSG_KICK_USER_ON_OFFLINE);
        }
    }

    private void onSeatMute(int index, boolean mute) {
        TRTCLogger.i(TAG, "onSeatMute " + index + " mute:" + mute);
        if (mDelegate != null) {
            mDelegate.onSeatMute(index, mute);
        }
    }

    public void destroy() {

    }

    public String sendInvitation(String cmd, String userId, String content, final TXCallback callback) {
        int roomId = 0;
        try {
            roomId = Integer.parseInt(mRoomId);
        } catch (Exception e) {
            TRTCLogger.e(TAG, "room is not right: " + mRoomId);
        }
        SignallingData signallingData = createSignallingData();
        SignallingData.DataInfo dataInfo = signallingData.getData();
        dataInfo.setCmd(cmd);
        dataInfo.setSeatNumber(content);
        dataInfo.setRoomID(roomId);
        String json = new Gson().toJson(signallingData);
        TRTCLogger.i(TAG, "send " + userId + " json:" + json);
        return V2TIMManager.getSignalingManager().invite(userId, json, true, null, 0, new V2TIMCallback() {
            @Override
            public void onError(int i, String s) {
                TRTCLogger.e(TAG, "sendInvitation error " + i);
                if (callback != null) {
                    callback.onCallback(i, s);
                }
            }

            @Override
            public void onSuccess() {
                TRTCLogger.i(TAG, "sendInvitation success ");
                if (callback != null) {
                    callback.onCallback(0, "send invitation success");
                }
            }
        });
    }

    public void acceptInvitation(String id, final TXCallback callback) {
        TRTCLogger.i(TAG, "acceptInvitation " + id);
        SignallingData signallingData = createSignallingData();
        String json = new Gson().toJson(signallingData);
        V2TIMManager.getSignalingManager().accept(id, json, new V2TIMCallback() {
            @Override
            public void onError(int i, String s) {
                TRTCLogger.e(TAG, "acceptInvitation error " + i);
                if (callback != null) {
                    callback.onCallback(i, s);
                }
            }

            @Override
            public void onSuccess() {
                TRTCLogger.i(TAG, "acceptInvitation success ");
                if (callback != null) {
                    callback.onCallback(0, "send invitation success");
                }
            }
        });
    }

    public void rejectInvitation(String id, final TXCallback callback) {
        TRTCLogger.i(TAG, "rejectInvitation " + id);
        SignallingData signallingData = createSignallingData();
        String json = new Gson().toJson(signallingData);
        V2TIMManager.getSignalingManager().reject(id, json, new V2TIMCallback() {
            @Override
            public void onError(int i, String s) {
                TRTCLogger.e(TAG, "rejectInvitation error " + i);
                if (callback != null) {
                    callback.onCallback(i, s);
                }
            }

            @Override
            public void onSuccess() {
                if (callback != null) {
                    callback.onCallback(0, "send invitation success");
                }
            }
        });
    }

    public void cancelInvitation(String id, final TXCallback callback) {
        TRTCLogger.i(TAG, "cancelInvitation " + id);
        SignallingData signallingData = createSignallingData();
        String json = new Gson().toJson(signallingData);
        V2TIMManager.getSignalingManager().cancel(id, json, new V2TIMCallback() {
            @Override
            public void onError(int i, String s) {
                TRTCLogger.e(TAG, "cancelInvitation error " + i);
                if (callback != null) {
                    callback.onCallback(i, s);
                }
            }

            @Override
            public void onSuccess() {
                TRTCLogger.i(TAG, "cancelInvitation success ");
                if (callback != null) {
                    callback.onCallback(0, "send invitation success");
                }
            }
        });
    }

    public void getAudienceList(final TXUserListCallback txUserListCallback) {
        V2TIMManager.getGroupManager().getGroupMemberList(mRoomId,
                V2TIMGroupMemberFullInfo.V2TIM_GROUP_MEMBER_FILTER_COMMON, 0,
                new V2TIMValueCallback<V2TIMGroupMemberInfoResult>() {
                    @Override
                    public void onError(int i, String s) {
                        if (txUserListCallback != null) {
                            txUserListCallback.onCallback(i, s, new ArrayList<TXUserInfo>());
                        }
                    }

                    @Override
                    public void onSuccess(V2TIMGroupMemberInfoResult v2TIMGroupMemberInfoResult) {
                        List<TXUserInfo> userInfos = new ArrayList<>();
                        if (v2TIMGroupMemberInfoResult.getMemberInfoList() != null) {
                            for (V2TIMGroupMemberFullInfo info : v2TIMGroupMemberInfoResult.getMemberInfoList()) {
                                TXUserInfo userInfo = new TXUserInfo();
                                userInfo.userId = info.getUserID();
                                userInfo.userName = info.getNickName();
                                userInfo.avatarURL = info.getFaceUrl();
                                userInfos.add(userInfo);
                            }
                        }
                        if (txUserListCallback != null) {
                            txUserListCallback.onCallback(0, "", userInfos);
                        }
                    }
                });
    }

    private int getSeatIndex(String userId) {
        if (TextUtils.isEmpty(userId)) {
            TRTCLogger.e(TAG, "get seat index, userId is empty");
            return NOT_IN_SEAT;
        }
        if (mTXSeatInfoList == null) {
            TRTCLogger.e(TAG, "get seat index, current seat info list is null");
            return NOT_IN_SEAT;
        }
        for (int i = 0; i < mTXSeatInfoList.size(); i++) {
            TXSeatInfo info = mTXSeatInfoList.get(i);
            if (info != null && userId.equals(info.user)) {
                return i;
            }
        }
        return NOT_IN_SEAT;
    }

    private class VoiceRoomSimpleListener extends V2TIMSimpleMsgListener {
        @Override
        public void onRecvGroupTextMessage(String msgID, String groupID, V2TIMGroupMemberInfo sender, String text) {
            TRTCLogger.i(TAG, "im get text msg group:" + groupID + " userid :" + sender.getUserID() + " text:" + text);
            if (!groupID.equals(mRoomId)) {
                return;
            }
            TXUserInfo userInfo = new TXUserInfo();
            userInfo.userId = sender.getUserID();
            userInfo.avatarURL = sender.getFaceUrl();
            userInfo.userName = sender.getNickName();
            if (mDelegate != null) {
                mDelegate.onRoomRecvRoomTextMsg(mRoomId, text, userInfo);
            }
        }

        @Override
        public void onRecvGroupCustomMessage(String msgID, String groupID, V2TIMGroupMemberInfo sender,
                                             byte[] customData) {
            if (!groupID.equals(mRoomId)) {
                return;
            }
            String customStr = new String(customData);
            if (!TextUtils.isEmpty(customStr)) {
                try {
                    JSONObject jsonObject = new JSONObject(customStr);
                    String version = jsonObject.getString(IMProtocol.Define.KEY_ATTR_VERSION);
                    if (!version.equals(IMProtocol.Define.VALUE_ATTR_VERSION)) {
                        TRTCLogger.e(TAG, "protocol version is not match, ignore msg.");
                    }
                    int action = jsonObject.getInt(IMProtocol.Define.KEY_CMD_ACTION);

                    switch (action) {
                        case IMProtocol.Define.CODE_UNKNOWN:
                            // ignore
                            break;
                        case IMProtocol.Define.CODE_ROOM_CUSTOM_MSG:
                            TXUserInfo userInfo = new TXUserInfo();
                            userInfo.userId = sender.getUserID();
                            userInfo.avatarURL = sender.getFaceUrl();
                            userInfo.userName = sender.getNickName();
                            Pair<String, String> cusPair = IMProtocol.parseCusMsg(jsonObject);
                            if (mDelegate != null && cusPair != null) {
                                mDelegate.onRoomRecvRoomCustomMsg(mRoomId, cusPair.first, cusPair.second, userInfo);
                            }
                            break;
                        case IMProtocol.Define.CODE_ROOM_DESTROY:
                            exitRoom(null);
                            resetStatus();
                            if (mDelegate != null) {
                                mDelegate.onRoomDestroy(mRoomId);
                            }
                            break;
                        default:
                            break;
                    }
                } catch (JSONException e) {
                    TRTCLogger.e(TAG, "json parse error: " + e.getMessage());
                }
            }
        }
    }

    private class VoiceRoomGroupListener extends V2TIMGroupListener {
        @Override
        public void onMemberEnter(String groupID, List<V2TIMGroupMemberInfo> memberList) {
            if (!groupID.equals(mRoomId)) {
                return;
            }
            if (mDelegate != null && memberList != null) {
                for (V2TIMGroupMemberInfo member : memberList) {
                    TXUserInfo userInfo = new TXUserInfo();
                    userInfo.userId = member.getUserID();
                    userInfo.userName = member.getNickName();
                    userInfo.avatarURL = member.getFaceUrl();
                    mDelegate.onRoomAudienceEnter(userInfo);
                }
            }
        }

        @Override
        public void onMemberLeave(String groupID, V2TIMGroupMemberInfo member) {
            if (!groupID.equals(mRoomId)) {
                return;
            }
            if (mDelegate != null) {
                TXUserInfo userInfo = new TXUserInfo();
                userInfo.userId = member.getUserID();
                userInfo.userName = member.getNickName();
                userInfo.avatarURL = member.getFaceUrl();
                mDelegate.onRoomAudienceLeave(userInfo);
            }
        }

        @Override
        public void onGroupDismissed(String groupID, V2TIMGroupMemberInfo opUser) {
            // 解散逻辑
            if (!groupID.equals(mRoomId)) {
                return;
            }
            resetStatus();
            if (mDelegate != null) {
                mDelegate.onRoomDestroy(mRoomId);
            }
        }

        @Override
        public void onGroupAttributeChanged(String groupID, Map<String, String> groupAttributeMap) {
            TRTCLogger.i(TAG, "onGroupAttributeChanged :" + groupAttributeMap);
            if (!groupID.equals(mRoomId)) {
                return;
            }
            if (mTXRoomInfo == null) {
                TRTCLogger.e(TAG, "group attr changed, but room info is empty!");
                return;
            }
            onSeatAttrMapChanged(groupAttributeMap, mTXRoomInfo.seatSize);
        }
    }

    private class VoiceRoomSignalListener extends V2TIMSignalingListener {
        @Override
        public void onReceiveNewInvitation(String inviteID, String inviter, String groupId, List<String> inviteeList,
                                           String data) {
            TRTCLogger.i(TAG, "recv new invitation: " + inviteID + " from " + inviter + " data:" + data);
            if (mDelegate != null) {
                SignallingData signallingData = IMProtocol.convert2SignallingData(data);
                if (!isVoiceRoomData(signallingData)) {
                    TRTCLogger.i(TAG, "this is not the voice room sense ");
                    return;
                }
                SignallingData.DataInfo dataInfo = signallingData.getData();
                if (dataInfo == null) {
                    TRTCLogger.e(TAG, "parse data error, dataInfo is null");
                    return;
                }
                if (!mRoomId.equals(String.valueOf(dataInfo.getRoomID()))) {
                    TRTCLogger.e(TAG, "roomId is not right");
                    return;
                }
                mDelegate.onReceiveNewInvitation(inviteID, inviter, dataInfo.getCmd(), dataInfo.getSeatNumber());
            }
        }

        @Override
        public void onInviteeAccepted(String inviteID, String invitee, String data) {
            TRTCLogger.i(TAG, "recv accept invitation: " + inviteID + " from " + invitee);
            SignallingData signallingData = IMProtocol.convert2SignallingData(data);
            if (!isVoiceRoomData(signallingData)) {
                TRTCLogger.i(TAG, "this is not the voice room sense ");
                return;
            }
            if (mDelegate != null) {
                mDelegate.onInviteeAccepted(inviteID, invitee);
            }
        }

        @Override
        public void onInviteeRejected(String inviteID, String invitee, String data) {
            TRTCLogger.i(TAG, "recv reject invitation: " + inviteID + " from " + invitee);
            SignallingData signallingData = IMProtocol.convert2SignallingData(data);
            if (!isVoiceRoomData(signallingData)) {
                TRTCLogger.i(TAG, "this is not the voice room sense ");
                return;
            }
            if (mDelegate != null) {
                mDelegate.onInviteeRejected(inviteID, invitee);
            }
        }

        @Override
        public void onInvitationCancelled(String inviteID, String inviter, String data) {
            TRTCLogger.i(TAG, "recv cancel invitation: " + inviteID + " from " + inviter);
            SignallingData signallingData = IMProtocol.convert2SignallingData(data);
            if (!isVoiceRoomData(signallingData)) {
                TRTCLogger.i(TAG, "this is not the voice room sense ");
                return;
            }
            if (mDelegate != null) {
                mDelegate.onInvitationCancelled(inviteID, inviter);
            }
        }

        @Override
        public void onInvitationTimeout(String inviteID, List<String> inviteeList) {
        }
    }

    private boolean isVoiceRoomData(SignallingData signallingData) {
        if (signallingData == null) {
            return false;
        }
        String businessId = signallingData.getBusinessID();
        return IMProtocol.SignallingDefine.VALUE_BUSINESS_ID.equals(businessId);
    }

    private SignallingData createSignallingData() {
        SignallingData callingData = new SignallingData();
        callingData.setVersion(IMProtocol.SignallingDefine.VALUE_VERSION);
        callingData.setBusinessID(IMProtocol.SignallingDefine.VALUE_BUSINESS_ID);
        callingData.setPlatform(IMProtocol.SignallingDefine.VALUE_PLATFORM);
        SignallingData.DataInfo dataInfo = new SignallingData.DataInfo();
        callingData.setData(dataInfo);
        return callingData;
    }

    private void kickUserOnOffline() {
        mIsKickUserOnOffline = true;
        if (mOfflineUserList.isEmpty()) {
            mIsKickUserOnOffline = false;
            return;
        }
        final String userId = mOfflineUserList.getFirst();
        mOfflineUserList.removeFirst();
        final int seatIndex = getSeatIndex(userId);
        TRTCLogger.i(TAG, "find user " + userId + ", seatIndex: " + seatIndex);
        if (seatIndex == NOT_IN_SEAT) {
            mMainHandler.sendEmptyMessage(MSG_KICK_USER_ON_OFFLINE);
        } else {
            kickSeat(seatIndex, new TXCallback() {
                @Override
                public void onCallback(int code, String msg) {
                    TRTCLogger.i(TAG, userId + " is offline, remove it from seat list, code: " + code + " msg: "
                            + msg);
                    if (code == 0) {
                        mOfflineKickMap.put(seatIndex, userId);
                    } else {
                        mMainHandler.sendEmptyMessage(MSG_KICK_USER_ON_OFFLINE);
                    }
                }
            });
        }
    }

    private class UserStatusListener extends V2TIMSDKListener {
        @Override
        public void onUserStatusChanged(List<V2TIMUserStatus> userStatusList) {
            if (userStatusList == null) {
                TRTCLogger.e(TAG, "onUserStatusChanged, userStatusList is null ");
                return;
            }
            for (V2TIMUserStatus userStatus : userStatusList) {
                final String userId = userStatus.getUserID();
                int status = userStatus.getStatusType();
                TRTCLogger.i(TAG, "onUserStatusChanged, userId: " + userId + " status:" + status);
                if (status == V2TIMUserStatus.V2TIM_USER_STATUS_OFFLINE) {
                    Message message = mMainHandler.obtainMessage();
                    message.obj = userId;
                    message.what = MSG_ON_USER_OFFLINE;
                    message.sendToTarget();
                } else if (status == V2TIMUserStatus.V2TIM_USER_STATUS_ONLINE) {
                    if (mOfflineUserList.contains(userId)) {
                        mOfflineUserList.remove(userId);
                    }
                }
            }
        }
    }

    private class HandlerCallback implements Handler.Callback {
        @Override
        public boolean handleMessage(Message msg) {
            if (msg.what == MSG_ON_USER_OFFLINE) {
                String userId = (String) msg.obj;
                if (!mOfflineUserList.contains(userId)) {
                    mOfflineUserList.add(userId);
                }
                if (!mIsKickUserOnOffline) {
                    mMainHandler.sendEmptyMessage(MSG_KICK_USER_ON_OFFLINE);
                }
                return true;
            } else if (msg.what == MSG_KICK_USER_ON_OFFLINE) {
                kickUserOnOffline();
                return true;
            }
            return false;
        }
    }
}