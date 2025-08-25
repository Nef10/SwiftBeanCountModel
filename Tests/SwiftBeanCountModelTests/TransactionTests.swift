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
        try ledger.add(Account(name: TestUtils.cash))
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

    // MARK: - Sellgains Tests

    func testSellgainsValidationDisabled() throws {
        // Test that sellgains validation is skipped when plugin is not enabled
        let ledger = Ledger()
        // Note: NOT adding the sellgains plugin
        
        // Add required accounts with opening dates
        try ledger.add(Account(name: TestUtils.cash, opening: TestUtils.date20170608))
        try ledger.add(Account(name: TestUtils.chequing, opening: TestUtils.date20170608))
        try ledger.add(Account(name: TestUtils.income, opening: TestUtils.date20170608))

        let transactionMetaData = TransactionMetaData(date: TestUtils.date20170608, payee: "Sale", narration: "Sell stocks", flag: .complete, tags: [])
        
        // Sell 10 shares bought at 5 EUR each (expected proceeds: 50 EUR)
        let sellAmount = Amount(number: -10, commoditySymbol: "STOCK", decimalDigits: 0)
        let costAmount = Amount(number: 5, commoditySymbol: TestUtils.eur, decimalDigits: 2)
        let cost = try Cost(amount: costAmount, date: TestUtils.date20170608, label: nil)
        let sellPosting = Posting(accountName: TestUtils.chequing, amount: sellAmount, cost: cost)
        
        // Receive 60 EUR cash (10 EUR more than expected based on cost)
        let proceedsAmount = Amount(number: 60, commoditySymbol: TestUtils.eur, decimalDigits: 2)
        let cashPosting = Posting(accountName: TestUtils.cash, amount: proceedsAmount)
        
        // Capital gain of 10 EUR to balance the transaction
        let gainAmount = Amount(number: -10, commoditySymbol: TestUtils.eur, decimalDigits: 2)
        let incomePosting = Posting(accountName: TestUtils.income, amount: gainAmount)
        
        let transaction = Transaction(metaData: transactionMetaData, postings: [sellPosting, cashPosting, incomePosting])
        
        // Should be valid since sellgains plugin is not enabled
        let validationResult = transaction.validate(in: ledger)
        if case .invalid(let error) = validationResult {
            print("Validation error: \(error)")
            XCTFail("Transaction should be valid when sellgains plugin is not enabled - got error: \(error)")
        }
    }

    func testSellgainsValidationValidSale() throws {
        // Test valid sellgains transaction
        let ledger = Ledger()
        ledger.plugins.append("beancount.plugins.sellgains")
        
        // Add required accounts with opening dates
        try ledger.add(Account(name: TestUtils.cash, opening: TestUtils.date20170608))
        try ledger.add(Account(name: TestUtils.chequing, opening: TestUtils.date20170608))

        let transactionMetaData = TransactionMetaData(date: TestUtils.date20170608, payee: "Sale", narration: "Sell stocks", flag: .complete, tags: [])
        
        // Sell 10 shares bought at 5 EUR each (expected proceeds: 50 EUR)
        let sellAmount = Amount(number: -10, commoditySymbol: "STOCK", decimalDigits: 0)
        let costAmount = Amount(number: 5, commoditySymbol: TestUtils.eur, decimalDigits: 2)
        let cost = try Cost(amount: costAmount, date: TestUtils.date20170608, label: nil)
        let sellPosting = Posting(accountName: TestUtils.chequing, amount: sellAmount, cost: cost)
        
        // Receive exactly 50 EUR cash (correct proceeds: 10 * 5 EUR = 50 EUR)
        let proceedsAmount = Amount(number: 50, commoditySymbol: TestUtils.eur, decimalDigits: 2)
        let cashPosting = Posting(accountName: TestUtils.cash, amount: proceedsAmount)
        
        let transaction = Transaction(metaData: transactionMetaData, postings: [sellPosting, cashPosting])
        ledger.add(transaction)
        
        // Should be valid since proceeds exactly match cost
        let validationResult = transaction.validate(in: ledger)
        if case .invalid(let error) = validationResult {
            print("Validation error: \(error)")
            XCTFail("Transaction should be valid when proceeds match cost - got error: \(error)")
        } else {
            // Success case
        }
    }

    func testSellgainsValidationInvalidSale() throws {
        // Test invalid sellgains transaction with mismatched proceeds
        let ledger = Ledger()
        ledger.plugins.append("beancount.plugins.sellgains")
        
        // Add required accounts with opening dates
        try ledger.add(Account(name: TestUtils.cash, opening: TestUtils.date20170608))
        try ledger.add(Account(name: TestUtils.chequing, opening: TestUtils.date20170608))
        try ledger.add(Account(name: TestUtils.income, opening: TestUtils.date20170608))

        let transactionMetaData = TransactionMetaData(date: TestUtils.date20170608, payee: "Sale", narration: "Sell stocks", flag: .complete, tags: [])
        
        // Sell 10 shares bought at 5 EUR each (expected proceeds: 50 EUR)
        let sellAmount = Amount(number: -10, commoditySymbol: "STOCK", decimalDigits: 0)
        let costAmount = Amount(number: 5, commoditySymbol: TestUtils.eur, decimalDigits: 2)
        let cost = try Cost(amount: costAmount, date: TestUtils.date20170608, label: nil)
        let sellPosting = Posting(accountName: TestUtils.chequing, amount: sellAmount, cost: cost)
        
        // Receive 60 EUR cash (10 EUR more than expected based on cost)
        let proceedsAmount = Amount(number: 60, commoditySymbol: TestUtils.eur, decimalDigits: 2)
        let cashPosting = Posting(accountName: TestUtils.cash, amount: proceedsAmount)
        
        // Capital gain of 10 EUR to balance the transaction
        let gainAmount = Amount(number: -10, commoditySymbol: TestUtils.eur, decimalDigits: 2)
        let incomePosting = Posting(accountName: TestUtils.income, amount: gainAmount)
        
        let transaction = Transaction(metaData: transactionMetaData, postings: [sellPosting, cashPosting, incomePosting])
        
        // Should be invalid due to sellgains mismatch (proceeds don't match cost)
        let validationResult = transaction.validate(in: ledger)
        if case .invalid(let error) = validationResult {
            XCTAssertTrue(error.contains("sellgains validation failed"), "Error should contain sellgains validation failed: \(error)")
            XCTAssertTrue(error.contains("10 EUR too much"), "Error should contain 10 EUR too much: \(error)")
        } else {
            XCTFail("Transaction should be invalid due to sellgains mismatch")
        }
    }

    func testSellgainsValidationWithIncomeAccount() throws {
        // Test sellgains validation with Income account (should be excluded from validation)
        let ledger = Ledger()
        ledger.plugins.append("beancount.plugins.sellgains")
        
        // Add required accounts with opening dates
        try ledger.add(Account(name: TestUtils.cash, opening: TestUtils.date20170608))
        try ledger.add(Account(name: TestUtils.chequing, opening: TestUtils.date20170608))
        try ledger.add(Account(name: TestUtils.income, opening: TestUtils.date20170608))

        let transactionMetaData = TransactionMetaData(date: TestUtils.date20170608, payee: "Sale", narration: "Sell stocks", flag: .complete, tags: [])
        
        // Sell 10 shares bought at 5 EUR each (expected proceeds: 50 EUR)
        let sellAmount = Amount(number: -10, commoditySymbol: "STOCK", decimalDigits: 0)
        let costAmount = Amount(number: 5, commoditySymbol: TestUtils.eur, decimalDigits: 2)
        let cost = try Cost(amount: costAmount, date: TestUtils.date20170608, label: nil)
        let sellPosting = Posting(accountName: TestUtils.chequing, amount: sellAmount, cost: cost)
        
        // Receive exactly 50 EUR cash (matches expected proceeds from cost)
        let proceedsAmount = Amount(number: 50, commoditySymbol: TestUtils.eur, decimalDigits: 2)
        let cashPosting = Posting(accountName: TestUtils.cash, amount: proceedsAmount)
        
        // Income account posting (should be excluded from sellgains validation)
        let gainAmount = Amount(number: 0, commoditySymbol: TestUtils.eur, decimalDigits: 2)
        let incomePosting = Posting(accountName: TestUtils.income, amount: gainAmount)
        
        let transaction = Transaction(metaData: transactionMetaData, postings: [sellPosting, cashPosting, incomePosting])
        ledger.add(transaction)
        
        // Should be valid since Income posting is excluded from sellgains validation
        // and non-Income proceeds (50 EUR) match cost-based expected proceeds (50 EUR)
        let validationResult = transaction.validate(in: ledger)
        if case .invalid(let error) = validationResult {
            print("Validation error: \(error)")
            XCTFail("Transaction should be valid when Income account is excluded from sellgains validation - got error: \(error)")
        }
    }

    func testSellgainsValidationNoSellPostings() throws {
        // Test that sellgains validation passes when there are no sell postings
        let ledger = Ledger()
        ledger.plugins.append("beancount.plugins.sellgains")
        
        // Add required accounts with opening dates
        try ledger.add(Account(name: TestUtils.cash, opening: TestUtils.date20170608))
        try ledger.add(Account(name: TestUtils.chequing, opening: TestUtils.date20170608))

        let transactionMetaData = TransactionMetaData(date: TestUtils.date20170608, payee: "Purchase", narration: "Buy stocks", flag: .complete, tags: [])
        
        // Buy 10 shares at 5 EUR each (positive amount, not a sale)
        let buyAmount = Amount(number: 10, commoditySymbol: "STOCK", decimalDigits: 0)
        let costAmount = Amount(number: 5, commoditySymbol: TestUtils.eur, decimalDigits: 2)
        let cost = try Cost(amount: costAmount, date: TestUtils.date20170608, label: nil)
        let buyPosting = Posting(accountName: TestUtils.chequing, amount: buyAmount, cost: cost)
        
        // Pay 50 EUR cash
        let paymentAmount = Amount(number: -50, commoditySymbol: TestUtils.eur, decimalDigits: 2)
        let cashPosting = Posting(accountName: TestUtils.cash, amount: paymentAmount)
        
        let transaction = Transaction(metaData: transactionMetaData, postings: [buyPosting, cashPosting])
        ledger.add(transaction)
        
        // Should be valid since there are no sell postings (negative amounts with cost)
        let validationResult = transaction.validate(in: ledger)
        if case .invalid(let error) = validationResult {
            print("Validation error: \(error)")
            XCTFail("Transaction should be valid when there are no sell postings - got error: \(error)")
        }
    }

    func testSellgainsValidationMultipleSales() throws {
        // Test sellgains validation with multiple sell postings
        let ledger = Ledger()
        ledger.plugins.append("beancount.plugins.sellgains")
        
        // Add required accounts with opening dates
        try ledger.add(Account(name: TestUtils.cash, opening: TestUtils.date20170608))
        try ledger.add(Account(name: TestUtils.chequing, opening: TestUtils.date20170608))

        let transactionMetaData = TransactionMetaData(date: TestUtils.date20170608, payee: "Sale", narration: "Sell multiple stocks", flag: .complete, tags: [])
        
        // Sell 5 shares of STOCK1 bought at 10 EUR each (expected: 50 EUR)
        let sell1Amount = Amount(number: -5, commoditySymbol: "STOCK1", decimalDigits: 0)
        let cost1Amount = Amount(number: 10, commoditySymbol: TestUtils.eur, decimalDigits: 2)
        let cost1 = try Cost(amount: cost1Amount, date: TestUtils.date20170608, label: nil)
        let sell1Posting = Posting(accountName: TestUtils.chequing, amount: sell1Amount, cost: cost1)
        
        // Sell 3 shares of STOCK2 bought at 20 EUR each (expected: 60 EUR)
        let sell2Amount = Amount(number: -3, commoditySymbol: "STOCK2", decimalDigits: 0)
        let cost2Amount = Amount(number: 20, commoditySymbol: TestUtils.eur, decimalDigits: 2)
        let cost2 = try Cost(amount: cost2Amount, date: TestUtils.date20170608, label: nil)
        let sell2Posting = Posting(accountName: TestUtils.chequing, amount: sell2Amount, cost: cost2)
        
        // Receive total proceeds: (5 * 10) + (3 * 20) = 110 EUR (matches expected cost)
        let proceedsAmount = Amount(number: 110, commoditySymbol: TestUtils.eur, decimalDigits: 2)
        let cashPosting = Posting(accountName: TestUtils.cash, amount: proceedsAmount)
        
        let transaction = Transaction(metaData: transactionMetaData, postings: [sell1Posting, sell2Posting, cashPosting])
        ledger.add(transaction)
        
        // Should be valid since total proceeds match total cost
        let validationResult = transaction.validate(in: ledger)
        if case .invalid(let error) = validationResult {
            print("Validation error: \(error)")
            XCTFail("Transaction should be valid for multiple sales with correct total proceeds - got error: \(error)")
        }
    }

}
