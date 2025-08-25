//
//  Transaction.swift
//  SwiftBeanCountModel
//
//  Created by Steffen Kötte on 2017-06-07.
//  Copyright © 2017 Steffen Kötte. All rights reserved.
//

import Foundation

/// A Transaction has meta data as well as multiple postings
public class Transaction {

    /// Meta data of the Transaction
    public let metaData: TransactionMetaData

    /// Arrary of the `Posting`s of the transaction.
    ///
    /// Should at least have two elements, otherwise the Transaction is not valid
    public var postings: [TransactionPosting] {
        internalPostings
    }

    // can only be set in the init, but must not be let because otherwise not all required lets are set in init
    // before calling out to create the TransactionPostings
    private var internalPostings = [TransactionPosting]()

    /// Creates a transaction
    ///
    /// - Parameters:
    ///   - metaData: `TransactionMetaData`
    ///   - postings: `Postings`
    public init(metaData: TransactionMetaData, postings: [Posting]) {
        self.metaData = metaData
        self.internalPostings = postings.map { TransactionPosting(posting: $0, transaction: self) }
    }

    func validate(in ledger: Ledger) -> ValidationResult {
        guard !postings.isEmpty else {
            return .invalid("\(self) has no postings")
        }
        let balanced = validateBalance(in: ledger)
        guard case .valid = balanced else {
            return balanced
        }

        // Validate commodity usage dates
        let commodityValidation = validateCommodityUsageDates(in: ledger)
        guard case .valid = commodityValidation else {
            return commodityValidation
        }

        // Validate sellgains if plugin is enabled
        let sellgainsValidation = validateSellgains(in: ledger)
        guard case .valid = sellgainsValidation else {
            return sellgainsValidation
        }

        for posting in postings {
            guard let account = ledger.accounts.first(where: { $0.name == posting.accountName }) else {
                return .invalid("Account \(posting.accountName) does not exist in the ledger")
            }
            let validationResult = account.validate(posting)
            guard case .valid = validationResult else {
                return validationResult
            }
        }
        return .valid
    }

    /// Validates that all commodities used in the transaction are not used before their opening dates
    ///
    /// - Parameter ledger: The ledger context
    /// - Returns: `ValidationResult`
    private func validateCommodityUsageDates(in ledger: Ledger) -> ValidationResult {
        let transactionDate = metaData.date

        for posting in postings {
            // Validate main amount commodity
            if let commodity = ledger.commodities.first(where: { $0.symbol == posting.amount.commoditySymbol }) {
                let validation = commodity.validateUsageDate(transactionDate, in: ledger)
                guard case .valid = validation else {
                    return validation
                }
            }

            // Validate price commodity if present
            if let priceAmount = posting.price {
                if let commodity = ledger.commodities.first(where: { $0.symbol == priceAmount.commoditySymbol }) {
                    let validation = commodity.validateUsageDate(transactionDate, in: ledger)
                    guard case .valid = validation else {
                        return validation
                    }
                }
            }

            // Validate cost commodity if present
            if let cost = posting.cost, let costAmount = cost.amount {
                if let commodity = ledger.commodities.first(where: { $0.symbol == costAmount.commoditySymbol }) {
                    let validation = commodity.validateUsageDate(transactionDate, in: ledger)
                    guard case .valid = validation else {
                        return validation
                    }
                }
            }
        }

        return .valid
    }

    /// Validates sellgains for transactions with cost-based postings
    ///
    /// When the sellgains plugin is enabled, this validates that the proceeds from selling
    /// inventory match the expected value based on the cost of the sold units.
    ///
    /// - Parameter ledger: The ledger context containing enabled plugins
    /// - Returns: `ValidationResult`
    private func validateSellgains(in ledger: Ledger) -> ValidationResult {
        // Only validate if the sellgains plugin is enabled
        guard ledger.plugins.contains("beancount.plugins.sellgains") else {
            return .valid
        }

        // Find postings with cost that have negative amounts (indicating sales)
        let sellPostings = postings.filter { posting in
            posting.cost != nil && posting.amount.number.sign == .minus
        }

        // If no sell postings, validation passes
        guard !sellPostings.isEmpty else {
            return .valid
        }

        let expectedProceeds = calculateExpectedProceeds(from: sellPostings)
        
        let actualProceedsResult = calculateActualProceeds(excluding: sellPostings, in: ledger)
        guard case .valid = actualProceedsResult.result,
              let actualProceeds = actualProceedsResult.proceeds else {
            return actualProceedsResult.result
        }

        return validateProceedsMatch(expected: expectedProceeds, actual: actualProceeds)
    }

