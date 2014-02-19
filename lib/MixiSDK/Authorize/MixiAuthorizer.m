//
//  MixiAuthorizer.m
//  iosSDK
//
//  Created by Platform Service Department on 11/11/28.
//  Copyright 2011 mixi Inc. All rights reserved.
//

#import "MixiAuthorizer.h"

#import "Mixi.h"
#import "MixiConfig.h"
#import "MixiConstants.h"
#import "MixiRefreshTokenURLDelegate.h"
#import "MixiUserDefaults.h"
#import "MixiUtils.h"
#import "SBJson.h"

/** \cond PRIVATE */
@interface MixiAuthorizer (PRIVATE)
/* サブクラスでの実装を促すためのマーカー */
- (void)subclassResponsibility;

/* アクセストークンをリフレッシュするためのリクエストを取得 */
- (NSURLRequest*)requestToRefreshAccessToken;

/* userDefaults_が初期化されていなければ初期化して取得 */
- (MixiUserDefaults*)assuredUserDefaults;

/* 現在保持しているパーミッションを利用して認可するか否か */
- (BOOL)shouldKeepCurrentPermissions:(NSArray*)permissions;
@end
/** \endcond */

@implementation MixiAuthorizer

@synthesize mixi=mixi_,
    accessToken=accessToken_, 
    refreshToken=refreshToken_, 
    expiresIn=expiresIn_, 
    state=state_,
    accessTokenExpiryDate=accessTokenExpiryDate_,
    shouldLogoutAfterRevoke=shouldLogoutAfterRevoke_,
    permissions=permissions_;

+ (id)authorizer {
    return [[[self alloc] init] autorelease];
}

- (id)initWithMixi:(Mixi *)mixi {
    if ((self = [super init])) {
        self.mixi = mixi;
        userDefaults_ = [[MixiUserDefaults alloc] initWithConfig:mixi_.config];
        shouldLogoutAfterRevoke_ = NO;
    }
    return self;
}

- (void)dealloc {
    self.mixi = nil;
    self.accessToken = nil;
    self.refreshToken = nil;
    self.expiresIn = nil;
    self.state = nil;
    self.accessTokenExpiryDate = nil;
    [super dealloc];
}

#pragma mark - Authorize

- (BOOL)authorizeWithParentViewController:(UIViewController*)parentViewController for:(NSString*)permission, ... {
    NSMutableArray *permissions = [NSMutableArray array];
    [permissions addObject:permission];
	va_list args;
	va_start (args, permission);
	while ((permission = va_arg(args, id))) {
        [permissions addObject:permission];
	}
	va_end (args);
    return [self authorizeWithParentViewController:parentViewController forPermissions:permissions];
}

- (BOOL)authorize:(NSString*)permission, ... {
    NSMutableArray *permissions = [NSMutableArray array];
    [permissions addObject:permission];
	va_list args;
	va_start (args, permission);
	while ((permission = va_arg(args, id))) {
        [permissions addObject:permission];
	}
	va_end (args);
    return [self authorizeForPermissions:permissions];
}

- (BOOL)authorizeForPermission:(NSString*)permission {
    return [self authorizeForPermissions:[permission componentsSeparatedByString:@","]];
}

- (BOOL)authorizeForPermissions:(NSArray*)permissions {
    [self subclassResponsibility];
    return NO;
}

- (BOOL)authorizeWithParentViewController:(UIViewController*)parentViewController forPermissions:(NSArray*)permissions {
    return [self authorizeForPermissions:permissions];
}

- (BOOL)checkAndStorePermissions:(NSArray*)permissions {
    for (NSString *permission in permissions) {
        NSAssert(![permission isEqualToString:@"mixi_apps"], 
                 @"'mixi_apps' scope is deprecated. Use 'mixi_apps2' instead.");
    }
    if ([self shouldKeepCurrentPermissions:permissions]) {
        if (!permissions_ || [permissions_ count] == 0) {
            return NO;
        }
    }
    else {
        self.permissions = permissions;
    }
    return YES;
}

#pragma mark - Refresh token

- (NSURLRequest*)requestToRefreshAccessToken {
    NSString *post = [NSString stringWithFormat:@"grant_type=refresh_token&client_id=%@&client_secret=%@&refresh_token=%@",
                      self.mixi.config.clientId, self.mixi.config.secret, self.refreshToken];
    NSData *postData = [post dataUsingEncoding:NSUTF8StringEncoding];    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:kMixiApiRefreshTokenEndpoint]];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:postData];
    return request;
}

- (BOOL)refreshAccessToken {
    NSError *error = nil;
    [self refreshAccessTokenWithError:&error];
    return error == nil;
}

