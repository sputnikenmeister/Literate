/*
Smultron version 3.6b1, 2009-09-12
Written by Peter Borg, pgw3@mac.com
Find the latest version at http://smultron.sourceforge.net

Copyright 2004-2009 Peter Borg
 
Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 
http://www.apache.org/licenses/LICENSE-2.0
 
Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
*/

#import "LTStandardHeader.h"

#import "LTApplication.H"
#import "LTProjectsController.h"
#import "LTTextView.h"
#import "LTApplicationDelegate.h"
#import "LTDocumentsMenuController.h"
#import "LTTextMenuController.h"
#import "LTInterfacePerformer.h"
#import "LTMainController.h"
#import "LTFullScreenWindow.h"
#import "LTSnippetsController.h"
#import "LTShortcutsController.h"
#import "LTCommandsController.h"
#import "LTLineNumbers.h"
#import "LTProject.h"
#import "LTProject+ToolbarController.h"
#import "LTSearchField.h"

@implementation LTApplication

- (void)awakeFromNib
{
	textViewClass = [LTTextView class];
	
	[self setDelegate:[LTApplicationDelegate sharedInstance]];
}


- (void)sendEvent:(NSEvent *)event
{
	if ([event type] == NSKeyDown) {
		eventWindow = [event window];
		if (eventWindow == LTCurrentWindow) {
			flags = [event modifierFlags] & NSDeviceIndependentModifierFlagsMask;
			
			if (flags == 1703936) { // Command, Option, Shift
				keyCode = [event keyCode];
				if (keyCode == 3) { // 3 is F
					if ([[LTCurrentProject projectWindowToolbar] isVisible] && [[LTCurrentProject projectWindowToolbar] displayMode] != NSToolbarDisplayModeLabelOnly) {
						NSArray *array = [[LTCurrentProject projectWindowToolbar] visibleItems];
						for (id item in array) {
							if ([[item itemIdentifier] isEqualToString:@"FunctionToolbarItem"]) {
								[LTCurrentProject functionToolbarItemAction:[LTCurrentProject functionButton]];
								return;
							}
						}
						
					}
				}
			} else if (flags == 12058624) { // Command, Option
				keyCode = [event keyCode];
				if (keyCode == 124) { // 124 is right arrow
					if ([[LTCurrentProject documents] count] > 1) {
						[[LTDocumentsMenuController sharedInstance] nextDocumentAction:nil];
						return;
					}
				} else if (keyCode == 123) { // 123 is left arrow
					if ([[LTCurrentProject documents] count] > 1) {
						[[LTDocumentsMenuController sharedInstance] previousDocumentAction:nil];
						return;
					}
				}
			} else if (flags == 131072) { // Shift
				keyCode = [event keyCode];
				if (keyCode == 48) { // 48 is Tab
					if (LTCurrentTextView != nil) {
						[[LTTextMenuController sharedInstance] shiftLeftAction:nil];
						return;
					}
				}
			} else if (flags == 1048576 || flags == 3145728 || flags == 1179648) { // Command, command with a numerical key and command with shift for the keyboards that requires it 
				character = [event charactersIgnoringModifiers];
				if ([character isEqualToString:@"+"] || [character isEqualToString:@"="]) {
					NSFont *oldFont = [NSUnarchiver unarchiveObjectWithData:[LTDefaults valueForKey:@"TextFont"]];
					CGFloat size = [oldFont pointSize] + 1;
					[LTDefaults setValue:[NSArchiver archivedDataWithRootObject:[NSFont fontWithName:[oldFont fontName] size:size]] forKey:@"TextFont"];
					return;
				} else if ([character isEqualToString:@"-"]) {
					NSFont *oldFont = [NSUnarchiver unarchiveObjectWithData:[LTDefaults valueForKey:@"TextFont"]];
					CGFloat size = [oldFont pointSize];
					if (size > 4) {
						size--;
						[LTDefaults setValue:[NSArchiver archivedDataWithRootObject:[NSFont fontWithName:[oldFont fontName] size:size]] forKey:@"TextFont"];
						return;
					}
				}
			}
			
			
		} else if (eventWindow == [LTInterface fullScreenWindow]) {
			if ([LTMain isInFullScreenMode]) {
				flags = [event modifierFlags] & NSDeviceIndependentModifierFlagsMask;
				keyCode = [event keyCode];
				if (keyCode == 0x35 && flags == 0) { // 35 is Escape,
					[(LTFullScreenWindow *)[LTInterface fullScreenWindow] returnFromFullScreen];
					return;
				} else if (keyCode == 0x07 && flags == 1048576) { // 07 is X, 1048576 is Command
					[(NSTextView *)[[LTInterface fullScreenWindow] firstResponder] cut:nil];
					return;
				} else if (keyCode == 0x08 && flags == 1048576) { // 08 is C
					[(NSTextView *)[[LTInterface fullScreenWindow] firstResponder] copy:nil];
					return;
				} else if (keyCode == 0x09 && flags == 1048576) { // 09 is V
					[(NSTextView *)[[LTInterface fullScreenWindow] firstResponder] paste:nil];
					return;
				} else if (keyCode == 0x06 && flags == 1048576) { // 06 is Z
					[[(NSTextView *)[[LTInterface fullScreenWindow] firstResponder] undoManager] undo];
					return;
				}
			}
			
			
		} else if (eventWindow == [[LTSnippetsController sharedInstance] snippetsWindow]) {
			NSInteger editedColumn = [[[LTSnippetsController sharedInstance] snippetsTableView] editedColumn];
			if (editedColumn != -1) {
				NSTableColumn *tableColumn = [[[[LTSnippetsController sharedInstance] snippetsTableView] tableColumns] objectAtIndex:editedColumn];
				
				if ([[tableColumn identifier] isEqualToString:@"shortcut"]) {
					key = [[event charactersIgnoringModifiers] characterAtIndex:0];
					keyCode = [event keyCode];
					if (keyCode == 0x35) { // If the user cancels by pressing Escape don't insert a hot key
						[[[LTSnippetsController sharedInstance] snippetsWindow] makeFirstResponder:[[LTSnippetsController sharedInstance] snippetsTableView]];
						return;
					} else if (keyCode == 0x30) { // Tab
						[[[LTSnippetsController sharedInstance] snippetsWindow] makeFirstResponder:[[LTSnippetsController sharedInstance] snippetsTextView]];
						return;
					} else {
						flags = ([event modifierFlags] & 0x00FF);
						if ((key == NSDeleteCharacter || keyCode == 0x75) && flags == 0) { // 0x75 is forward delete 
							[[LTShortcutsController sharedInstance] unregisterSelectedSnippetShortcut];
						} else {
							[[LTShortcutsController sharedInstance] registerSnippetShortcutWithEvent:event];
						}
						[[[LTSnippetsController sharedInstance] snippetsWindow] makeFirstResponder:[[LTSnippetsController sharedInstance] snippetsTableView]];
						return;
					}
				}
			}
			
			
		} else if (eventWindow == [[LTCommandsController sharedInstance] commandsWindow]) {
			NSInteger editedColumn = [[[LTCommandsController sharedInstance] commandsTableView] editedColumn];
			if (editedColumn != -1) {
				NSTableColumn *tableColumn = [[[[LTCommandsController sharedInstance] commandsTableView] tableColumns] objectAtIndex:editedColumn];
				
				if ([[tableColumn identifier] isEqualToString:@"shortcut"]) {
					key = [[event charactersIgnoringModifiers] characterAtIndex:0];
					keyCode = [event keyCode];

					if (keyCode == 0x35) { // If the user cancels by pressing Escape don't insert a hot key
						[[[LTCommandsController sharedInstance] commandsWindow] makeFirstResponder:[[LTCommandsController sharedInstance] commandsTableView]];
						return;
					} else if (keyCode == 0x30) { // Tab
						[[[LTCommandsController sharedInstance] commandsWindow] makeFirstResponder:[[LTCommandsController sharedInstance] commandsTextView]];
						return;
					} else {
						flags = ([event modifierFlags] & 0x00FF);
						if ((key == NSDeleteCharacter || keyCode == 0x75) && flags == 0) { // 0x75 is forward delete 
							[[LTShortcutsController sharedInstance] unregisterSelectedCommandShortcut];
						} else {
							[[LTShortcutsController sharedInstance] registerCommandShortcutWithEvent:event];
						}

						[[[LTCommandsController sharedInstance] commandsWindow] makeFirstResponder:[[LTCommandsController sharedInstance] commandsTableView]];
						return;
					}
				}
			}
		}
	}
	[super sendEvent:event];
}


