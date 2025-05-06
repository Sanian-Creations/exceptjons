#include "Windows.h"

typedef void Context;
typedef void Data;
typedef DWORD Exception_Code;
typedef DWORD Exception_Resolution;
typedef void (*Try_Proc)(Context*, Data*);
typedef void (*Handler_Proc)(Context*, Data*, Exception_Code);
typedef Exception_Resolution (*Exception_Filter)(Context*, Data*, Exception_Code);

typedef struct { // []Exception_Code
    INT64 count;
    Exception_Code *data;
} Exception_Code_List;

static BOOL filter_list(DWORD code, Exception_Code_List filter) {
    for (INT64 i = 0; i < filter.count; i++) if (code == filter.data[i]) return TRUE;
    return FALSE;
}

Exception_Code jai_catch_try_except(
    Context              *ctx,
    Exception_Code_List  filter,
    Data                 *data,
    Try_Proc             try_proc,
    Handler_Proc         catch_proc,
    Handler_Proc         finally_proc
) {
    Exception_Code exception = 0;
    __try {
        __try {
	       try_proc(ctx, data);
        } __except(filter_list(exception = GetExceptionCode(), filter) ? EXCEPTION_EXECUTE_HANDLER : EXCEPTION_CONTINUE_SEARCH) {
            if (catch_proc) catch_proc(ctx, data, exception);
        }
    } __finally {
        if (finally_proc) finally_proc(ctx, data, exception);
    }
    return exception;
}

Exception_Code jai_catch_try_except_filter(
    Context          *ctx,
    Exception_Filter filter,
    Data             *data,
    Try_Proc         try_proc,
    Handler_Proc     catch_proc,
    Handler_Proc     finally_proc
) {
    Exception_Code exception = 0;
    __try {
        __try {
        	try_proc(ctx, data);
        } __except ( filter(ctx, data, exception = GetExceptionCode()) ) {
            if (catch_proc) catch_proc(ctx, data, exception);
        }
    } __finally {
        if (finally_proc) finally_proc(ctx, data, exception);
    }
    return exception;
}

/*
more on exception syntax and intrinsics like GetExceptionCode, GetExceptionInformation, AbnormalTermination:
https://learn.microsoft.com/en-us/cpp/cpp/try-except-statement?view=msvc-170
*/
