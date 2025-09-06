# Comment for New PR #175008

Copy and paste this comment to your new PR:

---

Hi @chunhtai @QuncCccccc @loic-sharma! 👋

This PR implements the MediaQuery override approach that was suggested in PR #173520. Based on @chunhtai's feedback about using MediaQuery above MaterialApp instead of expanding the API surface, I've created a clean documentation-focused solution.

## What's Changed
✅ **Documentation enhancement** - Added comprehensive examples to MaterialApp showing the MediaQuery override pattern  
✅ **Clean approach** - Pure documentation with no API expansion  
✅ **Comprehensive examples** - Shows both programmatic and user-controlled theme switching  
✅ **No breaking changes** - Uses existing MediaQuery capabilities  

## Addresses Previous Feedback
This approach directly implements @chunhtai's suggestion:
```dart
MaterialApp(
  builder: (context, child) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        highContrast: customHighContrastEnabled,
      ),
      child: child!,
    );
  },
  theme: ThemeData(...),
  highContrastTheme: ThemeData(...),
  // ... other properties
)
```

The documentation now shows developers exactly how to achieve high contrast theme control without needing new API parameters.

Could you please review this clean approach? I believe it addresses all the architectural concerns raised in the previous discussion while providing the functionality developers need.

Note: I'm closing PR #175007 as this is a cleaner version with the same improvements.

Thank you for your guidance! 🙏

---

**What to do:**
1. Close old PR #175007 manually
2. Go to new PR: https://github.com/flutter/flutter/pull/175008  
3. Copy and paste the above comment
4. Click "Comment" to notify reviewers
