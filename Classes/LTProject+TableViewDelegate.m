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

#import "LTProject+TableViewDelegate.h"
#import "LTApplicationDelegate.h"
#import "LTDocumentsListCell.h"
#import "LTInterfacePerformer.h"
#import "LTVariousPerformer.h"
#import "LTLineNumbers.h"
#import "LTProject+DocumentViewsController.h"

@implementation LTProject (TableViewDelegate)


- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	NSTableView *tableView = [aNotification object];
	if (tableView == [self documentsTableView] || aNotification == nil) {
		if ([[LTApplicationDelegate sharedInstance] isTerminatingApplication] == YES) {
			return;
		}
		if ([[[self documentsArrayController] arrangedObjects] count] < 1 || [[[self documentsArrayController] selectedObjects] count] < 1) {
			[self updateWindowTitleBarForDocument:nil];
			return;
		}
		
		id document = [[[self documentsArrayController] selectedObjects] objectAtIndex:0];
		
		[self performInsertFirstDocument:document];
	}
	
}


- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	if ([[LTDefaults valueForKey:@"SizeOfDocumentsListTextPopUp"] integerValue] == 0) {
		[aCell setFont:[NSFont systemFontOfSize:11.0]];
	} else {
		[aCell setFont:[NSFont systemFontOfSize:13.0]];
	}
	
	if (aTableView == [self documentsTableView]) {
		id document = [[[self documentsArrayController] arrangedObjects] objectAtIndex:rowIndex];
		
		if ([[document valueForKey:@"isNewDocument"] boolValue] == YES) {
			[aTableView addToolTipRect:[aTableView rectOfRow:rowIndex] owner:UNSAVED_STRING userData:nil];
		} else {
			if ([[document valueForKey:@"fromExternal"] boolValue]) {
				[aTableView addToolTipRect:[aTableView rectOfRow:rowIndex] owner:[document valueForKey:@"externalPath"] userData:nil];
			} else {
				[aTableView addToolTipRect:[aTableView rectOfRow:rowIndex] owner:[document valueForKey:@"path"] userData:nil];
			}
		}
		
		if ([[aTableColumn identifier] isEqualToString:@"name"]) {
			NSImage *image;
			if ([[document valueForKey:@"isEdited"] boolValue] == YES) {
				image = [document valueForKey:@"unsavedIcon"];
			} else {
				image = [document valueForKey:@"icon"];
			}

			[(LTDocumentsListCell *)aCell setHeightAndWidth:[[[self valueForKey:@"project"] valueForKey:@"viewSize"] floatValue]];
			[(LTDocumentsListCell *)aCell setImage:image];
			
			if ([[LTDefaults valueForKey:@"ShowFullPathInDocumentsList"] boolValue] == YES) {
				[(LTDocumentsListCell *)aCell setStringValue:[document valueForKey:@"nameWithPath"]];
			} else {
				[(LTDocumentsListCell *)aCell setStringValue:[document valueForKey:@"name"]];
			}
		}
		
	}
}


- (void)performInsertFirstDocument:(id)document
{	
	[self setFirstDocument:document];
	
	[LTInterface removeAllSubviewsFromView:firstContentView];
	[firstContentView addSubview:[document valueForKey:@"firstTextScrollView"]];
	if ([[document valueForKey:@"showLineNumberGutter"] boolValue] == YES) {
		[firstContentView addSubview:[document valueForKey:@"firstGutterScrollView"]];
	}
	
	[self updateWindowTitleBarForDocument:document];
	[self resizeViewsForDocument:document]; // If the window has changed since the view was last visible
	[[self documentsTableView] scrollRowToVisible:[[self documentsTableView] selectedRow]];
	
	[[self window] makeFirstResponder:[document valueForKey:@"firstTextView"]];
	[[document valueForKey:@"lineNumbers"] updateLineNumbersForClipView:[[document valueForKey:@"firstTextScrollView"] contentView] checkWidth:NO recolour:YES]; // If the window has changed since the view was last visible
	[LTInterface updateStatusBar];
	
	[self selectSameDocumentInTabBarAsInDocumentsList];
}

@end
