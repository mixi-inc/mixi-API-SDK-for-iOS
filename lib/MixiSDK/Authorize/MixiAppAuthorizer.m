//
//  MixiAppAuthorizer.m
//  iosSDK
//
//  Created by Platform Service Department on 11/11/28.
//  Copyright 2011 mixi Inc. All rights reserved.
//

#import "MixiAppAuthorizer.h"

#import "Mixi.h"
#import "MixiConfig.h"
#import "MixiConstants.h"
#import "MixiUtils.h"

/** \cond PRIVATE */
@interface MixiAppAuthorizer (Private)
/* トークンを取得するためのURLを取得 */
- (NSURL*)tokenURL:(NSArray*)permissions;
/* 認可を解除するためのURLを取得 */
- (NSURL*)revokeURL;
/* 現在保持しているパーミッションを利用して認可するか否か */
- (BOOL)shouldKeepCurrentPermissions:(NSArray*)permissions;
@end
/** \endcond */

@implementation MixiAppAuthorizer

- (id)init {
    if ((self = [super init])) {
        returnScheme_ = MixiUtilFirstBundleURLScheme();
    }
    return self;
}

#pragma mark - Authorize

- (BOOL)authorizeForPermissions:(NSArray*)permissions {
    if (![self checkAndStorePermissions:permissions]) {
        return NO;
    }
    
    NSURL *url = [self tokenURL:self.permissions];
    UIApplication *app = [UIApplication sharedApplication];
    if ([app canOpenURL:url]) {
        [UIPasteboard pasteboardWithName:self.mixi.config.pbkey create:YES];    
        [mixi_.uuReporter cancel];
        [app openURL:url];
        return YES;
    }
    else {
        return NO;
    }
}

#pragma mark - Revoke

- (BOOL)revoke {
    NSURL *url = [self revokeURL];
    UIApplication *app = [UIApplication sharedApplication];
    if ([app canOpenURL:url]) {
        [mixi_.uuReporter cancel];
        [app openURL:url];
        return YES;
    }
    else {
        return NO;
    }
}

- (BOOL)revokeWithError:(NSError**)error {
    // エラーはURLスキーム経由で返されるので無視する
    return [self revoke];
}

#pragma mark - Getter/Setter

- (id)delegate {
    NSLog(@"MixiAppAuthorizer can not set a delegate.");
    return nil;
}

- (void)setDelegate:(id)delegate {
    NSLog(@"MixiAppAuthorizer can not set a delegate.");
}

#pragma mark - Private methods

- (NSURL*)tokenURL:(NSArray*)permissions {
    return [NSURL URLWithString:[NSString stringWithFormat:@"%@#%@=%@&%@=%@&%@=%@", kMixiAppTokenUri, 
                                 kMixiSDKClientIdKey, mixi_.config.clientId, 
                                 kMixiSDKPermissionsKey, [permissions componentsJoinedByString:@"%20"],
                                 kMixiSDKReturnSchemeKey, returnScheme_]];
}

- (NSURL*)revokeURL {
    return [NSURL URLWithString:[NSString stringWithFormat:@"%@#%@=%@&%@=%@&%@=%@", kMixiAppRevokeUri, 
                                 kMixiSDKClientIdKey, mixi_.config.clientId,
                                 kMixiSDKTokenKey, self.refreshToken,
                                 kMixiSDKReturnSchemeKey, returnScheme_]];
}

@end
