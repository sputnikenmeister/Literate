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

#import <Cocoa/Cocoa.h>


@interface LTAdvancedFindController : NSObject <NSOutlineViewDelegate>
{
    IBOutlet NSWindow *advancedFindWindow;
    IBOutlet NSSearchField *findSearchField;
    IBOutlet NSSearchField *replaceSearchField;
    IBOutlet NSTextField *findResultTextField;
    IBOutlet NSOutlineView *findResultsOutlineView;
	IBOutlet NSView *resultDocumentContentView;
	IBOutlet NSTreeController *findResultsTreeController;
	
	IBOutlet NSSplitView *advancedFindSplitView;
	
	IBOutlet NSButton *currentDocumentScope;
	IBOutlet NSButton *currentProjectScope;
	IBOutlet NSButton *allDocumentsScope;
	
	id currentlyDisplayedDocumentInAdvancedFind;
}

@property (assign) id currentlyDisplayedDocumentInAdvancedFind;
@property (readonly) IBOutlet NSWindow *advancedFindWindow;
@property (readonly) IBOutlet NSOutlineView *findResultsOutlineView;

+ (LTAdvancedFindController *)sharedInstance;

- (IBAction)findAction:(id)sender;
- (IBAction)replaceAction:(id)sender;

- (void)performNumberOfReplaces:(NSInteger)numberOfReplaces;

- (void)showAdvancedFindWindow;

- (NSEnumerator *)scopeEnumerator;

- (void)removeCurrentlyDisplayedDocumentInAdvancedFind;

- (NSView *)resultDocumentContentView;

- (NSManagedObjectContext *)managedObjectContext;

- (NSMutableDictionary *)preparedResultDictionaryFromString:(NSString *)completeString searchStringLength:(NSInteger)searchStringLength range:(NSRange)foundRange lineNumber:(NSInteger)lineNumber document:(id)document;

- (void)alertThatThisIsNotAValidRegularExpression:(NSString *)string;

- (void)searchScopeChanged:(id)sender;

- (IBAction)showRegularExpressionsHelpPanelAction:(id)sender;

@end
