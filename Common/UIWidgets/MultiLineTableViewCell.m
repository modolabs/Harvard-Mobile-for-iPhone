/****************************************************************
 *
 *  Copyright 2010 The President and Fellows of Harvard College
 *  Copyright 2010 Modo Labs Inc.
 *
 *****************************************************************/

#import "MultiLineTableViewCell.h"
#import "MITUIConstants.h"

@implementation MultiLineTableViewCell
@synthesize textLabelNumberOfLines, detailTextLabelNumberOfLines, hasIndex = _hasIndex;

+ (CGFloat)widthForTextLabel:(BOOL)isTextLabel
                   cellStyle:(UITableViewCellStyle)style
                   tableView:(UITableView *)tableView
               accessoryType:(UITableViewCellAccessoryType)accessoryType
                   cellImage:(BOOL)cellImage
                    hasIndex:(BOOL)hasIndex
{
    CGFloat width = tableView.frame.size.width;
    if (tableView.style == UITableViewStyleGrouped) width -= 20.0; // 10px margin either side of table

    width -= 20.0; // 10px padding either side within cell

    switch (style) {
        case UITableViewCellStyleValue2:
        {
            //width -= 10.0; // 10px spacing between text and detailText
            if (isTextLabel) {
                width = floor(width * 0.24);
                if (cellImage) width -= 33.0;
            } else {
                width = floor(width * 0.76);
                switch (accessoryType) {
                    case UITableViewCellAccessoryCheckmark:
                    case UITableViewCellAccessoryDetailDisclosureButton:
                        width -= 20.0;
                        break;
                    case UITableViewCellAccessoryDisclosureIndicator:
                        width -= 15.0;
                        break;
                }
            }
            break;
        }
        case UITableViewCellStyleValue1: // please please just don't make multiline cells with this style
        {
            width -= 10.0; // 10px spacing between text and detailText
            width = floor(width * 0.5);
            if (isTextLabel) {
                switch (accessoryType) {
                    case UITableViewCellAccessoryCheckmark:
                    case UITableViewCellAccessoryDetailDisclosureButton:
                        width -= 10.0;
                        break;
                    case UITableViewCellAccessoryDisclosureIndicator:
                        width -= 15.0;
                        break;
                }
            } else {
                if (cellImage) width -= 33.0;
            }
            break;
        }
        default:
        {
            if (cellImage) width -= 33.0;
            
            switch (accessoryType) {
                case UITableViewCellAccessoryCheckmark:
                case UITableViewCellAccessoryDetailDisclosureButton:
                    width -= 21.0;
                    break;
                case UITableViewCellAccessoryDisclosureIndicator:
                    width -= 33.0;
                    break;
            }
            
            break;
        }
    }
	
	if (hasIndex)
		width -= 15;
	
    return width;
}

+ (CGFloat)heightForLabelWithText:(NSString *)text font:(UIFont *)font width:(CGFloat)width maxLines:(NSInteger)maxLines
{
    CGFloat height;
    if (maxLines == 0) {
        CGSize size = CGSizeMake(width, 2000.0);
        height = [text sizeWithFont:font constrainedToSize:size lineBreakMode:UILineBreakModeWordWrap].height;
    } else if (maxLines == 1) {
        height = [text sizeWithFont:font].height;
    } else {
        height = [text sizeWithFont:font].height;
        CGSize size = CGSizeMake(width, height * maxLines);
        height = [text sizeWithFont:font constrainedToSize:size lineBreakMode:UILineBreakModeWordWrap].height;
    }
    DLog(@"height for label with text %@ and width %.1f is %.1f", text, width, height);
    return height;
}

// TODO: consolidate the following two methods

