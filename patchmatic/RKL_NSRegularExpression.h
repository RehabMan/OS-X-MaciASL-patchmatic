//
//  RKL_NSRegularExpression.h
//  MaciASL
//
//  Created by RehabMan on 4/2/13.
//  Copyright (c) 2013 RehabMan. All rights reserved.
//

#import <Foundation/Foundation.h>

// Map all references to NSRegularExpression to RKL_NSRegularExpression
#define NSRegularExpression RKL_NSRegularExpression
#define NSTextCheckingResult RKL_NSTextCheckingResult

@interface RKL_NSTextCheckingResult : NSObject {
@private
    NSRange* _p_ranges;
    NSUInteger _p_count;
};

+ (RKL_NSTextCheckingResult*)textCheckingResultWithRanges:(const NSRange*)ranges andCount:(NSUInteger)count;

/* Mandatory properties, used with all types of results. */
@property(readonly) NSRange range;

@end // RK_NSTextCheckingResult

@interface RKL_NSTextCheckingResult (RKL_NSTextCheckingResultOptional)

/* A result must have at least one range, but may optionally have more (for example, to represent regular expression capture groups).  The range at index 0 always matches the range property.  Additional ranges, if any, will have indexes from 1 to numberOfRanges-1. */
@property(readonly) NSUInteger numberOfRanges;
- (NSRange)rangeAtIndex:(NSUInteger)idx;

@end // RKL_NSTextCheckingResult (RKL_NSTextCheckingResultOptional)

// Note: unsupported options are not defined to force errors if used
enum {
    RKL_NSRegularExpressionCaseInsensitive             = 1 << 0,     /* Match letters in the pattern independent of case. */
    RKL_NSRegularExpressionAllowCommentsAndWhitespace  = 1 << 1,     /* Ignore whitespace and #-prefixed comments in the pattern. */
  //RKL_NSRegularExpressionIgnoreMetacharacters        = 1 << 2,     /* Treat the entire pattern as a literal string. */
    RKL_NSRegularExpressionDotMatchesLineSeparators    = 1 << 3,     /* Allow . to match any character, including line separators. */
    RKL_NSRegularExpressionAnchorsMatchLines           = 1 << 4,     /* Allow ^ and $ to match the start and end of lines. */
  //RKL_NSRegularExpressionUseUnixLineSeparators       = 1 << 5,     /* Treat only \n as a line separator (otherwise, all standard line separators are used). */
    RKL_NSRegularExpressionUseUnicodeWordBoundaries    = 1 << 6      /* Use Unicode TR#29 to specify word boundaries (otherwise, traditional regular expression word boundaries are used). */
};
typedef NSUInteger RKL_NSRegularExpressionOptions;

#define NSRegularExpressionOptions RKL_NSRegularExpressionOptions
#define NSRegularExpressionCaseInsensitive              RKL_NSRegularExpressionCaseInsensitive
#define NSRegularExpressionAllowCommentsAndWhitespace   RKL_NSRegularExpressionAllowCommentsAndWhitespace
#define NSRegularExpressionIgnoreMetacharacters         RKL_NSRegularExpressionIgnoreMetacharacters
#define NSRegularExpressionDotMatchesLineSeparators     RKL_NSRegularExpressionDotMatchesLineSeparators
#define NSRegularExpressionAnchorsMatchLines            RKL_NSRegularExpressionAnchorsMatchLines
#define NSRegularExpressionUseUnixLineSeparators        RKL_NSRegularExpressionUseUnixLineSeparators
#define NSRegularExpressionUseUnicodeWordBoundaries     RKL_NSRegularExpressionUseUnicodeWordBoundaries

@interface RKL_NSRegularExpression : NSObject {
@private
    NSString* _p_pattern;
    NSRegularExpressionOptions _p_options;
};

/* An instance of NSRegularExpression is created from a regular expression pattern and a set of options.  If the pattern is invalid, nil will be returned and an NSError will be returned by reference.  The pattern syntax currently supported is that specified by ICU.
 */
