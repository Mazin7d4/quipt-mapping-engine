using System.Xml.Linq;

namespace QuiptMappingEngine.Evaluation;

public static class GroundTruthXsltExtractor
{
    // Extracts: amazonTagName -> quiptXPath
    // We look for <xsl:value-of select="..."> and use the closest non-xsl parent element name as the Amazon tag.
    public static Dictionary<string, string> ExtractFromFile(string xsltPath)
    {
        if (!File.Exists(xsltPath))
            throw new FileNotFoundException($"XSLT not found: {xsltPath}");

        var doc = XDocument.Load(xsltPath);

        XNamespace xsl = "http://www.w3.org/1999/XSL/Transform";

        var dict = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);

        // Find all <xsl:value-of .../>
        var valueOfNodes = doc.Descendants(xsl + "value-of");

        foreach (var valueOf in valueOfNodes)
        {
            var selectAttr = valueOf.Attribute("select")?.Value?.Trim();
            if (string.IsNullOrWhiteSpace(selectAttr))
                continue;

            // Find the nearest ancestor that is NOT an xsl element.
            // That ancestor's name is the Amazon output tag.
            var amazonTag = valueOf
                .Ancestors()
                .FirstOrDefault(a => a.Name.Namespace != xsl);

            if (amazonTag == null)
                continue;

            var tagName = amazonTag.Name.LocalName.Trim();
            if (string.IsNullOrWhiteSpace(tagName))
                continue;

            // Keep first mapping if duplicates exist
            if (!dict.ContainsKey(tagName))
                dict[tagName] = selectAttr;
        }

        return dict;
    }
}