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

#import "LTVariousPerformer.h"
#import "NSString+Literate.h"
#import "LTBasicPerformer.h"
#import "LTProjectsController.h"
#import "LTMainController.h"
#import "LTCommandsController.h"
#import "LTFileMenuController.h"
#import "LTExtraInterfaceController.h"
#import "LTProject.h"
#import "LTProject+DocumentViewsController.h"
#import "NSImage+Literate.h"

#import "ODBEditorSuite.h"






@implementation LTVariousPerformer

static id sharedInstance = nil;

+ (LTVariousPerformer *)sharedInstance
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
		untitledNumber = 1;
		
		isChangingSyntaxDefinitionsProgrammatically = NO; // So that LTManagedObject does not need to care about changes when resetting the preferences
    }
    return sharedInstance;
}



- (void)updateCheckIfAnotherApplicationHasChangedDocumentsTimer
{
	if ([[LTDefaults valueForKey:@"CheckIfDocumentHasBeenUpdated"] boolValue] == YES) 
	{
		
		NSInteger interval = [[LTDefaults valueForKey:@"TimeBetweenDocumentUpdateChecks"] integerValue];
		if (interval < 1) 
		{
			interval = 1;
		}
		checkIfAnotherApplicationHasChangedDocumentsTimer = 
			[NSTimer scheduledTimerWithTimeInterval:interval 
											 target:LTVarious 
										   selector:@selector(checkIfDocumentsHaveBeenUpdatedByAnotherApplication)	
										   userInfo:nil 
											repeats:YES];
	} 
	else 
	{
		if (checkIfAnotherApplicationHasChangedDocumentsTimer) 
		{
			[checkIfAnotherApplicationHasChangedDocumentsTimer invalidate];
			checkIfAnotherApplicationHasChangedDocumentsTimer = nil;
		}
	}
}


- (void)insertTextEncodings
{
	const NSStringEncoding *availableEncodings = [NSString availableStringEncodings];
	NSStringEncoding encoding;
	NSArray *activeEncodings = [LTDefaults valueForKey:@"ActiveEncodings"];
	while (encoding = *availableEncodings++) 
	{
		id item = [LTBasic createNewObjectForEntity:@"Encoding"];
		NSNumber *encodingObject = [NSNumber numberWithInteger:encoding];
		if ([activeEncodings containsObject:encodingObject]) 
		{
			[item setValue:[NSNumber numberWithBool:YES] forKey:@"active"];
		}
		[item setValue:encodingObject forKey:@"encoding"];
		[item setValue:[NSString localizedNameOfStringEncoding:encoding] forKey:@"name"];
	}
}


- (void)insertSyntaxDefinitions
{
	isChangingSyntaxDefinitionsProgrammatically = YES;
	NSMutableArray *syntaxDefinitionsArray = [[NSMutableArray alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"SyntaxDefinitions" ofType:@"plist"]];
	NSString *path = [[[[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Application Support"] stringByAppendingPathComponent:@"Literate"] stringByAppendingPathComponent:@"SyntaxDefinitions.plist"];
	if ([[NSFileManager defaultManager] fileExistsAtPath:path] == YES) {
		NSArray *syntaxDefinitionsUserArray = [[NSArray alloc] initWithContentsOfFile:path];
		[syntaxDefinitionsArray addObjectsFromArray:syntaxDefinitionsUserArray];
	}
	
	NSArray *keys = [NSArray arrayWithObjects:@"name", @"file", @"extensions", nil];
	NSDictionary *standard = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"Standard", @"standard", [NSString string], nil] forKeys:keys];
	NSDictionary *none = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"None", @"none", [NSString string], nil] forKeys:keys];
	[syntaxDefinitionsArray insertObject:none atIndex:0];
	[syntaxDefinitionsArray insertObject:standard atIndex:0];
	
	NSMutableArray *changedSyntaxDefinitionsArray = nil;
	if ([LTDefaults valueForKey:@"ChangedSyntaxDefinitions"]) {
		changedSyntaxDefinitionsArray = [NSArray arrayWithArray:[LTDefaults valueForKey:@"ChangedSyntaxDefinitions"]];
	}
	
	id item;
	NSInteger index = 0;
	for (item in syntaxDefinitionsArray) {
		if ([[item valueForKey:@"extensions"] isKindOfClass:[NSArray class]]) { // If extensions is an array instead of a string, i.e. an older version
			continue;
		}
		id syntaxDefinition = [LTBasic createNewObjectForEntity:@"SyntaxDefinition"];
		NSString *name = [item valueForKey:@"name"];
		[syntaxDefinition setValue:name forKey:@"name"];
		[syntaxDefinition setValue:[item valueForKey:@"file"] forKey:@"file"];
		[syntaxDefinition setValue:[NSNumber numberWithInteger:index] forKey:@"sortOrder"];
		index++;
		
		BOOL hasInsertedAChangedValue = NO;
		if (changedSyntaxDefinitionsArray != nil) {
			for (id changedObject in changedSyntaxDefinitionsArray) {
				if ([[changedObject valueForKey:@"name"] isEqualToString:name]) {
					[syntaxDefinition setValue:[changedObject valueForKey:@"extensions"] forKey:@"extensions"];
					hasInsertedAChangedValue = YES;
					break;
				}					
			}
		} 
		
		if (hasInsertedAChangedValue == NO) {
			[syntaxDefinition setValue:[item valueForKey:@"extensions"] forKey:@"extensions"];
		}		
	}

	isChangingSyntaxDefinitionsProgrammatically = NO;
}


