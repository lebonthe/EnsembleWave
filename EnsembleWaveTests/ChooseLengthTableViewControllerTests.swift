//
//  ChooseLengthTableViewControllerTests.swift
//  EnsembleWaveTests
//
//  Created by Min Hu on 2024/5/20.
//

import XCTest
@testable import EnsembleWave

final class ChooseLengthTableViewControllerTests: XCTestCase {

    var sut: ChooseLengthTableViewController!
    
    override func setUpWithError() throws {
        super.setUp()
        sut = ChooseLengthTableViewController()
        sut.loadViewIfNeeded()
    }

    override func tearDownWithError() throws {
        sut = nil
        super.tearDown()
    }

    func testNumberOfRows() {
        let numberOfRows = sut.tableView(sut.tableView, numberOfRowsInSection: 0)
        XCTAssertEqual(numberOfRows, sut.lengths.count)
    }
    
    func testPickerViewSelectionMoreThan10Minutes() {
        sut.pickerView.selectRow(9, inComponent: 0, animated: false)
        sut.pickerView.selectRow(55, inComponent: 1, animated: false)

        XCTAssertEqual(sut.minuteRow, 9)
        XCTAssertEqual(sut.secondRow, 55)
    }
    
        func testPickerViewSelectionLessThan5Seconds() {
            sut.pickerView(sut.pickerView, didSelectRow: 0, inComponent: 0)
            sut.pickerView(sut.pickerView, didSelectRow: 2, inComponent: 1)
    
            XCTAssertEqual(sut.minuteRow, 0)
            XCTAssertEqual(sut.secondRow, 5)
        }
}
