//
//  SolarTests.swift
//  SolarTests
//
//  Created by Chris Howell on 08/02/2017.
//  Copyright © 2017 Chris Howell. All rights reserved.
//

import XCTest
import CoreLocation
@testable import Solar

final class SolarTests: XCTestCase {
    
    private let testDate = Date(timeIntervalSince1970: 1486598400)
    
    /// How accurate, in minutes either side of the actual sunrise sunset, we want to be
    /// This is necessary as the algorithm uses assumptions during calculation
    private let testAccuracy: TimeInterval = 60 * 5
    private var cities: [City]!

    let bundle: Bundle = {
        #if SWIFT_PACKAGE
        return Bundle.module
        #else
        return Bundle(for: SolarTests.self)
        #endif
    }()

    override func setUpWithError() throws {
        try super.setUpWithError()
        let resultsURL = try XCTUnwrap(bundle.url(forResource: "CorrectResults", withExtension: "json"))
        let data = try Data(contentsOf: resultsURL)
        let cityDictionaries = try XCTUnwrap(try JSONSerialization.jsonObject(with: data, options: []) as? [[String : Any]])
        cities = cityDictionaries.map(City.init(json:))
    }
    
    func testSunrise() {
        for city in cities {
            let solar = Solar(for: testDate, coordinate: city.coordinate)
            
            guard
                let sunrise = solar?.sunrise
            else {
                XCTFail("Sunrise cannot be generated for city \(city.name)")
                return
            }
            
            XCTAssertEqual(sunrise.timeIntervalSince1970, city.sunrise.timeIntervalSince1970, accuracy: testAccuracy, "\(city.name): \(sunrise) not close to \(city.sunrise)")
        }
    }
    
    func testSunrise_isNil_whenNoSunriseOccurs() {
        let solar = Solar(for: testDate, coordinate: CLLocationCoordinate2D(latitude: 78.2186, longitude: 15.64007)) // Location: Longyearbyen
        XCTAssertNotNil(solar)
        XCTAssertNil(solar?.sunrise)
    }
    
    func testSunset() {
        for city in cities {
            
            let solar = Solar(for: testDate, coordinate: city.coordinate)
            
            guard
                let sunset = solar?.sunset
            else {
                XCTFail("Sunset cannot be generated for city \(city.name)")
                return
            }
            
            XCTAssertEqual(sunset.timeIntervalSince1970, city.sunset.timeIntervalSince1970, accuracy: testAccuracy, "\(city.name): \(sunset) not close to \(city.sunset)")
        }
    }
    
    func testSunset_isNil_whenNoSunsetOccurs() {
        
        let solar = Solar(for: testDate, coordinate: CLLocationCoordinate2D(latitude: 78.2186, longitude: 15.64007)) // Location: Longyearbyen
        XCTAssertNotNil(solar)
        XCTAssertNil(solar?.sunset)
    }
    
    func testIsDayTime_isTrue_betweenSunriseAndSunset() {
        let daytime = Date(timeIntervalSince1970: 1486641600) // noon
        let city = cities.first(where: { $0.name == "London" })!
        
        guard
            let solar = Solar(for: daytime, coordinate: city.coordinate)
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
            let solar = Solar(for: sunrise, coordinate: city.coordinate)
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
            let solar = Solar(for: sunset, coordinate: city.coordinate)
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
            let solar = Solar(for: beforeSunrise, coordinate: city.coordinate)
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
            let solar = Solar(for: afterSunset, coordinate: city.coordinate)
        else {
            XCTFail("Cannot get solar")
            return
        }
        
        XCTAssertFalse(solar.isDaytime, "isDaytime is true for date: \(afterSunset) with sunrise: \(solar.sunrise!), sunset: \(solar.sunset!)")
        XCTAssertTrue(solar.isNighttime, "isNighttime is false for date: \(afterSunset) with sunrise: \(solar.sunrise!), sunset: \(solar.sunset!)")
    }

    func testSolar_ShouldReturnNilOnInit_GivenInvalidcoordinate() {
        
        let invalidCoordinate1 = CLLocationCoordinate2D(latitude: -100, longitude: 0)
        XCTAssertFalse(CLLocationCoordinate2DIsValid(invalidCoordinate1))
        let solar1 = Solar(for: testDate, coordinate: invalidCoordinate1)
        XCTAssertNil(solar1)
        
        let invalidCoordinate2 = CLLocationCoordinate2D(latitude: 180, longitude: 190)
        XCTAssertFalse(CLLocationCoordinate2DIsValid(invalidCoordinate2))
        let solar2 = Solar(for: testDate, coordinate: invalidCoordinate2)
        XCTAssertNil(solar2)
    }
}
