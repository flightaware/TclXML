<xsl:stylesheet version='1.0'
  xmlns:xsl='http://www.w3.org/1999/XSL/Transform'
  xmlns:d='http://docbook.org/ns/docbook'
  xmlns:xlink='http://www.w3.org/1999/xlink'
  xmlns:tcl='http://tclxml.sourceforge.net/doc'
  xmlns:str='http://xsltsl.org/string'
  extension-element-prefixes='str'
  exclude-result-prefixes='d xlink tcl'>

  <!--
     - nroff.xsl -
     -
     - Copyright (c) 2005-2008 Explain
     - http://www.explain.com.au/
     -
     - Copyright (c) 2000-2003 Zveno Pty Ltd
     -
     - See the file "LICENSE" for information on usage and
     - redistribution of this file, and for a DISCLAIMER OF ALL WARRANTIES.
     -
     -	XSLT stylesheet to convert DocBook+Tcl mods to nroff.
     -	NB. Tcl man macros are used.
     -
     - $Id: nroff.xsl,v 1.4 2005/05/20 12:02:18 balls Exp $
  -->

  <xsl:import href='xsltsl/stdlib.xsl'/>

  <xsl:output method="text"/>

  <xsl:template match="d:refentry">
    <xsl:text>'\"
</xsl:text>
    <xsl:apply-templates select='d:info/d:copyright'/>
    <xsl:apply-templates select='d:info/d:legalnotice'/>
    <xsl:text>'\"
'\" RCS: @(#) $Id: nroff.xsl,v 1.4 2005/05/20 12:02:18 balls Exp $
'\" 
.so man.macros
</xsl:text>
    <xsl:apply-templates select="*[not(self::d:info)]"/>
</xsl:template>

  <xsl:template match="d:info/d:legalnotice">
    <xsl:apply-templates select='d:para' mode='comment'/>
  </xsl:template>

  <xsl:template match="d:info/d:copyright">
    <xsl:text>'\" Copyright (c) </xsl:text>
    <xsl:value-of select="d:year[1]"/>
    <xsl:text> </xsl:text>
    <xsl:value-of select="d:holder"/>
    <xsl:text>
</xsl:text>
    <xsl:if test='d:holder/@xlink:href'>
      <xsl:text>'\" </xsl:text>
      <xsl:value-of select='d:holder/@xlink:href'/>
      <xsl:text>
</xsl:text>
    </xsl:if>
    <xsl:text>'\"
</xsl:text>
  </xsl:template>

  <xsl:template match="d:info/d:legalnotice/d:para" mode='comment'>
    <xsl:call-template name="str:justify">
      <xsl:with-param name="text" select="."/>
      <xsl:with-param name="prefix">'\" </xsl:with-param>
      <xsl:with-param name='max' select='"75"'/>
    </xsl:call-template>
    <xsl:text>
'\"
</xsl:text>
  </xsl:template>

  <xsl:template match="d:refmeta">
    <xsl:text>.TH </xsl:text>
    <xsl:value-of select="d:refentrytitle"/>
    <xsl:text> </xsl:text>
    <xsl:value-of select="d:manvolnum"/>
    <xsl:text> </xsl:text>
    <xsl:value-of select="/d:refentry/d:info/d:revhistory/d:revision[1]/d:revnumber"/>
    <xsl:text> TclXML "TclXML Package Commands"
</xsl:text>
  </xsl:template>
  <xsl:template match='d:refentrytitle'>
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="d:refnamediv">
    <xsl:text>.BS
'\" Note:  do not modify the .SH NAME line immediately below!
.SH NAME
</xsl:text>
    <xsl:for-each select="d:refname">
      <xsl:apply-templates/>
      <xsl:text> </xsl:text>
    </xsl:for-each>
    <xsl:text>\- </xsl:text>
    <xsl:value-of select="d:refpurpose"/>
    <xsl:text>
.BE

</xsl:text>
  </xsl:template>

  <xsl:template match="d:refsynopsisdiv">
    <xsl:text>.SH SYNOPSIS
