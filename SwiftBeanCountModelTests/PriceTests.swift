//
//  PriceTests.swift
//  SwiftBeanCountModelTests
//
//  Created by Steffen Kötte on 2018-05-13.
//  Copyright © 2018 Steffen Kötte. All rights reserved.
//

@testable import SwiftBeanCountModel
import XCTest

class PriceTests: XCTestCase {

    func testDescription() {
        let date = Date(timeIntervalSince1970: 1_496_905_200)
        let amount = Amount(number: Decimal(1), commodity: Commodity(symbol: "CAD"))
        let commodity = Commodity(symbol: "EUR")

        let price = Price(date: date, commodity: commodity, amount: amount)
        XCTAssertEqual(String(describing: price), "2017-06-08 price \(String(describing: commodity)) \(String(describing: amount))")
    }

    func testEqual() {
        let date = Date(timeIntervalSince1970: 1_496_905_200)
        let amount = Amount(number: Decimal(1), commodity: Commodity(symbol: "CAD"))
        let commodity = Commodity(symbol: "EUR")
        let price = Price(date: date, commodity: commodity, amount: amount)

        XCTAssertEqual(price, price)

        // Date different
        let date2 = Date(timeIntervalSince1970: 1_496_991_600)
        let price2 = Price(date: date2, commodity: commodity, amount: amount)
        XCTAssertNotEqual(price, price2)

        // Commodity different
        let commodity2 = Commodity(symbol: "USD")
        let price3 = Price(date: date, commodity: commodity2, amount: amount)
        XCTAssertNotEqual(price, price3)

        // Amount commodity different
        let amount2 = Amount(number: Decimal(1), commodity: Commodity(symbol: "USD"))
        let price4 = Price(date: date, commodity: commodity, amount: amount2)
        XCTAssertNotEqual(price, price4)

        // Amount number different
        let amount3 = Amount(number: Decimal(2), commodity: Commodity(symbol: "CAD"))
        let price5 = Price(date: date, commodity: commodity, amount: amount3)
        XCTAssertNotEqual(price, price5)
    }

}