- (void)insertDefaultSnippets
{
	if ([[LTBasic fetchAll:@"Snippet"] count] == 0 && [[LTDefaults valueForKey:@"HasInsertedDefaultSnippets"] boolValue] == NO) {
		NSDictionary *defaultSnippets = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"DefaultSnippets" ofType:@"plist"]];
		
		NSEnumerator *collectionEnumerator = [defaultSnippets keyEnumerator];
		for (id collection in collectionEnumerator) {
			id newCollection = [LTBasic createNewObjectForEntity:@"SnippetCollection"];
			[newCollection setValue:collection forKey:@"name"];
			NSArray *array = [defaultSnippets valueForKey:collection];
			for (id snippet in array) {
				id newSnippet = [LTBasic createNewObjectForEntity:@"Snippet"];
				[newSnippet setValue:[snippet valueForKey:@"name"] forKey:@"name"];
				[newSnippet setValue:[snippet valueForKey:@"text"] forKey:@"text"];
				[[newCollection mutableSetValueForKey:@"snippets"] addObject:newSnippet];
			}
		}
		
		[LTDefaults setValue:[NSNumber numberWithBool:YES] forKey:@"HasInsertedDefaultSnippets"];
	}
}


- (void)insertDefaultCommands
{
	if ([[LTDefaults valueForKey:@"HasInsertedDefaultCommands3"] boolValue] == NO) {
		
		NSDictionary *defaultCommands = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"DefaultCommands" ofType:@"plist"]];
		
		NSEnumerator *collectionEnumerator = [defaultCommands keyEnumerator];
		for (id collection in collectionEnumerator) {
			id newCollection = [LTBasic createNewObjectForEntity:@"CommandCollection"];
			[newCollection setValue:collection forKey:@"name"];
			NSEnumerator *snippetEnumerator = [[defaultCommands valueForKey:collection] objectEnumerator];
			for (id command in snippetEnumerator) {
				id newCommand = [LTBasic createNewObjectForEntity:@"Command"];
				[newCommand setValue:[command valueForKey:@"name"] forKey:@"name"];
				[newCommand setValue:[command valueForKey:@"text"] forKey:@"text"];
				if ([command valueForKey:@"inline"] != nil) {
					[newCommand setValue:[command valueForKey:@"inline"] forKey:@"inline"];
				}
				if ([command valueForKey:@"interpreter"] != nil) {
					[newCommand setValue:[command valueForKey:@"interpreter"] forKey:@"interpreter"];
				}
				[[newCollection mutableSetValueForKey:@"commands"] addObject:newCommand];
			}
		}
		
		[LTDefaults setValue:[NSNumber numberWithBool:YES] forKey:@"HasInsertedDefaultCommands3"];
	}
}


- (void)standardAlertSheetWithTitle:(NSString *)title message:(NSString *)message window:(NSWindow *)window
{
	if ([window attachedSheet]) {
		[[window attachedSheet] close];
	}
	
	NSBeginAlertSheet(title,
					  OK_BUTTON,
					  nil,
					  nil,
					  window,
					  self,
					  nil,
					  @selector(sheetDidDismiss:returnCode:contextInfo:),
					  nil,
					  message);
	
	[NSApp runModalForWindow:[window attachedSheet]]; // Modal to catch if there are sheets for many files to be displayed
}


