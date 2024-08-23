import Cocoa
import FlutterMacOS
import IOUSBHost
import IOKit
import IOKit.usb
import Foundation

public class FlutterThermalPrinterPlugin: NSObject, FlutterPlugin  , FlutterStreamHandler{
    
    private var eventSink: FlutterEventSink?
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events;
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_thermal_printer", binaryMessenger: registrar.messenger)
        let instance = FlutterThermalPrinterPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        let eventChannel =  FlutterEventChannel(name: "flutter_thermal_printer/events", binaryMessenger: registrar.messenger)
        eventChannel.setStreamHandler(instance)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformVersion":
            result("macOS " + ProcessInfo.processInfo.operatingSystemVersionString)
        case "getUsbDevicesList":
            result(getAllUsbDevice())
        case "connect":
            let args = call.arguments as? [String: Any]
            let vendorID = args?["vendorId"] as? String
            let productID = args?["productId"] as? String
            result(connectPrinter(vendorID: vendorID!, productID: productID!))
        case "printText":
            let args = call.arguments as? [String: Any]
            let vendorID = args?["vendorId"] as? String ?? "0"
            let productID = args?["productId"] as? String ?? "0"
            let data = args?["data"] as? Array<Int> ??  []
            let path = args?["path"] as? String ?? "asd"
            printData(vendorID: vendorID, productID: productID, data: data,path: path)
        case "isConnected":
            let args = call.arguments as? [String: Any]
            let vendorID = args?["vendorId"] as? String
            let productID = args?["productId"] as? String
            result(connectPrinter(vendorID: vendorID!, productID: productID!))
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    public func getAllUsbDevice() -> [[String:Any]]{
        var devices: [[String:Any]] = []
        var matchingDict = [String: AnyObject]()
        var iterator: io_iterator_t = 0
            // Create an IOServiceMatching dictionary to match all USB devices
        matchingDict[kIOProviderClassKey as String] = "IOUSBDevice" as AnyObject
        let result = IOServiceGetMatchingServices(kIOMasterPortDefault, matchingDict as CFDictionary, &iterator)
        
       if result != KERN_SUCCESS {
           print("Error: \(result)")
           return []
       }
        var device: io_object_t = IOIteratorNext(iterator)
        while device != 0 {
            var properties: Unmanaged<CFMutableDictionary>?
            let kr = IORegistryEntryCreateCFProperties(device, &properties, kCFAllocatorDefault, 0)
            if kr == KERN_SUCCESS, let properties = properties?.takeRetainedValue() as? [String: Any] {
             
                var deviceName = properties[kUSBHostDevicePropertyProductString]
                if deviceName == nil {
                    deviceName = properties[kUSBVendorString]
                }
                let vendorId = properties[kUSBVendorID]
                let productId = properties[kUSBProductID]
                let locationId = properties[kUSBDevicePropertyLocationID]
                let vendorName = properties[kUSBVendorName]
                let serialNo = properties[kUSBSerialNumberString]
                let usbDevice = USBDevice(id: locationId as! UInt64, vendorId: vendorId as! UInt16, productId: productId as! UInt16, name: deviceName as! String, locationId: locationId as! UInt32, vendorName: vendorName as? String, serialNr: serialNo as? String)
                devices.append(usbDevice.toDictionary())
            } else {
                print("Error getting properties for device: \(kr)")
            }
             
            IOObjectRelease(device)
            device = IOIteratorNext(iterator)
        }
        return devices
    }
         
    public func connectPrinter(vendorID: String, productID: String)-> Bool{
         return findPrinter(vendorId: Int(vendorID)!, productId: Int(productID)!) != nil
    }
    
    func findPrinter(vendorId: Int, productId: Int) -> io_service_t? {
        var iterator: io_iterator_t = 0

        // Create the matching dictionary
        guard let matchingDict = IOServiceMatching(kIOUSBDeviceClassName) as? NSMutableDictionary else {
            print("Error creating matching dictionary")
            return nil
        }
        
        // Set vendorId and productId in the matching dictionary
        matchingDict[kUSBVendorID as String] = NSNumber(value: vendorId)
        matchingDict[kUSBProductID as String] = NSNumber(value: productId)

        // Get the matching services
        let result = IOServiceGetMatchingServices(kIOMasterPortDefault, matchingDict, &iterator)
        
        if result != KERN_SUCCESS {
            print("Error: \(result)")
            return nil
        }
        
        // Get the first matching device
        let device = IOIteratorNext(iterator)
        IOObjectRelease(iterator)
        return device
    }

