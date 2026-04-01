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

<xsl:variable name='qColor' select="q:Catalog/q:Attributes/q:Attribute[q:Code='GENERICCOLOR']/q:Value/a:string[1]" />
<xsl:variable name="map">

<item qColor="Red">red</item>
<item qColor="Orange">orange</item>
<item qColor="Yellow">yellow</item>
<item qColor="Green">green</item>
<item qColor="Blue">blue</item>
<item qColor="Purple">purple</item>
<item qColor="Pink">pink</item>
<item qColor="Silver">silver</item>
<item qColor="Gold">gold</item>
<item qColor="Beige">Beige</item>
<item qColor="Brown">brown</item>
<item qColor="Grey">Grey</item>
<item qColor="Black">black</item>
<item qColor="White">white</item>
<item qColor="Clear">Transparent</item>


</xsl:variable>

<xsl:value-of select="msxsl:node-set($map)/item[@qColor=$qColor]"/>


</value>
</color></xsl:with-param></xsl:call-template><xsl:call-template name="render"><xsl:with-param name="value"><supplier_declared_dg_hz_regulation json:Array="true">
   <value>not_applicable</value>
</supplier_declared_dg_hz_regulation></xsl:with-param></xsl:call-template><xsl:call-template name="render"><xsl:with-param name="value">
<size json:Array="true">
<value><xsl:value-of select="q:Catalog/q:Attributes/q:Attribute[q:Code='RAMSIZE']/q:Value/a:string[1]" /></value>
<unit>GB</unit>
</size></xsl:with-param></xsl:call-template><xsl:call-template name="render"><xsl:with-param name="value"><display json:Array="true">

<size json:Array="true">
<value><xsl:value-of select="q:Catalog/q:Attributes/q:Attribute[q:Code='SCRNSIZE']/q:Value/a:string[1]" /></value>
<unit>inches</unit>
</size>

<resolution_maximum json:Array="true">
<value><xsl:value-of select="q:Catalog/q:Attributes/q:Attribute[q:Code='NATIVERES']/q:Value/a:string[1]" /></value>
<unit>pixels</unit>
</resolution_maximum>

<!-- anyOf,AMOLED,LCD,OLED -->
<type json:Array="true">
<value>anyOf</value>
</type>

</display></xsl:with-param></xsl:call-template><xsl:call-template name="render"><xsl:with-param name="value"><flash_memory json:Array="true">
<installed_size json:Array="true">
   <value  json:Type="Float"><xsl:value-of select="q:Catalog/q:Attributes/q:Attribute[q:Code='STORSIZE']/q:Value/a:string[1]" /></value><unit>GB</unit>
</installed_size>

</flash_memory></xsl:with-param></xsl:call-template><xsl:call-template name="render"><xsl:with-param name="value"><!-- anyOf,Android 10.0,Android 11.0,Android 12.0,Android 13.0,Android 14,Android 4.0,Android 4.1,Android 4.2,Android 4.3,Android 4.4,Android 5.0,Android 5.1,Android 6.0,Android 7.0,Android 7.1,Android 8.0,Android 8.1,Android 9.0,BlackBerry 10.0,BlackBerry 6.0,BlackBerry 7.0,EMUI 10.0,FunTouch OS 10,FunTouch OS 4,FunTouch OS 9,iOS 10,iOS 11,iOS 12,iOS 13,iOS 14,iOS 15,iOS 16,iOS 17,iOS 3,iOS 4,iOS 7,iOS 8,iOS 9,KaiOS,MIUI 10,MIUI 11,MIUI 12,MIUI 12.5,MIUI 8,MIUI 9,Nucleus OS,OxygenOS,Symbian 9.1,Symbian 9.3,Windows Mobile 6.5 -->
<operating_system json:Array="true">
    <value>
<xsl:value-of select="q:Catalog/q:Attributes/q:Attribute[q:Code='TABOS']/q:Value/a:string[1]" />
 </value>

</operating_system></xsl:with-param></xsl:call-template><xsl:call-template name="render"><xsl:with-param name="value"><!-- anyOf,2G,3G,4G,5G -->

