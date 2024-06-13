_**Everything in this doc and linked from this doc is experimental. These details WILL change. Do not use these instructions or APIs in production code because we will break you.**_

# Add Flutter as a Fragment in a ViewPager

Tabbed navigation often expects the presence of a `ViewPager`, such that the user can swipe left/right to navigate between tabbed pages. This guide shows you how to integrate Flutter as one or more of the pages in your `ViewPager`.

Start by implementing standard tabbed navigation in Android with a `ViewPager`. Consider following [this guide](https://developer.android.com/training/implementing-navigation/lateral).

Next, alter your `FragmentPagerAdapter` to return a `FlutterFragment` for the desired page(s).

```java
  /**
   * A {@link FragmentPagerAdapter} that returns a fragment corresponding to
   * one of the sections/tabs/pages.
   */
  public class SectionsPagerAdapter extends FragmentPagerAdapter {

    public SectionsPagerAdapter(FragmentManager fm) {
      super(fm);
    }

    @Override
    public Fragment getItem(int position) {
      if (position == FLUTTER_PAGE_INDEX) {
        // In this case we construct a FlutterFragment that will run
        // our main() method in Dart and start with an initial route of "/".
        return new FlutterFragment.createDefault();
      } else {
        // return some other page's Fragment
      }
    }

    @Override
    public int getCount() {
      // You need to define PAGE_COUNT
      return PAGE_COUNT;
    }
  }
```

You should now have a Flutter UI as one or more pages within your tabbed navigation.

You may notice a delay between creation of your `FlutterFragment` and the display of your Flutter UI. This delay is caused by the warm-up time for the `FlutterEngine`. This warm-up issue a standard concern that applies to all uses of Flutter, including `FlutterActivity`. The way to minimize this visual delay is to use pre-warmed `FlutterEngine`s. Please see [the page about pre-warming FlutterEngines](Experimental-Reuse-FlutterEngine-across-screens.md).