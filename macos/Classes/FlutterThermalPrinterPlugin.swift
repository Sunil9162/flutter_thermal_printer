import Cocoa
import FlutterMacOS
import IOUSBHost
import IOKit
import IOKit.usb
import Foundation
import ORSSerial

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
    
//     public func deviceAdded(_ device: io_object_t) {
//             print("device added: \(device.name() ?? "<unknown>")")
//             if let usbDevice = device.getInfo() {
//                 print("usbDevice.getInfo(): \(usbDevice)")
//                 // Map usbDevice to a string and send it to the Flutter side
//                 let deviceDict = [
//                     "type" : "Added",
//                     "device": usbDevice.toDictionary()
//                 ] as [String : Any]
//                 if eventSink != nil {
//                     eventSink!(deviceDict)
//                 }
//             }else{
//                 print("usbDevice: no extra info")
//             }
//         }
//    
//     public func deviceRemoved(_ device: io_object_t) {
//             print("device removed: \(device.name() ?? "<unknown>")")
//             if let usbDevice = device.getInfo() {
//                 print("usbDevice.getInfo(): \(usbDevice)")
//                 // Map usbDevice to a dictionary and send it to the Flutter side
//                 let deviceDict = [
//                     "type" : "Removed",
//                     "device": usbDevice.toDictionary()
//                 ] as [String : Any]
//                 if eventSink != nil {
//                     eventSink!(deviceDict)
//                 }
//             }else{
//                 print("usbDevice: no extra info")
//             }
//         }
//     private var usbWatcher: USBWatcher!
//    
//     override init() {
//         super.init()
//         usbWatcher = USBWatcher(delegate: self)
//     }
// 
    
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
        var devices = Array<String>()
        let matchingDict = IOServiceMatching(kIOUSBDeviceClassName)
        let iter = UnsafeMutablePointer<io_iterator_t>.allocate(capacity: 1)
        let kr = IOServiceGetMatchingServices(kIOMasterPortDefault, matchingDict, iter)
        if kr != KERN_SUCCESS {
            print("Error getting services")
            result(devices)
        }
        while case let usbDevice = IOIteratorNext(iter.pointee), usbDevice != 0 {
            let bsdPath = getBSDPath(for: usbDevice)
            print(bsdPath as Any)
            let device = usbDevice.getInfo()
            var deviceInfo = device?.toDictionary()
            deviceInfo?["bsdPath"] = bsdPath
            devices.append(String(data: try! JSONSerialization.data(withJSONObject: deviceInfo as Any, options: .prettyPrinted), encoding: .utf8)!)
        }
        result(devices)
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
    
    public func getAllUsbDevice() -> Array<USBDevice>{
        var devices = Array<USBDevice>()
        let matchingDict = IOServiceMatching(kIOUSBDeviceClassName)
        let iter = UnsafeMutablePointer<io_iterator_t>.allocate(capacity: 1)
        let kr = IOServiceGetMatchingServices(kIOMasterPortDefault, matchingDict, iter)
        if kr != KERN_SUCCESS {
            print("Error getting services")
            return devices
        }    
        while case let usbDevice = IOIteratorNext(iter.pointee), usbDevice != 0 {
            devices.append(usbDevice.getInfo()!)
        }
        return devices
    }
    
    public func connectPrinter(vendorID: String, productID: String)-> Bool{
        let devices = getAllUsbDevice()
        for device in devices {
            if String(device.vendorId) == vendorID && String(device.productId) == productID {
                return true
            }
        }
        return false
    }
    
    
    func getBSDPath(for usbDevice: io_service_t) -> String? {
        guard let bsdNameAsCFString = IORegistryEntryCreateCFProperty(usbDevice, kIOBSDNameKey as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue()else {
            print("Unable to get BSD path for USB device.")
            return nil
        }
        let bsdPath = bsdNameAsCFString as? String
        print("BSD Path: \(String(describing: bsdPath))")
        return bsdPath
    }
    public func printData(vendorID: String, productID: String, data: Array<Int>, path: String){
                let serialPort = ORSSerialPort(path: path)
                serialPort?.baudRate = 9600
                serialPort?.open()
                var data = Data()
                for byte in data {
                    data.append(byte)
                }
                serialPort?.send(data as Data)
                return
 
    }
}
