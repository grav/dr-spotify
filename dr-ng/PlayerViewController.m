//
// Created by Mikkel Gravgaard on 21/01/14.
// Copyright (c) 2014 Betafunk. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "PlayerViewController.h"
#import "CocoaLibSpotify.h"
#import "ChannelCell.h"
#import "PlaylistReader.h"
#import "WBSuccessNoticeView.h"
#import "WBErrorNoticeView.h"
#import "BTFSpotify.h"
#include "appkey.c"
#import "PlayerView.h"
#import "PlayerViewModel.h"

#if DEBUG
static NSString *const kPlaylistName = @"RadioSpot-DEBUG";
#else
static NSString *const kPlaylistName = @"RadioSpot";
#endif

#define CREATE_RANDOM_PLAYLIST 0

@interface PlayerViewController () <UITableViewDataSource, UITableViewDelegate>
@property(nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) id<Playlist> playlist;
@property (nonatomic, strong) AVAudioPlayer *spotifyAddingSuccessPlayer;
@property(nonatomic, strong) BTFSpotify *btfSpotify;
@property (nonatomic, strong) PlayerViewModel *viewModel;
@end

@implementation PlayerViewController {

}

- (instancetype)init{
    self = [super init];
    if(self){

        RACSignal *remoteControlSignal = [[self rac_signalForSelector:@selector(remoteControlReceivedWithEvent:)] map:^id(RACTuple *tuple) {
            return tuple.first;
        }];

        [[remoteControlSignal filter:^BOOL(UIEvent *event) {
            return event.subtype == UIEventSubtypeRemoteControlPreviousTrack;
        }] subscribeNext:^(id x) {
            if(self.playlist.currentTrack){
                [self addTrack:self.playlist.currentTrack];
            }
        }];


        self.playlist = [PlaylistReader new]; // TODO - use fallback if it fails

        self.viewModel = [PlayerViewModel new];

        self.btfSpotify = [[BTFSpotify alloc] initWithAppKey:g_appkey size:g_appkey_size];
        self.btfSpotify.presentingViewController = self;


    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor colorWithWhite:0.93 alpha:1];

    RACSignal *currentTrackS = RACObserve(self.playlist, currentTrack);

    UITableView *tableView = [UITableView new];
    tableView.dataSource = self; tableView.delegate = self;
    [self.view addSubview:tableView];
    tableView.frame = self.view.bounds;
    tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    tableView.backgroundColor = [UIColor clearColor];

    PlayerView *playerView = [PlayerView new];
    playerView.frame = CGRectOffset(playerView.frame, 0, self.view.bounds.size.height);
    [self.view addSubview:playerView];

    RAC(playerView,track) = currentTrackS;

    [currentTrackS subscribeNext:^(NSDictionary *track) {
        if(track) {
            [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:@{
                    MPMediaItemPropertyTitle : track[kTitle],
                    MPMediaItemPropertyArtist : track[kArtist],
            }];
        } else {
            [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:nil];
        }
    }];

    RACSignal *talkingToSpotify = RACObserve(self.viewModel, talkingToSpotify);
    RACSignal *hasTrack = [currentTrackS map:^id(id track) {
        return @(track != nil);
    }];

    RACSignal *buttonEnabled = [RACSignal combineLatest:@[talkingToSpotify,hasTrack] reduce:^id(NSNumber *talking,NSNumber *track) {
        return @(track.boolValue && !talking.boolValue);
    }];

    playerView.addToSpotBtn.rac_command = [[RACCommand alloc] initWithEnabled:buttonEnabled
                                                                  signalBlock:^RACSignal *(id input) {
                                                                      [self addTrack:self.playlist.currentTrack];
                                                                      return [RACSignal empty];
                                                                  }];

    playerView.stopBtn.rac_command = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
        [self stop];
        [tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:YES];
        return [RACSignal empty];
    }];

    RAC(playerView.activityIndicatorView,hidden) = [RACSignal combineLatest:@[talkingToSpotify,hasTrack] reduce:^id(NSNumber *talking, NSNumber *track){
        return @(!track.boolValue || !talking.boolValue);
    }];

    [RACObserve(self, player) subscribeNext:^(id x) {
        CGRect frame = playerView.frame;
        CGFloat playerHeight = frame.size.height;
        CGFloat originY = x==nil?self.view.bounds.size.height : self.view.bounds.size.height- playerHeight;
        frame.origin.y = originY;

        UIEdgeInsets insets =  tableView.contentInset;
        insets.bottom = x==nil? 0 : playerHeight;
        [UIView animateWithDuration:0.4 animations:^{
            tableView.contentInset = insets;
            playerView.frame = frame;
        } completion:^(BOOL finished) {
            [tableView scrollToNearestSelectedRowAtScrollPosition:UITableViewScrollPositionNone
                                                         animated:YES];

        }];
    }];
}

