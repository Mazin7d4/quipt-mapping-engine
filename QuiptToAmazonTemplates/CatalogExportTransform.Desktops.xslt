<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" exclude-result-prefixes="msxsl q i a str" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:q="http://schemas.quipt.com/api" xmlns:i="http://www.w3.org/2001/XMLSchema-instance" xmlns:a="http://schemas.microsoft.com/2003/10/Serialization/Arrays" xmlns:str="http://exslt.org/strings" xmlns:json="http://james.newtonking.com/projects/json">
  <!-- All these xsl:stylesheet attributes should be defined in the 'axsl:stylesheet' element of CatalogExportTransform.Builder.xslt file. 
    For proper rendering all xsl:stylesheet attributes changes should be copied to 'axsl:stylesheet' element of Builder template. -->

	<xsl:import href="str.tab.template.xslt" />
	<xsl:import href="str.utility.template.xslt" />
	<xsl:import href="inventory.shared.xslt" />
	<xsl:import href="InventoryCatalogExportTransform.json.Shared.xslt" />

	<xsl:output method="xml" indent="yes" />

	<xsl:param name="BypassFilter">1</xsl:param>
	<xsl:param name="Type">XML</xsl:param>
	<xsl:param name="Encoding">UTF-8</xsl:param>
	<xsl:param name="MARKETPLACEID">MKTID</xsl:param>
	<xsl:param name="MERCHANTID">MERID</xsl:param>
	<!-- path to this transform file. Needed to extract all mapped product types from current transform by category id only when no real inventory virtual result item provided. -->
	<xsl:param name="CurrentTransformPath" />


	<xsl:variable name="separator" select="'&#x9;'" />
	<xsl:variable name="newline" select="'&#xD;&#xA;'" />

	<xsl:param name="Mode" />

	<!-- TEST TEMPLATES BEGIN -->
	<!-- These templates are for master template testing only and can be removed.
  More specific templates will be appended by builder, so these dummy templates should not affect transformation results. -->
	<xsl:template match="*" mode="ItemType">DummyItemType</xsl:template>
	<xsl:template match="*" mode="ProductType">DummyProductType</xsl:template>
	<xsl:template match="*" mode="Filter">dummy filter (do not filter if template is not empty and produces any text)</xsl:template>

	<xsl:template match="*" mode="language_tag">dummy_en_US</xsl:template>

	<!-- TEST TEMPLATES END -->

	<xsl:template match="/q:SyncInventoryVirtualResults">
		<xsl:apply-templates select="." mode="shouldExport" />
	</xsl:template>

	<xsl:template match="/q:ArrayOfInventoryVirtualResult">
		<xsl:choose>
			<xsl:when test="$Mode='GetCategoryId'">
				<xsl:variable name="shouldExport">
					<xsl:apply-templates select="q:InventoryVirtualResult[1]" mode="Filter" />
				</xsl:variable>
				<xsl:if test="(normalize-space($shouldExport)!='' or string(q:InventoryVirtualResult[1]/q:Summary/q:SKU)='')">
					<xsl:apply-templates select="q:InventoryVirtualResult[1]" mode="GetProductType" />
				</xsl:if>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="items">
					<xsl:apply-templates select="q:InventoryVirtualResult" />
				</xsl:variable>
				<xsl:variable name="itemsNodeSet" select="msxsl:node-set($items)" />
				<xsl:if test="$itemsNodeSet/messages">
					<Root>
						<header>
							<sellerId>
								<xsl:value-of select="$MERCHANTID" />
							</sellerId>
							<version>2.0</version>
							<issueLocale>
								<xsl:apply-templates select="q:InventoryVirtualResult[1]" mode="language_tag" />
							</issueLocale>
						</header>
						<xsl:copy-of select="$itemsNodeSet" />
					</Root>
				</xsl:if>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="q:InventoryVirtualResult" mode="GetProductType">
		<!-- Store additional data for troubleshooting. Only product types required. -->
		<GetConditionsRequest>
			<FeedId>
				<xsl:value-of select="q:Id" />
			</FeedId>
			<CategoryId>
				<xsl:value-of select="q:Catalog/q:Category/q:Id" />
			</CategoryId>
			<ProductTypes>
				<xsl:choose>
					<xsl:when test="normalize-space(q:SKU)!=''">
						<ProductType>
							<xsl:apply-templates select="." mode="ProductType" />
						</ProductType>
					</xsl:when>
					<xsl:otherwise>
						<!-- Load the XSLT file -->
						<xsl:variable name="stylesheet" select="document($CurrentTransformPath)//node()[@mode='ProductType' and @match='q:InventoryVirtualResult']" />
						<xsl:apply-templates select="$stylesheet" mode="parseProductTypes" />
					</xsl:otherwise>
				</xsl:choose>
			</ProductTypes>
		</GetConditionsRequest>
	</xsl:template>

	<!-- Match any element that has text content -->
	<xsl:template match="*" mode="text">
		<xsl:apply-templates select="text()" mode="parseProductTypes" />
		<xsl:apply-templates select="*" mode="parseProductTypes" />
	</xsl:template>

	<!-- Wrap all text values inside <a:string> -->
	<xsl:template match="text()[normalize-space()]" mode="parseProductTypes">
		<ProductType>
			<xsl:value-of select="." />
		</ProductType>
	</xsl:template>

	<xsl:template match="q:InventoryVirtualResult">
		<xsl:choose>
			<xsl:when test="normalize-space($BypassFilter) != ''">
				<xsl:apply-templates select="." mode="render">
					<xsl:with-param name="index" select="position()" />
				</xsl:apply-templates>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="shouldExport">
					<xsl:apply-templates select="." mode="Filter" />
				</xsl:variable>
				<xsl:variable name="excludeReason">
					<xsl:apply-templates select="." mode="ExcludeReason" />
				</xsl:variable>
				<xsl:if test="normalize-space($shouldExport)!='' and normalize-space($excludeReason)=''">
					<xsl:apply-templates select="." mode="render">
						<xsl:with-param name="index" select="position()" />
					</xsl:apply-templates>
				</xsl:if>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="q:InventoryVirtualResult" mode="ExcludeReason">

		<xsl:choose>
			<xsl:when test="$Mode='GetCategoryId'" />
			<xsl:otherwise>
				<xsl:variable name="condition">
					<xsl:apply-templates select="." mode="condition" />
				</xsl:variable>
				<xsl:if test="normalize-space($condition)=''">
					<xsl:text>Missing condition support for </xsl:text>
					<xsl:value-of select="q:Summary/q:Condition/q:Name" />
					<xsl:text>. If Certified Refurbished ensure you add brand and category to policy.</xsl:text>
				</xsl:if>
			</xsl:otherwise>
		</xsl:choose>

	</xsl:template>

	<xsl:template match="q:InventoryVirtualResult" mode="render">
		<xsl:param name="index" />

		<xsl:choose>
			<xsl:when test="$Mode='InvCat'">
				<xsl:apply-templates select="." mode="renderInvCat">
					<xsl:with-param name="index" select="$index" />
				</xsl:apply-templates>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates select="." mode="renderCat">
					<xsl:with-param name="index" select="$index" />
				</xsl:apply-templates>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="q:InventoryVirtualResult" mode="renderInvCat">
		<xsl:param name="index" />
		<xsl:variable name="images">
			<xsl:apply-templates select="q:Catalog" mode="images" />
		</xsl:variable>
		<xsl:variable name="image-frag" select="msxsl:node-set($images)" />

		<messages json:Array="true">
			<messageId json:Type="Integer">
				<xsl:value-of select="$index" />
			</messageId>
			<sku>
				<xsl:value-of select="normalize-space(q:Summary/q:SKU)" />
			</sku>
			<operationType>UPDATE</operationType>
			<productType>PRODUCT</productType>
			<requirements>LISTING_OFFER_ONLY</requirements>
			<attributes>
				<xsl:variable name="preMapped">
					<xsl:variable name="mapId">
						<xsl:choose>
							<xsl:when test="string-length(q:MapId) = 10 and substring(q:MapId, 1, 1) = 'B'">
								<value>
									<xsl:value-of select="q:MapId" />
								</value>
								<type>asin</type>
							</xsl:when>
							<xsl:when test="string-length(q:MapId) = 13">
								<value>
									<xsl:value-of select="q:MapId" />
								</value>
								<type>ean</type>
							</xsl:when>
							<xsl:when test="string-length(q:MapId) = 14">
								<value>
									<xsl:value-of select="q:MapId" />
								</value>
								<type>gtin</type>
							</xsl:when>
							<xsl:when test="string-length(q:MapId) = 12">
								<value>
									<xsl:value-of select="q:MapId" />
								</value>
								<type>upc</type>
							</xsl:when>
							<xsl:when test="string-length(q:MapId) = 17">
								<value>
									<xsl:value-of select="q:MapId" />
								</value>
								<type>isbn</type>
							</xsl:when>
						</xsl:choose>
					</xsl:variable>
					<xsl:variable name="mapIdNodeSet" select="msxsl:node-set($mapId)" />
					<xsl:variable name="asin">
						<xsl:if test="string($mapIdNodeSet/value)!='' and string($mapIdNodeSet/type)='asin'">
							<xsl:value-of select="$mapIdNodeSet/value" />
						</xsl:if>
					</xsl:variable>
					<xsl:variable name="product-id">
						<xsl:choose>
							<xsl:when test="string($mapIdNodeSet/value)!='' and string($mapIdNodeSet/type)!='asin'">
								<xsl:value-of select="$mapIdNodeSet/value" />
							</xsl:when>
							<xsl:when test="$asin = '' and normalize-space(q:Catalog/q:SKUs/q:SKU[q:Type='UPC']/q:Value) != ''">
								<xsl:value-of select="normalize-space(q:Catalog/q:SKUs/q:SKU[q:Type='UPC']/q:Value)" />
							</xsl:when>
						</xsl:choose>
					</xsl:variable>

					<xsl:call-template name="ArrayItem">
						<xsl:with-param name="tagName">externally_assigned_product_identifier</xsl:with-param>
						<xsl:with-param name="value" select="$product-id" />
						<xsl:with-param name="additionalNodes">
							<xsl:if test="$product-id != ''">
								<type>
									<xsl:choose>
										<!--<xsl:when test="string-length($product-id) = 10 and substring($product-id, 1, 1) = 'B'">ASIN</xsl:when>-->
										<xsl:when test="string-length($product-id) = 13">ean</xsl:when>
										<xsl:when test="string-length($product-id) = 14">gtin</xsl:when>
										<xsl:when test="string-length($product-id) = 17">isbn</xsl:when>
										<xsl:when test="string-length($product-id) = 12">upc</xsl:when>
										<xsl:otherwise>gtin</xsl:otherwise>
									</xsl:choose>
								</type>
							</xsl:if>
						</xsl:with-param>
						<xsl:with-param name="addLanguage">0</xsl:with-param>
					</xsl:call-template>

					<xsl:call-template name="ArrayItem">
						<xsl:with-param name="tagName">merchant_suggested_asin</xsl:with-param>
						<xsl:with-param name="value" select="$asin" />
						<xsl:with-param name="addLanguage">0</xsl:with-param>
					</xsl:call-template>
					<xsl:call-template name="ArrayItem">
						<xsl:with-param name="tagName">condition_type</xsl:with-param>
						<xsl:with-param name="value">
							<xsl:apply-templates select="." mode="condition" />
						</xsl:with-param>
						<xsl:with-param name="addLanguage">0</xsl:with-param>
						<xsl:with-param name="addMarketplace">0</xsl:with-param>
					</xsl:call-template>
					<xsl:apply-templates select="." mode="fulfillment_availability" />
					<xsl:apply-templates select="." mode="purchasable_offer" />
					<xsl:call-template name="ArrayItem">
						<xsl:with-param name="tagName">merchant_shipping_group</xsl:with-param>
						<xsl:with-param name="value">
							<xsl:apply-templates select="." mode="merchant_shipping_group_name" />
						</xsl:with-param>
						<xsl:with-param name="addLanguage">0</xsl:with-param>
					</xsl:call-template>
					<xsl:call-template name="ArrayItem">
						<xsl:with-param name="tagName">country_of_origin</xsl:with-param>
						<xsl:with-param name="addLanguage">0</xsl:with-param>
						<xsl:with-param name="value" select="normalize-space(q:Catalog/q:CountryOfOrigin/q:ISO)" />
					</xsl:call-template>
					<xsl:call-template name="ArrayItem">
						<xsl:with-param name="tagName">item_package_dimensions</xsl:with-param>
						<xsl:with-param name="additionalNodes">
							<xsl:variable name="dimensionsUnits">
								<xsl:choose>
									<xsl:when test="q:ShippingInfo/q:Dimensions/q:Units='IN'">inches</xsl:when>
									<xsl:when test="q:ShippingInfo/q:Dimensions/q:Units='CM'">centimeters</xsl:when>
								</xsl:choose>
							</xsl:variable>
							<length>
								<value json:Type="Float">
									<xsl:value-of select="format-number(q:ShippingInfo/q:Dimensions/q:Length,'0.##')" />
								</value>
								<unit>
									<xsl:value-of select="$dimensionsUnits" />
								</unit>
							</length>
							<width>
								<value json:Type="Float">
									<xsl:value-of select="format-number(q:ShippingInfo/q:Dimensions/q:Width,'0.##')" />
								</value>
								<unit>
									<xsl:value-of select="$dimensionsUnits" />
								</unit>
							</width>
							<height>
								<value json:Type="Float">
									<xsl:value-of select="format-number(q:ShippingInfo/q:Dimensions/q:Height,'0.##')" />
								</value>
								<unit>
									<xsl:value-of select="$dimensionsUnits" />
								</unit>
							</height>
						</xsl:with-param>
						<xsl:with-param name="addLanguage">0</xsl:with-param>
					</xsl:call-template>
					<xsl:call-template name="ArrayItem">
						<xsl:with-param name="tagName">item_package_weight</xsl:with-param>
						<xsl:with-param name="value">
							<xsl:value-of select="format-number(q:ShippingInfo/q:Weight/q:Value,'0.##')" />
						</xsl:with-param>
						<xsl:with-param name="additionalNodes">
							<unit>
								<xsl:choose>
									<xsl:when test="q:ShippingInfo/q:Weight/q:Units='Pounds'">pounds</xsl:when>
									<xsl:when test="q:ShippingInfo/q:Weight/q:Units='Grams'">grams</xsl:when>
									<xsl:when test="q:ShippingInfo/q:Weight/q:Units='Kilograms'">kilograms</xsl:when>
								</xsl:choose>
							</unit>
						</xsl:with-param>
						<xsl:with-param name="addLanguage">0</xsl:with-param>
					</xsl:call-template>
				</xsl:variable>
				<xsl:variable name="preMappedNodeSet" select="msxsl:node-set($preMapped)" />
				<xsl:variable name="attributes">
					<xsl:apply-templates select="." mode="render-attributes" />
				</xsl:variable>
				<xsl:variable name="attributesNodeSet" select="msxsl:node-set($attributes)" />
				<xsl:for-each select="$preMappedNodeSet/node()">
					<!-- allow to override pre-mapped attributes by catalog mapper -->
					<xsl:if test="not($attributesNodeSet/*[name()=name(current())])">
						<xsl:copy-of select="." />
					</xsl:if>
				</xsl:for-each>
				<!-- for invCat output premapped OFFER attributes only, do not copy the rest -->
				<!--<xsl:copy-of select="$attributesNodeSet/*"/>-->
			</attributes>
		</messages>
	</xsl:template>

	<xsl:template match="q:InventoryVirtualResult" mode="renderCat">
		<xsl:param name="index" />
		<xsl:variable name="images">
			<xsl:apply-templates select="q:Catalog" mode="images" />
		</xsl:variable>
		<xsl:variable name="image-frag" select="msxsl:node-set($images)" />

		<messages json:Array="true">
			<messageId json:Type="Integer">
				<xsl:value-of select="$index" />
			</messageId>
			<sku>
				<xsl:value-of select="normalize-space(q:Summary/q:SKU)" />
			</sku>
			<operationType>UPDATE</operationType>
			<productType>
				<xsl:apply-templates select="." mode="ProductType" />
			</productType>
			<requirements>LISTING</requirements>
			<attributes>
				<xsl:variable name="preMapped">
					<xsl:call-template name="ArrayItem">
						<xsl:with-param name="tagName">item_name</xsl:with-param>
						<xsl:with-param name="maxLength">200</xsl:with-param>
						<xsl:with-param name="value">
							<xsl:call-template name="title" />
						</xsl:with-param>
					</xsl:call-template>
					<xsl:call-template name="ArrayItem">
						<xsl:with-param name="tagName">brand</xsl:with-param>
						<xsl:with-param name="maxLength">100</xsl:with-param>
						<xsl:with-param name="value" select="normalize-space(q:Catalog/q:Brand/q:Name)" />
					</xsl:call-template>
					<xsl:call-template name="ArrayItem">
						<xsl:with-param name="tagName">manufacturer</xsl:with-param>
						<xsl:with-param name="maxLength">100</xsl:with-param>
						<xsl:with-param name="value" select="normalize-space(q:Catalog/q:Manufacturer/q:Name)" />
					</xsl:call-template>
					<xsl:call-template name="ArrayItem">
						<xsl:with-param name="tagName">item_type_keyword</xsl:with-param>
						<xsl:with-param name="maxLength">20090</xsl:with-param>
						<xsl:with-param name="addLanguage">0</xsl:with-param>
						<xsl:with-param name="value">
							<xsl:apply-templates select="." mode="ItemType" />
						</xsl:with-param>
					</xsl:call-template>
					<xsl:call-template name="ArrayItem">
						<xsl:with-param name="tagName">list_price</xsl:with-param>
						<xsl:with-param name="value">
							<xsl:value-of select="format-number(q:Catalog/q:Pricing/q:MSRP/q:Value, '#######0.00')" />
						</xsl:with-param>
						<xsl:with-param name="addLanguage">0</xsl:with-param>
						<xsl:with-param name="additionalNodes">
							<currency>
								<xsl:value-of select="q:Catalog/q:Pricing/q:MSRP/q:Units" />
							</currency>
						</xsl:with-param>
					</xsl:call-template>
					<xsl:variable name="mapId">
						<xsl:choose>
							<xsl:when test="string-length(q:MapId) = 10 and substring(q:MapId, 1, 1) = 'B'">
								<value>
									<xsl:value-of select="q:MapId" />
								</value>
								<type>asin</type>
							</xsl:when>
							<xsl:when test="string-length(q:MapId) = 13">
								<value>
									<xsl:value-of select="q:MapId" />
								</value>
								<type>ean</type>
							</xsl:when>
							<xsl:when test="string-length(q:MapId) = 14">
								<value>
									<xsl:value-of select="q:MapId" />
								</value>
								<type>gtin</type>
							</xsl:when>
							<xsl:when test="string-length(q:MapId) = 12">
								<value>
									<xsl:value-of select="q:MapId" />
								</value>
								<type>upc</type>
							</xsl:when>
							<xsl:when test="string-length(q:MapId) = 17">
								<value>
									<xsl:value-of select="q:MapId" />
								</value>
								<type>isbn</type>
							</xsl:when>
						</xsl:choose>
					</xsl:variable>
					<xsl:variable name="mapIdNodeSet" select="msxsl:node-set($mapId)" />
					<xsl:variable name="asin">
						<xsl:if test="string($mapIdNodeSet/value)!='' and string($mapIdNodeSet/type)='asin'">
							<xsl:value-of select="$mapIdNodeSet/value" />
						</xsl:if>
					</xsl:variable>
					<xsl:variable name="product-id">
						<xsl:choose>
							<xsl:when test="string($mapIdNodeSet/value)!='' and string($mapIdNodeSet/type)!='asin'">
								<xsl:value-of select="$mapIdNodeSet/value" />
							</xsl:when>
							<xsl:when test="$asin = '' and normalize-space(q:Catalog/q:SKUs/q:SKU[q:Type='UPC']/q:Value) != ''">
								<xsl:value-of select="normalize-space(q:Catalog/q:SKUs/q:SKU[q:Type='UPC']/q:Value)" />
							</xsl:when>
						</xsl:choose>
					</xsl:variable>
					
					<xsl:call-template name="ArrayItem">
						<xsl:with-param name="tagName">externally_assigned_product_identifier</xsl:with-param>
						<xsl:with-param name="value" select="$product-id" />
						<xsl:with-param name="additionalNodes">
							<xsl:if test="$product-id != ''">
								<type>
									<xsl:choose>
										<!--<xsl:when test="string-length($product-id) = 10 and substring($product-id, 1, 1) = 'B'">ASIN</xsl:when>-->
										<xsl:when test="string-length($product-id) = 13">ean</xsl:when>
										<xsl:when test="string-length($product-id) = 14">gtin</xsl:when>
										<xsl:when test="string-length($product-id) = 17">isbn</xsl:when>
										<xsl:when test="string-length($product-id) = 12">upc</xsl:when>
										<xsl:otherwise>gtin</xsl:otherwise>
									</xsl:choose>
								</type>
							</xsl:if>
						</xsl:with-param>
						<xsl:with-param name="addLanguage">0</xsl:with-param>
					</xsl:call-template>
					<xsl:call-template name="ArrayItem">
						<xsl:with-param name="tagName">merchant_suggested_asin</xsl:with-param>
						<xsl:with-param name="value" select="$asin" />
						<xsl:with-param name="addLanguage">0</xsl:with-param>
					</xsl:call-template>
					<xsl:call-template name="ArrayItem">
						<xsl:with-param name="tagName">condition_type</xsl:with-param>
						<xsl:with-param name="value">
							<xsl:apply-templates select="." mode="condition" />
						</xsl:with-param>
						<xsl:with-param name="addLanguage">0</xsl:with-param>
						<xsl:with-param name="addMarketplace">0</xsl:with-param>
					</xsl:call-template>
					<xsl:apply-templates select="." mode="fulfillment_availability" />
					<xsl:apply-templates select="." mode="purchasable_offer" />
					<xsl:call-template name="ArrayItem">
						<xsl:with-param name="tagName">merchant_shipping_group</xsl:with-param>
						<xsl:with-param name="value">
							<xsl:apply-templates select="." mode="merchant_shipping_group_name" />
						</xsl:with-param>
						<xsl:with-param name="addLanguage">0</xsl:with-param>
					</xsl:call-template>
					<!--<xsl:call-template name="ArrayItem">
          <xsl:with-param name="tagName">main_offer_image_locator</xsl:with-param>
          <xsl:with-param name="additionalNodes">
            <media_location>
              <xsl:value-of select="$image-frag/image[@type='primary']"/>
            </media_location>
          </xsl:with-param>
          <xsl:with-param name="addLanguage">0</xsl:with-param>
        </xsl:call-template>
        <xsl:call-template name="ArrayItem">
          <xsl:with-param name="tagName">other_offer_image_locator_1</xsl:with-param>
          <xsl:with-param name="additionalNodes">
            <media_location>
              <xsl:value-of select="$image-frag/image[@type='secondary'][1]"/>
            </media_location>
          </xsl:with-param>
          <xsl:with-param name="addLanguage">0</xsl:with-param>
        </xsl:call-template>
        <xsl:call-template name="ArrayItem">
          <xsl:with-param name="tagName">other_offer_image_locator_2</xsl:with-param>
          <xsl:with-param name="additionalNodes">
            <media_location>
              <xsl:value-of select="$image-frag/image[@type='secondary'][2]"/>
            </media_location>
          </xsl:with-param>
          <xsl:with-param name="addLanguage">0</xsl:with-param>
        </xsl:call-template>
        <xsl:call-template name="ArrayItem">
          <xsl:with-param name="tagName">other_offer_image_locator_3</xsl:with-param>
          <xsl:with-param name="additionalNodes">
            <media_location>
              <xsl:value-of select="$image-frag/image[@type='secondary'][3]"/>
            </media_location>
          </xsl:with-param>
          <xsl:with-param name="addLanguage">0</xsl:with-param>
        </xsl:call-template>
        <xsl:call-template name="ArrayItem">
          <xsl:with-param name="tagName">other_offer_image_locator_4</xsl:with-param>
          <xsl:with-param name="additionalNodes">
            <media_location>
              <xsl:value-of select="$image-frag/image[@type='secondary'][4]"/>
            </media_location>
          </xsl:with-param>
          <xsl:with-param name="addLanguage">0</xsl:with-param>
        </xsl:call-template>
        <xsl:call-template name="ArrayItem">
          <xsl:with-param name="tagName">other_offer_image_locator_5</xsl:with-param>
          <xsl:with-param name="additionalNodes">
            <media_location>
              <xsl:value-of select="$image-frag/image[@type='secondary'][5]"/>
            </media_location>
          </xsl:with-param>
          <xsl:with-param name="addLanguage">0</xsl:with-param>
        </xsl:call-template>-->
					<xsl:call-template name="ArrayItem">
						<xsl:with-param name="tagName">product_description</xsl:with-param>
						<xsl:with-param name="maxLength">9900</xsl:with-param>
						<xsl:with-param name="value" select="normalize-space(q:Catalog/q:Description)" />
					</xsl:call-template>
					<xsl:variable name="featuresResult">
						<xsl:call-template name="features">
							<xsl:with-param name="conditionCode" select="q:Catalog/q:Condition/q:Code" />
							<xsl:with-param name="nodes">
								<feature>
									<xsl:variable name="custom">
										<xsl:apply-templates select="." mode="bullet_point1" />
									</xsl:variable>
									<xsl:choose>
										<xsl:when test="normalize-space($custom)!=''">
											<xsl:value-of select="normalize-space($custom)" />
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="normalize-space(q:Catalog/q:Features/a:string[1])" />
										</xsl:otherwise>
									</xsl:choose>
								</feature>
								<feature>
									<xsl:variable name="custom">
										<xsl:apply-templates select="." mode="bullet_point2" />
									</xsl:variable>
									<xsl:choose>
										<xsl:when test="normalize-space($custom)!=''">
											<xsl:value-of select="normalize-space($custom)" />
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="normalize-space(q:Catalog/q:Features/a:string[2])" />
										</xsl:otherwise>
									</xsl:choose>
								</feature>
								<feature>
									<xsl:variable name="custom">
										<xsl:apply-templates select="." mode="bullet_point3" />
									</xsl:variable>
									<xsl:choose>
										<xsl:when test="normalize-space($custom)!=''">
											<xsl:value-of select="normalize-space($custom)" />
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="normalize-space(q:Catalog/q:Features/a:string[3])" />
										</xsl:otherwise>
									</xsl:choose>
								</feature>
								<feature>
									<xsl:variable name="custom">
										<xsl:apply-templates select="." mode="bullet_point4" />
									</xsl:variable>
									<xsl:choose>
										<xsl:when test="normalize-space($custom)!=''">
											<xsl:value-of select="normalize-space($custom)" />
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="normalize-space(q:Catalog/q:Features/a:string[4])" />
										</xsl:otherwise>
									</xsl:choose>
								</feature>
								<feature>
									<xsl:variable name="custom">
										<xsl:apply-templates select="." mode="bullet_point5" />
									</xsl:variable>
									<xsl:choose>
										<xsl:when test="normalize-space($custom)!=''">
											<xsl:value-of select="normalize-space($custom)" />
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="normalize-space(q:Catalog/q:Features/a:string[5])" />
										</xsl:otherwise>
									</xsl:choose>
								</feature>
								<feature>
									<xsl:value-of select="normalize-space(q:Catalog/q:Features/a:string[6])" />
								</feature>
								<feature>
									<xsl:value-of select="normalize-space(q:Catalog/q:Features/a:string[7])" />
								</feature>
								<feature>
									<xsl:value-of select="normalize-space(q:Catalog/q:Features/a:string[8])" />
								</feature>
								<feature>
									<xsl:value-of select="normalize-space(q:Catalog/q:Features/a:string[9])" />
								</feature>
								<feature>
									<xsl:value-of select="normalize-space(q:Catalog/q:Features/a:string[10])" />
								</feature>
							</xsl:with-param>
						</xsl:call-template>
					</xsl:variable>
					<xsl:variable name="features" select="msxsl:node-set($featuresResult)" />
					<xsl:for-each select="$features/a:string[normalize-space(.)!='']">
						<xsl:if test="position() &lt;= 10">
							<xsl:call-template name="ArrayItem">
								<xsl:with-param name="tagName">bullet_point</xsl:with-param>
								<xsl:with-param name="maxLength">700</xsl:with-param>
								<xsl:with-param name="value" select="." />
							</xsl:call-template>
						</xsl:if>
					</xsl:for-each>
					<xsl:call-template name="ArrayItem">
						<xsl:with-param name="tagName">generic_keyword</xsl:with-param>
						<xsl:with-param name="maxLength">500</xsl:with-param>
						<xsl:with-param name="value">
							<xsl:for-each select="q:Catalog/q:Tags/a:string[normalize-space(.)!='']">
								<xsl:value-of select="." />
								<xsl:if test="position()!=last()">
									<xsl:text>; </xsl:text>
								</xsl:if>
							</xsl:for-each>
						</xsl:with-param>
					</xsl:call-template>
					<xsl:call-template name="ArrayItem">
						<xsl:with-param name="tagName">part_number</xsl:with-param>
						<xsl:with-param name="addLanguage">0</xsl:with-param>
						<xsl:with-param name="maxLength">40</xsl:with-param>
						<xsl:with-param name="value" select="normalize-space(q:Catalog/q:SKUs/q:SKU[q:Type='MPN']/q:Value)" />
					</xsl:call-template>

					<xsl:call-template name="ArrayItem">
						<xsl:with-param name="tagName">country_of_origin</xsl:with-param>
						<xsl:with-param name="addLanguage">0</xsl:with-param>
						<xsl:with-param name="value" select="normalize-space(q:Catalog/q:CountryOfOrigin/q:ISO)" />
					</xsl:call-template>
					<xsl:call-template name="ArrayItem">
						<xsl:with-param name="tagName">warranty_description</xsl:with-param>
						<xsl:with-param name="maxLength">1900</xsl:with-param>
						<xsl:with-param name="value">
							<xsl:choose>
								<xsl:when test="q:Catalog/q:Warranty/q:Provider = 'Manufacturer'">
									<xsl:text>The warranty is covered by the manufacturer for </xsl:text>
									<xsl:value-of select="normalize-space(q:Catalog/q:Warranty/q:Duration)" />
									<xsl:text>.</xsl:text>
								</xsl:when>
								<xsl:when test="q:Catalog/q:Warranty/q:Provider = 'Distributor'">
									<xsl:text>The warranty is through us for </xsl:text>
									<xsl:value-of select="normalize-space(q:Catalog/q:Warranty/q:Duration)" />
									<xsl:text>.</xsl:text>
								</xsl:when>
								<xsl:otherwise>No Warranty</xsl:otherwise>
							</xsl:choose>
						</xsl:with-param>
					</xsl:call-template>
					<xsl:call-template name="ArrayItem">
						<xsl:with-param name="tagName">main_product_image_locator</xsl:with-param>
						<xsl:with-param name="additionalNodes">
							<media_location>
								<xsl:value-of select="$image-frag/image[@type='primary']" />
							</media_location>
						</xsl:with-param>
						<xsl:with-param name="addLanguage">0</xsl:with-param>
					</xsl:call-template>
					<xsl:call-template name="ArrayItem">
						<xsl:with-param name="tagName">other_product_image_locator_1</xsl:with-param>
						<xsl:with-param name="additionalNodes">
							<media_location>
								<xsl:value-of select="$image-frag/image[@type='secondary'][1]" />
							</media_location>
						</xsl:with-param>
						<xsl:with-param name="addLanguage">0</xsl:with-param>
					</xsl:call-template>
					<xsl:call-template name="ArrayItem">
						<xsl:with-param name="tagName">other_product_image_locator_2</xsl:with-param>
						<xsl:with-param name="additionalNodes">
							<media_location>
								<xsl:value-of select="$image-frag/image[@type='secondary'][2]" />
							</media_location>
						</xsl:with-param>
						<xsl:with-param name="addLanguage">0</xsl:with-param>
					</xsl:call-template>
					<xsl:call-template name="ArrayItem">
						<xsl:with-param name="tagName">other_product_image_locator_3</xsl:with-param>
						<xsl:with-param name="additionalNodes">
							<media_location>
								<xsl:value-of select="$image-frag/image[@type='secondary'][3]" />
							</media_location>
						</xsl:with-param>
						<xsl:with-param name="addLanguage">0</xsl:with-param>
					</xsl:call-template>
					<xsl:call-template name="ArrayItem">
						<xsl:with-param name="tagName">other_product_image_locator_4</xsl:with-param>
						<xsl:with-param name="additionalNodes">
							<media_location>
								<xsl:value-of select="$image-frag/image[@type='secondary'][4]" />
							</media_location>
						</xsl:with-param>
						<xsl:with-param name="addLanguage">0</xsl:with-param>
					</xsl:call-template>
					<xsl:call-template name="ArrayItem">
						<xsl:with-param name="tagName">other_product_image_locator_5</xsl:with-param>
						<xsl:with-param name="additionalNodes">
							<media_location>
								<xsl:value-of select="$image-frag/image[@type='secondary'][5]" />
							</media_location>
						</xsl:with-param>
						<xsl:with-param name="addLanguage">0</xsl:with-param>
					</xsl:call-template>
					<xsl:call-template name="ArrayItem">
						<xsl:with-param name="tagName">other_product_image_locator_6</xsl:with-param>
						<xsl:with-param name="additionalNodes">
							<media_location>
								<xsl:value-of select="$image-frag/image[@type='secondary'][6]" />
							</media_location>
						</xsl:with-param>
						<xsl:with-param name="addLanguage">0</xsl:with-param>
					</xsl:call-template>
					<xsl:call-template name="ArrayItem">
						<xsl:with-param name="tagName">other_product_image_locator_7</xsl:with-param>
						<xsl:with-param name="additionalNodes">
							<media_location>
								<xsl:value-of select="$image-frag/image[@type='secondary'][7]" />
							</media_location>
						</xsl:with-param>
						<xsl:with-param name="addLanguage">0</xsl:with-param>
					</xsl:call-template>
					<xsl:call-template name="ArrayItem">
						<xsl:with-param name="tagName">other_product_image_locator_8</xsl:with-param>
						<xsl:with-param name="additionalNodes">
							<media_location>
								<xsl:value-of select="$image-frag/image[@type='secondary'][8]" />
							</media_location>
						</xsl:with-param>
						<xsl:with-param name="addLanguage">0</xsl:with-param>
					</xsl:call-template>
					<xsl:call-template name="ArrayItem">
						<xsl:with-param name="tagName">item_package_dimensions</xsl:with-param>
						<xsl:with-param name="additionalNodes">
							<xsl:variable name="dimensionsUnits">
								<xsl:choose>
									<xsl:when test="q:ShippingInfo/q:Dimensions/q:Units='IN'">inches</xsl:when>
									<xsl:when test="q:ShippingInfo/q:Dimensions/q:Units='CM'">centimeters</xsl:when>
								</xsl:choose>
							</xsl:variable>
							<length>
								<value json:Type="Float">
									<xsl:value-of select="format-number(q:ShippingInfo/q:Dimensions/q:Length,'0.##')" />
								</value>
								<unit>
									<xsl:value-of select="$dimensionsUnits" />
								</unit>
							</length>
							<width>
								<value json:Type="Float">
									<xsl:value-of select="format-number(q:ShippingInfo/q:Dimensions/q:Width,'0.##')" />
								</value>
								<unit>
									<xsl:value-of select="$dimensionsUnits" />
								</unit>
							</width>
							<height>
								<value json:Type="Float">
									<xsl:value-of select="format-number(q:ShippingInfo/q:Dimensions/q:Height,'0.##')" />
								</value>
								<unit>
									<xsl:value-of select="$dimensionsUnits" />
								</unit>
							</height>
						</xsl:with-param>
						<xsl:with-param name="addLanguage">0</xsl:with-param>
					</xsl:call-template>
					<xsl:call-template name="ArrayItem">
						<xsl:with-param name="tagName">item_package_weight</xsl:with-param>
						<xsl:with-param name="value">
							<xsl:value-of select="format-number(q:ShippingInfo/q:Weight/q:Value,'0.##')" />
						</xsl:with-param>
						<xsl:with-param name="additionalNodes">
							<unit>
								<xsl:choose>
									<xsl:when test="q:ShippingInfo/q:Weight/q:Units='Pounds'">pounds</xsl:when>
									<xsl:when test="q:ShippingInfo/q:Weight/q:Units='Grams'">grams</xsl:when>
									<xsl:when test="q:ShippingInfo/q:Weight/q:Units='Kilograms'">kilograms</xsl:when>
								</xsl:choose>
							</unit>
						</xsl:with-param>
						<xsl:with-param name="addLanguage">0</xsl:with-param>
					</xsl:call-template>
				</xsl:variable>
				<xsl:variable name="preMappedNodeSet" select="msxsl:node-set($preMapped)" />
				<xsl:variable name="attributes">
					<xsl:apply-templates select="." mode="render-attributes" />
				</xsl:variable>
				<xsl:variable name="attributesNodeSet" select="msxsl:node-set($attributes)" />
				<xsl:for-each select="$preMappedNodeSet/node()">
					<!-- allow to override pre-mapped attributes by catalog mapper -->
					<xsl:if test="not($attributesNodeSet/*[name()=name(current())])">
						<xsl:copy-of select="." />
					</xsl:if>
				</xsl:for-each>
				<xsl:copy-of select="$attributesNodeSet/*" />
			</attributes>
		</messages>
	</xsl:template>

	<xsl:template match="q:CountryOfOrigin">
		<xsl:choose>
			<xsl:when test="normalize-space(q:Name) = 'Peoples Republic of China'">China</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="normalize-space(q:Name)" />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="title">
		<xsl:variable name="title">
			<xsl:value-of select="normalize-space(q:Catalog/q:Title)" />
			<!--<xsl:apply-templates select="." mode="Title"/>-->
		</xsl:variable>
		<xsl:variable name="certRfbCat">
			<xsl:apply-templates select="." mode="certRfbCat" />
		</xsl:variable>
		<xsl:variable name="certRfbBrnd">
			<xsl:apply-templates select="." mode="certRfbBrnd" />
		</xsl:variable>
		<xsl:variable name="restored">
			<xsl:apply-templates select="." mode="RESTORED" />
		</xsl:variable>
		<xsl:variable name="restoredPrem">
			<xsl:apply-templates select="." mode="RESTOREDPREM" />
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="$restoredPrem = 1 and q:Summary/q:Condition/q:Code = 'REFURBMAN'">
				<xsl:value-of select="concat(normalize-space($title), ' (Renewed Premium)')" />
			</xsl:when>
			<xsl:when test="$restoredPrem = 1 and q:Summary/q:Condition/q:Code = 'REFURB3RD'">
				<xsl:value-of select="concat(normalize-space($title), ' (Renewed Premium)')" />
			</xsl:when>
			<xsl:when test="$restoredPrem = 1 and q:Summary/q:Condition/q:Code = 'SCRADDNT'">
				<xsl:value-of select="concat(normalize-space($title), ' (Renewed Premium)')" />
			</xsl:when>

			<xsl:when test="$restored = 1 and q:Summary/q:Condition/q:Code = 'REFURBMAN'">
				<xsl:value-of select="concat(normalize-space($title), ' (Renewed)')" />
			</xsl:when>
			<xsl:when test="$restored = 1 and q:Summary/q:Condition/q:Code = 'REFURB3RD'">
				<xsl:value-of select="concat(normalize-space($title), ' (Renewed)')" />
			</xsl:when>
			<xsl:when test="$restored = 1 and q:Summary/q:Condition/q:Code = 'SCRADDNT'">
				<xsl:value-of select="concat(normalize-space($title), ' (Renewed)')" />
			</xsl:when>

			<xsl:when test="$certRfbCat = 1 and $certRfbBrnd = 1 and q:Summary/q:Condition/q:Code = 'REFURBMAN'">
				<xsl:value-of select="concat(normalize-space($title), ' (Renewed)')" />
			</xsl:when>
			<xsl:when test="$certRfbCat = 1 and $certRfbBrnd = 1 and q:Summary/q:Condition/q:Code = 'REFURB3RD'">
				<xsl:value-of select="concat(normalize-space($title), ' (Renewed)')" />
			</xsl:when>
			<xsl:when test="$certRfbCat = 1 and $certRfbBrnd = 1 and q:Summary/q:Condition/q:Code = 'SCRADDNT'">
				<xsl:value-of select="concat(normalize-space($title), ' (Renewed)')" />
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$title" />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="replace">
		<xsl:param name="from" />
		<xsl:param name="text" />
		<xsl:param name="replaceBy" />
		<xsl:choose>
			<xsl:when test="contains($from,$text)">
				<xsl:variable name="result">
					<xsl:value-of select="substring-before($from,$text)" />
					<xsl:value-of select="$replaceBy" />
					<xsl:value-of select="substring-after($from,$text)" />
				</xsl:variable>
				<xsl:value-of select="normalize-space($result)" />
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$from" />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="min">
		<xsl:param name="elements" />
		<xsl:for-each select="$elements">
			<xsl:sort select="." data-type="number" order="ascending" />
			<xsl:if test="position()=1">
				<xsl:value-of select="." />
			</xsl:if>
		</xsl:for-each>
	</xsl:template>

	<!--Template to render attribute from the Builder-->
	<xsl:template name="render">
		<xsl:param name="value" />
		<xsl:copy-of select="msxsl:node-set($value)" />
	</xsl:template>

	<!-- End of shared part of .MasterTemplate. Templates below are category-specific and were auto-generated by Builder template. -->
