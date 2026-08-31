//
//  Solar.swift
//  SolarExample
//
//  Created by Chris Howell on 16/01/2016.
//  Copyright © 2016 Chris Howell. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the “Software”), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation
import CoreLocation

public struct Solar {
    
    /// The coordinate that is used for the calculation
    public let coordinate: CLLocationCoordinate2D
    
    /// The date to generate sunrise / sunset times for
    public fileprivate(set) var date: Date
    
    public fileprivate(set) var sunrise: Date?
    public fileprivate(set) var sunset: Date?
    public fileprivate(set) var civilSunrise: Date?
    public fileprivate(set) var civilSunset: Date?
    public fileprivate(set) var nauticalSunrise: Date?
    public fileprivate(set) var nauticalSunset: Date?
    public fileprivate(set) var astronomicalSunrise: Date?
    public fileprivate(set) var astronomicalSunset: Date?
    
    /// Whether the location is in daytime at `date`: the sun's elevation at that
    /// instant is above the official zenith. Because this asks about the instant
    /// directly, polar day, polar night, their transition days, and daylight
    /// spanning UTC midnight need no special cases. The published events are
    /// bisected from this same predicate, so isDaytime becomes true exactly at
    /// `sunrise` and false exactly at `sunset`.
    public var isDaytime: Bool {
        return sunIsUp(atEpoch: date.timeIntervalSince1970, above: .official)
    }

    /// Whether the location specified by the `latitude` and `longitude` is in nighttime on `date`
    public var isNighttime: Bool {
        return !isDaytime
    }

    /// Trigonometry of the immutable latitude, shared by every predicate evaluation.
    fileprivate let sinLatitude: Double
    fileprivate let cosLatitude: Double

    /// The day-of-year mapping for `date`'s year and its neighbours.
    fileprivate let yearMap: YearMap

    // MARK: Init

    public init?(for date: Date = Date(), coordinate: CLLocationCoordinate2D) {
        self.date = date

        guard CLLocationCoordinate2DIsValid(coordinate), let yearMap = YearMap(containing: date) else {
            return nil
        }

        self.coordinate = coordinate
        self.yearMap = yearMap
        let latitude = coordinate.latitude.degreesToRadians
        self.sinLatitude = sin(latitude)
        self.cosLatitude = cos(latitude)

        // Fill this Solar object with relevant data
        calculate()
    }
    
    // MARK: - Public functions
    
    /// Sets all of the Solar object's sunrise / sunset variables, if possible.
    /// - Note: Can return `nil` objects if sunrise / sunset does not occur on that day.
    public mutating func calculate() {
        // Anchor on the solar noon nearest the middle of `date`'s UTC day. Each event
        // is then the exact whole second the elevation predicate flips, found by
        // bisecting between solar midnight and solar noon; the transit itself is
        // zenith-independent, so one anchor serves all eight events.
        let dayOrdinal = floor(yearMap.t(forEpoch: date.timeIntervalSince1970))
        let transitT = solarTransitT(near: dayOrdinal + (12 - lngHour) / 24)
        let transitEpoch = floor(yearMap.epoch(forT: transitT))

        (sunrise, sunset) = events(at: .official, transitEpoch: transitEpoch)
        (civilSunrise, civilSunset) = events(at: .civil, transitEpoch: transitEpoch)
        (nauticalSunrise, nauticalSunset) = events(at: .nautical, transitEpoch: transitEpoch)
        (astronomicalSunrise, astronomicalSunset) = events(at: .astronimical, transitEpoch: transitEpoch)
    }
    
    // MARK: - Private functions
    
    fileprivate static let utcCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()
    
    fileprivate enum SunriseSunset {
        case sunrise
        case sunset
    }

    /// Used for generating several of the possible sunrise / sunset times
    fileprivate enum Zenith: Double {
        case official = 90.83
        case civil = 96
        case nautical = 102
        case astronimical = 108
    }
    
