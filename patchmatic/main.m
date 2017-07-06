//
// main.m
// patchmatic
//
// Created by RehabMan on 3/28/13.
// Copyright (c) 2013 RehabMan. All rights reserved.
//
// A simple command line driver for patching functionality of MaciASL.
//
// Most functionality is in two core components of MaciASL:
//     Navigator: DSDT parser
//     Patch: DSDT patching
//
// I simply added enough #ifdefs to those source files to get the code
// to run in a command line environment.
//

//#define REGEXTEST

#import <Foundation/Foundation.h>

#import "../MaciASL/Patch.h"

const char name[] = "patchmatic";

void NSPrintF(NSString *format, ...) {
    va_list args;
    va_start(args, format);
    NSString* formattedString = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    NSFileHandle* fileStdout = [NSFileHandle fileHandleWithStandardOutput];
    [fileStdout writeData:[formattedString dataUsingEncoding:NSASCIIStringEncoding]];
#if !__has_feature(objc_arc)
    [formattedString release];  // could also be [formattedString autorelease] (especially if we were returning it)
#endif
}

static void PatchMatic(NSString* strInputFile, NSString* strPatchesFile, NSString* strOutputFile) {
    NSError* err;
    NSString* strInput = [NSString stringWithContentsOfFile:strInputFile encoding:NSASCIIStringEncoding error:&err];
    if (nil == strInput) {
        NSPrintF(@"%s: unable to open input file '%@'\n", name, strInputFile);
        return;
    }
    NSString* strPatches = [NSString stringWithContentsOfFile:strPatchesFile encoding:NSASCIIStringEncoding error:&err];
    if (nil == strPatches) {
        NSPrintF(@"%s: unable to open patches file '%@'\n", name, strPatchesFile);
        return;
    }
    PatchFile* patches = [PatchFile create:strPatches];
    patches.text = [NSMutableString stringWithString:strInput];
    [patches apply];
    NSPrintF(@"patch complete: %d patches, %ld changes, %d rejects\n", (unsigned)patches.patches.count, patches.preview.count-patches.rejects, (unsigned)patches.rejects);
    if (![patches.text writeToFile:strOutputFile atomically:NO encoding:NSASCIIStringEncoding error:&err]) {
        NSPrintF(@"%s: unable to write output file '%@'\n", name, strOutputFile);
        return;
    }
    NSPrintF(@"patched result written to '%@'\n", strOutputFile);
}

void ExtractTables(bool all, NSString* strTargetDirectory)
{
    io_service_t expert;
    if ((expert = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("AppleACPIPlatformExpert")))) {
        NSDictionary* tableset = (__bridge NSDictionary *)IORegistryEntryCreateCFProperty(expert, CFSTR("ACPI Tables"), kCFAllocatorDefault, 0);
        for (NSString* table in tableset.allKeys) {
            if (all || [table hasPrefix:@"DSDT"] || [table hasPrefix:@"SSDT"]) {
                ////NSPrintF(@"%@\n", table);
                NSData* aml = [tableset objectForKey:table];
                if (aml) {
                    NSMutableString* name = [NSMutableString stringWithString:table];
                    [name appendString:@".aml"];
                    // Add directory
                    if(strTargetDirectory != nil){
                        [name insertString:strTargetDirectory atIndex:0];
                    }
                    [aml writeToFile:name atomically:false];
                    ////NSPrintF(@"%@\n", name);
                }
            }
        }
        IOObjectRelease(expert);
    }
}

#ifndef REGEXTEST
int main(int argc, const char* argv[]) {
    @autoreleasepool {
        if (2 == argc && 0 == strcmp(argv[1], "-extract"))
        {
            ExtractTables(false, nil);
            return 0;
        }
        //// If <target> is given
        if (3 == argc && 0 == strcmp(argv[1], "-extract"))
        {
            bool isDir;
            NSString* strTargetDirectory = [NSString stringWithCString:argv[2] encoding:NSASCIIStringEncoding];
            if([[NSFileManager defaultManager] fileExistsAtPath:strTargetDirectory isDirectory:&isDir]){
                if(isDir){
                    if(![strTargetDirectory hasSuffix:@"/"]) strTargetDirectory = [strTargetDirectory stringByAppendingString:@"/"];
                    ExtractTables(false, strTargetDirectory);
                    return 0;
                }
            }
            return 1;
        }
        if (2 == argc && 0 == strcmp(argv[1], "-extractall"))
        {
            ExtractTables(true, nil);
            return 0;
        }
        //// If <target> is given
        if (3 == argc && 0 == strcmp(argv[1], "-extractall"))
        {
            bool isDir;
            NSString* strTargetDirectory = [NSString stringWithCString:argv[2] encoding:NSASCIIStringEncoding];
            if([[NSFileManager defaultManager] fileExistsAtPath:strTargetDirectory isDirectory:&isDir]){
                if(isDir){
                    if(![strTargetDirectory hasSuffix:@"/"]) strTargetDirectory = [strTargetDirectory stringByAppendingString:@"/"];
                    ExtractTables(true, strTargetDirectory);
                    return 0;
                }
            }
            return 1;
        }
        if (argc < 3)
        {
            NSString* usage =
            @"Usage: patchmatic <dsl-input> <patches-file> [<dsl-output>]\n"
            " where:\n"
            "   <dsl-input>     name of ASCII DSL input file (output from iasl -d)\n"
            "   <patches-file>  name of file containing patches to apply to <dsl-input>\n"
            "   <dsl-output>    name of patched output file (to be compiled with iasl)\n"
            ">> Patches <dsl-input> with <patches-file> and produces patched <dsl-output>\n"
            "\n"
            "-OR-\n"
            "\n"
            "Usage: patchmatic -extract [<target>]\n"
            "Usage: patchmatic -extractall [<target>]\n"
            " where:\n"
            "   <target>        target directory (must be an existing directory)\n"
            ">> Extracts loaded ACPI binaries from ioreg\n"
            "  -extract will extract just DSDT/SSDTs\n"
            "  -extractall will extract all ACPI tables\n"
            "\n";
            NSPrintF(@"%@", usage);
            return 1;
        }
        NSString* strInputFile = [NSString stringWithCString:argv[1] encoding:NSASCIIStringEncoding];
        NSString* strPatchesFile = [NSString stringWithCString:argv[2] encoding:NSASCIIStringEncoding];
        NSString* strOutputFile = argc > 3 ? [NSString stringWithCString:argv[3] encoding:NSASCIIStringEncoding] : strInputFile;
        PatchMatic(strInputFile, strPatchesFile, strOutputFile);
    }
    return 0;
}

