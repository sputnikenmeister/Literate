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

#import "NSImage+Literate.h"
#import "LTProject.h"
#import "LTBasicPerformer.h"
#import "LTProjectsController.h"
#import "LTDocumentsListCell.h"
#import "LTViewMenuController.h"
#import "LTDragAndDropController.h"
#import "LTApplicationDelegate.h"
#import "LTInterfacePerformer.h"
#import "LTViewMenuController.h"
#import "LTVariousPerformer.h"
#import "LTSyntaxColouring.h"
#import "LTFileMenuController.h"
#import "LTAdvancedFindController.h"
#import "LTProject+DocumentViewsController.h"
#import "LTProject+ToolbarController.h"
#import "LTLineNumbers.h"
#import "LTPrintViewController.h"
#import "LTPrintTextView.h"

@implementation LTProject

@synthesize firstDocument, secondDocument, lastTextViewInFocus, project, documentsArrayController, documentsTableView, firstContentView, secondContentView, statusBarTextField, mainSplitView, contentSplitView, secondContentViewNavigationBar, secondContentViewPopUpButton, leftDocumentsView, leftDocumentsTableView, tabBarControl, tabBarTabView;


- (id)init
{
    self = [super init];
    if (self) {
		project = [LTBasic createNewObjectForEntity:@"Project"];
		[[LTProjectsController sharedDocumentController] setCurrentProject:self];
    }
    return self;
}


#pragma mark -
#pragma mark Overrides


- (NSString *)windowNibName
{
    return @"LTProject";
}


- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
	[super windowControllerDidLoadNib:aController];
	
	[[[self windowControllers] objectAtIndex:0] setWindowFrameAutosaveName:@"LiterateProjectWindow"];
	[[self window] setFrameAutosaveName:@"LiterateProjectWindow"];
	//[[[self windowControllers] objectAtIndex:0] setShouldCascadeWindows:NO];
	
	[self setDefaultAppearanceAtStartup];
	
	[self setDefaultViews];
	
	[documentsTableView setDelegate:self];
	[mainSplitView setDelegate:self];
	//[mainSplitView setAutosaveName:@"MainSplitView"];
	[contentSplitView setDelegate:self];	
	
	[[LTViewMenuController sharedInstance] performCollapse];
	[self performSelector:@selector(performSetupAfterItIsCurrentProject) withObject:nil afterDelay:0.0];
	
	[[self window] setDelegate:self];
	
	[documentsTableView setDataSource:[LTDragAndDropController sharedInstance]];
	[documentsTableView registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, NSStringPboardType, @"LTMovedDocumentType", nil]];
	[documentsTableView setDraggingSourceOperationMask:(NSDragOperationCopy | NSDragOperationMove) forLocal:NO];
	
	
