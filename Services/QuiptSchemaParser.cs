using System;
using System.Collections.Generic;
using System.Linq;
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

        XNamespace rootNs = doc.Root.Name.Namespace;
        const string prefix = "q";

        var fields = new List<Field>();

        foreach (var el in doc.Root.DescendantsAndSelf())
        {
            if (el.Elements().Any())
                continue;

            var path = BuildPath(el, rootNs, prefix);

            fields.Add(new Field
            {
                Name = el.Name.LocalName,
                Path = path,
                DataType = "",
                IsRequired = false,
                EnumValues = null
            });
        }

        return fields
            .GroupBy(f => f.Path)
            .Select(g => g.First())
            .ToList();
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