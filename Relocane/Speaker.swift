//
//  Speaker.swift
//  Relocane
//
//  Created by: RELOCANE LLC on 3/3/25.
//

import Foundation
import SwiftUI
import AVFoundation

class Speaker: NSObject, ObservableObject{
    var voice = AVSpeechSynthesisVoice(language: "en-GB")
    var speaker = AVSpeechSynthesizer()
    var rate = 0.4 //maybe make a modifier for this idk
    
    
    func speak(phrase p: String = "Hello World"){
        if speaker.isSpeaking {
            stop()
        }
        let talk = AVSpeechUtterance(string: p)
        
        talk.rate = Float(rate)
        talk.pitchMultiplier = 0.75
        talk.postUtteranceDelay = 0.2
        talk.volume = 0.75
        talk.voice = voice
        
        speaker.speak(talk)
    }
    
    func stop() {
        speaker.stopSpeaking(at: .immediate)
    }
}
