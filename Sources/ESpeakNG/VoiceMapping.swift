//
//  VoiceMapping.swift
//  ESpeakNG
//
//  Protocol for mapping voices to languages/dialects
//

import Foundation

/// Protocol for types that can be mapped to ESpeakNG languages
public protocol ESpeakNGVoiceMapping {
    /// Returns the language dialect for this voice
    var languageDialect: ESpeakNGEngine.LanguageDialect { get }
    
    /// Returns the ESpeakNG voice name identifier
    var espeakVoiceName: String { get }
}

