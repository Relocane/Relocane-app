//
//  Beep.swift
//  Relocane
//
//  Created by Relocane LLC on 3/13/25.
//
import Foundation
import AVFoundation
import SwiftUI

var speaker = Speaker()

class Beep: NSObject, ObservableObject{
    var strength = -100
    var last_strength = -100
    var audio = AVAudioPlayer()
    var spoken = 40
    public var BLE: BLEmanager!
    var enabled = false
    var stopping = false
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
    func run(_ shouldwait: Bool = true) {
        if (!enabled){
            stopping = false
            return
        }
            
        var timertime = 0.0
        if shouldwait {
            timertime = 1.0/audio.format.sampleRate * 100000.0 / Double(self.audio.rate)
        }
        
        Timer.scheduledTimer(withTimeInterval: timertime, repeats: false) {_ in
            if (!self.enabled) { self.stopping = false; return }
            
            self.audio.currentTime = 0
            print("Locating, current strength is ", self.strength)
            self.strength = Int(self.BLE.strength)
            
            if (self.strength == self.last_strength) {
                if (self.strength == -100 && self.count >= 2) {
                    speaker.speak(phrase: "Waiting...")
                }
                self.count += 1
            }
            else {
                self.count = 0
            }
            
            if (self.strength>0 || abs(self.strength-self.last_strength) > 80) {
                self.strength = self.last_strength
            }
            
            self.last_strength = self.strength
            
            if (self.count >= 5 && !self.BLE.seen(self.BLE.connectedUUID!)) {
                speaker.speak(phrase: "Device not found nearby. Stopping scanning.")
                self.stopping = false
                self.enabled = false
                return
            }
            else {
                self.audio.prepareToPlay()
                
                //rate is 1.25^1 if strength = 90, about 5 when strength = 3
                self.audio.enableRate = true
                self.audio.rate = Float(pow(1.4, 10 - round(Double(self.strength * -1) / 10.0))) + (self.strength > -50 ? 1.0 : 0.0)
                self.audio.volume = 0.3 * self.audio.rate
                print(self.audio.volume)
                
                self.audio.play()
                self.run(true)
            }
        } //end timer
    }
    func start() {
        enabled = true
        last_strength = Int(BLE.strength)
        run(false)
        //UInt32(10 * Int(round(Double(strength) / 10.0)) * 10)
        //big ass thing to round the strength to nearest 10 an uint32 to put it into the sleep func
    }
    
    func stop() {
        stopping = true
        enabled = false
    }
}
