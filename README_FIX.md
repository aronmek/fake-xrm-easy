# How to Apply the FetchXML EntityName Alias Fix

This repository contains the fix for the FetchXML condition `entityname` alias bug in FakeXrmEasy.

## Problem Summary

FetchXML conditions with `entityname="alias"` fail when the attribute doesn't exist on the main entity, even though it exists on the linked entity with that alias.

**Example:**
```xml
<fetch>
  <entity name="account">
    <filter>
      <condition attribute="birthdate" operator="not-null" 
                 entityname="linkedContact" />
    </filter>
    <link-entity name="contact" alias="linkedContact" ...>
      <attribute name="birthdate" />
    </link-entity>
  </entity>
</fetch>
```

This should work because `entityname="linkedContact"` means check the `contact` entity (aliased as `linkedContact`), not the `account` entity.

## Files in This Repository

1. **FIX_SUMMARY.md** - Detailed explanation of the bug and the fix
2. **fetchxml-alias-fix.patch** - Git patch file that can be applied to fake-xrm-easy-core repository

## How to Apply the Fix

### Option 1: Apply the Patch File (Recommended)

If you have a local clone of the `fake-xrm-easy-core` repository:

```bash
cd path/to/fake-xrm-easy-core
git apply path/to/fetchxml-alias-fix.patch
```

### Option 2: Manual Changes

Follow the instructions in `FIX_SUMMARY.md` to manually apply the changes to:
- `src/FakeXrmEasy.Core/Extensions/XmlExtensionsForFetchXml.cs`
- `tests/FakeXrmEasy.Core.Tests/Query/FetchXml/FetchXmlAliasedConditionTests.cs`

### Option 3: View the Changes

The patch file contains all the changes. You can view it directly or use:

```bash
git apply --stat fetchxml-alias-fix.patch
git apply --check fetchxml-alias-fix.patch
```

## Testing the Fix

After applying the fix:

1. Install mono if on Linux: `sudo apt-get install mono-complete`
2. Build the project: `pwsh ./build.ps1 -targetFrameworks all`
3. Run the new tests:
   ```bash
   dotnet test --configuration FAKE_XRM_EASY_9 --filter "FullyQualifiedName~FetchXmlAliasedConditionTests"
   ```
4. Verify existing tests still pass:
   ```bash
   dotnet test --configuration FAKE_XRM_EASY_9 --filter "FullyQualifiedName~FetchXml_EntityName"
   ```

All tests should pass (6/6).

## What Changed

### New Method: `ResolveAliasToEntityName`
- Resolves an alias (e.g., "linkedContact") to the actual entity name (e.g., "contact")
- Searches the FetchXML tree for link-entities with matching alias
- Handles both aliased and non-aliased link-entities

### Modified Method: `ToConditionExpression`
- Now resolves the alias when `entityname` is specified
- Uses the resolved entity name for attribute type lookup
- Ensures attribute is looked up on the correct entity

### New Tests
- `FetchXml_WithEntityNameAlias_ShouldFilterOnLinkedEntity_NotMainEntity` - Main bug fix test
- `FetchXml_WithEntityNameNoAlias_ShouldWork` - Backward compatibility test

## Impact

- **Minimal and Surgical**: Only affects FetchXML conditions with `entityname` attribute
- **Backward Compatible**: All existing tests pass
- **Fixes Real Bug**: Matches Dynamics 365 behavior

## Repository Structure

This fix is for the **fake-xrm-easy-core** repository, which is a dependency of the main fake-xrm-easy package.

```
fake-xrm-easy/              (this repository - facade package)
├── FIX_SUMMARY.md          (detailed explanation)
├── fetchxml-alias-fix.patch (git patch)
└── README_FIX.md           (this file)

fake-xrm-easy-core/         (needs to be cloned separately)
├── src/FakeXrmEasy.Core/Extensions/XmlExtensionsForFetchXml.cs  (modified)
└── tests/.../FetchXmlAliasedConditionTests.cs                     (new)
```

## Next Steps

1. Clone the fake-xrm-easy-core repository if you haven't already
2. Apply the patch using one of the methods above
3. Build and test
4. Optionally create a PR to the upstream DynamicsValue/fake-xrm-easy-core repository

## References

- [FakeXrmEasy Documentation](https://dynamicsvalue.github.io/fake-xrm-easy-docs/)
- [FakeXrmEasy Core Repository](https://github.com/DynamicsValue/fake-xrm-easy-core)
