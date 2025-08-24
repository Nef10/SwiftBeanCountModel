//
//  TransactionTests.swift
//  SwiftBeanCountModelTests
//
//  Created by Steffen Kötte on 2017-06-18.
//  Copyright © 2017 Steffen Kötte. All rights reserved.
//

@testable import SwiftBeanCountModel
import XCTest

final class TransactionTests: XCTestCase {

    private var transaction1WithoutPosting: Transaction!
    private var transaction2WithoutPosting: Transaction!
    private var transaction1WithPosting1: Transaction!
    private var transaction3WithPosting1: Transaction!
    private var transaction1WithPosting1And2: Transaction!
    private var transaction2WithPosting1And2: Transaction!
    private var account1: Account?
    private var account2: Account?
    private let ledger = Ledger()

    override func setUpWithError() throws {
        account1 = Account(name: TestUtils.cash, opening: TestUtils.date20170608)
        account2 = Account(name: TestUtils.chequing, opening: TestUtils.date20170608)
        try ledger.add(account1!)
        try ledger.add(account2!)
        let transactionMetaData1 = TransactionMetaData(date: TestUtils.date20170608, payee: "Payee", narration: "Narration", flag: Flag.complete, tags: [])
        let transactionMetaData2 = TransactionMetaData(date: TestUtils.date20170608, payee: "Payee", narration: "Narration", flag: Flag.complete, tags: [])
        let transactionMetaData3 = TransactionMetaData(date: TestUtils.date20170608, payee: "Payee", narration: "Narration", flag: Flag.incomplete, tags: [])

        let amount1 = Amount(number: Decimal(10), commoditySymbol: TestUtils.eur)
        let amount2 = Amount(number: Decimal(-10), commoditySymbol: TestUtils.eur)

        transaction1WithoutPosting = Transaction(metaData: transactionMetaData1, postings: [])

        transaction2WithoutPosting = Transaction(metaData: transactionMetaData2, postings: [])

        let transaction1Posting1 = Posting(accountName: TestUtils.cash, amount: amount1)
        transaction1WithPosting1 = Transaction(metaData: transactionMetaData1, postings: [transaction1Posting1])

        let transaction3Posting1 = Posting(accountName: TestUtils.chequing, amount: amount1)
        transaction3WithPosting1 = Transaction(metaData: transactionMetaData3, postings: [transaction3Posting1])

        let transaction1WithPosting1And2Posting1 = Posting(accountName: TestUtils.cash, amount: amount1)
        let transaction1WithPosting1And2Posting2 = Posting(accountName: TestUtils.chequing, amount: amount2)
        transaction1WithPosting1And2 = Transaction(metaData: transactionMetaData1, postings: [transaction1WithPosting1And2Posting1, transaction1WithPosting1And2Posting2])

        let transaction2WithPosting1And2Posting1 = Posting(accountName: TestUtils.cash, amount: amount1)
        let transaction2WithPosting1And2Posting2 = Posting(accountName: TestUtils.chequing, amount: amount2)
        transaction2WithPosting1And2 = Transaction(metaData: transactionMetaData1, postings: [transaction2WithPosting1And2Posting1, transaction2WithPosting1And2Posting2])

        ledger.add(transaction1WithoutPosting)
        ledger.add(transaction2WithoutPosting)
        ledger.add(transaction1WithPosting1)
        ledger.add(transaction3WithPosting1)
        ledger.add(transaction1WithPosting1And2)
        ledger.add(transaction2WithPosting1And2)
        try super.setUpWithError()
    }

    func testDescriptionWithoutPosting() {
        XCTAssertEqual(String(describing: transaction1WithoutPosting!), String(describing: transaction1WithoutPosting!.metaData))
    }

    func testDescriptionWithPostings() {
        XCTAssertEqual(String(describing: transaction1WithPosting1And2!),
                       String(describing: transaction1WithPosting1And2!.metaData) + "\n"
                         + String(describing: transaction1WithPosting1And2!.postings[0]) + "\n"
                         + String(describing: transaction1WithPosting1And2!.postings[1]))
    }

