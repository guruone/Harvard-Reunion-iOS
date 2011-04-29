#import "CoreDataManager.h"
#import "FacebookMediaDetailViewController.h"
#import "UIKit+KGOAdditions.h"
#import "Foundation+KGOAdditions.h"
#import "KGOSocialMediaController.h"
#import "KGOSocialMediaController+FacebookAPI.h"
#import "KGOAppDelegate.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "FacebookModel.h"
#import <QuartzCore/QuartzCore.h>
#import "FacebookModule.h"

typedef enum {
    kToolbarLikeButtonTag = 0x419,
    kToolbarCommentButtonTag,
    kToolbarBookmarkButtonTag
}
ToolbarButtonTags;

#pragma mark Private methods

@interface FacebookMediaDetailViewController (Private)

- (UIButton *)buttonForTag:(NSInteger)tag;

- (void)updateLikeButtonStatus;

- (void)restoreToolbars:(id)sender;
- (void)restorePortraitOrientation;
- (void)restorePortraitLayout;

@end

@implementation FacebookMediaDetailViewController 

- (UIButton *)buttonForTag:(NSInteger)tag {
    
    UIView *buttonParent = self.view;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        buttonParent = self.actionsToolbar;
    }
    return (UIButton *)[buttonParent viewWithTag:tag];
}

- (void)updateLikeButtonStatus {
    
    KGOFacebookService *fbService = [[KGOSocialMediaController sharedController] serviceWithType:KGOSocialMediaTypeFacebook];
    if([self.post.likes member:[fbService currentFacebookUser]]) {
        UIButton *likeButton = [self buttonForTag:kToolbarLikeButtonTag];
        likeButton.selected = YES;
    }
}

@synthesize post, posts, tableView = _tableView;
@synthesize mediaView = _mediaView;
@synthesize moduleTag;
@synthesize actionsToolbar;
@synthesize tapRecoginizer = _tapRecognizer;

/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
*/

