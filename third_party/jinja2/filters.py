# -*- coding: utf-8 -*-
"""
    jinja2.filters
    ~~~~~~~~~~~~~~

    Bundled jinja filters.

    :copyright: (c) 2010 by the Jinja Team.
    :license: BSD, see LICENSE for more details.
"""
import re
import math

from random import choice
from operator import itemgetter
from itertools import groupby
from jinja2.utils import Markup, escape, pformat, urlize, soft_unicode, \
     unicode_urlencode
from jinja2.runtime import Undefined
from jinja2.exceptions import FilterArgumentError
from jinja2._compat import next, imap, string_types, text_type, iteritems


_word_re = re.compile(r'\w+(?u)')


def contextfilter(f):
    """Decorator for marking context dependent filters. The current
    :class:`Context` will be passed as first argument.
    """
    f.contextfilter = True
    return f


def evalcontextfilter(f):
    """Decorator for marking eval-context dependent filters.  An eval
    context object is passed as first argument.  For more information
    about the eval context, see :ref:`eval-context`.

    .. versionadded:: 2.4
    """
    f.evalcontextfilter = True
    return f


def environmentfilter(f):
    """Decorator for marking evironment dependent filters.  The current
    :class:`Environment` is passed to the filter as first argument.
    """
    f.environmentfilter = True
    return f


def make_attrgetter(environment, attribute):
    """Returns a callable that looks up the given attribute from a
    passed object with the rules of the environment.  Dots are allowed
    to access attributes of attributes.  Integer parts in paths are
    looked up as integers.
    """
    if not isinstance(attribute, string_types) \
       or ('.' not in attribute and not attribute.isdigit()):
        return lambda x: environment.getitem(x, attribute)
    attribute = attribute.split('.')
    def attrgetter(item):
        for part in attribute:
            if part.isdigit():
                part = int(part)
            item = environment.getitem(item, part)
        return item
    return attrgetter


def do_forceescape(value):
    """Enforce HTML escaping.  This will probably double escape variables."""
    if hasattr(value, '__html__'):
        value = value.__html__()
    return escape(text_type(value))


def do_urlencode(value):
    """Escape strings for use in URLs (uses UTF-8 encoding).  It accepts both
    dictionaries and regular strings as well as pairwise iterables.

    .. versionadded:: 2.7
    """
    itemiter = None
    if isinstance(value, dict):
        itemiter = iteritems(value)
    elif not isinstance(value, string_types):
        try:
            itemiter = iter(value)
        except TypeError:
            pass
    if itemiter is None:
        return unicode_urlencode(value)
    return u'&'.join(unicode_urlencode(k) + '=' +
                     unicode_urlencode(v) for k, v in itemiter)


@evalcontextfilter
def do_replace(eval_ctx, s, old, new, count=None):
    """Return a copy of the value with all occurrences of a substring
    replaced with a new one. The first argument is the substring
    that should be replaced, the second is the replacement string.
    If the optional third argument ``count`` is given, only the first
    ``count`` occurrences are replaced:

    .. sourcecode:: jinja

        {{ "Hello World"|replace("Hello", "Goodbye") }}
            -> Goodbye World

        {{ "aaaaargh"|replace("a", "d'oh, ", 2) }}
            -> d'oh, d'oh, aaargh
    """
    if count is None:
        count = -1
    if not eval_ctx.autoescape:
        return text_type(s).replace(text_type(old), text_type(new), count)
    if hasattr(old, '__html__') or hasattr(new, '__html__') and \
       not hasattr(s, '__html__'):
        s = escape(s)
    else:
        s = soft_unicode(s)
    return s.replace(soft_unicode(old), soft_unicode(new), count)


def do_upper(s):
    """Convert a value to uppercase."""
    return soft_unicode(s).upper()


def do_lower(s):
    """Convert a value to lowercase."""
    return soft_unicode(s).lower()


