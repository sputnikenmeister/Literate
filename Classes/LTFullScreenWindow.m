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

#import "LTFullScreenWindow.h"
#import "LTInterfacePerformer.h"

@implementation LTFullScreenWindow

- (BOOL)canBecomeKeyWindow
{
	return YES;
}


- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)styleMask backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag 
{
    if (self = [super initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:bufferingType defer:flag]) {
        [self setAlphaValue:0];
        [self setOpaque:NO];
        [self setHasShadow:NO];
        [self setBackgroundColor:[NSColor blackColor]];
		
        return self;
    }
	
    return nil;
}


- (void)enterFullScreen
{	
	SetSystemUIMode(kUIModeAllHidden, kUIOptionAutoShowMenuBar);
	fullScreenTimer = [NSTimer scheduledTimerWithTimeInterval:0.02 target:self selector:@selector(fadeIn) userInfo:nil repeats:YES];
}


- (void)fadeIn
{
	if ([self alphaValue] < 1.0) {
		[self setAlphaValue:([self alphaValue] + 0.05)];
	} else {		
		if (fullScreenTimer != nil) {
			[fullScreenTimer invalidate];
			fullScreenTimer = nil;
		}
		
		[LTInterface insertDocumentIntoFullScreenWindow];
	}
}


- (void)returnFromFullScreen
{
	fullScreenTimer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(fadeOut) userInfo:nil repeats:YES];
	
}


- (void)fadeOut
{
	if ([self alphaValue] > 0) {
		[self setAlphaValue:([self alphaValue] - 0.05)];
	} else {		
		if (fullScreenTimer != nil) {
			[fullScreenTimer invalidate];
			fullScreenTimer = nil;
		}
		
		[LTInterface returnFromFullScreen];
	}	
}

@end
