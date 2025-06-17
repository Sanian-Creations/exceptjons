main :: () {
    test1();
    test2();
    print("Passed all tests.\n");
}

test1 :: () {
    using mydata: struct {
        a: int;
        b: int;
        did_catch: bool;
        did_finally: bool;
    };

    a = 5;
    b = 0;
    did_finally = false;

    ex := jai_catch(.ACCESS_VIOLATION, .INT_DIVIDE_BY_ZERO, .INT_OVERFLOW, .BREAKPOINT,
        data = *mydata,
        try = (data) => {
            using data;
            c := a / b;
        },
        catch = (data, ex) => {
            using data;
            data.did_catch = true;
            assert(ex == .INT_DIVIDE_BY_ZERO);
        },
        finally = (data, ex) => {
            using data;
            did_finally = true;
        }
    );

    assert(did_catch);
    assert(did_finally);
    assert(a == 5); // not corrupted
    assert(b == 0); // not corrupted
    print("[Test 1] Passed.\n");
}

test2 :: () {

    using mydata: struct {
        did_catch: bool;
        did_finally: bool;
    };

    // Rather than a static list of exceptions to catch, you can make it dynamic with a proc.
    filter_proc :: (data: *type_of(mydata), ex: Exception_Code) -> Exception_Resolution {
        caught := ex == .ACCESS_VIOLATION
            || ex == .INT_DIVIDE_BY_ZERO
            || ex == .INT_OVERFLOW
            || ex == .BREAKPOINT;
        return ifx caught then .DO_HANDLE else .DONT_HANDLE;
    }

    context.assertion_failed = (loc, msg) => true;

    ex2 := jai_catch(filter_proc,
        data = *mydata,
        try = (_) => {
            assert(false); // We are going to catch this assertion
        },
        catch = (data, ex) => {
            using data;
            data.did_catch = true;
            assert(ex == .BREAKPOINT); // assert runs debug_break(), so expect .BREAKPOINT
        },
        finally = (data, ex) => {
            using data;
            data.did_finally = true;
        }
    );

    assert(did_catch);
    assert(did_finally);
    print("[Test 2] Passed.\n");
}

#import "Basic";
#import,file "module.jai";