- (void)dealloc
{
    [actionsToolbar release];
    [_comments release];
    self.moduleTag = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.tapRecoginizer = nil;
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark -

- (void)setupToolbarButtons {
    NSAutoreleasePool *setupPool = [[NSAutoreleasePool alloc] init];
    
    // Set up the buttons that go in the toolbar items.
    UIButton *likeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    likeButton.tag = kToolbarLikeButtonTag;
    [likeButton 
     setImage:[UIImage imageWithPathName:@"modules/facebook/button-icon-like"] 
     forState:UIControlStateNormal];
    [likeButton 
     setImage:[UIImage imageWithPathName:@"modules/facebook/button-icon-unlike"] 
     forState:UIControlStateSelected];
    [likeButton 
     addTarget:self action:@selector(likeButtonPressed:) 
     forControlEvents:UIControlEventTouchUpInside];

    UIButton *commentButton = [UIButton buttonWithType:UIButtonTypeCustom];
    commentButton.tag = kToolbarCommentButtonTag;
    [commentButton 
     setImage:[UIImage imageWithPathName:@"modules/facebook/button-icon-comment"] 
     forState:UIControlStateNormal];
    [commentButton  
     addTarget:self action:@selector(commentButtonPressed:) 
     forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *bookmarkButton = [UIButton buttonWithType:UIButtonTypeCustom];
    bookmarkButton.tag = kToolbarBookmarkButtonTag;
    [bookmarkButton 
     setImage:
     [UIImage imageWithPathName:@"common/button-icon-favorites-star"] 
     forState:UIControlStateNormal];
    [bookmarkButton 
     setImage:
     [UIImage imageWithPathName:@"common/button-bookmark-on"] 
     forState:UIControlStateSelected];
    [bookmarkButton 
     addTarget:self action:@selector(bookmarkButtonPressed:) 
     forControlEvents:UIControlEventTouchUpInside];
    // Set up initial state of bookmark button.
    bookmarkButton.selected = 
    [FacebookModule isMediaObjectWithIDBookmarked:[self identifierForBookmark]
                                        mediaType:[self mediaTypeForBookmark]];
    
    // Add state-specific images for the buttons.
    UIImage *normalImage = 
    [UIImage imageWithPathName:@"common/secondary-toolbar-button"];
    UIImage *pressedImage = 
    [UIImage imageWithPathName:@"common/secondary-toolbar-button-pressed"];
    CGRect frame = CGRectZero;
    if (normalImage) {
        frame.size = normalImage.size;
    } else {
        frame.size = CGSizeMake(42, 31);
    }
    
    NSArray *buttons = 
    [NSArray arrayWithObjects:likeButton, commentButton, bookmarkButton, nil];
    for (UIButton *aButton in buttons) {
        aButton.frame = frame;
        [aButton setBackgroundImage:normalImage 
                           forState:UIControlStateNormal];
        [aButton setBackgroundImage:pressedImage 
                           forState:UIControlStateHighlighted];
    }
    
    // Set up the toolbar items.
	UIBarButtonItem *spacer = 
    [[[UIBarButtonItem alloc] 
      initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace 
      target:nil 
      action:nil] 
     autorelease];
    
    self.actionsToolbar.items = 
    [NSArray arrayWithObjects:
     [[[UIBarButtonItem alloc] initWithCustomView:likeButton] autorelease], 
     spacer,
     [[[UIBarButtonItem alloc] initWithCustomView:commentButton] autorelease], 
     spacer,
     [[[UIBarButtonItem alloc] initWithCustomView:bookmarkButton] autorelease], 
     nil];
    
    // this has to be called after button attached to 
    // to view heirarchy
    [self updateLikeButtonStatus];
    [setupPool release];
}

- (IBAction)commentButtonPressed:(UIBarButtonItem *)sender {
    [self restoreToolbars:nil];
    [self restorePortraitOrientation];
    
    FacebookCommentViewController *vc = [[[FacebookCommentViewController alloc] initWithNibName:@"FacebookCommentViewController"
                                                                                         bundle:nil] autorelease];
    vc.delegate = self;
    vc.post = self.post;
    
    UINavigationController *navC = [[[UINavigationController alloc] initWithRootViewController:vc] autorelease];
    navC.navigationBar.barStyle = UIBarStyleBlack;
    navC.modalPresentationStyle = UIModalPresentationFormSheet;
    
    [self presentModalViewController:navC animated:YES];
}

- (IBAction)likeButtonPressed:(UIBarButtonItem *)sender {
    [self restoreToolbars:nil];

    UIButton *button = [self buttonForTag:kToolbarLikeButtonTag];
    
    if (button.state & UIControlStateSelected) {
        [[KGOSocialMediaController facebookService] 
         unlikeFacebookPost:self.post receiver:self 
         callback:@selector(didUnlikePost:)];
    }
    else {
        [[KGOSocialMediaController facebookService] 
         likeFacebookPost:self.post receiver:self 
         callback:@selector(didLikePost:)];
    }
}

- (void)didLikePost:(id)result {
    DLog(@"%@", [result description]);
    if ([result isKindOfClass:[NSDictionary class]] && 
        [[result stringForKey:@"result" nilIfEmpty:YES] isEqualToString:@"true"]) {
        
        KGOFacebookService *fbService = [[KGOSocialMediaController sharedController] serviceWithType:KGOSocialMediaTypeFacebook];
        [self.post addLikesObject:[fbService currentFacebookUser]];
        
        // Set the button to the "unlike" state.
        UIButton *button = [self buttonForTag:kToolbarLikeButtonTag];
        button.selected = YES;
    }
}

- (void)didUnlikePost:(id)result {
    NSLog(@"%@", [result description]);
    if ([result isKindOfClass:[NSDictionary class]] && [[result stringForKey:@"result" nilIfEmpty:YES] isEqualToString:@"true"]) {

        KGOFacebookService *fbService = [[KGOSocialMediaController sharedController] serviceWithType:KGOSocialMediaTypeFacebook];
        [self.post removeLikesObject:[fbService currentFacebookUser]];
         
        // Set the button to the "like" state.
        UIButton *button = [self buttonForTag:kToolbarLikeButtonTag];
        button.selected = NO;
    }
}

- (NSString *)identifierForBookmark {
    // Override if implementing bookmarking.
    return nil;
}

- (NSString *)mediaTypeForBookmark {
    // Override if implementing bookmarking.
    return nil;
}

- (IBAction)bookmarkButtonPressed:(UIBarButtonItem *)sender {
    [self restoreToolbars:nil];
    
    BOOL bookmarked = 
    [FacebookModule 
     toggleBookmarkForMediaObjectWithID:[self identifierForBookmark] 
     mediaType:[self mediaTypeForBookmark]];
    // Update toolbar button to reflect bookmarked state.
    UIButton *button = [self buttonForTag:kToolbarBookmarkButtonTag];
    // When the button is in the selected state, it shows an image indicating 
    // that the current media object is bookmarked.
    button.selected = bookmarked;
}

- (IBAction)closeButtonPressed:(id)sender {
    [KGO_SHARED_APP_DELEGATE() showPage:LocalPathPageNameHome forModuleTag:moduleTag params:nil];
}

- (IBAction)uploadButtonPressed:(id)sender {
}

- (void)getCommentsForPost {
    NSString *objectID = self.post.postIdentifier.length ? self.post.postIdentifier : self.post.identifier;
    NSString *path = [NSString stringWithFormat:@"%@/comments", objectID];
    [[KGOSocialMediaController facebookService] requestFacebookGraphPath:path
                                                                receiver:self
                                                                callback:@selector(didReceiveComments:)];
}

- (void)didReceiveComments:(id)result {
    NSLog(@"%@", [result description]);
    if ([result isKindOfClass:[NSDictionary class]]) {
        NSDictionary *resultDict = (NSDictionary *)result;
        NSArray *comments = [resultDict arrayForKey:@"data"];
        for (NSDictionary *commentData in comments) {
            FacebookComment *aComment = [FacebookComment commentWithDictionary:commentData];
            aComment.parent = self.post;
        }
        
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES];
        [_comments release];
        _comments = [[self.post.comments sortedArrayUsingDescriptors:[NSArray arrayWithObject:sort]] retain];
        
        [_tableView reloadData];
    }
}

- (void)uploadDidComplete:(FacebookPost *)result {
    if ([result isKindOfClass:[FacebookComment class]]) {        
        FacebookComment *aComment = (FacebookComment *)result;
        aComment.parent = self.post;
        
        NSSortDescriptor *sort = 
        [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES];
        
        [_comments release];
        
        _comments = 
        [[self.post.comments 
          sortedArrayUsingDescriptors:[NSArray arrayWithObject:sort]] retain];
        
        [self dismissModalViewControllerAnimated:YES];        
        
        [_tableView reloadData];
        
        if (self.post.comments.count > 0) {
            NSIndexPath *newLastRowPath = 
            [NSIndexPath indexPathForRow:self.post.comments.count - 1 
                               inSection:0];            
            
            [_tableView scrollToRowAtIndexPath:newLastRowPath 
                              atScrollPosition:UITableViewScrollPositionMiddle 
                                      animated:YES];
        }
    }
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateLikeButtonStatus) name:FacebookDidGetSelfInfoNotification object:nil];
    
    _tableView.rowHeight = 100;
    
    if (self.actionsToolbar) {
        [self setupToolbarButtons];
    }
    
    NSSortDescriptor *sort = 
    [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES];
    [_comments release];
    _comments = [[self.post.comments sortedArrayUsingDescriptors:[NSArray arrayWithObject:sort]] retain];
    
    if (self.post) {
        KGODetailPager *pager = [[[KGODetailPager alloc] initWithPagerController:self delegate:self] autorelease];
        self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:pager] autorelease];
    }
        
    if (!_mediaView) {
        CGRect frame = self.view.bounds;
        frame.size.height = floor(frame.size.width * 9 / 16); // need to tweak this aspect ratio
        _mediaView = [[[UIView alloc] initWithFrame:frame] autorelease];
    } 
    
    [_mediaView initPreviewView:_mediaPreviewView];
 
    // add drop show to image background
    if (_mediaImageBackgroundView) {
        _mediaImageBackgroundView.layer.shadowOffset = CGSizeMake(0, 1);
        _mediaImageBackgroundView.layer.shadowColor = [[UIColor blackColor] CGColor];
        _mediaImageBackgroundView.layer.shadowRadius = 3.0;
        _mediaImageBackgroundView.layer.shadowOpacity = 0.8;
    }
    
    [self displayPost];
    
    // these listeners and delegates are used for 
    // handling rotations on the iPhone
    if([self allowRotationForIPhone] &&
       (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) ) 
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChange:) name:@"UIDeviceOrientationDidChangeNotification" object:nil];
        self.tapRecoginizer = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(restoreToolbars:)] autorelease];
        self.navigationController.delegate = self;
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)orientationChange:(NSNotification *)notification {
    UIDevice *device = [notification object];
    CGFloat statusBarHeight = 20.0;
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    _tableView.scrollEnabled = UIInterfaceOrientationIsPortrait(device.orientation);
    _tableView.contentOffset = CGPointZero;
    
    if (UIDeviceOrientationIsLandscape(device.orientation)) {
        [[UIApplication sharedApplication] setStatusBarHidden:YES];
        
        [UIView animateWithDuration:0.75 animations:^(void) {
            if (device.orientation == UIInterfaceOrientationLandscapeRight) {
                self.navigationController.view.transform = CGAffineTransformMakeRotation(M_PI_2);
                self.navigationController.view.frame = CGRectMake(0, 0, window.frame.size.width+statusBarHeight, window.frame.size.height);
            } else {
                self.navigationController.view.transform = CGAffineTransformMakeRotation(-M_PI_2);
                self.navigationController.view.frame = CGRectMake(-20.0, 0, window.frame.size.width+statusBarHeight, window.frame.size.height);
            }
            // disappear toolBars
            self.navigationController.navigationBar.alpha = 0;
            actionToolbarRoot.alpha = 0;
            
            // shrink navbar
            CGRect navigationBarFrame = self.navigationController.navigationBar.frame;
            navigationBarFrame.size.height = 30.0f;
            self.navigationController.navigationBar.frame = navigationBarFrame;
            
            // expand tablview to show whole photo
            CGRect tableViewFrame = self.tableView.frame;
            tableViewFrame.origin.y = statusBarHeight;
            tableViewFrame.size.height = tableViewFrame.size.height + actionToolbarRoot.frame.size.height;
            self.tableView.frame = tableViewFrame;
            _mediaView.fixedPreviewHeight = window.frame.size.width;
        }
        completion:^(BOOL finished) {
            [_mediaView addGestureRecognizer:self.tapRecoginizer];
        }];
    } else {
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        [_mediaView removeGestureRecognizer:self.tapRecoginizer];
        
        [[UIApplication sharedApplication] setStatusBarHidden:NO];
        [UIView animateWithDuration:0.75 animations:^(void) {
            [self restorePortraitLayout];
        }];
    }
}

