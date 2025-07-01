import Foundation

public protocol TemplateParameters {
    func convertToDictionary() -> [String: String]
}
