//
//  Beep.swift
//  Relocane
//
//  Created by Coding Club on 3/13/25.
//
import Foundation
import AVFoundation
import SwiftUI

var speaker = Speaker()

class Beep: NSObject, ObservableObject{
    var strength = -100
    var last_strength = -100
    var audio = AVAudioPlayer()
    var BLE: BLEmanager!
    var enabled = false
    var count = 0 //counts how many times the same strength has repeated
    //when it repeats more than 5? times we say we cant see the device
    
    override init() {
        super.init()
        guard let file = NSDataAsset(name: "sonar") else {
            print(":( couldnt find the sound sonar sound wahhh")
            return
        }
        do {
            audio = try AVAudioPlayer(data: file.data)
        }
        catch {
            print(":( couldnt read the sound sonar sound wahhh")
        }
    }
    
    func start() {
        enabled = true
        last_strength = Int(BLE.strength)
        while (enabled) { //just tried this
            strength = Int(BLE.strength)
            if (strength == last_strength) {
                count += 1
            }
            else {
                count = 0
            }
            
            if (abs(strength-last_strength) > 50) {
                strength = last_strength
            }
            
            last_strength = strength
            
            if (count >= 5 && !BLE.seen(BLE.connectedUUID!)) {
                speaker.speak(phrase: "Device not found nearby. Stopping scanning.")
                return
            }
            else {
                audio.play()
            }
            sleep(UInt32(10 * Int(round(Double(strength) / 10.0)) * 10))
            //big ass thing to round the strength
        }
    }
    
    func stop() {
        enabled = false
    }
}
