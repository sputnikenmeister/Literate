/*
Smultron version 3.6b1, 2009-09-12
Written by Peter Borg, pgw3@mac.com
Find the latest version at http://smultron.sourceforge.net

Copyright 2004-2009 Peter Borg
 
Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 
http://www.apache.org/licenses/LICENSE-2.0
 
Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
*/

#import <Cocoa/Cocoa.h>

@class LTFullScreenWindow;
@class LTPrintTextView;

@interface LTVariousPerformer : NSObject {
	
	NSInteger untitledNumber;

	NSString *separatorString;
	
	NSTimer *checkIfAnotherApplicationHasChangedDocumentsTimer;
	
	BOOL isChangingSyntaxDefinitionsProgrammatically;
	NSTask *asynchronousTask;
	NSMutableString *asynchronousTaskResult;
}

+ (LTVariousPerformer *)sharedInstance;

- (void)updateCheckIfAnotherApplicationHasChangedDocumentsTimer;

- (void)insertTextEncodings;
- (void)insertSyntaxDefinitions;
- (void)insertDefaultSnippets;

- (void)insertDefaultCommands;
- (void)standardAlertSheetWithTitle:(NSString *)title message:(NSString *)message window:(NSWindow *)window;
- (void)stopModalLoop;
- (void)sendModifiedEventToExternalDocument:(id)document path:(NSString *)path;
- (void)sendClosedEventToExternalDocument:(id)document;

- (NSInteger)alertWithMessage:(NSString *)message informativeText:(NSString *)informativeText defaultButton:(NSString *)defaultButton alternateButton:(NSString *)alternateButton otherButton:(NSString *)otherButton;

- (void)checkIfDocumentsHaveBeenUpdatedByAnotherApplication;
- (void)sheetDidFinish:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
- (NSString *)performCommand:(NSString *)command;
- (void)performCommandAsynchronously:(NSString *)command;
- (void)asynchronousTaskCompleted;

- (BOOL)isChangingSyntaxDefinitionsProgrammatically;

- (void)setUnsavedAsLastSavedDateForDocument:(id)document;
- (void)setLastSavedDateForDocument:(id)document date:(NSDate *)lastSavedDate;
- (void)hasChangedDocument:(id)document;

- (void)setNameAndPathForDocument:(id)document path:(NSString *)path;


- (void)fixSortOrderNumbersForArrayController:(NSArrayController *)arrayController overIndex:(NSInteger)index;
- (void)resetSortOrderNumbersForArrayController:(NSArrayController *)arrayController;


- (void)insertIconsInBackground:(id)array;

//- (LTPrintTextView *)printView;
@end
