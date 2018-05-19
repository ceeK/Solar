//
//  Solar.swift
//  SolarExample
//
//  Created by Chris Howell on 16/01/2016.
//  Changed by Brandon Roehl on 02/05/2018.
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

public class Solar {
    
    /// The coordinate that is used for the calculation
    private let coordinate: CLLocationCoordinate2D
    private var date: Date?
    private var zenith: Zenith

    private var _sunrise: Date?
    public var sunrise: Date? {
        let date = self.date == nil ? Date() : self.date!

        if self._sunrise == nil || (self.date == nil && self._sunrise! < Date()) {
            self._sunrise = calculate(.sunrise, for: date, and: zenith)
        }

        return self._sunrise;
    }
    private var _sunset: Date?
    public var sunset: Date? {
        let date = self.date == nil ? Date() : self.date!

        if self._sunset == nil || (self.date == nil && self._sunset! < Date()) {
            self._sunset = calculate(.sunset, for: date, and: zenith)
        }

        return self._sunset;
    }
    
    // MARK: Init
    
    public init?(for date: Date? = nil, coordinate: CLLocationCoordinate2D, and zenith: Zenith = .official) {
        self.date = date
        self.zenith = zenith
        
        guard CLLocationCoordinate2DIsValid(coordinate) else {
            return nil
        }
        
        self.coordinate = coordinate
        
        // Fill this Solar object with relevant data
        self.calculate()
    }
    
    // MARK: - Public functions
    
    /// Sets all of the Solar object's sunrise / sunset variables, if possible.
    /// - Note: Can return `nil` objects if sunrise / sunset does not occur on that day.
    public func calculate() {
        self._sunrise = nil
        self._sunrise = nil
    }
    
    // MARK: - Private functions
    
    public enum SunriseSunset {
        case sunrise
        case sunset
    }
    
    /// Used for generating several of the possible sunrise / sunset times
    public enum Zenith: Double {
        case official = 90.83
        case civil = 96
        case nautical = 102
        case astronimical = 108
    }
    
    fileprivate func calculate(_ sunriseSunset: SunriseSunset, for date: Date, and zenith: Zenith) -> Date? {
        return Solar.calculate(sunriseSunset, at: coordinate, for: date, and: zenith)
    }

    public static func calculate(_ sunriseSunset: SunriseSunset, at coordinate: CLLocationCoordinate2D, for date: Date, and zenith: Zenith) -> Date? {
        guard let utcTimezone = TimeZone(identifier: "UTC") else { return nil }
        
        // Get the day of the year
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = utcTimezone
        guard let dayInt = calendar.ordinality(of: .day, in: .year, for: date) else { return nil }
        let day = Double(dayInt)
        
        // Convert longitude to hour value and calculate an approx. time
        let lngHour = coordinate.longitude / 15
        
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
        let cosH = (cos(zenith.rawValue.degreesToRadians) - (sinDec * sin(coordinate.latitude.degreesToRadians))) / (cosDec * cos(coordinate.latitude.degreesToRadians))
        
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
        UT = Solar.normalise(UT, withMaximum: 24)
        
        // Calculate all of the sunrise's / sunset's date components
        let hour = floor(UT)
        let minute = floor((UT - hour) * 60.0)
        let second = (((UT - hour) * 60) - minute) * 60.0
        
        let shouldBeYesterday = lngHour > 0 && UT > 12 && sunriseSunset == .sunrise
        let shouldBeTomorrow = lngHour < 0 && UT < 12 && sunriseSunset == .sunset
        
        let setDate: Date
        if shouldBeYesterday {
            setDate = Date(timeInterval: -(60 * 60 * 24), since: date)
        } else if shouldBeTomorrow {
            setDate = Date(timeInterval: (60 * 60 * 24), since: date)
        } else {
            setDate = date
        }
        
        var components = calendar.dateComponents([.day, .month, .year], from: setDate)
        components.hour = Int(hour)
        components.minute = Int(minute)
        components.second = Int(second)
        
        calendar.timeZone = utcTimezone
        return calendar.date(from: components)
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

    public enum Cycle {
        case day
        case night
    }

    /// Whether the location specified by the `latitude` and `longitude` is in daytime on `date`
    /// - Complexity: O(1)
    public var currentCycle: Cycle {

        guard let sunrise = sunrise, let sunset = sunset else {
            return .day
        }

        // Get the seconds of the begining of the day
        let beginningOfDay = sunrise.timeIntervalSince1970.truncatingRemainder(dividingBy: 86400)

        // Set the beginging of the day to zero
        let endOfDay = sunset.timeIntervalSince1970.advanced(by: -(beginningOfDay)).truncatingRemainder(dividingBy: 86400)
        let currentTime = (self.date == nil ? Date() : self.date!).timeIntervalSince1970.advanced(by: -(beginningOfDay)).truncatingRemainder(dividingBy: 86400)

        return currentTime < endOfDay ? .day : .night
    }

    public var isDaytime: Bool {
        return self.currentCycle == .day
    }
    
    /// Whether the location specified by the `latitude` and `longitude` is in nighttime on `date`
    /// - Complexity: O(1)
    public var isNighttime: Bool {
        return self.currentCycle == .night
    }
    
}

// MARK: - Helper extensions

fileprivate extension Double {
    var degreesToRadians: Double {
        return Double(self) * (Double.pi / 180.0)
    }
    
    var radiansToDegrees: Double {
        return (Double(self) * 180.0) / Double.pi
    }
}
