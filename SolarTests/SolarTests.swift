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

private extension Date {
	func simpleTime(calendar: Calendar) -> String {
		let df = DateFormatter()
		df.dateFormat = "MM-dd HH:mmZ"
		return df.string(from: self)
	}
}

final class SolarTests: XCTestCase {
    
    private let testDate = Date(timeIntervalSince1970: 1486598400)
    
    /// How accurate, in minutes either side of the actual sunrise sunset, we want to be
    /// This is necessary as the algorithm uses assumptions during calculation
    private let testAccuracy: TimeInterval = 60 * 5
    
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
    
    func testSunrise() {
        for city in cities {
            let solar = Solar(for: testDate, latitude: city.latitude, longitude: city.longitude)
            
            guard
                let sunrise = solar?.sunrise
            else {
                XCTFail("Sunrise cannot be generated for city \(city.name)")
                return
            }
            
            XCTAssertEqualWithAccuracy(sunrise.timeIntervalSince1970, city.sunrise.timeIntervalSince1970, accuracy: testAccuracy, "\(city.name): \(sunrise) not close to \(city.sunrise)")
        }
    }
    
    func testSunrise_isNil_whenNoSunriseOccurs() {
        let solar = Solar(for: testDate, latitude: 78.2186, longitude: 15.64007) // Location: Longyearbyen
        XCTAssertNotNil(solar)
        XCTAssertNil(solar?.sunrise)
    }
    
    func testSunset() {
        for city in cities {
            let solar = Solar(for: testDate, latitude: city.latitude, longitude: city.longitude)
            
            guard
                let sunset = solar?.sunset
            else {
                XCTFail("Sunset cannot be generated for city \(city.name)")
                return
            }
            
            XCTAssertEqualWithAccuracy(sunset.timeIntervalSince1970, city.sunset.timeIntervalSince1970, accuracy: testAccuracy, "\(city.name): \(sunset) not close to \(city.sunset)")
        }
    }
    
    func testSunset_isNil_whenNoSunsetOccurs() {
        let solar = Solar(for: testDate, latitude: 78.2186, longitude: 15.64007) // Location: Longyearbyen
        XCTAssertNotNil(solar)
        XCTAssertNil(solar?.sunset)
    }
    
    func testIsDayTime_isTrue_betweenSunriseAndSunset() {
        let daytime = Date(timeIntervalSince1970: 1486641600) // noon
        let city = cities.first(where: { $0.name == "London" })!
        
        guard
            let solar = Solar(for: daytime, latitude: city.latitude, longitude: city.longitude)
        else {
            XCTFail("Cannot get solar")
            return
        }
        
        XCTAssertTrue(solar.isDaytime, "isDaytime is false for date: \(daytime) with sunrise: \(solar.sunrise!), sunset: \(solar.sunset!)")
        XCTAssertFalse(solar.isNighttime, "isNighttime is true for date: \(daytime) with sunrise: \(solar.sunrise!), sunset: \(solar.sunset!)")
    }
    
    func testIsDayTime_isTrue_exactlyAtSunrise() {
        let sunrise = Date(timeIntervalSince1970: 1486625181)
        let city = cities.first(where: { $0.name == "London" })!
        
        guard
            let solar = Solar(for: sunrise, latitude: city.latitude, longitude: city.longitude)
        else {
            XCTFail("Cannot get solar")
            return
        }
        
        XCTAssertTrue(solar.isDaytime, "isDaytime is false for date: \(sunrise) with sunrise: \(solar.sunrise!), sunset: \(solar.sunset!)")
        XCTAssertFalse(solar.isNighttime, "isNighttime is true for date: \(sunrise) with sunrise: \(solar.sunrise!), sunset: \(solar.sunset!)")
    }
    
    func testIsDayTime_isFalse_exactlyAtSunset() {
        let sunset = Date(timeIntervalSince1970: 1486659846)
        let city = cities.first(where: { $0.name == "London" })!
        
        guard
            let solar = Solar(for: sunset, latitude: city.latitude, longitude: city.longitude)
        else {
            XCTFail("Cannot get solar")
            return
        }
                
        XCTAssertFalse(solar.isDaytime, "isDaytime is false for date: \(sunset) with sunrise: \(solar.sunrise!), sunset: \(solar.sunset!)")
        XCTAssertTrue(solar.isNighttime, "isNighttime is true for date: \(sunset) with sunrise: \(solar.sunrise!), sunset: \(solar.sunset!)")
    }
    
    func testIsDayTime_isFalse_beforeSunrise() {
        let beforeSunrise = Date(timeIntervalSince1970: 1486624980)
        let city = cities.first(where: { $0.name == "London" })!
        
        guard
            let solar = Solar(for: beforeSunrise, latitude: city.latitude, longitude: city.longitude)
        else {
            XCTFail("Cannot get solar")
            return
        }
        
        XCTAssertFalse(solar.isDaytime, "isDaytime is true for date: \(beforeSunrise) with sunrise: \(solar.sunrise!), sunset: \(solar.sunset!)")
        XCTAssertTrue(solar.isNighttime, "isNighttime is false for date: \(beforeSunrise) with sunrise: \(solar.sunrise!), sunset: \(solar.sunset!)")
    }
    
    func testIsDayTime_isFalse_afterSunset() {
        let afterSunset = Date(timeIntervalSince1970: 1486659960)
        let city = cities.first(where: { $0.name == "London" })!
        
        guard
            let solar = Solar(for: afterSunset, latitude: city.latitude, longitude: city.longitude)
        else {
            XCTFail("Cannot get solar")
            return
        }
        
        XCTAssertFalse(solar.isDaytime, "isDaytime is true for date: \(afterSunset) with sunrise: \(solar.sunrise!), sunset: \(solar.sunset!)")
        XCTAssertTrue(solar.isNighttime, "isNighttime is false for date: \(afterSunset) with sunrise: \(solar.sunrise!), sunset: \(solar.sunset!)")
    }
	
    func testLateTimeCorrectReturnDate() {
        let lateTime = Date(timeIntervalSince1970: 1499130000)
        let city = cities.first(where: { $0.name == "Washington, D. C." })!
		
        let calendar: Calendar = {
            var calendar = Calendar.current
            calendar.timeZone = TimeZone(identifier: "EST")!
            return calendar
        }()
		
        guard let solar = Solar(for: lateTime, latitude: city.latitude, longitude: city.longitude, withCalendar: calendar) else {
            XCTFail("Cannot get solar")
            return
        }
		
        let sameDate = calendar.compare(lateTime, to: solar.sunset!, toGranularity: .day)
		
        XCTAssertTrue(sameDate == .orderedSame, "The sunset given \(solar.sunset!.simpleTime(calendar: calendar)) is not same day as given date \(lateTime.simpleTime(calendar: calendar))")
    }
}
