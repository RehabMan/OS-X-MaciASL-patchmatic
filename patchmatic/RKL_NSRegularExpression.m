//
//  RKL_NSRegularExpression.m
//  MaciASL
//
//  Created by Admin on 4/2/13.
//  Copyright (c) 2013 Sourceforge. All rights reserved.
//

#import "RKL_NSRegularExpression.h"
#import "RegexKitLite.h"

static RKLRegexOptions ConvertOptions(RKL_NSRegularExpressionOptions options) {
    RKLRegexOptions result = RKLNoOptions;
    if (options & RKL_NSRegularExpressionCaseInsensitive)
        result |= RKLCaseless;
    if (options & RKL_NSRegularExpressionAllowCommentsAndWhitespace)
        result |= RKLComments;
    //REVIEW: no equiv. for RKL_NSRegularExpressionIgnoreMetacharacters (would need to escape entire string)
    if (options & RKL_NSRegularExpressionDotMatchesLineSeparators)
        result |= RKLDotAll;
    if (options & RKL_NSRegularExpressionAnchorsMatchLines)
        result |= RKLMultiline;
    //REVIEW: no equiv. for RKL_NSRegularExpressionUseUnixLineSeparators (hopefully we don't need it)
    if (options & RKL_NSRegularExpressionUseUnicodeWordBoundaries)
        result |= RKLUnicodeWordBoundaries;
    return result;
}

#undef NSRegularExpression

@implementation RKL_NSRegularExpression

+ (RKL_NSRegularExpression*)regularExpressionWithPattern:(NSString*)pattern options:(NSRegularExpressionOptions)options error:(NSError**)error {
    if (error) *error = nil;
    RKL_NSRegularExpression* temp = [RKL_NSRegularExpression new];
    if (nil != temp) {
        temp->_p_pattern = [pattern copy];
        temp->_p_options = options;
    }
    return temp;
}

- (id)initWithPattern:(NSString*)pattern options:(NSRegularExpressionOptions)options error:(NSError**)error {
    if (error) *error = nil;
    self->_p_pattern = [pattern copy];
    self->_p_options = options;
    return self;
}

@synthesize pattern=_p_pattern;
////- (NSString*)pattern { return _p_pattern; }

@synthesize options=_p_options;
////- (NSRegularExpressionOptions)options { return _p_options; }

- (NSUInteger)numberOfCaptureGroups { return [_p_pattern captureCount]; }

#if 0
+ (NSString*)escapedPatternForString:(NSString*)string {
    //REVIEW_NOTIMPL: implement me...
    return nil;
}
#endif

@end // RK_NSRegularExpression

@implementation RKL_NSRegularExpression (RKL_NSMatching)

#if NS_BLOCKS_AVAILABLE
- (void)enumerateMatchesInString:(NSString*)string options:(NSMatchingOptions)options range:(NSRange)range usingBlock:(void (^)(NSTextCheckingResult*result, NSMatchingFlags flags, BOOL* stop))block {
    RKLRegexOptions rkl_options = ConvertOptions(_p_options);
    [string enumerateStringsMatchedByRegex:_p_pattern options:rkl_options inRange:range error:nil enumerationOptions:RKLRegexEnumerationCapturedStringsNotRequired usingBlock:^(NSInteger captureCount, NSString* const __unsafe_unretained* capturedStrings, const NSRange* capturedRanges, volatile BOOL* const stop) {
        NSTextCheckingResult* result = [NSTextCheckingResult textCheckingResultWithRanges:capturedRanges andCount:captureCount];
        block(result, 0, (BOOL*)stop);
    }];
}
#endif /* NS_BLOCKS_AVAILABLE */

- (NSArray*)matchesInString:(NSString*)string options:(NSMatchingOptions)options range:(NSRange)range {
    RKLRegexOptions rkl_options = ConvertOptions(_p_options);
    __block NSMutableArray* array = [NSMutableArray array];
    [string enumerateStringsMatchedByRegex:_p_pattern options:rkl_options inRange:range error:nil enumerationOptions:RKLRegexEnumerationCapturedStringsNotRequired usingBlock:^(NSInteger captureCount, NSString* const __unsafe_unretained* capturedStrings, const NSRange* capturedRanges, volatile BOOL* const stop) {
        NSTextCheckingResult* result = [NSTextCheckingResult textCheckingResultWithRanges:capturedRanges andCount:captureCount];
        [array addObject:result];
    }];
    return array;
}

