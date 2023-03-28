package com.xiaoluo.updatelib;

import android.app.DownloadManager;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.database.Cursor;
import android.net.Uri;
import android.os.Build;
import android.text.TextUtils;

import androidx.core.content.FileProvider;

import java.io.File;

/**
 * 更新完成广播
 *
 * author: xiaoluo
 * date: 2017/8/15 11:22
 */
public class UpdateReceiverEx extends BroadcastReceiver {

    public UpdateReceiverEx() {

    }
    @Override
    public void onReceive(Context context, Intent intent) {
        String action = intent.getAction();
        if (DownloadManager.ACTION_DOWNLOAD_COMPLETE.equals(action)) {
            UpdateManagerEx.getInstance().onDownloadComplete(context,intent);
        }else if(DownloadManager.ACTION_NOTIFICATION_CLICKED.equals(action)){
            UpdateManagerEx.getInstance().onLookDownload(context);
        }
    }
}
