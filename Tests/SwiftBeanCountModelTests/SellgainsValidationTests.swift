//
//  SellgainsValidationTests.swift
//  SwiftBeanCountModelTests
//
//  Created by Steffen Kötte on 2024-08-25.
//  Copyright © 2024 Steffen Kötte. All rights reserved.
//

@testable import SwiftBeanCountModel
import XCTest

final class SellgainsValidationTests: XCTestCase {

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
            XCTFail("Transaction should be valid when proceeds match cost - got error: \(error)")
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
            XCTFail("Transaction should be valid for multiple sales with correct total proceeds - got error: \(error)")
        }
    }

}
