//
//  ExampleTableViewCell.m
//  HMCImageCacheExample
//
//  Created by Chuong Huynh on 3/31/18.
//  Copyright © 2018 Chuong Huynh. All rights reserved.
//

#import "ExampleTableViewCell.h"

@implementation ExampleTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    self.imageView.autoresizingMask = UIViewAutoresizingNone;
    self.imageView.clipsToBounds = YES;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    //[super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