+ (NSRegularExpression*)regularExpressionWithPattern:(NSString *)pattern options:(NSRegularExpressionOptions)options error:(NSError**)error;
- (id)initWithPattern:(NSString*)pattern options:(NSRegularExpressionOptions)options error:(NSError**)error;

@property(readonly) NSString *pattern;
@property(readonly) NSRegularExpressionOptions options;
@property(readonly) NSUInteger numberOfCaptureGroups;

/* This class method will produce a string by adding backslash escapes as necessary to the given string, to escape any characters that would otherwise be treated as pattern metacharacters.
 */
//+ (NSString *)escapedPatternForString:(NSString *)string; //REVIEW_NOTIMPL

@end // RKL_NSRegularExpression

// Note: unsupported options are not defined to force errors if used
enum {
    RKL_NSMatchingOptionsNotImplemented,
  //RKL_NSMatchingReportProgress         = 1 << 0,       /* Call the block periodically during long-running match operations. */
  //RKL_NSMatchingReportCompletion       = 1 << 1,       /* Call the block once after the completion of any matching. */
  //RKL_NSMatchingAnchored               = 1 << 2,       /* Limit matches to those at the start of the search range. */
  //RKL_NSMatchingWithTransparentBounds  = 1 << 3,       /* Allow matching to look beyond the bounds of the search range. */
  //RKL_NSMatchingWithoutAnchoringBounds = 1 << 4        /* Prevent ^ and $ from automatically matching the beginning and end of the search range. */
};
typedef NSUInteger RKL_NSMatchingOptions;

#define NSMatchingOptions RKL_NSMatchingOptions
#define NSMatchingReportProgress            RKL_NSMatchingReportProgress
#define NSMatchingReportCompletion          RKL_NSMatchingReportCompletion
#define NSMatchingAnchored                  RKL_NSMatchingAnchored
#define NSMatchingWithTransparentBounds     RKL_NSMatchingWithTransparentBounds
#define NSMatchingWithoutAnchoringBounds    RKL_NSMatchingWithoutAnchoringBounds

// Note: unsupported options are not defined to force errors if used
enum {
    RKL_NSMatchingFlagsNotImplemented,
  //RKL_NSMatchingProgress               = 1 << 0,       /* Set when the block is called to report progress during a long-running match operation. */
  //RKL_NSMatchingCompleted              = 1 << 1,       /* Set when the block is called after completion of any matching. */
  //RKL_NSMatchingHitEnd                 = 1 << 2,       /* Set when the current match operation reached the end of the search range. */
  //RKL_NSMatchingRequiredEnd            = 1 << 3,       /* Set when the current match depended on the location of the end of the search range. */
  //RKL_NSMatchingInternalError          = 1 << 4        /* Set when matching failed due to an internal error. */
};
typedef NSUInteger RKL_NSMatchingFlags;

#define NSMatchingFlags RKL_NSMatchingFlags
#define NSMatchingProgress          RKL_NSMatchingProgress
#define NSMatchingCompleted         RKL_NSMatchingCompleted
#define NSMatchingHitEnd            RKL_NSMatchingHitEnd
#define NSMatchingRequiredEnd       RKL_NSMatchingRequiredEnd
#define NSMatchingInternalError     RKL_NSMatchingInternalError

@interface RKL_NSRegularExpression (RKL_NSMatching)

/* The fundamental matching method on NSRegularExpression is a block iterator.  There are several additional convenience methods, for returning all matches at once, the number of matches, the first match, or the range of the first match.  Each match is specified by an instance of NSTextCheckingResult (of type NSTextCheckingTypeRegularExpression) in which the overall match range is given by the range property (equivalent to rangeAtIndex:0) and any capture group ranges are given by rangeAtIndex: for indexes from 1 to numberOfCaptureGroups.  {NSNotFound, 0} is used if a particular capture group does not participate in the match.
 */

#if NS_BLOCKS_AVAILABLE
- (void)enumerateMatchesInString:(NSString *)string options:(NSMatchingOptions)options range:(NSRange)range usingBlock:(void (^)(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop))block;
#endif /* NS_BLOCKS_AVAILABLE */

