/*
 * LipikaIME is a user-configurable phonetic Input Method Engine for Mac OS X.
 * Copyright (C) 2013 Ranganath Atreya
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 */

#import "DJLipikaInputController.h"
#import "DJPreferenceController.h"
#import "DJInputEngineFactory.h"
#import "DJLipikaFileConvertor.h"
#import "Constants.h"

@implementation DJLipikaInputController

#pragma mark - Overridden methods of IMKInputController

-(id)initWithServer:(IMKServer *)server delegate:(id)delegate client:(id)inputClient {
    self = [super initWithServer:server delegate:delegate client:inputClient];
    if (self == nil) {
        return self;
    }
    manager = [[DJLipikaClientManager alloc] initWithClient:[[DJLipikaClientDelegate alloc] initWithClient:inputClient]];
    return self;
}

-(void)candidateSelected:(NSAttributedString *)candidateString {
    [manager onCandidateSelected:candidateString.string];
}

-(NSMenu *)menu {
	return [[NSApp delegate] mainMenu];
}

#pragma mark - IMKServerInput and IMKStateSetting protocol methods

-(BOOL)inputText:(NSString *)string client:(id)sender {
    return [manager inputText:string];
}

-(void)commitComposition:(id)sender {
    [manager onEndSession];
}

-(BOOL)didCommandBySelector:(SEL)aSelector client:(id)sender {
    if (aSelector == @selector(deleteBackward:)) {
        return [manager handleBackspace];
    }
    else if (aSelector == @selector(cancelOperation:)) {
        return [manager handleCancel];
    }
    else {
        [manager commit];
    }
    return NO;
}

-(NSArray *)candidates:(id)sender {
    return [manager.candidateManager candidates];
}

// This message is sent when our client gains focus
-(void)activateServer:(id)sender {
    [manager onFocus];
}

// This message is sent when our client looses focus
-(void)deactivateServer:(id)sender {
    [manager onUnFocus];
}

-(IBAction)showPreferences:(id)sender {
/*
 sender is a NSDictionary object with the following keys:
 {
    IMKCommandClient = "<IMKInputSession>";
    IMKCommandMenuItem = "<NSMenuItem>";
    IMKMenuTitle = "<NSString>";
 }
 */
    NSMenuItem *menuItem = [sender objectForKey:kIMKCommandMenuItemName];
    if ([menuItem tag] == 1) {     // Preferrence
        [self showPreferenceImplimentation:menuItem];
    }
    else if ([menuItem tag] == 2) { // Convert file
        [DJLipikaFileConvertor convert];
    }
    else if ([menuItem tag] > 2) { // Input Schemes
        [self changeInputScheme:menuItem];
    }
    else {
        [NSException raise:@"Unknown tag" format:@"Unknown menu tag: %ld", [menuItem tag]];
    }
}

#pragma mark - DJLipikaInputController's instance methods

-(void)clearAllOnStates:(NSMenu *)rootMenu {
    NSArray *peerItems = [rootMenu itemArray];
    [peerItems enumerateObjectsUsingBlock:^(NSMenuItem *obj, NSUInteger idx, BOOL *stop) {
        [obj setState:NSOffState];
        if ([obj hasSubmenu]) [self clearAllOnStates:[obj submenu]];
    }];
}

-(void)changeInputScheme:(NSMenuItem *)menuItem {
    BOOL isGoogleItem = [[[[menuItem parentItem] submenu] title] isEqualToString:DJGoogleSubMenu];
    BOOL isSchemeItem = [[[[menuItem parentItem] submenu] title] isEqualToString:DJSchemeSubMenu];
    BOOL isScriptItem = [[[[menuItem parentItem] submenu] title] isEqualToString:DJScriptSubMenu];
    if (isGoogleItem) {
        [self clearAllOnStates:[NSApp mainMenu]];
    }
    else if (isScriptItem || isSchemeItem) {
        // Clear state of all sub-menus under "Input scheme" or "Output script" menu item
        [self clearAllOnStates:[menuItem menu]];
    }
    else {
        [NSException raise:@"Unknown menu item" format:@"Menu parent title %@ not recognized", [[[menuItem parentItem] submenu] title]];
    }
    // Turn on state for the script and scheme
    [menuItem setState:NSOnState];
    NSString *name = [menuItem title];
    if (isSchemeItem) {
        [manager changeToSchemeWithName:name forScript:[DJInputEngineFactory currentScriptName] type:DJ_LIPIKA];
    }
    else if (isScriptItem) {
        [manager changeToSchemeWithName:[DJInputEngineFactory currentSchemeName] forScript:name type:DJ_LIPIKA];
    }
    else if (isGoogleItem) {
        [manager changeToSchemeWithName:name forScript:nil type:DJ_GOOGLE];
    }
}

-(void)showPreferenceImplimentation:(NSMenuItem *)menuItem {
    static DJPreferenceController *preference;
    if (!preference) {
        preference = [[DJPreferenceController alloc] initWithWindowNibName:@"Preferences"];
    }
    [NSApp activateIgnoringOtherApps:YES];
    [[preference window] makeKeyAndOrderFront:self];
    [preference showWindow:self];
}

@end
