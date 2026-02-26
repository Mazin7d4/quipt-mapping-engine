using QuiptMappingEngine.Member4TestHarness;
using QuiptMappingEngine.Services;

var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.UseHttpsRedirection();

if (args.Contains("--member4test"))
{
    Member4QuickTest.Run();
}

//creating a browser endpoint
app.MapGet("/", () =>
{
    var parser = new AmazonFieldParser();
    var filePath = "AmazonTaxonomy/amazon-laptops-attributes.json";

    if (!File.Exists(filePath))
    {
        return Results.Text($"File NOT found at: {filePath}");
    }

    try
    {
        var fields = parser.Parse(filePath);

        var result = "";

        foreach (var f in fields)
        {
            result += $"Name: {f.Name}\n";
            result += $"Path: {f.Path}\n";
            result += $"Type: {f.DataType}\n";
            result += $"Required: {f.IsRequired}\n";
            result += "------------------------------\n";
        }

        return Results.Text(result);
    }
    catch (Exception ex)
    {
        return Results.Text($"ERROR:\n{ex.Message}");
    }
});

app.Run();