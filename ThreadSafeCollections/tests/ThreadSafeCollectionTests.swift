//
//  ThreadSafeCollectionTests.swift
//
//  Created by Terry Grossman.
//  
//  Copyright © 2024 Terry Grossman. All rights reserved.
//
//  Description:
//  This file contains unit tests for the ThreadSafeCollection actor.
//  The tests validate the thread safety and correctness of various operations 
//  like appending, removing, sorting, and filtering elements in different types
//  of collections (e.g., Array, Set). The tests also include concurrent access 
//  checks to ensure the actor safely handles concurrent modifications.
//

import XCTest
@testable import YourModule

final class ThreadSafeCollectionTests: XCTestCase {
    
    func testAppendAndRetrieveArray() async {
        let threadSafeArray = ThreadSafeCollection<Array<Int>>()
        await threadSafeArray.append(5)
        await threadSafeArray.append(10)
        let count = await threadSafeArray.count()
        XCTAssertEqual(count, 2)
        let element = await threadSafeArray.element(at: 0)
        XCTAssertEqual(element, 5)
    }
    
    func testAppendAndRetrieveSet() async {
        let threadSafeSet = ThreadSafeCollection<Set<String>>()
        await threadSafeSet.append("apple")
        await threadSafeSet.append("banana")
        let count = await threadSafeSet.count()
        XCTAssertEqual(count, 2)
        let filteredSet = await threadSafeSet.filter { $0.contains("a") }
        XCTAssertEqual(filteredSet, Set(["apple", "banana"]))
    }

    func testSortArray() async {
        let threadSafeArray = ThreadSafeCollection<Array<Int>>()
        await threadSafeArray.append(5)
        await threadSafeArray.append(1)
        await threadSafeArray.append(3)
        await threadSafeArray.sort()
        let sortedArray = await threadSafeArray.allElements()
        XCTAssertEqual(sortedArray, [1, 3, 5])
    }
    
    func testFilterSet() async {
        let threadSafeSet = ThreadSafeCollection<Set<String>>()
        await threadSafeSet.append("apple")
        await threadSafeSet.append("banana")
        await threadSafeSet.append("cherry")
        let filteredSet = await threadSafeSet.filter { $0.contains("a") }
        XCTAssertEqual(filteredSet, Set(["apple", "banana"]))
    }

    func testConcurrentAccessArray() async {
        let threadSafeArray = ThreadSafeCollection<Array<Int>>()
        
        // Simulate concurrent writes
        await withTaskGroup(of: Void.self) { taskGroup in
            for i in 0..<1000 {
                taskGroup.addTask {
                    await threadSafeArray.append(i)
                }
            }
        }
        
        // Check that all elements were appended
        let count = await threadSafeArray.count()
        XCTAssertEqual(count, 1000)
    }
}