//	splitWindowImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"LTSplitWindowIcon" ofType:@"pdf" inDirectory:@"Toolbar Icons"]];
//	[[[splitWindowImage representations] objectAtIndex:0] setAlpha:YES];
//	closeSplitImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"LTCloseSplitIcon" ofType:@"pdf" inDirectory:@"Toolbar Icons"]];
//	[[[closeSplitImage representations] objectAtIndex:0] setAlpha:YES];
//	lineWrapImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"LTLineWrapIcon" ofType:@"pdf" inDirectory:@"Toolbar Icons"]];
//	[[[lineWrapImage representations] objectAtIndex:0] setAlpha:YES];
//	dontLineWrapImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"LTDontLineWrapIcon" ofType:@"pdf" inDirectory:@"Toolbar Icons"]];
//	[[[dontLineWrapImage representations] objectAtIndex:0] setAlpha:YES];
	saveImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"LTSaveIcon" ofType:@"pdf" inDirectory:@"Toolbar Icons"]];
	//[[[saveImage representations] objectAtIndex:0] setAlpha:YES];
	openDocumentImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"LTOpenIcon" ofType:@"pdf" inDirectory:@"Toolbar Icons"]];
	//[[[openDocumentImage representations] objectAtIndex:0] setAlpha:YES];
	newImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"LTNewIcon" ofType:@"pdf" inDirectory:@"Toolbar Icons"]];
	//[[[newImage representations] objectAtIndex:0] setAlpha:YES];
	closeImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"LTCloseIcon" ofType:@"pdf" inDirectory:@"Toolbar Icons"]];
	//[[[closeImage representations] objectAtIndex:0] setAlpha:YES];
	//preferencesImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"LTPreferencesIcon" ofType:@"pdf" inDirectory:@"Toolbar Icons"]];
	//[[[preferencesImage representations] objectAtIndex:0] setAlpha:YES];
	advancedFindImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"LTAdvancedFindIcon" ofType:@"pdf" inDirectory:@"Toolbar Icons"]];
	[[[advancedFindImage representations] objectAtIndex:0] setAlpha:YES];
	previewImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"LTPreviewIcon" ofType:@"pdf" inDirectory:@"Toolbar Icons"]];
	//[[[previewImage representations] objectAtIndex:0] setAlpha:YES];
	functionImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"LTFunctionIcon" ofType:@"pdf" inDirectory:@"Toolbar Icons"]];
	//[[[functionImage representations] objectAtIndex:0] setAlpha:YES];
	infoImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"LTInfoIcon" ofType:@"pdf" inDirectory:@"Toolbar Icons"]];
	//[[[infoImage representations] objectAtIndex:0] setAlpha:YES];
	
	NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier:@"ToolbarIdentifier"];
    [toolbar setShowsBaselineSeparator:YES];
	[toolbar setAllowsUserCustomization:YES];
    [toolbar setAutosavesConfiguration:YES];
    [toolbar setDisplayMode:NSToolbarDisplayModeDefault];
    [toolbar setDelegate:self];
	//[toolbar setSizeMode:NSToolbarSizeModeSmall];
    [[self window] setToolbar:toolbar];
	
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"sortOrder" ascending:YES];
	[documentsArrayController setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];

	if ([[LTApplicationDelegate sharedInstance] shouldCreateEmptyDocument] == YES) {
		id document = [self createNewDocumentWithContents:@""];
		[self insertDefaultIconsInDocument:document];
		[self selectionDidChange];
	}
}


- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{	
	return [NSArchiver archivedDataWithRootObject:[self dictionaryOfDocumentsInProject]];
}


- (BOOL)prepareSavePanel:(NSSavePanel *)savePanel
{
	[savePanel setDirectory:[LTInterface whichDirectoryForSave]];
	
	return YES;
}


- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
	return NO;
}

/**
 * This method creates a NSPrintOperation object to allow the user to print its document or to export it. It also
 * shows the Printing panel so the user can modify settings concerning the document printing. The printing operation
 * is executed in a new thread so the user can still interact with the application.
 */
- (NSPrintOperation *)printOperationWithSettings:(NSDictionary *)printSettings error:(NSError **)outError
{
	NSPrintInfo *printInfo = [self printInfo]; 
	LTPrintTextView *printTextView = [[LTPrintTextView alloc] initWithFrame:NSMakeRect([printInfo leftMargin], [printInfo bottomMargin], [printInfo paperSize].width - [printInfo leftMargin] - [printInfo rightMargin], [printInfo paperSize].height - [printInfo topMargin] - [printInfo bottomMargin])];
	
	NSPrintOperation *printOperation = [NSPrintOperation printOperationWithView:printTextView printInfo:printInfo];
    [printOperation setShowsPrintPanel:YES];
	[printOperation setCanSpawnSeparateThread:YES]; // Allow the printing process to be executed in a new thread.
    
    NSPrintPanel *printPanel = [printOperation printPanel];
	LTPrintViewController *printViewController = [[LTPrintViewController alloc] init];    
	[printPanel addAccessoryController:printViewController];
	
    return printOperation;
}


- (NSPrintInfo *)printInfo
{
    NSPrintInfo *printInfo = [super printInfo];
	
	CGFloat marginsMin = [[LTDefaults valueForKey:@"MarginsMin"] floatValue];
	if ([[LTDefaults valueForKey:@"PrintHeader"] boolValue] == YES) {
		[printInfo setTopMargin:(marginsMin + 22)];
	} else {
		[printInfo setTopMargin:marginsMin];
	}
	[printInfo setLeftMargin:marginsMin];	
	[printInfo setRightMargin:marginsMin];
	[printInfo setBottomMargin:marginsMin];
	
	[printInfo setHorizontallyCentered:NO];    
	[printInfo setVerticallyCentered:NO];
	
	[printInfo setHorizontalPagination:NSAutoPagination];
	[printInfo setVerticalPagination:NSAutoPagination];
	
    return printInfo;
}


