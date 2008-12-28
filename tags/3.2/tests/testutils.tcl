# testutils.tcl --
#
# 	Auxilliary utilities for use with the tcltest package.
# 	Author: Joe English <jenglish@flightlab.com>
# 	Version: 1.1
#
# This file is hereby placed in the public domain.
#
# $Id: testutils.tcl,v 1.3 2004/02/20 09:15:53 balls Exp $

variable tracing 0		;# Set to '1' to enable the 'trace' command
variable tracingErrors 0	;# If set, 'expectError' prints error messages

# ok --
#	Returns an empty string.
#	May be used as the last statement in test scripts 
#	that are only evaluated for side-effects or in cases
#	where you just want to make sure that an operation succeeds
#
proc ok {} { return {} }

# result result --
#	Just returns $result
#
proc result {result} { return $result }

# tracemsg msg --
#	Prints tracing message if $::tracing is nonzero.
#
proc tracemsg {string} {
    if {$::tracing} {
	puts $::tcltest::outputChannel $string
    }
}

# assert expr ?msg? --
#	Evaluates 'expr' and signals an error
#	if the condition is not true.
#
proc assert {expr {message ""}} {
    if {![uplevel 1 [list expr $expr]]} {
	return -code error "Assertion {$expr} failed:\n$message"
    }
}

# expectError script  ? pattern ? --
#	Evaluate 'script', which is expected to fail
#	with an error message matching 'pattern'.
#
#	Returns the error message if the script 'correctly' fails,
#	raises an error otherwise

proc expectError {script {pattern "*"}} {
    set rc [catch [list uplevel 1 $script] result]
    if {$::tracingErrors} {
	puts stderr "==> [string replace $result 70 end ...]"
    }
    set rmsg [string replace $result 40 end ...]
    if {$rc != 1} {
	return -code error \
	    "Expected error, got '$rmsg' (rc=$rc)"
    }
    return $result
}

# sortedarray --
#
#	Return the contents of an array, sorted by index

proc sortedarray arrName {
    upvar 1 $arrName thearray

    set result {}
    foreach idx [lsort [array names thearray]] {
	lappend result $idx $thearray($idx)
    }

    return $result
}

# compareNodes
#	Compares two nodes, taking implementations into account

proc compareNodes {node1 node2} {
    if {[::tcltest::testConstraint dom_libxml2] || [::tcltest::testConstraint dom_tcl]} {
	::dom::node isSameNode $node1 $node2
    } else {
	return [expr ![string compare $node1 $node2]]
    }
}

# compareNodeList list1 list2
#	Compares two lists of DOM nodes, in an ordered fashion.
#	NB. the node identities are compared, not their tokens.

proc compareNodeList {list1 list2} {
    if {[llength $list1] != [llength $list2]} {
	return 0
    }
    foreach node1 $list1 node2 $list2 {
	if {![compareNodes $node1 $node2]} {
	    return 0
	}
    }
    return 1
}

# compareNodeset set1 set2
#	Compares two sets of DOM nodes, in an unordered fashion.
#	NB. the node identities are compared, not their tokens.

proc compareNodeset {set1 set2} {
    if {[llength $set1] != [llength $set2]} {
	return 0
    }
    foreach node1 [lsort $set1] node2 [lsort $set2] {
	if {![compareNodes $node1 $node2]} {
	    return 0
	}
    }
    return 1
}

# checkTree doc list
#	Tests that a DOM tree has a structure specified as a Tcl list

proc checkTree {node spec {checktype 1}} {
    if {[dom::node cget $node -nodeType] == "document"} {
	if {$checktype} {
	    if {[lindex [lindex $spec 0] 0] == "doctype"} {
		set doctype [dom::document cget $node -doctype]
		if {[dom::node cget $doctype -nodeType] != "documentType"} {
		    return 0
		}
		if {[dom::documenttype cget $doctype -name] != [lindex [lindex $spec 0] 1]} {
		    return 0
		}
		# Should also check external identifiers and internal subset
		set spec [lrange $spec 1 end]
	    }
	}
    }
    foreach child [dom::node children $node] specchild $spec {
	switch [lindex $specchild 0] {
	    element {
		if {[dom::node cget $child -nodeType] != "element"} {
		    return 0
		}
		if {[dom::node cget $child -nodeName] != [lindex $specchild 1]} {
		    return 0
		}
		foreach {name value} [lindex $specchild 2] {
		    if {[dom::element getAttribute $child $name] != $value} {
			return 0
		    }
		}
		set result [checkTree $child [lindex $specchild 3]]
		if {!$result} {
		    return 0
		}
	    }
	    pi {
		if {[dom::node cget $child -nodeType] != "processingInstruction"} {
		    return 0
		}
		if {[dom::node cget $child -nodeName] != [lindex $specchild 1]} {
		    return 0
		}
	    }
	    dtd {
		if {[dom::node cget $child -nodeType] != "dtd"} {
		    return 0
		}
	    }
	    text {
		if {[dom::node cget $child -nodeType] != "textNode"} {
		    return 0
		}
		if {[dom::node cget $child -nodeValue] != [lindex $specchild 1]} {
		    return 0
		}
	    }
	    default {
	    }
	}
    }

    return 1
}

# testPackage package ?version?
#	Loads specified package with 'package require $package $version',
#	then prints message describing how the package was loaded.
#
#	This is useful when you've got several versions of a
#	package to lying around and want to make sure you're 
#	testing the right one.
#

proc testPackage {package {version ""}} {
    if {$package == "libxml2"} {
	# "libxml2" is shorthand for xml::libxml2
	set package xml::libxml2
    }
    if {![catch "package present $package $version"]} { return }
    set rc [catch "package require $package $version" result]
    if {$rc} { return -code $rc $result }
    set version $result
    set loadScript [package ifneeded $package $version]
    puts $::tcltest::outputChannel \
	"Loaded $package version $version via {$loadScript}"
    return;
}

#*EOF*
