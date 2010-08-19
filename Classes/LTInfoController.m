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

#import "NSString+Literate.h"
#import "LTInfoController.h"
#import "LTProjectsController.h"
#import "LTBasicPerformer.h"
#import "LTInterfacePerformer.h"
#import "LTTextView.h"
#import "LTVariousPerformer.h"


@implementation LTInfoController

@synthesize infoWindow;

static id sharedInstance = nil;

+ (LTInfoController *)sharedInstance
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


- (void)openInfoWindow
{
	if (infoWindow == nil) {
		[NSBundle loadNibNamed:@"LTInfo.nib" owner:self];
		
	}
	
	if ([infoWindow isVisible] == NO) {
		[self refreshInfo];
		[infoWindow makeKeyAndOrderFront:self];
	} else {
		[infoWindow orderOut:nil];
	}
}


- (void)refreshInfo
{
	id document = LTCurrentDocument;
	if (document == nil) {
		NSBeep();
		return;			
	}
	
	[titleTextField setStringValue:[document valueForKey:@"name"]];
	if ([[document valueForKey:@"isNewDocument"] boolValue] == YES || [document valueForKey:@"path"] == nil) {
		NSImage *image = [NSImage imageNamed:@"LTDocumentIcon"];
		[image setSize:NSMakeSize(64.0, 64.0)];
		NSArray *array = [image representations];
		for (id item in array) {
			[(NSImageRep *)item setSize:NSMakeSize(64.0, 64.0)];
		}
		[iconImageView setImage:image];
		
	} else {
		[iconImageView setImage:[[NSWorkspace sharedWorkspace] iconForFile:[document valueForKey:@"path"]]];
	}
	
	NSDictionary *fileAttributes = [document valueForKey:@"fileAttributes"];
	
	if (fileAttributes != nil) {
		[fileSizeTextField setStringValue:[NSString stringWithFormat:@"%@ %@", [LTBasic thousandFormatedStringFromNumber:[NSNumber numberWithLongLong:[fileAttributes fileSize]]], NSLocalizedString(@"bytes", @"The name for bytes in the info window")]];
		[whereTextField setStringValue:[[document valueForKey:@"path"] stringByDeletingLastPathComponent]];
		[createdTextField setStringValue:[NSString dateStringForDate:(NSCalendarDate *)[fileAttributes fileCreationDate] formatIndex:[[LTDefaults valueForKey:@"StatusBarLastSavedFormatPopUp"] integerValue]]];
		[modifiedTextField setStringValue:[NSString dateStringForDate:(NSCalendarDate *)[fileAttributes fileModificationDate] formatIndex:[[LTDefaults valueForKey:@"StatusBarLastSavedFormatPopUp"] integerValue]]];
		[creatorTextField setStringValue:NSFileTypeForHFSTypeCode([fileAttributes fileHFSCreatorCode])];
		[typeTextField setStringValue:NSFileTypeForHFSTypeCode([fileAttributes fileHFSTypeCode])];
		[ownerTextField setStringValue:[fileAttributes fileOwnerAccountName]];
		[groupTextField setStringValue:[fileAttributes fileGroupOwnerAccountName]];
		[permissionsTextField setStringValue:[self stringFromPermissions:[fileAttributes filePosixPermissions]]];
	}
	
	
	LTTextView *textView = LTCurrentTextView;
	if (textView == nil) {
		textView = [document valueForKey:@"firstTextView"];
	}
	NSString *text = [textView string];;
	
	[lengthTextField setStringValue:[LTBasic thousandFormatedStringFromNumber:[NSNumber numberWithUnsignedInteger:[text length]]]];
	
	NSArray *array = [textView selectedRanges];
	
	NSInteger selection = 0;
	for (id item in array) {
		selection = selection + [item rangeValue].length;
	}
	if (selection == 0) {
		[selectionTextField setStringValue:@""];
	} else {
		[selectionTextField setStringValue:[LTBasic thousandFormatedStringFromNumber:[NSNumber numberWithInteger:selection]]];
	}
	
	NSRange selectionRange;
	if (textView == nil) {
		selectionRange = NSMakeRange(0,0);
	} else {
		selectionRange = [textView selectedRange];
	}
	[positionTextField setStringValue:[NSString stringWithFormat:@"%@\\%@", [LTBasic thousandFormatedStringFromNumber:[NSNumber numberWithInteger:(selectionRange.location - [text lineRangeForRange:selectionRange].location)]], [LTBasic thousandFormatedStringFromNumber:[NSNumber numberWithInteger:selectionRange.location]]]];
	
	NSInteger index;
	NSInteger lineNumber;
	NSInteger lastCharacter = [text length];
	for (index = 0, lineNumber = 0; index < lastCharacter; lineNumber++) {
		index = NSMaxRange([text lineRangeForRange:NSMakeRange(index, 0)]);
	}
	if (lastCharacter > 0) {
		unichar lastGlyph = [text characterAtIndex:lastCharacter - 1];
		if (lastGlyph == '\n' || lastGlyph == '\r') {
			lineNumber++;
		}
	}


	[linesTextField setStringValue:[NSString stringWithFormat:@"%d/%d", [LTInterface currentLineNumber], lineNumber]];

	NSArray *functions = [LTInterface allFunctions];
	
	if ([functions count] == 0) {
		[functionTextField setStringValue:@""];
	} else {
		index = [LTInterface currentFunctionIndexForFunctions:functions];
		if (index == -1) {
			[functionTextField setStringValue:@""];
		} else {
			[functionTextField setStringValue:[[functions objectAtIndex:index] valueForKey:@"name"]];
		}
	}
	
	if (selection > 1) {
		[wordsTextField setStringValue:[NSString stringWithFormat:@"%@ (%@)", [LTBasic thousandFormatedStringFromNumber:[NSNumber numberWithInteger:[[NSSpellChecker sharedSpellChecker] countWordsInString:[text substringWithRange:selectionRange] language:nil]]], [LTBasic thousandFormatedStringFromNumber:[NSNumber numberWithInteger:[[NSSpellChecker sharedSpellChecker] countWordsInString:text language:nil]]]]];
	} else {
		[wordsTextField setStringValue:[NSString stringWithFormat:@"%@", [LTBasic thousandFormatedStringFromNumber:[NSNumber numberWithInteger:[[NSSpellChecker sharedSpellChecker] countWordsInString:text language:nil]]]]];
	}

	[encodingTextField setStringValue:[document valueForKey:@"encodingName"]];
	
	[syntaxTextField setStringValue:[document valueForKey:@"syntaxDefinition"]];

	if ([document valueForKey:@"path"] != nil) {
		[spotlightTextField setStringValue:[LTVarious performCommand:[NSString stringWithFormat:@"/usr/bin/mdls '%@'", [document valueForKey:@"path"]]]];
	} else {
		[spotlightTextField setStringValue:@""];
	}
}


- (NSString *)stringFromPermissions:(NSUInteger)permissions 
{
    char permissionsString[10];
	
#if __LP64__
	strmode((short)permissions, permissionsString);
#else
	strmode(permissions, permissionsString);
#endif	
	
	NSMutableString *returnString = [NSMutableString stringWithUTF8String:permissionsString];
	[returnString deleteCharactersInRange:NSMakeRange(0, 1)];
	[returnString insertString:@" " atIndex:3];
	[returnString insertString:@" " atIndex:7];
	[returnString insertString:@" " atIndex:11];
	
    return returnString;
}

@end