#pragma mark -
#pragma mark Others

- (void)performSetupAfterItIsCurrentProject
{
	[[LTProjectsController sharedDocumentController] setCurrentProject:nil];
	
	[documentsTableView setTarget:self];
	[documentsTableView setDoubleAction:@selector(doubleClick:)];
	
	if ([[documentsArrayController arrangedObjects] count] > 0) {
		[self updateWindowTitleBarForDocument:[[documentsArrayController selectedObjects] objectAtIndex:0]];
	} else {
		[self updateWindowTitleBarForDocument:nil];
	}
	
	[self extraToolbarValidation];
}


- (void)setDefaultAppearanceAtStartup
{
	[[statusBarTextField cell] setBackgroundStyle:NSBackgroundStyleRaised];
	
	LTDocumentsListCell *cell = [[LTDocumentsListCell alloc] init];
	[cell setWraps:NO];
	[cell setLineBreakMode:NSLineBreakByTruncatingMiddle];
	[[documentsTableView tableColumnWithIdentifier:@"name"] setDataCell:cell];

	if ([[LTDefaults valueForKey:@"ShowStatusBar"] boolValue] == NO) {
		[[LTViewMenuController sharedInstance] performHideStatusBar];
	}

	if ([[LTDefaults valueForKey:@"ShowTabBar"] boolValue] == NO) {
		CGFloat tabBarHeight = [tabBarControl bounds].size.height;
		NSRect mainSplitViewRect = [mainSplitView frame];
		[tabBarControl setHidden:YES];
		[mainSplitView setFrame:NSMakeRect(mainSplitViewRect.origin.x, mainSplitViewRect.origin.y, mainSplitViewRect.size.width, mainSplitViewRect.size.height + tabBarHeight)];
	} else {
		[self updateTabBar];
	}

	if ([project valueForKey:@"dividerPosition"] == nil) {
		[project setValue:[LTDefaults valueForKey:@"DividerPosition"] forKey:@"dividerPosition"];
	}
	[self resizeMainSplitView];
}


- (void)selectDocument:(id)document
{
	[documentsArrayController setSelectedObjects:[NSArray arrayWithObject:document]];
}


- (BOOL)areThereAnyDocuments
{
	if ([[documentsArrayController arrangedObjects] count] > 0) {
		return YES;
	} else {
		return NO;
	}
}


- (void)resizeViewsForDocument:(id)document
{	
	if ([self areThereAnyDocuments] == YES) {		
		NSInteger gutterWidth;
		CGFloat subtractFromY; // To remove extra "ugly" pixel row in singleDocumentWindow
		CGFloat subtractFromHeight = 0;
		NSInteger extraHeight;
		NSInteger viewNumber = 0;
		NSView *view = firstContentView;
		NSScrollView *textScrollView = [document valueForKey:@"firstTextScrollView"];
		NSScrollView *gutterScrollView = [document valueForKey:@"firstGutterScrollView"];
		
		while (viewNumber++ < 3) {
			subtractFromY = 0;
			extraHeight = 0;
			if (viewNumber == 2) {
				if ([document valueForKey:@"secondTextView"] != nil) {
					view = secondContentView;
					textScrollView = [document valueForKey:@"secondTextScrollView"];
					gutterScrollView = [document valueForKey:@"secondGutterScrollView"];
					subtractFromY = [secondContentViewNavigationBar bounds].size.height * -1;
					subtractFromHeight = [secondContentViewNavigationBar bounds].size.height;
				} else {
					continue;
				}
			}
			if (viewNumber == 3) {
				if ([document valueForKey:@"singleDocumentWindow"] != nil) {
					view = [[document valueForKey:@"singleDocumentWindow"] contentView];
					textScrollView = [document valueForKey:@"thirdTextScrollView"];
					gutterScrollView = [document valueForKey:@"thirdGutterScrollView"];
					subtractFromY = 1;
					extraHeight = 2;
				} else {
					continue;
				}
			}
			if ([[document valueForKey:@"showLineNumberGutter"] boolValue] == YES) {
				if (![[view subviews] containsObject:gutterScrollView]) {
					[view addSubview:gutterScrollView];
				}
				gutterWidth = [[document valueForKey:@"gutterWidth"] integerValue];
				[gutterScrollView setFrame:NSMakeRect(0, 0 - subtractFromY, gutterWidth, [view bounds].size.height + extraHeight - subtractFromHeight)];
			} else {
				gutterWidth = 0;
				[gutterScrollView removeFromSuperviewWithoutNeedingDisplay];
			}

			[textScrollView setFrame:NSMakeRect(gutterWidth, 0 - subtractFromY, [view bounds].size.width - gutterWidth, [view bounds].size.height + extraHeight - subtractFromHeight)];
		}
		
		[[document valueForKey:@"lineNumbers"] updateLineNumbersCheckWidth:YES recolour:YES];
	}
}


