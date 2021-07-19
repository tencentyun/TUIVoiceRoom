//
//  TXVoiceRoomIMJsonHandle.h
//  TRTCVoiceRoomOCDemo
//
//  Created by abyyxwang on 2020/7/2.
//  Copyright © 2020 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TXBaseDef.h"

NS_ASSUME_NONNULL_BEGIN

static NSString* VOICE_ROOM_KEY_ATTR_VERSION = @"version";
static NSString* VOICE_ROOM_VALUE_ATTR_VERSION = @"1.0";
static NSString* VOICE_ROOM_KEY_ROOM_INFO = @"roomInfo";
static NSString* VOICE_ROOM_KEY_SEAT = @"seat";

//static NSString* VOICE_ROOM_KEY_CMD_VERSION = @"version";
//static NSString* VOICE_ROOM_VALUE_CMD_VERSION = @"1.0";
static NSString* VOICE_ROOM_KEY_CMD_ACTION = @"action";

static NSString* VOICE_ROOM_KEY_INVITATION_VERSION = @"version";
static NSString* VOICE_ROOM_VALUE_INVITATION_VERSION = @"1.0";
static NSString* VOICE_ROOM_KEY_INVITATION_CMD = @"command";
static NSString* VOICE_ROOM_KEY_INVITAITON_CONTENT = @"content";

static NSString* VOICE_ROOM_KEY_CMD_VERSION = @"version";
static NSString* VOICE_ROOM_KEY_CMD_BUSINESSID = @"businessID";
static NSString* VOICE_ROOM_KEY_CMD_PLATFORM = @"platform";
static NSString* VOICE_ROOM_KEY_CMD_EXTINFO = @"extInfo";
static NSString* VOICE_ROOM_KEY_CMD_DATA = @"data";
static NSString* VOICE_ROOM_KEY_CMD_ROOMID = @"room_id";
static NSString* VOICE_ROOM_KEY_CMD_CMD = @"cmd";
static NSString* VOICE_ROOM_KEY_CMD_SEATNUMBER = @"seat_number";

static NSInteger VOICE_ROOM_VALUE_CMD_BASIC_VERSION = 1;
static NSInteger VOICE_ROOM_VALUE_CMD_VERSION = 1;
static NSString* VOICE_ROOM_VALUE_CMD_BUSINESSID = @"VoiceRoom";
static NSString* VOICE_ROOM_VALUE_CMD_PLATFORM = @"iOS";
static NSString* VOICE_ROOM_VALUE_CMD_PICK = @"pickSeat";
static NSString* VOICE_ROOM_VALUE_CMD_TAKE = @"takeSeat";


typedef NS_ENUM(NSUInteger, TXVoiceRoomCustomCodeType) {
    kVoiceRoomCodeUnknown = 0,
    kVoiceRoomCodeDestroy = 200,
    kVoiceRoomCodeCustomMsg = 301,
};

@interface TXVoiceRoomIMJsonHandle : NSObject

+ (NSDictionary<NSString *, NSString *> *)getInitRoomDicWithRoomInfo:(TXRoomInfo *)roominfo seatInfoList:(NSArray<TXSeatInfo *> *)seatInfoList;

+ (NSDictionary<NSString *, NSString *> *)getSeatInfoListJsonStrWithSeatInfoList:(NSArray<TXSeatInfo *> *)seatInfoList;

+ (NSDictionary<NSString *, NSString *> *)getSeatInfoJsonStrWithIndex:(NSInteger)index info:(TXSeatInfo *)info;

+ (TXRoomInfo * _Nullable)getRoomInfoFromAttr:(NSDictionary<NSString *, NSString *> *)attr;

+ (NSArray<TXSeatInfo *> * _Nullable)getSeatListFromAttr:(NSDictionary<NSString *, NSString *> *)attr seatSize:(NSUInteger)seatSize;

+ (NSString *)getInvitationMsgWithRoomId:(NSString *)roomId cmd:(NSString *)cmd content:(NSString *)content;

+ (TXInviteData * _Nullable)parseInvitationMsgWithJson:(NSString *)json;

+ (NSString *)getRoomdestroyMsg;

+ (NSString *)getCusMsgJsonStrWithCmd:(NSString *)cmd msg:(NSString *)msg;

+ (NSDictionary<NSString *, NSString *> *)parseCusMsgWithJsonDic:(NSDictionary *)jsonDic;

@end

NS_ASSUME_NONNULL_END
