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

package require Tcl 8.4
package require tcltest 2.2
tcltest::Option -parser xml {
    Selects the XML parser class.
} AcceptAll parser
tcltest::configure -testdir [file dirname [file normalize [info script]]]
eval tcltest::configure $argv

if {$::tcltest::parser == "xml"} {
    foreach parser {libxml2 tclparser} {
	puts "\nTesting parser class \"$parser\"\n"
	tcltest::configure -parser $parser
	tcltest::runAllTests
    }
} else {
    tcltest::runAllTests
}
