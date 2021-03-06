//
//  SocializeAuthenticateService.m
//  SocializeSDK
//
//  Created by Fawad Haider on 6/13/11.
//  Copyright 2011 Socialize, Inc. All rights reserved.
//

#import "SocializeAuthenticateService.h"
#import "SocializeRequest.h"
#import "SocializeProvider.h"
#import "OAMutableURLRequest.h"
#import "OADataFetcher.h"
#import "OAAsynchronousDataFetcher.h"
#import <UIKit/UIKit.h>
#import "JSONKit.h"

@interface SocializeAuthenticateService()
-(NSString*)getSocializeId;
-(NSString*)getSocializeToken;
-(void)persistUserInfo:(NSDictionary*)dictionary;
-(void)persistConsumerInfo:(NSString*)apiKey andApiSecret:(NSString*)apiSecret;
@end

@implementation SocializeAuthenticateService

@synthesize provider = _provider;
@synthesize delegate = _delegate;

-(id) initWithProvider:(SocializeProvider*) provider delegate:(id<SocializeAuthenticationDelegate>)delegate
{
    self = [super init];
    if(self != nil)
    {
        _provider = provider;
        _delegate = delegate;
    }
    return self;
}

-(void)dealloc{
    _provider = nil;
    [super dealloc];
}

#define AUTHENTICATE_METHOD @"authenticate/"

-(void)authenticateWithApiKey:(NSString*)apiKey 
          apiSecret:(NSString*)apiSecret
         {
             
    NSString* payloadJson = [NSString stringWithFormat:@"{\"udid\":\"%@\"}", [UIDevice currentDevice].uniqueIdentifier];
    NSMutableDictionary* paramsDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                payloadJson, @"jsonData",
                                                nil];
    [self persistConsumerInfo:apiKey andApiSecret:apiSecret];
    [_provider secureRequestWithMethodName:AUTHENTICATE_METHOD andParams:paramsDict expectedJSONFormat:SocializeDictionary andHttpMethod:@"POST" andDelegate:self];
}

+(BOOL)isAuthenticated {
    OAToken *authToken = [[[OAToken alloc ]initWithUserDefaultsUsingServiceProviderName:kPROVIDER_NAME prefix:kPROVIDER_PREFIX] autorelease];
    if (authToken.key)
        return YES;
    else
        return NO;
}

-(void)persistConsumerInfo:(NSString*)apiKey andApiSecret:(NSString*)apiSecret{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if (userDefaults){
        [userDefaults setObject:apiKey forKey:kSOCIALIZE_API_KEY_KEY];
        [userDefaults setObject:apiSecret forKey:kSOCIALIZE_API_SECRET_KEY];
        [userDefaults synchronize];
    }
}

-(void)persistUserInfo:(NSDictionary*)dictionary{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if (userDefaults){
        NSString* userId = [dictionary objectForKey:@"id"]; 
        if ((userId != nil) && ((id)userId != [NSNull null]))
            [userDefaults setObject:userId forKey:kSOCIALIZE_USERID_KEY];
        
        NSString* username = [dictionary objectForKey:@"username"]; 
        if ((username != nil) && ((id)username != [NSNull null]))
            [userDefaults setObject:username forKey:kSOCIALIZE_USERNAME_KEY];

        NSString* smallImageUri = [dictionary objectForKey:@"small_image_uri"]; 
        
        if ((smallImageUri != nil) && ((id)smallImageUri != [NSNull null]))
            [userDefaults setObject:smallImageUri forKey:kSOCIALIZE_USERIMAGEURI_KEY];
        
        [userDefaults synchronize];
    }
}

-(NSString*)getSocializeId{
    NSUserDefaults* userPreferences = [NSUserDefaults standardUserDefaults];
    NSString* userJSONObject = [userPreferences valueForKey:kSOCIALIZE_USERID_KEY];
    if (!userJSONObject)
        return @"";
    return userJSONObject;
}

-(NSString*)getSocializeToken{
    OAToken *authToken = [[[OAToken alloc ]initWithUserDefaultsUsingServiceProviderName:kPROVIDER_NAME prefix:kPROVIDER_PREFIX] autorelease];
    if (authToken.key)
        return authToken.key;
    else 
        return nil;
}

-(void)authenticateWithApiKey:(NSString*)apiKey
                            apiSecret:(NSString*)apiSecret 
                  thirdPartyAuthToken:(NSString*)thirdPartyAuthToken
                     thirdPartyUserId:(NSString*)thirdPartyUserId
                       thirdPartyName:(ThirdPartyAuthName)thirdPartyName
{
    NSMutableDictionary* params = [NSMutableDictionary dictionaryWithObjectsAndKeys: 
                             [UIDevice currentDevice].uniqueIdentifier,@"udid", 
                             [self getSocializeId],  @"socialize_id", 
                             @"1"/* auth type is for facebook*/ , @"auth_type", //TODO:: should be changed
                             thirdPartyAuthToken, @"auth_token",
                             thirdPartyUserId, @"auth_id" , nil] ;                        
                               
   [self persistConsumerInfo:apiKey andApiSecret:apiSecret];
   [_provider secureRequestWithMethodName:AUTHENTICATE_METHOD andParams:params expectedJSONFormat:SocializeDictionary andHttpMethod:@"POST" andDelegate:self];
}


/**
 * Called when an error prevents the request from completing successfully.
 */
- (void)request:(SocializeRequest *)request didFailWithError:(NSError *)error{
   [_delegate didNotAuthenticate:error];
}

/**
 * Called when a request returns and its response has been parsed into
 * an object.
 *
 * The resulting object may be a dictionary, an array, a string, or a number,
 * depending on the format of the API response.
 */

- (void)request:(SocializeRequest *)request didLoadRawResponse:(NSData *)data{

    NSString *responseBody = [[NSString alloc] initWithData:data
                                                   encoding:NSUTF8StringEncoding];
    
    
    JSONDecoder *jsonKitDecoder = [JSONDecoder decoder];
    id jsonObject = [jsonKitDecoder objectWithData:data];
    
    if ([jsonObject isKindOfClass:[NSDictionary class]]){
        
        NSString* token_secret = [jsonObject objectForKey:@"oauth_token_secret"];
        NSString* token = [jsonObject objectForKey:@"oauth_token"];
        
        if (token_secret && token){
            OAToken *requestToken = [[OAToken alloc] initWithKey:token secret:token_secret];
            [requestToken storeInUserDefaultsWithServiceProviderName:kPROVIDER_NAME prefix:kPROVIDER_PREFIX];
            [requestToken release]; requestToken = nil;
            [_delegate didAuthenticate];
        }
        else
            [_delegate didNotAuthenticate:[NSError errorWithDomain:@"Socialize" code: 600 userInfo:nil]];
            
        [self persistUserInfo:[jsonObject objectForKey:@"user"]];
    }
    
    [responseBody release];
}

-(void)removeAuthenticationInfo
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString* key = [NSString stringWithFormat:@"OAUTH_%@_%@_KEY", kPROVIDER_PREFIX, kPROVIDER_NAME];
    NSString* secret = [NSString stringWithFormat:@"OAUTH_%@_%@_SECRET", kPROVIDER_PREFIX, kPROVIDER_NAME];
    
    if ([defaults objectForKey:key] && [defaults objectForKey:secret]) 
    {
        [defaults removeObjectForKey:key];
        [defaults removeObjectForKey:secret];
    }
    
    [defaults synchronize];
}

@end