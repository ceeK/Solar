<div align="center">
<img src="./solar-logo.png" />
</div>

# Solar

[![SPM compatible](https://img.shields.io/badge/SPM-compatible-4BC51D.svg?style=flat)](https://swift.org/package-manager/) [![CI](https://github.com/ceeK/Solar/actions/workflows/ci.yml/badge.svg)](https://github.com/ceeK/Solar/actions/workflows/ci.yml)
[![MIT licensed](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/ceeK/Solar/blob/main/LICENSE)
[![Swift Compatibility](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FceeK%2FSolar%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/ceeK/Solar)
[![Platform Compatibility](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FceeK%2FSolar%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/ceeK/Solar)

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

Solar is available through Swift Package Manager.

### Swift Package Manager

To include Solar in an application in Xcode:

1. Go to File ‣ Swift Packages ‣ Add Package Dependency.
1. Enter `https://github.com/ceeK/Solar.git` as the package repository and click Next.
1. Set Rules to Version, Up to Next Major, and enter `4.0.0` as the minimum version requirement. Click Next.

To include Solar in another Swift package, add the following [dependency](https://developer.apple.com/documentation/swift_packages/package/dependency) to your Package.swift:

```swift
.package(name: "Solar", url: "https://github.com/ceeK/Solar.git", from: "4.0.0")
```

# License

Solar is available under the MIT license. See the [LICENSE](LICENSE) file for details.
