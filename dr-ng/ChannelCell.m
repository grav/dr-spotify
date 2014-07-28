//
// Created by Mikkel Gravgaard on 25/01/14.
// Copyright (c) 2014 Betafunk. All rights reserved.
//

#import "ChannelCell.h"
#import "PlayerViewController.h"

@implementation ChannelCell {

}

- (id)init {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ReuseId];
    if (self) {
        self.backgroundColor = [UIColor clearColor];

        UIButton *stopButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [stopButton addTarget:nil action:@selector(stop:)
             forControlEvents:UIControlEventTouchUpInside];

        [stopButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [stopButton setTitle:@"◼" forState:UIControlStateNormal];
        [self.contentView addSubview:stopButton];
        [stopButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(stopButton.superview);
            make.right.equalTo(stopButton.superview).offset(-10);
        }];

        RAC(stopButton,hidden) = [[[self rac_signalForSelector:@selector(setSelected:animated:)] map:^id(RACTuple *tuple) {
            return tuple.first;
        }] not];
    }

    return self;
}


- (void)configure:(NSDictionary *)channel {
    self.textLabel.text = channel[kName];
//    self.imageView.image = [UIImage imageWithContentsOfFile:channel.iconLocalURL.absoluteString];
}

@end