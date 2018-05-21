//
//  MultiCurrencyAmount.swift
//  SwiftBeanCountModel
//
//  Created by Steffen Kötte on 2017-07-07.
//  Copyright © 2017 Steffen Kötte. All rights reserved.
//

import Foundation

/// protocol to describe objects which can be represented as `MultiCurrencyAmount`
public protocol MultiCurrencyAmountRepresentable {

    /// the `MultiCurrencyAmount` representation of the current object
    var multiAccountAmount: MultiCurrencyAmount { get }

}

/// Represents an amout which consists of amouts in multiple currencies
///
/// **Tolerance** for validation: Half of the last digit of precision provided separately for each currency
///
public struct MultiCurrencyAmount {
    var amounts: [Commodity: Decimal]
    var decimalDigits: [Commodity: Int]

    /// Validates that the amount is zero within the allowed tolerance
    ///
    /// - Returns: `ValidationResult`
    func validateZeroWithTolerance() -> ValidationResult {
        let zero = MultiCurrencyAmount(amounts: [:], decimalDigits: self.decimalDigits)
        return MultiCurrencyAmount.equalWithinTolerance(amount1: self, amount2: zero)
    }

    /// Checks if all amounts of the first one are equal to the one in the second
    ///
    /// In the second amount contains amounts in currencies which are not in the first one,
    /// or the tolerance is lower in the second one, this will NOT result in an error.
    ///
    /// To check this combinations call this function twice with switched arguments
    ///
    /// - Parameters:
    ///   - amount1: first amount
    ///   - amount2: second amount
    /// - Returns: `ValidationResult`
    private static func equalWithinTolerance(amount1: MultiCurrencyAmount, amount2: MultiCurrencyAmount) -> ValidationResult {
        for (commodity, decimal1) in amount1.amounts {
            let decimal2 = amount2.amounts[commodity] ?? 0
            let result = decimal1 - decimal2
            let decimalDigits = amount1.decimalDigits[commodity] ?? 0
            var tolerance = Decimal()
            if decimalDigits != 0 {
                tolerance = Decimal(sign: FloatingPointSign.plus, exponent: -(decimalDigits + 1), significand: Decimal(5))
            }
            if result > tolerance || result < -tolerance {
                return .invalid("\(result) \(commodity.symbol) too much (\(tolerance) tolerance)")
            }
        }
        return .valid
    }

}

extension MultiCurrencyAmount {
    init() {
        amounts = [:]
        decimalDigits = [:]
    }
}

extension MultiCurrencyAmount: MultiCurrencyAmountRepresentable {

    /// returns self to conform to the `MultiCurrencyAmountRepresentable` protocol
    public var multiAccountAmount: MultiCurrencyAmount {
        return self
    }

}

extension MultiCurrencyAmount: Equatable {
    public static func == (lhs: MultiCurrencyAmount, rhs: MultiCurrencyAmount) -> Bool {
        return lhs.amounts == rhs.amounts && lhs.decimalDigits == rhs.decimalDigits
    }
}

/// Adds two `MultiCurrencyAmountRepresentable`s into a MultiCurrencyAmount
///
/// If the MultiCurrencyAmount of both MultiCurrencyAmountRepresentable contain an `Amount` in the same `Commodity`
/// the higher number of decimalDigits will be used to ensure the tolerance is correct
///
/// - Parameters:
///   - left: first MultiCurrencyAmountRepresentable, the multiAccountAmount will be added
///   - right: second MultiCurrencyAmountRepresentable, the multiAccountAmount will be added
/// - Returns: MultiCurrencyAmount which includes both amounts
func + (left: MultiCurrencyAmountRepresentable, right: MultiCurrencyAmountRepresentable) -> MultiCurrencyAmount {
    var result = left.multiAccountAmount.amounts
    var decimalDigits = left.multiAccountAmount.decimalDigits
    for (commodity, decimal) in right.multiAccountAmount.amounts {
        result[commodity] = (result[commodity] ?? Decimal(0)) + decimal
    }
    for (commodity, digits) in right.multiAccountAmount.decimalDigits {
        decimalDigits[commodity] = max((decimalDigits[commodity] ?? 0), digits)
    }
    return MultiCurrencyAmount(amounts: result, decimalDigits: decimalDigits)
}

/// Adds the `MultiCurrencyAmount` of a `MultiCurrencyAmountRepresentable` to a `MultiCurrencyAmount`
///
/// - Parameters:
///   - left: first MultiCurrencyAmount which at the same time will store the result
///   - right: MultiCurrencyAmountRepresentable of which the multiAccountAmount will be added
func += (left: inout MultiCurrencyAmount, right: MultiCurrencyAmountRepresentable) {
    // swiftlint:disable:next shorthand_operator
    left = left + right
}
