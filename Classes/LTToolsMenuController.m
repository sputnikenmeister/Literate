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

#import "LTToolsMenuController.h"
#import "LTCommandsController.h"
#import "LTSnippetsController.h"
#import "LTProjectsController.h"
#import "LTPreviewController.h"
#import "LTBasicPerformer.h"
#import "LTTextPerformer.h"
#import "LTInterfacePerformer.h"
#import "LTTextMenuController.h"
#import "LTInfoController.h"
#import "LTExtraInterfaceController.h"
#import "LTTextView.h"

@implementation LTToolsMenuController

static id sharedInstance = nil;

+ (LTToolsMenuController *)sharedInstance
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


- (IBAction)createSnippetFromSelectionAction:(id)sender
{	
	id item = [[LTSnippetsController sharedInstance] performInsertNewSnippet];
	
	NSRange selectedRange = [LTCurrentTextView selectedRange];
	NSString *text = [[LTCurrentTextView string] substringWithRange:selectedRange];
	if (selectedRange.length == 0 || text == nil || [text isEqualToString:@""]) {
		NSBeep();
		return;
	}

	[item setValue:text forKey:@"text"];
	if ([text length] > SNIPPET_NAME_LENGTH) {
		[item setValue:[LTText replaceAllNewLineCharactersWithSymbolInString:[text substringWithRange:NSMakeRange(0, SNIPPET_NAME_LENGTH)]] forKey:@"name"];
	} else {
		[item setValue:text forKey:@"name"];
	}
}


- (IBAction)insertColourAction:(id)sender
{
	NSColorPanel *colourPanel = [NSColorPanel sharedColorPanel];
	
	if ([NSApp keyWindow] == colourPanel) {
		[colourPanel orderOut:nil];
		return;
	}
	
	textViewToInsertColourInto = LTCurrentTextView;
	
	if (textViewToInsertColourInto == nil) {
		NSBeep();
		return;
	}
	
	[colourPanel makeKeyAndOrderFront:self];
	[colourPanel setTarget:self];
	[colourPanel setAction:@selector(insertColour:)];
}


- (IBAction)previewAction:(id)sender
{
	[[LTPreviewController sharedInstance] showPreviewWindow];
}


- (IBAction)reloadPreviewAction:(id)sender
{
	[[LTPreviewController sharedInstance] reload];
}


- (IBAction)showCommandsWindowAction:(id)sender
{
	[[LTCommandsController sharedInstance] openCommandsWindow];
}


- (IBAction)runTextAction:(id)sender
{
	NSString *text = LTCurrentText;
	if (text == nil || [text isEqualToString:@""]) {
		return;
	}
	NSString *textPath = [LTBasic genererateTemporaryPath];
	
	id document = LTCurrentDocument;
	NSData *data = [[NSData alloc] initWithData:[[LTText convertLineEndings:text inDocument:document] dataUsingEncoding:[[document valueForKey:@"encoding"] integerValue] allowLossyConversion:YES]];
	if ([data writeToFile:textPath atomically:YES]) {
		NSString *result;
		NSString *resultPath = [LTBasic genererateTemporaryPath];
		system([[NSString stringWithFormat:@"%@ %@ > %@", [LTDefaults valueForKey:@"RunText"], textPath, resultPath] UTF8String]);
		if ([[NSFileManager defaultManager] fileExistsAtPath:resultPath]) {
			result = [NSString stringWithContentsOfFile:resultPath encoding:[[document valueForKey:@"encoding"] integerValue] error:nil];
			[[NSFileManager defaultManager] removeItemAtPath:resultPath error:nil];
			[[[LTExtraInterfaceController sharedInstance] commandResultWindow] makeKeyAndOrderFront:nil];
			[[[LTExtraInterfaceController sharedInstance] commandResultTextView] setString:result];
		}
		if ([[NSFileManager defaultManager] fileExistsAtPath:textPath]) {
			[[NSFileManager defaultManager] removeItemAtPath:textPath error:nil];
		}
	}
}


