//
//  Peripheral.swift
//  Relocane
//
//  Created by Coding Club on 2/10/25.
//


//
//  peripheral.swift
//  Finder by ReloCane
//
//  Created by Cristian on 1/8/25.
//

import Foundation

struct Peripheral: Identifiable { //peripheral type, going to be used with the bluetooth stuffs
    let id: UUID //has an ID (number?)
    let name: String //name of each (MacBook)
    let rssi: Int //signal strength number
}