<xsl:template match="q:InventoryVirtualResult" mode="render-attributes"><xsl:call-template name="render"><xsl:with-param name="value"><color json:Array="true">
<value>
<xsl:value-of select="normalize-space(q:Catalog/q:Attributes/q:Attribute[q:Code='GENERICCOLOR']/q:Value/a:string[1])" />
</value>
</color></xsl:with-param></xsl:call-template><xsl:call-template name="render"><xsl:with-param name="value"><supplier_declared_dg_hz_regulation json:Array="true">
   <value>not_applicable</value>
</supplier_declared_dg_hz_regulation></xsl:with-param></xsl:call-template><xsl:call-template name="render"><xsl:with-param name="value"><xsl:variable name = "qweight" select="q:Catalog/q:Attributes/q:Attribute[q:Code='ITEMWEIGHT']/q:Value/a:string[1]" />

<item_weight json:Array="true">
<value>
<xsl:value-of select="format-number($qweight, '0.0')"/>
</value><unit>pounds</unit>
</item_weight></xsl:with-param></xsl:call-template><xsl:call-template name="render"><xsl:with-param name="value"><item_dimensions json:Array="true">
<height>
<value json:Type="Float">
<xsl:if test="normalize-space(q:Catalog/q:Attributes/q:Attribute[q:Code='ITEMDIMS']/q:Value/a:string)!=''">
      <xsl:value-of select="format-number(normalize-space(substring-after(substring-after(q:Catalog/q:Attributes/q:Attribute[q:Code='ITEMDIMS']/q:Value/a:string,'x'),'x')), '0.0')"/>
    </xsl:if>
