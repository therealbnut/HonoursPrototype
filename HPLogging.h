//
//  HPLogging.h
//  Logging
//
//  Created by Andrew Bennett on 15/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "DropboxSDK.h"
#import "DBLoginController.h"

@protocol HPLoggingDelegate;

@interface HPLogging : NSObject<DBSessionDelegate,DBLoginControllerDelegate,DBRestClientDelegate>
{
	DBSession * _session;
	DBRestClient * _restClient;

	UIWindow  * _window;

	NSString * _logName;
	
	id<HPLoggingDelegate> _delegate;
}

+(void) startLogging: (NSString*) logName
		  mainWindow: (UIWindow*) main
			delegate: (id<HPLoggingDelegate>) delegate;

-(void) askToLogin;

+(void) logView: (UIView *) view;
+(NSString*) saveView: (UIView *) view;
+(void) logString: (NSString*) string;

@end

@protocol HPLoggingDelegate <NSObject>

-(void) loggingAuthenticated: (HPLogging*) logging;

@end

