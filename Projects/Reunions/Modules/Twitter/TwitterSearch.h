
/****************************************************************
 *
 *  Copyright 2011 The President and Fellows of Harvard College
 *  Copyright 2011 Modo Labs Inc.
 *
 *****************************************************************/

// this is a temporary file that just searches a hash tag
// may evolve into a more complete twitter api controller

#import <Foundation/Foundation.h>
#import "ConnectionWrapper.h"

@class TwitterSearch;

@protocol TwitterSearchDelegate <NSObject>

- (void)twitterSearch:(TwitterSearch *)twitterSearch didReceiveSearchResults:(NSArray *)results;
- (void)twitterSearch:(TwitterSearch *)twitterSearch didFailWithError:(NSError *)error;

@end


@interface TwitterSearch : NSObject <ConnectionWrapperDelegate> {

    ConnectionWrapper *_connection;
    
}

@property(nonatomic, assign) id <TwitterSearchDelegate> delegate;

- (id)initWithDelegate:(id<TwitterSearchDelegate>)aDelegate;
- (void)searchTwitterHashtag:(NSString *)hashtag;

@end
