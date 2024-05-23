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
    
    func testPickerViewSelectioncCommonTime() {
        let rowMin = 4
        let rowSec = 33
        
        sut.pickerView.selectRow(rowMin, inComponent: 0, animated: false)
        sut.pickerView.selectRow(rowSec, inComponent: 1, animated: false)
        
        sut.pickerView(sut.pickerView, didSelectRow: rowMin, inComponent: 0)
        sut.pickerView(sut.pickerView, didSelectRow: rowSec, inComponent: 1)

        XCTAssertEqual(sut.minuteRow, 4)
        XCTAssertEqual(sut.secondRow, 33)
    }
    
    func testPickerViewSelectionMoreThan10Minutes() {
        let rowMin = 10
        let rowSec = 55
        
        sut.pickerView.selectRow(rowMin, inComponent: 0, animated: false)
        sut.pickerView.selectRow(rowSec, inComponent: 1, animated: false)
        
        sut.pickerView(sut.pickerView, didSelectRow: rowMin, inComponent: 0)
        sut.pickerView(sut.pickerView, didSelectRow: rowSec, inComponent: 1)

        XCTAssertEqual(sut.minuteRow, 10)
        XCTAssertEqual(sut.secondRow, 0)
    }
    
    func testPickerViewSelectionLessThan5Seconds() {
        let rowMin = 0
        let rowSec = 2
        
        sut.pickerView.selectRow(rowMin, inComponent: 0, animated: false)
        sut.pickerView.selectRow(rowSec, inComponent: 1, animated: false)
        
        sut.pickerView(sut.pickerView, didSelectRow: rowMin, inComponent: 0)
        sut.pickerView(sut.pickerView, didSelectRow: rowSec, inComponent: 1)
        
        XCTAssertEqual(sut.minuteRow, 0)
        XCTAssertEqual(sut.secondRow, 5)
    }
}
