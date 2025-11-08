# ESpeakNG-Swift

A Swift wrapper for the ESpeakNG text-to-speech library, providing phonemization capabilities for TTS applications.

## Features

- Protocol-based design for flexible voice mapping
- Supports multiple languages and dialects including en-US, en-GB, ja, zh-CN, fr, hi, it, es, and pt-BR
- Includes ESpeakNG.xcframework for iOS and macOS
- Configurable bundle identifier for different integration scenarios
- Type-safe voice mapping via protocols

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(path: "../EspeakNG-Swift")
]
```

## Usage

### Basic Usage

```swift
import ESpeakNG

// Initialize the engine
let engine = try ESpeakNGEngine()

// Set language directly
try engine.setLanguage(.enUS)

// Phonemize text
let phonemes = try engine.phonemize(text: "Hello, world!")
```

### Protocol-Based Voice Mapping

Create a voice type that conforms to `ESpeakNGVoiceMapping`:

```swift
enum MyVoice: String, ESpeakNGVoiceMapping {
    case voice1
    case voice2
    
    var languageDialect: ESpeakNGEngine.LanguageDialect {
        switch self {
        case .voice1: return .enUS
        case .voice2: return .enGB
        }
    }
    
    var espeakVoiceName: String {
        // Return the ESpeakNG voice identifier
        return languageDialect.rawValue
    }
}

// Use with the engine
try engine.setLanguage(for: MyVoice.voice1)
```

### Custom Bundle Identifier

If integrating with a framework that embeds ESpeakNG:

```swift
let engine = try ESpeakNGEngine(bundleIdentifier: "com.yourframework.espeakng")
```

## Integration with MLX Audio

For Kokoro TTS integration, see the example extension in the mlx-audio package.

## Requirements

- iOS 17.0+ / macOS 14.0+
- Apple Silicon (M1+) recommended

## License

This package wraps ESpeakNG, which is licensed under the GNU General Public License v3.