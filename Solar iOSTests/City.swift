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
    
    @nonobjc static var isoDateFormatter: DateFormatter = {
        var dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return dateFormatter
    }()
    
}

struct City {
    let name: String
    let coordinates: CLLocationCoordinate2D
    let sunrise: Date
    let sunset: Date
    
    init(json: [String: Any]) {
        guard
            let name = json["city"] as? String,
            let latitude = json["latitude"] as? Double,
            let longitude = json["longitude"] as? Double,
            let sunriseString = json["sunrise"] as? String,
            let sunsetString = json["sunset"] as? String,
            let sunrise = DateFormatter.isoDateFormatter.date(from: sunriseString),
            let sunset = DateFormatter.isoDateFormatter.date(from: sunsetString)
            else {
                fatalError("Could not instantiate a city from JSON: \(json)")
        }
        let coordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        if !CLLocationCoordinate2DIsValid(coordinates) {
            fatalError("City has invalid coordinates: \(coordinates)")
        }
        
        self.name = name
        self.coordinates = coordinates
        self.sunrise = sunrise
        self.sunset = sunset
    }
}
