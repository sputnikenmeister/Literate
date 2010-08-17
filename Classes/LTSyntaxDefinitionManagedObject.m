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

#import "LTSyntaxDefinitionManagedObject.h"
#import "LTApplicationDelegate.h"
#import "LTVariousPerformer.h"

@implementation LTSyntaxDefinitionManagedObject

- (void)didChangeValueForKey:(NSString *)key
{	
	[super didChangeValueForKey:key];
	
	if ([[LTApplicationDelegate sharedInstance] hasFinishedLaunching] == NO) {
		return;
	}
	
	if ([LTVarious isChangingSyntaxDefinitionsProgrammatically] == YES) {
		return;
	}

	NSDictionary *changedObject = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[self valueForKey:@"name"], [self valueForKey:@"extensions"], nil] forKeys:[NSArray arrayWithObjects:@"name", @"extensions", nil]];
	if ([LTDefaults valueForKey:@"ChangedSyntaxDefinitions"]) {
		NSMutableArray *changedSyntaxDefinitionsArray = [NSMutableArray arrayWithArray:[LTDefaults valueForKey:@"ChangedSyntaxDefinitions"]];
		NSArray *array = [NSArray arrayWithArray:changedSyntaxDefinitionsArray];
		for (id item in array) {
			if ([[item valueForKey:@"name"] isEqualToString:[self valueForKey:@"name"]]) {
				[changedSyntaxDefinitionsArray removeObject:item];
			}					
		}
		[changedSyntaxDefinitionsArray addObject:changedObject];
		[LTDefaults setValue:changedSyntaxDefinitionsArray forKey:@"ChangedSyntaxDefinitions"];
	} else {
		[LTDefaults setValue:[NSArray arrayWithObject:changedObject] forKey:@"ChangedSyntaxDefinitions"];		
	}
}
@end