// See -[LTTextView complete:]
- (NSEvent *)nextEventMatchingMask:(NSUInteger)eventMask untilDate:(NSDate *)expirationDate inMode:(NSString *)runLoopMode dequeue:(BOOL)dequeue
{
	if ([runLoopMode isEqualToString:NSEventTrackingRunLoopMode]) {
		if ([LTCurrentTextView inCompleteMethod]) eventMask &= ~NSAppKitDefinedMask;
	}
	
	return [super nextEventMatchingMask:eventMask untilDate:expirationDate inMode:runLoopMode dequeue:dequeue];
}


#pragma mark
#pragma mark AppleScript
- (NSString *)name
{
	return [LTCurrentDocument valueForKey:@"name"];
}


- (NSString *)path
{
	return [LTCurrentDocument valueForKey:@"path"]; 
}


- (NSString *)content
{
    return [[LTCurrentDocument valueForKey:@"firstTextView"] string]; 
}


- (void)setContent:(NSString *)newContent
{
	LTTextView *textView = [LTCurrentDocument valueForKey:@"firstTextView"];
	if ([textView shouldChangeTextInRange:NSMakeRange(0, [[textView string] length]) replacementString:newContent]) { // Do it this way to mark it as an Undo
		[textView replaceCharactersInRange:NSMakeRange(0, [[textView string] length]) withString:newContent];
		[textView didChangeText];
	}
    [[LTCurrentDocument valueForKey:@"lineNumbers"] updateLineNumbersCheckWidth:YES recolour:YES];
}


- (BOOL)edited
{
    return [[LTCurrentDocument valueForKey:@"isEdited"] boolValue];
}


- (BOOL)smartInsertDelete
{
	return [[LTDefaults valueForKey:@"SmartInsertDelete"] boolValue];
}


- (void)setSmartInsertDelete:(BOOL)flag
{
	[LTDefaults setValue:[NSNumber numberWithBool:flag] forKey:@"SmartInsertDelete"];
}

@end
