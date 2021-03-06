
/****************************************************************
 *
 *  Copyright 2011 The President and Fellows of Harvard College
 *  Copyright 2011 Modo Labs Inc.
 *
 *****************************************************************/

#import "KGOModule.h"

extern NSString * const FacebookStatusDidUpdateNotification;
extern NSString * const TwitterStatusDidUpdateNotification;

@class KGOHomeScreenWidget;
@class MITThumbnailView;

#define CHAT_BUBBLE_TAG 35892

@interface MicroblogModule : KGOModule {
    
    KGOHomeScreenWidget *_chatBubble;
    KGOHomeScreenWidget *_buttonWidget;
    
    UILabel *_chatBubbleTitleLabel;
    UILabel *_chatBubbleSubtitleLabel;
    MITThumbnailView *_chatBubbleThumbnail;
    
    UINavigationController *_modalFeedController;
    UIView *_scrim;
    
    NSString *_labelText;
}

- (void)hideChatBubble:(NSNotification *)aNotification;
- (void)didLogin:(NSNotification *)aNotification;

- (Class)feedViewControllerClass;
- (NSString *)feedViewControllerTitle;
- (void)hideModalFeedController:(id)sender;
- (void)willShowModalFeedController;

- (NSDate *)lastFeedUpdate;

@property(nonatomic, retain) UIImage *buttonImage;
@property(nonatomic, retain) NSString *labelText;

@property(nonatomic, readonly) KGOHomeScreenWidget *buttonWidget;

// chat bubble properties
@property(nonatomic, readonly) KGOHomeScreenWidget *chatBubble;
@property(nonatomic, readonly) UILabel *chatBubbleTitleLabel;
@property(nonatomic, readonly) UILabel *chatBubbleSubtitleLabel;
@property(nonatomic, readonly) MITThumbnailView *chatBubbleThumbnail;
@property(nonatomic) CGFloat chatBubbleCaratOffset;

@end
