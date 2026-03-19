# Revert Plattr OS Styles

If you want to restore the **original design** (before UI enrichment and color consistency changes):

```bash
npm run styles:revert
```

Or manually:

```bash
cp src/styles.css.backup src/styles.css
```

The backup (`src/styles.css.backup`) contains the exact previous styles with no modifications.