</value>
<unit><xsl:text>inches</xsl:text></unit>
</height>
<length>
<value json:Type="Float">
<xsl:if test="normalize-space(q:Catalog/q:Attributes/q:Attribute[q:Code='ITEMDIMS']/q:Value/a:string)!=''">
      <xsl:value-of select="format-number(normalize-space(substring-before(substring-after(q:Catalog/q:Attributes/q:Attribute[q:Code='ITEMDIMS']/q:Value/a:string,'x'),'x')), '0.0')"/>
    </xsl:if>
</value>
<unit><xsl:text>inches</xsl:text></unit>
</length>
<width>
<value json:Type="Float">
<xsl:if test="normalize-space(q:Catalog/q:Attributes/q:Attribute[q:Code='ITEMDIMS']/q:Value/a:string)!=''">
      <xsl:value-of select="format-number(normalize-space(substring-after(substring-after(q:Catalog/q:Attributes/q:Attribute[q:Code='ITEMDIMS']/q:Value/a:string,'x'),'x')), '0.0')"/>
    </xsl:if>
</value>
<unit><xsl:text>inches</xsl:text></unit>
</width>
</item_dimensions>

</xsl:with-param></xsl:call-template><xsl:call-template name="render"><xsl:with-param name="value" /></xsl:call-template><xsl:call-template name="render"><xsl:with-param name="value"><number_of_items json:Array="true">
<value json:Type="Integer">1</value>
</number_of_items></xsl:with-param></xsl:call-template><xsl:call-template name="render"><xsl:with-param name="value"><connectivity_technology json:Array="true">
<value><xsl:value-of select="q:Catalog/q:Attributes/q:Attribute[q:Code='HDTYPE']/q:Value/a:string[1]" /></value>
</connectivity_technology></xsl:with-param></xsl:call-template><xsl:call-template name="render"><xsl:with-param name="value"><model_number json:Array="true">
<value><xsl:value-of select="q:Catalog/q:Attributes/q:Attribute[q:Code='MODELNBR']/q:Value/a:string[1]" /></value>
</model_number></xsl:with-param></xsl:call-template><xsl:call-template name="render"><xsl:with-param name="value"><xsl:variable name = "qHDSz" select="q:Catalog/q:Attributes/q:Attribute[q:Code='HDSIZE']/q:Value/a:string[1]" />
<xsl:variable name = "qspeed" select="q:Catalog/q:Attributes/q:Attribute[q:Code='HDSPEED']/q:Value/a:string[1]" />
<!-- anyOf,Hybrid Drive,Mechanical Hard Disk,Solid State Drive -->
<xsl:variable name = "qtype" select="q:Catalog/q:Attributes/q:Attribute[q:Code='HDTYPEHWARE']/q:Value/a:string[1]" />


