//
//  ContentView.swift
//  Finder by ReloCane
//
//  Created by Cristian on 1/6/25.
//

import SwiftUI
import Foundation
import CoreBluetooth

var bleManager = BLEmanager()


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
    }
}

struct BluetoothDevicesView: View {
    
    var body: some View {
        VStack(spacing: 20) {
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
            
            .frame(height: UIScreen.main.bounds.height / 3)
            
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
            bleManager.clearStack()
        }
        
        .onAppear {
            bleManager.clearStack()
            if bleManager.on {
                bleManager.startScanning()
                //let timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(bleManager.refreshing), userInfo: nil, repeats: true)
            }
        }
        NavigationStack {
            VStack {
                NavigationLink("Settings", value: "S")
                Spacer()
                NavigationLink("Back to Relocane", value: "R")
            }
            .navigationDestination(for: String.self,
                                   destination: {value in value == "S" ? BluetoothSettingsView() : BluetoothSettingsView()})
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    @StateObject var bleManager: BLEmanager
    
    static var previews: some View {
        BluetoothDevicesView()
            .environmentObject(bleManager)
    }
}
