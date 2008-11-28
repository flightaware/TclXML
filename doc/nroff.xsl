<?xml version="1.0"?>

<!--
   - nroff.xsl -
   -
   - Copyright (c) 2005 Explain
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

<xsl:stylesheet version='1.0'
  xmlns:xsl='http://www.w3.org/1999/XSL/Transform'
  xmlns:xlink='http://www.w3.org/1999/xlink'
  xmlns:str='http://xsltsl.org/string'
  extension-element-prefixes='str'>

  <xsl:import href='xsltsl/stdlib.xsl'/>

  <xsl:output method="text"/>

  <xsl:template match="refentry">
    <xsl:text>'\"
</xsl:text>
    <xsl:apply-templates select='refentryinfo/copyright'/>
    <xsl:apply-templates select='refentryinfo/legalnotice'/>
    <xsl:text>'\"
'\" RCS: @(#) $Id: nroff.xsl,v 1.4 2005/05/20 12:02:18 balls Exp $
'\" 
.so man.macros
</xsl:text>
    <xsl:apply-templates select="*[not(self::refentryinfo)]"/>
</xsl:template>

  <xsl:template match="refentryinfo/legalnotice">
    <xsl:apply-templates select='para' mode='comment'/>
  </xsl:template>

  <xsl:template match="refentryinfo/copyright">
    <xsl:text>'\" Copyright (c) </xsl:text>
    <xsl:value-of select="year[1]"/>
    <xsl:text> </xsl:text>
    <xsl:value-of select="holder"/>
    <xsl:text>
</xsl:text>
    <xsl:if test='holder/@xlink:href'>
      <xsl:text>'\" </xsl:text>
      <xsl:value-of select='holder/@xlink:href'/>
      <xsl:text>
</xsl:text>
    </xsl:if>
    <xsl:text>'\"
</xsl:text>
  </xsl:template>

  <xsl:template match="refentryinfo/legalnotice/para" mode='comment'>
    <xsl:call-template name="str:justify">
      <xsl:with-param name="text" select="."/>
      <xsl:with-param name="prefix">'\" </xsl:with-param>
      <xsl:with-param name='max' select='"75"'/>
    </xsl:call-template>
    <xsl:text>
'\"
</xsl:text>
  </xsl:template>

  <xsl:template match="refmeta">
    <xsl:text>.TH </xsl:text>
    <xsl:value-of select="refentrytitle"/>
    <xsl:text> </xsl:text>
    <xsl:value-of select="manvolnum"/>
    <xsl:text> </xsl:text>
    <xsl:value-of select="/refentry/refentryinfo/revhistory/revision[1]/revnumber"/>
    <xsl:text> TclXML "TclXML Package Commands"
</xsl:text>
  </xsl:template>
  <xsl:template match='refentrytitle'>
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="refnamediv">
    <xsl:text>.BS
'\" Note:  do not modify the .SH NAME line immediately below!
.SH NAME
</xsl:text>
    <xsl:for-each select="refname">
      <xsl:apply-templates/>
      <xsl:text> </xsl:text>
    </xsl:for-each>
    <xsl:text>\- </xsl:text>
    <xsl:value-of select="refpurpose"/>
    <xsl:text>
.BE

</xsl:text>
  </xsl:template>

  <xsl:template match="refsynopsisdiv">
    <xsl:text>.SH SYNOPSIS
