<div align="center">
<img src="./solar-logo.png" />
</div>

# Solar

[![Version](https://img.shields.io/cocoapods/v/Solar.svg?style=flat)](http://cocoapods.org/pods/Solar) [![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage) [![Build Status](https://travis-ci.org/ceeK/Solar.svg?branch=master)](https://travis-ci.org/ceeK/Solar)
 [![MIT licensed](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/hyperium/hyper/master/LICENSE)

A Swift helper for generating Sunrise and Sunset times. 

Solar performs its calculations locally using an algorithm from the [United States Naval Observatory](http://williams.best.vwh.net/sunrise_sunset_algorithm.htm), and thus does not require the use of a network.

## Usage

Solar simply needs a date and a location specified as a latitude and longitude:

```swift
let solar = Solar(for: someDate, latitude: 51.528308, longitude: -0.1340267)
let sunrise = solar.sunrise
let sunset = solar.sunset
```

We can also omit providing a date if we just need the sunrise and sunset for today:

```swift
let solar = Solar(latitude: 51.528308, longitude: -0.1340267)
let sunrise = solar.sunrise
let sunset = solar.sunset
```

Note that all dates are UTC. Don't forget to format your date into the appropriate timezone if required.

### Types of sunrise and sunset

There are several types of sunrise and sunset that Solar generates. They differ by how many degrees the sun lies below the horizon:

- **Official** (~0°)

- **Civil** (6° below horizon)

- **Nautical** (12° below horizon)

- **Astromonical** (18° below horizon)

For more information, see https://www.timeanddate.com/astronomy/different-types-twilight.html

## Convenience methods

Solar also comes packaged with some convenience methods:

```swift
// Whether the location specified by the `latitude` and `longitude` is in daytime on `date`
let isDaytime = solar.isDaytime

// Whether the location specified by the `latitude` and `longitude` is in nighttime on `date`
let isNighttime = solar.isNighttime
```

## Installation

Solar is available through CocoaPods and Carthage. 

### Cocoapods

To install, simply add the following line to your podfile:

```ruby
pod "Solar"
```

Then run `pod install`

### Carthage

Add the `ceek/Solar` project to your [Cartfile](https://github.com/Carthage/Carthage/blob/master/Documentation/Artifacts.md#cartfile)

```ruby
github "ceeK/Solar"
```

Then run `carthage update`

# License 

The MIT License (MIT)

Copyright (c) 2017 Chris Howell

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