- (void)sheetDidDismiss:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
{
	[sheet close];
	[self stopModalLoop];
}


- (void)stopModalLoop
{
	[NSApp stopModal];
	[[LTCurrentWindow standardWindowButton:NSWindowCloseButton] setEnabled:YES];
	[[LTCurrentWindow standardWindowButton:NSWindowMiniaturizeButton] setEnabled:YES];
	[[LTCurrentWindow standardWindowButton:NSWindowZoomButton] setEnabled:YES];
}


- (void)sendModifiedEventToExternalDocument:(id)document path:(NSString *)path
{
	BOOL fromSaveAs = NO;
	NSString *currentPath = [document valueForKey:@"path"];
	if ([path isEqualToString:currentPath] == NO) {
		fromSaveAs = YES;
	}
	
	NSURL *url = [NSURL fileURLWithPath:currentPath];
	NSData *data = [[url absoluteString] dataUsingEncoding:NSUTF8StringEncoding];
	
	OSType signature = [[document valueForKey:@"externalSender"] typeCodeValue];
	NSAppleEventDescriptor *descriptor = [NSAppleEventDescriptor descriptorWithDescriptorType:typeApplSignature bytes:&signature length:sizeof(OSType)];
	NSAppleEventDescriptor *event = [NSAppleEventDescriptor appleEventWithEventClass:kODBEditorSuite eventID:kAEModifiedFile targetDescriptor:descriptor returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID];
	[event setParamDescriptor:[NSAppleEventDescriptor descriptorWithDescriptorType:typeFileURL data:data] forKeyword:keyDirectObject];
	
	if ([document valueForKey:@"externalToken"]) {
		[event setParamDescriptor:[document valueForKey:@"externalToken"] forKeyword:keySenderToken];
	}
	if (fromSaveAs) {
		[descriptor setParamDescriptor:[NSAppleEventDescriptor descriptorWithDescriptorType:typeFileURL data:data] forKeyword:keyNewLocation];
		[document setValue:[NSNumber numberWithBool:NO] forKey:@"fromExternal"]; // If it's a Save As it no longer belongs to the external program
	}
	
	AppleEvent *eventPointer = (AEDesc *)[event aeDesc];
	
	if (eventPointer) {
		AESendMessage(eventPointer, NULL, kAENoReply, kAEDefaultTimeout);
	}
}


- (void)sendClosedEventToExternalDocument:(id)document
{
	NSURL *url = [NSURL fileURLWithPath:[document valueForKey:@"path"]];
	NSData *data = [[url absoluteString] dataUsingEncoding:NSUTF8StringEncoding];
	
	OSType signature = [[document valueForKey:@"externalSender"] typeCodeValue];
	NSAppleEventDescriptor *descriptor = [NSAppleEventDescriptor descriptorWithDescriptorType:typeApplSignature bytes:&signature length:sizeof(OSType)];
	
	NSAppleEventDescriptor *event = [NSAppleEventDescriptor appleEventWithEventClass:kODBEditorSuite eventID:kAEClosedFile targetDescriptor:descriptor returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID];
	[event setParamDescriptor:[NSAppleEventDescriptor descriptorWithDescriptorType:typeFileURL data:data] forKeyword:keyDirectObject];

	if ([document valueForKey:@"externalToken"]) {
		[event setParamDescriptor:[document valueForKey:@"externalToken"] forKeyword:keySenderToken];
	}
	
	AppleEvent *eventPointer = (AEDesc *)[event aeDesc];
	
	if (eventPointer) {
		AESendMessage(eventPointer, NULL, kAENoReply, kAEDefaultTimeout);
	}
}


- (NSInteger)alertWithMessage:(NSString *)message informativeText:(NSString *)informativeText defaultButton:(NSString *)defaultButton alternateButton:(NSString *)alternateButton otherButton:(NSString *)otherButton
{	
	NSAlert *alert = [[NSAlert alloc] init];
	[alert setMessageText:message];
	[alert setInformativeText:informativeText];
	if (defaultButton != nil) {
		[alert addButtonWithTitle:defaultButton];
	}
	if (alternateButton != nil) {
		[alert addButtonWithTitle:alternateButton];
	}
	if (otherButton != nil) {
		[alert addButtonWithTitle:otherButton];
	}
	
	return [alert runModal];
	// NSAlertFirstButtonReturn
	// NSAlertSecondButtonReturn
	// NSAlertThirdButtonReturn
}




