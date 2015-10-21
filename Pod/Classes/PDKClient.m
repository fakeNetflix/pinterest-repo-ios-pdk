//  Copyright (c) 2015 Pinterest. All rights reserved.
//  Created by Ricky Cancro on 1/28/15.

#if TARGET_OS_IPHONE
@import UIKit;
#endif
#import "PDKClient.h"

#import "PDKBoard.h"
#import "PDKCategories.h"
#import "PDKPin.h"
#import "PDKResponseObject.h"
#import "PDKUser.h"

#import <SSKeychain/SSKeychain.h>

NSString * const PDKClientReadPublicPermissions = @"read_public";
NSString * const PDKClientWritePublicPermissions = @"write_public";
NSString * const PDKClientReadPrivatePermissions = @"read_private";
NSString * const PDKClientWritePrivatePermissions = @"write_private";
NSString * const PDKClientReadRelationshipsPermissions = @"read_relationships";
NSString * const PDKClientWriteRelationshipsPermissions = @"write_relationships";

NSString * const kPDKClientBaseURLString = @"https://api.pinterest.com/v1/";

static NSString * const PDKPinterestSDK = @"pinterestSDK";
static NSString * const PDKPinterestSDKUsername = @"authenticatedUser";

static NSString * const PDKPinterestSDKPermissionsKey = @"PDKPinterestSDKPermissionsKey";
static NSString * const PDKPinterestSDKAppIdKey = @"PDKPinterestSDKAppIdKey";
static NSString * const PDKPinterestSDKUserIdKey = @"PDKPinterestSDKUserIdKey";

static NSString * const kPDKPinterestAppOAuthURLString = @"pinterestsdk.v1://oauth/";
static NSString * const kPDKPinterestWebOAuthURLString = @"https://api.pinterest.com/oauth/";

@interface PDKClient()
@property (nonatomic, assign) BOOL configured;
@property (nonatomic, copy, readwrite) NSString *appId;
@property (nonatomic, copy) NSString *clientRedirectURLString;
@property (nonatomic, assign, readwrite) BOOL authorized;
@property (nonatomic, copy) PDKClientSuccess authenticationSuccessBlock;
@property (nonatomic, copy) PDKClientFailure authenticationFailureBlock;

@end

@implementation PDKClient

+ (instancetype)sharedInstance
{
    static PDKClient *gClientSDK;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        gClientSDK = [[[self class] alloc] initWithBaseURL:[NSURL URLWithString:kPDKClientBaseURLString]];
    });
    return gClientSDK;
}

+ (void)configureSharedInstanceWithAppId:(NSString *)appId
{
    [[self sharedInstance] setAppId:appId];
    [[self sharedInstance] setClientRedirectURLString:[NSString stringWithFormat:@"pdk%@", appId]];
    [[self sharedInstance] setConfigured:YES];
}

- (instancetype)initWithBaseURL:(NSURL *)baseURL
{
    if (self = [super initWithBaseURL:baseURL]) {
        _configured = NO;
        _authorized = NO;
    }
    return self;
}

- (NSString *)appId
{
    NSAssert(self.configured == YES, @"PDKClient must be configured before use. Call [PDK configureShareInstanceWithAppId:]");
    return _appId;
}

- (void)inspectToken:(NSString *)oauthToken
         withSuccess:(PDKClientSuccess)successBlock
          andFailure:(PDKClientFailure)failureBlock
{
    [[[self class] sharedInstance] getPath:@"oauth/inspect"
                                parameters:@{@"access_token":oauthToken,
                                             @"token":oauthToken}
                               withSuccess:successBlock
                                andFailure:failureBlock];
    
    
}

- (BOOL)verifyTokenDetails:(NSDictionary *)dictionary
{
    BOOL verified = NO;
    NSDictionary *dataDictionary = dictionary[@"data"];
    if (dataDictionary) {
        NSArray *permissions = dataDictionary[@"scopes"];
        NSNumber *userId = dataDictionary[@"user_id"];
        
        NSDictionary *appDictionary = dataDictionary[@"app"];
        if (appDictionary) {
            NSNumber *appId = appDictionary[@"id"];
            
            NSArray *cachedPermissions = [[NSUserDefaults standardUserDefaults] objectForKey:PDKPinterestSDKPermissionsKey];
            NSNumber *cachedAppId = [[NSUserDefaults standardUserDefaults] objectForKey:PDKPinterestSDKAppIdKey];
            NSNumber *cachedUserId = [[NSUserDefaults standardUserDefaults] objectForKey:PDKPinterestSDKUserIdKey];
            
            permissions = [permissions sortedArrayUsingSelector:@selector(compare:)];
            verified =  cachedAppId && cachedPermissions && cachedUserId &&
            [appId isEqualToNumber:cachedAppId] &&
            [permissions isEqualToArray:cachedPermissions] &&
            [userId isEqualToNumber:cachedUserId];
        }
    }
    
    return verified;
}