- (BOOL)allowRotationForIPhone {
    NSAssert(NO, @"this method must be subclassed");
    return NO;
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if (viewController != self) {
        [self restorePortraitLayout];
        navigationController.delegate = nil;
    }
}

- (void)restorePortraitOrientation {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [_mediaView removeGestureRecognizer:self.tapRecoginizer];    
    _tableView.scrollEnabled = YES;
    
    [self restorePortraitLayout];
}

- (void)restorePortraitLayout {
    if([self allowRotationForIPhone] && (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)) {
        UIWindow *window = [[UIApplication sharedApplication] keyWindow];
        
        [[UIApplication sharedApplication] setStatusBarHidden:NO];
        self.navigationController.view.transform = CGAffineTransformMakeRotation(0);
        self.navigationController.view.frame = CGRectMake(0, 0, window.frame.size.width, window.frame.size.height);
        
        // redisplay toolbars
        self.navigationController.navigationBar.alpha = 1.0;
        actionToolbarRoot.alpha = 1.0;
        
        // expand navbar
        CGRect navigationBarFrame = self.navigationController.navigationBar.frame;
        navigationBarFrame.size.height = 44.0f;
        self.navigationController.navigationBar.frame = navigationBarFrame;
        
        // reset tableview to propersize
        CGRect tableViewFrame = self.tableView.frame;
        tableViewFrame.origin.y = 0;
        tableViewFrame.size.height = window.frame.size.height - actionToolbarRoot.frame.size.height;
        self.tableView.frame = tableViewFrame;
        _mediaView.fixedPreviewHeight = 0;
    }
}

