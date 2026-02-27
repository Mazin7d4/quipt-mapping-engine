using System.Linq;
using QuiptMappingEngine.Services;
var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseHttpsRedirection();

var summaries = new[]
{
    "Freezing", "Bracing", "Chilly", "Cool", "Mild", "Warm", "Balmy", "Hot", "Sweltering", "Scorching"
};

app.MapGet("/weatherforecast", () =>
{
    var forecast =  Enumerable.Range(1, 5).Select(index =>
        new WeatherForecast
        (
            DateOnly.FromDateTime(DateTime.Now.AddDays(index)),
            Random.Shared.Next(-20, 55),
            summaries[Random.Shared.Next(summaries.Length)]
        ))
        .ToArray();
    return forecast;
})
.WithName("GetWeatherForecast");


// ===============================
// Quipt Schema Parser
// ===============================

app.MapGet("/quipt-schema", () =>
{
    var parser = new QuiptSchemaParser();

    // Change filename to Desktops.xml / Monitors.xml when needed
    var filePath = @"QuiptData\Laptops.xml";

    if (!File.Exists(filePath))
        return Results.Text($"File NOT found at: {filePath}");

    try
    {
        var fields = parser.ParseFields(filePath);

        var result = "";

        foreach (var f in fields.OrderBy(x => x.Path))
        {
            result += $"Name: {f.Name}\n";
            result += $"Path: {f.Path}\n";           // Path = XPath-like string
            result += $"Type: {f.DataType}\n";
            result += $"Required: {f.IsRequired}\n";

            if (f.EnumValues != null && f.EnumValues.Count > 0)
                result += $"EnumValues: {string.Join(", ", f.EnumValues)}\n";

            result += "-------------------------\n";
        }

        result += $"\nTotal Fields: {fields.Count}\n";
        return Results.Text(result);
    }
    catch (Exception ex)
    {
        return Results.Text($"ERROR:\n{ex.Message}");
    }
});

app.Run();

record WeatherForecast(DateOnly Date, int TemperatureC, string? Summary)
{
    public int TemperatureF => 32 + (int)(TemperatureC / 0.5556);
}