</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>
.BE
</xsl:text>
  </xsl:template>

  <xsl:template match='tclpkgsynopsis|tclnamespacesynopsis|keywordset'/>

  <xsl:template match="tclcmdsynopsis|tcloptionsynopsis">
    <xsl:apply-templates/>
    <xsl:choose>
      <xsl:when test="command/node()[position() = last() and self::*]">
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
  <xsl:template match="tclcmdsynopsis[position() = last()]|tcloptionsynopsis[position() = last()]">
    <xsl:apply-templates/>
    <xsl:choose>
      <xsl:when test="command/node()[position() = last() and self::*]">
        <!-- last element would have reset font -->
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>\fP</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="tclcmdsynopsis/command">
    <xsl:text>\fB</xsl:text>
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="option">
    <xsl:text>\fI </xsl:text>
    <xsl:apply-templates/>
    <xsl:text>\fR</xsl:text>
  </xsl:template>

  <xsl:template match="group">
    <xsl:apply-templates/>
  </xsl:template>
  <xsl:template match="group[@choice='opt']">
    <xsl:text> ?</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>?</xsl:text>
  </xsl:template>
  <xsl:template match="group[@choice='opt' and @rep='repeat']">
    <xsl:text> ?</xsl:text>
    <xsl:apply-templates/>
    <xsl:text> ... ?</xsl:text>
  </xsl:template>

  <xsl:template match="arg">
    <xsl:text>\fI </xsl:text>
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="replaceable|emphasis">
    <xsl:text>\fI</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>\fR</xsl:text>
  </xsl:template>

  <xsl:template match="tclcommand|tclnamespace">
    <xsl:call-template name='inline.bold'/>
  </xsl:template>
  <xsl:template name='inline.bold'>
    <xsl:text>\fB</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>\fR</xsl:text>
  </xsl:template>

  <xsl:template match="refsect1">
    <xsl:text>
.SH </xsl:text>
    <xsl:value-of select="translate(title,'abcdefghijklmnopqrstuvwxyz','ABCDEFGHIJKLMNOPQRSTUVWXYZ')"/>
    <xsl:text>
</xsl:text>
    <xsl:apply-templates select='*[not(self::title)]'/>
  </xsl:template>

  <xsl:template match="para">
    <xsl:text>
.PP
</xsl:text>
    <xsl:if test='parent::listitem/parent::itemizedlist and
                  not(preceding-sibling::para)'>
      <xsl:text>*  </xsl:text>
    </xsl:if>
    <xsl:apply-templates/>
    <xsl:text>
</xsl:text>
  </xsl:template>

  <xsl:template match="para/text()">
    <xsl:value-of select="."/>
  </xsl:template>

  <xsl:template match="refsect2|refsect3">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="acronym">
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="refsect2/title|refsect3/title">
    <xsl:text>.SS </xsl:text>
    <xsl:apply-templates/>
    <xsl:text>
</xsl:text>
  </xsl:template>

  <xsl:template match="segmentedlist|variablelist|itemizedlist">
    <xsl:text>
.RS
</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>.RE
</xsl:text>
  </xsl:template>

  <xsl:template match="seglistitem">
    <xsl:text>.TP
\fI</xsl:text>
    <xsl:value-of select="seg[1]"/>
    <xsl:text>\fP </xsl:text>
    <xsl:value-of select="seg[2]"/>
    <xsl:text>
</xsl:text>
  </xsl:template>

  <xsl:template match="varlistentry">
    <xsl:text>.TP
\fI</xsl:text>
    <xsl:apply-templates select="term"/>
    <xsl:text>\fP 
</xsl:text>
    <xsl:apply-templates select="listitem"/>
    <xsl:text>
</xsl:text>
  </xsl:template>
  <xsl:template match='term'>
    <xsl:call-template name='inline.bold'/>
  </xsl:template>
  <xsl:template match='listitem'>
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match='methodname|version|package|literal'>
    <xsl:call-template name='inline.bold'/>
  </xsl:template>

  <xsl:template match="informalexample">
    <xsl:text>.PP
</xsl:text>
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="programlisting">
    <xsl:text>.CS
</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>
.CE
</xsl:text>
  </xsl:template>

  <xsl:template match='author'>
    <xsl:apply-templates select='firstname'/>
    <xsl:text> </xsl:text>
    <xsl:apply-templates select='surname'/>
  </xsl:template>

  <xsl:template match='firstname|surname'>
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
