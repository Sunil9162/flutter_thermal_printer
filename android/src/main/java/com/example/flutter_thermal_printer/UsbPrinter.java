package com.example.flutter_thermal_printer;

import static android.content.Context.USB_SERVICE;
import android.content.Context;
import android.hardware.usb.UsbDevice;
import android.hardware.usb.UsbManager;
import android.os.Build;
import android.util.Log;

import java.lang.reflect.Array;
import java.security.Permission;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class UsbPrinter {

    private UsbPrinter() {
        // Private constructor to prevent instantiation
    }

    private List<Map<String, String>> usbDevicesList;
    Permission permission;

    public static HashMap<String, Object> getUsbDevicesList(Context context) {
        UsbManager m = (UsbManager)context.getSystemService(USB_SERVICE);
        HashMap<String, UsbDevice> usbDevices = m.getDeviceList();
        Log.d("USB", "getUsbDevicesList: " + usbDevices);
        HashMap<String, Object>  data =   new HashMap<String, Object>();
        for (Map.Entry<String, UsbDevice> entry : usbDevices.entrySet()) {
            UsbDevice device = entry.getValue();
            if (m.hasPermission(device)) {
                Log.d("USB", "getUsbDevicesList: " + device.getDeviceName());
            } else {
                m.requestPermission(device, null);
            }
            HashMap<String, String> deviceData = new HashMap<String, String>();
            deviceData.put("name", device.getDeviceName());
            deviceData.put("vendorId", String.valueOf(device.getVendorId()));
            deviceData.put("productId", String.valueOf(device.getProductId()));
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                deviceData.put("serialNumber", device.getSerialNumber());
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                deviceData.put("manufacturerName", device.getManufacturerName());
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                deviceData.put("productName", device.getProductName());
            }
            deviceData.put("deviceClass", String.valueOf(device.getDeviceClass()));
            deviceData.put("deviceSubclass", String.valueOf(device.getDeviceSubclass()));
            deviceData.put("deviceProtocol", String.valueOf(device.getDeviceProtocol()));
            deviceData.put("interfaceCount", String.valueOf(device.getInterfaceCount()));
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                deviceData.put("configurationCount", String.valueOf(device.getConfigurationCount()));
            }
            data.put(device.getDeviceName(), deviceData);
        }
        return data;
    }
}
