# Quipt Mapping Engine

## Overview

Quipt Mapping Engine is a .NET Web API that automatically generates XSLT transformations between Quipt product XML and external marketplace schemas (Amazon for Sprint 1).

The system:

1. Reads Quipt XML schema
2. Reads marketplace taxonomy JSON
3. Matches fields using an inference engine
4. Generates structured XSLT
5. Evaluates mapping accuracy
6. Returns results via API

---

## Sprint 1 Scope

* Amazon only
* 3 categories (Desktops, Laptops, Smartphones)
* Heuristic-based inference engine
* Structured XSLT generation
* Accuracy evaluation against manual mappings

Target:

* Required field coverage ≥ 80%

---

## Project Structure

### Api/

Contains API endpoints.

* `GenerateController.cs`
  Main POST endpoint that runs the full pipeline:
  Parse → Match → Generate XSLT → Evaluate → Return response.

---

### Models/

Shared data contracts used across the system.

* `Field.cs`
  Represents a schema field from Quipt or Amazon.

* `MappingResult.cs`
  Represents a matched field pair with score and metadata.

* `ApiResponse.cs`
  Standard response model returned by API.

---

### Parsers/

Responsible for extracting structured schema models.

* Quipt XML parser
* Amazon JSON parser

Outputs:
`List<Field>`

---

### Engine/

Core inference logic.

Implements:

* Structural filtering
* Name similarity scoring
* Token normalization
* Enum overlap detection
* Unit awareness

Outputs:
`List<MappingResult>`

---

### Evaluation/

Compares auto-generated mappings against manual mappings.

Computes:

* Accuracy %
* Required field coverage %

---

### Xslt/

Responsible for building structured XSLT output.

* `XsltBuilder.cs`
  Generates marketplace-compatible XSLT based on MappingResult list.

---

### Program.cs

Bootstraps the Web API application.

---

## Development Setup

Requirements:

* .NET 10 SDK
* VS Code
* Git

Run locally:

```
dotnet restore
dotnet run
```

---

## Team Workflow

* Do not push directly to `main`.
* Create feature branch:

```
git checkout -b feature/<module-name>
```

* Push branch:

```
git push -u origin feature/<module-name>
```

---

## Architecture Flow

Input schemas → Match → Generate XSLT → Transform data

1. Parse Quipt XML
2. Parse Amazon JSON
3. Compute field matches
4. Generate structured XSLT
5. Evaluate accuracy
6. Return API response

---