@evalcontextfilter
def do_xmlattr(_eval_ctx, d, autospace=True):
    """Create an SGML/XML attribute string based on the items in a dict.
    All values that are neither `none` nor `undefined` are automatically
    escaped:

    .. sourcecode:: html+jinja

        <ul{{ {'class': 'my_list', 'missing': none,
                'id': 'list-%d'|format(variable)}|xmlattr }}>
        ...
        </ul>

    Results in something like this:

    .. sourcecode:: html

        <ul class="my_list" id="list-42">
        ...
        </ul>

    As you can see it automatically prepends a space in front of the item
    if the filter returned something unless the second parameter is false.
    """
    rv = u' '.join(
        u'%s="%s"' % (escape(key), escape(value))
        for key, value in iteritems(d)
        if value is not None and not isinstance(value, Undefined)
    )
    if autospace and rv:
        rv = u' ' + rv
    if _eval_ctx.autoescape:
        rv = Markup(rv)
    return rv


def do_capitalize(s):
    """Capitalize a value. The first character will be uppercase, all others
    lowercase.
    """
    return soft_unicode(s).capitalize()


def do_title(s):
    """Return a titlecased version of the value. I.e. words will start with
    uppercase letters, all remaining characters are lowercase.
    """
    rv = []
    for item in re.compile(r'([-\s]+)(?u)').split(s):
        if not item:
            continue
        rv.append(item[0].upper() + item[1:].lower())
    return ''.join(rv)


def do_dictsort(value, case_sensitive=False, by='key'):
    """Sort a dict and yield (key, value) pairs. Because python dicts are
    unsorted you may want to use this function to order them by either
    key or value:

    .. sourcecode:: jinja

        {% for item in mydict|dictsort %}
            sort the dict by key, case insensitive

        {% for item in mydict|dictsort(true) %}
            sort the dict by key, case sensitive

        {% for item in mydict|dictsort(false, 'value') %}
            sort the dict by key, case insensitive, sorted
            normally and ordered by value.
    """
    if by == 'key':
        pos = 0
    elif by == 'value':
        pos = 1
    else:
        raise FilterArgumentError('You can only sort by either '
                                  '"key" or "value"')
    def sort_func(item):
        value = item[pos]
        if isinstance(value, string_types) and not case_sensitive:
            value = value.lower()
        return value

    return sorted(value.items(), key=sort_func)


@environmentfilter
def do_sort(environment, value, reverse=False, case_sensitive=False,
            attribute=None):
    """Sort an iterable.  Per default it sorts ascending, if you pass it
    true as first argument it will reverse the sorting.

    If the iterable is made of strings the third parameter can be used to
    control the case sensitiveness of the comparison which is disabled by
    default.

    .. sourcecode:: jinja

        {% for item in iterable|sort %}
            ...
        {% endfor %}

    It is also possible to sort by an attribute (for example to sort
    by the date of an object) by specifying the `attribute` parameter:

    .. sourcecode:: jinja

        {% for item in iterable|sort(attribute='date') %}
            ...
        {% endfor %}

    .. versionchanged:: 2.6
       The `attribute` parameter was added.
    """
    if not case_sensitive:
        def sort_func(item):
            if isinstance(item, string_types):
                item = item.lower()
            return item
    else:
        sort_func = None
    if attribute is not None:
        getter = make_attrgetter(environment, attribute)
        def sort_func(item, processor=sort_func or (lambda x: x)):
            return processor(getter(item))
    return sorted(value, key=sort_func, reverse=reverse)


def do_default(value, default_value=u'', boolean=False):
    """If the value is undefined it will return the passed default value,
    otherwise the value of the variable:

    .. sourcecode:: jinja

        {{ my_variable|default('my_variable is not defined') }}

    This will output the value of ``my_variable`` if the variable was
    defined, otherwise ``'my_variable is not defined'``. If you want
    to use default with variables that evaluate to false you have to
    set the second parameter to `true`:

    .. sourcecode:: jinja

        {{ ''|default('the string was empty', true) }}
    """
    if isinstance(value, Undefined) or (boolean and not value):
        return default_value
    return value


