<xsl:stylesheet version='1.0'
  xmlns:xsl='http://www.w3.org/1999/XSL/Transform'>

  <xsl:template match='/'>
    <xsl:text>The document contains </xsl:text>
    <xsl:call-template name='add'>
      <xsl:with-param name='nodes' select='//text()'/>
    </xsl:call-template>
    <xsl:text> characters.
</xsl:text>
  </xsl:template>

  <xsl:template name='add'>
    <xsl:param name='sum' select='0'/>
    <xsl:param name='nodes' select='/..'/>

    <xsl:choose>
      <xsl:when test='not($nodes)'>
        <xsl:value-of select='$sum'/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name='add'>
          <xsl:with-param name='sum'
            select='$sum + string-length($nodes[1])'/>
          <xsl:with-param name='nodes'
            select='$nodes[position() != 1]'/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
