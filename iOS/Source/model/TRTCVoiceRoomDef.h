//
//  TRTCVoiceRoomDef.h
//  TRTCVoiceRoomOCDemo
//
//  Created by abyyxwang on 2020/6/30.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

//当前app module定义的版本号
static NSString *APP_VERSION = @"9.4.16";
/// 群属性写冲突，请先拉取最新的群属性后再尝试写操作，IMSDK5.6及其以上版本支持，麦位信息已经发生变化，需要重新拉取
static int ERR_SVR_GROUP_ATTRIBUTE_WRITE_CONFLICT = 10056;
/// 接口调用限频
static int ERR_CALL_METHOD_LIMIT = 10001;

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