@evalcontextfilter
def do_join(eval_ctx, value, d=u'', attribute=None):
    """Return a string which is the concatenation of the strings in the
    sequence. The separator between elements is an empty string per
    default, you can define it with the optional parameter:

    .. sourcecode:: jinja

        {{ [1, 2, 3]|join('|') }}
            -> 1|2|3

        {{ [1, 2, 3]|join }}
            -> 123

    It is also possible to join certain attributes of an object:

    .. sourcecode:: jinja

        {{ users|join(', ', attribute='username') }}

    .. versionadded:: 2.6
       The `attribute` parameter was added.
    """
    if attribute is not None:
        value = imap(make_attrgetter(eval_ctx.environment, attribute), value)

    # no automatic escaping?  joining is a lot eaiser then
    if not eval_ctx.autoescape:
        return text_type(d).join(imap(text_type, value))

    # if the delimiter doesn't have an html representation we check
    # if any of the items has.  If yes we do a coercion to Markup
    if not hasattr(d, '__html__'):
        value = list(value)
        do_escape = False
        for idx, item in enumerate(value):
            if hasattr(item, '__html__'):
                do_escape = True
            else:
                value[idx] = text_type(item)
        if do_escape:
            d = escape(d)
        else:
            d = text_type(d)
        return d.join(value)

    # no html involved, to normal joining
    return soft_unicode(d).join(imap(soft_unicode, value))


def do_center(value, width=80):
    """Centers the value in a field of a given width."""
    return text_type(value).center(width)


@environmentfilter
def do_first(environment, seq):
    """Return the first item of a sequence."""
    try:
        return next(iter(seq))
    except StopIteration:
        return environment.undefined('No first item, sequence was empty.')


@environmentfilter
def do_last(environment, seq):
    """Return the last item of a sequence."""
    try:
        return next(iter(reversed(seq)))
    except StopIteration:
        return environment.undefined('No last item, sequence was empty.')


@environmentfilter
def do_random(environment, seq):
    """Return a random item from the sequence."""
    try:
        return choice(seq)
    except IndexError:
        return environment.undefined('No random item, sequence was empty.')


def do_filesizeformat(value, binary=False):
    """Format the value like a 'human-readable' file size (i.e. 13 kB,
    4.1 MB, 102 Bytes, etc).  Per default decimal prefixes are used (Mega,
    Giga, etc.), if the second parameter is set to `True` the binary
    prefixes are used (Mebi, Gibi).
    """
    bytes = float(value)
    base = binary and 1024 or 1000
    prefixes = [
        (binary and 'KiB' or 'kB'),
        (binary and 'MiB' or 'MB'),
        (binary and 'GiB' or 'GB'),
        (binary and 'TiB' or 'TB'),
        (binary and 'PiB' or 'PB'),
        (binary and 'EiB' or 'EB'),
        (binary and 'ZiB' or 'ZB'),
        (binary and 'YiB' or 'YB')
    ]
    if bytes == 1:
        return '1 Byte'
    elif bytes < base:
        return '%d Bytes' % bytes
    else:
        for i, prefix in enumerate(prefixes):
            unit = base ** (i + 2)
            if bytes < unit:
                return '%.1f %s' % ((base * bytes / unit), prefix)
        return '%.1f %s' % ((base * bytes / unit), prefix)


def do_pprint(value, verbose=False):
    """Pretty print a variable. Useful for debugging.

    With Jinja 1.2 onwards you can pass it a parameter.  If this parameter
    is truthy the output will be more verbose (this requires `pretty`)
    """
    return pformat(value, verbose=verbose)


