import pystache

def render(source, values):
	print pystache.render(source, values)

render(
	"{{ # # foo }} {{ oi }} {{ / # foo }}",
	{'# foo': [{'oi': 'OI!'}]}) # OI!

render(
	"{{ #foo }} {{ oi }} {{ /foo }}",
	{'foo': [{'oi': 'OI!'}]}) # OI!

render(
	"{{{ #foo }}} {{{ /foo }}}",
	{'#foo': 1, '/foo': 2}) # 1 2

render(
	"{{{ { }}}",
	{'{': 1}) # 1

render(
	"{{ > }}}",
	{'>': 'oi'}) # "}"  bug??

render(
	"{{\nfoo}}",
	{'foo': 'bar'}) # // bar

render(
	"{{\tfoo}}",
	{'foo': 'bar'}) # bar

render(
	"{{\t# foo}}oi{{\n/foo}}",
	{'foo': True}) # oi

render(
	"{{{\tfoo\t}}}",
	{'foo': True}) # oi

# Don't work in mustache.js
# render(
# 	"{{ { }}",
# 	{'{': 1}) # ERROR unclosed tag

# render(
# 	"{{ { foo } }}",  
# 	{'foo': 1}) # ERROR unclosed tag
