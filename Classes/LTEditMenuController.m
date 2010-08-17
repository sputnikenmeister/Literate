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

#import "LTEditMenuController.h"
#import "LTProjectsController.h"
#import "LTAdvancedFindController.h"
#import "LTProject.h"
#import "LTTextView.h"
#import "LTProject+ToolbarController.h"

@implementation LTEditMenuController


//- (IBAction)selectAction:(id)sender
//{
//	NSTextView *textView = LTCurrentTextView;
//	NSInteger tag = [sender tag];
//	if (tag == 1) {
//		[textView selectWord:nil];
//	} else if (tag == 11) {
//		[textView selectLine:nil];
//	} else if (tag == 111) {
//		[textView selectParagraph:nil];
//	}
//}


- (BOOL)validateMenuItem:(NSMenuItem *)anItem
{
	BOOL enableMenuItem = YES;
	NSInteger tag = [anItem tag];
	if (tag == 1 || tag == 11 || tag == 111) { // All items that should only be active when there's text to select/delete
		if (LTCurrentTextView == nil) {
			enableMenuItem = NO;
		}
	} else if (tag == 2) { // Live Find
		if ([LTCurrentProject areThereAnyDocuments] == NO) {
			enableMenuItem = NO;
		}
	}
	
	return enableMenuItem;
}


- (IBAction)advancedFindReplaceAction:(id)sender
{
	[[LTAdvancedFindController sharedInstance] showAdvancedFindWindow];
}


- (IBAction)liveFindAction:(id)sender
{
	id firstResponder = [LTCurrentWindow firstResponder];
	[LTCurrentWindow makeFirstResponder:[LTCurrentProject liveFindSearchField]];
	NSText *fieldEditor = (NSText *)[[[LTCurrentProject liveFindSearchField] window] firstResponder];
	
	if (firstResponder == fieldEditor) {
		[LTCurrentWindow makeFirstResponder:[LTCurrentProject lastTextViewInFocus]]; // If the search field is already in focus switch it back to the text, this allows the user to use the same key command to get to the search field and get back to the selected text after the search is complete
	} else {
		[LTCurrentProject prepareForLiveFind];
	}
}


//- (IBAction)deleteLineAction:(id)sender
//{
//	id firstResponder = [LTCurrentWindow firstResponder];
//	if ([firstResponder isKindOfClass:[LTTextView class]]) {
//		NSEnumerator *enumerator = [[firstResponder selectedRanges] reverseObjectEnumerator];
//		for (id item in enumerator) {
//			NSRange lineRange = [[firstResponder string] lineRangeForRange:[item rangeValue]];
//			if ([firstResponder shouldChangeTextInRange:lineRange replacementString:@""]) { // Do it this way to mark it as an Undo
//				[firstResponder replaceCharactersInRange:lineRange withString:@""];
//				[firstResponder didChangeText];
//			}
//		}
//	}
//}
//
//
//- (IBAction)deleteToBeginningOfLineAction:(id)sender
//{
//	id firstResponder = [LTCurrentWindow firstResponder];
//	if ([firstResponder isKindOfClass:[LTTextView class]]) {
//		NSRange selectedRange = [firstResponder selectedRange];
//		if (selectedRange.length == 0) {
//			NSRange lineRange = [[firstResponder string] lineRangeForRange:selectedRange];
//			if ([firstResponder shouldChangeTextInRange:NSMakeRange(lineRange.location, selectedRange.location - lineRange.location) replacementString:@""]) { // Do it this way to mark it as an Undo
//				[firstResponder replaceCharactersInRange:NSMakeRange(lineRange.location, selectedRange.location - lineRange.location) withString:@""];
//				[firstResponder didChangeText];
//			}
//		}
//	}
//}
//
//
//- (IBAction)deleteToEndOfLineAction:(id)sender
//{
//	id firstResponder = [LTCurrentWindow firstResponder];
//	if ([firstResponder isKindOfClass:[LTTextView class]]) {
//		NSRange selectedRange = [firstResponder selectedRange];
//		if (selectedRange.length == 0) {
//			NSRange lineRange = [[firstResponder string] lineRangeForRange:selectedRange];
//			if ([firstResponder shouldChangeTextInRange:NSMakeRange(selectedRange.location, NSMaxRange(lineRange) - selectedRange.location) replacementString:@""]) { // Do it this way to mark it as an Undo
//				[firstResponder replaceCharactersInRange:NSMakeRange(selectedRange.location, NSMaxRange(lineRange) - selectedRange.location) withString:@""];
//				[firstResponder didChangeText];
//			}
//		}
//	}
//}

@end