@evalcontextfilter
def do_urlize(eval_ctx, value, trim_url_limit=None, nofollow=False):
    """Converts URLs in plain text into clickable links.

    If you pass the filter an additional integer it will shorten the urls
    to that number. Also a third argument exists that makes the urls
    "nofollow":

    .. sourcecode:: jinja

        {{ mytext|urlize(40, true) }}
            links are shortened to 40 chars and defined with rel="nofollow"
    """
    rv = urlize(value, trim_url_limit, nofollow)
    if eval_ctx.autoescape:
        rv = Markup(rv)
    return rv


def do_indent(s, width=4, indentfirst=False):
    """Return a copy of the passed string, each line indented by
    4 spaces. The first line is not indented. If you want to
    change the number of spaces or indent the first line too
    you can pass additional parameters to the filter:

    .. sourcecode:: jinja

        {{ mytext|indent(2, true) }}
            indent by two spaces and indent the first line too.
    """
    indention = u' ' * width
    rv = (u'\n' + indention).join(s.splitlines())
    if indentfirst:
        rv = indention + rv
    return rv


def do_truncate(s, length=255, killwords=False, end='...'):
    """Return a truncated copy of the string. The length is specified
    with the first parameter which defaults to ``255``. If the second
    parameter is ``true`` the filter will cut the text at length. Otherwise
    it will discard the last word. If the text was in fact
    truncated it will append an ellipsis sign (``"..."``). If you want a
    different ellipsis sign than ``"..."`` you can specify it using the
    third parameter.

    .. sourcecode:: jinja

        {{ "foo bar"|truncate(5) }}
            -> "foo ..."
        {{ "foo bar"|truncate(5, True) }}
            -> "foo b..."
    """
    if len(s) <= length:
        return s
    elif killwords:
        return s[:length] + end
    words = s.split(' ')
    result = []
    m = 0
    for word in words:
        m += len(word) + 1
        if m > length:
            break
        result.append(word)
    result.append(end)
    return u' '.join(result)

@environmentfilter
def do_wordwrap(environment, s, width=79, break_long_words=True,
                wrapstring=None):
    """
    Return a copy of the string passed to the filter wrapped after
    ``79`` characters.  You can override this default using the first
    parameter.  If you set the second parameter to `false` Jinja will not
    split words apart if they are longer than `width`. By default, the newlines
    will be the default newlines for the environment, but this can be changed
    using the wrapstring keyword argument.

    .. versionadded:: 2.7
       Added support for the `wrapstring` parameter.
    """
    if not wrapstring:
        wrapstring = environment.newline_sequence
    import textwrap
    return wrapstring.join(textwrap.wrap(s, width=width, expand_tabs=False,
                                   replace_whitespace=False,
                                   break_long_words=break_long_words))


def do_wordcount(s):
    """Count the words in that string."""
    return len(_word_re.findall(s))


def do_int(value, default=0):
    """Convert the value into an integer. If the
    conversion doesn't work it will return ``0``. You can
    override this default using the first parameter.
    """
    try:
        return int(value)
    except (TypeError, ValueError):
        # this quirk is necessary so that "42.23"|int gives 42.
        try:
            return int(float(value))
        except (TypeError, ValueError):
            return default


def do_float(value, default=0.0):
    """Convert the value into a floating point number. If the
    conversion doesn't work it will return ``0.0``. You can
    override this default using the first parameter.
    """
    try:
        return float(value)
    except (TypeError, ValueError):
        return default


def do_format(value, *args, **kwargs):
    """
    Apply python string formatting on an object:

    .. sourcecode:: jinja

        {{ "%s - %s"|format("Hello?", "Foo!") }}
            -> Hello? - Foo!
    """
    if args and kwargs:
        raise FilterArgumentError('can\'t handle positional and keyword '
                                  'arguments at the same time')
    return soft_unicode(value) % (kwargs or args)


def do_trim(value):
    """Strip leading and trailing whitespace."""
    return soft_unicode(value).strip()


def do_striptags(value):
    """Strip SGML/XML tags and replace adjacent whitespace by one space.
    """
    if hasattr(value, '__html__'):
        value = value.__html__()
    return Markup(text_type(value)).striptags()


