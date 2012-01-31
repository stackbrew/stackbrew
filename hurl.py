
##
## Hurl - Human Url.
## A human-friendly url parsing utility
##
## Solomon Hykes <solomon@dotcloud.com>
##

import re

def change(url, **args):
    """ Parse `url`, change certain `parts`, and return it re-assembled.

        Parts can be specified as strings, or modifier functions.

        >>> hurl.change("tcp://toto@localhost:4242/foo/bar", user="solomon", host=str.upper)'
        tcp://solomon@LOCALHOST:4242/foo/bar
        >>>
    """
    parts = parse(url)
    for (key, value) in args.items():
        if callable(value):
            parts[key] = value(parts[key])
        else:
            parts[key] = value
    return unparse(parts)


def parse(url):
    """ urlparse can't deal with arbitrary schemes (eg. tcp:// ssh://).
        This is a good-enough replacement.
    """
    m = re.match('^(?P<scheme>[^:]+)://((?P<user>[^@]+)@)?(?P<host>[^:/]+)(:(?P<port>\d+))?(?P<path>/.*)?$', url)
    if not m:
        raise ValueError('"{url}" is not a valid url'.format(url=url))
    ret = m.groupdict()
    # backward compatibility
    ret['proto'] = ret['scheme']
    return ret


def unparse(parts):
    return (
        ('{proto}://' if parts.get('proto') else '')    +
        ('{user}@' if parts.get('user') else '')        +
        ('{host}' if parts.get('host') else '')         +
        (':{port}' if parts.get('port') else '')        +
        ('{path}' if parts.get('path') else '')
    ).format(**parts)

