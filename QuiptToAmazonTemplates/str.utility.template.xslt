<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:str="http://exslt.org/strings"
                xmlns:msxsl="urn:schemas-microsoft-com:xslt"
                extension-element-prefixes="str msxsl">

  <!-- upper/lower case alphabet strings that is used for latercase conversions -->
  <xsl:variable name="str:lowercase">abcdefghijklmnopqrstuvwxyz</xsl:variable>
  <xsl:variable name="str:uppercase">ABCDEFGHIJKLMNOPQRSTUVWXYZ</xsl:variable>

  <xsl:template name="str:reverse">
    <xsl:param name="input"/>
    <xsl:choose>
      <xsl:when test="string-length($input) &gt; 1">
        <xsl:call-template name="str:reverse">
          <xsl:with-param name="input" select="substring($input, 2)"/>
        </xsl:call-template>
        <xsl:value-of select="substring($input, 1, 1)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$input"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="str:replace">
    <xsl:param name="text"/>
    <xsl:param name="replace"/>
    <xsl:param name="with"/>
    <xsl:choose>
      <xsl:when test="contains($text,$replace)">
        <xsl:value-of select="substring-before($text,$replace)"/>
        <xsl:value-of select="$with"/>
        <xsl:call-template name="str:replace">
          <xsl:with-param name="text" select="substring-after($text,$replace)"/>
          <xsl:with-param name="replace" select="$replace"/>
          <xsl:with-param name="with" select="$with"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$text"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="str:filter-phrases">
    <xsl:param name="text"/>
    <xsl:param name="remove"/>
    <xsl:param name="current-index">1</xsl:param>

    <xsl:variable name ="phrasesNodeSet" select="msxsl:node-set($remove)"/>
    <xsl:variable name ="phrase" select="$phrasesNodeSet/token[$current-index]"/>
    <xsl:choose>
      <xsl:when test="count($phrasesNodeSet/token) &lt; $current-index">
        <xsl:value-of select="$text"/>
      </xsl:when>
      <xsl:when test="string($phrase)=''">
        <xsl:call-template name="str:filter-phrases">
          <xsl:with-param name="current-index" select="$current-index+1"/>
          <xsl:with-param name="remove" select="$remove"/>
          <xsl:with-param name="text" select="$text"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="str:filter-phrases">
          <xsl:with-param name="current-index" select="$current-index+1"/>
          <xsl:with-param name="remove" select="$remove"/>
          <xsl:with-param name="text">
            <xsl:call-template name="str:replace">
              <xsl:with-param name="text" select="$text"/>
              <xsl:with-param name="replace" select="$phrase"/>
              <xsl:with-param name="with"></xsl:with-param>
            </xsl:call-template>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- 
  Case insensitive 'contains' implementation. If true returns $then (default is 1),
  otherwise returns $else (default is empty) 
  $then and $else can be xml fragment or text.
  -->
  <xsl:template name="str:contains">
    <xsl:param name="haystack"/>
    <xsl:param name="needle"/>
    <xsl:param name="then">1</xsl:param>
    <xsl:param name="else"/>
    <xsl:choose>
      <xsl:when test="contains(translate($haystack,$str:lowercase,$str:uppercase),translate($needle,$str:lowercase,$str:uppercase))">
        <xsl:choose>
          <xsl:when test="msxsl:node-set($then)">
            <xsl:copy-of select="msxsl:node-set($then)"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$then"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:choose>
          <xsl:when test="msxsl:node-set($else)">
            <xsl:copy-of select="msxsl:node-set($else)"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$else"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

	<xsl:template name="str:trim-right">
		<xsl:param name="input"/>
		<xsl:choose>
			<xsl:when test="substring($input, string-length($input)) = ' '">
				<xsl:call-template name="str:trim-right">
					<xsl:with-param name="input" select="substring($input, 1, string-length($input) - 1)"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$input"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
</xsl:stylesheet>
