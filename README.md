<div align="center">
<img src="./solar-logo.png" />
</div>

# Solar

[![Version](https://img.shields.io/cocoapods/v/Solar.svg?style=flat)](http://cocoapods.org/pods/Solar) [![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage) [![POD compatible](https://img.shields.io/badge/Cocoapods-compatible-4BC51D.svg?style=flat)](https://cocoapods.org) [![SPM compatible](https://img.shields.io/badge/SPM-compatible-4BC51D.svg?style=flat)](https://swift.org/package-manager/) [![Build Status](https://travis-ci.org/ceeK/Solar.svg?branch=master)](https://travis-ci.org/ceeK/Solar)
[![MIT licensed](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/hyperium/hyper/master/LICENSE)

A Swift helper for generating Sunrise and Sunset times. 

Solar performs its calculations locally using an algorithm from the [United States Naval Observatory](http://edwilliams.org/sunrise_sunset_algorithm.htm), and thus does not require the use of a network.

## Usage

Solar simply needs a date and a location specified as a latitude and longitude:

```swift
let solar = Solar(for: someDate, coordinate: CLLocationCoordinate2D(latitude: 51.528308, longitude: -0.1340267))
let sunrise = solar?.sunrise
let sunset = solar?.sunset
```

We can also omit providing a date if we just need the sunrise and sunset for the current date and time:

```swift
let solar = Solar(coordinate: CLLocationCoordinate2D(latitude: 51.528308, longitude: -0.1340267))
let sunrise = solar?.sunrise
let sunset = solar?.sunset
```

Note that all dates are UTC. Don't forget to format your date into the appropriate timezone if required.

### Types of sunrise and sunset

There are several types of sunrise and sunset that Solar generates. They differ by how many degrees the sun lies below the horizon:

- **Official** (~0°)

- **Civil** (6° below horizon)

- **Nautical** (12° below horizon)

- **Astronomical** (18° below horizon)

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

Solar is available through CocoaPods, Carthage, and Swift Package Manager. 

### CocoaPods

To include Solar in an application, add the following [pod](https://guides.cocoapods.org/syntax/podfile.html#pod) to your Podfile, then run `pod install`:

```ruby
pod "Solar-dev", "~> 3.0"
```

To include Solar in another pod, add the following [dependency](https://guides.cocoapods.org/syntax/podspec.html#dependency) to your podspec:

```ruby
s.dependency "Solar", "~> 3.0"
```

### Carthage

Add the `ceek/Solar` project to your [Cartfile](https://github.com/Carthage/Carthage/blob/master/Documentation/Artifacts.md#cartfile), then follow the rest of [Carthage’s XCFramework installation instructions](https://github.com/Carthage/Carthage#building-platform-independent-xcframeworks-xcode-12-and-above):

```ruby
github "ceeK/Solar" ~> 3.0
```

### Swift Package Manager

To include Solar in an application in Xcode:

1. Go to File ‣ Swift Packages ‣ Add Package Dependency.
1. Enter `https://github.com/ceeK/Solar.git` as the package repository and click Next.
1. Set Rules to Version, Up to Next Major, and enter `3.0.0` as the minimum version requirement. Click Next.

To include Solar in another Swift package, add the following [dependency](https://developer.apple.com/documentation/swift_packages/package/dependency) to your Package.swift:

```swift
.package(name: "Solar", url: "https://github.com/ceeK/Solar.git", from: "3.0.0")
```

# License 

The MIT License (MIT)

Copyright (c) 2016-2021 Chris Howell

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