    func testEqual() {
        XCTAssertEqual(transaction1WithoutPosting, transaction2WithoutPosting)
        XCTAssertFalse(transaction1WithoutPosting < transaction2WithoutPosting)
        XCTAssertFalse(transaction2WithoutPosting < transaction1WithoutPosting)
    }

    func testEqualWithPostings() {
        XCTAssertEqual(transaction1WithPosting1And2, transaction2WithPosting1And2)
        XCTAssertFalse(transaction1WithPosting1And2 < transaction2WithPosting1And2)
        XCTAssertFalse(transaction2WithPosting1And2 < transaction1WithPosting1And2)
    }

    func testEqualRespectsPostings() {
        XCTAssertNotEqual(transaction1WithPosting1, transaction1WithPosting1And2)
        XCTAssert(transaction1WithPosting1 < transaction1WithPosting1And2)
        XCTAssertFalse(transaction1WithPosting1And2 < transaction1WithPosting1)
    }

    func testEqualRespectsTransactionMetaData() {
        XCTAssertNotEqual(transaction1WithPosting1, transaction3WithPosting1)
        XCTAssertFalse(transaction1WithPosting1 < transaction3WithPosting1)
        XCTAssert(transaction3WithPosting1 < transaction1WithPosting1)
    }

    func testIsValid() {
        guard case .valid = transaction2WithPosting1And2!.validate(in: ledger) else {
            XCTFail("\(transaction2WithPosting1And2!) is not valid")
            return
        }
    }

    func testIsValidFromOutsideLedger() {
        let ledger = Ledger()
        guard case .invalid = transaction2WithPosting1And2!.validate(in: ledger) else {
            XCTFail("\(transaction2WithPosting1And2!) is valid")
            return
        }
    }

    func testIsValidWithoutPosting() {
        if case .invalid(let error) = transaction1WithoutPosting!.validate(in: ledger) {
            XCTAssertEqual(error, "2017-06-08 * \"Payee\" \"Narration\" has no postings")
        } else {
            XCTFail("\(transaction1WithoutPosting!) is valid")
        }
    }

    func testIsValidInvalidPosting() throws {
        // Accounts are not opened
        let ledger = Ledger()
        try ledger.add(Account(name: TestUtils.cash, opening: TestUtils.date20170608))
        try ledger.add(Account(name: TestUtils.chequing, opening: TestUtils.date20170608))
        ledger.add(transaction1WithPosting1And2)
        if case .invalid(let error) = transaction1WithPosting1And2.validate(in: ledger) {
            XCTAssertEqual(error, """
                2017-06-08 * "Payee" "Narration"
                  Assets:Cash 10 EUR
                  Assets:Chequing -10 EUR was posted while the accout Assets:Cash was closed
                """)
        } else {
            XCTFail("\(transaction1WithPosting1And2!) is valid")
        }
    }

    func testIsValidUnbalanced() {
        if case .invalid(let error) = transaction1WithPosting1!.validate(in: ledger) {
            XCTAssertEqual(error, """
                2017-06-08 * "Payee" "Narration"
                  Assets:Cash 10 EUR is not balanced - 10 EUR too much (0 tolerance)
                """)
        } else {
            XCTFail("\(transaction1WithPosting1!) is valid")
        }
    }

    func testIsValidUnbalancedIntegerTolerance() {
        // Assets:Cash     -1  EUR
        // Assets:Checking 10.00000 CAD @ 0.101 EUR

        let transactionMetaData = TransactionMetaData(date: TestUtils.date20170608, payee: "Payee", narration: "Narration", flag: Flag.complete, tags: [])
        let amount1 = Amount(number: Decimal(-1), commoditySymbol: TestUtils.eur, decimalDigits: 0)
        let amount2 = Amount(number: Decimal(10.000_00), commoditySymbol: TestUtils.cad, decimalDigits: 5)
        // 0.101
        let price = Amount(number: Decimal(sign: FloatingPointSign.plus, exponent: -3, significand: Decimal(101)), commoditySymbol: TestUtils.eur, decimalDigits: 3)
        let posting1 = Posting(accountName: TestUtils.cash, amount: amount1)
        let posting2 = Posting(accountName: TestUtils.chequing, amount: amount2, price: price)
        let transaction = Transaction(metaData: transactionMetaData, postings: [posting1, posting2])
        // 10 * 0.101  = 1.01
        // |1 - 1.01| = 0.01
        // -1 EUR has 0 decimal digits -> tolerance is 0 !
        // (Percision of price is irrelevant, percision of CAD is not used because no posting in CAD)
        // 0.01 > 0 -> is invalid
        if case .invalid(let error) = transaction.validate(in: ledger) {
            XCTAssertEqual(error, """
                2017-06-08 * "Payee" "Narration"
                  Assets:Cash -1 EUR
                  Assets:Chequing 10.00000 CAD @ 0.101 EUR is not balanced - 0.01 EUR too much (0 tolerance)
                """)
        } else {
            XCTFail("\(transaction) is valid")
        }
    }

