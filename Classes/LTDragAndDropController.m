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

#import "LTDragAndDropController.h"
#import "LTOpenSavePerformer.h"
#import "LTProjectsController.h"
#import "LTTableView.h"
#import "LTTextPerformer.h"
#import "LTCommandsController.h"
#import "LTBasicPerformer.h"
#import "LTSnippetsController.h"
#import "LTVariousPerformer.h"
#import "LTProject.h"

@implementation LTDragAndDropController

static id sharedInstance = nil;

+ (LTDragAndDropController *)sharedInstance
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
		
		movedDocumentType = @"LTMovedDocumentType";
		movedSnippetType = @"LTMovedSnippetType";
		movedCommandType = @"LTMovedCommandType";
    }
    return sharedInstance;
}


- (BOOL)tableView:(NSTableView *)aTableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard
{
	NSArray *typesArray;
	if (aTableView == [LTCurrentProject documentsTableView]) {		
		typesArray = [NSArray arrayWithObjects:movedDocumentType, nil];
		
		NSMutableArray *uriArray = [NSMutableArray array];
		NSArray *arrangedObjects = [[LTCurrentProject documentsArrayController] arrangedObjects];
		NSInteger currentIndex = [rowIndexes firstIndex];
		while (currentIndex != NSNotFound) {
			[uriArray addObject:[LTBasic uriFromObject:[arrangedObjects objectAtIndex:currentIndex]]];
			currentIndex = [rowIndexes indexGreaterThanIndex:currentIndex];
		}
		
		[pboard declareTypes:typesArray owner:self];
		[pboard setData:[NSArchiver archivedDataWithRootObject:[NSArray arrayWithObjects:rowIndexes, uriArray, nil]] forType:movedDocumentType];
		
		return YES;
		
	} else if (aTableView == [[LTSnippetsController sharedInstance] snippetsTableView]) {
		typesArray = [NSArray arrayWithObjects:NSStringPboardType, movedSnippetType, nil];
		
		NSMutableString *string = [NSMutableString stringWithString:@""];
		NSMutableArray *uriArray = [NSMutableArray array];
		NSArray *arrangedObjects = [[[LTSnippetsController sharedInstance] snippetsArrayController] arrangedObjects];
		NSInteger currentIndex = [rowIndexes firstIndex];
		while (currentIndex != NSNotFound) {
			NSRange selectedRange = [LTCurrentTextView selectedRange];
			NSString *selectedText = [[LTCurrentTextView string] substringWithRange:selectedRange];
			if (selectedText == nil) {
				selectedText = @"";
			}
			NSMutableString *insertString = [NSMutableString stringWithString:[[arrangedObjects objectAtIndex:currentIndex] valueForKey:@"text"]];
			[insertString replaceOccurrencesOfString:@"%%s" withString:selectedText options:NSLiteralSearch range:NSMakeRange(0, [insertString length])];
			
			[string appendString:insertString];
			[uriArray addObject:[LTBasic uriFromObject:[arrangedObjects objectAtIndex:currentIndex]]];
			currentIndex = [rowIndexes indexGreaterThanIndex:currentIndex];
		}
		
		[pboard declareTypes:typesArray owner:self];
		[pboard setString:string forType:NSStringPboardType];
		[pboard setData:[NSArchiver archivedDataWithRootObject:[NSArray arrayWithObjects:rowIndexes, uriArray, nil]] forType:movedSnippetType];
		
		return YES;
		
	} else if (aTableView == [[LTCommandsController sharedInstance] commandsTableView]) {
		typesArray = [NSArray arrayWithObjects:NSStringPboardType, movedCommandType, nil];
		
		NSMutableString *string = [NSMutableString stringWithString:@""];
		NSMutableArray *uriArray = [NSMutableArray array];
		NSArray *arrangedObjects = [[[LTCommandsController sharedInstance] commandsArrayController] arrangedObjects];
		NSInteger currentIndex = [rowIndexes firstIndex];
		while (currentIndex != NSNotFound) {
			NSRange selectedRange = [LTCurrentTextView selectedRange];
			NSString *selectedText = [[LTCurrentTextView string] substringWithRange:selectedRange];
			if (selectedText == nil) {
				selectedText = @"";
			}
			NSMutableString *insertString = [NSMutableString stringWithString:[[arrangedObjects objectAtIndex:currentIndex] valueForKey:@"text"]];
			[insertString replaceOccurrencesOfString:@"%%s" withString:selectedText options:NSLiteralSearch range:NSMakeRange(0, [insertString length])];
			
			[string appendString:insertString];
			[uriArray addObject:[LTBasic uriFromObject:[arrangedObjects objectAtIndex:currentIndex]]];
			currentIndex = [rowIndexes indexGreaterThanIndex:currentIndex];
		}
		
		[pboard declareTypes:typesArray owner:self];
		[pboard setString:string forType:NSStringPboardType];
		[pboard setData:[NSArchiver archivedDataWithRootObject:[NSArray arrayWithObjects:rowIndexes, uriArray, nil]] forType:movedCommandType];
		
		return YES;
		
	} else {
		return NO;
	}
}


