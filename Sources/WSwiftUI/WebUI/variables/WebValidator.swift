//
//  WebValidator.swift
//  WSwiftUI
//
//  Created by Adrian Herridge on 12/08/2025.
//

import Foundation

public enum ValidationCondition {
    case notEmpty
    case empty
    case atLeast(Int)
    case validURL
    case validEmail
    case validPhoneNumber
    case validDate
    case validJSON
    case validNumber
    
    var encoded: String {
        switch self {
            case .notEmpty: return "notEmpty"
            case .empty: return "empty"
            case .atLeast(let length): return "atLeast:\(length)"
            case .validURL: return "validURL"
            case .validEmail: return "validEmail"
            case .validPhoneNumber: return "validPhoneNumber"
            case .validDate: return "validDate"
            case .validJSON: return "validJSON"
            case .validNumber: return "validNumber"
        }
    }
    
}

public enum ValidateField {
    case named(String,[ValidationCondition])
}

public extension CoreWebEndpoint {
    func validateData(_ fields: [ValidateField]) -> Bool {
        
        var overallResult = true
        
        for field in fields {
            
            // get the field value from the data object
            switch field {
                case .named(let name, let conditions):
                    
                    guard let value = data.raw(name) ?? data.webVariableTransaction()?.data[name] else {
                        return false
                    }
                    
                    // ensure value is converted into a string to check the conditions
                    let valueString: String
                    if let stringValue = value as? String {
                        valueString = stringValue
                    } else if let intValue = value as? Int {
                        valueString = String(intValue)
                    } else if let doubleValue = value as? Double {
                        valueString = String(doubleValue)
                    } else if let boolValue = value as? Bool {
                        valueString = String(boolValue)
                    } else if let wVarValue = value as? JSONValue {
                        switch wVarValue {
                            case .string(let str):
                                valueString = str
                            case .int(let intVal):
                                valueString = String(intVal)
                            case .double(let doubleVal):
                                valueString = String(doubleVal)
                            case .bool(let boolVal):
                                valueString = String(boolVal)
                            case .array(let arr):
                                valueString = arr.description // or handle as needed
                            case .object(let obj):
                                valueString = obj.description // or handle as needed
                            case .null:
                                valueString = ""
                        }
                    } else {
                        return false
                    }
                    
                    for condition in conditions {
                        switch condition {
                            case .notEmpty:
                                if valueString.isEmpty {
                                    overallResult = false
                                    ephemeralData["error_\(name)"] = "Field cannot be empty"
                                    ephemeralData["previous_\(name)"] = value
                                }
                            case .empty:
                                if !valueString.isEmpty {
                                    overallResult = false
                                    ephemeralData["error_\(name)"] = "Field must be empty"
                                    ephemeralData["previous_\(name)"] = value
                                }
                            case .atLeast(let length):
                                if valueString.count < length {
                                    overallResult = false
                                    ephemeralData["error_\(name)"] = "Field must be at least \(length) characters"
                                    ephemeralData["previous_\(name)"] = value
                                }
                            case .validURL:
                                if URL(string: valueString) == nil  {
                                    overallResult = false
                                    ephemeralData["error_\(name)"] = "Field must be a valid URL"
                                }
                            case .validEmail:
                                // A simple regex for email
                                let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
                                let emailTest = NSPredicate(format: "SELF MATCHES %@", emailRegex)
                                if !emailTest.evaluate(with: valueString) {
                                    overallResult = false
                                    ephemeralData["error_\(name)"] = "Field must be a valid email address"
                                    ephemeralData["previous_\(name)"] = value
                                }
                            case .validPhoneNumber:
                                // A simple regex for phone numbers, can be improved
                                let phoneRegex = "^[0-9+\\-() ]{7,15}$"
                                let phoneTest = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
                                if !phoneTest.evaluate(with: valueString) {
                                    overallResult = false
                                    ephemeralData["error_\(name)"] = "Field must be a valid phone number"
                                    ephemeralData["previous_\(name)"] = value
                                }
                            case .validDate:
                                // A simple date format check, can be improved
                                let dateFormatter = DateFormatter()
                                dateFormatter.dateFormat = "yyyy-MM-dd" // Adjust as needed
                                if dateFormatter.date(from: valueString) == nil {
                                    overallResult = false
                                    ephemeralData["error_\(name)"] = "Field must be a valid date (yyyy-MM-dd)"
                                    ephemeralData["previous_\(name)"] = value
                                }
                            case .validJSON:
                                // Check if the string is valid JSON
                                if let data = valueString.data(using: .utf8) {
                                    do {
                                        _ = try JSONSerialization.jsonObject(with: data, options: [])
                                    } catch {
                                        overallResult = false
                                        ephemeralData["error_\(name)"] = "Field must be valid JSON"
                                        ephemeralData["previous_\(name)"] = value
                                    }
                                } else {
                                    overallResult = false
                                    ephemeralData["error_\(name)"] = "Field must be valid JSON"
                                    ephemeralData["previous_\(name)"] = value
                                }
                            case .validNumber:
                                // Check if the string can be converted to a number
                                let numberFormatter = NumberFormatter()
                                numberFormatter.numberStyle = .decimal
                                if numberFormatter.number(from: valueString) == nil {
                                    overallResult = false
                                    ephemeralData["error_\(name)"] = "Field must be a valid number"
                                    ephemeralData["previous_\(name)"] = value
                                }
                        }
                    }
            }
        }
        return overallResult
    }
}
