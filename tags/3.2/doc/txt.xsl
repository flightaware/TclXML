<xsl:stylesheet version='1.0'
  xmlns:xsl='http://www.w3.org/1999/XSL/Transform'
  xmlns:d='http://docbook.org/ns/docbook'
  xmlns:xlink='http://www.w3.org/1999/xlink'
  xmlns:tcl='http://tclxml.sourceforge.net/doc'
  xmlns:str='http://xsltsl.org/string'
  extension-element-prefixes='str'
  exclude-result-prefixes="d xlink tcl">

  <xsl:import href='xsltsl/stdlib.xsl'/>

  <d:article>
    <d:info>
      <d:title>Text Stylesheet</d:title>
      <d:copyright>
        <d:year>2008</d:year>
        <d:holder>Explain</d:holder>
      </d:copyright>
    </d:info>

    <d:para>This stylesheet produces a text rendition of a DocBook document.</d:para>
  </d:article>

  <xsl:output method='text'/>

  <xsl:strip-space elements='*'/>
  <xsl:preserve-space elements='d:programlisting d:literallayout d:command'/>

  <xsl:template match='d:article'>
    <xsl:choose>
      <xsl:when test='d:title'>
        <xsl:apply-templates select='d:title'/>
      </xsl:when>
      <xsl:when test='d:info/d:title'>
        <xsl:apply-templates select='d:info/d:title'/>
      </xsl:when>
    </xsl:choose>

    <xsl:apply-templates select='d:info/d:author'/>
    <xsl:text>

</xsl:text>

    <xsl:apply-templates select='*[not(self::d:info|self::d:title)]'/>
  </xsl:template>

  <xsl:template match='d:article/d:title|d:article/d:info/d:title'>
    <xsl:text>
	</xsl:text>
    <xsl:apply-templates/>
    <xsl:text>

</xsl:text>

    <xsl:if test='following-sibling::d:subtitle'>
      <xsl:text>	</xsl:text>
      <xsl:apply-templates select='following-sibling::d:subtitle'/>
      <xsl:if test='following-sibling::d:revhistory'>
        <xsl:text> Version </xsl:text>
        <xsl:apply-templates select='following-sibling::d:revhistory/d:revision[1]/d:revnumber'/>
      </xsl:if>
    </xsl:if>
    <xsl:text>

</xsl:text>
  </xsl:template>

  <xsl:template match='d:author'>
    <xsl:apply-templates select='d:firstname'/>
    <xsl:text> </xsl:text>
    <xsl:apply-templates select='d:surname'/>
    <xsl:if test='d:affiliation'>
      <xsl:text>, </xsl:text>
      <xsl:apply-templates select='d:affiliation/d:orgname'/>
    </xsl:if>
  </xsl:template>

  <xsl:template match='d:para'>
    <xsl:param name='indent' select='0'/>
    <xsl:param name='linelen' select='80'/>

    <xsl:call-template name='str:justify'>
      <xsl:with-param name='text'>
        <xsl:apply-templates/>
      </xsl:with-param>
      <xsl:with-param name='indent' select='$indent'/>
      <xsl:with-param name='max' select='$linelen'/>
    </xsl:call-template>
    <xsl:text>

</xsl:text>
  </xsl:template>

  <xsl:template match='d:note'>
    <xsl:call-template name='str:justify'>
      <xsl:with-param name='text'>
        <xsl:apply-templates/>
      </xsl:with-param>
      <xsl:with-param name='indent' select='4'/>
    </xsl:call-template>
    <xsl:text>

</xsl:text>
  </xsl:template>

  <xsl:template match='d:section'>
    <xsl:text>

</xsl:text>
    <xsl:apply-templates select='d:info/d:title'/>
    <xsl:if test='d:info/d:subtitle'>
      <xsl:text> (</xsl:text>
      <xsl:apply-templates select='d:info/d:subtitle'/>
      <xsl:text>)</xsl:text>
    </xsl:if>
    <xsl:text>
