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
    
    // var speakit = false //controls whether the voice speaks checkpoints (ex: 50 achieved, 40 achieved) THIS IS DISABLED
    //var last_strengths = [Int]()//this used to be for a rolloing average, THIS IS DISABLED
    //var spoken = 40 this used to be for checkpoints, THIS IS DISABLED
    
    var best_strength = -100
    var strength = -100
    var last_strength = -100
    
    var audio = AVAudioPlayer()
    public var BLE: BLEmanager!
    
    var enabled = false
    var stopping = false
    
    var count = 0 //counts how many times the same strength has repeated
    
    @AppStorage("NUMBER_KEY") var best = -40
    @AppStorage("NUMBER_KEY") var area = -60
    
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
    
    func storeBest(_ thingie: Int){
        best = thingie
    }
    func storeArea(_ thingie: Int){
        area = thingie
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
            if (!self.enabled) {
                self.stopping = false; return
            }
            
            self.audio.currentTime = 0 //reset audio to start
            self.strength = Int(self.BLE.strength)
            
            
            if (self.strength == self.last_strength) {
                if (self.strength == -100 && self.count >= 2 && self.count % 3 == 0) {
                    speaker.speak(phrase: "Waiting...")
                }
                self.count += 1
            }
            else {
                self.count = 0
            }
            
            //for checking if we get like 127 randomly, since sometimes the signal strength has a stroke
            if (self.strength>0 || abs(self.strength-self.last_strength) > 80) {
                self.strength = self.last_strength
            }
            
            
            if (self.count >= (self.audio.rate > 10 ? 20 : 10)) {
                speaker.speak(phrase: "Device not found nearby. Stopping scanning.")
                self.count = 0
                self.stopping = false
                self.enabled = false
                self.BLE.clearStack()
                return
            }
            else {
                let NEW = Double(self.last_strength) + Double(self.strength - self.last_strength) / 2.0
                
                self.last_strength = Int(NEW)
                
                
                print("Current NEW:",NEW,"|Target:",self.strength,"|Area:",self.area)
                
                
                self.audio.prepareToPlay()
                self.audio.enableRate = true
                
                let ROUNDER = round(Double(NEW * -1) * 2 / 10.0) / 2 //rounds the sig strength to the nearest 5?
                
                self.audio.rate = Int(NEW) < self.area ? 4 : Float(pow(1.5, 10 - ROUNDER)) + ((NEW+2.0) > Double(self.best) ? 2 : 0)
                self.audio.volume = Int(NEW) < self.area ? 0.2 : pow(1.1, self.audio.rate) //* (self.speakit ? 0.2 : 1)
                
                print("Current rate: ", self.audio.rate)
                
                
                self.audio.play()
                self.run(true)
            }
        } //end timer
    }
    func start() {
        enabled = true
        last_strength = Int(BLE.strength)
        best_strength = Int(round(Double(last_strength * -1) / 10.0))
        run(false)
        //UInt32(10 * Int(round(Double(strength) / 10.0)) * 10)
        //big ass thing to round the strength to nearest 10 an uint32 to put it into the sleep func
    }
    
    func STOPPING(){ //used for stopping the button from being spammed with the switching from cane to phone
        stopping = true
    }
    
    func UNSTOPPING(){
        stopping = false
    }
    
    func stop() {
        stopping = true
        enabled = false
    }
}
