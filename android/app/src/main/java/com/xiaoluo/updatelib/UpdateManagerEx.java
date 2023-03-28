package com.xiaoluo.updatelib;

import android.Manifest;
import android.app.Activity;
import android.app.DownloadManager;
import android.app.ProgressDialog;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.pm.PackageManager;
import android.database.Cursor;
import android.net.Uri;
import android.os.Build;
import android.os.Environment;
import android.os.Handler;
import android.os.Message;
import android.text.TextUtils;
import android.util.Log;
import android.widget.Toast;

import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import androidx.core.content.FileProvider;


import com.wbsoft.wbyq.R;

import java.io.File;

/**
 * 更新管理类
 *
 * author: xiaoluo
 * date: 2017/8/15 10:09
 */
public class UpdateManagerEx {

    public static final int COMPARE_VERSION_NAME = 110;                    // 版本名比较
    public static final int COMPARE_VERSION_CODE = 120;                    // 版本号比较
    public static final String RESULT_LASTEST = "最新版本";         // 最新版本
    public static final String RESULT_FORCE = "强制更新";              // 强制更新
    public static final String RESULT_NOT_LASTEST = "低于最新"; // 低于最新

    public static String mApkPath = "";
    public static long mApkId = -1;
    public static boolean isUpdating = false;  // 是否更新中
    private static UpdateManagerEx mInstance;

    private Context mContext;

    private String mLastestVerName = "";                // 最新版本名
    private int mLastestVerCode = -1;                   // 最新版本号
    private String mMinVerName = "";                    // 最低版本名
    private int mMinVerCode = -1;                       // 最低版本号
    private String mCurrentVerName = "";                // 当前版本名
    private int mCurrentVerCode = -1;                   // 当前版本号
    private boolean isForce = false;                    // 是否强制更新
    private String mDownloadUrl = "";                   // 下载地址
    private String mDownloadTitle = "下载新版本中...";   // 下载标题
    private int mCompare = COMPARE_VERSION_CODE;        // 默认使用版本号检测
    private UpdateListener mListener;

    //下载进度弹窗
    private DownloadProgressDialog progressDialog;

    //查询下载进度
    private class QueryRunnable implements Runnable {
        @Override
        public void run() {
            queryState();
            mHandler.postDelayed(mQueryProgressRunnable,100);
        }
    }

    private DownloadManager mDownloadManager;
    private final QueryRunnable mQueryProgressRunnable = new QueryRunnable();
    private final Handler mHandler = new Handler() {
        @Override
        public void handleMessage(Message msg) {
            super.handleMessage(msg);
            if (msg.what == 1001) {
                if (progressDialog != null) {
                    progressDialog.setProgress(msg.arg1);
                    progressDialog.setMax(msg.arg2);
                }
            }
        }
    };

    //查询下载进度
    private void queryState() {
        // 通过ID向下载管理查询下载情况，返回一个cursor
        Cursor c = mDownloadManager.query(new DownloadManager.Query().setFilterById(mApkId));
        if (c == null) {
            Toast.makeText(mContext, "下载失败",Toast.LENGTH_SHORT).show();
            finish();
        } else { // 以下是从游标中进行信息提取
            if (!c.moveToFirst()) {
                Toast.makeText(mContext,"下载失败",Toast.LENGTH_SHORT).show();
                finish();
                if(!c.isClosed()) {
                    c.close();
                }
                return;
            }else{
                int status = c.getInt(c.getColumnIndex(DownloadManager.COLUMN_STATUS));
                switch (status) {
                    case DownloadManager.STATUS_PAUSED:
                    case DownloadManager.STATUS_PENDING:
                    case DownloadManager.STATUS_RUNNING:
                        // Do something
                        break;
                    case DownloadManager.STATUS_SUCCESSFUL:
                        // Do something
                        break;
                    case DownloadManager.STATUS_FAILED:
                        int reason = c.getInt(c.getColumnIndex(DownloadManager.COLUMN_REASON));
                        Log.w("UpdateManagerex", "Download (" + mApkId + ") failed. Reason: " + reason);
                }
            }
            int mDownload_so_far = c.getInt(c.getColumnIndex(DownloadManager.COLUMN_BYTES_DOWNLOADED_SO_FAR));
            int mDownload_all = c.getInt(c.getColumnIndex(DownloadManager.COLUMN_TOTAL_SIZE_BYTES));
            Message msg=Message.obtain();
            if(mDownload_all>0) {
                msg.what = 1001;
                msg.arg1=mDownload_so_far;
                msg.arg2=mDownload_all;
                mHandler.sendMessage(msg);
            }
            if(!c.isClosed()){
                c.close();
            }
        }
    }

