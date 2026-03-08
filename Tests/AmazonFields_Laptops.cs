using System.Collections.Generic;
using QuiptMappingEngine.Models;

public static class AmazonFields_Laptops
{
    public static List<Field> Get()
    {
        return new List<Field>
        {
            // Required Amazon fields
            new Field { Name = "item_name", DataType = "required", Path = "properties.item_name" },
            new Field { Name = "brand", DataType = "required", Path = "properties.brand" },
            new Field { Name = "item_type_keyword", DataType = "required", Path = "properties.item_type_keyword" },
            new Field { Name = "product_description", DataType = "required", Path = "properties.product_description" },
            new Field { Name = "bullet_point", DataType = "required", Path = "properties.bullet_point" },
            new Field { Name = "country_of_origin", DataType = "required", Path = "properties.country_of_origin" },
            new Field { Name = "supplier_declared_dg_hz_regulation", DataType = "required", Path = "properties.supplier_declared_dg_hz_regulation" },

            // Common laptop attributes
            new Field { Name = "model_number", DataType = "array", Path = "properties.model_number" },
            new Field { Name = "model_name", DataType = "array", Path = "properties.model.model_name" },
            new Field { Name = "manufacturer", DataType = "array", Path = "properties.manufacturer" },
            new Field { Name = "processor_description", DataType = "array", Path = "properties.processor_description" },
            new Field { Name = "processor_count", DataType = "array", Path = "properties.processor_count" },
            new Field { Name = "graphics_description", DataType = "array", Path = "properties.graphics_description" },
            new Field { Name = "ram_memory", DataType = "array", Path = "properties.ram_memory" },
            new Field { Name = "memory_storage_capacity", DataType = "array", Path = "properties.memory_storage_capacity" },
            new Field { Name = "hard_disk", DataType = "array", Path = "properties.hard_disk" },
            new Field { Name = "solid_state_storage_drive", DataType = "array", Path = "properties.solid_state_storage_drive" },
            new Field { Name = "operating_system", DataType = "array", Path = "properties.operating_system" },
            new Field { Name = "display", DataType = "array", Path = "properties.display" },
            new Field { Name = "resolution", DataType = "array", Path = "properties.resolution" },
            new Field { Name = "color", DataType = "array", Path = "properties.color" },
            new Field { Name = "size", DataType = "array", Path = "properties.size" },

            // Physical attributes
            new Field { Name = "item_weight", DataType = "array", Path = "properties.item_weight" },
            new Field { Name = "item_length", DataType = "array", Path = "properties.item_length" },

            // Connectivity
            new Field { Name = "wireless_comm_standard", DataType = "array", Path = "properties.wireless_comm_standard" },
            new Field { Name = "connectivity_technology", DataType = "array", Path = "properties.connectivity_technology" },
            new Field { Name = "bluetooth_version", DataType = "array", Path = "properties.bluetooth_version" },

            // Images
            new Field { Name = "main_product_image_locator", DataType = "array", Path = "properties.main_product_image_locator" },

            // Warranty
            new Field { Name = "warranty_type", DataType = "array", Path = "properties.warranty_type" },

            // Safety
            new Field { Name = "hazmat", DataType = "array", Path = "properties.hazmat" },
            new Field { Name = "battery", DataType = "array", Path = "properties.battery" },
            new Field { Name = "batteries_required", DataType = "array", Path = "properties.batteries_required" },
            new Field { Name = "batteries_included", DataType = "array", Path = "properties.batteries_included" }
        };
    }
}