    /// The sun's position for an approximate time `t` (days since the start of the
    /// year, including the fraction of the day), per the USNO Almanac for Computers
    /// sunrise/sunset algorithm.
    fileprivate struct SunPosition {
        let rightAscension: Double   // hours
        let sinDeclination: Double
        let cosDeclination: Double
    }
    
    fileprivate static func sunPosition(forT t: Double) -> SunPosition {
        // Calculate the suns mean anomaly
        let M = (0.9856 * t) - 3.289
        
        // Calculate the sun's true longitude
        let subexpression1 = 1.916 * sin(M.degreesToRadians)
        let subexpression2 = 0.020 * sin(2 * M.degreesToRadians)
        var L = M + subexpression1 + subexpression2 + 282.634
        
        // Normalise L into [0, 360] range
        L = normalise(L, withMaximum: 360)
        
        // Calculate the Sun's right ascension
        var RA = atan(0.91764 * tan(L.degreesToRadians)).radiansToDegrees
        
        // Normalise RA into [0, 360] range
        RA = normalise(RA, withMaximum: 360)
        
        // Right ascension value needs to be in the same quadrant as L...
        let Lquadrant = floor(L / 90) * 90
        let RAquadrant = floor(RA / 90) * 90
        RA = RA + (Lquadrant - RAquadrant)
        
        // Convert RA into hours
        RA = RA / 15
        
        // Calculate Sun's declination
        let sinDec = 0.39782 * sin(L.degreesToRadians)
        return SunPosition(rightAscension: RA,
                           sinDeclination: sinDec,
                           cosDeclination: cos(asin(sinDec)))
    }
    
    /// Longitude expressed in hours of Earth rotation (15° per hour).
    fileprivate var lngHour: Double {
        return coordinate.longitude / 15
    }

    /// The almanac's clock relation, T = H + RA - siderealDrift * t - clockOffset,
    /// links a time of day to the sun's hour angle. `sunIsUp` and `solarTransitT`
    /// both invert it, so the constants are shared to keep them exact inverses.
    fileprivate static let siderealDrift = 0.06571
    fileprivate static let clockOffset = 6.622

    fileprivate static let secondsPerDay: TimeInterval = 86400

    /// Maps instants to the fractional day-of-year `t` the position model is
    /// parameterized on (1.0 = midnight starting 1 January), against the year that
    /// contains each instant — so an event published in an adjacent year agrees
    /// exactly with a fresh Solar built at it.
    fileprivate struct YearMap {
        let previous: TimeInterval
        let current: TimeInterval
        let next: TimeInterval

        init?(containing date: Date) {
            let year = Solar.utcCalendar.dateComponents([.year], from: date)
            guard
                let currentStart = Solar.utcCalendar.date(from: year),
                let previousStart = Solar.utcCalendar.date(byAdding: .year, value: -1, to: currentStart),
                let nextStart = Solar.utcCalendar.date(byAdding: .year, value: 1, to: currentStart)
                else {
                    return nil
            }
            previous = previousStart.timeIntervalSince1970
            current = currentStart.timeIntervalSince1970
            next = nextStart.timeIntervalSince1970
        }

        /// Whole seconds only, matching Date equality on the published events.
        func t(forEpoch epoch: TimeInterval) -> Double {
            let second = floor(epoch)
            let yearStart = second >= next ? next : (second >= current ? current : previous)
            return (second - yearStart) / Solar.secondsPerDay + 1
        }

        /// The inverse of `t(forEpoch:)`, on the year the map was built around.
        func epoch(forT t: Double) -> TimeInterval {
            return current + (t - 1) * Solar.secondsPerDay
        }
    }

    /// Whether the sun's elevation at the instant is above `zenith`.
    fileprivate func sunIsUp(atEpoch epoch: TimeInterval, above zenith: Zenith) -> Bool {
        return sunIsUp(atT: yearMap.t(forEpoch: epoch), above: zenith)
    }

