#import "FacebookMediaDetailViewController.h"

@class FacebookVideo;

@interface FacebookVideoDetailViewController : FacebookMediaDetailViewController 
<UIPopoverControllerDelegate> {
    
    //MITThumbnailView *_thumbnail;
}

@property (nonatomic, retain) FacebookVideo *video;
//@property (nonatomic, retain) UIPopoverController *commentPopover;
@property (nonatomic, retain) UIWebView *webView;

- (void)loadVideosFromCache;

@end
