package com.tencent.liteav.trtcvoiceroom.ui.widget;

import android.graphics.Rect;
import androidx.recyclerview.widget.RecyclerView;
import android.view.View;

public class SpaceDecorations extends RecyclerView.ItemDecoration {
    private int space;

    public SpaceDecorations(int space) {
        this.space = space;
    }

    @Override
    public void getItemOffsets(Rect outRect, View view, RecyclerView parent, RecyclerView.State state) {
        outRect.top = space;
    }
}
