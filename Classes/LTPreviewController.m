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

#import "LTPreviewController.h"
#import "LTProjectsController.h"
#import "LTBasicPerformer.h"
#import "LTProject.h"

@implementation LTPreviewController

@synthesize previewWindow;

static id sharedInstance = nil;

+ (LTPreviewController *)sharedInstance
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


- (void)showPreviewWindow
{	
	if (previewWindow != nil) {
		[previewWindow close];
	}
	
	[NSBundle loadNibNamed:@"LTPreview.nib" owner:self]; // Otherwise [webView mainFrame] return nil the second time the window loads
		
	[webView setResourceLoadDelegate:self];
	[webView setFrameLoadDelegate:self];
	[previewWindow makeKeyAndOrderFront:self];

	[self reload];
}


- (void)reload
{
	if ([LTCurrentProject areThereAnyDocuments]) {
		
		scrollPoint = [[[[[[webView mainFrame] frameView] documentView] enclosingScrollView] contentView] bounds].origin;
			
		[[NSURLCache sharedURLCache] removeAllCachedResponses];

		NSURL *baseURL;
		if ([[LTDefaults valueForKey:@"BaseURL"] isEqualToString:@""]) { // If no base URL is supplied use the document path
			if ([[LTCurrentDocument valueForKey:@"isNewDocument"] boolValue] == NO) {
				NSString *path = [NSString stringWithString:[LTCurrentDocument valueForKey:@"path"]];
				baseURL = [NSURL fileURLWithPath:path];
			} else {
				baseURL = [NSURL URLWithString:@""];
			}
		} else {
			baseURL = [NSURL URLWithString:[[LTDefaults valueForKey:@"BaseURL"] stringByAppendingPathComponent:[LTCurrentDocument valueForKey:@"name"]]];
		}
		
		if ([LTCurrentDocument valueForKey:@"path"] != nil) {
			NSString *path;
			if ([[LTCurrentDocument valueForKey:@"fromExternal"] boolValue] == NO) {
				path = [LTCurrentDocument valueForKey:@"path"];
			} else {
				path = [LTCurrentDocument valueForKey:@"externalPath"];
			}
			[previewWindow setTitle:[NSString stringWithFormat:@"%@ - %@", path, PREVIEW_STRING]];
		} else {
			[previewWindow setTitle:[NSString stringWithFormat:@"%@ - %@", [LTCurrentDocument valueForKey:@"name"], PREVIEW_STRING]];
		}
		
		NSData *data;
		if ([[LTDefaults valueForKey:@"PreviewParser"] integerValue] == LTPreviewHTML) {
			data = [LTCurrentText dataUsingEncoding:NSUTF8StringEncoding];
		} else {
			NSString *temporaryPathMarkdown = [LTBasic genererateTemporaryPath];
			[LTCurrentText writeToFile:temporaryPathMarkdown atomically:YES encoding:[[LTCurrentDocument valueForKey:@"encoding"] integerValue] error:nil];
			NSString *temporaryPathHTML = [LTBasic genererateTemporaryPath];
			NSString *htmlString;
			if ([[NSFileManager defaultManager] fileExistsAtPath:temporaryPathMarkdown]) {
				if ([[LTDefaults valueForKey:@"PreviewParser"] integerValue] == LTPreviewMarkdown) {
					system([[NSString stringWithFormat:@"/usr/bin/perl %@ %@ > %@", [[NSBundle mainBundle] pathForResource:@"Markdown" ofType:@"pl"], temporaryPathMarkdown, temporaryPathHTML] UTF8String]);
				} else {
					system([[NSString stringWithFormat:@"/usr/bin/perl %@ %@ > %@", [[NSBundle mainBundle] pathForResource:@"MultiMarkdown" ofType:@"pl"], temporaryPathMarkdown, temporaryPathHTML] UTF8String]);
				}
				if ([[NSFileManager defaultManager] fileExistsAtPath:temporaryPathMarkdown]) {
					htmlString = [NSString stringWithContentsOfFile:temporaryPathHTML encoding:[[LTCurrentDocument valueForKey:@"encoding"] integerValue] error:nil];
					[[NSFileManager defaultManager] removeItemAtPath:temporaryPathHTML error:nil];
				} else {
					htmlString = LTCurrentText;
				}
				[[NSFileManager defaultManager] removeItemAtPath:temporaryPathMarkdown error:nil];
			} else {
				htmlString = LTCurrentText;
			}
			data = [htmlString dataUsingEncoding:NSUTF8StringEncoding];
		}
		
		[[webView mainFrame] loadData:data MIMEType:@"text/html" textEncodingName:@"utf-8" baseURL:baseURL];
	} else {
		[[webView mainFrame] loadHTMLString:@"" baseURL:[NSURL URLWithString:@""]];
		[previewWindow setTitle:PREVIEW_STRING];
	}

}


- (IBAction)reloadAction:(id)sender
{
	[self reload];
}


- (NSURLRequest *)webView:(WebView *)sender resource:(id)identifier willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse fromDataSource:(WebDataSource *)dataSource
{
	if ([[LTDefaults valueForKey:@"PreviewParser"] integerValue] == LTPreviewHTML) {
		NSURL *url = [request URL];
		NSURLRequest *noCacheRequest = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:120];
		return noCacheRequest;
	} else {
		return request;
	}
}


- (void)liveUpdate
{
	if (previewWindow != nil && [previewWindow isVisible]) {
		[webView setResourceLoadDelegate:nil];
		[self reload];
		[webView setResourceLoadDelegate:self];
	}
}


- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
	[[[[[[webView mainFrame] frameView] documentView] enclosingScrollView] contentView] scrollPoint:scrollPoint];
}
@end
