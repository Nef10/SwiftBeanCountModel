//
//  AccountNameTests.swift
//  SwiftBeanCountModelTests
//
//  Created by Steffen Kötte on 2020-05-22.
//  Copyright © 2020 Steffen Kötte. All rights reserved.
//

@testable import SwiftBeanCountModel
import XCTest

class AccountNameTests: XCTestCase {

    let invalidNames = ["Assets", "Liabilities", "Income", "Expenses", "Equity", "Assets:", "Assets:Test:", "Assets:Test:", "Assets:Test::Test", "💰", ""]
    let validNames = ["Assets:Cash", "Assets:Cash:Test:Test:A", "Assets:Cash:💰", "Assets:Cash:Ca💰h:Test:💰", "Liabilities:Test", "Income:Test", "Expenses:Test", "Equity:Test"]

    func testInitNames() {
        for name in validNames {
            XCTAssertNoThrow(try AccountName(name))
        }
        for name in invalidNames {
            XCTAssertThrowsError(try AccountName(name)) {
                XCTAssertEqual($0.localizedDescription, "Invalid Account name: \(name)")
            }
        }
    }

    func testIsAccountNameVaild() {
        for name in validNames {
            XCTAssert(AccountName.isNameValid(name))
        }
        for name in invalidNames {
            XCTAssertFalse(AccountName.isNameValid(name))
        }
    }

    func testNameItem() {
        XCTAssertEqual(try! AccountName("Assets:Cash").nameItem, "Cash")
        XCTAssertEqual(try! AccountName("Assets:A:B:C:D:E:Cash").nameItem, "Cash")
        XCTAssertEqual(try! AccountName("Assets:💰").nameItem, "💰")
    }

    func testAccountType() {
        XCTAssertEqual(try! AccountName("Assets:Test").accountType, AccountType.asset)
        XCTAssertEqual(try! AccountName("Liabilities:Test").accountType, AccountType.liability)
        XCTAssertEqual(try! AccountName("Income:Test").accountType, AccountType.income)
        XCTAssertEqual(try! AccountName("Expenses:Test").accountType, AccountType.expense)
        XCTAssertEqual(try! AccountName("Equity:Test").accountType, AccountType.equity)
    }

    func testAccountNameEqual() {
        let name1 = try! AccountName("Assets:Test")
        let name2 = try! AccountName("Assets:Test")
        let name3 = try! AccountName("Assets:Test:Test")
        XCTAssertEqual(name1, name2)
        XCTAssertNotEqual(name1, name3)
    }

}