- (void)doubleClick:(id)sender
{
	[[LTViewMenuController sharedInstance] viewDocumentInSeparateWindowAction:nil];
}


- (id)createNewDocumentWithContents:(NSString *)textString
{
	id document = [self createNewDocumentWithPath:nil andContents:textString];
	
	[document setValue:[NSNumber numberWithBool:YES] forKey:@"isNewDocument"];
	[LTVarious setUnsavedAsLastSavedDateForDocument:document];
	[LTInterface updateStatusBar];
	
	return document;
}


- (id)createNewDocumentWithPath:(NSString *)path andContents:(NSString *)textString
{
	id document = [LTBasic createNewObjectForEntity:@"Document"];
	
	[[self documents] addObject:document];
	
	[LTVarious setNameAndPathForDocument:document path:path];
	[LTInterface createFirstViewForDocument:document];

	[[document valueForKey:@"firstTextView"] setString:textString];
	
	LTSyntaxColouring *syntaxColouring = [[LTSyntaxColouring alloc] initWithDocument:document];
	[document setValue:syntaxColouring forKey:@"syntaxColouring"];
	
	[[document valueForKey:@"lineNumbers"] updateLineNumbersForClipView:[[document valueForKey:@"firstTextScrollView"] contentView] checkWidth:NO recolour:YES];
	[document setValue:[NSNumber numberWithInteger:[[documentsArrayController arrangedObjects] count]] forKey:@"sortOrder"];
	[self documentsListHasUpdated];
	
	[documentsArrayController setSelectedObjects:[NSArray arrayWithObject:document]];
	
	[document setValue:[NSString localizedNameOfStringEncoding:[[document valueForKey:@"encoding"] integerValue]] forKey:@"encodingName"];
	
	return document;
}


- (void)updateEditedBlobStatus
{
	id currentDocument = LTCurrentDocument;
	if ([[currentDocument valueForKey:@"isEdited"] boolValue] == YES) {
		[[self window] setDocumentEdited:YES];
		if ([currentDocument valueForKey:@"singleDocumentWindow"] != nil) {
			[[currentDocument valueForKey:@"singleDocumentWindow"] setDocumentEdited:YES];
		}
	} else {
		[[self window] setDocumentEdited:NO];
		if ([currentDocument valueForKey:@"singleDocumentWindow"] != nil) {
			[[currentDocument valueForKey:@"singleDocumentWindow"] setDocumentEdited:NO];
		}
	}
}


