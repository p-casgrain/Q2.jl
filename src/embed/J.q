@[`.J;`init`eval_string`J_atexit_hook;:;(`:J 2:(`qjl;1))`.J[`init]:0b];
\d .J

if[(not `isinit in key `.J);.J.isinit:0b];
if[not .J.isinit;.J.init[`];.J.isinit:1b]
setenv[`IS_EMBEDDED_Q;"true"]

/ push!(LOAD_PATH,"/Users/philippecasgrain/Github/Q2.jl/")
repl:{[].J.eval_string "Base._start()"};


/ eval_simple "Q2.__init__()";

u_.makeWrapFunc:{[f]
    callerfunc:{[f;params] f . params}f;
    '[callerfunc;enlist]
    };

wrapfn:{[fn_name]
    / wraps a julia function into a KDB function taking arbitrary number of args
    if[not type[fn_name]~-11h;'type];
    :.J.u_.makeWrapFunc e"Q2._wrap_function(",string[fn_name],",",string[floor nargs],")"
    };


\d .

.J.eval_string "push!(LOAD_PATH,\"/Users/philippecasgrain/Github/Q2.jl/\")";