<cellular_technology json:Array="true">
<value>

<xsl:variable name="qwireless" select="q:Catalog/q:Attributes/q:Attribute[q:Code='WIRELESSTECH']/q:Value/a:string[1]" />

<xsl:choose> 

<xsl:when test="contains($qwireless,'2G')">
<xsl:text>2G</xsl:text>
</xsl:when>

<xsl:when test="contains($qwireless,'3G')">
<xsl:text>3G</xsl:text>
</xsl:when>

<xsl:when test="contains($qwireless,'4G LTE')">
<xsl:text>4G</xsl:text>
</xsl:when>

<xsl:when test="contains($qwireless,'5G')">
<xsl:text>5G</xsl:text>
</xsl:when>


</xsl:choose>

</value>
</cellular_technology>


</xsl:with-param></xsl:call-template><xsl:call-template name="render"><xsl:with-param name="value"><!-- amps,CDMA,GSM,Iden,LTE,TDMA,UMTS,unknown,wifi,WiMax -->

<wireless_network_technology json:Array="true">
<value>

<xsl:variable name="qcelular" select="q:Catalog/q:Attributes/q:Attribute[q:Code='CELLULARNETWORK']/q:Value/a:string[1]" />

<xsl:choose> 

<xsl:when test="contains($qcelular,'Not Applicable')">
<xsl:text>unknown</xsl:text>
</xsl:when>

<xsl:when test="contains($qcelular,'GSM')">
<xsl:text>GSM</xsl:text>
</xsl:when>

<xsl:when test="contains($qcelular,'CDMA')">
<xsl:text>CDMA</xsl:text>
</xsl:when>

</xsl:choose>

</value>
</wireless_network_technology>
</xsl:with-param></xsl:call-template><xsl:call-template name="render"><xsl:with-param name="value"><memory_storage_capacity json:Array="true">
<value><xsl:value-of select="q:Catalog/q:Attributes/q:Attribute[q:Code='STORSIZE']/q:Value/a:string[1]" /></value>
<unit>GB</unit>
</memory_storage_capacity></xsl:with-param></xsl:call-template><xsl:call-template name="render"><xsl:with-param name="value"><connector_type json:Array="true">
<value></value>
</connector_type></xsl:with-param></xsl:call-template><xsl:call-template name="render"><xsl:with-param name="value" /></xsl:call-template><xsl:call-template name="render"><xsl:with-param name="value"><!-- 1und1,3,airtel,aldi_talk,algar_telecom,america_movil,att,au,base,bell_mobility,biglobe,bild_connect,blue,boost_infinite,boost_mobile,bsnl,cabo_telecom,china_mobile,china_telecom,china_unicom,claro,congstar,consumer_cellular,copel,correios,cricket,deutsche_telekom,docomo,du,e-plus,edeka_mobil,embratel,etisalat,freedompop,freenet,global_village_telecom,go,project_fi,gowireless,h2o_wireless,ig_internet_group,iij,intelig_telecom,jio,kajeet,kt_corporation,lebara,lidl_connect,line_mobile,linksmate,lycamobile,metro_by_tmobile,mineo,mint_mobile,mobilcom,mobily,movistar,mvno,net,net_10,netell,ntt_communications,o2,oi,optus,orange,otelo,rakuten_mobile,republic,republic_wireless,rogers_wireless,sercomtel,simple_mobile,sk_telecom,smartmobil_de,softbank,sprint,stc,sti_mobile_actual,straight_talk,swipe,t_mobile,talkline,tchibo_mobil,telcel,telecom_egypt,telefonica,telstra,telus,tesco,tim,ting,tokai_communications,total_wireless,tpg,tracfone,unlocked,all_carriers,uol_universo_online,uq_mobile,uscellular,verizon,verizon_wireless,virgin_mobile,vodafone,vodafone_idea,voicestream,whatsapp_sim,win_sim,y_mobile,zain -->
<wireless_provider json:Array="true">
<value>