def do_slice(value, slices, fill_with=None):
    """Slice an iterator and return a list of lists containing
    those items. Useful if you want to create a div containing
    three ul tags that represent columns:

    .. sourcecode:: html+jinja

        <div class="columwrapper">
          {%- for column in items|slice(3) %}
            <ul class="column-{{ loop.index }}">
            {%- for item in column %}
              <li>{{ item }}</li>
            {%- endfor %}
            </ul>
          {%- endfor %}
        </div>

    If you pass it a second argument it's used to fill missing
    values on the last iteration.
    """
    seq = list(value)
    length = len(seq)
    items_per_slice = length // slices
    slices_with_extra = length % slices
    offset = 0
    for slice_number in range(slices):
        start = offset + slice_number * items_per_slice
        if slice_number < slices_with_extra:
            offset += 1
        end = offset + (slice_number + 1) * items_per_slice
        tmp = seq[start:end]
        if fill_with is not None and slice_number >= slices_with_extra:
            tmp.append(fill_with)
        yield tmp


def do_batch(value, linecount, fill_with=None):
    """
    A filter that batches items. It works pretty much like `slice`
    just the other way round. It returns a list of lists with the
    given number of items. If you provide a second parameter this
    is used to fill up missing items. See this example:

    .. sourcecode:: html+jinja

        <table>
        {%- for row in items|batch(3, '&nbsp;') %}
          <tr>
          {%- for column in row %}
            <td>{{ column }}</td>
          {%- endfor %}
          </tr>
        {%- endfor %}
        </table>
    """
    result = []
    tmp = []
    for item in value:
        if len(tmp) == linecount:
            yield tmp
            tmp = []
        tmp.append(item)
    if tmp:
        if fill_with is not None and len(tmp) < linecount:
            tmp += [fill_with] * (linecount - len(tmp))
        yield tmp


def do_round(value, precision=0, method='common'):
    """Round the number to a given precision. The first
    parameter specifies the precision (default is ``0``), the
    second the rounding method:

    - ``'common'`` rounds either up or down
    - ``'ceil'`` always rounds up
    - ``'floor'`` always rounds down

    If you don't specify a method ``'common'`` is used.

    .. sourcecode:: jinja

        {{ 42.55|round }}
            -> 43.0
        {{ 42.55|round(1, 'floor') }}
            -> 42.5

    Note that even if rounded to 0 precision, a float is returned.  If
    you need a real integer, pipe it through `int`:

    .. sourcecode:: jinja

        {{ 42.55|round|int }}
            -> 43
    """
    if not method in ('common', 'ceil', 'floor'):
        raise FilterArgumentError('method must be common, ceil or floor')
    if method == 'common':
        return round(value, precision)
    func = getattr(math, method)
    return func(value * (10 ** precision)) / (10 ** precision)


@environmentfilter
def do_groupby(environment, value, attribute):
    """Group a sequence of objects by a common attribute.

    If you for example have a list of dicts or objects that represent persons
    with `gender`, `first_name` and `last_name` attributes and you want to
    group all users by genders you can do something like the following
    snippet:

    .. sourcecode:: html+jinja

        <ul>
        {% for group in persons|groupby('gender') %}
            <li>{{ group.grouper }}<ul>
            {% for person in group.list %}
                <li>{{ person.first_name }} {{ person.last_name }}</li>
            {% endfor %}</ul></li>
        {% endfor %}
        </ul>

    Additionally it's possible to use tuple unpacking for the grouper and
    list:

    .. sourcecode:: html+jinja

        <ul>
        {% for grouper, list in persons|groupby('gender') %}
            ...
        {% endfor %}
        </ul>

    As you can see the item we're grouping by is stored in the `grouper`
    attribute and the `list` contains all the objects that have this grouper
    in common.

    .. versionchanged:: 2.6
       It's now possible to use dotted notation to group by the child
       attribute of another attribute.
    """
    expr = make_attrgetter(environment, attribute)
    return sorted(map(_GroupTuple, groupby(sorted(value, key=expr), expr)))


