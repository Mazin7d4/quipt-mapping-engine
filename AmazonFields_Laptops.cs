using System.Collections.Generic;

public static class AmazonFields_Laptops
{
    public static List<Field> Get()
    {
        return new List<Field>
        {
            // Required Amazon fields
            new Field { Name = "item_name", DataType = "required", XPath = "properties.item_name" },
            new Field { Name = "brand", DataType = "required", XPath = "properties.brand" },
            new Field { Name = "item_type_keyword", DataType = "required", XPath = "properties.item_type_keyword" },
            new Field { Name = "product_description", DataType = "required", XPath = "properties.product_description" },
            new Field { Name = "bullet_point", DataType = "required", XPath = "properties.bullet_point" },
            new Field { Name = "country_of_origin", DataType = "required", XPath = "properties.country_of_origin" },
            new Field { Name = "supplier_declared_dg_hz_regulation", DataType = "required", XPath = "properties.supplier_declared_dg_hz_regulation" },

            // Common laptop attributes
            new Field { Name = "model_number", DataType = "array", XPath = "properties.model_number" },
            new Field { Name = "model_name", DataType = "array", XPath = "properties.model.model_name" },
            new Field { Name = "manufacturer", DataType = "array", XPath = "properties.manufacturer" },
            new Field { Name = "processor_description", DataType = "array", XPath = "properties.processor_description" },
            new Field { Name = "processor_count", DataType = "array", XPath = "properties.processor_count" },
            new Field { Name = "graphics_description", DataType = "array", XPath = "properties.graphics_description" },
            new Field { Name = "ram_memory", DataType = "array", XPath = "properties.ram_memory" },
            new Field { Name = "memory_storage_capacity", DataType = "array", XPath = "properties.memory_storage_capacity" },
            new Field { Name = "hard_disk", DataType = "array", XPath = "properties.hard_disk" },
            new Field { Name = "solid_state_storage_drive", DataType = "array", XPath = "properties.solid_state_storage_drive" },
            new Field { Name = "operating_system", DataType = "array", XPath = "properties.operating_system" },
            new Field { Name = "display", DataType = "array", XPath = "properties.display" },
            new Field { Name = "resolution", DataType = "array", XPath = "properties.resolution" },
            new Field { Name = "color", DataType = "array", XPath = "properties.color" },
            new Field { Name = "size", DataType = "array", XPath = "properties.size" },

            // Physical attributes
            new Field { Name = "item_weight", DataType = "array", XPath = "properties.item_weight" },
            new Field { Name = "item_length", DataType = "array", XPath = "properties.item_length" },

            // Connectivity
            new Field { Name = "wireless_comm_standard", DataType = "array", XPath = "properties.wireless_comm_standard" },
            new Field { Name = "connectivity_technology", DataType = "array", XPath = "properties.connectivity_technology" },
            new Field { Name = "bluetooth_version", DataType = "array", XPath = "properties.bluetooth_version" },

            // Images
            new Field { Name = "main_product_image_locator", DataType = "array", XPath = "properties.main_product_image_locator" },

            // Warranty
            new Field { Name = "warranty_type", DataType = "array", XPath = "properties.warranty_type" },

            // Safety
            new Field { Name = "hazmat", DataType = "array", XPath = "properties.hazmat" },
            new Field { Name = "battery", DataType = "array", XPath = "properties.battery" },
            new Field { Name = "batteries_required", DataType = "array", XPath = "properties.batteries_required" },
            new Field { Name = "batteries_included", DataType = "array", XPath = "properties.batteries_included" }
        };
    }
}
