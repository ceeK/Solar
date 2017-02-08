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

public final class Solar: NSObject {
    
    /// The timezone for the Solar object
    public fileprivate(set) var timeZone: TimeZone = .autoupdatingCurrent
    
    /// The latitude that is used for the calculation
    public fileprivate(set) var latitude: Double = 0
    
    /// The longitude that is used for the calculation
    public fileprivate(set) var longitude: Double = 0
    
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
    
    /// Whether the location specified by the `latitude` and `longitude` is in daytime on `date`
    /// - Complexity: O(1)
    public var isDaytime: Bool {
        let beginningOfDay = sunrise?.timeIntervalSince1970
        let endOfDay = sunset?.timeIntervalSince1970
        let currentTime = Date().timeIntervalSince1970
        
        if currentTime >= beginningOfDay && currentTime <= endOfDay {
            return true
        }
        return false
    }
    
    /// Whether the location specified by the `latitude` and `longitude` is in nighttime on `date`
    /// - Complexity: O(1)
    public var isNighttime: Bool {
        return !isDaytime
    }
    
    // MARK: Init
    
    public init?(forDate date: Date = Date(), withTimeZone timeZone: TimeZone = .autoupdatingCurrent, latitude: Double, longitude: Double) {
        self.date = date
        self.timeZone = timeZone
        self.latitude = latitude
        self.longitude = longitude
        super.init()
        
        guard latitude >= -90.0 && latitude <= 90.0 else {
            return nil
        }
        
        guard longitude >= -180.0 && longitude <= 180.0 else {
            return nil
        }
        
        // Fill this Solar object with relevant data
        calculate()
    }
    
    // MARK: - Public functions
    
    /// Sets all of the Solar object's sunrise / sunset variables, if possible.
    /// - Note: Can return `nil` objects if sunrise / sunset does not occur on that day.
    public func calculate() {
        sunrise = calculate(.sunrise, forDate: date, andZenith: .official)
        sunset = calculate(.sunset, forDate: date, andZenith: .official)
        civilSunrise = calculate(.sunrise, forDate: date, andZenith: .civil)
        civilSunset = calculate(.sunset, forDate: date, andZenith: .civil)
        nauticalSunrise = calculate(.sunrise, forDate: date, andZenith: .nautical)
        nauticalSunset = calculate(.sunset, forDate: date, andZenith: .nautical)
        astronomicalSunrise = calculate(.sunrise, forDate: date, andZenith: .astronimical)
        astronomicalSunset = calculate(.sunset, forDate: date, andZenith: .astronimical)
    }
    
    // MARK: - Private functions
    
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
    
    fileprivate func calculate(_ sunriseSunset: SunriseSunset, forDate date: Date, andZenith zenith: Zenith) -> Date? {
        guard let utcTimezone = TimeZone(identifier: "UTC") else { return nil }
        
        // Get the day of the year
        var calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        calendar.timeZone = utcTimezone
        guard let dayInt = calendar.ordinality(of: .day, in: .year, for: date) else { return nil }
        let day = Double(dayInt)
        
        // Convert longitude to hour value and calculate an approx. time
        let lngHour = longitude / 15
        
        let hourTime: Double = sunriseSunset == .sunrise ? 6 : 18
        let t = day + ((hourTime - lngHour) / 24)
        
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
        let cosDec = cos(asin(sinDec))
        
        // Calculate the Sun's local hour angle
        let cosH = (cos(zenith.rawValue.degreesToRadians) - (sinDec * sin(latitude.degreesToRadians))) / (cosDec * cos(latitude.degreesToRadians))
        
        // No sunrise
        guard cosH < 1 else {
            return nil
        }
        
        // No sunset
        guard cosH > -1 else {
            return nil
        }
        
        // Finish calculating H and convert into hours
        let tempH = sunriseSunset == .sunrise ? 360 - acos(cosH).radiansToDegrees : acos(cosH).radiansToDegrees
        let H = tempH / 15.0
        
        // Calculate local mean time of rising
        let T = H + RA - (0.06571 * t) - 6.622
        
        // Adjust time back to UTC
        var UT = T - lngHour
        
        // Normalise UT into [0, 24] range
        UT = normalise(UT, withMaximum: 24)
        
        // Convert UT value to local time zone of lat/long provided
        var localT = UT + (Double(timeZone.secondsFromGMT(for: date)) / 3600.0)
        
        // As applying the offset can push localT above 24 or below 0, we need to normalise
        localT = normalise(localT, withMaximum: 24)
        
        // Calculate all of the sunrise's / sunset's date components
        let hour = floor(localT)
        let minute = floor((localT - hour) * 60.0)
        let second = (((localT - hour) * 60) - minute) * 60.0
        
        var components = calendar.dateComponents([.day, .month, .year], from: date)
        components.hour = Int(hour)
        components.minute = Int(minute)
        components.second = Int(second)
        
        calendar.timeZone = timeZone
        return calendar.date(from: components)
    }
    
    /// Normalises a value between 0 and `maximum`, by adding or subtracting `maximum`
    fileprivate func normalise(_ value: Double, withMaximum maximum: Double) -> Double {
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
        return Double(self) * (M_PI / 180.0)
    }
    
    var radiansToDegrees: Double {
        return (Double(self) * 180.0) / M_PI
    }
}

/// Added these functions to support comparison between optional types
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

fileprivate func >= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l >= r
    default:
        return !(lhs < rhs)
    }
}

fileprivate func <= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l <= r
    default:
        return !(rhs < lhs)
    }
}

