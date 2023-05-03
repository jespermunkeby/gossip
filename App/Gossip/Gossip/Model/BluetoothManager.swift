import Foundation
import CoreBluetooth

let serviceUUID = CBUUID(string: "E20A39F4-73F5-4BC4-A12F-17D1AD07A961")
let characteristicUUID = CBUUID(string: "08590F7E-DB05-467E-8757-72F6FAEB13D4")
let messageInterval: TimeInterval = 1

/*
//OLD STUFF, might come in handy if down the line
// Operations for concurrency
class PeripheralCycleOperation: Operation {
    let cycleTime: TimeInterval
    let peripheralManager: CBPeripheralManager
    let characteristic: CBMutableCharacteristic
    
    let messageTime: TimeInterval = 1
    
    var cycleSchedule: Timer!
    var messageSchedule: Timer!
    
    init(peripheralManager: CBPeripheralManager, cycleTime: TimeInterval, characteristic: CBMutableCharacteristic){
        self.cycleTime = cycleTime
        self.peripheralManager = peripheralManager
        self.characteristic = characteristic
    }
    
    override func main() {
        cycleSchedule = Timer.scheduledTimer(
            timeInterval: cycleTime,
            target: self,
            selector: #selector(self.finish),
            userInfo: nil,
            repeats: false
        )
        
        messageSchedule = Timer.scheduledTimer(
            timeInterval: messageTime,
            target: self,
            selector: #selector(self.changeCharacteristic),
            userInfo: nil,
            repeats: true
        )
        
        //TODO: maybe wait for these to end or someting to get them to run as operations concurrently??
        //I think they are cleaned up when main reaches its end..
    }
    
    @objc func finish(){
        messageSchedule.invalidate()
        cycleSchedule.invalidate()
        print("finished peripheral operation")
    }
    
    @objc func changeCharacteristic(){
        //TODO: Take from shared data
        peripheralManager.updateValue("hello\(Int.random(in: 1..<100))".data(using: .utf8)!, for: characteristic, onSubscribedCentrals: nil)
        print("changed characteristic")
    }
    
}

class CentralCycleOperation: Operation{
    let cycleTime: TimeInterval
    let centralManager: CBCentralManager
    
    var cycleSchedule: Timer!
    var done = false
    
    init(centralManager: CBCentralManager, cycleTime: TimeInterval){
        self.cycleTime = cycleTime
        self.centralManager = centralManager
    }
    
    override func main() {
        cycleSchedule = Timer.scheduledTimer(
            timeInterval: cycleTime,
            target: self,
            selector: #selector(self.finish),
            userInfo: nil,
            repeats: false
        )
        
        //connect
        centralManager.scanForPeripherals(withServices: [serviceUUID],
                                           options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]) //??
        let peripherals = centralManager.retrieveConnectedPeripherals(withServices: [serviceUUID])
        if peripherals == []{return}
        let peripheral = peripherals.randomElement()
        centralManager.connect(peripheral!, options: nil) //TODO: handle fail
        
        //
        
    }
    
    @objc func finish(){
        
        done = true
    }
}
*/

//Singleton class to manage bluetooth stuff
class BluetoothManager: NSObject, ObservableObject {
    // singleton pattern
    // makes this object accessible at BluetoothManager.shared
    static let shared = BluetoothManager()
    
    //managers
    private var centralManager: CBCentralManager!
    private var peripheralManager: CBPeripheralManager!
    private var targetPeripheral: CBPeripheral!
    private var peripheralCharacteristic: CBMutableCharacteristic!
    