- (void)checkIfDocumentsHaveBeenUpdatedByAnotherApplication
{
	if ([LTCurrentProject areThereAnyDocuments] == NO || [LTMain isInFullScreenMode] == YES || [[LTDefaults valueForKey:@"CheckIfDocumentHasBeenUpdated"] boolValue] == NO || [LTCurrentWindow attachedSheet] != nil) {
		return;
	}
	
	NSArray *array = [LTBasic fetchAll:@"Document"];
	for (id item in array) {
		if ([[item valueForKey:@"isNewDocument"] boolValue] == YES || [[item valueForKey:@"ignoreAnotherApplicationHasUpdatedDocument"] boolValue] == YES) {
			continue;
		}
		NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[item valueForKey:@"path"] error:nil];
		if ([attributes fileModificationDate] == nil) {
			continue; // If fileModificationDate is nil the file has been removed or renamed there's no need to check the dates then
		}
		if (![[[item valueForKey:@"fileAttributes"] fileModificationDate] isEqualToDate:[attributes fileModificationDate]]) {
			if ([[LTDefaults valueForKey:@"UpdateDocumentAutomaticallyWithoutWarning"] boolValue] == YES) {
				[[LTFileMenuController sharedInstance] performRevertOfDocument:item];
				[item setValue:[[NSFileManager defaultManager] attributesOfItemAtPath:[item valueForKey:@"path"] error:nil] forKey:@"fileAttributes"];
			} else {
				if ([NSApp isHidden]) { // To display the sheet properly if the application is hidden
					[NSApp activateIgnoringOtherApps:YES]; 
					[LTCurrentWindow makeKeyAndOrderFront:self];
				}
				
				NSString *title = [NSString stringWithFormat:NSLocalizedString(@"The document %@ has been updated by another application", @"Indicate that the document %@ has been updated by another application in Document-has-been-updated-alert sheet"), [item valueForKey:@"path"]];
				NSString *message;
				if ([[item valueForKey:@"isEdited"] boolValue] == YES) {
					message = NSLocalizedString(@"Do you want to ignore the updates the other application has made or reload the document and destroy any changes you have made to this document?", @"Ask whether they want to ignore the updates the other application has made or reload the document and destroy any changes you have made to this document Document-has-been-updated-alert sheet");
				} else {
					message = NSLocalizedString(@"Do you want to ignore the updates the other application has made or reload the document?", @"Ask whether they want to ignore the updates the other application has made or reload the document Document-has-been-updated-alert sheet");
				}
				NSBeginAlertSheet(title,
								  NSLocalizedString(@"Ignore", @"Ignore-button in Document-has-been-updated-alert sheet"),
								  nil,
								  NSLocalizedString(@"Reload", @"Reload-button in Document-has-been-updated-alert sheet"),
								  LTCurrentWindow,
								  self,
								  @selector(sheetDidFinish:returnCode:contextInfo:),
								  nil,
								  (void *)[NSArray arrayWithObject:item],
								  message);
				[NSApp runModalForWindow:[LTCurrentWindow attachedSheet]];
			}
		}
	}
}


- (void)sheetDidFinish:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
{
	[sheet close];
	[LTVarious stopModalLoop];
	
	id document = [(NSArray *)contextInfo objectAtIndex:0];
	if (returnCode == NSAlertDefaultReturn) {
		[document setValue:[NSNumber numberWithBool:YES] forKey:@"ignoreAnotherApplicationHasUpdatedDocument"];
	} else if (returnCode == NSAlertOtherReturn) {
		[[LTFileMenuController sharedInstance] performRevertOfDocument:document];
		[document setValue:[[NSFileManager defaultManager] attributesOfItemAtPath:[document valueForKey:@"path"] error:nil] forKey:@"fileAttributes"];
	}
}


