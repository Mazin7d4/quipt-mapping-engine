public class Field
{
    public string Name { get; set; }
    public string DataType { get; set; }
    public string XPath { get; set; }
    public List<string> EnumValues { get; set; } = new();
}
