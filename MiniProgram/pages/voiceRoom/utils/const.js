const EVENT_TYPE = {
  onReady: 'onReady',
  onError: 'onError',
  onRoomDestroy: 'onRoomDestroy', // 房间被销毁的回调。
  onSeatListChange: 'onSeatListChange', // 全量的麦位列表变化。
  onAnchorEnterSeat: 'onAnchorEnterSeat', // 有成员上麦（主动上麦/房主抱人上麦）。
  onAnchorLeaveSeat: 'onAnchorLeaveSeat', // 有成员下麦（主动下麦/房主踢人下麦）。
  onSeatMute: 'onSeatMute', //	房主禁麦。
  onSeatClose: 'onSeatClose', // 房主封麦。
  onAudienceEnter: 'onAudienceEnter', // 收到听众进房通知。
  onAudienceExit: 'onAudienceExit', // 收到听众退房通知。
  onRecvRoomTextMsg: 'onRecvRoomTextMsg', // 收到文本消息。
  onReceiveNewInvitation: 'onReceiveNewInvitation', // 收到新的邀请请求。
  onInviteeAccepted: 'onInviteeAccepted', // 被邀请人接受邀请。
  onInviteeRejected: 'onInviteeRejected', // 被邀请人拒绝邀请。
  onInvitationCancelled: 'onInvitationCancelled', // 邀请人取消邀请。
};
const SEAT_STATUS = {
  SEAT_LENGTH: 4,
  NO_USER: 0, // 麦位没人
  EXIST_USER: 1, // 麦位存在用户
  CLOSE: 2, // 麦位被封禁
};
const IM_STATUS = {
  GROUP_DISMISSED: 5, // 群组被解散
};

const SIGNAL = {
  BUSINESS_ID: 'VoiceRoom',
  PLATFORM: 'MiniApp',
  PICK_SEAT: 'pickSeat',
  TAKE_SEAT: 'takeSeat',
};

export { EVENT_TYPE, SEAT_STATUS, IM_STATUS, SIGNAL };
