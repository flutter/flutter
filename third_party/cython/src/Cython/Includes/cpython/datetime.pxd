from cpython.ref cimport PyObject

cdef extern from "Python.h":
    ctypedef struct PyTypeObject:
        pass

cdef extern from "datetime.h":
    
    ctypedef extern class datetime.date[object PyDateTime_Date]:
        pass

    ctypedef extern class datetime.time[object PyDateTime_Time]:
        pass

    ctypedef extern class datetime.datetime[object PyDateTime_DateTime]:
        pass

    ctypedef extern class datetime.timedelta[object PyDateTime_Delta]:
        pass

    ctypedef extern class datetime.tzinfo[object PyDateTime_TZInfo]:
        pass

    ctypedef struct PyDateTime_Date:
        pass
    
    ctypedef struct PyDateTime_Time:
        char hastzinfo
        PyObject *tzinfo
        
    ctypedef struct PyDateTime_DateTime:
        char hastzinfo
        PyObject *tzinfo

    ctypedef struct PyDateTime_Delta:
        int days
        int seconds
        int microseconds
        
    # Define structure for C API.
    ctypedef struct PyDateTime_CAPI:
        # type objects 
        PyTypeObject *DateType
        PyTypeObject *DateTimeType
        PyTypeObject *TimeType
        PyTypeObject *DeltaType
        PyTypeObject *TZInfoType
    
        # constructors
        object (*Date_FromDate)(int, int, int, PyTypeObject*)
        object (*DateTime_FromDateAndTime)(int, int, int, int, int, int, int, object, PyTypeObject*)
        object (*Time_FromTime)(int, int, int, int, object, PyTypeObject*)
        object (*Delta_FromDelta)(int, int, int, int, PyTypeObject*)
    
        # constructors for the DB API
        object (*DateTime_FromTimestamp)(object, object, object)
        object (*Date_FromTimestamp)(object, object)

    # Check type of the object.
    bint PyDate_Check(object op)
    bint PyDate_CheckExact(object op)

    bint PyDateTime_Check(object op)
    bint PyDateTime_CheckExact(object op)

    bint PyTime_Check(object op)
    bint PyTime_CheckExact(object op)

    bint PyDelta_Check(object op)
    bint PyDelta_CheckExact(object op)

    bint PyTZInfo_Check(object op)
    bint PyTZInfo_CheckExact(object op)

    # Getters for date and datetime (C macros).
    int PyDateTime_GET_YEAR(object o)
    int PyDateTime_GET_MONTH(object o)
    int PyDateTime_GET_DAY(object o)

    # Getters for datetime (C macros).
    int PyDateTime_DATE_GET_HOUR(object o)
    int PyDateTime_DATE_GET_MINUTE(object o)
    int PyDateTime_DATE_GET_SECOND(object o)
    int PyDateTime_DATE_GET_MICROSECOND(object o)

    # Getters for time (C macros).
    int PyDateTime_TIME_GET_HOUR(object o)
    int PyDateTime_TIME_GET_MINUTE(object o)
    int PyDateTime_TIME_GET_SECOND(object o)
    int PyDateTime_TIME_GET_MICROSECOND(object o)

    # Getters for timedelta (C macros).
    #int PyDateTime_DELTA_GET_DAYS(object o)
    #int PyDateTime_DELTA_GET_SECONDS(object o)
    #int PyDateTime_DELTA_GET_MICROSECONDS(object o)

    # PyDateTime CAPI object.
    PyDateTime_CAPI *PyDateTimeAPI
    
    void PyDateTime_IMPORT()

# Datetime C API initialization function.
# You have to call it before any usage of DateTime CAPI functions.
cdef inline void import_datetime():
    PyDateTime_IMPORT

# Create date object using DateTime CAPI factory function.
# Note, there are no range checks for any of the arguments.
cdef inline object date_new(int year, int month, int day):
    return PyDateTimeAPI.Date_FromDate(year, month, day, PyDateTimeAPI.DateType)
    
# Create time object using DateTime CAPI factory function
# Note, there are no range checks for any of the arguments.
cdef inline object time_new(int hour, int minute, int second, int microsecond, object tz):
    return PyDateTimeAPI.Time_FromTime(hour, minute, second, microsecond, tz, PyDateTimeAPI.TimeType)

# Create datetime object using DateTime CAPI factory function.
# Note, there are no range checks for any of the arguments.
cdef inline object datetime_new(int year, int month, int day, int hour, int minute, int second, int microsecond, object tz):
    return PyDateTimeAPI.DateTime_FromDateAndTime(year, month, day, hour, minute, second, microsecond, tz, PyDateTimeAPI.DateTimeType)

# Create timedelta object using DateTime CAPI factory function.
# Note, there are no range checks for any of the arguments.
cdef inline object timedelta_new(int days, int seconds, int useconds):
    return PyDateTimeAPI.Delta_FromDelta(days, seconds, useconds, 1, PyDateTimeAPI.DeltaType)

# More recognizable getters for date/time/datetime/timedelta.
# There are no setters because datetime.h hasn't them.
# This is because of immutable nature of these objects by design.
# If you would change time/date/datetime/timedelta object you need to recreate. 

# Get tzinfo of time
cdef inline object time_tzinfo(object o):
    if (<PyDateTime_Time*>o).hastzinfo:
        return <object>(<PyDateTime_Time*>o).tzinfo
    else:
        return None

# Get tzinfo of datetime 
cdef inline object datetime_tzinfo(object o):
    if (<PyDateTime_DateTime*>o).hastzinfo:
        return <object>(<PyDateTime_DateTime*>o).tzinfo
    else:
        return None

# Get year of date
cdef inline int date_year(object o):
    return PyDateTime_GET_YEAR(o)
    
# Get month of date
cdef inline int date_month(object o):
    return PyDateTime_GET_MONTH(o)

# Get day of date
cdef inline int date_day(object o):
    return PyDateTime_GET_DAY(o)

# Get year of datetime
cdef inline int datetime_year(object o):
    return PyDateTime_GET_YEAR(o)
    
# Get month of datetime
cdef inline int datetime_month(object o):
    return PyDateTime_GET_MONTH(o)

# Get day of datetime
cdef inline int datetime_day(object o):
    return PyDateTime_GET_DAY(o)

# Get hour of time
cdef inline int time_hour(object o):
    return PyDateTime_TIME_GET_HOUR(o)

# Get minute of time
cdef inline int time_minute(object o):
    return PyDateTime_TIME_GET_MINUTE(o)

# Get second of time
cdef inline int time_second(object o):
    return PyDateTime_TIME_GET_SECOND(o)

# Get microsecond of time
cdef inline int time_microsecond(object o):
    return PyDateTime_TIME_GET_MICROSECOND(o)

# Get hour of datetime
cdef inline int datetime_hour(object o):
    return PyDateTime_DATE_GET_HOUR(o)

# Get minute of datetime
cdef inline int datetime_minute(object o):
    return PyDateTime_DATE_GET_MINUTE(o)

# Get second of datetime
cdef inline int datetime_second(object o):
    return PyDateTime_DATE_GET_SECOND(o)

# Get microsecond of datetime
cdef inline int datetime_microsecond(object o):
    return PyDateTime_DATE_GET_MICROSECOND(o)

# Get days of timedelta
cdef inline int timedelta_days(object o):
    return (<PyDateTime_Delta*>o).days

# Get seconds of timedelta
cdef inline int timedelta_seconds(object o):
    return (<PyDateTime_Delta*>o).seconds

# Get microseconds of timedelta
cdef inline int timedelta_microseconds(object o):
    return (<PyDateTime_Delta*>o).microseconds
