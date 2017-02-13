//
//  SolarTests.swift
//  SolarTests
//
//  Created by Chris Howell on 08/02/2017.
//  Copyright © 2017 Chris Howell. All rights reserved.
//

import XCTest

@testable
import Solar

final class SolarTests: XCTestCase {
    
    private let testDate = Date(timeIntervalSince1970: 1486598400)
    
    private lazy var cities: [City] = {
        guard
            let resultsURLString = Bundle(for: type(of: self)).path(forResource: "CorrectResults", ofType: "json"),
            let resultsURL = URL(string: "file:///" + resultsURLString),
            let data = try? Data(contentsOf: resultsURL),
            let dictionary = try? JSONSerialization.jsonObject(with: data, options: []),
            let cityDictionaries = dictionary as? [[String : Any]]
        else {
            fatalError("Correct results JSON doesn't appear to be included in the test bundle.")
        }
        return cityDictionaries.map(City.init(json:))
    }()
    
    func testIsDayTime() {
        let city = cities.first!
        let solar = Solar(for: testDate, latitude: city.latitude, longitude: city.longitude)
        
        guard
            let sunset = solar?.sunset,
            let sunrise = solar?.sunrise
        else {
            XCTFail("Cannot get sunset and sunrise")
            return
        }
        
        
    }
    
    func testIsNightTime() {
        
    }
    
    func testSunrise() {
        for city in cities {
            let solar = Solar(for: testDate, latitude: city.latitude, longitude: city.longitude)
            
            guard
                let sunrise = solar?.sunrise
            else {
                XCTFail("Sunrise cannot be generated for city \(city.name)")
                return
            }
            
            XCTAssertEqualWithAccuracy(sunrise.timeIntervalSince1970, city.sunrise.timeIntervalSince1970, accuracy: (60 * 5), "\(city.name): \(sunrise) not close to \(city.sunrise)")
        }
        
    }
    
    func testSunset() {
        for city in cities {
            let solar = Solar(for: testDate, latitude: city.latitude, longitude: city.longitude)
            
            guard
                let sunset = solar?.sunset
            else {
                XCTFail("Sunrise cannot be generated for city \(city.name)")
                return
            }
            
            XCTAssertEqualWithAccuracy(sunset.timeIntervalSince1970, city.sunset.timeIntervalSince1970, accuracy: (60 * 5), "\(city.name): \(sunset) not close to \(city.sunset)")
        }

    }
    
}

// MARK: - Helpers

private extension DateFormatter {
    
    @nonobjc static var isoDateFormatter: DateFormatter = {
        var dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return dateFormatter
    }()
    
}

private struct City {
    let name: String
    let latitude: Double
    let longitude: Double
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
        
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.sunrise = sunrise
        self.sunset = sunset
    }
}
