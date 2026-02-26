using System.Collections.Generic;

public static class QuiptFields_Laptops
{
    public static List<Field> GetFields()
    {
        return new List<Field>
        {
            new Field {
                Name = "Units",
                DataType = "string",
                XPath = "q:ArrayOfInventoryVirtualResult/q:InventoryVirtualResult/q:ARP/q:Units"
            },
            new Field {
                Name = "Value",
                DataType = "decimal",
                XPath = "q:ArrayOfInventoryVirtualResult/q:InventoryVirtualResult/q:ARP/q:Value",
                EnumValues = new List<string> { "214.9900", "279.9900", "274.9900" }
            },
            new Field {
                Name = "Description",
                DataType = "string",
                XPath = "q:ArrayOfInventoryVirtualResult/q:InventoryVirtualResult/q:Catalog/q:AdditionalImages/q:Asset/q:Description"
            },
            new Field {
                Name = "Height",
                DataType = "string",
                XPath = "q:ArrayOfInventoryVirtualResult/q:InventoryVirtualResult/q:Catalog/q:AdditionalImages/q:Asset/q:Height"
            },
            new Field {
                Name = "BrandName",
                DataType = "string",
                XPath = "q:ArrayOfInventoryVirtualResult/q:InventoryVirtualResult/q:Catalog/q:Brand/q:Name",
                EnumValues = new List<string> { "Dell", "HP", "Lenovo" }
            },
            new Field {
                Name = "WeightValue",
                DataType = "decimal",
                XPath = "q:ArrayOfInventoryVirtualResult/q:InventoryVirtualResult/q:Catalog/q:Weight/q:Value",
                EnumValues = new List<string> { "4.0000", "3.9500", "7.0000" }
            },
            new Field {
                Name = "DimensionsHeight",
                DataType = "decimal",
                XPath = "q:ArrayOfInventoryVirtualResult/q:InventoryVirtualResult/q:Catalog/q:Dimensions/q:Height",
                EnumValues = new List<string> { "5.00", "2.70", "6.00" }
            },
            new Field {
                Name = "DimensionsLength",
                DataType = "decimal",
                XPath = "q:ArrayOfInventoryVirtualResult/q:InventoryVirtualResult/q:Catalog/q:Dimensions/q:Length",
                EnumValues = new List<string> { "18.00", "17.70", "14.00" }
            },
            new Field {
                Name = "DimensionsWidth",
                DataType = "decimal",
                XPath = "q:ArrayOfInventoryVirtualResult/q:InventoryVirtualResult/q:Catalog/q:Dimensions/q:Width",
                EnumValues = new List<string> { "14.00", "11.90" }
            }
        };
    }
}