- (NSDragOperation)tableView:(NSTableView *)aTableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation
{
	if (aTableView == [LTCurrentProject documentsTableView]) {
		if ([info draggingSource] == [LTCurrentProject documentsTableView]) {
			[aTableView setDropRow:row dropOperation:NSTableViewDropAbove];
			return NSDragOperationMove;
		} else {
			[aTableView setDropRow:[[[LTCurrentProject documentsArrayController] arrangedObjects] count] dropOperation:NSTableViewDropAbove];
			return NSDragOperationCopy;
		}
		
	} else if (aTableView == [[LTSnippetsController sharedInstance] snippetsTableView]) {
		[aTableView setDropRow:row dropOperation:NSTableViewDropAbove];
	 	return NSDragOperationCopy;
		
	} else if (aTableView == [[LTSnippetsController sharedInstance] snippetCollectionsTableView]) {
		if ([info draggingSource] == [[LTSnippetsController sharedInstance] snippetsTableView]) {
			[aTableView setDropRow:row dropOperation:NSTableViewDropOn];
			return NSDragOperationMove;
		} else {
			[aTableView setDropRow:[[[[LTSnippetsController sharedInstance] snippetCollectionsArrayController] arrangedObjects] count] dropOperation:NSTableViewDropAbove];
			return NSDragOperationCopy;
		}
		return NSDragOperationCopy;
		
	} else if (aTableView == [[LTCommandsController sharedInstance] commandsTableView]) {
		[aTableView setDropRow:row dropOperation:NSTableViewDropAbove];
	 	return NSDragOperationCopy;
		
	} else if (aTableView == [[LTCommandsController sharedInstance] commandCollectionsTableView]) {
		if ([info draggingSource] == [[LTCommandsController sharedInstance] commandsTableView]) {
			[aTableView setDropRow:row dropOperation:NSTableViewDropOn];
			return NSDragOperationMove;
		} else {
			[aTableView setDropRow:[[[[LTCommandsController sharedInstance] commandCollectionsArrayController] arrangedObjects] count] dropOperation:NSTableViewDropAbove];
			return NSDragOperationCopy;
		}
		return NSDragOperationCopy;
		
	} else if ([aTableView isKindOfClass:[LTTableView class]]) {		
		[aTableView setDropRow:row dropOperation:NSTableViewDropAbove];
		return NSDragOperationMove;
	}
	
	return NSDragOperationNone;
}


- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation
{
	if (row < 0) {
		row = 0;
	}

    // Documents list
	if (aTableView == [LTCurrentProject documentsTableView]) {
		if ([info draggingSource] == [LTCurrentProject documentsTableView]) {
			if (![[[info draggingPasteboard] types] containsObject:movedDocumentType]) {
				return NO;
			}
			NSArrayController *arrayController = [LTCurrentProject documentsArrayController];
			
			NSArray *pasteboardData = [NSUnarchiver unarchiveObjectWithData:[[info draggingPasteboard] dataForType:movedDocumentType]];
			NSIndexSet *rowIndexes = [pasteboardData objectAtIndex:0];
			NSArray *uriArray = [pasteboardData objectAtIndex:1];
			[self moveObjects:uriArray inArrayController:arrayController fromIndexes:rowIndexes toIndex:row];
			
			[LTCurrentProject documentsListHasUpdated];
			
			return YES;
			
		}

		NSArray *filesToImport = [[info draggingPasteboard] propertyListForType:NSFilenamesPboardType];
		if (filesToImport != nil && aTableView == [LTCurrentProject documentsTableView]) {
			[LTOpenSave openAllTheseFiles:filesToImport];
			return YES;
		}
		
		NSString *textToImport = (NSString *)[[info draggingPasteboard] stringForType:NSStringPboardType];
		if (textToImport != nil && aTableView == [LTCurrentProject documentsTableView]) {
			[LTCurrentProject createNewDocumentWithContents:textToImport];
			return YES;
		}
		
	// Snippets
	} else if (aTableView == [[LTSnippetsController sharedInstance] snippetsTableView]) {
		
		NSString *textToImport = (NSString *)[[info draggingPasteboard] stringForType:NSStringPboardType];
		if (textToImport != nil) {
			
			id item = [[LTSnippetsController sharedInstance] performInsertNewSnippet];
			
			[item setValue:textToImport forKey:@"text"];
			if ([textToImport length] > SNIPPET_NAME_LENGTH) {
				[item setValue:[LTText replaceAllNewLineCharactersWithSymbolInString:[textToImport substringWithRange:NSMakeRange(0, SNIPPET_NAME_LENGTH)]] forKey:@"name"];
			} else {
				[item setValue:textToImport forKey:@"name"];
			}
			
			return YES;
		} else {
			return NO;
		}		
	
	// Snippet collections
	} else if (aTableView == [[LTSnippetsController sharedInstance] snippetCollectionsTableView]) {
		NSArray *filesToImport = [[info draggingPasteboard] propertyListForType:NSFilenamesPboardType];
		
		if (filesToImport != nil) {
			[LTOpenSave openAllTheseFiles:filesToImport];
			return YES;
		}
		
		if ([info draggingSource] == [[LTSnippetsController sharedInstance] snippetsTableView]) {
			if (![[[info draggingPasteboard] types] containsObject:movedSnippetType]) {
				return NO;
			}
			
			NSArray *pasteboardData = [NSUnarchiver unarchiveObjectWithData:[[info draggingPasteboard] dataForType:movedSnippetType]];
			NSArray *uriArray = [pasteboardData objectAtIndex:1];
			
			id collection = [[[[LTSnippetsController sharedInstance] snippetCollectionsArrayController] arrangedObjects] objectAtIndex:row];
			
			id item;
			for (item in uriArray) {
				[[collection mutableSetValueForKey:@"snippets"] addObject:[LTBasic objectFromURI:item]];
			}
			
			[[[LTSnippetsController sharedInstance] snippetsArrayController] rearrangeObjects];

			return YES;
		}
		
		
	// Commands
	} else if (aTableView == [[LTCommandsController sharedInstance] commandsTableView]) {
		
		NSString *textToImport = (NSString *)[[info draggingPasteboard] stringForType:NSStringPboardType];
		if (textToImport != nil) {
			
			id item = [[LTCommandsController sharedInstance] performInsertNewCommand];
			
			[item setValue:textToImport forKey:@"text"];
			if ([textToImport length] > SNIPPET_NAME_LENGTH) {
				[item setValue:[LTText replaceAllNewLineCharactersWithSymbolInString:[textToImport substringWithRange:NSMakeRange(0, SNIPPET_NAME_LENGTH)]] forKey:@"name"];
			} else {
				[item setValue:textToImport forKey:@"name"];
			}
			
			return YES;
		} else {
			return NO;
		}		
		
	// Command collections
	} else if (aTableView == [[LTCommandsController sharedInstance] commandCollectionsTableView]) {

		NSArray *filesToImport = [[info draggingPasteboard] propertyListForType:NSFilenamesPboardType];
		
		if (filesToImport != nil) {
			[LTOpenSave openAllTheseFiles:filesToImport];
			return YES;
		}
		
		if ([info draggingSource] == [[LTCommandsController sharedInstance] commandsTableView]) {
			if (![[[info draggingPasteboard] types] containsObject:movedCommandType]) {
				return NO;
			}
			
			NSArray *pasteboardData = [NSUnarchiver unarchiveObjectWithData:[[info draggingPasteboard] dataForType:movedCommandType]];
			NSArray *uriArray = [pasteboardData objectAtIndex:1];
			
			id collection = [[[[LTCommandsController sharedInstance] commandCollectionsArrayController] arrangedObjects] objectAtIndex:row];
			
			id item;
			for (item in uriArray) {
				[[collection mutableSetValueForKey:@"commands"] addObject:[LTBasic objectFromURI:item]];
			}
			
			[[[LTCommandsController sharedInstance] commandsArrayController] rearrangeObjects];
			
			return YES;
		}
		
	// From another project
	} else if ([[info draggingSource] isKindOfClass:[LTTableView class]]) {
		if (![[[info draggingPasteboard] types] containsObject:movedDocumentType]) {
			return NO;
		}
		
		NSArray *array = [[LTProjectsController sharedDocumentController] documents];
		id destinationProject;
		for (destinationProject in array) {
			if (aTableView == [destinationProject documentsTableView]) {
				break;
			}
		}
		
		if (destinationProject == nil) {
			return NO;
		}
		
		NSArrayController *destinationArrayController = [destinationProject documentsArrayController];
		NSArray *pasteboardData = [NSUnarchiver unarchiveObjectWithData:[[info draggingPasteboard] dataForType:movedDocumentType]];
		NSArray *uriArray = [pasteboardData objectAtIndex:1];
		id document = [LTBasic objectFromURI:[uriArray objectAtIndex:0]];
		[(NSMutableSet *)[destinationProject documents] addObject:document];
		[document setValue:[NSNumber numberWithInteger:row] forKey:@"sortOrder"];
		[LTVarious fixSortOrderNumbersForArrayController:destinationArrayController overIndex:row];
		[destinationArrayController rearrangeObjects];
		[destinationProject selectDocument:document];
		[destinationProject documentsListHasUpdated];
		[LTCurrentProject documentsListHasUpdated];
		
		return YES;	
		
	
	// To a table view which is not active
	} else if ([aTableView isKindOfClass:[LTTableView class]]) {
		
		NSArray *filesToImport = [[info draggingPasteboard] propertyListForType:NSFilenamesPboardType];
		
		if (filesToImport != nil) {
			[[aTableView window] makeMainWindow];
			NSArray *array = [[LTProjectsController sharedDocumentController] documents];
			for (id item in array) {
				if (aTableView == [item documentsTableView]) {
					[[LTProjectsController sharedDocumentController] setCurrentProject:item];
					break;
				}
			}
			
			if (LTCurrentProject != nil) {
				[LTOpenSave openAllTheseFiles:filesToImport];
				[[LTProjectsController sharedDocumentController] setCurrentProject:nil];
				return YES;
			}
		}
		
		return NO;
	}
	
	
    return NO;
}


- (void)moveObjects:(NSArray *)objects inArrayController:(NSArrayController *)arrayController fromIndexes:(NSIndexSet *)rowIndexes toIndex:(NSInteger)insertIndex
{
	NSMutableArray *arrangedObjects = [NSMutableArray arrayWithArray:[arrayController arrangedObjects]]; 
	
	if (arrangedObjects == nil || objects == nil) {
		return; 
	} 
	
	NSUInteger currentIndex = [rowIndexes firstIndex];
	while (currentIndex != NSNotFound) {
		[arrangedObjects replaceObjectAtIndex:currentIndex withObject:[NSNull null]]; 
		currentIndex = [rowIndexes indexGreaterThanIndex:currentIndex];
	}
	
	NSEnumerator *enumerator = [objects reverseObjectEnumerator]; 
	id item;
	for (item in enumerator) {
		[arrangedObjects insertObject:[LTBasic objectFromURI:item] atIndex:insertIndex];
	}

	[arrangedObjects removeObject:[NSNull null]];
	
	NSInteger index = 0;
	for (item in arrangedObjects) {
		[item setValue:[NSNumber numberWithInteger:index] forKey:@"sortOrder"];
		index++;
	}
	
	[arrayController setContent:arrangedObjects];
}

@end
