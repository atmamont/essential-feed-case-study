//
//  Copyright © 2019 Essential Developer. All rights reserved.
//

import Foundation

public final class LocalFeedLoader {
	private let store: FeedStore
	private let currentDate: () -> Date
	
	public init(store: FeedStore, currentDate: @escaping () -> Date) {
		self.store = store
		self.currentDate = currentDate
	}
}

extension LocalFeedLoader {
	public typealias SaveResult = Result<Void, Error>

	public func save(_ feed: [FeedImage], completion: @escaping (SaveResult) -> Void) {
		store.deleteCachedFeed { [weak self] result in
			guard let self = self else { return }
			
            switch result {
            case let .failure(cacheDeletionError):
                completion(.failure(cacheDeletionError))
            default:
				self.cache(feed, with: completion)
			}
		}
	}
	
	private func cache(_ feed: [FeedImage], with completion: @escaping (SaveResult) -> Void) {
		store.insert(feed.toLocal(), timestamp: currentDate()) { [weak self] insertionResult in
			guard self != nil else { return }
			
            completion(insertionResult)
//            completion(.failure(error))
		}
	}
}

extension LocalFeedLoader: FeedLoader {
	public typealias LoadResult = LoadFeedResult

	public func load(completion: @escaping (LoadResult) -> Void) {
		store.retrieve { [weak self] result in
			guard let self = self else { return }
			
			switch result {
			case let .failure(error):
				completion(.failure(error))

			case let .found(feed, timestamp) where FeedCachePolicy.validate(timestamp, against: self.currentDate()):
				completion(.success(feed.toModels()))
				
			case .found, .empty:
				completion(.success([]))
			}
		}
	}
}

extension LocalFeedLoader {
	public func validateCache() {
		store.retrieve { [weak self] result in
			guard let self = self else { return }
			
			switch result {
			case .failure:
				self.store.deleteCachedFeed { _ in }
				
			case let .found(_, timestamp) where !FeedCachePolicy.validate(timestamp, against: self.currentDate()):
				self.store.deleteCachedFeed { _ in }
				
			case .empty, .found: break
			}
		}
	}
}

private extension Array where Element == FeedImage {
	func toLocal() -> [LocalFeedImage] {
		return map { LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url) }
	}
}

private extension Array where Element == LocalFeedImage {
	func toModels() -> [FeedImage] {
		return map { FeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url) }
	}
}
