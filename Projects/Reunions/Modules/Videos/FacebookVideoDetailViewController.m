
/****************************************************************
 *
 *  Copyright 2011 The President and Fellows of Harvard College
 *  Copyright 2011 Modo Labs Inc.
 *
 *****************************************************************/

#import "FacebookVideoDetailViewController.h"
#import "FacebookModel.h"
#import "UIKit+KGOAdditions.h"
#import "CoreDataManager.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "FacebookModule.h"

static const NSInteger kLoadingCurtainViewTag = 0x937;

#pragma mark Private methods

@interface FacebookVideoDetailViewController (Private)

- (void)fadeOutLoadingCurtainView;

@end

@implementation FacebookVideoDetailViewController (Private)

- (void)fadeOutLoadingCurtainView {
    UIView *loadingCurtainView = [[self.mediaView previewView] viewWithTag:kLoadingCurtainViewTag];
    loadingCurtainView.tag = 0; // prevent us from trying to fade this out twice
    
    if (loadingCurtainView) {
        [UIView 
         animateWithDuration:0.4f 
         delay:0.1f
         options:UIViewAnimationOptionTransitionNone
         animations:
         ^{
             loadingCurtainView.alpha = 0.0f;
         }
         completion:nil];
    }    
}

@end


@implementation FacebookVideoDetailViewController

@synthesize video;
@synthesize webView;
//@synthesize curtainView;
@synthesize loadingCurtainImage;
@synthesize player;

/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
*/

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    self.webView.delegate = nil;
    self.player = nil;
    [loadingCurtainImage release];
    [webView release];
    [video release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (NSString *)youtubeId:(NSString *)source {
    // sample URL
    // http://www.youtube.com/v/d9av8-lhJS8&fs=1?autoplay
    NSArray *parts = [self.video.src componentsSeparatedByString:@"/"]; 
    NSArray *components = [[parts lastObject] componentsSeparatedByString:@"&"];
    return [components objectAtIndex:0];
}

- (NSString *)vimeoId:(NSString *)source {
    // sample URL
    // http://vimeo.com/moogaloop.swf?clip_id=8327538&autoplay=1
    NSArray *parts1 = [self.video.src componentsSeparatedByString:@"="]; 
    NSArray *parts2 = [[parts1 objectAtIndex:1] componentsSeparatedByString:@"&"];
    return  [parts2 objectAtIndex:0];
}

- (void)loadVideo
{
    if (self.player) {
        [self.player prepareToPlay];
        
    } else if (self.webView) {
        // For some reason [self.webView reload] does not reliably work here
        NSString *urlString;
        
        NSString *videoSourceName = [self.video videoSourceName];
        if ([videoSourceName isEqualToString:@"YouTube"]) {
            urlString =  [NSString stringWithFormat:@"http://www.youtube.com/embed/%@", [self youtubeId:self.video.src]];
        } else if ([videoSourceName isEqualToString:@"Vimeo"]) {
            urlString = [NSString stringWithFormat:@"http://player.vimeo.com/video/%@", [self vimeoId:self.video.src]];
        } else {
            urlString = self.video.src;
        }
        [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlString]]];
    }
}

- (void)displayPost {
    NSURL *url = [NSURL URLWithString:self.video.src];
 
    if (url != nil && [[url host] rangeOfString:@"fbcdn"].location != NSNotFound) {
        self.player = 
        [[[MPMoviePlayerController alloc] initWithContentURL:url] autorelease];
        player.shouldAutoplay = NO;
        [self.mediaView setPreviewView:player.view];
        [self.mediaView setPreviewSize:CGSizeMake(10, 10)];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerLoadStateDidChange:) name:MPMoviePlayerLoadStateDidChangeNotification object:nil];
    } else {
        CGSize aspectRatio = CGSizeMake(16, 9); // default aspect ratio 
        if ([[self.video videoSourceName] isEqualToString:@"YouTube"]) {
            aspectRatio = CGSizeMake(10, 10);
        }
        
        self.webView = [[[UIWebView alloc] init] autorelease];
        self.webView.allowsInlineMediaPlayback = YES;
        self.webView.delegate = self;
        // prevent webView from scrolling separately from the parent scrollview
        for (id subview in webView.subviews) {
            if ([[subview class] isSubclassOfClass: [UIScrollView class]]) {
                ((UIScrollView *)subview).bounces = NO;
            }
        }
        [self.mediaView setPreviewView:self.webView];
        [self.mediaView setPreviewSize:aspectRatio];
    }
    [self loadVideo];
    
    if (!self.video.comments.count) {
        [self getCommentsForPost];
    }
}

