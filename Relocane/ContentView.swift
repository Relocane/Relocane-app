//
//  ContentView.swift
//  Finder by ReloCane
//
//  Created by: RELOCANE LLC on 1/6/25.
//

// RELOCANE device ID: UUID(uuidString: "E929D4BE-6CCA-FA85-1C5E-4138AEF818D6")

import SwiftUI
import Foundation
import CoreBluetooth

//MAIN APP CALLS
struct ContentView: View {
    var body: some View {
        MainView()
    }
}

struct BluetoothSettingsView: View {
    @EnvironmentObject var bleManager: BLEmanager
    
    var body: some View {
    
        VStack(spacing: 10) {
            Button(action: {bleManager.clearStack()}) {
                Text("Refresh")
            }.buttonStyle(BorderedProminentButtonStyle())
            
            Button(action: {bleManager.disconnect()}) {
                Text("Disconnect")
            }.buttonStyle(BorderedProminentButtonStyle())
            
            Button(action: {bleManager.togglePuesdo()}) {
                Text("MODE: " + (bleManager.FAKED ? "Store ID" : "Connect"))
            }.buttonStyle(BorderedProminentButtonStyle())
        }
        .onAppear {
            print("Settings Appeared")
        }
    }
}

struct MainView: View{
    @EnvironmentObject var bleManager : BLEmanager
    @StateObject var speaker = Speaker()
    @StateObject var beep = Beep()
    @State var activated = true
    
    var body: some View {
        NavigationStack {
            Button(action:{
                if beep.stopping {
                    
                }
                else if beep.enabled {
                    beep.stop()
                }
                else {
                    if bleManager.connectedUUID != nil {
                        //locate
                        bleManager.startScanning()
                        beep.start()
                        beep.strength = bleManager.strength //hopefully this updates
                        speaker.speak(phrase: "Finding cane")
                        
                    }
                    else {
                        speaker.speak(phrase: "No device connected.")
                    }
                }
            }){
                Text((bleManager.connectedUUID == nil ? "Go to settings, connect a device" : "RELOCANE: Locate Cane Device"))
                    .frame(maxWidth: .infinity,
                           maxHeight: UIScreen.main.bounds.height / 1.3)
            }   .buttonStyle(BorderedButtonStyle())
                .onAppear{
                    if !beep.enabled {
                        speaker.speak(phrase : ((bleManager.connectedUUID == nil) ? "Please give the phone to someone who can find the REE LOW CANE locator device in the Settings menu. This page is not yet easily accessible to the visually impaired." : "Ree low cane app ready! Press the middle of the screen to start locating."))
                    }
                }
                .accessibilityInputLabels(["Button","Locate Cane","Find Cane","Where is my cane","Donde esta","Where my cane at","Start locating","Start","Done","Found Cane"])
                //.accessibilityInputLabels(["Done","Button","Cane","Found"], isEnabled: beep.enabled)
            
            
            //settings
            
            Spacer()
            NavigationLink(destination: {
                BluetoothDevicesView().environmentObject(bleManager)
                    .onAppear {
                        speaker.stop()
                    }
            }) {
                Text("Settings")
            }
            
            
            NavigationLink(destination: EmptyView()) {
                EmptyView()
            }
        }
        .onAppear {
            beep.BLE = bleManager
            print("ID: "+(bleManager.connectedUUID?.uuidString ?? "NO CONNECTED UUID"))
            if (bleManager.on) {
                bleManager.startScanning()
            }
        }
        
    }
}

struct BluetoothDevicesView: View {
    @EnvironmentObject var bleManager : BLEmanager
    var body: some View {
        NavigationStack {
            VStack(spacing: 10) {
                List(bleManager.peripherals.filter({$0.name != "Unknown"}))
                {peripheral in
                    HStack {
                        Text(peripheral.name)
                        
                        Spacer()
                        
                        Text(String(peripheral.rssi))
                            .foregroundStyle(peripheral.rssi > -45 ? .green : peripheral.rssi > -75 ? .yellow : .red)
                        Button(action: { bleManager.connect(to: peripheral) }) {
                            if bleManager.connectedUUID == peripheral.id {
                                Text(bleManager.startConnect ? (bleManager.FAKED ? "Storing..." :  "Connecting...") : bleManager.gotagain ? (bleManager.FAKED ? "Stored!" :  "Connected") : "Waiting...")
                                    .foregroundStyle(.green) //yayy
                            }
                            else {
                                Text(bleManager.FAKED ? "Store?" : "Connect?")
                            }
                        }
                    }
                }
                
                .frame(height: UIScreen.main.bounds.height / 3)
                
                
                List(bleManager.peripherals.filter({$0.name == "Unknown"})) {peripheral in
                    HStack {
                        Text(peripheral.name)
                        
                        Spacer()
                        
                        Text(String(peripheral.rssi))
                        Button(action: { bleManager.connect(to: peripheral) }) {
                            if bleManager.connectedUUID == peripheral.id {
                                Text(bleManager.startConnect ? (bleManager.FAKED ? "Storing..." :  "Connecting...") : bleManager.gotagain ? (bleManager.FAKED ? "Stored!" :  "Connected") : "Waiting...")
                                    .foregroundStyle(.green) //yayy
                            }
                            else {
                                Text(bleManager.FAKED ? "Store?" : "Connect?")
                            }
                        }
                    }
                }
                
                .frame(height: UIScreen.main.bounds.height / 4)
                
                if bleManager.on {
                    if let PER = bleManager.connectedperip {
                        Text("Connection device: "+(PER.name ?? "???"))
                            .foregroundStyle(.teal)
                    }
                    else if let UU = bleManager.connectedUUID {
                        Text("Stored ID: "+(UU.uuidString.prefix(8))+"...")
                            .foregroundStyle(.orange)
                    }
                    else {
                        Text(bleManager.on ? "Bluetooth: on!!" : "Bluetooth: off :(")
                            .foregroundStyle(bleManager.on ? .green : .red)
                    }
                }
                
                Spacer()
            }
            
            
            .onDisappear {
                //bleManager.clearStack()
            }
            
            .onAppear {
                //bleManager.clearStack()
                if bleManager.on {
                    bleManager.startScanning()
                    //let timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(bleManager.refreshing), userInfo: nil, repeats: true)
                }
            }
            
            VStack {
                NavigationLink(destination: {MainView().environmentObject(bleManager)}) {
                    Text("Back to Relocane")
                }
                Spacer()
                NavigationLink(destination: {BluetoothSettingsView().environmentObject(bleManager)}) {
                    Text("Settings")
                }
            }
        }
    }
}


//PREVIEW CALLS

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(BLEmanager())
    }
}
struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView().environmentObject(BLEmanager())
    }
}
struct BluetoothDevicesView_Previews: PreviewProvider {
    static var previews: some View {
        BluetoothDevicesView().environmentObject(BLEmanager())
    }
}
struct BluetoothSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        BluetoothSettingsView().environmentObject(BLEmanager())
    }
}
