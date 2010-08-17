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

#import "LTExtraInterfaceController.h"
#import "LTTextMenuController.h"
#import "LTProjectsController.h"
#import "LTInterfacePerformer.h"
#import "LTProject.h"


@implementation LTExtraInterfaceController

@synthesize openPanelAccessoryView, openPanelEncodingsPopUp, commandResultWindow, commandResultTextView, newProjectWindow;



static id sharedInstance = nil;

+ (LTExtraInterfaceController *)sharedInstance
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


- (void)displayEntab
{
	if (entabWindow == nil) {
		[NSBundle loadNibNamed:@"LTEntab.nib" owner:self];
	}
	
	[NSApp beginSheet:entabWindow modalForWindow:LTCurrentWindow modalDelegate:self didEndSelector:nil contextInfo:nil];
}


- (void)displayDetab
{
	if (detabWindow == nil) {
		[NSBundle loadNibNamed:@"LTDetab.nib" owner:self];
	}
	
	[NSApp beginSheet:detabWindow modalForWindow:LTCurrentWindow modalDelegate:self didEndSelector:nil contextInfo:nil];
}


- (IBAction)entabButtonEntabWindowAction:(id)sender
{
	[NSApp endSheet:[LTCurrentWindow attachedSheet]]; 
	[[LTCurrentWindow attachedSheet] close];
	
	[[LTTextMenuController sharedInstance] performEntab];
}


- (IBAction)detabButtonDetabWindowAction:(id)sender
{
	[NSApp endSheet:[LTCurrentWindow attachedSheet]]; 
	[[LTCurrentWindow attachedSheet] close];
	
	[[LTTextMenuController sharedInstance] performDetab];
}


- (IBAction)cancelButtonEntabDetabGoToLineWindowsAction:(id)sender
{
	[NSApp endSheet:[LTCurrentWindow attachedSheet]]; 
	[[LTCurrentWindow attachedSheet] close];
}


- (void)displayGoToLine
{
	if (goToLineWindow == nil) {
		[NSBundle loadNibNamed:@"LTGoToLine.nib" owner:self];
	}
	
	[NSApp beginSheet:goToLineWindow modalForWindow:LTCurrentWindow modalDelegate:self didEndSelector:nil contextInfo:nil];
}


- (IBAction)goButtonGoToLineWindowAction:(id)sender
{
	[NSApp endSheet:[LTCurrentWindow attachedSheet]]; 
	[[LTCurrentWindow attachedSheet] close];
	
	[[LTTextMenuController sharedInstance] performGoToLine:[lineTextFieldGoToLineWindow integerValue]];
}


//- (IBAction)setPrintFontAction:(id)sender
//{
//	NSFontManager *fontManager = [NSFontManager sharedFontManager];
//	[fontManager setSelectedFont:[NSUnarchiver unarchiveObjectWithData:[LTDefaults valueForKey:@"PrintFont"]] isMultiple:NO];
//	[fontManager orderFrontFontPanel:nil];
//}


- (NSPopUpButton *)openPanelEncodingsPopUp
{
	if (openPanelEncodingsPopUp == nil) {
		[NSBundle loadNibNamed:@"LTOpenPanelAccessoryView.nib" owner:self];
	}
	
	return openPanelEncodingsPopUp;
}


- (NSView *)openPanelAccessoryView
{
	if (openPanelAccessoryView == nil) {
		[NSBundle loadNibNamed:@"LTOpenPanelAccessoryView.nib" owner:self];
	}
	
	return openPanelAccessoryView;
}


//- (NSView *)printAccessoryView
//{
//	if (printAccessoryView == nil) {
//		[NSBundle loadNibNamed:@"LTPrintAccessoryView.nib" owner:self];
//	}
//	
//	return printAccessoryView;
//}


- (NSWindow *)commandResultWindow
{
    if (commandResultWindow == nil) {
		[NSBundle loadNibNamed:@"LTCommandResult.nib" owner:self];
		[commandResultWindow setTitle:COMMAND_RESULT_WINDOW_TITLE];
	}
	
	return commandResultWindow;
}


- (NSTextView *)commandResultTextView
{
    if (commandResultTextView == nil) {
		[NSBundle loadNibNamed:@"LTCommandResult.nib" owner:self];
		[commandResultWindow setTitle:COMMAND_RESULT_WINDOW_TITLE];		
	}
	
	return commandResultTextView; 
}


- (void)showCommandResultWindow
{
	[[self commandResultWindow] makeKeyAndOrderFront:nil];
}



- (NSWindow *)newProjectWindow
{
	if (newProjectWindow == nil) {
		[NSBundle loadNibNamed:@"LTNewProject.nib" owner:self];
	}
	
	return newProjectWindow;
}


- (IBAction)createNewProjectAction:(id)sender
{
	if ([[LTDefaults valueForKey:@"WhatKindOfProject"] integerValue] == LTVirtualProject) {
		[newProjectWindow orderOut:nil]; 
		[[LTProjectsController sharedDocumentController] newDocument:nil];
		[LTCurrentProject updateWindowTitleBarForDocument:nil];
		[LTCurrentProject selectionDidChange];	
	} else {
		NSSavePanel *savePanel = [NSSavePanel savePanel];
		[savePanel setAllowedFileTypes:[NSArray arrayWithObject:@"smultronProject"]];
		[savePanel beginSheetForDirectory:[LTInterface whichDirectoryForSave]
									 file:nil
						   modalForWindow:newProjectWindow
							modalDelegate:self
						   didEndSelector:@selector(savePanelDidEnd:returnCode:contextInfo:)
							  contextInfo:nil];
	}	
}


- (void)savePanelDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	[sheet close];
	
	[newProjectWindow orderOut:nil];
	
	if (returnCode == NSOKButton) {
		[[LTProjectsController sharedDocumentController] newDocument:nil];
		[LTCurrentProject setFileURL:[NSURL fileURLWithPath:[sheet filename]]];
		[LTCurrentProject saveToURL:[NSURL fileURLWithPath:[sheet filename]] ofType:@"smultronProject" forSaveOperation:NSSaveOperation error:nil];
		[LTCurrentProject updateWindowTitleBarForDocument:nil];
		[LTCurrentProject saveDocument:nil];
	}
}


- (void)showRegularExpressionsHelpPanel
{
	if (regularExpressionsHelpPanel == nil) {
		[NSBundle loadNibNamed:@"LTRegularExpressionHelp.nib" owner:self];
	}
	
	[regularExpressionsHelpPanel makeKeyAndOrderFront:nil];
}
@end
