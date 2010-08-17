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

#import <Foundation/Foundation.h>
#import <AppKit/NSWorkspace.h>

int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
	if (!argv[1]) { // There is no argument
		if (![workspace launchApplication:@"Literate.app"]) {
			NSLog(@"Can't open Literate");
		}
	} else { // We should open files
		short i = 1;
		NSString *path;
		while (argv[i]) {
			path = [[NSString alloc] initWithUTF8String:argv[i]];
			if (![fileManager fileExistsAtPath:path]) 
			{ // Check if file exists, otherwise create it
				NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
				NSNumber *creatorCode = [NSNumber numberWithUnsignedLong:'LTRT'];
				NSNumber *typeCode = [NSNumber numberWithUnsignedLong:'LTd'];
				[attributes setObject:creatorCode forKey:@"NSFileHFSCreatorCode"];
				[attributes setObject:typeCode forKey:@"NSFileHFSTypeCode"];
				[fileManager createFileAtPath:path contents:nil attributes:attributes];
			}

			if (![workspace openFile:path withApplication:@"Literate.app"]) { // Open file
				NSLog(@"Couldn't open %@ with Literate", path);
			}
			i++;
		}
	}

    [pool drain];
    return 0;
}
