//
//  SqfliteFmdbImport.m
//  Shared import for FMDB
//
// Not a header file as XCode might complain.
//
//  Created by Alexandre Roux on 03/12/2022.
//
#ifndef SqfliteFmdbImport_m
#define SqfliteFmdbImport_m

#if __has_include(<fmdb/FMDB.h>)
#import <fmdb/FMDB.h>
#else
@import FMDB;
#endif

#endif /* SqfliteFmdbImport_m */
