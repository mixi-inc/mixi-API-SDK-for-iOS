//
//  MixiURLRequestConstructor.m
//
//  Created by Platform Service Department on 13/01/23.
//  Copyright (c) 2013 mixi Inc. All rights reserved.
//

#import "MixiURLRequestConstructor.h"
#import "MixiConstants.h"

@implementation MixiURLRequestConstructor
@synthesize endpoint=endpoint_,
    endpointBaseUrl=endpointBaseUrl_,
    openMixiAppToAuthorizeIfNeeded=openMixiAppToAuthorizeIfNeeded_;

- (id)initWithEndpoint:(NSString*)endpoint {
    if ((self = [super init])) {
        self.endpoint = endpoint;
        self.endpointBaseUrl = kMixiApiBaseUrl;
        self.openMixiAppToAuthorizeIfNeeded = YES;
    }
    return self;
}

- (NSURLRequest*)constructURLRequest:(Mixi*)mixi {
    NSAssert(false, @"Subclass Responsibility");
    return nil;
}

- (void)dealloc {
    self.endpoint = nil;
    self.endpointBaseUrl = nil;
    [super dealloc];
}


@end