+ (CGFloat)heightForCellWithStyle:(UITableViewCellStyle)style
                        tableView:(UITableView *)tableView 
                             text:(NSString *)text
                     maxTextLines:(NSInteger)maxTextLines
                       detailText:(NSString *)detailText
                   maxDetailLines:(NSInteger)maxDetailLines
                             font:(UIFont *)font 
                       detailFont:(UIFont *)detailFont 
                    accessoryType:(UITableViewCellAccessoryType)accessoryType
                        cellImage:(BOOL)cellImage
{
    CGFloat textWidth = [MultiLineTableViewCell widthForTextLabel:YES cellStyle:style tableView:tableView accessoryType:accessoryType cellImage:cellImage hasIndex:NO];
    CGFloat detailTextWidth = [MultiLineTableViewCell widthForTextLabel:NO cellStyle:style tableView:tableView accessoryType:accessoryType cellImage:cellImage hasIndex:NO];

    if (font == nil) font = [UIFont fontWithName:STANDARD_FONT size:CELL_STANDARD_FONT_SIZE];
    CGFloat textHeight = [MultiLineTableViewCell heightForLabelWithText:text font:font width:textWidth maxLines:maxTextLines];

    CGFloat detailTextHeight = 0.0;
    if (detailText) {
        if (detailFont == nil) detailFont = [UIFont fontWithName:STANDARD_FONT size:CELL_DETAIL_FONT_SIZE];
        detailTextHeight = [MultiLineTableViewCell heightForLabelWithText:detailText font:detailFont width:detailTextWidth maxLines:maxDetailLines];
    }
    
    CGFloat result;
    if (style == UITableViewCellStyleValue1 || style == UITableViewCellStyleValue2) {
        result = (textHeight > detailTextHeight ? textHeight : detailTextHeight) + 20.0;
    } else {
        result = textHeight + detailTextHeight + 20.0;
    }
    
    return result;
}

+ (CGFloat)heightForCellWithStyle:(UITableViewCellStyle)style
                        tableView:(UITableView *)tableView 
                             text:(NSString *)text
                     maxTextLines:(NSInteger)maxTextLines
                       detailText:(NSString *)detailText
                   maxDetailLines:(NSInteger)maxDetailLines
                             font:(UIFont *)font 
                       detailFont:(UIFont *)detailFont 
                    accessoryType:(UITableViewCellAccessoryType)accessoryType
                        cellImage:(BOOL)cellImage
						 hasIndex:(BOOL)indexPane
{
    CGFloat textWidth = [MultiLineTableViewCell widthForTextLabel:YES cellStyle:style tableView:tableView accessoryType:accessoryType cellImage:cellImage hasIndex:indexPane];
    CGFloat detailTextWidth = [MultiLineTableViewCell widthForTextLabel:NO cellStyle:style tableView:tableView accessoryType:accessoryType cellImage:cellImage hasIndex:indexPane];
	
    if (font == nil) font = [UIFont fontWithName:STANDARD_FONT size:CELL_STANDARD_FONT_SIZE];
    CGFloat textHeight = [MultiLineTableViewCell heightForLabelWithText:text font:font width:textWidth maxLines:maxTextLines];
	
    CGFloat detailTextHeight = 0.0;
    if (detailText) {
        if (detailFont == nil) detailFont = [UIFont fontWithName:STANDARD_FONT size:CELL_DETAIL_FONT_SIZE];
        detailTextHeight = [MultiLineTableViewCell heightForLabelWithText:detailText font:detailFont width:detailTextWidth maxLines:maxDetailLines];
    }
    
    CGFloat result;
    if (style == UITableViewCellStyleValue1 || style == UITableViewCellStyleValue2) {
        result = (textHeight > detailTextHeight ? textHeight : detailTextHeight) + 20.0;
    } else {
        result = textHeight + detailTextHeight + 20.0;
    }
    
    return result;
}

