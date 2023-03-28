package com.jqsoft.idcloudmb;

import android.Manifest;
import android.app.Activity;
import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.nfc.NfcAdapter;
import android.nfc.NfcManager;
import android.nfc.Tag;
import android.nfc.tech.NfcB;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.os.Message;
import android.util.Log;

import androidx.annotation.NonNull;

import java.io.ByteArrayOutputStream;
import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;

import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class IdCloudPlugin implements FlutterPlugin,MethodChannel.MethodCallHandler, EventChannel.StreamHandler, NfcAdapter.ReaderCallback, ActivityAware {
    final int PERMISSION_NFC = 1007;

    private static final String TAG = "IdCloudPlugin";

    public static final String METHOD_CHANNEL_NAME = "id_cloud_plugin";
    public static final String EVENT_CHANNEL_NAME = "id_cloud_plugin/nfcReader";

    static {
        System.loadLibrary("idcloudmb");
    }

    private native boolean NfcInit(String netAddress, String uid, List<String> subscribers, List<String> notifiers);

    private native boolean NfcReadIdCard(String accessToken, NfcB nfcB, HashMap<String, Object> result);


    private NfcAdapter _nfcAdapter;
    private EventChannel.EventSink _eventChannel;

    private static MethodChannel _channel;

    private MethodChannel.Result _readResult;

    private final Handler _handler = new Handler(Looper.getMainLooper()) {
        @Override
        public void handleMessage(Message msg) {
            if (msg.what == 0) {
                if (_readResult != null) {
                    _readResult.success(msg.obj);
                    _readResult = null;
                } else if (_eventChannel != null)
                    _eventChannel.success(msg.obj);
            } else if (msg.what == 1) {

                Map params = (Map) msg.obj;

                NfcB nfcB = NfcB.get((Tag) params.get("tag"));

                HashMap<String, Object> nfcResult = new HashMap<>();

                boolean isOK = NfcReadIdCard((String) params.get("accessToken"), nfcB, nfcResult);

                sendNfcMessage(nfcResult);

            } else if (msg.what == 2) {
                Tag tag = (Tag) msg.obj;

                assert tag != null;
                startReader(tag);
            }
        }
    };

    public IdCloudPlugin(Activity activity, FlutterEngine flutterEngine) {
        _channel = new MethodChannel(flutterEngine.getDartExecutor(), IdCloudPlugin.METHOD_CHANNEL_NAME);
        _channel.setMethodCallHandler(this);

        new EventChannel(flutterEngine.getDartExecutor(), IdCloudPlugin.EVENT_CHANNEL_NAME).setStreamHandler(this);

        Object nfcService = activity.getSystemService(Context.NFC_SERVICE);
        if (nfcService instanceof NfcManager) {
            NfcManager nfcManager = (NfcManager) nfcService;
            _nfcAdapter = nfcManager.getDefaultAdapter();
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            activity.requestPermissions(
                    new String[]{Manifest.permission.NFC},
                    PERMISSION_NFC
            );
        }

        if (_nfcAdapter != null) {
            _nfcAdapter.enableReaderMode(activity, this, NfcAdapter.FLAG_READER_NFC_B, null);
        }
    }


    private byte[] Bitmap2PngBytes(Bitmap bm) {

        ByteArrayOutputStream baos = new ByteArrayOutputStream();

        bm.compress(Bitmap.CompressFormat.PNG, 100, baos);

        return baos.toByteArray();

    }

    private Map<String, Object> toFlutterMap(Map<String, Object> map) {
        if (map == null)
            return null;

        Map<String, Object> result = new HashMap<>();

        for (final Map.Entry<String, Object> entry : map.entrySet()) {
            if (entry.getValue() == null)
                continue;

            if (entry.getValue() instanceof ByteBuffer) {
                ByteBuffer buf = (ByteBuffer) entry.getValue();
                assert buf != null;
                byte[] arr = new byte[buf.remaining()];
                buf.get(arr);

                result.put(entry.getKey(), arr);
            }
        }

        map.putAll(result);

        return map;
    }

    private void sendNfcMessage(Map<String, Object> result) {
        Map<String, Object> msg = new HashMap<>();

        Map<String, Object> result1 = toFlutterMap(result);

        if (result1.containsKey("nfcError")) {
            msg.put("nfcError", result1.get("nfcError"));
            msg.put("nfcStatus", "error");
        } else {
            if (result1.containsKey("bmp")) {

                byte[] arr = (byte[]) result1.remove("bmp");

                assert arr != null;
                Log.i(TAG, "bmp size:" + arr.length);

                try {
                    //Log.i("bmp", Base64.encodeToString(arr, Base64.NO_WRAP));

                    Bitmap bm = BitmapFactory.decodeByteArray(arr, 0, arr.length);

                    arr = Bitmap2PngBytes(bm);

                    result1.put("png", arr);
                } catch (Exception e) {
                    Log.e(TAG, "bmp decode exception", e);
                }
            }


            msg.put("nfcContent", result1);
            msg.put("nfcStatus", "read");
        }

        if (_readResult != null) {
            _readResult.success(msg);
            _readResult = null;
        } else if (_eventChannel != null)
            _eventChannel.success(msg);
    }

    private void startReader(Tag tag) {

        _channel.invokeMethod("getAccessToken", HexUtil.bin2HexStr(tag.getId()), new MethodChannel.Result() {
            @Override
            public void success(Object accessToken) {
                _handler.post(() -> {
                    Map<String, Object> msg1 = new HashMap<>();

                    msg1.put("nfcId", HexUtil.bin2HexStr(tag.getId()));
                    msg1.put("nfcStatus", "reading");

                    Message message1 = _handler.obtainMessage(0, msg1);
                    _handler.sendMessage(message1);

                    _handler.post(() -> {
                        Map<String, Object> msg = new HashMap<>();
                        msg.put("tag", tag);
                        msg.put("accessToken", accessToken);

                        Message message = _handler.obtainMessage(1, msg);
                        _handler.sendMessage(message);
                    });
                });
            }

            @Override
            public void error(String s, String s1, Object o) {
                _handler.post(() -> {
                    Map<String, Object> msg = new HashMap<>();

                    //msg.put("nfcId",HexUtil.bin2HexStr(tag.getId()));
                    msg.put("nfcError", "获取令牌出错");
                    msg.put("nfcStatus", "error");

                    Message message = _handler.obtainMessage(0, msg);
                    _handler.sendMessage(message);
                });
            }

            @Override
            public void notImplemented() {
                _handler.post(() -> {
                    Map<String, Object> msg = new HashMap<>();

                    msg.put("nfcId", HexUtil.bin2HexStr(tag.getId()));
                    msg.put("nfcError", "请实现令牌获取方法");
                    msg.put("nfcStatus", "error");

                    Message message = _handler.obtainMessage(0, msg);
                    _handler.sendMessage(message);
                });
            }
        });
    }


    @Override
    public void onTagDiscovered(Tag tag) {
        if (_eventChannel == null)
            return;

        NfcB nfcB = NfcB.get(tag);
        if (nfcB == null) {
            Map<String, Object> msg = new HashMap<>();

            msg.put("nfcError", "卡类型错误");
            msg.put("nfcStatus", "error");

            Message message = _handler.obtainMessage(0, msg);
            _handler.sendMessage(message);
        } else {
            Message message = _handler.obtainMessage(2, tag);
            _handler.sendMessage(message);
        }


    }

    // EventChannel.StreamHandler methods
    @Override
    public void onListen(Object arguments, EventChannel.EventSink events) {
        _eventChannel = events;
    }

    @Override
    public void onCancel(Object arguments) {
        _eventChannel = null;
    }

    @Override
    public void onMethodCall(MethodCall call,MethodChannel.Result result) {
        if (_nfcAdapter == null || (!_nfcAdapter.isEnabled() && !Objects.equals(call.method, "NfcAvailable"))) {
            result.error("404", "NFC Hardware not found", null);

            return;
        }

        switch (call.method) {
            case "NfcInit": {
                List<String> subscribers = call.argument("subscribers");
                if (subscribers == null)
                    subscribers = new ArrayList<>();

                List<String> notifiers = call.argument("notifiers");
                if (notifiers == null)
                    notifiers = new ArrayList<>();

                boolean isOK = NfcInit(call.argument("netAddress"), call.argument("uid"), subscribers, notifiers);
                result.success(isOK);
                break;
            }
            case "NfcAvailable": {
                if (_nfcAdapter == null)
                    result.success("not_supported");
                else if (_nfcAdapter.isEnabled())
                    result.success("available");
                else
                    result.success("disabled");
                break;
            }
            case "NfcStop":
            case "NfcRead": {
                _readResult = null;
                break;
            }
            default:
                result.notImplemented();
                break;
        }
    }

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        _channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), IdCloudPlugin.METHOD_CHANNEL_NAME);
        _channel.setMethodCallHandler(this);

        new EventChannel(flutterPluginBinding.getBinaryMessenger(), IdCloudPlugin.EVENT_CHANNEL_NAME).setStreamHandler(this);


    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {

    }

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {

        Activity activity=binding.getActivity();

        Object nfcService = activity.getSystemService(Context.NFC_SERVICE);
        if (nfcService instanceof NfcManager) {
            NfcManager nfcManager = (NfcManager) nfcService;
            _nfcAdapter = nfcManager.getDefaultAdapter();
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            activity.requestPermissions(
                    new String[]{Manifest.permission.NFC},
                    PERMISSION_NFC
            );
        }

        if (_nfcAdapter != null) {
            _nfcAdapter.enableReaderMode(activity, this, NfcAdapter.FLAG_READER_NFC_B, null);
        }
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {

    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {

    }

    @Override
    public void onDetachedFromActivity() {

    }
}

