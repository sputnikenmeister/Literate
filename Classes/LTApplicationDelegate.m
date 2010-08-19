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

#import "LTApplicationDelegate.h"
#import "LTOpenSavePerformer.h"
#import "LTProjectsController.h"
#import "LTCommandsController.h"
#import "LTBasicPerformer.h"
#import "LTServicesController.h"
#import "LTToolsMenuController.h"
#import "LTProject.h"
#import "LTVariousPerformer.h"

#import "ODBEditorSuite.h"

@implementation LTApplicationDelegate
	
@synthesize persistentStoreCoordinator,  managedObjectModel, managedObjectContext, shouldCreateEmptyDocument, hasFinishedLaunching, isTerminatingApplication, filesToOpenArray, appleEventDescriptor;


static id sharedInstance = nil;

+ (LTApplicationDelegate *)sharedInstance
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
		
		shouldCreateEmptyDocument = YES;
		hasFinishedLaunching = NO;
		isTerminatingApplication = NO;
		appleEventDescriptor = nil;
    }
	
    return sharedInstance;
}


- (NSString *)applicationSupportFolder
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
    return [basePath stringByAppendingPathComponent:@"Literate"];
}


- (NSManagedObjectModel *)managedObjectModel
{
    if (managedObjectModel != nil) {
        return managedObjectModel;
    }
	
    managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"LTDataModel3" ofType:@"mom"]]];
    
    return managedObjectModel;
}


- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (persistentStoreCoordinator != nil) {
        return persistentStoreCoordinator;
    }

    NSString *applicationSupportFolder = nil;
    NSError *error;
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
    applicationSupportFolder = [self applicationSupportFolder];
    if (![fileManager fileExistsAtPath:applicationSupportFolder isDirectory:NULL] ) {
        [fileManager createDirectoryAtPath:applicationSupportFolder withIntermediateDirectories:YES attributes:nil error:nil];
    }

	NSString *storePath = [applicationSupportFolder stringByAppendingPathComponent: @"Literate.literate"];
	
	NSURL *url = [NSURL fileURLWithPath:storePath];
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSBinaryStoreType configuration:nil URL:url options:nil error:&error]){
        [[NSApplication sharedApplication] presentError:error];
    }    

    return persistentStoreCoordinator;
}

 
- (NSManagedObjectContext *)managedObjectContext
{
    if (managedObjectContext != nil) {
        return managedObjectContext;
    }

    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setPersistentStoreCoordinator: coordinator];
    }
    
    return managedObjectContext;
}

 
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window
{
	return [[self managedObjectContext] undoManager];
}

 
- (IBAction)saveAction:(id)sender
{
    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}

 
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
	id item;
	NSArray *array = [[LTProjectsController sharedDocumentController] documents];
	for (item in array) {
		[item autosave];
		if ([item areAllDocumentsSaved] == NO) {
			return NSTerminateCancel;
		}
	}

	isTerminatingApplication = YES; // This is to avoid changing the document when quiting the application because otherwise it "flashes" when removing the documents
	
	[[LTCommandsController sharedInstance] clearAnyTemporaryFiles];
	
	if ([[LTDefaults valueForKey:@"OpenAllDocumentsIHadOpen"] boolValue] == YES) {

		NSMutableArray *documentsArray = [NSMutableArray array];
		NSArray *projects = [[LTProjectsController sharedDocumentController] documents];
		for (id project in projects) {
			if ([project fileURL] == nil) {
				NSArray *documents = [[project documentsArrayController] arrangedObjects];
				for (id document in documents) {
					if ([document valueForKey:@"path"] != nil && [[document valueForKey:@"fromExternal"] boolValue] != YES) {
						[documentsArray addObject:[document valueForKey:@"path"]];
					}
				}
			}
		}
		
		[LTDefaults setValue:documentsArray forKey:@"OpenDocuments"];
	}
	
	if ([[LTDefaults valueForKey:@"OpenAllProjectsIHadOpen"] boolValue] == YES) {
		NSMutableArray *projectsArray = [NSMutableArray array];
		NSArray *array = [[LTProjectsController sharedDocumentController] documents];
		for (id project in array) {
			if ([project fileURL] != nil) {
				[projectsArray addObject:[[project fileURL] path]];
			}
		}
		
		[LTDefaults setValue:projectsArray forKey:@"OpenProjects"];
	}
	
	array = [LTBasic fetchAll:@"Document"]; // Mark any external documents as closed
	for (item in array) {
		if ([[item valueForKey:@"fromExternal"] boolValue] == YES) {
			[LTVarious sendClosedEventToExternalDocument:item];
		}
	}
	
	[LTBasic removeAllObjectsForEntity:@"Document"];
	[LTBasic removeAllObjectsForEntity:@"Encoding"];
	[LTBasic removeAllObjectsForEntity:@"SyntaxDefinition"];
	[LTBasic removeAllObjectsForEntity:@"Project"];
	
	NSError *error;
    NSInteger reply = NSTerminateNow;
    
    if (managedObjectContext != nil) {
        if ([managedObjectContext commitEditing]) {
            if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) { 

                BOOL errorResult = [[NSApplication sharedApplication] presentError:error];
				
                if (errorResult == YES) {
                    reply = NSTerminateCancel;
                } else {
                    NSInteger alertReturn = NSRunAlertPanel(nil, @"Could not save changes while quitting. Quit anyway?" , @"Quit anyway", @"Cancel", nil);
                    if (alertReturn == NSAlertAlternateReturn) {
                        reply = NSTerminateCancel;	
                    }
                }
            }
        } else {
            reply = NSTerminateCancel;
        }
    }
    
	if (reply == NSTerminateCancel) {
		isTerminatingApplication = NO;
	}
	
    return reply;
}


- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames
{
	filesToOpenArray = [[NSMutableArray alloc] initWithArray:filenames];
	[filesToOpenArray sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
	shouldCreateEmptyDocument = NO;
	
	if (hasFinishedLaunching) {
		[LTOpenSave openAllTheseFiles:filesToOpenArray];
		filesToOpenArray = nil;
	} else if ([[[NSAppleEventManager sharedAppleEventManager] currentAppleEvent] paramDescriptorForKeyword:keyFileSender] != nil || [[[NSAppleEventManager sharedAppleEventManager] currentAppleEvent] paramDescriptorForKeyword:keyAEPropData] != nil) {
		if (appleEventDescriptor == nil) {
			appleEventDescriptor = [[NSAppleEventDescriptor alloc] initWithDescriptorType:[[[NSAppleEventManager sharedAppleEventManager] currentAppleEvent] descriptorType] data:[[[NSAppleEventManager sharedAppleEventManager] currentAppleEvent] data]];
			shouldCreateEmptyDocument = NO;
		}
	}
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	[NSApp setServicesProvider:[LTServicesController sharedInstance]];
	
	[self performSelector:@selector(markItAsTrulyFinishedWithLaunching) withObject:nil afterDelay:0.0]; // Do it this way because otherwise this is called before the values are inserted by Core Data
}


- (void)markItAsTrulyFinishedWithLaunching
{
	if (filesToOpenArray != nil && [filesToOpenArray count] > 0) {
		NSArray *openDocument = [LTBasic fetchAll:@"Document"];
		if ([openDocument count] != 0) {
			if (LTCurrentProject != nil) {
				[LTCurrentProject performCloseDocument:[openDocument objectAtIndex:0]];
			}
		}
		[LTManagedObjectContext processPendingChanges];
		[LTOpenSave openAllTheseFiles:filesToOpenArray];
		[LTCurrentProject selectionDidChange];
		filesToOpenArray = nil;
	} else { // Open previously opened documents/projects only if Literate wasn't opened by e.g. dragging a document onto the icon
		
		if ([[LTDefaults valueForKey:@"OpenAllDocumentsIHadOpen"] boolValue] == YES && [[LTDefaults valueForKey:@"OpenDocuments"] count] > 0) {
			shouldCreateEmptyDocument = NO;
			NSArray *openDocument = [LTBasic fetchAll:@"Document"];
			if ([openDocument count] != 0) {
				if (LTCurrentProject != nil) {
					filesToOpenArray = [[NSMutableArray alloc] init]; // A hack so that -[LTProject performCloseDocument:] won't close the window
					[LTCurrentProject performCloseDocument:[openDocument objectAtIndex:0]];
					filesToOpenArray = nil;
				}
			}
			[LTManagedObjectContext processPendingChanges];
			[LTOpenSave openAllTheseFiles:[LTDefaults valueForKey:@"OpenDocuments"]];
			[LTCurrentProject selectionDidChange];
		}
		
		if ([[LTDefaults valueForKey:@"OpenAllProjectsIHadOpen"] boolValue] == YES && [[LTDefaults valueForKey:@"OpenProjects"] count] > 0) {
			shouldCreateEmptyDocument = NO;
			[LTOpenSave openAllTheseFiles:[LTDefaults valueForKey:@"OpenProjects"]];
		}
	}

	hasFinishedLaunching = YES;
	shouldCreateEmptyDocument = NO;

	// Do this here so that it won't slow down the perceived start-up time
	[[LTToolsMenuController sharedInstance] buildInsertSnippetMenu];
	[[LTToolsMenuController sharedInstance] buildRunCommandMenu];
	
	if ([[LTDefaults valueForKey:@"HasImportedFromVersion2"] boolValue] == NO) {
		[self importFromVersion2];
	}

}


- (void)changeFont:(id)sender // When you change the font in the print panel
{
	NSFontManager *fontManager = [NSFontManager sharedFontManager];
	NSFont *panelFont = [fontManager convertFont:[fontManager selectedFont]];
	[LTDefaults setValue:[NSArchiver archivedDataWithRootObject:panelFont] forKey:@"PrintFont"];
}


- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
{
	if ([[LTDefaults valueForKey:@"OpenAllProjectsIHadOpen"] boolValue] == YES && [[LTDefaults valueForKey:@"OpenProjects"] count] > 0 || [[[LTProjectsController sharedDocumentController] documents] count] > 0) {
		return NO;
	} else {
		return [[LTDefaults valueForKey:@"NewDocumentAtStartup"] boolValue];
	}
}


- (NSMenu *)applicationDockMenu:(NSApplication *)sender
{
	NSMenu *returnMenu = [[NSMenu alloc] init];
	NSMenuItem *menuItem;
	id document;
	
	NSEnumerator *currentProjectEnumerator = [[[LTCurrentProject documentsArrayController] arrangedObjects] reverseObjectEnumerator];
	for (document in currentProjectEnumerator) {
		menuItem = [[NSMenuItem alloc] initWithTitle:[document valueForKey:@"name"] action:@selector(selectDocumentFromTheDock:) keyEquivalent:@""];
		[menuItem setTarget:[LTProjectsController sharedDocumentController]];
		[menuItem setRepresentedObject:document];
		[returnMenu insertItem:menuItem atIndex:0];
	}
	
	NSArray *projects = [[LTProjectsController sharedDocumentController] documents];
	for (id project in projects) {
		if (project == LTCurrentProject) {
			continue;
		}
		NSMenu *menu;
		if ([project valueForKey:@"name"] == nil) {
			menu = [[NSMenu alloc] initWithTitle:UNTITLED_PROJECT_NAME];
		} else {
			menu = [[NSMenu alloc] initWithTitle:[project valueForKey:@"name"]];
		}
		
		NSEnumerator *documentsEnumerator = [[[(LTProject *)project documents] allObjects] reverseObjectEnumerator];
		for (document in documentsEnumerator) {
			menuItem = [[NSMenuItem alloc] initWithTitle:[document valueForKey:@"name"] action:@selector(selectDocumentFromTheDock:) keyEquivalent:@""];
			[menuItem setTarget:[LTProjectsController sharedDocumentController]];
			[menuItem setRepresentedObject:document];
			[menu insertItem:menuItem atIndex:0];
		}
		
		NSMenuItem *subMenuItem = [[NSMenuItem alloc] initWithTitle:[menu title] action:nil keyEquivalent:@""];
		[subMenuItem setSubmenu:menu];
		[returnMenu addItem:subMenuItem];
	}

	return returnMenu;
}


- (void)applicationDidBecomeActive:(NSNotification *)aNotification
{
	if ([[LTDefaults valueForKey:@"CheckIfDocumentHasBeenUpdated"] boolValue] == YES) { // Check for updates directly when Literate gets focus
		[LTVarious checkIfDocumentsHaveBeenUpdatedByAnotherApplication];
	}
}

@end