    //Peripheral scedulers
    var cycleSchedule: Timer!
    var messageSchedule: Timer!
    var scanSchedule: Timer!
    @Published private(set) var sharedData: Set<Data> = ["3".data(using: .utf8)!, "4".data(using: .utf8)!]
    @Published private(set) var initialized = false
    
    
    //override the init of NSObject
    private override init() {
        //init NSObject
        super.init()
        //init managers
        centralManager = CBCentralManager(delegate: self, queue: nil)
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    private func initPeripheral() {
        // Create a service with characteristic.
        let service = CBMutableService(type: serviceUUID, primary: true)
        
        peripheralCharacteristic = CBMutableCharacteristic(
            type: characteristicUUID,
            properties: [.notify],
            value: nil,
            permissions: [.readable]
        )
        
        service.characteristics = [peripheralCharacteristic]
        
        // add service
        peripheralManager.add(service)
        peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [serviceUUID]])
    }
    
    private func startCentral(scanDuration: TimeInterval){
        centralManager.scanForPeripherals(withServices: [serviceUUID], options: nil)
        // if scanSchedule != nil {scanSchedule.invalidate()} ????
        scanSchedule = Timer.scheduledTimer(withTimeInterval: scanDuration, repeats: false) { _ in
            if self.targetPeripheral == nil {
                print("Target peripheral not found. Starting another scan.")
                self.centralManager.stopScan()
                self.startCentral(scanDuration: scanDuration)
            }
        }
    }

    private func stopCentral(){
        if targetPeripheral != nil{
            centralManager.cancelPeripheralConnection(targetPeripheral)
        }
    }
}

extension BluetoothManager {
    func cycle(scanDuration: TimeInterval, messageInterval: TimeInterval, cycleDuration: TimeInterval){
        //central
        startCentral(scanDuration: scanDuration)
        
        //peripheral
        cycleSchedule = Timer.scheduledTimer(
            timeInterval: cycleDuration,
            target: self,
            selector: #selector(self.finish),
            userInfo: nil,
            repeats: false
        )
        
        messageSchedule = Timer.scheduledTimer(
            timeInterval: messageInterval,
            target: self,
            selector: #selector(self.changeCharacteristic),
            userInfo: nil,
            repeats: true
        )
    }
    
    @objc private func finish(){
        cycleSchedule.invalidate()
        messageSchedule.invalidate()
        if scanSchedule != nil {scanSchedule.invalidate()}
        stopCentral()
        print("cycle complete")
    }
    
    @objc private func changeCharacteristic(){
        //TODO: Not random elem, handle empty
        peripheralManager.updateValue(sharedData.randomElement()!, for: peripheralCharacteristic, onSubscribedCentrals: nil)
        
        print("changed characteristic")
    }
}

//TODO: Maybe this is the way to do peripheral too??
extension BluetoothManager: CBCentralManagerDelegate {
    //Scan for devices when the central manager is powered on:
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            print("Central Manager powered on")
            startCentral(scanDuration: 10)
        } else {
            print("Central Manager powered off")
        }
    }
    
    //When a peripheral is discovered, stop scanning, store a reference to it, and connect
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        // Check the RSSI value of the discovered peripheral
        let rssiThreshold: NSNumber = -70 // set your desired threshold value here
        if RSSI.intValue > rssiThreshold.intValue {
            // Connect to the peripheral if its RSSI value is greater than the threshold
            targetPeripheral = peripheral
            centralManager.stopScan()
            centralManager.connect(peripheral, options: nil)
        } else {
            // Otherwise, continue scanning for other peripherals
            print("Peripheral with weak signal ignored: \(peripheral)")
        }
    }


    
    //When the peripheral is connected, set its delegate and discover services
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices([serviceUUID])
    }
    
    //When the service is discovered, discover the target characteristic
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for service in services {
                if service.uuid == serviceUUID {
                    peripheral.discoverCharacteristics([characteristicUUID], for: service)
                }
            }
        }
    }
    
    //When the characteristic is discovered, subscribe to its value updates
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                if characteristic.uuid == characteristicUUID {
                    peripheral.setNotifyValue(true, for: characteristic)
                }
            }
        }
    }
    
    //Handle updates to the characteristic value
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic.uuid == characteristicUUID {
            if let data = characteristic.value {
                sharedData.insert(data)
                print(data)
            }
        }
    }
}

extension BluetoothManager: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state == .poweredOn {
            print("Peripheral Manager powered on")
            initPeripheral()
            initialized = true
            print("Peripheral initialization complete")
        } else {
            print("Peripheral Manager powered off")
        }
    }
}

extension BluetoothManager: CBPeripheralDelegate{
    
}