- (void)updateWindowTitleBarForDocument:(id)document
{
	NSWindow *currentWindow = [self window];
	NSString *projectName = nil;
	if ([self name] != nil) {
		projectName = [self name];
	}

	if ([self areThereAnyDocuments] == YES && document != nil) {
		NSWindow *singleDocumentWindow = [document valueForKey:@"singleDocumentWindow"];
		[self updateEditedBlobStatus];
		if ([document valueForKey:@"path"] != nil && [[LTDefaults valueForKey:@"ShowFullPathInWindowTitle"] boolValue] == YES) {
			
			if ([[document valueForKey:@"fromExternal"] boolValue] == YES) {
				
				if (document == [self firstDocument] || document == [self secondDocument]) {
					[currentWindow setTitleWithRepresentedFilename:[document valueForKey:@"path"]];
					if (projectName != nil) {
						[currentWindow setTitle:[NSString stringWithFormat:@"%@ - %@ (%@)", [document valueForKey:@"name"], [[document valueForKey:@"externalPath"] stringByDeletingLastPathComponent], projectName]];
					} else {
						[currentWindow setTitle:[NSString stringWithFormat:@"%@ - %@", [document valueForKey:@"name"], [[document valueForKey:@"externalPath"] stringByDeletingLastPathComponent]]];
					}
				}
				if (singleDocumentWindow != nil) {
					[singleDocumentWindow setTitleWithRepresentedFilename:[document valueForKey:@"path"]];
					[singleDocumentWindow setTitle:[NSString stringWithFormat:@"%@ - %@", [document valueForKey:@"name"], [[document valueForKey:@"externalPath"] stringByDeletingLastPathComponent]]];
				}
				
			} else {
				if (document == [self firstDocument] || document == [self secondDocument]) {
					[currentWindow setTitleWithRepresentedFilename:[document valueForKey:@"path"]];
					if (projectName != nil) {
						[currentWindow setTitle:[NSString stringWithFormat:@"%@ (%@)", [document valueForKey:@"nameWithPath"], projectName]];
					} else {
						[currentWindow setTitle:[document valueForKey:@"nameWithPath"]];
					}
				}
				if (singleDocumentWindow != nil) {
					[singleDocumentWindow setTitleWithRepresentedFilename:[document valueForKey:@"path"]];
					[singleDocumentWindow setTitle:[document valueForKey:@"nameWithPath"]];
				}
			}
			
		} else {
			if ([document valueForKey:@"path"] != nil) {
				if (document == [self firstDocument] || document == [self secondDocument]) {
					[currentWindow setTitleWithRepresentedFilename:[document valueForKey:@"path"]];
					if (projectName != nil) {
						[currentWindow setTitle:[NSString stringWithFormat:@"%@ (%@)", [document valueForKey:@"name"], projectName]];
					}
				}
				if (singleDocumentWindow != nil) {
					[singleDocumentWindow setTitleWithRepresentedFilename:[document valueForKey:@"path"]];
				}
				
			} else {
				if (document == [self firstDocument] || document == [self secondDocument]) {
					[currentWindow setRepresentedFilename:[[NSBundle mainBundle] bundlePath]];
					if (projectName != nil) {
						[currentWindow setTitle:[NSString stringWithFormat:@"%@ (%@)", [document valueForKey:@"name"], projectName]];
					} else {
						[currentWindow setTitle:[document valueForKey:@"name"]];
					}
				}
				if (singleDocumentWindow != nil) {
					[singleDocumentWindow setRepresentedFilename:[[NSBundle mainBundle] bundlePath]];
				}
			}
			
			if (document == [self firstDocument] || document == [self secondDocument]) {
				if (projectName != nil) {
					[currentWindow setTitle:[NSString stringWithFormat:@"%@ (%@)", [document valueForKey:@"name"], projectName]];
				} else {
					[currentWindow setTitle:[document valueForKey:@"name"]];
				}
			}
			if (singleDocumentWindow != nil) {
				[singleDocumentWindow setTitle:[document valueForKey:@"name"]];
			}
		}
	} else {
		[currentWindow setDocumentEdited:NO];
		[currentWindow setRepresentedFilename:[[NSBundle mainBundle] bundlePath]];
		[currentWindow setTitle:@"Literate"];
	}
}


- (void)checkIfDocumentIsUnsaved:(id)document keepOpen:(BOOL)keepOpen
{	
	if ([[document valueForKey:@"isEdited"] boolValue] == YES) {
		[self selectDocument:document];
		NSString *title = [NSString stringWithFormat:NSLocalizedString(@"The document %@ has not been saved", @"Indicate in Close-sheet that the document %@ has not been saved."), [document valueForKey:@"name"]];
		
		NSBeginAlertSheet(title,
						  SAVE_STRING,
						  NSLocalizedString(@"Don't Save", @"Don't Save-button in Close-sheet"),
						  CANCEL_BUTTON,
						  [self window],
						  self,
						  @selector(closeSheetDidEnd:returnCode:contextInfo:),
						  nil,
						  (void *)[NSArray arrayWithObjects:document, [NSNumber numberWithBool:keepOpen], nil],
						  NSLocalizedString(@"Your changes will be lost if you close the document without saving.", @"Your changes will be lost if you close the document without saving in Close-sheet"));
		[NSApp runModalForWindow:[[self window] attachedSheet]]; // Modal to make sure that nothing happens while the sheet is displaying
	} else {
		if (keepOpen == NO) {
			[self performCloseDocument:document];
		}
	}
}


