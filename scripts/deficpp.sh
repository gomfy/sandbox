#!/bin/bash

CPPFILES="ampltab.c blockput.c call.c clearq.c cmd.c collect.c compile.c cpexpr.c crunch.c crypt0.c deriv.c decoding.c display.c dist.c dotnames.c expand.c expr.c func.c genmod.c init.c let.c lib.c libC.c main.c mach.c massage.c mem.c misc.c nextfile.c opgen.c ops.c option.c outmps.c output.c parse.c pllin.c presolve.c print.c problem.c qsort.c qsortv.c randadd.c rawioadd.c read.c readcmd.c regexp.c setops.c sets.c show.c solve.c solveout.c symtab.c tables.c time.c utflen.c vops.c yytok.c cd_nt.c misc/run_nt.c misc/shell_nt.c"

HFILES="ac.h CCfix.h cmd.h crypt.h display.h errors.h externs.h fileinfo.h funcadd.h func.h genmod.h lp.h mach.h massage.h Math1.h nancheck.h pipefunc.h presolve.h random.h misc/run_nt.h setjmp1.h stdio1.h token.h"

grep -E "$1" $CPPFILES $HFILES | grep -v "extern" | grep -vE "(if|else|return|fprintf)"
