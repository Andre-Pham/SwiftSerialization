//
//  LegacyTests.swift
//  SwiftSerializationTests
//
//  Created by Andre Pham on 23/2/2023.
//

import XCTest
@testable import SwiftSerialization

final class LegacyTests: XCTestCase {
    
    let databaseTargets: [DatabaseTarget] = [SerializationDatabase(), SerializationFileDatabase()]
    
    override func setUp() async throws {
        self.databaseTargets.forEach({ _ = $0.clearDatabase() })
    }
    
    override func tearDown() {
        self.databaseTargets.forEach({ _ = $0.clearDatabase() })
    }

    func testFieldAndClassNameRefactor() throws {
        // First remember to declare the refactor
        Legacy.addClassRefactor(old: "LegacyHomework", new: "Homework")
        
        let legacyHomework = LegacyHomework(legacyAnswers: "1 + 1 = 2", legacyGrade: 100)
        for database in self.databaseTargets {
            print("-- DATABASE \(database.self) --")
            
            XCTAssertTrue(database.write(Record(data: legacyHomework)))
            let allHomework: [Homework] = database.read()
            if allHomework.count == 1 {
                let homework = allHomework[0]
                XCTAssertEqual(homework.answers, legacyHomework.legacyAnswers)
                XCTAssertEqual(homework.grade, legacyHomework.legacyGrade)
            } else {
                XCTFail("Legacy class could not be restored")
            }
        }
    }

}