- (void)recordTokenDetails:(NSDictionary *)dictionary
{
    NSDictionary *dataDictionary = dictionary[@"data"];
    if (dataDictionary) {
        NSArray *permissions = dataDictionary[@"scopes"];
        NSNumber *userId = dataDictionary[@"user_id"];
        
        NSDictionary *appDictionary = dataDictionary[@"app"];
        if (appDictionary) {
            NSNumber *appId = appDictionary[@"id"];
            
            permissions = [permissions sortedArrayUsingSelector:@selector(compare:)];
            [[NSUserDefaults standardUserDefaults] setObject:permissions forKey:PDKPinterestSDKPermissionsKey];
            [[NSUserDefaults standardUserDefaults] setObject:userId forKey:PDKPinterestSDKUserIdKey];
            [[NSUserDefaults standardUserDefaults] setObject:appId forKey:PDKPinterestSDKAppIdKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
}

// authentication
- (void)authenticateWithPermissions:(NSArray *)permissions
                        withSuccess:(PDKClientSuccess)successBlock
                         andFailure:(PDKClientFailure)failureBlock
{
    __weak PDKClient *weakSelf = self;
    
    // Check to see if we have a saved token and that the permissions are valid
    NSString *cachedToken = [SSKeychain passwordForService:PDKPinterestSDK account:PDKPinterestSDKUsername];
    NSArray *cachedPermissions = [[NSUserDefaults standardUserDefaults] objectForKey:PDKPinterestSDKPermissionsKey];
    if (cachedToken && cachedPermissions) {
        
        PDKClientFailure localFailureBlock = ^(NSError *error) {
            [SSKeychain deletePasswordForService:PDKPinterestSDK account:PDKPinterestSDKUsername];
            [weakSelf authenticateWithPermissions:permissions withSuccess:successBlock andFailure:failureBlock];
        };
        
        [self inspectToken:cachedToken
               withSuccess:^(PDKResponseObject *responseObject) {
                   BOOL validCachedCredentials = NO;
                   if ([responseObject isValid]) {
                       if ([weakSelf verifyTokenDetails:responseObject.parsedJSONDictionary]) {
                           weakSelf.authorized = YES;
                           weakSelf.oauthToken = cachedToken;
                           validCachedCredentials = YES;
                           NSSet *fields = [NSSet setWithArray:@[@"id",
                                                                 @"username",
                                                                 @"first_name",
                                                                 @"last_name",
                                                                 @"bio",
                                                                 @"created_at",
                                                                 @"counts",
                                                                 @"image"]];
                           [[PDKClient sharedInstance] getAuthorizedUserFields:fields
                                                                   withSuccess:successBlock
                                                                    andFailure:failureBlock];
                       }
                   }
                   
                   if (validCachedCredentials == NO) {
                       localFailureBlock(nil);
                   }
                   
               } andFailure:localFailureBlock];
    } else {
        self.authenticationSuccessBlock = successBlock;
        self.authenticationFailureBlock = failureBlock;
        
        NSString *permissionsString = [permissions componentsJoinedByString:@","];
        NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
        if (appName == nil) {
            appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
        }
        
        NSDictionary *params = @{@"client_id" : self.appId,
                                 @"permissions" : permissionsString,
                                 @"app_name" : appName
                                 };
        
        // check to see if the Pinterest app is installed
        NSURL *oauthURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@", kPDKPinterestAppOAuthURLString, [params _PDK_queryStringValue]]];
        
#if TARGET_OS_IPHONE
        if ([[UIApplication sharedApplication] canOpenURL:oauthURL]) {
            [[UIApplication sharedApplication] openURL:oauthURL];
        } else {
            NSString *redirectURL = [NSString stringWithFormat:@"pdk%@://", self.appId];
            params = @{@"client_id" : self.appId,
                       @"scope" : permissionsString,
                       @"redirect_uri" : redirectURL,
                       @"response_type": @"token",
                       };
            
            // open the web oauth
            oauthURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@", kPDKPinterestWebOAuthURLString, [params _PDK_queryStringValue]]];
            [[UIApplication sharedApplication] openURL:oauthURL];
        }
#else
        NSString *redirectURL = [NSString stringWithFormat:@"pdk%@://", self.appId];
        params = @{@"client_id" : self.appId,
                   @"scope" : permissionsString,
                   @"redirect_uri" : redirectURL,
                   @"response_type": @"token",
                   };
        
        // open the web oauth
        oauthURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@", kPDKPinterestWebOAuthURLString, [params _PDK_queryStringValue]]];
        [[NSWorkspace sharedWorkspace] openURL:oauthURL];
#endif
    }
}

+ (void)clearAuthorizedUser
{
    [SSKeychain deletePasswordForService:PDKPinterestSDK account:PDKPinterestSDKUsername];
}

- (BOOL)handleCallbackURL:(NSURL *)url
{
    BOOL handled = NO;
    NSString *urlScheme = [url scheme];
    if ([urlScheme isEqualToString:self.clientRedirectURLString]) {
        // get the oauth token
        NSDictionary *parameters = [NSDictionary _PDK_dictionaryWithQueryString:[url query]];
        NSString *method = parameters[@"method"];
        if (method == nil) {
            method = @"auth";
        }
        
        __weak PDKClient *weakSelf = self;
        PDKClientFailure localFailureBlock = ^(NSError *error) {
            if (weakSelf.authenticationFailureBlock) {
                weakSelf.authenticationFailureBlock(error);
                weakSelf.authenticationFailureBlock = nil;
            }
        };
        
        if ([method isEqualToString:@"auth"]) {
            if ([parameters[@"access_token"] length] > 0) {
                NSString *oauthToken = parameters[@"access_token"];
                
                [self inspectToken:oauthToken
                       withSuccess:^(PDKResponseObject *responseObject) {
                           // save the permissions that were just authorized
                           [weakSelf recordTokenDetails:responseObject.parsedJSONDictionary];
                           
                           weakSelf.oauthToken = oauthToken;
                           [SSKeychain setPassword:weakSelf.oauthToken forService:PDKPinterestSDK account:PDKPinterestSDKUsername];
                           
                           [[PDKClient sharedInstance] getPath:@"me/"
                                                    parameters:nil
                                                   withSuccess:^(PDKResponseObject *responseObject) {
                                                       [PDKClient sharedInstance].authorized = YES;
                                                       if (weakSelf.authenticationSuccessBlock) {
                                                           weakSelf.authenticationSuccessBlock(responseObject);
                                                           weakSelf.authenticationSuccessBlock = nil;
                                                       }
                                                   } andFailure:localFailureBlock];
                           
                       } andFailure:localFailureBlock];
                
            } else {
                localFailureBlock(nil);
            }
            handled = YES;
        } else if ([method isEqualToString:@"pinit"]) {
            if (parameters[@"error"]) {
                [PDKPin callUnauthFailureWithError:parameters[@"error"]];
            } else {
                [PDKPin callUnauthSuccess];
            }
            handled = YES;
        }
    }
    return handled;
}

#pragma mark - Endpoints

- (void)getPath:(NSString *)path
     parameters:(NSDictionary *)parameters
    withSuccess:(PDKClientSuccess)successBlock
     andFailure:(PDKClientFailure)failureBlock;
{
    NSMutableURLRequest *request = [[self requestWithMethod:@"GET" path:path parameters:parameters] mutableCopy];
    
    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request
                                                                      success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                                                          if (successBlock && [responseObject isKindOfClass:[NSDictionary class]]) {
                                                                              PDKResponseObject *response = [[PDKResponseObject alloc] initWithDictionary:(NSDictionary *)responseObject response:[operation response] path:path parameters:parameters];
                                                                              successBlock(response);
                                                                          }
                                                                      } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                                          if (failureBlock) {
                                                                              failureBlock(error);
                                                                          }
                                                                      }];
    [self.operationQueue addOperation:operation];
}