    func testIsValidUnbalancedTolerance() {
        // Assets:Cash     -8.52  EUR
        // Assets:Checking 10.00000 CAD @ 0.85251 EUR

        let transactionMetaData = TransactionMetaData(date: TestUtils.date20170608, payee: "Payee", narration: "Narration", flag: Flag.complete, tags: [])
        // -8.52
        let amount1 = Amount(number: Decimal(sign: FloatingPointSign.minus, exponent: -2, significand: Decimal(852)), commoditySymbol: TestUtils.eur, decimalDigits: 2)
        let amount2 = Amount(number: Decimal(10.000_00), commoditySymbol: TestUtils.cad, decimalDigits: 5)
        // 0.85251
        let price = Amount(number: Decimal(sign: FloatingPointSign.plus, exponent: -5, significand: Decimal(85_251)), commoditySymbol: TestUtils.eur, decimalDigits: 5)
        let posting1 = Posting(accountName: TestUtils.cash, amount: amount1)
        let posting2 = Posting(accountName: TestUtils.chequing, amount: amount2, price: price)
        let transaction = Transaction(metaData: transactionMetaData, postings: [posting1, posting2])

        // 10 * 0.85251  = 8.5251
        // |8.52 - 8.5251| = 0.0051
        // -8.52 EUR has 2 decimal digits -> tolerance is 0.005
        // (Percision of price is irrelevant, percision of CAD is not used because no posting in CAD)
        // 0.0051 > 0.005 -> is invalid
        if case .invalid(let error) = transaction.validate(in: ledger) {
            XCTAssertEqual(error, """
                2017-06-08 * "Payee" "Narration"
                  Assets:Cash -8.52 EUR
                  Assets:Chequing 10.00000 CAD @ 0.85251 EUR is not balanced - 0.0051 EUR too much (0.005 tolerance)
                """)
        } else {
            XCTFail("\(transaction) is valid")
        }
    }

    func testIsValidUnusedCommodity() {
        // Assets:Checking 10.00000 CAD @ 0.85251 EUR

        let transactionMetaData = TransactionMetaData(date: TestUtils.date20170608, payee: "Payee", narration: "Narration", flag: Flag.complete, tags: [])
        let amount1 = Amount(number: Decimal(10.000_00), commoditySymbol: TestUtils.cad, decimalDigits: 5)
        // 0.85251
        let price = Amount(number: Decimal(sign: FloatingPointSign.plus, exponent: -5, significand: Decimal(85_251)), commoditySymbol: TestUtils.eur, decimalDigits: 5)
        let posting1 = Posting(accountName: TestUtils.cash, amount: amount1, price: price)
        let transaction = Transaction(metaData: transactionMetaData, postings: [posting1])

        if case .invalid(let error) = transaction.validate(in: ledger) {
            XCTAssertEqual(error, """
                2017-06-08 * "Payee" "Narration"
                  Assets:Cash 10.00000 CAD @ 0.85251 EUR is not balanced - 8.5251 EUR too much (0 tolerance)
                """)
        } else {
            XCTFail("\(transaction) is valid")
        }
    }

