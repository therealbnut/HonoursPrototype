//
//  HPLogging.m
//  Logging
//
//  Created by Andrew Bennett on 15/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "HPLogging.h"

#import <QuartzCore/QuartzCore.h>

NSString * const kConsumerKey    = @"ve9eg6j4qdlu6ev";
NSString * const kConsumerSecret = @"h64mggpv5urg6xw";

HPLogging * gCurrentLoggingSession = nil;

@implementation HPLogging

-(void) createSession
{
	self->_session = [[DBSession alloc] initWithConsumerKey: kConsumerKey
											 consumerSecret: kConsumerSecret];
	[self->_session setDelegate: self];
	[DBSession setSharedSession: self->_session];
    [self->_session release];
}

-(id)initWithLogName: (NSString*) logName
		  mainWindow: (UIWindow *) main
			delegate: (id<HPLoggingDelegate>) delegate
{
	if (self = [super init])
	{
		self->_logName  = [[logName copy] retain];
		self->_window   = main;
		self->_delegate = delegate;
	}
	return self;
}

- (DBRestClient*)restClient
{
    if (self->_restClient == nil)
	{
    	self->_restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
    	[self->_restClient setDelegate: self];
    }
    return self->_restClient;
}

+(void) startLogging: (NSString*) logName
		  mainWindow: (UIWindow *) main
			delegate: (id<HPLoggingDelegate>) delegate
{
	gCurrentLoggingSession = [[HPLogging alloc] initWithLogName: logName
													 mainWindow: main
													   delegate: delegate];
	[gCurrentLoggingSession createSession];
	if (![[DBSession sharedSession] isLinked])
		[gCurrentLoggingSession askToLogin];
}

#pragma mark - Utility

+(NSData*) saveViewAsPDF: (UIView *) view
{
    // Creates a mutable data object for updating with binary data, like a byte array
    NSMutableData *pdfData = [NSMutableData data];

    // Points the pdf converter to the mutable data object and to the UIView to be converted
    UIGraphicsBeginPDFContextToData(pdfData, view.bounds, nil);
    UIGraphicsBeginPDFPage();
    CGContextRef pdfContext = UIGraphicsGetCurrentContext();
    // draws rect to the view and thus this is captured by UIGraphicsBeginPDFContextToData
    [(CALayer*)view.layer renderInContext:pdfContext];
    // remove PDF rendering context
    UIGraphicsEndPDFContext();

	return pdfData;
}

+(NSData*) saveViewAsJPEG: (UIView*) view
{
	CGRect myRect = view.bounds;
	UIGraphicsBeginImageContext(myRect.size);
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	[[UIColor blackColor] set];
	CGContextFillRect(ctx, myRect);
	[view.layer renderInContext: ctx];
	UIImage * image = UIGraphicsGetImageFromCurrentImageContext();
	return UIImageJPEGRepresentation(image, 0.5);
}

-(void) uploadData: (NSData*) data
	  withFilename: (NSString*) filename
{
    // Retrieves the document directories from the iOS device
    NSArray* documentDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask,YES);
	
    NSString* documentDirectory = [documentDirectories objectAtIndex:0];
    NSString* documentDirectoryFilename = [documentDirectory stringByAppendingPathComponent: filename];
	
    // instructs the mutable data object to write its context to a file on disk
    [data writeToFile: documentDirectoryFilename
		   atomically: YES];

	[[self restClient] uploadFile: filename
						   toPath: [NSString stringWithFormat: @"/hp-logging/%@", self->_logName]
						 fromPath: documentDirectoryFilename];
}

-(void) uploadString: (NSString*) string
		withFilename: (NSString*) filename
{
	NSData * data;
	data = [string dataUsingEncoding: NSUTF8StringEncoding];
	[self uploadData: data
		withFilename: filename];
}

+(NSString*) saveView: (UIView *) view
{
	NSMutableString * fname, * full_filename;
	NSData * data;
	
	fname = [NSMutableString stringWithFormat: @"%lf", CFAbsoluteTimeGetCurrent()];
	[fname replaceOccurrencesOfString: @"."	
						   withString: @"_"
							  options: 0
								range: NSMakeRange(0,  [fname length])];
	full_filename = [NSString stringWithFormat: @"screenshot_%@.jpg", fname];
	data = [self saveViewAsJPEG: view];
    // Retrieves the document directories from the iOS device
    NSArray* documentDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask,YES);
	
    NSString* documentDirectory = [documentDirectories objectAtIndex:0];
    NSString* documentDirectoryFilename = [documentDirectory stringByAppendingPathComponent: full_filename];
	
    // instructs the mutable data object to write its context to a file on disk
    [data writeToFile: documentDirectoryFilename
		   atomically: YES];
	return full_filename;
}

+(void) logView: (UIView *) view
{
	NSMutableString * fname, * full_filename;
	NSData * data;

	fname = [NSMutableString stringWithFormat: @"%lf", CFAbsoluteTimeGetCurrent()];
	[fname replaceOccurrencesOfString: @"."	
						   withString: @"_"
							  options: 0
								range: NSMakeRange(0,  [fname length])];
	full_filename = [NSString stringWithFormat: @"screenshot_%@.jpg", fname];
	data = [self saveViewAsJPEG: view];
	[gCurrentLoggingSession uploadData: data
						  withFilename: full_filename];
}
+(void) logString: (NSString*) string
{
	NSMutableString * fname, * full_filename;
	
	fname = [NSMutableString stringWithFormat: @"%lf", CFAbsoluteTimeGetCurrent()];
	[fname replaceOccurrencesOfString: @"."	
						   withString: @"_"
							  options: 0
								range: NSMakeRange(0,  [fname length])];
	full_filename = [NSString stringWithFormat: @"log_%@.txt", fname];
	[gCurrentLoggingSession uploadString: string
							withFilename: full_filename];
}

-(void) askToLogin
{
	DBLoginController* loginController;
	UIViewController * viewController;

	viewController  = [self->_window rootViewController];
	loginController = [[DBLoginController new] autorelease];

	[loginController setDelegate: self];
	[loginController presentFromController: viewController];
}

#pragma mark - Login Delegate

- (void)loginControllerDidLogin:(DBLoginController*)controller
{
    [self->_delegate loggingAuthenticated: self];
}
- (void)loginControllerDidCancel:(DBLoginController*)controller {
	
}

#pragma mark - Session Delegate

- (void)sessionDidReceiveAuthorizationFailure:(DBSession*)session
{
	NSLog(@"Failed to authenticate session!");
	[self askToLogin];
}

#pragma mark - Rest Delegate

- (void) restClient:(DBRestClient *)client uploadFileFailedWithError:(NSError *)error
{
	NSLog(@"upload failed with error: %@", error);
}

@end
