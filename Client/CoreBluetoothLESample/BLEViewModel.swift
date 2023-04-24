import Foundation
import CoreBluetooth
import Combine

class BLEViewModel: NSObject, ObservableObject {
    @Published var receivedText: String = ""
    
    private var centralManager: CBCentralManager!
    private var discoveredPeripheral: CBPeripheral?
    private var transferCharacteristic: CBCharacteristic?
    
    // Add your service and characteristic UUIDs here
    let serviceUUID = CBUUID(string: "E20A39F4-73F5-4BC4-A12F-17D1AD07A961")
    let characteristicUUID = CBUUID(string: "08590F7E-DB05-467E-8757-72F6FAEB13D4")

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func connect() {
        if let peripheral = discoveredPeripheral {
            centralManager.connect(peripheral, options: nil)
        } else {
            centralManager.scanForPeripherals(withServices: [serviceUUID], options: nil)
        }
    }
}

// MARK: - CBCentralManagerDelegate
extension BLEViewModel: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            print("Central Manager is powered on")
            centralManager.scanForPeripherals(withServices: [serviceUUID], options: nil)
        } else {
            print("Central Manager is not powered on")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("Discovered \(peripheral.name ?? "unknown")")
        discoveredPeripheral = peripheral
        centralManager.stopScan()
        centralManager.connect(peripheral, options: nil)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to peripheral: \(peripheral.name ?? "unknown")")
        peripheral.delegate = self
        peripheral.discoverServices([serviceUUID])
    }
}

// MARK: - CBPeripheralDelegate
extension BLEViewModel: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("Error discovering services: \(error.localizedDescription)")
            return
        }

        guard let services = peripheral.services else { return }
        for service in services {
            print("Discovered service: \(service.uuid.uuidString)")
            peripheral.discoverCharacteristics([characteristicUUID], for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("Error discovering characteristics: \(error.localizedDescription)")
            return
        }

        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            print("Discovered characteristic: \(characteristic.uuid.uuidString)")
            if characteristic.uuid == characteristicUUID {
                transferCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error updating value for characteristic: \(error.localizedDescription)")
            return
        }

        guard let data = characteristic.value else {
            print("Error: Received empty data")
            return
        }

        if let receivedString = String(data: data, encoding: .utf8) {
            print("Received: \(receivedString)")
            DispatchQueue.main.async {
                if receivedString != "EOM" {
                    self.receivedText = receivedString
                }
            }
        } else {
            print("Received data is not a valid UTF-8 string")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error changing notification state: \(error.localizedDescription)")
            return
        }

        if characteristic.isNotifying {
            print("Notification started for \(characteristic.uuid.uuidString)")
        } else {
            print("Notification stopped for \(characteristic.uuid.uuidString)")
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if let error = error {
            print("Error disconnecting from peripheral: \(error.localizedDescription)")
        } else {
            print("Disconnected from peripheral")
        }
        discoveredPeripheral = nil
        transferCharacteristic = nil
        centralManager.scanForPeripherals(withServices: [serviceUUID], options: nil)
    }
}
