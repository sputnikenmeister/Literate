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

#import "LTProjectsController.h"
#import "LTOpenSavePerformer.h"
#import "LTSingleDocumentPanel.h"
#import "LTBasicPerformer.h"
#import "LTInterfacePerformer.h"
#import "LTProject.h"
#import "LTTextView.h"
#import "LTProject+DocumentViewsController.h"

@implementation LTProjectsController

@synthesize currentProject;

- (id)currentDocument
{
	if ([self currentProject] != nil) {
		return [self currentProject];
	} else {
		return [super currentDocument];
	}
}


- (id)currentLTDocument
{
	if ([LTCurrentProject areThereAnyDocuments] == NO) {
		return nil;
	}
	
	NSWindow *mainWindow = [NSApp mainWindow];
	NSWindow *keyWindow = [NSApp keyWindow];
	id selectedDocument = [[[LTCurrentProject documentsArrayController] selectedObjects] objectAtIndex:0];
	
	if ([keyWindow isKindOfClass:[LTSingleDocumentPanel class]]) {
		if (keyWindow != nil) { // Loop through all single document windows to see if one of those is the key window
			NSArray *array = [LTBasic fetchAll:@"Document"];
			for (id item in array) {
				if (keyWindow == [item valueForKey:@"singleDocumentWindow"]) {
					return item;
				}
			}
		}
	} else if (mainWindow == LTCurrentWindow) {
		id firstResponder = [mainWindow firstResponder];		
		if (firstResponder == [selectedDocument valueForKey:@"firstTextView"]) { // Guess that it is the firstTextView as it is usually correct
			return selectedDocument;
		}
		
		if ([firstResponder isKindOfClass:[LTTextView class]]) {		
			NSArray *array = [LTBasic fetchAll:@"Document"];
			for (id item in array) {
				if (firstResponder == [item valueForKey:@"firstTextView"] || firstResponder == [item valueForKey:@"secondTextView"] || firstResponder == [item valueForKey:@"thirdTextView"]) {
					return item;
				}
			}
		}
	} else {
		
	}
	
	// Hasn't found the document so return the selected
	return selectedDocument;	
	
}


- (LTTextView *)currentTextView
{
	id firstResponder = [[NSApp mainWindow] firstResponder];
	
	if ([firstResponder isKindOfClass:[LTTextView class]]) {
		return firstResponder;
	}
	
	// If the firstResponder isn't a LTTextView there isn't a current text view so return nil 
	return nil;
}


- (NSString *)currentText
{
	NSString *returnString = [[self currentTextView] string];
	if (returnString == nil) {
		if ([LTCurrentProject areThereAnyDocuments] == NO) {
			return nil;
		}
		
		id selectedDocument = [[[LTCurrentProject documentsArrayController] selectedObjects] objectAtIndex:0];
		
		returnString = [[selectedDocument valueForKey:@"firstTextView"] string];
		if (returnString == nil) {
			returnString = @"";
		}
	}
	
	return returnString;
}


- (void)selectDocumentFromTheDock:(id)sender
{
	[NSApp activateIgnoringOtherApps:YES];
	[self selectDocument:[sender representedObject]];
}


- (void)putInRecentWithPath:(NSString *)path
{	
	//Log([NSURL fileURLWithPath:path]);
	[self noteNewRecentDocumentURL:[NSURL fileURLWithPath:path]];
}


- (IBAction)openProjectAction:(id)sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setResolvesAliases:YES];		
	NSInteger result = [openPanel runModalForDirectory:[LTInterface whichDirectoryForOpen] file:nil types:[NSArray arrayWithObjects:@"smlp", @"smultronProject", nil]];
	if (result == NSOKButton) {
		[self performOpenProjectWithPath:[[openPanel filenames] objectAtIndex:0]];
	}
}


- (void)performOpenProjectWithPath:(NSString *)path
{
	[self putInRecentWithPath:path];
	
	id item;
	NSArray *array = [self documents];
	for (item in array) {
		if ([[[item valueForKey:@"project"] valueForKey:@"path"] isEqualToString:path]) {
			[[item window] makeKeyAndOrderFront:nil];
			return;
		}
	}
	
	id project = [self openUntitledDocumentAndDisplay:NO error:nil];
	[self setCurrentProject:project];
	[project makeWindowControllers];

	[project setFileURL:[NSURL fileURLWithPath:path]];
	[[project project] setValue:path forKey:@"path"];
	id projectToOpen = [NSUnarchiver unarchiveObjectWithData:[NSData dataWithContentsOfFile:path]];
	
	if ([projectToOpen isKindOfClass:[NSArray class]]) { // From version 2
		[self insertDocumentsFromProjectArray:projectToOpen];
	} else { // From version 3
		
		if ([projectToOpen valueForKey:@"windowFrame"] != nil) {
			[[project window] setFrame:NSRectFromString([projectToOpen valueForKey:@"windowFrame"]) display:NO animate:NO];
		}
		
		NSArray *documents = [projectToOpen valueForKey:@"documentsArray"];
		[self insertDocumentsFromProjectArray:documents];
		
		if ([projectToOpen valueForKey:@"selectedDocumentName"] != nil) {
			NSString *name = [projectToOpen valueForKey:@"selectedDocumentName"];
			NSArray *array = [project documents];
			for (id item in array) {
				if ([[item valueForKey:@"name"] isEqualToString:name]) {
					[project selectDocument:item];
					break;
				}
			}		
		}
		
		if ([projectToOpen valueForKey:@"view"] != nil) {
			[[project project] setValue:[projectToOpen valueForKey:@"view"] forKey:@"view"];
		}
		if ([projectToOpen valueForKey:@"viewSize"] != nil) {
			[[project project] setValue:[projectToOpen valueForKey:@"viewSize"] forKey:@"viewSize"];
		}
		if ([projectToOpen valueForKey:@"dividerPosition"] != nil) {
			[[project project] setValue:[projectToOpen valueForKey:@"dividerPosition"] forKey:@"dividerPosition"];
			[project resizeMainSplitView];
		}
		
	}
	
	[project setDefaultViews];
	[project selectionDidChange];

	[[project documentsArrayController] rearrangeObjects];
	
	[project showWindows];
	[self setCurrentProject:nil];
}


- (void)insertDocumentsFromProjectArray:(NSArray *)array
{
	id item;
	for (item in array) {	
		[LTOpenSave shouldOpen:[item valueForKey:@"path"] withEncoding:[[item valueForKey:@"encoding"] unsignedIntegerValue]];
		id document = LTCurrentDocument;
		if ([item valueForKey:@"selectedRange"] != nil && document != nil) {
			[[document valueForKey:@"firstTextView"] setSelectedRange:NSRangeFromString([item valueForKey:@"selectedRange"])];
			[[document valueForKey:@"firstTextView"] scrollRangeToVisible:NSRangeFromString([item valueForKey:@"selectedRange"])];
		}
		
		[LTCurrentDocument setValue:[item valueForKey:@"sortOrder"] forKey:@"sortOrder"];
	}
}
	

- (void)selectDocument:(id)document
{
	NSArray *projects = [self documents];
	for (id project in projects) {
		NSArray *documents = [[(LTProject *)project documents] allObjects];
		for (id item in documents) {
			if (item == document) {
				[[project window] makeKeyAndOrderFront:nil];
				[[project window] makeMainWindow];
				[[project window] makeFirstResponder:[document valueForKey:@"firstTextView"]];
				[project selectDocument:document];
				return;
			}
		}
	}
}
@end
