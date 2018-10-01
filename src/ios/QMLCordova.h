#import <Cordova/CDV.h>
#import "AppDelegate.h"

@interface QMLCordova : CDVPlugin
- (void)ocr:(CDVInvokedUrlCommand*)command;
@end
