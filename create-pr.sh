#!/bin/bash
# Script to push changes and create PR for FetchXML entityname alias fix

set -e

echo "=== FakeXrmEasy Core - Create PR Script ==="
echo ""
echo "This script will:"
echo "1. Apply the fix to your local fork"
echo "2. Push to your fork"
echo "3. Provide the command to create the PR"
echo ""

# Check if we're in the right directory
if [ ! -f "FakeXrmEasy.Core.sln" ]; then
    echo "Error: Please run this script from the fake-xrm-easy-core repository root"
    exit 1
fi

# Get the patch file path
PATCH_FILE="../fake-xrm-easy/fetchxml-alias-fix.patch"
if [ ! -f "$PATCH_FILE" ]; then
    echo "Error: Patch file not found at $PATCH_FILE"
    echo "Please ensure the fake-xrm-easy repository is cloned at ../fake-xrm-easy/"
    exit 1
fi

echo "Step 1: Checking out 2x-dev branch..."
git checkout 2x-dev

echo ""
echo "Step 2: Applying patch..."
git apply "$PATCH_FILE"

echo ""
echo "Step 3: Staging changes..."
git add -A

echo ""
echo "Step 4: Committing changes..."
git commit -m "Fix FetchXML condition entityname alias resolution

- Add ResolveAliasToEntityName method to resolve alias to actual entity name
- Update ToConditionExpression to use resolved entity name for type lookup
- Add comprehensive tests for entityname alias scenarios
- All existing tests continue to pass

Fixes issue where FetchXML conditions with entityname attribute fail when
the attribute exists only on the linked entity, not the main entity."

echo ""
echo "Step 5: Pushing to fork..."
git push origin 2x-dev

echo ""
echo "✅ Changes pushed successfully!"
echo ""
echo "Step 6: Create PR using one of these methods:"
echo ""
echo "METHOD 1 - Using GitHub CLI (if installed):"
echo "-------------------------------------------"
echo "gh pr create --repo DynamicsValue/fake-xrm-easy-core \\"
echo "  --base 2x-dev \\"
echo "  --head aronmek:2x-dev \\"
echo "  --title \"Fix FetchXML condition entityname alias resolution for linked entities\" \\"
echo "  --body \"See CREATE_PR_INSTRUCTIONS.md for full description\""
echo ""
echo "METHOD 2 - Using GitHub Web UI:"
echo "-------------------------------------------"
echo "1. Go to: https://github.com/aronmek/fake-xrm-easy-core"
echo "2. Click the 'Compare & pull request' button"
echo "3. Or visit: https://github.com/DynamicsValue/fake-xrm-easy-core/compare/2x-dev...aronmek:fake-xrm-easy-core:2x-dev"
echo "4. Fill in the PR description from CREATE_PR_INSTRUCTIONS.md"
echo ""
echo "Done! 🎉"
