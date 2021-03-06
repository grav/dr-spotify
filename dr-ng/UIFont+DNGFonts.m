//
// Created by Mikkel Gravgaard on 31/07/14.
// Copyright (c) 2014 Betafunk. All rights reserved.
//

#import "UIFont+DNGFonts.h"


@implementation UIFont (DNGFonts)

+ (instancetype)titleName {
    return [UIFont fontWithName:@"AvenirNext-DemiBold" size:20.0f];
}

+ (instancetype)channelName {
    return [UIFont fontWithName:@"AvenirNext-DemiBold" size:18.0f];
}

+ (instancetype)nowPlaying {
    return [UIFont fontWithName:@"AvenirNext-Regular" size:13.0f];
}

+ (instancetype)songTitle {
    return [UIFont fontWithName:@"AvenirNext-DemiBold" size:16.0f];
}

+ (instancetype)artist {
    return [UIFont fontWithName:@"AvenirNext-Regular" size:12.0f];
}

+ (instancetype)buttonFont {
    return [UIFont fontWithName:@"AvenirNext-DemiBold" size:16.0f];
}

+ (instancetype)messageFont {
    return [UIFont systemFontOfSize:14.0f];
}

@end