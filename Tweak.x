#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <substrate.h>

static NSArray *proxyServers = nil;

static void loadProxyServers() {
    NSString *jsPath = [[NSBundle mainBundle] pathForResource:@"twitch.user" ofType:@"js"];
    if (!jsPath) jsPath = [[NSBundle mainBundle] pathForResource:@"twitch_proxy" ofType:@"js"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:jsPath]) {
        jsPath = @"/var/jb/Library/Application Support/TwitchProxy/twitch_proxy.js";
    }

    if ([[NSFileManager defaultManager] fileExistsAtPath:jsPath]) {
        NSString *jsCode = [NSString stringWithContentsOfFile:jsPath encoding:NSUTF8StringEncoding error:nil];
        if (jsCode) {
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"PROXY_SERVERS\\s*=\\s*\\[(.*?)\\];" options:NSRegularExpressionDotMatchesLineSeparators error:nil];
            NSTextCheckingResult *match = [regex firstMatchInString:jsCode options:0 range:NSMakeRange(0, jsCode.length)];
            
            if (match) {
                NSString *arrayContent = [jsCode substringWithRange:[match rangeAtIndex:1]];
                NSRegularExpression *urlRegex = [NSRegularExpression regularExpressionWithPattern:@"'([^']+)'|\"([^\"]+)\"" options:0 error:nil];
                NSArray *urlMatches = [urlRegex matchesInString:arrayContent options:0 range:NSMakeRange(0, arrayContent.length)];
                
                NSMutableArray *servers = [NSMutableArray array];
                for (NSTextCheckingResult *urlMatch in urlMatches) {
                    NSRange range = [urlMatch rangeAtIndex:1];
                    if (range.location == NSNotFound) range = [urlMatch rangeAtIndex:2];
                    if (range.location != NSNotFound) [servers addObject:[arrayContent substringWithRange:range]];
                }
                
                if (servers.count > 0) {
                    proxyServers = [servers copy];
                    NSLog(@"[TwitchProxy] Loaded proxy servers from js: %@", proxyServers);
                    return;
                }
            }
        }
    }
    
    proxyServers = @[ @"https://proxy4.rte.net.ru/", @"https://proxy7.rte.net.ru/", @"https://proxy5.rte.net.ru/", @"https://proxy6.rte.net.ru/" ];
    NSLog(@"[TwitchProxy] Using default proxy servers: %@", proxyServers);
}

static NSString* getAuthToken() {
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie *cookie in [cookieStorage cookies]) {
        if ([[cookie name] isEqualToString:@"auth-token"]) return [cookie value];
    }
    return nil;
}

