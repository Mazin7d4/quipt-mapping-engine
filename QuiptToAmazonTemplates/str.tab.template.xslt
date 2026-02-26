<?xml version="1.0"?>
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:str="http://exslt.org/strings"
                extension-element-prefixes="str">

	<xsl:template name="str:TABencode">
    		<xsl:param name="string" />
    		<xsl:param name="length">80</xsl:param>

    		<xsl:variable name="temp">
			    <xsl:value-of select="substring($string, 1, $length)"/>
    		</xsl:variable>

    		<xsl:choose>
      			<xsl:when test="contains($temp, '&#09;') or contains($temp, '&quot;') or contains($temp, '&lt;!--')">"<xsl:call-template name="str:TABescape"><xsl:with-param name="string" select="$temp" /></xsl:call-template>"</xsl:when>
      			<xsl:otherwise>
        			<xsl:value-of select="normalize-space($temp)" disable-output-escaping="yes"/>
      			</xsl:otherwise>
    		</xsl:choose> 
	</xsl:template>

	<xsl:template name="str:TABescape">
    		<xsl:param name="string" />
    
    		<xsl:choose>
      			<xsl:when test="contains($string, '&quot;')">
        			<xsl:value-of select="substring-before($string, '&quot;')" disable-output-escaping="yes"/>
        			<xsl:text>""</xsl:text>
        			<xsl:variable name="substring_after_first_quote" select="substring-after($string, '&quot;')" />
        			<xsl:choose>
          				<xsl:when test="not(contains($substring_after_first_quote, '&quot;'))">
            					<xsl:value-of select="$substring_after_first_quote" disable-output-escaping="yes"/>
          				</xsl:when>
          				<xsl:otherwise>
            					<xsl:call-template name="str:TABescape">
              						<xsl:with-param name="string" select="$substring_after_first_quote" />
            					</xsl:call-template>
          				</xsl:otherwise>
        			</xsl:choose>
      			</xsl:when>
			<xsl:when test="contains($string, '&#13;&#10;')">
        			<xsl:value-of select="substring-before($string, '&#13;&#10;')" disable-output-escaping="yes"/>
        			<xsl:text> </xsl:text>
        			<xsl:variable name="substring_after_first_quote1" select="substring-after($string, '&#13;&#10;')" />
        			<xsl:choose>
          				<xsl:when test="not(contains($substring_after_first_quote1, '&#13;&#10;'))">
            					<xsl:value-of select="$substring_after_first_quote1" disable-output-escaping="yes"/>
          				</xsl:when>
          				<xsl:otherwise>
            					<xsl:call-template name="str:TABescape">
              						<xsl:with-param name="string" select="$substring_after_first_quote1" />
            					</xsl:call-template>
          				</xsl:otherwise>
        			</xsl:choose>
      			</xsl:when>
			      <xsl:when test="contains($string, '&lt;!--')">
				      <xsl:value-of select="substring-before($string, '&lt;!--')" disable-output-escaping="yes"/>
				      <xsl:call-template name="str:TABescape">
					      <xsl:with-param name="string" select="substring-after($string, '--&gt;')"/>
				      </xsl:call-template>
			      </xsl:when>
      			<xsl:otherwise>
        			<xsl:value-of select="$string" disable-output-escaping="yes"/>
      			</xsl:otherwise>
    		</xsl:choose>
	</xsl:template>
</xsl:stylesheet>