</xsl:text>
    <xsl:variable name='titlelen'>
      <xsl:choose>
        <xsl:when test='d:subtitle'>
          <xsl:value-of select='string-length(d:info/d:title) + 3 + string-length(d:info/d:subtitle)'/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select='string-length(d:info/d:title)'/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:call-template name='str:generate-string'>
      <xsl:with-param name='count' select='$titlelen'/>
      <xsl:with-param name='text'>
        <xsl:choose>
          <xsl:when test='parent::d:section'>-</xsl:when>
          <xsl:otherwise>=</xsl:otherwise>
        </xsl:choose>
      </xsl:with-param>
    </xsl:call-template>
    <xsl:text>

</xsl:text>

    <xsl:apply-templates select='*[not(self::d:info)]'/>
  </xsl:template>

  <xsl:template match='d:itemizedlist'>
    <xsl:apply-templates select='d:listitem'/>
    <xsl:text>
</xsl:text>
  </xsl:template>
  <xsl:template match='d:itemizedlist/d:listitem'>
    <xsl:call-template name='str:generate-string'>
      <xsl:with-param name='text' select='" "'/>
      <xsl:with-param name='count' select='count(ancestor::d:itemizedlist|ancestor::d:variablelist) * 4'/>
    </xsl:call-template>

    <xsl:text>* </xsl:text>
    <xsl:apply-templates select='*'>
      <xsl:with-param name='indent' select='count(ancestor::d:itemizedlist|ancestor::d:variablelist) * 4'/>
      <xsl:with-param name='linelen' select='80 - count(ancestor::d:itemizedlist|ancestor::d:variablelist) * 4'/>
    </xsl:apply-templates>
  </xsl:template>

  <xsl:template match='d:variablelist'>
    <xsl:apply-templates select='d:varlistentry'/>
  </xsl:template>
  <xsl:template match='d:varlistentry'>
    <xsl:call-template name='str:generate-string'>
      <xsl:with-param name='text' select='" "'/>
      <xsl:with-param name='count' select='(count(ancestor::d:variablelist|ancestor::d:itemizedlist) - 1) * 4'/>
    </xsl:call-template>

    <xsl:apply-templates select='d:term'/>
    <xsl:apply-templates select='d:listitem'/>
    <xsl:text>

</xsl:text>
  </xsl:template>
  <xsl:template match='d:varlistentry/d:term'>
    <xsl:apply-templates/>
    <xsl:text>
</xsl:text>
  </xsl:template>
  <xsl:template match='d:varlistentry/d:listitem'>
    <xsl:apply-templates select='*'>
      <xsl:with-param name='indent' select='count(ancestor::d:variablelist|ancestor::d:itemizedlist) * 4'/>
    </xsl:apply-templates>
  </xsl:template>

  <xsl:template match='d:programlisting|d:literallayout'>
    <xsl:call-template name='indent'>
      <xsl:with-param name='text' select='.'/>
      <xsl:with-param name='indent' select='(count(ancestor::d:itemizedlist|ancestor::d:variablelist) + 1) * 4'/>
    </xsl:call-template>
    <xsl:text>

</xsl:text>
  </xsl:template>

  <xsl:template name='indent'>
    <xsl:param name='text'/>
    <xsl:param name='indent' select='4'/>

    <xsl:choose>
      <xsl:when test='not($text)'/>
      <xsl:when test='contains($text, "&#xa;")'>
        <xsl:call-template name='str:generate-string'>
          <xsl:with-param name='text' select='" "'/>
          <xsl:with-param name='count' select='$indent'/>
        </xsl:call-template>
        <xsl:value-of select='substring-before($text, "&#xa;")'/>
        <xsl:text>
</xsl:text>
        <xsl:call-template name='indent'>
          <xsl:with-param name='text' select='substring-after($text, "&#xa;")'/>
          <xsl:with-param name='indent' select='$indent'/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name='str:generate-string'>
          <xsl:with-param name='text' select='" "'/>
          <xsl:with-param name='count' select='$indent'/>
        </xsl:call-template>
        <xsl:value-of select='$text'/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match='d:link'>
    <xsl:apply-templates/>
    <xsl:text> [</xsl:text>
    <xsl:value-of select='@xlink:href'/>
    <xsl:text>]</xsl:text>
  </xsl:template>

</xsl:stylesheet>
