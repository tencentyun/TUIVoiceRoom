package com.tencent.liteav.trtcvoiceroom.ui.widget;

import android.content.Context;

import com.google.android.material.bottomsheet.BottomSheetDialog;

import android.util.TypedValue;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.widget.LinearLayout;
import android.widget.TextView;

import com.tencent.liteav.trtcvoiceroom.R;

public class CommonBottomDialog extends BottomSheetDialog {
    private LinearLayout          mViewContainer;
    private int                   mButtonSize;
    private OnButtonClickListener mOnButtonClickListener;

    public CommonBottomDialog(Context context) {
        super(context, R.style.TRTCVoiceRoomDialogTheme);
        setContentView(R.layout.trtcvoiceroom_view_bottom_dialog);
        mViewContainer = (LinearLayout) findViewById(R.id.view_container);
        findViewById(R.id.tv_cancel).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                dismiss();
            }
        });
    }

    public CommonBottomDialog(Context context, int theme) {
        super(context, theme);
    }

    public static int dp2px(Context context, float dpVal) {
        return (int) TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP,
                dpVal, context.getResources().getDisplayMetrics());
    }

    public void setButton(OnButtonClickListener buttonClickListener, String... textList) {
        mButtonSize = textList.length;
        mOnButtonClickListener = buttonClickListener;
        mViewContainer.removeAllViews();
        for (int i = 0; i < mButtonSize; i++) {
            TextView textView = createButton(i, textList[i]);
            LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT,
                    dp2px(getContext(), 57));
            lp.setMargins(dp2px(getContext(), 10), 0, dp2px(getContext(), 10), dp2px(getContext(), 8));
            textView.setPadding(dp2px(getContext(), 5), dp2px(getContext(), 10), dp2px(getContext(), 5),
                    dp2px(getContext(), 10));
            textView.setLayoutParams(lp);
            textView.setGravity(Gravity.CENTER);
            mViewContainer.addView(textView);
        }
    }

    private TextView createButton(final int position, final String text) {
        TextView textView = new TextView(getContext());
        textView.setText(text);
        textView.setTextSize(TypedValue.COMPLEX_UNIT_SP, 20);
        textView.setTextColor(getContext().getResources().getColor(R.color.trtcvoiceroom_color_blue));
        textView.setBackgroundResource(R.drawable.trtcvoiceroom_bg_bottom_item);
        textView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (mOnButtonClickListener != null) {
                    mOnButtonClickListener.onClick(position, text);
                }
            }
        });
        return textView;
    }

    public interface OnButtonClickListener {
        void onClick(int position, String text);
    }
}
