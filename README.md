# Quipt Mapping Engine

## Overview

Quipt Mapping Engine is a .NET 10 Web API that **automatically generates XSLT transformations** between Quipt product XML and external marketplace schemas. The goal is to replace the manual process of writing XSLT mappings for each marketplace/category combination with an inference-based approach.

Currently supports **Amazon** across 3 product categories. **eBay** is not started yet.

### How It Works (End-to-End)

```
POST /generate  { "category": "laptops" }
        │
        ▼
┌─────────────────┐     ┌──────────────────┐
│ QuiptSchemaParser│     │ AmazonFieldParser │
│ (Quipt XML)     │     │ (Amazon JSON)     │
└────────┬────────┘     └────────┬──────────┘
         │  List<Field>          │  List<Field>
         └──────────┬────────────┘
                    ▼
          ┌──────────────────┐
          │  MatchingEngine   │
          │  (heuristic       │
          │   scoring)        │
          └────────┬─────────┘
                   │  List<MappingResult>
          ┌────────┴─────────────────────┐
          ▼                              ▼
┌──────────────────┐         ┌────────────────────────┐
│  XsltBuilder      │         │  EvaluationService      │
│  (generates XSLT) │         │  (compares vs manual    │
└────────┬─────────┘         │   XSLT ground truth)    │
         │                    └────────┬───────────────┘
         └──────────┬─────────────────┘
                    ▼
            API JSON Response
    (xslt, mappings, accuracy, per-field verdicts)
```

---

## Current Progress

### What's Working

- **Amazon field parsing** — reads JSON taxonomy files in `AmazonTaxonomy/` and extracts fields with name, type, required flag, and enum values
- **Quipt XML parsing** — two-pass parser that extracts both structured `<Attribute>` fields (by Code) and regular leaf elements from XML in `QuiptData/`
- **Matching engine** — multi-signal heuristic scorer with token overlap, Levenshtein, substring matching, enum overlap, unit similarity, and specificity penalties
- **1:1 matching** — each Quipt field can only be matched to one Amazon field (prevents duplicates)
- **XSLT generation** — produces a basic but valid XSLT from the matched pairs
- **Ground truth evaluation** — extracts expected mappings from the manually-written XSLT files in `QuiptToAmazonTemplates/` and compares against auto-generated matches
- **Per-field verdict system** — each field gets a verdict: `CORRECT`, `WRONG`, `MISSING`, `UNMATCHED`, or `NO_GROUND_TRUTH`
- **Normalization dictionary** — ~120 synonym entries mapping Quipt attribute codes and domain terms to canonical forms

### Latest Test Results (Amazon)

| Category     | Accuracy | Required Coverage | Correct Matches | Total Matched |
|-------------|----------|-------------------|-----------------|---------------|
| Laptops     | 1.96%    | 71.43%            | 4 / 204         | 71            |
| Desktops    | 1.80%    | 71.43%            | 3 / 167         | 58            |
| Smartphones | 0.00%    | 71.43%            | 0 / 173         | 51            |

**Note:** Accuracy is computed over ALL Amazon fields (167–204), but only 19–24 have ground truth entries. So the theoretical maximum accuracy with current ground truth is ~12%. A more meaningful metric is the per-field verdict breakdown visible in the API response.

### What's NOT Done Yet

- **eBay marketplace** — no parser, no taxonomy files, no templates. Fully missing.
- **Accuracy is still low** — the matching engine matches most fields to *something*, but many matches are wrong compared to ground truth
- **Ground truth key mismatch** — ~13 of 24 ground truth keys extracted from XSLT don't line up with Amazon field names (different naming conventions between the XSLT tags and the JSON property names)
- **XSLT output is basic** — generates a flat structure; doesn't handle nested JSON arrays, conditional logic, or the complex structure seen in the manual XSLT templates
- **No unit tests** — `Tests/` folder exists with `MatchingTest.csproj` but tests are stub files, not wired up
- **No CI/CD pipeline**

---

## Project Structure

