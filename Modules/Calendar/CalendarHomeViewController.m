#import "CalendarHomeViewController.h"
#import "KGOAppDelegate.h"
#import "CalendarModel.h"

@implementation CalendarHomeViewController

@synthesize searchTerms, currentCalendar = _currentCalendar;

/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
    }
    return self;
}
*/

- (void)dealloc
{
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _tabstrip.delegate = self;
    _datePager.delegate = self;
    
    _dataManager = [[CalendarDataManager alloc] init];
    _dataManager.delegate = self;
    [_dataManager requestGroups];
    
    [_datePager setDate:[NSDate date]];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - CalendarDataManager

- (void)groupsDidChange:(NSArray *)groups
{
    [_groupTitles release];
    _groupTitles = [[NSMutableArray alloc] init];
    
    for (KGOCalendarGroup *aGroup in groups) {
        [_groupTitles addObject:aGroup.title];
    }
    
    [self setupTabstripButtons];
}

- (void)groupDataDidChange:(KGOCalendarGroup *)group
{
    NSLog(@"%@", [group.calendars description]);
    
    if (group.calendars.count) {
        [_loadingView stopAnimating];
        
        UITableViewStyle style = (group.calendars.count > 1) ? UITableViewStyleGrouped : UITableViewStylePlain;
        if (group.calendars.count > 1) {
            style = UITableViewStyleGrouped;
        } else {
            style = UITableViewStylePlain;
        }
        
        CGRect frame = self.view.frame;
        if ([_datePager isDescendantOfView:self.view]) {
            frame.origin.y += _datePager.frame.size.height;
            frame.size.height -= _datePager.frame.size.height;
        }
        if ([_tabstrip isDescendantOfView:self.view]) {
            frame.origin.y += _tabstrip.frame.size.height;
            frame.size.height -= _tabstrip.frame.size.height;
        }

        UITableView *tableView = [self addTableViewWithFrame:frame style:style];
        
        self.currentCalendar = (group.calendars.count > 1) ? nil : [group.calendars anyObject];
    }
}

- (void)categoriesDidChange:(NSArray *)categories group:(NSString *)group
{
    if ([group isEqualToString:[_groupTitles objectAtIndex:_currentGroupIndex]]) {
    }
}

// TODO: flesh out placeholder functions
static bool isOverOneMonth(NSTimeInterval interval) {
    return interval > 31 * 24 * 60 * 60;
}

static bool isOverOneDay(NSTimeInterval interval) {
    return interval > 24 * 60 * 60;
}

static bool isOverOneHour(NSTimeInterval interval) {
    return interval > 60 * 60;
}


- (void)eventsDidChange:(NSArray *)events category:(NSString *)category
{
    if (![_currentCalendar.identifier isEqualToString:category]) {
        return;
    }
    
    [_currentSections release];
    _currentSections = nil;
    
    [_currentEventsBySection release];
    _currentEventsBySection = nil;
    
    if (events.count) {
        // TODO: make sure this set of events is what we last requested
        NSMutableDictionary *eventsBySection = [NSMutableDictionary dictionary];
        NSMutableArray *sectionTitles = [NSMutableArray array];
        NSArray *sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"startDate" ascending:YES]];
        NSArray *sortedEvents = [events sortedArrayUsingDescriptors:sortDescriptors];
        KGOEventWrapper *firstEvent = [sortedEvents objectAtIndex:0];
        KGOEventWrapper *lastEvent = [sortedEvents lastObject];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        NSTimeInterval interval = [lastEvent.startDate timeIntervalSinceDate:firstEvent.startDate];
        if (isOverOneMonth(interval)) {
            [formatter setDateStyle:NSDateFormatterMediumStyle];
            [formatter setTimeStyle:NSDateFormatterNoStyle];

        } else if (isOverOneDay(interval)) {
            [formatter setDateStyle:NSDateFormatterMediumStyle];
            [formatter setTimeStyle:NSDateFormatterNoStyle];

        } else if (isOverOneHour(interval)) {
            [formatter setDateStyle:NSDateFormatterNoStyle];
            [formatter setTimeStyle:NSDateFormatterMediumStyle];
        
        } else {
            [formatter setDateStyle:NSDateFormatterNoStyle];
            [formatter setTimeStyle:NSDateFormatterMediumStyle];
        
        }
        
        for (KGOEventWrapper *event in events) {
            NSString *title = [formatter stringFromDate:event.startDate];
            NSMutableArray *eventsForCurrentSection = [eventsBySection objectForKey:title];
            if (!eventsForCurrentSection) {
                eventsForCurrentSection = [NSMutableArray array];
                [eventsBySection setObject:eventsForCurrentSection forKey:title];
                [sectionTitles addObject:title];
            }
            [eventsForCurrentSection addObject:event];
        }
    
        _currentSections = [sectionTitles copy];
        _currentEventsBySection = [eventsBySection copy];
    }
    
    [self reloadDataForTableView:self.tableView];
}



- (KGOCalendar *)currentCalendar
{
    return _currentCalendar;
}

- (void)setCurrentCalendar:(KGOCalendar *)currentCalendar
{
    [_currentCalendar release];
    _currentCalendar = [currentCalendar retain];
    
    if (_currentCalendar) {
        [_dataManager requestEventsForCalendar:_currentCalendar time:[NSDate date]];
    }
}

#pragma mark - Scrolling tabstrip