    func testIsValidBalancedTolerance() {
        // Assets:Cash     -8.52  EUR
        // Assets:Checking 10.00000 CAD @ 0.85250 EUR

        let transactionMetaData = TransactionMetaData(date: TestUtils.date20170608, payee: "Payee", narration: "Narration", flag: Flag.complete, tags: [])
        let amount1 = Amount(number: Decimal(sign: FloatingPointSign.minus, exponent: -2, significand: Decimal(852)), commoditySymbol: TestUtils.eur, decimalDigits: 2)
        let amount2 = Amount(number: Decimal(10.000_00), commoditySymbol: TestUtils.cad, decimalDigits: 5)
        let price = Amount(number: Decimal(sign: FloatingPointSign.plus, exponent: -5, significand: Decimal(85_250)), commoditySymbol: TestUtils.eur, decimalDigits: 5)
        let posting1 = Posting(accountName: TestUtils.cash, amount: amount1)
        let posting2 = Posting(accountName: TestUtils.chequing, amount: amount2, price: price)
        let transaction = Transaction(metaData: transactionMetaData, postings: [posting1, posting2])
        ledger.add(transaction)

        // 10 * 0.8525  = 8.525
        // |8.52 - 8.525| = 0.005
        // -8.52 EUR has 2 decimal digits -> tolerance is 0.005
        // (Percision of price is irrelevant, percision of CAD is not used because no posting in CAD)
        // 0.005 <= 0.005 -> is valid
        guard case .valid = transaction.validate(in: ledger) else {
            XCTFail("\(transaction) is not valid")
            return
        }
    }

    func testIsValidBalancedToleranceCost() throws {
        // Assets:Cash     -8.52  EUR
        // Assets:Checking 10.00000 CAD { 0.85250 EUR }

        let transactionMetaData = TransactionMetaData(date: TestUtils.date20170608, payee: "Payee", narration: "Narration", flag: Flag.complete, tags: [])
        let amount1 = Amount(number: Decimal(sign: FloatingPointSign.minus, exponent: -2, significand: Decimal(852)), commoditySymbol: TestUtils.eur, decimalDigits: 2)
        let amount2 = Amount(number: Decimal(10.000_00), commoditySymbol: TestUtils.cad, decimalDigits: 5)
        let costAmount = Amount(number: Decimal(sign: FloatingPointSign.plus, exponent: -5, significand: Decimal(85_250)),
                                commoditySymbol: TestUtils.eur,
                                decimalDigits: 5)
        let cost = try Cost(amount: costAmount, date: TestUtils.date20170608, label: nil)
        let posting1 = Posting(accountName: TestUtils.cash, amount: amount1)
        let posting2 = Posting(accountName: TestUtils.chequing, amount: amount2, price: nil, cost: cost)
        let transaction = Transaction(metaData: transactionMetaData, postings: [posting1, posting2])
        ledger.add(transaction)

        // 10 * 0.8525  = 8.525
        // |8.52 - 8.525| = 0.005
        // -8.52 EUR has 2 decimal digits -> tolerance is 0.005
        // (Percision of price is irrelevant, percision of CAD is not used because no posting in CAD)
        // 0.005 <= 0.005 -> is valid
        guard case .valid = transaction.validate(in: ledger) else {
            XCTFail("\(transaction) is not valid")
            return
        }
    }

    func testIsValidUnbalancedToleranceCost() throws {
        // Assets:Cash     -8.52  EUR
        // Assets:Checking 10.00000 CAD { 0.85251 EUR }

        let transactionMetaData = TransactionMetaData(date: TestUtils.date20170608, payee: "Payee", narration: "Narration", flag: Flag.complete, tags: [])
        // -8.52
        let amount1 = Amount(number: Decimal(sign: FloatingPointSign.minus, exponent: -2, significand: Decimal(852)), commoditySymbol: TestUtils.eur, decimalDigits: 2)
        let amount2 = Amount(number: Decimal(10.000_00), commoditySymbol: TestUtils.cad, decimalDigits: 5)
        // 0.85251
        let costAmount = Amount(number: Decimal(sign: FloatingPointSign.plus, exponent: -5, significand: Decimal(85_251)),
                                commoditySymbol: TestUtils.eur,
                                decimalDigits: 5)
        let cost = try Cost(amount: costAmount, date: nil, label: nil)
        let posting1 = Posting(accountName: TestUtils.cash, amount: amount1)
        let posting2 = Posting(accountName: TestUtils.chequing, amount: amount2, price: nil, cost: cost)
        let transaction = Transaction(metaData: transactionMetaData, postings: [posting1, posting2])

        // 10 * 0.85251  = 8.5251
        // |8.52 - 8.5251| = 0.0051
        // -8.52 EUR has 2 decimal digits -> tolerance is 0.005
        // (Percision of cost is irrelevant, percision of CAD is not used because no posting in CAD)
        // 0.0051 > 0.005 -> is invalid
        if case .invalid(let error) = transaction.validate(in: ledger) {
            XCTAssertEqual(error, """
                2017-06-08 * "Payee" "Narration"
                  Assets:Cash -8.52 EUR
                  Assets:Chequing 10.00000 CAD {0.85251 EUR} is not balanced - 0.0051 EUR too much (0.005 tolerance)
                """)
        } else {
            XCTFail("\(transaction) is valid")
        }
    }

