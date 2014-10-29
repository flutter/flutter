The empty, cr, and utf16 tests don't import the test framework so they
currently hang until timeout. Really they should just check that
nothing crashes. For now they are disabled.

We should also test the following (each line is its own test):

```
<
<!
<!-
<!--
<!---
<!----
<!---->
<!----->
<a
<aa
<a 
<a a
<a a=
<a a=&
<a a=&#
<a a=&#x
<a a=&#x1
<a a=&#x1;
<a a=&#1
<a a=&#1;
<a a=&a
<a a=&a;
<a a=&;
<a a='
<a a="
<a a=a
<a>
<a >
<a a>
<a a=>
<a a=&>
<a a=&#>
<a a=&#x>
<a a=&#x1>
<a a=&#x1;>
<a a=&#1>
<a a=&#1;>
<a a=&a>
<a a=&a;>
<a a=&;>
<a a=''>
<a a="">
<a a=a>
<a a >
<a a= >
<a a=& >
<a a=&# >
<a a=&#x >
<a a=&#x1 >
<a a=&#x1; >
<a a=&#1 >
<a a=&#1; >
<a a=&a >
<a a=&a; >
<a a=&; >
<a a='' >
<a a="" >
<a a=a >
</a
</aa
</a 
</a a
</a a=
</a a=&
</a a=&#
</a a=&#x
</a a=&#x1
</a a=&#x1;
</a a=&#1
</a a=&#1;
</a a=&a
</a a=&a;
</a a=&;
</a a='
</a a="
</a a=a
</a>
</a >
</a a>
</a a=>
</a a=&>
</a a=&#>
</a a=&#x>
</a a=&#x1>
</a a=&#x1;>
</a a=&#1>
</a a=&#1;>
</a a=&a>
</a a=&a;>
</a a=&;>
</a a=''>
</a a="">
</a a=a>
</a a >
</a a= >
</a a=& >
</a a=&# >
</a a=&#x >
</a a=&#x1 >
</a a=&#x1; >
</a a=&#1 >
</a a=&#1; >
</a a=&a >
</a a=&a; >
</a a=&; >
</a a='' >
</a a="" >
</a a=a >
a
&
&#
&#x
&#x1
&#x1;
&#1
&#1;
&a
&a;
&;
```

We should also test:

- multiple elements per page
- signature stuff
- <t>
