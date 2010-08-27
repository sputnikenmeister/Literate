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

#import "LTInterfacePerformer.h"
#import "LTGutterTextView.h"
#import "LTTextView.h"
#import "LTTextMenuController.h"
#import "LTProjectsController.h"
#import "LTLineNumbers.h"
#import "LTLayoutManager.h"
#import "LTSingleDocumentWindowDelegate.h"
#import "LTAdvancedFindController.h"
#import "LTBasicPerformer.h"
#import "LTMainController.h"
#import "LTProject.h"
#import "LTSyntaxColouring.h"
#import "LTFullScreenWindow.h"

#import "ICUPattern.h"
#import "ICUMatcher.h"
#import "NSStringICUAdditions.h"


@implementation LTInterfacePerformer

@synthesize fullScreenWindow, fullScreenDocument, defaultIcon, defaultUnsavedIcon;

static id sharedInstance = nil;

+ (LTInterfacePerformer *)sharedInstance
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
		
		statusBarBetweenString = [[NSString alloc] initWithFormat:@"  %C  ", 0x00B7];
		statusBarLastSavedString = NSLocalizedString(@"Saved", @"Saved, in the status bar");
		statusBarDocumentLengthString = NSLocalizedString(@"Length", @"Length, in the status bar");
		statusBarSelectionLengthString = NSLocalizedString(@"Selection", @"Selection, in the status bar");
		statusBarPositionString = NSLocalizedString(@"Position", @"Position, in the status bar");
		statusBarSyntaxDefinitionString = NSLocalizedString(@"Syntax", @"Syntax, in the status bar");
		statusBarEncodingString = NSLocalizedString(@"Encoding", @"Encoding, in the status bar");
		
		defaultIcon = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"LTDefaultIcon" ofType:@"png"]];
		defaultUnsavedIcon = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"LTDefaultUnsavedIcon" ofType:@"png"]];
    }
    return sharedInstance;
}


- (void)goToFunctionOnLine:(id)sender
{
	NSInteger lineToGoTo = [sender tag];
	[[LTTextMenuController sharedInstance] performGoToLine:lineToGoTo];
}


- (void)createFirstViewForDocument:(id)document
{
	CGFloat gutterWidth = [[document valueForKey:@"firstGutterScrollView"] bounds].size.width;
	
	NSView *firstContentView = [LTCurrentProject firstContentView];
	NSScrollView *textScrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(gutterWidth, 
																				  0, 
																				  [firstContentView bounds].size.width - [[LTDefaults valueForKey:@"GutterWidth"] floatValue], 
																				  [firstContentView bounds].size.height)];
	[textScrollView setBorderType:NSNoBorder];
	[textScrollView setHasVerticalScroller:YES];
	[textScrollView setAutohidesScrollers:YES];
	[textScrollView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
	[[textScrollView contentView] setAutoresizesSubviews:YES];
	
	LTLineNumbers *lineNumbers = [[LTLineNumbers alloc] initWithDocument:document];
	[[NSNotificationCenter defaultCenter] addObserver:lineNumbers selector:@selector(viewBoundsDidChange:) name:NSViewBoundsDidChangeNotification object:[textScrollView contentView]];
	[document setValue:lineNumbers forKey:@"lineNumbers"];
	
	NSSize contentSize = [textScrollView contentSize];
	LTTextView *textView = [[LTTextView alloc] initWithFrame:NSMakeRect(0, 0, contentSize.width, contentSize.height)];
	
	if ([[LTDefaults valueForKey:@"LineWrapNewDocuments"] boolValue] == YES) 
	{
		[textScrollView setHasHorizontalScroller:NO];
		[textView setHorizontallyResizable:NO];
		[[textView textContainer] setWidthTracksTextView:YES];
		[[textView textContainer] setContainerSize:NSMakeSize(contentSize.width, FLT_MAX)];		 
	}
	else 
	{
		[textScrollView setHasHorizontalScroller:YES];
		[textView setHorizontallyResizable:YES];
		[[textView textContainer] setWidthTracksTextView:NO];
		[[textView textContainer] setContainerSize:NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX)];
	}
	
	[textScrollView setDocumentView:textView];

	NSScrollView *gutterScrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(0, 
																					0, 
																					gutterWidth,
																					contentSize.height)];
	[gutterScrollView setBorderType:NSNoBorder];
	[gutterScrollView setHasVerticalScroller:NO];
	[gutterScrollView setHasHorizontalScroller:NO];
	[gutterScrollView setAutoresizingMask:NSViewHeightSizable];
	[[gutterScrollView contentView] setAutoresizesSubviews:YES];
	
	LTGutterTextView *gutterTextView = [[LTGutterTextView alloc] initWithFrame:NSMakeRect(0, 0, 
																						  gutterWidth, 
																						  contentSize.height - 50)];
	[gutterScrollView setDocumentView:gutterTextView];
	
	[document setValue:textView forKey:@"firstTextView"];
	[document setValue:textScrollView forKey:@"firstTextScrollView"];
	[document setValue:gutterScrollView forKey:@"firstGutterScrollView"];
}