- (void)closeSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
    [LTVarious stopModalLoop];
	
	id document = [(NSArray *)contextInfo objectAtIndex:0];
	BOOL keepOpen = [[(NSArray *)contextInfo objectAtIndex:1] boolValue];
	
	if (returnCode == NSAlertDefaultReturn) {
		[sheet close];
		[[LTFileMenuController sharedInstance] saveAction:nil];
		if ([[document valueForKey:@"isEdited"] boolValue] == NO) { // Save didn't fail
			if (keepOpen == NO) {
				[self performCloseDocument:document];
			}
		} else {
			shouldWindowClose = NO;
		}
	} else if (returnCode == NSAlertAlternateReturn) {
		if (keepOpen == NO) {
			[self performCloseDocument:document];
		}
	} else { // The user wants to review the document
		shouldWindowClose = NO;
	}
}


- (void)performCloseDocument:(id)document
{
	if (document == nil) {
		return;
	}
	
	NSInteger documentIndex = [[[self documentsArrayController] arrangedObjects] indexOfObject:document];

	[self cleanUpDocument:document];
	
	if ([self areThereAnyDocuments]) {
		if (documentIndex > 0) {
			documentIndex--;
			[[self documentsArrayController] setSelectionIndex:documentIndex];
		} else {
			[[self documentsArrayController] setSelectionIndex:0];
			[self selectionDidChange]; // Doesn't seem to send this notification otherwise
		}
		[self updateWindowTitleBarForDocument:LTCurrentDocument];
	
		[self documentsListHasUpdated];
	} else {
		if ([[LTApplicationDelegate sharedInstance] filesToOpenArray] == nil) { // A hack to make it only close the window when there no documents to open, from e.g. a FTP-program
			if ([[self window] attachedSheet]) {
				[self performSelector:@selector(performCloseWindow) withObject:nil afterDelay:0.0]; // Do it this way to allow a possible attached sheet to close, otherwise it won't work
			} else {
				if ([[LTDefaults valueForKey:@"KeepEmptyWindowOpen"] boolValue] == NO) {
					[[self window] performClose:nil];
				}
			}
		}
	}
	
	[LTVarious resetSortOrderNumbersForArrayController:documentsArrayController];
	
	[[NSGarbageCollector defaultCollector] collectExhaustively];
}


- (void)performCloseWindow
{
	[[self window] performClose:nil];
}


- (void)cleanUpDocument:(id)document
{
	[[NSNotificationCenter defaultCenter] removeObserver:[document valueForKey:@"lineNumbers"]];
	
	if ([self secondDocument] == document && [[document valueForKey:@"secondTextScrollView"] contentView] != nil) {
		[[LTViewMenuController sharedInstance] performCollapse];
	}
	
	if ([document valueForKey:@"singleDocumentWindow"] != nil) {
		[[document valueForKey:@"singleDocumentWindow"] performClose:nil];
	}	
	
	if ([[LTAdvancedFindController sharedInstance] currentlyDisplayedDocumentInAdvancedFind] == document) {
		[[LTAdvancedFindController sharedInstance] removeCurrentlyDisplayedDocumentInAdvancedFind];
	}
	
	if ([[document valueForKey:@"fromExternal"] boolValue] == YES) {
		[LTVarious sendClosedEventToExternalDocument:document];
	}
	
	if ([self firstDocument] == document) {
		[LTInterface removeAllSubviewsFromView:[self firstContentView]];
		[self setFirstDocument:nil];
	}
	
	[LTManagedObjectContext deleteObject:document];
	[[LTApplicationDelegate sharedInstance] saveAction:nil]; // To remove it from memory
	[[LTManagedObjectContext undoManager] removeAllActions];
}


