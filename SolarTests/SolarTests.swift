//
//  SolarTests.swift
//  SolarTests
//
//  Created by Chris Howell on 08/02/2017.
//  Copyright © 2017 Chris Howell. All rights reserved.
//

import Testing
import CoreLocation
@testable import Solar

struct SolarTests {

    private static let testDate = Date(timeIntervalSince1970: 1486598400)

    /// How accurate, in minutes either side of the actual sunrise sunset, we want to be
    /// This is necessary as the algorithm uses assumptions during calculation
    private static let testAccuracy: TimeInterval = 60 * 5

    private final class BundleToken {}

    private static let bundle: Bundle = {
        #if SWIFT_PACKAGE
        return Bundle.module
        #else
        return Bundle(for: BundleToken.self)
        #endif
    }()

    static let cities: [City] = {
        let resultsURL = bundle.url(forResource: "CorrectResults", withExtension: "json")!
        let data = try! Data(contentsOf: resultsURL)
        let cityDictionaries = try! JSONSerialization.jsonObject(with: data, options: []) as! [[String: Any]]
        return cityDictionaries.map(City.init(json:))
    }()

    @Test("Sunrise is close to expected time", arguments: cities)
    func sunrise(for city: City) throws {
        let solar = Solar(for: Self.testDate, coordinate: city.coordinate)

        let sunrise = try #require(solar?.sunrise, "Sunrise cannot be generated for city \(city.name)")

        #expect(abs(sunrise.timeIntervalSince1970 - city.sunrise.timeIntervalSince1970) <= Self.testAccuracy, "\(city.name): \(sunrise) not close to \(city.sunrise)")
    }

    @Test("Sunrise is nil when no sunrise occurs")
    func sunriseIsNilWhenNoSunriseOccurs() {
        let solar = Solar(for: Self.testDate, coordinate: CLLocationCoordinate2D(latitude: 78.2186, longitude: 15.64007)) // Location: Longyearbyen
        #expect(solar != nil)
        #expect(solar?.sunrise == nil)
    }

    @Test("Sunset is close to expected time", arguments: cities)
    func sunset(for city: City) throws {
        let solar = Solar(for: Self.testDate, coordinate: city.coordinate)

        let sunset = try #require(solar?.sunset, "Sunset cannot be generated for city \(city.name)")

        #expect(abs(sunset.timeIntervalSince1970 - city.sunset.timeIntervalSince1970) <= Self.testAccuracy, "\(city.name): \(sunset) not close to \(city.sunset)")
    }

    @Test("Sunset is nil when no sunset occurs")
    func sunsetIsNilWhenNoSunsetOccurs() {
        let solar = Solar(for: Self.testDate, coordinate: CLLocationCoordinate2D(latitude: 78.2186, longitude: 15.64007)) // Location: Longyearbyen
        #expect(solar != nil)
        #expect(solar?.sunset == nil)
    }

    @Test("isDaytime is true between sunrise and sunset")
    func isDaytimeIsTrueBetweenSunriseAndSunset() throws {
        let daytime = Date(timeIntervalSince1970: 1486641600) // noon
        let city = try #require(Self.cities.first(where: { $0.name == "London" }))

        let solar = try #require(Solar(for: daytime, coordinate: city.coordinate))

        #expect(solar.isDaytime, "isDaytime is false for date: \(daytime) with sunrise: \(solar.sunrise!), sunset: \(solar.sunset!)")
        #expect(!solar.isNighttime, "isNighttime is true for date: \(daytime) with sunrise: \(solar.sunrise!), sunset: \(solar.sunset!)")
    }

    @Test("isDaytime is true exactly at sunrise")
    func isDaytimeIsTrueExactlyAtSunrise() throws {
        let sunrise = Date(timeIntervalSince1970: 1486625181)
        let city = try #require(Self.cities.first(where: { $0.name == "London" }))

        let solar = try #require(Solar(for: sunrise, coordinate: city.coordinate))

        #expect(solar.isDaytime, "isDaytime is false for date: \(sunrise) with sunrise: \(solar.sunrise!), sunset: \(solar.sunset!)")
        #expect(!solar.isNighttime, "isNighttime is true for date: \(sunrise) with sunrise: \(solar.sunrise!), sunset: \(solar.sunset!)")
    }

    @Test("isDaytime is false exactly at sunset")
    func isDaytimeIsFalseExactlyAtSunset() throws {
        let sunset = Date(timeIntervalSince1970: 1486659846)
        let city = try #require(Self.cities.first(where: { $0.name == "London" }))

        let solar = try #require(Solar(for: sunset, coordinate: city.coordinate))

        #expect(!solar.isDaytime, "isDaytime is false for date: \(sunset) with sunrise: \(solar.sunrise!), sunset: \(solar.sunset!)")
        #expect(solar.isNighttime, "isNighttime is true for date: \(sunset) with sunrise: \(solar.sunrise!), sunset: \(solar.sunset!)")
    }

    @Test("isDaytime is false before sunrise")
    func isDaytimeIsFalseBeforeSunrise() throws {
        let beforeSunrise = Date(timeIntervalSince1970: 1486624980)
        let city = try #require(Self.cities.first(where: { $0.name == "London" }))

        let solar = try #require(Solar(for: beforeSunrise, coordinate: city.coordinate))

        #expect(!solar.isDaytime, "isDaytime is true for date: \(beforeSunrise) with sunrise: \(solar.sunrise!), sunset: \(solar.sunset!)")
        #expect(solar.isNighttime, "isNighttime is false for date: \(beforeSunrise) with sunrise: \(solar.sunrise!), sunset: \(solar.sunset!)")
    }

    @Test("isDaytime is false after sunset")
    func isDaytimeIsFalseAfterSunset() throws {
        let afterSunset = Date(timeIntervalSince1970: 1486659960)
        let city = try #require(Self.cities.first(where: { $0.name == "London" }))

        let solar = try #require(Solar(for: afterSunset, coordinate: city.coordinate))

        #expect(!solar.isDaytime, "isDaytime is true for date: \(afterSunset) with sunrise: \(solar.sunrise!), sunset: \(solar.sunset!)")
        #expect(solar.isNighttime, "isNighttime is false for date: \(afterSunset) with sunrise: \(solar.sunrise!), sunset: \(solar.sunset!)")
    }

    @Test("Solar init returns nil given an invalid coordinate")
    func solarInitReturnsNilGivenInvalidCoordinate() {
        let invalidCoordinate1 = CLLocationCoordinate2D(latitude: -100, longitude: 0)
        #expect(!CLLocationCoordinate2DIsValid(invalidCoordinate1))
        #expect(Solar(for: Self.testDate, coordinate: invalidCoordinate1) == nil)

        let invalidCoordinate2 = CLLocationCoordinate2D(latitude: 180, longitude: 190)
        #expect(!CLLocationCoordinate2DIsValid(invalidCoordinate2))
        #expect(Solar(for: Self.testDate, coordinate: invalidCoordinate2) == nil)
    }
}
