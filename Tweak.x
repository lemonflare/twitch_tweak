#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import <substrate.h>

@interface WebView
- (void)stringByEvaluatingJavaScriptFromString:(NSString *)script;
@end

@interface WKWebView
- (void)evaluateJavaScript:(NSString *)script completionHandler:(void (^)(id, NSError *))completionHandler;
@end

static NSString *kInjectedKey = @"com.reyohoho.twitch.injected";

%hook WebView

- (void)webView:(id)sender didClearWindowObject:(id)windowObject forFrame:(id)frame {
    %orig;

    UIView *view = (UIView *)self;
    if ([view respondsToSelector:@selector(setAssociatedObject:)]) {
        if (objc_getAssociatedObject(self, kInjectedKey)) return;
        objc_setAssociatedObject(self, kInjectedKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    NSString *jsPath = [[NSBundle mainBundle] pathForResource:@"twitch_proxy" ofType:@"js"];
    if (!jsPath) {
        jsPath = @"/var/jb/Library/Application Support/TwitchProxy/twitch_proxy.js";
    }

    if ([[NSFileManager defaultManager] fileExistsAtPath:jsPath]) {
        NSString *jsCode = [NSString stringWithContentsOfFile:jsPath encoding:NSUTF8StringEncoding error:nil];
        if (jsCode) {
            [self stringByEvaluatingJavaScriptFromString:jsCode];
            NSLog(@"[TwitchProxy] Injected into WebView");
        }
    }
}

%end

%hook WKWebView

- (void)evaluateJavaScript:(NSString *)script completionHandler:(void (^)(id, NSError *))completionHandler {
    %orig;
}

%new
- (void)loadTwitchProxy {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *jsPath = @"/var/jb/Library/Application Support/TwitchProxy/twitch_proxy.js";

        if ([[NSFileManager defaultManager] fileExistsAtPath:jsPath]) {
            NSString *jsCode = [NSString stringWithContentsOfFile:jsPath encoding:NSUTF8StringEncoding error:nil];
            if (jsCode) {
                [self evaluateJavaScript:jsCode completionHandler:^(id result, NSError *error) {
                    if (!error) {
                        NSLog(@"[TwitchProxy] Injected into WKWebView");
                    } else {
                        NSLog(@"[TwitchProxy] WKWebView injection error: %@", error);
                    }
                }];
            }
        }
    });
}

%end

%hook UIViewController

- (void)viewDidAppear:(BOOL)animated {
    %orig;

    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    if ([bundleID containsString:@"twitch"] || [bundleID containsString:@"video"]) {
        for (UIView *subview in self.view.subviews) {
            if ([subview isKindOfClass:%c(WKWebView)]) {
                WKWebView *webView = (WKWebView *)subview;
                [webView loadTwitchProxy];
            }
        }
    }
}

%end

%ctor {
    NSLog(@"[TwitchProxy] Tweak loaded");
}
