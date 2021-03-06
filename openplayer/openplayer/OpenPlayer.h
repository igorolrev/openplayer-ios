//
//  OpusPlayer.h
//  Open Player
//
//  Created by Florin Moisa on 27/05/14.
//  Copyright (c) 2014 Audio Now Digital. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "INativeInterface.h"
#import "PlayerEvents.h"

@class InputStreamConnection;
@class StreamConnection;
@class AudioController;

/* Define internal player states */
typedef enum player_state{
    STATE_READY_TO_PLAY = 0,    // player is ready to play, this is the state used also for Pause
    STATE_PLAYING = 1,          // player is currently playing
    STATE_STOPPED = 2,          // player is currently stopped (not playing)
    STATE_READING_HEADER = 3    // player is currently reading the header
} PlayerState;

/* Define player types , affecting the decoder being used */
typedef enum player_types {
    PLAYER_OPUS = 1,
    PLAYER_VORBIS = 2
} PlayerType;

/* Error codes returned. Made similar to Android implementation */
typedef enum decode_status{
    SUCCESS = 0,                // Everything was a success
    INVALID_HEADER = -1,        // The data is not in the expected header format
    DECODE_ERROR = -2,           // Failed to decode, for some reason
    DATA_ERROR = -3             // When we got a -1 from the input stream, resulting in PLAYING_FAILED
} DecodingStatus;

@interface OpenPlayer : NSObject <INativeInterface, NSStreamDelegate>
{
    int _type, _sampleRate, _channels;      // globals to hold the parameters for the current track
    long _writtenPCMData, _writtenMiliSeconds, _miliSecondsBackup;
    
    PlayerEvents *_playerEvents;            // player events
    InputStreamConnection *inputStreamConnection;
    AudioController *_audio;
    
    long srcSizeInSeconds;
    
    NSCondition *waitPlayCondition;
    
    PlayerState _state;
}

-(id)initWithPlayerHandler:(id<IPlayerHandler>)handler typeOfPlayer:(int)type enableLogs:(BOOL)useLogs;
-(id)initWithPlayerHandler:(id<IPlayerHandler>)handler typeOfPlayer:(int)type ;

-(void)setDataSource:(NSURL *)sourceUrl; // for live streams
-(void)setDataSource:(NSURL *)sourceUrl withSize:(long)sizeInSeconds; // for recorded streams
-(void)play;
-(void)pause;
-(void)stop;
-(void)seekToPercent:(float)percent;

-(BOOL)isReadyToPlay;
-(BOOL)isPlaying;
-(BOOL)isStopped;
-(BOOL)isReadingHeader;

-(void)updatePCMDisplayForArray:(short *)arrayPointer withSize:(int)size;

-(int)convertSamplesToMs:(long)bytes sampleRate:(long)sampleRate channels:(long)channels;
-(int)convertSamplesToMs:(long)bytes;


@property PlayerState state;

@end
