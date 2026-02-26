using QuiptMappingEngine.Member4TestHarness;
using QuiptMappingEngine.Services;

var builder = WebApplication.CreateBuilder(args);

// Enable controllers (GenerateController)
builder.Services.AddControllers();

var app = builder.Build();

/*
    MEMBER 4 TEST HARNESS
    Run using:
    dotnet run -- --member4test
*/
if (args.Contains("--member4test"))
{
    Member4QuickTest.Run();
    return; // Stop app after harness runs
}

/*
    TEMP DEMO ENDPOINT (Amazon parser test)
    GET http://localhost:5253/
*/
app.MapGet("/", () =>
{
    var parser = new AmazonFieldParser();
    var filePath = "AmazonTaxonomy/amazon-laptops-attributes.json";

    if (!File.Exists(filePath))
        return Results.Text($"File NOT found at: {filePath}");

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

// Enable your /generate controller route
app.MapControllers();

app.MapGet("/ping", () => "pong");
app.Run();