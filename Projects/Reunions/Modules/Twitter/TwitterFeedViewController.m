
/****************************************************************
 *
 *  Copyright 2011 The President and Fellows of Harvard College
 *  Copyright 2011 Modo Labs Inc.
 *
 *****************************************************************/

#import "TwitterFeedViewController.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "TwitterModule.h"
#import "Foundation+KGOAdditions.h"
#import "UIKit+KGOAdditions.h"
#import "TwitterViewController.h"
#import "MITThumbnailView.h"
#import "AnalyticsWrapper.h"

@implementation TwitterFeedViewController

@synthesize latestTweets;

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    self.latestTweets = nil;
    twitterModule = nil;
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)twitterFeedDidUpdate:(NSNotification *)aNotification {
    self.latestTweets = twitterModule.latestTweets;
    [self reloadDataForTableView:self.tableView];
}

- (void)tweetButtonPressed:(id)sender
{
    TwitterViewController *twitterVC = [[[TwitterViewController alloc] initWithNibName:@"TwitterViewController"
                                                                                bundle:nil] autorelease];
    twitterVC.preCannedMessage = twitterModule.hashtag;
    twitterVC.delegate = self;
    
    UINavigationController *navC = [[[UINavigationController alloc] initWithRootViewController:twitterVC] autorelease];
    navC.modalPresentationStyle = UIModalPresentationFormSheet;
    navC.navigationBar.barStyle = UIBarStyleBlack;
    
    [self presentModalViewController:navC animated:YES];
}

#pragma mark TwitterViewControllerDelegate

- (BOOL)controllerShouldContinueToMessageScreen:(TwitterViewController *)controller
{
    return YES;
}

- (void)controllerDidPostTweet:(TwitterViewController *)controller
{
    [self dismissModalViewControllerAnimated:YES];
     [twitterModule performSelector:@selector(requestStatusUpdates:) withObject:nil afterDelay:10];
    
    [[AnalyticsWrapper sharedWrapper] trackGroupAction:@"Twitter Post" label:twitterModule.hashtag];
}

- (void)controllerFailedToTweet:(TwitterViewController *)controller
{
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    twitterModule = (TwitterModule *)[KGO_SHARED_APP_DELEGATE() moduleForTag:@"twitter"];
    self.latestTweets = twitterModule.latestTweets;
    
    if (!self.latestTweets) {
        [twitterModule requestStatusUpdates:nil];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(twitterFeedDidUpdate:)
                                                 name:TwitterStatusDidUpdateNotification
                                               object:nil];
    
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Tweet"
                                                                               style:UIBarButtonItemStyleDone
                                                                              target:self
                                                                              action:@selector(tweetButtonPressed:)] autorelease];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait)
        || UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
}

#pragma mark - Table view data source

- (CellManipulator)tableView:(UITableView *)tableView manipulatorForCellAtIndexPath:(NSIndexPath *)indexPath
{
    return [[^(UITableViewCell *cell) {
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    } copy] autorelease];
}

- (NSArray *)tableView:(UITableView *)tableView viewsForCellAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger rownum = indexPath.row;
    if (_inputView) {
        if (rownum == 0) {
            return [NSArray arrayWithObject:_inputView];
        } else {
            rownum--;
        }
    }
    
    NSDictionary *aTweet = [self.latestTweets objectAtIndex:rownum];
    
    NSString *title = [aTweet stringForKey:@"text" nilIfEmpty:YES];
    NSString *user = [aTweet stringForKey:@"from_user" nilIfEmpty:YES];
    NSString *dateString = [aTweet stringForKey:@"created_at" nilIfEmpty:YES];
    NSString *imageURL = [aTweet stringForKey:@"profile_image_url" nilIfEmpty:YES];
    
    MITThumbnailView *thumbView = [[[MITThumbnailView alloc] initWithFrame:CGRectMake(10, 10, 50, 50)] autorelease];
    thumbView.imageURL = imageURL;
    [thumbView loadImage];
    
    NSDate *date = [[twitterModule twitterDateFormatter] dateFromString:dateString];

    UIFont *titleFont = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyBodyText];
    UIFont *detailFont = [UIFont systemFontOfSize:12];
    CGFloat width = tableView.frame.size.width - 20 - thumbView.frame.size.width;

    // tweet text
    UILabel *titleLabel = [UILabel multilineLabelWithText:title
                                                     font:titleFont
                                                    width:width];
    CGRect frame = titleLabel.frame;
    frame.origin.x = thumbView.frame.size.width + 20;
    frame.origin.y = 10;
    UIFont *userFont = [UIFont boldSystemFontOfSize:12];
    CGSize size = [user sizeWithFont:userFont];
    frame.size = size;

    // username
    UILabel *userLabel = [[[UILabel alloc] initWithFrame:frame] autorelease];
    userLabel.font = userFont;
    userLabel.text = user;
    frame.origin.y += userLabel.frame.size.height + 2;

    frame.size = titleLabel.frame.size;
    titleLabel.frame = frame;

    // tweet time
    frame.origin.y += titleLabel.frame.size.height + 2;
    frame.size.height = detailFont.lineHeight;

    UILabel *subtitleLabel = [[[UILabel alloc] initWithFrame:frame] autorelease];
    subtitleLabel.text = [date agoString];
    subtitleLabel.font = detailFont;
    subtitleLabel.textColor = [[KGOTheme sharedTheme] textColorForThemedProperty:KGOThemePropertyNavListSubtitle];
    
    return [NSArray arrayWithObjects:thumbView, userLabel, titleLabel, subtitleLabel, nil];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger num = self.latestTweets.count;
    if (_inputView) {
        num++;
    }
    return num;
}

#pragma mark UITextView

#define TWEET_MAX_CHARS 140

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
	if (textView.text.length - range.length + text.length <= TWEET_MAX_CHARS) {
		return YES;
	} else {
		return NO;
	}
}

@end
