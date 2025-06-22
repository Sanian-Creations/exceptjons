// TODO: rather than using a static c library with callback functions I think it should be possible to figure out what the machine instructions are and use inline assembly to achieve the try-catch behaviour. But maybe that is more complex than I am giving it credit for, idk.

jai_catch :: (
    filter:    ..Exception_Code,
    data:      *$T,
    $$try:     (*T)->(),
    $$catch:   (*T, Exception_Code)->() = null,
    $$finally: (*T, Exception_Code)->() = null
) -> Exception_Code
#expand /* expand to not generate proc for each overload */ {

    #if is_constant(try) && is_constant(catch) && is_constant(finally) {

        #assert try != null;
        try_proc :: (ctx: *#Context, data: *void) #c_call {
            push_context ctx { try(data); }
        }

        catch_proc :: #ifx !catch then null
        else (ctx: *#Context, data: *void, ex: Exception_Code) #c_call {
            push_context ctx { catch(data, ex); }
        }

        finally_proc :: #ifx !finally then null
        else (ctx: *#Context, data: *void, ex: Exception_Code) #c_call {
            push_context ctx { finally(data, ex); }
        }

        return jai_catch_try_except(*context, filter, data,
            try_proc, catch_proc, finally_proc);

    } else {

        if !try return 0;

        wrapper_data := Wrapper.{
            data    = data,
            try     = xx try,
            catch   = xx catch,
            finally = xx finally,
        };

        return jai_catch_try_except(*context, filter, *wrapper_data,
            wrapper_try_proc,
            ifx catch   then wrapper_catch_proc,
            ifx finally then wrapper_finally_proc);
    }
}

jai_catch :: (
    $$filter:  (*T, Exception_Code) -> Exception_Resolution,
    data:      *$T,
    $$try:     (*T)->(),
    $$catch:   (*T, Exception_Code)->() = null,
    $$finally: (*T, Exception_Code)->() = null
) -> Exception_Code
#expand /* expand to not generate proc for each overload */ {

    #if is_constant(try) && is_constant(catch) &&
        is_constant(finally) && is_constant(filter)
    {
        try_proc :: (ctx: *#Context, data: *void) #c_call {
            push_context ctx { try(data); }
        }

        filter_proc :: (ctx: *#Context, data: *void, ex: Exception_Code)
        -> Exception_Resolution #c_call {
            push_context ctx { return filter(data, ex); }
        }

        catch_proc :: #ifx !catch then null
        else (ctx: *#Context, data: *void, ex: Exception_Code) #c_call {
            push_context ctx { catch(data, ex); }
        }

        finally_proc :: #ifx !finally then null
        else (ctx: *#Context, data: *void, ex: Exception_Code) #c_call {
            push_context ctx { finally(data, ex); }
        }

        return jai_catch_try_except_filter(*context, filter_proc, data,
            try_proc, catch_proc, finally_proc);
    } else {

        if !try return 0;

        wrapper_data := Wrapper.{
            data    = data,
            try     = xx try,
            catch   = xx catch,
            finally = xx finally,
            filter  = xx filter,
        };

        return jai_catch_try_except_filter(*context,
            wrapper_filter_proc,
            *wrapper_data,
            wrapper_try_proc,
            ifx catch   then wrapper_catch_proc,
            ifx finally then wrapper_finally_proc);
    }
}

