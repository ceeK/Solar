<div align="center">
<img src="./solar-logo.png" />
</div>

# Solar

[![SPM compatible](https://img.shields.io/badge/SPM-compatible-4BC51D.svg?style=flat)](https://swift.org/package-manager/) [![CI](https://github.com/ceeK/Solar/actions/workflows/ci.yml/badge.svg)](https://github.com/ceeK/Solar/actions/workflows/ci.yml)
[![Swift Compatibility](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FceeK%2FSolar%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/ceeK/Solar)
[![Platform Compatibility](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FceeK%2FSolar%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/ceeK/Solar)
[![MIT licensed](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/ceeK/Solar/blob/main/LICENSE)

A Swift micro library for generating Sunrise and Sunset times, requiring no network access.

Solar performs its calculations locally using an algorithm from the [United States Naval Observatory](http://edwilliams.org/sunrise_sunset_algorithm.htm).

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

Solar is available through the Swift Package Manager. Add it to the `dependencies` value of your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/ceeK/Solar.git", .upToNextMajor(from: "4.0.0"))
]
```

Or in Xcode: **File ▸ Add Package Dependencies…** and enter `https://github.com/ceeK/Solar.git` as the package URL.

# License

Solar is available under the MIT license. See the [LICENSE](LICENSE) file for details.
