//
//  main.m
//  patchmatic
//
//  Created by Admin on 3/28/13.
//  Copyright (c) 2013 Sourceforge. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "../MaciASL/Patch.h"

const char name[] = "patchmatic";

void NSPrintF(NSString *format, ...) {
    va_list args;
    va_start(args, format);
    NSString *formattedString = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    NSFileHandle* fileStdout = [NSFileHandle fileHandleWithStandardOutput];
    [fileStdout writeData:[formattedString dataUsingEncoding:NSASCIIStringEncoding]];
}

static void PatchMatic(NSString* strInputFile, NSString* strPatchesFile, NSString* strOutputFile) {
    NSError* err;
    NSString* strInput = [NSString stringWithContentsOfFile:strInputFile encoding:NSASCIIStringEncoding error:&err];
    if (nil == strInput) {
        NSPrintF(@"%s: unable to open input file '%@'\n", name, strInputFile);
        NSPrintF(@"error description: %@\n", [err localizedDescription]);
        return;
    }
    NSString* strPatches = [NSString stringWithContentsOfFile:strPatchesFile encoding:NSASCIIStringEncoding error:&err];
    if (nil == strPatches) {
        NSPrintF(@"%s: unable to open patches file '%@'\n", name, strPatchesFile);
        NSPrintF(@"error description: %@\n", [err localizedDescription]);
        return;
    }
    PatchFile* patches = [PatchFile create:strPatches];
    patches.text = [NSMutableString stringWithString:strInput];
    [patches apply];
    if (![patches.text writeToFile:strOutputFile atomically:NO encoding:NSASCIIStringEncoding error:&err]) {
        NSPrintF(@"%s: unable to write output file '%@'\n", name, strOutputFile);
        NSPrintF(@"error description: %@\n", [err localizedDescription]);
        return;
    }
    NSPrintF(@"patch complete... written to '%@': %d patches, %ld changes, %d rejects\n", strOutputFile, (unsigned)patches.patches.count, patches.preview.count-patches.rejects, (unsigned)patches.rejects);
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        if (argc < 4)
        {
            NSString* usage =
               @"Usage: %s <dsl-input> <patches-file> <dsl-output>\n"
                " where:\n"
                "   <dsl-input>     name of ASCII DSL input file (output from iasl -d)\n"
                "   <patches-file>  name of file containing patches to apply to <dsl-input>\n"
                "   <dsl-output>    name of patched output file (to be compiled with iasl)\n";
            NSPrintF(usage, name);
            return 1;
        }
        NSString* strInputFile = [NSString stringWithCString:argv[1] encoding:NSASCIIStringEncoding];
        NSString* strPatchesFile = [NSString stringWithCString:argv[2] encoding:NSASCIIStringEncoding];
        NSString* strOutputFile = [NSString stringWithCString:argv[3] encoding:NSASCIIStringEncoding];
        PatchMatic(strInputFile, strPatchesFile, strOutputFile);
    }
    return 0;
}

