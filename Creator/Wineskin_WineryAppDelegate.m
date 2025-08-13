//
//  Wineskin_WineryAppDelegate.m
//  Wineskin Winery
//
//  Copyright 2011-2013 by The Wineskin Project and Urge Software LLC All rights reserved.
//  Licensed for use under the LGPL <http://www.gnu.org/licenses/lgpl-2.1.txt>
//

#import "Wineskin_WineryAppDelegate.h"
#import "NSWineskinEngine.h"
#import <ObjectiveC_Extension/ObjectiveC_Extension.h>

@implementation Wineskin_WineryAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	srand((unsigned int)time(NULL));
	[waitWheel startAnimation:self];
	[busyWindow makeKeyAndOrderFront:self];
	[self refreshButtonPressed:self];
	[self checkForUpdates];
    
    //TODO: Disable XQuartz option on Catalina and above
    if (IS_SYSTEM_MAC_OS_10_15_OR_SUPERIOR) {
        [hideXQuartzEnginesCheckBox setEnabled:NO];
    }
}

- (void)systemCommand:(NSString *)commandToRun withArgs:(NSArray *)args
{
    [[NSTask launchedTaskWithLaunchPath:commandToRun arguments:args] waitUntilExit];
}

- (IBAction)aboutWindow:(id)sender
{
	NSDictionary* plistDictionary = [[NSDictionary alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/Contents/Info.plist",[[NSBundle mainBundle] bundlePath]]];
	[aboutWindowVersionNumber setStringValue:[plistDictionary valueForKey:@"CFBundleVersion"]];
	[aboutWindow makeKeyAndOrderFront:self];
}

- (IBAction)helpWindow:(id)sender
{
	[helpWindow makeKeyAndOrderFront:self];
}

- (void)makeFoldersAndFiles
{
	NSFileManager *filemgr = [NSFileManager defaultManager];
    NSString* wineskinFolder = [NSString stringWithFormat:@"%@/Library/Application Support/Sikarugir",NSHomeDirectory()];
	
    [filemgr createDirectoryAtPath:[wineskinFolder stringByAppendingString:@"/Engines"] withIntermediateDirectories:YES
                        attributes:nil error:nil];
	[filemgr createDirectoryAtPath:[wineskinFolder stringByAppendingString:@"/Wrapper"] withIntermediateDirectories:YES
                        attributes:nil error:nil];
	[filemgr createDirectoryAtPath:[NSHomeDirectory() stringByAppendingString:@"/Applications/Sikarugir"] withIntermediateDirectories:YES
                        attributes:nil error:nil];
}

- (void)checkForUpdates
{
	//get current version number
	NSString *currentVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
	
    //get latest available version number
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/NewestZersion.txt?%@",WINESKIN_WEBSITE_WINERY_FOLDER,[[NSNumber numberWithLong:rand()] stringValue]]];
	NSString *newVersion = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
	newVersion = [newVersion stringByReplacingOccurrencesOfString:@"\n" withString:@""]; //remove \n
	if (!([newVersion hasPrefix:@"Creator"]) || ([currentVersion isEqualToString:newVersion]))
	{
		[window makeKeyAndOrderFront:self];
		[busyWindow orderOut:self];
		return;
	}
	NSAlert *alert = [[NSAlert alloc] init];
	[alert addButtonWithTitle:@"Do Update"];
	[alert addButtonWithTitle:@"Cancel"];
	[alert setMessageText:@"Update Available!"];
	[alert setInformativeText:@"An Update to Creator is available, would you like to update now?"];
	[alert setAlertStyle:NSInformationalAlertStyle];
	if ([alert runModal] != NSAlertFirstButtonReturn)
	{
		//display warning about not updating.
		NSAlert *warning = [[NSAlert alloc] init];
		[warning addButtonWithTitle:@"OK"];
		[warning setMessageText:@"Warning!"];
		[warning setInformativeText:@"Some things may not function properly with new Wrappers or Engines until you update!"];
		[warning runModal];
		//bring main window up
		[window makeKeyAndOrderFront:self];
		[busyWindow orderOut:self];
		return;
	}
	//try removing files that might already exist
	NSFileManager *fm = [NSFileManager defaultManager];
	[fm removeItemAtPath:@"/tmp/WineskinWinery.app.tar.xz" error:nil];
	[fm removeItemAtPath:@"/tmp/WineskinWinery.app.tar" error:nil];
	[fm removeItemAtPath:@"/tmp/WineskinWinery.app" error:nil];
	//update selected, download update
	[urlInput setStringValue:[NSString stringWithFormat:@"%@/WineskinWinery.app.tar.xz?%@",WINESKIN_WEBSITE_WINERY_FOLDER,[[NSNumber numberWithLong:rand()] stringValue]]];
	[urlOutput setStringValue:@"file:///tmp/WineskinWinery.app.tar.xz"];
	[fileName setStringValue:@"Wineskin Winery Update"];
	[downloadingWindow makeKeyAndOrderFront:self];
	[window orderOut:self];
	[busyWindow orderOut:self];
}

-(NSArray<NSWineskinEngine*>*)installedEnginesList {
    BOOL hideX11Engines = hideXQuartzEnginesCheckBox.state;
    return hideX11Engines ? _installedMacDriverEnginesList : _installedEnginesList;
}

-(BOOL)isXQuartzInstalled {
    return [[NSFileManager defaultManager] fileExistsAtPath:@"/opt/X11/bin/Xquartz"];
}

-(IBAction)showOrHideXQuartzEngines:(NSButton*)sender {
    [installedEngines reloadData];
    
    if (!sender.state && !self.isXQuartzInstalled) {
        [VMMAlert showAlertOfType:VMMAlertTypeWarning withMessage:@"You need to install XQuartz to use XQuartz-only compatible engines. You can find it here:\n\nhttps://www.xquartz.org"];
    }
}

-(IBAction)compressEngines:(NSButton*)sender {
    
    if (!sender.state) {
        //TODO: Set compression to 0
    }
    else
    {
        //TODO: Set compression to 1 the default setting
    }
}

- (IBAction)createNewBlankWrapperButtonPressed:(id)sender
{
	NSWineskinEngine* engine = [self.installedEnginesList objectAtIndex:[installedEngines selectedRow]];
	[createWrapperEngine setStringValue:engine.engineName];
	[createWrapperWindow makeKeyAndOrderFront:self];
	[window orderOut:self];
}

- (IBAction)refreshButtonPressed:(id)sender
{
	//make sure files and folders are created
	[self makeFoldersAndFiles];
	
    //set installed engines list
	[self getInstalledEngines:@""];
	[installedEngines setAllowsEmptySelection:NO];
	[installedEngines reloadData];
	
    //check if engine updates are available
	[self setEnginesAvailablePrompt];
	
    //set current wrapper version blank
	[wrapperVersion setStringValue:[self getCurrentWrapperVersion]];
	
    //check if wrapper update is available
	[self setWrapperAvailablePrompt];
	
    // make sure an engine and master wrapper are both installed first, or have CREATE button disabled!
    [createWrapperButton setEnabled:([self.installedEnginesList count] > 0 &&
                                    ![[wrapperVersion stringValue] isEqualToString:@"No Wrapper Installed"])];
	
    //check wrapper version is 1.0+, if not then do not enable button
	int numToCheckMajor = [[[self getCurrentWrapperVersion] substringWithRange:NSMakeRange(9,1)] intValue];
	int numToCheckMinor = [[[self getCurrentWrapperVersion] substringWithRange:NSMakeRange(11,1)] intValue];
	if (numToCheckMajor < 1 && numToCheckMinor < 0) [createWrapperButton setEnabled:NO];
}

- (IBAction)downloadPackagesManuallyButtonPressed:(id)sender;
{
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://mega.nz/#F!7ZxFQYDB!7CJRmNuPReBcbsp0-rfjqg&?%@",[[NSNumber numberWithLong:rand()] stringValue]]];
	[[NSWorkspace sharedWorkspace] openURL:url];
}

- (IBAction)plusButtonPressed:(id)sender
{
	[self showAvailableEngines:@""];
	//show the engines window
	[addEngineWindow makeKeyAndOrderFront:self];
	[window orderOut:self];
}

- (void)showAvailableEngines:(NSString *)theFilter
{
	//populate engines list in engines window
	[engineWindowEngineList removeAllItems];
	NSMutableArray *availableEngines = [self getAvailableEngines];
	NSMutableArray *testList = [NSMutableArray arrayWithCapacity:[availableEngines count]];
	for (NSString *itemAE in availableEngines)
	{
		BOOL matchFound=NO;
		for (NSWineskinEngine *itemIE in _installedEnginesList)
		{
			if ([itemAE isEqualToString:itemIE.engineName])
			{
				matchFound=YES;
				break;
			}
		}
		if (!matchFound) [testList addObject:itemAE];
	}
	for (NSString *item in testList)
	{
		if ([theFilter isEqualToString:@""])
		{
			[engineWindowEngineList addItemWithTitle:item];
			continue;
		}
		else
		{
			if ([item rangeOfString:theFilter options:NSCaseInsensitiveSearch].location != NSNotFound)
				[engineWindowEngineList addItemWithTitle:item];
		}
	}
	if ([[engineWindowEngineList selectedItem] title] == nil)
	{
		[engineWindowDownloadAndInstallButton setEnabled:NO];
		[engineWindowViewWineReleaseNotesButton setEnabled:NO];
		[engineWindowDontPromptAsNewButton setEnabled:NO];
	}
	else
	{
		[engineWindowDontPromptAsNewButton setEnabled:YES];
		[engineWindowDownloadAndInstallButton setEnabled:YES];
		[engineWindowViewWineReleaseNotesButton setEnabled:YES];
		[self engineWindowEngineListChanged:self];
	}
	
}

- (IBAction)minusButtonPressed:(id)sender
{
	NSWineskinEngine* engine = [self.installedEnginesList objectAtIndex:[installedEngines selectedRow]];
	NSAlert *alert = [[NSAlert alloc] init];
	[alert addButtonWithTitle:@"Yes"];
	[alert addButtonWithTitle:@"Cancel"];
	[alert setMessageText:@"Confirm Deletion"];
	[alert setInformativeText:[NSString stringWithFormat:@"Are you sure you want to delete the engine \"%@\"",engine.engineName]];
	[alert setAlertStyle:NSInformationalAlertStyle];
	if ([alert runModal] != NSAlertFirstButtonReturn)
    {
        return;
    }
	//move file to trash
	NSArray *filenamesArray = [NSArray arrayWithObject:[NSString stringWithFormat:@"%@.tar.xz",engine.engineName]];
	[[NSWorkspace sharedWorkspace] performFileOperation:NSWorkspaceRecycleOperation source:[NSString stringWithFormat:@"%@/Library/Application Support/Sikarugir/Engines",NSHomeDirectory()] destination:@"" files:filenamesArray tag:nil];
	[self refreshButtonPressed:self];
}

- (IBAction)updateButtonPressed:(id)sender
{
    //TODO: Wrapper version
    //get latest available version number
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://raw.githubusercontent.com/Sikarugir-App/Wrapper/main/NewestVersion.txt?%@",[[NSNumber numberWithLong:rand()] stringValue]]];
	NSString *newVersion = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
	newVersion = [newVersion stringByReplacingOccurrencesOfString:@"\n" withString:@""]; //remove \n
	if (newVersion == nil || ![[newVersion substringToIndex:8] isEqualToString:@"Template"])
	{
		NSAlert *alert = [[NSAlert alloc] init];
		[alert addButtonWithTitle:@"OK"];
		[alert setMessageText:@"Oops!"];
		[alert setInformativeText:@"Error, connection to download failed!"];
		[alert setAlertStyle:NSInformationalAlertStyle];
		[alert runModal];
		return;
	}
	//download new wrapper to /tmp
	[urlInput setStringValue:[NSString stringWithFormat:@"https://github.com/Sikarugir-App/Wrapper/releases/download/v1.0/%@.tar.xz?%@",newVersion,[[NSNumber numberWithLong:rand()] stringValue]]];
	[urlOutput setStringValue:[NSString stringWithFormat:@"file:///tmp/%@.tar.xz",newVersion]];
	[fileName setStringValue:newVersion];
	[fileNameDestination setStringValue:@"Wrapper"];
	[downloadingWindow makeKeyAndOrderFront:self];
	[window orderOut:self];
}

- (IBAction)wineskinWebsiteButtonPressed:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/Sikarugir-App/sikarugir/"]];
}

- (void)getInstalledEngines:(NSString *)theFilter
{
	[_installedEnginesList removeAllObjects];
    [_installedEnginesList addObjectsFromArray:[NSWineskinEngine getListOfAvailableEngines]];
    [_installedEnginesList filter:^BOOL(NSWineskinEngine * _Nonnull engine) {
        return (theFilter.length == 0 || [engine.engineName.lowercaseString contains:theFilter.lowercaseString]);
    }];

    //Only show wine versions compatiblbe with Freetype2.8.1
    //Only show wine32on64 & wine64 Engines
    //XQuartz checkbox is always disabled on Catalina now
    if (IS_SYSTEM_MAC_OS_10_15_OR_SUPERIOR) {
        _installedMacDriverEnginesList = [_installedEnginesList mutableCopy];
        [_installedMacDriverEnginesList filter:^BOOL(NSWineskinEngine *  _Nonnull engine) {
            return engine.isCompatibleWith32on64Bit;
        }];
        
        [_installedMacDriverEnginesList filter:^BOOL(NSWineskinEngine *  _Nonnull engine) {
            return engine.requiresXquartz;
        }];
    }

    //Only show wine versions compatiblbe with Freetype2.8.1
    if (!IS_SYSTEM_MAC_OS_10_15_OR_SUPERIOR) {
        _installedMacDriverEnginesList = [_installedEnginesList mutableCopy];
        [_installedMacDriverEnginesList filter:^BOOL(NSWineskinEngine *  _Nonnull engine) {
            return engine.requiresXquartz;
        }];
    }
}

- (NSArray *)getEnginesToIgnore
{
	NSString *fileString = [NSString stringWithContentsOfFile:[NSString stringWithFormat:@"%@/Library/Application Support/Sikarugir/IgnoredEngines.txt",NSHomeDirectory()] encoding:NSUTF8StringEncoding error:nil];
	if ([fileString hasSuffix:@"\n"])
	{
		fileString = [fileString stringByAppendingString:@":!:!:"];
		fileString = [fileString stringByReplacingOccurrencesOfString:@"\n:!:!:" withString:@""];
	}
	return [fileString componentsSeparatedByString:@"\n"];
}

- (NSMutableArray *)getAvailableEngines
{
    NSFileManager *fm = [NSFileManager defaultManager];
    
    // If EngineList.txt is present in the same directly use that instead of the online copy
    if ([fm fileExistsAtPath:[NSString stringWithFormat:@"%@/../EngineList.txt",[[NSBundle mainBundle] bundlePath]]])
    {
        NSString *fileString = [NSString stringWithContentsOfFile:[NSString stringWithFormat:@"%@/../EngineList.txt",[[NSBundle mainBundle] bundlePath]] encoding:NSUTF8StringEncoding error:nil];
        if ([fileString hasSuffix:@"\n"])
        {
            fileString = [fileString stringByAppendingString:@":!:!:"];
            fileString = [fileString stringByReplacingOccurrencesOfString:@"\n:!:!:" withString:@""];
        }
        NSArray *tempA = [fileString componentsSeparatedByString:@"\n"];
        NSMutableArray *tempMA = [NSMutableArray arrayWithCapacity:[tempA count]];
        for(NSString *item in tempA) [tempMA addObject:item];
        return tempMA;
    }
    else
    {
        //read online EngineList.txt
        NSString *fileString = [NSString stringWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://raw.githubusercontent.com/Sikarugir-App/Engines/main/EngineList.txt?%@",[[NSNumber numberWithLong:rand()] stringValue]]] encoding:NSUTF8StringEncoding error:nil];
        if ([fileString hasSuffix:@"\n"])
        {
            fileString = [fileString stringByAppendingString:@":!:!:"];
            fileString = [fileString stringByReplacingOccurrencesOfString:@"\n:!:!:" withString:@""];
        }
        NSArray *tempA = [fileString componentsSeparatedByString:@"\n"];
        NSMutableArray *tempMA = [NSMutableArray arrayWithCapacity:[tempA count]];
        for(NSString *item in tempA) [tempMA addObject:item];
        return tempMA;
    }
}

- (NSString *)getCurrentWrapperVersion
{
	NSString *folder = [NSString stringWithFormat:@"%@/Library/Application Support/Sikarugir/Wrapper",NSHomeDirectory()];
	NSFileManager *fm = [NSFileManager defaultManager];
	NSArray *filesArray = [fm contentsOfDirectoryAtPath:folder error:nil];
	NSMutableArray *files = [NSMutableArray arrayWithCapacity:2];
	for(NSString *file in filesArray)
	{
		if (!([file isEqualToString:@".DS_Store"])) [files addObject:file];
	}

	if ([files count] < 1) return @"No Wrapper Installed";
	if ([files count] > 1) return @"Error In Wrapper Folder";
	NSString *currentVersion = [files objectAtIndex:0];
	currentVersion = [currentVersion stringByReplacingOccurrencesOfString:@".app" withString:@""];
	return currentVersion;
}

- (void)setEnginesAvailablePrompt
{
	NSMutableArray *availableEngines = [self getAvailableEngines];
	NSArray *ignoredEngines = [self getEnginesToIgnore];
	NSMutableArray *testList = [NSMutableArray arrayWithCapacity:[availableEngines count]];
	for (NSString *itemAE in availableEngines)
	{
		BOOL matchFound=NO;
		for (NSWineskinEngine *itemIE in _installedEnginesList)
		{
			if ([itemAE isEqualToString:itemIE.engineName])
			{
				matchFound=YES;
				break;
			}
		}
		if (!matchFound)
		{
			for (NSString *itemIE in ignoredEngines)
			{
				if ([itemAE isEqualToString:itemIE])
				{
					matchFound=YES;
					break;
				}
			}
		}
		if (!matchFound) [testList addObject:itemAE];
	}
	if ([testList count] > 0) [engineAvailableLabel setHidden:NO];
	else [engineAvailableLabel setHidden:YES];
}

//TODO: Wrapper url
- (void)setWrapperAvailablePrompt
{
    NSDictionary* plistDictionary = [[NSDictionary alloc] initWithContentsOfFile:[NSString stringWithFormat:@"%@/Contents/Info.plist",[[NSBundle mainBundle] bundlePath]]];
	//get latest available version number
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://raw.githubusercontent.com/Sikarugir-App/Wrapper/main/NewestVersion.txt?%@",[[NSNumber numberWithLong:rand()] stringValue]]];
	NSString *newVersion = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
	newVersion = [newVersion stringByReplacingOccurrencesOfString:@"\n" withString:@""]; //remove \n
	if (newVersion == nil || ![[newVersion substringToIndex:8] isEqualToString:@"Template"]) return;
	//if different, prompt update available
	if ([[wrapperVersion stringValue] isEqualToString:newVersion])
	{
		[updateButton setEnabled:NO];
		[updateAvailableLabel setHidden:YES];
		return;
	}
	[updateButton setEnabled:YES];
	[updateAvailableLabel setHidden:NO];
}

- (IBAction)engineSearchFilter:(id)sender
{
	[self getInstalledEngines:[[sender stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
	[installedEngines reloadData];
}

- (IBAction)availEngineSearchFilter:(id)sender
{
	[self showAvailableEngines:[[sender stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
}

- (void)ds:(NSString *)input
{
	if (input == nil) input=@"nil";
	NSAlert *TESTER = [[NSAlert alloc] init];
	[TESTER addButtonWithTitle:@"close"];
	[TESTER setMessageText:@"Contents of string"];
	[TESTER setInformativeText:input];
	[TESTER setAlertStyle:NSInformationalAlertStyle];
	[TESTER runModal];
}

//******************* engine build window *****************************
- (IBAction)engineBuildChooseButtonPressed:(id)sender
{
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	[panel setTitle:@"Choose Wine Source Folder"];
	[panel setPrompt:@"Choose"];
	[panel setCanChooseDirectories:YES];
	[panel setCanChooseFiles:NO];
	[panel setAllowsMultipleSelection:NO];
	NSModalResponse error = [panel runModal];
	if (error == 0) return;
    
    NSURL* url = [[panel URLs] objectAtIndex:0];
	[engineBuildWineSource setStringValue:url.path];
}

//************ Engine Window (+ button) methods *******************
- (IBAction)engineWindowDownloadAndInstallButtonPressed:(id)sender
{
    NSString* selectedEngineName = [[engineWindowEngineList selectedItem] title];
    NSWineskinEngine* selectedEngine = [NSWineskinEngine wineskinEngineWithString:selectedEngineName];

    [urlInput setStringValue:[NSString stringWithFormat:@"https://github.com/Sikarugir-App/Engines/releases/download/v1.0/%@.tar.xz?%@",selectedEngineName,[[NSNumber numberWithLong:rand()] stringValue]]];
    [urlOutput setStringValue:[NSString stringWithFormat:@"file:///tmp/%@.tar.xz",[[engineWindowEngineList selectedItem] title]]];
    [fileName setStringValue:[[engineWindowEngineList selectedItem] title]];
    [fileNameDestination setStringValue:@"Engines"];
    // Workaround explorer.exe hang with CX24.x
    system([[NSString stringWithFormat:@"/usr/bin/xattr -drs com.apple.quarantine \"%@/Library/Application Support/Sikarugir/Engines\"",NSHomeDirectory()] UTF8String]);
    [downloadingWindow makeKeyAndOrderFront:self];
    [addEngineWindow orderOut:self];
}

- (IBAction)engineWindowViewWineReleaseNotesButtonPressed:(id)sender
{
    NSString* selectedEngineName = [[engineWindowEngineList selectedItem] title];
    NSWineskinEngine* selectedEngine = [NSWineskinEngine wineskinEngineWithString:selectedEngineName];
    NSString *wineVersion = selectedEngine.wineVersion;
    
    if (selectedEngine.engineType == NSWineskinEngineCrossOver)
    {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://www.codeweavers.com/crossover/changelog#%@",wineVersion]]];
    }
    else
    {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.winehq.org/announce/%@",wineVersion]]];
    }
}

- (IBAction)engineWindowEngineListChanged:(id)sender
{
	NSArray *ignoredEngines = [self getEnginesToIgnore];
	BOOL matchFound=NO;
	for (NSString *item in ignoredEngines)
		if ([item isEqualToString:[[engineWindowEngineList selectedItem] title]]) matchFound=YES;
	if (matchFound) [engineWindowDontPromptAsNewButton setEnabled:NO];
	else [engineWindowDontPromptAsNewButton setEnabled:YES];
    NSString* selectedEngineName = [[engineWindowEngineList selectedItem] title];
    NSWineskinEngine* selectedEngine = [NSWineskinEngine wineskinEngineWithString:selectedEngineName];
    if (selectedEngine.engineType == NSWineskinEngineWineStaging) [engineWindowViewWineReleaseNotesButton setEnabled:NO];
    else [engineWindowViewWineReleaseNotesButton setEnabled:YES];
}

- (IBAction)engineWindowDontPromptAsNewButtonPressed:(id)sender
{
	//read current ignore list into string
	NSArray *ignoredEngines = [self getEnginesToIgnore];
	NSString *ignoredEnginesString = @"";
	for (NSString *item in ignoredEngines)
		ignoredEnginesString = [ignoredEnginesString stringByAppendingString:[item stringByAppendingString:@"\n"]];
	ignoredEnginesString = [NSString stringWithFormat:@"%@\n%@",ignoredEnginesString,[[engineWindowEngineList selectedItem] title]];
	//write engine to ignored engines text file
	[ignoredEnginesString writeToFile:[NSHomeDirectory() stringByAppendingString:@"/Library/Application Support/Sikarugir/IgnoredEngines.txt"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
	//disable prompt button
	[engineWindowDontPromptAsNewButton setEnabled:NO];
	
}

- (IBAction)engineWindowDontPromptAllEnginesAsNewButtonPressed:(id)sender
{
	NSArray *ignoredEngines = [self getEnginesToIgnore];
	NSMutableArray *availableEngines = [NSMutableArray arrayWithCapacity:[ignoredEngines count]];
	NSInteger length = [engineWindowEngineList numberOfItems];
	for (int i=0;i<length;i++)
		[availableEngines addObject:[engineWindowEngineList itemTitleAtIndex:i]];
	NSMutableArray *fixedIgnoredEnginesList = [NSMutableArray arrayWithCapacity:[ignoredEngines count]];
	for (NSString *item in ignoredEngines)
	{
		if (!([availableEngines containsObject:item]))
			[fixedIgnoredEnginesList addObject:item];
	}
	NSString *ignoredEnginesString = @"";
	//add all fixed ignored list if any... new ones already removed.
	for (NSString *item in fixedIgnoredEnginesList)
		ignoredEnginesString = [NSString stringWithFormat:@"%@\n%@",ignoredEnginesString,item];
	//add all the engines available to the string
	for (NSString *item in availableEngines)
		ignoredEnginesString = [NSString stringWithFormat:@"%@\n%@",ignoredEnginesString,item];
	//remove any \n off the front of the string
	if ([ignoredEnginesString hasPrefix:@"\n"])
	{
		ignoredEnginesString = [ignoredEnginesString stringByReplacingCharactersInRange:[ignoredEnginesString rangeOfString:@"\n"] withString:@""];
	}
	//write engine to ignored engines text file
	[ignoredEnginesString writeToFile:[NSHomeDirectory() stringByAppendingString:@"/Library/Application Support/Sikarugir/IgnoredEngines.txt"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
	//disable prompt button
	[engineWindowDontPromptAsNewButton setEnabled:NO];
}

- (IBAction)engineWindowCancelButtonPressed:(id)sender
{
	[window makeKeyAndOrderFront:self];
	[addEngineWindow orderOut:self];
	[self refreshButtonPressed:self];
}

//***************************** Downloader ************************
- (IBAction) startDownload:(NSButton *)sender;
{
	[self downloadToggle:YES];
	NSString *input = [urlInput stringValue];
	NSURL *url = [NSURL URLWithString:input];
	
	request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20.0];
	connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
	if (connection)
	{
		payload = [NSMutableData data];
		//NSLog(@"Connection starting: %@", connection);
	}
	else
	{
		NSAlert *alert = [[NSAlert alloc] init];
		[alert addButtonWithTitle:@"OK"];
		[alert setMessageText:@"Download Failed!"];
		[alert setInformativeText:@"unable to download!"];
		[alert setAlertStyle:NSCriticalAlertStyle];
		[alert beginSheetModalForWindow:[cancelButton window] modalDelegate:self didEndSelector:nil contextInfo:nil];
		[self downloadToggle:NO];
	}
}

- (IBAction) stopDownloading:(NSButton *)sender;
{
	if (connection) [connection cancel];
	[self downloadToggle:NO];
	if (([[fileNameDestination stringValue] isEqualToString:@"EngineBase"]))
	{
		[wineskinEngineBuilderWindow makeKeyAndOrderFront:self];
		[downloadingWindow orderOut:self];
	}
	else if (([[fileNameDestination stringValue] isEqualToString:@"Engines"]))
	{
		[addEngineWindow makeKeyAndOrderFront:self];
		[downloadingWindow orderOut:self];
	}
	else if ([[fileName stringValue] isEqualToString:@"Wineskin Winery Update"])
	{
		//display warning about not updating.
		NSAlert *warning = [[NSAlert alloc] init];
		[warning addButtonWithTitle:@"OK"];
		[warning setMessageText:@"Warning!"];
		[warning setInformativeText:@"Some things may not function properly with new Wrappers or Engines until you update!"];
		[warning runModal];
		[window makeKeyAndOrderFront:self];
		[downloadingWindow orderOut:self];
	}
	else
	{
		[window makeKeyAndOrderFront:self];
		[downloadingWindow orderOut:self];
	}
}

- (void) downloadToggle:(BOOL)toggle
{
	[progressBar setMaxValue:100.0];
	[progressBar setDoubleValue:1.0];
	if (toggle == YES)
	{
		[downloadButton setEnabled:NO];
		[progressBar setHidden:NO];
	}
	else
	{
		[downloadButton setEnabled:YES];
		[progressBar setHidden:YES];
	}
}

- (void)connection:(NSURLConnection *)conn didReceiveResponse:(NSURLResponse *)response
{
	//NSLog(@"Recieved response with expected length: %i", [response expectedContentLength]);
	[payload setLength:0];
	[progressBar setMaxValue:[response expectedContentLength]];
}

- (void)connection:(NSURLConnection *)conn didReceiveData:(NSData *)data
{
	//NSLog(@"Recieving data. Incoming Size: %i  Total Size: %i", [data length], [payload length]);
	[payload appendData:data];
	[progressBar setDoubleValue:[payload length]];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)conn
{
	[self downloadToggle:NO];
	//delete any files that might exist in /tmp first
	[[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"/tmp/%@.app.tar.xz",[fileName stringValue]] error:nil];
	[[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"/tmp/%@.app.tar",[fileName stringValue]] error:nil];
	[[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"/tmp/%@.app",[fileName stringValue]] error:nil];
	[[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"/tmp/%@.tar.xz",[fileName stringValue]] error:nil];
	[[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"/tmp/%@.tar",[fileName stringValue]] error:nil];
	[[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"/tmp/%@",[fileName stringValue]] error:nil];
	[[NSFileManager defaultManager] removeItemAtPath:@"/tmp/WineskinWinery.app.tar.xz" error:nil];
	[[NSFileManager defaultManager] removeItemAtPath:@"/tmp/WineskinWinery.app.tar" error:nil];
	[[NSFileManager defaultManager] removeItemAtPath:@"/tmp/WineskinWinery.app" error:nil];
	[payload writeToURL:[NSURL URLWithString:[urlOutput stringValue]] atomically:YES];
	[busyWindow makeKeyAndOrderFront:self];
	[downloadingWindow orderOut:self];

    //TODO: Fix wrapper bundle name
	if (([[fileNameDestination stringValue] isEqualToString:@"Wrapper"]))
	{
		//uncompress download
		[self makeFoldersAndFiles];
		system([[NSString stringWithFormat:@"/usr/bin/tar -C /tmp -xf /tmp/%@.tar.xz",[fileName stringValue]] UTF8String]);
        //fix wrappers permissions
        system([[NSString stringWithFormat:@"chmod -R 777 \"/tmp/%@.app\"",[fileName stringValue]] UTF8String]);
		//remove 7z and tar
		[[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"/tmp/%@.tar.xz",[fileName stringValue]] error:nil];
		//remove old one
		[[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@/Library/Application Support/Sikarugir/Wrapper",NSHomeDirectory()] error:nil];
		[self makeFoldersAndFiles];
		//move download into place
		[[NSFileManager defaultManager] moveItemAtPath:[NSString stringWithFormat:@"/tmp/%@.app",[fileName stringValue]] toPath:[NSString stringWithFormat:@"%@/Library/Application Support/Sikarugir/%@/%@.app",NSHomeDirectory(),[fileNameDestination stringValue],[fileName stringValue]] error:nil];
        system([[NSString stringWithFormat:@"/usr/bin/xattr -drs com.apple.quarantine \%@/Library/Application Support/Sikarugir/%@/%@.app",NSHomeDirectory(),[fileNameDestination stringValue],[fileName stringValue]] UTF8String]);
		[window makeKeyAndOrderFront:self];
		[busyWindow orderOut:self];
	}
	else if (([[fileNameDestination stringValue] isEqualToString:@"Engines"]))
	{
		//move download into place
		[[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@/Library/Application Support/Sikarugir/%@/%@.tar.xz",NSHomeDirectory(),[fileNameDestination stringValue],[fileName stringValue]] error:nil];
		[[NSFileManager defaultManager] moveItemAtPath:[NSString stringWithFormat:@"/tmp/%@.tar.xz",[fileName stringValue]] toPath:[NSString stringWithFormat:@"%@/Library/Application Support/Sikarugir/%@/%@.tar.xz",NSHomeDirectory(),[fileNameDestination stringValue],[fileName stringValue]] error:nil];
		//Add engine to ignored list
		NSArray *ignoredEngines = [self getEnginesToIgnore];
		NSString *ignoredEnginesString = @"";
		BOOL fixTheList=YES;
		for (NSString *item in ignoredEngines)
		{
			if ([item isEqualToString:[fileName stringValue]])
			{
				fixTheList=NO;
				break;
			}
			ignoredEnginesString = [ignoredEnginesString stringByAppendingString:[item stringByAppendingString:@"\n"]];	
		}
		if (fixTheList)
		{
			ignoredEnginesString = [NSString stringWithFormat:@"%@\n%@",ignoredEnginesString,[fileName stringValue]];
			[ignoredEnginesString writeToFile:[NSHomeDirectory() stringByAppendingString:@"/Library/Application Support/Sikarugir/IgnoredEngines.txt"] atomically:YES encoding:NSUTF8StringEncoding error:nil];
		}
		[window makeKeyAndOrderFront:self];
		[busyWindow orderOut:self];
	}
	[self refreshButtonPressed:self];
}

- (void)connection:(NSURLConnection *)conn didFailWithError:(NSError *)error
{
	[self downloadToggle:NO];
	[payload setLength:0];	
	NSAlert *alert = [[NSAlert alloc] init];
	[alert addButtonWithTitle:@"OK"];
	[alert setMessageText:[error localizedDescription]];
	[alert setAlertStyle:NSCriticalAlertStyle];
	[alert beginSheetModalForWindow:[cancelButton window] modalDelegate:self didEndSelector:nil contextInfo:nil];
	[window makeKeyAndOrderFront:self];
	[downloadingWindow orderOut:self];
}

//*********************** wrapper creation **********************
- (IBAction)createWrapperOkButtonPressed:(id)sender
{
	//replace common symbols...
    NSString* wrapperName = [createWrapperName stringValue];
    wrapperName = [wrapperName stringByReplacingOccurrencesOfString:@"&" withString:@"and"];
    wrapperName = [wrapperName stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"!#$%%^*()+=|\\?><;:@"]];
    [createWrapperName setStringValue:wrapperName];

	//make sure wrapper name is unique
	if ([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@/Applications/Sikarugir/%@.app",NSHomeDirectory(),[createWrapperName stringValue]]])
	{
		NSAlert *alert = [[NSAlert alloc] init];
		[alert addButtonWithTitle:@"OK"];
		[alert setMessageText:@"Oops! File already exists!"];
		[alert setInformativeText:[NSString stringWithFormat:@"A wrapper at \"%@/Applications/Sikarugir\" with the name \"%@\" already exists!  Please choose a different name.",NSHomeDirectory(),[createWrapperName stringValue]]];
		[alert setAlertStyle:NSInformationalAlertStyle];
		[alert runModal];
		return;
	}

	//get rid of window
	[busyWindow makeKeyAndOrderFront:self];
	[createWrapperWindow orderOut:self];
	[self makeFoldersAndFiles];
	//delete files that might already exist
	NSFileManager *fm = [NSFileManager defaultManager];
	[fm removeItemAtPath:[NSString stringWithFormat:@"/tmp/%@.app",[createWrapperName stringValue]] error:nil];
	[fm removeItemAtPath:[NSString stringWithFormat:@"%@/Library/Application Support/Sikarugir/Engines/%@.tar",NSHomeDirectory(),[createWrapperEngine stringValue]] error:nil];
	[fm removeItemAtPath:[NSString stringWithFormat:@"%@/Library/Application Support/Sikarugir/Engines/wswine.bundle",NSHomeDirectory()] error:nil];
	//copy master wrapper to /tmp with correct name
	[fm copyItemAtPath:[NSString stringWithFormat:@"%@/Library/Application Support/Sikarugir/Wrapper/%@.app",NSHomeDirectory(),[wrapperVersion stringValue]] toPath:[NSString stringWithFormat:@"/tmp/%@.app",[createWrapperName stringValue]] error:nil];

	//decompress engine
	system([[NSString stringWithFormat:@"/usr/bin/tar -C \"%@/Library/Application Support/Sikarugir/Engines\" -xf \"%@/Library/Application Support/Sikarugir/Engines/%@.tar.xz\"",NSHomeDirectory(),NSHomeDirectory(),[createWrapperEngine stringValue]] UTF8String]);

    //TODO: wtf
    [self makeFoldersAndFiles];
    //system([[NSString stringWithFormat:@"/usr/bin/tar zxf /tmp/%@.tar.gz --strip-components=2 -C /tmp/wswine.bundle",[fileName stringValue]] UTF8String]);

	//remove tar
	[fm removeItemAtPath:[NSString stringWithFormat:@"%@/Library/Application Support/Sikarugir/Engines/%@.tar",NSHomeDirectory(),[createWrapperEngine stringValue]] error:nil];
	//test a couple of file sint he engine just to make sure it isn't corrupted
	BOOL engineError=NO;
	if (![fm fileExistsAtPath:[NSString stringWithFormat:@"%@/Library/Application Support/Sikarugir/Engines/wswine.bundle",NSHomeDirectory()]]) engineError=YES;
	else if (![fm fileExistsAtPath:[NSString stringWithFormat:@"%@/Library/Application Support/Sikarugir/Engines/wswine.bundle/bin/wineserver",NSHomeDirectory()]]) engineError=YES;
	if (engineError)
	{
		NSAlert *alert = [[NSAlert alloc] init];
		[alert addButtonWithTitle:@"OH NO!!"];
		[alert setMessageText:@"ERROR!"];
		[alert setInformativeText:[NSString stringWithFormat:@"The engine %@ is corrupted or opened incorrectly. If this error continues next time you try, reinstall the selected engine",[createWrapperEngine stringValue]]];
		[alert setAlertStyle:NSCriticalAlertStyle];
		[alert runModal];
		//get rid of junk in /tmp
		[fm removeItemAtPath:[NSString stringWithFormat:@"/tmp/%@.app",[createWrapperName stringValue]] error:nil];
		[fm removeItemAtPath:[NSString stringWithFormat:@"%@/Library/Application Support/Sikarugir/Engines/%@.tar",NSHomeDirectory(),[createWrapperEngine stringValue]] error:nil];
		[fm removeItemAtPath:[NSString stringWithFormat:@"%@/Library/Application Support/Sikarugir/Engines/wswine.bundle",NSHomeDirectory()] error:nil];
	}
	else
	{
        //TODO: Put engine in wrapper
		[fm copyItemAtPath:[NSString stringWithFormat:@"%@/Library/Application Support/Sikarugir/Engines/wswine.bundle",NSHomeDirectory()] toPath:[NSString stringWithFormat:@"/tmp/%@.app/Contents/SharedSupport/wine",[createWrapperName stringValue]] error:nil];
        [fm removeItemAtPath:[NSString stringWithFormat:@"%@/Library/Application Support/Sikarugir/Engines/wswine.bundle",NSHomeDirectory()] error:nil];
                
        // 777 the wrapper
        system([[NSString stringWithFormat:@"chmod -R 777 \"/tmp/%@.app\"",[createWrapperName stringValue]] UTF8String]);

        // 777 the bundle
        system([[NSString stringWithFormat:@"chmod 777 \"/tmp/%@.app/Contents/SharedSupport/wine\"",[createWrapperName stringValue]] UTF8String]);

        system([[NSString stringWithFormat:@"/usr/bin/xattr -drs com.apple.quarantine \"/tmp/%@.app\"",[createWrapperName stringValue]] UTF8String]);

        //initialize wrapper
        system([[NSString stringWithFormat:@"\"/tmp/%@.app/Contents/MacOS/wineskinlauncher\" WSS-wineprefixcreate",[createWrapperName stringValue]] UTF8String]);

		//move wrapper to ~/Applications/Sikarugir
		[fm moveItemAtPath:[NSString stringWithFormat:@"/tmp/%@.app",[createWrapperName stringValue]] toPath:[NSString stringWithFormat:@"%@/Applications/Sikarugir/%@.app",NSHomeDirectory(),[createWrapperName stringValue]] error:nil];

		//put ending message
		NSAlert *alert = [[NSAlert alloc] init];
		[alert addButtonWithTitle:@"View wrapper in Finder"];
		[alert addButtonWithTitle:@"OK"];
		[alert setMessageText:@"Wrapper Creation Finished"];
		[alert setInformativeText:[NSString stringWithFormat:@"Created File: %@.app\n\nCreated In:%@/Applications/Sikarugir\n",[createWrapperName stringValue],NSHomeDirectory()]];
		[alert setAlertStyle:NSInformationalAlertStyle];
		if ([alert runModal] == NSAlertFirstButtonReturn)
        {
			[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"file://%@/Applications/Sikarugir/",NSHomeDirectory()]]];
        }
	}
	// bring main window back
	[window makeKeyAndOrderFront:self];
	[busyWindow orderOut:self];
}

- (IBAction)createWrapperCancelButtonPressed:(id)sender
{
	[window makeKeyAndOrderFront:self];
	[createWrapperWindow orderOut:self];
}

//***************************** OVERRIDES *************************
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [self.installedEnginesList count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    NSString* engineName = [self.installedEnginesList objectAtIndex:rowIndex].engineName;
    NSMutableAttributedString* text = [[NSMutableAttributedString alloc] initWithString:engineName];

    if (![self.installedEnginesList objectAtIndex:rowIndex].requiresXquartz) {
        [text setFontColor:[NSColor redColor]];
    }
    return text;
}

- (id)init
{
	self = [super init];
	if (self)
	{
		_installedEnginesList = [[NSMutableArray alloc] init];
        _installedMacDriverEnginesList = [[NSMutableArray alloc] init];
	}
	return self;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
    return YES;
}

@end