    /// Calculates expected proceeds from cost-based sell postings
    private func calculateExpectedProceeds(from sellPostings: [TransactionPosting]) -> MultiCurrencyAmount {
        var expectedProceeds = MultiCurrencyAmount()

        for posting in sellPostings {
            guard let cost = posting.cost,
                  let costAmount = cost.amount else {
                continue
            }

            // Calculate proceeds: absolute value of sold amount * cost per unit
            let soldAmount = abs(posting.amount.number)
            let proceedsAmount = soldAmount * costAmount.number

            expectedProceeds += Amount(number: proceedsAmount,
                                       commoditySymbol: costAmount.commoditySymbol,
                                       decimalDigits: costAmount.decimalDigits).multiCurrencyAmount
        }

        return expectedProceeds
    }

    /// Calculates actual proceeds excluding sell postings and Income accounts
    private func calculateActualProceeds(excluding sellPostings: [TransactionPosting],
                                         in ledger: Ledger) -> (proceeds: MultiCurrencyAmount?, result: ValidationResult) {
        var actualProceeds = MultiCurrencyAmount()

        for posting in postings {
            // Skip the sell postings and Income accounts
            if sellPostings.contains(posting) || posting.accountName.accountType == .income {
                continue
            }

            do {
                actualProceeds += try posting.balance(in: ledger)
            } catch {
                let errorMessage = "Failed to calculate balance for posting \(posting): \(error.localizedDescription)"
                return (nil, .invalid(errorMessage))
            }
        }

        return (actualProceeds, .valid)
    }

    /// Validates that expected and actual proceeds match within tolerance
    private func validateProceedsMatch(expected: MultiCurrencyAmount, actual: MultiCurrencyAmount) -> ValidationResult {
        // Compare expected vs actual proceeds
        // Invert expected proceeds to subtract from actual proceeds
        let negativeExpectedProceeds = MultiCurrencyAmount(amounts: expected.amounts.mapValues { -$0 },
                                                            decimalDigits: expected.decimalDigits)
        let difference = actual + negativeExpectedProceeds
        let validation = difference.validateZeroWithTolerance()

        if case .invalid(let error) = validation {
            return .invalid("\(self) sellgains validation failed - \(error)")
        }

        return .valid
    }

    /// Gets the balance of a transaction, should be zero (within tolerance)
    ///
    /// This method just adds up the balances of the individual postings
    ///
    /// - Parameter ledger: ledger to calculate in
    /// - Throws: if the balances cannot be calculated
    /// - Returns: MultiCurrencyAmount
    public func balance(in ledger: Ledger) throws -> MultiCurrencyAmount {
        try postings.map { try $0.balance(in: ledger) }.reduce(MultiCurrencyAmount(), +)
    }

    /// Returns the effect (income + expenses) a transaction has
    ///
    /// This methods adds up the amount of all postings from income and expense accounts in the transaction
    ///
    /// - Parameter ledger: ledger to calculate in
    /// - Throws: if the effect cannot be calculated
    /// - Returns: MultiCurrencyAmount
    public func effect(in ledger: Ledger) throws -> MultiCurrencyAmount {
        try postings.compactMap {
            ($0.accountName.accountType == .income || $0.accountName.accountType == .expense) ? try $0.balance(in: ledger) : nil
        }
        .reduce(MultiCurrencyAmount(), +)
    }

    /// Checks if a Transaction is balanced within the allowed Tolerance
    ///
    /// **Tolerance**: If multiple postings are in the same currency the percision of the number with the best precision is used
    ///  *Note*: Price and cost values are ignored
    ///  *Note*: Tolerance for interger amounts is zero
    ///
    /// - Parameter ledger: ledger to calculate in
    /// - Returns: `ValidationResult`
    private func validateBalance(in ledger: Ledger) -> ValidationResult {
        let amount: MultiCurrencyAmount
        do {
            amount = try balance(in: ledger)
        } catch {
            return .invalid(error.localizedDescription)
        }
        let validation = amount.validateZeroWithTolerance()
        if case .invalid(let error) = validation {
            return .invalid("\(self) is not balanced - \(error)")
        }
        return validation
    }

}

extension Transaction: CustomStringConvertible {

    /// the `String` representation of this transaction for the ledger file
    public var description: String {
        var string = String(describing: metaData)
        postings.forEach { string += "\n\(String(describing: $0))" }
        return string
    }

}

extension Transaction: Equatable {

    /// Checks if two transactions are the same
    ///
    /// This means the `metaData` and all `postings` must be the same
    ///
    /// - Parameters:
    ///   - lhs: first transaction
    ///   - rhs: second transaction
    /// - Returns: if they are the same
    public static func == (lhs: Transaction, rhs: Transaction) -> Bool {
        lhs.metaData == rhs.metaData && lhs.postings == rhs.postings
    }

}

extension Transaction: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(metaData)
        hasher.combine(postings)
    }

}

extension Transaction: Comparable {

    public static func < (lhs: Transaction, rhs: Transaction) -> Bool {
        String(describing: lhs) < String(describing: rhs)
    }

}