- (void)insertDocumentIntoSecondContentView:(id)document
{
	[LTCurrentProject setSecondDocument:document];
	NSView *secondContentView = [LTCurrentProject secondContentView];
	[self removeAllSubviewsFromView:secondContentView];
	
	NSTextStorage *textStorage = [[[document valueForKey:@"firstTextScrollView"] documentView] textStorage];
	LTLayoutManager *layoutManager = [[LTLayoutManager alloc] init];
	[textStorage addLayoutManager:layoutManager];
	[[document valueForKey:@"syntaxColouring"] setSecondLayoutManager:layoutManager];
	
	CGFloat gutterWidth = [[document valueForKey:@"firstGutterScrollView"] bounds].size.width;
	
	NSView *secondContentViewNavigationBar = [LTCurrentProject secondContentViewNavigationBar];
	CGFloat secondContentViewNavigationBarHeight = [secondContentViewNavigationBar bounds].size.height;
	
	NSScrollView *textScrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(gutterWidth, 
																				  secondContentViewNavigationBarHeight, 
																				  [secondContentView bounds].size.width - gutterWidth, 
																				  [secondContentView bounds].size.height - secondContentViewNavigationBarHeight - secondContentViewNavigationBarHeight)];
	[textScrollView setBorderType:NSNoBorder];
	[textScrollView setHasVerticalScroller:YES];
	[textScrollView setAutohidesScrollers:YES];
	[textScrollView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
	[[textScrollView contentView] setAutoresizesSubviews:YES];
	
	[[NSNotificationCenter defaultCenter] addObserver:[document valueForKey:@"lineNumbers"] 
											 selector:@selector(viewBoundsDidChange:) 
												 name:NSViewBoundsDidChangeNotification 
											   object:[textScrollView contentView]];
	
	NSSize contentSize = [textScrollView contentSize];
	NSTextContainer *container = [[NSTextContainer alloc] initWithContainerSize:contentSize];
	[layoutManager addTextContainer:container];
	
	LTTextView *textView = [[LTTextView alloc] initWithFrame:NSMakeRect(0, 0, contentSize.width, contentSize.height) 
											   textContainer:container];
	
	if ([[document valueForKey:@"isLineWrapped"] boolValue] == YES) 
	{
		[textScrollView setHasHorizontalScroller:NO];
		[textView setHorizontallyResizable:NO];
		[[textView textContainer] setContainerSize:NSMakeSize(contentSize.width/* - 2*/, CGFLOAT_MAX)];		 
		[[textView textContainer] setWidthTracksTextView:YES];
	} 
	else 
	{
		[textScrollView setHasHorizontalScroller:YES];
		[textView setHorizontallyResizable:YES];
		[[textView textContainer] setWidthTracksTextView:NO];
		[[textView textContainer] setContainerSize:NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX)];
	}
	[textView setDefaults];
	
	[textScrollView setDocumentView:textView];
	
	NSScrollView *gutterScrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(0, secondContentViewNavigationBarHeight, gutterWidth, contentSize.height)];
	[gutterScrollView setBorderType:NSNoBorder];
	[gutterScrollView setHasVerticalScroller:NO];
	[gutterScrollView setHasHorizontalScroller:NO];
	[gutterScrollView setAutoresizingMask:NSViewHeightSizable];
	[[gutterScrollView contentView] setAutoresizesSubviews:YES];
	
	LTGutterTextView *gutterTextView = [[LTGutterTextView alloc] initWithFrame:NSMakeRect(0, secondContentViewNavigationBarHeight, gutterWidth, contentSize.height)];
	[gutterScrollView setDocumentView:gutterTextView];
	
	[secondContentView addSubview:textScrollView];
	
	[textView setDelegate:[document valueForKey:@"syntaxColouring"]];
	[document setValue:textView forKey:@"secondTextView"];
	[document setValue:textScrollView forKey:@"secondTextScrollView"];
	[document setValue:gutterScrollView forKey:@"secondGutterScrollView"];
	
	[secondContentViewNavigationBar setFrame:NSMakeRect(0, 0, [secondContentView bounds].size.width, secondContentViewNavigationBarHeight)];
	[secondContentViewNavigationBar setAutoresizingMask:NSViewWidthSizable];
	[secondContentView addSubview:secondContentViewNavigationBar];
	
	NSRect visibleRect = [[[[document valueForKey:@"firstTextView"] enclosingScrollView] contentView] documentVisibleRect];
	NSRange visibleRange = [[[document valueForKey:@"firstTextView"] layoutManager] glyphRangeForBoundingRect:visibleRect 
																							  inTextContainer:[[document valueForKey:@"firstTextView"] textContainer]];
	[textView scrollRangeToVisible:visibleRange];
	
	[LTCurrentProject resizeViewsForDocument:document]; // To properly set the width of the line number gutter and to recolour the document
}


