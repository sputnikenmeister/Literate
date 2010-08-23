/*
Literate version 1.0, August 2010
Copyright 2010 Ryan Walklin

Based on Smultron version 3.6b1, 2009-09-12
Written by Peter Borg, pgw3@mac.com
Find the latest version at http://smultron.sourceforge.net

Copyright 2004-2009 Peter Borg
 
Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 
http://www.apache.org/licenses/LICENSE-2.0
 
Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
*/

#import "LTStandardHeader.h"

#import "LTMainController.h"
#import "LTPreferencesController.h"
#import "LTTextMenuController.h"
#import "LTFileMenuController.h"
#import "LTBasicPerformer.h"
#import "LTVariousPerformer.h"
#import "LTFontTransformer.h"

#define THISVERSION 0.01

@interface LTMainController (Private)

-(NSTimeInterval)timeIntervalForAutosaveIndex:(NSInteger)index;
-(void)setAutosaveTimerForTimeInterval:(NSTimeInterval)interval;
-(void)autosaveTimerFireAction:(NSTimer *)timer;

@end


@implementation LTMainController

@synthesize isInFullScreenMode, singleDocumentWindowWasOpenBeforeEnteringFullScreen, operationQueue;

static id sharedInstance = nil;

+ (LTMainController *)sharedInstance
{
	if (sharedInstance == nil) { 
		sharedInstance = [[self alloc] init];
	}

	return sharedInstance;
} 


- (id)init 
{
	if (sharedInstance == nil) {
        sharedInstance = [super init];
		
		operationQueue = [[NSOperationQueue alloc] init];
    }
    return sharedInstance;
}


+ (void)initialize
{
	SInt32 systemVersion;
	if (Gestalt(gestaltSystemVersion, &systemVersion) == noErr) {
		if (systemVersion < 0x1060) {
			[NSApp activateIgnoringOtherApps:YES];
			[LTVarious alertWithMessage:[NSString stringWithFormat:NSLocalizedStringFromTable(@"You need %@ or later to run this version of Literate", @"Localizable3", @"You need %@ or later to run Literate"), @"Mac OS X 10.6 Snow Leopard"] informativeText:NSLocalizedStringFromTable(@"Try Smultron (http://smultron.sourceforge.net) if you are running an earlier Mac OS X system", @"Localizable3", @"Go to the web site (http://smultron.sourceforge.net) to download another version for an earlier Mac OS X system") defaultButton:OK_BUTTON alternateButton:nil otherButton:nil];
			
			[NSApp terminate:nil];
		}
	}
	
	[LTBasic insertFetchRequests];
	
	[[LTPreferencesController sharedInstance] setDefaults];	
			
	NSValueTransformer *fontTransformer = [[LTFontTransformer alloc] init];
    [NSValueTransformer setValueTransformer:fontTransformer forName:@"FontTransformer"];
	
}


- (void)awakeFromNib
{
	// If the application crashed so these weren't removed, remove them now
	[LTBasic removeAllObjectsForEntity:@"Document"];
	[LTBasic removeAllObjectsForEntity:@"Encoding"];
	[LTBasic removeAllObjectsForEntity:@"SyntaxDefinition"];
	[LTBasic removeAllObjectsForEntity:@"Project"];
	
	[LTVarious insertTextEncodings];
	[LTVarious insertSyntaxDefinitions];
	[LTVarious insertDefaultSnippets];
	[LTVarious insertDefaultCommands];
	
	[[LTTextMenuController sharedInstance] buildSyntaxDefinitionsMenu];
	[[LTTextMenuController sharedInstance] buildEncodingsMenus];
	
	isInFullScreenMode = NO;
	
	[LTVarious updateCheckIfAnotherApplicationHasChangedDocumentsTimer];
	
	// enable autosave
	[[NSUserDefaultsController sharedUserDefaultsController] addObserver:self 
															  forKeyPath:@"values.AutosaveInterval" 
																 options:NSKeyValueObservingOptionNew 
																 context:@"AutosaveIntervalChanged"];
	
	NSTimeInterval interval = [self timeIntervalForAutosaveIndex:[[LTDefaults valueForKey:@"AutosaveInterval"] integerValue]];
	[self setAutosaveTimerForTimeInterval:interval];
}

#pragma mark -
#pragma mark Autosave

// autosave - 1, 2, 5, 10, 30
-(NSTimeInterval)timeIntervalForAutosaveIndex:(NSInteger)index
{
	NSInteger timeInterval = -1;
	switch (index)
	{
		case 0:
			timeInterval = 60;
			break;
		case 1:
			timeInterval = 120;
			break;
		case 2:
			timeInterval = 300;
			break;
		case 3:
			timeInterval = 600;
			break;
		case 4:
			timeInterval = 1800;
			break;
		default:
			timeInterval = 300;
			break;
	}
	return timeInterval;
}

-(void)setAutosaveTimerForTimeInterval:(NSTimeInterval)interval
{
	if (_autosaveTimer)
	{
		[_autosaveTimer invalidate];
		_autosaveTimer = nil;
	}
	_autosaveTimer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(autosaveTimerFireAction:) userInfo:nil repeats:YES];
}

-(void)autosaveTimerFireAction:(NSTimer*)timer
{
	if ([[LTDefaults valueForKey:@"AutosaveEnabled"] integerValue] == YES)
	{
		[[LTFileMenuController sharedInstance] autosaveAllAction:self];
	}
}

#pragma mark -
#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([(NSString *)context isEqualToString:@"AutosaveIntervalChanged"]) 
	{
		NSTimeInterval interval = [self timeIntervalForAutosaveIndex:[[LTDefaults valueForKey:@"AutosaveInterval"] integerValue]];
		[self setAutosaveTimerForTimeInterval:interval];
	}
	else
	{
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

@end
