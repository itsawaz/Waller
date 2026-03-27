import AppKit
import WebKit

class WallpaperBrowserPanel: NSPanel, WKNavigationDelegate, WKDownloadDelegate, WKUIDelegate, NSWindowDelegate {

    private var webView: WKWebView!
    private weak var wallpaperWindow: WallpaperWindow?
    private var downloadPaths: [WKDownload: URL] = [:]

    // MARK: - Init

    init(wallpaperWindow: WallpaperWindow) {
        self.wallpaperWindow = wallpaperWindow
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 1080, height: 740),
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        self.title = "Waller · MoeWalls Gallery"
        self.titlebarAppearsTransparent = true
        self.isMovableByWindowBackground = true
        self.level = .floating
        self.backgroundColor = NSColor(srgbRed: 0.1, green: 0.1, blue: 0.15, alpha: 1)
        self.minSize = NSSize(width: 800, height: 600)
        self.delegate = self

        // Configuration
        let config = WKWebViewConfiguration()
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = prefs

        // CSS/JS Injection: 
        // 1. Grid page: Hide ads and sidebars. 
        // 2. Single page: Rebuild UI to show ONLY the video, download button, and info list.
        let scriptSource = """
        // CSS rules to hide junk but keep original DOM completely structurally intact to not break jQuery
        var style = document.createElement('style');
        style.innerHTML = `
            /* Hide massive headers, footers and typical ad containers globally */
            .site-header, .site-footer, #wpadminbar,
            .advertisement, .g1-ad, .ad-home, .ads-sidebar,
            .snax, .mashsb-container, .g1-related-entries,
            #comments, .entry-tags {
                display: none !important;
            }

            /* Single Post view formatting */
            body.single-post #primary { width: 100% !important; }
            body.single-post .entry-header { text-align: center !important; }
            body.single-post .entry-title { color: #fff !important; font-size: 28px !important; margin-top: 20px !important; }
            body.single-post .entry-body > *:not(.wp-video):not(.entry-featured-media) {
                display: none !important; /* hide tutorial text */
            }
            body.single-post .wp-video, body.single-post .entry-featured-media {
                display: block !important;
                margin: 0 auto !important;
                max-width: 800px !important;
                border-radius: 12px;
                box-shadow: 0 10px 40px rgba(0,0,0,0.5);
                overflow: hidden;
            }

            /* Hide the actual sidebar visually, but keep it in DOM for jQuery to find it */
            body.single-post #secondary { 
                position: absolute !important;
                left: -9999px !important;
                visibility: hidden !important; 
            }
            body { background: #09090f !important; color: #ccc !important; padding-top: 0 !important; }
            
            /* Give bottom padding so the floating button doesn't cover anything */
            body.single-post { padding-bottom: 120px !important; }
        `;
        document.head.appendChild(style);

        // Inject foolproof floating action button for downloads
        window.addEventListener('load', () => {
            let realButton = document.getElementById('moe-download');
            if (realButton) {
                let floatingBtn = document.createElement('button');
                floatingBtn.innerHTML = '⬇ Download Wallpaper';
                floatingBtn.style.position = 'fixed';
                floatingBtn.style.bottom = '40px';
                floatingBtn.style.left = '50%';
                floatingBtn.style.transform = 'translateX(-50%)';
                floatingBtn.style.zIndex = '999999';
                floatingBtn.style.padding = '18px 48px';
                floatingBtn.style.fontSize = '20px';
                floatingBtn.style.fontWeight = 'bold';
                floatingBtn.style.background = 'linear-gradient(135deg, #7c6aff, #e879c0)';
                floatingBtn.style.color = '#fff';
                floatingBtn.style.border = 'none';
                floatingBtn.style.borderRadius = '50px';
                floatingBtn.style.boxShadow = '0 15px 35px rgba(124, 106, 255, 0.4)';
                floatingBtn.style.cursor = 'pointer';
                
                // When clicked, trigger the real hidden button natively
                floatingBtn.onclick = function() {
                    floatingBtn.innerHTML = '⏳ Processing...';
                    floatingBtn.style.transform = 'translateX(-50%) scale(0.95)';
                    setTimeout(() => {
                        floatingBtn.innerHTML = '⬇ Download Wallpaper';
                        floatingBtn.style.transform = 'translateX(-50%) scale(1)';
                    }, 500);
                    realButton.click();
                };
                
                document.body.appendChild(floatingBtn);
            }
            // Grid Page - clean up layout
            let gridStyles = document.createElement('style');
            gridStyles.innerHTML = `
                body.archive #primary { width: 100% !important; }
                body.archive #secondary { display: none !important; }
            `;
            document.head.appendChild(gridStyles);
        });
        """
        let userScript = WKUserScript(source: scriptSource, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        config.userContentController.addUserScript(userScript)

        webView = WKWebView(frame: contentView!.bounds, configuration: config)
        webView.autoresizingMask = [.width, .height]
        webView.navigationDelegate = self
        webView.uiDelegate = self
        contentView!.addSubview(webView)

        self.center()
    }