```
quipt-mapping-engine/
│
├── Api/
│   └── GenerateController.cs          # POST /generate endpoint — orchestrates full pipeline
│
├── Services/
│   ├── AmazonFieldParser.cs           # Parses Amazon JSON taxonomy → List<Field>
│   └── QuiptSchemaParser.cs           # Parses Quipt XML → List<Field> (two-pass: Attributes + leaves)
│
├── MatchingEngine/
│   ├── MatchingEngine.cs              # Core scoring engine (6 signals + specificity)
│   └── Similarity.cs                  # Levenshtein distance implementation
│
├── Normalization/
│   ├── FieldNormalizer.cs             # Tokenizes + normalizes field names (camelCase split, synonym lookup)
│   ├── NormalizationDictionary.cs     # ~120 synonym entries (Quipt codes → canonical terms)
│   └── EnumOverlapScorer.cs           # Jaccard overlap between enum value lists
│
├── Evaluation/
│   ├── EvaluationService.cs           # Computes accuracy % and required field coverage %
│   ├── GroundTruthXsltExtractor.cs    # Extracts amazon→quipt mappings from manual XSLT files
│   ├── EvaluatedMapping.cs            # Data model for evaluation input
│   ├── EvaluationReport.cs            # Data model for evaluation output
│   └── PurvikaAdapter.cs              # Adapter to convert matching results for evaluation
│
├── Xslt/
│   └── XsltBuilder.cs                # Generates XSLT from MappingResult list
│
├── Models/
│   ├── Field.cs                       # Schema field (Name, Path, DataType, IsRequired, EnumValues)
│   ├── MappingResult.cs               # Match result (AmazonField, QuiptPath, Score, IsRequired, IsUnmatched)
│   ├── ApiResponseModel.cs            # Full API response with mappings + evaluation details
│   └── SchemaModel.cs                 # (empty — unused)
│
├── AmazonTaxonomy/                    # Amazon JSON schema files per category
│   ├── amazon-desktops-attributes.json
│   ├── amazon-laptops-attributes.json
│   └── amazon-smartphones-attributes.json
│
├── QuiptData/                         # Sample Quipt XML exports per category
│   ├── Desktops.xml
│   ├── Laptops.xml
│   └── Smartphones.xml
│
├── QuiptToAmazonTemplates/            # Manually-written XSLT (ground truth for evaluation)
│   ├── CatalogExportTransform.Laptops.xslt
│   ├── CatalogExportTransform.Desktops.xslt
│   ├── CatalogExportTransform.SmartPhones.xslt
│   ├── CatalogExportTransform.Builder.MasterTemplate.json.xslt
│   ├── CatalogExportTransform.Builder.xslt
│   ├── inventory.shared.xslt
│   └── ... (shared + utility templates)
│
├── Member4TestHarness/
│   └── Member4QuickTest.cs            # Quick test harness (not part of main pipeline)
│
├── Tests/
│   ├── MatchingTest.csproj            # Test project (stubs only, not implemented)
│   ├── AmazonFields_Laptops.cs
│   └── QuiptFields_Laptops.cs
│
├── Program.cs                         # ASP.NET Web API bootstrap
├── QuiptMappingEngine.csproj          # .NET 10 project file
└── appsettings.json
```

---

## How the Key Components Connect

### 1. Parsers → Matching Engine

Both parsers produce `List<Field>` objects. A `Field` has:
- `Name` — human-readable field name (e.g. `"brand"`, `"# of Processor Cores"`)
- `Path` — full path (Amazon: `"properties.brand"`, Quipt: `"q:Catalog/q:Attributes/q:Attribute[q:Code='CPUCORE']/q:Value/a:string"`)
- `DataType` — `"string"`, `"integer"`, `"array"`, etc.
- `IsRequired` — from Amazon JSON `required` array
- `EnumValues` — allowed values (from Amazon `enum` or Quipt `<Value>` children)

**QuiptSchemaParser** does two passes:
1. **Pass 1 (Attributes):** Finds `<Attribute>` elements with `<Code>`, uses the `<Name>` child as display name, collects `<Value><a:string>` children as enum values, builds paths like `q:Catalog/q:Attributes/q:Attribute[q:Code='MODELNBR']/q:Value/a:string`
2. **Pass 2 (Leaves):** Walks all leaf elements not inside `<Attributes>`, builds standard XPaths

**AmazonFieldParser** reads JSON with `properties` and `required` keys, extracts `type` and `enum` per property.

### 2. Matching Engine Scoring

For each Amazon field, the engine scores every available Quipt field using 6 signals:

| Signal              | Weight | Description |
|---------------------|--------|-------------|
| Token overlap       | 0.45   | Jaccard similarity of normalized token sets |
| Weighted token match| 0.20   | Fraction of Amazon tokens found in Quipt tokens |
| Levenshtein         | 0.15   | Edit distance on concatenated normalized tokens |
| Substring bonus     | 0.10   | Full containment bonus |
| Enum overlap        | 0.05   | Jaccard overlap of enum value lists |
| Unit similarity     | 0.05   | Both fields contain unit-related terms |

The raw score is then multiplied by a **specificity factor**:
- `1.0` for Attribute fields (have a Code identifier)
- `0.9` for normal fields
- `0.5` for generic leaf names (Id, Name, Value, Description, etc.)
- `0.4` for penalized paths (Description, Title, SKU, etc.)

Minimum threshold: **0.20** — anything below is marked `IsUnmatched = true` with `QuiptPath = null`.

Required Amazon fields are processed first to get priority on the best Quipt matches (1:1 constraint).

### 3. Evaluation Against Ground Truth

`GroundTruthXsltExtractor` reads the manually-written XSLT files and extracts a `Dictionary<string, string>` mapping Amazon tag names to Quipt XPaths. It uses a line-by-line tag stack parser (not regex over the full file — that caused catastrophic backtracking).

