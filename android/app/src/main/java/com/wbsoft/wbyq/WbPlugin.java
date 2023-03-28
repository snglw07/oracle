package com.wbsoft.wbyq;

import android.Manifest;
import android.annotation.TargetApi;
import android.app.Activity;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.graphics.BitmapFactory;
import android.graphics.Color;
import android.net.Uri;
import android.os.Build;
import android.util.Log;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;
import androidx.core.app.NotificationCompat;
import androidx.core.content.ContextCompat;

import android.os.Handler;
import android.os.Looper;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.TimerTask;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;
import io.flutter.embedding.engine.FlutterEngine;
import java.util.concurrent.atomic.AtomicBoolean;

import io.flutter.plugin.common.JSONMethodCodec;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import io.flutter.view.FlutterCallbackInformation;
import io.flutter.view.FlutterMain;
import io.flutter.view.FlutterNativeView;
import io.flutter.view.FlutterRunArguments;
import com.xiaoluo.updatelib.UpdateManagerEx;

/** WbPlugin */
public class WbPlugin implements MethodCallHandler {
  private static final String TAG = "WbPlugin";

  private static final String METHOD_CHANNEL_NAME = "wb_plugin";

  private static FlutterNativeView _backgroundFlutterView;
  private static MethodChannel _dispatchChannel;


  static private Long _registrationCallbackId;
  //push消息回调
  static private Long _onPushCallbackId;
  //callkit消息回调
  static private Long _onCallkitCallbackId;

  static private Map<String,Object> _pushMsgMap=new ConcurrentHashMap<>();

  private static final AtomicBoolean mHeadlessTaskRegistered = new AtomicBoolean(false);

  private int _tokenIncorrectTimes;
  private int _loginErrorCount;

  private Activity _activity;
  private static MethodChannel _channel;

  private static WbPlugin _instance;
    private static FlutterEngine _flutterEngine;

  private static boolean _cfgInited=false;

  //private static RongLogin _rongLogin=new RongLogin();
  //private static MIPushLogin _miPushLogin=new MIPushLogin();

  private static String _appId;
  private static String _serverAddress;
  private static String _accessToken;

  private static ConcurrentMap<String, Object> _globalKV = new ConcurrentHashMap<>();
  private static boolean _timerIsRun=false;

  public WbPlugin(Activity activity, FlutterEngine flutterEngine){
      _flutterEngine = flutterEngine;
      _activity = activity;
      _channel = new MethodChannel(_flutterEngine.getDartExecutor(), WbPlugin.METHOD_CHANNEL_NAME);
      _channel.setMethodCallHandler(this);
      _instance = this;

      try {
          PackageManager pm = activity.getPackageManager();
          PackageInfo info = pm.getPackageInfo(activity.getPackageName(), 0);
          String[] arr= info.applicationInfo.packageName.split("[.]");
          _appId=arr[arr.length-1];
      }catch (Exception e){
          Log.e(TAG,e.getMessage(),e);
      }

  }


  java.util.Timer _timer = new java.util.Timer(true);

  TimerTask _task = new TimerTask() {
    public void run() {
        onHeartBeat();
    }
  };

  private void onHeartBeat(){
      if(_appId==null || _accessToken==null || _serverAddress==null )
          return;

      try {
          String appUrl = _serverAddress+"/w/control/appd.heartbeat/"+_appId;

          URL url = new URL(appUrl);
          HttpURLConnection conn = (HttpURLConnection) url.openConnection();
          conn.setRequestMethod("GET");
          conn.setReadTimeout(1000);
          conn.setRequestProperty("_ACCESS_TOKEN", _accessToken);

          int code = conn.getResponseCode();
          //if(code==401)
          //    _timer.cancel();
      } catch (Exception e) {
          Log.e("APP","获取app配置出错",e);
      }
  }

    private static String readInputStream(InputStream is) {
        try {
            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            int len = 0;
            byte[] buffer = new byte[1024];
            while ((len = is.read(buffer)) != -1) {
                baos.write(buffer, 0, len);
            }
            baos.close();
            is.close();
            byte[] result = baos.toByteArray();
            return new String(result);
        } catch (Exception e) {
            // TODO Auto-generated catch block
            e.printStackTrace();
            return null;
        }

    }