- (NSString *)performCommand:(NSString *)command
{
	NSMutableString *returnString = [NSMutableString string];
	
	@try {
		NSTask *task = [[NSTask alloc] init];
		NSPipe *pipe = [[NSPipe alloc] init];
		NSPipe *errorPipe = [[NSPipe alloc] init];
		
		NSMutableArray *splitArray = [NSMutableArray arrayWithArray:[command divideCommandIntoArray]];
		[task setLaunchPath:[splitArray objectAtIndex:0]];
		[splitArray removeObjectAtIndex:0];
		
		[task setArguments:splitArray];
		[task setStandardOutput:pipe];
		[task setStandardError:errorPipe];
		
		[task launch];
		
		[task waitUntilExit];
		
		NSString *errorString = [[NSString alloc] initWithData:[[errorPipe fileHandleForReading] readDataToEndOfFile] encoding:NSUTF8StringEncoding];
		NSString *outputString = [[NSString alloc] initWithData:[[pipe fileHandleForReading] readDataToEndOfFile] encoding:NSUTF8StringEncoding];
		[returnString appendString:errorString];
		[returnString appendString:outputString];
	}
	@catch (NSException *exception) {
		[returnString appendString:NSLocalizedString(@"Unknown error when running the command", @"Unknown error when running the command in performCommand")];
	}
	@finally {
		return returnString;
	}
}


- (void)performCommandAsynchronously:(NSString *)command
{
	asynchronousTaskResult = [[NSMutableString alloc] initWithString:@""];
	
	asynchronousTask = [[NSTask alloc] init];
	
	if (LTCurrentDocument != nil && [LTCurrentDocument valueForKey:@"path"] != nil) {
		NSMutableDictionary *defaultEnvironment = [NSMutableDictionary dictionaryWithDictionary:[[NSProcessInfo processInfo] environment]];
		NSString *envPath = [NSString stringWithCString:getenv("PATH") encoding:NSUTF8StringEncoding];
		NSString *directory = [[LTCurrentDocument valueForKey:@"path"] stringByDeletingLastPathComponent];
		[defaultEnvironment setObject:[NSString stringWithFormat:@"%@:%@", envPath, directory]  forKey:@"PATH"];
		[defaultEnvironment setObject:directory forKey:@"PWD"];
		[asynchronousTask setEnvironment:defaultEnvironment];
	}
	
	NSMutableArray *splitArray = [NSMutableArray arrayWithArray:[command divideCommandIntoArray]];
	//NSLog([splitArray description]);
	[asynchronousTask setLaunchPath:[splitArray objectAtIndex:0]];
	[splitArray removeObjectAtIndex:0];
	[asynchronousTask setArguments:splitArray];
	
	[asynchronousTask setStandardOutput:[NSPipe pipe]];
	[asynchronousTask setStandardError:[asynchronousTask standardOutput]];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(asynchronousDataReceived:) name:NSFileHandleReadCompletionNotification object:[[asynchronousTask standardOutput] fileHandleForReading]];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(asynchronousTaskCompleted:) name:NSTaskDidTerminateNotification object:nil];
	
	[[[asynchronousTask standardOutput] fileHandleForReading] readInBackgroundAndNotify];
	
	[asynchronousTask launch];
}


- (void)asynchronousDataReceived:(NSNotification *)aNotification
{
    NSData *data = [[aNotification userInfo] valueForKey:@"NSFileHandleNotificationDataItem"];
	
	if ([data length]) {
		NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		if (string != nil) {
			[asynchronousTaskResult appendString:string];
		}
		
		[[[asynchronousTask standardOutput] fileHandleForReading] readInBackgroundAndNotify];
	} else {
		//[self asynchronousTaskCompleted];
	}
	
}

- (void)asynchronousTaskCompleted:(NSNotification *)aNotification
{
	[asynchronousTask waitUntilExit];
	[self asynchronousTaskCompleted];
}