- (void)insertDocumentIntoThirdContentView:(id)document orderFront:(BOOL)orderFront
{
	if ([document valueForKey:@"singleDocumentWindow"] != nil) {
		[[document valueForKey:@"singleDocumentWindow"] makeKeyAndOrderFront:nil];
		return;
	}
	
	NSWindowController *windowController = [[NSWindowController alloc] initWithWindowNibName:@"LTSingleDocument"];
	
	NSWindow *window = [windowController window];

	// For some reason this code does not work, so save the frame manually in LTSingleDocumentWindowDelegate and use that
	//[windowController setShouldCascadeWindows:NO];
	//[windowController setWindowFrameAutosaveName:@"SingleDocumentWindow"];
	//[window setFrameAutosaveName:@"SingleDocumentWindow"];
	
	if ([LTDefaults valueForKey:@"SingleDocumentWindow"] != nil) {
		[window setFrame:NSRectFromString([LTDefaults valueForKey:@"SingleDocumentWindow"]) display:NO animate:NO];
	}
	
	if (orderFront == YES) {
		[window makeKeyAndOrderFront:nil];
	}
	
	NSView *thirdContentView = [window contentView];
	
	NSTextStorage *textStorage = [[[document valueForKey:@"firstTextScrollView"] documentView] textStorage];
	LTLayoutManager *layoutManager = [[LTLayoutManager alloc] init];
	[textStorage addLayoutManager:layoutManager];
	[[document valueForKey:@"syntaxColouring"] setThirdLayoutManager:layoutManager];
	
	CGFloat gutterWidth = [[document valueForKey:@"firstGutterScrollView"] bounds].size.width;	
	
	NSScrollView *textScrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(gutterWidth, -1, [thirdContentView bounds].size.width - gutterWidth, [thirdContentView bounds].size.height + 2)]; // +2 and -1 to remove extra line at the top and bottom
	
	[textScrollView setBorderType:NSNoBorder];
	[textScrollView setHasVerticalScroller:YES];
	[textScrollView setAutohidesScrollers:YES];
	[textScrollView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
	[[textScrollView contentView] setAutoresizesSubviews:YES];
	
	NSSize contentSize = [textScrollView contentSize];
	NSTextContainer *container = [[NSTextContainer alloc] initWithContainerSize:contentSize];
	[layoutManager addTextContainer:container];
		
	[[NSNotificationCenter defaultCenter] addObserver:[document valueForKey:@"lineNumbers"] 
											 selector:@selector(viewBoundsDidChange:) 
												 name:NSViewBoundsDidChangeNotification 
											   object:[textScrollView contentView]];
	
	LTTextView *textView = [[LTTextView alloc] initWithFrame:NSMakeRect(0, 0, contentSize.width, contentSize.height) textContainer:container];
	if ([[document valueForKey:@"isLineWrapped"] boolValue] == YES) 
	{
		
		[textScrollView setHasHorizontalScroller:NO];
		[textView setHorizontallyResizable:NO];
		[[textView textContainer] setWidthTracksTextView:YES];
		[[textView textContainer] setContainerSize:NSMakeSize(contentSize.width, CGFLOAT_MAX)];		 
	} 
	else 
	{
		[textScrollView setHasHorizontalScroller:YES];
		[textView setHorizontallyResizable:YES];
		[[textView textContainer] setContainerSize:NSMakeSize(FLT_MAX, FLT_MAX)];
		[[textView textContainer] setWidthTracksTextView:NO];
	}
	[textView setDefaults];
	
	[textScrollView setDocumentView:textView];
	
	NSScrollView *gutterScrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(0, -1, gutterWidth, contentSize.height)];
	[gutterScrollView setBorderType:NSNoBorder];
	[gutterScrollView setHasVerticalScroller:NO];
	[gutterScrollView setHasHorizontalScroller:NO];
	[gutterScrollView setAutoresizingMask:NSViewHeightSizable];
	[[gutterScrollView contentView] setAutoresizesSubviews:YES];
	
	LTGutterTextView *gutterTextView = [[LTGutterTextView alloc] initWithFrame:NSMakeRect(0, 0, gutterWidth, contentSize.height)];
	[gutterScrollView setDocumentView:gutterTextView];
	
	[thirdContentView addSubview:textScrollView];
	
	[textView setDelegate:[document valueForKey:@"syntaxColouring"]];
	[document setValue:textView forKey:@"thirdTextView"];
	[document setValue:textScrollView forKey:@"thirdTextScrollView"];
	[document setValue:gutterScrollView forKey:@"thirdGutterScrollView"];
	[document setValue:window forKey:@"singleDocumentWindow"];
	[document setValue:windowController forKey:@"singleDocumentWindowController"];
	
	[LTCurrentProject resizeViewsForDocument:document]; // To properly set the width of the line number gutter and to recolour the document
	
	[window setDelegate:[LTSingleDocumentWindowDelegate sharedInstance]];
	[window makeFirstResponder:textView];
}


