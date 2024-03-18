package com.example.flutter_thermal_printer;

import static android.content.Context.USB_SERVICE;

import android.annotation.SuppressLint;
import android.annotation.TargetApi;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.hardware.usb.UsbConstants;
import android.hardware.usb.UsbDevice;
import android.hardware.usb.UsbDeviceConnection;
import android.hardware.usb.UsbEndpoint;
import android.hardware.usb.UsbManager;
import android.os.Build;

import java.security.Permission;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CompletableFuture;

import android.content.BroadcastReceiver;
import android.content.IntentFilter;
import android.util.Log;
import io.flutter.plugin.common.EventChannel; 
public class UsbPrinter implements EventChannel.StreamHandler{
    @SuppressLint("StaticFieldLeak")
    private static Context context;

    private static final String ACTION_USB_PERMISSION = "com.android.example.USB_PERMISSION";
    private static final String ACTION_USB_ATTACHED = "android.hardware.usb.action.USB_DEVICE_ATTACHED";
    private static final String ACTION_USB_DETACHED = "android.hardware.usb.action.USB_DEVICE_DETACHED";
    private static final String TAG = "FlutterThermalPrinterPlugin";
    private   EventChannel.EventSink events;

    private BroadcastReceiver createUsbStateChangeReceiver(final EventChannel.EventSink events) {
        return new BroadcastReceiver() {
          @Override
          public void onReceive(Context context, Intent intent) {
            if (intent.getAction().equals(ACTION_USB_ATTACHED)) {
              UsbDevice device = (UsbDevice) intent.getParcelableExtra(UsbManager.EXTRA_DEVICE);
              Log.d(TAG, "ACTION_USB_ATTACHED");
              if (events != null) {  
                events.success("USB_ATTACHED: " + device.getDeviceName() + " " + device.getProductName() + " " + device.getVendorId() + " " + device.getProductId());
              }
            } else if (intent.getAction().equals(ACTION_USB_DETACHED)) {
              UsbDevice device = (UsbDevice) intent.getParcelableExtra(UsbManager.EXTRA_DEVICE);
              Log.d(TAG, "ACTION_USB_DETACHED");
              if (events != null) {
                events.success("USB_DETACHED: " + device.getDeviceName() + " " + device.getProductName() + " " + device.getVendorId() + " " + device.getProductId());
              }
            }
          }
        };
    }
 

    @Override
    public void onListen(Object arguments, EventChannel.EventSink events) {
        this.events = events;
        IntentFilter filter = new IntentFilter();
        filter.addAction(ACTION_USB_ATTACHED);
        filter.addAction(ACTION_USB_DETACHED);
        context.registerReceiver(createUsbStateChangeReceiver(events), filter);
    }

    @Override
    public void onCancel(Object arguments) {
        context.unregisterReceiver(createUsbStateChangeReceiver(events)); 
    } 

 


    private static PendingIntent mPermissionIntent;
    UsbPrinter(Context context) {
        UsbPrinter.context = context;
        mPermissionIntent =
                PendingIntent.getActivity(context, 0, new Intent("com.example.flutter_thermal_printer.USB_PERMISSION"), PendingIntent.FLAG_IMMUTABLE
                );
    }

    private List<Map<String, String>> usbDevicesList;
    Permission permission;

    public    List<Map<String, String>> getUsbDevicesList() {
        UsbManager m = (UsbManager)context.getSystemService(USB_SERVICE);
        HashMap<String, UsbDevice> usbDevices = m.getDeviceList();
        List<Map<String, String>> data = new ArrayList<Map<String, String>>();
        for (Map.Entry<String, UsbDevice> entry : usbDevices.entrySet()) {
            UsbDevice device = entry.getValue();
            HashMap<String, String> deviceData = new HashMap<String, String>();
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                deviceData.put("name", device.getProductName());
            }
            deviceData.put("vendorId", String.valueOf(device.getVendorId()));
            deviceData.put("productId", String.valueOf(device.getProductId()));
            data.add(deviceData);
        }
        return data;
    }

