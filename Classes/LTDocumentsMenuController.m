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

#import "LTDocumentsMenuController.h"
#import "LTProjectsController.h"
#import "LTProject.h"

@implementation LTDocumentsMenuController

static id sharedInstance = nil;

+ (LTDocumentsMenuController *)sharedInstance
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


- (void)awakeFromNib
{
	[documentsMenu setDelegate:self];
}


- (IBAction)nextDocumentAction:(id)sender
{
	NSInteger currentDocument = [[LTCurrentProject documentsArrayController] selectionIndex];
	if (currentDocument + 2 > [[LTCurrentProject documents] count]) {
		[[LTCurrentProject documentsArrayController] setSelectedObjects:[NSArray arrayWithObject:[[[LTCurrentProject documentsArrayController] arrangedObjects] objectAtIndex:0]]];
	} else {
		[[LTCurrentProject documentsArrayController] setSelectedObjects:[NSArray arrayWithObject:[[[LTCurrentProject documentsArrayController] arrangedObjects] objectAtIndex:(currentDocument + 1)]]];
	}
}


- (IBAction)previousDocumentAction:(id)sender
{
	NSInteger currentDocument = [[LTCurrentProject documentsArrayController] selectionIndex];
	if (currentDocument == 0) {
		[[LTCurrentProject documentsArrayController] setSelectedObjects:[NSArray arrayWithObject:[[[LTCurrentProject documentsArrayController] arrangedObjects] objectAtIndex:[[LTCurrentProject documents] count] - 1]]];
	} else {
		[[LTCurrentProject documentsArrayController] setSelectedObjects:[NSArray arrayWithObject:[[[LTCurrentProject documentsArrayController] arrangedObjects] objectAtIndex:(currentDocument - 1)]]];
	}
}


- (void)buildDocumentsMenu
{
	NSMenuItem *menuItem;
	NSArray *array = [documentsMenu itemArray];
	for (menuItem in array) {
		if ([menuItem action] != @selector(nextDocumentAction:) && [menuItem action] != @selector(previousDocumentAction:) && [menuItem isSeparatorItem] == NO) {
			[documentsMenu removeItem:menuItem];
		}
	}
	
	array = [[LTCurrentProject documentsArrayController] arrangedObjects];

	NSInteger index = 1;
	for (id document in array) {
		if (index < 10) {
			menuItem = [[NSMenuItem alloc] initWithTitle:[document valueForKey:@"name"] action:@selector(changeSelectedDocument:) keyEquivalent:[[NSNumber numberWithUnsignedShort:index] stringValue]];
		} else if (index == 10) {
			menuItem = [[NSMenuItem alloc] initWithTitle:[document valueForKey:@"name"] action:@selector(changeSelectedDocument:) keyEquivalent:@"0"];
		} else {
			menuItem = [[NSMenuItem alloc] initWithTitle:[document valueForKey:@"name"] action:@selector(changeSelectedDocument:) keyEquivalent:@""];
		}

		[menuItem setTarget:self];
		[menuItem setRepresentedObject:document];
		[documentsMenu insertItem:menuItem atIndex:index + 2];
		index++;
	}

	array = [[LTProjectsController sharedDocumentController] documents];
	for (id project in array) {
		if (project == LTCurrentProject) {
			continue;
		}
		NSMenu *menu;
		if ([project valueForKey:@"name"] == nil) {
			menu = [[NSMenu alloc] initWithTitle:UNTITLED_PROJECT_NAME];
		} else {
			menu = [[NSMenu alloc] initWithTitle:[project valueForKey:@"name"]];
		}
		
		NSEnumerator *documentsEnumerator = [[[(LTProject *)project documents] allObjects] reverseObjectEnumerator];
		for (id document in documentsEnumerator) {
			menuItem = [[NSMenuItem alloc] initWithTitle:[document valueForKey:@"name"] action:@selector(changeSelectedDocument:) keyEquivalent:@""];
			[menuItem setTarget:self];
			[menuItem setRepresentedObject:document];
			[menu insertItem:menuItem atIndex:0];
		}
		
		NSMenuItem *subMenuItem = [[NSMenuItem alloc] initWithTitle:[menu title] action:nil keyEquivalent:@""];
		[subMenuItem setSubmenu:menu];
		[documentsMenu addItem:subMenuItem];
	}

}


- (void)changeSelectedDocument:(id)sender
{
	[[LTProjectsController sharedDocumentController] selectDocument:[sender representedObject]];
}


- (BOOL)validateMenuItem:(NSMenuItem *)anItem
{
	BOOL enableMenuItem = YES;
	if ([[LTCurrentProject documents] count] < 2) {
		if ([anItem action] == @selector(nextDocumentAction:) || [anItem action] == @selector(previousDocumentAction:)) { // Next and Previous document
			enableMenuItem = NO;
		}
	}
	
	return enableMenuItem;
}


- (void)menuNeedsUpdate:(NSMenu *)menu
{
	[self buildDocumentsMenu];
}
@end
