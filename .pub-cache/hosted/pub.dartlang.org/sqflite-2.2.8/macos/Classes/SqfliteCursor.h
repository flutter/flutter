//
//  SqfliteCursor.h
//  sqflite
//
//  Created by Alexandre Roux on 24/10/2022.
//
#ifndef SqfliteCursor_h
#define SqfliteCursor_h

// Cursor information
@class FMResultSet;
@interface SqfliteCursor : NSObject

@property (atomic, retain) NSNumber* cursorId;
@property (atomic, retain) NSNumber* pageSize;
@property (atomic, retain) FMResultSet *resultSet;

@end

#endif // SqfliteCursor_h
