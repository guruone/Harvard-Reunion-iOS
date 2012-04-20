#import "SettingsTableViewController.h"
#import "KGOAppDelegate.h"
#import "KGOModule.h"
#import "KGOTheme.h"
#import "KGORequestManager.h"
#import "KGOSocialMediaController.h"
#import "UIKit+KGOAdditions.h"
#import "KGOAppDelegate+ModuleAdditions.h"
#import "Foundation+KGOAdditions.h"
#import "ReunionHomeModule.h"

static NSString * const KGOSettingsDefaultFont = @"DefaultFont";
static NSString * const KGOSettingsDefaultFontSize = @"DefaultFontSize";
static NSString * const KGOSettingsLogin = @"Login";
static NSString * const KGOSettingsWidgets = @"Widgets";
static NSString * const KGOSettingsSocialMedia = @"SocialMedia";


@interface SettingsTableViewController (Private)

- (NSString *)readableStringForKey:(NSString *)key;

@end

@implementation SettingsTableViewController

- (NSString *)readableStringForKey:(NSString *)key
{
    if ([key isEqualToString:KGOSettingsDefaultFont]) {
        return NSLocalizedString(@"Default font", nil);
        
    } else if ([key isEqualToString:KGOSettingsDefaultFontSize]) {
        return NSLocalizedString(@"Default font size", nil);
        
    } else if ([key isEqualToString:KGOSettingsWidgets]) {
        return NSLocalizedString(@"Updates to show on home screen", nil);
        
    } else if ([key isEqualToString:KGOSettingsSocialMedia]) {
        return NSLocalizedString(@"Third party services", nil);

    } else if ([key isEqualToString:KGOSettingsLogin]) {
        return nil;
        
    }
    return key;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    KGOAppDelegate *appDelegate = KGO_SHARED_APP_DELEGATE();
    
    _availableUserSettings = [[[appDelegate appConfig] objectForKey:@"UserSettings"] retain];
    _setUserSettings = [[[NSUserDefaults standardUserDefaults] objectForKey:KGOUserPreferencesKey] retain];
    if (!_setUserSettings) {
        NSDictionary *defaultUserSettings = [[appDelegate appConfig] objectForKey:@"DefaultUserSettings"];
        if (defaultUserSettings) {
            _setUserSettings = [defaultUserSettings copy];
        }
    }
    

    NSArray *preferredOrder = [NSArray arrayWithObjects: 
                               KGOSettingsLogin, 
                               KGOSettingsWidgets, 
                               KGOSettingsSocialMedia, 
                               KGOSettingsDefaultFont, 
                               KGOSettingsDefaultFontSize, 
                               nil];    
    
    _settingKeys = [[[_availableUserSettings allKeys] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        int obj1Index = [preferredOrder indexOfObject:obj1];
        int obj2Index = [preferredOrder indexOfObject:obj2];
        
        if (obj1Index == obj2Index) {
            return NSOrderedSame;
        } else if (obj1Index < obj2Index) { 
            return NSOrderedAscending;
        } else {
            return NSOrderedDescending;
        }
    }] retain];
    
    if ([appDelegate navigationStyle] == KGONavigationStyleTabletSidebar) {
        CGRect frame = self.tableView.frame;
        frame.origin.y += 44;
        frame.size.height -= 44;
        self.tableView.frame = frame;
    }
    
    self.tableView.rowHeight += 16; // room for subtitle
    
}
/*
- (void)viewWillAppear:(BOOL)animated
{
    [self reloadDataForTableView:self.tableView];
}
*/
- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

- (void)dealloc {
    [_availableUserSettings release];
    [_settingKeys release];
    [_setUserSettings release];
    [super dealloc];
}

