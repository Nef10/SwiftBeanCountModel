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
    var multiCurrencyAmount: MultiCurrencyAmount { get }

}

/// Represents an amout which consists of amouts in multiple currencies
///
/// **Tolerance** for validation: Half of the last digit of precision provided separately for each currency
///
public struct MultiCurrencyAmount {
    let amounts: [CommoditySymbol: Decimal]
    let decimalDigits: [CommoditySymbol: Int]

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
        for (commoditySymbol, decimal1) in amount1.amounts {
            let decimal2 = amount2.amounts[commoditySymbol] ?? 0
            let result = decimal1 - decimal2
            let decimalDigits = amount1.decimalDigits[commoditySymbol] ?? 0
            var tolerance = Decimal()
            if decimalDigits != 0 {
                tolerance = Decimal(sign: FloatingPointSign.plus, exponent: -(decimalDigits + 1), significand: Decimal(5))
            }
            if result > tolerance || result < (tolerance == 0 ? tolerance : -tolerance) {
                return .invalid("\(result) \(commoditySymbol) too much (\(tolerance) tolerance)")
            }
        }
        return .valid
    }

    /// Validates that the amount is zero within the allowed tolerance
    ///
    /// - Returns: `ValidationResult`
    func validateZeroWithTolerance() -> ValidationResult {
        let zero = MultiCurrencyAmount(amounts: [:], decimalDigits: self.decimalDigits)
        return MultiCurrencyAmount.equalWithinTolerance(amount1: self, amount2: zero)
    }

    /// Validates that the amount is the same in the MultiCurrencyAmount
    ///
    /// Ignores other currencies in the MultiCurrencyAmount.
    /// Uses the tolerance of the passed amount. The tolerance of the MultiCurrencyAmount is ignored.
    ///
    /// - Parameter amount: amount to validate
    /// - Returns: `ValidationResult`
    func validateOneAmountWithTolerance(amount: Amount) -> ValidationResult {
        return MultiCurrencyAmount.equalWithinTolerance(amount1: amount.multiCurrencyAmount, amount2: self)
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
    public var multiCurrencyAmount: MultiCurrencyAmount {
        self
    }

}

extension MultiCurrencyAmount: Equatable {
    public static func == (lhs: MultiCurrencyAmount, rhs: MultiCurrencyAmount) -> Bool {
        lhs.amounts == rhs.amounts && lhs.decimalDigits == rhs.decimalDigits
    }
}

/// Adds two `MultiCurrencyAmountRepresentable`s into a MultiCurrencyAmount
///
/// If the MultiCurrencyAmount of both MultiCurrencyAmountRepresentable contain an `Amount` in the same `Commodity`
/// the higher number of decimalDigits will be used to ensure the tolerance is correct, except one is 0 than 0 is used
/// as it is more precise
///
/// - Parameters:
///   - left: first MultiCurrencyAmountRepresentable, the multiAccountAmount will be added
///   - right: second MultiCurrencyAmountRepresentable, the multiAccountAmount will be added
/// - Returns: MultiCurrencyAmount which includes both amounts
func + (left: MultiCurrencyAmountRepresentable, right: MultiCurrencyAmountRepresentable) -> MultiCurrencyAmount {
    var result = left.multiCurrencyAmount.amounts
    var decimalDigits = left.multiCurrencyAmount.decimalDigits
    for (commodity, decimal) in right.multiCurrencyAmount.amounts {
        result[commodity] = (result[commodity] ?? Decimal(0)) + decimal
    }
    for (commodity, rightDigits) in right.multiCurrencyAmount.decimalDigits {
        decimalDigits[commodity] = decimalDigitToKeep(rightDigits, decimalDigits[commodity])
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

/// Returns the number of decimals digits which is less precise
///
/// If one of the numbers is zero this indicats no tolerance (e.g. very precise).
/// So it returns the smaller number (= less precise), unless it is 0, in this
/// case the highest number will be returned
///
/// - Parameters:
///   - decimal1: first decimal
///   - decimal2: secons decimal
/// - Returns: the decimal which indicates lower precision
private func decimalDigitToKeep(_ decimal1: Int, _ decimal2: Int?) -> Int {
    guard let decimal2 = decimal2 else {
        return decimal1
    }
    let minValue = min(decimal1, decimal2)
    if minValue == 0 {
        return max(decimal1, decimal2)
    }
    return minValue
}
