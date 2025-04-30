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
    
    var speakit = false //controls whether the voice speaks checkpoints (ex: 50 achieved, 40 achieved)
    var best_strength = -100
    
    var strength = -100
    var last_strength = -100
    var audio = AVAudioPlayer()
    var last_strengths = [Int]()
    var spoken = 40
    public var BLE: BLEmanager!
    var enabled = false
    var stopping = false
    var count = 0 //counts how many times the same strength has repeated
    //when it repeats more than 5? times we say we cant see the device
    
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
    
    func toggle() {
        speakit = !speakit
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
            if (!self.enabled) { self.stopping = false; return }
            
            self.audio.currentTime = 0
            print(" Strength: ", self.strength,", Last: ",self.last_strength,", Best: ",self.best_strength,", Count:",self.count)
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
            
            if (self.strength>0 || abs(self.strength-self.last_strength) > 80) {
                self.strength = self.last_strength
            }
            
            self.last_strength = self.strength
            
            
            
            if (self.count >= (self.audio.rate > 10 ? 20 : 10)) {
                speaker.speak(phrase: "Device not found nearby. Stopping scanning.")
                self.count = 0
                self.stopping = false
                self.enabled = false
                self.BLE.clearStack()
                return
            }
            else {
                
                //for rolling average
                if (self.last_strengths.count == 3) {
                    self.last_strengths.removeLast()
                }
                self.last_strengths.append(self.strength)
                
                let T = self.last_strengths
                let NEW = Double(T[0] + (T.count > 1 ? T[1] : T[0]) + (T.count > 2 ? T[2] : T[0])) / 3.0
                
                self.audio.prepareToPlay()
                
                //rate is 1.25^1 if strength = 90, about 5 when strength = 3
                self.audio.enableRate = true
                
                
                self.audio.rate = Float(pow(NEW > Double(self.area) ? 1.5 : 1.4, 10 - round(Double(NEW * -1) / 10.0))) + ((NEW+2.0) > Double(self.best) ? 2 : 0)
                //NEW SYSTEM:
                //When you get above self.area, the exponential goes from 1.4^x to 1.5^x
                //When you get above self.best, just a flat bonus of 2
                
                
                
                self.audio.volume = 0.3 * self.audio.rate * (self.speakit ? 0.2 : 1)
                print("Current rate: ", self.audio.rate)
                
                self.audio.play()
                
                //this is for the checkpoint thing
                if (self.speakit && (self.best_strength > Int(round(Double(self.strength * -1) / 10.0)))) {
                    print("Bested!!!")
                    speaker.speak(phrase: "Proximity "+String(Int(round(Double(self.strength * -1) / 10.0)) - 2)+" achieved")

                    self.best_strength = Int(round(Double(self.strength * -1) / 10.0))
                }
                
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
    
    func stop() {
        stopping = true
        enabled = false
    }
}
