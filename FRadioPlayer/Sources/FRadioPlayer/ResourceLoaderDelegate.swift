import Foundation
import AVFoundation

class ResourceLoaderDelegate: NSObject, AVAssetResourceLoaderDelegate, URLSessionDelegate, URLSessionDataDelegate, URLSessionTaskDelegate {
    
    let streamURL: URL
    var item: AVPlayerItem?
    
    private var session: URLSession?
    private var infoResponse: URLResponse?
    private var pendingRequests = Set<AVAssetResourceLoadingRequest>()
    
    private lazy var mediaData  = Data()
    private var mediaDataChunks = [Data]()
    
    init(streamURL: URL) {
        self.streamURL = streamURL
        super.init()
    }
    
    func invalidate() {
        pendingRequests.forEach { $0.finishLoading() }
        pendingRequests.removeAll()
        
        session?.invalidateAndCancel()
        session = nil
    }
    
    func resourceLoader(
        _ resourceLoader: AVAssetResourceLoader,
        shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest
    ) -> Bool {
        if session == nil {
            // If we're playing from a url, we need to download the file.
            // We start loading the file on first request only.
            session = createSession()
            let task = session?.dataTask(with: streamURL)
            task?.resume()
        }
        
        if let request = loadingRequest.contentInformationRequest {
            print("""
------------Content Info Request------------
        Current Length: \(request.contentLength)
--------------------------------------------
""")
        }
        
        if let dataRequest = loadingRequest.dataRequest {
            print("""
------------Data Request-------------
        Requested Offset: \(dataRequest.requestedOffset)
        Requested Length: \(dataRequest.requestedLength)
        Current Offset: \(dataRequest.currentOffset)
-------------------------------------
""")
        }

        pendingRequests.insert(loadingRequest)
        
        return true
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
        print("Cancelled request")
        pendingRequests.remove(loadingRequest)
    }
    
    // MARK: - URLSessionTaskDelegate
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        print("Task completed with error: \(String(describing: error))")
        DispatchQueue.main.async {
            self.invalidate()
        }
    }
    
    // MARK: - URLSessionDataDelegate
    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse,
        completionHandler: @escaping (URLSession.ResponseDisposition) -> Void
    ) {
        infoResponse = response
        print("Did receive response")
        completionHandler(.allow)
        
        processPendingRequests()
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        mediaData.append(data)
        mediaDataChunks.append(data)
        //        while mediaDataChunks.reduce(0, { $0 + $1.count }) > 1_000_000 {
        //            mediaDataChunks.removeFirst()
        //        }
        
        print("Did receive data of size: \(data.count)")
        
        processPendingRequests()
    }
    
    private func processPendingRequests() {
        var finishedRequests = Set<AVAssetResourceLoadingRequest>()
        self.pendingRequests.forEach {
            var request = $0
            
            if self.isInfo(request: request), let response = self.infoResponse {
                self.fillInfoRequest(request: &request, response: response)
                finishedRequests.insert(request)
                request.finishLoading()
            } else if let dataRequest = request.dataRequest, self.checkAndRespond(forRequest: dataRequest) {
                finishedRequests.insert(request)
                request.finishLoading()
            }
        }
        
        pendingRequests = pendingRequests.filter { !finishedRequests.contains($0) }
    }
    
    private func isInfo(request: AVAssetResourceLoadingRequest) -> Bool {
        return request.contentInformationRequest != nil
    }
    
    private func fillInfoRequest(request: inout AVAssetResourceLoadingRequest, response: URLResponse) {
        request.contentInformationRequest?.isByteRangeAccessSupported = false
        request.contentInformationRequest?.contentType = response.mimeType
        request.contentInformationRequest?.contentLength = response.expectedContentLength
    }
    
    private func checkAndRespond(forRequest dataRequest: AVAssetResourceLoadingDataRequest) -> Bool {
        print("Current Data Length: \(mediaData.count);\n\tRequested Data Length: \(dataRequest.requestedLength);")
        let downloadedData = mediaData
        
        let downloadedDataLength = Int64(downloadedData.count)
        let requestedDataLength = Int64(dataRequest.requestedLength)
        
        if downloadedDataLength < requestedDataLength {
            return false
        }
        
        let respondData = mediaData.prefix(Int(requestedDataLength))
        mediaData.removeFirst(Int(requestedDataLength))

        print("New Current Data Length: \(mediaData.count); Responding with Data Length: \(respondData.count);")
        
        dataRequest.respond(
            with: respondData
        )
        
        return true
    }
    
    private func createSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        configuration.timeoutIntervalForRequest = 60
        configuration.timeoutIntervalForResource = 60
        return URLSession(
            configuration: configuration,
            delegate: self,
            delegateQueue: .main
        )
    }
    
    deinit {
        session?.invalidateAndCancel()
    }
}

extension URL {
    
    static let resourceLoaderScheme = "resourceloader"

    func addRedirectToResourceLoader() -> URL {
        var components = URLComponents(url: self, resolvingAgainstBaseURL: false)
        let scheme = components?.scheme ?? ""
        components?.scheme = Self.resourceLoaderScheme + scheme
        return components?.url ?? self
    }
}