</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>
.BE
</xsl:text>
  </xsl:template>

  <xsl:template match='tcl:pkgsynopsis|tcl:namespacesynopsis|d:keywordset'/>

  <xsl:template match="tcl:cmdsynopsis|tcl:optionsynopsis">
    <xsl:apply-templates/>
    <xsl:choose>
      <xsl:when test="d:command/node()[position() = last() and self::*]">
        <!-- last element would have reset font -->
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>\fP</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:text>
.sp
</xsl:text>
  </xsl:template>
  <xsl:template match="tcl:cmdsynopsis[position() = last()]|tcl:optionsynopsis[position() = last()]">
    <xsl:apply-templates/>
    <xsl:choose>
      <xsl:when test="d:command/node()[position() = last() and self::*]">
        <!-- last element would have reset font -->
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>\fP</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="tcl:cmdsynopsis/d:command">
    <xsl:text>\fB</xsl:text>
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="d:option">
    <xsl:text>\fI </xsl:text>
    <xsl:apply-templates/>
    <xsl:text>\fR</xsl:text>
  </xsl:template>

  <xsl:template match="d:group">
    <xsl:apply-templates/>
  </xsl:template>
  <xsl:template match="d:group[@choice='opt']">
    <xsl:text> ?</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>?</xsl:text>
  </xsl:template>
  <xsl:template match="d:group[@choice='opt' and @rep='repeat']">
    <xsl:text> ?</xsl:text>
    <xsl:apply-templates/>
    <xsl:text> ... ?</xsl:text>
  </xsl:template>

  <xsl:template match="d:arg">
    <xsl:text>\fI </xsl:text>
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="d:replaceable|d:emphasis">
    <xsl:text>\fI</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>\fR</xsl:text>
  </xsl:template>

  <xsl:template match="tcl:command|tcl:namespace|tcl:method|tcl:package">
    <xsl:call-template name='inline.bold'/>
  </xsl:template>
  <xsl:template name='inline.bold'>
    <xsl:text>\fB</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>\fR</xsl:text>
  </xsl:template>

  <xsl:template match="d:refsect1">
    <xsl:text>
.SH </xsl:text>
    <xsl:value-of select="translate(d:info/d:title,'abcdefghijklmnopqrstuvwxyz','ABCDEFGHIJKLMNOPQRSTUVWXYZ')"/>
    <xsl:text>
</xsl:text>
    <xsl:apply-templates select='*[not(self::d:info)]'/>
  </xsl:template>

  <xsl:template match="d:para|d:note">
    <xsl:text>
.PP
</xsl:text>
    <xsl:if test='parent::d:listitem/parent::d:itemizedlist and
                  not(preceding-sibling::d:para)'>
      <xsl:text>*  </xsl:text>
    </xsl:if>
    <xsl:apply-templates/>
    <xsl:text>
</xsl:text>
  </xsl:template>

  <xsl:template match="d:para/text()">
    <xsl:value-of select="."/>
  </xsl:template>

  <xsl:template match="d:refsect2|d:refsect3">
    <xsl:apply-templates/>
  </xsl:template>
  <xsl:template match="d:refsect2/d:info|d:refsect3/d:info">
    <xsl:apply-templates select='d:title'/>
  </xsl:template>

  <xsl:template match="d:acronym|d:link">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="d:refsect2/d:info/d:title|d:refsect3/d:info/d:title">
    <xsl:text>.SS </xsl:text>
    <xsl:apply-templates/>
    <xsl:text>
</xsl:text>
  </xsl:template>

  <xsl:template match="d:segmentedlist|d:variablelist|d:itemizedlist|d:orderedlist">
    <xsl:text>
.RS
</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>.RE
</xsl:text>
  </xsl:template>

  <xsl:template match="d:seglistitem">
    <xsl:text>.TP
\fI</xsl:text>
    <xsl:value-of select="d:seg[1]"/>
    <xsl:text>\fP </xsl:text>
    <xsl:value-of select="d:seg[2]"/>
    <xsl:text>
</xsl:text>
  </xsl:template>

  <xsl:template match="d:varlistentry">
    <xsl:text>.TP
\fI</xsl:text>
    <xsl:apply-templates select="d:term"/>
    <xsl:text>\fP 
</xsl:text>
    <xsl:apply-templates select="d:listitem"/>
    <xsl:text>
</xsl:text>
  </xsl:template>
  <xsl:template match='d:term|d:classname|d:tag|d:application'>
    <xsl:call-template name='inline.bold'/>
  </xsl:template>
  <xsl:template match='d:listitem'>
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match='d:methodname|d:version|d:package|d:literal'>
    <xsl:call-template name='inline.bold'/>
  </xsl:template>

  <xsl:template match="d:informalexample">
    <xsl:text>.PP
</xsl:text>
    <xsl:apply-templates/>
  </xsl:template>
  <xsl:template match="d:example">
    <xsl:text>.PP
</xsl:text>
<xsl:apply-templates select='d:title/node()|d:info/d:title/node()'/>
    <xsl:text>.PP
</xsl:text>
    <xsl:apply-templates select='*[not(self::d:title|self::d:info)]'/>
  </xsl:template>

  <xsl:template match="d:programlisting|d:literallayout|d:computeroutput">
    <xsl:text>.CS
</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>
.CE
</xsl:text>
  </xsl:template>

  <xsl:template match='d:author'>
    <xsl:apply-templates select='d:firstname'/>
    <xsl:text> </xsl:text>
    <xsl:apply-templates select='d:surname'/>
  </xsl:template>

  <xsl:template match='d:firstname|d:surname'>
    <xsl:apply-templates/>
  </xsl:template>

  <!-- Override built-in rules to omit unwanted content -->

  <xsl:template match="*">
    <xsl:message>No template matching <xsl:value-of select="name()"/> (parent <xsl:value-of select="name(..)"/>)</xsl:message>
  </xsl:template>
  <xsl:template match="text()[string-length(normalize-space()) = 0]|@*">
    <!-- Don't emit white space -->
  </xsl:template>

</xsl:stylesheet>
