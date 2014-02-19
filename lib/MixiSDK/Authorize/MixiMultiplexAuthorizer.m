//
//  MixiMultiplexAuthorizer.m
//  iosSDK
//
//  Created by Platform Service Department on 12/06/13.
//  Copyright 2012 mixi Inc. All rights reserved.
//

#import "MixiMultiplexAuthorizer.h"
#import "MixiAppAuthorizer.h"
#import "MixiSDKAuthorizer.h"
#import "MixiUserDefaults.h"
#import "Mixi.h"

/** \cond PRIVATE */
@interface MixiSDKAuthorizer (Private)
- (MixiAuthorizer*)authorizer;
@end
/** \endcond */

@implementation MixiMultiplexAuthorizer

@synthesize appAuthorizer=appAuthorizer_, 
    sdkAuthorizer=sdkAuthorizer_;

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
        self.appAuthorizer = [MixiAppAuthorizer authorizer];
        self.sdkAuthorizer = [MixiSDKAuthorizer authorizerWithRedirectUrl:redirectUrlString
                                                     parentViewController:parentViewController];
        [self shouldChooseAuthorizer];
    }
    return self;
}

#pragma mark - Setter/getter

- (void)setMixi:(Mixi *)mixi {
    mixi_ = mixi;
    self.appAuthorizer.mixi = mixi;
    self.sdkAuthorizer.mixi = mixi;
}

- (void)setParentViewController:(UIViewController *)parentViewController {
    self.sdkAuthorizer.parentViewController = parentViewController;
}

- (UIViewController*)parentViewController {
    return self.sdkAuthorizer.parentViewController;
}

- (void)shouldUseAppAuthorizer {
    authorizerType_ = kMixiMultiplexAuthorizerApp;
}

- (void)shouldUseSDKAuthorizer {
    authorizerType_ = kMixiMultiplexAuthorizerSDK;    
}

- (void)shouldChooseAuthorizer {
    authorizerType_ = kMixiMultiplexAuthorizerAuto;
}

- (id)delegate {
    return self.sdkAuthorizer.delegate;
}

- (void)setDelegate:(id)delegate {
    self.sdkAuthorizer.delegate = delegate;
}

#pragma mark - Authorize

- (BOOL)authorizeForPermissions:(NSArray*)permissions {
    if (![self checkAndStorePermissions:permissions]) {
        return NO;
    }
    return [[self authorizer] authorizeForPermissions:self.permissions];
}

- (BOOL)authorizeWithParentViewController:(UIViewController*)parentViewController forPermissions:(NSArray*)permissions {
    if (![self checkAndStorePermissions:permissions]) {
        return NO;
    }
    [self setParentViewController:parentViewController];
    return [[self authorizer] authorizeForPermissions:self.permissions];
}

#pragma mark - Revoke

- (BOOL)revokeWithError:(NSError**)error {
    return [[self authorizer] revokeWithError:error];
}

- (BOOL)revoke {
    return [[self authorizer] revoke];
}

- (void)setShouldLogoutAfterRevoke:(BOOL)shouldLogoutAfterRevoke {
    appAuthorizer_.shouldLogoutAfterRevoke = shouldLogoutAfterRevoke;
    sdkAuthorizer_.shouldLogoutAfterRevoke = shouldLogoutAfterRevoke;
}

- (BOOL)shouldLogoutAfterRevoke {
    return [self authorizer].shouldLogoutAfterRevoke;
}

#pragma mark - Store/Restore

- (void)store {
    [[self performSelector:@selector(assuredUserDefaults)] storeAuthorizer:[self authorizer]];
}

#pragma mark - Memory management

- (void)dealloc {
    self.appAuthorizer = nil;
    self.sdkAuthorizer = nil;
    [super dealloc];
}

#pragma mark - Private

- (MixiAuthorizer*)authorizer {
    self.appAuthorizer.accessToken = self.accessToken;
    self.appAuthorizer.refreshToken = self.refreshToken;
    self.appAuthorizer.expiresIn = self.expiresIn;
    self.appAuthorizer.state = self.state;
    self.appAuthorizer.accessTokenExpiryDate = self.accessTokenExpiryDate;
    self.appAuthorizer.permissions = self.permissions;
    
    self.sdkAuthorizer.accessToken = self.accessToken;
    self.sdkAuthorizer.refreshToken = self.refreshToken;
    self.sdkAuthorizer.expiresIn = self.expiresIn;
    self.sdkAuthorizer.state = self.state;
    self.sdkAuthorizer.accessTokenExpiryDate = self.accessTokenExpiryDate;
    self.sdkAuthorizer.permissions = self.permissions;

    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        return self.sdkAuthorizer;
    }
    else if (authorizerType_ == kMixiMultiplexAuthorizerApp) {
        return self.appAuthorizer;
    }
    else if (authorizerType_ == kMixiMultiplexAuthorizerSDK) {
        return self.sdkAuthorizer;
    }
    else {
        return [mixi_ isMixiAppInstalled] ? self.appAuthorizer : self.sdkAuthorizer;
    }
}

@end
