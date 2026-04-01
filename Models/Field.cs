namespace QuiptMappingEngine.Models;

public class Field
{
    public string Name { get; set; } = "";
    public string Path { get; set; } = "";
    public string DataType { get; set; } = "";
    public bool IsRequired { get; set; }
    public List<string>? EnumValues { get; set; }
}