- (void)setVideo:(FacebookVideo *)aVideo {
    self.post = aVideo;
}

- (FacebookVideo *)video {
    return (FacebookVideo *)self.post;
}

/*
- (void)playVideo:(id)sender {
    NSURL *url = [NSURL URLWithString:self.video.link];
    
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url];
    }
}
*/
 
#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Video";
    
    // this code overlays a play button on the video
    // for now we will try to use the built in play buttons
    // but we may need this code in the future
    /*
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setImage:[UIImage imageWithPathName:@"common/arrow-white-right"] forState:UIControlStateNormal];
    button.frame = CGRectMake(120, 80, 80, 60);
    [button addTarget:self action:@selector(playVideo:) forControlEvents:UIControlEventTouchUpInside];
    [self.mediaView addSubview:button];    
    */     
    
    // Show curtain image in view over the web view until the web view finishes 
    // loading.
    if (self.loadingCurtainImage) {
        UIView *previewView = [self.mediaView previewView];
        CGRect loadingCurtainFrame = previewView.frame;
        loadingCurtainFrame.origin = CGPointZero;
        UIImageView *loadingCurtainView = 
        [[UIImageView alloc] initWithFrame:loadingCurtainFrame];
        loadingCurtainView.image = self.loadingCurtainImage;
        loadingCurtainView.tag = kLoadingCurtainViewTag;
        loadingCurtainView.backgroundColor = [UIColor blackColor];
        loadingCurtainView.autoresizingMask = 
        [self.mediaView previewView].autoresizingMask;
        [[self.mediaView previewView] addSubview:loadingCurtainView];
        [loadingCurtainView release];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]]];
    [self.player stop];
}

- (void)viewDidUnload
{
    self.loadingCurtainImage = nil;
    
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (NSString *)postTitle {
    return self.video.name;
}

#pragma mark FacebookMediaDetailViewController

- (IBAction)closeButtonPressed:(id)sender {    
    [KGO_SHARED_APP_DELEGATE() showPage:LocalPathPageNameHome 
                           forModuleTag:VideoModuleTag params:nil];    
}

#pragma mark FacebookMediaDetailViewController
- (NSString *)identifierForBookmark {
    return self.video.identifier;
}

- (NSString *)mediaTypeForBookmark {
    return @"video";
}

- (NSString *)mediaTypeHumanReadableName{
    return @"video";
}

- (NSString *)closeButtonName {
    return @"Videos";
}

- (BOOL)hideToolbarsInLandscape {
    return NO;
}

#pragma mark - FacebookCommentDelegate

- (void)didPostComment
{
    [self loadVideo];
}

- (void)didCancelComment
{
    [self loadVideo];
}

#pragma mark UIWebViewDelegate
- (void)webViewDidFinishLoad:(UIWebView *)theWebView {
    [self fadeOutLoadingCurtainView];
}

- (void)webView:(UIWebView *)theWebView didFailLoadWithError:(NSError *)error {
    [self fadeOutLoadingCurtainView];    
}

#pragma mark player state change notification 
//(used for facebook videos which play directly in MPMoviePlayer)

- (void)playerLoadStateDidChange:(id)notification {
    if(player.loadState | MPMovieLoadStatePlayable) {
        [self fadeOutLoadingCurtainView];
    }
}


@end