    func sendBytesToPrinter(vendorId: Int, productId: Int, data: Data) {
        guard let device = findPrinter(vendorId: vendorId, productId: productId) else {
            print("Printer not found")
            return
        }
        
        var plugInInterfacePtrPtr: UnsafeMutablePointer<UnsafeMutablePointer<IOCFPlugInInterface>?>? = UnsafeMutablePointer.allocate(capacity: 1)
        var score: Int32 = 0

        let result = IOCreatePlugInInterfaceForService(device,
                                                       kIOUSBDeviceUserClientTypeID,
                                                       kIOCFPlugInInterfaceID,
                                                       &plugInInterfacePtrPtr,
                                                       &score)
        
        if result != KERN_SUCCESS {
            print("Unable to create plugin interface: \(result)")
            plugInInterfacePtrPtr?.deallocate()
            return
        }else{
            print("Created interface: \(result)")
        }
//
//        // Safely unwrap the optional plug-in interface
//        guard let plugInInterface = plugInInterfacePtrPtr?.pointee?.pointee else {
//            print("Plugin interface is nil")
//            plugInInterfacePtrPtr?.deallocate()
//            return
//        }
//
//        var usbDeviceInterfacePtr: UnsafeMutablePointer<IOUSBDeviceInterface>? = nil
//        let iid = kIOUSBDeviceInterfaceID
//        
//        let result2 = withUnsafeMutablePointer(to: &usbDeviceInterfacePtr) {
//            $0.withMemoryRebound(to: UnsafeMutableRawPointer.self, capacity: 1) {
//                plugInInterface.QueryInterface($0,
//                                               CFUUIDGetUUIDBytes(iid),
//                                               $0)
//            }
//        }
//        
//        if result2 != KERN_SUCCESS {
//            print("Unable to query plugin interface: \(result2.debugDescription)")
//            plugInInterfacePtrPtr?.deallocate()
//            return
//        }
//        
//        guard let usbDeviceInterface = usbDeviceInterfacePtr else {
//            print("No USB device interface found")
//            plugInInterfacePtrPtr?.deallocate()
//            return
//        }
//
//        // Open the device
//        let kr = usbDeviceInterface.pointee.USBDeviceOpen(usbDeviceInterface)
//        if kr != KERN_SUCCESS {
//            print("Unable to open USB device: \(kr.debugDescription)")
//            usbDeviceInterface.pointee.USBDeviceClose(usbDeviceInterface)
//            plugInInterfacePtrPtr?.deallocate()
//            return
//        }
//
//        // Find the bulk output endpoint
//        var interfaceIterator: io_iterator_t = 0
//        let interfaceMatchingDict = IOServiceMatching(kIOUSBInterfaceClassName)
//        IOServiceGetMatchingServices(kIOMasterPortDefault, interfaceMatchingDict, &interfaceIterator)
//
//        var foundInterface: io_service_t = 0
//        while (foundInterface = IOIteratorNext(interfaceIterator)) != 0 {
//            var usbInterfaceInterfacePtrPtr: UnsafeMutablePointer<UnsafeMutablePointer<IOUSBInterfaceInterface>?>? = UnsafeMutablePointer.allocate(capacity: 1)
//            var localPlugInInterfacePtrPtr: UnsafeMutablePointer<UnsafeMutablePointer<IOCFPlugInInterface>?>? = UnsafeMutablePointer.allocate(capacity: 1)
//            IOCreatePlugInInterfaceForService(foundInterface,
//                                              kIOUSBInterfaceUserClientTypeID,
//                                              kIOCFPlugInInterfaceID,
//                                              &localPlugInInterfacePtrPtr,
//                                              &score)
//            
//            let plugInInterface = localPlugInInterfacePtrPtr?.pointee?.pointee
//            plugInInterface?.QueryInterface(localPlugInInterfacePtrPtr,
//                                            CFUUIDGetUUIDBytes(kIOUSBInterfaceInterfaceID),
//                                            &usbInterfaceInterfacePtrPtr)
//            
//            let usbInterfaceInterface = usbInterfaceInterfacePtrPtr?.pointee?.pointee
//            
//            // Open the interface
//            let kr = usbInterfaceInterface?.USBInterfaceOpen(usbInterfaceInterfacePtrPtr)
//            if kr == KERN_SUCCESS {
//                // Find the bulk output endpoint
//                var pipeRef: UInt8 = 0
//                var endpointDescriptor = IOUSBEndpointDescriptor()
//                
//                let result = usbInterfaceInterface?.GetPipeProperties(usbInterfaceInterfacePtrPtr, 1, &pipeRef, nil, nil, nil, &endpointDescriptor)
//                
//                if result == KERN_SUCCESS && (endpointDescriptor.bEndpointAddress & 0x80) == 0 { // Check if it's an output endpoint
//                    var bytesWritten = UInt32(data.count)
//                    let dataPtr = (data as NSData).bytes.bindMemory(to: UInt8.self, capacity: data.count)
//                    let writeResult = usbInterfaceInterface?.WritePipe(usbInterfaceInterfacePtrPtr, pipeRef, UnsafeMutablePointer(mutating: dataPtr), bytesWritten, 0)
//                    if writeResult == KERN_SUCCESS {
//                        print("Successfully sent data to printer")
//                    } else {
//                        print("Failed to send data to printer: \(writeResult.debugDescription)")
//                    }
//                    usbInterfaceInterface?.USBInterfaceClose(usbInterfaceInterfacePtrPtr)
//                    break
//                }
//                usbInterfaceInterface?.USBInterfaceClose(usbInterfaceInterfacePtrPtr)
//            }
//            IOObjectRelease(foundInterface)
//            usbInterfaceInterfacePtrPtr?.deallocate()
//            localPlugInInterfacePtrPtr?.deallocate()
//        }
//        IOObjectRelease(interfaceIterator)
//        usbDeviceInterface.pointee.USBDeviceClose(usbDeviceInterface)

        // Clean up
        plugInInterfacePtrPtr?.deallocate()
    }
     
    
    public func printData(vendorID: String, productID: String, data: Array<Int>, path: String){
        let dataArray = data.map { $0.byteSwapped }
        let data = Data(bytes: dataArray, count: dataArray.count)
        self.sendBytesToPrinter(vendorId: Int(vendorID)!, productId: Int(productID)!, data: data)
        
    }
}