class _GroupTuple(tuple):
    __slots__ = ()
    grouper = property(itemgetter(0))
    list = property(itemgetter(1))

    def __new__(cls, xxx_todo_changeme):
        (key, value) = xxx_todo_changeme
        return tuple.__new__(cls, (key, list(value)))


@environmentfilter
def do_sum(environment, iterable, attribute=None, start=0):
    """Returns the sum of a sequence of numbers plus the value of parameter
    'start' (which defaults to 0).  When the sequence is empty it returns
    start.

    It is also possible to sum up only certain attributes:

    .. sourcecode:: jinja

        Total: {{ items|sum(attribute='price') }}

    .. versionchanged:: 2.6
       The `attribute` parameter was added to allow suming up over
       attributes.  Also the `start` parameter was moved on to the right.
    """
    if attribute is not None:
        iterable = imap(make_attrgetter(environment, attribute), iterable)
    return sum(iterable, start)


def do_list(value):
    """Convert the value into a list.  If it was a string the returned list
    will be a list of characters.
    """
    return list(value)


def do_mark_safe(value):
    """Mark the value as safe which means that in an environment with automatic
    escaping enabled this variable will not be escaped.
    """
    return Markup(value)


def do_mark_unsafe(value):
    """Mark a value as unsafe.  This is the reverse operation for :func:`safe`."""
    return text_type(value)


def do_reverse(value):
    """Reverse the object or return an iterator the iterates over it the other
    way round.
    """
    if isinstance(value, string_types):
        return value[::-1]
    try:
        return reversed(value)
    except TypeError:
        try:
            rv = list(value)
            rv.reverse()
            return rv
        except TypeError:
            raise FilterArgumentError('argument must be iterable')


@environmentfilter
def do_attr(environment, obj, name):
    """Get an attribute of an object.  ``foo|attr("bar")`` works like
    ``foo["bar"]`` just that always an attribute is returned and items are not
    looked up.

    See :ref:`Notes on subscriptions <notes-on-subscriptions>` for more details.
    """
    try:
        name = str(name)
    except UnicodeError:
        pass
    else:
        try:
            value = getattr(obj, name)
        except AttributeError:
            pass
        else:
            if environment.sandboxed and not \
               environment.is_safe_attribute(obj, name, value):
                return environment.unsafe_undefined(obj, name)
            return value
    return environment.undefined(obj=obj, name=name)


@contextfilter
def do_map(*args, **kwargs):
    """Applies a filter on a sequence of objects or looks up an attribute.
    This is useful when dealing with lists of objects but you are really
    only interested in a certain value of it.

    The basic usage is mapping on an attribute.  Imagine you have a list
    of users but you are only interested in a list of usernames:

    .. sourcecode:: jinja

        Users on this page: {{ users|map(attribute='username')|join(', ') }}

    Alternatively you can let it invoke a filter by passing the name of the
    filter and the arguments afterwards.  A good example would be applying a
    text conversion filter on a sequence:

    .. sourcecode:: jinja

        Users on this page: {{ titles|map('lower')|join(', ') }}

    .. versionadded:: 2.7
    """
    context = args[0]
    seq = args[1]

    if len(args) == 2 and 'attribute' in kwargs:
        attribute = kwargs.pop('attribute')
        if kwargs:
            raise FilterArgumentError('Unexpected keyword argument %r' %
                next(iter(kwargs)))
        func = make_attrgetter(context.environment, attribute)
    else:
        try:
            name = args[2]
            args = args[3:]
        except LookupError:
            raise FilterArgumentError('map requires a filter argument')
        func = lambda item: context.environment.call_filter(
            name, item, args, kwargs, context=context)

    if seq:
        for item in seq:
            yield func(item)


