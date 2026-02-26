<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                xmlns:q="http://schemas.quipt.com/api"
                xmlns:a="http://schemas.microsoft.com/2003/10/Serialization/Arrays"
                xmlns:str="http://exslt.org/strings"
                 xmlns:json="http://james.newtonking.com/projects/json"
                xmlns:msxsl="urn:schemas-microsoft-com:xslt" exclude-result-prefixes="msxsl xsi xsd str q a">
  <xsl:import href="inventory.shared.xslt" />
  <!-- SHPTMPLT - string -->
  <xsl:param name="SHPTMPLT"/>
  <!-- SHPTMPLT2 - xml. Expected format:
<array>
    <a key="SHPTMPLT_{QuiptCategoryId}" value="amzn1"/>
</array> -->
  <xsl:param name="SHPTMPLT2"/>
  <xsl:param name="MARKETPLACEID" />

  <!-- Xml parameter. Expected xml format: 
      Key: COND_{QuiptConditionCode} - General override
      Key: COND_{QuiptConditionCode}_{QuiptCategoryId} - Category specific override
  <array><a key="COND_{QuiptConditionCode}_{QuiptCategoryId}" value="AmazonCondition"/></array>-->
  <xsl:param name="COND"/>

  <!-- Xml parameter. If value=False - exclude. Expected xml format:
    <array>
    <a key="RESTORED_{MANID}_{CATID}" value="True"/>
    <a key="RESTORED_{MANID}_ALL" value="True"/>
    <a key="RESTORED_ALL_{CATID}" value="True"/>