- (IBAction)showSnippetsWindowAction:(id)sender
{
	[[LTSnippetsController sharedInstance] openSnippetsWindow];
}


- (void)buildInsertSnippetMenu
{
	[LTBasic removeAllItemsFromMenu:insertSnippetMenu];
	
	NSEnumerator *collectionEnumerator = [[LTBasic fetchAll:@"SnippetCollectionSortKeyName"] reverseObjectEnumerator];
	for (id collection in collectionEnumerator) {
		if ([collection valueForKey:@"name"] == nil) {
			continue;
		}
		NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:[collection valueForKey:@"name"] action:nil keyEquivalent:@""];
		NSMenu *subMenu = [[NSMenu alloc] init];
		
		NSMutableArray *array = [NSMutableArray arrayWithArray:[[collection mutableSetValueForKey:@"snippets"] allObjects]];
		[array sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
		for (id snippet in array) {
			if ([snippet valueForKey:@"name"] == nil) {
				continue;
			}
			NSString *keyString;
			if ([snippet valueForKey:@"shortcutMenuItemKeyString"] != nil) {
				keyString = [snippet valueForKey:@"shortcutMenuItemKeyString"];
			} else {
				keyString = @"";
			}
			NSMenuItem *subMenuItem = [[NSMenuItem alloc] initWithTitle:[snippet valueForKey:@"name"] action:@selector(snippetShortcutFired:) keyEquivalent:keyString];
			[subMenuItem setKeyEquivalentModifierMask:[[snippet valueForKey:@"shortcutModifier"] integerValue]];
			[subMenuItem setTarget:self];			
			[subMenuItem setRepresentedObject:snippet];
			[subMenu insertItem:subMenuItem atIndex:0];
		}
		
		[menuItem setSubmenu:subMenu];
		[insertSnippetMenu insertItem:menuItem atIndex:0];
	}
}


- (void)snippetShortcutFired:(id)sender
{
	[[LTSnippetsController sharedInstance] insertSnippet:[sender representedObject]];
}


- (void)buildRunCommandMenu
{
	[LTBasic removeAllItemsFromMenu:runCommandMenu];
	
	NSEnumerator *collectionEnumerator = [[LTBasic fetchAll:@"CommandCollectionSortKeyName"] reverseObjectEnumerator];
	for (id collection in collectionEnumerator) {
		if ([collection valueForKey:@"name"] == nil) {
			continue;
		}
		NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:[collection valueForKey:@"name"] action:nil keyEquivalent:@""];
		NSMenu *subMenu = [[NSMenu alloc] init];
		
		NSMutableArray *array = [NSMutableArray arrayWithArray:[[collection mutableSetValueForKey:@"commands"] allObjects]];
		[array sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
		for (id command in array) {
			if ([command valueForKey:@"name"] == nil) {
				continue;
			}
			NSString *keyString;
			if ([command valueForKey:@"shortcutMenuItemKeyString"] != nil) {
				keyString = [command valueForKey:@"shortcutMenuItemKeyString"];
			} else {
				keyString = @"";
			}
			NSMenuItem *subMenuItem = [[NSMenuItem alloc] initWithTitle:[command valueForKey:@"name"] action:@selector(commandShortcutFired:) keyEquivalent:keyString];
			[subMenuItem setKeyEquivalentModifierMask:[[command valueForKey:@"shortcutModifier"] integerValue]];
			[subMenuItem setTarget:self];			
			[subMenuItem setRepresentedObject:command];
			[subMenu insertItem:subMenuItem atIndex:0];
		}
		
		[menuItem setSubmenu:subMenu];
		[runCommandMenu insertItem:menuItem atIndex:0];
	}
	
}


- (void)commandShortcutFired:(id)sender
{
	[[LTCommandsController sharedInstance] runCommand:[sender representedObject]];
}


