//
//  MixiSDKAuthorizerWebViewController.m
//  iosSDK
//
//  Copyright (c) 2012 mixi Inc. All rights reserved.
//

#import "MixiSDKAuthorizerWebViewController.h"

@implementation MixiSDKAuthorizerWebViewController

@synthesize endpoint=endpoint_, authorizer=authorizer_;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self startIndicatorAnimating];
}

- (IBAction)close:(id)sender {
    if (self.authorizer) {
        [self.authorizer performSelector:@selector(notifyCancelWithEndpoint:) withObject:self.endpoint];
    }
    [super close:sender];
}

- (void)dealloc {
    self.endpoint = nil;
    self.authorizer = nil;
    [super dealloc];
}

@end
