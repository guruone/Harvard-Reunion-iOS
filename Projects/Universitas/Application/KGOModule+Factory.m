#import "KGOModule+Factory.h"
#import "KGOModule.h"
#import "AboutModule.h"
#import "CalendarModule.h"
#import "FacebookModule.h"
#import "ExternalURLModule.h"
#import "HomeModule.h"
#import "LoginModule.h"
#import "NewsModule.h"
#import	"MapModule.h"
#import "PeopleModule.h"
#import "SettingsModule.h"
#import "BumpModule.h"

@implementation KGOModule (Factory)

+ (KGOModule *)moduleWithDictionary:(NSDictionary *)args {
    KGOModule *module = nil;
    NSString *className = [args objectForKey:@"class"];
    
    if ([className isEqualToString:@"AboutModule"])
        module = [[[AboutModule alloc] initWithDictionary:args] autorelease];
    
    else if ([className isEqualToString:@"CalendarModule"])
        module = [[[CalendarModule alloc] initWithDictionary:args] autorelease];
    
    else if ([className isEqualToString:@"HomeModule"])
        module = [[[HomeModule alloc] initWithDictionary:args] autorelease];
    
    else if ([className isEqualToString:@"FacebookModule"])
        module = [[[FacebookModule alloc] initWithDictionary:args] autorelease];
    
    else if ([className isEqualToString:@"ExternalURLModule"])
        module = [[[ExternalURLModule alloc] initWithDictionary:args] autorelease];
    
    else if ([className isEqualToString:@"LoginModule"])
        module = [[[LoginModule alloc] initWithDictionary:args] autorelease];
    
    else if ([className isEqualToString:@"MapModule"])
        module = [[[MapModule alloc] initWithDictionary:args] autorelease];
    
    else if ([className isEqualToString:@"NewsModule"])
        module = [[[NewsModule alloc] initWithDictionary:args] autorelease];
    
    else if ([className isEqualToString:@"PeopleModule"])
        module = [[[PeopleModule alloc] initWithDictionary:args] autorelease];
    
    //else if ([className isEqualToString:@"PhotosModule"])
    //    module = [[[PhotosModule alloc] initWithDictionary:args] autorelease];
    
    else if ([className isEqualToString:@"SettingsModule"])
        module = [[[SettingsModule alloc] initWithDictionary:args] autorelease];
    
    //else if ([className isEqualToString:@"TwitterModule"])
    //    module = [[[TwitterModule alloc] initWithDictionary:args] autorelease];
    
    //else if ([className isEqualToString:@"TransitModule"])
    //    module = [[[TransitModule alloc] initWithDictionary:args] autorelease];
    
    //else if ([className isEqualToString:@"VideosModule"])
    //    module = [[[VideosModule alloc] initWithDictionary:args] autorelease];
    
    //else if ([className isEqualToString:@"EmergencyModule"])
    //    module = [[[EmergencyModule alloc] initWithDictionary:args] autorelease];
    else if ([className isEqualToString:@"BumpModule"])
        module = [[[BumpModule alloc] initWithDictionary:args] autorelease];
    
    return module;
}

@end
