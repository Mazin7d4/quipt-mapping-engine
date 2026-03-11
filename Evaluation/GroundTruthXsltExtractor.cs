using System.Text.RegularExpressions;

namespace QuiptMappingEngine.Evaluation;

public static class GroundTruthXsltExtractor
{
    // Extracts: amazonTagName -> quiptXPath
    // Line-by-line approach to avoid catastrophic regex backtracking on large XSLT files.
    //
    // Strategy:
    // 1. Track opening tags on a stack as we scan lines
    // 2. When we see <xsl:value-of select="q:..."/>, record the innermost enclosing tag
    public static Dictionary<string, string> ExtractFromFile(string xsltPath)
    {
        if (!File.Exists(xsltPath))
            throw new FileNotFoundException($"XSLT not found: {xsltPath}");

        var lines = File.ReadAllLines(xsltPath);
        var dict = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);

        // Regex to find <xsl:value-of select="XPATH" ... />
        var valueOfRx = new Regex(
            @"<xsl:value-of\s+[^>]*select\s*=\s*""(?<path>[^""]+)""",
            RegexOptions.Compiled);

        // Regex to find opening tags like <brand>, <item_weight json:Array="true">, etc.
        // Excludes xsl: tags and self-closing tags.
        var openTagRx = new Regex(
            @"<(?<tag>[a-zA-Z][a-zA-Z0-9_\-]*)(?:\s[^>]*)?>",
            RegexOptions.Compiled);

        // Regex to find closing tags like </brand>
        var closeTagRx = new Regex(
            @"</(?<tag>[a-zA-Z][a-zA-Z0-9_\-]*)>",
            RegexOptions.Compiled);

        // Tags that are structural / not Amazon field names
        var ignoreTags = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
        {
            "xsl", "Root", "header", "messages", "message", "attributes",
            "sellerId", "items", "item", "value", "unit"
        };

        var tagStack = new Stack<string>();

        foreach (var line in lines)
        {
            // Process closing tags first (they may appear on same line)
            foreach (Match cm in closeTagRx.Matches(line))
            {
                var ctag = cm.Groups["tag"].Value;
                if (ctag.StartsWith("xsl:")) continue;

                // Pop until we find the matching open tag (or stack is empty)
                if (tagStack.Count > 0 && tagStack.Peek() == ctag)
                    tagStack.Pop();
            }

            // Check for xsl:value-of on this line
            var vom = valueOfRx.Match(line);
            if (vom.Success)
            {
                var path = vom.Groups["path"].Value.Trim();

                // Only care about Quipt paths (q: namespace)
                if (path.Contains("q:") && tagStack.Count > 0)
                {
                    var parentTag = tagStack.Peek();
                    if (!parentTag.StartsWith("xsl:") && !ignoreTags.Contains(parentTag))
                    {
                        if (!dict.ContainsKey(parentTag))
                            dict[parentTag] = path;
                    }
                }
            }

            // Process opening tags (push non-xsl, non-self-closing tags)
            foreach (Match om in openTagRx.Matches(line))
            {
                var fullMatch = om.Value;
                var otag = om.Groups["tag"].Value;

                if (otag.StartsWith("xsl") || otag == "xsl") continue;
                if (fullMatch.TrimEnd().EndsWith("/>")) continue; // self-closing

                tagStack.Push(otag);
            }
        }

        return dict;
    }
}