- (void)asynchronousTaskCompleted
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[asynchronousTask terminate];
	
	NSData *data;
	while ((data = [[[asynchronousTask standardOutput] fileHandleForReading] availableData]) && [data length]) {
		NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		if (string != nil) {
			[asynchronousTaskResult appendString:string];
		}
	}

	[[LTCommandsController sharedInstance] setCommandRunning:NO];

	if ([asynchronousTask terminationStatus] == 0) {
		if ([[LTCommandsController sharedInstance] currentCommandShouldBeInsertedInline]) {
			[LTCurrentTextView insertText:asynchronousTaskResult];
			[[[LTExtraInterfaceController sharedInstance] commandResultTextView] setString:@""];
		} else {
			[[[LTExtraInterfaceController sharedInstance] commandResultTextView] setString:asynchronousTaskResult];
			[[[LTExtraInterfaceController sharedInstance] commandResultWindow] makeKeyAndOrderFront:nil];
		}
	} else {
		NSBeep();
		[[[LTExtraInterfaceController sharedInstance] commandResultWindow] makeKeyAndOrderFront:nil];
		[[[LTExtraInterfaceController sharedInstance] commandResultTextView] setString:asynchronousTaskResult];
	}

	[[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)setUnsavedAsLastSavedDateForDocument:(id)document
{
	[document setValue:UNSAVED_STRING forKey:@"lastSaved"];
}


- (void)setLastSavedDateForDocument:(id)document date:(NSDate *)lastSavedDate
{
	[document setValue:[NSString dateStringForDate:(NSCalendarDate *)lastSavedDate formatIndex:[[LTDefaults valueForKey:@"StatusBarLastSavedFormatPopUp"] integerValue]] forKey:@"lastSaved"];
}


- (void)hasChangedDocument:(id)document
{
	[document setValue:[NSNumber numberWithBool:YES] forKey:@"isEdited"];
	[LTCurrentProject reloadData];
	if (document == LTCurrentDocument) {
		[LTCurrentWindow setDocumentEdited:YES];
	}
	if ([document valueForKey:@"singleDocumentWindow"] != nil) {
		[[document valueForKey:@"singleDocumentWindow"] setDocumentEdited:YES];
	}
	
	[LTCurrentProject updateTabBar];
}


- (BOOL)isChangingSyntaxDefinitionsProgrammatically
{
    return isChangingSyntaxDefinitionsProgrammatically;
}


- (void)setNameAndPathForDocument:(id)document path:(NSString *)path
{
	NSString *name;
	if (path == nil) {
		NSString *untitledName = NSLocalizedString(@"untitled", @"Name for untitled document");
		if (untitledNumber == 1) {
			name = [NSString stringWithString:untitledName];
		} else {
			name = [NSString stringWithFormat:@"%@ %ld", untitledName, untitledNumber];
		}
		untitledNumber++;
		[document setValue:name forKey:@"nameWithPath"];
		
	} else {
		
		name = [path lastPathComponent];
		[document setValue:[NSString stringWithFormat:@"%@ - %@", name, [path stringByDeletingLastPathComponent]] forKey:@"nameWithPath"];
	}
	
	[document setValue:name forKey:@"name"];
	[document setValue:path forKey:@"path"];
}





- (void)fixSortOrderNumbersForArrayController:(NSArrayController *)arrayController overIndex:(NSInteger)index
{
	NSArray *array = [arrayController arrangedObjects];
	for (id item in array) {
		if ([[item valueForKey:@"sortOrder"] integerValue] >= index) {
			[item setValue:[NSNumber numberWithInteger:([[item valueForKey:@"sortOrder"] integerValue] + 1)] forKey:@"sortOrder"];
		}
	}
}


- (void)resetSortOrderNumbersForArrayController:(NSArrayController *)arrayController
{
	NSInteger index = 0;
	NSArray *array = [arrayController arrangedObjects];
	for (id item in array) {
		[item setValue:[NSNumber numberWithInteger:index] forKey:@"sortOrder"];
		index++;
	}
}


- (void)insertIconsInBackground:(id)array
{
	NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(performInsertIcons:) object:array];
	
    [[LTMain operationQueue] addOperation:operation];
}


- (void)performInsertIcons:(id)array
{
	NSArray *icons = [NSImage iconsForPath:[array objectAtIndex:1]];
	
	NSArray *resultArray = [NSArray arrayWithObjects:[array objectAtIndex:0], icons, nil];
	
	[self performSelectorOnMainThread:@selector(performInsertIconsOnMainThread:) withObject:resultArray waitUntilDone:NO];
}
	

- (void)performInsertIconsOnMainThread:(id)array
{
	id document = [array objectAtIndex:0];
	
	NSArray *icons = [array objectAtIndex:1];
	
	if (document != nil) { // Check that the document hasn't been closed etc.
		[document setValue:[icons objectAtIndex:0] forKey:@"icon"];
		[document setValue:[icons objectAtIndex:1] forKey:@"unsavedIcon"];
		
		[LTCurrentProject reloadData];
	}
}


