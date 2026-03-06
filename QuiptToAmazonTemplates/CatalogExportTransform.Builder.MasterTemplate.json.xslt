<!-- All these xsl:stylesheet attributes should be defined in the 'axsl:stylesheet' element of CatalogExportTransform.Builder.xslt file. 
    For proper rendering all xsl:stylesheet attributes changes should be copied to 'axsl:stylesheet' element of Builder template. -->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:msxsl="urn:schemas-microsoft-com:xslt"
                xmlns:q="http://schemas.quipt.com/api"
                xmlns:i="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:a="http://schemas.microsoft.com/2003/10/Serialization/Arrays"
                xmlns:str="http://exslt.org/strings"
                xmlns:json="http://james.newtonking.com/projects/json"
                exclude-result-prefixes="msxsl q str i a">

	<xsl:import href="str.tab.template.xslt" />
	<xsl:import href="str.utility.template.xslt" />
	<xsl:import href="inventory.shared.xslt" />
	<xsl:import href="InventoryCatalogExportTransform.json.Shared.xslt"/>

	<xsl:output method="xml" indent="yes"/>

	<xsl:param name="BypassFilter">1</xsl:param>
	<xsl:param name="Type">XML</xsl:param>
	<xsl:param name="Encoding">UTF-8</xsl:param>
	<xsl:param name="MARKETPLACEID">MKTID</xsl:param>
	<xsl:param name="MERCHANTID">MERID</xsl:param>
	<!-- path to this transform file. Needed to extract all mapped product types from current transform by category id only when no real inventory virtual result item provided. -->
	<xsl:param name="CurrentTransformPath"/>

	<xsl:variable name="separator" select="'&#9;'"/>
	<xsl:variable name="newline" select="'&#x0d;&#x0a;'"/>

	<xsl:param name="Mode"/>

	<!-- TEST TEMPLATES BEGIN -->
	<!-- These templates are for master template testing only and can be removed.
  More specific templates will be appended by builder, so these dummy templates should not affect transformation results. -->
	<xsl:template match="*" mode="ItemType">DummyItemType</xsl:template>
	<xsl:template match="*" mode="ProductType">DummyProductType</xsl:template>
	<xsl:template match="*" mode="Filter">dummy filter (do not filter if template is not empty and produces any text)</xsl:template>

	<xsl:template match="*" mode="language_tag">dummy_en_US</xsl:template>

	<!-- TEST TEMPLATES END -->

	<xsl:template match= "/q:SyncInventoryVirtualResults">
		<xsl:apply-templates select="." mode="shouldExport"/>
	</xsl:template>

	<xsl:template match="/q:ArrayOfInventoryVirtualResult">
		<xsl:choose>
			<xsl:when test="$Mode='GetCategoryId'">
				<xsl:variable name="shouldExport">
					<xsl:apply-templates select="q:InventoryVirtualResult[1]" mode="Filter"/>
				</xsl:variable>
				<xsl:if test="(normalize-space($shouldExport)!='' or string(q:InventoryVirtualResult[1]/q:Summary/q:SKU)='')">
					<xsl:apply-templates select="q:InventoryVirtualResult[1]" mode="GetProductType"/>
				</xsl:if>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="items">
					<xsl:apply-templates select="q:InventoryVirtualResult"/>
				</xsl:variable>
				<xsl:variable name="itemsNodeSet" select="msxsl:node-set($items)"/>
				<xsl:if test="$itemsNodeSet/messages">
					<Root>
						<header>
							<sellerId>
								<xsl:value-of select="$MERCHANTID"/>
							</sellerId>
							<version>2.0</version>
							<issueLocale>
								<xsl:apply-templates select="q:InventoryVirtualResult[1]" mode="language_tag"/>
							</issueLocale>
						</header>
						<xsl:copy-of select="$itemsNodeSet"/>
					</Root>
				</xsl:if>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="q:InventoryVirtualResult" mode="GetProductType">
		<!-- Store additional data for troubleshooting. Only product types required. -->
		<GetConditionsRequest>
			<FeedId>
				<xsl:value-of select="q:Id"/>
			</FeedId>
			<CategoryId>
				<xsl:value-of select="q:Catalog/q:Category/q:Id"/>
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
						<xsl:apply-templates select="$stylesheet" mode="parseProductTypes"/>
					</xsl:otherwise>
				</xsl:choose>
			</ProductTypes>
		</GetConditionsRequest>
	</xsl:template>

	<!-- Match any element that has text content -->
	<xsl:template match="*" mode="text">
		<xsl:apply-templates select="text()" mode="parseProductTypes"/>
		<xsl:apply-templates select="*" mode="parseProductTypes"/>
	</xsl:template>

	<!-- Wrap all text values inside <a:string> -->
	<xsl:template match="text()[normalize-space()]" mode="parseProductTypes">
		<ProductType>
			<xsl:value-of select="."/>
		</ProductType>
	</xsl:template>

	<xsl:template match="q:InventoryVirtualResult">
		<xsl:choose>
			<xsl:when test="normalize-space($BypassFilter) != ''">
				<xsl:apply-templates select="." mode="render">
					<xsl:with-param name="index" select="position()"/>
				</xsl:apply-templates>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="shouldExport">
					<xsl:apply-templates select="." mode="Filter"/>
				</xsl:variable>
				<xsl:variable name="excludeReason">
					<xsl:apply-templates select="." mode="ExcludeReason"/>
				</xsl:variable>
				<xsl:if test="normalize-space($shouldExport)!='' and normalize-space($excludeReason)=''">
					<xsl:apply-templates select="." mode="render">
						<xsl:with-param name="index" select="position()"/>
					</xsl:apply-templates>
				</xsl:if>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="q:InventoryVirtualResult" mode="ExcludeReason">

		<xsl:choose>
			<xsl:when test="$Mode='GetCategoryId'"></xsl:when>
			<xsl:otherwise>
				<xsl:variable name="condition">
					<xsl:apply-templates select="." mode="condition"/>
				</xsl:variable>
				<xsl:if test="normalize-space($condition)=''">
					<xsl:text>Missing condition support for </xsl:text>
					<xsl:value-of select="q:Summary/q:Condition/q:Name"/>
					<xsl:text>. If Certified Refurbished ensure you add brand and category to policy.</xsl:text>
				</xsl:if>
			</xsl:otherwise>
		</xsl:choose>

	</xsl:template>

	<xsl:template match="q:InventoryVirtualResult" mode="render">
		<xsl:param name="index"/>

		<xsl:choose>
			<xsl:when test="$Mode='InvCat'">
				<xsl:apply-templates select="." mode="renderInvCat">
					<xsl:with-param name="index" select="$index"/>
				</xsl:apply-templates>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates select="." mode="renderCat">
					<xsl:with-param name="index" select="$index"/>
				</xsl:apply-templates>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="q:InventoryVirtualResult" mode="renderInvCat">
		<xsl:param name="index"/>
		<xsl:variable name="images">
			<xsl:apply-templates select="q:Catalog" mode="images"/>
		</xsl:variable>
		<xsl:variable name="image-frag" select="msxsl:node-set($images)"/>

		<messages json:Array="true">
			<messageId  json:Type="Integer">
				<xsl:value-of select="$index"/>
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
									<xsl:value-of select="q:MapId"/>
								</value>
								<type>asin</type>
							</xsl:when>
							<xsl:when test="string-length(q:MapId) = 13">
								<value>
									<xsl:value-of select="q:MapId"/>
								</value>
								<type>ean</type>
							</xsl:when>
							<xsl:when test="string-length(q:MapId) = 14">
								<value>
									<xsl:value-of select="q:MapId"/>
								</value>
								<type>gtin</type>
							</xsl:when>
							<xsl:when test="string-length(q:MapId) = 12">
								<value>
									<xsl:value-of select="q:MapId"/>
								</value>
								<type>upc</type>
							</xsl:when>
							<xsl:when test="string-length(q:MapId) = 17">
								<value>
									<xsl:value-of select="q:MapId"/>
								</value>
								<type>isbn</type>
							</xsl:when>
						</xsl:choose>
					</xsl:variable>
					<xsl:variable name="mapIdNodeSet" select="msxsl:node-set($mapId)"/>
					<xsl:variable name="asin">
						<xsl:if test="string($mapIdNodeSet/value)!='' and string($mapIdNodeSet/type)='asin'">
							<xsl:value-of select="$mapIdNodeSet/value"/>
						</xsl:if>
					</xsl:variable>
					<xsl:variable name="product-id">
						<xsl:choose>
							<xsl:when test="string($mapIdNodeSet/value)!='' and string($mapIdNodeSet/type)!='asin'">
								<xsl:value-of select="$mapIdNodeSet/value"/>
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
							<xsl:apply-templates select="." mode="condition"/>
						</xsl:with-param>
						<xsl:with-param name="addLanguage">0</xsl:with-param>
						<xsl:with-param name="addMarketplace">0</xsl:with-param>
					</xsl:call-template>
					<xsl:apply-templates select="." mode="fulfillment_availability"/>
					<xsl:apply-templates select="." mode="purchasable_offer"/>
					<xsl:call-template name="ArrayItem">
						<xsl:with-param name="tagName">merchant_shipping_group</xsl:with-param>
						<xsl:with-param name="value">
							<xsl:apply-templates select="." mode="merchant_shipping_group_name"/>
						</xsl:with-param>
						<xsl:with-param name="addLanguage">0</xsl:with-param>
					</xsl:call-template>
					<xsl:call-template name="ArrayItem">
						<xsl:with-param name="tagName">country_of_origin</xsl:with-param>
						<xsl:with-param name="addLanguage">0</xsl:with-param>
						<xsl:with-param name="value" select="normalize-space(q:Catalog/q:CountryOfOrigin/q:ISO)"/>
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
									<xsl:value-of select="format-number(q:ShippingInfo/q:Dimensions/q:Length,'0.##')"/>
								</value>
								<unit>
									<xsl:value-of select="$dimensionsUnits"/>
								</unit>
							</length>
							<width>
								<value json:Type="Float">
									<xsl:value-of select="format-number(q:ShippingInfo/q:Dimensions/q:Width,'0.##')"/>
								</value>
								<unit>
									<xsl:value-of select="$dimensionsUnits"/>
								</unit>
							</width>
							<height>
								<value json:Type="Float">
									<xsl:value-of select="format-number(q:ShippingInfo/q:Dimensions/q:Height,'0.##')"/>
								</value>
								<unit>
									<xsl:value-of select="$dimensionsUnits"/>
								</unit>
							</height>
						</xsl:with-param>
						<xsl:with-param name="addLanguage">0</xsl:with-param>
					</xsl:call-template>
					<xsl:call-template name="ArrayItem">
						<xsl:with-param name="tagName">item_package_weight</xsl:with-param>
						<xsl:with-param name="value">
							<xsl:value-of select="format-number(q:ShippingInfo/q:Weight/q:Value,'0.##')"/>
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
				<xsl:variable name="preMappedNodeSet" select="msxsl:node-set($preMapped)"/>
				<xsl:variable name="attributes">
					<xsl:apply-templates select="." mode="render-attributes"/>
				</xsl:variable>
				<xsl:variable name="attributesNodeSet" select="msxsl:node-set($attributes)"/>
				<xsl:for-each select="$preMappedNodeSet/node()">
					<!-- allow to override pre-mapped attributes by catalog mapper -->
					<xsl:if test="not($attributesNodeSet/*[name()=name(current())])">
						<xsl:copy-of select="."/>
					</xsl:if>
				</xsl:for-each>
				<!-- for invCat output premapped OFFER attributes only, do not copy the rest -->
				<!--<xsl:copy-of select="$attributesNodeSet/*"/>-->
			</attributes>
		</messages>
	</xsl:template>

	<xsl:template match="q:InventoryVirtualResult" mode="renderCat">
		<xsl:param name="index"/>
		<xsl:variable name="images">
			<xsl:apply-templates select="q:Catalog" mode="images"/>
		</xsl:variable>
		<xsl:variable name="image-frag" select="msxsl:node-set($images)"/>

		<messages json:Array="true">
			<messageId  json:Type="Integer">
				<xsl:value-of select="$index"/>
			</messageId>
			<sku>
				<xsl:value-of select="normalize-space(q:Summary/q:SKU)" />
			</sku>
			<operationType>UPDATE</operationType>
			<productType>
				<xsl:apply-templates select="." mode="ProductType"/>
			</productType>
			<requirements>LISTING</requirements>
			<attributes>
				<xsl:variable name="preMapped">
					<xsl:call-template name="ArrayItem">
						<xsl:with-param name="tagName">item_name</xsl:with-param>
						<xsl:with-param name="maxLength">200</xsl:with-param>
						<xsl:with-param name="value">
							<xsl:call-template name="title"/>
						</xsl:with-param>
					</xsl:call-template>
					<xsl:call-template name="ArrayItem">
						<xsl:with-param name="tagName">brand</xsl:with-param>
						<xsl:with-param name="maxLength">100</xsl:with-param>
						<xsl:with-param name="value" select="normalize-space(q:Catalog/q:Brand/q:Name)"/>
					</xsl:call-template>
					<xsl:call-template name="ArrayItem">
						<xsl:with-param name="tagName">manufacturer</xsl:with-param>
						<xsl:with-param name="maxLength">100</xsl:with-param>
						<xsl:with-param name="value" select="normalize-space(q:Catalog/q:Manufacturer/q:Name)"/>
					</xsl:call-template>
					<xsl:call-template name="ArrayItem">
						<xsl:with-param name="tagName">item_type_keyword</xsl:with-param>
						<xsl:with-param name="maxLength">20090</xsl:with-param>
						<xsl:with-param name="addLanguage">0</xsl:with-param>
						<xsl:with-param name="value">
							<xsl:apply-templates select="." mode="ItemType"/>
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
								<xsl:value-of select="q:Catalog/q:Pricing/q:MSRP/q:Units"/>
							</currency>
						</xsl:with-param>
					</xsl:call-template>
					<xsl:variable name="mapId">
						<xsl:choose>
							<xsl:when test="string-length(q:MapId) = 10 and substring(q:MapId, 1, 1) = 'B'">
								<value>
									<xsl:value-of select="q:MapId"/>
								</value>
								<type>asin</type>
							</xsl:when>
							<xsl:when test="string-length(q:MapId) = 13">
								<value>
									<xsl:value-of select="q:MapId"/>
								</value>
								<type>ean</type>
							</xsl:when>
							<xsl:when test="string-length(q:MapId) = 14">
								<value>
									<xsl:value-of select="q:MapId"/>
								</value>
								<type>gtin</type>
							</xsl:when>
							<xsl:when test="string-length(q:MapId) = 12">
								<value>
									<xsl:value-of select="q:MapId"/>
								</value>
								<type>upc</type>
							</xsl:when>
							<xsl:when test="string-length(q:MapId) = 17">
								<value>
									<xsl:value-of select="q:MapId"/>
								</value>
								<type>isbn</type>
							</xsl:when>
						</xsl:choose>
					</xsl:variable>
					<xsl:variable name="mapIdNodeSet" select="msxsl:node-set($mapId)"/>
					<xsl:variable name="asin">
						<xsl:if test="string($mapIdNodeSet/value)!='' and string($mapIdNodeSet/type)='asin'">
							<xsl:value-of select="$mapIdNodeSet/value"/>
						</xsl:if>
					</xsl:variable>
					<xsl:variable name="product-id">
						<xsl:choose>
							<xsl:when test="string($mapIdNodeSet/value)!='' and string($mapIdNodeSet/type)!='asin'">
								<xsl:value-of select="$mapIdNodeSet/value"/>
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
							<xsl:apply-templates select="." mode="condition"/>
						</xsl:with-param>
						<xsl:with-param name="addLanguage">0</xsl:with-param>
						<xsl:with-param name="addMarketplace">0</xsl:with-param>
					</xsl:call-template>
					<xsl:apply-templates select="." mode="fulfillment_availability"/>
					<xsl:apply-templates select="." mode="purchasable_offer"/>
					<xsl:call-template name="ArrayItem">
						<xsl:with-param name="tagName">merchant_shipping_group</xsl:with-param>
						<xsl:with-param name="value">
							<xsl:apply-templates select="." mode="merchant_shipping_group_name"/>
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
						<xsl:with-param name="value" select="normalize-space(q:Catalog/q:Description)"/>
					</xsl:call-template>
					<xsl:variable name="featuresResult">
						<xsl:call-template name="features">
							<xsl:with-param name="conditionCode" select="q:Catalog/q:Condition/q:Code"/>
							<xsl:with-param name="nodes">
								<feature>
									<xsl:variable name="custom">
										<xsl:apply-templates select="." mode="bullet_point1"/>
									</xsl:variable>
									<xsl:choose>
										<xsl:when test="normalize-space($custom)!=''">
											<xsl:value-of select="normalize-space($custom)"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="normalize-space(q:Catalog/q:Features/a:string[1])"/>
										</xsl:otherwise>
									</xsl:choose>
								</feature>
								<feature>
									<xsl:variable name="custom">
										<xsl:apply-templates select="." mode="bullet_point2"/>
									</xsl:variable>
									<xsl:choose>
										<xsl:when test="normalize-space($custom)!=''">
											<xsl:value-of select="normalize-space($custom)"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="normalize-space(q:Catalog/q:Features/a:string[2])"/>
										</xsl:otherwise>
									</xsl:choose>
								</feature>
								<feature>
									<xsl:variable name="custom">
										<xsl:apply-templates select="." mode="bullet_point3"/>
									</xsl:variable>
									<xsl:choose>
										<xsl:when test="normalize-space($custom)!=''">
											<xsl:value-of select="normalize-space($custom)"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="normalize-space(q:Catalog/q:Features/a:string[3])"/>
										</xsl:otherwise>
									</xsl:choose>
								</feature>
								<feature>
									<xsl:variable name="custom">
										<xsl:apply-templates select="." mode="bullet_point4"/>
									</xsl:variable>
									<xsl:choose>
										<xsl:when test="normalize-space($custom)!=''">
											<xsl:value-of select="normalize-space($custom)"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="normalize-space(q:Catalog/q:Features/a:string[4])"/>
										</xsl:otherwise>
									</xsl:choose>
								</feature>
								<feature>
									<xsl:variable name="custom">
										<xsl:apply-templates select="." mode="bullet_point5"/>
									</xsl:variable>
									<xsl:choose>
										<xsl:when test="normalize-space($custom)!=''">
											<xsl:value-of select="normalize-space($custom)"/>
										</xsl:when>
										<xsl:otherwise>
											<xsl:value-of select="normalize-space(q:Catalog/q:Features/a:string[5])"/>
										</xsl:otherwise>
									</xsl:choose>
								</feature>
								<feature>
									<xsl:value-of select="normalize-space(q:Catalog/q:Features/a:string[6])"/>
								</feature>
								<feature>
									<xsl:value-of select="normalize-space(q:Catalog/q:Features/a:string[7])"/>
								</feature>
								<feature>
									<xsl:value-of select="normalize-space(q:Catalog/q:Features/a:string[8])"/>
								</feature>
								<feature>
									<xsl:value-of select="normalize-space(q:Catalog/q:Features/a:string[9])"/>
								</feature>
								<feature>
									<xsl:value-of select="normalize-space(q:Catalog/q:Features/a:string[10])"/>
								</feature>
							</xsl:with-param>
						</xsl:call-template>
					</xsl:variable>
					<xsl:variable name="features" select="msxsl:node-set($featuresResult)"/>
					<xsl:for-each select="$features/a:string[normalize-space(.)!='']">
						<xsl:if test="position() &lt;= 10">
							<xsl:call-template name="ArrayItem">
								<xsl:with-param name="tagName">bullet_point</xsl:with-param>
								<xsl:with-param name="maxLength">700</xsl:with-param>
								<xsl:with-param name="value" select="."/>
							</xsl:call-template>
						</xsl:if>
					</xsl:for-each>
					<xsl:call-template name="ArrayItem">
						<xsl:with-param name="tagName">generic_keyword</xsl:with-param>
						<xsl:with-param name="maxLength">500</xsl:with-param>
						<xsl:with-param name="value">
							<xsl:for-each select="q:Catalog/q:Tags/a:string[normalize-space(.)!='']">
								<xsl:value-of select="."/>
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
						<xsl:with-param name="value" select="normalize-space(q:Catalog/q:CountryOfOrigin/q:ISO)"/>
					</xsl:call-template>
					<xsl:call-template name="ArrayItem">
						<xsl:with-param name="tagName">warranty_description</xsl:with-param>
						<xsl:with-param name="maxLength">1900</xsl:with-param>
						<xsl:with-param name="value">
							<xsl:choose>
								<xsl:when test="q:Catalog/q:Warranty/q:Provider = 'Manufacturer'">
									<xsl:text>The warranty is covered by the manufacturer for </xsl:text>
									<xsl:value-of select="normalize-space(q:Catalog/q:Warranty/q:Duration)"/>
									<xsl:text>.</xsl:text>
								</xsl:when>
								<xsl:when test="q:Catalog/q:Warranty/q:Provider = 'Distributor'">
									<xsl:text>The warranty is through us for </xsl:text>
									<xsl:value-of select="normalize-space(q:Catalog/q:Warranty/q:Duration)"/>
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
								<xsl:value-of select="$image-frag/image[@type='primary']"/>
							</media_location>
						</xsl:with-param>
						<xsl:with-param name="addLanguage">0</xsl:with-param>
					</xsl:call-template>
					<xsl:call-template name="ArrayItem">
						<xsl:with-param name="tagName">other_product_image_locator_1</xsl:with-param>
						<xsl:with-param name="additionalNodes">
							<media_location>
								<xsl:value-of select="$image-frag/image[@type='secondary'][1]"/>
							</media_location>
						</xsl:with-param>
						<xsl:with-param name="addLanguage">0</xsl:with-param>
					</xsl:call-template>
					<xsl:call-template name="ArrayItem">
						<xsl:with-param name="tagName">other_product_image_locator_2</xsl:with-param>
						<xsl:with-param name="additionalNodes">
							<media_location>
								<xsl:value-of select="$image-frag/image[@type='secondary'][2]"/>
							</media_location>
						</xsl:with-param>
						<xsl:with-param name="addLanguage">0</xsl:with-param>
					</xsl:call-template>
					<xsl:call-template name="ArrayItem">
						<xsl:with-param name="tagName">other_product_image_locator_3</xsl:with-param>
						<xsl:with-param name="additionalNodes">
							<media_location>
								<xsl:value-of select="$image-frag/image[@type='secondary'][3]"/>
							</media_location>
						</xsl:with-param>
						<xsl:with-param name="addLanguage">0</xsl:with-param>
					</xsl:call-template>
					<xsl:call-template name="ArrayItem">
						<xsl:with-param name="tagName">other_product_image_locator_4</xsl:with-param>
						<xsl:with-param name="additionalNodes">
							<media_location>
								<xsl:value-of select="$image-frag/image[@type='secondary'][4]"/>
							</media_location>
						</xsl:with-param>
						<xsl:with-param name="addLanguage">0</xsl:with-param>
					</xsl:call-template>
					<xsl:call-template name="ArrayItem">
						<xsl:with-param name="tagName">other_product_image_locator_5</xsl:with-param>
						<xsl:with-param name="additionalNodes">
							<media_location>
								<xsl:value-of select="$image-frag/image[@type='secondary'][5]"/>
							</media_location>
						</xsl:with-param>
						<xsl:with-param name="addLanguage">0</xsl:with-param>
					</xsl:call-template>
					<xsl:call-template name="ArrayItem">
						<xsl:with-param name="tagName">other_product_image_locator_6</xsl:with-param>
						<xsl:with-param name="additionalNodes">
							<media_location>
								<xsl:value-of select="$image-frag/image[@type='secondary'][6]"/>
							</media_location>
						</xsl:with-param>
						<xsl:with-param name="addLanguage">0</xsl:with-param>
					</xsl:call-template>
					<xsl:call-template name="ArrayItem">
						<xsl:with-param name="tagName">other_product_image_locator_7</xsl:with-param>
						<xsl:with-param name="additionalNodes">
							<media_location>
								<xsl:value-of select="$image-frag/image[@type='secondary'][7]"/>
							</media_location>
						</xsl:with-param>
						<xsl:with-param name="addLanguage">0</xsl:with-param>
					</xsl:call-template>
					<xsl:call-template name="ArrayItem">
						<xsl:with-param name="tagName">other_product_image_locator_8</xsl:with-param>
						<xsl:with-param name="additionalNodes">
							<media_location>
								<xsl:value-of select="$image-frag/image[@type='secondary'][8]"/>
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
									<xsl:value-of select="format-number(q:ShippingInfo/q:Dimensions/q:Length,'0.##')"/>
								</value>
								<unit>
									<xsl:value-of select="$dimensionsUnits"/>
								</unit>
							</length>
							<width>
								<value json:Type="Float">
									<xsl:value-of select="format-number(q:ShippingInfo/q:Dimensions/q:Width,'0.##')"/>
								</value>
								<unit>
									<xsl:value-of select="$dimensionsUnits"/>
								</unit>
							</width>
							<height>
								<value json:Type="Float">
									<xsl:value-of select="format-number(q:ShippingInfo/q:Dimensions/q:Height,'0.##')"/>
								</value>
								<unit>
									<xsl:value-of select="$dimensionsUnits"/>
								</unit>
							</height>
						</xsl:with-param>
						<xsl:with-param name="addLanguage">0</xsl:with-param>
					</xsl:call-template>
					<xsl:call-template name="ArrayItem">
						<xsl:with-param name="tagName">item_package_weight</xsl:with-param>
						<xsl:with-param name="value">
							<xsl:value-of select="format-number(q:ShippingInfo/q:Weight/q:Value,'0.##')"/>
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
				<xsl:variable name="preMappedNodeSet" select="msxsl:node-set($preMapped)"/>
				<xsl:variable name="attributes">
					<xsl:apply-templates select="." mode="render-attributes"/>
				</xsl:variable>
				<xsl:variable name="attributesNodeSet" select="msxsl:node-set($attributes)"/>
				<xsl:for-each select="$preMappedNodeSet/node()">
					<!-- allow to override pre-mapped attributes by catalog mapper -->
					<xsl:if test="not($attributesNodeSet/*[name()=name(current())])">
						<xsl:copy-of select="."/>
					</xsl:if>
				</xsl:for-each>
				<xsl:copy-of select="$attributesNodeSet/*"/>
			</attributes>
		</messages>
	</xsl:template>

	<xsl:template match="q:CountryOfOrigin">
		<xsl:choose>
			<xsl:when test="normalize-space(q:Name) = 'Peoples Republic of China'">China</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="normalize-space(q:Name)"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="title">
		<xsl:variable name="title">
			<xsl:value-of select="normalize-space(q:Catalog/q:Title)"/>
			<!--<xsl:apply-templates select="." mode="Title"/>-->
		</xsl:variable>
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
			<xsl:when test="$restoredPrem = 1 and q:Summary/q:Condition/q:Code = 'REFURBMAN'">
				<xsl:value-of select="concat(normalize-space($title), ' (Renewed Premium)')"/>
			</xsl:when>
			<xsl:when test="$restoredPrem = 1 and q:Summary/q:Condition/q:Code = 'REFURB3RD'">
				<xsl:value-of select="concat(normalize-space($title), ' (Renewed Premium)')"/>
			</xsl:when>
			<xsl:when test="$restoredPrem = 1 and q:Summary/q:Condition/q:Code = 'SCRADDNT'">
				<xsl:value-of select="concat(normalize-space($title), ' (Renewed Premium)')"/>
			</xsl:when>

			<xsl:when test="$restored = 1 and q:Summary/q:Condition/q:Code = 'REFURBMAN'">
				<xsl:value-of select="concat(normalize-space($title), ' (Renewed)')"/>
			</xsl:when>
			<xsl:when test="$restored = 1 and q:Summary/q:Condition/q:Code = 'REFURB3RD'">
				<xsl:value-of select="concat(normalize-space($title), ' (Renewed)')"/>
			</xsl:when>
			<xsl:when test="$restored = 1 and q:Summary/q:Condition/q:Code = 'SCRADDNT'">
				<xsl:value-of select="concat(normalize-space($title), ' (Renewed)')"/>
			</xsl:when>

			<xsl:when test="$certRfbCat = 1 and $certRfbBrnd = 1 and q:Summary/q:Condition/q:Code = 'REFURBMAN'">
				<xsl:value-of select="concat(normalize-space($title), ' (Renewed)')"/>
			</xsl:when>
			<xsl:when test="$certRfbCat = 1 and $certRfbBrnd = 1 and q:Summary/q:Condition/q:Code = 'REFURB3RD'">
				<xsl:value-of select="concat(normalize-space($title), ' (Renewed)')"/>
			</xsl:when>
			<xsl:when test="$certRfbCat = 1 and $certRfbBrnd = 1 and q:Summary/q:Condition/q:Code = 'SCRADDNT'">
				<xsl:value-of select="concat(normalize-space($title), ' (Renewed)')"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$title"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="replace">
		<xsl:param name="from"/>
		<xsl:param name="text"/>
		<xsl:param name="replaceBy"/>
		<xsl:choose>
			<xsl:when test="contains($from,$text)">
				<xsl:variable name="result">
					<xsl:value-of select="substring-before($from,$text)"/>
					<xsl:value-of select="$replaceBy"/>
					<xsl:value-of select="substring-after($from,$text)"/>
				</xsl:variable>
				<xsl:value-of select="normalize-space($result)"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$from"/>
			</xsl:otherwise>
		</xsl:choose>
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

	<!--Template to render attribute from the Builder-->
	<xsl:template name="render">
		<xsl:param name="value"/>
		<xsl:copy-of select="msxsl:node-set($value)"/>
	</xsl:template>

	<!-- End of shared part of .MasterTemplate. Templates below are category-specific and were auto-generated by Builder template. -->
</xsl:stylesheet>