<hard_disk json:Array="true">
<description json:Array="true">
<value>
<xsl:choose>
<xsl:when test="$qtype='Hard Disk Drive (HDD)'">
<xsl:text>Mechanical Hard Disk</xsl:text>
</xsl:when>
<xsl:when test="$qtype='Solid State Drive (SSD)'">
<xsl:text>Solid State Drive</xsl:text>
</xsl:when>
<xsl:when test="$qtype='Hybrid Hard Disk Drive (H-HDD)'">
<xsl:text>Hybrid Drive</xsl:text>
</xsl:when>
<xsl:otherwise></xsl:otherwise>
</xsl:choose>
</value>
</description>
  <size json:Array="true">
     <value json:Type="Float"><xsl:value-of select="$qHDSz"/></value>
<unit>GB</unit>
</size>
<rotational_speed json:Array="true">
<value json:Type="Integer">
<xsl:value-of select="$qspeed"/>
</value><unit>rpm</unit>
</rotational_speed>

<interface json:Array="true">
<xsl:variable name = "qinterface" select="q:Catalog/q:Attributes/q:Attribute[q:Code='HDTYPE']/q:Value/a:string[1]" />
<value>
<xsl:choose>
<xsl:when test="contains($qinterface, 'SATA')">
<xsl:text>esata</xsl:text>
</xsl:when>
<xsl:when test="contains($qinterface, 'PCIe NVMe')">
<xsl:text>pci_express_x4</xsl:text>
</xsl:when>
<xsl:when test="contains($qinterface, 'PCIe')">
<xsl:text>pci_express_x4</xsl:text>
</xsl:when>
<xsl:when test="contains($qinterface, 'SSD')">
<xsl:text>solid_state</xsl:text>
</xsl:when>
<xsl:otherwise>
</xsl:otherwise>
</xsl:choose>
</value>
</interface>
</hard_disk>
</xsl:with-param></xsl:call-template><xsl:call-template name="render"><xsl:with-param name="value"><!-- ddr_dram,ddr_sdram,ddr2_sdram,ddr3_sdram,ddr4_sdram,ddr5_ram,dimm,sdram,simm,sodimm -->
<system_ram_type json:Array="true"> 

