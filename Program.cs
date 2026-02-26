using System;
using System.Collections.Generic;

class Program
{
    static void Main()
    {
        // Load real parsed fields 
        var quiptFields = QuiptFields_Laptops.GetFields();
        var amazonFields = AmazonFields_Laptops.Get();

        var engine = new MatchingEngine();
        var results = engine.Match(quiptFields, amazonFields);

        Console.WriteLine("=== REAL MATCHING RESULTS (Laptops) ===");
        foreach (var r in results)
        {
            Console.WriteLine($"Amazon: {r.AmazonField}");
            Console.WriteLine($"Required: {r.IsRequired}");
            Console.WriteLine($"Matched Quipt: {r.QuiptField ?? "NULL"}");
            Console.WriteLine($"Score: {r.Score:F3}");
            Console.WriteLine($"Unmatched: {r.IsUnmatched}");
            Console.WriteLine("----------------------------");
        }
    }
}