    private UpdateManagerEx() {

    }

    /**
     * 单例创建,必备
     */
    public static UpdateManagerEx getInstance() {
        if (mInstance == null) {
            mInstance = new UpdateManagerEx();
        }
        return mInstance;
    }

    /**
     * 初始化,必备
     */
    public UpdateManagerEx init(Context context) {
        this.mContext = context;
        mCurrentVerName = LibUtils.getVersionName(mContext);
        mCurrentVerCode = LibUtils.getVersionCode(mContext);

        //initReceiver();

        return this;
    }

    //初始化广播接收者
//    private void initReceiver(){
//        IntentFilter downloadCompleteFilter = new IntentFilter(DownloadManager.ACTION_DOWNLOAD_COMPLETE);
//        mContext.registerReceiver(mDownloadCompleteReceiver, downloadCompleteFilter);
//        IntentFilter downloadDetailsFilter = new IntentFilter(DownloadManager.ACTION_NOTIFICATION_CLICKED);
//        mContext.registerReceiver(mDownloadDetailsReceiver, downloadDetailsFilter);
//    }

    // 下载完成监听，下载完成之后自动安装
    public void onDownloadComplete(Context context,Intent intent){
        long downloadId = intent.getLongExtra(DownloadManager.EXTRA_DOWNLOAD_ID, 0);
        // 查询
        DownloadManager.Query query = new DownloadManager.Query();
        query.setFilterById(downloadId);
        Cursor c = mDownloadManager.query(query);
        if (c!=null && c.moveToFirst()) {
            int columnIndex = c.getColumnIndex(DownloadManager.COLUMN_STATUS);
            if (DownloadManager.STATUS_SUCCESSFUL == c.getInt(columnIndex)) {
                finish();
                installApkByGuide(context,mApkPath);
            }
        }
        if(c != null && ! c.isClosed()){
            c.close();
        }
    }

    //进入下载详情
    public void onLookDownload(Context context) {
        Intent intent=new Intent(DownloadManager.ACTION_VIEW_DOWNLOADS);
        if(intent.resolveActivity(context.getPackageManager())!=null){
            context.startActivity(intent);
        }
    }

//    // 下载完成监听，下载完成之后自动安装
//    private final BroadcastReceiver mDownloadCompleteReceiver = new BroadcastReceiver() {
//        @Override
//        public void onReceive(Context context, Intent intent) {
//            String action = intent.getAction();
//            if (DownloadManager.ACTION_DOWNLOAD_COMPLETE.equals(action)) {
//                long downloadId = intent.getLongExtra(DownloadManager.EXTRA_DOWNLOAD_ID, 0);
//                // 查询
//                DownloadManager.Query query = new DownloadManager.Query();
//                query.setFilterById(downloadId);
//                Cursor c = mDownloadManager.query(query);
//                if (c!=null && c.moveToFirst()) {
//                    int columnIndex = c.getColumnIndex(DownloadManager.COLUMN_STATUS);
//                    if (DownloadManager.STATUS_SUCCESSFUL == c.getInt(columnIndex)) {
//                        finish();
//                        installApkByGuide(mApkPath);
//                    }
//                }
//                if(c != null && ! c.isClosed()){
//                    c.close();
//                }
//            }
//        }
//    };

//    // 通知栏点击事件，点击进入下载详情
//    private final BroadcastReceiver mDownloadDetailsReceiver = new BroadcastReceiver() {
//        @Override
//        public void onReceive(Context context, Intent intent) {
//            String action = intent.getAction();
//            if (DownloadManager.ACTION_NOTIFICATION_CLICKED.equals(action)) {
//                lookDownload();
//            }
//        }
//    };

