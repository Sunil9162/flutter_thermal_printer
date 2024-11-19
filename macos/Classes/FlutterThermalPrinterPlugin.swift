import Cocoa
import FlutterMacOS
import IOUSBHost
import IOKit
import IOKit.usb
import IOKit.usb.IOUSBLib
import Foundation
import CoreFoundation

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
        guard let matchingDict = IOServiceMatching(kIOUSBDeviceClassName) else {
            print("Error creating matching dictionary")
            return nil
        }

        // Set vendorId and productId in the matching dictionary
        let vendorIdNumber = NSNumber(value: vendorId)
        let productIdNumber = NSNumber(value: productId)

        // Set the Vendor ID in the dictionary
        CFDictionarySetValue(matchingDict, Unmanaged.passUnretained(kUSBVendorID as CFString).toOpaque(), Unmanaged.passUnretained(vendorIdNumber).toOpaque())

        // Set the Product ID in the dictionary
        CFDictionarySetValue(matchingDict, Unmanaged.passUnretained(kUSBProductID as CFString).toOpaque(), Unmanaged.passUnretained(productIdNumber).toOpaque())

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
//        // Create the matching dictionary
//        var matchingDict: CFMutableDictionary?
//        let dict = IOServiceMatching(kIOUserServicePropertiesKey as String)
//        
//        // Ensure the matching dictionary is not nil
//        guard let dictUnwrapped = dict else {
//            print("Unable to create matching dictionary.")
//            return
//        }
//        
//        matchingDict = CFDictionaryCreateMutableCopy(kCFAllocatorDefault, 0, dictUnwrapped)
//        
//        // Set the vendor and product IDs
//        let vendorIdNumber = NSNumber(value: vendorId)
//        let productIdNumber = NSNumber(value: productId)
//        
//        // Set the Vendor ID in the dictionary
//        CFDictionarySetValue(matchingDict, Unmanaged.passUnretained(kUSBVendorID as CFString).toOpaque(), Unmanaged.passUnretained(vendorIdNumber).toOpaque())
//
//        // Set the Product ID in the dictionary
//        CFDictionarySetValue(matchingDict, Unmanaged.passUnretained(kUSBProductID as CFString).toOpaque(), Unmanaged.passUnretained(productIdNumber).toOpaque())
//        
//
//        var iterator: io_iterator_t = 0
//            let result = IOServiceGetMatchingServices(kIOMasterPortDefault, matchingDict!, &iterator)
//
//        if result == KERN_SUCCESS {
//                var service: io_object_t = 0
//                while service != 0 {
//                    service = IOIteratorNext(iterator)
//                    
//                    var usbDevice: io_object_t = service
//                    var usbInterface: io_object_t = 0
//                    // Open the USB device interface
//                    let openResult = IOUSBDeviceInterfaceOpen(usbDevice, &usbInterface)
//                    
//                    if openResult == KERN_SUCCESS {
//                        // Send data to the printer
//                        let bytesWritten = IOUSBDeviceWrite(usbInterface, 0, data.count, data.bytes.bindMemory(to: UInt8.self, capacity: data.count))
//                        
//                        if bytesWritten < 0 {
//                            print("Error writing to USB printer: \(bytesWritten)")
//                        }
//                        
//                        // Close the USB device interface
//                        IOUSBDeviceClose(usbInterface)
//                    } else {
//                        print("Error opening USB device")
//                    }
//                    
//                    // Release the USB device
//                    IOObjectRelease(usbDevice)
//                }
//                
//                // Release the iterator
//                IOObjectRelease(iterator)
//            } else {
//                print("No USB printer found with the specified vendor and product ID.")
//            }
        let matchingDict = IOServiceMatching(kIOUSBDeviceClassName)
            var iterator: io_iterator_t = 0
            let kr = IOServiceGetMatchingServices(kIOMasterPortDefault, matchingDict, &iterator)

            if kr == KERN_SUCCESS {
                var service: io_object_t = IOIteratorNext(iterator)
                while service != 0 {
                    var vendorIdNumber: NSNumber?
                    var productIdNumber: NSNumber?

                    var properties: Unmanaged<CFMutableDictionary>?
                    let result = IORegistryEntryCreateCFProperties(service, &properties, kCFAllocatorDefault, 0)

                    if result == KERN_SUCCESS, let cfProperties = properties?.takeRetainedValue() as? [String: Any] {
                        vendorIdNumber = cfProperties[kUSBVendorID as String] as? NSNumber
                        productIdNumber = cfProperties[kUSBProductID as String] as? NSNumber
                    }

                    if let vendor = vendorIdNumber, let product = productIdNumber,
                       vendor.intValue == vendorId, product.intValue == productId {
                        print("USB printer found with Vendor ID: \(vendorId), Product ID: \(productId)")
                        
                        // Write data to USB printer
                        writeToUSBPrinter(service, data: data)
                    }

                    // Release the current service and move to the next one
                    IOObjectRelease(service)
                    service = IOIteratorNext(iterator)
                }
                
                // Release the iterator when done
                IOObjectRelease(iterator)
            } else {
                print("No USB printer found with the specified vendor and product ID.")
            }
    }
    
    func openUSBDevice(service: io_service_t) -> io_connect_t? {
        var usbDeviceConnection: io_connect_t = 0
        let kr = IOServiceOpen(service, mach_task_self_, 0, &usbDeviceConnection)

        if kr != KERN_SUCCESS {
            print("Unable to open USB device: \(kr)")
            return nil
        }

        return usbDeviceConnection
    }

    func closeUSBDevice(deviceConnection: io_connect_t) {
        IOServiceClose(deviceConnection)
    }

    func writeDataToUSBInterface(interface: UnsafeMutablePointer<IOUSBInterfaceInterface>, data: Data) -> kern_return_t {
        var pipeRef: UInt8 = 1 // Assume pipe 1 is for bulk transfer; this may differ for your device
        var kr: kern_return_t = KERN_SUCCESS

        // Use `withUnsafeBytes` to work with the raw data buffer
        data.withUnsafeBytes { (buffer: UnsafeRawBufferPointer) in
            let ptr = buffer.baseAddress!.assumingMemoryBound(to: UInt8.self) // Get a typed pointer to UInt8
            let numBytesToSend = UInt32(buffer.count)
            
            // Cast to `UnsafeMutableRawPointer?` as required by `WritePipe`
            kr = interface.pointee.WritePipe(interface, pipeRef, UnsafeMutableRawPointer(mutating: ptr), numBytesToSend)
            
            if kr != KERN_SUCCESS {
                print("Error writing to USB interface: \(kr)")
            } else {
                print("Successfully wrote \(numBytesToSend) bytes to USB device.")
            }
        }

        return kr
    }

    func writeToUSBPrinter(_ service: io_service_t, data: Data) {
        guard let usbDevice = openUSBDevice(service: service) else {
            print("Error opening USB device")
            return
        }

        // Find the interface
//        var iterator: io_iterator_t = 0
//        let kr = IOUsbDeviceMatching(usbDevice, &iterator)
//        
//        if kr != KERN_SUCCESS {
//            print("Error finding USB interfaces: \(kr)")
//            closeUSBDevice(deviceConnection: usbDevice)
//            return
//        }
//
//        var interface: io_service_t
//        while (interface = IOIteratorNext(iterator)) != 0 {
//            var pluginInterface: UnsafeMutablePointer<IOCFPlugInInterface>? = nil
//            var interfacePtr: UnsafeMutablePointer<UnsafeMutablePointer<IOUSBInterfaceInterface>?>? = nil
//            let result = IOCreatePlugInInterfaceForService(interface, kIOUSBInterfaceUserClientTypeID, kIOCFPlugInInterfaceID, &pluginInterface, nil)
//
//            if result == KERN_SUCCESS, let plugin = pluginInterface {
//                let queryResult = plugin.pointee.pointee.QueryInterface(plugin, CFUUIDGetUUIDBytes(kIOUSBInterfaceInterfaceID), UnsafeMutablePointer(&interfacePtr))
//                
//                if queryResult == KERN_SUCCESS, let usbInterface = interfacePtr?.pointee {
//                    let openResult = usbInterface.pointee.Open(usbInterface)
//
//                    if openResult == KERN_SUCCESS {
//                        print("Opened USB interface successfully")
//                        
//                        // Write data to USB
//                        let writeResult = writeDataToUSBInterface(interface: usbInterface.pointee, data: data)
//                        
//                        if writeResult != KERN_SUCCESS {
//                            print("Error writing data to USB device")
//                        }
//                        
//                        // Close the interface
//                        usbInterface.pointee.Close(usbInterface)
//                    } else {
//                        print("Failed to open USB interface")
//                    }
//                }
//            }
//
//            // Release resources
//            IOObjectRelease(interface)
//        }
//
//        // Release the iterator and close the USB device connection
//        IOObjectRelease(iterator)
//        closeUSBDevice(deviceConnection: usbDevice)
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
