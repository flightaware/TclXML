# all.tcl --
#
# This file contains a support module to run all of the Tcl
# tests.  It must be invoked using "source all.test" by 
# a calling tcl script that has loaded the parser class it wishes to
# test in this directory.
#
# Copyright (c) 2008 Explain
# http://www.explain.com.au/
# Copyright (c) 2003 Zveno Pty Ltd
# Copyright (c) 1998-1999 by Scriptics Corporation.
#
# All rights reserved.
# 
# RCS: @(#) $Id: all.tcl,v 1.4 2003/12/03 20:06:36 balls Exp $

switch -glob -- [info tclversion] {
    "8*" { set REQUIRED 8.4 }
    "9*" { set REQUIRED 9.0 }
}

package require Tcl $REQUIRED
package require tcltest 2.2
tcltest::configure -testdir [file dirname [file normalize [info script]]] -debug 3
eval tcltest::configure $argv

tcltest::runAllTests