static NSString* rewriteTwitchUrl(NSString *originalUrlString) {
    if (!originalUrlString || ![originalUrlString isKindOfClass:[NSString class]]) return originalUrlString;
    if (![originalUrlString containsString:@"usher.ttvnw.net"]) return originalUrlString;

    NSString *proxyUrl = proxyServers.firstObject;
    if (!proxyUrl) return originalUrlString;

    // Prevent double proxying
    for (NSString *proxy in proxyServers) {
        NSString *proxyDomain = [proxy stringByReplacingOccurrencesOfString:@"https://" withString:@""];
        proxyDomain = [proxyDomain stringByReplacingOccurrencesOfString:@"http://" withString:@""];
        if ([originalUrlString containsString:proxyDomain] || [originalUrlString containsString:@"rte.net.ru"]) {
            return originalUrlString;
        }
    }

    // Preserve custom schemes like twitch-hls:// used by AVAssetResourceLoaderDelegate
    NSString *scheme = @"https://";
    NSString *urlWithoutScheme = originalUrlString;
    NSRange schemeRange = [originalUrlString rangeOfString:@"://"];
    if (schemeRange.location != NSNotFound) {
        scheme = [originalUrlString substringToIndex:schemeRange.location + 3];
        urlWithoutScheme = [originalUrlString substringFromIndex:schemeRange.location + 3];
    }

    NSString *proxyDomainPath = [proxyUrl stringByReplacingOccurrencesOfString:@"https://" withString:@""];
    proxyDomainPath = [proxyDomainPath stringByReplacingOccurrencesOfString:@"http://" withString:@""];
    if (![proxyDomainPath hasSuffix:@"/"]) proxyDomainPath = [proxyDomainPath stringByAppendingString:@"/"];

    // Format: [original scheme][proxy domain/path]https://[original url without scheme]
    NSString *newUrlString = [NSString stringWithFormat:@"%@%@https://%@", scheme, proxyDomainPath, urlWithoutScheme];
    
    NSString *authToken = getAuthToken();
    if (authToken && authToken.length > 0 && ![newUrlString containsString:@"auth="]) {
        NSString *separator = [newUrlString containsString:@"?"] ? @"&" : @"?";
        NSString *encodedAuth = [authToken stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        newUrlString = [NSString stringWithFormat:@"%@%@auth=%@", newUrlString, separator, encodedAuth];
    }
    
    NSLog(@"[TwitchProxy] Proxied URL: %@", newUrlString);
    return newUrlString;
}

static NSURL* getProxiedNSURL(NSURL *originalURL) {
    if (!originalURL || ![originalURL isKindOfClass:[NSURL class]]) return originalURL;
    NSString *absoluteString = originalURL.absoluteString;
    if ([absoluteString containsString:@"usher.ttvnw.net"]) {
        NSString *proxiedStr = rewriteTwitchUrl(absoluteString);
        if (proxiedStr && ![proxiedStr isEqualToString:absoluteString]) {
            return [NSURL URLWithString:proxiedStr];
        }
    }
    return originalURL;
}

static NSURLRequest* getProxiedNSURLRequest(NSURLRequest *originalRequest) {
    if (!originalRequest) return originalRequest;
    NSURL *newURL = getProxiedNSURL(originalRequest.URL);
    if (newURL != originalRequest.URL) {
        NSMutableURLRequest *newReq = [originalRequest mutableCopy];
        newReq.URL = newURL;
        return [newReq copy];
    }
    return originalRequest;
}

// ----------------------------------------------------
// NSURLSession Hooks (Catches Swift URLRequest networking)
// ----------------------------------------------------
%hook NSURLSession

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request {
    return %orig(getProxiedNSURLRequest(request));
}
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(id)completionHandler {
    return %orig(getProxiedNSURLRequest(request), completionHandler);
}
- (NSURLSessionDataTask *)dataTaskWithURL:(NSURL *)url {
    return %orig(getProxiedNSURL(url));
}
- (NSURLSessionDataTask *)dataTaskWithURL:(NSURL *)url completionHandler:(id)completionHandler {
    return %orig(getProxiedNSURL(url), completionHandler);
}
%end

// ----------------------------------------------------
// NSURLRequest / NSMutableURLRequest Hooks
// ----------------------------------------------------
%hook NSURLRequest
+ (instancetype)requestWithURL:(NSURL *)URL { return %orig(getProxiedNSURL(URL)); }
- (instancetype)initWithURL:(NSURL *)URL { return %orig(getProxiedNSURL(URL)); }
- (instancetype)initWithURL:(NSURL *)URL cachePolicy:(NSURLRequestCachePolicy)cachePolicy timeoutInterval:(NSTimeInterval)timeoutInterval {
    return %orig(getProxiedNSURL(URL), cachePolicy, timeoutInterval);
}
%end

%hook NSMutableURLRequest
+ (instancetype)requestWithURL:(NSURL *)URL { return %orig(getProxiedNSURL(URL)); }
- (instancetype)initWithURL:(NSURL *)URL { return %orig(getProxiedNSURL(URL)); }
- (instancetype)initWithURL:(NSURL *)URL cachePolicy:(NSURLRequestCachePolicy)cachePolicy timeoutInterval:(NSTimeInterval)timeoutInterval {
    return %orig(getProxiedNSURL(URL), cachePolicy, timeoutInterval);
}
%end

// ----------------------------------------------------
// AVFoundation Hooks (Catches direct media player loads)
// ----------------------------------------------------
%hook AVPlayer
+ (instancetype)playerWithURL:(NSURL *)URL { return %orig(getProxiedNSURL(URL)); }
- (instancetype)initWithURL:(NSURL *)URL { return %orig(getProxiedNSURL(URL)); }
%end

%hook AVPlayerItem
+ (instancetype)playerItemWithURL:(NSURL *)URL { return %orig(getProxiedNSURL(URL)); }
- (instancetype)initWithURL:(NSURL *)URL { return %orig(getProxiedNSURL(URL)); }
%end

%hook AVURLAsset
+ (instancetype)URLAssetWithURL:(NSURL *)URL options:(NSDictionary<NSString *,id> *)options {
    return %orig(getProxiedNSURL(URL), options);
}
- (instancetype)initWithURL:(NSURL *)URL options:(NSDictionary<NSString *,id> *)options {
    return %orig(getProxiedNSURL(URL), options);
}
%end

%ctor {
    NSLog(@"[TwitchProxy] Native Tweak loaded (Comprehensive Hooks)");
    loadProxyServers();
}
