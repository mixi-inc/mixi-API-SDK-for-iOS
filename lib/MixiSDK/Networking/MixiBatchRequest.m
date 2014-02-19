//
//  MixiBatchRequest.m
//
//  Created by Platform Service Department on 13/01/23.
//  Copyright (c) 2013 mixi Inc. All rights reserved.
//

#import "MixiBatchRequest.h"
#import "Mixi.h"
#import "MixiConstants.h"
#import "MixiRequest.h"
#import "NSObject+SBJson.h"

@implementation MixiBatchRequest

@synthesize requests=requests_;

- (id)initWithEndpoint:(NSString*)endpoint {
    if ((self = [super initWithEndpoint:endpoint])) {
        self.requests = [NSMutableArray array];
    }
    return self;
}

- (void)addRequest:(NSDictionary*)request {
    [self.requests addObject:request];
}

- (void)clearRequests {
    [self.requests removeAllObjects];
}

- (NSURLRequest*)constructURLRequest:(Mixi*)mixi {
    NSMutableString *json = [NSMutableString string];
    [json appendString:@"["];
    BOOL isFirst = YES;
    for (NSDictionary *request in self.requests) {
        if (!isFirst) [json appendString:@","];
        [json appendString:[request JSONRepresentation]];
        isFirst = NO;
    }
    [json appendString:@"]"];
    
    MixiRequest *mixiRequest = [MixiRequest postRequestWithEndpoint:self.endpoint body:json];
    mixiRequest.endpointBaseUrl = self.endpointBaseUrl;
    mixiRequest.contentType = @"application/json";
    mixiRequest.openMixiAppToAuthorizeIfNeeded = self.openMixiAppToAuthorizeIfNeeded;
    return [mixiRequest constructURLRequest:mixi];
}

- (void)dealloc {
    self.requests = nil;
    [super dealloc];
}

@end