- (void)hideToolbars {
    [UIView animateWithDuration:0.5 animations:^(void) {
        self.navigationController.navigationBar.alpha = 0;
        actionToolbarRoot.alpha = 0;
    }];
}

- (void)restoreToolbars:(id)sender {
    if (![self allowRotationForIPhone]) {
        // if rotation are disallowed
        // toolbars will never be hidded 
        // so dont need to restore them
        return;
    }
    
    self.navigationController.navigationBar.alpha = 1;
    actionToolbarRoot.alpha = 1;
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone &&
       UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation)) 
    {   
       [self performSelector:@selector(hideToolbars) withObject:nil afterDelay:3.0];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    CGFloat height;
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
        CGRect frame = self.view.frame;
        height = frame.size.width * self.view.transform.c + frame.size.height * self.view.transform.d;
        height -= _buttonsBar.frame.size.height;
    } else {
        height = floor(_tableView.frame.size.width * 9 / 16);
    }
    
    _tableView.tableHeaderView.frame = CGRectMake(0, 0, _tableView.frame.size.width, height);
    _tableView.tableHeaderView = _tableView.tableHeaderView;
    [_tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
    
    _tableView.scrollEnabled = UIInterfaceOrientationIsPortrait(self.interfaceOrientation);
}
    
- (void)displayPost {
    // subclasses should override this
}

