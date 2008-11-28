# tclxmlutils.tcl --
#
# This script prepares the testing environment for TclXML.
#
# Copyright (c) 2008 Explain
# http://www.explain.com.au/
# Copyright (c) 2003 Zveno Pty Ltd.
#
# $Id: tclxmlutils.tcl,v 1.2 2003/12/03 20:06:37 balls Exp $

package require tcltest
tcltest::Option -parser xml {
    Selects the XML parser class.
} AcceptAll parser

source [file join [tcltest::workingDirectory] .. testutils.tcl]

eval tcltest::configure $argv

switch -- $tcltest::parser {
    xml {
	package require xml
	switch [xml::parserclass info default] {
	    libxml2 {
		tcltest::testConstraint xml_libxml2 1
	    }
	    tcl {
		tcltest::testConstraint xml_tcl 1
	    }
	}
    }
    libxml2 {
	tcltest::testConstraint xml_libxml2 1
    }
    tclparser {
	tcltest::testConstraint xml_tcl 1
    }
}
