
/ `EMBEDJL_RUN_CMD setenv "push!(LOAD_PATH,\"$(ENV[\"HOME\"])/Github/KdbConnect.jl/\");";
\d .J
/ dynamic load functions
u_:(`:J 2:(`qjl;1))`;
/ check if simple or non-simple startup required
jl_cmdargs:" " vs neg[1]_ getenv`EMBEDJL_CMD_ARGS; / julia command line args (as one big string)
jl_initcmd:neg[1]_ getenv`EMBEDJL_RUN_CMD;
/ use_simple_init:all[""~/:(jl_cmdargs;jl_binloc)];
use_simple_init:""~jl_cmdargs;
init:$[use_simple_init;{.J.u_.init_simple[`]};{.J.u_.init[.J.jl_cmdargs;""]}];
atexit:u_`atexit;
e_:u_`eval_simple;
if[(not `isinit in key `.J);.J.isinit:0b];
if[not .J.isinit;.J.init[];.J.isinit:1b];
setenv[`IS_EMBEDDED_Q;"true"]
/ REPL function
repl:{[].J.e_ "Base._start()"};
/ load KdbConnect
if[count jl_initcmd;e_ jl_initcmd,"; true"];
.J.KdbConnect_isinstalled:e_ "try\n using KdbConnect;import KdbConnect;using KdbConnect.K_lib;true\n catch err\n show(err); false\n end";
$[.J.KdbConnect_isinstalled;[
    / setup wrapper function
    u_.fixenlist:{[x]:$[x~enlist[];enlist[::];(::),x]};
    wrapfn:{[fn_str]if[type[fn_str]<>10h;'type];('[;]) over (u_.J_fn_wrap[fn_str;];u_.fixenlist;enlist)};
 ];[
    1 "warn: package KdbConnect is not installed in julia session. .J functionality severely limited.";
    1 "tip : Use .J.repl[] to inspect session (ctrl+D to exit back to q session.)\n";
 ]];
\d .
