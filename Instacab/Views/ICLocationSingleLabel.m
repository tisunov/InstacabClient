//
//  ICLocationSingleLabel.m
//  InstaCab
//
//  Created by Pavel Tisunov on 26/04/14.
//  Copyright (c) 2014 Bright Stripe. All rights reserved.
//

#import "ICLocationSingleLabel.h"
#import "UIView+Positioning.h"

@implementation ICLocationSingleLabel {
    UILabel *_addressLabel;
    UILabel *_nameLabel;
    UIView *_separatorLine;
    UIView *_verticalLine;
    UIImageView *_imageView;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor whiteColor];
        
        _imageView = [[UIImageView alloc] initWithFrame:CGRectMake(16.0, self.frame.size.height / 2 - 12.0 / 2, 12.0, 12.0)];
        [self addSubview:_imageView];
        
        _addressLabel = [[UILabel alloc] initWithFrame:CGRectMake(37.0, [self addressLabelCenterY], 320 - 44.0, 21.0)];
        _addressLabel.textColor = [UIColor darkGrayColor];
        _addressLabel.font = [UIFont systemFontOfSize:14.0];
        _addressLabel.adjustsFontSizeToFitWidth = YES;
        _addressLabel.minimumScaleFactor = 0.6;
        [self addSubview:_addressLabel];

        _nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(37.0, 4.0, 320 - 44.0, 21.0)];
        _nameLabel.adjustsFontSizeToFitWidth = YES;
        _nameLabel.font = [UIFont systemFontOfSize:16.0];
        _nameLabel.minimumScaleFactor = 0.6;
        _nameLabel.hidden = YES;
        [self addSubview:_nameLabel];
        
        _separatorLine = [[UIView alloc] initWithFrame:CGRectMake(0, frame.size.height, frame.size.width, 1)];
        _separatorLine.backgroundColor = [UIColor colorWithRed:0.89 green:0.89 blue:0.89 alpha:1];
        [self addSubview:_separatorLine];
        
        _verticalLine = [[UIView alloc] initWithFrame:CGRectMake(_imageView.centerX - 0.5, _imageView.y + _imageView.height - 1.0, 1, self.height / 2 - _imageView.height / 2 + 2)];
        _verticalLine.backgroundColor = [UIColor colorWithRed:51/255.0 green:153/255.0 blue:0 alpha:1];
        [self addSubview:_verticalLine];
    }
    return self;
}

-(float)addressLabelCenterY {
    return self.frame.size.height / 2 - 21 / 2;
}

-(void)setType:(ICLocationLabelType)type {
    switch (type) {
        case ICLocationLabelTypePickup:
            _imageView.image = [UIImage imageNamed:@"fare_estimate_pickup_icon"];
            [_separatorLine removeFromSuperview];
            break;
            
        case ICLocationLabelTypeDropoff:
            _imageView.image = [UIImage imageNamed:@"fare_estimate_dropoff_icon"];
            _verticalLine.y = 0;
            _verticalLine.backgroundColor = [UIColor colorWithRed:188/255.0 green:0/255.0 blue:5/255.0 alpha:1];
            break;
    }
}

-(void)setLocation:(ICLocation *)location {
    _location = location;
    
    if (location.name.length != 0) {
        _nameLabel.text = location.name;
        _nameLabel.hidden = NO;
        
        _addressLabel.text = [location formattedAddressWithCity:YES country:NO];
        _addressLabel.font = [UIFont systemFontOfSize:12.0];
        _addressLabel.y = 22.0;
    }
    else {
        _nameLabel.hidden = YES;

        _addressLabel.text = [location formattedAddressWithCity:YES country:NO];
        _addressLabel.font = [UIFont systemFontOfSize:14.0];
        _addressLabel.y = [self addressLabelCenterY];

    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
