<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                xmlns:q="http://schemas.quipt.com/api"
                xmlns:a="http://schemas.microsoft.com/2003/10/Serialization/Arrays"
                xmlns:msxsl="urn:schemas-microsoft-com:xslt" exclude-result-prefixes="msxsl xsi xsd">
	<xsl:output method="xml" indent="yes"/>
	<xsl:param name="REPRICER"/>
	<xsl:template match="q:InventoryVirtualResult" mode="REPRICER">
		<!-- output 1 to export price -->
		<xsl:choose>
			<xsl:when test="translate(normalize-space(q:Properties/q:InventoryVirtualResultBase.Property[q:Code='REPRICER']/q:Value), 'on', 'ON') = 'ON'">0</xsl:when>
			<xsl:when test="q:Properties/q:InventoryVirtualResultBase.Property[q:Code='REPRICER'] and translate(normalize-space(q:Properties/q:InventoryVirtualResultBase.Property[q:Code='REPRICER']/q:Value), 'on', 'ON') != 'ON'">1</xsl:when>
			<xsl:when test="string($REPRICER)='ON'">0</xsl:when>
			<xsl:otherwise>1</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="InventoryVirtualResult" mode="REPRICER">
		<!-- output 1 to export price -->
		<xsl:choose>
			<xsl:when test="translate(normalize-space(Properties/InventoryVirtualResultBase.Property[Code='REPRICER']/Value), 'on', 'ON') = 'ON'">0</xsl:when>
			<xsl:when test="Properties/InventoryVirtualResultBase.Property[Code='REPRICER'] and translate(normalize-space(Properties/InventoryVirtualResultBase.Property[Code='REPRICER']/Value), 'on', 'ON') != 'ON'">1</xsl:when>
			<xsl:when test="string($REPRICER)='ON'">0</xsl:when>
			<xsl:otherwise>1</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:param name="COND"/>
	<xsl:template match="q:InventoryVirtualResult" mode="COND">
		<xsl:variable name="condKeyCategory" select="concat('COND_',q:Summary/q:Condition/q:Code,'_',q:Catalog/q:Category/q:Id)"/>
		<xsl:variable name="condKey" select="concat('COND_',q:Summary/q:Condition/q:Code)"/>
		<xsl:variable name="condNodeSet" select="msxsl:node-set($COND)"/>

		<xsl:choose>
			<xsl:when test="normalize-space(q:Properties/q:InventoryVirtualResultBase.Property[q:Code = 'COND']/q:Value)!=''">
				<xsl:value-of select="normalize-space(q:Properties/q:InventoryVirtualResultBase.Property[q:Code = 'COND']/q:Value)"/>
			</xsl:when>
			<xsl:when test="string($condNodeSet/array/a[@key=$condKeyCategory]/@value)!=''">
				<xsl:value-of select="string($condNodeSet/array/a[@key=$condKeyCategory]/@value)"/>
			</xsl:when>
			<xsl:when test="string($condNodeSet/array/a[@key=$condKey]/@value)!=''">
				<xsl:value-of select="string($condNodeSet/array/a[@key=$condKey]/@value)"/>
			</xsl:when>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="q:InventoryVirtualResult" mode="isCategoryCondition">
		<!-- Check if inventory item matches specified xml parameter.
 Xml parameter. If value=False - exclude. For prefix='RESTORED' expected xml format:
    <array>
    <a key="RESTORED_{MANID}_{CATID}" value="True"/>
    <a key="RESTORED_{MANID}_ALL" value="True"/>
    <a key="RESTORED_ALL_{CATID}" value="True"/>
