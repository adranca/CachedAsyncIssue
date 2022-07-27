import SwiftUI

// source: https://github.com/lorenzofiamingo/swiftui-cached-async-image

public struct CachedAsyncImage<Content>: View where Content: View {
    @State private var phase: AsyncImagePhase?
    private let session: URLSession
    private let urlRequest: URLRequest?
    private let cache: URLCache
    private let transaction: Transaction
    private let content: (AsyncImagePhase) -> Content

    public var body: some View {
        if let phase = phase {
            content(phase)
                .task(id: urlRequest, load)
        } else {
            Rectangle().opacity(0).task(id: urlRequest, load)
        }
    }

    public init(url: URL?, placeholder: Image, cachePolicy: URLRequest.CachePolicy = .returnCacheDataElseLoad)
        where Content == _ConditionalContent<Image, Image> {
        let request = url.flatMap { URLRequest(url: $0, cachePolicy: cachePolicy, timeoutInterval: 60.0) }
        self.init(urlRequest: request) { phase in
            if let image = phase.image {
                image
            } else {
                placeholder.resizable()
            }
        }
    }

    public init(urlRequest: URLRequest?,
                cache: URLCache = .imageCache,
                transaction: Transaction = Transaction(),
                @ViewBuilder content: @escaping (AsyncImagePhase) -> Content) {
        let config = URLSessionConfiguration.default
        config.urlCache = cache
        self.cache = cache
        self.urlRequest = urlRequest
        session = URLSession(configuration: config)
        self.transaction = transaction
        self.content = content
    }

    @Sendable
    func load() async {
        do {
            if let urlRequest = urlRequest {
                let date = Date()
                if let cachedImage = try cachedImage(from: urlRequest, cache: cache) {
                    print("Finished load \(Date().timeIntervalSince1970 - date.timeIntervalSince1970)")
                    phase = .success(cachedImage)
                } else {
                    phase = .empty
                    let image = try await remoteImage(from: urlRequest, session: session)
                    withAnimation(transaction.animation) {
                        phase = .success(image)
                    }
                }
            }
        } catch {
            withAnimation(transaction.animation) {
                phase = .failure(error)
            }
        }
    }
}

private extension CachedAsyncImage {
    func remoteImage(from request: URLRequest, session: URLSession) async throws -> Image {
        let (data, _) = try await session.data(for: request)
        return try image(from: data)
    }

    func cachedImage(from request: URLRequest, cache: URLCache) throws -> Image? {
        guard let cachedResponse = cache.cachedResponse(for: request) else { return nil }
        return try image(from: cachedResponse.data)
    }

    func image(from data: Data) throws -> Image {
        if let uiImage = UIImage(data: data) {
            return Image(uiImage: uiImage).resizable()
        } else {
            throw AsyncImage<Content>.LoadingError()
        }
    }
}

private extension AsyncImage {
    struct LoadingError: Error {}
}

public extension URLCache {
    static var imageCache: URLCache = {
        let cachesURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let diskCacheURL = cachesURL.appendingPathComponent("ImageCache")
        let oneHundredMegabyte = 100_000_000
        let oneGigabyte = 1_000_000_000
        let cache = URLCache(memoryCapacity: oneHundredMegabyte, diskCapacity: oneGigabyte, directory: diskCacheURL)
        return cache
    }()
}
