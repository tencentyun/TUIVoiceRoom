package com.tencent.liteav.trtcvoiceroom.ui.widget.msg;

import android.content.Context;
import android.content.Intent;
import android.net.Uri;

import androidx.recyclerview.widget.RecyclerView;

import android.text.Spannable;
import android.text.SpannableStringBuilder;
import android.text.TextUtils;
import android.text.style.ForegroundColorSpan;
import android.text.style.UnderlineSpan;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import com.tencent.liteav.basic.IntentUtils;
import com.tencent.liteav.trtcvoiceroom.R;

import java.util.List;

/**
 * Adapter for displaying message interaction in the voice chat room
 * Different styles will be displayed by message type, and the color of username of the message sender can be set.
 * <p>
 * TYPE_NORMAL: Common message, whose content will be displayed on the UI
 * TYPE_WAIT_AGREE: Invitation wait message, which has a button for acceptance and can be used to process an event
 * TYPE_AGREED: Accepted invitation message, which indicates that the invitation message has been processed. The event
 * button is hidden in this message
 * TYPE_WELCOME: Welcome message, which will be displayed on the UI with the URL to be redirected to
 */
public class MsgListAdapter extends
        RecyclerView.Adapter<MsgListAdapter.ViewHolder> {

    private static final String TAG = MsgListAdapter.class.getSimpleName();

    private Context             mContext;
    private List<MsgEntity>     mList;
    private OnItemClickListener mOnItemClickListener;

    public MsgListAdapter(Context context, List<MsgEntity> list,
                          OnItemClickListener onItemClickListener) {
        this.mContext = context;
        this.mList = list;
        this.mOnItemClickListener = onItemClickListener;
    }

    @Override
    public ViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {
        Context context = parent.getContext();
        LayoutInflater inflater = LayoutInflater.from(context);
        View view = inflater.inflate(R.layout.trtcvoiceroom_item_msg, parent, false);
        ViewHolder viewHolder = new ViewHolder(view);
        return viewHolder;
    }

    @Override
    public void onBindViewHolder(ViewHolder holder, int position) {
        MsgEntity item = mList.get(position);
        holder.bind(item, mOnItemClickListener);
    }

    @Override
    public int getItemCount() {
        return mList.size();
    }

    public interface OnItemClickListener {
        void onAgreeClick(int position);
    }


    public class ViewHolder extends RecyclerView.ViewHolder {
        private TextView mTvMsgContent;
        private TextView mBtnMsgAgree;

        public ViewHolder(View itemView) {
            super(itemView);
            initView(itemView);
        }

        private void initView(View itemView) {
            mTvMsgContent = (TextView) itemView.findViewById(R.id.tv_msg_content);
            mBtnMsgAgree = (TextView) itemView.findViewById(R.id.btn_msg_agree);
        }

        public void bind(final MsgEntity model,
                         final OnItemClickListener listener) {
            String userName = !TextUtils.isEmpty(model.userName) ? model.userName : model.userId;
            if (model.type == MsgEntity.TYPE_WELCOME) {
                String result = model.content + model.linkUrl;
                SpannableStringBuilder builder = new SpannableStringBuilder(result);
                ForegroundColorSpan welcomeTitleSpan =
                        new ForegroundColorSpan(mContext.getResources().getColor(R.color.trtcvoiceroom_color_welcome));
                ForegroundColorSpan linkSpan =
                        new ForegroundColorSpan(mContext.getResources().getColor(R.color.trtcvoiceroom_color_link));
                UnderlineSpan linkUnderline = new UnderlineSpan();
                builder.setSpan(welcomeTitleSpan, 0, model.content.length(), Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
                builder.setSpan(linkSpan, model.content.length(), result.length(), Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
                builder.setSpan(linkUnderline, model.content.length(), result.length(),
                        Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
                mTvMsgContent.setText(builder);
                mTvMsgContent.setBackground(null);
            } else if (!TextUtils.isEmpty(userName) && model.color != 0) {
                String split = model.isChat ? ": " : " ";
                String result = model.userName + split + model.content;
                SpannableStringBuilder builder = new SpannableStringBuilder(result);
                ForegroundColorSpan redSpan = new ForegroundColorSpan(model.color);
                builder.setSpan(redSpan, 0, model.userName.length(), Spannable.SPAN_EXCLUSIVE_EXCLUSIVE);
                mTvMsgContent.setText(builder);
                mTvMsgContent.setBackgroundResource(R.drawable.trtcvoiceroom_bg_msg_item);
            } else {
                mTvMsgContent.setText(model.content);
                mTvMsgContent.setBackgroundResource(R.drawable.trtcvoiceroom_bg_msg_item);
            }
            if (model.type == MsgEntity.TYPE_AGREED) {
                mBtnMsgAgree.setVisibility(View.GONE);
                mBtnMsgAgree.setEnabled(false);
            } else if (model.type == MsgEntity.TYPE_WAIT_AGREE) {
                mBtnMsgAgree.setVisibility(View.VISIBLE);
                mBtnMsgAgree.setText(R.string.trtcvoiceroom_agree);
                mBtnMsgAgree.setEnabled(true);
            } else {
                mBtnMsgAgree.setVisibility(View.GONE);
            }

            mBtnMsgAgree.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    if (listener != null) {
                        listener.onAgreeClick(getLayoutPosition());
                    }
                }
            });
            itemView.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    if (model.type == MsgEntity.TYPE_WELCOME) {
                        startLinkActivity(model.linkUrl);
                    }
                }
            });
        }
    }

    private void startLinkActivity(String url) {
        Intent intent = new Intent(Intent.ACTION_VIEW);
        intent.setData(Uri.parse(url));
        IntentUtils.safeStartActivity(mContext, intent);
    }
}