- (NSString *)postTitle {
    // subclasses hsould override this
    return nil;
}

#pragma mark - KGODetailPager

- (void)pager:(KGODetailPager *)pager showContentForPage:(id<KGOSearchResult>)content {
    [self restoreToolbars:nil];
    
    [[KGOSocialMediaController facebookService] disconnectFacebookRequests:self]; // stop getting data for previous post
    
    self.post = (FacebookParentPost *)content;
    [self displayPost];
    
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES];
    [_comments release];
    _comments = [[self.post.comments sortedArrayUsingDescriptors:[NSArray arrayWithObject:sort]] retain];
    
    [_tableView reloadData];
}

- (NSInteger)numberOfSections:(KGODetailPager *)pager {
    return 1;
}

- (NSInteger)pager:(KGODetailPager *)pager numberOfPagesInSection:(NSInteger)section {
    return self.posts.count;
}

- (id<KGOSearchResult>)pager:(KGODetailPager *)pager contentForPageAtIndexPath:(NSIndexPath *)indexPath {
    return [self.posts objectAtIndex:indexPath.row];
}

#pragma mark - Table view methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _comments.count + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *text;
    NSDate *date;
    NSString *ownerName;
    if (indexPath.row == 0) {
        text = [self postTitle];
        date = self.post.date;
        ownerName = self.post.owner.name;
    } else {
        FacebookComment *aComment = [_comments objectAtIndex:indexPath.row-1];
        NSLog(@"%@", [aComment description]);
        
        text = aComment.text;
        ownerName = aComment.owner.name;
        date = aComment.date;
    }
    

    
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    NSInteger commentTag = 80;
    NSInteger authorTag = 81;
    NSInteger dateTag = 82;
    
    UILabel *commentLabel = (UILabel *)[cell.contentView viewWithTag:commentTag];
    if (!commentLabel) {
        commentLabel = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width - 20, 80)] autorelease];
        commentLabel.font = [UIFont systemFontOfSize:15];
        commentLabel.backgroundColor = [UIColor clearColor];
        commentLabel.numberOfLines = 3;
        commentLabel.lineBreakMode = UILineBreakModeTailTruncation;
        commentLabel.tag = commentTag;
        CGRect frame = commentLabel.frame;
        frame.origin.x = 10;
        frame.origin.y = 5;
        commentLabel.frame = frame;
    } 
    CGSize singleLine = [text sizeWithFont:commentLabel.font];
    CGSize multipleLines = [text sizeWithFont:commentLabel.font constrainedToSize:CGSizeMake(commentLabel.frame.size.width, 1000)];
    CGFloat height = multipleLines.height;
    if(height > singleLine.height * commentLabel.numberOfLines) {
        height = singleLine.height * commentLabel.numberOfLines;
    }
    commentLabel.text = text;
    CGRect commentFrame = commentLabel.frame;
    commentFrame.size.height = height;
    commentLabel.frame = commentFrame;
    [cell.contentView addSubview:commentLabel];
    
    UILabel *authorLabel = (UILabel *)[cell.contentView viewWithTag:authorTag];
    if (!authorLabel) {
        UIFont *authorFont = [UIFont systemFontOfSize:13];
        authorLabel = [UILabel multilineLabelWithText:ownerName font:authorFont width:tableView.frame.size.width - 20];
        authorLabel.tag = authorTag;
        CGRect frame = authorLabel.frame;
        frame.origin.x = 10;
        frame.origin.y = 80;
        authorLabel.frame = frame;
    } else {
        authorLabel.text = ownerName;
    }
    [cell.contentView addSubview:authorLabel];
    
    UILabel *dateLabel = (UILabel *)[cell.contentView viewWithTag:dateTag];
    NSString *dateString = [date agoString];
    if (!dateLabel) {
        UIFont *dateFont = [UIFont systemFontOfSize:13];
        dateLabel = [UILabel multilineLabelWithText:dateString font:dateFont width:tableView.frame.size.width - 20];
        dateLabel.tag = dateTag;
        CGRect frame = dateLabel.frame;
        frame.origin.x = 160;
        frame.origin.y = 80;
        dateLabel.frame = frame;
    } else {
        dateLabel.text = dateString;
    }
    [cell.contentView addSubview:dateLabel];
    
    return cell;
}

@end
