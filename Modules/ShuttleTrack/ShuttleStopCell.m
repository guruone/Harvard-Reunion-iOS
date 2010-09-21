
#import "ShuttleStopCell.h"
#import "ShuttleStop.h"
#import "MITUIConstants.h"

@implementation ShuttleStopCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        // Initialization code
    }
    return self;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {

    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


- (void)dealloc {
    [super dealloc];
}


-(void) setShuttleInfo:(ShuttleStop*)shuttleStop
{
	_shuttleNameLabel.text = shuttleStop.title;
	
	
	NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
	[formatter setDateFormat:@"h:mm a"];
	
	_shuttleTimeLabel.text = [formatter stringFromDate:shuttleStop.nextScheduledDate];

	if (shuttleStop.upcoming) 
	{
		_shuttleStopImageView.image = [UIImage imageNamed:@"shuttle-stop-dot-next.png"] ;
		_shuttleTimeLabel.textColor = SEARCH_BAR_TINT_COLOR;
        _shuttleTimeLabel.font = [UIFont boldSystemFontOfSize:16.0];
		_shuttleNextLabel.text = @"Arriving Next at: ";
		
	}
	else 
	{
		//_shuttleStopImageView.image = [UIImage imageNamed:@"shuttle-stop-dot.png"];
		_shuttleTimeLabel.textColor = [UIColor blackColor];
        _shuttleTimeLabel.font = [UIFont systemFontOfSize:16.0];
		_shuttleNameLabel.frame = CGRectMake(_shuttleNameLabel.frame.origin.x, _shuttleNameLabel.frame.origin.y - 5, _shuttleNameLabel.frame.size.width, _shuttleNameLabel.frame.size.height);
	}
}

@end
