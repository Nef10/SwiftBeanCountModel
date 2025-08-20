//
//  PriceTests.swift
//  SwiftBeanCountModelTests
//
//  Created by Steffen Kötte on 2018-05-13.
//  Copyright © 2018 Steffen Kötte. All rights reserved.
//

@testable import SwiftBeanCountModel
import XCTest

final class PriceTests: XCTestCase {

    func testInit() {
        let amount = Amount(number: Decimal(1), commoditySymbol: TestUtils.cad)
        XCTAssertNoThrow(try Price(date: TestUtils.date20170608, commoditySymbol: TestUtils.eur, amount: amount))
        XCTAssertThrowsError(try Price(date: TestUtils.date20170608, commoditySymbol: TestUtils.cad, amount: amount)) {
            XCTAssertEqual($0.localizedDescription, "Invalid Price, using same commodity: CAD")
        }
    }

    func testDescription() throws {
        let amount = Amount(number: Decimal(1), commoditySymbol: TestUtils.cad)
        var price = try Price(date: TestUtils.date20170608, commoditySymbol: TestUtils.eur, amount: amount)
        XCTAssertEqual(String(describing: price), "2017-06-08 price \(TestUtils.eur) \(String(describing: amount))")

        price = try Price(date: TestUtils.date20170608, commoditySymbol: TestUtils.eur, amount: amount, metaData: ["A": "B"])
        XCTAssertEqual(String(describing: price), "2017-06-08 price \(TestUtils.eur) \(String(describing: amount))\n  A: \"B\"")

    }

    func testEqual() throws {
        let amount = Amount(number: Decimal(1), commoditySymbol: TestUtils.cad)
        var price = try Price(date: TestUtils.date20170608, commoditySymbol: TestUtils.eur, amount: amount)
        var price2 = try Price(date: TestUtils.date20170608, commoditySymbol: TestUtils.eur, amount: amount)

        XCTAssertEqual(price, price2)

        // Meta Data
        price = try Price(date: TestUtils.date20170608, commoditySymbol: TestUtils.eur, amount: amount, metaData: ["A": "B"])
        XCTAssertNotEqual(price, price2)
        price2 = try Price(date: TestUtils.date20170608, commoditySymbol: TestUtils.eur, amount: amount, metaData: ["A": "B"])
        XCTAssertEqual(price, price2)

        // Date different
        let price3 = try Price(date: TestUtils.date20170609, commoditySymbol: TestUtils.eur, amount: amount)
        XCTAssertNotEqual(price, price3)

        // Commodity different
        let price4 = try Price(date: TestUtils.date20170608, commoditySymbol: TestUtils.usd, amount: amount)
        XCTAssertNotEqual(price, price4)

        // Amount commodity different
        let amount2 = Amount(number: Decimal(1), commoditySymbol: TestUtils.usd)
        let price5 = try Price(date: TestUtils.date20170608, commoditySymbol: TestUtils.eur, amount: amount2)
        XCTAssertNotEqual(price, price5)

        // Amount number different
        let amount3 = Amount(number: Decimal(2), commoditySymbol: TestUtils.cad)
        let price6 = try Price(date: TestUtils.date20170608, commoditySymbol: TestUtils.eur, amount: amount3)
        XCTAssertNotEqual(price, price6)
    }

    func testInitTotalPrice() {
        let amount = Amount(number: Decimal(100), commoditySymbol: TestUtils.cad) // total price
        XCTAssertNoThrow(try Price(date: TestUtils.date20170608, commoditySymbol: TestUtils.eur, amount: amount, priceType: .total))
        XCTAssertThrowsError(try Price(date: TestUtils.date20170608, commoditySymbol: TestUtils.cad, amount: amount, priceType: .total)) {
            XCTAssertEqual($0.localizedDescription, "Invalid Price, using same commodity: CAD")
        }
    }

    func testPerUnitPriceConversion() throws {
        // Test per-unit price stays the same
        let perUnitAmount = Amount(number: Decimal(2), commoditySymbol: TestUtils.cad)
        let perUnitPrice = try Price(date: TestUtils.date20170608, commoditySymbol: TestUtils.eur, amount: perUnitAmount, priceType: .perUnit)
        
        let convertedPerUnit = perUnitPrice.perUnitPrice(for: Decimal(10))
        XCTAssertEqual(convertedPerUnit.number, Decimal(2))
        XCTAssertEqual(convertedPerUnit.commoditySymbol, TestUtils.cad)

        // Test total price conversion to per-unit
        let totalAmount = Amount(number: Decimal(20), commoditySymbol: TestUtils.cad) // total for 10 units
        let totalPrice = try Price(date: TestUtils.date20170608, commoditySymbol: TestUtils.eur, amount: totalAmount, priceType: .total)
        
        let convertedFromTotal = totalPrice.perUnitPrice(for: Decimal(10))
        XCTAssertEqual(convertedFromTotal.number, Decimal(2))
        XCTAssertEqual(convertedFromTotal.commoditySymbol, TestUtils.cad)
    }

    func testTotalPriceConversion() throws {
        // Test total price stays the same
        let totalAmount = Amount(number: Decimal(20), commoditySymbol: TestUtils.cad)
        let totalPrice = try Price(date: TestUtils.date20170608, commoditySymbol: TestUtils.eur, amount: totalAmount, priceType: .total)
        
        let convertedTotal = totalPrice.totalPrice(for: Decimal(10))
        XCTAssertEqual(convertedTotal.number, Decimal(20))
        XCTAssertEqual(convertedTotal.commoditySymbol, TestUtils.cad)

        // Test per-unit price conversion to total
        let perUnitAmount = Amount(number: Decimal(2), commoditySymbol: TestUtils.cad) // per unit
        let perUnitPrice = try Price(date: TestUtils.date20170608, commoditySymbol: TestUtils.eur, amount: perUnitAmount, priceType: .perUnit)
        
        let convertedFromPerUnit = perUnitPrice.totalPrice(for: Decimal(10))
        XCTAssertEqual(convertedFromPerUnit.number, Decimal(20))
        XCTAssertEqual(convertedFromPerUnit.commoditySymbol, TestUtils.cad)
    }

    func testEqualWithPriceType() throws {
        let amount = Amount(number: Decimal(1), commoditySymbol: TestUtils.cad)
        let pricePerUnit = try Price(date: TestUtils.date20170608, commoditySymbol: TestUtils.eur, amount: amount, priceType: .perUnit)
        let priceTotal = try Price(date: TestUtils.date20170608, commoditySymbol: TestUtils.eur, amount: amount, priceType: .total)

        // Same amount but different price types should not be equal
        XCTAssertNotEqual(pricePerUnit, priceTotal)

        // Same price type should be equal
        let pricePerUnit2 = try Price(date: TestUtils.date20170608, commoditySymbol: TestUtils.eur, amount: amount, priceType: .perUnit)
        XCTAssertEqual(pricePerUnit, pricePerUnit2)
    }

}
