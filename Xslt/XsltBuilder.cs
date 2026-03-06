using System.Text;
using QuiptMappingEngine.Models;

namespace QuiptMappingEngine.Xslt
{
    public class XsltBuilder
    {
        public string Build(string category, List<MappingResult> mappings)
        {
            var sb = new StringBuilder();

            sb.AppendLine(@"<xsl:stylesheet version=""1.0"" 
xmlns:xsl=""http://www.w3.org/1999/XSL/Transform"">");
            sb.AppendLine(@"<xsl:output method=""xml"" indent=""yes""/>");
            sb.AppendLine(@"<xsl:template match=""/"">");
            sb.AppendLine("<Root>");
            sb.AppendLine("<attributes>");

            foreach (var map in mappings)
            {
                if (!string.IsNullOrWhiteSpace(map.QuiptPath))
                {
                    sb.AppendLine($"<{map.AmazonField}>");
                    sb.AppendLine($"  <xsl:value-of select=\"{map.QuiptPath}\"/>");
                    sb.AppendLine($"</{map.AmazonField}>");
                }
                else if (map.IsRequired)
                {
                    sb.AppendLine($"<!-- Unmatched Required Field: {map.AmazonField} -->");
                }
            }

            sb.AppendLine("</attributes>");
            sb.AppendLine("</Root>");
            sb.AppendLine("</xsl:template>");
            sb.AppendLine("</xsl:stylesheet>");

            return sb.ToString();
        }
    }
}