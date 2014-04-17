//
//  MFApi.m
//  MFApi
//
//  Created by herve.peroteau on 17/04/2014.
//  Copyright (c) 2014 MyFox. All rights reserved.
//

#import "MFApi.h"

//#define USED_AFNETWORKING

#ifdef USED_AFNETWORKING
    #import <AFNetworking.h>
#else 
    #import <MKNetworkKit.h>
#endif

#import <NSDate-Utilities.h>

#define MFURLSCHEME     @"https://"
#define MFURLAPI        @"api.myfox.me"
#define MFVERSIONAPI    @"v2"

#define OAUTH_GRANTTYPE_ACCESS @"password"

#define METHOD_OAUTH_TOKEN @"/oauth2/token"


@interface MFApi ()

@property (nonatomic, copy) NSString *grantTypeAccess;
@property (nonatomic, copy) NSString *baseUrlString;

// TOKEN OAUTH
@property (nonatomic, copy) NSString *accessToken;
@property (nonatomic, copy) NSString *refreshToken;
@property (nonatomic, copy) NSString *typeToken;
@property (nonatomic, copy) NSString *scopeToken;
@property (nonatomic, assign) NSInteger durationToken;
@property (nonatomic, strong) NSDate *dateToken;
@property (nonatomic, strong) NSDate *expireDateToken;

@property (nonatomic, strong) NSError *lastError;
@property (nonatomic, strong) NSString *lastErrorIdent;
@property (nonatomic, strong) NSString *lastErrorDesc;

#ifdef USED_AFNETWORKING
    // AFNetworking Manager
    @property (nonatomic, strong) AFHTTPRequestOperationManager *httpManager;
#else 
    // MKNetworkKit Manager
    @property (nonatomic, strong) MKNetworkEngine *httpManager;
#endif

@end

@implementation MFApi

#pragma mark - init

+(MFApi *) sharedInstance {
    
    static dispatch_once_t pred;
    static MFApi *sharedInstance = nil;
    dispatch_once(&pred, ^{ sharedInstance = [[self alloc] init]; });
    return sharedInstance;
}

-(id) init {
    
    if ( (self = [super init]) ) {
        
        self.baseUrlString = MFURLAPI;
        self.grantTypeAccess = OAUTH_GRANTTYPE_ACCESS;
    }
    
    return self;
}

-(void) setBaseUrlString:(NSString *)baseUrlString {
    
    _baseUrlString = baseUrlString;
    
#ifdef USED_AFNETWORKING
    
    NSString *completeBaseUrlString = baseUrlString;
    
    if ( [baseUrlString rangeOfString:@"http://"].location == NSNotFound ) {
        completeBaseUrlString = [NSString stringWithFormat:@"%@%@", MFURLSCHEME, baseUrlString];
    }
    
    self.httpManager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:[NSURL URLWithString:completeBaseUrlString]];
#else
    self.httpManager = [[MKNetworkEngine alloc] initWithHostName:_baseUrlString];
#endif
}

-(void) checkSetup {
    
    NSAssert(self.clientId.length>0, @"Set clientId before use the API !!!");
    NSAssert(self.clientSecret.length>0, @"Set clientSecret before use the API !!!");
}

#pragma mark - API public

-(void) signInWithLogin:(NSString *)login
               Password:(NSString *)pwd
         successHandler:(ReturnBlock)successHandler
         failureHandler:(ReturnBlockWithError)failureHandler {
    
    NSLog(@"%@.signInWithLogin:%@ Password:%@ ...", self.class, login, pwd);
    
    [self getFreshTokenWithLogin:login
                        Password:pwd
                  successHandler:successHandler
                  failureHandler:failureHandler];
}


#pragma mark - privates methods

-(void) getFreshTokenWithLogin:(NSString *)login
                      Password:(NSString *)pwd
                successHandler:(ReturnBlock)successHandler
                failureHandler:(ReturnBlockWithError)failureHandler {
    
    NSLog(@"%@.getFreshTokenWithLogin:%@ Password:%@ ...", self.class, login, pwd);
    
    NSDictionary *params = @{@"client_id": self.clientId,
                             @"client_secret": self.clientSecret,
                             @"username" : login,
                             @"password" : pwd,
                             @"grant_type": self.grantTypeAccess};
    
    [self getTokenWithParams:params
              successHandler:successHandler
              failureHandler:failureHandler];
}

-(void) getTokenWithRefreshToken:(NSString *)refreshToken
                  successHandler:(ReturnBlock)successHandler
                  failureHandler:(ReturnBlockWithError)failureHandler {
    
    NSLog(@"%@.getTokenWithRefreshToken:%@ ...", self.class, refreshToken);
    
    NSDictionary *params = @{@"client_id": self.clientId,
                             @"client_secret": self.clientSecret,
                             @"refresh_token" : refreshToken,
                             @"grant_type": @"refresh_token"};
   
    [self getTokenWithParams:params
              successHandler:successHandler
              failureHandler:failureHandler];
}

