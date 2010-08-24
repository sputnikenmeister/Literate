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

#import "LTFileMenuController.h"
#import "LTProjectsController.h"
#import "LTExtraInterfaceController.h"
#import "LTBasicPerformer.h"
#import "LTOpenSavePerformer.h"
#import "LTInterfacePerformer.h"
#import "LTVariousPerformer.h"
#import "LTPrintTextView.h"
#import "LTLayoutManager.h"
#import "LTSyntaxColouring.h"
#import "LTProject.h"
#import "LTLineNumbers.h"


@implementation LTFileMenuController


static id sharedInstance = nil;

+ (LTFileMenuController *)sharedInstance
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


- (IBAction)newAction:(id)sender
{
	if (LTCurrentProject == nil) {
		[[LTProjectsController sharedDocumentController] newDocument:nil];
	}
	id document = [LTCurrentProject createNewDocumentWithContents:@""];
	[LTCurrentProject insertDefaultIconsInDocument:document];
	[LTCurrentProject selectionDidChange];
}


- (IBAction)newProjectAction:(id)sender
{
	[[[LTExtraInterfaceController sharedInstance] newProjectWindow] makeKeyAndOrderFront:nil];
}


- (IBAction)openAction:(id)sender
{
	[LTBasic removeAllItemsFromMenu:[[[LTExtraInterfaceController sharedInstance] openPanelEncodingsPopUp] menu]];

	NSEnumerator *enumerator = [[LTBasic fetchAll:@"EncodingSortKeyName"] reverseObjectEnumerator];
	NSMenuItem *menuItem;
	for (id item in enumerator) {
		if ([[item valueForKey:@"active"] boolValue] == YES) {
			NSUInteger encoding = [[item valueForKey:@"encoding"] unsignedIntegerValue];
			menuItem = [[NSMenuItem alloc] initWithTitle:[NSString localizedNameOfStringEncoding:encoding] action:nil keyEquivalent:@""];
			[menuItem setTag:encoding];
			[[[[LTExtraInterfaceController sharedInstance] openPanelEncodingsPopUp] menu] insertItem:menuItem atIndex:0];
		}
	}

	menuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Use settings from Preferences", @"Use settings from Preferences in openAction") action:nil keyEquivalent:@""];
	[menuItem setTag:0];
	[[[[LTExtraInterfaceController sharedInstance] openPanelEncodingsPopUp] menu] insertItem:menuItem atIndex:0];

	[[[LTExtraInterfaceController sharedInstance] openPanelEncodingsPopUp] selectItemAtIndex:0]; // Reset it to: Use settings from Preferences
	
	if ([sender tag] == 7) { // Needs to be set before it is created
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"AppleShowAllFiles"];
	}
	
	openPanel = [[NSOpenPanel alloc] init];

	[openPanel setResolvesAliases:YES];
	[openPanel setAllowsMultipleSelection:YES];
	[openPanel setAccessoryView:[[LTExtraInterfaceController sharedInstance] openPanelAccessoryView]];
	
	if ([[LTDefaults valueForKey:@"OpenAllFilesWithinAFolder"] boolValue] == YES) {
		[openPanel setCanChooseDirectories:YES];
	}
	
	if ([sender tag] == 7) {
		[openPanel setTreatsFilePackagesAsDirectories:YES];
	}
	
	[openPanel beginSheetForDirectory:[LTInterface whichDirectoryForOpen]
							 file:nil
							types:nil
				   modalForWindow:LTCurrentWindow
					modalDelegate:self
				   didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:)
					  contextInfo:nil];
}


- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"AppleShowAllFiles"];
	
	if (returnCode == NSOKButton) {	
		[LTDefaults setValue:[[sheet filename] stringByDeletingLastPathComponent] forKey:@"LastOpenDirectory"];
		NSArray *array = [sheet filenames];
		for (id item in array) {
			[LTOpenSave shouldOpen:item withEncoding:[[[LTExtraInterfaceController sharedInstance] openPanelEncodingsPopUp] selectedTag]];
		}
	}
}


