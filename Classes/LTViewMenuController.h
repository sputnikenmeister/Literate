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

@interface LTViewMenuController : NSObject
{
	
	
}

+ (LTViewMenuController *)sharedInstance;

- (IBAction)splitWindowAction:(id)sender;
- (void)performCollapse;
- (IBAction)lineWrapTextAction:(id)sender;
- (IBAction)showSyntaxColoursAction:(id)sender;
- (IBAction)showLineNumbersAction:(id)sender;
- (IBAction)showStatusBarAction:(id)sender;
- (void)performHideStatusBar;
- (IBAction)showInvisibleCharactersAction:(id)sender;
- (IBAction)viewDocumentInSeparateWindowAction:(id)sender;
- (IBAction)viewDocumentInFullScreenAction:(id)sender;

- (IBAction)showTabBarAction:(id)sender;
- (void)performHideTabBar;

- (IBAction)showDocumentsViewAction:(id)sender;
- (void)performCollapseDocumentsView;

- (IBAction)documentsViewAction:(id)sender;

- (IBAction)emptyDummyAction:(id)sender;

- (IBAction)showSizeSliderAction:(id)sender;
@end