public let kIOUSBDeviceUserClientTypeID = CFUUIDGetConstantUUIDWithBytes(nil, 0x9D, 0xA6, 0x9A, 0xAA, 0x2B, 0xD7, 0x11, 0xD4, 0xBA, 0xE8, 0x00, 0x60, 0x97, 0xB2, 0x1F, 0xF0)
public let kIOCFPlugInInterfaceID = CFUUIDGetConstantUUIDWithBytes(nil, 0xC2, 0x44, 0xE8, 0xE0, 0x54, 0xE6, 0x11, 0xD3, 0xA9, 0x1D, 0x00, 0xC0, 0x4F, 0xC2, 0x91, 0x63)
public let kIOUSBDeviceInterfaceID = CFUUIDGetConstantUUIDWithBytes(nil, 0x9d, 0xa6, 0x98, 0x08, 0x1d, 0xc4, 0x11, 0xd4, 0xba, 0xe8, 0x00, 0x04, 0x02, 0x75, 0x69, 0x65)
public let  kIOUSBInterfaceInterfaceID = CFUUIDGetConstantUUIDWithBytes(nil, 0x9d, 0xa6, 0x98, 0x08, 0x1d, 0xc4, 0x11, 0xd4, 0xba, 0xe8, 0x00, 0x04, 0x02, 0x75, 0x69, 0x65)