    func testEffectZeroPrice() throws {
        // Assets:Cash     -8.52  EUR
        // Assets:Checking 10.00000 CAD @ 0.85250 EUR

        let transactionMetaData = TransactionMetaData(date: TestUtils.date20170608, payee: "Payee", narration: "Narration", flag: Flag.complete, tags: [])
        let amount1 = Amount(number: Decimal(sign: FloatingPointSign.minus, exponent: -2, significand: Decimal(852)), commoditySymbol: TestUtils.eur, decimalDigits: 2)
        let amount2 = Amount(number: Decimal(10.000_00), commoditySymbol: TestUtils.cad, decimalDigits: 5)
        let price = Amount(number: Decimal(sign: FloatingPointSign.plus, exponent: -5, significand: Decimal(85_250)), commoditySymbol: TestUtils.eur, decimalDigits: 5)
        let posting1 = Posting(accountName: TestUtils.cash, amount: amount1)
        let posting2 = Posting(accountName: TestUtils.chequing, amount: amount2, price: price)
        let transaction = Transaction(metaData: transactionMetaData, postings: [posting1, posting2])
        ledger.add(transaction)

        guard case .valid = try transaction.effect(in: ledger).validateZeroWithTolerance() else {
            XCTFail("\(transaction) effect is not zero")
            return
        }
    }

    func testEffectCost() throws {
        // Income:Test     -8.52  EUR
        // Assets:Checking 10.00000 CAD { 0.85250 EUR }

        let transactionMetaData = TransactionMetaData(date: TestUtils.date20170608, payee: "Payee", narration: "Narration", flag: Flag.complete, tags: [])
        let amount1 = Amount(number: Decimal(sign: FloatingPointSign.minus, exponent: -2, significand: Decimal(852)), commoditySymbol: TestUtils.eur, decimalDigits: 2)
        let amount2 = Amount(number: Decimal(10.000_00), commoditySymbol: TestUtils.cad, decimalDigits: 5)
        let costAmount = Amount(number: Decimal(sign: FloatingPointSign.plus, exponent: -5, significand: Decimal(85_250)),
                                commoditySymbol: TestUtils.eur,
                                decimalDigits: 5)
        let cost = try Cost(amount: costAmount, date: TestUtils.date20170608, label: nil)
        let posting1 = Posting(accountName: TestUtils.income, amount: amount1)
        let posting2 = Posting(accountName: TestUtils.chequing, amount: amount2, price: nil, cost: cost)
        let transaction = Transaction(metaData: transactionMetaData, postings: [posting1, posting2])
        ledger.add(transaction)

        let effect = try transaction.effect(in: ledger)
        XCTAssertEqual(effect.amounts.count, 1)
        guard case .valid = effect.validateOneAmountWithTolerance(amount: amount1) else {
            XCTFail("\(transaction) effect is not the expected value")
            return
        }
    }

