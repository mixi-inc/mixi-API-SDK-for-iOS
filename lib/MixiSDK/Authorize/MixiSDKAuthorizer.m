//
//  MixiSDKAuthorizer.m
//  iosSDK
//
//  Created by Platform Service Department on 11/11/30.
//  Copyright 2011 mixi Inc. All rights reserved.
//

#import "MixiSDKAuthorizer.h"
#import "Mixi.h"
#import "MixiConfig.h"
#import "MixiConstants.h"
#import "MixiRequest.h"
#import "MixiUtils.h"
#import "MixiWebViewController.h"
#import "MixiSDKAuthorizerWebViewController.h"
#import "SBJson.h"

#define kMixiTokenEndpointBaseUrl @"https://secure.mixi-platform.com/2"
#define kMixiRevokeRedirectUrl @"file:///__MIXI_URL_SCHEME__:///authorize/revoke#"
#define kMixiSDKAuthorizerAnimated YES

/** \cond PRIVATE */
@interface MixiSDKAuthorizer (Private)
- (void)requestToken:(NSString*)query;
- (void)requestRevoke:(NSString*)fragment;
- (NSURL*)tokenURL:(NSArray*)permissions;
- (NSURL*)revokeURL;
- (BOOL)isJoinCompletedUrl:(NSString*)urlString;
- (BOOL)isNotJoinedMixiAppUrl:(NSString*)redirectUrlString;
- (BOOL)notifySuccessWithEndpoint:(NSString*)endpoint;
- (BOOL)notifyCancelWithEndpoint:(NSString*)endpoint;
- (BOOL)notifyError:(NSError*)error withEndpoint:(NSString*)endpoint;
- (void)stopWebViewIndicatorAnimating;
- (BOOL)dismissIfParentViewControllerExists;
- (BOOL)canHandleBySDK:(NSURLRequest*)request;
- (BOOL)canNotHandleBySDK:(NSURLRequest*)request;
- (BOOL)shouldKeepCurrentPermissions:(NSArray*)permissions;
@end
/** \endcond */

@implementation MixiSDKAuthorizer

@synthesize delegate=authorizerDelegate_,
    parentViewController=parentViewController_,
    redirectUrl=redirectUrl_,
    toolbarColor=toolbarColor_,
    authUrl=authUrl_;

#pragma mark - Init

+ (id)authorizer {
    return [[[self alloc] init] autorelease];
}

+ (id)authorizerWithParentViewController:(UIViewController*)parentViewController {
    return [[[self alloc] initWithParentViewController:parentViewController] autorelease];
}

+ (id)authorizerWithRedirectUrl:(NSString*)redirectUrlString {
    return [[[self alloc] initWithRedirectUrl:redirectUrlString] autorelease];
}

+ (id)authorizerWithRedirectUrl:(NSString*)redirectUrlString parentViewController:(UIViewController*)parentViewController {
    return [[[self alloc] initWithRedirectUrl:redirectUrlString parentViewController:parentViewController] autorelease];
}

- (id)init {
//    return [self initWithRedirectUrl:kMixiDefaultRedirectUrl parentViewController:nil];
    return [self initWithRedirectUrl:nil parentViewController:nil];
}

- (id)initWithParentViewController:(UIViewController*)parentViewController {
    return [self initWithRedirectUrl:nil parentViewController:parentViewController];
}

- (id)initWithRedirectUrl:(NSString*)redirectUrlString {
    return [self initWithRedirectUrl:redirectUrlString parentViewController:nil];
}

- (id)initWithRedirectUrl:(NSString*)redirectUrlString parentViewController:(UIViewController*)parentViewController {
    if ((self = [super init])) {
        self.redirectUrl = redirectUrlString;
        self.parentViewController = parentViewController;
    }
    return self;
}

#pragma mark - Authorize

