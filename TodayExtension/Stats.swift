//
//  File.swift
//  TodayExtension
//
//  Created by Леонид Лядвейкин on 19.03.2018.
//  Copyright © 2018 hse. All rights reserved.
//

import Foundation
import SwiftyJSON

class BitCoinStats : NSObject {
    let marketPriceUSD: NSNumber
    let time: Date
    
    public init(fromJSON json: JSON) {
        marketPriceUSD = json["market_price_usd"].number!
        
        let timeInterval :TimeInterval = json["timestamp"].double! / 1000
        time = Date(timeIntervalSince1970: timeInterval)
    }
}

class BitCoinPrice : NSObject {
    let value: Double
    let time: Date
    
    public init(fromJSON json: JSON) {
        value = json["y"].double!
        
        let timeInterval: TimeInterval = json["x"].double!
        let timezoneBump = Double(-TimeZone.current.secondsFromGMT()) 
        time = Date(timeIntervalSince1970: timeInterval + timezoneBump)
    }
    
}
