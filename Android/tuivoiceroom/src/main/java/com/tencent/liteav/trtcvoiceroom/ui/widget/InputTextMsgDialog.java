package com.tencent.liteav.trtcvoiceroom.ui.widget;

import android.app.Dialog;
import android.content.Context;
import android.graphics.PorterDuff;
import android.text.InputType;
import android.text.TextUtils;
import android.util.Log;
import android.view.KeyEvent;
import android.view.View;
import android.view.inputmethod.InputMethodManager;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
import android.widget.TextView;
import android.widget.Toast;

import com.tencent.liteav.trtcvoiceroom.R;

public class InputTextMsgDialog extends Dialog {
    private static final String TAG = InputTextMsgDialog.class.getSimpleName();

    private TextView           mTextConfirm;
    private EditText           mEditMessage;
    private RelativeLayout     mRelativeLayout;
    private LinearLayout       mConfirmArea;
    private Context            mContext;
    private InputMethodManager mInputMethodManager;
    private OnTextSendListener mOnTextSendListener;

    public InputTextMsgDialog(Context context, int theme) {
        super(context, theme);
        mContext = context;
        setContentView(R.layout.trtcvoiceroom_dialog_input_text);

        mEditMessage = (EditText) findViewById(R.id.et_input_message);
        mEditMessage.setInputType(InputType.TYPE_CLASS_TEXT);
        mEditMessage.getBackground().setColorFilter(context.getResources().getColor(R.color.trtcvoiceroom_transparent),
                PorterDuff.Mode.CLEAR);

        mTextConfirm = (TextView) findViewById(R.id.confrim_btn);
        mInputMethodManager = (InputMethodManager) mContext.getSystemService(Context.INPUT_METHOD_SERVICE);
        mTextConfirm.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                String msg = mEditMessage.getText().toString().trim();
                if (!TextUtils.isEmpty(msg)) {

                    mOnTextSendListener.onTextSend(msg);
                    mInputMethodManager.showSoftInput(mEditMessage, InputMethodManager.SHOW_FORCED);
                    mInputMethodManager.hideSoftInputFromWindow(mEditMessage.getWindowToken(), 0);
                    mEditMessage.setText("");
                    dismiss();
                } else {
                    Toast.makeText(mContext, R.string.trtcvoiceroom_warning_not_empty, Toast.LENGTH_LONG).show();
                }
                mEditMessage.setText(null);
            }
        });

        mEditMessage.setOnEditorActionListener(new TextView.OnEditorActionListener() {
            @Override
            public boolean onEditorAction(TextView v, int actionId, KeyEvent event) {
                switch (actionId) {
                    case KeyEvent.KEYCODE_ENDCALL:
                    case KeyEvent.KEYCODE_ENTER:
                        if (mEditMessage.getText().length() > 0) {
                            mInputMethodManager.hideSoftInputFromWindow(mEditMessage.getWindowToken(), 0);
                            dismiss();
                        } else {
                            Toast.makeText(mContext, R.string.trtcvoiceroom_warning_not_empty, Toast.LENGTH_LONG)
                                    .show();
                        }
                        return true;
                    case KeyEvent.KEYCODE_BACK:
                        dismiss();
                        return false;
                    default:
                        return false;
                }
            }
        });

        mConfirmArea = (LinearLayout) findViewById(R.id.confirm_area);
        mConfirmArea.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                String msg = mEditMessage.getText().toString().trim();
                if (!TextUtils.isEmpty(msg)) {

                    mOnTextSendListener.onTextSend(msg);
                    mInputMethodManager.showSoftInput(mEditMessage, InputMethodManager.SHOW_FORCED);
                    mInputMethodManager.hideSoftInputFromWindow(mEditMessage.getWindowToken(), 0);
                    mEditMessage.setText("");
                    dismiss();
                } else {
                    Toast.makeText(mContext, R.string.trtcvoiceroom_warning_not_empty, Toast.LENGTH_LONG).show();
                }
                mEditMessage.setText(null);
            }
        });

        mEditMessage.setOnKeyListener(new View.OnKeyListener() {
            @Override
            public boolean onKey(View view, int i, KeyEvent keyEvent) {
                Log.d(TAG, "onKey " + keyEvent.getCharacters());
                return false;
            }
        });

        mRelativeLayout = (RelativeLayout) findViewById(R.id.rl_outside_view);
        mRelativeLayout.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (v.getId() != R.id.rl_inputdlg_view) {
                    dismiss();
                }
            }
        });

        final LinearLayout inputDialogView = (LinearLayout) findViewById(R.id.rl_inputdlg_view);
        inputDialogView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                mInputMethodManager.hideSoftInputFromWindow(mEditMessage.getWindowToken(), 0);
                dismiss();
            }
        });
    }

    public void setOnTextSendListener(OnTextSendListener onTextSendListener) {
        this.mOnTextSendListener = onTextSendListener;
    }

    public interface OnTextSendListener {
        void onTextSend(String msg);
    }
}