- (void)layoutSubviews {
	[super layoutSubviews]; // this resizes labels to default size
    
    CGFloat heightAdded = 0.0f;
    UITableView *tableView = (UITableView *)self.superview;
    BOOL cellImage = (self.imageView.image != nil);
    CGRect frame;
    
    UITableViewCellAccessoryType accessoryType = self.accessoryType;
    if (accessoryType == UITableViewCellAccessoryNone && self.accessoryView != nil) {
        accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    }
    
    if (textLabelNumberOfLines != 1) {
        self.textLabel.numberOfLines = textLabelNumberOfLines;
        self.textLabel.lineBreakMode = textLabelNumberOfLines == 0 ? UILineBreakModeWordWrap : UILineBreakModeTailTruncation;
        frame = self.textLabel.frame;
        if (frame.origin.y == 0.0) {
            // TODO: find out why this happens with rows in event detail screen
            frame.origin.y = 10.0;
        }
        
        frame.size.width = [MultiLineTableViewCell widthForTextLabel:YES cellStyle:_style tableView:tableView accessoryType:accessoryType cellImage:cellImage hasIndex:_hasIndex];
        frame.size.height = [MultiLineTableViewCell heightForLabelWithText:self.textLabel.text
                                                                      font:self.textLabel.font
                                                                     width:frame.size.width
                                                                  maxLines:self.textLabel.numberOfLines];
        heightAdded = frame.size.height - self.textLabel.frame.size.height;
        self.textLabel.frame = frame;
    }
    
    if (self.detailTextLabel.text && detailTextLabelNumberOfLines != 1) {
        self.detailTextLabel.numberOfLines = detailTextLabelNumberOfLines;
        self.detailTextLabel.lineBreakMode = detailTextLabelNumberOfLines == 0 ? UILineBreakModeWordWrap : UILineBreakModeTailTruncation;
        frame = self.detailTextLabel.frame;
        if (_style == UITableViewCellStyleSubtitle)
            frame.origin.y += heightAdded;
        frame.size.width = [MultiLineTableViewCell widthForTextLabel:NO cellStyle:_style tableView:tableView accessoryType:accessoryType cellImage:cellImage hasIndex:_hasIndex];
        frame.size.height = [MultiLineTableViewCell heightForLabelWithText:self.detailTextLabel.text
                                                                      font:self.detailTextLabel.font
                                                                     width:frame.size.width
                                                                  maxLines:self.detailTextLabel.numberOfLines];
        self.detailTextLabel.frame = frame;
        
        
        // for cells with detail text only...
        // if the OS is more aggressive with accessory sizes,
        // it will make the text narrower and taller
        // than we make it, and recenter the labels within the cell.
        // so we re-recenter the frame based on its actual size
        CGFloat innerHeight = self.detailTextLabel.frame.origin.y + self.detailTextLabel.frame.size.height - self.textLabel.frame.origin.y;
        frame = self.textLabel.frame;
        frame.origin.y = floor((self.frame.size.height - innerHeight) / 2);
        heightAdded = frame.origin.y - self.textLabel.frame.origin.y;
        self.textLabel.frame = frame;
        
        frame = self.detailTextLabel.frame;
        frame.origin.y += heightAdded;
        self.detailTextLabel.frame = frame;
    }
    if (self.detailTextLabel.text && 
        (self.accessoryView != nil)) {
        // If we have a single line detailTextLabel with an accessory view, we need to bring in
        // the right margin to make sure the text doesn't touch the accessory image.
        CGRect detailTextFrame = self.detailTextLabel.frame;
        self.detailTextLabel.frame = 
        CGRectMake(detailTextFrame.origin.x, detailTextFrame.origin.y, 
                   detailTextFrame.size.width - 2, detailTextFrame.size.height);
    }
    
    /*
    if (self.textLabel.frame.size.height > 0) {
        NSLog(@"margin: %.1f, height: %.1f, %.1f x %.1f; detail: %.1f x %.1f",
              self.textLabel.frame.origin.y,
              self.frame.size.height,
              self.textLabel.frame.size.width,
              self.textLabel.frame.size.height,
              self.detailTextLabel.frame.size.width,
              self.detailTextLabel.frame.size.height);
    }
    */
    
	// make sure any extra views are drawn on top of standard testLabel and detailTextLabel
	NSMutableArray *extraSubviews = [NSMutableArray arrayWithCapacity:[self.contentView.subviews count]];
	for (UIView *aView in self.contentView.subviews) {
		if (aView != self.textLabel && aView != self.detailTextLabel) {
			[extraSubviews addObject:aView];
			[aView removeFromSuperview];
		}
	}
	for (UIView *aView in extraSubviews) {
        // TODO: generalize this more if the following assumption no longer holds
        // right now we assume extra views are on the same line as the detailTextLabel
        // (true for stellar announcements and events calendar)
        CGRect frame = aView.frame;
        frame.origin.y = self.detailTextLabel.frame.origin.y;
        aView.frame = frame;
		[self.contentView addSubview:aView];
	}
}

- (id) initWithStyle: (UITableViewCellStyle)cellStyle reuseIdentifier: (NSString *)reuseIdentifier {
    if(self = [super initWithStyle:cellStyle reuseIdentifier:reuseIdentifier]) {		
        _style = cellStyle;
        textLabelNumberOfLines = 0;
        detailTextLabelNumberOfLines = 0;
    }
    return self;
}

- (void)dealloc {
    [super dealloc];
}


@end

