# ISO8583

![](https://github.com/ifau/ISO8583/workflows/Build%20and%20Test/badge.svg)

Swift package for iOS/macOS/Linux that helps to create and parse ISO8583 financial transaction messages.

## Installation

### Swift Package Manager

Add dependency to your `Package.swift`

```swift
dependencies: [
    .package(url: "https://github.com/ifau/ISO8583.git")
]
```

Or with **Xcode 11** and above `File` – `Swift Packages` – `Add Package Dependency...`

## Usage

Define your custom processing scheme by adopting the [`ISOScheme`](https://github.com/ifau/ISO8583/blob/master/Sources/ISO8583/ISOScheme.swift) protocol

```swift
class CustomProcessingScheme: ISOScheme {
    
    func numberOfBytesForLength() -> UInt {
        return 2
    }
    
    func lengthFormat() -> ISONumberFormat {
        return .bcd
    }
    
    func mtiFormat() -> ISONumberFormat {
        return .bcd
    }
    
    func fieldFormat(for fieldNumber: UInt) -> ISOFieldFormat {
        switch fieldNumber {
        case 3:
            return .numeric(length: 6)                          // Processing code
        case 24:
            return .numeric(length: 3)                          // Function code
        case 35:
            return .llvar(lengthFormat: .bcd, valueFormat:[.z]) // Track 2
        case 38:
            return .alpha(length: 6, valueFormat:[.a, .n, .p])  // Approval Code
        case 39:
            return .numeric(length: 3)                          // Response code
        case 64:
            return .binary(length: 8)                           // Message authentication code
        default:
            return .undefined
        }
    }
}
```

Then you can decode any binary message into the `ISOMessage` object

```swift
let message = try? ISOMessage(data: data, using: CustomProcessingScheme())
```

Or encode the `ISOMessage` object into a binary message

```swift
let message = ISOMessage(mti: 200, fields: [3:"000000", 24:"200", 35:"4000010000000001=991233000123410000"])
let data = try? message.data(using: CustomProcessingScheme())
```

A complete example is available [here](https://github.com/ifau/ISO8583/blob/master/Tests/ISO8583Tests/ExampleUsageTests.swift).