- (void)insertDocumentIntoFourthContentView:(id)document
{	
	NSTextStorage *textStorage = [[[document valueForKey:@"firstTextScrollView"] documentView] textStorage];
	LTLayoutManager *layoutManager = [[LTLayoutManager alloc] init];
	[textStorage addLayoutManager:layoutManager];
	[[document valueForKey:@"syntaxColouring"] setFourthLayoutManager:layoutManager];
	
	CGFloat gutterWidth = [[document valueForKey:@"firstGutterScrollView"] bounds].size.width;
	
	NSView *fourthContentView = [[LTAdvancedFindController sharedInstance] resultDocumentContentView];
	
	NSScrollView *textScrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(gutterWidth, 0, [fourthContentView bounds].size.width - gutterWidth, [fourthContentView bounds].size.height)];
	
	[textScrollView setBorderType:NSNoBorder];
	[textScrollView setHasVerticalScroller:YES];
	[textScrollView setAutohidesScrollers:YES];
	[textScrollView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
	[[textScrollView contentView] setAutoresizesSubviews:YES];
	
	NSSize contentSize = [textScrollView contentSize];
	NSTextContainer *container = [[NSTextContainer alloc] initWithContainerSize:contentSize];
	[layoutManager addTextContainer:container];
	
	[[NSNotificationCenter defaultCenter] addObserver:[document valueForKey:@"lineNumbers"] selector:@selector(viewBoundsDidChange:) name:NSViewBoundsDidChangeNotification object:[textScrollView contentView]];
	
	LTTextView *textView = [[LTTextView alloc] initWithFrame:NSMakeRect(0, 0, contentSize.width, contentSize.height) textContainer:container];;
	if ([[document valueForKey:@"isLineWrapped"] boolValue] == YES) 
	{
		[textScrollView setHasHorizontalScroller:NO];
		[textView setHorizontallyResizable:NO];
		[[textView textContainer] setWidthTracksTextView:YES];
		[[textView textContainer] setContainerSize:NSMakeSize(contentSize.width, CGFLOAT_MAX)];		 
	} 
	else 
	{
		[textScrollView setHasHorizontalScroller:YES];
		[textView setHorizontallyResizable:YES];
		[[textView textContainer] setWidthTracksTextView:NO];
		[[textView textContainer] setContainerSize:NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX)];
	}
	[textView setDefaults];
	
	[textScrollView setDocumentView:textView];
	
	NSScrollView *gutterScrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(0, 0, gutterWidth, contentSize.height)];
	[gutterScrollView setBorderType:NSNoBorder];
	[gutterScrollView setHasVerticalScroller:NO];
	[gutterScrollView setHasHorizontalScroller:NO];
	[gutterScrollView setAutoresizingMask:NSViewHeightSizable];
	[[gutterScrollView contentView] setAutoresizesSubviews:YES];
	
	LTGutterTextView *gutterTextView = [[LTGutterTextView alloc] initWithFrame:NSMakeRect(0, 0, gutterWidth, contentSize.height)];
	[gutterScrollView setDocumentView:gutterTextView];
	
	[fourthContentView addSubview:textScrollView];
	
	[textView setDelegate:[document valueForKey:@"syntaxColouring"]];
	[document setValue:textView forKey:@"fourthTextView"];
	[document setValue:textScrollView forKey:@"fourthTextScrollView"];
	[document setValue:gutterScrollView forKey:@"fourthGutterScrollView"];
}


