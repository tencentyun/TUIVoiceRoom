//
//  TXBaseDef.m
//  TRTCVoiceRoomOCDemo
//
//  Created by abyyxwang on 2020/6/30.
//  Copyright © 2020 tencent. All rights reserved.
//

#import "TXBaseDef.h"
#import "TRTCCloud.h"

@interface TRTCCloud (VoiceRoomLog)

- (void)apiLog:(NSString *)log;

@end

void tuiVoiceRoomLog(NSString *format, ...){
    if (!format || ![format isKindOfClass:[NSString class]] || format.length == 0) {
        return;
    }
    va_list arguments;
    va_start(arguments, format);
    NSString *content = [[NSString alloc] initWithFormat:format arguments:arguments];
    va_end(arguments);
    if (content) {
        [[TRTCCloud sharedInstance] apiLog:content];
    }
}

@implementation TXRoomInfo

@end

@implementation TXVoiceRoomUserInfo


@end

@implementation TXSeatInfo

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.status = 0;
        self.mute = NO;
        self.user = @"";
    }
    return self;
}

@end

@implementation TXInviteData


@end