#pragma mark tblview

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.viewModel.channels.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ChannelCell *cell = [tableView dequeueReusableCellWithIdentifier:ReuseId];
    if(!cell){
        cell = [ChannelCell new];
    }
    [cell configure:self.viewModel.channels[(NSUInteger) indexPath.row]];
    return cell;
}

- (void)playChannel:(NSDictionary*)channel
{
    self.player = [AVPlayer playerWithURL:[NSURL URLWithString:channel[kUrl]]];
#if DEBUG
    [self startLogging];
#endif

    [self.player play];



    [[[RACObserve(self.player.currentItem, playbackLikelyToKeepUp) throttle:4] ignore:@YES]
            subscribeNext:^(id x) {
                NSLog(@"===== buffer empty- lets restart =====");
                [[WBErrorNoticeView errorNoticeInView:self.navigationController.view title:@"Trying to restart" message:nil] show];

                [self performSelector:@selector(playChannel:) withObject:channel afterDelay:1];
    }];

}

- (void)startLogging {

    [[RACSignal interval:4 onScheduler:[RACScheduler currentScheduler]] subscribeNext:^(id x) {
        NSLog(@"%@",(__bridge NSString *)CMTimeCopyDescription(NULL, self.player.currentTime));
    }];

    [@[@"status", @"rate", @"currentItem", @"error", @"currentTime"] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [[self.player rac_valuesForKeyPath:obj observer:self.player] subscribeNext:^(id x) {
            NSLog(@"%@: %@",obj,x);
        }];
    }];

    [@[@"error", @"status", @"playbackBufferEmpty", @"playbackBufferFull", @"playbackLikelyToKeepUp"] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [[self.player.currentItem rac_valuesForKeyPath:obj
                                              observer:self.player.currentItem] subscribeNext:^(id x) {
            NSLog(@"currentItem %@: %@",obj,x);
        }];
    }];


    [[RACObserve(self.player.currentItem, loadedTimeRanges) map:^id(NSArray *timeranges) {
        CMTimeRange range = [timeranges.firstObject CMTimeRangeValue];
        return @(CMTimeGetSeconds(range.duration));
    }] subscribeNext:^(id x) {
        NSLog(@"duration: %@",x);
    }];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *channel = self.viewModel.channels[(NSUInteger) indexPath.row];
    self.playlist.channel = (Channel) ((NSNumber*)(channel[kChannelId])).integerValue;
    [self playChannel:channel];

}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 65.0f;
}


- (void)stop
{
    [self.player pause];
    self.player = nil;

}

#pragma mark spot

- (void)addTrack:(NSDictionary *)track
{
    self.viewModel.talkingToSpotify = YES;
    NSString *searchQuery = [NSString stringWithFormat:@"%@ %@",track[kArtist],track[kTitle]];
    NSLog(@"searching spotify for '%@'...",searchQuery);


    NSString *playlistName = kPlaylistName;

    #if DEBUG && CREATE_RANDOM_PLAYLIST

    playlistName = [NSString stringWithFormat:@"RS_%d", arc4random()];

    #endif

    RACSignal *playlist = [[self.btfSpotify playlistWithName:playlistName] catch:^RACSignal *(NSError *error) {
        return [[self.btfSpotify createPlaylist:playlistName] flattenMap:^RACStream *(id value) {
            return [self.btfSpotify playlistWithName:playlistName];
        }];
    }];
    RACSignal *trackAdded = [[self.btfSpotify search:searchQuery] flattenMap:^RACStream *(SPSearch *search) {
        return [playlist flattenMap:^RACStream *(SPPlaylist *playlist1) {
            return [self.btfSpotify addItem:search.tracks.firstObject
                                 toPlaylist:playlist1
                                    atIndex:0];
        }];
    }];

    [trackAdded subscribeNext:^(id x) {
        NSString *info = [NSString stringWithFormat:@"Added track to playlist '%@'", playlistName];
        [[WBSuccessNoticeView successNoticeInView:self.navigationController.view title:info] show];
        if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground) {
            NSURL *url = [[NSBundle mainBundle] URLForResource:@"success" withExtension:@"wav"];
            [self playSound:url];
        }
        NSLog(@"added track to playlist");
        self.viewModel.talkingToSpotify = NO;

    } error:^(NSError *error) {
        [[WBErrorNoticeView errorNoticeInView:self.navigationController.view title:@"Problem adding track"
                                      message:[error description]] show];
        if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground) {
            NSURL *url = [[NSBundle mainBundle] URLForResource:@"fail" withExtension:@"wav"];
            [self playSound:url];
        }
        NSLog(@"%@", error);
        self.viewModel.talkingToSpotify = NO;
    }];

}

- (void)playSound:(NSURL *)url {
    NSError *error;
    self.spotifyAddingSuccessPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url
                                                                             error:&error];
    [self.spotifyAddingSuccessPlayer play];
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)event
{
    NSLog(@"event received: %d",event.subtype);
}

- (BOOL)isPlaying {
    return self.player!=nil;
}
@end