    //安装apk
    private void installApkByGuide(Context context,String uriString) {
        if (TextUtils.isEmpty(mApkPath)) {
            return;
        }

        Uri uri;
        Intent intent = new Intent(Intent.ACTION_VIEW);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
            uri = FileProvider.getUriForFile(context, context.getPackageName() + ".FileProvider",
                    new File(mApkPath));
        } else {
            uri = Uri.fromFile(new File(mApkPath));
        }
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        intent.setDataAndType(uri, "application/vnd.android.package-archive");
        context.startActivity(intent);
    }


    /**
     * 最新版本名
     */
    public UpdateManagerEx lastestVerName(String versionName) {
        this.mLastestVerName = versionName;
        return this;
    }

    /**
     * 最新版本号
     */
    public UpdateManagerEx lastestVerCode(int versionCode) {
        this.mLastestVerCode = versionCode;
        return this;
    }

    /**
     * 最低版本名
     */
    public UpdateManagerEx minVerName(String versionName) {
        this.mMinVerName = versionName;
        return this;
    }

    /**
     * 最低版本号
     */
    public UpdateManagerEx minVerCode(int versionCode) {
        this.mMinVerCode = versionCode;
        return this;
    }

    /**
     * 忽略版本名和版本号,强制更新
     */
    public UpdateManagerEx isForce(boolean isForce) {
        this.isForce = isForce;
        return this;
    }

    /**
     * 通过版本名或版本号比较更新版本
     * 默认通过版本号
     */
    public UpdateManagerEx compare(int compare) {
        this.mCompare = compare;
        return this;
    }

    /**
     * 下载地址,必备
     */
    public UpdateManagerEx downloadUrl(String url) {
        this.mDownloadUrl = url;
        return this;
    }

    /**
     * 下载通知栏标题
     */
    public UpdateManagerEx downloadTitle(String title) {
        this.mDownloadTitle = title;
        return this;
    }

    /**
     * 开始逻辑,必备
     */
    public UpdateManagerEx update() {
        if (isUpdating) {
            Toast.makeText(mContext, "正在检查版本更新...", Toast.LENGTH_SHORT).show();
            return this;
        } else {
            checkUpdate();
            return this;
        }
    }

    /**
     * 设置更新检测回调
     */
    public UpdateManagerEx setListener(UpdateListener listener) {
        this.mListener = listener;
        return this;
    }

    /**
     * 检查更新
     */
    private void checkUpdate() {
        // 跳过版本对比，强制更新
        if (isForce) {
            beginUpdate(true);
            if (mListener != null) {
                mListener.onCheckResult(RESULT_FORCE);
            }
            return;
        }
        switch (mCompare) {
            case COMPARE_VERSION_CODE:
                compareVerCode();
                break;
            case COMPARE_VERSION_NAME:
                compareVerName();
                break;
            default:
                compareVerCode();
                break;
        }
    }

    /**
     * 比较版本号
     */
    private void compareVerCode() {
        if (mCurrentVerCode < mMinVerCode) {
            beginUpdate(true);
            if (mListener != null) {
                mListener.onCheckResult(RESULT_FORCE);
            }
            return;
        }
        if (mCurrentVerCode < mLastestVerCode) {
            beginUpdate(false);
            if (mListener != null) {
                mListener.onCheckResult(RESULT_NOT_LASTEST);
            }
        } else {
            if (mListener != null) {
                mListener.onCheckResult(RESULT_LASTEST);
            }
        }
    }

    /**
     * 比较版本名
     */
    private void compareVerName() {
        // 版本名小于最低,强制更新
        if (!TextUtils.isEmpty(mMinVerName)) {
            int min = LibUtils.compareVersion(mCurrentVerName, mMinVerName);
            if (min < 0) {
                beginUpdate(true);
                if (mListener != null) {
                    mListener.onCheckResult(RESULT_FORCE);
                }
                return;
            }
        }

        // 版本名小于最新,提示更新
        int last = LibUtils.compareVersion(mCurrentVerName, mLastestVerName);
        if (last < 0) {
            beginUpdate(false);
            if (mListener != null) {
                mListener.onCheckResult(RESULT_NOT_LASTEST);
            }
        } else {
            if (mListener != null) {
                mListener.onCheckResult(RESULT_LASTEST);
            }
        }
    }

    /**
     * 开始更新
     * @param forceUpdate 是否强制更新
     */
    private void beginUpdate(final boolean forceUpdate) {
        if (ContextCompat.checkSelfPermission(mContext, Manifest.permission.WRITE_EXTERNAL_STORAGE)
                != PackageManager.PERMISSION_GRANTED) {
            Toast.makeText(mContext, "请申请读写SD卡权限", Toast.LENGTH_SHORT).show();
            return;
        }

        mDownloadManager = (DownloadManager)mContext.getSystemService(mContext.DOWNLOAD_SERVICE);

        ConfirmDialog dialog = new ConfirmDialog(mContext);
        if (forceUpdate) {
            String msg="当前版本过低\n请更新至["+mLastestVerName+"]版";
            dialog.setMessage(msg)
                    .setLeftText("退出程序")
                    .setRightText("立即更新")
                    .setCanceledOnTouchOutside(false);
            dialog.setCancelable(false);
        } else {
            String msg="发现新版本["+mLastestVerName+"]\n是否马上更新?";
            dialog.setMessage(msg)
                    .setLeftText("稍后更新")
                    .setRightText("立即更新");
        }
        dialog.setOnSelectListener(new ConfirmDialog.OnSelectListener() {
            @Override
            public void onLeftSelect() {
                if (forceUpdate) {
                    ((Activity) mContext).finish();
                    System.exit(0);
                }
            }

            @Override
            public void onRightSelect() {
                startDownloadApk();
            }
        }).show();
    }

    /**
     * 下载
     */
    private void startDownloadApk() {
        if (TextUtils.isEmpty(mDownloadUrl)) {
            return;
        }

        String filePath = null;
        if (Environment.getExternalStorageState().equals(Environment.MEDIA_MOUNTED)) {//外部存储卡
            filePath = Environment.getExternalStorageDirectory().getAbsolutePath();
        } else {
            Toast.makeText(mContext, "没有SD卡", Toast.LENGTH_SHORT).show();
            return;
        }
        mApkPath = filePath + File.separator + "update_" +mLastestVerName+".apk";
        File file = new File(mApkPath);
        if (file.exists()) {
            file.delete();
            System.gc();
        }
        Uri fileUri = Uri.parse("file://" + mApkPath);

        //mDownloadUrl="https://www.ncgzjk.cn/wbappd_nc.apk";

        Uri uri = Uri.parse(mDownloadUrl);
        DownloadManager downloadManager = (DownloadManager) mContext.getSystemService(Context.DOWNLOAD_SERVICE);
        DownloadManager.Request request = new DownloadManager.Request(uri);
        request.setAllowedNetworkTypes(DownloadManager.Request.NETWORK_MOBILE | DownloadManager.Request.NETWORK_WIFI);
        request.setVisibleInDownloadsUi(true);
        request.setTitle(mDownloadTitle);
        request.setDestinationUri(fileUri);
        mApkId = downloadManager.enqueue(request);
        isUpdating = true;
        startQuery();
    }
    //更新下载进度
    private void startQuery() {
        if (mApkId != 0) {
            displayProgressDialog();
            mHandler.post(mQueryProgressRunnable);
        }
    }

    //进度对话框
    private void displayProgressDialog() {
        if (progressDialog == null) {
            // 创建ProgressDialog对象
            progressDialog = new DownloadProgressDialog(mContext, R.style.Theme_AppCompat_Light_Dialog_Alert);
            // 设置进度条风格，风格为长形
            progressDialog.setProgressStyle(ProgressDialog.STYLE_HORIZONTAL);
            // 设置ProgressDialog 标题
            progressDialog.setTitle("下载提示");
            // 设置ProgressDialog 提示信息
            progressDialog.setMessage("当前下载进度:");
            // 设置ProgressDialog 的进度条是否不明确
            progressDialog.setIndeterminate(false);
            // 设置ProgressDialog 是否可以按退回按键取消
            progressDialog.setCancelable(false);
            progressDialog.setProgressDrawable(mContext.getResources().getDrawable(R.drawable.progressbar_bg));//download_progressdrawable rc_progress_sending_style
            progressDialog.setButton(DialogInterface.BUTTON_NEGATIVE, "取消", new DialogInterface.OnClickListener() {
                @Override
                public void onClick(DialogInterface dialog, int which) {
                    removeDownload();
                    dialog.dismiss();
                    finish();

                    System.exit(0);
                }
            });
        }
        if (!progressDialog.isShowing()) {
            // 让ProgressDialog显示
            progressDialog.show();
        }
    }

    //下载停止同时删除下载文件
    private void removeDownload() {
        if(mDownloadManager!=null){
            mDownloadManager.remove(mApkId);
        }
    }

    void finish(){
//        if(mDownloadCompleteReceiver!=null) {
//            mContext.unregisterReceiver(mDownloadCompleteReceiver);
//        }
//        if(mDownloadDetailsReceiver!=null) {
//            mContext.unregisterReceiver(mDownloadDetailsReceiver);
//        }

        if(mContext!=null)
            ((Activity) mContext).finish();
    }

    /**
     * 更新检测回调
     */
    public interface UpdateListener {
        void onCheckResult(String result);
    }
}