<xsl:variable name="qcelular" select="q:Catalog/q:Attributes/q:Attribute[q:Code='NETWORKPROVIDER']/q:Value/a:string[1]" />

<xsl:choose> 

<xsl:when test="contains($qcelular,'Not Applicable')">
<xsl:text>unlocked</xsl:text>
</xsl:when>
<xsl:when test="contains($qcelular,'Not Specified')">
<xsl:text>unlocked</xsl:text>
</xsl:when>
<xsl:when test="contains($qcelular,'AT&amp;T')">
<xsl:text>att</xsl:text>
</xsl:when>
<xsl:otherwise>
<xsl:value-of select="$qcelular" />

</xsl:otherwise>

</xsl:choose>

</value>
</wireless_provider>
</xsl:with-param></xsl:call-template><xsl:call-template name="render"><xsl:with-param name="value"><effective_still_resolution json:Array="true">
<value><xsl:value-of select="q:Catalog/q:Attributes/q:Attribute[q:Code='REARCAM']/q:Value/a:string[1]" /></value>
<unit>megapixels</unit>
</effective_still_resolution></xsl:with-param></xsl:call-template><xsl:call-template name="render"><xsl:with-param name="value"><!-- anyOf,Bar,Foldable Case,Foldable Screen,Slate,Slider -->
<form_factor json:Array="true">
<value></value>
</form_factor></xsl:with-param></xsl:call-template><xsl:call-template name="render"><xsl:with-param name="value"><model_number json:Array="true">
<value><xsl:value-of select="q:Catalog/q:Attributes/q:Attribute[q:Code='MODELNBR']/q:Value/a:string[1]" /></value>
</model_number></xsl:with-param></xsl:call-template><xsl:call-template name="render"><xsl:with-param name="value" /></xsl:call-template><xsl:call-template name="render"><xsl:with-param name="value"><!-- anyOf,Dual-Micro/Nano,Dual-Nano,Dual-SIM,Dual-SIM/Micro,Dual-SIM/Nano,Micro-SIM,Nano-SIM Dual-Micro,SIM -->
<telephone_type json:Array="true">
<value><xsl:value-of select="q:Catalog/q:Attributes/q:Attribute[q:Code='DUALSIM']/q:Value/a:string[1]" /></value>
</telephone_type></xsl:with-param></xsl:call-template><xsl:call-template name="render"><xsl:with-param name="value" /></xsl:call-template><xsl:call-template name="render"><xsl:with-param name="value"><digital_storage_capacity json:Array="true">
<value><xsl:value-of select="q:Catalog/q:Attributes/q:Attribute[q:Code='STORSIZE']/q:Value/a:string[1]" /></value>
<unit>GB</unit>
</digital_storage_capacity></xsl:with-param></xsl:call-template><xsl:call-template name="render"><xsl:with-param name="value"><xsl:variable name="qm2" select="q:Catalog/q:Attributes/q:Attribute[q:Code='MODELNBR']/q:Value/a:string[1]" />

<xsl:variable name="qm1" select="q:Catalog/q:Attributes/q:Attribute[q:Code='PHONEPRODLINE']/q:Value/a:string[1]" />
<model_name json:Array="true">
    <value><xsl:value-of select="concat($qm1, $qm2)" /></value>
</model_name></xsl:with-param></xsl:call-template><xsl:call-template name="render"><xsl:with-param name="value"><!-- anyOf,Audio Adapter,Headset,Phone Case,Power Adapter,Screen Protector,SIM Tray Ejector,Stylus,USB Cable,USB OTG Adapter -->

<included_components json:Array="true">
    <xsl:variable name="hasCharger" select="count(q:Catalog/q:InBox/a:string[contains(., 'Charger') or contains(., 'charger')]) > 0" />

    <xsl:choose>
        <xsl:when test="$hasCharger">
            <value>Power Adapter</value>
            <value>USB Cable</value>
        </xsl:when>
        <xsl:otherwise>
            <value>USB Cable</value>
        </xsl:otherwise>
    </xsl:choose>

