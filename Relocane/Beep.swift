//
//  Beep.swift
//  Relocane
//
//  Created by Coding Club on 3/13/25.
//
import Foundation
import AVFoundation
import SwiftUI

class Beep: NSObject, ObservableObject{
    var strength = -100
    var last_strength = -100
    var audio = AVAudioPlayer()
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
        audio.play()
    }
}
