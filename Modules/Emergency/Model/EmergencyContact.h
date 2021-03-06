//
//  EmergencyContact.h
//  Universitas
//
//  Created by Brian Patt on 4/3/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class EmergencyContactsSection;

@interface EmergencyContact : NSManagedObject {
@private
}
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * subtitle;
@property (nonatomic, retain) NSString * formattedPhone;
@property (nonatomic, retain) NSString * dialablePhone;
@property (nonatomic, retain) NSNumber * order;
@property (nonatomic, retain) EmergencyContactsSection * section;

- (NSString *)summary;

@end
