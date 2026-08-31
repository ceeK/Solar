//
//  City.swift
//  Solar
//
//  Created by Chris Howell on 13/02/2017.
//  Copyright © 2017 Chris Howell. All rights reserved.
//

import Foundation
import CoreLocation

extension DateFormatter {
    
    @nonobjc static let isoDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return dateFormatter
    }()
    
}

struct City {
    let name: String
    let coordinate: CLLocationCoordinate2D
    let sunrise: Date
    let sunset: Date
    let civilSunrise: Date
    let civilSunset: Date
    let nauticalSunrise: Date
    let nauticalSunset: Date
    let astronomicalSunrise: Date
    let astronomicalSunset: Date

    init(json: [String: Any]) {
        func date(_ key: String) -> Date {
            guard
                let string = json[key] as? String,
                let date = DateFormatter.isoDateFormatter.date(from: string)
                else {
                    fatalError("Could not read '\(key)' from JSON: \(json)")
            }
            return date
        }

        guard
            let name = json["city"] as? String,
            let latitude = json["latitude"] as? Double,
            let longitude = json["longitude"] as? Double
            else {
                fatalError("Could not instantiate a city from JSON: \(json)")
        }
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        guard CLLocationCoordinate2DIsValid(coordinate) else {
            fatalError("City has invalid coordinates: \(coordinate)")
        }

        self.name = name
        self.coordinate = coordinate
        self.sunrise = date("sunrise")
        self.sunset = date("sunset")
        self.civilSunrise = date("civilSunrise")
        self.civilSunset = date("civilSunset")
        self.nauticalSunrise = date("nauticalSunrise")
        self.nauticalSunset = date("nauticalSunset")
        self.astronomicalSunrise = date("astronomicalSunrise")
        self.astronomicalSunset = date("astronomicalSunset")
    }
}
