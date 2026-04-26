#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <substrate.h>

static NSArray<NSString *> *proxyServers = nil;
static NSString *capturedAuthToken = nil;

static NSString *trimmedString(NSString *value) {
    if (!value || ![value isKindOfClass:[NSString class]]) return nil;
    return [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

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

                NSMutableArray<NSString *> *servers = [NSMutableArray array];
                for (NSTextCheckingResult *urlMatch in urlMatches) {
                    NSRange range = [urlMatch rangeAtIndex:1];
                    if (range.location == NSNotFound) range = [urlMatch rangeAtIndex:2];
                    if (range.location != NSNotFound) {
                        NSString *server = trimmedString([arrayContent substringWithRange:range]);
                        if (server.length > 0) [servers addObject:server];
                    }
                }

                if (servers.count > 0) {
                    proxyServers = [servers copy];
                    NSLog(@"[TwitchProxy] Loaded %lu proxy servers from JS", (unsigned long)proxyServers.count);
                    return;
                }
            }
        }
    }

    proxyServers = @[ @"https://proxy4.rte.net.ru/", @"https://proxy7.rte.net.ru/", @"https://proxy5.rte.net.ru/", @"https://proxy6.rte.net.ru/" ];
    NSLog(@"[TwitchProxy] Using default proxy servers");
}

static NSString *normalizedProxyUrl(void) {
    NSString *proxyUrl = proxyServers.firstObject;
    if (proxyUrl.length == 0) return nil;
    return [proxyUrl hasSuffix:@"/"] ? proxyUrl : [proxyUrl stringByAppendingString:@"/"];
}

static NSString *encodedQueryValue(NSString *value) {
    NSMutableCharacterSet *allowed = [[NSCharacterSet URLQueryAllowedCharacterSet] mutableCopy];
    [allowed removeCharactersInString:@"&=+?"];
    return [value stringByAddingPercentEncodingWithAllowedCharacters:allowed];
}

static NSString *authTokenFromCookies(void) {
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie *cookie in [cookieStorage cookies]) {
        if ([[cookie name] isEqualToString:@"auth-token"]) return [cookie value];
    }
    return nil;
}

static NSString *currentAuthToken(void) {
    @synchronized ([NSBundle mainBundle]) {
        if (capturedAuthToken.length > 0) return capturedAuthToken;
    }
    return authTokenFromCookies();
}

static BOOL isTwitchRelatedHost(NSString *host) {
    NSString *lowerHost = host.lowercaseString;
    if (lowerHost.length == 0) return NO;
    return [lowerHost isEqualToString:@"twitch.tv"] ||
           [lowerHost hasSuffix:@".twitch.tv"] ||
           [lowerHost isEqualToString:@"ttvnw.net"] ||
           [lowerHost hasSuffix:@".ttvnw.net"] ||
           [lowerHost isEqualToString:@"jtvnw.net"] ||
           [lowerHost hasSuffix:@".jtvnw.net"] ||
           [lowerHost isEqualToString:@"twitchcdn.net"] ||
           [lowerHost hasSuffix:@".twitchcdn.net"];
}

static void captureAuthTokenFromRequest(NSURLRequest *request) {
    if (!request) return;
    if (!isTwitchRelatedHost(request.URL.host)) return;

    NSDictionary *headers = request.allHTTPHeaderFields;
    NSString *authorization = headers[@"Authorization"] ?: headers[@"authorization"];
    NSString *token = nil;

    if ([authorization isKindOfClass:[NSString class]]) {
        NSString *trimmed = trimmedString(authorization);
        if ([trimmed rangeOfString:@"OAuth " options:NSCaseInsensitiveSearch].location == 0) {
            token = [trimmed substringFromIndex:6];
        } else if ([trimmed rangeOfString:@"Bearer " options:NSCaseInsensitiveSearch].location == 0) {
            token = [trimmed substringFromIndex:7];
        }
    }

    if (!token) {
        NSString *cookieHeader = headers[@"Cookie"] ?: headers[@"cookie"];
        if ([cookieHeader isKindOfClass:[NSString class]]) {
            NSArray<NSString *> *cookies = [cookieHeader componentsSeparatedByString:@";"];
            for (NSString *cookie in cookies) {
                NSString *trimmedCookie = trimmedString(cookie);
                if ([trimmedCookie hasPrefix:@"auth-token="]) {
                    token = [[trimmedCookie substringFromIndex:11] stringByRemovingPercentEncoding];
                    break;
                }
            }
        }
    }

    token = trimmedString(token);
    if (token.length == 0) return;

    @synchronized ([NSBundle mainBundle]) {
        if (![capturedAuthToken isEqualToString:token]) {
            capturedAuthToken = [token copy];
            NSLog(@"[TwitchProxy] Captured Twitch auth token from native request");
        }
    }
}

static BOOL shouldProxyURL(NSURL *url) {
    if (!url || ![url isKindOfClass:[NSURL class]]) return NO;

    NSString *scheme = url.scheme.lowercaseString;
    if (!([scheme isEqualToString:@"https"] || [scheme isEqualToString:@"http"])) return NO;

    NSString *host = url.host.lowercaseString;
    if (![host isEqualToString:@"usher.ttvnw.net"]) return NO;

    NSString *absoluteString = url.absoluteString;
    if ([absoluteString rangeOfString:@"picture-by-picture" options:NSCaseInsensitiveSearch].location != NSNotFound) return NO;

    NSString *path = url.path.lowercaseString;
    if (![path hasSuffix:@".m3u8"]) return NO;

    return YES;
}

