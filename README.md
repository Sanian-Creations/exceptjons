# Exceptjons
Very basic support for catching hardware exceptions in jai using Structured Exception Handling on Windows.

> [!important]
> This project needs to build a static library before it works, keep reading.
>
> You can choose to use a batch file or CMake.

# Dir content

### `build_lib_windows.bat`
Batch file that can be used to build the static library needed for this module to work. It uses some hardcoded file paths that may or may not be present on your pc, but the script includes some additional error messages to help you fix it, and manually updating them should not be too hard. Still, this may require a bit of tinkering to get working.

### `CMakeLists.txt`
Generic way to build the library using CMake. It is more reliable than the batch file since it requires NO tinkering, but not as lightweight/fast, and CMake is not everyone's cup of tea.

The commands you need to run to build the static library are `cmake -B build -G "Visual Studio 16 2019"` and `cmake --build build --config Release`. Despite what it looks like this does not require you to have VS2019 installed, just vsbuildtools should work.

### `jai_catch_windows.c`
The c file containing the source code of the required static library. Compile this to make the module work.

### `module.jai`
Module file. Will not work straight out of the box since the required library "jai_catch_windows.lib" needs to manually be built before this module is usable.

### `test.jai`
File containing some basic tests to ensure the module runs as it should. Not necessary for the module to function.


# Usage

```jai
// Using a struct makes it seem as if we are working with local variables.
// Since we need to pass a data pointer into our callbacks, this makes them more like clojures.
using local_vars: struct {
    a: int;
    b: int;
};

a = 5;
b = 0;

ex := jai_catch(
    // Which exceptions to capture
    .ACCESS_VIOLATION, .INT_DIVIDE_BY_ZERO, .INT_OVERFLOW, .BREAKPOINT,
    data = *local_vars,
    try = (data) => {
        using data;
        print("Dividing a (%) and b (%)...\n", a, b);
        c := a / b;
        print("The result is %!\n", c); // Not reached.
    },
    catch = (data, ex) => {
        print("Caught a big one! It's %!\n", ex);
    },
    finally = (data, ex) => {
        print("This always runs, even if an exception passes that is not caught.\n");
    }
);
```
```
Dividing a (5) and b (0)...
Caught a big one! It's INT_DIVIDE_BY_ZERO!
This always runs, even if an exception passes that is not caught.
```
