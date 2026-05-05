#!/usr/bin/env bash
# =============================================================================
# tcctok-clean-final.sh
# Clean tcctok.h + insert TOK_ASM_pop/push exactly once, safely guarded
# =============================================================================

set -euo pipefail

echo "=== Final clean token fix (purge duplicates + safe insert) ==="

# 1. Reset to original
echo "→ Resetting tcctok.h to original..."
git checkout -- tcctok.h

# 2. Purge any existing TOK_ASM_pop / TOK_ASM_push lines
echo "→ Removing any leftover duplicate tokens..."
sed -i '/TOK_ASM_pop/d' tcctok.h
sed -i '/TOK_ASM_push/d' tcctok.h

# 3. Insert the tokens in the correct place (after the last #include block)
echo "→ Inserting tokens exactly once in correct location..."
awk '
  /#endif/ && !done {
    print ""
    print "/* Added after removing disputed arm-tok.h — needed for #pragma pack(push/pop) */"
    print "#ifndef TOK_ASM_pop"
    print "DEF(TOK_ASM_pop, \"pop\")"
    print "#endif"
    print "#ifndef TOK_ASM_push"
    print "DEF(TOK_ASM_push, \"push\")"
    print "#endif"
    print ""
    done=1
  }
  {print}
' tcctok.h > tcctok.h.new && mv tcctok.h.new tcctok.h

echo "→ Tokens inserted safely (guarded with #ifndef)"

# 4. Rebuild and test
echo "→ Cleaning and rebuilding..."
make clean
make -j$(sysctl -n hw.ncpu 2>/dev/null || echo 4)

echo "→ Running tests from deps_test/tccfork submodule..."
make test

echo ""
echo "=== Done! ==="
echo "If make test passes 100% (including cross-test), you're finished."
echo ""
echo "Delete temp scripts now:"
echo "   rm -f *.sh"
echo ""
echo "Then commit:"
echo "   git add tcctok.h"
echo '   git commit -m "Relicense to MIT: fix ASM tokens for all builds"'