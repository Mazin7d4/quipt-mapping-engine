
using QuiptMappingEngine.Models;
using System.Text.Json;

namespace QuiptMappingEngine.Services
{
    public class AmazonFieldParser
    {
        public List<Field> Parse(string filePath)
        {
            var json = File.ReadAllText(filePath);

            using JsonDocument doc = JsonDocument.Parse(json);

            var root = doc.RootElement;

            var fields = new List<Field>();

            // Get required fields list
            var requiredFields = new HashSet<string>();

            if (root.TryGetProperty("required", out JsonElement requiredElement))
            {
                foreach (var item in requiredElement.EnumerateArray())
                {
                    requiredFields.Add(item.GetString() ?? "");
                }
            }

            // Get properties
            if (root.TryGetProperty("properties", out JsonElement properties))
            {
                foreach (var prop in properties.EnumerateObject())
                {
                    var field = new Field();

                    field.Name = prop.Name;
                    field.Path = $"properties.{prop.Name}";
                    field.IsRequired = requiredFields.Contains(prop.Name);

                    var value = prop.Value;

                    // Data Type
                    if (value.TryGetProperty("type", out JsonElement typeElement))
                    {
                        field.DataType = typeElement.GetString() ?? "";
                    }

                    // Enum values
                    if (value.TryGetProperty("enum", out JsonElement enumElement))
                    {
                        var enums = new List<string>();

                        foreach (var e in enumElement.EnumerateArray())
                        {
                            enums.Add(e.ToString());
                        }

                        field.EnumValues = enums;
                    }

                    fields.Add(field);
                }
            }

            return fields;
        }
    }
}