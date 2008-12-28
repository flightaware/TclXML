# tcldomutils.tcl --
#
# This script prepares the testing environment for TclXML.
#
# Copyright (c) 2008 Explain
# http://www.explain.com.au/
# Copyright (c) 2003 Zveno Pty Ltd.
#
# $Id: tclxmlutils.tcl,v 1.2 2003/12/03 20:06:37 balls Exp $

package require tcltest

source [file join [tcltest::workingDirectory] .. testutils.tcl]

eval tcltest::configure $argv

if {[catch {package require dom::libxml2}]} {
    tcltest::testConstraint dom_tcl 1
} else {
    tcltest::testConstraint dom_libxml2 1
}