  public static ArrayList<String> getRongMemberIdByGroupId(String groupId){
      if(_appId==null || _accessToken==null || _serverAddress==null )
          return null;

      try {
          String appUrl = _serverAddress+"w/control/exec/appd.query.chatgroup.member.sql?groupId="+groupId;

          URL url = new URL(appUrl);
          HttpURLConnection conn = (HttpURLConnection) url.openConnection();
          conn.setRequestMethod("GET");
          conn.setReadTimeout(5000);
          conn.setRequestProperty("_ACCESS_TOKEN", _accessToken);

          int code = conn.getResponseCode();
          if (code == 200) {
              InputStream is = conn.getInputStream();
              String result = readInputStream(is);

              final JSONObject json= new JSONObject(result);
              JSONArray arr=json.getJSONArray("exec");

              ArrayList<String> ret=new ArrayList<>();
              for(int i=0;i<arr.length();i++){
                  ret.add(_appId+"."+arr.getJSONObject(i).getString("userLoginId"));
              }

              return ret;
          }
      } catch (Exception e) {
          Log.e("APP","getRongMemberIdByGroupId 出错",e);
      }

      return null;
  }

  @Override
  public void onMethodCall(MethodCall call, Result result) {
      Log.d(TAG,".........................."+call.method);
    if ("configure".equals(call.method)) {
        if(!_cfgInited){
            //初始化mipush
            String miPushAppId=call.argument("miPushAppId");
            String miPushAppKey=call.argument("miPushAppKey");
            initMiPush(miPushAppId,miPushAppKey);

            //初始化融云 sdk
            String rongAppKey=call.argument("rongAppKey");
            initRong(rongAppKey);
        }

        //TODO:在这里检查下，是否有版本更新

        result.success(_cfgInited);
        _cfgInited=true;
    }else if("registerHeadlessCallback".equals(call.method)){
        registerHeadlessCallback(call);

        result.success(true);
    }else if (call.method.equalsIgnoreCase("initialized")) {
      synchronized(mHeadlessTaskRegistered) {
        mHeadlessTaskRegistered.set(true);
      }
      result.success(true);
    }else if("setPushAlias".equals(call.method)){
        String alias=call.argument("alias");
        //_miPushLogin.setAlias(alias);

      result.success(true);
    }else if("loginCallkit".equals(call.method)){
        String token=call.argument("token");
        String userLoginId=call.argument("userLoginId");
        String lastName=call.argument("lastName");
        String headImgUrl=call.argument("headImgUrl");

        login(token,userLoginId,lastName,headImgUrl);
        result.success(true);
    }else if(call.method.equals("get")){
      String key=call.argument("key");

      if("isDebug".equals(key)){
          result.success(BuildConfig.DEBUG);
      }else
        result.success(key==null?null:_globalKV.get(key));
  }else if(call.method.equals("set")){
      String key=call.argument("key");
      Object value=call.argument("value");
      if(key!=null && value!=null) {
          _globalKV.put(key, value);
          result.success(true);
      }else
          result.success(false);
  }else if("setAccessToken".equals(call.method)){
        _serverAddress=call.argument("serverAddress");
        _accessToken=call.argument("accessToken");

        //_timer.cancel();
        if(!_timerIsRun) {
            _timerIsRun=true;
            //_timer.schedule(_task, 1000, 240000);//4分钟1次
        }

    }else if("fetchMissingMessage".equals(call.method)){

        List<Object> list=new ArrayList<>();
        for(Map.Entry<String,Object> entry :_pushMsgMap.entrySet()){
            list.add(entry.getValue());
        }
        _pushMsgMap.clear();

        result.success(list);
    }else if (call.method.equals("startSingleCall")) {
        String userId=call.argument("userId");
        String callMediaType=call.argument("callMediaType");

        //_rongLogin.startSingleCall(_activity,userId, "CALL_MEDIA_TYPE_AUDIO".equals(callMediaType));
    }else if (call.method.equals("startMultiCall")) {
        List<String> userIds=call.argument("userIds");
        String targetId=call.argument("targetId");
        String callMediaType=call.argument("callMediaType");
        String ct=call.argument("conversationType");

        //_rongLogin.startMultiCall(_activity,userIds,targetId,"CALL_MEDIA_TYPE_AUDIO".equals(callMediaType),ct);
    }else if (call.method.equals("addParticipants")) {
        List<String> userIds=call.argument("userIds");
        String targetId=call.argument("targetId");
        List<String> observerUserIds=call.argument("observerUserIds");

        //_rongLogin.addParticipants(targetId,userIds,observerUserIds);
    }else if (call.method.equals("onMessageCB")){
        String messageId=call.argument("messageId");
        if(messageId!=null)
            _pushMsgMap.remove(messageId);
    }else if(call.method.equals("checkAppUpdate")){
        if (ContextCompat.checkSelfPermission(_activity, Manifest.permission.WRITE_EXTERNAL_STORAGE)
                != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(_activity, new String[]{Manifest.permission.WRITE_EXTERNAL_STORAGE}, 1);
        }

        String apkurl="http://gw.cqblt.cn/appd.apk";

        if(call.hasArgument("apkurl") && call.argument("apkurl")!=null)
            apkurl=call.argument("apkurl");

        String downloadTitle="正在下载...";
        if(call.hasArgument("downloadTitle") && call.argument("downloadTitle")!=null)
            downloadTitle=call.argument("downloadTitle");

        String lastestVerName="1.0";
        if(call.hasArgument("lastestVerName") && call.argument("lastestVerName")!=null)
            lastestVerName=call.argument("lastestVerName");

        int lastestVerCode=1;
        if(call.hasArgument("lastestVerCode") && call.argument("lastestVerCode")!=null)
            lastestVerCode=call.argument("lastestVerCode");

        String minVerName="1.0";
        if(call.hasArgument("minVerName") && call.argument("minVerName")!=null)
            minVerName=call.argument("minVerName");

        int minVerCode=1;
        if(call.hasArgument("minVerCode") && call.argument("minVerCode")!=null)
            minVerCode=call.argument("minVerCode");

        boolean forceUpdate=false;
        if(call.hasArgument("forceUpdate") && call.argument("forceUpdate")!=null)
            forceUpdate=call.argument("forceUpdate");

        UpdateManagerEx.getInstance().init(_activity)
                .compare(UpdateManagerEx.COMPARE_VERSION_CODE) // 通过版本号或版本名比较,默认版本号
                .downloadUrl(apkurl) // 下载地址,必要
                .downloadTitle(downloadTitle)                 // 下载标题
                .lastestVerName(lastestVerName)                         // 最新版本名
                .lastestVerCode(lastestVerCode)                              // 最新版本号
                .minVerName(minVerName)                             // 最低版本名
                .minVerCode(minVerCode)                                  // 最低版本号
                .isForce(forceUpdate)                                 // 是否强制更新,true无视版本直接更新
                .update();

        UpdateManagerEx.getInstance().setListener(new UpdateManagerEx.UpdateListener() {
            @Override
            public void onCheckResult(String result) {
                Toast.makeText(_activity, result, Toast.LENGTH_SHORT).show();
            }
        });

        result.success("OK");
    }else {
      result.notImplemented();
    }
  }