<value><xsl:variable name='qram' select="q:Catalog/q:Attributes/q:Attribute[q:Code='RAMTYPE']/q:Value/a:string[1]" />

<xsl:choose> 

<xsl:when test="$qram ='DDR4'">ddr4_sdram</xsl:when>
<xsl:when test="$qram ='DDR3'">ddr3_sdram</xsl:when>
<xsl:when test="$qram ='Unified'">ddr5_ram</xsl:when>
<xsl:when test="$qram ='DDR2'">ddr2_sdram</xsl:when>
<xsl:when test="$qram ='DDR5'">ddr5_ram</xsl:when>
<xsl:when test="$qram ='DDR5'">ddr5_ram</xsl:when>
<xsl:when test="$qram ='DDR'">ddr_dram</xsl:when>
<xsl:when test="$qram ='LPDDR4X'">ddr4_sdram</xsl:when>
<xsl:when test="$qram ='LPDDR5X'">ddr5_ram</xsl:when>
<xsl:when test="$qram ='LPDDR5'">ddr5_ram</xsl:when>
<xsl:when test="$qram ='LPDDR4'">ddr4_sdram</xsl:when>
<xsl:otherwise>
    <xsl:value-of select="$qram"/>
</xsl:otherwise>
</xsl:choose></value>