- (IBAction)saveAction:(id)sender
{
	if ([[LTCurrentDocument valueForKey:@"isNewDocument"] boolValue] == YES) {   
		[[LTProjectsController sharedDocumentController] selectDocument:LTCurrentDocument]; // If one has saved from a single document window it should select the proper document in the project
		[self saveAsAction:sender];    
	} else {
		[LTOpenSave performSaveOfDocument:LTCurrentDocument fromSaveAs:NO];
	}
}


- (IBAction)saveAsAction:(id)sender
{
	NSSavePanel *savePanel = [NSSavePanel savePanel];
	NSMutableString *name = [NSMutableString stringWithString:[LTCurrentDocument valueForKey:@"name"]];
	if ([[LTDefaults valueForKey:@"AppendNameInSaveAs"] boolValue] == YES) {
		[name appendString:[LTDefaults valueForKey:@"AppendNameInSaveAsWith"]];
	}
	[savePanel beginSheetForDirectory:[LTInterface whichDirectoryForSave]				
								 file:name
					   modalForWindow:LTCurrentWindow
						modalDelegate:self
					   didEndSelector:@selector(savePanelDidEnd:returnCode:contextInfo:)
						  contextInfo:nil];
	
	[NSApp runModalForWindow:savePanel]; // Run as modal to handle if there are more than one document that needs saving
}


- (void)savePanelDidEnd:(NSSavePanel *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)context
{
	[sheet close];
	[LTVarious stopModalLoop];
	
	if (returnCode == NSOKButton) {						
		if ([[LTCurrentDocument valueForKey:@"fromExternal"] boolValue] == YES) {
			[LTVarious sendClosedEventToExternalDocument:LTCurrentDocument];
			[LTCurrentDocument setValue:[NSNumber numberWithBool:NO] forKey:@"fromExternal"]; // If it is "fromExternal" it shouldn't be that after it has gone through a Save As, but rather, it should be a normal document
		}
		
		[LTOpenSave performSaveOfDocument:LTCurrentDocument path:[sheet filename] fromSaveAs:YES aCopy:NO];
		if ([[NSFileManager defaultManager] fileExistsAtPath:[sheet filename]]) {// Check that it has actually been saved
			[[LTProjectsController sharedDocumentController] putInRecentWithPath:[sheet filename]];
		}
		[LTDefaults setValue:[[sheet filename] stringByDeletingLastPathComponent] forKey:@"LastSaveAsDirectory"];
		[[LTCurrentDocument valueForKey:@"syntaxColouring"] setSyntaxDefinition];
		
		[[LTCurrentDocument valueForKey:@"syntaxColouring"] pageRecolour];
		
		[LTInterface updateStatusBar];
	}
}


- (IBAction)saveACopyAsAction:(id)sender
{
	NSSavePanel *savePanel = [NSSavePanel savePanel];
	
	NSString *copyName = [NSString stringWithFormat:@"%@ %@", [LTCurrentDocument valueForKey:@"name"], NSLocalizedString(@"copy", @"The word to indicate that the filename is a copy in Save-A-Copy-As save-panel")];
	
	[savePanel beginSheetForDirectory:[LTInterface whichDirectoryForSave]				
								 file:copyName
					   modalForWindow:LTCurrentWindow
						modalDelegate:self
					   didEndSelector:@selector(saveACopyAsPanelDidEnd:returnCode:contextInfo:)
						  contextInfo:nil];
	
}


- (void)saveACopyAsPanelDidEnd:(NSSavePanel *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)context
{
	if (returnCode == NSOKButton) {						
		[LTOpenSave performSaveOfDocument:LTCurrentDocument path:[sheet filename] fromSaveAs:YES aCopy:YES];
		[LTDefaults setValue:[[sheet filename] stringByDeletingLastPathComponent] forKey:@"LastSaveAsDirectory"];
	}
}


