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

#define countof(x) (sizeof(x)/sizeof(x[0]))

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

void ExtractTables(NSString* target, bool all, bool noOemTableId, bool noHotpatchNaming)
{
    io_service_t expert;
    if ((expert = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("AppleACPIPlatformExpert")))) {
        NSDictionary* tableset = (__bridge NSDictionary *)IORegistryEntryCreateCFProperty(expert, CFSTR("ACPI Tables"), kCFAllocatorDefault, 0);
        for (NSString* table in tableset.allKeys) {
            if (all || [table hasPrefix:@"DSDT"] || [table hasPrefix:@"SSDT"]) {
                ////NSPrintF(@"%@\n", table);
                NSData* aml = [tableset objectForKey:table];
                if (aml) {
                    // default rules for naming... (depending on noOemTableId/noHotpatchNaming)
                    // SSDT -> SSDT-0.aml (or SSDT-0-tblid)
                    // SSDT-nn where OemTableID does not start with underscore -> SSDT-nn.aml (or SSDT-nn-tblid)
                    // SSDT-nn where OemTableID starts with underscore -> SSDT-tblid_without_leading_underscore
                    // others -> tablename.aml
                    NSMutableString* name = [NSMutableString stringWithString:table];
                    // special case for SSDT.aml to match Clover ACPI/origin extract
                    if ([name isEqualToString:@"SSDT"]) {
                        [name setString:@"SSDT-0"];
                    }
                    // append table name
                    if ([name hasPrefix:@"SSDT"]) {
                        NSString* suffix = [[[NSString alloc] initWithData:[[tableset objectForKey:table] subdataWithRange:NSMakeRange(16, 8)] encoding:NSASCIIStringEncoding] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                        // table name can have NULs in it, so clean it up
                        char buffer[9];
                        [suffix getCString:buffer maxLength:countof(buffer) encoding:NSASCIIStringEncoding];
                        NSString* clean = [NSString stringWithFormat:@"%s", buffer];
                        if ([clean length] != 0) {
                            if ([clean hasPrefix:@"_"] && !noHotpatchNaming) {
                                // when OemTableID starts with underscore,...
                                if ([clean length] > 1) {
                                    [name setString:@"SSDT-"];
                                    [name appendString:[clean substringFromIndex:1]];
                                }
                            } else {
                                if (!noOemTableId) {
                                    [name appendString:@"-"];
                                    [name appendString:clean];
                                }
                            }
                        }
                    }
                    [name appendString:@".aml"];
                    // add target directory
                    if (target != nil) {
                        [name insertString:target atIndex:0];
                    }
                    ////NSPrintF(@"name: \"%@\"\n", name);
                    [aml writeToFile:name atomically:NO];
                }
            }
        }
        IOObjectRelease(expert);
    }
}

void Usage()
{
    NSString* usage =
        @"Usage: patchmatic <dsl-input> <patches-file> [<dsl-output>]\n"
        " where:\n"
        "   <dsl-input>     name of ASCII DSL input file (output from iasl -d)\n"
        "   <patches-file>  name of file containing patches to apply to <dsl-input>\n"
        "   [dsl-output]    optional name of patched output file (to be compiled with iasl)\n"
        ">> Patches <dsl-input> with <patches-file> and produces patched [dsl-output]\n"
        "   (when [dsl-output] not specified, output is to <dsl-input>)\n"
        "\n"
        "-OR-\n"
        "\n"
        "Usage: patchmatic [options] -extract [target-directory]\n"
        "Usage: patchmatic [options] -extractall [target-directory]\n"
        ">> Extracts loaded ACPI binaries from ioreg\n"
        "  -extract will extract just DSDT/SSDTs\n"
        "  -extractall will extract all ACPI tables\n"
        ">> Options (may appear after -extract/-extractall or before)\n"
        "  -nooemtableid: omits OEM table ID from file names\n"
        "  -nohotpatchnaming: no OEM table ID handling based on RM hotpatch conventions\n"
        "  -raw: same as both -nooemtableid and -nohotpatchnaming\n"
        "\n";
    NSPrintF(@"%@", usage);
}

#ifndef REGEXTEST
int main(int argc, const char* argv[]) {
    @autoreleasepool {
        bool extract = false;
        bool all = false;
        bool noOemTableId = false;
        bool noHotpatchNaming = false;
        NSString* target = nil;
        int i = 1;
        for (; i < argc; i++) {
            const char* arg = argv[i];
            if (0 == strcmp(arg, "-extract")) {
                extract = true;
            }
            else if (0 == strcmp(arg, "-extractall")) {
                extract = true;
                all = true;
            }
            else if (0 == strcmp(arg, "-nooemtableid")) {
                noOemTableId = true;
            }
            else if (0 == strcmp(arg, "-nohotpatchnaming")) {
                noHotpatchNaming = true;
            }
            else if (0 == strcmp(arg, "-raw")) {
                noOemTableId = true;
                noHotpatchNaming = true;
            }
            else {
                break;
            }
        }
        if (extract) {
            if (argc - i > 1) {
                Usage();
                return 0;
            }
            if (argc - i == 1) {
                // target directory specified
                target = [NSString stringWithCString:argv[i] encoding:NSASCIIStringEncoding];
                BOOL isDir;
                if (![[NSFileManager defaultManager] fileExistsAtPath:target isDirectory:&isDir]) {
                    NSPrintF(@"Error: target specified, \"%@\", does not exist\n", target);
                    return 0;
                }
                if (!isDir) {
                    NSPrintF(@"Error: target specified, \"%@\", is not a directory\n", target);
                    return 0;
                }
                if (![target hasSuffix:@"/"])
                    target = [target stringByAppendingString:@"/"];
            }
            ExtractTables(target, all, noOemTableId, noHotpatchNaming);
            return 0;
        }
        if (argc - i < 2 || argc - i > 3)
        {
            Usage();
            return 1;
        }
        // Normal patching function (now rarely used)
        NSString* strInputFile = [NSString stringWithCString:argv[i+0] encoding:NSASCIIStringEncoding];
        NSString* strPatchesFile = [NSString stringWithCString:argv[i+1] encoding:NSASCIIStringEncoding];
        NSString* strOutputFile = argc > 3 ? [NSString stringWithCString:argv[i+2] encoding:NSASCIIStringEncoding] : strInputFile;
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