#else

int main(int argc, const char* argv[]) {
    @autoreleasepool {
        NSError *error = NULL;
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\b(a|b)(c|d)\\b"
                                                                               options:NSRegularExpressionCaseInsensitive
                                                                                 error:&error];
        
        NSString* string = @"aa bb ab ac bc ba ad bd";
        NSUInteger numberOfMatches = [regex numberOfMatchesInString:string
                                                            options:0
                                                              range:NSMakeRange(0, [string length])];
        NSPrintF(@"numberOfMatches: %ld\n", numberOfMatches);
        
        NSRange rangeOfFirstMatch = [regex rangeOfFirstMatchInString:string options:0 range:NSMakeRange(0, [string length])];
        if (!NSEqualRanges(rangeOfFirstMatch, NSMakeRange(NSNotFound, 0))) {
            NSString *substringForFirstMatch = [string substringWithRange:rangeOfFirstMatch];
            NSPrintF(@"substringForFirstMatch = '%@'\n", substringForFirstMatch);
        }
        
        NSPrintF(@"begin array match...\n");
        NSArray *matches = [regex matchesInString:string
                                          options:0
                                            range:NSMakeRange(0, [string length])];
        for (NSTextCheckingResult *match in matches) {
            NSPrintF(@"match.numberOfRanges = %ld\n", [match numberOfRanges]);
            for (NSUInteger x = 0; x < [match numberOfRanges]; ++x) {
                NSPrintF(@"match[%ld] = (%ld, %ld)\n", x, [match rangeAtIndex:x].location, [match rangeAtIndex:x].length);
            }
        }
        
        NSPrintF(@"begin enumeration...\n");
        [regex enumerateMatchesInString:string options:0 range:NSMakeRange(0, [string length]) usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop){
            NSPrintF(@"match.numberOfRanges = %ld\n", [match numberOfRanges]);
            for (NSUInteger x = 0; x < [match numberOfRanges]; ++x) {
                NSPrintF(@"match[%ld] = (%ld, %ld)\n", x, [match rangeAtIndex:x].location, [match rangeAtIndex:x].length);
            }
        }];
        
        NSString* replacement1 =
        [regex stringByReplacingMatchesInString:string options:0 range:NSMakeRange(0, [string length]) withTemplate:@"$0/$1/$2"];
        NSPrintF(@"replacement1 = '%@'\n", replacement1);
        
        NSMutableString* replacement2 = [NSMutableString stringWithString:string];
        [regex replaceMatchesInString:replacement2 options:0 range:NSMakeRange(0, [string length]) withTemplate:@"$0-$1-$2"];
        NSPrintF(@"replacement2 = '%@'\n", replacement2);
        
        NSPrintF(@"begin replacementStringForResult test...\n");
        matches = [regex matchesInString:string
                                 options:0
                                   range:NSMakeRange(0, [string length])];
        for (NSUInteger x = 0; x < [matches count]; x++) {
            NSString* replacementString = [regex replacementStringForResult:[matches objectAtIndex:x] inString:string offset:0 template:@"$$$$0__$xyz$$TE\\$T0$0_TEST1$1\\TEST2_$2LAST\\$"];
            NSPrintF(@"replacementString(%ld) = '%@'\n", x, replacementString);
        }
        
        NSPrintF(@"begin escapedTemplateForString test...\n");
        NSString* escapedTemplate = [NSRegularExpression escapedTemplateForString:@"This is without escapes"];
        NSPrintF(@"without escapes: %@\n", escapedTemplate);
        escapedTemplate = [NSRegularExpression escapedTemplateForString:@"$1 $2 $3 escapes at beginning"];
        NSPrintF(@"escapes at beginning: %@\n", escapedTemplate);
        escapedTemplate = [NSRegularExpression escapedTemplateForString:@"escapes at end $1 $2 $3"];
        NSPrintF(@"escapes at end: %@\n", escapedTemplate);
        escapedTemplate = [NSRegularExpression escapedTemplateForString:@"escapes in middle $1 $2 $3 after middle"];
        NSPrintF(@"escapes in middle: %@\n", escapedTemplate);
        escapedTemplate = [NSRegularExpression escapedTemplateForString:@"$1 $2 $3 $$$$ escapes in beginning/middle/end $4 $5 $6 $$$$ after middle $$$$ $7 $8 $9"];
        NSPrintF(@"escapes everywhere: %@\n", escapedTemplate);
    }
}

#endif