</included_components></xsl:with-param></xsl:call-template><xsl:call-template name="render"><xsl:with-param name="value"><number_of_items json:Array="true">
    <value json:Type="Integer"><xsl:value-of select="count(q:Catalog/q:InBox/a:string)"/></value>
</number_of_items></xsl:with-param></xsl:call-template><xsl:call-template name="render"><xsl:with-param name="value"><batteries_required json:Array="true">
<value>

<xsl:variable name="battery" select="q:Catalog/q:Attributes/q:Attribute[q:Code='BATTYPE']/q:Value/a:string[1]" />

	<xsl:choose>
		<xsl:when test="contains($battery, 'No Battery')">
<xsl:text>False</xsl:text>
		</xsl:when>
		
		
		<xsl:otherwise>
		<xsl:text>True</xsl:text>
		</xsl:otherwise>
	</xsl:choose>


</value>

</batteries_required></xsl:with-param></xsl:call-template><xsl:call-template name="render"><xsl:with-param name="value"><battery json:Array="true">

<capacity json:Array="true">
<value json:Type="Float"><xsl:value-of select="q:Catalog/q:Attributes/q:Attribute[q:Code='BATCAP']/q:Value/a:string[1]" /></value>
<unit>milliampere_hour</unit>
</capacity>

<xsl:variable name='qbat' select="q:Catalog/q:Attributes/q:Attribute[q:Code='BATTYPE']/q:Value/a:string[1]" />
 <cell_composition json:Array="true">
            <value>
                <xsl:choose>
                    <xsl:when test="$qbat ='Lithium-Ion'">lithium_ion</xsl:when>
                    <xsl:when test="$qbat ='Lithium-Metal'">lithium_metal</xsl:when>
                    <xsl:when test="$qbat ='Lithium-Polymer'">lithium_polymer</xsl:when>
                    <xsl:when test="$qbat ='Nickel Cadmium (NICD)'">NiCAD</xsl:when>
                    <xsl:when test="$qbat ='Nickel-Metal Hydride (NIMH)'">NiMh</xsl:when>

                    <xsl:when test="$qbat ='Alkaline'">alkaline</xsl:when>
                    <xsl:when test="$qbat ='Lead-Acid'">lead_acid</xsl:when>
                    <xsl:when test="$qbat ='Sodium-Ion'">sodium_ion</xsl:when>
                    <xsl:when test="$qbat ='Wet-Alkali'">wet_alkali</xsl:when>

                    <xsl:otherwise>
                        <xsl:text>other_than_listed</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </value>
        </cell_composition>


<power json:Array="true">
<value json:Type="Float"><xsl:value-of select="q:Catalog/q:Attributes/q:Attribute[q:Code='BATCAP']/q:Value/a:string[1]" /></value>
<unit>milliampere_hour</unit>
</power >


<weight json:Array="true">
<value json:Type="Float"><xsl:value-of select="q:Catalog/q:Attributes/q:Attribute[q:Code='BATWEIGHT']/q:Value/a:string[1]" /></value>
<unit>ounces</unit>
</weight>
</battery></xsl:with-param></xsl:call-template><xsl:call-template name="render"><xsl:with-param name="value"><batteries_included json:Array="true">
<value>

<xsl:variable name="battery" select="q:Catalog/q:Attributes/q:Attribute[q:Code='BATTYPE']/q:Value/a:string[1]" />

	<xsl:choose>
		<xsl:when test="contains($battery, 'No Battery')">
<xsl:text>False</xsl:text>
		</xsl:when>
		
		
		<xsl:otherwise>
		<xsl:text>True</xsl:text>
		</xsl:otherwise>
	</xsl:choose>


</value>

