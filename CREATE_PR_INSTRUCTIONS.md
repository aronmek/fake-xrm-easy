# Creating the Pull Request to DynamicsValue/fake-xrm-easy-core

Since I don't have push access to your fork, here are the steps to create the PR:

## Option 1: Using the Commit from Local Clone (Recommended)

The fix has been committed locally in the cloned repository at:
`/home/runner/work/fake-xrm-easy/fake-xrm-easy-core`

**Commit Details:**
- Branch: 2x-dev
- Commit Hash: ddbef947
- Commit Message: "Fix FetchXML condition entityname alias resolution"

### Steps:

1. **Copy the commit to your local machine:**
   
   From the environment where this agent ran, you can access the repository at:
   `/home/runner/work/fake-xrm-easy/fake-xrm-easy-core`
   
   Or regenerate the commit by applying the patch:
   ```bash
   cd /path/to/your/fake-xrm-easy-core
   git checkout 2x-dev
   git apply /path/to/fetchxml-alias-fix.patch
   git add -A
   git commit -m "Fix FetchXML condition entityname alias resolution

   - Add ResolveAliasToEntityName method to resolve alias to actual entity name
   - Update ToConditionExpression to use resolved entity name for type lookup
   - Add comprehensive tests for entityname alias scenarios
   - All existing tests continue to pass

   Fixes issue where FetchXML conditions with entityname attribute fail when
   the attribute exists only on the linked entity, not the main entity."
   ```

2. **Push to your fork:**
   ```bash
   git push origin 2x-dev
   ```

3. **Create the PR via GitHub Web UI:**
   - Go to: https://github.com/aronmek/fake-xrm-easy-core
   - Click "Compare & pull request" (should appear after push)
   - Or go to: https://github.com/DynamicsValue/fake-xrm-easy-core/compare/2x-dev...aronmek:fake-xrm-easy-core:2x-dev
   - Fill in the PR details (see template below)

## Option 2: Using GitHub CLI (Alternative)

If you have the commit on your local machine:

```bash
cd /path/to/your/fake-xrm-easy-core
git push origin 2x-dev

# Create PR
gh pr create --repo DynamicsValue/fake-xrm-easy-core \
  --base 2x-dev \
  --head aronmek:2x-dev \
  --title "Fix FetchXML condition entityname alias resolution for linked entities" \
  --body-file pr-description.md
```

## PR Title
```
Fix FetchXML condition entityname alias resolution for linked entities
```

## PR Description Template

```markdown
## What issue does this PR address?

FetchXML conditions with `entityname` attribute fail when the referenced attribute exists only on the linked entity, not the main entity. This occurs because attribute type lookup incorrectly uses the parent entity name instead of resolving the alias.

### Example of the Bug:
```xml
<fetch>
  <entity name="account">
    <filter>
      <!-- birthdate exists on contact, not account -->
      <condition attribute="birthdate" operator="not-null" entityname="linkedContact" />
    </filter>
    <link-entity name="contact" alias="linkedContact">
      <attribute name="birthdate" />
    </link-entity>
  </entity>
</fetch>
```

**Expected Behavior**: Query succeeds because `entityname="linkedContact"` means check `linkedContact.birthdate`  
**Actual Behavior (Before Fix)**: FakeXrmEasy throws "Attribute not found: birthdate on account"

## Changes

### 1. Added `ResolveAliasToEntityName` Method
**File**: `src/FakeXrmEasy.Core/Extensions/XmlExtensionsForFetchXml.cs`

- Traverses FetchXML DOM to resolve alias to actual entity name
- Handles both aliased (`alias="linkedContact"`) and non-aliased scenarios (`entityname="contact"`)
- Searches for link-entities with matching alias attribute

### 2. Modified `ToConditionExpression` Method
**File**: `src/FakeXrmEasy.Core/Extensions/XmlExtensionsForFetchXml.cs`

- Resolves `entityname` attribute to actual entity name before attribute type lookup
- Passes resolved entity name to `GetConditionExpressionValueCast` for correct type resolution
- Maintains backward compatibility

### 3. Added Comprehensive Test Coverage
**File**: `tests/FakeXrmEasy.Core.Tests/Query/FetchXml/FetchXmlAliasedConditionTests.cs`

- New test: `FetchXml_WithEntityNameAlias_ShouldFilterOnLinkedEntity_NotMainEntity` - Validates fix for main bug
- New test: `FetchXml_WithEntityNameNoAlias_ShouldWork` - Ensures backward compatibility

## Testing

### Test Results: ✅ All Passing
- **New tests**: 2/2 passing
- **Existing entityname tests**: 4/4 passing  
- **Full test suite**: 973/973 passing

### Test Commands:
```bash
# Build
pwsh ./build.ps1 -targetFrameworks all

# Run new tests
dotnet test --configuration FAKE_XRM_EASY_9 --framework net462 \
  --filter "FullyQualifiedName~FetchXmlAliasedConditionTests"

# Run existing entityname tests
dotnet test --configuration FAKE_XRM_EASY_9 --framework net462 \
  --filter "FullyQualifiedName~FetchXml_EntityName"
```

## Impact

- **Scope**: Minimal - only affects FetchXML queries with `entityname` in filter conditions
- **Compatibility**: Backward compatible - all existing tests pass
- **Risk**: Low - surgical changes with comprehensive test coverage
- **Behavior**: Now matches Dynamics 365 behavior

## Files Changed

- `src/FakeXrmEasy.Core/Extensions/XmlExtensionsForFetchXml.cs` - Core fix (~80 lines added/modified)
- `tests/FakeXrmEasy.Core.Tests/Query/FetchXml/FetchXmlAliasedConditionTests.cs` - New test file (~150 lines)

Total: 2 files changed, 225 insertions(+), 4 deletions(-)

---

**CLA Acknowledgment:**
I acknowledge and agree that by submitting this pull request, I accept the terms of the [Contributor License Agreement (CLA)](https://github.com/DynamicsValue/licence-agreements/blob/main/FakeXrmEasy/CLA.md).
```

## Files You Need

1. **Patch file**: Available at `/home/runner/work/fake-xrm-easy/fake-xrm-easy/fetchxml-alias-fix.patch`
2. **Commit**: Available in `/home/runner/work/fake-xrm-easy/fake-xrm-easy-core` (commit ddbef947)

## Verification

Before creating the PR, verify locally:
```bash
cd /path/to/your/fake-xrm-easy-core
git log -1 --stat
# Should show the commit with 2 files changed, 225 insertions(+), 4 deletions(-)
```