- (NSArray *)matchesInString:(NSString *)string options:(NSMatchingOptions)options range:(NSRange)range;
- (NSUInteger)numberOfMatchesInString:(NSString *)string options:(NSMatchingOptions)options range:(NSRange)range;
- (NSTextCheckingResult *)firstMatchInString:(NSString *)string options:(NSMatchingOptions)options range:(NSRange)range;
- (NSRange)rangeOfFirstMatchInString:(NSString *)string options:(NSMatchingOptions)options range:(NSRange)range;

/* By default, the block iterator method calls the block precisely once for each match, with a non-nil result and appropriate flags.  The client may then stop the operation by setting the contents of stop to YES.  If the NSMatchingReportProgress option is specified, the block will also be called periodically during long-running match operations, with nil result and NSMatchingProgress set in the flags, at which point the client may again stop the operation by setting the contents of stop to YES.  If the NSMatchingReportCompletion option is specified, the block will be called once after matching is complete, with nil result and NSMatchingCompleted set in the flags, plus any additional relevant flags from among NSMatchingHitEnd, NSMatchingRequiredEnd, or NSMatchingInternalError.  NSMatchingReportProgress and NSMatchingReportCompletion have no effect for methods other than the block iterator.
 
 NSMatchingHitEnd is set in the flags passed to the block if the current match operation reached the end of the search range.  NSMatchingRequiredEnd is set in the flags passed to the block if the current match depended on the location of the end of the search range.  NSMatchingInternalError is set in the flags passed to the block if matching failed due to an internal error (such as an expression requiring exponential memory allocations) without examining the entire search range.
 
 NSMatchingAnchored, NSMatchingWithTransparentBounds, and NSMatchingWithoutAnchoringBounds can apply to any match or replace method.  If NSMatchingAnchored is specified, matches are limited to those at the start of the search range.  If NSMatchingWithTransparentBounds is specified, matching may examine parts of the string beyond the bounds of the search range, for purposes such as word boundary detection, lookahead, etc.  If NSMatchingWithoutAnchoringBounds is specified, ^ and $ will not automatically match the beginning and end of the search range (but will still match the beginning and end of the entire string).  NSMatchingWithTransparentBounds and NSMatchingWithoutAnchoringBounds have no effect if the search range covers the entire string.
 
 NSRegularExpression is designed to be immutable and threadsafe, so that a single instance can be used in matching operations on multiple threads at once.  However, the string on which it is operating should not be mutated during the course of a matching operation (whether from another thread or from within the block used in the iteration).
 */

@end // RKL_NSRegularExpression (RKL_NSMatching)


@interface RKL_NSRegularExpression (RKL_NSReplacement)

/* NSRegularExpression also provides find-and-replace methods for both immutable and mutable strings.  The replacement is treated as a template, with $0 being replaced by the contents of the matched range, $1 by the contents of the first capture group, and so on.  Additional digits beyond the maximum required to represent the number of capture groups will be treated as ordinary characters, as will a $ not followed by digits.  Backslash will escape both $ and itself.
 */
- (NSString *)stringByReplacingMatchesInString:(NSString *)string options:(NSMatchingOptions)options range:(NSRange)range withTemplate:(NSString *)templ;
- (NSUInteger)replaceMatchesInString:(NSMutableString *)string options:(NSMatchingOptions)options range:(NSRange)range withTemplate:(NSString *)templ;

/* For clients implementing their own replace functionality, this is a method to perform the template substitution for a single result, given the string from which the result was matched, an offset to be added to the location of the result in the string (for example, in case modifications to the string moved the result since it was matched), and a replacement template.
 */
- (NSString *)replacementStringForResult:(NSTextCheckingResult *)result inString:(NSString *)string offset:(NSInteger)offset template:(NSString *)templ;

/* This class method will produce a string by adding backslash escapes as necessary to the given string, to escape any characters that would otherwise be treated as template metacharacters.
 */
+ (NSString *)escapedTemplateForString:(NSString *)string;

@end // RKL_NSRegularExpression (RKL_NSReplacement)