`EvaluationService` then compares each auto-matched path against ground truth:
- **Accuracy %** = correct matches / total Amazon fields × 100
- **Required Coverage %** = required fields with any match / total required fields × 100
- **PathsEqual** handles abbreviated paths and strips `[N]` index predicates for flexible comparison

### 4. Normalization

`FieldNormalizer.GetNormalizedTokens()` is used everywhere matching happens:
1. Splits camelCase/PascalCase (`"cpuModel"` → `"cpu model"`)
2. Replaces underscores/hyphens with spaces
3. Lowercases
4. Removes special characters
5. Looks up each token in `NormalizationDictionary` (e.g. `"cpu"` → `"processor"`, `"ram"` → `"memory"`, `"modelnbr"` → `"model"`)

The dictionary covers ~120 mappings including all Quipt attribute codes and domain synonyms for ports, peripherals, display, energy ratings, form factors, expansion, connectivity, etc.

---

## API Usage

### Endpoint

```
POST http://localhost:5253/generate
Content-Type: application/json

{
  "category": "laptops"
}
```

Valid categories: `laptops`, `desktops`, `smartphones`

### Response Shape

```json
{
  "category": "laptops",
  "amazonFieldCount": 204,
  "quiptFieldCount": 85,
  "mappingCount": 71,
  "accuracy": 1.96,
  "requiredFieldCoverage": 71.43,
  "groundTruthCount": 24,
  "correctMatches": 4,
  "unmatchedRequiredFields": ["connectivity_technology", "..."],
  "generatedXslt": "<xsl:stylesheet ...>...</xsl:stylesheet>",
  "mappings": [
    {
      "amazonField": "brand",
      "quiptPath": "q:Catalog/q:Brand/q:Name",
      "score": 0.6532,
      "isRequired": true,
      "isUnmatched": false
    }
  ],
  "evaluationDetails": [
    {
      "amazonField": "brand",
      "isRequired": true,
      "autoMatchedPath": "q:Catalog/q:Brand/q:Name",
      "score": 0.6532,
      "expectedPath": "q:Catalog/q:Brand/q:Name",
      "verdict": "CORRECT"
    },
    {
      "amazonField": "model_number",
      "isRequired": false,
      "autoMatchedPath": "q:Catalog/q:PhoneNumber",
      "score": 0.45,
      "expectedPath": "q:Catalog/q:Attributes/q:Attribute[q:Code='MODELNBR']/q:Value/a:string",
      "verdict": "WRONG"
    }
  ]
}
```

### Verdict Values

| Verdict           | Meaning |
|-------------------|---------|
| `CORRECT`         | Auto match equals ground truth |
| `WRONG`           | Auto matched something, but it's the wrong Quipt path |
| `MISSING`         | Ground truth exists but engine couldn't find any match |
| `UNMATCHED`       | No ground truth and no match found |
| `NO_GROUND_TRUTH` | Engine found a match but we have no ground truth to verify |

---

## Development Setup

**Requirements:**
- .NET 10 SDK
- VS Code or Visual Studio
- Git

**Run locally:**
```bash
dotnet restore
dotnet run
# API starts on http://localhost:5253
```

**Test via Postman or curl:**
```bash
curl -X POST http://localhost:5253/generate -H "Content-Type: application/json" -d "{\"category\": \"laptops\"}"
```

---

## Known Issues & Next Steps

### Accuracy Improvements Needed
1. **Ground truth key alignment** — 13 of 24 ground truth keys from XSLT don't match Amazon JSON field names. The XSLT uses tag names like `<brand>` but Amazon JSON uses `brand` as a property key. Different naming conventions (e.g. `item_weight` vs `itemWeight`) cause lookup misses. Need normalized key comparison in the controller.
2. **More normalization entries** — fields like `graphics_description` → `GPUMODEL`, `memory_storage_capacity` → `RAMSIZE`, `model_year` → `RELEASEYEAR` still don't map because the synonym dictionary doesn't link them.
3. **Accuracy denominator** — accuracy is currently divided by ALL Amazon fields (~200), but only ~20 have ground truth. Consider computing accuracy only over fields that have ground truth for a more meaningful percentage.
4. **Smarter matching signals** — current approach is pure heuristic. Could explore: TF-IDF weighting, embedding-based similarity, or learning weights from correct matches.

### eBay Marketplace (Not Started)
- No eBay taxonomy files exist
- No eBay parser
- No eBay ground truth XSLT templates
- Need to determine eBay's field format (JSON? XML? API?)
- `GenerateController` is currently Amazon-only — needs marketplace parameter and routing

### XSLT Generation
- Current output is a flat `<xsl:value-of>` per field
- Manual XSLT templates have: JSON array markers, conditional logic, shared templates, string utilities
- Need to handle nested structures, default values, multi-value fields

### Testing
- `Tests/MatchingTest.csproj` exists with stub files but no actual test logic
- No integration tests
- No automated regression checks

---

## Team Workflow

- Do not push directly to `main`
- Create feature branches:
  ```
  git checkout -b feature/<module-name>
  git push -u origin feature/<module-name>
  ```

---
