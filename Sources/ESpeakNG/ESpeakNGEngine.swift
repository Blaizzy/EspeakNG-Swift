//
//  ESpeakNGEngine.swift
//  ESpeakNG
//
//  ESpeakNG wrapper for phonemizing text strings
//

import Foundation
import ESpeakNG

/// ESpeakNG wrapper for phonemizing text strings
public final class ESpeakNGEngine {
    private var language: LanguageDialect = .none
    private var languageMapping: [String: String] = [:]
    private let bundleIdentifier: String
    
    /// Errors that can occur during ESpeakNG operations
    public enum ESpeakNGEngineError: Error {
        case dataBundleNotFound
        case couldNotInitialize
        case languageNotFound
        case internalError
        case languageNotSet
        case couldNotPhonemize
    }
    
    /// Available language dialects
    public enum LanguageDialect: String, CaseIterable {
        case none = ""
        case enUS = "en-us"
        case enGB = "en-gb"
        case jaJP = "ja"
        case znCN = "yue"
        case frFR = "fr-fr"
        case hiIN = "hi"
        case itIT = "it"
        case esES = "es"
        case ptBR = "pt-br"
    }
    
    /// Initialize the ESpeakNG engine
    /// - Parameters:
    ///   - bundleIdentifier: The bundle identifier to search for the espeak-ng-data bundle.
    ///                        Defaults to "com.espeakng.framework" for the standalone package.
    ///                        For Kokoro integration, use "com.kokoro.espeakng"
    public init(bundleIdentifier: String = "com.espeakng.framework") throws {
        self.bundleIdentifier = bundleIdentifier
        
        #if !targetEnvironment(simulator)
        if let bundleURLStr = findDataBundlePath() {
            let initOK = espeak_Initialize(AUDIO_OUTPUT_PLAYBACK, 0, bundleURLStr, 0)
            
            if initOK != Constants.successAudioSampleRate {
                print("Internal espeak-ng error, could not initialize")
                throw ESpeakNGEngineError.couldNotInitialize
            }
            
            var languageList: Set<String> = []
            let voiceList = espeak_ListVoices(nil)
            var index = 0
            while let voicePointer = voiceList?.advanced(by: index).pointee {
                let voice = voicePointer.pointee
                if let cLang = voice.languages {
                    let language = String(cString: cLang, encoding: .utf8)!
                        .replacingOccurrences(of: "\u{05}", with: "")
                        .replacingOccurrences(of: "\u{02}", with: "")
                    languageList.insert(language)
                    
                    if let cName = voice.identifier {
                        let name = String(cString: cName, encoding: .utf8)!
                            .replacingOccurrences(of: "\u{05}", with: "")
                            .replacingOccurrences(of: "\u{02}", with: "")
                        languageMapping[language] = name
                    }
                }
                
                index += 1
            }
            
            try LanguageDialect.allCases.forEach {
                if $0.rawValue.count > 0, !languageList.contains($0.rawValue) {
                    print("Language dialect \($0) not found in espeak-ng voice list")
                    throw ESpeakNGEngineError.languageNotFound
                }
            }
        } else {
            print("Couldn't find the espeak-ng data bundle, cannot initialize")
            throw ESpeakNGEngineError.dataBundleNotFound
        }
        #else
        throw ESpeakNGEngineError.couldNotInitialize
        #endif
    }
    
    /// Cleanup when deallocated
    deinit {
        #if !targetEnvironment(simulator)
        let terminateOK = espeak_Terminate()
        print("ESpeakNGEngine termination OK: \(terminateOK == EE_OK)")
        #endif
    }
    
    /// Set the language using a voice mapping protocol
    /// - Parameter voice: A type conforming to ESpeakNGVoiceMapping
    public func setLanguage<V: ESpeakNGVoiceMapping>(for voice: V) throws {
        #if !targetEnvironment(simulator)
        let language = voice.languageDialect
        guard let name = languageMapping[language.rawValue] else {
            throw ESpeakNGEngineError.languageNotFound
        }
        
        let result = espeak_SetVoiceByName((name as NSString).utf8String)
        
        if result == EE_NOT_FOUND {
            throw ESpeakNGEngineError.languageNotFound
        } else if result != EE_OK {
            throw ESpeakNGEngineError.internalError
        }
        
        self.language = language
        #else
        throw ESpeakNGEngineError.languageNotFound
        #endif
    }
    
    /// Set the language directly using a language dialect
    /// - Parameter language: The language dialect to use
    public func setLanguage(_ language: LanguageDialect) throws {
        #if !targetEnvironment(simulator)
        guard let name = languageMapping[language.rawValue] else {
            throw ESpeakNGEngineError.languageNotFound
        }
        
        let result = espeak_SetVoiceByName((name as NSString).utf8String)
        
        if result == EE_NOT_FOUND {
            throw ESpeakNGEngineError.languageNotFound
        } else if result != EE_OK {
            throw ESpeakNGEngineError.internalError
        }
        
        self.language = language
        #else
        throw ESpeakNGEngineError.languageNotFound
        #endif
    }
    