- (void)tabstrip:(KGOScrollingTabstrip *)tabstrip clickedButtonAtIndex:(NSUInteger)index
{
    // TODO: make tabstrip only return indexes of non-special buttons
    // since what it does now is way too confusing
    if (index == [tabstrip searchButtonIndex] || index == [tabstrip bookmarkButtonIndex]) {
        return;
    }
    
    NSString *title = [tabstrip buttonTitleAtIndex:index];
    index = [_groupTitles indexOfObject:title];
    
    if (index != _currentGroupIndex) {
        [self removeTableView:self.tableView];
        [_loadingView startAnimating];

        _currentGroupIndex = index;
        [_dataManager selectGroupAtIndex:index];
        KGOCalendarGroup *group = [_dataManager currentGroup];
        [self groupDataDidChange:group];
    }
}

- (void)setupTabstripButtons
{
    _tabstrip.showsSearchButton = YES;

    for (NSInteger i = 0; i < _groupTitles.count; i++) {
        NSString *buttonTitle = [_groupTitles objectAtIndex:i];
        [_tabstrip addButtonWithTitle:buttonTitle];
    }
    [_tabstrip setNeedsLayout];
    
    if (_currentGroupIndex >= _groupTitles.count) {
        _currentGroupIndex = 0;
    }
    
    [_tabstrip selectButtonAtIndex:_currentGroupIndex];
}

#pragma mark - Date pager

- (void)pager:(KGODatePager *)pager didSelectDate:(NSDate *)date
{
    // TODO: show loading indicator
    
    [_dataManager requestEventsForCalendar:_currentCalendar startDate:date endDate:nil];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSInteger num = 1;
    if (_currentSections && _currentEventsBySection) {
        num = _currentSections.count;
    }
    return num;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger num = 0;
    if (_currentSections && _currentEventsBySection) {
        NSArray *eventsForSection = [_currentEventsBySection objectForKey:[_currentSections objectAtIndex:section]];
        num = eventsForSection.count;

    } else if (_currentCategories) {
        num = _currentCategories.count;
    }

    return num;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (_currentSections && _currentEventsBySection) {
        return [_currentSections objectAtIndex:section];
    }
    
    return nil;
}

- (KGOTableCellStyle)tableView:(UITableView *)tableView styleForCellAtIndexPath:(NSIndexPath *)indexPath {
    if (_currentCategories) {
        return UITableViewCellStyleDefault;
    }
    return UITableViewCellStyleSubtitle;
}

- (NSArray *)tableView:(UITableView *)tableView viewsForCellAtIndexPath:(NSIndexPath *)indexPath {
    if (!_currentCategories && _currentSections && _currentEventsBySection) {
        NSArray *eventsForSection = [_currentEventsBySection objectForKey:[_currentSections objectAtIndex:indexPath.section]];
        KGOEventWrapper *event = [eventsForSection objectAtIndex:indexPath.row];
    
        if (event.briefLocation) {
            // right align event location
            CGFloat maxWidth = tableView.frame.size.width - 20;
            UIFont *font = [[KGOTheme sharedTheme] fontForTableCellTitleWithStyle:KGOTableCellStyleSubtitle];
            CGSize textSize = [event.title sizeWithFont:font];
            CGFloat textHeight = 10.0 + (textSize.width > maxWidth ? textSize.height * 1 : textSize.height);
            
            font = [[KGOTheme sharedTheme] fontForTableCellSubtitleWithStyle:KGOTableCellStyleSubtitle];
            CGSize locationTextSize = [event.briefLocation sizeWithFont:font
                                                               forWidth:100.0
                                                          lineBreakMode:UILineBreakModeTailTruncation];
            CGRect locationFrame = CGRectMake(maxWidth - locationTextSize.width,
                                              textHeight,
                                              locationTextSize.width,
                                              locationTextSize.height);
            
            UILabel *locationLabel = [[[UILabel alloc] initWithFrame:locationFrame] autorelease];
            locationLabel.lineBreakMode = UILineBreakModeTailTruncation;
            locationLabel.text = event.briefLocation;
            locationLabel.textColor = [[KGOTheme sharedTheme] textColorForTableCellSubtitleWithStyle:KGOTableCellStyleSubtitle];
            locationLabel.font = font;
            locationLabel.highlightedTextColor = [UIColor whiteColor];
            
            return [NSArray arrayWithObject:locationLabel];
        }
    
    }
    
	return nil;
}

- (CellManipulator)tableView:(UITableView *)tableView manipulatorForCellAtIndexPath:(NSIndexPath *)indexPath {
    if (_currentCategories) {
        KGOCalendar *category = [_currentCategories objectAtIndex:indexPath.row];
        NSString *title = category.title;
        
        return [[^(UITableViewCell *cell) {
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
            cell.textLabel.text = title;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        } copy] autorelease];
        
    } else if (_currentSections && _currentEventsBySection) {
        NSArray *eventsForSection = [_currentEventsBySection objectForKey:[_currentSections objectAtIndex:indexPath.section]];
        KGOEventWrapper *event = [eventsForSection objectAtIndex:indexPath.row];
        
        NSString *title = event.title;
        NSString *subtitle = nil; // TODO: put some date string here
        
        return [[^(UITableViewCell *cell) {
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
            cell.textLabel.text = title;
            cell.detailTextLabel.text = subtitle;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        } copy] autorelease];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_currentCategories) {
        ;
        
    } else if (_currentSections && _currentEventsBySection) {
        NSArray *eventsForSection = [_currentEventsBySection objectForKey:[_currentSections objectAtIndex:indexPath.section]];
        KGOEventWrapper *event = [eventsForSection objectAtIndex:indexPath.row];
        
        NSDictionary *params = [NSDictionary dictionaryWithObject:event forKey:@"event"];
        [KGO_SHARED_APP_DELEGATE() showPage:LocalPathPageNameDetail forModuleTag:CalendarTag params:params];
    }
}

@end