//- (LTPrintTextView *)printView
//{
//	Pos;
//	NSPrintInfo *printInfo = [LTCurrentProject printInfo];
//	
//	LTPrintTextView *printTextView = [[LTPrintTextView alloc] initWithFrame:NSMakeRect([printInfo leftMargin], [printInfo bottomMargin], [printInfo paperSize].width - [printInfo leftMargin] - [printInfo rightMargin], [printInfo paperSize].height - [printInfo topMargin] - [printInfo bottomMargin])];
//	
//	
//	// Set the tabs
//	NSMutableString *sizeString = [NSMutableString string];
//	NSUInteger numberOfSpaces = [[LTDefaults valueForKey:@"TabWidth"] integerValue];
//	while (numberOfSpaces--) {
//		[sizeString appendString:@" "];
//	}
//	NSDictionary *sizeAttribute = [[NSDictionary alloc] initWithObjectsAndKeys:[NSUnarchiver unarchiveObjectWithData:[LTDefaults valueForKey:@"PrintFont"]], NSFontAttributeName, nil];
//	CGFloat sizeOfTab = [sizeString sizeWithAttributes:sizeAttribute].width;
//	
//	NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
//	NSArray *array = [style tabStops];
//	for (id item in array) {
//		[style removeTabStop:item];
//	}
//	
//	[style setDefaultTabInterval:sizeOfTab];
//	NSDictionary *attributes = [[NSDictionary alloc] initWithObjectsAndKeys:style, NSParagraphStyleAttributeName, nil];
//	[printTextView setTypingAttributes:attributes];
//	
//	BOOL printOnlySelection = NO;
//	NSInteger selectionLocation = 0;
//	
//	if ([LTCurrentProject areThereAnyDocuments]) {
//		if ([[LTDefaults valueForKey:@"OnlyPrintSelection"] boolValue] == YES && [LTCurrentTextView selectedRange].length > 0) {
//			[printTextView setString:[LTCurrentText substringWithRange:[LTCurrentTextView selectedRange]]];
//			printOnlySelection = YES;
//			selectionLocation = [LTCurrentTextView selectedRange].location;
//		} else {
//			[printTextView setString:LTCurrentText];
//		}
//		
//		if ([[LTCurrentDocument valueForKey:@"isSyntaxColoured"] boolValue] == YES && [[LTDefaults valueForKey:@"PrintSyntaxColours"] boolValue] == YES) {
//			LTTextView *textView = [LTCurrentDocument valueForKey:@"firstTextView"];
//			LTLayoutManager *layoutManager = (LTLayoutManager *)[textView layoutManager];
//			NSTextStorage *textStorage = [printTextView textStorage];
//			NSInteger lastCharacter = [[textView string] length];
//			[layoutManager removeTemporaryAttribute:NSBackgroundColorAttributeName forCharacterRange:NSMakeRange(0, lastCharacter)];
//			NSInteger index = 0;
//			if (printOnlySelection == YES) {
//				index = [LTCurrentTextView selectedRange].location;
//				lastCharacter = NSMaxRange([LTCurrentTextView selectedRange]);
//				[[LTCurrentDocument valueForKey:@"syntaxColouring"] recolourRange:[LTCurrentTextView selectedRange]];
//			} else {
//				[[LTCurrentDocument valueForKey:@"syntaxColouring"] recolourRange:NSMakeRange(0, lastCharacter)];
//			}
//			NSRange range;
//			NSDictionary *attributes;
//			NSInteger rangeLength = 0;
//			while (index < lastCharacter) {
//				attributes = [layoutManager temporaryAttributesAtCharacterIndex:index effectiveRange:&range];
//				rangeLength = range.length;
//				if ([attributes count] != 0) {
//					if (printOnlySelection == YES) {
//						[textStorage setAttributes:attributes range:NSMakeRange(range.location - selectionLocation, rangeLength)];
//					} else {
//						[textStorage setAttributes:attributes range:range];
//					}
//				}
//				if (rangeLength != 0) {
//					index = index + rangeLength;
//				} else {
//					index++;
//				}
//			}
//		}
//	}
//	
//	[printTextView setFont:[NSUnarchiver unarchiveObjectWithData:[LTDefaults valueForKey:@"PrintFont"]]];
//	
//	return printTextView;
//	
//}
@end
