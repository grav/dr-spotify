//
// Created by Mikkel Gravgaard on 18/09/14.
// Copyright (c) 2014 Betafunk. All rights reserved.
//

#import "SpotifyButton.h"
#import "MASConstraintMaker+Self.h"
#import "UIActivityIndicatorView+BTFAdditions.h"

@interface SpotifyButton ()
@property (nonatomic, strong) UIActivityIndicatorView* activityIndicatorView;
@property(nonatomic, strong) UIImageView *backgroundImageView;
@property (nonatomic, strong) UIImageView *notesImageView;
@property (nonatomic, strong) UIImageView *actionImageView;
@end

@implementation SpotifyButton {

}

- (instancetype)init {
    if (!(self = [super init])) return nil;


    self.backgroundImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Images/empty_btn"]];
    [self addSubview:self.backgroundImageView];
    [self.backgroundImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(make.superview);
    }];

    self.notesImageView = [UIImageView new];
    RAC(self.notesImageView,image) = [RACObserve(self, enabled) map:^id(NSNumber *n) {
        return n.boolValue?[UIImage imageNamed:@"Images/notes"] : [UIImage imageNamed:@"Images/unavail"];
    }];

    [self addSubview:self.notesImageView];
    [self.notesImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(make.superview).offset(-1);
    }];

    RAC(self, alpha) = [RACObserve(self, highlighted) map:^id(NSNumber *n) {
        return @(n.boolValue ? 0.4 : 1);
    }];

    self.activityIndicatorView = [UIActivityIndicatorView new];
    self.activityIndicatorView.color = [UIColor colorWithRed:122/255.0f green:170/255.0f
                                                                blue:64/255.0f alpha:1.0f];
    self.activityIndicatorView.hidesWhenStopped = YES;
    [self addSubview:self.activityIndicatorView];
    [self.activityIndicatorView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(make.superview);
    }];
    [self.activityIndicatorView startAnimating];

    RAC(self.activityIndicatorView,animate) = RACObserve(self, working);

    RAC(self.notesImageView,hidden) = RACObserve(self,working);

    self.actionImageView = [UIImageView new];
    [self addSubview:self.actionImageView];
    [self.actionImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(make.superview);
    }];

    return self;
}

- (void)showStatus:(ButtonStatus)status
{
    UIImage *image;
    switch (status){

        case ButtonStatusSuccess:
            image = [UIImage imageNamed:@"Images/success"];
            break;
        case ButtonStatusFail:
            image = [UIImage imageNamed:@"Images/fail"];
            break;
        case ButtonStatusNotFound:
            image = [UIImage imageNamed:@"Images/notfound"];
            break;
    }
    self.actionImageView.image = image;
    [self brieflyShowStatus];

}

- (void)brieflyShowStatus {
    self.actionImageView.alpha = 0;
    self.notesImageView.alpha = 0;
    [UIView animateWithDuration:0.2 animations:^{
        self.actionImageView.alpha = 1;
    }                completion:^(BOOL finished) {
        [UIView animateWithDuration:0.2 delay:3
                            options:0 animations:^{
                    self.notesImageView.alpha = 1;
                    self.actionImageView.alpha = 0;
                }
                         completion:nil];
    }];
}


@end