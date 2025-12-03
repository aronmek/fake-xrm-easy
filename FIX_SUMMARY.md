# FetchXML Condition with EntityName Alias Fix

## Problem
FetchXML conditions with `entityname` attribute that reference linked entity aliases fail when the attribute doesn't exist on the main entity, even though it exists on the linked entity.

### Example Bug
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

**Expected**: Query succeeds because `entityname="linkedContact"` means check `linkedContact.birthdate`, not `account.birthdate`.

**Actual (Before Fix)**: FakeXrmEasy throws "Attribute not found: birthdate on account" because it's looking for the attribute on the main entity instead of the linked entity.

## Root Cause
In `XmlExtensionsForFetchXml.cs`, the `ToConditionExpression` method:
1. Extracts the `entityname` attribute (alias) from the condition
2. Calls `GetAssociatedEntityNameForConditionExpression` which returns the PARENT entity's name
3. Uses that parent entity name for attribute type lookup in `GetConditionExpressionValueCast`

When `entityname` is specified, it should resolve the alias to find the actual entity name of the linked entity, then use that for type lookup.

## Solution
Added a new method `ResolveAliasToEntityName` that:
1. Traverses up to the root `<fetch>` element
2. Searches for a `<link-entity>` with matching `alias` attribute
3. Returns the entity name from that link-entity

Modified `ToConditionExpression` to:
1. Resolve the alias when `entityname` is specified
2. Use the resolved entity name for type lookup instead of the parent entity name

## Files Changed

### fake-xrm-easy-core repository

#### `src/FakeXrmEasy.Core/Extensions/XmlExtensionsForFetchXml.cs`

**Added new method** (after line 355):
```csharp
/// <summary>
/// Resolves an alias to the actual entity name by finding the link-entity with the matching alias
/// </summary>
/// <param name="el">The current element (typically a condition element)</param>
/// <param name="alias">The alias to resolve</param>
/// <returns>The entity name for the link-entity with the given alias, or null if not found</returns>
public static string ResolveAliasToEntityName(this XElement el, string alias)
{
    if (string.IsNullOrWhiteSpace(alias))
    {
        return null;
    }

    // Traverse up to find the root fetch element
    var current = el;
    while (current != null && !current.Name.LocalName.Equals("fetch"))
    {
        current = current.Parent;
    }

    if (current == null)
    {
        return null;
    }

    // Search for link-entity with matching alias
    var linkEntity = current.Descendants()
        .Where(e => e.Name.LocalName.Equals("link-entity"))
        .FirstOrDefault(e =>
        {
            var aliasAttr = e.GetAttribute("alias");
            return aliasAttr != null && aliasAttr.Value.Equals(alias, StringComparison.InvariantCultureIgnoreCase);
        });

    if (linkEntity != null)
    {
        var nameAttr = linkEntity.GetAttribute("name");
        if (nameAttr != null)
        {
            return nameAttr.Value;
        }
    }

    // If alias doesn't match any link-entity, it might be the entity name itself (no alias case)
    // Check if alias matches a link-entity name directly
    var linkEntityByName = current.Descendants()
        .Where(e => e.Name.LocalName.Equals("link-entity"))
        .FirstOrDefault(e =>
        {
            var nameAttr = e.GetAttribute("name");
            return nameAttr != null && nameAttr.Value.Equals(alias, StringComparison.InvariantCultureIgnoreCase);
        });

    if (linkEntityByName != null)
    {
        return alias;
    }

    return null;
}
```

**Modified `ToConditionExpression` method** (around line 859-904):

Changed from:
```csharp
var entityName = GetAssociatedEntityNameForConditionExpression(elem);

//Find values inside the condition expression, if apply
values = elem
            .Elements()
            .Where(el => el.Name.LocalName.Equals("value"))
            .Select(el => el.ToValue(ctx, entityName, attributeName, op))
            .ToArray();

//Otherwise, a single value was used
if (value != null)
{
#if FAKE_XRM_EASY_2013 || FAKE_XRM_EASY_2015 || FAKE_XRM_EASY_2016 || FAKE_XRM_EASY_365 || FAKE_XRM_EASY_9
    if (string.IsNullOrWhiteSpace(conditionEntityName))
    {
        return new ConditionExpression(attributeName, op, GetConditionExpressionValueCast(value, ctx, entityName, attributeName, op));
    }
    else
    {
        return new ConditionExpression(conditionEntityName, attributeName, op, GetConditionExpressionValueCast(value, ctx, entityName, attributeName, op));
    }
#else
    return new ConditionExpression(attributeName, op, GetConditionExpressionValueCast(value, ctx, entityName, attributeName, op));
#endif
}
```

To:
```csharp
var entityName = GetAssociatedEntityNameForConditionExpression(elem);

// When entityname is specified (alias or entity name), resolve it to the actual entity name for type lookup
var entityNameForTypeLookup = entityName;
if (!string.IsNullOrWhiteSpace(conditionEntityName))
{
    var resolvedEntityName = elem.ResolveAliasToEntityName(conditionEntityName);
    if (!string.IsNullOrWhiteSpace(resolvedEntityName))
    {
        entityNameForTypeLookup = resolvedEntityName;
    }
}

//Find values inside the condition expression, if apply
values = elem
            .Elements()
            .Where(el => el.Name.LocalName.Equals("value"))
            .Select(el => el.ToValue(ctx, entityNameForTypeLookup, attributeName, op))
            .ToArray();

//Otherwise, a single value was used
if (value != null)
{
#if FAKE_XRM_EASY_2013 || FAKE_XRM_EASY_2015 || FAKE_XRM_EASY_2016 || FAKE_XRM_EASY_365 || FAKE_XRM_EASY_9
    if (string.IsNullOrWhiteSpace(conditionEntityName))
    {
        return new ConditionExpression(attributeName, op, GetConditionExpressionValueCast(value, ctx, entityNameForTypeLookup, attributeName, op));
    }
    else
    {
        return new ConditionExpression(conditionEntityName, attributeName, op, GetConditionExpressionValueCast(value, ctx, entityNameForTypeLookup, attributeName, op));
    }
#else
    return new ConditionExpression(attributeName, op, GetConditionExpressionValueCast(value, ctx, entityNameForTypeLookup, attributeName, op));
#endif
}
```

#### `tests/FakeXrmEasy.Core.Tests/Query/FetchXml/FetchXmlAliasedConditionTests.cs`

**New test file** with comprehensive tests:
1. `FetchXml_WithEntityNameAlias_ShouldFilterOnLinkedEntity_NotMainEntity` - Tests the main bug fix scenario
2. `FetchXml_WithEntityNameNoAlias_ShouldWork` - Ensures backward compatibility when using entity name without alias

## Test Results
All tests pass:
- New tests: 2/2 ✓
- Existing `entityname` tests: 4/4 ✓

## Impact
- **Minimal**: Only affects FetchXML queries with `entityname` attribute in conditions
- **Backward Compatible**: All existing tests pass
- **Fixes**: Attribute type lookup now correctly uses the linked entity's name when `entityname` is specified

## Next Steps
1. The fix is in the `fake-xrm-easy-core` repository
2. Need to build and package the core library
3. Reference the updated core package in the main `fake-xrm-easy` repository
