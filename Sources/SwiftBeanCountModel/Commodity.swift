//
//  Commodity.swift
//  SwiftBeanCountModel
//
//  Created by Steffen Kötte on 2017-06-08.
//  Copyright © 2017 Steffen Kötte. All rights reserved.
//

import Foundation

/// A CommoditySymbol is just a string
public typealias CommoditySymbol = String

/// A commodity just consists of a symbol
public class Commodity {

    /// symbol of the commodity
    public let symbol: CommoditySymbol

    /// opening of the commodity
    public let opening: Date?

    /// MetaData of the Commodity
    public let metaData: [String: String]

    /// Creates an commodity with the given symbol, and an optinal opening date
    ///
    /// - Parameters:
    ///   - symbol: symbol of the commodity
    ///   - opening: date the commodity was opened
    public init(symbol: CommoditySymbol, opening: Date? = nil, metaData: [String: String] = [:]) {
        self.symbol = symbol
        self.opening = opening
        self.metaData = metaData
    }

    /// Validates the commodity
    ///
    /// A commodity is valid if it has an opening date. Name and price are optional
    ///
    /// - Returns: `ValidationResult`
    func validate() -> ValidationResult {
        guard opening != nil else {
            return .invalid("Commodity \(symbol) does not have an opening date")
        }
        return .valid
    }

    /// Validates the commodity in the context of enabled plugins
    ///
    /// If the beancount.plugins.check_commodity plugin is enabled, a commodity is only valid if it has an opening date.
    /// Otherwise, commodities are always valid regardless of opening date.
    ///
    /// - Parameter enabledPlugins: Array of enabled plugins to check
    /// - Returns: `ValidationResult`
    func validate(enabledPlugins: [String]) -> ValidationResult {
        // Only check for opening date if the check_commodity plugin is enabled
        if enabledPlugins.contains("beancount.plugins.check_commodity") {
            guard opening != nil else {
                return .invalid("Commodity \(symbol) does not have an opening date")
            }
        }
        return .valid
    }

}

extension Commodity: CustomStringConvertible {

    private static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter
    }()

    /// String of the commodity definition
    ///
    /// If no opening is set it is an empty string
    public var description: String {
        guard let opening else {
            return ""
        }
        var result = "\(Self.dateFormatter.string(from: opening)) commodity \(symbol)"
        if !metaData.isEmpty {
            result += "\n\(metaData.map { "  \($0): \"\($1)\"" }.joined(separator: "\n"))"
        }
        return result
    }

}

extension Commodity: Equatable {

    /// Retuns if the two commodities are equal, meaning their `symbol`s and meta data are equal
    ///
    /// - Parameters:
    ///   - lhs: commodity 1
    ///   - rhs: commodity 2
    /// - Returns: true if the sybols and meta data are equal, false otherwise
    public static func == (lhs: Commodity, rhs: Commodity) -> Bool {
        lhs.symbol == rhs.symbol && lhs.metaData == rhs.metaData
    }

}