    /// Whether the sun's elevation at `t` (a fractional day-of-year) is above `zenith`.
    fileprivate func sunIsUp(atT t: Double, above zenith: Zenith) -> Bool {
        let sun = Solar.sunPosition(forT: t)
        let ut = (t - floor(t)) * 24

        // The clock relation inverted: the sun's hour angle at this instant, where 0°
        // is solar noon. The drift term spans many multiples of 24, so take the
        // remainder before normalising.
        let drifted = (ut + lngHour) - sun.rightAscension + (Solar.siderealDrift * t) + Solar.clockOffset
        let H = Solar.normalise(drifted.truncatingRemainder(dividingBy: 24), withMaximum: 24)
        let hourAngle = (H * 15).degreesToRadians

        let sinElevation = sun.sinDeclination * sinLatitude + sun.cosDeclination * cosLatitude * cos(hourAngle)
        return sinElevation >= cos(zenith.rawValue.degreesToRadians)
    }

    /// The solar transit (solar noon) nearest `guess`, as a fractional day-of-year:
    /// the t at which the hour angle in `sunIsUp` vanishes. Right ascension drifts
    /// slowly, so two passes of the fixed point converge far below a second.
    fileprivate func solarTransitT(near guess: Double) -> Double {
        var t = guess
        for _ in 0..<2 {
            let target = Solar.sunPosition(forT: t).rightAscension - lngHour - Solar.clockOffset
            let cycles = (((24 + Solar.siderealDrift) * t - target) / 24).rounded()
            t = (target + 24 * cycles) / (24 + Solar.siderealDrift)
        }
        return t
    }

    /// The sunrise/sunset pair for one zenith, both bisected from the same anchor.
    fileprivate func events(at zenith: Zenith, transitEpoch: TimeInterval) -> (sunrise: Date?, sunset: Date?) {
        return (crossing(.sunrise, at: zenith, transitEpoch: transitEpoch),
                crossing(.sunset, at: zenith, transitEpoch: transitEpoch))
    }

    /// The published event around the solar noon at `transitEpoch`: the first whole
    /// second at which the sun is up (sunrise) or no longer up (sunset), found by
    /// bisecting the elevation predicate against solar midnight. Elevation rises from
    /// one solar midnight to noon and falls to the next, so a single crossing exists
    /// exactly when the endpoints disagree; when they agree the sun stays on one side
    /// of the zenith all day (polar day or night) and there is no event to publish.
    fileprivate func crossing(_ sunriseSunset: SunriseSunset, at zenith: Zenith, transitEpoch: TimeInterval) -> Date? {
        func afterEvent(_ epoch: TimeInterval) -> Bool {
            let isUp = sunIsUp(atEpoch: epoch, above: zenith)
            return sunriseSunset == .sunrise ? isUp : !isUp
        }

        let halfDay = Solar.secondsPerDay / 2
        var before = sunriseSunset == .sunrise ? transitEpoch - halfDay : transitEpoch
        var after = sunriseSunset == .sunrise ? transitEpoch : transitEpoch + halfDay

        guard !afterEvent(before), afterEvent(after) else {
            return nil
        }

        while after - before > 1 {
            let midpoint = ((before + after) / 2).rounded(.down)
            if afterEvent(midpoint) {
                after = midpoint
            } else {
                before = midpoint
            }
        }
        return Date(timeIntervalSince1970: after)
    }
    
    /// Normalises a value between 0 and `maximum`, by adding or subtracting `maximum`
    fileprivate static func normalise(_ value: Double, withMaximum maximum: Double) -> Double {
        var value = value
        
        if value < 0 {
            value += maximum
        }
        
        if value > maximum {
            value -= maximum
        }
        
        return value
    }
    
}

// MARK: - Helper extensions

private extension Double {
    var degreesToRadians: Double {
        return Double(self) * (Double.pi / 180.0)
    }
    
    var radiansToDegrees: Double {
        return (Double(self) * 180.0) / Double.pi
    }
}
