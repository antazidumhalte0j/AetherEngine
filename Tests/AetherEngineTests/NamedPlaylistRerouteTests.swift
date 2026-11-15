import Testing
import Foundation
@testable import AetherEngine

/// Fork (aiostreams): a VOD URL whose path names a playlist and whose loopback open failed takes the
/// AE#154 reroute even when no open read `#EXTM3U` off the body. Apple's trailer CDN
/// (play-edge.itunes.apple.com) answered the reader now and then with bytes other than the playlist:
/// the load died as FFmpeg's invalid data, or as "answers byte ranges with other bytes", for a
/// source AVPlayer played when asked again.
struct NamedPlaylistRerouteTests {
    private let playlist = URL(string: "https://play-edge.itunes.apple.com/WebObjects/subscription/playlist.m3u8")!

    @Test("A VOD .m3u8 whose open failed as invalid data reroutes")
    func invalidDataReroutes() {
        #expect(RemoteHLSMediaSelection.shouldRerouteNamedPlaylist(
            failure: DemuxerError.openFailed(code: -1094995529), url: playlist, isLive: false, isCustomSource: false))
    }

    @Test("An .m3u path reroutes too, whatever its case")
    func m3uReroutes() {
        let url = URL(string: "https://example.com/list/Index.M3U")!
        #expect(RemoteHLSMediaSelection.shouldRerouteNamedPlaylist(
            failure: DemuxerError.openFailed(code: -5), url: url, isLive: false, isCustomSource: false))
    }

    @Test("A URL that names no playlist keeps its failure")
    func otherExtensionsDoNot() {
        for path in ["movie.mkv", "movie.mp4", "stream", "video.ts"] {
            let url = URL(string: "https://example.com/\(path)")!
            #expect(!RemoteHLSMediaSelection.shouldRerouteNamedPlaylist(
                failure: DemuxerError.openFailed(code: -1094995529), url: url, isLive: false, isCustomSource: false))
        }
    }

    @Test("The origin's refusal is surfaced as itself")
    func refusalsDoNot() {
        #expect(!RemoteHLSMediaSelection.shouldRerouteNamedPlaylist(
            failure: AVIOReaderError.httpStatus(403), url: playlist, isLive: false, isCustomSource: false))
        #expect(!RemoteHLSMediaSelection.shouldRerouteNamedPlaylist(
            failure: AVIOReaderError.transportSecurityFailed(code: NSURLErrorServerCertificateUntrusted),
            url: playlist, isLive: false, isCustomSource: false))
    }

    @Test("Live loads, custom sources, cancellation and no failure don't reroute")
    func guards() {
        let failure = DemuxerError.openFailed(code: -1094995529)
        #expect(!RemoteHLSMediaSelection.shouldRerouteNamedPlaylist(
            failure: failure, url: playlist, isLive: true, isCustomSource: false))
        #expect(!RemoteHLSMediaSelection.shouldRerouteNamedPlaylist(
            failure: failure, url: playlist, isLive: false, isCustomSource: true))
        #expect(!RemoteHLSMediaSelection.shouldRerouteNamedPlaylist(
            failure: CancellationError(), url: playlist, isLive: false, isCustomSource: false))
        #expect(!RemoteHLSMediaSelection.shouldRerouteNamedPlaylist(
            failure: nil, url: playlist, isLive: false, isCustomSource: false))
    }
}