</system_ram_type></xsl:with-param></xsl:call-template><xsl:call-template name="render"><xsl:with-param name="value"><cpu_model json:Array="true">
<xsl:variable name="uppercase" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'" />
<xsl:variable name="lowercase" select="'abcdefghijklmnopqrstuvwxyz'" />
<family json:Array="true">
    <value>
        <xsl:variable name="qcpunum" select="q:Catalog/q:Attributes/q:Attribute[q:Code='CPUNUM']/q:Value/a:string[1]" />


<xsl:choose>
                <xsl:when test="$qcpunum = 'AMD Ryzen 7 3780U'">
                    <xsl:value-of select="'ryzen_7'" />
                </xsl:when>
 <xsl:when test="$qcpunum = 'Intel Core i5-7400'">
                    <xsl:value-of select="'core_i5'" />
                </xsl:when>
                <xsl:when test="$qcpunum = 'Intel Core i5-13400'">
                    <xsl:value-of select="'core_i5'" />
                </xsl:when>
                 <xsl:when test="$qcpunum = 'Intel Core i3-13700H'">
                    <xsl:value-of select="'core_i3'" />
                </xsl:when>

 <xsl:when test="$qcpunum = 'Intel Xeon E5-1607 v4'">
                    <xsl:value-of select="'xeon_e5_1607'" />
                </xsl:when>
<xsl:when test="$qcpunum = 'Intel Core i7-13700'">
                    <xsl:value-of select="'core_i7'" />
                </xsl:when>
                
                <xsl:when test="$qcpunum = 'Intel Core Ultra 5'">
                    <xsl:value-of select="'core_i5'" />
                </xsl:when>
                
                 <xsl:when test="$qcpunum = 'AMD Ryzen 5 Pro 4650G'">
                    <xsl:value-of select="'ryzen_5'" />
                </xsl:when>
                <xsl:when test="$qcpunum = 'Intel Xeon W-2125'">
                    <xsl:value-of select="'intel_xeon'" />
                </xsl:when>
                  <xsl:when test="$qcpunum = 'Intel Xeon 4210'">
                    <xsl:value-of select="'intel_xeon'" />
                </xsl:when>
 <xsl:when test="$qcpunum = 'AMD Ryzen 5 Pro 3400G'">
                    <xsl:value-of select="'ryzen_5_3400g'" />
                </xsl:when>
           

<xsl:when test="$qcpunum = 'AMD Ryzen 5 Pro 2600'">
                    <xsl:value-of select="'ryzen_5_2600'" />
                </xsl:when>
                <xsl:when test="$qcpunum = 'AMD Ryzen 5 4680U'">
                    <xsl:value-of select="'Ryzen_5_4680U'" />
                </xsl:when>
<xsl:when test="$qcpunum = 'Intel Core Ultra 7 165H'">
                    <xsl:value-of select="'intel_core_ultra_7'" />
                </xsl:when>
   <xsl:when test="$qcpunum = 'Apple M1 Max'">
                    <xsl:value-of select="'apple_m1'" />
                </xsl:when>
                <xsl:when test="$qcpunum = 'AMD Ryzen 5 3580U'">
                    <xsl:value-of select="'ryzen_5'" />
                </xsl:when>
<xsl:when test="$qcpunum = 'AMD Ryzen 5 Pro 3400GU'">
                    <xsl:value-of select="'ryzen_5_3400g'" />
                </xsl:when>
<xsl:when test="$qcpunum = 'AMD Ryzen 5 7520U with Radeon Graphics'">
                    <xsl:value-of select="'ryzen_5'" />
                </xsl:when>
                <xsl:when test="$qcpunum = 'Intel Core i5-8250U'">
                    <xsl:value-of select="'core_i5_8250u'" />
                </xsl:when>
                <xsl:when test="$qcpunum = 'Intel Core i7-1065G7'">
                    <xsl:value-of select="'core_i7_1065g7'" />
                </xsl:when>
 <xsl:when test="$qcpunum = 'Intel Core i7-1165G7'">
                    <xsl:value-of select="'intel_core_i7_1165g7'" />
                </xsl:when>
                 <xsl:when test="$qcpunum = 'Intel Core i7-14700'">
                    <xsl:value-of select="'core_i7'" />
                </xsl:when>
                <xsl:when test="$qcpunum = 'Intel Core i7-1185G7'">
                    <xsl:value-of select="'Intel_core_i7_1185G7'" />
                </xsl:when>
               <xsl:when test="$qcpunum = 'Intel Core i5-1135G7'">
                    <xsl:value-of select="'intel_core_i5_1135g7'" />
                </xsl:when>
                <xsl:when test="$qcpunum = 'AMD Ryzen 7 4980U'">
                    <xsl:value-of select="'Ryzen_7_4980U'" />
                </xsl:when>
                <xsl:when test="$qcpunum = 'Intel Core i5-1035G7'">
                    <xsl:value-of select="'core_i5_1035g7'" />
                </xsl:when>
   <xsl:when test="$qcpunum = 'Intel Core i5- 7300U'">
                    <xsl:value-of select="'core_i5_7300u'" />
                </xsl:when>
         
               
                <xsl:when test="$qcpunum = 'Intel Core i5-1145G7'">
                    <xsl:value-of select="'core_i5_1145g7e'" />
                </xsl:when>
               
                  <xsl:when test="$qcpunum = 'Intel Core i5-7600'">
                    <xsl:value-of select="'core_i5'" />
                </xsl:when>
                <xsl:otherwise>

    <xsl:variable name="temp-without-intel-rtf">
        <xsl:choose>
            <xsl:when test="starts-with($qcpunum, 'Intel ')">
                <xsl:value-of select="substring-after($qcpunum, 'Intel ')" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$qcpunum" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <xsl:variable name="temp-clean-space" select="normalize-space(string($temp-without-intel-rtf))"/>
    
    <xsl:variable name="temp-replaced-hyphens" select="translate($temp-clean-space, '-', '_')" />
    
    <xsl:variable name="temp-transformed-cpunum" select="translate($temp-replaced-hyphens, ' ', '_')" />
    
    <xsl:variable name="final-transformed-cpunum" select="translate($temp-transformed-cpunum, $uppercase, $lowercase)" />

    <xsl:choose>
        <xsl:when test="starts-with($qcpunum, 'Intel ') and not(starts-with($final-transformed-cpunum, 'core_'))">
            <xsl:value-of select="concat('intel_', $final-transformed-cpunum)" />
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="$final-transformed-cpunum" />
        </xsl:otherwise>
    </xsl:choose>
</xsl:otherwise>
            </xsl:choose>
    </value>
</family>

<model_number json:Array="true">
<value><xsl:value-of select="q:Catalog/q:Attributes/q:Attribute[q:Code='CPUNUM']/q:Value/a:string[1]" /></value>
</model_number>


<!-- anyOf,BGA 1023,BGA 413,BGA 437,BGA 559,LGA 1150,LGA 1151,LGA 1155,LGA 1156,LGA 1200,LGA 1366,LGA 2011,LGA 2011-3,LGA 2066,LGA 3647,LGA 771,LGA 775,Socket 370,Socket 478,Socket 604,Socket 7,Socket 754,Socket 939,Socket 940,Socket A,Socket AM1,Socket AM2,Socket AM2+,Socket AM3,Socket AM4,Socket F,Socket FM1,Socket FM2,Socket FM2+,Socket P -->
<socket json:Array="true">
<value>anyOf</value>
</socket>




<manufacturer json:Array="true">
<value>

<xsl:variable name="qcpunum" select="q:Catalog/q:Attributes/q:Attribute[q:Code='CPUNUM']/q:Value/a:string[1]" />

<xsl:choose>

<xsl:when test="contains($qcpunum,'i7')">
<xsl:text>Intel</xsl:text>
</xsl:when>

<xsl:when test="contains($qcpunum,'i3')">
<xsl:text>Intel</xsl:text>
</xsl:when>

<xsl:when test="contains($qcpunum,'i5')">
<xsl:text>Intel</xsl:text>
</xsl:when>

<xsl:when test="contains($qcpunum,'4260U')">
<xsl:text>Intel</xsl:text>
</xsl:when>



<xsl:when test="contains($qcpunum,'6600')">
<xsl:text>Intel</xsl:text>
</xsl:when>


<xsl:when test="$qcpunum='intel Core Duo E8135'">
<xsl:text>Intel</xsl:text>
</xsl:when>

<xsl:when test="contains($qcpunum,'Intel')">
<xsl:text>Intel</xsl:text>
</xsl:when>

<xsl:when test="contains($qcpunum,'AMD')">
<xsl:text>AMD</xsl:text>
</xsl:when>

<xsl:when test="contains($qcpunum,'ARM')">
<xsl:text>ARM</xsl:text>
</xsl:when>

<xsl:when test="contains($qcpunum,'Apple')">
<xsl:text>Apple</xsl:text>
</xsl:when>

<xsl:when test="contains($qcpunum,'IBM')">
<xsl:text>IBM</xsl:text>
</xsl:when>

<xsl:when test="contains($qcpunum,'Qualcomm')">
<xsl:text>Qualcomm</xsl:text>
</xsl:when>

<xsl:when test="contains($qcpunum,'Motorola')">
<xsl:text>Motorola</xsl:text>
</xsl:when>

<xsl:when test="contains($qcpunum,'NVIDIA')">
<xsl:text>NVIDIA</xsl:text>
</xsl:when>

<xsl:when test="contains($qcpunum,'VIA')">
<xsl:text>VIA</xsl:text>
</xsl:when>

</xsl:choose>

</value>
</manufacturer>