    /// Get the language dialect for a voice mapping
    /// - Parameter voice: A type conforming to ESpeakNGVoiceMapping
    /// - Returns: The language dialect for the voice
    public func languageForVoice<V: ESpeakNGVoiceMapping>(voice: V) -> LanguageDialect {
        return voice.languageDialect
    }
    
    /// Phonemize a text string
    /// - Parameter text: The text to phonemize
    /// - Returns: The phonemized text
    /// - Throws: ESpeakNGEngineError if phonemization fails
    public func phonemize(text: String) throws -> String {
        #if !targetEnvironment(simulator)
        guard language != .none else {
            throw ESpeakNGEngineError.languageNotSet
        }
        
        guard !text.isEmpty else {
            return ""
        }
        
        let textCopy = text as NSString
        var textPtr = UnsafeRawPointer(textCopy.utf8String)
        let phonemes_mode = Int32((Int32(Character("_").asciiValue!) << 8) | 0x02)
        
        // Use autoreleasepool to ensure memory is managed properly
        let result = autoreleasepool { () -> [String] in
            withUnsafeMutablePointer(to: &textPtr) { ptr in
                var resultWords: [String] = []
                while ptr.pointee != nil {
                    if let result = ESpeakNG.espeak_TextToPhonemes(ptr, espeakCHARS_UTF8, phonemes_mode) {
                        // Create a copy of the returned string to ensure we own the memory
                        resultWords.append(String(cString: result, encoding: .utf8)!)
                    }
                }
                return resultWords
            }
        }
        
        if !result.isEmpty {
            return postProcessPhonemes(result.joined(separator: " "))
        } else {
            throw ESpeakNGEngineError.couldNotPhonemize
        }
        #else
        throw ESpeakNGEngineError.couldNotPhonemize
        #endif
    }
    
    // MARK: - Private Methods
    
    /// Post-process phonemes for English (and other languages as needed)
    /// NOTE: This is currently optimized for English. Other languages may require different post-processing
    private func postProcessPhonemes(_ phonemes: String) -> String {
        var result = phonemes.trimmingCharacters(in: .whitespacesAndNewlines)
        for (old, new) in Constants.E2M {
            result = result.replacingOccurrences(of: old, with: new)
        }
        
        result = result.replacingOccurrences(of: "(\\S)\u{0329}", with: "ᵊ$1", options: .regularExpression)
        result = result.replacingOccurrences(of: "\u{0329}", with: "")
        
        if language == .enGB {
            result = result.replacingOccurrences(of: "e^ə", with: "ɛː")
            result = result.replacingOccurrences(of: "iə", with: "ɪə")
            result = result.replacingOccurrences(of: "ə^ʊ", with: "Q")
        } else {
            result = result.replacingOccurrences(of: "o^ʊ", with: "O")
            result = result.replacingOccurrences(of: "ɜːɹ", with: "ɜɹ")
            result = result.replacingOccurrences(of: "ɜː", with: "ɜɹ")
            result = result.replacingOccurrences(of: "ɪə", with: "iə")
            result = result.replacingOccurrences(of: "ː", with: "")
        }
        
        // For espeak < 1.52
        result = result.replacingOccurrences(of: "o", with: "ɔ")
        return result.replacingOccurrences(of: "^", with: "")
    }
    
    /// Find the data bundle path within the framework
    private func findDataBundlePath() -> String? {
        if let frameworkBundle = Bundle(identifier: bundleIdentifier),
           let dataBundleURL = frameworkBundle.url(forResource: "espeak-ng-data", withExtension: "bundle")
        {
            return dataBundleURL.path
        }
        return nil
    }
    
    private enum Constants {
        static let successAudioSampleRate = 22050
        static let E2M: [(String, String)] = [
            ("ʔˌn\u{0329}", "tn"), ("ʔn\u{0329}", "tn"), ("ʔn", "tn"), ("ʔ", "t"),
            ("a^ɪ", "I"), ("a^ʊ", "W"),
            ("d^ʒ", "ʤ"),
            ("e^ɪ", "A"), ("e", "A"),
            ("t^ʃ", "ʧ"),
            ("ɔ^ɪ", "Y"),
            ("ə^l", "ᵊl"),
            ("ʲo", "jo"), ("ʲə", "jə"), ("ʲ", ""),
            ("ɚ", "əɹ"),
            ("r", "ɹ"),
            ("x", "k"), ("ç", "k"),
            ("ɐ", "ə"),
            ("ɬ", "l"),
            ("\u{0303}", ""),
        ].sorted(by: { $0.0.count > $1.0.count })
    }
}