- (void)postPath:(NSString *)path
      parameters:(NSDictionary *)parameters
     withSuccess:(PDKClientSuccess)successBlock
      andFailure:(PDKClientFailure)failureBlock;
{
    NSURLRequest *request = [self requestWithMethod:@"POST" path:path parameters:parameters];
    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request
                                                                      success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                                                          if (successBlock && [responseObject isKindOfClass:[NSDictionary class]]) {
                                                                              PDKResponseObject *response = [[PDKResponseObject alloc] initWithDictionary:(NSDictionary *)responseObject response:operation.response];
                                                                              successBlock(response);
                                                                          }
                                                                      } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                                          if (failureBlock) {
                                                                              failureBlock(error);
                                                                          }
                                                                      }];
    [self.operationQueue addOperation:operation];
}

- (void)putPath:(NSString *)path
     parameters:(NSDictionary *)parameters
    withSuccess:(PDKClientSuccess)successBlock
     andFailure:(PDKClientFailure)failureBlock;
{
    NSURLRequest *request = [self requestWithMethod:@"PUT" path:path parameters:parameters];
    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request
                                                                      success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                                                          if (successBlock && [responseObject isKindOfClass:[NSDictionary class]]) {
                                                                              PDKResponseObject *response = [[PDKResponseObject alloc] initWithDictionary:(NSDictionary *)responseObject response:operation.response];
                                                                              successBlock(response);
                                                                          }
                                                                      } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                                          if (failureBlock) {
                                                                              failureBlock(error);
                                                                          }
                                                                      }];
    [self.operationQueue addOperation:operation];
}