  //初始化所有flutter isolate 回调
  private void registerHeadlessCallback(MethodCall call){
      _registrationCallbackId=call.argument("registrationCB");
      _onPushCallbackId=call.argument("pushCB");
      _onCallkitCallbackId=call.argument("callkitCB");

      //单位秒
     // Integer heartHitPeriodSeconds=call.argument("heartHitPeriodSeconds");
     // if(heartHitPeriodSeconds==null)
     //     heartHitPeriodSeconds=5;

      if(_backgroundFlutterView==null)
          initFlutterView(_activity);

     // if(_onHeartHitCallbackId!=null  && heartHitPeriodSeconds>0)
      //    _timer.schedule(task, 1000, heartHitPeriodSeconds*1000);
  }

  ///初始化小米推送有配置
  private void initMiPush(String miPushAppId,String miPushAppKey){
      if(miPushAppId!=null && miPushAppKey!=null) {
         // _miPushLogin.init(_activity, miPushAppId, miPushAppKey);
      }
  }

  ///初始化融云配置
  private void initRong(String rongAppKey){
      if(rongAppKey!=null) {
//        _rongLogin.init(_activity, rongAppKey, new RongIMClient.ConnectionStatusListener() {
//          @Override
//          public void onChanged(ConnectionStatus status) {
//            if (status == ConnectionStatus.TOKEN_INCORRECT) {
//              Log.d(TAG, "#####################ConnectCallback connect onTokenIncorrect1");
//
//              Map<String, Object> map = new HashMap<>();
//
//              map.put("method", "onTokenIncorrect");
//              map.put("incorrectTimes", _tokenIncorrectTimes++);
//
//              callDart(_onCallkitCallbackId,map);
//            }
//          }
//        });
      }
  }