- (NSDictionary *)dictionaryOfDocumentsInProject
{	
	[LTVarious resetSortOrderNumbersForArrayController:documentsArrayController];
	
	NSArray *array = [[self documents] allObjects];
	NSMutableDictionary *returnDictionary = [NSMutableDictionary dictionary];
	NSMutableArray *documentsArray = [NSMutableArray array];
	for (id item in array) {
		if ([item valueForKey:@"path"] != nil) {
			NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
			[dictionary setValue:[item valueForKey:@"path"] forKey:@"path"];
			[dictionary setValue:[item valueForKey:@"encoding"] forKey:@"encoding"];
			[dictionary setValue:[item valueForKey:@"sortOrder"] forKey:@"sortOrder"];
			NSRange selectedRange = [[item valueForKey:@"firstTextView"] selectedRange];
			if (selectedRange.location == NSNotFound) {
				[dictionary setValue:NSStringFromRange(NSMakeRange(0, 0)) forKey:@"selectedRange"];
			} else {
				[dictionary setValue:NSStringFromRange(selectedRange) forKey:@"selectedRange"];
			}
			[documentsArray addObject:dictionary];
		}
	}
	
	[returnDictionary setValue:documentsArray forKey:@"documentsArray"];
	NSString *name;
	
	if ([self areThereAnyDocuments] == NO || [[[documentsArrayController selectedObjects] objectAtIndex:0] valueForKey:@"name"] == nil) {
		name = @"";
	} else {
		name = [[[documentsArrayController selectedObjects] objectAtIndex:0] valueForKey:@"name"];
	}
	[returnDictionary setValue:name forKey:@"selectedDocumentName"];
	[returnDictionary setValue:NSStringFromRect([[self window] frame]) forKey:@"windowFrame"];
	[returnDictionary setValue:[project valueForKey:@"view"] forKey:@"view"];
	[returnDictionary setValue:[project valueForKey:@"viewSize"] forKey:@"viewSize"];
	[self saveMainSplitViewFraction];
	[returnDictionary setValue:[project valueForKey:@"dividerPosition"]  forKey:@"dividerPosition"];
	[returnDictionary setValue:[NSNumber numberWithInteger:3] forKey:@"version"];
	
	return returnDictionary;
}


- (void)autosave
{
	if ([self fileURL] != nil) {
		[self saveDocument:nil];
	}
}


- (NSString *)name
{
	if ([self fileURL] == nil) {
		return nil;
	}
	
	NSString *urlString = (NSString*)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL, (CFStringRef)[[self fileURL] absoluteString], CFSTR(""), kCFStringEncodingUTF8);
	NSMakeCollectable(urlString);
	return [[urlString lastPathComponent] stringByDeletingPathExtension];
}


- (void)selectionDidChange
{
	[self tableViewSelectionDidChange:[NSNotification notificationWithName:@"NSTableViewSelectionDidChangeNotification" object:documentsTableView]];
}


- (BOOL)isDocumentEdited
{
	return NO;
}


- (BOOL)areAllDocumentsSaved
{	
	[self saveMainSplitViewFraction];
	
	shouldWindowClose = YES;
	
	NSArray *array = [[self documents] allObjects];
	for (id item in array) {
		if ([[item valueForKey:@"isEdited"] boolValue] == YES) {	
			[self checkIfDocumentIsUnsaved:item keepOpen:YES];
		}
		if (shouldWindowClose == NO) { // If one has chosen Cancel to review document one should not be asked about other unsaved documents
			return NO;
		}
	}
	
	// If the user has chosen to review the document instead of closing it the application should not be closed
	if (shouldWindowClose == NO) {
		return NO;
	} else {
		return YES;
	}
}


- (void)documentsListHasUpdated
{
	[self updateTabBar];
	[self buildSecondContentViewNavigationBarMenu];
		
	[self reloadData];
	
	if ([[LTApplicationDelegate sharedInstance] hasFinishedLaunching] == YES) { // Do this toolbar validation here so it doesn't need to be updated all the time as it would have been in validateToolbarItem
		[self extraToolbarValidation];
	}
}


- (void)buildSecondContentViewNavigationBarMenu
{
	if (secondDocument == nil) {
		return;
	}
	
	NSMenu *menu = [secondContentViewPopUpButton menu];
	[LTBasic removeAllItemsFromMenu:menu];
	
	id menuItemToSelect = nil;
	NSEnumerator *enumerator = [[documentsArrayController arrangedObjects] reverseObjectEnumerator];
	for (id item in enumerator) {
		NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:[item valueForKey:@"name"] action:@selector(secondContentViewDocumentChanged:) keyEquivalent:@""];
		[menuItem setRepresentedObject:item];
		[menuItem setTarget:self];
		[menu insertItem:menuItem atIndex:0];
		if (item == secondDocument) {
			menuItemToSelect = menuItem;
		}
	}
	
	[secondContentViewPopUpButton selectItem:menuItemToSelect];
}


