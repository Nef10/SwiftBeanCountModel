//
//  Price.swift
//  SwiftBeanCountModel
//
//  Created by Steffen Kötte on 2018-05-13.
//  Copyright © 2018 Steffen Kötte. All rights reserved.
//

import Foundation

/// Type of price specification
public enum PriceType {
    /// Price per unit (@)
    case perUnit
    /// Total price (@@)
    case total
}

/// Errors a price can throw
public enum PriceError: Error {
    /// the price is listed in its own commodity
    case sameCommodity(String)
}

/// Price of a commodity in another commodity on a given date
public struct Price {

    /// Date of the Price
    public let date: Date

    /// `CommoditySymbol` of the Price
    public let commoditySymbol: CommoditySymbol

    /// `Amount` of the Price (per unit for @ or total for @@)
    public let amount: Amount

    /// Type of price specification
    public let priceType: PriceType

    /// MetaData of the Price
    public let metaData: [String: String]

    /// Create a price per unit (@)
    ///
    /// - Parameters:
    ///   - date: date of the price
    ///   - commodity: commodity
    ///   - amount: amount per unit
    /// - Throws: PriceError.sameCommodity if the commodity and the commodity of the amount are the same
    public init(date: Date, commoditySymbol: CommoditySymbol, amount: Amount, metaData: [String: String] = [:]) throws {
        self.date = date
        self.commoditySymbol = commoditySymbol
        self.amount = amount
        self.priceType = .perUnit
        self.metaData = metaData
        guard commoditySymbol != amount.commoditySymbol else {
            throw PriceError.sameCommodity(commoditySymbol)
        }
    }

    /// Create a price with specified type
    ///
    /// - Parameters:
    ///   - date: date of the price
    ///   - commodity: commodity
    ///   - amount: amount (per unit for @ or total for @@)
    ///   - priceType: type of price specification
    /// - Throws: PriceError.sameCommodity if the commodity and the commodity of the amount are the same
    public init(date: Date, commoditySymbol: CommoditySymbol, amount: Amount, priceType: PriceType, metaData: [String: String] = [:]) throws {
        self.date = date
        self.commoditySymbol = commoditySymbol
        self.amount = amount
        self.priceType = priceType
        self.metaData = metaData
        guard commoditySymbol != amount.commoditySymbol else {
            throw PriceError.sameCommodity(commoditySymbol)
        }
    }

    /// Returns the per-unit price for a given quantity
    ///
    /// - Parameter quantity: quantity of commodity units
    /// - Returns: per-unit price amount
    public func perUnitPrice(for quantity: Decimal) -> Amount {
        switch priceType {
        case .perUnit:
            return amount
        case .total:
            return Amount(number: amount.number / quantity, 
                         commoditySymbol: amount.commoditySymbol, 
                         decimalDigits: amount.decimalDigits)
        }
    }

    /// Returns the total price for a given quantity
    ///
    /// - Parameter quantity: quantity of commodity units
    /// - Returns: total price amount
    public func totalPrice(for quantity: Decimal) -> Amount {
        switch priceType {
        case .perUnit:
            return Amount(number: amount.number * quantity, 
                         commoditySymbol: amount.commoditySymbol, 
                         decimalDigits: amount.decimalDigits)
        case .total:
            return amount
        }
    }

}

extension Price: CustomStringConvertible {

    private static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter
    }()

    /// Returns the price string for the ledger.
    public var description: String {
        var result = "\(Self.dateFormatter.string(from: date)) price \(commoditySymbol) \(amount)"
        if !metaData.isEmpty {
            result += "\n\(metaData.map { "  \($0): \"\($1)\"" }.joined(separator: "\n"))"
        }
        return result
    }

}

extension PriceError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case let .sameCommodity(error):
            return "Invalid Price, using same commodity: \(error)"
        }
    }
}

extension Price: Equatable {

    /// Retuns if the two prices are equal
    ///
    /// - Parameters:
    ///   - lhs: price 1
    ///   - rhs: price 2
    /// - Returns: true if the prices are equal, false otherwise
    public static func == (lhs: Price, rhs: Price) -> Bool {
        lhs.date == rhs.date && lhs.commoditySymbol == rhs.commoditySymbol && lhs.amount == rhs.amount && lhs.priceType == rhs.priceType && lhs.metaData == rhs.metaData
    }

}