  static void  postMessage(String messageId,Object message){
      if (messageId != null && message != null) {
          _pushMsgMap.put(messageId, message);
          if (_channel != null) {
              Log.e(TAG, " _channel.invokeMethod:  ---------------:" + messageId);
              //!!! 坑 必须在mainThread中 才可以唤醒消息
              new Handler(Looper.getMainLooper()).post(new Runnable() {
                  @Override
                  public void run() {
                      _channel.invokeMethod("onMessage", message);//new Object[]{messageId,message});
                  }
              });

              Log.e(TAG, " _channel.invokeMethod:  ---------------onMessage:ok ");
          }
      }
  }

  static void postRongCallkitMessage(Object json){
      if (_channel != null) {
          new Handler(Looper.getMainLooper()).post(new Runnable() {
              @Override
              public void run() {
                  _channel.invokeMethod("onRongCallkitMessage", json);
              }
          });
      }
  }

  private void login(String rongToken,String userLoginId,String lastName,String headImgUrl){
    _tokenIncorrectTimes=0;
    _loginErrorCount=0;

    //_rongLogin.login(rongToken,userLoginId,lastName,headImgUrl,getConnectCallback());
  }

  public static void onCommandCB(Map<String, Object> map){
//    if ("register".equals(map.get("command")) && map.containsKey("regId")){
//      //_miPushLogin.setInitedOK();
//    }else if(MiPushClient.COMMAND_SET_ALIAS.equals(map.get("command"))){
//        //更新最后一次登录mi push的用户id
//          String alias=String.class.cast(map.get("alias"));
//          if(alias!=null)
//              _miPushLogin.setLastLoginIn(alias);
//      }

    Log.d(TAG,"onCommandCB:"+map);
    if(_onPushCallbackId==null){
      //Log.d(TAG, "WbpushPlugin还未初始化成功1...");
      return;
    }

    //onCommandCB
    map.put("method", "onCommandCB");
    callDart(_onPushCallbackId,map);
  }

  public static void onMessage(String type,Map<String, Object> map){
      map.put("method", "onMessage");
      map.put("type",type);
//      map.put("acceptUserLoginId",_miPushLogin.getLastLoginUserLoginId());
//      String sendUserLoginId=String.class.cast(map.get("sendUserLoginId"));
//      if(sendUserLoginId!=null && sendUserLoginId.equals(_miPushLogin.getLastLoginUserLoginId())){
//          SimpleDateFormat formatter = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
//          String now = formatter.format(new Date());
//          map.put("acceptDate",now);
//      }

      String messageId=String.class.cast(map.get("messageId"));
      postMessage(messageId,map);

      String createdUserLoginId=null;
      if(Map.class.cast(map.get("extra"))!=null ){
          createdUserLoginId=String.class.cast(Map.class.cast((map.get("extra"))).get("createdUserLoginId"));
      }
      String description=String.class.cast(map.get("description"));
      //语音图像消息 全部进行提示 仅仅处理别人发送的穿透消息
//      if(description.contains("targetId")&& "PASS_THROUGH".equals(type) && createdUserLoginId!=null && !createdUserLoginId.equals(_miPushLogin.getLastLoginUserLoginId())){
//          showNotify(map);
//      }else if(!AppLifecycleHandler.isApplicationInForeground() && "PASS_THROUGH".equals(type) && createdUserLoginId!=null && !createdUserLoginId.equals(_miPushLogin.getLastLoginUserLoginId())){
//          showNotify(map);
//      }


    if(_onPushCallbackId!=null){
      //Log.d(TAG, "WbpushPlugin还未初始化成功2...");
        callDart(_onPushCallbackId,map);
    }
  }