- (IBAction)revertAction:(id)sender
{
	id document = LTCurrentDocument;
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if (![fileManager fileExistsAtPath:[document valueForKey:@"path"]]) { // Check if original file exists
		NSString *title = [NSString stringWithFormat:NSLocalizedString(@"You cannot revert this document because the file %@ doesn't exist anymore", @"Indicate that you cannot revert this document because the file %@ doesn't exist anymore Revert-file-doesn't-exist sheet"), [document valueForKey:@"path"]];
		[LTVarious standardAlertSheetWithTitle:title message:NSLocalizedString(@"Please check if you've moved or deleted the original file", @"Indicate that they should please check if you've moved or deleted the original file in Revert-file-doesn't-exist sheet") window:LTCurrentWindow];
		return;
	}
	
	if ([[document valueForKey:@"isEdited"] boolValue] == NO) {
		[self performRevertOfDocument:document]; // I.e an update of the document
	} else {
		if ([LTCurrentWindow attachedSheet]) {
			[[LTCurrentWindow attachedSheet] close];
		}
		
		NSBeginAlertSheet(NSLocalizedString(@"Are you sure you want to revert this document?", @"Ask if you are sure you want to revert this document in Revert-sheet"),
						  NSLocalizedString(@"Revert", @"Revert-button in Revert-sheet"),
						  nil,
						  CANCEL_BUTTON,
						  LTCurrentWindow,
						  self,
						  @selector(revertSheetDidEnd:returnCode:contextInfo:),
						  nil,
						  nil,
						  NSLocalizedString(@"Your changes will be lost if you revert the document", @"Warn that changes will be lost if you revert in Revert-sheet"));
	}
}


- (void)revertSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    if (returnCode == NSAlertDefaultReturn) {
		[self performRevertOfDocument:LTCurrentDocument];
	}
}


- (void)performRevertOfDocument:(id)document
{	
	NSData *textData = [[NSData alloc] initWithContentsOfFile:[document valueForKey:@"path"]];
	
	// UTF-8 e.g. encoding returns nil if the file is not properly formed so check for that and try others if it's nil
	NSString *string = [[NSString alloc] initWithData:textData encoding:[[document valueForKey:@"encoding"] integerValue]];
	
	if (string == nil) { // Test if encoding worked, else try NSISOLatin1StringEncoding
		string = [[NSString alloc] initWithData:textData encoding:NSISOLatin1StringEncoding];
		if (string == nil) { // Test if encoding worked, else try defaultCStringEncoding
			string = [[NSString alloc] initWithData:textData encoding:[NSString defaultCStringEncoding]];
			if (string == nil) { // If it still is nil set it to empty string
				string = @"";
			}
		}
	}
	[[[document valueForKey:@"firstTextView"] undoManager] removeAllActions];
	[[document valueForKey:@"firstTextView"] setString:string];
	[[document valueForKey:@"syntaxColouring"] pageRecolour];
	[[document valueForKey:@"lineNumbers"] updateLineNumbersCheckWidth:NO recolour:NO];
	[[document valueForKey:@"firstTextView"] setSelectedRange:NSMakeRange(0,0)];
	[document setValue:[NSNumber numberWithBool:NO] forKey:@"isEdited"];
	[LTCurrentProject updateEditedBlobStatus];
	[LTCurrentProject reloadData];
	[LTInterface updateStatusBar];
}


- (BOOL)validateMenuItem:(NSMenuItem *)anItem
{
	BOOL enableMenuItem = YES;
	NSInteger tag = [anItem tag];
	if (LTCurrentProject != nil && [LTCurrentProject areThereAnyDocuments]) {
		if (tag == 2) { // Save All
			NSArray *array = [LTCurrentProject documents];
			for (id item in array) {
				if ([[item valueForKey:@"isEdited"] boolValue] == YES) {
					enableMenuItem = YES;
					break;
				}
				enableMenuItem = NO;
			}

		} else if (tag == 4 || tag == 8 ) { // Revert & Reveal In Finder
			enableMenuItem = ![[LTCurrentDocument valueForKey:@"isNewDocument"] boolValue];
		} else if (tag == 5) { // Save Documents As Project
			if ([LTCurrentProject fileURL] != nil) {
				enableMenuItem = NO;
			}
		} else if (tag == 6) { // Close
			if ([NSApp mainWindow] == nil && [NSApp keyWindow] == nil) {
				enableMenuItem = NO;
			}
		} else if (tag == 9) { // Close Project
			if ([NSApp mainWindow] == nil) {
				enableMenuItem = NO;
			}
		}
			
	} else {
		if (tag == 1 || tag == 7) { // All items that should be active all the time and Open Hidden...
			enableMenuItem = YES;
		} else if (tag == 6) { // Close
			if ([NSApp mainWindow] == nil && [NSApp keyWindow] == nil) {
				enableMenuItem = NO;
			}
		} else {
			enableMenuItem = NO;
		}
	}
	
	return enableMenuItem;
}


