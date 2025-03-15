//
//  BLEmanager.swift
//  Relocane
//
//  Created by: RELOCANE LLC on 2/10/25.
//


import Foundation
import SwiftUI //just to make sure
import CoreBluetooth //duh

class BLEmanager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    var central: CBCentralManager!
    
    @Published var on = false //is bluetooth on?
    @Published var peripherals = [Peripheral]() //array of peripherals
    @Published var connectedperip: CBPeripheral? //the actual fucking peripheral
    @Published var connectedUUID: UUID? //uuid of the connected peripheral
    @Published var strength = -100 //STRENGTH FOR THE BEEP
    @Published var startConnect = false //false = hit connect, hasnt connected
    @Published var gotagain = true //when you connect to a device, did you see it again?
    @Published var FAKED = true //if youre trying to pseudo connect, we need this for BOB (prioritize only BOB without actually connecting)
    //make FAKED start at true, stored mode by default
    
    @AppStorage("STRING_KEY") var connected = "none"
    
    override init() {
        print("New BLEmanager made...")
        super.init() //super that initializer
        if (self.connected != "none") {
            connectedUUID = UUID(uuidString: connected) //hopefully loading the thingie???
        }
        central = CBCentralManager(delegate: self, queue: nil)
    }
    
    //clled when state of the manager is updated (duh)
    func centralManagerDidUpdateState(_ Central: CBCentralManager) {
        on = Central.state == .poweredOn //on updates accordingly
        if on {
            startScanning()}
        else {
            stopScanning()}
    }
    
    //scanning functions
    func connect(to peripheral:Peripheral) {
        guard let n = central.retrievePeripherals(withIdentifiers: [peripheral.id]).first
        else { //ese is called by guard
            print("No peripheral found for this connection")
            return
        }
        
        if connectedperip != nil  { //need to disconnect first
            return
        }
        
        connectedUUID = n.identifier
        connected = connectedUUID?.uuidString ?? "none"
        n.delegate = self
        print("starting connection...")
        if (FAKED) {
            print("Not actually connected via bluetooth, only prioritizing "+n.identifier.uuidString)
            refreshing()
            return
        }
        connectedperip = n
        startConnect = true
        central.connect(n, options:nil)
    }
    
    func disconnect(_ pseudo: Bool = false) {
        startConnect = false
        gotagain = true
        if pseudo { //update this
            FAKED = true;
        }
        if (FAKED) {
            connectedUUID = nil
            connected = "none"
        }
        if connectedperip != nil {
            central.cancelPeripheralConnection(connectedperip!)
        }
    }
    func startScanning() {
        print("Starting Scanning...")
        central.scanForPeripherals(withServices: nil, options: nil)
        //scans without specified services
    }
    
    func stopScanning() {
        print("Stopping Scanning... (Reset list too)")
        central.stopScan()
        peripherals.removeAll()
    }
    
    @objc func refreshing() { //used with the timer in content view (WOULDVE BEEN , NOW OBSOLETE)
        central.stopScan()
        central.scanForPeripherals(withServices: nil, options: nil)
    }
    
    func togglePuesdo() { 
        FAKED = !FAKED
        disconnect()
        //just making sure it actually disconnects lol
        connectedUUID = nil
        connected = "none"
        connectedperip = nil
        
        refreshing()
    }
    
    
    //THERE ARE MANY TYPES OF CENTRAL MANAGER!!!!
    
    //this is what is called when a peripheral is discovered
    func centralManager(_ Central: CBCentralManager, didDiscover perip:CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        
        let peripheral = Peripheral(id: perip.identifier,
                                    name: perip.name ?? "Unknown", //perip.identifier.uuidString,
                                    rssi: RSSI.intValue) //this is our new discovered peripheral
        
        
        //if not peripherals contains a spot where the index's id = our new peripheral.id
        //then add it to the list of peripherals
        if let ind = peripherals.firstIndex(where: {$0.id == peripheral.id}) { //if its in the thing
            if peripheral.id == connectedUUID {
                strength = peripheral.rssi
                gotagain = true
                refreshing() //refresh if you find the one youre connected to
            }
            self.peripherals[ind] = peripheral; //if rediscovered, update
        }
        else {
            self.peripherals.append(peripheral); //idk why there was dispatchquene here
        }
    }
    
    func clearStack() {
        print("Cleared the stack!")
        peripherals.removeAll() //yeah
        refreshing()
    }
    
    // when we connect yipeeee
    func centralManager(_ Central: CBCentralManager, didConnect perip: CBPeripheral) {
        startConnect = false
        print("connected!!! device: \(perip.name ?? "unknown")")
        gotagain = false
        perip.discoverServices(nil)
        refreshing()
    }
    
    //when disconnected unyipeeeee
    func centralManager(_ Central: CBCentralManager, didDisconnectPeripheral perip: CBPeripheral, error: Error?) {
        print("disconnected!!!! device: \(perip.name ?? "unknown"), error: \(error?.localizedDescription ?? "no error info")")
        gotagain = true
        
        if perip.identifier == connectedUUID {
            connectedperip = nil
            if !(FAKED) { //leave the UUID if we wanna pseudo!!!
                connectedUUID = nil
                
                connected = "none"
            }
        }
    }
    
    //if failed to connect
    func centralManager(_ Central: CBCentralManager, didFailToConnect perip: CBPeripheral, error: Error?) {
        print("failed to connect to \(perip.name ?? "unknown") :(, error: \(error?.localizedDescription ?? "no error info")")
        
        if perip.identifier == connectedUUID {
            connectedperip = nil
            connectedUUID = nil
            
            connected = "none"
        }
    }
    
    
    
    //stuff that happens with peripheral: .discoverServices and .discoverCharacteristics
    
    //prints all services of the peripheral
    func peripheral(_ perip: CBPeripheral, didDiscoverServices error: Error?) {
        if let Ss = perip.services { //idk why bro didnt use guard
            for S in Ss {
                print("SERVICE FOUND: \(S.uuid)")
                perip.discoverCharacteristics(nil, for: S)
            }
        }
    }
    
    //prints all characteristics of the service (passed in above)
    func peripheral(_ perip: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let Cs = service.characteristics { //idk why bro didnt use guard
            for C in Cs {
                print("SERVICE CHARACTERISTIC FOUND: \(C.uuid)")
            }
        }
    }
    
    func seen(_ uuid: UUID) -> Bool {
        //if this UUID in peripherals return true, else false
        return (peripherals.firstIndex(where: {$0.id == uuid}) != nil)
        
    }

    //fin fin fin 
}

