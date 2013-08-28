//
//  TUTrendulateHTTPURLConnection.h
//  TUTrendulateEngine
//
//  Created by Rex Ren on 1/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface TUTrendulateHTTPURLConnection : NSURLConnection {
    NSMutableData *_data;
    NSURL *_URL;
    NSString *_identifier;
    
    NSHTTPURLResponse *_response;
}

@property (nonatomic, retain) NSHTTPURLResponse *response;

- (id)initWithRequest:(NSURLRequest *)request delegate:(id)delegate;

// Data helper methods
- (void)resetDataLength;
- (void)appendData:(NSData *)data;

// Accessors
- (NSString *)identifier;
- (NSData *)data;
- (NSURL *)URL;



@end
