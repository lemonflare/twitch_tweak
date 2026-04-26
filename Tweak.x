#import <Foundation/Foundation.h>
#import <substrate.h>

static NSArray *proxyServers = nil;

// Function to extract PROXY_SERVERS from the twitch.user.js file
static void loadProxyServers() {
    // 1. Try to load from the main bundle (if injected via inject_dylib.py)
    NSString *jsPath = [[NSBundle mainBundle] pathForResource:@"twitch.user" ofType:@"js"];
    if (!jsPath) {
        jsPath = [[NSBundle mainBundle] pathForResource:@"twitch_proxy" ofType:@"js"];
    }
    
    // 2. Try to load from jailbreak tweak path
    if (![[NSFileManager defaultManager] fileExistsAtPath:jsPath]) {
        jsPath = @"/var/jb/Library/Application Support/TwitchProxy/twitch_proxy.js";
    }

    if ([[NSFileManager defaultManager] fileExistsAtPath:jsPath]) {
        NSString *jsCode = [NSString stringWithContentsOfFile:jsPath encoding:NSUTF8StringEncoding error:nil];
        if (jsCode) {
            // Regex to find PROXY_SERVERS = [ ... ]
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"PROXY_SERVERS\\s*=\\s*\\[(.*?)\\];" options:NSRegularExpressionDotMatchesLineSeparators error:nil];
            NSTextCheckingResult *match = [regex firstMatchInString:jsCode options:0 range:NSMakeRange(0, jsCode.length)];
            
            if (match) {
                NSString *arrayContent = [jsCode substringWithRange:[match rangeAtIndex:1]];
                NSRegularExpression *urlRegex = [NSRegularExpression regularExpressionWithPattern:@"'([^']+)'|\"([^\"]+)\"" options:0 error:nil];
                NSArray *urlMatches = [urlRegex matchesInString:arrayContent options:0 range:NSMakeRange(0, arrayContent.length)];
                
                NSMutableArray *servers = [NSMutableArray array];
                for (NSTextCheckingResult *urlMatch in urlMatches) {
                    NSRange range = [urlMatch rangeAtIndex:1];
                    if (range.location == NSNotFound) {
                        range = [urlMatch rangeAtIndex:2];
                    }
                    if (range.location != NSNotFound) {
                        [servers addObject:[arrayContent substringWithRange:range]];
                    }
                }
                
                if (servers.count > 0) {
                    proxyServers = [servers copy];
                    NSLog(@"[TwitchProxy] Loaded proxy servers from js: %@", proxyServers);
                    return;
                }
            }
        }
    }
    
    // Fallback if parsing fails or file is missing
    proxyServers = @[ @"https://proxy4.rte.net.ru/", @"https://proxy7.rte.net.ru/", @"https://proxy5.rte.net.ru/", @"https://proxy6.rte.net.ru/" ];
    NSLog(@"[TwitchProxy] Using default proxy servers: %@", proxyServers);
}

// Function to get the auth-token from cookies
static NSString* getAuthToken() {
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie *cookie in [cookieStorage cookies]) {
        if ([[cookie name] isEqualToString:@"auth-token"]) {
            return [cookie value];
        }
    }
    return nil;
}

static NSString* rewriteTwitchUrl(NSString *originalUrlString) {
    if (!originalUrlString || ![originalUrlString containsString:@"usher.ttvnw.net"]) {
        return originalUrlString;
    }

    NSString *proxyUrl = proxyServers.firstObject;
    if (!proxyUrl) return originalUrlString;

    // Use the first proxy (we can enhance this to check proxy health, but let's keep it simple)
    NSString *newUrlString = [proxyUrl stringByAppendingString:originalUrlString];
    
    // Get and append auth-token if present
    NSString *authToken = getAuthToken();
    if (authToken && authToken.length > 0) {
        NSString *separator = [originalUrlString containsString:@"?"] ? @"&" : @"?";
        NSString *encodedAuth = [authToken stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        newUrlString = [NSString stringWithFormat:@"%@%@auth=%@", newUrlString, separator, encodedAuth];
    }
    
    NSLog(@"[TwitchProxy] Proxied URL: %@", newUrlString);
    return newUrlString;
}

// Hooking NSURL initializations to rewrite the URL string before it is instantiated
%hook NSURL

+ (instancetype)URLWithString:(NSString *)URLString {
    NSString *newURLString = rewriteTwitchUrl(URLString);
    return %orig(newURLString);
}

+ (instancetype)URLWithString:(NSString *)URLString relativeToURL:(NSURL *)baseURL {
    if ([URLString containsString:@"usher.ttvnw.net"]) {
        NSString *newURLString = rewriteTwitchUrl(URLString);
        return %orig(newURLString, nil);
    }
    return %orig;
}

- (instancetype)initWithString:(NSString *)URLString {
    NSString *newURLString = rewriteTwitchUrl(URLString);
    return %orig(newURLString);
}

- (instancetype)initWithString:(NSString *)URLString relativeToURL:(NSURL *)baseURL {
    if ([URLString containsString:@"usher.ttvnw.net"]) {
        NSString *newURLString = rewriteTwitchUrl(URLString);
        return %orig(newURLString, nil);
    }
    return %orig;
}

%end

%ctor {
    NSLog(@"[TwitchProxy] Native Tweak loaded");
    loadProxyServers();
}
