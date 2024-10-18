//
//  ThreadSafeCollection.swift
//
//  Created by Terry Grossman.
//  
//  Copyright © 2024 Terry Grossman. All rights reserved.  See license file for usage.
//
//  Description:
//  This file contains the implementation of a generic thread-safe collection
//  using Swift actors to ensure safe concurrent access to mutable collections.
//  The collection supports various operations such as appending, sorting, 
//  filtering, and removing elements, while maintaining thread safety.
//
// Example with Array of Ints:
// let threadSafeArray = ThreadSafeCollection<Array<Int>>()
// 
// Task {
//     await threadSafeArray.append(5)
//     await threadSafeArray.append(10)
//     await threadSafeArray.append(3)
// 
//     await threadSafeArray.sort()
//     let sortedArray = await threadSafeArray.allElements()
//     print("Sorted Array: \(sortedArray)")
// }


import Foundation

actor ThreadSafeCollection<CollectionType> where CollectionType: RangeReplaceableCollection {
    private var collection: CollectionType

    init(initialCollection: CollectionType = CollectionType()) {
        self.collection = initialCollection
    }

    // Add an element to the collection (write operation)
    func append(_ element: CollectionType.Element) {
        collection.append(element)
    }

    // Get the element at a specific index (read operation, only for collections that support indexing)
    func element(at index: CollectionType.Index) -> CollectionType.Element? where CollectionType: RandomAccessCollection {
        guard collection.indices.contains(index) else { return nil }
        return collection[index]
    }

    // Get all elements (read operation)
    func allElements() -> CollectionType {
        return collection
    }

    // Remove the element at a specific index (write operation, only for collections that support indexing)
    func remove(at index: CollectionType.Index) where CollectionType: RangeReplaceableCollection & RandomAccessCollection {
        guard collection.indices.contains(index) else { return }
        collection.remove(at: index)
    }

    // Get the count of the collection (read operation)
    func count() -> Int {
        return collection.count
    }

    // Sort the collection (write operation, only for collections where the elements are Comparable)
    func sort() where CollectionType: MutableCollection, CollectionType.Element: Comparable {
        collection.sort()
    }

    // Sort the collection with a custom closure (write operation)
    func sort(by areInIncreasingOrder: (CollectionType.Element, CollectionType.Element) -> Bool) where CollectionType: MutableCollection {
        collection.sort(by: areInIncreasingOrder)
    }

    // Filter the collection based on a predicate (read operation, returns new collection)
    func filter(_ isIncluded: (CollectionType.Element) -> Bool) -> CollectionType {
        return collection.filter(isIncluded)
    }
}