- (MixiWebViewController*)authorizerViewController:(NSArray*)permissions {
    if (![self checkAndStorePermissions:permissions]) {
        return nil;
    }
    self.authUrl = [self tokenURL:self.permissions];

    MixiSDKAuthorizerWebViewController *vc = [[[MixiSDKAuthorizerWebViewController alloc] initWithURL:self.authUrl delegate:self] autorelease];
    vc.endpoint = kMixiApiTokenEndpoint;
    vc.authorizer = self;
    return vc;
}

- (BOOL)authorizeWithParentViewController:(UIViewController*)parentViewController forPermissions:(NSArray*)permissions {
    [self setParentViewController:parentViewController];
    return [self authorizeForPermissions:permissions];
}

- (BOOL)authorizeForPermissions:(NSArray*)permissions {
    MixiWebViewController *vc = [self authorizerViewController:permissions];
    if (!vc) return NO;
    vc.toolbarTitle = @"利用同意";

    if (self.toolbarColor) vc.toolbarColor = self.toolbarColor;
    MixiUtilPresentModalViewControllerAnimated(self.parentViewController, vc, kMixiSDKAuthorizerAnimated);
    return YES;
}

#pragma mark - Revoke

- (MixiWebViewController*)revokerViewControllerWithError:(NSError**)error {
    NSURL *revokeURL = [self revokeURL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:revokeURL 
                                                           cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                       timeoutInterval:20];
    [request setHTTPMethod:@"GET"];
    [request setValue:[NSString stringWithFormat:@"OAuth %@", self.accessToken] forHTTPHeaderField:@"Authorization"];
    [request setValue:[MixiRequest userAgent] forHTTPHeaderField:@"User-Agent"];
    
    NSURLResponse *res = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request 
                                         returningResponse:&res
                                                     error:error];
    NSString *html = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    NSDictionary *header = [(NSHTTPURLResponse*)res allHeaderFields];
    if (*error != nil) {
        return nil;
    }
    else if ([[header objectForKey:@"Www-Authenticate"] isEqualToString:@"OAuth error='invalid_request'"]) {
        *error = [NSError errorWithDomain:kMixiErrorDomain code:kMixiAuthErrorOAuthFailed userInfo:[NSDictionary dictionaryWithObject:@"invalid_request" forKey:@"message"]];
        return nil;
    }
    else if ([html hasPrefix:@"{\""] && [html hasSuffix:@"\"}"]) {
        SBJsonParser *parser = [[[SBJsonParser alloc] init] autorelease];
        NSDictionary *json = [parser objectWithString:html error:error];
        if (*error == nil) {
            *error = [NSError errorWithDomain:kMixiErrorDomain code:kMixiAPIErrorReply userInfo:json];
        }
        return nil;
    }
    MixiSDKAuthorizerWebViewController *vc = [[[MixiSDKAuthorizerWebViewController alloc] initWithHTML:html delegate:self] autorelease];
    vc.endpoint = kMixiApiRevokeEndpoint;
    vc.authorizer = self;
    return vc;
}

- (BOOL)revokeWithError:(NSError**)error {
    MixiWebViewController *vc = [self revokerViewControllerWithError:error];
    if (vc) {
        vc.toolbarTitle = @"認証取消";
        if (self.toolbarColor) vc.toolbarColor = self.toolbarColor;
        MixiUtilPresentModalViewControllerAnimated(self.parentViewController, vc, kMixiSDKAuthorizerAnimated);
        return YES;
    }
    else {
        return NO;
    }
}

- (BOOL)revoke {
    NSError *error = nil;
    BOOL ret = [self revokeWithError:&error];
    if (error) {
        [self notifyError:error withEndpoint:kMixiApiRevokeEndpoint];
    }
    return ret;
}

#pragma mark - Memory management

- (void)dealloc {
    self.authUrl = nil;
    [super dealloc];
}

#pragma mark - WebViewDelegate