- (void)updateStatusBar
{
	if ([[LTDefaults valueForKey:@"ShowStatusBar"] boolValue] == NO) {
		return;
	}
	
	NSMutableString *statusBarString = [NSMutableString string];
	id document = LTCurrentDocument;
	LTTextView *textView = LTCurrentTextView;
	NSString *text = LTCurrentText;
	
	if ([[LTDefaults valueForKey:@"StatusBarShowWhenLastSaved"] boolValue] == YES)
		[statusBarString appendFormat:@"%@: %@", statusBarLastSavedString, [document valueForKey:@"lastSaved"]];
	
	if ([[LTDefaults valueForKey:@"StatusBarShowLength"] boolValue] == YES) {
		if ([[LTDefaults valueForKey:@"StatusBarShowWhenLastSaved"] boolValue] == YES) {
			[statusBarString appendString:statusBarBetweenString];
		}
		
		[statusBarString appendFormat:@"%@: %@", statusBarDocumentLengthString, [LTBasic thousandFormatedStringFromNumber:[NSNumber numberWithUnsignedInteger:[text length]]]];
	}
	
	NSArray *array = [textView selectedRanges];
	NSInteger selection = 0;
	for (id item in array) {
		selection = selection + [item rangeValue].length;
	}
	if ([[LTDefaults valueForKey:@"StatusBarShowSelection"] boolValue] == YES && selection > 1) {
		if ([[LTDefaults valueForKey:@"StatusBarShowWhenLastSaved"] boolValue] == YES || [[LTDefaults valueForKey:@"StatusBarShowLength"] boolValue] == YES) {
			[statusBarString appendString:statusBarBetweenString];
		}
		[statusBarString appendFormat:@"%@: %@", statusBarSelectionLengthString, [LTBasic thousandFormatedStringFromNumber:[NSNumber numberWithInteger:selection]]];
	}
	
	if ([[LTDefaults valueForKey:@"StatusBarShowPosition"] boolValue] == YES) {
		if ([[LTDefaults valueForKey:@"StatusBarShowWhenLastSaved"] boolValue] == YES || [[LTDefaults valueForKey:@"StatusBarShowLength"] boolValue] == YES || ([[LTDefaults valueForKey:@"StatusBarShowSelection"] boolValue] == YES && selection > 1)) {
			[statusBarString appendString:statusBarBetweenString];
		}
		NSRange selectionRange;
		if (textView == nil) {
			selectionRange = NSMakeRange(0,0);
		} else {
			selectionRange = [textView selectedRange];
		}
		[statusBarString appendFormat:@"%@: %@\\%@", statusBarPositionString, [LTBasic thousandFormatedStringFromNumber:[NSNumber numberWithInteger:(selectionRange.location - [text lineRangeForRange:selectionRange].location)]], [LTBasic thousandFormatedStringFromNumber:[NSNumber numberWithInteger:selectionRange.location]]];
	}
	
	if ([[LTDefaults valueForKey:@"StatusBarShowEncoding"] boolValue] == YES) {
		if ([[LTDefaults valueForKey:@"StatusBarShowWhenLastSaved"] boolValue] == YES || [[LTDefaults valueForKey:@"StatusBarShowLength"] boolValue] == YES || ([[LTDefaults valueForKey:@"StatusBarShowSelection"] boolValue] == YES && selection > 1) || [[LTDefaults valueForKey:@"StatusBarShowPosition"] boolValue] == YES) {
			[statusBarString appendString:statusBarBetweenString];
		}
		[statusBarString appendFormat:@"%@: %@", statusBarEncodingString, [document valueForKey:@"encodingName"]];
	}
	
	if ([[LTDefaults valueForKey:@"StatusBarShowSyntax"] boolValue] == YES && [[document valueForKey:@"isSyntaxColoured"] boolValue]) {
		if ([[LTDefaults valueForKey:@"StatusBarShowWhenLastSaved"] boolValue] == YES || ([[LTDefaults valueForKey:@"StatusBarShowSelection"] boolValue] == YES && selection > 1) || [[LTDefaults valueForKey:@"StatusBarShowPosition"] boolValue] == YES || [[LTDefaults valueForKey:@"StatusBarShowEncoding"] boolValue] == YES) {
			[statusBarString appendString:statusBarBetweenString];
		}
		[statusBarString appendFormat:@"%@: %@", statusBarSyntaxDefinitionString, [document valueForKey:@"syntaxDefinition"]];
	}
	
	[[LTCurrentProject statusBarTextField] setStringValue:statusBarString];
}


