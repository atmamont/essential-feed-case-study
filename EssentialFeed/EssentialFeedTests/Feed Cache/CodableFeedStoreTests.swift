//
//  CodableFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by Andrei on 05/09/2023.
//  Copyright © 2023 Essential Developer. All rights reserved.
//

import XCTest
import EssentialFeed

class CodableFeedStore {
    func retrieve(completion: @escaping (FeedStore.RetrievalCompletion)) {
        completion(.empty)
    }
}

class CodableFeedStoreTests: XCTestCase {
    
    func test_retrieve_deliversEmptyOnEmptyCache() {
        let sut = CodableFeedStore()
        let exp = expectation(description: "Wait for cache retrieval")
        sut.retrieve { result in
            switch result {
            case .empty: break
            default:
                XCTFail("Expected empty, got \(result) instead")
            }
            
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
}