//    Connect using VendorId and ProductId
    public    boolean connect(String vendorId, String productId){
        UsbManager m = (UsbManager)context.getSystemService(USB_SERVICE);
        HashMap<String, UsbDevice> usbDevices = m.getDeviceList();
        UsbDevice device = null;
        for (Map.Entry<String, UsbDevice> entry : usbDevices.entrySet()) {
            if (String.valueOf(entry.getValue().getVendorId()).equals(vendorId) && String.valueOf(entry.getValue().getProductId()).equals(productId)){
                device = entry.getValue();
                break;
            }
        }
        if (device == null){
            return false;
        }
        if (!m.hasPermission(device)){
            m.requestPermission(device,mPermissionIntent);
        }
        return m.hasPermission(device);
    }

//    Print text on the printer
    public   void printText(String vendorId, String productId, List<Integer> bytes){
      UsbManager m = (UsbManager)context.getSystemService(USB_SERVICE);
        HashMap<String, UsbDevice> usbDevices = m.getDeviceList();
        UsbDevice device = null;
        for (Map.Entry<String, UsbDevice> entry : usbDevices.entrySet()) {
            if (String.valueOf(entry.getValue().getVendorId()).equals(vendorId) && String.valueOf(entry.getValue().getProductId()).equals(productId)){
                device = entry.getValue();
                break;
            }
        }
        if (device == null){
            return;
        }
        if (!m.hasPermission(device)){
            m.requestPermission(device,mPermissionIntent);
        }
        if (!m.hasPermission(device)){
            return;
        }
        UsbDeviceConnection connection = m.openDevice(device);

        if (connection == null){
            return;
        } 
        connection.claimInterface(device.getInterface(0), true);
        UsbEndpoint mBulkEndOut = null;
        for (int i = 0; i < device.getInterface(0).getEndpointCount(); i++) {
            if (device.getInterface(0).getEndpoint(i).getType() == UsbConstants.USB_ENDPOINT_XFER_BULK && device.getInterface(0).getEndpoint(i).getDirection() == UsbConstants.USB_DIR_OUT) {
                mBulkEndOut = device.getInterface(0).getEndpoint(i);
                break;
            }
        }
        byte[] data = new byte[bytes.size()];
        for (int i = 0; i < bytes.size(); i++) {
            data[i] = bytes.get(i).byteValue();
        }
        connection.bulkTransfer(mBulkEndOut, data, data.length, 5000);
        connection.releaseInterface(device.getInterface(0));
        connection.close();
    }

    public boolean isConnected(String vendorId, String productId){
        UsbManager m = (UsbManager)context.getSystemService(USB_SERVICE);
        HashMap<String, UsbDevice> usbDevices = m.getDeviceList();
        UsbDevice device = null;
        for (Map.Entry<String, UsbDevice> entry : usbDevices.entrySet()) {
            if (String.valueOf(entry.getValue().getVendorId()).equals(vendorId) && String.valueOf(entry.getValue().getProductId()).equals(productId)){
                device = entry.getValue();
                break;
            }
        }
        if (device == null){
            return false;
        } 
        return m.hasPermission(device);
    }

    // Convert image bytes to esc/pos command
    @TargetApi(Build.VERSION_CODES.O)
    public List<Integer> convertimage(List<Integer> bytes){
        return bytes;
    }

    public boolean disconnect(String vendorId, String productId){
        UsbManager m = (UsbManager)context.getSystemService(USB_SERVICE);
        HashMap<String, UsbDevice> usbDevices = m.getDeviceList();
        UsbDevice device = null;
        for (Map.Entry<String, UsbDevice> entry : usbDevices.entrySet()) {
            if (String.valueOf(entry.getValue().getVendorId()).equals(vendorId) && String.valueOf(entry.getValue().getProductId()).equals(productId)){
                device = entry.getValue();
                break;
            }
        }
        if (device == null){
            return false;
        }
        boolean hasPermission = m.hasPermission(device);
        if(!hasPermission){
            return false;
        }
        //  Release the interface
        UsbDeviceConnection connection = m.openDevice(device); 
        connection.releaseInterface(device.getInterface(0));
        connection.close(); 
        return true;
    }
}
