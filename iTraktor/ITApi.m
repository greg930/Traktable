//
//  trakt.m
//  HandleBarApp
//
//  Created by Johan Kuijt on 30-01-13.
//  Copyright (c) 2013 Mustacherious. All rights reserved.
//

#import "ITApi.h"
#import "ITTVShow.h"
#import "ITMovie.h"
#import "ITConfig.h"
#import "EMKeychainItem.h"

#define kApiUrl @"http://api.trakt.tv"

@interface ITApi()

- (NSString *)sha1Hash:(NSString *)input;
- (NSString *)apiKey;

- (NSDictionary *)TVShow:(ITTVShow *)aTVShow batch:(NSArray *)aBatch;
- (NSDictionary *)Movie:(ITMovie *)aMovie batch:(NSArray *)aBatch;

- (void)callAPI:(NSString*)apiCall WithParameters:(NSDictionary *)params;
- (NSDictionary *)callURLSync:(NSString *)requestUrl withParameters:(NSDictionary *)params;
- (void)callURL:(NSString *)requestUrl withParameters:(NSDictionary *)params completionHandler:(void (^)(NSDictionary *, NSError *))completionBlock;

@end


@implementation ITApi

- (NSString *)sha1Hash:(NSString *)input   {
    
    const char *cstr = [input cStringUsingEncoding:NSUTF8StringEncoding];
    NSData *data = [NSData dataWithBytes:cstr length:input.length];
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    
    // This is an iOS5-specific method.
    // It takes in the data, how much data, and then output format, which in this case is an int array.
    CC_SHA1(data.bytes, (int) data.length, digest);
    
    NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    
    // Parse through the CC_SHA1 results (stored inside of digest[]).
    for(int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", digest[i]];
    }    
    
    return output;
}

- (NSString *)apiKey {
    
    NSDictionary *config = [ITConfig getConfigFile];
    
    return [config objectForKey:@"traktApiKey"];
}

- (NSString *)username {
    
    NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:@"username"];
    if (!username) {
        username = nil;
    }
    
    return username;
}

- (NSString *)password {
    
    EMGenericKeychainItem *keychain = [EMGenericKeychainItem genericKeychainItemForService:@"com.mustacherious.iTraktor" withUsername:self.username];
    
    if (!keychain) {
        return nil;
    }
    
    return [self sha1Hash:keychain.password];
}

- (void)setPassword:(NSString *)password {
    
    [EMGenericKeychainItem setKeychainPassword:password forUsername:self.username service:@"com.mustacherious.iTraktor"];
}

- (NSDictionary *)TVShow:(ITTVShow *)aTVShow batch:(NSArray *)aBatch {
    
    NSDictionary *params;
    
    if (aTVShow && aBatch == nil) {
        
        params = [NSDictionary dictionaryWithObjectsAndKeys:
                  self.username, @"username",
                  self.password, @"password",
                  aTVShow.show, @"title",
                  [NSNumber numberWithInteger:aTVShow.year], @"year",
                  [NSNumber numberWithInteger:aTVShow.seasonNumber], @"season",
                  [NSNumber numberWithInteger:aTVShow.episodeNumber], @"episode",
                  [NSNumber numberWithInteger:aTVShow.duration], @"duration",
                  [NSNumber numberWithInteger:50], @"progress",
                  @"1.0", @"plugin_version",
                  @"1.0", @"media_center_version",
                  @"31.12.2011", @"media_center_date",
                  nil];
        
    } else if(aTVShow != nil && aBatch != nil){
        
        params = [NSDictionary dictionaryWithObjectsAndKeys:
                  self.username, @"username",
                  self.password, @"password",
                  aTVShow.show, @"title",
                  [NSNumber numberWithInteger:aTVShow.year], @"year",
                  aBatch, @"episodes",
                  nil];
    } else {
        
        params = [NSDictionary dictionaryWithObjectsAndKeys:
                  self.username, @"username",
                  self.password, @"password",
                  nil];
        
    }

    
    return params;
}

