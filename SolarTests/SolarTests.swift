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
        let solar = Solar(for: Self.testDate, coordinate: Self.longyearbyen)
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
        let solar = Solar(for: Self.testDate, coordinate: Self.longyearbyen)
        #expect(solar != nil)
        #expect(solar?.sunset == nil)
    }

    // MARK: - Consistency between published times and isDaytime
    //
    // A published sunrise is the first whole second at which the sun is up, and a
    // published sunset the first whole second at which it is no longer up, so
    // isDaytime must flip exactly at the published instants — for every location,
    // including the high latitudes where the sun grazes the horizon.

    /// Asserts isDaytime flips exactly at `event`: it matches `rising` at the event
    /// and is opposite one second before.
    private func expectExactFlip(rising: Bool, at event: Date, coordinate: CLLocationCoordinate2D, label: String) throws {
        let atEvent = try #require(Solar(for: event, coordinate: coordinate))
        let justBefore = try #require(Solar(for: event.addingTimeInterval(-1), coordinate: coordinate))

        #expect(atEvent.isDaytime == rising, "\(label): isDaytime is \(atEvent.isDaytime) at the published event \(event)")
        #expect(justBefore.isDaytime != rising, "\(label): isDaytime is \(justBefore.isDaytime) a second before the published event \(event)")
    }

    @Test("isDaytime flips exactly at the published sunrise", arguments: cities)
    func isDaytimeFlipsExactlyAtPublishedSunrise(for city: City) throws {
        let solar = try #require(Solar(for: Self.testDate, coordinate: city.coordinate))
        let sunrise = try #require(solar.sunrise)

        try expectExactFlip(rising: true, at: sunrise, coordinate: city.coordinate, label: city.name)
    }

    @Test("isDaytime flips exactly at the published sunset", arguments: cities)
    func isDaytimeFlipsExactlyAtPublishedSunset(for city: City) throws {
        let solar = try #require(Solar(for: Self.testDate, coordinate: city.coordinate))
        let sunset = try #require(solar.sunset)

        try expectExactFlip(rising: false, at: sunset, coordinate: city.coordinate, label: city.name)
    }

    /// Regimes that pin the bisection's endpoint and year-mapping behaviour:
    /// grazing crossings near the polar circles, the near-pole equinox, a solar day
    /// straddling UTC midnight at the antimeridian, and an event landing in the
    /// previous calendar year.
    struct HardCase: CustomStringConvertible {
        let name: String
        let coordinate: CLLocationCoordinate2D
        let date: Date
        var description: String { name }

        init(_ name: String, _ latitude: Double, _ longitude: Double, _ epoch: TimeInterval) {
            self.name = name
            self.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            self.date = Date(timeIntervalSince1970: epoch)
        }
    }

    private static let antimeridianMidwinter = HardCase("Antimeridian, midwinter", 69.93, -180.0, 1737028800) // 2025-01-16 12:00 UTC

    private static let hardCases: [HardCase] = [
        HardCase("Arctic circle, midwinter", 67.5, 0.0, 1735732800),        // 2025-01-01 12:00 UTC
        HardCase("Near-pole, equinox", 89.5, -150.0, 1742212800),           // 2025-03-17 12:00 UTC
        antimeridianMidwinter,
        HardCase("Cross-year sunrise", -62.5, 90.0, 1735732800),            // 2025-01-01 12:00 UTC
    ]

    @Test("isDaytime flips exactly at the published events in hard cases", arguments: hardCases)
    func isDaytimeFlipsExactlyAtPublishedEventsInHardCases(for hardCase: HardCase) throws {
        let solar = try #require(Solar(for: hardCase.date, coordinate: hardCase.coordinate))
        let sunrise = try #require(solar.sunrise, "\(hardCase.name): no sunrise published")
        let sunset = try #require(solar.sunset, "\(hardCase.name): no sunset published")

        try expectExactFlip(rising: true, at: sunrise, coordinate: hardCase.coordinate, label: hardCase.name)
        try expectExactFlip(rising: false, at: sunset, coordinate: hardCase.coordinate, label: hardCase.name)
    }

    private static let utcCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    @Test("Events near the antimeridian are attributed to the correct UTC day")
    func eventsNearAntimeridianAreAttributedToCorrectUTCDay() throws {
        // 69.93°N, 180°W on 2025-01-16: the local solar day straddles UTC midnight, and
        // a single-wrap normalisation used to push the sunrise onto 2025-01-17 (~11 min
        // late). The true crossing is late on the 16th.
        let hardCase = Self.antimeridianMidwinter

        let solar = try #require(Solar(for: hardCase.date, coordinate: hardCase.coordinate))
        let sunrise = try #require(solar.sunrise)

        #expect(Self.utcCalendar.component(.day, from: sunrise) == 16, "sunrise \(sunrise) attributed to the wrong UTC day")
    }

    // MARK: - Year boundary
    //
    // An event can land in the adjacent calendar year: a Tokyo sunrise on 1 Jan falls
    // on 31 Dec UTC, a Los Angeles sunset on 31 Dec falls on 1 Jan UTC.

    private static let losAngeles = CLLocationCoordinate2D(latitude: 34.05, longitude: -118.24)

    @Test("Sunrise is published when it falls in the previous calendar year")
    func sunriseIsPublishedWhenItFallsInPreviousYear() throws {
        // Tokyo, 2021-01-01 12:00 UTC — sunrise is 2020-12-31 ~21:51 UTC.
        let newYearsDay = Date(timeIntervalSince1970: 1609502400)

        let solar = try #require(Solar(for: newYearsDay, coordinate: Self.tokyo))

        #expect(solar.sunrise != nil, "sunrise is nil on \(newYearsDay)")
        #expect(solar.civilSunrise != nil, "civilSunrise is nil on \(newYearsDay)")
    }

    @Test("Sunset is published when it falls in the next calendar year")
    func sunsetIsPublishedWhenItFallsInNextYear() throws {
        // Los Angeles, 2021-12-31 12:00 UTC — sunset is 2022-01-01 ~00:53 UTC.
        let newYearsEve = Date(timeIntervalSince1970: 1640952000)

        let solar = try #require(Solar(for: newYearsEve, coordinate: Self.losAngeles))

        #expect(solar.sunset != nil, "sunset is nil on \(newYearsEve)")
        #expect(solar.civilSunset != nil, "civilSunset is nil on \(newYearsEve)")
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

    // MARK: - UTC day boundary
    //
    // For locations west of Greenwich in the evening (and east of Greenwich in the
    // morning), the local solar day straddles UTC midnight. isDaytime must reflect
    // whether the sun is actually up at `date`, not whether `date` falls within the
    // sunrise/sunset window of its UTC calendar day.

    private static let minneapolis = CLLocationCoordinate2D(latitude: 44.9778, longitude: -93.2650)
    private static let tokyo = CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503)

    @Test("isDaytime is true before sunset when the UTC day is already tomorrow")
    func isDaytimeIsTrueBeforeSunsetWhenUTCDayIsAlreadyTomorrow() throws {
        // Minneapolis, 2026-06-15 20:30 CDT (2026-06-16 01:30 UTC).
        // The sun is up until ~21:02 CDT (~02:02 UTC), but in UTC the date is already June 16.
        let eveningSunUp = Date(timeIntervalSince1970: 1781573400)

        let solar = try #require(Solar(for: eveningSunUp, coordinate: Self.minneapolis))

        #expect(solar.isDaytime, "isDaytime is false for date: \(eveningSunUp) with sunrise: \(solar.sunrise!), sunset: \(solar.sunset!)")
        #expect(!solar.isNighttime, "isNighttime is true for date: \(eveningSunUp) with sunrise: \(solar.sunrise!), sunset: \(solar.sunset!)")
    }

    @Test("isDaytime is false after sunset when the UTC day is already tomorrow")
    func isDaytimeIsFalseAfterSunsetWhenUTCDayIsAlreadyTomorrow() throws {
        // Minneapolis, 2026-06-15 21:30 CDT (2026-06-16 02:30 UTC), shortly after the ~21:02 CDT sunset.
        let eveningSunDown = Date(timeIntervalSince1970: 1781577000)

        let solar = try #require(Solar(for: eveningSunDown, coordinate: Self.minneapolis))

        #expect(!solar.isDaytime, "isDaytime is true for date: \(eveningSunDown) with sunrise: \(solar.sunrise!), sunset: \(solar.sunset!)")
        #expect(solar.isNighttime, "isNighttime is false for date: \(eveningSunDown) with sunrise: \(solar.sunrise!), sunset: \(solar.sunset!)")
    }

    @Test("isDaytime is true after sunrise when the UTC day is still yesterday")
    func isDaytimeIsTrueAfterSunriseWhenUTCDayIsStillYesterday() throws {
        // Tokyo, 2026-06-16 08:30 JST (2026-06-15 23:30 UTC).
        // The sun rose at ~04:25 JST, but in UTC the date is still June 15.
        let morningSunUp = Date(timeIntervalSince1970: 1781566200)

        let solar = try #require(Solar(for: morningSunUp, coordinate: Self.tokyo))

        #expect(solar.isDaytime, "isDaytime is false for date: \(morningSunUp) with sunrise: \(solar.sunrise!), sunset: \(solar.sunset!)")
        #expect(!solar.isNighttime, "isNighttime is true for date: \(morningSunUp) with sunrise: \(solar.sunrise!), sunset: \(solar.sunset!)")
    }

    @Test("isDaytime is false before sunrise when the UTC day is still yesterday")
    func isDaytimeIsFalseBeforeSunriseWhenUTCDayIsStillYesterday() throws {
        // Tokyo, 2026-06-16 02:30 JST (2026-06-15 17:30 UTC), well before the ~04:25 JST sunrise.
        let nightBeforeSunrise = Date(timeIntervalSince1970: 1781544600)

        let solar = try #require(Solar(for: nightBeforeSunrise, coordinate: Self.tokyo))

        #expect(!solar.isDaytime, "isDaytime is true for date: \(nightBeforeSunrise) with sunrise: \(solar.sunrise!), sunset: \(solar.sunset!)")
        #expect(solar.isNighttime, "isNighttime is false for date: \(nightBeforeSunrise) with sunrise: \(solar.sunrise!), sunset: \(solar.sunset!)")
    }

    // MARK: - Polar day / polar night
    //
    // Above the polar circles there are days with no sunrise/sunset at all. `sunrise`
    // and `sunset` are nil on such days, but isDaytime must still reflect reality:
    // true all day during polar day (midnight sun), false all day during polar night.

    /// Lofoten, Norway (67.95°N) — above the Arctic Circle, 24h daylight in early June.
    /// Coordinates and date taken from the report in issue #59.
    private static let lofoten = CLLocationCoordinate2D(latitude: 67.94753132376813, longitude: 13.131613209843637)

    /// Longyearbyen, Svalbard (78.22°N) — polar night in early February.
    private static let longyearbyen = CLLocationCoordinate2D(latitude: 78.2186, longitude: 15.64007)

    @Test("isDaytime is true during polar day")
    func isDaytimeIsTrueDuringPolarDay() throws {
        // Lofoten, 2022-06-03 06:00 UTC. The sun does not set at all on this date.
        let polarDayMorning = Date(timeIntervalSince1970: 1654236000)

        let solar = try #require(Solar(for: polarDayMorning, coordinate: Self.lofoten))

        #expect(solar.isDaytime, "isDaytime is false during polar day for date: \(polarDayMorning)")
        #expect(!solar.isNighttime, "isNighttime is true during polar day for date: \(polarDayMorning)")
    }

    @Test("isDaytime is true at local midnight during polar day")
    func isDaytimeIsTrueAtLocalMidnightDuringPolarDay() throws {
        // Lofoten, 2022-06-03 22:00 UTC (midnight CEST) — midnight sun, the sun is still up.
        let midnightSun = Date(timeIntervalSince1970: 1654293600)

        let solar = try #require(Solar(for: midnightSun, coordinate: Self.lofoten))

        #expect(solar.isDaytime, "isDaytime is false under the midnight sun for date: \(midnightSun)")
        #expect(!solar.isNighttime, "isNighttime is true under the midnight sun for date: \(midnightSun)")
    }

    /// West Greenland (67.0°N, 50.0°W, near Kangerlussuaq) — chosen because its entry into
    /// polar day in 2022 produces a rare mixed day: 2022-06-02 has a final sunrise at
    /// 03:21 UTC but no sunset, after which the sun stays up.
    private static let westGreenland = CLLocationCoordinate2D(latitude: 67.0, longitude: -50.0)

    @Test("isDaytime is true after the final sunrise on the first day of polar day")
    func isDaytimeIsTrueAfterFinalSunriseOnFirstDayOfPolarDay() throws {
        // West Greenland, 2022-06-02 12:00 UTC — after the day's 03:21 UTC sunrise,
        // and the sun will not set again.
        let afterFinalSunrise = Date(timeIntervalSince1970: 1654171200)

        let solar = try #require(Solar(for: afterFinalSunrise, coordinate: Self.westGreenland))

        #expect(solar.isDaytime, "isDaytime is false after the final sunrise for date: \(afterFinalSunrise)")
        #expect(!solar.isNighttime, "isNighttime is true after the final sunrise for date: \(afterFinalSunrise)")
    }

    @Test("isDaytime is true late on the first day of polar day")
    func isDaytimeIsTrueLateOnFirstDayOfPolarDay() throws {
        // West Greenland, 2022-06-02 23:00 UTC. The sun rose at 03:21 UTC and never set;
        // the following UTC days are fully polar, so no adjacent day supplies a window.
        let lateEvening = Date(timeIntervalSince1970: 1654210800)

        let solar = try #require(Solar(for: lateEvening, coordinate: Self.westGreenland))

        #expect(solar.isDaytime, "isDaytime is false late on the first polar day for date: \(lateEvening)")
        #expect(!solar.isNighttime, "isNighttime is true late on the first polar day for date: \(lateEvening)")
    }

    @Test("isDaytime is true before the first sunset on the last day of polar day")
    func isDaytimeIsTrueBeforeFirstSunsetOnLastDayOfPolarDay() throws {
        // Lofoten, 2022-07-17 12:00 UTC. The sun has been up for weeks; the first sunset
        // in weeks comes at 22:57 UTC, so midday has no sunrise yet must be daytime.
        let middayBeforeFirstSunset = Date(timeIntervalSince1970: 1658059200)

        let solar = try #require(Solar(for: middayBeforeFirstSunset, coordinate: Self.lofoten))

        #expect(solar.isDaytime, "isDaytime is false before the first sunset for date: \(middayBeforeFirstSunset)")
        #expect(!solar.isNighttime, "isNighttime is true before the first sunset for date: \(middayBeforeFirstSunset)")
    }

    @Test("isDaytime is false after the first sunset on the last day of polar day")
    func isDaytimeIsFalseAfterFirstSunsetOnLastDayOfPolarDay() throws {
        // Lofoten, 2022-07-17 23:15 UTC — inside the first night in weeks, between the
        // 22:57 UTC sunset and the ~23:40 UTC sunrise of the next solar day.
        let firstNight = Date(timeIntervalSince1970: 1658099700)

        let solar = try #require(Solar(for: firstNight, coordinate: Self.lofoten))

        #expect(!solar.isDaytime, "isDaytime is true during the first night for date: \(firstNight)")
        #expect(solar.isNighttime, "isNighttime is false during the first night for date: \(firstNight)")
    }

    @Test("isDaytime is false at midday during polar night")
    func isDaytimeIsFalseAtMiddayDuringPolarNight() throws {
        // Longyearbyen, 2017-02-09 12:00 UTC (~13:00 local). The sun does not rise at all on
        // this date, so even at midday it is not daytime.
        let polarNightMidday = Date(timeIntervalSince1970: 1486641600)

        let solar = try #require(Solar(for: polarNightMidday, coordinate: Self.longyearbyen))

        #expect(!solar.isDaytime, "isDaytime is true during polar night for date: \(polarNightMidday)")
        #expect(solar.isNighttime, "isNighttime is false during polar night for date: \(polarNightMidday)")
    }

    // MARK: Polar night transition days
    //
    // Entering and leaving polar night also produces mixed days, where the sun is up
    // only for a short sliver around solar noon: on the last day of polar night the
    // sunrise calculation still reports "sun never rises" while a real sunset exists,
    // and on the first day the reverse. The sliver must read as daytime, but the rest
    // of those days must remain night.

    /// Siberia near Norilsk (69.1°N, 90.0°E) — leaves polar night on 2021-01-12, when the
    /// algorithm finds no sunrise but a real sunset at 06:29 UTC. The implied daylight
    /// sliver (~05:55–06:29 UTC) is ~34 minutes, wide enough to test its midpoint with
    /// a margin well beyond the algorithm's ~5 minute accuracy.
    private static let norilsk = CLLocationCoordinate2D(latitude: 69.1, longitude: 90.0)

    /// Norwegian Sea off Andøya (69.5°N, 15.0°E) — enters polar night on 2021-11-28, when
    /// the algorithm finds a real sunrise at 10:26 UTC but no sunset. The implied daylight
    /// sliver (~10:26–11:01 UTC) is ~35 minutes.
    private static let andoya = CLLocationCoordinate2D(latitude: 69.5, longitude: 15.0)

    @Test("isDaytime is true during the daylight sliver on the last day of polar night")
    func isDaytimeIsTrueDuringDaylightSliverOnLastDayOfPolarNight() throws {
        // Norilsk, 2021-01-12 06:12 UTC — the midpoint of the day's ~34 minute daylight
        // sliver, ~17 minutes from either edge.
        let insideSliver = Date(timeIntervalSince1970: 1610431920)

        let solar = try #require(Solar(for: insideSliver, coordinate: Self.norilsk))

        #expect(solar.isDaytime, "isDaytime is false inside the daylight sliver for date: \(insideSliver)")
        #expect(!solar.isNighttime, "isNighttime is true inside the daylight sliver for date: \(insideSliver)")
    }

    @Test("isDaytime is false in the morning on the last day of polar night")
    func isDaytimeIsFalseInMorningOnLastDayOfPolarNight() throws {
        // Norilsk, 2021-01-12 03:00 UTC — hours before the daylight sliver begins.
        // Guards against recovering the sliver by treating the whole day as daytime.
        let darkMorning = Date(timeIntervalSince1970: 1610420400)

        let solar = try #require(Solar(for: darkMorning, coordinate: Self.norilsk))

        #expect(!solar.isDaytime, "isDaytime is true in the dark morning for date: \(darkMorning)")
        #expect(solar.isNighttime, "isNighttime is false in the dark morning for date: \(darkMorning)")
    }

    @Test("isDaytime is true during the daylight sliver on the first day of polar night")
    func isDaytimeIsTrueDuringDaylightSliverOnFirstDayOfPolarNight() throws {
        // Andøya, 2021-11-28 10:43 UTC — the midpoint of the day's ~35 minute daylight
        // sliver, ~17 minutes from either edge.
        let insideSliver = Date(timeIntervalSince1970: 1638096180)

        let solar = try #require(Solar(for: insideSliver, coordinate: Self.andoya))

        #expect(solar.isDaytime, "isDaytime is false inside the daylight sliver for date: \(insideSliver)")
        #expect(!solar.isNighttime, "isNighttime is true inside the daylight sliver for date: \(insideSliver)")
    }

    @Test("isDaytime is false in the morning on the first day of polar night")
    func isDaytimeIsFalseInMorningOnFirstDayOfPolarNight() throws {
        // Andøya, 2021-11-28 07:00 UTC — hours before the 10:26 UTC sunrise.
        let darkMorning = Date(timeIntervalSince1970: 1638082800)

        let solar = try #require(Solar(for: darkMorning, coordinate: Self.andoya))

        #expect(!solar.isDaytime, "isDaytime is true in the dark morning for date: \(darkMorning)")
        #expect(solar.isNighttime, "isNighttime is false in the dark morning for date: \(darkMorning)")
    }

    @Test("isDaytime is true when polar day daylight crosses UTC midnight into a transition day")
    func isDaytimeIsTrueWhenPolarDayDaylightCrossesUTCMidnightIntoTransitionDay() throws {
        // Antarctica (78.13°S, 146.32°W), 2026-02-20 02:00 UTC — local solar afternoon at the
        // tail of polar day. The previous UTC day is full polar day and this UTC day's first
        // sunset comes hours later, so the continuous daylight spans the UTC midnight between
        // a polar day and a transition day. Found by fuzzing against a solar elevation oracle.
        let daylightAcrossMidnight = Date(timeIntervalSince1970: 1771552800)
        let antarctica = CLLocationCoordinate2D(latitude: -78.13, longitude: -146.32)

        let solar = try #require(Solar(for: daylightAcrossMidnight, coordinate: antarctica))

        #expect(solar.isDaytime, "isDaytime is false while the sun is up for date: \(daylightAcrossMidnight)")
        #expect(!solar.isNighttime, "isNighttime is true while the sun is up for date: \(daylightAcrossMidnight)")
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
