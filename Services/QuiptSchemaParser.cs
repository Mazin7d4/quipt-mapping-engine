using System.Xml.Linq;
using QuiptMappingEngine.Models;

namespace QuiptMappingEngine.Services;

public class QuiptSchemaParser
{
    public List<Field> ParseFields(string xmlFilePath)
    {
        var doc = XDocument.Load(xmlFilePath);
        if (doc.Root == null)
            return new List<Field>();

        // Root namespace for Quipt XML
        XNamespace rootNs = doc.Root.Name.Namespace;

        // We'll use a consistent prefix for this namespace in paths
        const string prefix = "q";

        // Collect values per unique leaf path
        var valueMap = new Dictionary<string, List<string>>(StringComparer.OrdinalIgnoreCase);

        foreach (var el in doc.Root.DescendantsAndSelf())
        {
            // Only leaf elements (no child elements)
            if (el.Elements().Any())
                continue;

            var path = BuildPath(el, rootNs, prefix);

            if (!valueMap.ContainsKey(path))
                valueMap[path] = new List<string>();

            var value = el.Value?.Trim();
            if (!string.IsNullOrWhiteSpace(value))
                valueMap[path].Add(value);
        }

        // Build final Field list (one Field per unique path)
        var fields = new List<Field>();

        foreach (var kvp in valueMap)
        {
            var path = kvp.Key;
            var distinctValues = kvp.Value
                .Where(v => !string.IsNullOrWhiteSpace(v))
                .Select(v => v.Trim())
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .ToList();

            fields.Add(new Field
            {
                // Leaf element name is last segment of the path
                Name = GetLeafName(path),
                Path = path,

                // Auto-detect basic type from observed values
                DataType = DetectDataType(distinctValues),

                // Quipt required fields are not defined here; Amazon required comes from Amazon JSON
                IsRequired = false,

                // Infer enum values if small set (heuristic)
                EnumValues = InferEnumValues(distinctValues)
            });
        }

        return fields;
    }

    private static string GetLeafName(string path)
    {
        // Example: ".../q:Vendor/q:Id" -> "Id"
        var last = path.Split('/').LastOrDefault() ?? "";
        return last.Replace("q:", "", StringComparison.OrdinalIgnoreCase);
    }

    private static List<string>? InferEnumValues(List<string> distinctValues)
    {
        // Heuristic: if there are 2–10 distinct values, treat as enum
        // (1 value often means sample data, not a real enum)
        if (distinctValues.Count >= 2 && distinctValues.Count <= 10)
            return distinctValues;

        return null;
    }

    private static string DetectDataType(List<string> values)
    {
        // If no values, we can't infer — default to string
        if (values.Count == 0)
            return "string";

        // Try int
        if (values.All(v => int.TryParse(v, out _)))
            return "int";

        // Try decimal
        if (values.All(v => decimal.TryParse(v, out _)))
            return "decimal";

        // Try bool
        if (values.All(v => bool.TryParse(v, out _)))
            return "bool";

        // Otherwise string
        return "string";
    }

    private static string BuildPath(XElement element, XNamespace rootNs, string prefix)
    {
        var stack = new Stack<string>();
        XElement? current = element;

        while (current != null)
        {
            var ns = current.Name.Namespace;

            string step = (ns == rootNs)
                ? $"{prefix}:{current.Name.LocalName}"
                : current.Name.LocalName;

            stack.Push(step);
            current = current.Parent;
        }

        return string.Join("/", stack);
    }
}