- (void)clearStatusBar
{
	[[LTCurrentProject statusBarTextField] setObjectValue:@""];
}


- (NSString *)whichDirectoryForOpen
{
	NSString *directory;
	if ([[LTDefaults valueForKey:@"OpenMatrix"] integerValue] == LTOpenSaveRemember) {
		directory = [LTDefaults valueForKey:@"LastOpenDirectory"];
	} else if ([[LTDefaults valueForKey:@"OpenMatrix"] integerValue] == LTOpenSaveCurrent) {
		if ([LTCurrentProject areThereAnyDocuments] == YES) {
			directory = [[LTCurrentDocument valueForKey:@"path"] stringByDeletingLastPathComponent]; 
		} else { 
			directory = NSHomeDirectory();
		}
	} else {
		directory = [LTDefaults valueForKey:@"OpenAlwaysUseTextField"];
	}
	
	return [directory stringByExpandingTildeInPath];
}


- (NSString *)whichDirectoryForSave
{
	NSString *directory;
	if ([[LTDefaults valueForKey:@"SaveMatrix"] integerValue] == LTOpenSaveRemember) {
		directory = [LTDefaults valueForKey:@"LastSaveAsDirectory"];
	} else if ([[LTDefaults valueForKey:@"SaveMatrix"] integerValue] == LTOpenSaveCurrent) {
		if ([[LTCurrentDocument valueForKey:@"isNewDocument"] boolValue] == NO) {
			directory = [[LTCurrentDocument valueForKey:@"path"] stringByDeletingLastPathComponent];
		} else { 
			directory = NSHomeDirectory();
		}
	} else {
		directory = [LTDefaults valueForKey:@"SaveAsAlwaysUseTextField"];
	}

	return [directory stringByExpandingTildeInPath];
}


- (void)removeAllSubviewsFromView:(NSView *)view
{
	[view setSubviews:[NSArray array]];
	//NSArray *array = [NSArray arrayWithArray:[view subviews]];
//	id item;
//	for (item in array) {
//		[item removeFromSuperview];
//		item = nil;
//	}
}


- (void)enterFullScreenForDocument:(id)document
{
	savedMainMenu = [NSApp mainMenu];
	fullScreenRect = [[NSScreen mainScreen] frame];	
	CGFloat width;
	if ([LTMain singleDocumentWindowWasOpenBeforeEnteringFullScreen] == YES) {
		width = [[document valueForKey:@"thirdTextView"] bounds].size.width * [[NSScreen mainScreen] userSpaceScaleFactor];
	} else {
		width = [[document valueForKey:@"firstTextView"] bounds].size.width * [[NSScreen mainScreen] userSpaceScaleFactor];
	}
	fullScreenRect = NSMakeRect(fullScreenRect.origin.x - ((width - fullScreenRect.size.width + [[document valueForKey:@"gutterWidth"] floatValue]) / 2), fullScreenRect.origin.y, width + [[document valueForKey:@"gutterWidth"] floatValue], fullScreenRect.size.height);

	fullScreenWindow = [[LTFullScreenWindow alloc] initWithContentRect:[[NSScreen mainScreen] frame] styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO screen:[NSScreen mainScreen]];
	
	if ([LTMain singleDocumentWindowWasOpenBeforeEnteringFullScreen] == NO) {
		NSRange sell = [[document valueForKey:@"firstTextView"] selectedRange];
		[[document valueForKey:@"thirdTextView"] scrollRangeToVisible:sell];
		[[document valueForKey:@"thirdTextView"] setSelectedRange:sell];
	}
	
	fullScreenDocument = document;
	[fullScreenWindow orderFront:nil];
	[fullScreenWindow enterFullScreen];
}


