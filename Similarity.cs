public static class Similarity
{
    public static int Levenshtein(string a, string b)
    {
        if (string.IsNullOrEmpty(a)) return b.Length;
        if (string.IsNullOrEmpty(b)) return a.Length;

        int[,] dp = new int[a.Length + 1, b.Length + 1];

        for (int i = 0; i <= a.Length; i++) dp[i, 0] = i;
        for (int j = 0; j <= b.Length; j++) dp[0, j] = j;

        for (int i = 1; i <= a.Length; i++)
        {
            for (int j = 1; j <= b.Length; j++)
            {
                int cost = (a[i - 1] == b[j - 1]) ? 0 : 1;

                dp[i, j] = Math.Min(
                    Math.Min(dp[i - 1, j] + 1, dp[i, j - 1] + 1),
                    dp[i - 1, j - 1] + cost
                );
            }
        }

        return dp[a.Length, b.Length];
    }

    public static double TokenOverlap(string a, string b)
    {
        var t1 = a.Split(new[] { ' ', '-', '_' }, StringSplitOptions.RemoveEmptyEntries);
        var t2 = b.Split(new[] { ' ', '-', '_' }, StringSplitOptions.RemoveEmptyEntries);

        int overlap = t1.Intersect(t2).Count();
        int total = t1.Union(t2).Count();

        return total == 0 ? 0 : (double)overlap / total;
    }
}