- (void)deletePath:(NSString *)path
        parameters:(NSDictionary *)parameters
       withSuccess:(PDKClientSuccess)successBlock
        andFailure:(PDKClientFailure)failureBlock;
{
    NSURLRequest *request = [self requestWithMethod:@"DELETE" path:path parameters:parameters];
    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request
                                                                      success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                                                          if (successBlock && [responseObject isKindOfClass:[NSDictionary class]]) {
                                                                              PDKResponseObject *response = [[PDKResponseObject alloc] initWithDictionary:(NSDictionary *)responseObject response:operation.response];
                                                                              successBlock(response);
                                                                          }
                                                                      } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                                          if (failureBlock) {
                                                                              failureBlock(error);
                                                                          }
                                                                      }];
    [self.operationQueue addOperation:operation];
}



- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
                                      path:(NSString *)URLString
                                parameters:(NSDictionary *)parameters
{
    NSString *urlPath = URLString;
    NSMutableDictionary *signedParameters = [NSMutableDictionary dictionaryWithDictionary:parameters];
    
    if (self.oauthToken && signedParameters[@"access_token"] == nil) {
        signedParameters[@"access_token"] = self.oauthToken;
    }
    
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:method
                                                                   URLString:[[NSURL URLWithString:urlPath
                                                                                     relativeToURL:self.baseURL] absoluteString]
                                                                  parameters:signedParameters
                                                                       error:nil];
    
    [request setHTTPShouldHandleCookies:YES];
    [request setValue:@"no-cache, no-store" forHTTPHeaderField:@"Cache-Control"];
    
    return request;
}