- (void)settingDidChange:(NSNotification *)aNotification
{
    [self reloadDataForTableView:self.tableView];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _availableUserSettings.count;    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSString *key = [_settingKeys objectAtIndex:section];
    return [[_availableUserSettings objectForKey:key] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [self readableStringForKey:[_settingKeys objectAtIndex:section]];
}

- (NSArray *)tableView:(UITableView *)tableView viewsForCellAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *key = [_settingKeys objectAtIndex:indexPath.section];
    if ([key isEqualToString:KGOSettingsSocialMedia]) {
        NSArray *options = [_availableUserSettings objectForKey:key];
        id optionValue = [options objectAtIndex:indexPath.row];
        if ([optionValue isKindOfClass:[NSDictionary class]]) {
            NSString *serviceName = [optionValue stringForKey:@"service" nilIfEmpty:YES];
            id<KGOSocialMediaService> service = [[KGOSocialMediaController sharedController] serviceWithType:serviceName];

            NSMutableArray *views = [NSMutableArray array];
            
            CGFloat width = tableView.frame.size.width - 45; // adjust for padding and chevron
            CGFloat x = 10;
            CGFloat y = 10;
            
            UIFont *font = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyNavListTitle];
            UILabel *titleLabel = [[[UILabel alloc] initWithFrame:CGRectMake(x, y, width, font.lineHeight)] autorelease];
            titleLabel.backgroundColor = [UIColor clearColor];
            titleLabel.font = font;
            titleLabel.text = [service serviceDisplayName];
            y += titleLabel.frame.size.height + 1;
            [views addObject:titleLabel];
            
            font = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyNavListSubtitle];
            UILabel *serviceLabel = [[[UILabel alloc] initWithFrame:CGRectMake(x, y, width, font.lineHeight)] autorelease];
            serviceLabel.backgroundColor = [UIColor clearColor];
            serviceLabel.font = font;
            if ([service isSignedIn]) {
                NSString *username = [service userDisplayName];
                if (username) {
                    serviceLabel.text = [NSString stringWithFormat:@"Signed in as %@", username];
                    
                } else {
                    serviceLabel.text = @"Signed in";
                }
                serviceLabel.textColor = [UIColor colorWithHexString:@"007100"];
                
            } else {
                serviceLabel.text = @"Not signed in";
                serviceLabel.textColor = [UIColor colorWithHexString:@"c10000"];
                
            }
            y += serviceLabel.frame.size.height + 1;
            [views addObject:serviceLabel];

            
            font = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyNavListSubtitle];
            NSString *string = [optionValue stringForKey:@"subtitle" nilIfEmpty:YES];
            if (string) {
                UILabel *subtitleLabel = [UILabel multilineLabelWithText:string font:font width:width];
                subtitleLabel.textColor = [[KGOTheme sharedTheme] textColorForThemedProperty:KGOThemePropertyNavListSubtitle];
                CGRect frame = subtitleLabel.frame;
                frame.origin.x = x;
                frame.origin.y = y;
                subtitleLabel.frame = frame;
                y += subtitleLabel.frame.size.height + 1;
                [views addObject:subtitleLabel];
            }

            UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(x, y, width, font.lineHeight)] autorelease];
            label.backgroundColor = [UIColor clearColor];
            label.font = font;
            label.textColor = [[KGOTheme sharedTheme] textColorForThemedProperty:KGOThemePropertyNavListSubtitle];
            if ([service isSignedIn]) {
                label.text = @"Tap to sign out";
            } else {
                label.text = @"Tap to sign in";
            }
            [views addObject:label];
            
            return views;
        }
    } else if ([key isEqualToString:KGOSettingsLogin]) {
        // TODO: clean up these ways of getting strings
        NSString *cellTitle = nil;
        NSString *cellSubtitle = nil;
        
        NSDictionary *dictionary = [[KGORequestManager sharedManager] sessionInfo];
        NSString *name = [[dictionary dictionaryForKey:@"user"] stringForKey:@"name" nilIfEmpty:YES];
        KGOAppDelegate *appDelegate = KGO_SHARED_APP_DELEGATE();
        ReunionHomeModule *homeModule = (ReunionHomeModule *)[appDelegate moduleForTag:@"home"];
        NSString *number = [homeModule reunionNumber];
        NSString *year = [homeModule reunionYear];
        if (name) {
            cellTitle = [NSString stringWithFormat:@"You are signed in as %@ (%@th Reunion)", name, number];
            cellSubtitle = @"Tap to sign out";
        } else if (year) {
            cellTitle = [NSString stringWithFormat:@"You are viewing the class of %@ (%@th Reunion) anonymously", year, number];
            cellSubtitle = @"Tap to sign in";
        } else {
            cellTitle = [NSString stringWithFormat:@"Loading…"];
            cellSubtitle = @"";
        }

        NSMutableArray *views = [NSMutableArray array];

        CGFloat width = tableView.frame.size.width - 45; // adjust for padding and chevron
        CGFloat y = 10;
        UIFont *font = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyNavListTitle];
        CGSize labelSize = [cellTitle sizeWithFont:font
                                 constrainedToSize:CGSizeMake(width, 1000)
                                     lineBreakMode:UILineBreakModeWordWrap];
        UILabel *titleLabel = [[[UILabel alloc] initWithFrame:CGRectMake(10, y, width, labelSize.height)] autorelease];
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.numberOfLines = 2;
        titleLabel.lineBreakMode = UILineBreakModeWordWrap;
        titleLabel.font = font;
        titleLabel.text = cellTitle;
        y += titleLabel.frame.size.height + 1;
        [views addObject:titleLabel];

        font = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyNavListSubtitle];
        UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(10, y, tableView.frame.size.width - 20, font.lineHeight)] autorelease];
        label.backgroundColor = [UIColor clearColor];
        label.font = font;
        label.text = cellSubtitle;
        label.textColor = [[KGOTheme sharedTheme] textColorForThemedProperty:KGOThemePropertyNavListSubtitle];
        [views addObject:label];

        return views;
    }
    
    return nil;
}