  private static void showNotify(Map<String, Object> map){
     if(_instance._activity==null)
         return;

      String title=String.class.cast(map.get("title"));
      if(title==null)title="无标题";
      String description=String.class.cast(map.get("description"));
      if(description==null)description="未知";
      if(description.contains("上传文件") && description.contains("md5") ){
          description="图片消息";
      }else if(description.contains("targetId")&& description.contains("onlyAudio")&& description.contains("true") ){
          description="语音消息";
      }else if(description.contains("targetId")&& description.contains("onlyAudio")&& description.contains("false") ){
          description="视频消息";
      }

      // 获取系统 通知管理 服务
      NotificationManager notificationManager = (NotificationManager) _instance._activity.getSystemService(Context.NOTIFICATION_SERVICE);

      // 构建 Notification
      Notification.Builder builder = new Notification.Builder( _instance._activity);
      builder.setContentTitle(title)
              .setSmallIcon(R.mipmap.ic_launcher)
              .setContentText(description)
              .setDefaults(Notification.DEFAULT_ALL)
              .setAutoCancel(true);

      // 点击后要执行的操作，打开MainActivity
      Intent intent = new Intent(_instance._activity, MainActivity.class);
      PendingIntent pendingIntents = PendingIntent.getActivity(_instance._activity, 0, intent, PendingIntent.FLAG_ONE_SHOT);
      builder.setContentIntent(pendingIntents);

// 兼容  API 26，Android 8.0
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O){
          // 第三个参数表示通知的重要程度，默认则只在通知栏闪烁一下
          NotificationChannel notificationChannel = new NotificationChannel(_appId, "提示消息", NotificationManager.IMPORTANCE_DEFAULT);
          // 注册通道，注册后除非卸载再安装否则不改变
          notificationManager.createNotificationChannel(notificationChannel);
          builder.setChannelId(_appId);
      }
// 发出通知
      notificationManager.notify(1, builder.build());
  }


  public static void reInitPush(Context ctx){
      //_miPushLogin.reInit();
  }

  private static void callDart(Long callbackId,Map<String,Object> params){
      if(callbackId==null)
          return;

    synchronized(mHeadlessTaskRegistered) {
      if (!mHeadlessTaskRegistered.get()) {
        // Queue up events while background isolate is starting
        Log.d(TAG,"[HeadlessTask] waiting for client to initialize");
      } else {
        JSONObject response = new JSONObject();
        try {
          response.put("callbackId", callbackId);
          for(Map.Entry<String,Object> entry : params.entrySet()){
              response.put(entry.getKey(),entry.getValue());
          }

            _dispatchChannel.invokeMethod("", response);
        } catch (JSONException e) {
          Log.e(TAG,e.getMessage(),e);
        }
      }
    }
  }

  private void initFlutterView(Context context) {
    FlutterMain.ensureInitializationComplete(context, null);

    FlutterCallbackInformation callbackInfo = FlutterCallbackInformation.lookupCallbackInformation(_registrationCallbackId);

    if (callbackInfo == null) {
      Log.e(TAG,"Fatal: failed to find callback");
      return;
    }

      _backgroundFlutterView = new FlutterNativeView(context.getApplicationContext(), true);

    // Create the Transmitter channel
     _dispatchChannel = new MethodChannel(_backgroundFlutterView, METHOD_CHANNEL_NAME + "/headless", JSONMethodCodec.INSTANCE);
     _dispatchChannel.setMethodCallHandler(this);

    //_pluginRegistrantCallback.registerWith(_backgroundFlutterView.getPluginRegistry());

    // Dispatch back to client for initialization.
    FlutterRunArguments args = new FlutterRunArguments();
    args.bundlePath = FlutterMain.findAppBundlePath(context);
    args.entrypoint = callbackInfo.callbackName;
    args.libraryPath = callbackInfo.callbackLibraryPath;
      _backgroundFlutterView.runFromBundle(args);
  }


}