</array>-->
  <xsl:param name="RESTORED"/>
  <!-- Xml parameter. Expected the same xml format like for RESTORED -->
  <xsl:param name="RESTOREDPREM"/>
  <xsl:param name="CERTREFURB_CAT"/>
  <xsl:param name="CERTREFURB_BRND"/>

  <xsl:variable name="CERTREFURB_CAT_UPR" select="translate($CERTREFURB_CAT,'abcdefl','ABCDEFL')"/>
  <xsl:variable name="CERTREFURB_BRND_UPR" select="translate($CERTREFURB_BRND,'abcdefl','ABCDEFL')"/>

  <xsl:template name="ArrayItem">
    <xsl:param name="value"/>
    <xsl:param name="additionalNodes"/>
    <xsl:param name="maxLength"/>
    <xsl:param name="tagName"/>
    <xsl:param name="addMarketplace">1</xsl:param>
    <xsl:param name="addLanguage">1</xsl:param>

    <xsl:if test="string($value)!='' or string($additionalNodes)!=''">
      <xsl:element name="{$tagName}">
        <xsl:attribute name="json:Array">true</xsl:attribute>
        <xsl:if test="string($value)!=''">
          <value>
            <xsl:choose>
              <xsl:when test="number($maxLength)&lt;string-length($value)">
                <xsl:value-of select ="substring($value,1,$maxLength)"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select ="$value"/>
              </xsl:otherwise>
            </xsl:choose>
          </value>
        </xsl:if>
        <xsl:if test="string($additionalNodes)!=''">
          <xsl:copy-of select="msxsl:node-set($additionalNodes)"/>
        </xsl:if>
        <xsl:if test="$addMarketplace=1">
          <marketplace_id>
            <xsl:value-of select="$MARKETPLACEID"/>
          </marketplace_id>
        </xsl:if>
        <xsl:if test="$addLanguage=1">
          <language_tag>
            <xsl:apply-templates select="." mode="language_tag"/>
          </language_tag>
        </xsl:if>
      </xsl:element>
    </xsl:if>
  </xsl:template>

  <xsl:template match="q:InventoryVirtualResult" mode="purchasable_offer">
    <xsl:variable name="offer">
      <xsl:call-template name="ArrayItem">
        <xsl:with-param name="tagName">purchasable_offer</xsl:with-param>
        <xsl:with-param name="addLanguage">0</xsl:with-param>
        <xsl:with-param name="addMarketplace">0</xsl:with-param>
        <xsl:with-param name="additionalNodes">
          <audience>ALL</audience>
          <currency>
            <xsl:value-of select="q:CurrentPricing/q:SRP/q:Units"/>
          </currency>
          <our_price json:Array="true">
            <schedule json:Array="true">
              <value_with_tax>
                <xsl:apply-templates select="." mode="CurrentPricing-SRP"/>
              </value_with_tax>
            </schedule>
          </our_price>
        </xsl:with-param>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="offerNodeSet" select="msxsl:node-set($offer)"/>
    <xsl:if test="$offerNodeSet/purchasable_offer/our_price/schedule/value_with_tax&gt;0">
      <xsl:copy-of select="$offerNodeSet/*"/>
    </xsl:if>
  </xsl:template>

  <xsl:template match="q:InventoryVirtualResult" mode="fulfillment_availability">
    <xsl:call-template name="ArrayItem">
      <xsl:with-param name="tagName">fulfillment_availability</xsl:with-param>
      <xsl:with-param name="addLanguage">0</xsl:with-param>
      <xsl:with-param name="addMarketplace">0</xsl:with-param>
      <xsl:with-param name="additionalNodes">
        <fulfillment_channel_code>
          <xsl:apply-templates select="." mode="fulfillment_channel_code"/>
        </fulfillment_channel_code>
        <quantity>
          <xsl:apply-templates select="." mode="qty"/>
        </quantity>
        <lead_time_to_ship_max_days>
          <xsl:variable name="leadTime">
            <xsl:call-template name="min">
              <xsl:with-param name="elements" select="q:Details/q:Detail[q:Available/q:Value &gt; 0]/q:LeadTimeInDays[number(.) &gt;=0]"/>
            </xsl:call-template>
          </xsl:variable>
          <xsl:choose>
            <xsl:when test="$leadTime != ''">
              <xsl:value-of select="$leadTime"/>
            </xsl:when>
            <xsl:otherwise>0</xsl:otherwise>
          </xsl:choose>
        </lead_time_to_ship_max_days>
        <!--<restock_date></restock_date>-->
        <!--<is_inventory_available></is_inventory_available>-->
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>

  <xsl:template match="q:InventoryVirtualResult" mode="fulfillment_channel_code">
    <xsl:choose>
      <xsl:when test="q:Details/q:Detail[q:Location/q:Code = '13']/q:Available/q:Value &gt; 0 or q:Details/q:Detail[q:Location/q:Code = '12']/q:Available/q:Value &gt; 0 or q:Details/q:Detail[q:Location/q:Code = 'FBA']/q:Available/q:Value &gt; 0">AMAZON_NA</xsl:when>
      <xsl:otherwise>DEFAULT</xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="q:InventoryVirtualResult" mode="merchant_shipping_group_name">
    <xsl:variable name="vendorId" select="translate(q:Vendor/q:Id, 'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ')"/>

    <xsl:variable name="shipTmplCategoryKey" select="concat('SHPTMPLT_',q:Catalog/q:Category/q:Id)"/>
    <xsl:variable name="shipTmplNodeSet" select="msxsl:node-set($SHPTMPLT2)"/>

    <xsl:choose>
      <xsl:when test="normalize-space(q:Properties/q:InventoryVirtualResultBase.Property[q:Code = 'SHPTMPLT']/q:Value)!=''">
        <xsl:value-of select="normalize-space(q:Properties/q:InventoryVirtualResultBase.Property[q:Code = 'SHPTMPLT']/q:Value)"/>
      </xsl:when>

      <xsl:when test="string($shipTmplNodeSet/array/a[@key=$shipTmplCategoryKey]/@value)!=''">
        <xsl:value-of select="string($shipTmplNodeSet/array/a[@key=$shipTmplCategoryKey]/@value)"/>
      </xsl:when>

      <xsl:when test="normalize-space($SHPTMPLT)!=''">
        <xsl:value-of select="$SHPTMPLT"/>
      </xsl:when>

      <xsl:when test="normalize-space(q:Summary/q:SKU) = 'E80E3KGB'">Ground Only</xsl:when>
      <xsl:when test="normalize-space(q:Summary/q:SKU) = 'M80D3KGB'">Ground Only</xsl:when>
      <xsl:when test="normalize-space(q:Summary/q:SKU) = 'P65E1EPB'">Ground Only</xsl:when>
      <xsl:when test="normalize-space(q:Summary/q:SKU) = 'UN65MU850DFXZAK'">Ground Only</xsl:when>
      <xsl:when test="normalize-space(q:Summary/q:SKU) = '65UH7650KGB'">Ground Only</xsl:when>
      <xsl:when test="normalize-space(q:Summary/q:SKU) = 'UN65MU800DFXZAK'">Ground Only</xsl:when>
      <xsl:when test="normalize-space(q:Summary/q:SKU) = 'UN65MU700DFXZAK'">Ground Only</xsl:when>
      <xsl:when test="normalize-space(q:Summary/q:SKU) = 'UN75MU800DFXZAK'">Ground Only</xsl:when>
      <xsl:when test="normalize-space(q:Summary/q:SKU) = 'UN60JS700DFXZAK'">Ground Only</xsl:when>
      <xsl:when test="normalize-space(q:Summary/q:SKU) = 'UN75KS900DFXZAK'">Ground Only</xsl:when>
      <xsl:when test="normalize-space(q:Summary/q:SKU) = 'UN85JU645DFXZAK'">Ground Only</xsl:when>
      <xsl:when test="normalize-space(q:Summary/q:SKU) = '75UJ657AKGB'">Ground Only</xsl:when>
      <xsl:when test="normalize-space(q:Summary/q:SKU) = 'M65D0EPB'">Ground Only</xsl:when>
      <xsl:when test="normalize-space(q:Summary/q:SKU) = 'M65E0EPB'">Ground Only</xsl:when>
      <xsl:when test="normalize-space(q:Summary/q:SKU) = 'P75C1EGB'">Ground Only</xsl:when>
      <xsl:when test="translate(normalize-space(q:Properties/q:InventoryVirtualResultBase.Property[q:Code = 'PREMSHIP']/q:Value), 'yesno', 'YESNO') = 'YES' and $vendorId = '1ABC3203-EE9D-4F83-B597-7898A6C937FD'">Segue Regional Prime</xsl:when>
      <xsl:when test="translate(normalize-space(q:Properties/q:InventoryVirtualResultBase.Property[q:Code = 'PREMSHIP']/q:Value), 'yesno','YESNO') = 'YES'">Regional Prime (Ground + Air)</xsl:when>
      <xsl:when test="normalize-space(q:Freight/q:FreightCollectionOption)='ChannelAccount'"></xsl:when>
      <xsl:when test="q:Freight/q:Rates/q:FreightRateDetails.FreightRate[q:Included = 'true' and (q:ServiceLevel = 'Truck')]">Ground Only</xsl:when>
      <xsl:when test="q:Freight/q:Rates/q:FreightRateDetails.FreightRate[q:Included = 'true' and (q:ServiceLevel = 'Ground')]">Free ground shipping</xsl:when>
      <xsl:when test="q:Freight/q:Rates/q:FreightRateDetails.FreightRate[q:Included = 'true' and (q:ServiceLevel = 'ThreeDay')]">Free expedited shipping</xsl:when>
      <xsl:when test="q:Freight/q:Rates/q:FreightRateDetails.FreightRate[q:Included = 'true' and (q:ServiceLevel = 'TwoDay')]">Free two-day shipping</xsl:when>
      <xsl:when test="q:Freight/q:Rates/q:FreightRateDetails.FreightRate[q:Included = 'true' and (q:ServiceLevel = 'OneDay')]">Free one-day shipping</xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="q:InventoryVirtualResult" mode="RESTORED">
    <xsl:apply-templates select="." mode="isCategoryCondition">
      <xsl:with-param name="xml" select="$RESTORED"/>
      <xsl:with-param name="prefix" select="'RESTORED'"/>
    </xsl:apply-templates>
  </xsl:template>

  <xsl:template match="q:InventoryVirtualResult" mode="RESTOREDPREM">
    <xsl:apply-templates select="." mode="isCategoryCondition">
      <xsl:with-param name="xml" select="$RESTOREDPREM"/>
      <xsl:with-param name="prefix" select="'RESTOREDPREM'"/>
    </xsl:apply-templates>
  </xsl:template>
 
  <xsl:template match="q:InventoryVirtualResult" mode="certRfbCat">
    <xsl:variable name="id" select="translate(q:Catalog/q:Category/q:Id,'abcdef','ABCDEF')"/>
    <xsl:choose>
      <xsl:when test="contains($CERTREFURB_CAT_UPR,'ALL')">1</xsl:when>
      <xsl:when test="contains($CERTREFURB_CAT_UPR,$id)">1</xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="q:InventoryVirtualResult" mode="certRfbBrnd">
    <xsl:variable name="brandId" select="translate(q:Catalog/q:Brand/q:Id,'abcdef','ABCDEF')"/>
    <xsl:variable name="manId" select="translate(q:Catalog/q:Manufacturer/q:Id,'abcdef','ABCDEF')"/>
    <xsl:choose>
      <xsl:when test="contains($CERTREFURB_BRND_UPR,'ALL')">1</xsl:when>
      <xsl:when test="contains($CERTREFURB_BRND_UPR,$brandId) or contains($CERTREFURB_BRND_UPR,$manId)">1</xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="q:InventoryVirtualResult" mode="condition">
    <xsl:variable name="cond">
      <xsl:apply-templates select="." mode="COND"/>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="string($cond)!=''">
		  <xsl:choose>
			  <xsl:when test="$cond = 'New'">new_new</xsl:when>
			  <xsl:when test="$cond = 'NewOpenBox'">new_open_box</xsl:when>
			  <xsl:when test="$cond = 'UsedLikeNew'">used_like_new</xsl:when>
			  <xsl:when test="$cond = 'UsedVeryGood'">used_very_good</xsl:when>
			  <xsl:when test="$cond = 'UsedGood'">used_good</xsl:when>
			  <xsl:when test="$cond = 'UsedAcceptable'">used_acceptable</xsl:when>
			  <xsl:when test="$cond = 'CollectibleLikeNew'">collectible_like_new</xsl:when>
			  <xsl:when test="$cond = 'CollectibleVeryGood'">collectible_very_good</xsl:when>
			  <xsl:when test="$cond = 'CollectibleGood'">collectible_good</xsl:when>
			  <xsl:when test="$cond = 'CollectibleAcceptable'">collectible_acceptable</xsl:when>
			  <xsl:otherwise>
				  <xsl:value-of select="$cond"/>
			  </xsl:otherwise>
		  </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="certRfbCat">
          <xsl:apply-templates select="." mode="certRfbCat"/>
        </xsl:variable>
        <xsl:variable name="certRfbBrnd">
          <xsl:apply-templates select="." mode="certRfbBrnd"/>
        </xsl:variable>
        <xsl:variable name="restored">
          <xsl:apply-templates select="." mode="RESTORED"/>
        </xsl:variable>
        <xsl:variable name="restoredPrem">
          <xsl:apply-templates select="." mode="RESTOREDPREM"/>
        </xsl:variable>
        <xsl:choose>
          <xsl:when test="$restored = 1 and q:Summary/q:Condition/q:Code = 'REFURBMAN'">new_new</xsl:when>
          <xsl:when test="$restored = 1 and q:Summary/q:Condition/q:Code = 'REFURB3RD'">used_good</xsl:when>
          <xsl:when test="$restored = 1 and q:Summary/q:Condition/q:Code = 'SCRADDNT'">used_acceptable</xsl:when>

          <xsl:when test="$restoredPrem = 1 and q:Summary/q:Condition/q:Code = 'REFURBMAN'">new_new</xsl:when>
          <xsl:when test="$restoredPrem = 1 and q:Summary/q:Condition/q:Code = 'REFURB3RD'">used_good</xsl:when>
          <xsl:when test="$restoredPrem = 1 and q:Summary/q:Condition/q:Code = 'SCRADDNT'">used_acceptable</xsl:when>

          <xsl:when test="$certRfbCat = 1 and $certRfbBrnd = 1 and q:Summary/q:Condition/q:Code = 'REFURBMAN'">new_new</xsl:when>
          <xsl:when test="$certRfbCat = 1 and $certRfbBrnd = 1 and q:Summary/q:Condition/q:Code = 'REFURB3RD'">used_good</xsl:when>
          <xsl:when test="$certRfbCat = 1 and $certRfbBrnd = 1 and q:Summary/q:Condition/q:Code = 'SCRADDNT'">used_acceptable</xsl:when>

          <xsl:when test="q:Summary/q:Condition/q:Code = 'NOB'">used_like_new</xsl:when>
          <xsl:when test="q:Summary/q:Condition/q:Code = 'USEDGD'">used_good</xsl:when>
          <xsl:when test="q:Summary/q:Condition/q:Code = 'NEW'">new_new</xsl:when>
          <xsl:otherwise></xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!--New, Used, Collectible, Refurbished, or Club.-->
  <xsl:template match="BuyboxRequest" mode="condition">

    <xsl:choose>
      <xsl:when test="starts-with(Condition,'new')">New</xsl:when>
      <xsl:when test="starts-with(Condition,'used')">Used</xsl:when>
      <xsl:when test="starts-with(Condition,'collectible')">Collectible</xsl:when>
      <xsl:when test="starts-with(Condition,'refurbished')">Refurbished</xsl:when>
      <xsl:when test="starts-with(Condition,'club')">Club</xsl:when>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="BuyboxRequest" mode="subcondition">
    <!--
  New, Mint, Very Good, Good, Acceptable, Poor, Club, OEM, Warranty, Refurbished Warranty, Refurbished, Open Box, or Other
  -->
    <xsl:variable name="condition">
      <xsl:apply-templates select="." mode="condition"/>
    </xsl:variable>
    <xsl:variable name="suffix" select="substring(Condition,string-length($condition)+2)"/>
	  <xsl:value-of select="$suffix"/>
    <!--<xsl:choose>
      <xsl:when test="$suffix='new'">New</xsl:when>
      <xsl:when test="$suffix='mint'">Mint</xsl:when>
      <xsl:when test="$suffix='like_new'">Mint</xsl:when>
      <xsl:when test="$suffix='very_good'">VeryGood</xsl:when>
      <xsl:when test="$suffix='good'">Good</xsl:when>
      <xsl:when test="$suffix='acceptable'">Acceptable</xsl:when>
      <xsl:when test="$suffix='poor'">Poor</xsl:when>
      <xsl:when test="$suffix='club'">Club</xsl:when>
      <xsl:when test="$suffix='oem'">OEM</xsl:when>
      <xsl:when test="$suffix='warranty'">Warranty</xsl:when>
      <xsl:when test="$suffix='refurbished_warranty'">RefurbishedWarranty</xsl:when>
      <xsl:when test="$suffix='refurbished'">Refurbished</xsl:when>
      <xsl:when test="$suffix='open_box'">OpenBox</xsl:when>
    </xsl:choose>-->
  </xsl:template>

  <xsl:template name="min">
    <xsl:param name="elements"/>
    <xsl:for-each select="$elements">
      <xsl:sort select="." data-type="number" order="ascending"/>
      <xsl:if test="position()=1">
        <xsl:value-of select="."/>
      </xsl:if>
    </xsl:for-each>
  </xsl:template>

</xsl:stylesheet>
