//
//  CostTests.swift
//  SwiftBeanCountModelTests
//
//  Created by Steffen Kötte on 2019-09-08.
//  Copyright © 2019 Steffen Kötte. All rights reserved.
//

@testable import SwiftBeanCountModel
import XCTest

class CostTests: XCTestCase {

    let amount1 = Amount(number: Decimal(1), commodity: Commodity(symbol: "CAD"))
    let amount2 = Amount(number: Decimal(1), commodity: Commodity(symbol: "EUR"))

    let date1 = Date(timeIntervalSince1970: 1_496_905_200)
    let date2 = Date(timeIntervalSince1970: 1_496_991_600)

    let label1 = "1"
    let label2 = "2"

    func testNegativeAmount() {
        XCTAssertThrowsError(try Cost(amount: Amount(number: -1, commodity: Commodity(symbol: "EUR")), date: nil, label: nil)) {
            XCTAssertEqual($0.localizedDescription, "Invalid Cost, negative amount: {-1 EUR}")
        }
    }

    func testEqual() {
        let cost1 = try! Cost(amount: amount1, date: date1, label: label1)
        let cost2 = try! Cost(amount: amount1, date: date1, label: label1)
        XCTAssertEqual(cost1, cost2)
    }

    func testEqualRespectsAmount() {
        let cost1 = try! Cost(amount: amount1, date: date1, label: label1)
        let cost2 = try! Cost(amount: amount2, date: date1, label: label1)
        let cost3 = try! Cost(amount: nil, date: date1, label: label1)
        XCTAssertNotEqual(cost1, cost2)
        XCTAssertNotEqual(cost1, cost3)
    }

    func testEqualRespectsDate() {
        let cost1 = try! Cost(amount: amount1, date: date1, label: label1)
        let cost2 = try! Cost(amount: amount1, date: date2, label: label1)
        let cost3 = try! Cost(amount: amount1, date: nil, label: label1)
        XCTAssertNotEqual(cost1, cost2)
        XCTAssertNotEqual(cost1, cost3)
    }

    func testEqualRespectsLabel() {
        let cost1 = try! Cost(amount: amount1, date: date1, label: label1)
        let cost2 = try! Cost(amount: amount1, date: date1, label: label2)
        let cost3 = try! Cost(amount: amount1, date: date1, label: nil)
        XCTAssertNotEqual(cost1, cost2)
        XCTAssertNotEqual(cost1, cost3)
    }

    func testEqualWorksWithNil() {
        let cost1 = try! Cost(amount: nil, date: nil, label: nil)
        let cost2 = try! Cost(amount: nil, date: nil, label: nil)
        XCTAssertEqual(cost1, cost2)
    }

    func testMatches() {
        let cost1 = try! Cost(amount: amount1, date: nil, label: label1)
        let cost2 = try! Cost(amount: amount1, date: date1, label: label1)
        XCTAssertTrue(cost1.matches(cost: cost2))
    }

    func testMatchesNil() {
        let cost1 = try! Cost(amount: nil, date: nil, label: nil)
        let cost2 = try! Cost(amount: amount1, date: date1, label: label1)
        XCTAssertTrue(cost1.matches(cost: cost2))
    }

    func testMatchesLabel() {
        let cost1 = try! Cost(amount: nil, date: nil, label: label1)
        let cost2 = try! Cost(amount: amount1, date: date1, label: label1)
        XCTAssertTrue(cost1.matches(cost: cost2))
    }

    func testMatchesDate() {
        let cost1 = try! Cost(amount: nil, date: date1, label: nil)
        let cost2 = try! Cost(amount: amount1, date: date1, label: label1)
        XCTAssertTrue(cost1.matches(cost: cost2))
    }

    func testMatchesAmount() {
        let cost1 = try! Cost(amount: amount1, date: nil, label: nil)
        let cost2 = try! Cost(amount: amount1, date: date1, label: label1)
        XCTAssertTrue(cost1.matches(cost: cost2))
    }

    func testNotMatchesLabel() {
        let cost1 = try! Cost(amount: nil, date: nil, label: label2)
        let cost2 = try! Cost(amount: amount1, date: date1, label: label1)
        XCTAssertFalse(cost1.matches(cost: cost2))
    }

    func testNotMatchesDate() {
        let cost1 = try! Cost(amount: nil, date: date2, label: nil)
        let cost2 = try! Cost(amount: amount1, date: date1, label: label1)
        XCTAssertFalse(cost1.matches(cost: cost2))
    }

    func testNotMatchesAmount() {
        let cost1 = try! Cost(amount: amount2, date: nil, label: nil)
        let cost2 = try! Cost(amount: amount1, date: date1, label: label1)
        XCTAssertFalse(cost1.matches(cost: cost2))
    }

    func testMatchesLabelWrong() {
        let cost1 = try! Cost(amount: amount1, date: date1, label: label2)
        let cost2 = try! Cost(amount: amount1, date: date1, label: label1)
        XCTAssertFalse(cost1.matches(cost: cost2))
    }

    func testMatchesDateWrong() {
        let cost1 = try! Cost(amount: amount1, date: date2, label: label1)
        let cost2 = try! Cost(amount: amount1, date: date1, label: label1)
        XCTAssertFalse(cost1.matches(cost: cost2))
    }

    func testMatchesAmountWrong() {
        let cost1 = try! Cost(amount: amount2, date: date1, label: label1)
        let cost2 = try! Cost(amount: amount1, date: date1, label: label1)
        XCTAssertFalse(cost1.matches(cost: cost2))
    }

    func testDescription() {
        let cost = try! Cost(amount: amount1, date: date1, label: label1)
        XCTAssertEqual(String(describing: cost), "{2017-06-08, \(String(describing: amount1)), \"\(label1)\"}")
    }

    func testDescriptionWithoutDate() {
        let cost = try! Cost(amount: amount1, date: nil, label: label1)
        XCTAssertEqual(String(describing: cost), "{\(String(describing: amount1)), \"\(label1)\"}")
    }

    func testDescriptionWithoutAmount() {
        let cost = try! Cost(amount: nil, date: date1, label: label1)
        XCTAssertEqual(String(describing: cost), "{2017-06-08, \"\(label1)\"}")
    }

    func testDescriptionWithoutLabel() {
        let cost = try! Cost(amount: amount1, date: date1, label: nil)
        XCTAssertEqual(String(describing: cost), "{2017-06-08, \(String(describing: amount1))}")
    }

    func testDescriptionWithOnlyAmount() {
        let cost = try! Cost(amount: amount1, date: nil, label: nil)
        XCTAssertEqual(String(describing: cost), "{\(String(describing: amount1))}")
    }

    func testDescriptionWithOnlyDate() {
        let cost = try! Cost(amount: nil, date: date1, label: nil)
        XCTAssertEqual(String(describing: cost), "{2017-06-08}")
    }

    func testDescriptionWithOnlyLabel() {
        let cost = try! Cost(amount: nil, date: nil, label: label1)
        XCTAssertEqual(String(describing: cost), "{\"\(label1)\"}")
    }

    func testEmptyDescription() {
        let cost = try! Cost(amount: nil, date: nil, label: nil)
        XCTAssertEqual(String(describing: cost), "{}")
    }

}