@contextfilter
def do_select(*args, **kwargs):
    """Filters a sequence of objects by appying a test to either the object
    or the attribute and only selecting the ones with the test succeeding.

    Example usage:

    .. sourcecode:: jinja

        {{ numbers|select("odd") }}

    .. versionadded:: 2.7
    """
    return _select_or_reject(args, kwargs, lambda x: x, False)


@contextfilter
def do_reject(*args, **kwargs):
    """Filters a sequence of objects by appying a test to either the object
    or the attribute and rejecting the ones with the test succeeding.

    Example usage:

    .. sourcecode:: jinja

        {{ numbers|reject("odd") }}

    .. versionadded:: 2.7
    """
    return _select_or_reject(args, kwargs, lambda x: not x, False)


@contextfilter
def do_selectattr(*args, **kwargs):
    """Filters a sequence of objects by appying a test to either the object
    or the attribute and only selecting the ones with the test succeeding.

    Example usage:

    .. sourcecode:: jinja

        {{ users|selectattr("is_active") }}
        {{ users|selectattr("email", "none") }}

    .. versionadded:: 2.7
    """
    return _select_or_reject(args, kwargs, lambda x: x, True)


@contextfilter
def do_rejectattr(*args, **kwargs):
    """Filters a sequence of objects by appying a test to either the object
    or the attribute and rejecting the ones with the test succeeding.

    .. sourcecode:: jinja

        {{ users|rejectattr("is_active") }}
        {{ users|rejectattr("email", "none") }}

    .. versionadded:: 2.7
    """
    return _select_or_reject(args, kwargs, lambda x: not x, True)


def _select_or_reject(args, kwargs, modfunc, lookup_attr):
    context = args[0]
    seq = args[1]
    if lookup_attr:
        try:
            attr = args[2]
        except LookupError:
            raise FilterArgumentError('Missing parameter for attribute name')
        transfunc = make_attrgetter(context.environment, attr)
        off = 1
    else:
        off = 0
        transfunc = lambda x: x

    try:
        name = args[2 + off]
        args = args[3 + off:]
        func = lambda item: context.environment.call_test(
            name, item, args, kwargs)
    except LookupError:
        func = bool

    if seq:
        for item in seq:
            if modfunc(func(transfunc(item))):
                yield item


FILTERS = {
    'attr':                 do_attr,
    'replace':              do_replace,
    'upper':                do_upper,
    'lower':                do_lower,
    'escape':               escape,
    'e':                    escape,
    'forceescape':          do_forceescape,
    'capitalize':           do_capitalize,
    'title':                do_title,
    'default':              do_default,
    'd':                    do_default,
    'join':                 do_join,
    'count':                len,
    'dictsort':             do_dictsort,
    'sort':                 do_sort,
    'length':               len,
    'reverse':              do_reverse,
    'center':               do_center,
    'indent':               do_indent,
    'title':                do_title,
    'capitalize':           do_capitalize,
    'first':                do_first,
    'last':                 do_last,
    'map':                  do_map,
    'random':               do_random,
    'reject':               do_reject,
    'rejectattr':           do_rejectattr,
    'filesizeformat':       do_filesizeformat,
    'pprint':               do_pprint,
    'truncate':             do_truncate,
    'wordwrap':             do_wordwrap,
    'wordcount':            do_wordcount,
    'int':                  do_int,
    'float':                do_float,
    'string':               soft_unicode,
    'list':                 do_list,
    'urlize':               do_urlize,
    'format':               do_format,
    'trim':                 do_trim,
    'striptags':            do_striptags,
    'select':               do_select,
    'selectattr':           do_selectattr,
    'slice':                do_slice,
    'batch':                do_batch,
    'sum':                  do_sum,
    'abs':                  abs,
    'round':                do_round,
    'groupby':              do_groupby,
    'safe':                 do_mark_safe,
    'xmlattr':              do_xmlattr,
    'urlencode':            do_urlencode
}
