package com.wbsoft.wbyq;

import android.content.pm.PackageManager;
import android.content.pm.Signature;
import android.content.pm.SigningInfo;
import android.os.Build;
import android.os.Bundle;
import android.os.Debug;
import android.util.Log;

import androidx.annotation.RequiresApi;

import com.jqsoft.idcloudmb.IdCloudPlugin;

import java.io.BufferedReader;
import androidx.annotation.NonNull;
import java.io.File;
import java.io.FileReader;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Locale;

import io.flutter.embedding.engine.FlutterEngine;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.plugins.GeneratedPluginRegistrant;
import io.flutter.plugin.common.MethodChannel;
import android.view.Window;
import android.view.WindowManager;

public class MainActivity extends FlutterActivity {
  private boolean isUnderTraced() {
    String processStatusFilePath = String.format(Locale.US,  "/proc/%d/status", android.os.Process.myPid());
    File procInfoFile = new File(processStatusFilePath);
    try {
      BufferedReader b = new BufferedReader(new FileReader(procInfoFile));
      String readLine;
      while ((readLine = b.readLine()) != null) {
        // Log.e("TracerPid...",readLine);
        if(readLine.contains("TracerPid")) {
          String[] arrays = readLine.split(":");
          if(arrays.length == 2) {
            int tracerPid = Integer.parseInt(arrays[1].trim());
            if(tracerPid != 0) {
              return true;
            }
          }
        }
      }

      b.close();
    } catch (Exception e) {
      e.printStackTrace();
    }
    return false;
  }

  private void addTracePidCheck() {
    Thread t=new Thread(new Runnable() {
      @Override
      public void run() {
        while (true){
          try {
            Thread.sleep(100);
            if(Debug.isDebuggerConnected()){
              System.exit(0);
            }

            if(isUnderTraced()){
              System.exit(0);
            }
          } catch (InterruptedException e) {
            e.printStackTrace();
          }
        }
      }
    },"SafeGuardThread");
    t.start();
  }

  @RequiresApi(api = Build.VERSION_CODES.P)
  @Override
  public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
    GeneratedPluginRegistrant.registerWith(flutterEngine);
    new WbPlugin(this.getActivity(), flutterEngine);
    new IdCloudPlugin(this.getActivity(), flutterEngine);
    new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), "create")
            .setMethodCallHandler(
                    (call, result) -> {
                      addTracePidCheck();
                      final String signtureStr = getSignMd5Str(this);
                      // 校验签名收费为发布版本签名值
                      if (!"d24c82e0e6c750294e404326ce538614".equals(signtureStr)) {
                        Log.e("应用签名不一致，自动退出...", signtureStr);
                        System.exit(0);
                      }

                      Window win = getWindow();
                      win.addFlags(WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED //锁屏状态下显示
                                      | WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD //解锁
                              //| WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON //保持屏幕长亮
                              //| WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON //打开屏幕
                      );
                    });
    //new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), WbPlugin.METHOD_CHANNEL_NAME).setMethodCallHandler();
  }


  /*@Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    addTracePidCheck();
    final  String signtureStr = getSignMd5Str(this);
    // 校验签名收费为发布版本签名值
    if (!"d24c82e0e6c750294e404326ce538614".equals(signtureStr) ) {
      Log.e("应用签名不一致，自动退出...",signtureStr);
      System.exit(0);
    }

    boolean isRegisterOK = this.hasPlugin(GeneratedPluginRegistrant.class.getCanonicalName());
    GeneratedPluginRegistrant.registerWith(this);
    if (!isRegisterOK) {
      WbPlugin.registerWith(this,this.registrarFor("com.wbsoft.wbyq.WbPlugin"));
      IdCloudPlugin.registerWith(this.registrarFor("com.jqsoft.idcloudmb.IdCloudPlugin"));
    }
  }*/

  @RequiresApi(api = Build.VERSION_CODES.P)
  public String getSignMd5Str(MainActivity mActivity) {
    try {
      SigningInfo signingInfo = mActivity.getPackageManager().getPackageInfo(mActivity.getPackageName(), PackageManager.GET_SIGNING_CERTIFICATES).signingInfo;
      Signature[] sign = signingInfo.getApkContentsSigners();
      return encryptionMD5(sign[0].toByteArray());
    } catch (PackageManager.NameNotFoundException e) {
      e.printStackTrace();
    }
    return "";
  }

  private String encryptionMD5(byte[] byteStr) {
    MessageDigest messageDigest = null;
    StringBuilder md5StrBuff = new StringBuilder();
    try {
      messageDigest = MessageDigest.getInstance("MD5");
      messageDigest.reset();
      messageDigest.update(byteStr);
      byte[] byteArray = messageDigest.digest();
      for (byte b : byteArray) {
        if (Integer.toHexString(0xFF & b).length() == 1) {
          md5StrBuff.append("0").append(Integer.toHexString(0xFF & b));
        } else {
          md5StrBuff.append(Integer.toHexString(0xFF & b));
        }
      }
    } catch (NoSuchAlgorithmException e) {
      e.printStackTrace();
    }
    return md5StrBuff.toString();
  }
}