- (void)insertDocumentIntoFullScreenWindow
{
	CGDisplayCapture(kCGDirectMainDisplay);
	[fullScreenWindow setLevel:CGShieldingWindowLevel()];
	[fullScreenWindow setContentView:[[fullScreenDocument valueForKey:@"singleDocumentWindow"] contentView]];
	[fullScreenWindow makeKeyAndOrderFront:nil];
	[fullScreenWindow setFrame:fullScreenRect display:YES animate:YES];
	
	[[fullScreenDocument valueForKey:@"lineNumbers"] updateLineNumbersForClipView:[[fullScreenDocument valueForKey:@"thirdTextScrollView"] contentView] checkWidth:YES recolour:YES];
	[[fullScreenDocument valueForKey:@"singleDocumentWindow"] orderOut:nil];
	[fullScreenWindow makeFirstResponder:[fullScreenDocument valueForKey:@"thirdTextView"]];
}


- (void)returnFromFullScreen
{	
	SetSystemUIMode(kUIModeNormal, 0);
	[NSApp setMainMenu:savedMainMenu];
	
	[[fullScreenDocument valueForKey:@"singleDocumentWindow"] setContentView:[fullScreenWindow contentView]];
	
	[fullScreenWindow orderOut:self];
	fullScreenWindow = nil;
	
	CGDisplayRelease(kCGDirectMainDisplay);
	
	if ([LTMain singleDocumentWindowWasOpenBeforeEnteringFullScreen] == NO) {
		[[fullScreenDocument valueForKey:@"singleDocumentWindow"] performClose:nil];
	} else {
		[[fullScreenDocument valueForKey:@"singleDocumentWindow"] makeKeyAndOrderFront:nil];
		[[fullScreenDocument valueForKey:@"lineNumbers"] updateLineNumbersForClipView:[[fullScreenDocument valueForKey:@"thirdTextScrollView"] contentView] checkWidth:YES recolour:YES];
	}
	
	fullScreenDocument = nil;
	[LTMain setIsInFullScreenMode:NO];
}


- (void)insertAllFunctionsIntoMenu:(NSMenu *)menu
{
	NSArray *allFunctions = [self allFunctions];

	if ([allFunctions count] == 0) {
		NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Not applicable", @"Not applicable in insertAllFunctionsIntoMenu") action:nil keyEquivalent:@""];
		[menuItem setState:NSOffState];
		[menu insertItem:menuItem atIndex:0];
		return;
	}		
	
	NSEnumerator *enumerator = [allFunctions reverseObjectEnumerator];
	NSInteger index = [allFunctions count] - 1;
	NSInteger currentFunctionIndex = [self currentFunctionIndexForFunctions:allFunctions];
	NSString *spaceBetween;
	if ([allFunctions count] != 0) {
		if ([[[allFunctions lastObject] valueForKey:@"lineNumber"] integerValue] > 999) {
			spaceBetween = @"\t\t ";
		} else {
			spaceBetween = @"\t ";
		}
	} else {
		spaceBetween = @"";
	}
	for (id item in enumerator) {
		NSMenuItem *menuItem = [[NSMenuItem alloc] init];
		NSInteger lineNumber = [[item valueForKey:@"lineNumber"] integerValue];
		NSString *title = [NSString stringWithFormat:@"%d%@%@", lineNumber, spaceBetween, [item valueForKey:@"name"]];
		[menuItem setTitle:title];
		[menuItem setTarget:LTInterface];
		[menuItem setAction:@selector(goToFunctionOnLine:)];
		[menuItem setTag:lineNumber];
		if (index == currentFunctionIndex) {
			[menuItem setState:NSOnState];
		}
		index--;
		[menu insertItem:menuItem atIndex:0];
	}
}