- (KGOTableCellStyle)tableView:(UITableView *)tableView styleForCellAtIndexPath:(NSIndexPath *)indexPath
{
    return KGOTableCellStyleSubtitle;
}

- (CellManipulator)tableView:(UITableView *)tableView manipulatorForCellAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *key = [_settingKeys objectAtIndex:indexPath.section];
    NSArray *options = [_availableUserSettings objectForKey:key];
    
    UIFont *cellTitleFont = nil;
    NSString *cellTitle = nil;
    NSString *cellSubtitle = nil;
    NSString *accessory = nil;
    
    id optionValue = [options objectAtIndex:indexPath.row];
    if ([key isEqualToString:KGOSettingsLogin]) {
        // custom view
    
    } else if ([key isEqualToString:KGOSettingsSocialMedia]) {
        // just don't want any other branches
        
    } else if ([key isEqualToString:KGOSettingsWidgets]) {
        cellTitle = [optionValue stringForKey:@"title" nilIfEmpty:YES];
        NSString *tag = [optionValue stringForKey:@"tag" nilIfEmpty:YES];
        if ([tag isEqualToString:@"twitter"]) {
            cellSubtitle = [[NSUserDefaults standardUserDefaults] stringForKey:TwitterHashTagKey];
            
        } else if ([tag isEqualToString:@"facebook"]) {
            cellSubtitle = [[NSUserDefaults standardUserDefaults] stringForKey:FacebookGroupTitleKey];
        }
        
    } else if ([optionValue isKindOfClass:[NSString class]]) {
        cellTitle = optionValue;
        
    } else if ([optionValue isKindOfClass:[NSDictionary class]]) {
        // TODO: the current setup is not amenable to localization
        cellTitle = [optionValue stringForKey:@"title" nilIfEmpty:YES];
        cellSubtitle = [optionValue stringForKey:@"subtitle" nilIfEmpty:YES];
    }

    // special treatment for different sections
    if ([key isEqualToString:KGOSettingsDefaultFont]) {
        cellTitleFont = [[KGOTheme sharedTheme] defaultBoldFont];
        
    } else {
        cellTitleFont = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyNavListTitle];
    }
    
    id optionSelected = [_setUserSettings objectForKey:key];
    if ([optionSelected isKindOfClass:[NSString class]] && [optionValue isKindOfClass:[NSString class]]) {
        accessory = [optionSelected isEqualToString:optionValue] ? KGOAccessoryTypeCheckmark : KGOAccessoryTypeNone;

    } else if ([optionSelected isKindOfClass:[NSArray class]] && [optionValue isKindOfClass:[NSDictionary class]]) {
        NSString *optionTag = [optionValue stringForKey:@"tag" nilIfEmpty:YES];
        accessory = [optionSelected containsObject:optionTag] ? KGOAccessoryTypeCheckmark : KGOAccessoryTypeNone;
            
    } else {
        accessory = KGOAccessoryTypeChevron;
    }
    
    return [[^(UITableViewCell *cell) {
        cell.textLabel.text = cellTitle;
        cell.textLabel.textColor = [[KGOTheme sharedTheme] textColorForThemedProperty:KGOThemePropertyNavListTitle];
        cell.textLabel.font = cellTitleFont;
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        cell.detailTextLabel.text = cellSubtitle;
        cell.detailTextLabel.font = [[KGOTheme sharedTheme] fontForThemedProperty:KGOThemePropertyNavListSubtitle];
        cell.detailTextLabel.textColor = [[KGOTheme sharedTheme] textColorForThemedProperty:KGOThemePropertyNavListSubtitle];
        cell.accessoryView = [[KGOTheme sharedTheme] accessoryViewForType:accessory];
    } copy] autorelease];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *key = [_settingKeys objectAtIndex:indexPath.section];
    NSArray *options = [_availableUserSettings objectForKey:key];
    id optionValue = [options objectAtIndex:indexPath.row];
    id optionSelected = [_setUserSettings objectForKey:key];
    id newOptionSelected = nil;
    
    if ([optionSelected isKindOfClass:[NSString class]] && [optionValue isKindOfClass:[NSString class]]) {
        if (![optionSelected isEqualToString:optionValue]) {
            newOptionSelected = optionValue;
        }
        
    } else if ([optionSelected isKindOfClass:[NSArray class]] && [optionValue isKindOfClass:[NSDictionary class]]) {
        NSString *optionTag = [optionValue stringForKey:@"tag" nilIfEmpty:YES];
        newOptionSelected = [[optionSelected mutableCopy] autorelease];
        if (!newOptionSelected) {
            newOptionSelected = [NSMutableArray array];
        }
        if ([optionSelected containsObject:optionTag]) { // remove from prefs
            [newOptionSelected removeObject:optionTag];
            
        } else { // add to prefs
            [newOptionSelected addObject:optionTag];
            
        }
        
    } else {
        if ([key isEqualToString:KGOSettingsSocialMedia] && [optionValue isKindOfClass:[NSDictionary class]]) {
            // login/logout
            NSString *serviceName = [optionValue stringForKey:@"service" nilIfEmpty:YES];
            id<KGOSocialMediaService> service = [[KGOSocialMediaController sharedController] serviceWithType:serviceName];
            if ([service isSignedIn]) {
                [service signout];
            } else {
                [service signin];
            }
            
        } else if ([key isEqualToString:KGOSettingsLogin]) {
            // pop self off navigation stack if there is a nav stack (sidebar will select default module on login)
            if ([KGO_SHARED_APP_DELEGATE() navigationStyle] != KGONavigationStyleTabletSidebar) {
                [self.navigationController popToRootViewControllerAnimated:YES]; // go back to home screen
            }

            // currently assuming the user has to be logged in to get here
            [[KGORequestManager sharedManager] logoutKurogoServer];
        }
    }
    
    if (newOptionSelected) {
        NSMutableDictionary *dict = [[_setUserSettings mutableCopy] autorelease];
        if (!dict) {
            dict = [NSMutableDictionary dictionary];
        }
        [dict setObject:newOptionSelected forKey:key];
        [_setUserSettings release];
        _setUserSettings = [dict copy];

        [[NSUserDefaults standardUserDefaults] setObject:dict forKey:KGOUserPreferencesKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:KGOUserPreferencesDidChangeNotification object:key];
        
        //[self reloadDataForTableView:tableView];
    }
}

@end
