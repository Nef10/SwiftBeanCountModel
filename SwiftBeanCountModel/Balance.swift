//
//  Balance.swift
//  SwiftBeanCountModel
//
//  Created by Steffen Kötte on 2018-05-13.
//  Copyright © 2018 Steffen Kötte. All rights reserved.
//

import Foundation

/// An assert that the balance of a given commodity is correct for the accout at the end of the given day
public struct Balance {

    /// Date of the Balance
    public let date: Date

    /// `Account` of the Balance
    public let account: Account

    /// `Amount` of the Balance
    public let amount: Amount

    /// Create a Balance
    ///
    /// - Parameters:
    ///   - date: date of the balance
    ///   - account: account
    ///   - amount: amount
    public init(date: Date, account: Account, amount: Amount) {
        self.date = date
        self.account = account
        self.amount = amount
    }

}

extension Balance: CustomStringConvertible {

    /// Returns the price string for the ledger.
    public var description: String {
        return "\(type(of: self).dateFormatter.string(from: date)) balance \(account.name) \(amount)"
    }

    static private let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter
    }()

}

extension Balance: Equatable {

    /// Retuns if the two prices are equal
    ///
    /// - Parameters:
    ///   - lhs: price 1
    ///   - rhs: price 2
    /// - Returns: true if the prices are equal, false otherwise
    public static func == (lhs: Balance, rhs: Balance) -> Bool {
        return lhs.date == rhs.date && lhs.account == rhs.account && lhs.amount == rhs.amount
    }

}
