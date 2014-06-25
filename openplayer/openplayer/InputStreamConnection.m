//
//  InputStreamConnection.m
//  openplayer
//
//  Created by Florin Moisa on 24/06/14.
//  Copyright (c) 2014 AudioNowDigital. All rights reserved.
//

#import "InputStreamConnection.h"

@implementation InputStreamConnection

-(id)initWithUrl:(NSURL *)url
{
    if (self = [super init]) {
        
        srcSize = -1;
        
        sourceUrl = url;
        
        BOOL ret = YES;
        if ([sourceUrl isFileURL]) {
            NSLog(@"Initialize stream from file url: %@", url);
            ret = [self initFileConnection];
        } else {
            NSLog(@"Initialize stream from network url: %@", url);
            ret = [self initSocketConnection];
        }
        
        if (!ret) {
            self = nil;
        }
    }
    return self;
}

-(BOOL)openStream:(NSStream *)stream {
    [stream open];
    
    double startTime = [NSDate timeIntervalSinceReferenceDate] * 1000.0; // we want it in ms
    
    while ((long)([NSDate timeIntervalSinceReferenceDate] * 1000.0 - startTime) < kTimeout) {
        
        NSLog(@"Stream state: %d", [stream streamStatus]);
        
        switch ([stream streamStatus]) {
            case NSStreamStatusOpen:
                return YES;
                
            case NSStreamStatusClosed:
            case NSStreamStatusError:
                return NO;
                
            default: break;
        }
        
        [NSThread sleepForTimeInterval:0.1];
    }
    
    return NO;
}

- (BOOL)initSocketConnection
{
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    
    int port = [sourceUrl port] > 0 ? [[sourceUrl port] intValue] : 80;
    
    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)[sourceUrl host], port, &readStream, &writeStream);
    
    inputStream = (__bridge_transfer NSInputStream *)readStream;
    outputStream = (__bridge_transfer NSOutputStream *)writeStream;
    
    if (![self openStream:outputStream]) {
        NSLog(@"Error opening output stream ! %@", [outputStream streamError]);
        return NO;
    }
    
    NSLog(@"output socket stream opened");
       
    // do a HTTP Get on the resource we want
    NSString * str = [NSString stringWithFormat:@"GET %@ HTTP/1.0\r\n\r\n", [sourceUrl path]];
    NSLog(@"Do get for: %@", str);
    const uint8_t * rawstring = (const uint8_t *)[str UTF8String];
    [outputStream write:rawstring maxLength:strlen((const char *)rawstring)];
    // leave the outputstream open
    
    if (![self openStream:inputStream]) {
        NSLog(@"Error opening input stream !");
        return NO;
    }
    
    NSLog(@"input socket stream opened");
    
    // Check HTTP response code (must be 200!) and then read HTTP Header and store useful details
    NSMutableString *strHeader = [NSMutableString string];
    NSInteger result;
    int eoh = 0;
    uint8_t ch;
    while((result = [inputStream read:&ch maxLength:1]) != 0) {
        if(result > 0) {
            // add data to our string
            [strHeader appendFormat:@"%c", ch];
            // check ending condition
            if (ch == '\r' || ch == '\n') eoh ++;
            else if (eoh > 0) eoh --;
            // if we have the header ending characters, stop
            if (eoh == 4) {
                NSLog(@"HTTP Header received:%@", strHeader);
                return YES;

            }
            // if there is no header, quit
            if (eoh > 1000) {
                NSLog(@"No HTTP Header found");
                return NO;
            }
        } else {
            NSLog(@"Error %@", [inputStream streamError]);
            return NO;
        }
    }
    // Check header data
    
    return YES;
}

-(BOOL)skip:(long)offset {
   // if (offset > srcSize) return NO;
    
    if ([outputStream streamStatus] != NSStreamStatusOpen ) return NO;
    
    if ([sourceUrl isFileURL]) {
        // do a skip on file handler
    } else {
        // do a HTTP Get on the resource we want
        NSString * str = [NSString stringWithFormat:@"GET %@ HTTP/1.0\r\nRange: bytes=%ld-%ld\r\n\r\n", [sourceUrl path], offset,offset*2];
        NSLog(@"SKIP Get: %@", str);

        const uint8_t * rawstring = (const uint8_t *)[str UTF8String];
        [outputStream write:rawstring maxLength:strlen((const char *)rawstring)];
    }
    return YES;
}

- (BOOL)initFileConnection
{
    inputStream = [[NSInputStream alloc] initWithURL:sourceUrl];
    
    if (![self openStream:inputStream]) {
        NSLog(@"Error opening input stream !");
        return NO;
    }
    
    return inputStream != nil;
}

-(long)readData:(uint8_t *)buffer maxLength:(NSUInteger) length
{
    
    return [inputStream read:buffer maxLength:length];
    
}

-(void)closeStream
{
    [outputStream close];
    [inputStream close];
    
    outputStream = nil;
    inputStream = nil;
}


@end