<speed json:Array="true">
<value><xsl:value-of select="q:Catalog/q:Attributes/q:Attribute[q:Code='CPUSPEED']/q:Value/a:string[1]" /></value>
<unit>GHz</unit>
</speed>
</cpu_model></xsl:with-param></xsl:call-template><xsl:call-template name="render"><xsl:with-param name="value"><total_usb_2_0_ports json:Array="true">
<value><xsl:value-of select="q:Catalog/q:Attributes/q:Attribute[q:Code='USBPRT']/q:Value/a:string[1]" /></value>
</total_usb_2_0_ports></xsl:with-param></xsl:call-template><xsl:call-template name="render"><xsl:with-param name="value"><specific_uses_for_product json:Array="true">
<value><xsl:value-of select="q:Catalog/q:Attributes/q:Attribute[q:Code='PCLIFESTYLE']/q:Value/a:string[1]" /></value>
</specific_uses_for_product></xsl:with-param></xsl:call-template><xsl:call-template name="render"><xsl:with-param name="value"><model_name json:Array="true">
<value><xsl:value-of select="q:Catalog/q:Attributes/q:Attribute[q:Code='MODELNBR']/q:Value/a:string[1]" /></value>
</model_name></xsl:with-param></xsl:call-template><xsl:call-template name="render"><xsl:with-param name="value"><flash_memory json:Array="true">
<installed_size json:Array="true">
   <value><xsl:value-of select="q:Catalog/q:Attributes/q:Attribute[q:Code='HDSIZE']/q:Value/a:string[1]" /></value><unit>GB</unit>
</installed_size>

</flash_memory></xsl:with-param></xsl:call-template><xsl:call-template name="render"><xsl:with-param name="value"><memory_storage_capacity json:Array="true">
   <value><xsl:value-of select="q:Catalog/q:Attributes/q:Attribute[q:Code='HDSIZE']/q:Value/a:string[1]" /></value>

<unit>GB</unit>
</memory_storage_capacity></xsl:with-param></xsl:call-template><xsl:call-template name="render"><xsl:with-param name="value"><optical_storage json:Array="true">
<device_description json:Array="true">
   <value><xsl:value-of select="q:Catalog/q:Attributes/q:Attribute[q:Code='OPTDR1']/q:Value/a:string[1]" /></value>
</device_description>
</optical_storage></xsl:with-param></xsl:call-template><xsl:call-template name="render"><xsl:with-param name="value"><total_usb_3_0_ports json:Array="true">
<value><xsl:value-of select="q:Catalog/q:Attributes/q:Attribute[q:Code='USBPWR']/q:Value/a:string[1]" /></value>
</total_usb_3_0_ports></xsl:with-param></xsl:call-template><xsl:call-template name="render"><xsl:with-param name="value"><!-- anyOf,Chrome OS,DOS,Linux,Mac OS,Mac OS 9,Mac OS X 10.0 Cheetah,Mac OS X 10.1 Puma,Mac OS X 10.2 Jaguar,Mac OS X 10.3 Panther,Mac OS X 10.4 Tiger,Mac OS X 10.5 Leopard,Mac OS X 10.6 Snow Leopard,macOS 10.12 Sierra,macOS 10.13 High Sierra,macOS 10.14 Mojave,macOS 10.15 Catalina,macOS 11 Big Sur,macOS 12 Monterey,OS X 10.10 Yosemite,OS X 10.11 El Capitan,OS X 10.7 Lion,OS X 10.8 Mountain Lion,OS X 10.9 Mavericks,Windows,Windows 10,Windows 10 Home,Windows 10 Pro,Windows 10 S,Windows 11,Windows 11 Home,Windows 11 Pro,Windows 11 S,Windows 11 SE,Windows 7,Windows 7 Home Basic,Windows 7 Home Premium,Windows 7 Professional,Windows 7 Starter,Windows 7 Ultimate,Windows 8,Windows 8 Pro,Windows 8.1,Windows 8.1 Pro,Windows RT,Windows Vista Home Basic,Windows Vista Home Premium,Windows XP Home,Windows XP Professional -->


<operating_system json:Array="true">
    <value>
        
<xsl:variable name="q-os" select="q:Catalog/q:Attributes/q:Attribute[q:Code='DESKTOPOS']/q:Value/a:string[1]" />
      <xsl:variable name="q-edition" select="q:Catalog/q:Attributes/q:Attribute[q:Code='DESKTOPOSEDITION']/q:Value/a:string[1]" />
      <xsl:variable name="q-os-code">
         <xsl:value-of select="$q-os"/>
         <xsl:if test="$q-edition != '' and $q-edition != 'Not Applicable'">
           <xsl:value-of select="$q-edition"/>
         </xsl:if>
      </xsl:variable>
      <xsl:variable name="q-os-fragment">
        <item os="Microsoft Windows 8">Windows 8</item>
        <item os="Microsoft Windows 8Home">Windows 8</item>
        <item os="Microsoft Windows 8Home Premium">Windows 8</item>
        <item os="Microsoft Windows 8Professional">Windows 8 Pro</item>
        <item os="Microsoft Windows 7">Windows 7 Home Premium</item>
        <item os="Microsoft Windows 7Home">Windows 7 Home Premium</item>
        <item os="Microsoft Windows 7Home Premium">Windows 7 Home Premium</item>
        <item os="Microsoft Windows 7Professional">Windows 7 Professional</item>
        <item os="Microsoft Windows 7Ultimate">Windows 7 Ultimate</item>
        <item os="Microsoft Windows 8.1">Windows 8</item>
        <item os="Microsoft Windows 8.1Home">Windows 8</item>
        <item os="Microsoft Windows 8.1Home Premium">Windows 8</item>
        <item os="Microsoft Windows 8.1Professional">Windows 8 Pro</item>
        <item os="Microsoft Windows 10">Windows 10</item>
        <item os="Microsoft Windows 10Home">Windows 10</item>
        <item os="Microsoft Windows 10Home Premium">Windows 10</item>
        <item os="Microsoft Windows 10Professional">Windows 10</item>
        <item os="Microsoft Windows 10Enterprise">Windows 10</item>
        <item os="Microsoft Windows 10IoT Enterprise">Windows 10</item>
        <item os="Microsoft Windows 10IoT">Windows 10</item>
		<item os="Microsoft Windows 10S">Windows 10</item>
        <item os="Microsoft Windows 10Education">Windows 10</item>
<item os="Microsoft Windows 11">Windows 11</item>
<item os="Apple Mac OS 15">Mac OS</item>
        <item os="Microsoft Windows 11Home">Windows 11</item>
	<item os="Windows 11">Windows 11</item>
        <item os="Microsoft Windows 11Home Premium">Windows 11</item>
        <item os="Microsoft Windows 11Professional">Windows 11</item>
        <item os="Microsoft Windows 11Enterprise">Windows 11</item>
        <item os="Microsoft Windows 11IoT Enterprise">Windows 11</item>
        <item os="Microsoft Windows 11IoT">Windows 11</item>
		<item os="Microsoft Windows 11S">Windows 11</item>
        <item os="Microsoft Windows 11Education">Windows 11</item>
        <item os="Microsoft Windows Vista">Windows Vista</item>
        <item os="Microsoft Windows VistaStarter">Windows Vista</item>
        <item os="Microsoft Windows VistaHome">Windows Vista</item>
        <item os="Microsoft Windows VistaHome Premium">Windows Vista</item>
        <item os="Microsoft Windows VistaBusiness">Windows Vista</item>
        <item os="Microsoft Windows XP">Windows XP Home Edition</item>
        <item os="Microsoft Windows XPHome">Windows XP Home Edition</item>
        <item os="Microsoft Windows XPProfessional">Windows XP Professional Edition</item>
        <item os="Microsoft Windows XPProfessional">Windows XP Professional Tablet PC Edition</item>
        <item os="Apple Mac OS X 10.5">Mac OS X</item>
        <item os="Apple Mac OS X 10.6">Mac OS X</item>
        <item os="Apple Mac OS X 10.7">Mac OS X</item>
        <item os="Apple Mac OS X 10.8">Mac OS X</item>
        <item os="Apple Mac OS X 10.9">Mac OS X</item>
        <item os="Chrome OS">Chrome OS</item>
        <item os="None">None</item>
        <item os="Apple Mac OS X 10.4">Mac OS X 10.4 Tiger</item>
        <item os="Ubuntu Linux">Linux</item>
        <item os="LeTOS">Linux</item>
        <item os="LeTOSv1">Linux</item>
        <item os="LeTOSv2">Linux</item>
        <item os="FreeDOS">DOS</item>
        <item os="Wyse OS">Linux</item>
		<item os="HP ThinPro">Linux</item>
        <item os="Apple Mac OS X 10.10">Mac OS X</item>
        <item os="Apple Mac OS X 10.11">Mac OS X</item>
        <item os="Apple Mac OS 10.15">Mac OS X</item>
        <item os="macOS 10.12">Mac OS X</item>
        <item os="macOS 10.13">Mac OS X</item>
        <item os="macOS 10.14">Mac OS X</item>
        <item os="macOS 10.15">Mac OS X</item>
        <item os="macOS 11">Mac OS X</item>
        <item os="Apple Mac OS 11">Mac OS X</item>
         <item os="Apple Mac OS 10.14">Mac OS X</item>


      </xsl:variable>

      <xsl:value-of select="msxsl:node-set($q-os-fragment)/item[@os = $q-os-code]"/>

</value>


</operating_system></xsl:with-param></xsl:call-template><xsl:call-template name="render"><xsl:with-param name="value"><!-- agp,integrated,pci_e -->
<graphics_card_interface json:Array="true">
<value><xsl:variable name='qGPUmodel' select="q:Catalog/q:Attributes/q:Attribute[q:Code='GPUTYPE']/q:Value/a:string[1]" />

<xsl:choose> 

<xsl:when test="$qGPUmodel ='Integrated'">integrated</xsl:when>
<xsl:when test="$qGPUmodel ='Dedicated'">pci_e</xsl:when>
<xsl:when test="$qGPUmodel ='Hybrid'">pci_e</xsl:when>

