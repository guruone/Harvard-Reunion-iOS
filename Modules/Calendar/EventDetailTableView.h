#import <UIKit/UIKit.h>
#import "KGOShareButtonController.h"
#import "KGODetailPageHeaderView.h"
#import <MessageUI/MFMailComposeViewController.h>
#import <EventKitUI/EventKitUI.h>
#import "KGORequest.h"

@class KGOEventWrapper, CalendarDataManager;
@class CalendarDetailViewController;

@interface EventDetailTableView : UITableView <UITableViewDelegate,
UITableViewDataSource, KGODetailPageHeaderDelegate, MFMailComposeViewControllerDelegate,
KGORequestDelegate, EKEventEditViewDelegate> {
    
    NSArray *_sections;
    KGOEventWrapper *_event;

    //UIButton *_shareButton;
    //UIButton *_bookmarkButton;
    
    KGODetailPageHeaderView *_headerView;
    //UILabel *_descriptionLabel;
    
    KGORequest *_eventDetailRequest;
}

@property (nonatomic, assign) UIViewController *viewController;
@property (nonatomic, retain) KGOEventWrapper *event;
@property (nonatomic, retain) NSArray * sections;
@property (nonatomic, retain) CalendarDataManager *dataManager;
@property (nonatomic, retain) KGODetailPageHeaderView *headerView;

@property (nonatomic) BOOL canAddToCalendar;

// functions split out for subclassing

- (UIView *)viewForTableHeader;

- (NSArray *)sectionForBasicInfo;
- (NSArray *)sectionForAttendeeInfo;
- (NSArray *)sectionForContactInfo;
- (NSArray *)sectionForExtendedInfo;

- (void)requestEventDetails;
- (void)eventDetailsDidChange;

@end