- (NSMutableURLRequest *)multipartFormRequestWithMethod:(NSString *)method
                                                   path:(NSString *)URLString
                                             parameters:(NSDictionary *)parameters
                              constructingBodyWithBlock:( void (^)(id <AFMultipartFormData>) )block
{
    NSAssert(self.oauthToken, @"self.oauthToken cannot be nil");
    
    NSMutableDictionary *signedParameters = [NSMutableDictionary dictionaryWithDictionary:parameters];
    signedParameters[@"access_token"] = self.oauthToken;
    
    NSMutableURLRequest *request = [self.requestSerializer multipartFormRequestWithMethod:method
                                                                                URLString:[[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString]
                                                                               parameters:signedParameters
                                                                constructingBodyWithBlock:block
                                                                                    error:nil];
    
    [request setHTTPShouldHandleCookies:YES];
    return request;
}

#pragma mark - User Endpoints

- (void)getAuthorizedUserFields:(NSSet *)fields
                    withSuccess:(PDKClientSuccess)success
                     andFailure:(PDKClientFailure)failure
{
    NSDictionary *parameters = @{@"fields" : [[fields allObjects] componentsJoinedByString:@","]};
    [self getPath:@"me/" parameters:parameters withSuccess:success andFailure:failure];
}

- (void)getUser:(NSString *)username
         fields:(NSSet *)fields
    withSuccess:(PDKClientSuccess)successBlock
     andFailure:(PDKClientFailure)failureBlock;
{
    NSDictionary *parameters = @{@"fields" : [[fields allObjects] componentsJoinedByString:@","]};
    NSString *path = [NSString stringWithFormat:@"users/%@/", username];
    [self getPath:path parameters:parameters withSuccess:successBlock andFailure:failureBlock];
}

- (void)getAuthenticatedUserPinsWithFields:(NSSet *)fields
                                   success:(PDKClientSuccess)successBlock
                                andFailure:(PDKClientFailure)failureBlock
{
    NSDictionary *parameters = @{@"fields" : [[fields allObjects] componentsJoinedByString:@","]};
    [self getPath:@"me/pins/" parameters:parameters withSuccess:successBlock andFailure:failureBlock];
}

- (void)getAuthenticatedUserLikesWithFields:(NSSet *)fields
                                    success:(PDKClientSuccess)successBlock
                                 andFailure:(PDKClientFailure)failureBlock
{
    NSDictionary *parameters = @{@"fields" : [[fields allObjects] componentsJoinedByString:@","]};
    [self getPath:@"me/likes/" parameters:parameters withSuccess:successBlock andFailure:failureBlock];
}

- (void)getAuthenticatedUserBoardsWithFields:(NSSet *)fields
                                     success:(PDKClientSuccess)successBlock
                                  andFailure:(PDKClientFailure)failureBlock
{
    NSDictionary *parameters = @{@"fields" : [[fields allObjects] componentsJoinedByString:@","]};
    [self getPath:@"me/boards/" parameters:parameters withSuccess:successBlock andFailure:failureBlock];
}

- (void)getAuthorizedUserFollowersWithFields:(NSSet *)fields
                                     success:(PDKClientSuccess)successBlock
                                  andFailure:(PDKClientFailure)failureBlock
{
    NSDictionary *parameters = @{@"fields" : [[fields allObjects] componentsJoinedByString:@","]};
    [self getPath:@"me/followers/" parameters:parameters withSuccess:successBlock andFailure:failureBlock];
}

- (void)getAuthorizedUserFollowedUsersWithFields:(NSSet *)fields
                                         success:(PDKClientSuccess)successBlock
                                      andFailure:(PDKClientFailure)failureBlock
{
    NSDictionary *parameters = @{@"fields" : [[fields allObjects] componentsJoinedByString:@","]};
    [self getPath:@"me/following/users/" parameters:parameters withSuccess:successBlock andFailure:failureBlock];
}

- (void)getAuthorizedUserFollowedBoardsWithFields:(NSSet *)fields
                                          success:(PDKClientSuccess)successBlock
                                       andFailure:(PDKClientFailure)failureBlock
{
    NSDictionary *parameters = @{@"fields" : [[fields allObjects] componentsJoinedByString:@","]};
    [self getPath:@"me/following/boards/" parameters:parameters withSuccess:successBlock andFailure:failureBlock];
}

- (void)getAuthorizedUserFollowedInterestsWithSuccess:(PDKClientSuccess)successBlock
                                           andFailure:(PDKClientFailure)failureBlock
{
    [self getPath:@"me/following/interests/" parameters:nil withSuccess:successBlock andFailure:failureBlock];
}

#pragma mark - Board Endpoints

- (void)getBoardWithIdentifier:(NSString *)boardId
                        fields:(NSSet *)fields
                   withSuccess:(PDKClientSuccess)successBlock
                    andFailure:(PDKClientFailure)failureBlock
{
    NSDictionary *parameters = @{@"fields" : [[fields allObjects] componentsJoinedByString:@","]};
    NSString *path = [NSString stringWithFormat:@"boards/%@/", boardId];
    [[PDKClient sharedInstance] getPath:path parameters:parameters withSuccess:successBlock andFailure:failureBlock];
}

- (void)getBoardPins:(NSString *)boardId
              fields:(NSSet *)fields
         withSuccess:(PDKClientSuccess)successBlock
          andFailure:(PDKClientFailure)failureBlock;
{
    NSDictionary *parameters = @{@"fields" : [[fields allObjects] componentsJoinedByString:@","]};
    NSString *path = [NSString stringWithFormat:@"boards/%@/pins/", boardId];
    [self getPath:path parameters:parameters withSuccess:successBlock andFailure:failureBlock];
}

- (void)deleteBoard:(NSString *)boardId
        withSuccess:(PDKClientSuccess)successBlock
         andFailure:(PDKClientFailure)failureBlock;
{
    NSString *path = [NSString stringWithFormat:@"boards/%@/", boardId];
    [self deletePath:path parameters:nil withSuccess:successBlock andFailure:failureBlock];
}

- (void)createBoard:(NSString *)boardName
   boardDescription:(NSString *)description
        withSuccess:(PDKClientSuccess)successBlock
         andFailure:(PDKClientFailure)failureBlock;
{
    NSString *path = @"boards/";
    
    if (description == nil) {
        description = @"";
    }
    NSDictionary *parameters = @{
                                 @"name" : boardName,
                                 @"description" : description
                                 };
    
    [self postPath:path parameters:parameters withSuccess:successBlock andFailure:failureBlock];
    
}

#pragma mark - Pin Endpoints

- (void)getPinWithIdentifier:(NSString *)pinId
                      fields:(NSSet *)fields
                 withSuccess:(PDKClientSuccess)successBlock
                  andFailure:(PDKClientFailure)failureBlock
{
    NSDictionary *parameters = @{@"fields" : [[fields allObjects] componentsJoinedByString:@","]};
    NSString *path = [NSString stringWithFormat:@"pins/%@/", pinId];
    [[PDKClient sharedInstance] getPath:path parameters:parameters withSuccess:successBlock andFailure:failureBlock];
}

- (void)createPinWithImageURL:(NSURL *)imageURL
                         link:(NSURL *)link
                      onBoard:(NSString *)boardId
                  description:(NSString *)pinDescription
                  withSuccess:(PDKClientSuccess)successBlock
                   andFailure:(PDKClientFailure)failureBlock;
{
    NSAssert(pinDescription, @"pinDescription cannot be nil");
    NSAssert(boardId, @"boardId cannot be nil");
    
    NSDictionary *parameters = @{
                                 @"image_url" : imageURL,
                                 @"link" : link.absoluteString,
                                 @"board" : boardId,
                                 @"note" : pinDescription
                                 };
    
    [self createPinWithParameters:parameters withSuccess:successBlock andFailure:failureBlock];
    
}

- (void)createPinWithParameters:(NSDictionary *)parameters
                    withSuccess:(PDKClientSuccess)successBlock
                     andFailure:(PDKClientFailure)failureBlock
{
    [self postPath:@"pins/" parameters:parameters withSuccess:successBlock andFailure:failureBlock];
}

#if TARGET_OS_IPHONE
- (void)createPinWithImage:(UIImage *)image
                      link:(NSURL *)link
                   onBoard:(NSString *)boardId
               description:(NSString *)pinDescription
                  progress:(PDKPinUploadProgress)progressBlock
               withSuccess:(PDKClientSuccess)successBlock
                andFailure:(PDKClientFailure)failureBlock;
{
    // Construction Block
    void (^requestConstruction)(id <AFMultipartFormData>) = ^(id <AFMultipartFormData> formData)
    {
        NSData *imageData = UIImageJPEGRepresentation(image, 1.0f);
        [formData appendPartWithFileData:imageData
                                    name:@"image"
                                fileName:@"myphoto.jpg"
                                mimeType:@"image/jpeg"];
    };
    
    void (^requestProgress)(NSUInteger, long long, long long) = ^(NSUInteger bytesWritten,
                                                                  long long totalBytesWritten,
                                                                  long long totalBytesExpectedToWrite)
    {
        if (progressBlock) {
            float percentComplete = totalBytesWritten / (float)totalBytesExpectedToWrite;
            progressBlock(percentComplete);
        }
    };
    
    NSDictionary *parameters = @{
                                 @"link" : link,
                                 @"board" : boardId,
                                 @"note" : pinDescription
                                 };
    NSURLRequest *request = [self multipartFormRequestWithMethod:@"POST"
                                                            path:@"pins/"
                                                      parameters:parameters
                                       constructingBodyWithBlock:requestConstruction];
    
    AFHTTPRequestOperation *operation = [self HTTPRequestOperationWithRequest:request
                                                                      success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                                                          if (successBlock && [responseObject isKindOfClass:[NSDictionary class]]) {
                                                                              PDKResponseObject *response = [[PDKResponseObject alloc] initWithDictionary:(NSDictionary *)responseObject response:operation.response];
                                                                              successBlock(response);
                                                                          }
                                                                      } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                                          if (failureBlock) {
                                                                              failureBlock(error);
                                                                          }
                                                                      }];
    
    [operation setUploadProgressBlock:requestProgress];
    [self.operationQueue addOperation:operation];
    
}
#endif


@end