- (NSUInteger)numberOfMatchesInString:(NSString*)string options:(NSMatchingOptions)options range:(NSRange)range {
    RKLRegexOptions rkl_options = ConvertOptions(_p_options);
    __block NSUInteger count = 0;
    [string enumerateStringsMatchedByRegex:_p_pattern options:rkl_options inRange:range error:nil enumerationOptions:RKLRegexEnumerationCapturedStringsNotRequired usingBlock:^(NSInteger captureCount, NSString* const __unsafe_unretained* capturedStrings, const NSRange* capturedRanges, volatile BOOL* const stop) {
        ++count;
    }];
    return count;
}

- (NSTextCheckingResult*)firstMatchInString:(NSString*)string options:(NSMatchingOptions)options range:(NSRange)range {
    RKLRegexOptions rkl_options = ConvertOptions(_p_options);
    __block NSTextCheckingResult* result = nil;
    [string enumerateStringsMatchedByRegex:_p_pattern options:rkl_options inRange:range error:nil enumerationOptions:RKLRegexEnumerationCapturedStringsNotRequired usingBlock:^(NSInteger captureCount, NSString* const __unsafe_unretained* capturedStrings, const NSRange* capturedRanges, volatile BOOL* const stop) {
        result = [NSTextCheckingResult textCheckingResultWithRanges:capturedRanges andCount:captureCount];
        *stop = YES;
    }];
    return result;
}

- (NSRange)rangeOfFirstMatchInString:(NSString*)string options:(NSMatchingOptions)options range:(NSRange)range {
    RKLRegexOptions rkl_options = ConvertOptions(_p_options);
    NSRange resultRange = [string rangeOfRegex:_p_pattern options:rkl_options inRange:range capture:0 error:nil];
    return resultRange;
}

@end // RKL_NSRegularExpression (RKL_NSMatching)

@implementation RKL_NSRegularExpression (RKL_NSReplacement)

/* NSRegularExpression also provides find-and-replace methods for both immutable and mutable strings.  The replacement is treated as a template, with $0 being replaced by the contents of the matched range, $1 by the contents of the first capture group, and so on.  Additional digits beyond the maximum required to represent the number of capture groups will be treated as ordinary characters, as will a $ not followed by digits.  Backslash will escape both $ and itself.
 */
- (NSString*)stringByReplacingMatchesInString:(NSString *)string options:(NSMatchingOptions)options range:(NSRange)range withTemplate:(NSString *)templ{
    RKLRegexOptions rkl_options = ConvertOptions(_p_options);
    return [string stringByReplacingOccurrencesOfRegex:_p_pattern withString:templ options:rkl_options range:range error:nil];
}

- (NSUInteger)replaceMatchesInString:(NSMutableString *)string options:(NSMatchingOptions)options range:(NSRange)range withTemplate:(NSString *)templ{
    NSUInteger matches = [self numberOfMatchesInString:string options:0 range:range];
    NSString* replacement = [self stringByReplacingMatchesInString:string options:0 range:range withTemplate:templ];
    [string setString:replacement];
    return matches;
}

/* For clients implementing their own replace functionality, this is a method to perform the template substitution for a single result, given the string from which the result was matched, an offset to be added to the location of the result in the string (for example, in case modifications to the string moved the result since it was matched), and a replacement template.
 */