    func testValidateCommodityUsageDatesWithoutPlugin() throws {
        // Test that commodity usage dates are not validated when plugin is not enabled
        let ledger = Ledger()

        // Add commodities with opening dates after the transaction date
        let eurCommodity = Commodity(symbol: TestUtils.eur, opening: TestUtils.date20170609)
        let cadCommodity = Commodity(symbol: TestUtils.cad, opening: TestUtils.date20170609)
        try ledger.add(eurCommodity)
        try ledger.add(cadCommodity)

        // Add accounts to the ledger
        let cashAccount = Account(name: TestUtils.cash, opening: TestUtils.date20170608)
        let chequingAccount = Account(name: TestUtils.chequing, opening: TestUtils.date20170608)
        try ledger.add(cashAccount)
        try ledger.add(chequingAccount)

        // Create transaction before commodity opening dates
        let transactionMetaData = TransactionMetaData(date: TestUtils.date20170608, payee: "Payee", narration: "Narration", flag: Flag.complete, tags: [])
        let posting1 = Posting(accountName: TestUtils.cash, amount: Amount(number: Decimal(10), commoditySymbol: TestUtils.eur))
        let posting2 = Posting(accountName: TestUtils.chequing, amount: Amount(number: Decimal(-10), commoditySymbol: TestUtils.eur))
        let transaction = Transaction(metaData: transactionMetaData, postings: [posting1, posting2])

        // Should be valid since plugin is not enabled
        guard case .valid = transaction.validate(in: ledger) else {
            XCTFail("Transaction should be valid when check_commodity plugin is not enabled")
            return
        }
    }

    func testValidateCommodityUsageDatesWithPlugin() throws {
        // Test that commodity usage dates are validated when plugin is enabled
        let ledger = Ledger()
        ledger.plugins.append("beancount.plugins.check_commodity")

        // Add commodities with opening dates after the transaction date
        let eurCommodity = Commodity(symbol: TestUtils.eur, opening: TestUtils.date20170609)
        let cadCommodity = Commodity(symbol: TestUtils.cad, opening: TestUtils.date20170609)
        try ledger.add(eurCommodity)
        try ledger.add(cadCommodity)

        // Add accounts to the ledger
        let cashAccount = Account(name: TestUtils.cash, opening: TestUtils.date20170608)
        let chequingAccount = Account(name: TestUtils.chequing, opening: TestUtils.date20170608)
        try ledger.add(cashAccount)
        try ledger.add(chequingAccount)

        // Create transaction before commodity opening dates
        let transactionMetaData = TransactionMetaData(date: TestUtils.date20170608, payee: "Payee", narration: "Narration", flag: Flag.complete, tags: [])
        let posting1 = Posting(accountName: TestUtils.cash, amount: Amount(number: Decimal(10), commoditySymbol: TestUtils.eur))
        let posting2 = Posting(accountName: TestUtils.chequing, amount: Amount(number: Decimal(-10), commoditySymbol: TestUtils.eur))
        let transaction = Transaction(metaData: transactionMetaData, postings: [posting1, posting2])

        // Should be invalid since commodity is used before opening
        if case .invalid(let error) = transaction.validate(in: ledger) {
            XCTAssertTrue(error.contains("EUR used on 2017-06-08 before its opening date of 2017-06-09"))
        } else {
            XCTFail("Transaction should be invalid when commodity is used before opening date")
        }
    }

    func testValidatePriceCommodityUsageDates() throws {
        // Test validation of price commodity usage dates
        let ledger = Ledger()
        ledger.plugins.append("beancount.plugins.check_commodity")

        // Add commodities with opening dates
        let eurCommodity = Commodity(symbol: TestUtils.eur, opening: TestUtils.date20170609)
        let cadCommodity = Commodity(symbol: TestUtils.cad, opening: TestUtils.date20170608)
        try ledger.add(eurCommodity)
        try ledger.add(cadCommodity)

        // Add accounts to the ledger
        let cashAccount = Account(name: TestUtils.cash, opening: TestUtils.date20170608)
        let chequingAccount = Account(name: TestUtils.chequing, opening: TestUtils.date20170608)
        try ledger.add(cashAccount)
        try ledger.add(chequingAccount)

        // Create transaction with price before EUR opening date
        let transactionMetaData = TransactionMetaData(date: TestUtils.date20170608, payee: "Payee", narration: "Narration", flag: Flag.complete, tags: [])
        let price = Amount(number: Decimal(1.2), commoditySymbol: TestUtils.eur) // EUR opens on 2017-06-09
        let posting1 = Posting(accountName: TestUtils.cash, amount: Amount(number: Decimal(10), commoditySymbol: TestUtils.cad), price: price)
        let posting2 = Posting(accountName: TestUtils.chequing, amount: Amount(number: Decimal(-12), commoditySymbol: TestUtils.eur))
        let transaction = Transaction(metaData: transactionMetaData, postings: [posting1, posting2])

        // Should be invalid since EUR (price commodity) is used before opening
        if case .invalid(let error) = transaction.validate(in: ledger) {
            XCTAssertTrue(error.contains("EUR used on 2017-06-08 before its opening date of 2017-06-09"))
        } else {
            XCTFail("Transaction should be invalid when price commodity is used before opening date")
        }
    }

