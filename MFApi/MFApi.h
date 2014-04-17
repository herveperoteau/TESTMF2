//
//  MFApi.h
//  MFApi
//
//  Created by herve.peroteau on 17/04/2014.
//  Copyright (c) 2014 MyFox. All rights reserved.
//

#import <Foundation/Foundation.h>

#define MF_ERROR_DOMAIN                    @"MYFOX-API"

typedef NS_ENUM(NSInteger, MFErrorCode) {
    
    MFError = -600,
    MFErrorCodeInvalidUserPwd = -601    
};


#define MF_ERROR_CODE_INVALID_USER_PWD     601

@interface MFApi : NSObject


// Singleton
+(MFApi *) sharedInstance;

// NEED TO SETUP BEFORE USED API
@property (nonatomic, copy) NSString *clientId;
@property (nonatomic, copy) NSString *clientSecret;


// Block Completion Handlers
typedef void (^ReturnBlock)();
typedef void (^ReturnBlockWithObject)(id result);
typedef void (^ReturnBlockWithDictionary)(NSDictionary *result);
typedef void (^ReturnBlockWithError)(NSError *error);


#pragma mark - API public

-(void) signInWithLogin:(NSString *)login
               Password:(NSString *)pwd
         successHandler:(ReturnBlock)successHandler
         failureHandler:(ReturnBlockWithError)failureHandler;




@end
