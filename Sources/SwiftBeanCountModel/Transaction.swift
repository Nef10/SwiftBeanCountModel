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

    /// Checks if a Transaction is balanced within the allowed Tolerance
    ///
    /// **Tolerance**: If multiple postings are in the same currency the percision of the number with the best precision is used
    ///  *Note*: Price and cost values are ignored
    ///  *Note*: Tolerance for interger amounts is zero
    ///
    /// - Returns: `ValidationResult`
    private func validateBalance(in ledger: Ledger) -> ValidationResult {
        var amount = MultiCurrencyAmount()
        for posting in postings {
            if let cost = posting.cost {
                if let postingAmount = ledger.postingPrices[self]?[posting] {
                    let postingAmount = MultiCurrencyAmount(amounts: postingAmount.amounts,
                                                            decimalDigits: [posting.amount.commoditySymbol: posting.amount.decimalDigits])
                    amount += postingAmount
                } else if let costAmount = cost.amount, costAmount.number > 0 {
                    let postingAmount = MultiCurrencyAmount(amounts: [costAmount.commoditySymbol: costAmount.number * posting.amount.number],
                                                            decimalDigits: [posting.amount.commoditySymbol: posting.amount.decimalDigits])
                    amount += postingAmount
                } else {
                    return .invalid("Posting \(posting) of transaction \(self) does not have an amount in the cost and add to the inventory")
                }
            } else if let price = posting.price {
                let postingAmount = MultiCurrencyAmount(amounts: [price.commoditySymbol: price.number * posting.amount.number],
                                                        decimalDigits: [posting.amount.commoditySymbol: posting.amount.decimalDigits])
                amount += postingAmount
            } else {
                amount += posting.amount
            }
        }
        let validation = amount.validateZeroWithTolerance()
        if case .invalid(let error) = validation {
            return .invalid("\(self) is not balanced - \(error)")
        }
        return validation
    }

}

extension Transaction: CustomStringConvertible {

    /// the `String representation of this transaction for the ledger file
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
        hasher.combine(description)
    }

}

extension Transaction: Comparable {

    public static func < (lhs: Transaction, rhs: Transaction) -> Bool {
        String(describing: lhs) < String(describing: rhs)
    }

}