- (void)secondContentViewDocumentChanged:(id)sender
{
	[LTInterface insertDocumentIntoSecondContentView:[sender representedObject]];
}


- (CGFloat)mainSplitViewFraction
{
	float fraction;
	if ([contentSplitView bounds].size.width + [leftDocumentsView bounds].size.width + [mainSplitView dividerThickness] != 0) {
		fraction = [leftDocumentsView bounds].size.width / ([contentSplitView bounds].size.width + [leftDocumentsView bounds].size.width + [mainSplitView dividerThickness]);
	} else {
		fraction = 0.0;
	}
	
	return fraction;
}


- (void)resizeMainSplitView
{	
	NSRect leftDocumentsViewFrame = [[[mainSplitView subviews] objectAtIndex:0] frame];
    NSRect contentViewFrame = [[[mainSplitView subviews] objectAtIndex:1] frame];
	CGFloat totalWidth = leftDocumentsViewFrame.size.width + contentViewFrame.size.width + [mainSplitView dividerThickness];
    leftDocumentsViewFrame.size.width = [[project valueForKey:@"dividerPosition"] floatValue] * totalWidth;
    contentViewFrame.size.width = totalWidth - leftDocumentsViewFrame.size.width - [mainSplitView dividerThickness];
	
    [[[mainSplitView subviews] objectAtIndex:0] setFrame:leftDocumentsViewFrame];
    [[[mainSplitView subviews] objectAtIndex:1] setFrame:contentViewFrame];
	
    [mainSplitView adjustSubviews];
}


- (void)saveMainSplitViewFraction
{
	NSNumber *fraction = [NSNumber numberWithFloat:[self mainSplitViewFraction]];
	[project setValue:fraction forKey:@"dividerPosition"];
	[LTDefaults setValue:fraction forKey:@"DividerPosition"];
}


- (void)insertDefaultIconsInDocument:(id)document
{
	NSImage *defaultIcon = [LTInterface defaultIcon];
	[defaultIcon setScalesWhenResized:YES];
		
	NSImage *defaultUnsavedIcon = [LTInterface defaultUnsavedIcon];
	[defaultUnsavedIcon setScalesWhenResized:YES];
	
	[document setValue:defaultIcon forKey:@"icon"];	
	[document setValue:defaultUnsavedIcon forKey:@"unsavedIcon"];
}


#pragma mark -
#pragma mark Accessors

- (void)setLastTextViewInFocus:(LTTextView *)newLastTextViewInFocus
{
	if (lastTextViewInFocus != newLastTextViewInFocus) {
		lastTextViewInFocus = newLastTextViewInFocus;
	}
	
	[self updateWindowTitleBarForDocument:LTCurrentDocument];
}


- (NSMutableSet *)documents
{
	return [project mutableSetValueForKey:@"documents"];
}


- (NSWindow *)window
{
	return [[[self windowControllers] objectAtIndex:0] window];
}


- (NSManagedObjectContext *)managedObjectContext
{
	return LTManagedObjectContext;
}


- (NSToolbar *)projectWindowToolbar
{
    return [[self window] toolbar];
}


#pragma mark -
#pragma mark Window delegates

- (BOOL)windowShouldClose:(id)sender
{	
	if ([self areAllDocumentsSaved] == YES) { // Has the closing been stopped, by e.g. the user wanting to review a document
		return YES;
	} else {
		return NO;
	}
}


- (void)windowWillClose:(NSNotification *)aNotification
{
	if ([[LTApplicationDelegate sharedInstance] isTerminatingApplication] == YES) {		
		return; // No need to clean up if we are quitting
	}
	
	[self autosave];
	
	NSArray *array = [[self documents] allObjects];
	for (id item in array) {
		[self cleanUpDocument:item];
	}

	[[LTApplicationDelegate sharedInstance] saveAction:nil]; // Make sure the documents objects really are deleted, before deleting the project

	if (project != nil) { // Remove the managed object project
		[LTManagedObjectContext deleteObject:project];
	}

	[[LTApplicationDelegate sharedInstance] saveAction:nil];
	[[LTManagedObjectContext undoManager] removeAllActions];
}





@end
