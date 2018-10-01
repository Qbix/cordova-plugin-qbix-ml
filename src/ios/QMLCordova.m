#import "QMLCordova.h"
#import <Cordova/CDV.h>
#import "AppDelegate.h"
#import "Firebase.h"

@implementation QMLCordova

- (void)pluginInitialize {
    NSLog(@"Starting Firebase plugin");
}

+(FIRVisionDetectorImageOrientation) visionImageOrientation:(UIImageOrientation) imageOrientation {
    switch (imageOrientation) {
            case UIImageOrientationUp:
                return FIRVisionDetectorImageOrientationTopLeft;
            case UIImageOrientationDown:
                return FIRVisionDetectorImageOrientationBottomRight;
            case UIImageOrientationLeft:
                return FIRVisionDetectorImageOrientationLeftBottom;
            case UIImageOrientationRight:
                return FIRVisionDetectorImageOrientationRightTop;
            case UIImageOrientationUpMirrored:
                return FIRVisionDetectorImageOrientationTopRight;
            case UIImageOrientationDownMirrored:
                return FIRVisionDetectorImageOrientationBottomLeft;
            case UIImageOrientationLeftMirrored:
                return FIRVisionDetectorImageOrientationLeftTop;
            case UIImageOrientationRightMirrored:
                return FIRVisionDetectorImageOrientationRightBottom;
    }
}

- (void) ocr:(CDVInvokedUrlCommand*) command {
    NSString *imageString = [command.arguments objectAtIndex:0];
    BOOL isCloud = [[command.arguments objectAtIndex:1] boolValue];
    
    if(imageString == nil || ![imageString isKindOfClass:[NSString class]]) {
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Image has bad format"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
    UIImage *image = nil;
    if([imageString containsString:@"file://"]) {
        NSString *convertedImage = [imageString stringByReplacingOccurrencesOfString:@"file://" withString:@""];
        image = [UIImage imageWithContentsOfFile:convertedImage];
    } else {
        image = [UIImage imageWithData:[[NSData alloc]initWithBase64EncodedString:imageString options:NSDataBase64DecodingIgnoreUnknownCharacters]];
    }
    if(image == nil) {
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Image has bad format"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        return;
    }
    
    
    FIRVision *vision = [FIRVision vision];
    
    FIRVisionTextRecognizer *textRecognizer = [vision onDeviceTextRecognizer];
    if(isCloud) {
        textRecognizer =[vision cloudTextRecognizer];
    }
    
    FIRVisionImageMetadata *imageMetadata = [[FIRVisionImageMetadata alloc] init];
    imageMetadata.orientation = [QMLCordova visionImageOrientation:([image imageOrientation])];
    
    FIRVisionImage *visionImage = [[FIRVisionImage alloc] initWithImage:image];
    [visionImage setMetadata:imageMetadata];

    [self process:visionImage withTextRecognizer:textRecognizer andCallback:^(NSMutableArray<NSArray<NSDictionary*>*> *results, NSError *resultError) {
        if(resultError) {
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:resultError.localizedDescription];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        } else {
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:results];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }
    }];
    
}

-(void) process:(FIRVisionImage*) visionImage withTextRecognizer:(FIRVisionTextRecognizer*) textRecognizer andCallback:(void (^)(NSMutableArray<NSArray<NSDictionary*>*> *results, NSError* resultError)) callback {
    [textRecognizer processImage:visionImage completion:^(FIRVisionText * _Nullable text, NSError * _Nullable error) {
        if(error != nil || text == nil) {
            if(error == nil) {
                error = [NSError errorWithDomain:@"Text is nil" code:0 userInfo:nil];
            }
            callback(nil, error);
            return;
        }
        
        NSMutableArray<NSArray<NSDictionary*>*> *results = [NSMutableArray array];
        for(FIRVisionTextBlock *block in text.blocks) {
            NSMutableArray<NSDictionary*> *lineArray = [NSMutableArray array];
            for(FIRVisionTextLine *line in block.lines) {
                
                NSMutableArray *cornerPoints = [NSMutableArray array];
                for(NSValue *point in line.cornerPoints) {
                    [cornerPoints addObject:@{
                                        @"x": @([point CGPointValue].x),
                                        @"y": @([point CGPointValue].y)
                                        }];
                }
                
                NSDictionary *result = @{
                                         @"text":line.text,
                                         @"language": (line.recognizedLanguages.lastObject != nil) ? line.recognizedLanguages.lastObject.languageCode : @"unknown",
                                         @"cornerPoints": cornerPoints
                                         };
                [lineArray addObject:result];
            }
            [results addObject:lineArray];
        }
        
        callback(results, nil);
    }];
}
@end
