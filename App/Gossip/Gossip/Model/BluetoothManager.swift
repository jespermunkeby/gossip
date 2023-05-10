import CryptoKit
import Foundation
import CoreBluetooth
import CoreData
import UIKit
import SwiftUI

let serviceUUID = CBUUID(string: "E20A39F4-73F5-4BC4-A12F-17D1AD07A961")
let characteristicUUID = CBUUID(string: "08590F7E-DB05-467E-8757-72F6FAEB13D4")

//TODO: try these out
let messageInterval: TimeInterval = 1
let cycleDuration: TimeInterval = 15
let maxRandomDurationDeviation: TimeInterval = 5


//TODO: refactor to model with both these?
class CoreDataHandler {
    private let persistentContainer: NSPersistentContainer
    
    init(persistentContainer: NSPersistentContainer) {
        self.persistentContainer = persistentContainer
    }
    
    func fetchMessages() -> [MessageModel] {
        let fetchRequest: NSFetchRequest<MessageModel> = MessageModel.fetchRequest()
        
        do {
            let messages = try persistentContainer.viewContext.fetch(fetchRequest)
            return messages
        } catch {
            print("Error fetching messages: \(error)")
            return []
        }
    }
}


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
    
    private var coreDataViewModel: CoreDataViewModel!
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private let encryptionKey = SymmetricKey(size: .bits256) // Example key, you should securely generate and store your key
    
    private var savedMessages : Set<Message> = []
    
    //Peripheral scedulers
    var cycleSchedule: Timer!
    var messageSchedule: Timer!
    @Published private(set) var messages: Set<Message> = []
    @Published private(set) var initialized_peripheral = false
    @Published private(set) var initialized_central = false

    //override the init of NSObject
    private override init() {
        //init NSObject
        super.init()
        //init managers
        centralManager = CBCentralManager(delegate: self, queue: nil)
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        
        coreDataViewModel = CoreDataViewModel()
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
    
    // startBackgroundTask method
    private func startBackgroundTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask {
            self.endBackgroundTask()
        }
    }

    // endBackgroundTask method
    private func endBackgroundTask() {
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid
    }
}

extension BluetoothManager {
    func cycle(){
        startBackgroundTask()
        //TODO: do saved message loading in a more energy efficient way
        savedMessages = Set(coreDataViewModel.fetchMessages().enumerated().map {_,message in
            return Message(messageModel: message)
        })
        
        print("starting new cycle...")
        //scan
        centralManager.scanForPeripherals(withServices: [serviceUUID], options: nil)
        
        //peripheral
        cycleSchedule = Timer.scheduledTimer(
            timeInterval: cycleDuration + TimeInterval.random(in: (-maxRandomDurationDeviation...maxRandomDurationDeviation) ),
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

        if targetPeripheral != nil{
            centralManager.cancelPeripheralConnection(targetPeripheral)
            targetPeripheral = nil
        }
        
        if centralManager.isScanning {
            centralManager.stopScan()
        }
        print("cycle finished")
        endBackgroundTask()
        cycle()
    }
    
    @objc private func changeCharacteristic() {
        //TODO: Not random elem, handle empty
        let set = messages.union(savedMessages)
        if (set.count != 0) {
            let message = set.randomElement()!
            if let messageContentString = String(data: message.content, encoding: .utf8),
               let encryptedMessageData = try? EncryptionManager.encrypt(key: encryptionKey, plaintext: messageContentString) {
                peripheralManager.updateValue(encryptedMessageData, for: peripheralCharacteristic, onSubscribedCentrals: nil)
                print("Changed characteristic")
            }
        }
    }
}

//TODO: Maybe this is the way to do peripheral too??
extension BluetoothManager: CBCentralManagerDelegate {
    //Scan for devices when the central manager is powered on:
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            print("Central Manager powered on")
            initialized_central = true
        } else {
            print("Central Manager powered off")
        }
    }
    
    //When a peripheral is discovered, stop scanning, store a reference to it, and connect
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        
        print("Discovered peripheral:")
                print("Name: \(peripheral.name ?? "Unknown")")
                print("Identifier (UUID): \(peripheral.identifier)")
                print("Advertisement data: \(advertisementData)")
                print("RSSI: \(RSSI)")
        
        targetPeripheral = peripheral
        centralManager.stopScan()
        centralManager.connect(peripheral, options: nil)
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
            if let encryptedData = characteristic.value {
                if let decryptedDataString = try? EncryptionManager.decrypt(key: encryptionKey, encryptedData: encryptedData),
                   let decryptedData = decryptedDataString.data(using: .utf8) {
                    let message = Message(data: decryptedData)
                    if !savedMessages.contains(message) && !messages.contains(message) {
                        messages.insert(message)
                    }
                    print("Received message: \(decryptedDataString)")
                }
            }
        }
    }
}

extension BluetoothManager: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state == .poweredOn {
            print("Peripheral Manager powered on")
            initPeripheral()
            initialized_peripheral = true
            print("Peripheral initialization complete")
        } else {
            print("Peripheral Manager powered off")
        }
    }
}

extension BluetoothManager: CBPeripheralDelegate{
    
}