-(void) getTokenWithParams:(NSDictionary *)params
            successHandler:(ReturnBlock)successHandler
            failureHandler:(ReturnBlockWithError)failureHandler {
    
    [self checkSetup];
    [self resetToken];
    
    __block MFApi *blockSelf = self;
    
#ifdef USED_AFNETWORKING
    
    [self.httpManager POST:METHOD_OAUTH_TOKEN
                parameters:params
                   success:^(AFHTTPRequestOperation *operation, id responseObject) {
                       
                       NSInteger statusCode = operation.response.statusCode;
                       
                       NSLog(@"%@.getTokenWithParams => statusCodeHTTP=%ld ...", self.class, (long)statusCode);
                       
                       NSError *error = [blockSelf parseOAuthResult:responseObject];
                       
                       if (error) {
                           
                           failureHandler(error);
                       }
                       else {
                           
                           successHandler();
                       }
                   }
                   failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                       
                       failureHandler(error);
                   }];
    
#else
    
    MKNetworkOperation *operation = [self.httpManager operationWithPath:METHOD_OAUTH_TOKEN
                                                                 params:params
                                                             httpMethod:@"POST"
                                                                    ssl:YES];
    
    [operation addCompletionHandler:^(MKNetworkOperation *completedOperation) {
        
        NSInteger statusCode = completedOperation.readonlyResponse.statusCode;
        
        NSLog(@"%@.getTokenWithParams => statusCodeHTTP=%ld ...", self.class, (long)statusCode);
        
        NSDictionary *json = completedOperation.responseJSON;
        
        NSError *error = [blockSelf parseOAuthResult:json];
        
        if (error) {
            
            failureHandler(error);
        }
        else {
            
            successHandler();
        }

    } errorHandler:^(MKNetworkOperation *completedOperation, NSError *error) {
        
        failureHandler(error);
    }];

    [self.httpManager enqueueOperation:operation forceReload:YES];

#endif
}


-(void) resetToken {
    
    self.accessToken = nil;
    self.typeToken = nil;
    self.scopeToken = nil;
    self.refreshToken = nil;
    self.dateToken = nil;
    self.expireDateToken = nil;
}

-(NSError *) parseOAuthResult:(NSDictionary *) response {

    NSError *error = nil;
    
    if ( (error = [self checkError:response]) ) {
        
        NSLog(@"%@.parseOAuthResult error=%@", self.class, error);
        return error;
    }

    //    {
    //        "access_token": "fd29fc95cbcb96dae703345e018998ba31ab0c5c",
    //        "expires_in": 3600,
    //        "token_type": "Bearer",
    //        "scope": null,
    //        "refresh_token": "6aa7802f7c8e443a55ca7f7b9c9d4ac346460325"
    //    }
    
    self.accessToken = response[@"access_token"];
    self.typeToken = response[@"token_type"];
    self.scopeToken = response[@"scope"];
    self.refreshToken = response[@"refresh_token"];
    
    NSNumber *expiresInNumber = response[@"expires_in"];
    self.durationToken = expiresInNumber.integerValue;
    if (self.durationToken == 0) {
        self.durationToken = 3600;
    }
    
    self.dateToken = [NSDate date];
    self.expireDateToken = [self.dateToken dateByAddingTimeInterval:self.durationToken];
    
    NSLog(@"%@.parseOAuthResult accessToken=%@, type=%@, scope=%@, refresh=%@, duration=%ld date=%@ expiry=%@", self.class,
              self.accessToken, self.typeToken, self.scopeToken, self.refreshToken, (long)self.durationToken, self.dateToken,   self.expireDateToken);
    
    return nil;
}

-(NSError *) checkError:(NSDictionary *)response  {
    
    //    {
    //        "error": "invalid_grant",
    //        "error_description": "Invalid username and password combination"
    //    }
    
    NSString *errorIdent = response[@"error"];
    NSString *errorDesc = response[@"error_description"];
    
    NSError *error = nil;
    
    if (errorIdent.length > 0) {
        
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey:errorDesc,
                                   NSLocalizedFailureReasonErrorKey:errorIdent};
        
        error = [NSError errorWithDomain:MF_ERROR_DOMAIN
                                    code:MFError
                                userInfo:userInfo];
    }
    
    self.lastError = error;
    self.lastErrorIdent = errorIdent;
    self.lastErrorDesc = errorDesc;

    return error;
}

- (BOOL)tokenExpired
{
    return ([[NSDate date] isLaterThanDate:self.expireDateToken]);
}





@end
