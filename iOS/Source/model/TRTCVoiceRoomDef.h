//
//  TRTCVoiceRoomDef.h
//  TRTCVoiceRoomOCDemo
//
//  Created by abyyxwang on 2020/6/30.
//  Copyright © 2020 Tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Version number defined by the current app module
static NSString *gAPP_VERSION = @"app_version_1.0";
/// Group attribute write conflict. Get the latest group attribute first before writing. This error code is supported in IM SDK 5.6 or later. The seat information has changed and needs to be pulled again.
static int gERR_SVR_GROUP_ATTRIBUTE_WRITE_CONFLICT = 10056;
/// API call frequency limit
static int gERR_CALL_METHOD_LIMIT = 10001;
/// Connect Tencent timeout
static int gERR_CONNECT_SERVICE_TIMEOUT = 10002;

@interface VoiceRoomSeatInfo : NSObject

@property (nonatomic, assign) NSInteger status;
@property (nonatomic, assign) BOOL mute;
@property (nonatomic, strong) NSString *userId;

@end

@interface VoiceRoomParam : NSObject

@property (nonatomic, strong) NSString *roomName;
@property (nonatomic, strong) NSString *coverUrl;
@property (nonatomic, assign) BOOL needRequest;
@property (nonatomic, assign) NSInteger seatCount;
@property (nonatomic, strong) NSArray<VoiceRoomSeatInfo *> *seatInfoList;


@end

@interface VoiceRoomUserInfo : NSObject

@property (nonatomic, strong) NSString *userId;
@property (nonatomic, strong) NSString *userName;
@property (nonatomic, strong) NSString *userAvatar;
@property (nonatomic, assign) BOOL mute;

@end

@interface VoiceRoomInfo : NSObject

@property (nonatomic, assign) NSInteger roomID;
@property (nonatomic, strong) NSString *roomName;
@property (nonatomic, strong) NSString *coverUrl;
@property (nonatomic, strong) NSString *ownerId;
@property (nonatomic, strong) NSString *ownerName;
@property (nonatomic, assign) NSInteger memberCount;
@property (nonatomic, assign) BOOL needRequest;

-(instancetype)initWithRoomID:(NSInteger)roomID ownerId:(NSString *)ownerId memberCount:(NSInteger)memberCount;

@end

typedef void(^ActionCallback)(int code, NSString * _Nonnull message);
typedef void(^VoiceRoomInfoCallback)(int code, NSString * _Nonnull message, NSArray<VoiceRoomInfo * > * _Nonnull roomInfos);
typedef void(^VoiceRoomUserListCallback)(int code, NSString * _Nonnull message, NSArray<VoiceRoomUserInfo * > * _Nonnull userInfos);

NS_ASSUME_NONNULL_END