- (NSArray *)allFunctions
{
	NSString *functionDefinition = [[LTCurrentDocument valueForKey:@"syntaxColouring"] functionDefinition];
	if (functionDefinition == nil || [functionDefinition isEqualToString:@""]) {
		return [NSArray array];
	}
	NSString *removeFromFunction = [[LTCurrentDocument valueForKey:@"syntaxColouring"] removeFromFunction];
	NSString *text = LTCurrentText;
	if (text == nil || [text isEqualToString:@""]) {
		return [NSArray array];
	}
	
	ICUPattern *pattern = [[ICUPattern alloc] initWithString:functionDefinition flags:(ICUCaseInsensitiveMatching | ICUMultiline)];
	ICUMatcher *matcher = [[ICUMatcher alloc] initWithPattern:pattern overString:text];

	NSInteger index = 0;
	NSInteger lineNumber = 0;
	NSMutableArray *returnArray = [NSMutableArray array];
	NSArray *keys = [[NSArray alloc] initWithObjects:@"lineNumber", @"name", nil];
	while ([matcher findNext]) {
		NSRange matchRange = [matcher rangeOfMatch];
		while (index <= matchRange.location + 1) {
			index = NSMaxRange([text lineRangeForRange:NSMakeRange(index, 0)]);
			lineNumber++;
		}
		
		NSMutableString *name = [NSMutableString stringWithString:[text substringWithRange:matchRange]];
		NSInteger nameIndex = -1;
		NSInteger nameLength = [name length];
		while (++nameIndex < nameLength && ([name characterAtIndex:nameIndex] == ' ' || [name characterAtIndex:nameIndex] == '\t' || [name characterAtIndex:nameIndex] == '\n' || [name characterAtIndex:nameIndex] == '\r')) {
			[name replaceCharactersInRange:NSMakeRange(nameIndex, 1) withString:@""];
			nameLength--;
			nameIndex--; // Move it backwards as it, so to speak, has moved forwards by deleting one
		}
		
		while (nameLength-- && ([name characterAtIndex:nameLength] == ' ' || [name characterAtIndex:nameLength] == '\t' || [name characterAtIndex:nameLength] == '{' || [name characterAtIndex:nameIndex] == '\n' || [name characterAtIndex:nameIndex] == '\r')) {
			[name replaceCharactersInRange:NSMakeRange(nameLength, 1) withString:@""];
		}
		
		[name replaceOccurrencesOfString:removeFromFunction withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [name length])];
		
		NSDictionary *dictionary = [[NSDictionary alloc] initWithObjects:[NSArray arrayWithObjects:[NSNumber numberWithInteger:lineNumber], name, nil] forKeys:keys];
		
		[returnArray addObject:dictionary];
	}
	
	return (NSArray *)returnArray;	
}


- (NSInteger)currentLineNumber
{
	NSTextView *textView = LTCurrentTextView;
	NSString *text = [textView string];
	NSInteger textLength = [text length];
	if (textView == nil || [text isEqualToString:@""]) {
		return 0;
	}
	
	NSRange selectedRange = [textView selectedRange];
	
	NSInteger index = 0;
	NSInteger	lineNumber = 0;
	while (index <= selectedRange.location && index < textLength) {
		index = NSMaxRange([text lineRangeForRange:NSMakeRange(index, 0)]);
		lineNumber++;
	}
	
	return lineNumber;	
}


- (NSInteger)currentFunctionIndexForFunctions:(NSArray *)functions
{
	NSInteger lineNumber = [LTInterface currentLineNumber];
	
	id item;
	NSInteger index = 0;
	for (item in functions) {
		NSInteger functionLineNumber = [[item valueForKey:@"lineNumber"] integerValue];
		if (functionLineNumber == lineNumber) {
			return index;
		} else if (functionLineNumber > lineNumber) {
			return index - 1;
		}
		index++;
	}
	
	return -1;	
}


- (void)removeAllTabBarObjectsForTabView:(NSTabView *)tabView
{
	NSArray *array = [tabView tabViewItems];
	for (id item in array) {
		[tabView removeTabViewItem:item];
	}
}


- (void)changeViewWithAnimationForWindow:(NSWindow *)window oldView:(NSView *)oldView newView:(NSView *)newView newRect:(NSRect)newRect
{	
    NSDictionary *windowResize = [NSDictionary dictionaryWithObjectsAndKeys:window, NSViewAnimationTargetKey, [NSValue valueWithRect:newRect], NSViewAnimationEndFrameKey, nil];
	
    NSDictionary *oldFadeOut = [NSDictionary dictionaryWithObjectsAndKeys:oldView, NSViewAnimationTargetKey, NSViewAnimationFadeOutEffect,	NSViewAnimationEffectKey, nil];
	
    NSDictionary *newFadeIn = [NSDictionary dictionaryWithObjectsAndKeys:newView, NSViewAnimationTargetKey, NSViewAnimationFadeInEffect, NSViewAnimationEffectKey, nil];
	
    NSArray *animations = [NSArray arrayWithObjects:windowResize, newFadeIn, oldFadeOut, nil];
	
    NSViewAnimation *animation = [[NSViewAnimation alloc] initWithViewAnimations:animations];
    [animation setAnimationBlockingMode:NSAnimationNonblocking];
    [animation setDuration:0.32];
    [animation startAnimation];
}


@end