- (NSString*)replacementStringForResult:(NSTextCheckingResult*)result inString:(NSString*)string offset:(NSInteger)offset template:(NSString*)templ {
    // start with empty string
    NSMutableString* mutable = [NSMutableString new];
    NSUInteger count = [result numberOfRanges];
    // walk through the template looking for things to replace...
    NSUInteger length = [templ length];
    NSUInteger anchor = 0, i = 0;
    while (i < length) {
        if ([templ characterAtIndex:i] == '\\' && i+1 < length) {
            // collect from anchor to here
            if (i > anchor)
                [mutable appendString:[templ substringWithRange:NSMakeRange(anchor, i-anchor)]];
            // acts like escape for next character
            [mutable appendString:[templ substringWithRange:NSMakeRange(i+1, 1)]];
            i = anchor = i+2;
            continue;
        }
        else if ([templ characterAtIndex:i] == '$' && i+1 < length) {
            // characters following $ are decimal index into result (captures)
            NSUInteger begin = i++;
            char digit;
            // a $ followed by non-digit is just a $
            if (!((digit = [templ characterAtIndex:i]) >= '0' && digit < '9'))
                continue;
            NSUInteger idx = 0;
            while (i < length && (digit = [templ characterAtIndex:i]) >= '0' && digit < '9') {
                NSUInteger new_idx = idx * 10 + digit - '0';
                if (new_idx >= count) {
                    // extra characters outside the range of captures should be treated as
                    // regular characters in the stream.
                    break;
                }
                idx = new_idx;
                ++i;
            }
            if (idx < count) {
                if (begin > anchor)
                    [mutable appendString:[templ substringWithRange:NSMakeRange(anchor, begin-anchor)]];
                NSRange range = [result rangeAtIndex:idx];
                range.location += offset;
                [mutable appendString:[string substringWithRange:range]];
                anchor = i;
            }
            continue;
        }
        ++i;
    }
    // collect from anchor to end
    if (length > anchor)
        [mutable appendString:[templ substringWithRange:NSMakeRange(anchor, length-anchor)]];
    return mutable;
}

/* This class method will produce a string by adding backslash escapes as necessary to the given string, to escape any characters that would otherwise be treated as template metacharacters.
 */
+ (NSString *)escapedTemplateForString:(NSString *)string {
    // start with empty string
    NSMutableString* mutable = [NSMutableString new];
    // walk through the template looking for things to escape...
    NSUInteger length = [string length];
    NSUInteger anchor = 0, i = 0;
    while (i < length) {
        if ([string characterAtIndex:i] == '$') {
            if (i > anchor)
                [mutable appendString:[string substringWithRange:NSMakeRange(anchor, i-anchor)]];
            [mutable appendString:@"\\$"];
            anchor = ++i;
            continue;
        }
        ++i;
    }
    // collect from anchor to end
    if (length > anchor)
        [mutable appendString:[string substringWithRange:NSMakeRange(anchor, length-anchor)]];
    return mutable;
}

@end // RKL_NSRegularExpression (RKL_NSReplacement)

@implementation RKL_NSTextCheckingResult

- (NSRange)range { return [self rangeAtIndex:0]; }

- (id)init {
    self = [super init];
    if (self) {
        self->_p_ranges = NULL;
        self->_p_count = 0;
    }
    return self;
}

- (void)dealloc {
    if (self->_p_ranges) {
        free(self->_p_ranges);
        _p_ranges = NULL;
    }
    _p_count = 0;
#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}

+ (RKL_NSTextCheckingResult*)textCheckingResultWithRanges:(const NSRange*)ranges andCount:(NSUInteger)count {
    NSRange* copy = malloc(sizeof(NSRange) * count);
    if (!copy) return nil;
    RKL_NSTextCheckingResult* result = [RKL_NSTextCheckingResult new];
    if (!result) {
        free(copy);
        return nil;
    }
    memcpy(copy, ranges, sizeof(NSRange) * count);
    result->_p_ranges = copy;
    result->_p_count = count;
#if !__has_feature(objc_arc)
    [result autorelease];
#endif
    return result;
}

@end // RKL_NSTextCheckingResult

@implementation RKL_NSTextCheckingResult (RKL_NSTextCheckingResultOptional)

/* A result must have at least one range, but may optionally have more (for example, to represent regular expression capture groups).  The range at index 0 always matches the range property.  Additional ranges, if any, will have indexes from 1 to numberOfRanges-1. */
////@synthesize numberOfRanges=_p_count;
- (NSUInteger)numberOfRanges { return _p_count; }

- (NSRange)rangeAtIndex:(NSUInteger)idx {
    if (idx < _p_count)
        return _p_ranges[idx];
    else
        return NSMakeRange(NSNotFound, NSNotFound);
}

@end // RKL_NSTextCheckingResult (RKL_NSTextCheckingResultOptional)
