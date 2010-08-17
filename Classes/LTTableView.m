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

#import "LTTableView.h"
#import "LTSnippetsController.h"
#import "LTCommandsController.h"
#import "LTToolsMenuController.h"
#import "LTProjectsController.h"
#import "LTProject.h"


@implementation LTTableView




- (void)keyDown:(NSEvent *)event
{
	if (self == [[LTCommandsController sharedInstance] commandCollectionsTableView] || self == [[LTCommandsController sharedInstance] commandsTableView] || self == [[LTSnippetsController sharedInstance] snippetCollectionsTableView] || self == [[LTSnippetsController sharedInstance] snippetsTableView] || self == [LTCurrentProject documentsTableView]) {
	
		unichar key = [[event charactersIgnoringModifiers] characterAtIndex:0];
		NSInteger keyCode = [event keyCode];
		NSUInteger flags = ([event modifierFlags] & 0x00FF);
		
		if ((key == NSDeleteCharacter || keyCode == 0x75) && flags == 0) { // 0x75 is forward delete 
			if ([self selectedRow] == -1) {
				NSBeep();
			} else {
				
				// Snippet collection
				if (self == [[LTSnippetsController sharedInstance] snippetCollectionsTableView]) {
					
					id collection = [[[[LTSnippetsController sharedInstance] snippetCollectionsArrayController] selectedObjects] objectAtIndex:0];
					NSMutableSet *snippetsToDelete = [collection mutableSetValueForKey:@"snippets"];
					if ([snippetsToDelete count] == 0) {
						[[LTSnippetsController sharedInstance] performDeleteCollection];
					} else {
						NSString *title = [NSString stringWithFormat:WILL_DELETE_ALL_ITEMS_IN_COLLECTION, [collection valueForKey:@"name"]];
						NSBeginAlertSheet(title,
										  DELETE_BUTTON,
										  nil,
										  CANCEL_BUTTON,
										  [[LTSnippetsController sharedInstance] snippetsWindow],
										  self,
										  nil,
										  @selector(snippetSheetDidDismiss:returnCode:contextInfo:),
										  nil,
										  NSLocalizedString(@"Please consider exporting the snippets first. There is no undo available.", @"Please consider exporting the snippets first. There is no undo available. when deleting a collection"));
					}
					[[LTToolsMenuController sharedInstance] buildInsertSnippetMenu];
					
				// Snippet
				} else if (self == [[LTSnippetsController sharedInstance] snippetsTableView]) {
					
					id snippet = [[[[LTSnippetsController sharedInstance] snippetsArrayController] selectedObjects] objectAtIndex:0];
					[[[LTSnippetsController sharedInstance] snippetsArrayController] removeObject:snippet];
					[[LTToolsMenuController sharedInstance] buildInsertSnippetMenu];
					
				// Command collection
				} else if (self == [[LTCommandsController sharedInstance] commandCollectionsTableView]) {
					
					id collection = [[[[LTCommandsController sharedInstance] commandCollectionsArrayController] selectedObjects] objectAtIndex:0];
					NSMutableSet *commandsToDelete = [collection mutableSetValueForKey:@"commands"];
					if ([commandsToDelete count] == 0) {
						[[LTCommandsController sharedInstance] performDeleteCollection];
					} else {
						NSString *title = [NSString stringWithFormat:WILL_DELETE_ALL_ITEMS_IN_COLLECTION, [collection valueForKey:@"name"]];
						NSBeginAlertSheet(title,
										  DELETE_BUTTON,
										  nil,
										  CANCEL_BUTTON,
										  [[LTCommandsController sharedInstance] commandsWindow],
										  self,
										  nil,
										  @selector(commandSheetDidDismiss:returnCode:contextInfo:),
										  nil,
										  NSLocalizedStringFromTable(@"Please consider exporting the commands first. There is no undo available", @"Localizable3", @"Please consider exporting the commands first. There is no undo available"));
					}
					[[LTToolsMenuController sharedInstance] buildRunCommandMenu];
				
				// Command
				} else if (self == [[LTCommandsController sharedInstance] commandsTableView]) {
					
					id command = [[[[LTCommandsController sharedInstance] commandsArrayController] selectedObjects] objectAtIndex:0];
					[[[LTCommandsController sharedInstance] commandsArrayController] removeObject:command];
					[[LTToolsMenuController sharedInstance] buildRunCommandMenu];
				
				// Document
				} else if (self == [LTCurrentProject documentsTableView]) {
					id document = [[[LTCurrentProject documentsArrayController] selectedObjects] objectAtIndex:0];
					[LTCurrentProject checkIfDocumentIsUnsaved:document keepOpen:NO];
				}
			}
		}
		
	} else {
		[super keyDown:event];
	}
}


- (void)snippetSheetDidDismiss:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
{
	[sheet close];
	
	if (returnCode == NSAlertDefaultReturn) {
		[[LTSnippetsController sharedInstance] performDeleteCollection];
		
	}
}


- (void)commandSheetDidDismiss:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
{
	[sheet close];
	
	if (returnCode == NSAlertDefaultReturn) {
		[[LTCommandsController sharedInstance] performDeleteCollection];
	}
}


- (void)textDidEndEditing:(NSNotification *)aNotification
{
	if ([[[aNotification userInfo] objectForKey:@"NSTextMovement"] integerValue] == NSReturnTextMovement) {
		[[self window] endEditingFor:self];
		[self reloadData];
		[[self window] makeFirstResponder:self];
	} else {
		[super textDidEndEditing:aNotification];
	}
}

@end
