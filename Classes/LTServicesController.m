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

#import "LTServicesController.h"
#import "LTProjectsController.h"
#import "LTOpenSavePerformer.h"
#import "LTProject.h"


@implementation LTServicesController

static id sharedInstance = nil;

+ (LTServicesController *)sharedInstance
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
    }
    return sharedInstance;
}


- (void)insertSelection:(NSPasteboard *)pboard userData:(NSString *)data error:(NSString **)error 
{
	if (![[pboard types] containsObject:NSStringPboardType]) {
		NSBeep();
		return;
	}
	
	if (LTCurrentProject == nil) {
		if ([[[LTProjectsController sharedDocumentController] documents] count] > 0) {
			[[LTProjectsController sharedDocumentController] setCurrentProject:[[LTProjectsController sharedDocumentController] documentForWindow:[[NSApp orderedWindows] objectAtIndex:0]]];
		} else {
			[[LTProjectsController sharedDocumentController] newDocument:nil];
		}
	}
	if (![[LTCurrentDocument valueForKey:@"firstTextView"] readSelectionFromPasteboard:pboard type:NSStringPboardType]) {
		NSBeep();
	}
}


- (void)openSelection:(NSPasteboard *)pboard userData:(NSString *)data error:(NSString **)error 
{
	if (![[pboard types] containsObject:NSStringPboardType]) {
		NSBeep();
		return;
	}
	
	if (LTCurrentProject == nil) {
		if ([[[LTProjectsController sharedDocumentController] documents] count] > 0) {
			[[LTProjectsController sharedDocumentController] setCurrentProject:[[LTProjectsController sharedDocumentController] documentForWindow:[[NSApp orderedWindows] objectAtIndex:0]]];
		} else {
			[[LTProjectsController sharedDocumentController] newDocument:nil];
		}
	}
	
	id document = [LTCurrentProject createNewDocumentWithContents:@""];

	if (![[document valueForKey:@"firstTextView"] readSelectionFromPasteboard:pboard type:NSStringPboardType]) {
		NSBeep();
	}
}


- (void)openFile:(NSPasteboard *)pboard userData:(NSString *)data error:(NSString **)error
{
	if (![[pboard types] containsObject:NSFilenamesPboardType]) {
		NSBeep();
		return;
	}
	
	NSString *path = [[pboard propertyListForType:NSFilenamesPboardType] objectAtIndex:0];
	[LTOpenSave shouldOpen:path withEncoding:0];
}


@end
