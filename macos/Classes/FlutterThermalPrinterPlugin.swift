import Cocoa
import FlutterMacOS
import IOUSBHost
import IOKit
import IOKit.usb
import Foundation


public class FlutterThermalPrinterPlugin: NSObject, FlutterPlugin , USBWatcherDelegate{
    public func deviceAdded(_ device: io_object_t) {
            print("device added: \(device.name() ?? "<unknown>")")
            if let usbDevice = device.getInfo() {
                print("usbDevice.getInfo(): \(usbDevice)")
            }else{
                print("usbDevice: no extra info")
            }
        }
    
    public func deviceRemoved(_ device: io_object_t) {
            print("device removed: \(device.name() ?? "<unknown>")")
        }
    private var usbWatcher: USBWatcher!
    
    override init() {
        super.init()
        usbWatcher = USBWatcher(delegate: self)
    }
 
    
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_thermal_printer", binaryMessenger: registrar.messenger)
    let instance = FlutterThermalPrinterPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("macOS " + ProcessInfo.processInfo.operatingSystemVersionString)
    case "getUsbDevicesList":
        result(getAllUsbDevice())
    case "connectPrinter":
        let args = call.arguments as? [String: Any]
        let vendorID = args?["vendorId"] as? String
        let productID = args?["productId"] as? String
        result(connectPrinter(vendorID: vendorID!, productID: productID!))
    case "printText":
        let args = call.arguments as? [String: Any]
        printData(args)
        result("Printing Text")
    default:
      result(FlutterMethodNotImplemented)
    }
  }

    func findUSBDevice(vendorID: UInt16, productID: UInt16) -> io_service_t? {
        var matchingDict: NSMutableDictionary
        matchingDict = IOServiceMatching(kIOUSBDeviceClassName)

        matchingDict[kUSBVendorID] = vendorID
        matchingDict[kUSBProductID] = productID

        var iterator: io_iterator_t = 0
        let result = IOServiceGetMatchingServices(kIOMasterPortDefault, matchingDict, &iterator)

        guard result == KERN_SUCCESS else {
            return nil
        }

        return iterator
    }

    public func printData(_ args: [String: Any]?) { 
       let vendorID = args?["vendorId"] as? String
       let productID = args?["productId"] as? String
       let text = args?["text"] as? String
       let device = findUSBDevice(vendorID: UInt16(vendorID!)!, productID: UInt16(productID!)!)
       if device != nil {
           
           let usbDevice = IOIteratorNext(device!)
           guard usbDevice != 0 else {
               print("Failed to open USB device")
               return
           }
          
       }
    }
 
    
     

    public func connectPrinter(vendorID: String, productID: String) -> String {
        var printerName: String = ""
        let matchingDictionary = IOServiceMatching(kIOUSBDeviceClassName)
        var iterator: io_iterator_t = 0
        let kr = IOServiceGetMatchingServices(kIOMasterPortDefault, matchingDictionary, &iterator)
        if kr == kIOReturnSuccess {
            var usbDevice = IOIteratorNext(iterator)
            while usbDevice != 0 {
                let deviceVendorIDAsCFNumber = IORegistryEntrySearchCFProperty(usbDevice,
                                                                   kIOServicePlane,
                                                                   "idVendor" as CFString,
                                                                   kCFAllocatorDefault,
                                                                   IOOptionBits(kIORegistryIterateRecursively))
                if deviceVendorIDAsCFNumber != nil {
                    let deviceVendorID = deviceVendorIDAsCFNumber! as! Int
                    if deviceVendorID == Int(vendorID) {
                        let deviceProductIDAsCFNumber = IORegistryEntrySearchCFProperty(usbDevice,
                                                                   kIOServicePlane,
                                                                   "idProduct" as CFString,
                                                                   kCFAllocatorDefault,
                                                                   IOOptionBits(kIORegistryIterateRecursively))
                        if deviceProductIDAsCFNumber != nil {
                            let deviceProductID = deviceProductIDAsCFNumber! as! Int
                            if deviceProductID == Int(productID) {
                                printerName = getUsbDeviceName(usbDevice: usbDevice)
                                break
                            }
                        }
                    }
                }
                usbDevice = IOIteratorNext(iterator)
            }
            print("Printer Name: \(printerName) is Connected")
        } else {
            // Handle error
        }
        IOObjectRelease(iterator)
        return printerName
    }
    
    public func getAllUsbDevice() -> [[String: Any]]{
        var usbDevices: [[String: Any]] = []
        // Get All USB Devices connected to the system
        let matchingDictionary = IOServiceMatching(kIOUSBDeviceClassName)
        var iterator: io_iterator_t = 0
        let kr = IOServiceGetMatchingServices(kIOMasterPortDefault, matchingDictionary, &iterator)
        if kr == kIOReturnSuccess {
            var usbDevice = IOIteratorNext(iterator)
            while usbDevice != 0 {
                usbDevices.append(getDeviceDetails(usbDevice: usbDevice))
                usbDevice = IOIteratorNext(iterator)
            }
        } else {
            // Handle error
        }
        IOObjectRelease(iterator)
        return usbDevices
    }

    public func getUsbDeviceName(usbDevice: io_service_t) -> String {
        var deviceName: String = ""
        let deviceNameAsCFString = IORegistryEntrySearchCFProperty(usbDevice,
                                                                   kIOServicePlane,
                                                                   "USB Product Name" as CFString,
                                                                   kCFAllocatorDefault,
                                                                   IOOptionBits(kIORegistryIterateRecursively))
        if deviceNameAsCFString != nil {
            deviceName = deviceNameAsCFString! as! String
        }
        return deviceName
    }

    // Get Device Details
    public func getDeviceDetails(usbDevice: io_service_t) -> [String: Any] {
        var deviceDetails: [String: Any] = [:]
        var deviceName: String = ""
        var deviceVendorID: Int = 0
        var deviceProductID: Int = 0 

        let deviceNameAsCFString = IORegistryEntrySearchCFProperty(usbDevice,
                                                                   kIOServicePlane,
                                                                     "USB Product Name" as CFString,
                                                                   kCFAllocatorDefault,
                                                                   IOOptionBits(kIORegistryIterateRecursively))
        if deviceNameAsCFString != nil {
            deviceName = deviceNameAsCFString! as! String
        }
        
        let deviceVendorIDAsCFNumber = IORegistryEntrySearchCFProperty(usbDevice,
                                                                   kIOServicePlane,
                                                                   "idVendor" as CFString,
                                                                   kCFAllocatorDefault,
                                                                   IOOptionBits(kIORegistryIterateRecursively))
        if deviceVendorIDAsCFNumber != nil {
            deviceVendorID = deviceVendorIDAsCFNumber! as! Int
        }

        let deviceProductIDAsCFNumber = IORegistryEntrySearchCFProperty(usbDevice,
                                                                   kIOServicePlane,
                                                                   "idProduct" as CFString,
                                                                   kCFAllocatorDefault,
                                                                   IOOptionBits(kIORegistryIterateRecursively))
        if deviceProductIDAsCFNumber != nil {
            deviceProductID = deviceProductIDAsCFNumber! as! Int
        }

        deviceDetails["name"] = deviceName
        deviceDetails["vendorID"] = deviceVendorID
        deviceDetails["productID"] = deviceProductID
        return deviceDetails
    }
    
}
