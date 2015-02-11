//
//  main.m
//  MaciASL
//
//  Created by PHPdev32 on 9/21/12.
//  Licensed under GPLv3, full text at http://www.gnu.org/licenses/gpl-3.0.txt
//

#import <Cocoa/Cocoa.h>

void handle_exception(NSException *exception) {
    @try {
        NSString *file = [NSString stringWithFormat:@"/tmp/%ld.plist", roundtol([[NSDate date] timeIntervalSince1970])];
        NSMutableDictionary *d = [NSMutableDictionary dictionary];
        if (exception.name) [d setObject:exception.name forKey:@"name"];
        if (exception.reason) [d setObject:exception.reason forKey:@"reason"];
        if (exception.userInfo) [d setObject:exception.userInfo forKey:@"userInfo"];
        if (exception.callStackReturnAddresses) [d setObject:exception.callStackReturnAddresses forKey:@"callStackReturnAddresses"];
        if (exception.callStackSymbols) [d setObject:exception.callStackSymbols forKey:@"callStackSymbols"];
        [d writeToFile:file atomically:true];
        NSRunAlertPanel(@"Uncaught Exception", @"An uncaught exception has occurred, and the program will now terminate. Please post the revealed file (may contain personal information), to %@", nil, nil, nil, @"http://sourceforge.net/projects/maciasl/support");
        [NSWorkspace.sharedWorkspace selectFile:file inFileViewerRootedAtPath:file];
    } @catch (NSException *e) {}
}

int main(int argc, char *argv[])
{
    NSSetUncaughtExceptionHandler(&handle_exception);
    NSImage *temp = [[NSImage alloc] initByReferencingFile:@"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/ToolbarUtilitiesFolderIcon.icns"];
    if (![temp isValid]) {
        temp = [[NSImage alloc] initByReferencingFile:@"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/ToolbarCustomizeIcon.icns"];
    }
    temp.name = @"ToolbarUtilitiesFolderIcon";
    return NSApplicationMain(argc, (const char **)argv);
}