static NSURL *proxiedURLForURL(NSURL *originalURL) {
    if (!shouldProxyURL(originalURL)) return originalURL;

    NSString *proxyUrl = normalizedProxyUrl();
    NSString *originalUrlString = originalURL.absoluteString;
    if (proxyUrl.length == 0 || originalUrlString.length == 0) return originalURL;

    NSString *newUrlString = [proxyUrl stringByAppendingString:originalUrlString];
    NSString *authToken = currentAuthToken();
    if (authToken.length > 0 && [newUrlString rangeOfString:@"auth=" options:NSCaseInsensitiveSearch].location == NSNotFound) {
        NSString *separator = [newUrlString containsString:@"?"] ? @"&" : @"?";
        newUrlString = [NSString stringWithFormat:@"%@%@auth=%@", newUrlString, separator, encodedQueryValue(authToken)];
    }

    NSURL *newURL = [NSURL URLWithString:newUrlString];
    if (!newURL) {
        NSLog(@"[TwitchProxy] Failed to create proxied URL for HLS request");
        return originalURL;
    }

    NSLog(@"[TwitchProxy] Proxied HLS request: %@", originalURL.path);
    return newURL;
}

static NSURLRequest *proxiedRequestForRequest(NSURLRequest *originalRequest) {
    if (!originalRequest) return originalRequest;
    captureAuthTokenFromRequest(originalRequest);

    NSURL *newURL = proxiedURLForURL(originalRequest.URL);
    if (newURL == originalRequest.URL || [newURL isEqual:originalRequest.URL]) return originalRequest;

    NSMutableURLRequest *newRequest = [originalRequest mutableCopy];
    newRequest.URL = newURL;
    return [newRequest copy];
}

%hook NSURLSession

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request {
    return %orig(proxiedRequestForRequest(request));
}

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(id)completionHandler {
    return %orig(proxiedRequestForRequest(request), completionHandler);
}

- (NSURLSessionDataTask *)dataTaskWithURL:(NSURL *)url {
    return %orig(proxiedURLForURL(url));
}

- (NSURLSessionDataTask *)dataTaskWithURL:(NSURL *)url completionHandler:(id)completionHandler {
    return %orig(proxiedURLForURL(url), completionHandler);
}

- (NSURLSessionDownloadTask *)downloadTaskWithRequest:(NSURLRequest *)request {
    return %orig(proxiedRequestForRequest(request));
}

- (NSURLSessionDownloadTask *)downloadTaskWithRequest:(NSURLRequest *)request completionHandler:(id)completionHandler {
    return %orig(proxiedRequestForRequest(request), completionHandler);
}

- (NSURLSessionDownloadTask *)downloadTaskWithURL:(NSURL *)url {
    return %orig(proxiedURLForURL(url));
}

- (NSURLSessionDownloadTask *)downloadTaskWithURL:(NSURL *)url completionHandler:(id)completionHandler {
    return %orig(proxiedURLForURL(url), completionHandler);
}

- (NSURLSessionUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request fromData:(NSData *)bodyData {
    return %orig(proxiedRequestForRequest(request), bodyData);
}

- (NSURLSessionUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request fromData:(NSData *)bodyData completionHandler:(id)completionHandler {
    return %orig(proxiedRequestForRequest(request), bodyData, completionHandler);
}

- (NSURLSessionUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request fromFile:(NSURL *)fileURL {
    return %orig(proxiedRequestForRequest(request), fileURL);
}

- (NSURLSessionUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request fromFile:(NSURL *)fileURL completionHandler:(id)completionHandler {
    return %orig(proxiedRequestForRequest(request), fileURL, completionHandler);
}

%end

%hook NSURLRequest

+ (instancetype)requestWithURL:(NSURL *)URL {
    return %orig(proxiedURLForURL(URL));
}

- (instancetype)initWithURL:(NSURL *)URL {
    return %orig(proxiedURLForURL(URL));
}

- (instancetype)initWithURL:(NSURL *)URL cachePolicy:(NSURLRequestCachePolicy)cachePolicy timeoutInterval:(NSTimeInterval)timeoutInterval {
    return %orig(proxiedURLForURL(URL), cachePolicy, timeoutInterval);
}

%end

%hook NSMutableURLRequest

+ (instancetype)requestWithURL:(NSURL *)URL {
    return %orig(proxiedURLForURL(URL));
}

- (instancetype)initWithURL:(NSURL *)URL {
    return %orig(proxiedURLForURL(URL));
}

- (instancetype)initWithURL:(NSURL *)URL cachePolicy:(NSURLRequestCachePolicy)cachePolicy timeoutInterval:(NSTimeInterval)timeoutInterval {
    return %orig(proxiedURLForURL(URL), cachePolicy, timeoutInterval);
}

%end

%hook AVPlayer

+ (instancetype)playerWithURL:(NSURL *)URL {
    return %orig(proxiedURLForURL(URL));
}

- (instancetype)initWithURL:(NSURL *)URL {
    return %orig(proxiedURLForURL(URL));
}

%end

%hook AVPlayerItem

+ (instancetype)playerItemWithURL:(NSURL *)URL {
    return %orig(proxiedURLForURL(URL));
}

- (instancetype)initWithURL:(NSURL *)URL {
    return %orig(proxiedURLForURL(URL));
}

%end

%hook AVURLAsset

+ (instancetype)URLAssetWithURL:(NSURL *)URL options:(NSDictionary<NSString *,id> *)options {
    return %orig(proxiedURLForURL(URL), options);
}

- (instancetype)initWithURL:(NSURL *)URL options:(NSDictionary<NSString *,id> *)options {
    return %orig(proxiedURLForURL(URL), options);
}

%end

%ctor {
    NSLog(@"[TwitchProxy] Native tweak loaded");
    loadProxyServers();
}
