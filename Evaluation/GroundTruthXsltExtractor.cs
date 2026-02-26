using System.Text.RegularExpressions;

namespace QuiptMappingEngine.Evaluation;

public static class GroundTruthXsltExtractor
{
    // Extracts: amazonTagName -> quiptXPath
    // Looks for patterns like:
    // <brand>
    //   <xsl:value-of select="q:Catalog/q:Brand/q:Name"/>
    // </brand>
    public static Dictionary<string, string> ExtractFromFile(string xsltPath)
    {
        if (!File.Exists(xsltPath))
            throw new FileNotFoundException($"XSLT not found: {xsltPath}");

        var text = File.ReadAllText(xsltPath);

        // Matches:
        // <tagName> ... <xsl:value-of select="SOMEPATH" .../> ... </tagName>
        // Non-greedy between tag and value-of, and between value-of and closing tag.
        var pattern =
            @"<(?<tag>[a-zA-Z0-9_\-]+)\b[^>]*>\s*.*?<xsl:value-of\s+[^>]*select\s*=\s*""(?<path>[^""]+)""[^>]*/>\s*.*?</\k<tag>>";

        var matches = Regex.Matches(text, pattern, RegexOptions.Singleline);

        var dict = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);

        foreach (Match m in matches)
        {
            var tag = m.Groups["tag"].Value.Trim();
            var path = m.Groups["path"].Value.Trim();

            // Keep first mapping if duplicates appear (can adjust later)
            if (!dict.ContainsKey(tag))
                dict[tag] = path;
        }

        return dict;
    }
}