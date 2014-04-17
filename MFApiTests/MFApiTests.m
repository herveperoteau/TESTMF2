//
//  MFApiTests.m
//  MFApiTests
//
//  Created by herve.peroteau on 17/04/2014.
//  Copyright (c) 2014 MyFox. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MFApi.h"

#warning TODO: SET GOOD VALUE CLIENT_ID AND CLIENT_SECRET

#define CLIENT_ID       @"myfox"
#define CLIENT_SECRET   @"myf0x++"

#define LOGIN_DEMO    @"demo@myfox.me"
#define PWD_DEMO        @"demo14789"


@interface MFApiTests : XCTestCase

@end

@implementation MFApiTests {

    MFApi *_serverMyFox;
    dispatch_semaphore_t _semaphore;
}

- (void)setUp
{
    [super setUp];

    // Setup API
    _serverMyFox = [MFApi sharedInstance];
    _serverMyFox.clientId = CLIENT_ID;
    _serverMyFox.clientSecret = CLIENT_SECRET;

    // Use to wait end request
    _semaphore = dispatch_semaphore_create(0);

}

- (void)tearDown
{
    [super tearDown];
}

- (void)testLoginGood
{
    NSLog(@"%@.testLoginGood ...", self.class);
    
    [_serverMyFox signInWithLogin:LOGIN_DEMO
                         Password:PWD_DEMO
                   successHandler:^{
                       NSLog(@"%@.testLoginGood: success ...", self.class);
                       dispatch_semaphore_signal(_semaphore);
                   }
                   failureHandler:^(NSError *error) {
                       NSLog(@"%@.testLoginGood: error=%@ !!!", self.class, [error localizedDescription]);
                       XCTAssert(NO, "error=%@", [error localizedDescription]);
                       dispatch_semaphore_signal(_semaphore);
                   }];
    
    NSLog(@"%@.testLoginGood wait ... ", self.class);

    while (dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_NOW))
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:20]];
    
    NSLog(@"%@.testLoginGood Ended.", self.class);
}


- (void)testLoginBadPwd
{
    NSLog(@"%@.testLoginBadPwd ...", self.class);
    
    [_serverMyFox signInWithLogin:LOGIN_DEMO
                         Password:@"badpwd"
                   successHandler:^{
                       NSLog(@"%@.testLoginBadPwd: success ...", self.class);
                       XCTAssert(NO, "BADPWD doesn't call successHandler !!!");
                       dispatch_semaphore_signal(_semaphore);
                   }
                   failureHandler:^(NSError *error) {
                       NSLog(@"%@.testLoginBadPwd: error=%@ !!!", self.class, [error localizedDescription]);
                       dispatch_semaphore_signal(_semaphore);
                   }];
    
    NSLog(@"%@.testLoginBadPwd wait ... ", self.class);
    
    while (dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_NOW))
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:20]];
    
    NSLog(@"%@.testLoginBadPwd Ended.", self.class);
}

- (void)testLoginBadLogin
{
    NSLog(@"%@.testLoginBadLogin ...", self.class);
    
    [_serverMyFox signInWithLogin:@"badlogin"
                         Password:@"badpwd"
                   successHandler:^{
                       NSLog(@"%@.testLoginBadLogin: success ...", self.class);
                       XCTAssert(NO, "BADLOGIN doesn't call successHandler !!!");
                       dispatch_semaphore_signal(_semaphore);
                   }
                   failureHandler:^(NSError *error) {
                       NSLog(@"%@.testLoginBadLogin: error=%@ !!!", self.class, [error localizedDescription]);
                       dispatch_semaphore_signal(_semaphore);
                   }];
    
    NSLog(@"%@.testLoginBadLogin wait ... ", self.class);
    
    while (dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_NOW))
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:20]];
    
    NSLog(@"%@.testLoginBadLogin Ended.", self.class);
}



@end