    // MARK: - WKUIDelegate

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        
        // When MoeWalls JS clicks download, it tries to open the "real" URL in a new blank tab
        // We catch this "new tab" request, and forcefully load it into OUR window so we can intercept it!
        if navigationAction.targetFrame == nil {
            print("[Browser] Intercepted new window/tab request to: \(navigationAction.request.url?.absoluteString ?? "unknown")")
            webView.load(navigationAction.request)
        }
        return nil
    }

    func showPanel() {
        if webView.url == nil {
            let req = URLRequest(url: URL(string: "https://moewalls.com/category/anime/")!)
            webView.load(req)
        }
        makeKeyAndOrderFront(nil)
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    func windowWillClose(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, preferences: WKWebpagePreferences, decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void) {
        
        // Let all navigation actions pass through for eval.
        // MoeWalls triggers downloads via window.open() which creates a targetFrame == nil.
        // If we block targetFrame == nil, we break their download button.
        
        // Direct MP4/Video navigation -> force download
        if let ext = navigationAction.request.url?.pathExtension.lowercased(),
           ["mp4", "webm", "mov", "mkv"].contains(ext) {
            decisionHandler(.download, preferences)
            return
        }

        decisionHandler(.allow, preferences)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        
        // Check for explicit video mimetypes
        if let mime = navigationResponse.response.mimeType {
            if mime.starts(with: "video/") {
                decisionHandler(.download)
                return
            } else if mime == "application/x-apple-diskimage" || mime == "application/x-msdos-program" {
                // Instantly block ad downloads like .dmg or .exe
                decisionHandler(.cancel)
                return
            }
        }
        
        // Catch server-forced file downloads
        if let httpRes = navigationResponse.response as? HTTPURLResponse {
            let disposition = (httpRes.allHeaderFields["Content-Disposition"] as? String) ?? (httpRes.allHeaderFields["content-disposition"] as? String) ?? ""
            if disposition.lowercased().contains("attachment") || disposition.lowercased().contains(".mp4") {
                decisionHandler(.download)
                return
            }
        }
        
        // Catch MoeWalls specific download scripts returning generic octet-stream
        if let urlstr = navigationResponse.response.url?.absoluteString, urlstr.contains("download.php") {
            decisionHandler(.download)
            return
        }
        
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
        download.delegate = self
    }

    func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
        download.delegate = self
    }

    // MARK: - WKDownloadDelegate

    func download(_ download: WKDownload, decideDestinationUsing response: URLResponse, suggestedFilename: String, completionHandler: @escaping (URL?) -> Void) {
        var ext = (suggestedFilename as NSString).pathExtension.lowercased()
        var finalFilename = suggestedFilename
        
        // If MoeWalls returns a generic script name, assume it's our video
        if ext == "php" || ext == "" {
            ext = "mp4"
            finalFilename = suggestedFilename + ".mp4"
        }
        
        let allowed = ["mp4", "webm", "mov", "mkv"]
        
        if !allowed.contains(ext) {
            print("[Browser] BLOCKED malicious/ad download: \(suggestedFilename)")
            download.cancel { _ in }
            let dummy = FileManager.default.temporaryDirectory.appendingPathComponent("discarded_ad.tmp")
            completionHandler(dummy)
            return
        }

        let tempDir = FileManager.default.temporaryDirectory
        let dest = tempDir.appendingPathComponent("waller_\(UUID().uuidString)_\(finalFilename)")
        print("[Browser] Downloading MoeWalls file to: \(dest.path)")
        
        downloadPaths[download] = dest
        
        DispatchQueue.main.async {
            self.title = "Waller · Downloading Wallpaper..."
        }
        
        completionHandler(dest)
    }

    func downloadDidFinish(_ download: WKDownload) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.title = "Waller · MoeWalls Gallery"
            if let dest = self.downloadPaths[download] {
                // Double check it wasn't an ad we discarded
                if dest.pathExtension.lowercased() != "tmp" {
                    print("[Browser] Download finished successfully: \(dest.lastPathComponent)")
                    self.wallpaperWindow?.playVideo(url: dest)
                }
            }
            self.downloadPaths.removeValue(forKey: download)
        }
    }
    
    func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
        print("[Browser] Download failed: \(error)")
        DispatchQueue.main.async {
            self.title = "Waller · MoeWalls Gallery"
            self.downloadPaths.removeValue(forKey: download)
        }
    }
}