    func testValidateCostCommodityUsageDates() throws {
        // Test validation of cost commodity usage dates
        let ledger = Ledger()
        ledger.plugins.append("beancount.plugins.check_commodity")

        // Add commodities with opening dates
        let eurCommodity = Commodity(symbol: TestUtils.eur, opening: TestUtils.date20170609)
        let cadCommodity = Commodity(symbol: TestUtils.cad, opening: TestUtils.date20170608)
        try ledger.add(eurCommodity)
        try ledger.add(cadCommodity)

        // Add accounts to the ledger
        let cashAccount = Account(name: TestUtils.cash, opening: TestUtils.date20170608)
        let chequingAccount = Account(name: TestUtils.chequing, opening: TestUtils.date20170608)
        try ledger.add(cashAccount)
        try ledger.add(chequingAccount)

        // Create transaction with cost before EUR opening date
        let transactionMetaData = TransactionMetaData(date: TestUtils.date20170608, payee: "Payee", narration: "Narration", flag: Flag.complete, tags: [])
        let costAmount = Amount(number: Decimal(1.2), commoditySymbol: TestUtils.eur) // EUR opens on 2017-06-09
        let cost = try Cost(amount: costAmount, date: TestUtils.date20170608, label: nil)
        let posting1 = Posting(accountName: TestUtils.cash, amount: Amount(number: Decimal(10), commoditySymbol: TestUtils.cad), cost: cost)
        let posting2 = Posting(accountName: TestUtils.chequing, amount: Amount(number: Decimal(-12), commoditySymbol: TestUtils.eur))
        let transaction = Transaction(metaData: transactionMetaData, postings: [posting1, posting2])

        // Should be invalid since EUR (cost commodity) is used before opening
        if case .invalid(let error) = transaction.validate(in: ledger) {
            XCTAssertTrue(error.contains("EUR used on 2017-06-08 before its opening date of 2017-06-09"))
        } else {
            XCTFail("Transaction should be invalid when cost commodity is used before opening date")
        }
    }

    func testValidateCommodityUsageDatesValid() throws {
        // Test that validation passes when commodities are used on or after opening dates
        let ledger = Ledger()
        ledger.plugins.append("beancount.plugins.check_commodity")

        // Add commodities with opening dates before or on the transaction date
        let eurCommodity = Commodity(symbol: TestUtils.eur, opening: TestUtils.date20170608)
        let cadCommodity = Commodity(symbol: TestUtils.cad, opening: TestUtils.date20170608)
        try ledger.add(eurCommodity)
        try ledger.add(cadCommodity)

        // Add accounts to the ledger
        let cashAccount = Account(name: TestUtils.cash, opening: TestUtils.date20170608)
        let chequingAccount = Account(name: TestUtils.chequing, opening: TestUtils.date20170608)
        try ledger.add(cashAccount)
        try ledger.add(chequingAccount)

        // Create transaction on the commodity opening dates
        let transactionMetaData = TransactionMetaData(date: TestUtils.date20170608, payee: "Payee", narration: "Narration", flag: Flag.complete, tags: [])
        let posting1 = Posting(accountName: TestUtils.cash, amount: Amount(number: Decimal(10), commoditySymbol: TestUtils.eur))
        let posting2 = Posting(accountName: TestUtils.chequing, amount: Amount(number: Decimal(-10), commoditySymbol: TestUtils.eur))
        let transaction = Transaction(metaData: transactionMetaData, postings: [posting1, posting2])

        // Should be valid since commodities are used on or after opening dates
        guard case .valid = transaction.validate(in: ledger) else {
            XCTFail("Transaction should be valid when commodities are used on or after opening dates")
            return
        }
    }

}
