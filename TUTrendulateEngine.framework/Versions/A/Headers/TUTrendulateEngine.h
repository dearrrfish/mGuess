//
//  TUTrendulateEngine.h
//  TUTrendulateEngine
//
//  Created by Rex Ren on 1/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol TUTrendulateEngineDelegate <NSObject>

- (void)requestSucceed:(NSString *)connectionIdentifier;
- (void)requestFailed:(NSString *)connectionIdentifier withError:(NSError *)error;

@optional
- (void)responseReceived:(NSDictionary *)response forRequest:(NSString *)connectionIdentifier;
@end


@interface TUTrendulateEngine : NSObject {
    id <TUTrendulateEngineDelegate> _delegate;
    NSString *_APIDomain;
    NSMutableDictionary *_connections;
    
    NSString *_username;
    NSString *_password;
    
    BOOL finished;
}

+ (id)TrendulateEngineWithUsername:(NSString *)username password:(NSString *)password delegate:(id <TUTrendulateEngineDelegate>)delegate;
+ (id)TrendulateEngineWithDelegate:(id <TUTrendulateEngineDelegate>)delegate;
- (id)initWithDelegate:(id <TUTrendulateEngineDelegate>)delegate;

+ (NSString *)version;
+ (NSString *)APIDomain;
+ (NSString *)getURLSafetyRepresentation:(NSString *)string;

// API Method
- (NSString *)getMyProfile;
- (NSString *)updateMyProfileWithFullname:(NSString *)fullname 
                                   gender:(NSString *)gender 
                                 location:(NSString *)location 
                                      url:(NSString *)url 
                                biography:(NSString *)biography 
                                    email:(NSString *)email 
                          currentPassword:(NSString *)currentPassword 
                              newPassword:(NSString *)newPassword;

- (NSString *)getFollowingTrendList;
- (NSString *)getFollowingDetailTrendList;
- (NSString *)getPropertiesForTrend:(NSString *)name;
- (NSString *)createTrendWithName:(NSString *)name 
                           schemas:(NSArray *)schemas 
                          privacy:(NSString *)privacy 
                      description:(NSString *)description 
                             node:(NSString *)note;
- (NSString *)deleteTrend:(NSString *)name;
- (NSString *)getTrendPointsForTrend:(NSString *)name;
- (NSString *)createTrendPointForTrend:(NSString *)name data:(NSDictionary *)data note:(NSString *)note withDate:(NSDate *)date;
- (NSString *)createTrendPointForTrend:(NSString *)name data:(NSDictionary *)data note:(NSString *)note;

@end

@interface TUTrendulateEngine (BasicAuth)

- (NSString *)username;
- (void)setUsername:(NSString *)newUsername;

- (NSString *)password;
- (void)setPassword:(NSString *)password;

@end