- (NSDictionary *)Movie:(ITMovie *)aMovie batch:(NSArray *)aBatch {
    
    NSDictionary *params;
    NSString *appVersion = [NSString stringWithFormat:@"Version %@",[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
    
    if (aMovie && aBatch == nil) {
        
        params = [NSDictionary dictionaryWithObjectsAndKeys:
                  self.username, @"username",
                  self.password, @"password",
                  aMovie.name, @"title",
                  aMovie.imdbId, @"imdb_id",
                  [NSNumber numberWithInteger:aMovie.year], @"year",
                  [NSNumber numberWithInteger:aMovie.duration], @"duration",
                  [NSNumber numberWithInteger:50], @"progress",
                  appVersion, @"plugin_version",
                  @"1.0", @"media_center_version",
                  @"31.12.2011", @"media_center_date",
                  nil];
    } else if(aMovie == nil && aBatch != nil){
        
        params = [NSDictionary dictionaryWithObjectsAndKeys:
                  self.username, @"username",
                  self.password, @"password",
                  aBatch, @"movies",
                  nil];
    } else {
        
        params = [NSDictionary dictionaryWithObjectsAndKeys:
                  self.username, @"username",
                  self.password, @"password",
                  nil];

    }
    
    return params;
}

- (NSDictionary *)callURLSync:(NSString *)requestUrl withParameters:(NSDictionary *)params {

    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:requestUrl]];
    [request setHTTPMethod: @"POST"];
    [request setHTTPBody: [NSJSONSerialization dataWithJSONObject:params options:NSJSONWritingPrettyPrinted error:nil]];
    
    NSURLResponse *response = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:nil];
    
    NSError *errorJSON;
    NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&errorJSON];
    
    return responseDict;
}

- (void)callURL:(NSString *)requestUrl withParameters:(NSDictionary *)params completionHandler:(void (^)(NSDictionary *, NSError *))completionBlock
{

    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:requestUrl]];
    [request setHTTPMethod: @"POST"];
    [request setHTTPBody: [NSJSONSerialization dataWithJSONObject:params options:NSJSONWritingPrettyPrinted error:nil]];
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue setName:@"com.mustacherious.iTraktor"];
    
    [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        
        if (error) {
            
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                completionBlock(nil, error);
            });
            return;
        }
        
        NSError *errorJSON;
        NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&errorJSON];
        
        if (errorJSON) {
            dispatch_async(dispatch_get_main_queue(), ^(void) { });
            return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            completionBlock(responseDict, nil);
        });
    }];
}


- (void)callAPI:(NSString*)apiCall WithParameters:(NSDictionary *)params {
    
    [self callURL:apiCall withParameters:params completionHandler:^(NSDictionary *dict, NSError *err) {
        if ([[dict objectForKey:@"status"] isEqualToString:@"success"]){
            NSLog(@"Succes: %@",[dict objectForKey:@"message"]);
        }
        if (err) NSLog(@"Error: %@",[err description]);
    }];
}

- (BOOL)testAccount {
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setValue:[self username] forKey:@"username"];
    [params setValue:[self password] forKey:@"password"];
    
    NSString *url = [NSString stringWithFormat:@"%@/account/test/%@", kApiUrl, [self apiKey]];
    NSDictionary *data = [self callURLSync:url withParameters:params];
    
    if([[data objectForKey:@"status"] isEqualToString:@"failure"])
        return NO;
    else
        return YES;
}

- (void)updateState:(id)aVideo state:(NSString *)aState {
    
    NSLog(@"%@ --> %@", [aState stringByReplacingCharactersInRange:NSMakeRange(0,1) withString:[[aState substringToIndex:1] uppercaseString]], aVideo);
    NSDictionary *params;
    NSString *type;
    
    if([aVideo isKindOfClass:[ITTVShow class]]) {
        params = [self TVShow:(ITTVShow *)aVideo batch:nil];
        type = @"show";
    } else if ([aVideo isKindOfClass:[ITMovie class]]) {
        params = [self Movie:(ITMovie *)aVideo batch:nil];
        type = @"movie";
    }

    NSString *url = [NSString stringWithFormat:@"%@/%@/%@/%@", kApiUrl, type, aState, [self apiKey]];
    [self callAPI:url WithParameters:params];
}

- (void)seen:(NSArray *)videos type:(iTunesEVdK)videoType video:(id)aVideo {
    
    NSDictionary *params;
    NSString *type;
    
    if(videoType == iTunesEVdKTVShow) {
        
        params = [self TVShow:aVideo batch:videos];
        type = @"show/episode";
        
    } else if(videoType == iTunesEVdKMovie) {

        params = [self Movie:nil batch:videos];
        type = @"movie";
    }

    NSString *url = [NSString stringWithFormat:@"%@/%@/seen/%@", kApiUrl, type, [self apiKey]];

    [self callAPI:url WithParameters:params];
}

@end