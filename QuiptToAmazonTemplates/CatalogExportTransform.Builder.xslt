<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:msxsl="urn:schemas-microsoft-com:xslt"
    xmlns:q="http://schemas.quipt.com/api"
    xmlns:axsl="http://www.w3.org/1999/XSL/TransformAlias"
    exclude-result-prefixes="axsl">

  <!--
  The purpose of this file is to take the serialized CatalogTemplateRequest.BuilderDetails, created with the help of the UITemplate,
  and build the CatalogExportTransform.<categoryId>.<index>.xslt file that will be used to create the catalog file for the specific category.
  -->

  <xsl:namespace-alias stylesheet-prefix="axsl" result-prefix="xsl"/>

  <xsl:output method="xml" indent="yes"/>

  <xsl:param name="Type">XML</xsl:param>

  <!--
Expected builder details:
    - version: Legacy or Json.
    - TemplateType: text.
    - Version: text.
    - ItemType: text or xslt
    - ProductType: text or xslt
    - Filter: xslt or text. If Filter field is empty, all items will be exported. If some xslt present, but xslt execution result is empty, item will be skipped, otherwise exported.
    - Attributes: Name, Code - text, Value - xslt to calculate Value. 
  -->

  <!-- Build category-specific xslt using builder details -->
  <xsl:template match="/q:CatalogTemplateRequest.BuilderDetails">

    <!-- Create xsl:stylesheet element for the output file. It should be the same as in the the master template file. -->
    <axsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:msxsl="urn:schemas-microsoft-com:xslt"
                xmlns:q="http://schemas.quipt.com/api"
                xmlns:i="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:a="http://schemas.microsoft.com/2003/10/Serialization/Arrays"
                xmlns:str="http://exslt.org/strings"
                xmlns:json="http://james.newtonking.com/projects/json"
                exclude-result-prefixes="msxsl q i a str">

      <!-- Current template contains only category-specific code that should be injected to the category-specific result template.
  Static part, that should be copied to all transforms extracted to the separate master template file and may be updated/debugged separately.
  All master template content (excluding xsl:stylesheet element declaration) will be copied to the output xslt. -->
      <xsl:variable name="MasterTemplateFile">
        <xsl:choose>
          <xsl:when test="normalize-space(q:Global/q:CatalogTemplateRequest.Property[q:Key='version']/q:Value)='Json'">CatalogExportTransform.Builder.MasterTemplate.json.xslt</xsl:when>
          <xsl:otherwise>CatalogExportTransform.Builder.MasterTemplate.xslt</xsl:otherwise>
        </xsl:choose>
      </xsl:variable>

      <!-- Copy xslt from the master template file -->
      <xsl:apply-templates select="document($MasterTemplateFile)" mode="copy-master-template"/>

      <!-- Render additional category-specific templates using data from CatalogTemplateRequest.Builder -->
      <xsl:choose>
        <xsl:when test="normalize-space(q:Global/q:CatalogTemplateRequest.Property[q:Key='version']/q:Value)='Json'">
          <!-- Json -->
          <axsl:template match="q:InventoryVirtualResult" mode="render-attributes">
            <xsl:apply-templates select="q:Attributes" mode="render-attributes"/>
          </axsl:template>
          <xsl:text>&#x0d;&#x0a;</xsl:text>
          <axsl:template match="q:InventoryVirtualResult" mode="ProductType">
            <xsl:value-of disable-output-escaping="yes" select="q:Global/q:CatalogTemplateRequest.Property[q:Key='ProductType']/q:Value"/>
          </axsl:template>
          <axsl:template match="node()" mode="language_tag">
            <xsl:value-of disable-output-escaping="yes" select="q:Global/q:CatalogTemplateRequest.Property[q:Key='language_tag']/q:Value"/>
          </axsl:template>
          <xsl:text>&#x0d;&#x0a;</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <!-- Legacy -->
          <!--Render file header-->
          <axsl:template match="q:ArrayOfInventoryVirtualResult" mode="TemplateType">
            <axsl:text>
              <xsl:value-of select="normalize-space(q:Global/q:CatalogTemplateRequest.Property[q:Key='TemplateType']/q:Value)"/>
            </axsl:text>
          </axsl:template>
          <xsl:text>&#x0d;&#x0a;</xsl:text>

          <axsl:template match="q:ArrayOfInventoryVirtualResult" mode="Version">
            <axsl:text>
              <xsl:value-of select="normalize-space(q:Global/q:CatalogTemplateRequest.Property[q:Key='Version']/q:Value)"/>
            </axsl:text>
          </axsl:template>
          <xsl:text>&#x0d;&#x0a;</xsl:text>

          <xsl:variable name="special_features" select="q:Global/q:CatalogTemplateRequest.Property[q:Key='special_features']/q:Value"/>

          <axsl:template match="q:ArrayOfInventoryVirtualResult" mode="render-attributes-row2">
            <xsl:if test="normalize-space($special_features)!=''">
              <axsl:call-template name="render">
                <axsl:with-param name="value">Additional Features</axsl:with-param>
                <axsl:with-param name="addseparator">
                  <xsl:if test="q:Attributes/q:CatalogTemplateRequest.Attribute">1</xsl:if>
                </axsl:with-param>
              </axsl:call-template>
            </xsl:if>
            <xsl:apply-templates select="q:Attributes" mode="render-attributes-row2"/>
          </axsl:template>
          <xsl:text>&#x0d;&#x0a;</xsl:text>

          <axsl:template match="q:ArrayOfInventoryVirtualResult" mode="render-attributes-row3">
            <xsl:if test="normalize-space($special_features)!=''">
              <axsl:call-template name="render">
                <axsl:with-param name="value">special_features</axsl:with-param>
                <axsl:with-param name="addseparator">
                  <xsl:if test="q:Attributes/q:CatalogTemplateRequest.Attribute">1</xsl:if>
                </axsl:with-param>
              </axsl:call-template>
            </xsl:if>
            <xsl:apply-templates select="q:Attributes" mode="render-attributes-row3"/>
          </axsl:template>
          <xsl:text>&#x0d;&#x0a;</xsl:text>

          <!--Render values -->

          <axsl:template match="q:InventoryVirtualResult" mode="render-attributes-values">
            <xsl:if test="normalize-space($special_features)!=''">
              <axsl:call-template name="render">
                <axsl:with-param name="value">
                  <xsl:value-of disable-output-escaping="yes" select="$special_features"/>
                </axsl:with-param>
                <axsl:with-param name="addseparator">
                  <xsl:if test="q:Attributes/q:CatalogTemplateRequest.Attribute">1</xsl:if>
                </axsl:with-param>
              </axsl:call-template>
            </xsl:if>
            <xsl:apply-templates select="q:Attributes" mode="render-attributes-values"/>
          </axsl:template>
        </xsl:otherwise>
      </xsl:choose>

      <axsl:template match="q:InventoryVirtualResult" mode="ItemType">
        <xsl:value-of disable-output-escaping="yes" select="q:Global/q:CatalogTemplateRequest.Property[q:Key='ItemType']/q:Value"/>
      </axsl:template>
      <xsl:text>&#x0d;&#x0a;</xsl:text>

      <axsl:template match="q:InventoryVirtualResult" mode="Filter">
        <xsl:apply-templates select="q:Global/q:CatalogTemplateRequest.Property[q:Key='Filter']"/>
      </axsl:template>
      <xsl:text>&#x0d;&#x0a;</xsl:text>

      <axsl:template match="q:InventoryVirtualResult" mode="bullet_point1">
        <xsl:apply-templates select="q:Global/q:CatalogTemplateRequest.Property[q:Key='bullet_point1']" mode="bullet_point_template"/>
      </axsl:template>
      <xsl:text>&#x0d;&#x0a;</xsl:text>

      <axsl:template match="q:InventoryVirtualResult" mode="bullet_point2">
        <xsl:apply-templates select="q:Global/q:CatalogTemplateRequest.Property[q:Key='bullet_point2']" mode="bullet_point_template"/>
      </axsl:template>
      <xsl:text>&#x0d;&#x0a;</xsl:text>

      <axsl:template match="q:InventoryVirtualResult" mode="bullet_point3">
        <xsl:apply-templates select="q:Global/q:CatalogTemplateRequest.Property[q:Key='bullet_point3']" mode="bullet_point_template"/>
      </axsl:template>
      <xsl:text>&#x0d;&#x0a;</xsl:text>

      <axsl:template match="q:InventoryVirtualResult" mode="bullet_point4">
        <xsl:apply-templates select="q:Global/q:CatalogTemplateRequest.Property[q:Key='bullet_point4']" mode="bullet_point_template"/>
      </axsl:template>
      <xsl:text>&#x0d;&#x0a;</xsl:text>

      <axsl:template match="q:InventoryVirtualResult" mode="bullet_point5">
        <xsl:apply-templates select="q:Global/q:CatalogTemplateRequest.Property[q:Key='bullet_point5']" mode="bullet_point_template"/>
      </axsl:template>
      <xsl:text>&#x0d;&#x0a;</xsl:text>

      <!--<axsl:template match="q:InventoryVirtualResult" mode="condition">
        <xsl:choose>
          <xsl:when test="q:Global/q:CatalogTemplateRequest.Property[q:Key='condition']/q:Value!=''">
            <xsl:value-of disable-output-escaping="yes" select="q:Global/q:CatalogTemplateRequest.Property[q:Key='condition']/q:Value"/>
          </xsl:when>
          <xsl:otherwise>
            <axsl:apply-templates select="." mode="condition_default"/>
        </xsl:otherwise>
        </xsl:choose>
      </axsl:template>
      <xsl:text>&#x0d;&#x0a;</xsl:text>-->

      <xsl:text>&#x0d;&#x0a;</xsl:text>
    </axsl:stylesheet>
  </xsl:template>

  <xsl:template match="q:Attributes" mode="render-attributes-row2">
    <xsl:for-each select="q:CatalogTemplateRequest.Attribute">
      <!--<xsl:sort select="normalize-space(q:Properties/q:CatalogTemplateRequest.Property[q:Key='Sort']/q:Value)"/>-->
      <xsl:text>&#x0d;&#x0a;</xsl:text>
      <axsl:call-template name="render">
        <axsl:with-param name="value">
          <xsl:value-of select="normalize-space(q:Properties/q:CatalogTemplateRequest.Property[q:Key='Name']/q:Value)"/>
        </axsl:with-param>
        <axsl:with-param name="addseparator">
          <xsl:if test="position()!=last()">1</xsl:if>
        </axsl:with-param>
      </axsl:call-template>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="q:Attributes" mode="render-attributes-row3">
    <xsl:for-each select="q:CatalogTemplateRequest.Attribute">
      <!--<xsl:sort select="normalize-space(q:Properties/q:CatalogTemplateRequest.Property[q:Key='Sort']/q:Value)"/>-->
      <xsl:text>&#x0d;&#x0a;</xsl:text>
      <axsl:call-template name="render">
        <axsl:with-param name="value">
          <xsl:value-of select="normalize-space(q:Properties/q:CatalogTemplateRequest.Property[q:Key='Code']/q:Value)"/>
        </axsl:with-param>
        <axsl:with-param name="addseparator">
          <xsl:if test="position()!=last()">1</xsl:if>
        </axsl:with-param>
      </axsl:call-template>
    </xsl:for-each>
  </xsl:template>

  <!-- Legacy Template to insert xslt that generates attributes -->
  <xsl:template match="q:Attributes" mode="render-attributes-values">
    <xsl:for-each select="q:CatalogTemplateRequest.Attribute">
      <!--<xsl:sort select="normalize-space(q:Properties/q:CatalogTemplateRequest.Property[q:Key='Sort']/q:Value)"/>-->
      <xsl:text>&#x0d;&#x0a;</xsl:text>
      <axsl:call-template name="render">
        <axsl:with-param name="value">
          <xsl:value-of disable-output-escaping="yes" select="q:Properties/q:CatalogTemplateRequest.Property[q:Key='Value']/q:Value"/>
        </axsl:with-param>
        <axsl:with-param name="addseparator">
          <xsl:if test="position()!=last()">1</xsl:if>
        </axsl:with-param>
      </axsl:call-template>
    </xsl:for-each>
  </xsl:template>

  <!-- Json Template to insert xslt that generates attributes -->
  <xsl:template match="q:Attributes" mode="render-attributes">
    <xsl:for-each select="q:CatalogTemplateRequest.Attribute">
      <axsl:call-template name="render">
        <axsl:with-param name="value">
          <xsl:value-of disable-output-escaping="yes" select="q:Properties/q:CatalogTemplateRequest.Property[q:Key='Value']/q:Value"/>
        </axsl:with-param>
      </axsl:call-template>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="q:Global/q:CatalogTemplateRequest.Property[q:Key='Filter']">
    <xsl:choose>
      <xsl:when test="normalize-space(q:Value)!=''">
        <axsl:variable name="includeItem">
          <xsl:value-of disable-output-escaping="yes" select="q:Value"/>
        </axsl:variable>
        <axsl:value-of select="normalize-space($includeItem)"/>
      </xsl:when>
      <xsl:otherwise>
        <axsl:text>No filter specified (export all)</axsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="q:Global/q:CatalogTemplateRequest.Property" mode="bullet_point_template">
    <xsl:if test="normalize-space(q:Value)!=''">
      <xsl:value-of disable-output-escaping="yes" select="q:Value"/>
    </xsl:if>
  </xsl:template>

  <!--Templates to copy xsl from master template to output excluding its xsl:stylesheet element-->
  <xsl:template match="/*" mode="copy-master-template">
    <xsl:apply-templates select="node()" mode="copy-master-template"/>
  </xsl:template>
  <xsl:template match="node() | @*" mode="copy-master-template">
    <xsl:copy>
      <xsl:apply-templates select="node() | @*" mode="copy-master-template"/>
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>