Exception_Code :: enum u32 {
    // https://learn.microsoft.com/en-us/windows/win32/debug/getexceptioncode
    ACCESS_VIOLATION ::          0xc0000005; // read/write forbidden memory
    ARRAY_BOUNDS_EXCEEDED ::     0xc000008c; // (!) Only for hardware-supported bounds checking. Jai bounds check triggers BREAKPOINT, not this.
    BREAKPOINT ::                0x80000003; // array bounds check, asserts,
    DATATYPE_MISALIGNMENT ::     0x80000002; // misaligned read/write
    FLT_DENORMAL_OPERAND ::      0xc000008d;
    FLT_DIVIDE_BY_ZERO ::        0xc000008e; // float div-by-0 normally results in Inf. idk how this could get thrown.
    FLT_INEXACT_RESULT ::        0xc000008f;
    FLT_INVALID_OPERATION ::     0xc0000090;
    FLT_OVERFLOW ::              0xc0000091;
    FLT_STACK_CHECK ::           0xc0000092;
    FLT_UNDERFLOW ::             0xc0000093;
    GUARD_PAGE ::                0x80000001;
    ILLEGAL_INSTRUCTION ::       0xc000001d;
    IN_PAGE_ERROR ::             0xc0000006;
    INT_DIVIDE_BY_ZERO ::        0xc0000094;
    INT_OVERFLOW ::              0xc0000095;
    INVALID_DISPOSITION ::       0xc0000026;
    INVALID_HANDLE ::            0xc0000008;
    NONCONTINUABLE_EXCEPTION ::  0xc0000025;
    PRIV_INSTRUCTION ::          0xc0000096;
    SINGLE_STEP ::               0x80000004;
    STACK_OVERFLOW ::            0xc00000fd;
    STATUS_UNWIND_CONSOLIDATE :: 0x80000029;
}

Exception_Resolution :: enum s32 {
    DO_HANDLE ::   1; // EXCEPTION_EXECUTE_HANDLER
    DONT_HANDLE :: 0; // EXCEPTION_CONTINUE_SEARCH
    CONTINUE ::   -1; // EXCEPTION_CONTINUE_EXECUTION
    // CONTINUE goes right back to the instruction that caused the exception, and just executes it again.
    // To stop infinite looping you have to change something to ensure that the instruction does not trigger an exception again.
    // Personally I don't quite understand it.
    // see: https://stackoverflow.com/questions/42590408/configuring-floating-point-unit-context-in-win32-vs-win64/42612909#42612909
}

#scope_file

// These wrappers are for when you pass a procedure pointer,
Wrapper :: struct {
    data:    *void;
    try:     (*void)->();
    catch:   (*void, Exception_Code)->();
    finally: (*void, Exception_Code)->();
    filter:  (*void, Exception_Code)->Exception_Resolution;
}

wrapper_try_proc :: (ctx: *#Context, data: *void) #c_call {
    push_context ctx {
        data.(*Wrapper).try(data.(*Wrapper).data);
    }
}
wrapper_catch_proc :: (ctx: *#Context, data: *void, ex: Exception_Code) #c_call {
    push_context ctx {
        data.(*Wrapper).catch(data.(*Wrapper).data, ex);
    }
}
wrapper_finally_proc :: (ctx: *#Context, data: *void, ex: Exception_Code) #c_call {
    push_context ctx {
        data.(*Wrapper).finally(data.(*Wrapper).data, ex);
    }
}
wrapper_filter_proc :: (ctx: *#Context, data: *void, ex: Exception_Code)
-> Exception_Resolution #c_call {
    push_context ctx {
        return data.(*Wrapper).filter(data.(*Wrapper).data, ex);
    }
}

Try_Proc ::     #type (*#Context, *void)                 #c_call;
Handler_Proc :: #type (*#Context, *void, Exception_Code) #c_call;
Filter_Proc ::  #type (*#Context, *void, Exception_Code) -> Exception_Resolution #c_call;

jai_catch_try_except :: (
    ctx:     *#Context,
    filter:  []Exception_Code,
    data:    *void,
    try:     Try_Proc,
    catch:   Handler_Proc,
    finally: Handler_Proc
) -> Exception_Code #foreign lib_jai_catch;

jai_catch_try_except_filter :: (
    ctx:     *#Context,
    filter:  Filter_Proc,
    data:    *void,
    try:     Try_Proc,
    catch:   Handler_Proc,
    finally: Handler_Proc
) -> Exception_Code #foreign lib_jai_catch;

lib_jai_catch :: #library,no_dll "lib/jai_catch_windows";