// SDK内で認可する場合は公式アプリを起動しないようにしておく
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSString *urlString = [[request URL] absoluteString];

    if (![self canHandleBySDK:request]) {
        // 設定されたリダイレクトURLの場合はSDK内で処理する
        if (![urlString hasPrefix:mixi_.config.redirectUrl]) {
            [[UIApplication sharedApplication] openURL:request.URL];
        }
        return NO;
    }
    else if ([self canNotHandleBySDK:request]) {
        MixiUtilShowMessageTitle(@"ページを表示できません。", @"");
        return NO;
    }
    else if ([urlString hasPrefix:kMixiAppCancelUri]) {
        // revokeをキャンセルされた場合
        [self dismissIfParentViewControllerExists];
        [self notifyCancelWithEndpoint:kMixiApiRevokeEndpoint];
        return NO;
    }
    else {
        NSString *body = [[[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding] autorelease];
        if ([body rangeOfString:@"&deny="].location != NSNotFound) {
            // token取得をキャンセルされた場合
            [self dismissIfParentViewControllerExists];
            [self notifyCancelWithEndpoint:kMixiApiTokenEndpoint];
            return NO;
        }
        else {
            if ([urlString hasSuffix:@"connect_authorize.pl"]) {
                // 認可実行中は認可ボタンをdisabledにする
                [webView stringByEvaluatingJavaScriptFromString:@"document.querySelector(\"input[class='cpSubmitBtn02']\").disabled = true;"];
            }
            else if ([urlString hasSuffix:@"login.pl"]) {
                // ログイン実行中はログインボタンをdisabledにする
                [webView stringByEvaluatingJavaScriptFromString:@"document.querySelector(\"p[class='loginButton'] input\").disabled = true;"];                
            }
            return ![urlString hasPrefix:mixi_.config.redirectUrl];
        }
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [self stopWebViewIndicatorAnimating];

    NSString *errorFailingUrl = [[[error userInfo] objectForKey:@"NSErrorFailingURLKey"] absoluteString];
    if ([self isNotJoinedMixiAppUrl:errorFailingUrl]) {
        NSString *appId = (NSString*)[[self.mixi.config.clientId componentsSeparatedByString:@"_"] lastObject];
        NSString *viewAppliUrl = [NSString stringWithFormat:@"%@?native=ios&id=%@&cid=%@", kMixiViewAppliURL, appId, self.mixi.config.clientId];
        [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:viewAppliUrl]]];
    } else if ([errorFailingUrl hasPrefix:[Mixi sharedMixi].config.redirectUrl]) {
        // get token
        [self requestToken:errorFailingUrl];
    }
    else if ([errorFailingUrl hasPrefix:kMixiRevokeRedirectUrl]) {
        // revoke
        NSString *fragment = [[errorFailingUrl stringByReplacingOccurrencesOfString:kMixiRevokeRedirectUrl withString:@""] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [self requestRevoke:fragment];
    }
    else if (error.code == NSURLErrorCancelled) {
        // do nothing
    }
    else {
        [self notifyError:error withEndpoint:kMixiApiUnknownEndpoint];
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    if (self.parentViewController) {
        [self stopWebViewIndicatorAnimating];

        MixiWebViewController *vc = (MixiWebViewController*)MixiUtilModalViewController(self.parentViewController);
        NSString *html = [webView stringByEvaluatingJavaScriptFromString:@"document.body.innerHTML"];
        if ([html rangeOfString:@"<form action=\"/login.pl\""].location != NSNotFound) {
            vc.toolbarTitle = @"ログイン";
        }
        else if ([[webView.request URL] isFileURL]) {
            vc.toolbarTitle = @"認証取消";
        }
        else {
            vc.toolbarTitle = @"利用同意";
        }
    }
    
    NSString *urlString = [[webView.request URL] absoluteString];
    if ([self isJoinCompletedUrl:urlString]) {
        [webView loadRequest:[NSURLRequest requestWithURL:self.authUrl]];
    }
//    else if ([urlString rangeOfString:self.redirectUrl].location != NSNotFound) {
    else if (self.redirectUrl && [urlString rangeOfString:self.redirectUrl].location != NSNotFound) {
        [self requestToken:[[webView.request URL] query]];
    }    
}

- (void)requestToken:(NSString*)query {
    NSString *authCode = [[query componentsSeparatedByString:@"="] objectAtIndex:1];
    MixiRequest *request = [MixiRequest postRequestWithEndpoint:kMixiApiTokenEndpoint paramsAndKeys:
                            @"authorization_code", @"grant_type",
                            self.mixi.config.clientId, @"client_id",   
                            self.mixi.config.secret, @"client_secret", 
                            authCode, @"code", 
                            self.mixi.config.redirectUrl, @"redirect_uri",
                            nil];
    request.endpointBaseUrl = kMixiTokenEndpointBaseUrl;
    [self.mixi sendRequest:request delegate:self forced:YES];
}

- (void)requestRevoke:(NSString*)fragment {
    NSError *error = nil;
    SBJsonParser *parser = [[[SBJsonParser alloc] init] autorelease];
    NSDictionary *json = [parser objectWithString:fragment error:&error];
    if (error) {
        [self notifyError:error withEndpoint:kMixiApiRevokeEndpoint];
    }
    else {
        if ([json objectForKey:@"error"]) {
            error = [NSError errorWithDomain:kMixiErrorDomain code:kMixiAPIErrorReply userInfo:json];
            [self notifyError:error withEndpoint:kMixiApiRevokeEndpoint];
        }
        else {
            MixiRequest *request = [MixiRequest postRequestWithEndpoint:kMixiApiRevokeEndpoint params:json];
            [self.mixi sendRequest:request delegate:self forced:YES];
        }
    }
}

#pragma mark - MixiDelegate


- (void)mixi:(Mixi*)mixi didSuccessWithJson:(NSDictionary*)data {
    // revokeに成功してもリダイレクト先不正でmixi:didFailWithConnection:error:が実行されるため
    // ここはtoken取得の場合しか通過しない
    [self.mixi setPropertiesFromDictionary:data];
    [self.mixi store];
    [self notifySuccessWithEndpoint:kMixiApiTokenEndpoint];
    [self dismissIfParentViewControllerExists];
}

- (void)mixi:(Mixi*)mixi didFailWithConnection:(NSURLConnection*)connection error:(NSError*)error {
    if (error.code == -1002/*unsupported URL*/ 
        && [[[error.userInfo objectForKey:@"NSErrorFailingURLKey"] absoluteString] isEqualToString:@"mixi-connect://success"]) {
        // success revoking
        [self notifySuccessWithEndpoint:kMixiApiRevokeEndpoint];
        if (self.shouldLogoutAfterRevoke) [self.mixi logout];
        [self dismissIfParentViewControllerExists];
    }
    else if ([self notifyError:error withEndpoint:kMixiApiUnknownEndpoint]) {
        // do nothing
    }
    else {
        [self dismissIfParentViewControllerExists];
    }
}

- (void)mixi:(Mixi*)mixi didFailWithError:(NSError*)error {
    [self notifyError:error withEndpoint:kMixiApiUnknownEndpoint];
    [self dismissIfParentViewControllerExists];
}

#pragma mark - Private

- (NSURL*)tokenURL:(NSArray*)permissions {
    return [NSURL URLWithString:[NSString stringWithFormat:@"%@?client_id=%@&reponse_code=code&scope=%@&display=ios", 
                                 kMixiConnectAuthorizeURL, mixi_.config.clientId, [permissions componentsJoinedByString:@"%20"]]];
}

- (NSURL*)revokeURL {
    return [NSURL URLWithString:[NSString stringWithFormat:@"%@%@?client_id=%@&token=%@&display=touch", 
                                 kMixiApiBaseUrl, kMixiApiRevokeEndpoint, mixi_.config.clientId, self.refreshToken]];
}

- (BOOL)isJoinCompletedUrl:(NSString*)urlString {
    return [urlString rangeOfString:@"run_appli.pl"].location != NSNotFound;
}

- (BOOL)isNotJoinedMixiAppUrl:(NSString*)redirectUrlString {
    return self.mixi.config.selectorType == kMixiApiTypeSelectorMixiApp 
        && [redirectUrlString hasSuffix:@"?error=access_denied"];
}

- (BOOL)notifySuccessWithEndpoint:(NSString*)endpoint {
    if (self.delegate && [self.delegate respondsToSelector:@selector(authorizer:didSuccessWithEndpoint:)]) {
        [self.delegate authorizer:self didSuccessWithEndpoint:endpoint];
        return YES;
    }
    else {
        return NO;
    }
}

- (BOOL)notifyCancelWithEndpoint:(NSString*)endpoint {
    if (self.delegate && [self.delegate respondsToSelector:@selector(authorizer:didCancelWithEndpoint:)]) {
        [self.delegate authorizer:self didCancelWithEndpoint:endpoint];
        return YES;
    }
    else {
        return NO;
    }
}

- (BOOL)notifyError:(NSError*)error withEndpoint:(NSString*)endpoint {
    if (self.delegate && [self.delegate respondsToSelector:@selector(authorizer:didFailWithEndpoint:error:)]) {
        [self.delegate authorizer:self didFailWithEndpoint:endpoint error:error];
        return YES;
    }
    else {
        return NO;
    }
}

- (void)stopWebViewIndicatorAnimating {
    if (self.parentViewController && MixiUtilModalViewController(self.parentViewController))
        [(MixiWebViewController*)MixiUtilModalViewController(self.parentViewController) stopIndicatorAnimating];
}

- (BOOL)dismissIfParentViewControllerExists {
    if (self.parentViewController) {
        if (kMixiSDKAuthorizerAnimated) {
            [self.parentViewController performSelector:@selector(dismissModalViewControllerAnimated:) 
                                            withObject:[NSNumber numberWithBool:kMixiSDKAuthorizerAnimated]
                                            afterDelay:0.5];
        }
        else {
            MixiUtilDismissModalViewControllerAnimated(self.parentViewController, kMixiSDKAuthorizerAnimated);
        }
        return YES;
    }
    else {
        return NO;
    }
}

- (BOOL)canHandleBySDK:(NSURLRequest*)request {
    if ([request.URL isFileURL]) return YES; // for revoke
    
    NSString *hostPath = [NSString stringWithFormat:@"%@%@", 
                          request.mainDocumentURL.host, 
                          request.mainDocumentURL.path];
    NSArray *whiteList = [NSArray arrayWithObjects:
                          @"mixi.jp/connect_authorize.pl", 
                          @"mixi.jp/login.pl", 
                          @"mixi.jp/check.pl", 
                          @"mixi.jp/view_appli.pl", 
                          @"mixi.jp/run_appli.pl", 
                          @"success",
                          @"cancel",
                          @"error",
                          nil];
    return YES || [whiteList containsObject:hostPath];
}

- (BOOL)canNotHandleBySDK:(NSURLRequest*)request {
    NSString *hostPath = [NSString stringWithFormat:@"%@%@", 
                          request.mainDocumentURL.host, 
                          request.mainDocumentURL.path];
    NSArray *blackHostList = [NSArray arrayWithObjects:
                              @"payment.mixi.jp",
                              nil];
    NSArray *blackPathList = [NSArray arrayWithObjects:
                              @"mixi.jp/premium.pl", 
                              nil];
    return [blackHostList containsObject:request.mainDocumentURL.host] 
        || [blackPathList containsObject:hostPath];
}

@end