</batteries_included></xsl:with-param></xsl:call-template><xsl:call-template name="render"><xsl:with-param name="value"><num_batteries json:Array="true">
<quantity>1</quantity>
<type>nonstandard_battery</type>
</num_batteries></xsl:with-param></xsl:call-template><xsl:call-template name="render"><xsl:with-param name="value"><has_multiple_battery_powered_components json:Array="true">
<value>False</value>
</has_multiple_battery_powered_components></xsl:with-param></xsl:call-template><xsl:call-template name="render"><xsl:with-param name="value"><contains_battery_or_cell json:Array="true">
<xsl:variable name="battery" select="q:Catalog/q:Attributes/q:Attribute[q:Code='BATTYPE']/q:Value/a:string[1]" />
<value>
	<xsl:choose>
		<xsl:when test="contains($battery, 'No Battery')">
<xsl:text>cell</xsl:text>
		</xsl:when>
		
		
		<xsl:otherwise>
		<xsl:text>battery</xsl:text>
		</xsl:otherwise>
	</xsl:choose>


</value>
</contains_battery_or_cell></xsl:with-param></xsl:call-template><xsl:call-template name="render"><xsl:with-param name="value"><lithium_battery json:Array="true">
<energy_content  json:Array="true">
<value json:Type="Float"><xsl:value-of select="q:Catalog/q:Attributes/q:Attribute[q:Code='BATCAP']/q:Value/a:string[1]" /></value>
<unit>milliampere_hour</unit>
</energy_content >

<packaging json:Array="true">
<xsl:variable name="packaging" select="q:Catalog/q:Attributes/q:Attribute[q:Code='BATTYPE']/q:Value/a:string[1]" />
<value>
	<xsl:choose>
		<xsl:when test="contains($packaging, '(Not Installed)')">
<xsl:text>batteries_packed_with_equipment</xsl:text>
		</xsl:when>
		
		
		<xsl:otherwise>
		<xsl:text>batteries_contained_in_equipment</xsl:text>
		</xsl:otherwise>
	</xsl:choose>
</value>
</packaging>


<weight json:Array="true">
<value><xsl:value-of select="q:Catalog/q:Attributes/q:Attribute[q:Code='BATWEIGHT']/q:Value/a:string[1]" /></value>
<unit>ounces</unit>
</weight>

</lithium_battery></xsl:with-param></xsl:call-template><xsl:call-template name="render"><xsl:with-param name="value"><number_of_lithium_ion_cells json:Array="true">
<value>
	<xsl:value-of select="q:Catalog/q:Attributes/q:Attribute[q:Code='BATSIZE']/q:Value/a:string[1]" />		
</value>
</number_of_lithium_ion_cells></xsl:with-param></xsl:call-template><xsl:call-template name="render"><xsl:with-param name="value"><!-- installed_in_equipment,installed_in_vehicle,installed_in_vessel,not_installed -->
<battery_installation_device_type json:Array="true">
<xsl:variable name="packaging" select="q:Catalog/q:Attributes/q:Attribute[q:Code='BATTYPE']/q:Value/a:string[1]" />
<value>
	<xsl:choose>
		<xsl:when test="contains($packaging, '(Not Installed)')">
<xsl:text>installed_in_equipment</xsl:text>
		</xsl:when>
		
		
		<xsl:otherwise>
		<xsl:text>not_installed</xsl:text>
		</xsl:otherwise>
	</xsl:choose>
</value>
</battery_installation_device_type></xsl:with-param></xsl:call-template></xsl:template>
<xsl:template match="q:InventoryVirtualResult" mode="ProductType"><xsl:text>CELLULAR_PHONE</xsl:text></xsl:template><xsl:template match="node()" mode="language_tag">en_US</xsl:template>
<xsl:template match="q:InventoryVirtualResult" mode="ItemType">cell-phones</xsl:template>
<xsl:template match="q:InventoryVirtualResult" mode="Filter"><xsl:text>No filter specified (export all)</xsl:text></xsl:template>
<xsl:template match="q:InventoryVirtualResult" mode="bullet_point1" />
<xsl:template match="q:InventoryVirtualResult" mode="bullet_point2" />
<xsl:template match="q:InventoryVirtualResult" mode="bullet_point3" />
<xsl:template match="q:InventoryVirtualResult" mode="bullet_point4" />
<xsl:template match="q:InventoryVirtualResult" mode="bullet_point5" />

</xsl:stylesheet>