</xsl:choose></value>
</graphics_card_interface></xsl:with-param></xsl:call-template><xsl:call-template name="render"><xsl:with-param name="value"><graphics_description json:Array="true">
<value><xsl:value-of select="q:Catalog/q:Attributes/q:Attribute[q:Code='GPUTYPE']/q:Value/a:string[1]" /></value>
</graphics_description>
</xsl:with-param></xsl:call-template><xsl:call-template name="render"><xsl:with-param name="value"><!--
Graphics Ram (Id: graphics_ram, Type: array)
marketplace_id (Id: marketplace_id, Type: string) : anyOf,ATVPDKIKX0DER
Graphics Card Ram (Id: size, Type: array)
*Graphics Ram Size (Id: value, Type: number[maxLength:5000]) : Free text
Graphics Ram Size Unit (Id: unit, Type: string) : GB,MB,TB
Graphics Ram Type (Id: type, Type: array)
*Graphics Ram (Id: value, Type: string) : 72_pin_edo_simm,ddr_dram,ddr_sdram,ddr2_sdram,ddr3_sdram,ddr3l_1600_sdram,ddr4_sdram,ddr5_sdram,dimm,dram,edo_dram,eeprom,eprom,fpm_dram,fpm_ram,gddr3,gddr4,gddr5,gddr5x,gddr6,gddr7,l2_cache,micro_dimm,pc_2100_ddr,pc_2700_ddr,pc_3200_ddr,pc_3500_ddr,pc_4000_ddr,pc_100_sdram,pc_133_sdram,pc_66_sdram,pc_1066,pc_1600,pc2_4200,pc2_4300,pc2_5300,pc2_5400,pc2_6000,pc_3000,pc_3700,pc_4200,pc_4300,pc_4400,pc_800,rambus,rdram,rimm,sdram,sgram,shared,simm,sipp,sldram,sodimm,sorimm,sram,vram,wram
-->
<xsl:variable name="qGPU" select="q:Catalog/q:Attributes/q:Attribute[q:Code='GPUTYPE']/q:Value/a:string[1]" />
<xsl:variable name='qGPUsize' select="q:Catalog/q:Attributes/q:Attribute[q:Code='GPUSIZE']/q:Value/a:string[1]" />

<graphics_ram json:Array="true">
   <size json:Array="true">
      <xsl:choose>
         <xsl:when test="$qGPU ='Integrated'">
            <value>0</value>
            <unit>GB</unit>
         </xsl:when>
         <xsl:when test="number($qGPUsize) &gt; 5000">
            <value><xsl:value-of select="format-number(number($qGPUsize) div 1024, '0.##')" /></value>
            <unit>GB</unit>  
         </xsl:when>
         <xsl:otherwise>
            <value><xsl:value-of select="$qGPUsize" /></value>
            <unit>MB</unit>    
        </xsl:otherwise>
      </xsl:choose>
   </size>
   <type json:Array="true">
      <value>
         <xsl:variable name="sourceRamType">
            <xsl:choose>
               <xsl:when test="$qGPU ='Integrated'">
                  <xsl:value-of select="q:Catalog/q:Attributes/q:Attribute[q:Code='RAMTYPE']/q:Value/a:string[1]" />
               </xsl:when>
               <xsl:otherwise>
                  <xsl:value-of select="q:Catalog/q:Attributes/q:Attribute[q:Code='GPURAMTYPE']/q:Value/a:string[1]" />      
               </xsl:otherwise>
            </xsl:choose>
         </xsl:variable>
         <xsl:choose>
            <xsl:when test="$sourceRamType = 'DDR'">ddr_sdram</xsl:when>
            <xsl:when test="$sourceRamType = 'DDR2'">ddr2_sdram</xsl:when>
            <xsl:when test="$sourceRamType = 'DDR3'">ddr3_sdram</xsl:when>
            <xsl:when test="$sourceRamType = 'SDRAM'">sdram</xsl:when>
            <xsl:when test="$sourceRamType = 'RDRAM'">rdram</xsl:when>
            <xsl:when test="$sourceRamType = 'EDO'">edo_dram</xsl:when>
            <xsl:when test="$sourceRamType = 'VRAM'">vram</xsl:when>
            <xsl:when test="$sourceRamType = 'DDR4'">ddr4_sdram</xsl:when>
            <xsl:when test="$sourceRamType = 'DDR5'">ddr5_sdram</xsl:when>
            <xsl:when test="$sourceRamType = 'LPDDR5'">ddr5_sdram</xsl:when>
            <xsl:when test="$sourceRamType = 'LPDDR4X'">ddr4_sdram</xsl:when>
            <xsl:when test="$sourceRamType = 'LPDDR4'">ddr4_sdram</xsl:when>
            <xsl:when test="$sourceRamType = 'LPDDR5X'">ddr5_sdram</xsl:when>
            <xsl:when test="$sourceRamType = 'GDDR3'">gddr3</xsl:when>
            <xsl:when test="$sourceRamType = 'GDDR4'">gddr4</xsl:when>
            <xsl:when test="$sourceRamType = 'GDDR5'">gddr5</xsl:when>
            <xsl:when test="$sourceRamType = 'GDDR5X'">gddr5x</xsl:when>
            <xsl:when test="$sourceRamType = 'GDDR6'">gddr6</xsl:when>
            <xsl:when test="$sourceRamType = 'GDDR6X'">gddr6x</xsl:when>
            <xsl:when test="$sourceRamType = 'Not Applicable'">shared</xsl:when>
            <xsl:when test="$sourceRamType = 'Unified'">shared</xsl:when>
            <xsl:when test="$sourceRamType = 'HBM2'">shared</xsl:when>
            <xsl:otherwise>dram</xsl:otherwise>
        </xsl:choose>
      </value>
   </type>
</graphics_ram></xsl:with-param></xsl:call-template><xsl:call-template name="render"><xsl:with-param name="value"><!-- touch_bar,touch_pad,touch_screen,touch_screen_stylus_pen -->
<xsl:variable name="touchscreen" select="normalize-space(Catalog/Attributes/Attribute[Code='TOUCH']/Value/a:string[1])" />
<human_interface_input json:Array="true">
<value>
<xsl:choose>
   <xsl:when test="$touchscreen='YES'">touch_screen</xsl:when>
<xsl:otherwise>touch_pad</xsl:otherwise> </xsl:choose>
</value>
</human_interface_input></xsl:with-param></xsl:call-template><xsl:call-template name="render"><xsl:with-param name="value"><xsl:for-each select="q:Catalog/q:InBox/a:string">

   <included_components json:Array="true"> 
      <value><xsl:value-of select="."/></value>
   </included_components>

</xsl:for-each></xsl:with-param></xsl:call-template><xsl:call-template name="render"><xsl:with-param name="value"><ram_memory json:Array="true">
<installed_size json:Array="true">
   <value><xsl:value-of select="q:Catalog/q:Attributes/q:Attribute[q:Code='RAMSIZE']/q:Value/a:string[1]" /></value><unit>GB</unit>
</installed_size>

<maximum_size json:Array="true">
   <value><xsl:value-of select="q:Catalog/q:Attributes/q:Attribute[q:Code='RAMSIZE']/q:Value/a:string[1]" /></value><unit>GB</unit>
</maximum_size>


<technology json:Array="true"> 

<value><xsl:variable name='qram' select="q:Catalog/q:Attributes/q:Attribute[q:Code='RAMTYPE']/q:Value/a:string[1]" />

<xsl:choose> 

<xsl:when test="$qram ='DDR4'">ddr4_sdram</xsl:when>
<xsl:when test="$qram ='DDR3'">ddr3_sdram</xsl:when>
<xsl:when test="$qram ='DDR2'">ddr2_sdram</xsl:when>
<xsl:when test="$qram ='DDR5'">ddr5_ram</xsl:when>
<xsl:when test="$qram ='DDR5'">ddr5_ram</xsl:when>
<xsl:when test="$qram ='DDR'">ddr_dram</xsl:when>

<xsl:otherwise>
    <xsl:value-of select="$qram"/>
</xsl:otherwise>
</xsl:choose></value>

</technology>


</ram_memory></xsl:with-param></xsl:call-template><xsl:call-template name="render"><xsl:with-param name="value"><display json:Array="true">


<size json:Array="true">
<value>0</value>
<unit>inches</unit>
</size>

<resolution_maximum json:Array="true">
<value>anyOf</value>
<unit>pixels</unit>
</resolution_maximum>

</display></xsl:with-param></xsl:call-template><xsl:call-template name="render"><xsl:with-param name="value"><cache_memory json:Array="true">
<installed_size json:Array="true">
   <value><xsl:value-of select="q:Catalog/q:Attributes/q:Attribute[q:Code='CPUCACHE']/q:Value/a:string[1]" /></value><unit>GB</unit>
</installed_size>

</cache_memory></xsl:with-param></xsl:call-template><xsl:call-template name="render"><xsl:with-param name="value">
	<modified_product json:Array="true">

 <value><xsl:variable name='qcondition' select="q:Catalog/q:Condition/q:Name" />

	<xsl:choose>
	
		<xsl:when test='$qcondition="New"'>
		<xsl:text>False</xsl:text>
		</xsl:when>

		<xsl:when test='$qcondition="New Open Box"'>
		<xsl:text>False</xsl:text>
		</xsl:when>

	<xsl:otherwise>True</xsl:otherwise>

	</xsl:choose>
	</value>


</modified_product></xsl:with-param></xsl:call-template></xsl:template>
<xsl:template match="q:InventoryVirtualResult" mode="ProductType"><xsl:text>PERSONAL_COMPUTER</xsl:text></xsl:template><xsl:template match="node()" mode="language_tag">en_US</xsl:template>
<xsl:template match="q:InventoryVirtualResult" mode="ItemType"><xsl:text>tower-computers</xsl:text>
</xsl:template>
<xsl:template match="q:InventoryVirtualResult" mode="Filter"><xsl:text>No filter specified (export all)</xsl:text></xsl:template>
<xsl:template match="q:InventoryVirtualResult" mode="bullet_point1" />
<xsl:template match="q:InventoryVirtualResult" mode="bullet_point2" />
<xsl:template match="q:InventoryVirtualResult" mode="bullet_point3" />
<xsl:template match="q:InventoryVirtualResult" mode="bullet_point4" />
<xsl:template match="q:InventoryVirtualResult" mode="bullet_point5" />

</xsl:stylesheet>