- (IBAction)closeAction:(id)sender
{
	NSWindow *window = [NSApp keyWindow];
	if (window == LTCurrentWindow && [[LTCurrentProject documents] count] > 0) {
		[LTCurrentProject checkIfDocumentIsUnsaved:LTCurrentDocument keepOpen:NO];
	} else {
		[window performClose:nil];
	}
}


-(IBAction)saveAllAction:(id)sender
{
	NSArray *array = [LTCurrentProject documents];
	for (id item in array) {
		if ([[item valueForKey:@"isEdited"] boolValue] == YES) {
			if ([[item valueForKey:@"isNewDocument"] boolValue] == YES) {
				[[LTProjectsController sharedDocumentController] selectDocument:item];
				[self saveAsInSaveAllForDocument:item];
			} else {
				[LTOpenSave performSaveOfDocument:item fromSaveAs:NO];
			}
		}
	}
	[LTInterface updateStatusBar]; // Might be needed if the current document has saved with a new name 
}

-(IBAction)autosaveAllAction:(id)sender
{
	NSArray *array = [LTBasic fetchAll:@"Document"];
	for (id item in array) 
	{
		if ([[item valueForKey:@"isEdited"] boolValue] == YES && 
			[[item valueForKey:@"isNewDocument"] boolValue] == NO) 
		{
			// only save named documents
			[LTOpenSave performSaveOfDocument:item fromSaveAs:NO];
		}
	}
}


- (void)saveAsInSaveAllForDocument:(id)document
{
	NSSavePanel *savePanel = [NSSavePanel savePanel];				
	
	[savePanel beginSheetForDirectory:[LTInterface whichDirectoryForSave]				
								 file:[document valueForKey:@"name"]
					   modalForWindow:LTCurrentWindow
						modalDelegate:self
					   didEndSelector:@selector(saveAsPanelInSaveAllDidEnd:returnCode:contextInfo:)
						  contextInfo:(void *)[NSArray arrayWithObject:document]];
	
	[NSApp runModalForWindow:savePanel]; // Run as modal to handle if there are more than one document that needs saving
}


- (void)saveAsPanelInSaveAllDidEnd:(NSSavePanel *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)context
{
	[sheet close];
	[LTVarious stopModalLoop];
	
	if (returnCode == NSOKButton) {
		id document = [(NSArray *)context objectAtIndex:0];
		NSString *path = [sheet filename];
		[LTOpenSave performSaveOfDocument:document path:path fromSaveAs:NO aCopy:NO];
		if ([[NSFileManager defaultManager] fileExistsAtPath:path]) { // Check that it has actually been saved
			[[LTProjectsController sharedDocumentController] putInRecentWithPath:path];
		}
		[LTDefaults setValue:[path stringByDeletingLastPathComponent] forKey:@"LastSaveAsDirectory"];
		[[document valueForKey:@"syntaxColouring"] setSyntaxDefinition];
		[[document valueForKey:@"syntaxColouring"] pageRecolour];
	}
}


- (void)printAction:(id)sender 
{
	[LTCurrentProject printDocument:sender];
}




- (IBAction)revealInFinderAction:(id)sender
{
	[[NSWorkspace sharedWorkspace] selectFile:[LTCurrentDocument valueForKey:@"path"] inFileViewerRootedAtPath:@""];
}
	

- (IBAction)saveDocumentsAsProjectAction:(id)sender
{
	[LTCurrentProject saveDocumentAs:nil];
}

@end
