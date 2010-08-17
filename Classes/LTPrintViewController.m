/*
Smultron version 3.6b1, 2009-09-12
Written by Peter Borg, pgw3@mac.com
Find the latest version at http://smultron.sourceforge.net

Copyright 2004-2009 Peter Borg

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
*/

#import "LTPrintViewController.h"

#import "LTStandardHeader.h"


@implementation LTPrintViewController

@synthesize dummyValue;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [super initWithNibName:@"LTPrintAccessoryView" bundle:nibBundleOrNil];
}


- (void)awakeFromNib
{
	[self setView:printAccessoryView];
	
	NSUserDefaultsController *defaultsController = [NSUserDefaultsController sharedUserDefaultsController];

	[defaultsController addObserver:self forKeyPath:@"values.PrintHeader" options:NSKeyValueObservingOptionNew context:@"PrinterSettingsChanged"];
	[defaultsController addObserver:self forKeyPath:@"values.PrintSyntaxColours" options:NSKeyValueObservingOptionNew context:@"PrinterSettingsChanged"];
	[defaultsController addObserver:self forKeyPath:@"values.OnlyPrintSelection" options:NSKeyValueObservingOptionNew context:@"PrinterSettingsChanged"];
	[defaultsController addObserver:self forKeyPath:@"values.MarginsMin" options:NSKeyValueObservingOptionNew context:@"PrinterSettingsChanged"];
	[defaultsController addObserver:self forKeyPath:@"values.PrintFont" options:NSKeyValueObservingOptionNew context:@"PrinterSettingsChanged"];
	
	[self performSelector:@selector(hackToMakeDisplayUpdateDirectly) withObject:nil afterDelay:0.0];
}


- (void)hackToMakeDisplayUpdateDirectly
{
	[self setDummyValue:!dummyValue];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([(NSString *)context isEqualToString:@"PrinterSettingsChanged"]) {
		[self setDummyValue:!dummyValue];

	} else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
	
}


- (NSSet *)keyPathsForValuesAffectingPreview
{
	return [NSSet setWithObject:@"dummyValue"];
}


- (NSArray *)localizedSummaryItems
{    
	return [NSArray arrayWithObject:[NSDictionary dictionary]];
}


- (IBAction)setPrintFontAction:(id)sender
{
	NSFontManager *fontManager = [NSFontManager sharedFontManager];
	[fontManager setSelectedFont:[NSUnarchiver unarchiveObjectWithData:[LTDefaults valueForKey:@"PrintFont"]] isMultiple:NO];
	[fontManager orderFrontFontPanel:nil];
}

@end