- (void)insertColour:(id)sender
{
	if (textViewToInsertColourInto == nil) {
		NSBeep();
		return;
	}
	
	NSColor *colour = [[sender color] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
	
	NSInteger red = (NSInteger)([colour redComponent] * 255);
	NSInteger green = (NSInteger)([colour greenComponent] * 255);
	NSInteger blue = (NSInteger)([colour blueComponent] * 255);
	
	NSString *insertString;
	if ([[LTDefaults valueForKey:@"UseRGBRatherThanHexWhenInsertingColourValues"] boolValue] == YES) {
		insertString = [NSString stringWithFormat:@"rgb(%i,%i,%i)", red, green, blue];
	} else {
		insertString = [[NSString stringWithFormat:@"#%02x%02x%02x", red, green, blue] uppercaseString];
	}
	
	
	NSRange selectedRange = [textViewToInsertColourInto selectedRange];
	[textViewToInsertColourInto insertText:insertString];
	[textViewToInsertColourInto setSelectedRange:NSMakeRange(selectedRange.location, [insertString length])]; // Select the inserted string so it will replace the last colour if more colours are inserted
}


- (IBAction)previousFunctionAction:(id)sender
{
	NSInteger lineNumber = [LTInterface currentLineNumber];
	NSArray *functions = [LTInterface allFunctions];
	
	if (lineNumber == 0 || [functions count] == 0) {
		NSBeep();
		return;
	}
	
	id item;
	NSInteger previousFunctionLineNumber = 0;
	for (item in functions) {
		NSInteger functionLineNumber = [[item valueForKey:@"lineNumber"] integerValue];
		if (functionLineNumber >= lineNumber) {
			if (previousFunctionLineNumber != 0) {
				[[LTTextMenuController sharedInstance] performGoToLine:previousFunctionLineNumber];
				break;
			} else {
				NSBeep();
				return;
			}
		}
		previousFunctionLineNumber = functionLineNumber;
	}
}


- (IBAction)nextFunctionAction:(id)sender
{
	NSInteger lineNumber = [LTInterface currentLineNumber];
	NSArray *functions = [LTInterface allFunctions];

	if (lineNumber == 0 || [functions count] == 0) {
		NSBeep();
		return;
	}

	id item;
	BOOL hasFoundNextFunction = NO;
	for (item in functions) {
		NSInteger functionLineNumber = [[item valueForKey:@"lineNumber"] integerValue];
		if (functionLineNumber > lineNumber) {
			[[LTTextMenuController sharedInstance] performGoToLine:functionLineNumber];
			hasFoundNextFunction = YES;
			break;
		}
	}
	
	if (hasFoundNextFunction == NO) {
		NSBeep();
	}
}


- (BOOL)validateMenuItem:(NSMenuItem *)anItem
{
	BOOL enableMenuItem = YES;
	NSInteger tag = [anItem tag];
	if (tag == 1) { // Run Text
		if (LTCurrentTextView == nil) {
			enableMenuItem = NO;
		}
	} else if (tag == 2) { // Functions
		[LTBasic removeAllItemsFromMenu:functionsMenu];
		[LTInterface insertAllFunctionsIntoMenu:functionsMenu];
	} else if (tag == 3) { // Refresh Info
		if ([[[LTInfoController sharedInstance] infoWindow] isVisible] == NO) {
			enableMenuItem = NO;
		}
	} else if (tag == 4) { // Reload Preview
		if ([[[LTPreviewController sharedInstance] previewWindow] isVisible] == NO) {
			enableMenuItem = NO;
		}
	} else if (tag == 5) { // Create Snippet From Selection
		if ([LTCurrentTextView selectedRange].length < 1) {
			enableMenuItem = NO;
		}
	} else if (tag == 6) { // Insert Colour
		if (LTCurrentTextView == nil) {
			enableMenuItem = NO;
		}
	} else if (tag == 7) { // Export Snippets
		if ([[[LTSnippetsController sharedInstance] snippetsWindow] isVisible] == NO || [[[[LTSnippetsController sharedInstance] snippetCollectionsArrayController] selectedObjects] count] < 1) {
			enableMenuItem = NO;
		}
	} else if (tag == 8) { // Export Commands
		if ([[[LTCommandsController sharedInstance] commandsWindow] isVisible] == NO || [[[[LTCommandsController sharedInstance] commandCollectionsArrayController] selectedObjects] count] < 1) {
			enableMenuItem = NO;
		}
	} else if (tag == 9) { // Run Selection Inline
		if ([LTCurrentTextView selectedRange].length < 1) {
			enableMenuItem = NO;
		}
	} else if (tag == 10) { // New Snippet, New Snippet Collection
		if ([[[LTSnippetsController sharedInstance] snippetsWindow] isVisible] == NO) {
			enableMenuItem = NO;
		}
	} else if (tag == 11) { // Run Command, New Command, New Command Collection
		if ([[[LTCommandsController sharedInstance] commandsWindow] isVisible] == NO) {
			enableMenuItem = NO;
		}
	}		
	return enableMenuItem;
}


- (IBAction)emptyDummyAction:(id)sender
{
	// An easy way to enable menu items with submenus without setting an action which actually does something
}


- (IBAction)getInfoAction:(id)sender
{
	[[LTInfoController sharedInstance] openInfoWindow];	
}


- (IBAction)refreshInfoAction:(id)sender
{
	[[LTInfoController sharedInstance] refreshInfo];
}


- (IBAction)importSnippetsAction:(id)sender
{
	[[LTSnippetsController sharedInstance] importSnippets];
}


- (IBAction)exportSnippetsAction:(id)sender
{
	[[LTSnippetsController sharedInstance] exportSnippets];	
}


- (IBAction)importCommandsAction:(id)sender
{
	[[LTCommandsController sharedInstance] importCommands];
}


- (IBAction)exportCommandsAction:(id)sender
{
	[[LTCommandsController sharedInstance] exportCommands];
}


- (IBAction)showCommandResultWindowAction:(id)sender
{
	[[LTExtraInterfaceController sharedInstance] showCommandResultWindow];
}


- (IBAction)runSelectionInlineAction:(id)sender
{
	LTTextView *textView = LTCurrentTextView;
	NSRange selectedRange = [textView selectedRange];
	NSString *text = [[textView string] substringWithRange:selectedRange];
	if (selectedRange.length == 0 || text == nil || [text isEqualToString:@""]) {
		NSBeep();
		return;
	}
	NSString *textPath = [LTBasic genererateTemporaryPath];
	
	id document = LTCurrentDocument;
	NSData *data = [[NSData alloc] initWithData:[[LTText convertLineEndings:text inDocument:document] dataUsingEncoding:[[document valueForKey:@"encoding"] integerValue] allowLossyConversion:YES]];
	if ([data writeToFile:textPath atomically:YES]) {
		NSString *result;
		NSString *resultPath = [LTBasic genererateTemporaryPath];
		system([[NSString stringWithFormat:@"%@ %@ > %@", [LTDefaults valueForKey:@"RunText"], textPath, resultPath] UTF8String]);
		if ([[NSFileManager defaultManager] fileExistsAtPath:resultPath]) {
			result = [NSString stringWithContentsOfFile:resultPath encoding:[[document valueForKey:@"encoding"] integerValue] error:nil];
			[[NSFileManager defaultManager] removeItemAtPath:resultPath error:nil];
			[textView insertText:result];
		}
		if ([[NSFileManager defaultManager] fileExistsAtPath:textPath]) {
			[[NSFileManager defaultManager] removeItemAtPath:textPath error:nil];
		}
	}
}


- (IBAction)runCommandAction:(id)sender
{
	[[LTCommandsController sharedInstance] runAction:sender];
}


- (IBAction)newCommandAction:(id)sender
{
	[[LTCommandsController sharedInstance] newCommandAction:sender];
}


- (IBAction)newCommandCollectionAction:(id)sender
{
	[[LTCommandsController sharedInstance] newCollectionAction:sender];
}


- (IBAction)newSnippetAction:(id)sender
{
	[[LTSnippetsController sharedInstance] newSnippetAction:sender];
}


- (IBAction)newSnippetCollectionAction:(id)sender
{
	[[LTSnippetsController sharedInstance] newCollectionAction:sender];
}

@end