- (BOOL)refreshAccessTokenWithError:(NSError**)error {
    if (!self.accessToken || !self.refreshToken) {
        if (error != nil) {
            *error = [NSError errorWithDomain:kMixiErrorDomain
                                         code:kMixiAPIErrorNotAuthorized
                                     userInfo:[NSDictionary dictionaryWithObject:@"A token is nil." forKey:@"message"]];
        }
        return NO;
    }
    NSURLRequest *request = [self requestToRefreshAccessToken];
    NSURLResponse *res;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&res error:error];
    NSString *jsonString = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    if (!MixiUtilIsJson(jsonString)) {
        if (error != nil && *error == nil) {
            *error = [NSError errorWithDomain:kMixiErrorDomain
                                         code:kMixiAPIErrorInvalidJson
                                     userInfo:[NSDictionary dictionaryWithObject:jsonString forKey:@"message"]];
        }
        return NO;
    }
    *error = nil;
    SBJsonParser *parser = [[[SBJsonParser alloc] init] autorelease];
    NSDictionary *json = [parser objectWithString:jsonString error:error];
    if (error != nil && *error != nil) {
        return NO;
    }
    if ([json objectForKey:@"error"] != nil) {
        if ([[json objectForKey:@"error"] isEqual:@"invalid_grant"]) {
            *error = [NSError errorWithDomain:kMixiErrorDomain
                                         code:kMixiAPIErrorRefreshTokenExpired
                                     userInfo:json];            
        }
        else if (error != nil) {
            *error = [NSError errorWithDomain:kMixiErrorDomain
                                         code:kMixiAPIErrorReply
                                     userInfo:json];
        }
        return NO;
    }
    [self setPropertiesFromDictionary:json];
    [self store];
    return YES;
}

- (NSURLConnection*)refreshAccessTokenWithDelegate:(id<MixiDelegate>)delegate {
    NSURLRequest *request = [self requestToRefreshAccessToken];
    MixiRefreshTokenURLDelegate *urlDelegate = [MixiRefreshTokenURLDelegate delegateWithMixi:self.mixi delegate:delegate];
    return [[[NSURLConnection alloc] initWithRequest:request delegate:urlDelegate] autorelease];
}

#pragma mark - Revoke

- (void)clear {
    [userDefaults_ clear];
}

- (void)logout {
    // clear login cookies
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie* cookie in [cookieStorage cookies]) {
        if ([cookie.domain hasSuffix:@".mixi.jp"]) {
            [cookieStorage deleteCookie:cookie];
        }
    }

    [self clear];
    self.accessToken = nil;
    self.refreshToken = nil;
    self.expiresIn = nil;
    self.state = nil;
    self.accessTokenExpiryDate = nil;
    self.mixi.mixiViewController = nil;
    self.permissions = nil;
}

- (BOOL)revoke {
    [self subclassResponsibility];
    return NO;
}

- (BOOL)revokeWithError:(NSError**)error {
    [self subclassResponsibility];
    return NO;
}

- (BOOL)revokeAndLogout {
    self.shouldLogoutAfterRevoke = YES;
    return [self revoke];
}

- (BOOL)revokeAndLogoutWithError:(NSError**)error {
    self.shouldLogoutAfterRevoke = YES;
    return [self revokeWithError:error];
}

#pragma mark - Store/Restore

- (void)store {
    [[self assuredUserDefaults] storeAuthorizer:self];
}

- (BOOL)restore {
    return [[self assuredUserDefaults] restoreAuthorizer:self];
}

#pragma mark - Check status

- (BOOL)isAuthorized {
    return self.accessToken != nil;
}

- (BOOL)isAccessTokenExpired {
    if (self.accessTokenExpiryDate != nil) {
        return [self.accessTokenExpiryDate compare:[NSDate date]] == NSOrderedAscending;
    }
    else {
        return YES;
    }
}

- (BOOL)isRefreshTokenExpired {
    // 現在のところリフレッシュトークンの期限切れは考える必要がありません
    return NO;
}

#pragma mark - Setter/Getter

- (void)setPropertiesFromDictionary:(NSDictionary*)dict {
     self.accessToken = (NSString*)[dict objectForKey:@"access_token"];
     self.refreshToken = (NSString*)[dict objectForKey:@"refresh_token"];
     self.expiresIn = (NSString*)[dict objectForKey:@"expires_in"];
     self.state = (NSString*)[dict objectForKey:@"state"];
     if (self.expiresIn != nil) {
         self.accessTokenExpiryDate = [NSDate dateWithTimeIntervalSinceNow:[self.expiresIn intValue]];
     }
}

- (void)subclassResponsibility {
    [[NSException exceptionWithName:@"SubclassResponsibility"
                             reason:@"This method should be implemented in a subclasse of MixiAuthorizer."
                           userInfo:nil] raise];
}

- (void)setParentViewController:(UIViewController *)parentViewController {
    // do nothing
}

- (UIViewController*)parentViewController {
    // do nothing
    return nil;
}

- (id)delegate {
    // do nothing
    return nil;
}

- (void)setDelegate:(id)delegate {
    // do nothing    
}

#pragma mark - Private

- (MixiUserDefaults*)assuredUserDefaults {
    if (!userDefaults_ && mixi_) {
        userDefaults_ = [[MixiUserDefaults alloc] initWithConfig:mixi_.config];        
    }
    return userDefaults_;
}

- (BOOL)shouldKeepCurrentPermissions:(NSArray*)permissions {
    return [permissions count] == 0;
}

@end