</array>
-->
		<xsl:param name="xml"/>
		<xsl:param name="prefix"/>
		<xsl:variable name="brandId" select="q:Catalog/q:Brand/q:Id"/>
		<xsl:variable name="manId" select="q:Catalog/q:Manufacturer/q:Id"/>
		<xsl:variable name="keys">
			<key>
				<xsl:value-of select="concat($prefix,'_ALL_ALL')"/>
			</key>
			<key>
				<xsl:value-of select="concat($prefix,'_','ALL','_',q:Catalog/q:Category/q:Id)"/>
			</key>
			<key>
				<xsl:value-of select="concat($prefix,'_',$brandId,'_',q:Catalog/q:Category/q:Id)"/>
			</key>
			<key>
				<xsl:value-of select="concat($prefix,'_',$brandId,'_','ALL')"/>
			</key>
			<key>
				<xsl:value-of select="concat($prefix,'_',$manId,'_',q:Catalog/q:Category/q:Id)"/>
			</key>
			<key>
				<xsl:value-of select="concat($prefix,'_',$manId,'_','ALL')"/>
			</key>
		</xsl:variable>
		<xsl:variable name="xmlNodeSet" select="msxsl:node-set($xml)"/>

		<xsl:variable name="keyNodeSet" select="msxsl:node-set($keys)"/>
		<xsl:variable name="match">
			<xsl:for-each select="$keyNodeSet/key">
				<xsl:variable name="key" select="."/>
				<xsl:if test="$xmlNodeSet/array/a[@key=$key and @value='True']">1</xsl:if>
			</xsl:for-each>
		</xsl:variable>
		<xsl:if test="$match!=''">1</xsl:if>
	</xsl:template>

	<!-- Calculate Quantity using QTYBFR xslt parameter or Threshold if QTYBFR is not set. -->
	<xsl:param name="QTYBFR_VAL"/>
	<xsl:param name="QTYBFR_UNT"/>
	<xsl:template match="q:InventoryVirtualResult" mode="qty">
		<xsl:call-template name="calculate-quantity">
			<xsl:with-param name="available" select="number(q:Available/q:Value)"/>
			<xsl:with-param name="defaultThreshold" select="number(q:Threshold/q:Value)"/>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="InventoryVirtualResult" mode="qty">
		<xsl:call-template name="calculate-quantity">
			<xsl:with-param name="available" select="number(Available/Value)"/>
			<xsl:with-param name="defaultThreshold" select="number(Threshold/Value)"/>
		</xsl:call-template>
	</xsl:template>

	<xsl:template name="calculate-threshold">
		<xsl:param name="defaultThreshold"/>
		<xsl:param name="available"/>
		<xsl:variable name="threshold">
			<xsl:choose>
				<xsl:when test="number($QTYBFR_VAL)=0 and string($QTYBFR_UNT)='%'">
					<xsl:value-of select="0"/>
				</xsl:when>
				<xsl:when test="number($QTYBFR_VAL)&gt;0 and string($QTYBFR_UNT)='%'">
					<xsl:value-of select="$available * number($QTYBFR_VAL) div 100"/>
				</xsl:when>
				<xsl:when test="number($QTYBFR_VAL)&gt;=0 and string($QTYBFR_UNT)='EA'">
					<xsl:value-of select="number($QTYBFR_VAL)"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="number($defaultThreshold)"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:value-of select="format-number($threshold,'0')" />
	</xsl:template>

	<xsl:template name="calculate-quantity">
		<xsl:param name="available"/>
		<xsl:param name="defaultThreshold"/>
		<xsl:variable name="threshold">
			<xsl:call-template name="calculate-threshold">
				<xsl:with-param name="available" select="$available"/>
				<xsl:with-param name="defaultThreshold" select="$defaultThreshold"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="$available &gt; $threshold">
				<xsl:value-of select="format-number($available - $threshold,'0')" />
			</xsl:when>
			<xsl:otherwise>0</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!-- Template to collect items not filtered out by catalog mapper Filter template. 
  It is used by all catalog feeds to post rejections for filtered out items. -->
	<xsl:template match= "/q:SyncInventoryVirtualResults" mode="shouldExport">
		<q:SyncExportedItems>
			<q:Errors>
				<xsl:for-each select="q:Items/q:InventoryVirtualResult">
					<xsl:variable name="error">
						<xsl:apply-templates select="." mode="ExcludeReason"/>
					</xsl:variable>
					<xsl:if test="normalize-space($error)!=''">
						<q:Error>
							<q:Id>
								<xsl:value-of select="q:Id"/>
							</q:Id>
							<q:Message>
								<xsl:value-of select="$error"/>
							</q:Message>
						</q:Error>
					</xsl:if>
				</xsl:for-each>
			</q:Errors>
			<q:Ids xmlns:a="http://schemas.microsoft.com/2003/10/Serialization/Arrays">
				<xsl:for-each select="q:Items/q:InventoryVirtualResult">
					<xsl:variable name="shouldExport">
						<xsl:apply-templates select="." mode="Filter"/>
					</xsl:variable>
					<xsl:if test="normalize-space($shouldExport)!=''">
						<a:guid>
							<xsl:value-of select="q:Id"/>
						</a:guid>
					</xsl:if>
				</xsl:for-each>
			</q:Ids>
		</q:SyncExportedItems>
	</xsl:template>

	<!-- to use ExcludeReason functionality this template should be overriden in the service transform -->
	<xsl:template match="*" mode="ExcludeReason"></xsl:template>
	<!-- to use Filter functionality this template should be overriden in the service transform -->
	<xsl:template match="*" mode="Filter">
		<xsl:variable name="exclude">
			<xsl:apply-templates select="." mode="ExcludeReason"/>
		</xsl:variable>
		<xsl:if test="normalize-space($exclude)=''">1</xsl:if>
	</xsl:template>

	<xsl:template match="q:InventoryVirtualResult" mode="features">
		<xsl:call-template name="features">
			<xsl:with-param name="conditionCode" select="q:Summary/q:Condition/q:Code"/>
			<xsl:with-param name="nodes" select="q:Catalog/q:Features"/>
		</xsl:call-template>
	</xsl:template>

	<!-- 
  Build features from input xml. Input 'nodes' - any xml, each node is a separate feature. 
  Template prepends features by 'This Certified Refurbished product...' feature for 
  -->
	<xsl:template name="features">
		<xsl:param name="nodes"/>
		<xsl:param name="conditionCode"/>
		<xsl:variable name="featuresNodeSet" select="msxsl:node-set($nodes)"/>
		<xsl:variable name="substr" select="'Certified Refurbished product is tested'"/>
		<xsl:variable name="first" select="'This Certified Refurbished product is tested and certified to look and work like new. The refurbishing process includes functionality testing, basic cleaning, inspection, and repackaging. The product ships with all relevant accessories, a minimum 90-day warranty, and may arrive in a generic box.'"/>
		<!--<xsl:if test="string($conditionCode)='REFURBMAN'">
			<a:string>
				<xsl:value-of select="$first"/>
			</a:string>
		</xsl:if>-->
		<xsl:for-each select="$featuresNodeSet/*">
			<xsl:if test="not(contains(normalize-space(.),$substr))">
				<a:string>
					<xsl:value-of select="normalize-space(.)"/>
				</a:string>
			</xsl:if>
		</xsl:for-each>
	</xsl:template>

	<xsl:template match="q:InventoryVirtualResult" mode="Title">
		<xsl:param name="maxLength">10000</xsl:param>
		<xsl:param name="appendCond">1</xsl:param>
		<xsl:param name="overrideCond"/>
		<xsl:variable name="value">
			<xsl:value-of select="q:Catalog/q:Title"/>
			<xsl:variable name="suffix">
				<xsl:choose>
					<xsl:when test="string($overrideCond)!=''">
						<xsl:value-of select="$overrideCond"/>
					</xsl:when>
					<xsl:when test="string(q:Catalog/q:Condition/q:Code) = 'NEW'"></xsl:when>
					<xsl:when test="string(q:Catalog/q:Condition/q:Code) = 'REFURBMAN'">Certified Refurbished</xsl:when>
					<xsl:when test="string(q:Catalog/q:Condition/q:Code) = 'REFURB3RD'">Refurbished</xsl:when>
					<xsl:when test="string(q:Catalog/q:Condition/q:Code) = 'SCRADDNT'">Scratch and Dent</xsl:when>
					<xsl:when test="string(q:Catalog/q:Condition/q:Code) = 'NOB'">New Open Box</xsl:when>
					<xsl:when test="string(q:Catalog/q:Condition/q:Code) = 'USEDGD'">Used - Good</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="q:Catalog/q:Condition/q:Name"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			<xsl:if test="$appendCond='1' and string($suffix)!='' and not(contains(q:Catalog/q:Title,$suffix))">
				<xsl:text> (</xsl:text>
				<xsl:value-of select="$suffix"/>
				<xsl:text>)</xsl:text>
			</xsl:if>
		</xsl:variable>
		<xsl:value-of select="substring(normalize-space($value),1,$maxLength)"/>
	</xsl:template>

	<xsl:template match="InventoryVirtualResult" mode="Title">
		<xsl:variable name="value">
			<xsl:value-of select="Catalog/Title"/>
			<xsl:variable name="suffix">
				<xsl:choose>
					<xsl:when test="string(Catalog/Condition/Code) = 'NEW'"></xsl:when>
					<xsl:when test="string(Catalog/Condition/Code) = 'REFURBMAN'">Certified Refurbished</xsl:when>
					<xsl:when test="string(Catalog/Condition/Code) = 'REFURB3RD'">Refurbished</xsl:when>
					<xsl:when test="string(Catalog/Condition/Code) = 'SCRADDNT'">Scratch and Dent</xsl:when>
					<xsl:when test="string(Catalog/Condition/Code) = 'NOB'">New Open Box</xsl:when>
					<xsl:when test="string(Catalog/Condition/Code) = 'USEDGD'">Used - Good</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="Catalog/Condition/Name"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			<xsl:if test="string($suffix)!='' and not(contains(Catalog/Title,$suffix))">
				<xsl:text> (</xsl:text>
				<xsl:value-of select="$suffix"/>
				<xsl:text>)</xsl:text>
			</xsl:if>
		</xsl:variable>
		<xsl:value-of select="normalize-space($value)"/>
	</xsl:template>


	<xsl:template match="q:InventoryVirtualResult" mode="AltTitle">
		<xsl:variable name="value">
			<xsl:value-of select="q:Catalog/q:AltTitle"/>
			<xsl:variable name="suffix">
				<xsl:choose>
					<xsl:when test="string(q:Catalog/q:Condition/q:Code) = 'NEW'"></xsl:when>
					<xsl:when test="string(q:Catalog/q:Condition/q:Code) = 'REFURBMAN'">Certified Refurbished</xsl:when>
					<xsl:when test="string(q:Catalog/q:Condition/q:Code) = 'REFURB3RD'">Refurbished</xsl:when>
					<xsl:when test="string(q:Catalog/q:Condition/q:Code) = 'SCRADDNT'">Scratch and Dent</xsl:when>
					<xsl:when test="string(q:Catalog/q:Condition/q:Code) = 'NOB'">New Open Box</xsl:when>
					<xsl:when test="string(q:Catalog/q:Condition/q:Code) = 'USEDGD'">Used - Good</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="q:Catalog/q:Condition/q:Name"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			<xsl:if test="string($suffix)!='' and not(contains(q:Catalog/q:AltTitle,$suffix))">
				<xsl:text> (</xsl:text>
				<xsl:value-of select="$suffix"/>
				<xsl:text>)</xsl:text>
			</xsl:if>
		</xsl:variable>
		<xsl:value-of select="normalize-space($value)"/>
	</xsl:template>

	<xsl:template match="InventoryVirtualResult" mode="CurrentPricing-SRP">
		<xsl:call-template name="pricing-value">
			<xsl:with-param name="value" select="CurrentPricing/SRP/Value"/>
		</xsl:call-template>
	</xsl:template>

	<xsl:template match="q:InventoryVirtualResult" mode="CurrentPricing-SRP">
		<xsl:call-template name="pricing-value">
			<xsl:with-param name="value" select="q:CurrentPricing/q:SRP/q:Value"/>
		</xsl:call-template>
	</xsl:template>

	<xsl:template match="InventoryVirtualResult" mode="CurrentPricing-SRP-Units">
		<xsl:call-template name="amount-units">
			<xsl:with-param name="amount" select="CurrentPricing/SRP"/>
		</xsl:call-template>
	</xsl:template>

	<xsl:template match="q:InventoryVirtualResult" mode="CurrentPricing-SRP-Units">
		<xsl:call-template name="amount-units">
			<xsl:with-param name="amount" select="q:CurrentPricing/q:SRP"/>
		</xsl:call-template>
	</xsl:template>

	<xsl:template match="InventoryVirtualResult" mode="CurrentPricing-Price">
		<xsl:call-template name="pricing-value">
			<xsl:with-param name="value" select="CurrentPricing/Price/Value"/>
		</xsl:call-template>
	</xsl:template>

	<xsl:template match="q:InventoryVirtualResult" mode="CurrentPricing-Price">
		<xsl:call-template name="pricing-value">
			<xsl:with-param name="value" select="q:CurrentPricing/q:Price/q:Value"/>
		</xsl:call-template>
	</xsl:template>

	<xsl:template match="InventoryVirtualResult" mode="Pricing-Price">
		<xsl:call-template name="pricing-value">
			<xsl:with-param name="value" select="Pricing/Price/Value"/>
		</xsl:call-template>
	</xsl:template>

	<xsl:template match="q:InventoryVirtualResult" mode="Pricing-Price">
		<xsl:call-template name="pricing-value">
			<xsl:with-param name="value" select="q:Pricing/q:Price/q:Value"/>
		</xsl:call-template>
	</xsl:template>

	<xsl:template match="InventoryVirtualResult" mode="Pricing-SRP">
		<xsl:call-template name="pricing-value">
			<xsl:with-param name="value" select="Pricing/SRP/Value"/>
		</xsl:call-template>
	</xsl:template>

	<xsl:template match="q:InventoryVirtualResult" mode="Pricing-SRP">
		<xsl:call-template name="pricing-value">
			<xsl:with-param name="value" select="q:Pricing/q:SRP/q:Value"/>
		</xsl:call-template>
	</xsl:template>

	<xsl:template match="InventoryVirtualResult" mode="Pricing-SRP-Units">
		<xsl:call-template name="amount-units">
			<xsl:with-param name="amount" select="Pricing/SRP"/>
		</xsl:call-template>
	</xsl:template>

	<xsl:template match="q:InventoryVirtualResult" mode="Pricing-SRP-Units">
		<xsl:call-template name="amount-units">
			<xsl:with-param name="amount" select="q:Pricing/q:SRP"/>
		</xsl:call-template>
	</xsl:template>

	<xsl:template name="pricing-value">
		<xsl:param name="value"/>
		<xsl:choose>
			<xsl:when test="string(number($value)) != 'NaN'">
				<xsl:value-of select="format-number($value, '#######0.00')"/>
			</xsl:when>
			<xsl:otherwise></xsl:otherwise>
			<!--Send no pricing, this will like cause error.-->
		</xsl:choose>
	</xsl:template>

	<xsl:template name="amount-units">
		<xsl:param name="amount"/>
		<xsl:choose>
			<xsl:when test="$amount/Units">
				<xsl:value-of select="$amount/Units"/>
			</xsl:when>
			<xsl:when test="$amount/q:Units">
				<xsl:value-of select="$amount/q:Units"/>
			</xsl:when>
			<xsl:otherwise>USD</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:variable name="image-http">http://api.getquipt.com/v2/image/</xsl:variable>
	<xsl:variable name="image-https">https://api.getquipt.com/v2/image/</xsl:variable>
	<xsl:template match="q:Catalog" mode="images">
		<xsl:param name="https">0</xsl:param>
		<xsl:param name="size">3000</xsl:param>
		<xsl:if test="q:PrimaryImage/q:Id != ''">
			<image type="primary">
				<xsl:choose>
					<xsl:when test="$https = 1">
						<xsl:value-of select="$image-https"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$image-http"/>
					</xsl:otherwise>
				</xsl:choose>
				<xsl:value-of select="q:PrimaryImage/q:Id"/>
				<xsl:text>/</xsl:text>
				<xsl:value-of select="$size"/>
				<xsl:text>/</xsl:text>
				<xsl:text>0.jpg</xsl:text>
			</image>
		</xsl:if>
		<xsl:for-each select="q:AdditionalImages/q:Asset[q:Id != '']">
			<image type="secondary">
				<xsl:choose>
					<xsl:when test="$https = 1">
						<xsl:value-of select="$image-https"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$image-http"/>
					</xsl:otherwise>
				</xsl:choose>
				<xsl:value-of select="q:Id"/>
				<xsl:text>/</xsl:text>
				<xsl:value-of select="$size"/>
				<xsl:text>/</xsl:text>
				<xsl:value-of select="position()"/>
				<xsl:text>.jpg</xsl:text>
			</image>
		</xsl:for-each>
		<xsl:if test="q:PrimaryImage/q:Id != ''">
			<image-500 type="primary">
				<xsl:choose>
					<xsl:when test="$https = 1">
						<xsl:value-of select="$image-https"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$image-http"/>
					</xsl:otherwise>
				</xsl:choose>
				<xsl:value-of select="q:PrimaryImage/q:Id"/>
				<xsl:text>/500/</xsl:text>
				<xsl:text>0x500.jpg</xsl:text>
			</image-500>
		</xsl:if>
		<xsl:if test="q:PrimaryImage/q:Id != ''">
			<image-100 type="primary">
				<xsl:choose>
					<xsl:when test="$https = 1">
						<xsl:value-of select="$image-https"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$image-http"/>
					</xsl:otherwise>
				</xsl:choose>
				<xsl:value-of select="q:PrimaryImage/q:Id"/>
				<xsl:text>/100/</xsl:text>
				<xsl:text>0x100.jpg</xsl:text>
			</image-100>
		</xsl:if>
	</xsl:template>

	<xsl:template match="q:Catalog" mode="swatch-images">
		<xsl:param name="https">0</xsl:param>
		<xsl:for-each select="q:SwatchImages/q:SwatchAsset[q:Id != '']">
			<image type="{q:AttributeCode}">
				<xsl:choose>
					<xsl:when test="$https = 1">
						<xsl:value-of select="$image-https"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$image-http"/>
					</xsl:otherwise>
				</xsl:choose>
				<xsl:value-of select="q:Id"/>
				<xsl:text>/3000/</xsl:text>
				<xsl:value-of select="position()"/>
				<xsl:text>.jpg</xsl:text>
			</image>
		</xsl:for-each>
	</xsl:template>
	<xsl:template name ="to-inches">
		<xsl:param name="units"/>
		<xsl:param name="value"/>
		<xsl:choose>
			<xsl:when test="$units='IN'">
				<xsl:value-of select="format-number($value,'0.##')"/>
			</xsl:when>
			<xsl:when test="$units='CM'">
				<xsl:value-of select="format-number($value * 0.393701,'0.##')"/>
			</xsl:when>
		</xsl:choose>
	</xsl:template>
	<xsl:template name ="to-cm">
		<xsl:param name="units"/>
		<xsl:param name="value"/>
		<xsl:param name="removeDecimals"/>
		<xsl:variable name="converted">
			<xsl:choose>
				<xsl:when test="$units='IN'">
					<xsl:value-of select="$value * 2.54"/>
				</xsl:when>
				<xsl:when test="$units='CM'">
					<xsl:value-of select="$value"/>
				</xsl:when>
			</xsl:choose>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="$removeDecimals='1'">
				<xsl:value-of select="format-number($converted,'0')"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="format-number($converted,'0.##')"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template name ="to-kg">
		<xsl:param name="units"/>
		<xsl:param name="value"/>
		<xsl:choose>
			<xsl:when test="$units='Pounds'">
				<xsl:value-of select="format-number($value * 0.453592,'0.##')"/>
			</xsl:when>
			<xsl:when test="$units='Grams'">
				<xsl:value-of select="format-number($value * 0.001,'0.##')"/>
			</xsl:when>
			<xsl:when test="$units='Kilograms'">
				<xsl:value-of select="format-number($value,'0.##')"/>
			</xsl:when>
		</xsl:choose>
	</xsl:template>
	<xsl:template name ="to-lbs">
		<xsl:param name="units"/>
		<xsl:param name="value"/>
		<xsl:choose>
			<xsl:when test="$units='Pounds'">
				<xsl:value-of select="format-number($value,'0.##')"/>
			</xsl:when>
			<xsl:when test="$units='Grams'">
				<xsl:value-of select="format-number($value * 0.002204623,'0.##')"/>
			</xsl:when>
			<xsl:when test="$units='Kilograms'">
				<xsl:value-of select="format-number($value * 2.204623,'0.##')"/>
			</xsl:when>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="q:InventoryVirtualResult" mode="warranty-days">
		<xsl:variable name="warranty-duration" select="number(normalize-space(translate(q:Catalog/q:Warranty/q:Duration,translate(q:Catalog/q:Warranty/q:Duration,'0123456789',''),'')))"/>
		<!-- attempt convert warranty to days -->
		<xsl:choose>
			<xsl:when test="q:Catalog/q:Warranty/q:Provider != 'Manufacturer' and q:Catalog/q:Warranty/q:Provider != 'Distributor'">0</xsl:when>
			<xsl:when test="$warranty-duration &gt; 0 and contains(translate(q:Catalog/q:Warranty/q:Duration,'d','D'),'D')">
				<xsl:value-of select="format-number($warranty-duration, '0')"/>
			</xsl:when>
			<xsl:when test="$warranty-duration &gt; 0 and contains(translate(q:Catalog/q:Warranty/q:Duration,'m','M'),'M')">
				<xsl:value-of select="$warranty-duration * 30"/>
			</xsl:when>
			<xsl:when test="$warranty-duration &gt; 0 and contains(translate(q:Catalog/q:Warranty/q:Duration,'y','Y'),'Y')">
				<xsl:value-of select="$warranty-duration * 365"/>
			</xsl:when>
			<!-- if number only. Assume days. May need adjust later -->
			<xsl:when test="$warranty-duration &gt; 0">
				<xsl:value-of select="$warranty-duration"/>
			</xsl:when>
			<xsl:otherwise>0</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!-- Convert length to a target unit: mm, cm, m, in, mi -->
	<xsl:template name="length-to">
		<xsl:param name="input"/>
		<xsl:param name="toUnit"/>

		<!-- normalize input -->
		<xsl:variable name="clean" select="normalize-space($input)"/>

		<!-- find where digits stop and unit begins -->
		<xsl:variable name="idx">
			<xsl:call-template name="find-letter-index">
				<xsl:with-param name="text" select="$clean"/>
				<xsl:with-param name="pos"  select="1"/>
			</xsl:call-template>
		</xsl:variable>

		<!-- numeric part -->
		<xsl:variable name="num"
		  select="number(substring($clean, 1, $idx - 1))"/>

		<!-- unit part (lowercased) -->
		<xsl:variable name="unit"
		  select="translate(normalize-space(substring($clean, $idx)),
                      'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
                      'abcdefghijklmnopqrstuvwxyz')" />

		<!-- STEP 1: convert INPUT to MILLIMETERS -->
		<xsl:variable name="mm">
			<xsl:choose>

				<!-- millimeters -->
				<xsl:when test="$unit='mm' or $unit='millimeter' or $unit='millimeters'">
					<xsl:value-of select="$num" />
				</xsl:when>

				<!-- centimeters -->
				<xsl:when test="$unit='cm' or $unit='centimeter' or $unit='centimeters'">
					<xsl:value-of select="$num * 10" />
				</xsl:when>

				<!-- meters -->
				<xsl:when test="$unit='m' or $unit='meter' or $unit='meters'">
					<xsl:value-of select="$num * 1000" />
				</xsl:when>

				<!-- inches -->
				<xsl:when test="$unit='in' or $unit='inch' or $unit='inches'">
					<xsl:value-of select="$num * 25.4" />
				</xsl:when>

				<!-- miles -->
				<xsl:when test="$unit='mi' or $unit='mile' or $unit='miles'">
					<xsl:value-of select="$num * 1609344" />
				</xsl:when>

				<!-- fallback: treat as millimeters -->
				<xsl:otherwise>
					<xsl:value-of select="$num" />
				</xsl:otherwise>

			</xsl:choose>
		</xsl:variable>

		<!-- lowercase target unit -->
		<xsl:variable name="target"
		  select="translate($toUnit,
                      'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
                      'abcdefghijklmnopqrstuvwxyz')" />

		<!-- STEP 2: convert MILLIMETERS to TARGET -->
		<xsl:variable name="result">
			<xsl:choose>

				<!-- mm -->
				<xsl:when test="$target='mm'">
					<xsl:value-of select="$mm" />
				</xsl:when>

				<!-- cm -->
				<xsl:when test="$target='cm'">
					<xsl:value-of select="$mm div 10" />
				</xsl:when>

				<!-- m -->
				<xsl:when test="$target='m'">
					<xsl:value-of select="$mm div 1000" />
				</xsl:when>

				<!-- in -->
				<xsl:when test="$target='in'">
					<xsl:value-of select="$mm div 25.4" />
				</xsl:when>

				<!-- mi -->
				<xsl:when test="$target='mi'">
					<xsl:value-of select="$mm div 1609344" />
				</xsl:when>

				<!-- fallback: return mm -->
				<xsl:otherwise>
					<xsl:value-of select="$mm" />
				</xsl:otherwise>

			</xsl:choose>
		</xsl:variable>

		<!-- Final numeric output -->
		<xsl:value-of select="format-number($result, '0.####')" />
	</xsl:template>

	<!-- Convert storage size to a target unit: b, kb, mb, gb, tb -->
	<xsl:template name="storage-to">
		<xsl:param name="input"/>
		<xsl:param name="toUnit"/>

		<!-- Normalize -->
		<xsl:variable name="clean" select="normalize-space($input)"/>

		<!-- Find split index (digits → unit) -->
		<xsl:variable name="idx">
			<xsl:call-template name="find-letter-index">
				<xsl:with-param name="text" select="$clean"/>
				<xsl:with-param name="pos"  select="1"/>
			</xsl:call-template>
		</xsl:variable>

		<!-- numeric amount -->
		<xsl:variable name="num"
		  select="number(substring($clean, 1, $idx - 1))"/>

		<!-- extracted unit (lowercased) -->
		<xsl:variable name="unit"
		  select="translate(normalize-space(substring($clean, $idx)),
                      'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
                      'abcdefghijklmnopqrstuvwxyz')" />

		<!-- STEP 1: convert input TO BYTES -->
		<xsl:variable name="bytes">
			<xsl:choose>

				<!-- bytes -->
				<xsl:when test="$unit='b' or $unit='byte' or $unit='bytes'">
					<xsl:value-of select="$num" />
				</xsl:when>

				<!-- KB -->
				<xsl:when test="$unit='kb' or $unit='kilobyte' or $unit='kilobytes'">
					<xsl:value-of select="$num * 1024" />
				</xsl:when>

				<!-- MB -->
				<xsl:when test="$unit='mb' or $unit='megabyte' or $unit='megabytes'">
					<xsl:value-of select="$num * 1048576" />
				</xsl:when>

				<!-- GB -->
				<xsl:when test="$unit='gb' or $unit='gigabyte' or $unit='gigabytes'">
					<xsl:value-of select="$num * 1073741824" />
				</xsl:when>

				<!-- TB -->
				<xsl:when test="$unit='tb' or $unit='terabyte' or $unit='terabytes'">
					<xsl:value-of select="$num * 1099511627776" />
				</xsl:when>

				<!-- fallback = treat as bytes -->
				<xsl:otherwise>
					<xsl:value-of select="$num" />
				</xsl:otherwise>

			</xsl:choose>
		</xsl:variable>

		<!-- lowercase the target -->
		<xsl:variable name="target"
		  select="translate($toUnit,
                      'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
                      'abcdefghijklmnopqrstuvwxyz')" />

		<!-- STEP 2: convert bytes TO TARGET UNIT -->
		<xsl:variable name="result">
			<xsl:choose>

				<!-- bytes -->
				<xsl:when test="$target='b'">
					<xsl:value-of select="$bytes" />
				</xsl:when>

				<!-- KB -->
				<xsl:when test="$target='kb'">
					<xsl:value-of select="$bytes div 1024" />
				</xsl:when>

				<!-- MB -->
				<xsl:when test="$target='mb'">
					<xsl:value-of select="$bytes div 1048576" />
				</xsl:when>

				<!-- GB -->
				<xsl:when test="$target='gb'">
					<xsl:value-of select="$bytes div 1073741824" />
				</xsl:when>

				<!-- TB -->
				<xsl:when test="$target='tb'">
					<xsl:value-of select="$bytes div 1099511627776" />
				</xsl:when>

				<!-- fallback → return bytes -->
				<xsl:otherwise>
					<xsl:value-of select="$bytes" />
				</xsl:otherwise>

			</xsl:choose>
		</xsl:variable>

		<!-- Final output -->
		<xsl:value-of select="format-number($result, '0.####')" />
	</xsl:template>

	<!-- Convert weight to a target unit: mg, g, oz, lb, kg -->
	<xsl:template name="weight-to">
		<xsl:param name="input"/>
		<xsl:param name="toUnit"/>

		<!-- normalize input -->
		<xsl:variable name="clean" select="normalize-space($input)"/>

		<!-- find where numeric part ends -->
		<xsl:variable name="idx">
			<xsl:call-template name="find-letter-index">
				<xsl:with-param name="text" select="$clean"/>
				<xsl:with-param name="pos"  select="1"/>
			</xsl:call-template>
		</xsl:variable>

		<!-- numeric part -->
		<xsl:variable name="num"
		  select="number(substring($clean, 1, $idx - 1))"/>

		<!-- unit part (lowercase) -->
		<xsl:variable name="unit"
		  select="translate(normalize-space(substring($clean, $idx)),
                      'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
                      'abcdefghijklmnopqrstuvwxyz')" />

		<!-- STEP 1: convert INPUT to GRAMS -->
		<xsl:variable name="grams">
			<xsl:choose>

				<!-- milligrams -->
				<xsl:when test="$unit='mg' or $unit='milligram' or $unit='milligrams'">
					<xsl:value-of select="$num div 1000" />
					<!-- mg → g -->
				</xsl:when>

				<!-- grams -->
				<xsl:when test="$unit='g' or $unit='gram' or $unit='grams'">
					<xsl:value-of select="$num" />
				</xsl:when>

				<!-- ounces -->
				<xsl:when test="$unit='oz' or $unit='ounce' or $unit='ounces'">
					<xsl:value-of select="$num * 28.3495" />
					<!-- oz → g -->
				</xsl:when>

				<!-- pounds -->
				<xsl:when test="$unit='lb' or $unit='lbs' or $unit='pound' or $unit='pounds'">
					<xsl:value-of select="$num * 453.59237" />
					<!-- lb → g -->
				</xsl:when>

				<!-- kilograms -->
				<xsl:when test="$unit='kg' or $unit='kilogram' or $unit='kilograms'">
					<xsl:value-of select="$num * 1000" />
					<!-- kg → g -->
				</xsl:when>

				<!-- fallback: treat as grams -->
				<xsl:otherwise>
					<xsl:value-of select="$num" />
				</xsl:otherwise>

			</xsl:choose>
		</xsl:variable>

		<!-- lowercase target -->
		<xsl:variable name="target"
		  select="translate($toUnit,
                      'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
                      'abcdefghijklmnopqrstuvwxyz')" />

		<!-- STEP 2: convert GRAMS to TARGET -->
		<xsl:variable name="result">
			<xsl:choose>

				<!-- milligrams -->
				<xsl:when test="$target='mg'">
					<xsl:value-of select="$grams * 1000" />
				</xsl:when>

				<!-- grams -->
				<xsl:when test="$target='g'">
					<xsl:value-of select="$grams" />
				</xsl:when>

				<!-- ounces -->
				<xsl:when test="$target='oz'">
					<xsl:value-of select="$grams div 28.3495" />
				</xsl:when>

				<!-- pounds -->
				<xsl:when test="$target='lb'">
					<xsl:value-of select="$grams div 453.59237" />
				</xsl:when>

				<!-- kilograms -->
				<xsl:when test="$target='kg'">
					<xsl:value-of select="$grams div 1000" />
				</xsl:when>

				<!-- fallback: return grams -->
				<xsl:otherwise>
					<xsl:value-of select="$grams" />
				</xsl:otherwise>

			</xsl:choose>
		</xsl:variable>

		<!-- Final numeric output -->
		<xsl:value-of select="format-number($result, '0.####')" />
	</xsl:template>

	<!-- Convert time to a target unit: ms, s, m, h, d -->
	<xsl:template name="time-to">
		<xsl:param name="input"/>
		<xsl:param name="toUnit"/>

		<!-- normalize input -->
		<xsl:variable name="clean" select="normalize-space($input)"/>

		<!-- find where numeric part ends and unit begins -->
		<xsl:variable name="idx">
			<xsl:call-template name="find-letter-index">
				<xsl:with-param name="text" select="$clean"/>
				<xsl:with-param name="pos"  select="1"/>
			</xsl:call-template>
		</xsl:variable>

		<!-- numeric part -->
		<xsl:variable name="num"
		  select="number(substring($clean, 1, $idx - 1))"/>

		<!-- unit part (lowercased) -->
		<xsl:variable name="unit"
		  select="translate(normalize-space(substring($clean, $idx)),
                      'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
                      'abcdefghijklmnopqrstuvwxyz')" />

		<!-- STEP 1: convert INPUT to MILLISECONDS -->
		<xsl:variable name="ms">
			<xsl:choose>

				<!-- milliseconds -->
				<xsl:when test="$unit='ms' or $unit='msec' or $unit='millisecond' or $unit='milliseconds'">
					<xsl:value-of select="$num" />
				</xsl:when>

				<!-- seconds -->
				<xsl:when test="$unit='s' or $unit='sec' or $unit='second' or $unit='seconds'">
					<xsl:value-of select="$num * 1000" />
				</xsl:when>

				<!-- minutes -->
				<xsl:when test="$unit='m' or $unit='min' or $unit='minute' or $unit='minutes'">
					<xsl:value-of select="$num * 60000" />
					<!-- 60 * 1000 -->
				</xsl:when>

				<!-- hours -->
				<xsl:when test="$unit='h' or $unit='hr' or $unit='hour' or $unit='hours'">
					<xsl:value-of select="$num * 3600000" />
					<!-- 60*60*1000 -->
				</xsl:when>

				<!-- days -->
				<xsl:when test="$unit='d' or $unit='day' or $unit='days'">
					<xsl:value-of select="$num * 86400000" />
					<!-- 24*60*60*1000 -->
				</xsl:when>

				<!-- fallback: treat as milliseconds -->
				<xsl:otherwise>
					<xsl:value-of select="$num" />
				</xsl:otherwise>

			</xsl:choose>
		</xsl:variable>

		<!-- lowercase target unit -->
		<xsl:variable name="target"
		  select="translate($toUnit,
                      'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
                      'abcdefghijklmnopqrstuvwxyz')" />

		<!-- STEP 2: convert MILLISECONDS to TARGET -->
		<xsl:variable name="result">
			<xsl:choose>

				<!-- ms -->
				<xsl:when test="$target='ms'">
					<xsl:value-of select="$ms" />
				</xsl:when>

				<!-- seconds -->
				<xsl:when test="$target='s'">
					<xsl:value-of select="$ms div 1000" />
				</xsl:when>

				<!-- minutes -->
				<xsl:when test="$target='m'">
					<xsl:value-of select="$ms div 60000" />
				</xsl:when>

				<!-- hours -->
				<xsl:when test="$target='h'">
					<xsl:value-of select="$ms div 3600000" />
				</xsl:when>

				<!-- days -->
				<xsl:when test="$target='d'">
					<xsl:value-of select="$ms div 86400000" />
				</xsl:when>

				<!-- fallback: return ms -->
				<xsl:otherwise>
					<xsl:value-of select="$ms" />
				</xsl:otherwise>

			</xsl:choose>
		</xsl:variable>

		<!-- Final numeric output -->
		<xsl:value-of select="format-number($result, '0.####')" />
	</xsl:template>

	<!-- Convert time to a target unit: ghz, mhz, khz, hz -->
	<xsl:template name="frequency-to">
		<xsl:param name="input"/>
		<xsl:param name="toUnit"/>

		<!-- normalize input -->
		<xsl:variable name="clean" select="normalize-space($input)"/>

		<!-- find where numeric part ends and unit begins -->
		<xsl:variable name="idx">
			<xsl:call-template name="find-letter-index">
				<xsl:with-param name="text" select="$clean"/>
				<xsl:with-param name="pos"  select="1"/>
			</xsl:call-template>
		</xsl:variable>

		<!-- numeric part -->
		<xsl:variable name="num"
		  select="number(substring($clean, 1, $idx - 1))"/>

		<!-- unit part (lowercased) -->
		<xsl:variable name="unit"
		  select="translate(normalize-space(substring($clean, $idx)),
                      'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
                      'abcdefghijklmnopqrstuvwxyz')" />

		<!-- STEP 1: convert INPUT to HZ -->
		<xsl:variable name="ms">
			<xsl:choose>
				<xsl:when test="$num = 0">
					<xsl:text>0</xsl:text>
				</xsl:when>

				<!-- megahertz -->
				<xsl:when test="$unit='mhz' or $unit='megahertz'">
					<xsl:value-of select="$num * 1000000" />
				</xsl:when>

				<!-- gigahertz -->
				<xsl:when test="$unit='ghz' or $unit='gigahertz'">
					<xsl:value-of select="$num * 1000000000" />
				</xsl:when>

				<!-- kilohertz -->
				<xsl:when test="$unit='khz' or $unit='kilohertz'">
					<xsl:value-of select="$num * 1000" />
				</xsl:when>

				<!-- fallback: treat as hertz -->
				<xsl:otherwise>
					<xsl:value-of select="$num" />
				</xsl:otherwise>

			</xsl:choose>
		</xsl:variable>

		<!-- lowercase target unit -->
		<xsl:variable name="target"
		  select="translate($toUnit,
                      'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
                      'abcdefghijklmnopqrstuvwxyz')" />

		<!-- STEP 2: convert HZ to TARGET -->
		<xsl:variable name="result">
			<xsl:choose>

				<!-- mhz -->
				<xsl:when test="$target='mhz'">
					<xsl:value-of select="$ms div 1000000" />
				</xsl:when>

				<!-- ghz -->
				<xsl:when test="$target='ghz'">
					<xsl:value-of select="$ms div 1000000000" />
				</xsl:when>

				<!-- khz -->
				<xsl:when test="$target='khz'">
					<xsl:value-of select="$ms div 60000" />
				</xsl:when>

				<!-- fallback: return hz -->
				<xsl:otherwise>
					<xsl:value-of select="$ms" />
				</xsl:otherwise>

			</xsl:choose>
		</xsl:variable>

		<!-- Final numeric output -->
		<xsl:value-of select="format-number($result, '0.####')" />
	</xsl:template>

	<!-- Convert time to a target unit: px, mpx -->
	<xsl:template name="pixel-to">
		<xsl:param name="input"/>
		<xsl:param name="toUnit"/>

		<!-- normalize input -->
		<xsl:variable name="clean" select="normalize-space($input)"/>

		<!-- find where numeric part ends and unit begins -->
		<xsl:variable name="idx">
			<xsl:call-template name="find-letter-index">
				<xsl:with-param name="text" select="$clean"/>
				<xsl:with-param name="pos"  select="1"/>
			</xsl:call-template>
		</xsl:variable>

		<!-- numeric part -->
		<xsl:variable name="num"
		  select="number(substring($clean, 1, $idx - 1))"/>

		<!-- unit part (lowercased) -->
		<xsl:variable name="unit"
		  select="translate(normalize-space(substring($clean, $idx)),
                      'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
                      'abcdefghijklmnopqrstuvwxyz')" />

		<!-- STEP 1: convert INPUT to pixels -->
		<xsl:variable name="ms">
			<xsl:choose>
				<xsl:when test="$num = 0">
					<xsl:text>0</xsl:text>
				</xsl:when>

				<!-- megapixels -->
				<xsl:when test="$unit='mpx' or $unit='megapixel' or $unit='megapixels'">
					<xsl:value-of select="$num * 1000000" />
				</xsl:when>

				<!-- fallback: treat as pixels -->
				<xsl:otherwise>
					<xsl:value-of select="$num" />
				</xsl:otherwise>

			</xsl:choose>
		</xsl:variable>

		<!-- lowercase target unit -->
		<xsl:variable name="target"
		  select="translate($toUnit,
                      'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
                      'abcdefghijklmnopqrstuvwxyz')" />

		<!-- STEP 2: convert pixels to TARGET -->
		<xsl:variable name="result">
			<xsl:choose>

				<!-- megapixels -->
				<xsl:when test="$target='mpx'">
					<xsl:value-of select="$ms div 1000000" />
				</xsl:when>

				<!-- fallback: return pixels -->
				<xsl:otherwise>
					<xsl:value-of select="$ms" />
				</xsl:otherwise>

			</xsl:choose>
		</xsl:variable>

		<!-- Final numeric output -->
		<xsl:value-of select="format-number($result, '0.####')" />
	</xsl:template>

	<!-- Convert time to a target unit: ah, mah -->
	<xsl:template name="ampere-hours-to">
		<xsl:param name="input"/>
		<xsl:param name="toUnit"/>

		<!-- normalize input -->
		<xsl:variable name="clean" select="normalize-space($input)"/>

		<!-- find where numeric part ends and unit begins -->
		<xsl:variable name="idx">
			<xsl:call-template name="find-letter-index">
				<xsl:with-param name="text" select="$clean"/>
				<xsl:with-param name="pos"  select="1"/>
			</xsl:call-template>
		</xsl:variable>

		<!-- numeric part -->
		<xsl:variable name="num"
		  select="number(substring($clean, 1, $idx - 1))"/>

		<!-- unit part (lowercased) -->
		<xsl:variable name="unit"
		  select="translate(normalize-space(substring($clean, $idx)),
                      'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
                      'abcdefghijklmnopqrstuvwxyz')" />

		<!-- STEP 1: convert INPUT to ampere-hours -->
		<xsl:variable name="ms">
			<xsl:choose>
				<xsl:when test="$num = 0">
					<xsl:text>0</xsl:text>
				</xsl:when>

				<!-- milliampere-hours -->
				<xsl:when test="$unit='mah' or $unit='milliampere-hours'">
					<xsl:value-of select="$num div 1000" />
				</xsl:when>

				<!-- fallback: treat as ampere-hours -->
				<xsl:otherwise>
					<xsl:value-of select="$num" />
				</xsl:otherwise>

			</xsl:choose>
		</xsl:variable>

		<!-- lowercase target unit -->
		<xsl:variable name="target"
		  select="translate($toUnit,
                      'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
                      'abcdefghijklmnopqrstuvwxyz')" />

		<!-- STEP 2: convert ampere-hours to TARGET -->
		<xsl:variable name="result">
			<xsl:choose>

				<!-- milliampere-hours -->
				<xsl:when test="$target='mah'">
					<xsl:value-of select="$ms * 1000" />
				</xsl:when>

				<!-- fallback: return ampere-hours -->
				<xsl:otherwise>
					<xsl:value-of select="$ms" />
				</xsl:otherwise>

			</xsl:choose>
		</xsl:variable>

		<!-- Final numeric output -->
		<xsl:value-of select="format-number($result, '0.####')" />
	</xsl:template>

	<xsl:template name="num-remove-suffix">
		<xsl:param name="input"/>

		<!-- normalize input -->
		<xsl:variable name="clean" select="normalize-space($input)"/>

		<!-- find where numeric part ends and unit begins -->
		<xsl:variable name="idx">
			<xsl:call-template name="find-letter-index">
				<xsl:with-param name="text" select="$clean"/>
				<xsl:with-param name="pos"  select="1"/>
			</xsl:call-template>
		</xsl:variable>

		<!-- numeric part -->
		<xsl:variable name="num"
		  select="number(substring($clean, 1, $idx - 1))"/>

		<xsl:value-of select="format-number($num, '0.####')"/>
	</xsl:template>

	<!-- Finds index of first non-digit and non-dot -->
	<xsl:template name="find-letter-index">
		<xsl:param name="text"/>
		<xsl:param name="pos"/>

		<xsl:choose>
			<xsl:when test="$pos > string-length($text)">
				<xsl:value-of select="$pos"/>
			</xsl:when>

			<!-- check if char at pos is NOT 0-9 or '.' -->
			<xsl:when test="not(translate(substring($text,$pos,1),'0123456789.',''))">
				<xsl:call-template name="find-letter-index">
					<xsl:with-param name="text" select="$text"/>
					<xsl:with-param name="pos" select="$pos + 1"/>
				</xsl:call-template>
			</xsl:when>

			<!-- found first unit character -->
			<xsl:otherwise>
				<xsl:value-of select="$pos"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
</xsl:stylesheet>
