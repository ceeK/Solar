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

final class Solar: NSObject {
    
    /// The timezone for the Solar object
    private(set) var timeZone: NSTimeZone = NSTimeZone.localTimeZone()
    
    /// The latitude that is used for the calculation
    private(set) var latitude: Double = 0
    
    /// The longitude that is used for the calculation
    private(set) var longitude: Double = 0
    
    /// The date to generate sunrise / sunset times for
    private(set) var date: NSDate
    
    private(set) var sunrise: NSDate? = nil
    private(set) var sunset: NSDate? = nil
    private(set) var civilSunrise: NSDate? = nil
    private(set) var civilSunset: NSDate? = nil
    private(set) var nauticalSunrise: NSDate? = nil
    private(set) var nauticalSunset: NSDate? = nil
    private(set) var astronomicalSunrise: NSDate? = nil
    private(set) var astronomicalSunset: NSDate? = nil
    
    /// Whether the location specified by the `latitude` and `longitude` is in daytime on `date`
    /// - Complexity: O(1)
    var isDaytime: Bool {
        let beginningOfDay = sunrise?.timeIntervalSince1970
        let endOfDay = sunset?.timeIntervalSince1970
        let currentTime = NSDate().timeIntervalSince1970
        
        if currentTime >= beginningOfDay && currentTime <= endOfDay {
            return true
        }
        return false
    }
    
    /// Whether the location specified by the `latitude` and `longitude` is in nighttime on `date`
    /// - Complexity: O(1)
    var isNighttime: Bool {
        return !isDaytime
    }
    
    // MARK: Init
    
    init?(forDate date: NSDate = NSDate(), withTimeZone timeZone: NSTimeZone = NSTimeZone.localTimeZone(), latitude: Double, longitude: Double) {
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
    func calculate() {
        sunrise = calculate(.Sunrise, forDate: date, andZenith: .Official)
        sunset = calculate(.Sunset, forDate: date, andZenith: .Official)
        civilSunrise = calculate(.Sunrise, forDate: date, andZenith: .Civil)
        civilSunset = calculate(.Sunset, forDate: date, andZenith: .Civil)
        nauticalSunrise = calculate(.Sunrise, forDate: date, andZenith: .Nautical)
        nauticalSunset = calculate(.Sunset, forDate: date, andZenith: .Nautical)
        astronomicalSunrise = calculate(.Sunrise, forDate: date, andZenith: .Astronimical)
        astronomicalSunset = calculate(.Sunset, forDate: date, andZenith: .Astronimical)
    }
    
    // MARK: - Private functions
    
    private enum SunriseSunset {
        case Sunrise
        case Sunset
    }
    
    /// Used for generating several of the possible sunrise / sunset times
    private enum Zenith: Double {
        case Official = 90.83
        case Civil = 96
        case Nautical = 102
        case Astronimical = 108
    }
    
    private func calculate(sunriseSunset: SunriseSunset, forDate date: NSDate, andZenith zenith: Zenith) -> NSDate? {
        // Get the day of the year
        let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
        calendar.timeZone = timeZone
        let day = Double(calendar.ordinalityOfUnit(.Day, inUnit: .Year, forDate: date))
        
        // Convert longitude to hour value and calculate an approx. time
        let lngHour = longitude / 15
        
        let hourTime: Double = sunriseSunset == .Sunrise ? 6 : 18
        let t = day + ((hourTime - lngHour) / 24)
        
        // Calculate the suns mean anomaly
        let M = (0.9856 * t) - 3.289
        
        // Calculate the sun's true longitude
        var L = M + (1.916 * sin(M.degreesToRadians)) + (0.020 * sin(2 * M.degreesToRadians)) + 282.634
        
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
        let cosH = (cos(Zenith.Official.rawValue.degreesToRadians) - (sinDec * sin(latitude.degreesToRadians))) / (cosDec * cos(latitude.degreesToRadians))
        
        // No sunrise
        guard cosH < 1 else {
            return nil
        }
        
        // No sunset
        guard cosH > -1 else {
            return nil
        }
        
        // Finish calculating H and convert into hours
        let tempH = sunriseSunset == .Sunrise ? 360 - acos(cosH).radiansToDegrees : acos(cosH).radiansToDegrees
        let H = tempH / 15.0
        
        // Calculate local mean time of rising
        let T = H + RA - (0.06571 * t) - 6.622
        
        // Adjust time back to UTC
        var UT = T - lngHour
        
        // Normalise UT into [0, 24] range
        UT = normalise(UT, withMaximum: 24)
        
        // Convert UT value to local time zone of lat/long provided
        let localT = UT + (Double(timeZone.secondsFromGMT) / 3600.0)
        
        let hour = floor(localT)
        let minute = floor((localT - hour) * 60.0)
        let second = (((localT - hour) * 60) - minute) * 60.0
        
        let components = calendar.components([.Day, .Month, .Year], fromDate: date)
        components.hour = Int(hour)
        components.minute = Int(minute)
        components.second = Int(second)
        
        var date = calendar.dateFromComponents(components)
        
        // Add a day to account for potential timezone issues
        if sunriseSunset == .Sunset && date?.timeIntervalSince1970 < sunrise?.timeIntervalSince1970 {
            date = date?.dateByAddingTimeInterval(60 * 60 * 24)
        }
        
        return date
    }
    
    /// Normalises a value between 0 and `maximum`, by adding or subtracting `maximum`
    private func normalise(var value: Double, withMaximum maximum: Double) -> Double {
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